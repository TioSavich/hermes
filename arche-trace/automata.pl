/** <module> Automata (Mathematical Models of Practices)
 *
 *  This module implements the core mathematical automata that model the
 *  "practices-or-abilities" (Pragmatic Foundations), along with utilities
 *  for analyzing their formal limits (Gödel numbering utilities).
 *
 *  Includes:
 *  - The Highlander Automaton (Uniqueness constraint).
 *  - The Arche-Trace (Möbius/Derridean dynamic, resistance to stabilization).
 *  - Prime Number Utilities (for arithmetization and incompleteness analysis).
 *
 *  (Synthesis_1, Chapter 8.2; Möbius Conclusion)
 */
:- module(automata,
          [ % Highlander
            highlander/2,
            % Arche-Trace
            generate_trace/1,
            contains_trace/1,
            % Prime Number Utilities
            nth_prime/2,
            is_prime/1
            % Export the attribute hook for SWI-Prolog
            , automata:attr_unify_hook/2
          ]).

% =================================================================
% The Highlander Automaton
% =================================================================

%!      highlander(+List:list, -Result) is semidet.
%
%       A pragmatic axiom enforcing uniqueness: "There can be only one."
%       Succeeds if the list contains exactly one element.
%
%       @param List The input list.
%       @param Result The single element of the list.
highlander([Result], Result) :- !.
highlander([], _) :- !, fail.
% Fixed from P0: The original implementation allowed multiple identical elements.
% We enforce strict singularity.
highlander([_, _|_], _) :- fail.


% =================================================================
% The Arche-Trace (Deconstruction Engine / Möbius Dynamic)
% =================================================================
% Implements the Elusive Subject (I_f) and the necessary failure of formal systems
% using attributed variables. The Trace resists stabilization (unification with a concrete term).

% Note: This implementation is specific to SWI-Prolog (using put_attr/3 and module-specific hooks).

%!  generate_trace(-T) is det.
%   Creates a variable imbued with the arche_trace attribute.
%   The attribute name is the module name (automata).
generate_trace(T) :-
    put_attr(T, automata, arche_trace).

%!  attr_unify_hook(+AttValue, +VarValue) is semidet.
%   The Deconstruction Hook (The Twist). Called by the Prolog engine during unification.
%   This models the resistance to stabilization (Möbius Conclusion, Section 3.2).
automata:attr_unify_hook(arche_trace, Value) :-
    ( var(Value) ->
        % Différance (Propagation and Deferral): If unifying with another variable, propagate the attribute.
        ( get_attr(Value, automata, arche_trace) ->
            true  % Value already has the trace attribute
        ;
            put_attr(Value, automata, arche_trace)  % Propagate the trace
        )
    ;
        % Resistance to Representation (The "Gobbling Up"):
        % If an attempt is made to stabilize the Trace with a concrete term (nonvar), unification fails.
        fail
    ).

%!  contains_trace(+Term) is semidet.
%   Succeeds if Term is or contains a variable attributed with arche_trace.
contains_trace(T) :-
    term_variables(T, Vars),
    member(V, Vars),
    get_attr(V, automata, arche_trace), !.

% ========================================================================
% Prime Number Utilities (for Gödel Numbering and Formal Analysis)
% ========================================================================

%!  nth_prime(+N:integer, -Prime:integer) is det.
%
%   Returns the Nth prime number (1-indexed).
nth_prime(1, 2) :- !.
nth_prime(N, Prime) :-
    N > 1,
    nth_prime_helper(2, 1, N, Prime).

nth_prime_helper(Candidate, Count, Target, Prime) :-
    Count =:= Target,
    !,
    Prime = Candidate.
nth_prime_helper(Candidate, Count, Target, Prime) :-
    Count < Target,
    NextCandidate is Candidate + 1,
    ( is_prime(NextCandidate) ->
        NewCount is Count + 1,
        nth_prime_helper(NextCandidate, NewCount, Target, Prime)
    ;
        nth_prime_helper(NextCandidate, Count, Target, Prime)
    ).

%!  is_prime(+N:integer) is semidet.
%
%   True if N is prime.
is_prime(2) :- !.
is_prime(N) :-
    N > 2,
    N mod 2 =\= 0,
    \+ has_divisor(N, 3).

has_divisor(N, D) :-
    D * D =< N,
    ( N mod D =:= 0 ->
        true
    ;
        D2 is D + 2,
        has_divisor(N, D2)
    ).
