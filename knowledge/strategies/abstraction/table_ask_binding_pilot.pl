:- encoding(utf8).
/** <module> Bind anchored table asks to routed grade 8 machines
 *
 * A table route licenses one machine kind.  This module binds that kind only
 * to an anchored directive or question in the same answer genre, then hands
 * the routed input to the grade 8 action seam.  It reads no sentence into
 * facts and computes no table cell itself.
 */

:- module(table_ask_binding_pilot,
          [ table_ask/3,
            ask_genre/2,
            routed_table_completion/3,
            check_table_ask_binding/0
          ]).

:- use_module(library(http/json)).
:- use_module(strategies('math/g8_action_pairs'),
              [g8_decode_input/2, run_g8_action/4]).

%!  table_ask(+Kind, +Sentences, -Ask) is semidet.
%
%   Ask is the first anchored directive or question whose surface matches the
%   routed machine's answer genre.  Sentences retain the order supplied by the
%   language harness.
table_ask(Kind, Sentences, ask(Index, Surface, Spans)) :-
    member(sentence(Index, Surface, Form, Spans), Sentences),
    memberchk(Form, [directive,question]),
    Spans = [_|_],
    ask_genre(Kind, Surface),
    !.

%!  ask_genre(+Kind, +Text) is semidet.
%
%   Genre words come from the routed kind and its machine vocabulary.  A
%   hyphenated compound remains one token, so `two-way` occupies the single
%   optional position between `the` and `table`.
ask_genre(complete_two_way_table, Text) :-
    surface_tokens(Text, Tokens),
    append(_, ["complete","the"|After], Tokens),
    (   After = ["table"|_]
    ;   After = [_Modifier,"table"|_]
    ),
    !.
ask_genre(rate_of_change_from_two_observations, Text) :-
    surface_tokens(Text, Tokens),
    (   memberchk("rate", Tokens)
    ;   memberchk("slope", Tokens)
    ),
    !.

surface_tokens(Text, Tokens) :-
    text_string(Text, String),
    string_lower(String, Lower),
    split_string(Lower,
                 " \t\n\r.,;:!?()[]{}\"'",
                 " \t\n\r.,;:!?()[]{}\"'",
                 Tokens).

text_string(Text, Text) :-
    string(Text),
    !.
text_string(Text, String) :-
    atom(Text),
    atom_string(Text, String).

%!  routed_table_completion(+Route, +Sentences, -Reply) is semidet.
%
%   The ask is bound before the JSON input is decoded, so an absent or
%   unanchored ask cannot run the machine.  Payload and refusal reason are the
%   machine's own result terms.
routed_table_completion(
    route(grade8, Kind, InputJSON,
          because(table_reading(TableId), _Shape)),
    Sentences,
    Reply) :-
    table_ask(Kind, Sentences, Ask),
    atom_json_dict(InputJSON, InputDict, [value_string_as(string)]),
    g8_decode_input(InputDict, Decoded),
    run_g8_action(Kind, Decoded, Outcome, _Trace),
    table_outcome_reply(Outcome, Ask, Kind, TableId, Reply).

table_outcome_reply(action_outcome(Kind, Properties), Ask, Kind, TableId,
                    table_completion(completed, Ask, Kind, TableId, Payload)) :-
    memberchk(classification(productive), Properties),
    memberchk(result(Payload), Properties),
    !.
table_outcome_reply(action_outcome(Kind, Properties), Ask, Kind, TableId,
                    table_completion(refused, Ask, Kind, TableId, Reason)) :-
    memberchk(classification(refusal), Properties),
    memberchk(result(refused(Reason)), Properties),
    !.

