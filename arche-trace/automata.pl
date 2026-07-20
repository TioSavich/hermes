/** <module> Automata (Mathematical Models of Practices)
 *
 *  This module implements the core mathematical automata that model the
 *  "practices-or-abilities" (Pragmatic Foundations), along with utilities
 *  for analyzing their formal limits (Gödel numbering utilities).
 *
 *  Includes:
 *  - The Highlander Automaton (Uniqueness constraint).
 *  - The vanishing-point mark (a limit-case of reference).
 *  - Prime Number Utilities (for arithmetization and incompleteness analysis).
 *
 *  The mechanism models Carspecken's limit-case of reference: the trace as
 *  "a vanishing point behind and a vanishing point ahead unified"
 *  (Carspecken, "Four Scenes", 1999). The formal mark is not the vanishing
 *  point itself, since a formal object cannot be. It is the track left in a
 *  proof where reference fails.
 */
:- module(automata,
          [ % Highlander
            highlander/2,
            % Vanishing-point mark
            generate_vanishing_point/1,
            contains_vanishing_point/1,
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
% The vanishing-point mark
% =================================================================
% Models a reference that propagates while refusing unification with a concrete
% term. The attributed variable is a formal track of that limit, not the
% vanishing point itself.

% Note: This implementation is specific to SWI-Prolog (using put_attr/3 and module-specific hooks).

%!  generate_vanishing_point(-T) is det.
%   Creates a variable carrying the vanishing_point attribute value.
%   The attribute name is the module name (automata).
generate_vanishing_point(T) :-
    put_attr(T, automata, vanishing_point).

%!  attr_unify_hook(+AttValue, +VarValue) is semidet.
%   Called by the Prolog engine during unification. This models the reference's
%   refusal of a concrete binding while allowing the mark to propagate.
automata:attr_unify_hook(vanishing_point, Value) :-
    ( var(Value) ->
        % If unifying with another variable, propagate the attribute.
        ( get_attr(Value, automata, vanishing_point) ->
            true  % Value already has the mark
        ;
            put_attr(Value, automata, vanishing_point)
        )
    ;
        % A concrete binding fails.
        fail
    ).

%!  contains_vanishing_point(+Term) is semidet.
%   Succeeds if Term is or contains a variable carrying the mark.
contains_vanishing_point(T) :-
    term_variables(T, Vars),
    member(V, Vars),
    get_attr(V, automata, vanishing_point), !.

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
