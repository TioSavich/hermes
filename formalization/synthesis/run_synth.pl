% Run the synthesizer against each declared target, time the search, print
% the discovered program plus any alternative programs of the same depth.
%
%   swipl -q -l paths.pl -l formalization/synthesis/run_synth.pl -g main -t halt

:- use_module(formalization(synthesis/synth)).

main :-
    findall(T, target(T, _), Targets),
    format("~n=== Synthesis run ===~n"),
    format("Targets: ~w~n", [Targets]),
    forall(member(T, Targets), run_one(T)),
    format("~n=== Done ===~n").

run_one(TargetName) :-
    target(TargetName, Examples),
    format("~n--- ~w ---~n", [TargetName]),
    format("Examples:~n"),
    forall(member(io(I, O), Examples),
           format("  ~w -> ~w~n", [I, O])),
    get_time(T0),
    ( synthesize(Examples, 5, Program)
    -> get_time(T1),
       Elapsed is T1 - T0,
       depth_of(Program, D),
       format("~nFound at depth ~w in ~3f s:~n", [D, Elapsed]),
       print_program(Program),
       % Look for alternatives at the same depth
       format("~nAlternative programs at depth ~w (up to 5):~n", [D]),
       synthesize_all(Examples, D, 6, Alts),
       length(Alts, NAlts),
       format("  total at this depth: ~w~n", [NAlts]),
       print_alts(Alts, Program, 0)
    ; format("~nNo program found within depth 5.~n")
    ).

depth_of(prog(Steps), D) :- length(Steps, D).

print_alts([], _, _).
print_alts([P|Rest], Canonical, Shown) :-
    ( P == Canonical
    -> print_alts(Rest, Canonical, Shown)
    ; format("~n  alt #~w:~n", [Shown]),
      print_program_indented(P),
      Shown1 is Shown + 1,
      print_alts(Rest, Canonical, Shown1)
    ).

print_program_indented(prog(Steps)) :-
    print_steps_indented(Steps, 1).
print_steps_indented([], _).
print_steps_indented([step(Op, ArgRefs)|Rest], Index) :-
    format("    var(~w) <- ~w(", [Index, Op]),
    print_args(ArgRefs),
    format(")~n"),
    Index1 is Index + 1,
    print_steps_indented(Rest, Index1).

print_args([]).
print_args([A]) :- print_arg(A).
print_args([A1, A2|Rest]) :- print_arg(A1), format(", "), print_args([A2|Rest]).
print_arg(input(I)) :- format("input(~w)", [I]).
print_arg(var(I))   :- format("var(~w)",   [I]).
