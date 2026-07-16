% ===================================================================
% Domain Management and Normative Crisis Detection
% ===================================================================
%
% These predicates manage the learner's current mathematical
% context (natural numbers, integers, rationals) and detect
% normative violations — operations that are prohibited in the
% current domain (e.g., subtracting a larger from a smaller
% in natural numbers).
%
% Normative crisis is not an error to be avoided but a signal
% that the current domain is insufficient. The crisis triggers
% a domain expansion (N -> Z -> Q) which is the learner's
% accommodation.
%
% Interpretive correspondence: normative crisis detection
% participates in what might be read as a Scene Three horizon
% (intersubjective, normative). The prohibitions represent
% shared mathematical norms ("we don't subtract larger from
% smaller in natural numbers") that the learner has internalized.
% When the learner violates a norm, it is encountering the
% boundary of a recognitive community's practice.
% ===================================================================

:- dynamic current_domain/1.
:- dynamic prohibition/2.
:- dynamic normative_crisis/2.

current_domain(n).

set_domain(D) :-
    ( member(D, [n, z, q]) -> retractall(current_domain(_)), assertz(current_domain(D)) ; true).

% --- Fraction Domain ---
fraction_predicates([rdiv, iterate, partition]).

natural_domain_value(recollection(History), recollection(History)) :-
    is_list(History),
    !.
natural_domain_value(N, Recollection) :-
    integer(N),
    N >= 0,
    grounded_arithmetic:integer_to_recollection(N, Recollection).

% --- Normative Crisis Detection ---

prohibition(natural_numbers, subtract(M, S, _)) :-
    axiom_pack_enabled(domains),
    current_domain(n),
    natural_domain_value(M, RecM),
    natural_domain_value(S, RecS),
    grounded_arithmetic:smaller_than(RecM, RecS).

prohibition(natural_numbers, divide(Dividend, Divisor, _)) :-
    axiom_pack_enabled(domains),
    current_domain(n),
    natural_domain_value(Dividend, RecDividend),
    natural_domain_value(Divisor, RecDivisor),
    \+ grounded_arithmetic:zero(RecDivisor),
    grounded_arithmetic:smaller_than(RecDividend, RecDivisor).

check_norms(Goal) :-
    ( is_core_operation(Goal) ->
        current_domain_context(Context),
        ( prohibition(Context, Goal) ->
            throw(normative_crisis(Goal, Context))
        ;
            incur_cost(norm_check)
        )
    ;
        true
    ).

is_core_operation(add(_, _, _)).
is_core_operation(subtract(_, _, _)).
is_core_operation(multiply(_, _, _)).
is_core_operation(divide(_, _, _)).

current_domain_context(Context) :-
    current_domain(Domain),
    domain_to_context(Domain, Context).

domain_to_context(n, natural_numbers).
domain_to_context(z, integers).
domain_to_context(q, rationals).

% --- Excluded Predicates for Arithmetic Evaluation ---
excluded_predicates(AllPreds) :-
    geometric_predicates(G),
    number_theory_predicates(NT),
    fraction_predicates(F),
    append(G, NT, Temp),
    append(Temp, F, DomainPreds),
    append([neg, conj, nec, comp_nec, exp_nec, exp_poss, comp_poss, is_recollection], DomainPreds, AllPreds).

% --- Fraction Grounding ---

proves_impl(([] => [o(iterate(U, M, R))]), _) :-
    axiom_pack_enabled(domains),
    is_recollection(U, _), integer(M), M >= 0,
    normalize(U, NU),
    (integer(NU) -> N1=NU, D1=1 ; NU = N1 rdiv D1),
    N_res is N1 * M,
    normalize(N_res rdiv D1, R).

proves_impl(([] => [o(partition(W, N, U))]), _) :-
    axiom_pack_enabled(domains),
    is_recollection(W, _), integer(N), N > 0,
    normalize(W, NW),
    (integer(NW) -> N1=NW, D1=1 ; NW = N1 rdiv D1),
    D_res is D1 * N,
    normalize(N1 rdiv D_res, U).
