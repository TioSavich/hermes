/** <module> Gate: every citation in the data-representation enactment lane
 *
 * Each form's warrant and each lesson's evidence names a teacher-guide file, a
 * line, and the text printed at that line. This reads the file and compares.
 * A citation that has drifted is a defect, because a warrant nobody can check
 * is a claim the lane is not entitled to.
 *
 * Run:
 *   swipl -q -g check -t 'halt(1)' paths.pl \
 *     scripts/checks/data_representation_enactment_citations.pl
 */

:- use_module(im_lessons('enactment/data_representation')).
:- use_module(library(readutil)).
% List predicates autoload. A blanket import also claims lists:select/3 in
% user after the path bootstrap has imported utils:select/3 there.

check :-
    findall(cite(warrant(L), S, N, T),
            ( data_representation_enactment:enactment_form(_, _, warrant(L, S, N, T)) ),
            Ws),
    findall(cite(evidence(L), S, N, T),
            ( data_representation_enactment:lesson_enactment_form(L, _, evidence(S, N, T)) ),
            Es),
    append(Ws, Es, Cites),
    length(Cites, Total),
    findall(C, ( member(C, Cites), \+ cite_holds(C) ), Bad),
    length(Bad, NBad),
    forall(member(cite(Who, S, N, T), Bad),
           ( guide_line(S, N, Actual)
           -> format("MISMATCH ~w ~w:~w~n  cited:  ~q~n  actual: ~q~n", [Who, S, N, T, Actual])
           ;  format("MISSING  ~w ~w:~w (no such line)~n", [Who, S, N])
           )),
    findall(L, data_representation_enactment:lane_lesson(L, _, _), Ls),
    length(Ls, Pop),
    findall(L, ( member(L, Ls), \+ data_representation_enactment:lesson_enactment_form(L, _, _) ), NoForm),
    findall(L, ( member(L, Ls), \+ ( data_representation_enactment:lesson_enactment_form(L, F, _),
                                     data_representation_enactment:lesson_inputs(L, F, _, _) ) ), NoInputs),
    length(NoForm, NF), length(NoInputs, NI),
    check_moves(Ls, Steps, Undeclared),
    check_trace_dicts(Ls, Traces, BadTraces),
    format("~w citations checked, ~w mismatched~n", [Total, NBad]),
    format("~w lessons, ~w without a form, ~w without inputs~n", [Pop, NF, NI]),
    format("~w emitted steps checked against enactment_move/3, ~w undeclared~n", [Steps, Undeclared]),
    format("~w trace dicts built, ~w malformed~n", [Traces, BadTraces]),
    (   NBad =:= 0, NF =:= 0, NI =:= 0, Undeclared =:= 0, BadTraces =:= 0
    ->  format("PASS~n"), halt(0)
    ;   format("FAIL~n"), halt(1)
    ).

%!  lane_enactment(?Lesson, -Enactment) is nondet.
%   Every enactment the lane emits, one per lesson and form.
lane_enactment(L, E) :-
    data_representation_enactment:lesson_enactment_form(L, Form, _),
    data_representation_enactment:lesson_inputs(L, Form, Inputs, _),
    data_representation_enactment:enact(L, [form-Form | Inputs], E).

%!  check_moves(+Lessons, -StepCount, -Undeclared) is det.
%
%   Every verb an emitted step uses has to be a declared enactment_move at that
%   index of that form. A step whose verb the form does not declare is a
%   vocabulary leak, not a doing.
check_moves(Lessons, StepCount, Undeclared) :-
    findall(step(L, Form, I, Verb, Operand),
            ( member(L, Lessons),
              lane_enactment(L, E),
              E = enactment(_, Form, _, Steps, _),
              member(step(I, Verb, Operand, _), Steps) ),
            All),
    length(All, StepCount),
    findall(S,
            ( member(S, All), S = step(_, Form, I, Verb, Operand),
              Declared =.. [Verb, Operand],
              \+ data_representation_enactment:enactment_move(Form, I, Declared) ),
            Bad),
    length(Bad, Undeclared),
    forall(member(step(L, F, I, V, O), Bad),
           format("UNDECLARED MOVE ~w ~w step ~w: ~w(~w)~n", [L, F, I, V, O])).

%!  check_trace_dicts(+Lessons, -Built, -Malformed) is det.
%
%   The trace dict has to carry every key the strategy-trace consumer reads,
%   with steps as _{n, label, value}.
check_trace_dicts(Lessons, Built, Malformed) :-
    findall(L-D,
            ( member(L, Lessons),
              lane_enactment(L, E),
              catch(data_representation_enactment:enactment_trace_dict(E, D), _, fail) ),
            Ds),
    length(Ds, Built),
    findall(L,
            ( member(L-D, Ds), \+ well_shaped_trace(D) ),
            Bad),
    length(Bad, Malformed),
    forall(member(L, Bad), format("MALFORMED TRACE ~w~n", [L])).

well_shaped_trace(D) :-
    forall(member(K, [strategy, ok, representation, result, steps, jumps, note]),
           get_dict(K, D, _)),
    get_dict(steps, D, Steps), Steps \== [],
    forall(member(S, Steps),
           ( get_dict(n, S, _), get_dict(label, S, _), get_dict(value, S, _) )).

cite_holds(cite(_, S, N, T)) :-
    guide_line(S, N, Actual),
    normalize_space(atom(A), Actual),
    normalize_space(atom(B), T),
    A == B.

guide_line(Source, N, Line) :-
    read_file_to_string(Source, Str, [encoding(utf8)]),
    split_string(Str, "\n", "", Lines),
    nth1(N, Lines, Line).
