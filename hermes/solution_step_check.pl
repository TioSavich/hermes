:- module(solution_step_check, [ check_solution_steps/2 ]).

:- use_module(hermes(math_claim_checker), [ check_math_claim/2 ]).
:- use_module(library(lists), [ member/2, min_list/2 ]).

%!  check_solution_steps(+Steps, -Report) is det.
%
%   Adjudicate every safe ground equation in a list of step(Index, Equations)
%   terms. Empty and unreadable equation lists remain not_checked.
check_solution_steps(Steps, Report) :-
    is_list(Steps),
    maplist(check_step, Steps, StepReports),
    report_counts(StepReports, CheckedCount, RefutedCount),
    first_refuted_step(StepReports, FirstRefuted),
    Report = _{
        first_refuted_step: FirstRefuted,
        checked_equations: CheckedCount,
        refuted_equations: RefutedCount,
        steps: StepReports
    }.

check_step(step(Index, Equations), Report) :-
    integer(Index),
    is_list(Equations),
    maplist(check_equation, Equations, EquationReports),
    step_verdict(EquationReports, Verdict),
    Report = _{
        index: Index,
        verdict: Verdict,
        equations: EquationReports
    }.

check_equation(equation(Span, Left, Right), Report) :-
    span_text(Span, SpanText),
    (   safe_ground_equation(Left, Right)
    ->  preferred_claim(Left, Right, Claim),
        catch(check_math_claim(Claim, Checked), _, not_checked_dict(Checked)),
        checked_equation_fields(Checked, Verdict, Trace)
    ;   Verdict = "not_checked",
        Trace = []
    ),
    Report = _{span: SpanText, verdict: Verdict, trace: Trace}.

span_text(Span, Span) :-
    string(Span),
    !.
span_text(Span, Text) :-
    format(string(Text), "~w", [Span]).

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

safe_ground_equation(Left, Right) :-
    ground(Left-Right),
    acyclic_term(Left-Right),
    safe_arithmetic_expression(Left),
    safe_arithmetic_expression(Right).

safe_arithmetic_expression(Value) :-
    number(Value).
safe_arithmetic_expression(Left + Right) :-
    safe_arithmetic_expression(Left),
    safe_arithmetic_expression(Right).
safe_arithmetic_expression(Left - Right) :-
    safe_arithmetic_expression(Left),
    safe_arithmetic_expression(Right).
safe_arithmetic_expression(Left * Right) :-
    safe_arithmetic_expression(Left),
    safe_arithmetic_expression(Right).
safe_arithmetic_expression(Left / Right) :-
    safe_arithmetic_expression(Left),
    safe_arithmetic_expression(Right).

preferred_claim(Left, Right, Claim) :-
    narrated_claim(Left, Right, Claim),
    !.
preferred_claim(Left, Right, arithmetic_equation(Left, Right)).

narrated_claim(A + B, C, sum(A, B, C)) :-
    nonnegative_integers([A, B, C]).
narrated_claim(A - B, C, subtraction(A, B, C)) :-
    nonnegative_integers([A, B, C]).
narrated_claim(A / B + C / D, P / Q,
        fraction_sum(fraction(A, B), fraction(C, D), fraction(P, Q))) :-
    fraction_parts(A, B),
    fraction_parts(C, D),
    fraction_parts(P, Q).
narrated_claim(A / B + C / D, Whole,
        fraction_sum(fraction(A, B), fraction(C, D), whole(Whole))) :-
    fraction_parts(A, B),
    fraction_parts(C, D),
    nonnegative_integer(Whole).
narrated_claim(A / B - C / D, P / Q,
        difference(fraction(A, B), fraction(C, D), fraction(P, Q))) :-
    fraction_parts(A, B),
    fraction_parts(C, D),
    fraction_parts(P, Q).
narrated_claim(A / B * (C / D), P / Q,
        multiplication(fraction(A, B), fraction(C, D), fraction(P, Q))) :-
    fraction_parts(A, B),
    fraction_parts(C, D),
    fraction_parts(P, Q).
narrated_claim(Fraction * Quantity, Result,
        fraction_of(Quantity, fraction(Numerator, Denominator), Result)) :-
    fraction_term(Fraction, Numerator, Denominator),
    nonnegative_integers([Quantity, Result]).
narrated_claim(Quantity * Fraction, Result,
        fraction_of(Quantity, fraction(Numerator, Denominator), Result)) :-
    fraction_term(Fraction, Numerator, Denominator),
    nonnegative_integers([Quantity, Result]).
narrated_claim(A / B, C / D,
        equivalence(fraction(A, B), fraction(C, D))) :-
    fraction_parts(A, B),
    fraction_parts(C, D).
narrated_claim(A / B, Whole,
        equivalence(fraction(A, B), fraction(Whole, 1))) :-
    fraction_parts(A, B),
    nonnegative_integer(Whole).

fraction_term(Numerator / Denominator, Numerator, Denominator) :-
    fraction_parts(Numerator, Denominator).

fraction_parts(Numerator, Denominator) :-
    nonnegative_integer(Numerator),
    integer(Denominator),
    Denominator > 0.

nonnegative_integers(Values) :-
    forall(member(Value, Values), nonnegative_integer(Value)).

nonnegative_integer(Value) :-
    integer(Value),
    Value >= 0.

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

