/** <module> Enactment lane: IM lessons classed data_representation_or_question
 *
 * WHAT THIS MODULE IS FOR. 42 Illustrative Mathematics lessons in
 * data/learningcommons/derived/im_action_seam_recut.json carry the subclass
 * `data_representation_or_question`. No arithmetic automaton computes them,
 * because what they ask a class to do is collect, arrange, and interrogate a
 * record rather than to calculate with a fixed pair of operands. This module
 * models the STRUCTURE each of those lessons asks a class to move through, and
 * runs that structure on the lesson's own inputs where the lesson fixes them
 * and on stand-in inputs where a class would supply them.
 *
 * WHAT AN ENACTMENT DOES NOT CLAIM. Nothing here holds a discussion. A
 * notice-and-wonder enactment prints the noticings the record licenses,
 * together with the arithmetic that grounds each one, and prints the
 * wonderings with the datum that would settle each. A class produces others,
 * and the ones it produces are the point of the routine. Every enactment
 * carries one sentence naming the part of the lesson it did not do, and
 * `enactment_verdict/2` reports `partial(stand_in_data(...))` whenever the
 * numbers came from this module rather than from the guide.
 *
 * THE ELEVEN FORMS. Read from all 42 lessons plus one handed over by the
 * measurement lane, each cited to a lesson id, a source file, and a printed
 * line:
 *
 *   survey_tally_display      a question and its choices become responses,
 *                             responses become a tally, the tally becomes a display
 *   display_question_set      a finished display answers a family of questions
 *   notice_and_wonder         a record licenses noticings and leaves wonderings open
 *   sort_into_bins            items are assigned to named bins, residue set aside
 *   table_from_rule           a rule over a seed generates a column of a table
 *   constraint_fill_table     rows are generated to satisfy a stated constraint
 *   adjudicate_against_data   a proposal is checked against what the data says
 *   measure_then_plot         measurements at a stated precision become a line plot
 *   scale_choice              candidate scales are each costed against the counts
 *   design_and_run_a_routine  a routine's own step sequence is filled in over a
 *                             stimulus, with its candidate contributions drafted
 *   two_displays_one_dataset  one data set rendered twice, totals checked to agree
 *
 * IM-G3-U8-L12 came from the measurement lane, which refused it because its
 * doing is facilitating a routine. It sits in lane_lesson/3 and is counted
 * apart from the subclass's own 42 in lane_coverage/1.
 *
 * A lesson may take more than one form; `lesson_enactment_form/3` is nondet in
 * Form and the first clause for a lesson is its primary form. `enact/3` runs
 * the primary form unless `form-Form` appears in Inputs.
 *
 * WHERE THE NUMBERS COME FROM. `lesson_inputs/4` carries, per lesson and form,
 * the operands and their provenance. `curriculum` means the value is printed in
 * the teacher guide at the cited line. `machine_supplied` means a class would
 * generate the value and this module chose a stand-in so the structure could
 * run; the stand-in is recorded with the same citation discipline, pointing at
 * the line that asks the class to generate it. No enactment reports
 * `well_formed` on stand-in data.
 *
 * DISPLAY SEAM. `Steps` serialize through `enactment_trace_dict/2` into the
 * same `_{strategy, ok, result, steps, note}` shape `strategy_trace_dict/3`
 * emits, with `steps` as `_{n, label, value}`, so an enactment reaches the
 * console and the MCP surface through the path a strategy trace already takes.
 * The enactment-specific keys (form, verdict, artifact) are additive.
 *
 * ARTIFACTS. `scene(Renderer, Term)` routes to an existing scene compiler in
 * knowledge/strategies/render/; this lane uses data_display_scene for
 * bar_chart/1 and dot_plot/1. `printed(record(Title, Rows))` carries the
 * records that are not pictures: tallies, question-and-answer lists, sorted
 * bins, generated tables.
 *
 * Registration into the coordinator: `lesson_enactment:enactment_lane/2` names
 * this module for the subclass, and the three relational contract predicates
 * are contributed as module-qualified multifile clauses. `enact/3` and
 * `enactment_verdict/2` stay local so the coordinator's own clauses keep their
 * determinism.
 */

:- module(data_representation_enactment,
          [ enactment_form/3,            % ?Form, ?Gloss, ?Warrant
            lesson_enactment_form/3,     % ?Lesson, ?Form, ?Evidence
            enactment_move/3,            % ?Form, ?Index, ?Move
            enact/3,                     % +Lesson, +Inputs, -Enactment
            enactment_verdict/2,         % +Enactment, -Verdict
            lesson_inputs/4,             % ?Lesson, ?Form, -Inputs, -Provenance
            lane_lesson/3,               % ?Lesson, ?Grade, ?Source
            enact_lesson/2,              % +Lesson, -Enactment
            enactment_trace_dict/2,      % +Enactment, -Dict
            enactment_not_claimed/2,     % +Enactment, -Sentence
            artifact_renders/2,          % +Artifact, -Status
            lane_coverage/1,             % -Dict
            print_enactment/1            % +Enactment
          ]).

:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(yall)).

% Lesson rows are grouped by lesson rather than by predicate, so a reader can
% check one lesson's form, inputs, and citation in one place.
:- discontiguous lesson_enactment_form/3.
:- discontiguous lesson_inputs/4.
:- discontiguous wonderings/2.
:- discontiguous noticings/2.
:- discontiguous run_move/7.
:- discontiguous form_artifact/4.
:- use_module(library(pairs), [pairs_keys_values/3]).
:- use_module(render(data_display_scene), [data_display_render_json/2]).

% Coordinator registration. The lane fact is additive and cannot double-count.
:- multifile lesson_enactment:enactment_lane/2.
:- multifile lesson_enactment:enactment_form/3.
:- multifile lesson_enactment:lesson_enactment_form/3.
:- multifile lesson_enactment:enactment_move/3.

lesson_enactment:enactment_lane(Form, data_representation_or_question) :-
    enactment_form(Form, _, _).
lesson_enactment:enactment_form(F, G, W) :- enactment_form(F, G, W).
lesson_enactment:lesson_enactment_form(L, F, E) :- lesson_enactment_form(L, F, E).
lesson_enactment:enactment_move(F, I, M) :- enactment_move(F, I, M).


% =============================================================================
% The forms
% =============================================================================

%!  enactment_form(?Form, ?Gloss, ?Warrant) is nondet.
%
%   A structural shape the lessons in this subclass take. Warrant names the
%   lesson the shape was read from and quotes the printed span that carries it,
%   with the source file and line, so the naming can be checked against the
%   guide rather than taken on trust.

enactment_form(survey_tally_display,
    "A survey question and its answer choices become responses, the responses become a tally by category, and the tally becomes a display that the class then questions.",
    warrant('IM-G1-U1-L12',
            'curriculum/im_teacher_guides/grade1/unit1/lesson12.md', 149,
            "     __________________________________________________        • “Today we are going to collect survey data and")).

enactment_form(display_question_set,
    "A finished display answers a fixed family of questions: how many in each category, how many in two categories together, how many more in one than another, how many in all, and which category sits at each extreme.",
    warrant('IM-G2-U1-L9',
            'curriculum/im_teacher_guides/grade2/unit1/lesson9.md', 236,
            "         voted for fall or spring?                      • “How can we use the bar graph to answer these")).

enactment_form(notice_and_wonder,
    "A record licenses some observations by computation over its own numbers and leaves others open; each open one names the datum that would settle it.",
    warrant('IM-G3-U6-L4',
            'curriculum/im_teacher_guides/grade3/unit6/lesson4.md', 245,
            "                                                               • “This line plot has data about the lengths of some")).

enactment_form(sort_into_bins,
    "Items are assigned to named bins by a stated criterion, and an item no bin admits is set aside rather than forced.",
    warrant('IM-G3-U3-L13',
            'curriculum/im_teacher_guides/grade3/unit3/lesson13.md', 209,
            "         If you don’t think a number belongs in any                   • “Now work with your partner to decide if the number")).

enactment_form(table_from_rule,
    "A rule applied to a seed generates a column of a table, and the completed table answers questions about a term at an index and about how two columns stand to one another.",
    warrant('IM-G4-U6-L3',
            'curriculum/im_teacher_guides/grade4/unit6/lesson3.md', 165,
            "      Andre’s rule for a pattern is “start with 9, keep          • Groups of 2")).

enactment_form(constraint_fill_table,
    "Rows are generated to satisfy a stated constraint rather than read off a given record, and each generated row is checked back against the constraint.",
    warrant('IM-G5-U7-L13',
            'curriculum/im_teacher_guides/grade5/unit7/lesson13.md', 167,
            "       1. Jada draws a rectangle with a perimeter of 12                  width?”")).

enactment_form(adjudicate_against_data,
    "A proposed statement or number is brought to the record and the record rules on it; a proposal the record refuses is repaired into one the record accepts.",
    warrant('IM-G1-U1-L11',
            'curriculum/im_teacher_guides/grade1/unit1/lesson11.md', 174,
            "                                                                 • “How can we revise this statement to make it true?”")).

enactment_form(measure_then_plot,
    "Objects measured at a stated precision become a table and then a line plot, and re-measuring at a finer precision produces a second plot whose spread differs.",
    warrant('IM-G4-U3-L13',
            'curriculum/im_teacher_guides/grade4/unit3/lesson13.md', 210,
            "       2. Create a line plot to represent the data your           nearest    inch. Record your measurements in the")).

enactment_form(scale_choice,
    "Each candidate scale for a display is costed against the counts: how many marks it needs per category, and what remainder it leaves that a whole mark cannot carry.",
    warrant('IM-G3-U1-L6',
            'curriculum/im_teacher_guides/grade3/unit1/lesson6.md', 166,
            "        • Mai says the scale of the bar graph should be")).

enactment_form(design_and_run_a_routine,
    "A classroom routine is instantiated over a chosen stimulus: the routine's own printed step sequence is filled in, and the noticings and wonderings the stimulus licenses are drafted so a facilitator has something to compare a class's contributions against.",
    warrant('IM-G3-U8-L12',
            'curriculum/im_teacher_guides/grade3/unit8/lesson12.md', 161,
            "       2. Write down some things students might notice           Wonder about equal groups.”")).

enactment_form(two_displays_one_dataset,
    "One data set is rendered two ways, the totals of the two renderings are checked to agree, and each rendering is named for the reading it makes direct.",
    warrant('IM-G3-U1-L2',
            'curriculum/im_teacher_guides/grade3/unit1/lesson2.md', 174,
            "       2. Represent the same data in a bar graph.                   bottom axis for bike, walk, bus, van, car, and train.")).


% =============================================================================
% The moves
% =============================================================================

%!  enactment_move(?Form, ?Index, ?Move) is nondet.
%
%   The ordered doings a form asks for. Each Move is Verb(Operand), and each
%   Verb has an executing clause in run_move/6 below. A move with no executing
%   clause would fail the form rather than print as a label.

enactment_move(survey_tally_display, 1, pose_question(survey_question)).
enactment_move(survey_tally_display, 2, record_responses(response_list)).
enactment_move(survey_tally_display, 3, tally_by_category(responses)).
enactment_move(survey_tally_display, 4, total_the_tally(tally)).
enactment_move(survey_tally_display, 5, build_display(tally)).
enactment_move(survey_tally_display, 6, question_the_display(tally)).

enactment_move(display_question_set, 1, read_display(display)).
enactment_move(display_question_set, 2, count_each_category(display)).
enactment_move(display_question_set, 3, total_two_categories(category_pairs)).
enactment_move(display_question_set, 4, compare_two_categories(category_pairs)).
enactment_move(display_question_set, 5, total_all_categories(display)).
enactment_move(display_question_set, 6, name_extremes(display)).

enactment_move(notice_and_wonder, 1, read_display(display)).
enactment_move(notice_and_wonder, 2, derive_noticings(display)).
enactment_move(notice_and_wonder, 3, derive_wonderings(display)).
enactment_move(notice_and_wonder, 4, mark_class_residue(display)).

