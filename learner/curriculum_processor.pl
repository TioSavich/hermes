/** <module> Curriculum Processor
 *
 * Processes mathematical curriculum line by line, building capabilities
 * progressively through accumulated learning and fact generation.
 */

:- module(curriculum_processor, [
    process_curriculum/1,
    process_curriculum_file/1,
    run_progressive_learning/0,
    process_task/1
]).

:- use_module(math(jason), [partitive_fractional_scheme/4]).
:- use_module(formalization(grounded_arithmetic), [add_grounded/3, subtract_grounded/3, multiply_grounded/3]).
:- use_module(formalization(grounded_ens_operations), [ens_partition/3]).
:- use_module(math(fraction_semantics), [apply_equivalence_rule/3]).

% Dynamic predicates for learned facts
:- dynamic(learned_fact/2).
:- dynamic(multiplication_fact/3).
:- dynamic(division_fact/3).
:- dynamic(fraction_fact/3).
:- discontiguous process_task/1.

% Clear previous learning session
reset_learning :-
    retractall(learned_fact(_, _)),
    retractall(multiplication_fact(_, _, _)),
    retractall(division_fact(_, _, _)),
    retractall(fraction_fact(_, _, _)).

% Process a single curriculum line
process_task(count(N)) :-
    Length is N,
    length(Tally, Length),
    maplist(=(t), Tally),
    Result = recollection(Tally),
    assertz(learned_fact(count(N), Result)),
    format('Learned: count(~w) = ~w~n', [N, Result]).

process_task(add(A, B)) :-
    (   learned_fact(count(A), TallyA) -> true
    ;   process_task(count(A)), learned_fact(count(A), TallyA)
    ),
    (   learned_fact(count(B), TallyB) -> true  
    ;   process_task(count(B)), learned_fact(count(B), TallyB)
    ),
    add_grounded(TallyA, TallyB, Result),
    assertz(learned_fact(add(A, B), Result)),
    format('Learned: add(~w, ~w) = ~w~n', [A, B, Result]).

process_task(subtract(A, B)) :-
    (   learned_fact(count(A), TallyA) -> true
    ;   process_task(count(A)), learned_fact(count(A), TallyA)
    ),
    (   learned_fact(count(B), TallyB) -> true
    ;   process_task(count(B)), learned_fact(count(B), TallyB)
    ),
    subtract_grounded(TallyA, TallyB, Result),
    assertz(learned_fact(subtract(A, B), Result)),
    format('Learned: subtract(~w, ~w) = ~w~n', [A, B, Result]).

process_task(multiply(A, B)) :-
    (   learned_fact(count(A), TallyA) -> true
    ;   process_task(count(A)), learned_fact(count(A), TallyA)
    ),
    (   learned_fact(count(B), TallyB) -> true
    ;   process_task(count(B)), learned_fact(count(B), TallyB)
    ),
    % Check if multiply_grounded exists, otherwise use repeated addition
    (   catch(multiply_grounded(TallyA, TallyB, Result), _, fail)
    ->  true
    ;   % Fallback: multiplication as repeated addition
        multiply_by_repeated_addition(TallyA, B, Result)
    ),
    assertz(learned_fact(multiply(A, B), Result)),
    assertz(multiplication_fact(A, B, Result)),
    Product is A * B,
    assertz(learned_fact(count(Product), Result)),
    format('Learned: multiply(~w, ~w) = ~w~n', [A, B, Result]).

% Helper predicate for multiplication by repeated addition
multiply_by_repeated_addition(_, 0, recollection([])) :- !.
multiply_by_repeated_addition(TallyA, 1, TallyA) :- !.
multiply_by_repeated_addition(TallyA, N, Result) :-
    N > 1,
    N1 is N - 1,
    multiply_by_repeated_addition(TallyA, N1, PartialResult),
    add_grounded(TallyA, PartialResult, Result).

process_task(divide(A, B)) :-
    % Division requires multiplication facts to work
    (   % Find a multiplication fact where B * Quotient = A
        multiplication_fact(B, Quotient, ProductResult),
        learned_fact(count(A), ProductResult)
    ->  learned_fact(count(Quotient), Result),
        assertz(division_fact(A, B, Result)),
        assertz(learned_fact(divide(A, B), Result)),
        format('Learned: divide(~w, ~w) = ~w (using ~w × ~w = ~w)~n', [A, B, Result, B, Quotient, A])
    ;   % Try the other way: A * Quotient = B  
        multiplication_fact(Quotient, B, ProductResult),
        learned_fact(count(A), ProductResult)
    ->  learned_fact(count(Quotient), Result),
        assertz(division_fact(A, B, Result)),
        assertz(learned_fact(divide(A, B), Result)),
        format('Learned: divide(~w, ~w) = ~w (using ~w × ~w = ~w)~n', [A, B, Result, Quotient, B, A])
    ;   format('Cannot yet divide(~w, ~w) - insufficient multiplication facts~n', [A, B])
    ).