check_table_ask_binding :-
    fixture_complete_route(CompleteRoute),
    FixtureSpan = span('fixtures/b6c94497.md', 6073, 6144),
    CompleteSentences = [
        sentence(3, "Here is a two-way table that gives some results from the survey.",
                 declarative, [FixtureSpan]),
        sentence(4, "Complete the table, assuming that all students answered both questions.",
                 directive, [FixtureSpan])
    ],
    routed_table_completion(CompleteRoute, CompleteSentences, CompleteReply),
    CompleteReply = table_completion(
        completed, ask(4, _, [FixtureSpan]), complete_two_way_table,
        fixture_table, CompletePayload),
    term_text(CompletePayload, CompleteText),
    require_equal(CompleteText, "completed_table([[5,11],[5,4]])",
                  productive_answer_text),

    UnanchoredSentences = [
        sentence(4, "Complete the table, assuming that all students answered both questions.",
                 directive, [])
    ],
    CompleteRoute = route(grade8, complete_two_way_table, _InputJSON, Because),
    BadJSONRoute = route(grade8, complete_two_way_table, "{not json", Because),
    require_failure(
        routed_table_completion(BadJSONRoute, UnanchoredSentences, _),
        unanchored_ask_must_not_bind_or_run),

    fixture_refusal_route(RefusalRoute),
    RefusalSentences = [
        sentence(2, "Complete the two-way table to show the data from the bar graph.",
                 directive, [span('fixtures/dbf89012.md', 0, 63)])
    ],
    routed_table_completion(RefusalRoute, RefusalSentences, RefusalReply),
    require_equal(
        RefusalReply,
        table_completion(
            refused,
            ask(2, "Complete the two-way table to show the data from the bar graph.",
                [span('fixtures/dbf89012.md', 0, 63)]),
            complete_two_way_table, fixture_table,
            table_does_not_determine_its_missing_cells),
        underdetermined_table_refusal),

    RateSentences = [
        sentence(0, "What is the rate of change?", question,
                 [span('fixtures/rate.md', 0, 27)])
    ],
    table_ask(rate_of_change_from_two_observations, RateSentences,
              ask(0, "What is the rate of change?", _)),
    require_failure(
        table_ask(rate_of_change_from_two_observations,
                  [sentence(0, "Who won the race?", question,
                            [span('fixtures/race.md', 0, 17)])], _),
        comparison_question_is_not_a_rate_ask),
    require_failure(
        table_ask(rate_of_change_from_two_observations,
                  [sentence(0, "Create a graph that represents this situation.",
                            directive, [span('fixtures/graph.md', 0, 46)])], _),
        graph_directive_is_not_a_rate_ask),
    require_failure(
        table_ask(complete_two_way_table,
                  [sentence(0, "Complete the sentence using the table.", directive,
                            [span('fixtures/sentence.md', 0, 38)])], _),
        sentence_completion_is_not_a_table_completion_ask),
    format('check_table_ask_binding: ok productive=completed_table([[5,11],[5,4]]) refusal=table_does_not_determine_its_missing_cells rate_fixture=bound~n').

fixture_complete_route(
    route(grade8, complete_two_way_table, InputJSON,
          because(table_reading(fixture_table),
                  shape(columns(4),rows(3))))) :-
    InputJSON = "{\"cells\":[[5,\"?\"],[\"?\",\"?\"]],\"column_totals\":[\"?\",15],\"columns\":[\"plays instrument\",\"does not play instrument\"],\"grand_total\":25,\"kind\":\"two_way_table_partial\",\"row_totals\":[16,\"?\"],\"rows\":[\"plays sport\",\"does not play sport\"]}".

fixture_refusal_route(
    route(grade8, complete_two_way_table, InputJSON,
          because(table_reading(fixture_table),
                  shape(columns(4),rows(3))))) :-
    InputJSON = "{\"cells\":[[\"?\",16],[5,\"?\"]],\"column_totals\":[\"?\",\"?\"],\"columns\":[\"plays an instrument\",\"does not play an instrument\"],\"grand_total\":25,\"kind\":\"two_way_table_partial\",\"row_totals\":[\"?\",\"?\"],\"rows\":[\"plays a sport\",\"does not play a sport\"]}".

term_text(Term, Text) :-
    term_string(Term, Text, [quoted(true),numbervars(true)]).

require_equal(Actual, Expected, _Label) :-
    Actual == Expected,
    !.
require_equal(Actual, Expected, Label) :-
    throw(error(check_failed(Label, expected(Expected), actual(Actual)),
                check_table_ask_binding/0)).

require_failure(Goal, _Label) :-
    \+ call(Goal),
    !.
require_failure(_Goal, Label) :-
    throw(error(check_failed(Label, expected(failure), actual(success)),
                check_table_ask_binding/0)).