enactment_move(sort_into_bins, 1, read_items(items)).
enactment_move(sort_into_bins, 2, read_bins(bins)).
enactment_move(sort_into_bins, 3, assign_each_item(items)).
enactment_move(sort_into_bins, 4, collect_residue(items)).
enactment_move(sort_into_bins, 5, report_bin_counts(bins)).

enactment_move(table_from_rule, 1, read_rule(rule)).
enactment_move(table_from_rule, 2, generate_terms(rule)).
enactment_move(table_from_rule, 3, fill_table(terms)).
enactment_move(table_from_rule, 4, answer_index_questions(terms)).
enactment_move(table_from_rule, 5, state_column_relationship(terms)).

enactment_move(constraint_fill_table, 1, read_constraint(constraint)).
enactment_move(constraint_fill_table, 2, enumerate_solutions(constraint)).
enactment_move(constraint_fill_table, 3, record_rows(solutions)).
enactment_move(constraint_fill_table, 4, check_rows_against_constraint(solutions)).

enactment_move(adjudicate_against_data, 1, read_data(data)).
enactment_move(adjudicate_against_data, 2, evaluate_each_claim(claims)).
enactment_move(adjudicate_against_data, 3, repair_refused_claims(claims)).
enactment_move(adjudicate_against_data, 4, report_verdicts(claims)).

enactment_move(measure_then_plot, 1, read_objects(objects)).
enactment_move(measure_then_plot, 2, round_to_precision(objects)).
enactment_move(measure_then_plot, 3, tabulate_measurements(objects)).
enactment_move(measure_then_plot, 4, plot_line_plot(measurements)).
enactment_move(measure_then_plot, 5, refine_precision(objects)).
enactment_move(measure_then_plot, 6, compare_two_plots(measurements)).

enactment_move(scale_choice, 1, read_counts(display)).
enactment_move(scale_choice, 2, cost_each_scale(candidate_scales)).
enactment_move(scale_choice, 3, name_remainders(candidate_scales)).
enactment_move(scale_choice, 4, choose_scale(candidate_scales)).

enactment_move(design_and_run_a_routine, 1, choose_stimulus(stimulus)).
enactment_move(design_and_run_a_routine, 2, draft_candidate_noticings(stimulus)).
enactment_move(design_and_run_a_routine, 3, draft_candidate_wonderings(stimulus)).
enactment_move(design_and_run_a_routine, 4, sequence_the_routine(protocol)).
enactment_move(design_and_run_a_routine, 5, mark_facilitator_residue(stimulus)).

enactment_move(two_displays_one_dataset, 1, read_dataset(display)).
enactment_move(two_displays_one_dataset, 2, render_first(first_kind)).
enactment_move(two_displays_one_dataset, 3, render_second(second_kind)).
enactment_move(two_displays_one_dataset, 4, check_totals_agree(display)).
enactment_move(two_displays_one_dataset, 5, name_reading_difference(display)).


% =============================================================================
% Running a form
% =============================================================================

%!  enact(+Lesson, +Inputs, -Enactment) is nondet.
%
%   Run the lesson's form over Inputs. Inputs is a list of Key-Value pairs and
%   `form-Form` comes first, so the form is read off the arguments rather than
%   looked up. Several lessons here exhibit two forms, so with no `form-` key
%   this backtracks over the forms the lesson takes. Fails rather than guessing
%   when Inputs do not carry what a form's moves need.
enact(Lesson, Inputs, enactment(Lesson, Form, Inputs, Steps, Artifact)) :-
    (   memberchk(form-Form, Inputs)
    ->  true
    ;   lesson_enactment_form(Lesson, Form, _)
    ),
    findall(I-M, enactment_move(Form, I, M), Moves0),
    keysort(Moves0, Moves),
    Moves \== [],
    run_moves(Moves, Form, Inputs, [], State, Steps),
    once(form_artifact(Form, Inputs, State, Artifact)).

% A move runs once. The form is the only place this predicate backtracks; a
% second solution from inside a move would be a second reading of one doing.
run_moves([], _Form, _Inputs, State, State, []).
run_moves([I-Move | Rest], Form, Inputs, State0, State, [Step | Steps]) :-
    Move =.. [Verb, Operand],
    once(run_move(Verb, Form, Operand, Inputs, State0, State1, Result)),
    Step = step(I, Verb, Operand, Result),
    run_moves(Rest, Form, Inputs, State1, State, Steps).

%!  enact_lesson(+Lesson, -Enactment) is semidet.
%
%   Run the lesson on the inputs this module records for it.
enact_lesson(Lesson, Enactment) :-
    once(lesson_enactment_form(Lesson, Form, _)),
    once(lesson_inputs(Lesson, Form, Inputs, _Provenance)),
    once(enact(Lesson, [form-Form | Inputs], Enactment)).


% =============================================================================
% Verdicts
% =============================================================================

%!  enactment_verdict(+Enactment, -Verdict) is det.
%
%   well_formed  every move ran and every operand came from the guide.
%   partial(R)   the form ran on at least one stand-in operand, or a move ran
%                on fewer operands than the lesson names.
%   refused(R)   the form did not run to an artifact.
enactment_verdict(E, Verdict) :-
    (   E = enactment(Lesson, Form, Inputs, Steps, Artifact)
    ->  (   Steps == []
        ->  Verdict = refused(no_move_ran)
        ;   Artifact == none
        ->  Verdict = refused(no_artifact_built)
        ;   once(lesson_inputs(Lesson, Form, _, Provenance)),
            memberchk(input_provenance-machine_supplied, Provenance)
        ->  memberchk(stand_in_note-Note, Provenance),
            Verdict = partial(stand_in_data(Note))
        ;   memberchk(partial-Reason, Inputs)
        ->  Verdict = partial(Reason)
        ;   Verdict = well_formed
        )
    ;   Verdict = refused(malformed_enactment)
    ).

%!  enactment_not_claimed(+Enactment, -Sentence) is det.
%
%   One sentence naming the part of the lesson the machine did not do. Always
%   present, never repeated elsewhere in the row.
enactment_not_claimed(enactment(_, Form, _, _, _), Sentence) :-
    form_not_claimed(Form, Sentence), !.
enactment_not_claimed(_, "This record is the mathematical work of the lesson and not the classroom exchange around it.").

form_not_claimed(survey_tally_display,
    "The responses are a stand-in for a class's own answers, so the tally is the right shape carrying numbers a real survey would replace.").
form_not_claimed(display_question_set,
    "These are the questions the display's own numbers settle, not the questions a class would think to ask of it.").
form_not_claimed(notice_and_wonder,
    "No discussion occurred: these are the observations the record licenses by computation, and a class would produce others that no computation over these numbers reaches.").
form_not_claimed(sort_into_bins,
    "The criterion is the one the lesson states, so a defensible disagreement about a borderline item is recorded as residue rather than adjudicated.").
form_not_claimed(table_from_rule,
    "The table is generated and checked; the reasoning a student gives for why the pattern holds is not.").
form_not_claimed(constraint_fill_table,
    "Every generated row satisfies the constraint, which is a weaker claim than that a student would choose these rows.").
form_not_claimed(adjudicate_against_data,
    "The record rules on each claim; the explanation a student owes for the ruling is not produced.").
form_not_claimed(measure_then_plot,
    "The measurements are supplied rather than taken, so the plot models what the class's own rulers would fill in.").
form_not_claimed(scale_choice,
    "Each scale is costed arithmetically; which cost a class should mind is the lesson's argument and stays open.").
form_not_claimed(design_and_run_a_routine,
    "The routine is instantiated and its candidate contributions are drafted; the routine was not run, and a class says things this draft does not anticipate.").
form_not_claimed(two_displays_one_dataset,
    "The two renderings and their agreement are computed; the preference a class forms between them is not.").


% =============================================================================
% Move execution
% =============================================================================
% Each clause is a doing over an operand. State threads the intermediate
% records so a later move reads what an earlier one built.

% --- survey_tally_display -------------------------------------------------

run_move(pose_question, _, _, Inputs, S, S, Result) :-
    memberchk(question-Q, Inputs),
    memberchk(choices-Cs, Inputs),
    length(Cs, N),
    atomic_list_concat(Cs, ', ', ChoiceText),
    format(atom(Result), "~w  [~w choices: ~w]", [Q, N, ChoiceText]).

run_move(record_responses, _, _, Inputs, S, [responses-Rs | S], Result) :-
    memberchk(responses-Rs, Inputs),
    length(Rs, N),
    format(atom(Result), "~w responses recorded", [N]).

run_move(tally_by_category, _, _, Inputs, S0, [tally-Tally | S0], Result) :-
    memberchk(responses-Rs, Inputs),
    memberchk(choices-Cs, Inputs),
    tally_responses(Cs, Rs, Tally),
    pairs_text(Tally, Result).

run_move(total_the_tally, _, _, _Inputs, S, S, Result) :-
    memberchk(tally-Tally, S),
    pairs_keys_values(Tally, _, Counts),
    sum_list(Counts, Total),
    memberchk(responses-Rs, S),
    length(Rs, N),
    (   Total =:= N
    ->  format(atom(Result), "~w in all; the tally accounts for every response", [Total])
    ;   format(atom(Result), "~w in all; ~w responses fall outside the listed choices", [Total, N])
    ).

run_move(build_display, _, _, Inputs, S, S, Result) :-
    memberchk(tally-Tally, S),
    (   memberchk(display-Kind, Inputs) -> true ; Kind = bar_graph ),
    length(Tally, N),
    format(atom(Result), "~w with ~w category bars", [Kind, N]).

run_move(question_the_display, _, _, Inputs, S, S, Result) :-
    memberchk(tally-Tally, S),
    (   memberchk(title-T, Inputs) -> true ; T = 'the survey' ),
    question_frame(Inputs, Frame),
    display_questions(Frame, T, categorical(T, Tally), QAs),
    length(QAs, N),
    qa_text(QAs, Text),
    format(atom(Result), "~w questions the display settles: ~w", [N, Text]).

% --- display_question_set -------------------------------------------------

run_move(read_display, _, _, Inputs, S, [display-D | S], Result) :-
    input_display(Inputs, D),
    display_summary(D, Result).

run_move(count_each_category, _, _, _Inputs, S, S, Result) :-
    memberchk(display-D, S),
    (   D = categorical(_, Pairs)
    ->  findall(Txt,
                ( member(C-N, Pairs),
                  format(atom(Txt), "~w: ~w", [C, N]) ),
                Txts)
    ;   D = numeric(_, Values),
        msort(Values, Sorted), unique_values(Sorted, Uniq),
        findall(Txt,
                ( member(V, Uniq), occurrences_of(V, Values, N),
                  format(atom(Txt), "~w: ~w", [V, N]) ),
                Txts)
    ),
    atomic_list_concat(Txts, '; ', Result).

% A categorical display answers "how many chose A or B"; a line plot answers
% "how many sit below a threshold and how many above". Both are the same move
% over the display's own numbers, so the clause branches on the display kind
% rather than on a stored label.
run_move(total_two_categories, _, _, Inputs, S, S, Result) :-
    question_frame(Inputs, incommensurable), !,
    memberchk(display-D, S),
    display_pairs(D, Pairs),
    length(Pairs, N),
    format(atom(Result),
           "adding two of these ~w entries has no referent: each is a count of a different unit",
           [N]).
run_move(total_two_categories, _, _, _Inputs, S, S, Result) :-
    memberchk(display-D, S),
    D = numeric(_, Values), !,
    msort(Values, Sorted), min_list(Values, Lo), max_list(Values, Hi),
    Mid is (Lo + Hi) / 2,
    include(below_value(Mid), Sorted, Below),
    include(above_value(Mid), Sorted, Above),
    include(at_value(Mid), Sorted, At),
    length(Below, Nb), length(Above, Na), length(At, Nat),
    value_text(Mid, MidT),
    format(atom(Result), "below ~w: ~w; at ~w: ~w; above ~w: ~w", [MidT, Nb, MidT, Nat, MidT, Na]).
