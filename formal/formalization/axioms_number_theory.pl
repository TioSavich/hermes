% ===================================================================
% Number Theory Axioms — Euclid's proof of prime infinitude
% ===================================================================
%
% Euclid's proof enters through an incoherence frame:
%   {The list of primes {A, B, C} is complete} in Inc
%
% The claim to completeness defeats itself through construction.
% This is not a contradiction in the logical sense but an
% incoherence — the assumption generates its own refutation.
%
% Interpretive correspondence: the proof is monological (any
% subject can verify it), but the RECOGNITION that completeness
% is self-defeating — that moment of "the assumption was wrong" —
% is where formalization goes hollow. The structural rules below
% execute the proof mechanically; the insight they formalize is
% not itself mechanical.
% ===================================================================

number_theory_predicates([prime, composite, divides, is_complete, analyze_euclid_number, member]).

% --- Helpers ---

product_of_list(L, P) :- (is_list(L) -> product_of_list_impl(L, P) ; fail).
product_of_list_impl([], 1).
product_of_list_impl([H|T], P) :- number(H), product_of_list_impl(T, P_tail), P is H * P_tail.

find_prime_factor(N, F) :- number(N), N > 1, once(find_factor_from(N, 2, F)).
find_factor_from(N, D, D) :- N mod D =:= 0, !.
find_factor_from(N, D, F) :-
    D * D =< N,
    (D =:= 2 -> D_next is 3 ; D_next is D + 2),
    find_factor_from(N, D_next, F).
find_factor_from(N, _, N).

is_prime(N) :- number(N), N > 1, find_prime_factor(N, F), F =:= N.

euclid_number(List, Product, EuclidNumber) :-
    product_of_list(List, Product),
    EuclidNumber is Product + 1.

number_theory_nonmember_witness(Prime, List,
                                _{kind: euclid_prime_not_in_finite_list,
                                  prime: Prime,
                                  list: List,
                                  product: Product,
                                  euclid_number: Prime,
                                  divides_product: no,
                                  not_member: n(neg(member(Prime, List))),
                                  reason: prime_equal_to_product_plus_one_cannot_be_one_of_the_product_factors}) :-
    axiom_pack_enabled(number_theory),
    euclid_number(List, Product, Prime),
    is_prime(Prime),
    \+ member(Prime, List),
    !.

number_theory_factor_witness(EuclidNumber, List,
                             _{kind: euclid_composite_factor,
                               euclid_number: EuclidNumber,
                               list: List,
                               product: Product,
                               prime_factor: Factor,
                               factor_prime: n(prime(Factor)),
                               divides: n(divides(Factor, EuclidNumber)),
                               not_member: n(neg(member(Factor, List))),
                               reason: factor_of_product_plus_one_leaves_remainder_one_against_every_list_factor}) :-
    axiom_pack_enabled(number_theory),
    euclid_number(List, Product, EuclidNumber),
    \+ is_prime(EuclidNumber),
    find_prime_factor(EuclidNumber, Factor),
    is_prime(Factor),
    \+ member(Factor, List),
    !.

number_theory_prime_case_witness(List,
                                 _{kind: euclid_prime_case,
                                   list: List,
                                   product: Product,
                                   euclid_number: EuclidNumber,
                                   prime: EuclidNumber,
                                   prime_fact: n(prime(EuclidNumber)),
                                   not_member: n(neg(member(EuclidNumber, List))),
                                   completeness_refutation: n(neg(is_complete(List))),
                                   nonmembership_witness: NonmembershipWitness}) :-
    axiom_pack_enabled(number_theory),
    euclid_number(List, Product, EuclidNumber),
    is_prime(EuclidNumber),
    number_theory_nonmember_witness(EuclidNumber, List, NonmembershipWitness),
    !.

number_theory_composite_case_witness(List,
                                     _{kind: euclid_composite_case,
                                       list: List,
                                       product: Product,
                                       euclid_number: EuclidNumber,
                                       prime_factor: Factor,
                                       prime_fact: n(prime(Factor)),
                                       divides: n(divides(Factor, EuclidNumber)),
                                       not_member: n(neg(member(Factor, List))),
                                       completeness_refutation: n(neg(is_complete(List))),
                                       factor_witness: FactorWitness}) :-
    axiom_pack_enabled(number_theory),
    euclid_number(List, Product, EuclidNumber),
    \+ is_prime(EuclidNumber),
    number_theory_factor_witness(EuclidNumber, List, FactorWitness),
    Factor = FactorWitness.prime_factor,
    !.
number_theory_composite_case_witness(List,
                                     _{kind: euclid_composite_case,
                                       list: List,
                                       product: Product,
                                       euclid_number: EuclidNumber,
                                       status: not_applicable_prime_euclid_number}) :-
    axiom_pack_enabled(number_theory),
    euclid_number(List, Product, EuclidNumber),
    is_prime(EuclidNumber),
    !.