process_task(fraction(Num, Den)) :-
    (   learned_fact(count(Num), TallyNum) -> true
    ;   process_task(count(Num)), learned_fact(count(Num), TallyNum)
    ),
    (   learned_fact(count(Den), TallyDen) -> true
    ;   process_task(count(Den)), learned_fact(count(Den), TallyDen)
    ),
    partitive_fractional_scheme(TallyNum, TallyDen, [unit(whole)], Result),
    assertz(fraction_fact(Num, Den, Result)),
    assertz(learned_fact(fraction(Num, Den), Result)),
    format('Learned: fraction(~w/~w) = ~w~n', [Num, Den, Result]).

process_task(fraction_of(Num, Den, whole)) :-
    (   fraction_fact(Num, Den, Result) -> true
    ;   process_task(fraction(Num, Den)), fraction_fact(Num, Den, Result)
    ),
    assertz(learned_fact(fraction_of(Num, Den, whole), Result)),
    format('Learned: ~w/~w of whole = ~w~n', [Num, Den, Result]).

process_task(fraction_of(Num, Den, wholes(Count))) :-
    (   learned_fact(count(Num), TallyNum) -> true
    ;   process_task(count(Num)), learned_fact(count(Num), TallyNum)
    ),
    (   learned_fact(count(Den), TallyDen) -> true
    ;   process_task(count(Den)), learned_fact(count(Den), TallyDen)
    ),
    length(Wholes, Count),
    maplist(=(unit(whole)), Wholes),
    partitive_fractional_scheme(TallyNum, TallyDen, Wholes, Result),
    assertz(learned_fact(fraction_of(Num, Den, wholes(Count)), Result)),
    format('Learned: ~w/~w of ~w wholes = ~w~n', [Num, Den, Count, Result]).

process_task(fraction_of_fraction(Num1, Den1, Num2, Den2)) :-
    % First get the base fraction
    (   fraction_fact(Num2, Den2, BaseFraction) -> true
    ;   process_task(fraction(Num2, Den2)), fraction_fact(Num2, Den2, BaseFraction)
    ),
    BaseFraction = [BaseUnit|_],
    (   learned_fact(count(Num1), _TallyNum1) -> true
    ;   process_task(count(Num1)), learned_fact(count(Num1), _TallyNum1)
    ),
    (   learned_fact(count(Den1), TallyDen1) -> true
    ;   process_task(count(Den1)), learned_fact(count(Den1), TallyDen1)
    ),
    ens_partition(BaseUnit, TallyDen1, Parts),
    length(SelectedParts, Num1),
    append(SelectedParts, _, Parts),
    assertz(learned_fact(fraction_of_fraction(Num1, Den1, Num2, Den2), SelectedParts)),
    format('Learned: ~w/~w of ~w/~w = ~w~n', [Num1, Den1, Num2, Den2, SelectedParts]).

process_task(Task) :-
    format('Skipping unimplemented task: ~w~n', [Task]).

% Process curriculum from file
process_curriculum_file(File) :-
    reset_learning,
    open(File, read, Stream),
    process_lines(Stream),
    close(Stream).

process_lines(Stream) :-
    read_line_to_string(Stream, Line),
    (   Line == end_of_file
    ->  true
    ;   (   string_concat('#', _, Line)  % Skip comments
        ->  true
        ;   Line == ""  % Skip empty lines
        ->  true
        ;   parse_and_process_line(Line)
        ),
        process_lines(Stream)
    ).

parse_and_process_line(Line) :-
    atom_string(_Atom, Line),
    (   catch(term_string(Term, Line), _, fail)
    ->  format('Processing: ~w~n', [Term]),
        process_task(Term)
    ;   format('Could not parse: ~w~n', [Line])
    ).

% Run the full curriculum
run_progressive_learning :-
    writeln(''),
    writeln('PROGRESSIVE MATHEMATICAL LEARNING DEMONSTRATION'),
    writeln('=' * 50),
    writeln('Starting with basic counting, building to complex operations'),
    writeln(''),
    process_curriculum_file('mathematical_curriculum.txt'),
    writeln(''),
    writeln('LEARNING SUMMARY:'),
    findall(Fact, learned_fact(_, Fact), Facts),
    length(Facts, NumFacts),
    format('Total facts learned: ~w~n', [NumFacts]),
    findall(MF, multiplication_fact(_, _, MF), MultFacts),
    length(MultFacts, NumMultFacts),
    format('Multiplication facts: ~w~n', [NumMultFacts]),
    findall(DF, division_fact(_, _, DF), DivFacts),
    length(DivFacts, NumDivFacts),
    format('Division facts: ~w~n', [NumDivFacts]),
    findall(FF, fraction_fact(_, _, FF), FracFacts),
    length(FracFacts, NumFracFacts),
    format('Fraction facts: ~w~n', [NumFracFacts]),
    writeln('').

process_curriculum(Tasks) :-
    reset_learning,
    maplist(process_task, Tasks).