run_move(total_two_categories, _, _, _Inputs, S, S, Result) :-
    memberchk(display-D, S),
    display_pairs(D, Pairs),
    length(Pairs, Len), Len >= 2,
    findall(Txt,
            ( adjacent_pair(Pairs, A-Na, B-Nb),
              T is Na + Nb,
              format(atom(Txt), "~w or ~w: ~w", [A, B, T]) ),
            Txts),
    atomic_list_concat(Txts, '; ', Result).

run_move(compare_two_categories, _, _, _Inputs, S, S, Result) :-
    memberchk(display-D, S),
    D = numeric(_, Values), !,
    min_list(Values, Lo), max_list(Values, Hi),
    Diff is Hi - Lo,
    value_text(Lo, LoT), value_text(Hi, HiT), value_text(Diff, DiffT),
    format(atom(Result), "longest ~w, shortest ~w, difference ~w", [HiT, LoT, DiffT]).
run_move(compare_two_categories, _, _, _Inputs, S, S, Result) :-
    memberchk(display-D, S),
    display_pairs(D, Pairs),
    max_pair(Pairs, Amax-Nmax),
    min_pair(Pairs, Amin-Nmin),
    Diff is Nmax - Nmin,
    format(atom(Result), "~w more for ~w than for ~w (~w - ~w)",
           [Diff, Amax, Amin, Nmax, Nmin]).

run_move(total_all_categories, _, _, Inputs, S, S, Result) :-
    question_frame(Inputs, incommensurable), !,
    memberchk(display-D, S),
    display_pairs(D, Pairs),
    max_pair(Pairs, Amax-Nmax), min_pair(Pairs, Amin-Nmin),
    format(atom(Result),
           "no grand total: the same quantity reported in ~w gives ~w and in ~w gives ~w, so the entries do not add",
           [Amax, Nmax, Amin, Nmin]).
run_move(total_all_categories, _, _, _Inputs, S, S, Result) :-
    memberchk(display-D, S),
    display_pairs(D, Pairs),
    pairs_keys_values(Pairs, _, Counts),
    sum_list(Counts, Total),
    length(Pairs, N),
    format(atom(Result), "~w in all across ~w categories", [Total, N]).

run_move(name_extremes, _, _, _Inputs, S, S, Result) :-
    memberchk(display-D, S),
    D = numeric(_, Values), !,
    display_pairs(D, Pairs),
    max_pair(Pairs, Vmode-Cmode),
    length(Values, N), length(Pairs, Distinct),
    value_text(Vmode, VmT),
    format(atom(Result), "most common value ~w with ~w marks; ~w marks over ~w positions",
           [VmT, Cmode, N, Distinct]).
run_move(name_extremes, _, _, _Inputs, S, S, Result) :-
    memberchk(display-D, S),
    display_pairs(D, Pairs),
    max_pair(Pairs, Amax-Nmax),
    min_pair(Pairs, Amin-Nmin),
    format(atom(Result), "most: ~w (~w); fewest: ~w (~w)", [Amax, Nmax, Amin, Nmin]).

% --- notice_and_wonder ----------------------------------------------------

run_move(derive_noticings, _, _, _Inputs, S, [noticings-Ns | S], Result) :-
    memberchk(display-D, S),
    noticings(D, Ns),
    Ns \== [],
    length(Ns, Count),
    findall(Txt, ( member(noticing(Sent, Ground), Ns),
                   format(atom(Txt), "~w  [~w]", [Sent, Ground]) ), Txts),
    atomic_list_concat(Txts, ' | ', Body),
    format(atom(Result), "~w noticings the record licenses: ~w", [Count, Body]).

run_move(derive_wonderings, _, _, _Inputs, S, [wonderings-Ws | S], Result) :-
    memberchk(display-D, S),
    wonderings(D, Ws),
    Ws \== [],
    length(Ws, Count),
    findall(Txt, ( member(wondering(Sent, Settle), Ws),
                   format(atom(Txt), "~w  [settled by: ~w]", [Sent, Settle]) ), Txts),
    atomic_list_concat(Txts, ' | ', Body),
    format(atom(Result), "~w wonderings left open: ~w", [Count, Body]).

run_move(mark_class_residue, _, _, _Inputs, S, S, Result) :-
    memberchk(noticings-Ns, S),
    memberchk(wonderings-Ws, S),
    length(Ns, Nn), length(Ws, Nw),
    format(atom(Result),
           "~w licensed noticings and ~w open wonderings; a class adds observations about the context that no computation over these numbers reaches",
           [Nn, Nw]).

% --- sort_into_bins -------------------------------------------------------

run_move(read_items, _, _, Inputs, S, [items-Is | S], Result) :-
    memberchk(items-Is, Inputs),
    length(Is, N),
    items_text(Is, Text),
    format(atom(Result), "~w items: ~w", [N, Text]).

run_move(read_bins, _, _, Inputs, S, [bins-Bs | S], Result) :-
    memberchk(bins-Bs, Inputs),
    findall(Name, member(bin(Name, _), Bs), Names),
    atomic_list_concat(Names, ' / ', Result).

run_move(assign_each_item, _, _, Inputs, S, [assignment-As | S], Result) :-
    memberchk(items-Is, S),
    memberchk(bins-Bs, S),
    (   memberchk(residue_bin-RB, Inputs) -> true ; RB = 'set aside' ),
    assign_items(Is, Bs, RB, As),
    findall(Txt, ( member(Item-Bin, As),
                   format(atom(Txt), "~w -> ~w", [Item, Bin]) ), Txts),
    atomic_list_concat(Txts, '; ', Result).

run_move(collect_residue, _, _, Inputs, S, S, Result) :-
    memberchk(assignment-As, S),
    (   memberchk(residue_bin-RB, Inputs) -> true ; RB = 'set aside' ),
    findall(I, member(I-RB, As), Residue),
    length(Residue, N),
    (   N =:= 0
    ->  Result = "no item was set aside; every item met a stated criterion"
    ;   items_text(Residue, Text),
        format(atom(Result), "~w set aside: ~w", [N, Text])
    ).

run_move(report_bin_counts, _, _, _Inputs, S, S, Result) :-
    memberchk(assignment-As, S),
    memberchk(bins-Bs, S),
    findall(Name-Count,
            ( member(bin(Name, _), Bs),
              aggregate_all(count, member(_-Name, As), Count) ),
            Counts),
    pairs_text(Counts, Result).

% --- table_from_rule ------------------------------------------------------

run_move(read_rule, _, _, Inputs, S, [rule-R | S], Result) :-
    memberchk(rule-R, Inputs),
    rule_text(R, Result).

run_move(generate_terms, _, _, Inputs, S, [terms-Terms | S], Result) :-
    memberchk(rule-R, S),
    (   memberchk(count-N, Inputs) -> true ; N = 10 ),
    apply_rule(R, N, Inputs, Terms),
    Terms \== [],
    values_text(Terms, Result).

run_move(fill_table, _, _, Inputs, S, [table-Rows | S], Result) :-
    memberchk(terms-Terms, S),
    (   memberchk(columns-Cols, Inputs) -> true ; Cols = ['term'] ),
    table_rows(Cols, Terms, Rows),
    length(Rows, N),
    atomic_list_concat(Cols, ' | ', Header),
    format(atom(Result), "~w rows under [~w]", [N, Header]).

run_move(answer_index_questions, _, _, Inputs, S, S, Result) :-
    memberchk(rule-R, S),
    (   memberchk(index_questions-Qs, Inputs) -> true ; Qs = [] ),
    (   Qs == []
    ->  Result = "the lesson asks no term-at-an-index question of this table"
    ;   findall(Txt,
                ( member(K, Qs),
                  nth_term(R, K, Inputs, V),
                  format(atom(Txt), "term ~w: ~w", [K, V]) ),
                Txts),
        atomic_list_concat(Txts, '; ', Result)
    ).

run_move(state_column_relationship, _, _, Inputs, S0, S, Result) :-
    memberchk(terms-Terms, S0),
    (   memberchk(second_rule-R2, Inputs)
    ->  (   memberchk(count-N, Inputs) -> true ; N = 10 ),
        apply_rule(R2, N, Inputs, Terms2),
        S = [second_terms-Terms2 | S0],
        column_relationship(Terms, Terms2, Result)
    ;   S = S0,
        consecutive_difference(Terms, Result)
    ).

% --- constraint_fill_table ------------------------------------------------

run_move(read_constraint, _, _, Inputs, S, [constraint-C | S], Result) :-
    memberchk(constraint-C, Inputs),
    constraint_text(C, Result).

run_move(enumerate_solutions, _, _, Inputs, S, [solutions-Sols | S], Result) :-
    memberchk(constraint-C, S),
    (   memberchk(count-N, Inputs) -> true ; N = 5 ),
    solutions_for(C, N, Sols),
    Sols \== [],
    length(Sols, Found),
    solutions_text(Sols, Text),
    format(atom(Result), "~w rows found: ~w", [Found, Text]).

run_move(record_rows, _, _, Inputs, S, S, Result) :-
    memberchk(solutions-Sols, S),
    (   memberchk(columns-Cols, Inputs) -> true ; Cols = ['value'] ),
    length(Sols, N),
    atomic_list_concat(Cols, ' | ', Header),
    format(atom(Result), "~w rows recorded under [~w]", [N, Header]).

run_move(check_rows_against_constraint, _, _, _Inputs, S, S, Result) :-
    memberchk(constraint-C, S),
    memberchk(solutions-Sols, S),
    include(satisfies_constraint(C), Sols, Good),
    length(Sols, N), length(Good, G),
    (   N =:= G
    ->  format(atom(Result), "all ~w rows check back against the constraint", [N])
    ;   Bad is N - G,
        format(atom(Result), "~w of ~w rows check back; ~w do not", [G, N, Bad])
    ).

% --- adjudicate_against_data ----------------------------------------------

run_move(read_data, _, _, Inputs, S, [display-D | S], Result) :-
    input_display(Inputs, D),
    display_summary(D, Result).

run_move(evaluate_each_claim, _, _, Inputs, S, [rulings-Rs | S], Result) :-
    memberchk(display-D, S),
    memberchk(claims-Claims, Inputs),
    findall(ruling(Text, Test, Holds),
            ( member(claim(Text, Test), Claims),
              (   claim_holds(Test, D) -> Holds = true ; Holds = false ) ),
            Rs),
    findall(Txt, ( member(ruling(T, _, H), Rs),
                   format(atom(Txt), "~w -> ~w", [T, H]) ), Txts),
    atomic_list_concat(Txts, '; ', Result).

run_move(repair_refused_claims, _, _, _Inputs, S, S, Result) :-
    memberchk(rulings-Rs, S),
    memberchk(display-D, S),
    findall(Txt,
            ( member(ruling(T, Test, false), Rs),
              repair_claim(Test, D, Repaired),
              format(atom(Txt), "~w  ->  ~w", [T, Repaired]) ),
            Txts),
    (   Txts == []
    ->  Result = "the record accepted every claim; nothing needed repair"
    ;   atomic_list_concat(Txts, ' | ', Result)
    ).

run_move(report_verdicts, _, _, _Inputs, S, S, Result) :-
    memberchk(rulings-Rs, S),
    aggregate_all(count, member(ruling(_, _, true), Rs), T),
    aggregate_all(count, member(ruling(_, _, false), Rs), F),
    format(atom(Result), "~w claims accepted, ~w refused", [T, F]).

% --- measure_then_plot ----------------------------------------------------

run_move(read_objects, _, _, Inputs, S, [objects-Os | S], Result) :-
    memberchk(objects-Os, Inputs),
    length(Os, N),
    (   memberchk(unit-U, Inputs) -> true ; U = unit ),
    format(atom(Result), "~w objects measured in ~w", [N, U]).

run_move(round_to_precision, _, _, Inputs, S, [rounded-Rs | S], Result) :-
    memberchk(objects-Os, S),
    memberchk(precision-P, Inputs),
    findall(Name-V,
            ( member(Name-Raw, Os), round_to(Raw, P, V) ),
            Rs),
    pairs_keys_values(Rs, _, Vs),
    values_text(Vs, Text),
    precision_text(P, PT),
    format(atom(Result), "to the nearest ~w: ~w", [PT, Text]).