number_theory_self_defeat_witness(List,
                                  _{kind: euclid_self_defeat,
                                    assumption: n(is_complete(List)),
                                    list: List,
                                    product: Product,
                                    euclid_number: EuclidNumber,
                                    constructed: n(analyze_euclid_number(EuclidNumber, List)),
                                    conclusion: n(neg(is_complete(List))),
                                    prime_case: PrimeCase,
                                    composite_case: CompositeCase}) :-
    axiom_pack_enabled(number_theory),
    euclid_number(List, Product, EuclidNumber),
    (   is_prime(EuclidNumber)
    ->  number_theory_prime_case_witness(List, PrimeCase),
        number_theory_composite_case_witness(List, CompositeCase)
    ;   PrimeCase = _{kind: euclid_prime_case,
                      list: List,
                      product: Product,
                      euclid_number: EuclidNumber,
                      status: not_applicable_composite_euclid_number},
        number_theory_composite_case_witness(List, CompositeCase)
    ),
    !.

number_theory_incoherence_witness(Context,
                                  _{kind: euclid_case_prime_incoherence,
                                    context: Context,
                                    assumption: n(is_complete(List)),
                                    prime_fact: n(prime(EuclidNumber)),
                                    product: Product,
                                    euclid_number: EuclidNumber,
                                    constructed: n(analyze_euclid_number(EuclidNumber, List)),
                                    reason: complete_list_cannot_contain_its_product_plus_one_as_prime}) :-
    axiom_pack_enabled(number_theory),
    member(n(prime(EuclidNumber)), Context),
    member(n(is_complete(List)), Context),
    euclid_number(List, Product, EuclidNumber),
    !.

axiom_incoherence_witness(Context, Witness) :-
    number_theory_incoherence_witness(Context, Witness).

% --- Euclid Case 1 Incoherence ---
is_incoherent(X) :-
    number_theory_incoherence_witness(X, _).

% --- Material Inferences ---

% M5: Euclid's Core Argument (Forward Chaining)
proves_impl(( [n(prime(G)), n(divides(G, N)), n(is_complete(L))] => [n(neg(member(G, L)))] ), _) :-
    axiom_pack_enabled(number_theory),
    (   number_theory_nonmember_witness(G, L, _),
        N = G
    ;   number_theory_factor_witness(N, L, FactorWitness),
        G = FactorWitness.prime_factor
    ).

% M4: Completeness Violation (Forward Chaining)
proves_impl(([n(prime(G)), n(neg(member(G, L))), n(is_complete(L))] => [n(neg(is_complete(L)))]), _) :-
    axiom_pack_enabled(number_theory),
    (   number_theory_nonmember_witness(G, L, _)
    ;   number_theory_factor_witness(_, L, FactorWitness),
        G = FactorWitness.prime_factor
    ).

% M4-Direct
proves_impl(([n(prime(G)), n(neg(member(G, L)))] => [n(neg(is_complete(L)))]), _) :-
    axiom_pack_enabled(number_theory),
    (   number_theory_nonmember_witness(G, L, _)
    ;   number_theory_factor_witness(_, L, FactorWitness),
        G = FactorWitness.prime_factor
    ).

% Primality grounding
proves_impl(([] => [n(prime(N))]), _) :-
    axiom_pack_enabled(number_theory),
    is_prime(N).
proves_impl(([] => [n(composite(N))]), _) :-
    axiom_pack_enabled(number_theory),
    number(N), N > 1, \+ is_prime(N).

% --- Structural Rules for Euclid's Proof ---

% Euclid's Construction
proves_impl((Premises => Conclusions), History) :-
    axiom_pack_enabled(number_theory),
    member(n(is_complete(L)), Premises),
    \+ member(euclid_construction(L), History),
    euclid_number(L, _DE, EF),
    NewPremise = n(analyze_euclid_number(EF, L)),
    proves_impl(([NewPremise|Premises] => Conclusions), [euclid_construction(L)|History]).

% Case Analysis (analyze_euclid_number)
proves_impl((Premises => Conclusions), History) :-
    axiom_pack_enabled(number_theory),
    select(n(analyze_euclid_number(EF, L)), Premises, RestPremises),
    EF > 1,
    (member(n(is_complete(L)), Premises) ->
        proves_impl(([n(prime(EF))|RestPremises] => Conclusions), History),
        proves_impl(([n(composite(EF))|RestPremises] => Conclusions), History)
    ; fail
    ).

% Prime Factorization (Existential Instantiation)
proves_impl((Premises => Conclusions), History) :-
    axiom_pack_enabled(number_theory),
    select(n(composite(N)), Premises, RestPremises),
    \+ member(factorization(N), History),
    find_prime_factor(N, G),
    NewPremises = [n(prime(G)), n(divides(G, N))|RestPremises],
    proves_impl((NewPremises => Conclusions), [factorization(N)|History]).
