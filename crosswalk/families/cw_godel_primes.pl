/** <module> Crosswalk family — Gödel-numbering prime utilities (godel_primes)
 *
 * Problem this solves: the prime-number / arithmetization utilities that the
 * incompleteness-analysis layers use are scattered across modules under
 * different functor names AND different arities. They are not redundant
 * duplicates — they denote three distinct (but related) operations:
 *
 *   - is_prime/1          : primality test  (N -> succeed/fail)
 *   - nth_prime/2         : index -> prime  (N -> the Nth prime)
 *   - product_of_list/2   : list -> product (used to build Gödel/Euclid numbers)
 *
 * Together they form the "prime utilities for arithmetization" concept the
 * manuscript names in automata.pl (Gödel numbering) and re-uses in the Euclid
 * incoherence proof (axioms_number_theory, included by sequent_engine).
 *
 * Following the Wave 1 pattern (crosswalk/canonical_vocabulary.pl), this module
 * renames nothing. It adds ONE canonical, read-only union query that ranges
 * over the real source predicates and tags each result with the source layer it
 * came from. The underlying predicates are untouched.
 *
 * Because the three operations have different shapes, the canonical predicate
 * takes a tagged QUERY term and returns a RESULT, normalizing to:
 *
 *   godel_primes_unified(+Query, -Result, -Source)
 *
 * where Query is one of:
 *   - is_prime(N)         : Result = true     iff N is prime         (else fails)
 *   - nth_prime(N)        : Result = the Nth prime (1-indexed)
 *   - product_of_list(L)  : Result = the arithmetic product of list L
 *
 * Source names the owning layer:
 *   - automata        : arche-trace/automata.pl  (is_prime/1, nth_prime/2)
 *   - sequent_engine  : arche-trace/sequent_engine.pl (product_of_list/2,
 *                       defined via include of formalization/axioms_number_theory.pl)
 *
 * Every source call is wrapped in catch(Goal,_,fail) + once/1 so that an absent
 * or erroring source contributes nothing, and so the query stays deterministic
 * and side-effect-free. The sources here are pure arithmetic with no
 * assert/retract, so once/1 only prunes the deterministic solution.
 *
 * Name-scope note: `godel_primes_unified` ranges over prime ARITHMETIC
 * primitives only: the primality test, the Nth prime, and the list product
 * that other layers fold into Goedel/Euclid numbers. It does not encode syntax,
 * number a formula, or build a Goedel sentence, and no syntax-arithmetization
 * step is wired here. The `godel` slug records where automata.pl and the Euclid
 * incoherence proof reuse these primitives; it does not claim this module
 * performs Goedel numbering.
 */