run_move(tabulate_measurements, _, _, _Inputs, S, S, Result) :-
    memberchk(rounded-Rs, S),
    findall(Txt, ( member(N-V, Rs), value_text(V, VT),
                   format(atom(Txt), "~w: ~w", [N, VT]) ), Txts),
    atomic_list_concat(Txts, '; ', Result).

run_move(plot_line_plot, _, _, _Inputs, S, [plot-Vs | S], Result) :-
    memberchk(rounded-Rs, S),
    pairs_keys_values(Rs, _, Vs),
    msort(Vs, Sorted), unique_values(Sorted, Uniq),
    length(Uniq, D), length(Vs, N),
    format(atom(Result), "~w marks over ~w distinct positions", [N, D]).

run_move(refine_precision, _, _, Inputs, S, [refined-Rs2 | S], Result) :-
    memberchk(objects-Os, S),
    (   memberchk(finer_precision-P2, Inputs)
    ->  findall(Name-V, ( member(Name-Raw, Os), round_to(Raw, P2, V) ), Rs2),
        pairs_keys_values(Rs2, _, Vs2),
        values_text(Vs2, Text),
        precision_text(P2, PT),
        format(atom(Result), "re-measured to the nearest ~w: ~w", [PT, Text])
    ;   memberchk(rounded-Rs2, S),
        Result = "the lesson names one precision, so no second pass runs"
    ).

run_move(compare_two_plots, _, _, _Inputs, S, S, Result) :-
    memberchk(plot-Vs, S),
    memberchk(refined-Rs2, S),
    pairs_keys_values(Rs2, _, Vs2),
    msort(Vs, S1), unique_values(S1, U1), length(U1, D1),
    msort(Vs2, S2), unique_values(S2, U2), length(U2, D2),
    (   D2 > D1
    ->  format(atom(Result), "the finer pass spreads the same objects over ~w positions instead of ~w", [D2, D1])
    ;   D2 =:= D1
    ->  format(atom(Result), "both passes land on ~w positions", [D1])
    ;   format(atom(Result), "the second pass collapses ~w positions to ~w", [D1, D2])
    ).

% --- scale_choice ---------------------------------------------------------

run_move(read_counts, _, _, Inputs, S, [display-D | S], Result) :-
    input_display(Inputs, D),
    display_summary(D, Result).

run_move(cost_each_scale, _, _, Inputs, S, [costs-Costs | S], Result) :-
    memberchk(display-D, S),
    display_pairs(D, Pairs),
    memberchk(candidate_scales-Scales, Inputs),
    findall(cost(Sc, Marks, Rem, Parts),
            ( member(Sc, Scales), scale_cost(Pairs, Sc, Marks, Rem, Parts) ),
            Costs),
    findall(Txt, ( member(cost(Sc, M, _, P), Costs),
                   format(atom(Txt), "scale ~w: ~w whole marks, ~w categories needing a part mark", [Sc, M, P]) ), Txts),
    atomic_list_concat(Txts, '; ', Result).

run_move(name_remainders, _, _, _Inputs, S, S, Result) :-
    memberchk(costs-Costs, S),
    findall(Sc, member(cost(Sc, _, _, 0), Costs), Exact),
    (   Exact == []
    ->  findall(P-Sc, member(cost(Sc, _, _, P), Costs), Ps), msort(Ps, [Pl-Sl | _]),
        format(atom(Result),
               "no candidate scale divides every count exactly; scale ~w comes closest, with ~w categories needing a part mark",
               [Sl, Pl])
    ;   values_text(Exact, Text),
        format(atom(Result), "divides every count exactly: ~w", [Text])
    ).

run_move(choose_scale, _, _, _Inputs, S, S, Result) :-
    memberchk(costs-Costs, S),
    (   findall(M-Sc, member(cost(Sc, M, _, 0), Costs), Exact), Exact \== []
    ->  msort(Exact, [Mm-Chosen | _]),
        format(atom(Result), "scale ~w: ~w whole marks and no part mark", [Chosen, Mm])
    ;   findall(P-Sc, member(cost(Sc, _, _, P), Costs), Ps),
        msort(Ps, [Pp-Chosen | _]),
        format(atom(Result),
               "scale ~w: ~w categories carry an amount a whole mark cannot show, so each of those needs a part mark",
               [Chosen, Pp])
    ).

% --- design_and_run_a_routine ---------------------------------------------
% A classroom-routine enactor. IM prints the step sequence of each of its
% routines in the guide; this fills that sequence in over a stated stimulus and
% drafts the noticings and wonderings the stimulus licenses, so the group
% facilitating the routine holds something to compare a class's own
% contributions against. It does not run the routine, and the draft is a
% prediction rather than a record.

run_move(choose_stimulus, _, _, Inputs, S, [stimulus-St | S], Result) :-
    memberchk(stimulus-St, Inputs),
    stimulus_text(St, Result).

run_move(draft_candidate_noticings, _, _, _Inputs, S, [noticings-Ns | S], Result) :-
    memberchk(stimulus-St, S),
    stimulus_noticings(St, Ns),
    Ns \== [],
    length(Ns, N),
    findall(Txt, ( member(noticing(Sent, Ground), Ns),
                   format(atom(Txt), "~w  [~w]", [Sent, Ground]) ), Txts),
    atomic_list_concat(Txts, ' | ', Body),
    format(atom(Result), "~w drafted noticings: ~w", [N, Body]).

run_move(draft_candidate_wonderings, _, _, _Inputs, S, [wonderings-Ws | S], Result) :-
    memberchk(stimulus-St, S),
    stimulus_wonderings(St, Ws),
    Ws \== [],
    length(Ws, N),
    findall(Txt, ( member(wondering(Sent, Settle), Ws),
                   format(atom(Txt), "~w  [settled by: ~w]", [Sent, Settle]) ), Txts),
    atomic_list_concat(Txts, ' | ', Body),
    format(atom(Result), "~w drafted wonderings: ~w", [N, Body]).

run_move(sequence_the_routine, _, _, Inputs, S, [protocol-Steps | S], Result) :-
    memberchk(routine-Routine, Inputs),
    memberchk(stimulus-St, S),
    routine_protocol(Routine, Template),
    stimulus_short_name(St, Name),
    findall(Filled,
            ( member(Slot, Template), fill_slot(Slot, Name, Filled) ),
            Steps),
    length(Steps, N),
    atomic_list_concat(Steps, ' / ', Body),
    format(atom(Result), "~w steps: ~w", [N, Body]).

run_move(mark_facilitator_residue, _, _, _Inputs, S, S, Result) :-
    memberchk(noticings-Ns, S),
    memberchk(wonderings-Ws, S),
    length(Ns, Nn), length(Ws, Nw),
    Total is Nn + Nw,
    format(atom(Result),
           "~w drafted contributions, ~w noticings and ~w wonderings, none of them said by a person; the facilitating group collects what the class actually offers and compares",
           [Total, Nn, Nw]).

%!  routine_protocol(?Routine, ?Template) is nondet.
%
%   The step sequence IM prints for the routine, read from a guide that runs
%   it. A slot marked stimulus(_) takes the name of this instance's stimulus.
routine_protocol(notice_and_wonder,
    [ display(stimulus),
      "\"What do you notice? What do you wonder?\"",
      "1 minute: quiet think time",
      "\"Discuss your thinking with your partner.\"",
      "1 minute: partner discussion",
      "Share and record responses." ]).
routine_protocol(estimation_exploration,
    [ display(stimulus),
      "\"What is an estimate that's too high? Too low? About right?\"",
      "1 minute: quiet think time",
      "\"Discuss your thinking with your partner.\"",
      "1 minute: partner discussion",
      "Record responses." ]).

%   Cited: notice_and_wonder from
%   curriculum/im_teacher_guides/grade3/unit8/lesson12.md lines 92-100, which
%   runs the routine the same lesson then asks a group to build.
%   estimation_exploration from
%   curriculum/im_teacher_guides/grade3/unit8/lesson14.md lines 90-101, which is
%   the routine the measurement lane's bracket_unknown_measure lessons carry, so
%   this form covers that shape when the stimulus is a measured quantity.

fill_slot(display(stimulus), Name, Filled) :- !,
    format(atom(Filled), "Display ~w.", [Name]).
fill_slot(Text, _, Text).

%!  stimulus_text(+Stimulus, -Text) is det.
stimulus_text(equal_groups(G, Sz, Item, _-Plural), T) :-
    format(atom(T), "~w ~w, each holding ~w ~w", [G, Plural, Sz, Item]).
stimulus_text(measured_quantity(What, Actual, Unit), T) :-
    format(atom(T), "~w, which measures ~w ~w", [What, Actual, Unit]).

stimulus_short_name(equal_groups(_, _, Item, _-Plural), N) :-
    format(atom(N), "the picture of ~w in ~w", [Item, Plural]).
stimulus_short_name(measured_quantity(What, _, _), N) :-
    format(atom(N), "the picture of ~w", [What]).

%!  stimulus_noticings(+Stimulus, -Noticings) is det.
%
%   Each drafted noticing carries the computation over the stimulus that would
%   ground it, so a facilitator can tell a licensed observation from a guess.
stimulus_noticings(equal_groups(G, Sz, Item, Singular-Plural), Ns) :-
    Total is G * Sz,
    format(atom(S1), "there are ~w ~w", [G, Plural]),
    format(atom(S2), "each ~w holds the same number, ~w", [Singular, Sz]),
    format(atom(S3), "counting by ~w reaches ~w after ~w counts", [Sz, Total, G]),
    format(atom(S4), "there are ~w ~w in all", [Total, Item]),
    format(atom(S5), "the same ~w make ~w groups of ~w as well", [Total, Sz, G]),
    Ns = [ noticing(S1, "count of the groups"),
           noticing(S2, "equality test across the group sizes"),
           noticing(S3, "repeated addition of the group size"),
           noticing(S4, "group count times group size"),
           noticing(S5, "the same product with the factors exchanged") ].
