/** <module> Utility Predicates
 *
 *  General-purpose helper predicates salvaged and cleaned from the legacy codebase.
 */
:- module(utils,
          [ select/3,
            match_antecedents/2
          ]).

% =================================================================
% List Utilities
% =================================================================

%!  select(?X, ?List1, ?List2) is nondet.
%
%   Succeeds when List1, with X removed, results in List2.
%   This is often used in sequent calculus implementations to select a
%   proposition from the premises or conclusions.
select(X, [X|T], T).
select(X, [H|T], [H|R]) :- select(X, T, R).

% =================================================================
% Logic Utilities
% =================================================================

%!  match_antecedents(+Antecedents:list, +Premises:list) is semidet.
%
%   Succeeds if all elements in the Antecedents list are present in the
%   Premises list. Allows for unification between elements.
%   Used for checking if the antecedents of an axiom are satisfied by the
%   current premises during proof search.
match_antecedents([], _).
match_antecedents([A|As], Premises) :-
    member(A, Premises),
    match_antecedents(As, Premises).