:- module(cw_godel_primes,
          [ godel_primes_unified/3,   % godel_primes_unified(+Query, -Result, -Source)
            godel_primes_witness/4,   % godel_primes_witness(+Query, -Result, ?Source, -Witness)
            canonical_concept/2,      % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2       % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

% Real source modules. Empty import lists: we call everything module-qualified,
% so nothing is pulled into this module's namespace (no clash on is_prime/1,
% which both automata and the sequent_engine-included number_theory file define).
:- use_module(arche_trace(automata), []).
:- use_module(arche_trace(sequent_engine), []).

%! godel_primes_unified(+Query, -Result, -Source) is nondet.
%
%  Canonical union query over the scattered prime/arithmetization utilities.
%  See module header for the Query/Result/Source contract.

% --- is_prime(N): primality test, normalized to Result = true ---
godel_primes_unified(is_prime(N), true, automata) :-
    godel_primes_witness(is_prime(N), true, automata, _).

% --- nth_prime(N): the Nth prime (1-indexed) ---
godel_primes_unified(nth_prime(N), Prime, automata) :-
    godel_primes_witness(nth_prime(N), Prime, automata, _).

% --- product_of_list(L): arithmetic product of a list of numbers ---
godel_primes_unified(product_of_list(L), Product, sequent_engine) :-
    godel_primes_witness(product_of_list(L), Product, sequent_engine, _).

%! godel_primes_witness(+Query, -Result, ?Source, -Witness) is semidet.
%
%  Witnessed form of `godel_primes_unified/3`. This is a closed-world finite
%  projection over the currently loaded prime/arithmetization utilities. It
%  does not prove arbitrary number theory; it records the bounded arithmetic
%  check or finite enumeration that made this concrete query succeed.
godel_primes_witness(Query, Result, Source,
                     WitnessDict86) :-
    witness_dict:witness_dict(godel_prime_utility_crosswalk, closed_world_finite_loaded_godel_prime_utilities,
                              _{source: Source,
                        legacy_functor: LegacyFunctor,
                        query: Query,
                        result: Result,
                        derivation: Derivation,
                        source_witness: SourceWitness }, WitnessDict86),
    godel_prime_source(Source, LegacyFunctor),
    source_godel_prime_witness(Source,
                               Query,
                               Result,
                               Derivation,
                               SourceWitness).

godel_prime_source(automata, 'automata:is_prime/1 or automata:nth_prime/2').
godel_prime_source(sequent_engine, 'sequent_engine:product_of_list/2').

source_godel_prime_witness(automata,
                           is_prime(N),
                           true,
                           automata_primality_check,
                           SourceWitness) :-
    catch(once(automata:is_prime(N)), _, fail),
    prime_check_witness(N, SourceWitness).
source_godel_prime_witness(automata,
                           nth_prime(N),
                           Prime,
                           automata_prime_enumeration,
                           _{ kind: nth_prime_enumeration,
                              index: N,
                              prime: Prime,
                              prefix: Prefix,
                              prefix_length: N,
                              final_prime_witness: PrimeWitness }) :-
    positive_integer(N),
    catch(once(automata:nth_prime(N, Prime)), _, fail),
    prime_prefix(N, Prefix),
    last(Prefix, Prime),
    prime_check_witness(Prime, PrimeWitness).
source_godel_prime_witness(sequent_engine,
                           product_of_list(List),
                           Product,
                           sequent_engine_product_fold,
                           _{ kind: product_of_list_fold,
                              list: List,
                              product: Product,
                              identity: 1,
                              steps: Steps }) :-
    catch(once(sequent_engine:product_of_list(List, Product)), _, fail),
    product_trace(List, 1, Product, Steps).

positive_integer(N) :-
    integer(N),
    N > 0.

prime_check_witness(2,
                    _{ kind: primality_check,
                       number: 2,
                       result: prime,
                       reason: first_prime }) :-
    !.
prime_check_witness(N,
                    _{ kind: primality_check,
                       number: N,
                       result: prime,
                       parity: odd,
                       divisor_search: finite_odd_divisors_up_to_floor_sqrt,
                       upper_bound: Bound,
                       candidates_checked: Candidates,
                       rejected_divisors: Candidates }) :-
    integer(N),
    N > 2,
    N mod 2 =\= 0,
    floor_sqrt(N, Bound),
    odd_divisor_candidates(3, Bound, Candidates),
    no_divides(N, Candidates).

floor_sqrt(N, Bound) :-
    Bound is floor(sqrt(N)).

odd_divisor_candidates(D, Bound, []) :-
    D > Bound,
    !.
odd_divisor_candidates(D, Bound, [D|Rest]) :-
    D =< Bound,
    D2 is D + 2,
    odd_divisor_candidates(D2, Bound, Rest).

no_divides(_, []).
no_divides(N, [D|Rest]) :-
    N mod D =\= 0,
    no_divides(N, Rest).

prime_prefix(N, Prefix) :-
    findall(Prime,
            ( between(1, N, I),
              catch(once(automata:nth_prime(I, Prime)), _, fail)
            ),
            Prefix),
    length(Prefix, N).

product_trace([], Product, Product, []).
product_trace([Factor|Rest],
              AccIn,
              Product,
              [_{ factor: Factor,
                  accumulator_in: AccIn,
                  accumulator_out: AccOut }|Steps]) :-
    number(Factor),
    AccOut is AccIn * Factor,
    product_trace(Rest, AccOut, Product, Steps).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
%
%  Maps each scattered legacy functor to this family's canonical query predicate.
%  The axioms_number_theory variant of is_prime/1 is recorded for provenance: it
%  is a file-scope clone (no module of its own; included into sequent_engine and
%  not re-exported), so it is reachable in spirit through the sequent_engine
%  product_of_list grounding but is not separately wired as a value source.
canonical_concept('automata:is_prime/1',                       godel_primes_unified).
canonical_concept('automata:nth_prime/2',                      godel_primes_unified).
canonical_concept('sequent_engine:product_of_list/2',          godel_primes_unified).
canonical_concept('axioms_number_theory:is_prime/1',           godel_primes_unified).
canonical_concept('axioms_number_theory:product_of_list/2',    godel_primes_unified).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(godel_primes_unified,
    [ 'automata:is_prime/1',
      'automata:nth_prime/2',
      'sequent_engine:product_of_list/2',
      'axioms_number_theory:is_prime/1',
      'axioms_number_theory:product_of_list/2' ]).
