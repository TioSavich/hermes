% Verify base-invariance for addition make-base targets.
%
% Mirrors run_lazy.pl but for the add_near_base_b{5,7,10,12} targets.
% Expected outcome: the same canonical four-step make-base structure
% emerges under every base, parallel to what was demonstrated for
% subtraction in DEMO_BASE_INVARIANCE.md.
%
%   swipl -q -l paths.pl -l formal/formalization/synthesis/run_add.pl -g main -t halt

:- use_module(formalization(synthesis/synth_lazy)).

main :-
    Bases = [
        add_near_base_b5,
        add_near_base_b7,
        add_near_base_b10,
        add_near_base_b12
    ],
    format("~n========================================~n"),
    format("Addition make-base invariance verification~n"),
    format("========================================~n"),
    forall(member(T, Bases), run_one(T)),
    format("~n========================================~n"),
    format("If the program shapes above are identical~n"),
    format("modulo the base parameter, the LX-naturality~n"),
    format("argument extends from subtraction to addition.~n"),
    format("========================================~n").

run_one(TargetName) :-
    target(TargetName, Base, Examples),
    format("~n--- ~w (working base = ~w) ---~n", [TargetName, Base]),
    format("Examples: ~w~n", [Examples]),
    get_time(T0),
    catch(
        discover(Examples, 4, Base, Productive, Deformations),
        E,
        (format("ERROR: ~q~n", [E]), Productive = [], Deformations = [])
    ),
    get_time(T1),
    Elapsed is T1 - T0,
    format("~nSearch finished in ~3f s.~n", [Elapsed]),
    report_productive(Productive),
    report_deformations(Deformations, Base).

report_productive([]) :-
    format("~nProductive: NONE FOUND within search depth.~n").
report_productive([Cost-Program|Rest]) :-
    format("~nProductive (cost=~w):~n", [Cost]),
    print_program(Program),
    ( Rest == []
    -> true
    ;  length(Rest, N),
       format("  (~w other program(s) at same cost.)~n", [N])
    ).

report_deformations([], _) :-
    format("~nDeformations: NONE (productive does not use shortcut primitives).~n").
report_deformations(Deforms, _Base) :-
    length(Deforms, N),
    format("~nDeformation candidates: ~w distinct wrong-output patterns~n", [N]),
    forall(member(OutTuple-Cost-Programs, Deforms),
           report_one_deform(OutTuple, Cost, Programs)).

report_one_deform(OutTuple, Cost, Programs) :-
    length(Programs, N),
    format("  out=~w cost=~w (~w distinct programs)~n", [OutTuple, Cost, N]),
    ( Programs = [P|_]
    -> format("    example:~n"),
       print_indented(P)
    ;  true
    ).

print_indented(prog(Steps)) :-
    print_indented_steps(Steps, 1).
print_indented_steps([], _).
print_indented_steps([step(Op, ArgRefs)|Rest], Index) :-
    format("      var(~w) <- ~w(", [Index, Op]),
    print_indented_args(ArgRefs),
    format(")~n"),
    Index1 is Index + 1,
    print_indented_steps(Rest, Index1).

print_indented_args([]).
print_indented_args([A]) :- print_indented_arg(A).
print_indented_args([A1, A2|Rest]) :-
    print_indented_arg(A1), format(", "), print_indented_args([A2|Rest]).
print_indented_arg(input(I)) :- format("input(~w)", [I]).
print_indented_arg(var(I))   :- format("var(~w)",   [I]).
