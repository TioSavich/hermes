:- module(solution_step_check, [ check_solution_steps/2 ]).

:- use_module(hermes(math_claim_checker), [ check_math_claim/2 ]).
:- use_module(hermes(math_claim_language), [ math_readings_in_text/2 ]).
:- use_module(library(error), [ must_be/2 ]).
:- use_module(library(lists), [ member/2, min_list/2 ]).
:- use_module(library(pcre), [ re_matchsub/4 ]).

%!  check_solution_steps(+Text, -Report) is det.
%
%   Split numbered solution text into steps, read explicit claims with
%   math_claim_language, and adjudicate each registered claim. Empty and
%   unreadable steps remain not_checked.
check_solution_steps(Text, Report) :-
    must_be(text, Text),
    solution_text_string(Text, String),
    solution_steps(String, Steps),
    maplist(check_step, Steps, StepReports),
    report_counts(StepReports, CheckedCount, RefutedCount),
    first_refuted_step(StepReports, FirstRefuted),
    Report = _{
        first_refuted_step: FirstRefuted,
        checked_equations: CheckedCount,
        refuted_equations: RefutedCount,
        steps: StepReports
    }.

solution_text_string(Text, Text) :-
    string(Text),
    !.
solution_text_string(Text, String) :-
    atom(Text),
    !,
    atom_string(Text, String).
solution_text_string(Text, String) :-
    catch(string_codes(String, Text), _, fail),
    !.
solution_text_string(Text, String) :-
    string_chars(String, Text).

solution_steps(Text, Steps) :-
    split_string(Text, "\n", "\r \t", Lines0),
    exclude(==(""), Lines0, Lines),
    (   member(Line, Lines),
        numbered_step_line(Line, _, _)
    ->  collect_numbered_steps(Lines, none, Steps)
    ;   index_step_lines(Lines, 1, Steps)
    ).

numbered_step_line(Line, Index, Body) :-
    re_matchsub(
        '^[[:space:]]*step[[:space:]]+(?<index>[0-9]+)[[:space:]]*(?:[-:.][[:space:]]*|[)][[:space:]]*|[[:space:]]+)(?<body>.*)$',
        Line,
        Match,
        [caseless(true)]),
    number_string(Index, Match.index),
    Body = Match.body.

collect_numbered_steps([], Current, Steps) :-
    close_numbered_step(Current, Steps, []).
collect_numbered_steps([Line|Lines], Current, Steps) :-
    (   numbered_step_line(Line, Index, Body)
    ->  close_numbered_step(Current, Steps, Tail),
        collect_numbered_steps(Lines, current(Index, [Body]), Tail)
    ;   Current = current(Index, RevParts)
    ->  collect_numbered_steps(
            Lines, current(Index, [Line|RevParts]), Steps)
    ;   collect_numbered_steps(Lines, none, Steps)
    ).

close_numbered_step(none, Steps, Steps).
close_numbered_step(current(Index, RevParts),
                    [step(Index, Text)|Steps], Steps) :-
    reverse(RevParts, Parts),
    atomics_to_string(Parts, " ", Text).

index_step_lines([], _, []).
index_step_lines([Text|Texts], Index, [step(Index, Text)|Steps]) :-
    NextIndex is Index + 1,
    index_step_lines(Texts, NextIndex, Steps).

check_step(step(Index, Text), Report) :-
    math_readings_in_text(Text, Readings),
    maplist(check_reading, Readings, EquationReports),
    step_verdict(EquationReports, Verdict),
    Report = _{
        index: Index,
        verdict: Verdict,
        equations: EquationReports
    }.

check_reading(Reading, Report) :-
    Claim = Reading.claim,
    Span = Reading.normalized_surface,
    catch(check_math_claim(Claim, Checked), _, not_checked_dict(Checked)),
    checked_equation_fields(Checked, Verdict, Trace),
    Report = _{span: Span, verdict: Verdict, trace: Trace}.

not_checked_dict(_{verdict: "not_checked"}).

checked_equation_fields(Checked, Verdict, Trace) :-
    (   get_dict(verdict, Checked, CheckedVerdict),
        memberchk(CheckedVerdict, ["holds", "refuted", "not_checked"])
    ->  Verdict = CheckedVerdict
    ;   Verdict = "not_checked"
    ),
    (   get_dict(trace, Checked, CheckedTrace),
        is_list(CheckedTrace)
    ->  Trace = CheckedTrace
    ;   Trace = []
    ).

step_verdict(EquationReports, "refuted") :-
    member(Equation, EquationReports),
    get_dict(verdict, Equation, "refuted"),
    !.
step_verdict(EquationReports, "holds") :-
    member(Equation, EquationReports),
    get_dict(verdict, Equation, "holds"),
    !.
step_verdict(_, "not_checked").

report_counts(Steps, Checked, Refuted) :-
    report_counts(Steps, 0, Checked, 0, Refuted).

report_counts([], Checked, Checked, Refuted, Refuted).
report_counts([Step|Steps], Checked0, Checked, Refuted0, Refuted) :-
    get_dict(equations, Step, Equations),
    equation_counts(Equations, StepChecked, StepRefuted),
    Checked1 is Checked0 + StepChecked,
    Refuted1 is Refuted0 + StepRefuted,
    report_counts(Steps, Checked1, Checked, Refuted1, Refuted).

equation_counts([], 0, 0).
equation_counts([Equation|Equations], Checked, Refuted) :-
    get_dict(verdict, Equation, Verdict),
    equation_counts(Equations, Checked0, Refuted0),
    (   Verdict == "not_checked"
    ->  Checked = Checked0
    ;   Checked is Checked0 + 1
    ),
    (   Verdict == "refuted"
    ->  Refuted is Refuted0 + 1
    ;   Refuted = Refuted0
    ).

first_refuted_step(Steps, First) :-
    findall(Index,
            ( member(Step, Steps),
              get_dict(verdict, Step, "refuted"),
              get_dict(index, Step, Index)
            ),
            Indices),
    (   Indices == []
    ->  First = none
    ;   min_list(Indices, First)
    ).