stimulus_noticings(measured_quantity(What, Actual, Unit), Ns) :-
    Low is max(0, Actual - max(1, Actual // 3)),
    High is Actual + max(1, Actual // 3),
    format(atom(S1), "~w is longer than ~w ~w", [What, Low, Unit]),
    format(atom(S2), "~w is shorter than ~w ~w", [What, High, Unit]),
    format(atom(S3), "an estimate of ~w ~w is about right", [Actual, Unit]),
    Width is High - Low,
    format(atom(S4), "the too-low and too-high proposals sit ~w ~w apart", [Width, Unit]),
    Ns = [ noticing(S1, "comparison of the measure with a low landmark"),
           noticing(S2, "comparison of the measure with a high landmark"),
           noticing(S3, "the measure itself"),
           noticing(S4, "width of the bracket") ].

%!  stimulus_wonderings(+Stimulus, -Wonderings) is det.
stimulus_wonderings(equal_groups(_, _, Item, Singular-_), Ws) :-
    format(atom(W1), "How many ~w are there altogether?", [Item]),
    format(atom(W2), "Does every ~w really hold the same number?", [Singular]),
    format(atom(W3), "What would change if one ~w held one more?", [Singular]),
    Ws = [ wondering(W1, "the product, which the picture shows and does not label"),
           wondering(W2, "a count of each group, which settles it either way"),
           wondering(W3, "a second arrangement, which the picture does not carry"),
           wondering("Where was this picture taken, and why are they arranged this way?",
                     "the context, which no count carries") ].
stimulus_wonderings(measured_quantity(What, _, Unit), Ws) :-
    format(atom(W1), "How was ~w measured, and to the nearest what?", [What]),
    format(atom(W2), "Would a different unit than the ~w give a friendlier number?", [Unit]),
    Ws = [ wondering(W1, "the measurement protocol, which the picture does not carry"),
           wondering(W2, "the same measure taken again in another unit"),
           wondering("How close does an estimate have to be to count as about right?",
                     "a tolerance the routine leaves to the class") ].

% --- two_displays_one_dataset ---------------------------------------------

run_move(read_dataset, _, _, Inputs, S, [display-D | S], Result) :-
    input_display(Inputs, D),
    display_summary(D, Result).

run_move(render_first, _, _, Inputs, S, [first-K | S], Result) :-
    memberchk(display-D, S),
    (   memberchk(first_kind-K, Inputs) -> true ; K = picture_graph ),
    display_pairs(D, Pairs),
    (   memberchk(key-Key, Inputs) -> true ; Key = 1 ),
    findall(Txt, ( member(C-N, Pairs), Symbols is (N + Key - 1) // Key,
                   format(atom(Txt), "~w: ~w symbol(s)", [C, Symbols]) ), Txts),
    atomic_list_concat(Txts, '; ', Body),
    format(atom(Result), "~w at ~w per symbol: ~w", [K, Key, Body]).

run_move(render_second, _, _, Inputs, S, [second-K | S], Result) :-
    memberchk(display-D, S),
    (   memberchk(second_kind-K, Inputs) -> true ; K = bar_graph ),
    display_pairs(D, Pairs),
    pairs_keys_values(Pairs, _, Counts),
    max_list(Counts, Max),
    length(Pairs, N),
    format(atom(Result), "~w with ~w bars and an axis reaching ~w", [K, N, Max]).

run_move(check_totals_agree, _, _, Inputs, S, S, Result) :-
    memberchk(display-D, S),
    display_pairs(D, Pairs),
    pairs_keys_values(Pairs, _, Counts),
    sum_list(Counts, Total),
    (   memberchk(key-Key, Inputs) -> true ; Key = 1 ),
    findall(V, ( member(_-N, Pairs), V is ((N + Key - 1) // Key) * Key ), Recovered),
    sum_list(Recovered, RecoveredTotal),
    (   RecoveredTotal =:= Total
    ->  format(atom(Result), "both renderings carry ~w in all", [Total])
    ;   format(atom(Result),
               "the bars carry ~w in all; whole symbols at ~w per symbol would report ~w, so a part symbol is needed",
               [Total, Key, RecoveredTotal])
    ).

run_move(name_reading_difference, _, _, _Inputs, S, S, Result) :-
    memberchk(first-K1, S),
    memberchk(second-K2, S),
    reading_cost(K1, C1),
    reading_cost(K2, C2),
    format(atom(Result), "~w: ~w. ~w: ~w", [K1, C1, K2, C2]).

reading_cost(picture_graph, "a count of symbols multiplied by the key") :- !.
reading_cost(scaled_picture_graph, "a count of symbols multiplied by the key, with a part symbol for an odd amount").
reading_cost(bar_graph, "one reading off the axis").
reading_cost(scaled_bar_graph, "one reading off the axis, interpolated between scale marks").
reading_cost(tally, "a count of marks in groups of five").
reading_cost(line_plot, "a count of marks stacked over a position").
reading_cost(table, "a value read from a cell").
reading_cost(_, "a reading whose cost this module does not record").


% =============================================================================
% Helpers the moves stand on
% =============================================================================

% Three display kinds. `categorical` is a count per named category, `numeric`
% is a list of measured values, `paired` is one row per item carrying a value
% under each of two headings, which is the shape a comparison table takes.
input_display(Inputs, paired(T, Rows)) :-
    memberchk(paired_rows-Rows, Inputs), !,
    (   memberchk(title-T, Inputs) -> true ; T = 'the comparison table' ).
input_display(Inputs, categorical(T, Pairs)) :-
    memberchk(categories-Pairs, Inputs), !,
    (   memberchk(title-T, Inputs) -> true ; T = 'the display' ).
input_display(Inputs, numeric(T, Values)) :-
    memberchk(values-Values, Inputs),
    (   memberchk(title-T, Inputs) -> true ; T = 'the plot' ).

display_pairs(categorical(_, Pairs), Pairs).
display_pairs(numeric(_, Values), Pairs) :-
    msort(Values, Sorted), unique_values(Sorted, Uniq),
    findall(V-N, ( member(V, Uniq), occurrences_of(V, Values, N) ), Pairs).
display_pairs(paired(_, Rows), Pairs) :-
    findall(Item-A, member(row(Item, A, _), Rows), Pairs).

display_summary(categorical(T, Pairs), Result) :-
    length(Pairs, N),
    pairs_keys_values(Pairs, _, Counts), sum_list(Counts, Total),
    format(atom(Result), "~w: ~w categories, ~w in all", [T, N, Total]).
display_summary(numeric(T, Values), Result) :-
    length(Values, N),
    min_list(Values, Lo), max_list(Values, Hi),
    value_text(Lo, LoT), value_text(Hi, HiT),
    format(atom(Result), "~w: ~w values from ~w to ~w", [T, N, LoT, HiT]).
display_summary(paired(T, Rows), Result) :-
    length(Rows, N),
    format(atom(Result), "~w: ~w items with a value under each of two headings", [T, N]).

tally_responses([], _, []).
tally_responses([C | Cs], Rs, [C-N | Rest]) :-
    aggregate_all(count, member(C, Rs), N),
    tally_responses(Cs, Rs, Rest).

occurrences_of(V, List, N) :- aggregate_all(count, member(V, List), N).

below_value(Mid, V) :- V < Mid.
above_value(Mid, V) :- V > Mid.
at_value(Mid, V) :- V =:= Mid.

unique_values([], []).
unique_values([X], [X]) :- !.
unique_values([X, X | T], U) :- !, unique_values([X | T], U).
unique_values([X, Y | T], [X | U]) :- unique_values([Y | T], U).

adjacent_pair(Pairs, A, B) :-
    append(_, [A, B | _], Pairs).

max_pair([P], P) :- !.
max_pair([_-N | T], Best) :- max_pair(T, _-M), M >= N, !, max_pair(T, Best).
max_pair([P | _], P).

min_pair([P], P) :- !.
min_pair([_-N | T], Best) :- min_pair(T, _-M), M =< N, !, min_pair(T, Best).
min_pair([P | _], P).

pairs_text(Pairs, Text) :-
    findall(T, ( member(K-V, Pairs), format(atom(T), "~w: ~w", [K, V]) ), Ts),
    atomic_list_concat(Ts, ', ', Text).

items_text(Items, Text) :-
    findall(T, ( member(I, Items), item_label(I, T) ), Ts),
    atomic_list_concat(Ts, ', ', Text).

item_label(Item-_, T) :- !, format(atom(T), "~w", [Item]).
item_label(Item, T) :- format(atom(T), "~w", [Item]).

values_text(Vs, Text) :-
    findall(T, ( member(V, Vs), value_text(V, T) ), Ts),
    atomic_list_concat(Ts, ', ', Text).

value_text(N/D, T) :- !, format(atom(T), "~w/~w", [N, D]).
value_text(V, T) :- rational(V), \+ integer(V), !,
    N is numerator(V), D is denominator(V),
    format(atom(T), "~w/~w", [N, D]).
value_text(V, T) :- format(atom(T), "~w", [V]).

qa_text(QAs, Text) :-
    findall(T, ( member(qa(Q, A), QAs), format(atom(T), "~w -> ~w", [Q, A]) ), Ts),
    atomic_list_concat(Ts, ' | ', Text).

%!  question_frame(+Inputs, -Frame) is det.
%
%   What the display's numbers count, which decides how its questions read and
%   whether adding two of them means anything.
%
%     chose           votes for a named category (the survey default)
%     counted         objects of a named kind
%     measured        marks stacked over a position on a scale
%     incommensurable one quantity reported in several units, so a sum of two
%                     entries has no referent
question_frame(Inputs, Frame) :-
    (   memberchk(question_frame-F, Inputs) -> Frame = F ; Frame = chose ).

frame_adds(incommensurable) :- !, fail.
frame_adds(_).

%!  display_questions(+Frame, +Title, +Display, -QAs) is det.
%
%   The family of questions a display settles, each answered by arithmetic over
%   the display's own numbers. Under the incommensurable frame the two summing
%   questions are replaced by the reason a sum would have no referent.
display_questions(Frame, Title, Display, QAs) :-
    display_pairs(Display, Pairs),
    findall(qa(Q, A),
            ( member(C-N, Pairs),
              per_entry_question(Frame, C, Q),
              format(atom(A), "~w", [N]) ),
            PerEntry),
    (   frame_adds(Frame), adjacent_pair(Pairs, A1-N1, B1-N2)
    ->  T1 is N1 + N2,
        pair_question(Frame, A1, B1, Qor),
        format(atom(Aor), "~w", [T1]),
        Or = [qa(Qor, Aor)]
    ;   Or = []
    ),
    comparison_question(Frame, Display, Pairs, Qcmp, Acmp),
    (   frame_adds(Frame)
    ->  pairs_keys_values(Pairs, _, Counts),
        sum_list(Counts, Total),
        total_question(Frame, Title, Qtot),
        format(atom(Atot), "~w", [Total]),
        Tot = [qa(Qtot, Atot)]
    ;   format(atom(Qtot), "What is the total across ~w?", [Title]),
        Tot = [qa(Qtot, 'no total: each entry counts a different unit, so the entries do not add')]
    ),
    append(PerEntry, Or, Q0),
    append(Q0, [qa(Qcmp, Acmp) | Tot], QAs).

per_entry_question(chose, C, Q) :- !, format(atom(Q), "How many chose ~w?", [C]).
per_entry_question(measured, C, Q) :- !,
    value_text(C, T), format(atom(Q), "How many measurements are at ~w?", [T]).
per_entry_question(_, C, Q) :- format(atom(Q), "How many ~w?", [C]).

pair_question(chose, A, B, Q) :- !, format(atom(Q), "How many chose ~w or ~w?", [A, B]).
pair_question(measured, A, B, Q) :- !,
    value_text(A, TA), value_text(B, TB),
    format(atom(Q), "How many measurements are at ~w or ~w?", [TA, TB]).
pair_question(_, A, B, Q) :- format(atom(Q), "How many ~w or ~w?", [A, B]).

total_question(chose, T, Q) :- !, format(atom(Q), "How many people are represented in ~w?", [T]).
total_question(measured, T, Q) :- !, format(atom(Q), "How many measurements are in ~w?", [T]).
total_question(_, T, Q) :- format(atom(Q), "How many in all in ~w?", [T]).

comparison_question(measured, numeric(_, Values), _, Q, A) :- !,
    min_list(Values, Lo), max_list(Values, Hi), Diff is Hi - Lo,
    value_text(Lo, LoT), value_text(Hi, HiT), value_text(Diff, DiffT),
    format(atom(Q), "What is the difference between the greatest measurement and the least?", []),
    format(atom(A), "~w, because the greatest is ~w and the least is ~w", [DiffT, HiT, LoT]).
comparison_question(Frame, _, Pairs, Q, A) :-
    max_pair(Pairs, Amax-Nmax),
    min_pair(Pairs, Amin-Nmin),
    Diff is Nmax - Nmin,
    (   Frame == chose
    ->  format(atom(Q), "How many more chose ~w than ~w?", [Amax, Amin])
    ;   format(atom(Q), "How many more ~w are there than ~w?", [Amax, Amin])
    ),
    format(atom(A), "~w", [Diff]).

%!  noticings(+Display, -Noticings) is det.
%
%   Each noticing is a sentence a computation over the display's own numbers
%   grounds, together with the name of that computation.
noticings(categorical(T, Pairs), Ns) :-
    max_pair(Pairs, Amax-Nmax),
    min_pair(Pairs, Amin-Nmin),
    pairs_keys_values(Pairs, _, Counts),
    sum_list(Counts, Total),
    length(Pairs, K),
    Diff is Nmax - Nmin,
    format(atom(S1), "~w has the most, with ~w", [Amax, Nmax]),
    format(atom(S2), "~w has the fewest, with ~w", [Amin, Nmin]),
    format(atom(S3), "~w people are represented in ~w in all", [Total, T]),
    format(atom(S4), "the tallest category runs ~w ahead of the shortest", [Diff]),
    format(atom(S5), "there are ~w categories", [K]),
    Ns0 = [ noticing(S1, "maximum over the counts"),
            noticing(S2, "minimum over the counts"),
            noticing(S3, "sum of the counts"),
            noticing(S4, "difference of maximum and minimum"),
            noticing(S5, "length of the category list") ],
    (   tied_counts(Pairs, Tied), Tied \== []
    ->  items_text(Tied, TT),
        format(atom(S6), "these categories are level with one another: ~w", [TT]),
        append(Ns0, [noticing(S6, "equality test across the counts")], Ns)
    ;   Ns = Ns0
    ).
noticings(numeric(T, Values), Ns) :-
    min_list(Values, Lo), max_list(Values, Hi),
    length(Values, N),
    Range is Hi - Lo,
    msort(Values, Sorted), unique_values(Sorted, Uniq),
    findall(C-V, ( member(V, Uniq), occurrences_of(V, Values, C) ), Counted),
    msort(Counted, Asc), last(Asc, Cmode-Vmode),
    value_text(Lo, LoT), value_text(Hi, HiT), value_text(Range, RT),
    value_text(Vmode, VmT),
    format(atom(S1), "~w values are plotted on ~w", [N, T]),
    format(atom(S2), "the shortest is ~w and the longest is ~w", [LoT, HiT]),
    format(atom(S3), "the values run over a range of ~w", [RT]),
    format(atom(S4), "~w is the most common value, with ~w marks", [VmT, Cmode]),
    length(Uniq, D),
    format(atom(S5), "the marks land on ~w distinct positions", [D]),
    Ns = [ noticing(S1, "count of the values"),
           noticing(S2, "minimum and maximum"),
           noticing(S3, "maximum minus minimum"),
           noticing(S4, "mode over the tallied values"),
           noticing(S5, "count of distinct values") ].

noticings(paired(T, Rows), Ns) :-
    findall(Ratio-Item,
            ( member(row(Item, A, B), Rows), B =\= 0, Ratio is A / B ),
            Ratios),
    Ratios \== [],
    msort(Ratios, Asc),
    Asc = [RloV-Ilo | _], last(Asc, RhiV-Ihi),
    length(Rows, N),
    aggregate_all(count, ( member(row(_, A2, B2), Rows), A2 > B2 ), Higher),
    round_two(RhiV, RhiT), round_two(RloV, RloT),
    format(atom(S1), "~w items are listed under both headings", [N]),
    format(atom(S2), "~w of them stand higher under the first heading", [Higher]),
    format(atom(S3), "~w carries the widest gap, at ~w times", [Ihi, RhiT]),
    format(atom(S4), "~w carries the narrowest gap, at ~w times", [Ilo, RloT]),
    format(atom(S5), "the gaps across ~w run from ~w to ~w times", [T, RloT, RhiT]),
    Ns = [ noticing(S1, "count of the rows"),
           noticing(S2, "row-by-row comparison of the two values"),
           noticing(S3, "maximum of the row ratios"),
           noticing(S4, "minimum of the row ratios"),
           noticing(S5, "range of the row ratios") ].

wonderings(paired(_, _), Ws) :-
    Ws = [ wondering("Would a third place fall inside this range or outside it?",
                     "the same items priced in a third place"),
           wondering("Does a wider gap on one item mean a harder month for a family?",
                     "how much of a month's money each item takes, which the table does not carry"),
           wondering("Were these values collected in the same week?",
                     "the collection date, which the table does not carry"),
           wondering("Which items were left off the list?",
                     "the full list the two places were priced on") ].

round_two(V, T) :- X is round(V * 100) / 100, format(atom(T), "~w", [X]).

tied_counts(Pairs, Tied) :-
    findall(A-B,
            ( member(A-N, Pairs), member(B, Pairs), B = Bn-N, Bn \== A ),
            Raw),
    findall(A, member(A-_, Raw), Names0),
    sort(Names0, Tied).

%!  wonderings(+Display, -Wonderings) is det.
%
%   Each wondering names the datum that would settle it. A wondering the
%   display's numbers already settle is a noticing, so it does not appear here.
wonderings(categorical(T, _), Ws) :-
    format(atom(W1), "Who was asked, and how many people were not asked?", []),
    format(atom(W2), "Would ~w come out the same with a different group?", [T]),
    W3 = "Why does the tallest category stand where it does?",
    W4 = "What would a person who chose nothing on the list have said?",
    Ws = [ wondering(W1, "the size of the group surveyed, which the display does not carry"),
           wondering(W2, "a second survey of a different group"),
           wondering(W3, "reasons, which no count carries"),
           wondering(W4, "an open response, which a fixed choice list excludes") ].
wonderings(numeric(_, _), Ws) :-
    Ws = [ wondering("What was measured, and with what tool?",
                     "the measurement protocol, which the plot does not carry"),
           wondering("Would a finer unit spread these marks further apart?",
                     "a second pass at a finer precision"),
           wondering("Is a value with no mark impossible, or just absent here?",
                     "the range the instrument could report"),
           wondering("Why does the tallest stack sit where it does?",
                     "reasons, which no count carries") ].

%!  assign_items(+Items, +Bins, +ResidueBin, -Assignment) is det.
assign_items([], _, _, []).
assign_items([I | Is], Bins, RB, [Label-Bin | Rest]) :-
    item_value(I, V),
    item_label(I, Label),
    (   member(bin(Name, Crit), Bins), bin_admits(Crit, V)
    ->  Bin = Name
    ;   Bin = RB
    ),
    assign_items(Is, Bins, RB, Rest).

item_value(_-V, V) :- !.
item_value(V, V).

%!  bin_admits(+Criterion, +Value) is semidet.
%
%   Executable bin criteria. Each is a test the module runs, never a label.
bin_admits(nearest_multiple_is(M, Target), V) :-
    number(V), Rounded is round(V / M) * M, Rounded =:= Target.
bin_admits(not_nearest_multiple_is(M, Target), V) :-
    number(V), Rounded is round(V / M) * M, Rounded =\= Target.
bin_admits(within(Lo, Hi), V) :- number(V), V >= Lo, V =< Hi.
bin_admits(less_than(X), V) :- number(V), V < X.
bin_admits(greater_than(X), V) :- number(V), V > X.
bin_admits(between_values(Lo, Hi), V) :- number(V), V >= Lo, V =< Hi.
bin_admits(closest_to(Targets, T), V) :-
    number(V), member(T, Targets),
    findall(D-C, ( member(C, Targets), D is abs(V - C) ), Ds),
    msort(Ds, [_-Best | _]), Best =:= T.
bin_admits(is_prime, V) :- integer(V), V > 1, \+ ( between(2, V, F), F * F =< V, 0 =:= V mod F ).
bin_admits(is_composite, V) :- integer(V), V > 1, \+ bin_admits(is_prime, V).
bin_admits(has_factor_pairs(K), V) :- integer(V), factor_pair_count(V, K).
bin_admits(exact_count_needed, V) :- V == exact.
bin_admits(estimate_suffices, V) :- V == estimate.
bin_admits(has_attribute(A), V) :- is_list(V), memberchk(A, V).
bin_admits(lacks_attribute(A), V) :- is_list(V), \+ memberchk(A, V).
bin_admits(equals(X), V) :- V == X.
bin_admits(one_of(Xs), V) :- memberchk(V, Xs).
bin_admits(unknown_solves_to(X), Eq) :- solve_unknown(Eq, X).
bin_admits(unknown_does_not_solve_to(X), Eq) :-
    solve_unknown(Eq, V), V =\= X.

%!  solve_unknown(+Equation, -Value) is semidet.
%
%   A first-grade part-part-whole equation with one blank. sum(A, B, C) reads
%   A + B = C and difference(C, A, B) reads C - A = B; `unknown` marks the
%   blank. The value is computed from the other two, so a card sort of
%   equations against a story runs rather than recites.
solve_unknown(sum(unknown, B, C), V) :- number(B), number(C), !, V is C - B.
solve_unknown(sum(A, unknown, C), V) :- number(A), number(C), !, V is C - A.
solve_unknown(sum(A, B, unknown), V) :- number(A), number(B), !, V is A + B.
solve_unknown(difference(unknown, B, C), V) :- number(B), number(C), !, V is B + C.
solve_unknown(difference(A, unknown, C), V) :- number(A), number(C), !, V is A - C.
solve_unknown(difference(A, B, unknown), V) :- number(A), number(B), !, V is A - B.

factor_pair_count(N, K) :-
    aggregate_all(count, ( between(1, N, A), A * A =< N, 0 =:= N mod A ), K).

%!  rule_text(+Rule, -Text) is det.
rule_text(arithmetic_sequence(Seed, Step), T) :-
    format(atom(T), "start with ~w, keep adding ~w", [Seed, Step]).
rule_text(round_to_multiple(M), T) :-
    format(atom(T), "round each value to the nearest multiple of ~w", [M]).
rule_text(place_value_count(Unit), T) :-
    format(atom(T), "count how many ~w are in each number", [Unit]).
rule_text(scale_by(F), T) :-
    format(atom(T), "multiply each value by ~w", [F]).
rule_text(multiply_pairs, "multiply the two values in each row").

%!  apply_rule(+Rule, +Count, +Inputs, -Terms) is det.
apply_rule(arithmetic_sequence(Seed, Step), N, _, Terms) :-
    findall(V, ( between(1, N, K), V is Seed + (K - 1) * Step ), Terms).
apply_rule(round_to_multiple(M), _, Inputs, Terms) :-
    memberchk(source_values-Vs, Inputs),
    findall(R, ( member(V, Vs), R is round(V / M) * M ), Terms).
apply_rule(place_value_count(Unit), _, Inputs, Terms) :-
    memberchk(source_values-Vs, Inputs),
    findall(C, ( member(V, Vs), C is V // Unit ), Terms).
apply_rule(scale_by(F), _, Inputs, Terms) :-
    memberchk(source_values-Vs, Inputs),
    findall(P, ( member(V, Vs), P is V * F ), Terms).
apply_rule(multiply_pairs, _, Inputs, Terms) :-
    memberchk(source_pairs-Ps, Inputs),
    findall(P, ( member(A-B, Ps), P is A * B ), Terms).

%!  nth_term(+Rule, +Index, +Inputs, -Value) is semidet.
nth_term(arithmetic_sequence(Seed, Step), K, _, V) :-
    !, integer(K), K >= 1, V is Seed + (K - 1) * Step.
nth_term(Rule, K, Inputs, V) :-
    apply_rule(Rule, K, Inputs, Terms),
    length(Terms, L), L >= K,
    nth1(K, Terms, V).

table_rows(Cols, Terms, Rows) :-
    length(Cols, W),
    findall(Row,
            ( nth1(I, Terms, V),
              (   W =:= 1 -> Row = row(I, [V]) ; Row = row(I, [I, V]) )
            ),
            Rows).

%!  column_relationship(+First, +Second, -Result) is det.
%
%   Test the two generated columns for a whole-number multiple in either
%   direction, checked at every row rather than at the first one. A leading
%   zero pair carries no ratio, so the anchor is the first row where both
%   columns are non-zero.
column_relationship(T1, T2, Result) :-
    (   ratio_holds(T1, T2, R)
    ->  multiple_phrase(R, second, first, Result)
    ;   ratio_holds(T2, T1, S)
    ->  multiple_phrase(S, first, second, Result)
    ;   subset_of(T2, T1)
    ->  Result = "every term of the second column appears in the first, and the first has terms the second does not"
    ;   subset_of(T1, T2)
    ->  Result = "every term of the first column appears in the second, and the second has terms the first does not"
    ;   Result = "no whole-number multiple relates the two columns at every row"
    ).

%!  ratio_holds(+From, +To, -R) is semidet.
%   R is a whole number greater than one with To[i] =:= R * From[i] at every i.
ratio_holds(From, To, R) :-
    same_length(From, To),
    nth1(I, From, A), A =\= 0, nth1(I, To, B), B =\= 0, !,
    0 =:= B mod A,
    R is B // A, R > 1,
    forall( ( nth1(J, From, X), nth1(J, To, Y) ), Y =:= R * X ).

multiple_phrase(2, Which, Other, Result) :- !,
    format(atom(Result), "each term of the ~w column is double the matching term of the ~w", [Which, Other]).
multiple_phrase(R, Which, Other, Result) :-
    format(atom(Result), "each term of the ~w column is ~w times the matching term of the ~w", [Which, R, Other]).

subset_of([], _).
subset_of([X | Xs], L) :- memberchk(X, L), subset_of(Xs, L).

consecutive_difference([A, B | Rest], Result) :-
    D is B - A,
    (   forall( append(_, [X, Y | _], [A, B | Rest]), Y - X =:= D )
    ->  format(atom(Result), "the terms step by ~w each time", [D])
    ;   Result = "the step between terms is not constant"
    ).
consecutive_difference(_, "the column is too short to carry a step").

%!  constraint_text(+Constraint, -Text) is det.
constraint_text(perimeter_pairs(P), T) :-
    format(atom(T), "whole-number length and width with a perimeter of ~w", [P]).
constraint_text(rectangles_with_area(A), T) :-
    format(atom(T), "whole-number side lengths with an area of ~w", [A]).
constraint_text(quotient_band(more_than_one, Total), T) :-
    format(atom(T), "a number of sharers below ~w, so each share is more than one", [Total]).
constraint_text(quotient_band(exactly_one, Total), T) :-
    format(atom(T), "a number of sharers equal to ~w, so each share is exactly one", [Total]).
constraint_text(quotient_band(less_than_one, Total), T) :-
    format(atom(T), "a number of sharers above ~w, so each share is less than one", [Total]).
constraint_text(coin_groups_for(C), T) :-
    format(atom(T), "groups of coins worth ~w cents", [C]).

%!  solutions_for(+Constraint, +Count, -Solutions) is det.
% Perimeter rows keep both orders, because the guide's own five rows for a
% perimeter of 12 list 5 by 1 and 1 by 5 as separate rows. Area rows dedupe,
% because the guide states there that a pair counts once.
solutions_for(perimeter_pairs(P), N, Sols) :-
    Half is P // 2,
    findall(L-W, ( between(1, Half, L), W is Half - L, W > 0 ), All),
    take_up_to(N, All, Sols).
solutions_for(rectangles_with_area(A), N, Sols) :-
    findall(L-W, ( between(1, A, L), L * L =< A, 0 =:= A mod L, W is A // L ), All),
    take_up_to(N, All, Sols).
solutions_for(quotient_band(Band, Total), N, Sols) :-
    band_range(Band, Total, Lo, Hi),
    findall(People-Total, between(Lo, Hi, People), All),
    take_up_to(N, All, Sols).
solutions_for(coin_groups_for(C), N, Sols) :-
    findall(Group, coin_group(C, Group), All0),
    sort(All0, All),
    take_up_to(N, All, Sols).

band_range(more_than_one, Total, 1, Hi) :- Hi is max(1, Total - 1).
band_range(exactly_one, Total, Total, Total).
band_range(less_than_one, Total, Lo, Hi) :- Lo is Total + 1, Hi is Total + 6.

coin_group(Cents, group(Q, D, Nk, P)) :-
    between(0, 4, Q), between(0, 10, D), between(0, 20, Nk),
    Rest is Cents - (25 * Q + 10 * D + 5 * Nk),
    Rest >= 0, Rest =< 4, P = Rest,
    Cents =:= 25 * Q + 10 * D + 5 * Nk + P.

take_up_to(N, List, Taken) :-
    length(List, L),
    (   L =< N -> Taken = List ; length(Taken, N), append(Taken, _, List) ).

solutions_text(Sols, Text) :-
    findall(T, ( member(S, Sols), solution_text(S, T) ), Ts),
    atomic_list_concat(Ts, '; ', Text).

solution_text(A-B, T) :- !, format(atom(T), "~w and ~w", [A, B]).
solution_text(group(Q, D, N, P), T) :- !,
    format(atom(T), "~w quarter(s), ~w dime(s), ~w nickel(s), ~w penn(y/ies)", [Q, D, N, P]).
solution_text(S, T) :- format(atom(T), "~w", [S]).

%!  satisfies_constraint(+Constraint, +Solution) is semidet.
satisfies_constraint(perimeter_pairs(P), L-W) :- P =:= 2 * (L + W).
satisfies_constraint(rectangles_with_area(A), L-W) :- A =:= L * W.
satisfies_constraint(quotient_band(more_than_one, Total), People-Total) :- Total > People.
satisfies_constraint(quotient_band(exactly_one, Total), People-Total) :- Total =:= People.
satisfies_constraint(quotient_band(less_than_one, Total), People-Total) :- Total < People.
satisfies_constraint(coin_groups_for(C), group(Q, D, N, P)) :-
    C =:= 25 * Q + 10 * D + 5 * N + P.

%!  claim_holds(+Test, +Display) is semidet.
%
%   Executable claim tests. Each runs against the record; none is a stored
%   verdict.
claim_holds(count_is(C, N), D) :- display_pairs(D, Pairs), memberchk(C-N, Pairs).
claim_holds(total_is(N), D) :-
    display_pairs(D, Pairs), pairs_keys_values(Pairs, _, Cs), sum_list(Cs, N).
claim_holds(sum_is(Cats, N), D) :-
    display_pairs(D, Pairs),
    findall(V, ( member(C, Cats), memberchk(C-V, Pairs) ), Vs),
    length(Vs, L), length(Cats, L),
    sum_list(Vs, N).
claim_holds(difference_is(A, B, N), D) :-
    display_pairs(D, Pairs), memberchk(A-Na, Pairs), memberchk(B-Nb, Pairs),
    N =:= Na - Nb.
claim_holds(most_is(C), D) :- display_pairs(D, Pairs), max_pair(Pairs, C-_).
claim_holds(fewest_is(C), D) :- display_pairs(D, Pairs), min_pair(Pairs, C-_).
claim_holds(estimate_band(too_low, X), D) :- display_total(D, T), X < T.
claim_holds(estimate_band(about_right, X), D) :-
    display_total(D, T), Lo is T - max(1, T // 5), Hi is T + max(1, T // 5),
    X >= Lo, X =< Hi.
claim_holds(estimate_band(too_high, X), D) :- display_total(D, T), X > T.

display_total(D, T) :-
    display_pairs(D, Pairs), pairs_keys_values(Pairs, _, Cs), sum_list(Cs, T).

%!  repair_claim(+Test, +Display, -Repaired) is det.
%
%   A refused claim is rewritten into the nearest claim the record accepts.
repair_claim(count_is(C, _), D, R) :-
    display_pairs(D, Pairs), memberchk(C-N, Pairs), !,
    format(atom(R), "there are ~w for ~w", [N, C]).
repair_claim(total_is(_), D, R) :-
    !, display_total(D, T), format(atom(R), "there are ~w in all", [T]).
repair_claim(sum_is(Cats, _), D, R) :-
    display_pairs(D, Pairs),
    findall(V, ( member(C, Cats), memberchk(C-V, Pairs) ), Vs), Vs \== [], !,
    sum_list(Vs, S), atomic_list_concat(Cats, ' or ', CT),
    format(atom(R), "~w chose ~w", [S, CT]).
repair_claim(difference_is(A, B, _), D, R) :-
    display_pairs(D, Pairs), memberchk(A-Na, Pairs), memberchk(B-Nb, Pairs), !,
    Diff is Na - Nb,
    format(atom(R), "~w more chose ~w than ~w", [Diff, A, B]).
repair_claim(most_is(_), D, R) :-
    !, display_pairs(D, Pairs), max_pair(Pairs, C-N),
    format(atom(R), "~w has the most, with ~w", [C, N]).
repair_claim(fewest_is(_), D, R) :-
    !, display_pairs(D, Pairs), min_pair(Pairs, C-N),
    format(atom(R), "~w has the fewest, with ~w", [C, N]).
repair_claim(estimate_band(Band, _), D, R) :-
    !, display_total(D, T),
    format(atom(R), "the count is ~w, so a ~w estimate has to sit on the other side of it", [T, Band]).
repair_claim(Test, _, R) :-
    format(atom(R), "the record refuses ~w and this module carries no repair for that claim shape", [Test]).

%!  round_to(+Value, +Precision, -Rounded) is det.
%
%   Precision is a unit fraction 1/D or a whole number. Values are carried as
%   rationals so a quarter-inch reading stays a quarter inch.
round_to(V, 1/D, R) :- !, X is V * D, K is round(X), R is K rdiv D.
round_to(V, P, R) :- number(P), P > 0, X is V / P, K is round(X), R is K * P.

precision_text(1/D, T) :- !, format(atom(T), "1/~w", [D]).
precision_text(P, T) :- format(atom(T), "~w", [P]).

%!  scale_cost(+Pairs, +Scale, -Marks, -Remainder) is det.
%
%   How many whole marks the scale needs across every category, and how much
%   the whole marks leave uncarried.
scale_cost(Pairs, Scale, Marks, Remainder, PartMarks) :-
    Scale > 0,
    findall(M-R, ( member(_-N, Pairs), M is N // Scale, R is N mod Scale ), MRs),
    pairs_keys_values(MRs, Ms, Rs),
    sum_list(Ms, Marks),
    sum_list(Rs, Remainder),
    aggregate_all(count, ( member(R, Rs), R > 0 ), PartMarks).


% =============================================================================
% Artifacts
% =============================================================================

%!  form_artifact(+Form, +Inputs, +State, -Artifact) is det.
%
%   A scene term routed to an existing renderer where the doing produces a
%   picture, a printed record where it produces a record.
form_artifact(survey_tally_display, _, State, scene(data_display_scene, bar_chart(Tally))) :-
    memberchk(tally-Tally, State), Tally \== [], !.
form_artifact(display_question_set, Inputs, State, Artifact) :-
    memberchk(display-D, State), !,
    (   memberchk(title-T, Inputs) -> true ; T = 'the display' ),
    question_frame(Inputs, Frame),
    display_questions(Frame, T, D, QAs),
    findall(row(Q, A), member(qa(Q, A), QAs), Rows),
    Artifact = printed(record(T, Rows)).
form_artifact(notice_and_wonder, Inputs, State, printed(record(Title, Rows))) :-
    memberchk(noticings-Ns, State),
    memberchk(wonderings-Ws, State), !,
    (   memberchk(title-Title, Inputs) -> true ; Title = 'notice and wonder' ),
    findall(row('I notice', S), member(noticing(S, _), Ns), R1),
    findall(row('I wonder', S), member(wondering(S, _), Ws), R2),
    append(R1, R2, Rows).
form_artifact(sort_into_bins, _, State, printed(record('sorted bins', Rows))) :-
    memberchk(assignment-As, State), !,
    findall(row(Item, Bin), member(Item-Bin, As), Rows).
form_artifact(table_from_rule, Inputs, State, printed(record(Title, Rows))) :-
    memberchk(terms-Terms, State), !,
    (   memberchk(title-Title, Inputs) -> true ; Title = 'generated table' ),
    (   memberchk(second_terms-Terms2, State)
    ->  findall(row(Label, Cell),
                ( nth1(I, Terms, V), nth1(I, Terms2, W),
                  source_label(Inputs, I, V, Label),
                  format(atom(Cell), "~w and ~w", [V, W]) ),
                Rows)
    ;   findall(row(Label, V),
                ( nth1(I, Terms, V), source_label(Inputs, I, V, Label) ),
                Rows)
    ).

%!  source_label(+Inputs, +Index, +Value, -Label) is det.
%   A generated row is labelled by the value the rule was applied to where one
%   exists, and by its position otherwise.
source_label(Inputs, I, _, Label) :-
    memberchk(source_values-Vs, Inputs), nth1(I, Vs, S), !,
    format(atom(Label), "~w", [S]).
source_label(Inputs, I, _, Label) :-
    memberchk(source_pairs-Ps, Inputs), nth1(I, Ps, A-B), !,
    format(atom(Label), "~w by ~w", [A, B]).
source_label(_, I, _, I).
form_artifact(constraint_fill_table, Inputs, State, printed(record(Title, Rows))) :-
    memberchk(solutions-Sols, State), !,
    (   memberchk(title-Title, Inputs) -> true ; Title = 'rows satisfying the constraint' ),
    findall(row(I, T), ( nth1(I, Sols, S), solution_text(S, T) ), Rows).
form_artifact(adjudicate_against_data, _, State, printed(record('claims and rulings', Rows))) :-
    memberchk(rulings-Rs, State), !,
    findall(row(T, H), member(ruling(T, _, H), Rs), Rows).
form_artifact(measure_then_plot, _, State, scene(data_display_scene, dot_plot(Ints))) :-
    memberchk(plot-Vs, State), Vs \== [],
    plottable_integers(Vs, Ints), !.
form_artifact(measure_then_plot, _, State, printed(record('measurements', Rows))) :-
    memberchk(rounded-Rs, State), !,
    findall(row(N, T), ( member(N-V, Rs), value_text(V, T) ), Rows).
form_artifact(scale_choice, _, State, printed(record('scale costs', Rows))) :-
    memberchk(costs-Costs, State), !,
    findall(row(Sc, T),
            ( member(cost(Sc, M, R, P), Costs),
              format(atom(T), "~w whole marks, ~w uncarried, ~w categories needing a part mark", [M, R, P]) ),
            Rows).
form_artifact(design_and_run_a_routine, _, State, printed(record('the routine, ready to run', Rows))) :-
    memberchk(protocol-Steps, State),
    memberchk(noticings-Ns, State),
    memberchk(wonderings-Ws, State), !,
    findall(row(Label, Step),
            ( nth1(I, Steps, Step), format(atom(Label), "step ~w", [I]) ),
            R0),
    findall(row('drafted: I notice', S), member(noticing(S, _), Ns), R1),
    findall(row('drafted: I wonder', S), member(wondering(S, _), Ws), R2),
    append(R0, R1, R01), append(R01, R2, Rows).
form_artifact(two_displays_one_dataset, _, State, scene(data_display_scene, bar_chart(Pairs))) :-
    memberchk(display-D, State), display_pairs(D, Pairs), Pairs \== [], !.
form_artifact(_, _, _, none).

%!  plottable_integers(+Values, -Integers) is semidet.
%
%   The dot-plot renderer takes integer positions. A quarter-inch reading is
%   carried to the plot by its numerator over the common denominator, so the
%   spacing is preserved and the axis labels are quarter units.
plottable_integers(Vs, Ints) :-
    maplist(rational_numerator_over(4), Vs, Ints).

rational_numerator_over(D, V, N) :-
    X is V * D, N is round(X), abs(X - N) < 1.0e-9.

%!  artifact_renders(+Artifact, -Status) is det.
%
%   Run the named renderer on the scene term and report whether it produced
%   frames. A scene term that a renderer refuses is a defect, not a picture.
artifact_renders(scene(data_display_scene, Term), Status) :-
    !,
    (   catch(data_display_render_json(Term, Dict), _, fail)
    ->  (   get_dict(error, Dict, Err)
        ->  Status = renderer_refused(Err)
        ;   get_dict(frames, Dict, Frames), Frames \== []
        ->  length(Frames, N), Status = frames(N)
        ;   Status = renderer_returned_no_frames
        )
    ;   Status = renderer_threw
    ).
artifact_renders(printed(record(_, Rows)), rows(N)) :- !, length(Rows, N).
artifact_renders(none, no_artifact) :- !.
artifact_renders(_, unrecognized_artifact).


% =============================================================================
% Serialization: the display seam and the emission row
% =============================================================================

%!  enactment_trace_dict(+Enactment, -Dict) is det.
%
%   The shape strategy_trace_dict/3 emits, so an enactment reaches the console
%   and the MCP surface along the path a strategy trace already takes. `steps`
%   carries _{n, label, value}; the enactment keys are additive.
enactment_trace_dict(E, Dict) :-
    E = enactment(Lesson, Form, _Inputs, Steps, Artifact),
    enactment_verdict(E, Verdict),
    enactment_not_claimed(E, NotClaimed),
    format(string(LessonStr), "~w", [Lesson]),
    format(string(FormStr), "~w", [Form]),
    verdict_string(Verdict, VerdictStr),
    findall(_{n: I, label: VerbStr, value: ValStr},
            ( member(step(I, Verb, Operand, Result), Steps),
              format(string(VerbStr), "~w", [Verb]),
              format(string(ValStr), "~w: ~w", [Operand, Result]) ),
            StepDicts),
    last(Steps, step(_, _, _, LastResult)),
    format(string(ResultStr), "~w", [LastResult]),
    artifact_dict(Artifact, ArtifactDict),
    Dict = _{ strategy: FormStr,
              ok: true,
              representation: "enactment",
              result: ResultStr,
              steps: StepDicts,
              jumps: [],
              note: "Lesson enactment: the structure the lesson asks a class to move through, run on the lesson's inputs. Not an arithmetic strategy trace.",
              lesson: LessonStr,
              form: FormStr,
              verdict: VerdictStr,
              artifact: ArtifactDict,
              what_it_does_not_claim: NotClaimed }.

verdict_string(well_formed, "well_formed") :- !.
verdict_string(partial(R), S) :- !, format(string(S), "partial: ~w", [R]).
verdict_string(refused(R), S) :- !, format(string(S), "refused: ~w", [R]).
verdict_string(V, S) :- format(string(S), "~w", [V]).

artifact_dict(scene(Renderer, Term), _{kind: "scene", renderer: RStr, term: TStr}) :-
    !, term_string(Renderer, RStr), term_string(Term, TStr).
artifact_dict(scene(Renderer, Term, _), _{kind: "scene", renderer: RStr, term: TStr}) :-
    !, term_string(Renderer, RStr), term_string(Term, TStr).
artifact_dict(printed(record(Title, Rows)), _{kind: "printed", record: Rec}) :-
    !, format(string(TitleStr), "~w", [Title]),
    findall(_{label: L, value: V},
            ( member(row(L0, V0), Rows),
              format(string(L), "~w", [L0]), format(string(V), "~w", [V0]) ),
            RowDicts),
    Rec = _{title: TitleStr, rows: RowDicts}.
artifact_dict(none, _{kind: "printed", record: _{title: "no artifact", rows: []}}).

%!  print_enactment(+Enactment) is det.
%
%   The readable form: what the machine did, step by step, with its verdict.
print_enactment(E) :-
    E = enactment(Lesson, Form, _, Steps, Artifact),
    enactment_verdict(E, Verdict),
    enactment_not_claimed(E, NotClaimed),
    once(lesson_enactment_form(Lesson, Form, evidence(Src, Line, Text))),
    format("~w  form: ~w~n", [Lesson, Form]),
    format("  read from ~w:~w~n", [Src, Line]),
    format("  \"~w\"~n", [Text]),
    forall(member(step(I, Verb, Operand, Result), Steps),
           format("  ~w. ~w(~w)~n     ~w~n", [I, Verb, Operand, Result])),
    artifact_renders(Artifact, Status),
    format("  artifact: ~w  [~w]~n", [Artifact, Status]),
    format("  verdict: ~w~n", [Verdict]),
    format("  does not claim: ~w~n~n", [NotClaimed]).


% =============================================================================
% Coverage
% =============================================================================

%!  lane_coverage(-Dict) is det.
%
%   Measured by running every lesson this lane names. Nothing here is
%   estimated: a lesson counts as enacted when enact/3 returns an enactment
%   whose artifact its renderer accepts.
lane_coverage(_{ subclass_population: SubPop,
                 handed_over: HandedOver,
                 population: Pop,
                 enacted: Enacted,
                 well_formed: WF,
                 partial_on_stand_in_data: Partial,
                 refused: Refused,
                 not_enacted: NotEnacted,
                 not_enacted_lessons: Missing,
                 forms: FormCount,
                 forms_used: FormsUsed }) :-
    findall(L, lane_lesson(L, _, _), Ls0),
    sort(Ls0, Ls),
    length(Ls, Pop),
    HandedOver = ['IM-G3-U8-L12'],
    length(HandedOver, NH),
    SubPop is Pop - NH,
    findall(L-V-F,
            ( member(L, Ls),
              once(( catch(enact_lesson(L, E), _, fail),
                     enactment_ok(E),
                     enactment_verdict(E, V),
                     E = enactment(_, F, _, _, _) )) ),
            Results),
    length(Results, Enacted),
    aggregate_all(count, member(_-well_formed-_, Results), WF),
    aggregate_all(count, member(_-partial(_)-_, Results), Partial),
    aggregate_all(count, member(_-refused(_)-_, Results), Refused),
    findall(L, ( member(L, Ls), \+ member(L-_-_, Results) ), Missing),
    length(Missing, NotEnacted),
    aggregate_all(count, enactment_form(_, _, _), FormCount),
    findall(F, member(_-_-F, Results), Fs0),
    msort(Fs0, Fs1),
    findall(F-N, ( member(F, Fs1), aggregate_all(count, member(F, Fs1), N) ), Fs2),
    sort(Fs2, FormsUsed).

enactment_ok(E) :-
    E = enactment(_, _, _, Steps, Artifact),
    Steps \== [],
    artifact_renders(Artifact, Status),
    Status \== no_artifact,
    Status \== renderer_threw,
    Status \== unrecognized_artifact,
    \+ Status = renderer_refused(_),
    enactment_verdict(E, V),
    V \= refused(_).


:- include(im_lessons('enactment/support/data_representation_lessons')).


% =============================================================================
% Registration on curriculum/im/lesson_enactment.pl
% =============================================================================
%
% The lane fact, the forms, the lesson rows and the moves are registered where
% they are declared above. What follows is the rest of the join: the run, the
% verdict, the sentence, and the provenance.
%
% The lane no longer writes its own emission file. `lesson_enactment` owns
% `data/learningcommons/derived/lesson_enactments/data_representation.jsonl`
% and writes every lane's rows in one shape.

:- use_module(im_lessons(lesson_enactment), []).

:- multifile
       lesson_enactment:enactment_run/3,
       lesson_enactment:enactment_lane_verdict/2,
       lesson_enactment:enactment_disclaimer/2,
       lesson_enactment:enactment_input_provenance/3.

% Every clause below is guarded on this lane's own forms. Without the guard a
% lane's verdict clause answers for every other lane's enactments too: these are
% multifile predicates in one namespace, and each lane's verdict predicate is
% total over enactment terms, so whichever lane loaded first would decide every
% verdict on the rung. The gate's list-artifact rule caught it, on an enactment
% of a fraction form reading well_formed out of a lane that never heard of it.

lesson_enactment:enactment_run(Form, Lesson, Enactment) :-
    enactment_form(Form, _, _),
    once(( lesson_inputs(Lesson, Form, Inputs, _Provenance),
           enact(Lesson, [form-Form | Inputs], Enactment) )).

lesson_enactment:enactment_lane_verdict(Enactment, Verdict) :-
    Enactment = enactment(_, Form, _, _, _),
    enactment_form(Form, _, _),
    once(enactment_verdict(Enactment, Verdict)).

lesson_enactment:enactment_disclaimer(Form, Sentence) :-
    form_not_claimed(Form, Sentence).

% The third provenance value, and the lesson class that made it necessary.
%
% Four lessons here run on numbers the guide prints in its own Student Response
% section as ONE worked sample of a task whose answer is open: four people
% sharing seven pounds, a class of twenty voting on a favourite season. Calling
% those `curriculum` says the guide settled the answer, and it did not. Calling
% them `machine_supplied` says this module chose the numbers, and it did not.
% They are curricular values carrying one instance of an open task, and
% `curriculum_sample` is that reading. It does not cap the verdict, because no
% machine chose the number; the lane's own verdict already reports the sample.
lesson_enactment:enactment_input_provenance(Form, Lesson, Provenance) :-
    once(lesson_inputs(Lesson, Form, Inputs, Declared)),
    (   memberchk(input_provenance-machine_supplied, Declared)
    ->  Provenance = machine_supplied
    ;   memberchk(partial-sample_response_and_not_a_class_record, Inputs)
    ->  Provenance = curriculum_sample
    ;   Provenance = curriculum
    ).
