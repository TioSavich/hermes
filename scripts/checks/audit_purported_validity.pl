:- encoding(utf8).
/** <module> Audit: does each action automaton compute what it purports?
 *
 * For every kind with an execution-verified input contract
 * (knowledge/strategies/automaton_input_contracts.pl), run the
 * automaton on its own contract example and hold validity claims
 * against the executed outcome:
 *
 *   validity(correct)                => result == expected
 *   validity(correct_but_inefficient) => result == expected
 *   validity(incorrect)              => result \== expected
 *   validity(contextually_correct)   => result == expected on this input
 *   validity(contextually_incorrect) => result \== expected on this input
 *   validity(accidentally_correct)   => result == expected on this input
 *
 * A row can fail four ways, each reported separately:
 *   purport_broken   - the validity claim contradicts the execution.
 *   no_expected      - the outcome purports a validity but carries no
 *                      expected/1 field to check it against, so the
 *                      claim is unauditable as data.
 *   did_not_run      - the automaton fails on its own verified example.
 *   validity_not_auditable - an unfamiliar validity atom has no declared
 *                      per-input semantics, so the audit does not guess.
 *
 * Kinds WITHOUT a contract are counted per family as the coverage gap:
 * they are exactly the automata that cannot yet be audited
 * automatically, which is a finding, not a footnote.
 *
 * Run (from the repo root):
 *   swipl -q -l paths.pl -l scripts/checks/audit_purported_validity.pl \
 *         -g audit_purported_validity:audit -t halt
 */

:- module(audit_purported_validity,
          [ audit/0,
            separating_example/4,
            deformation_separates_on/4
          ]).

:- use_module(library(http/json)).
:- use_module(strategies(math/action_automata_registry),
              [ run_action_automaton/6, action_automaton_signature/4 ]).
:- use_module(strategies(automaton_input_contracts),
              [ automaton_input_contract/5 ]).

% --- JSON example -> run_action_automaton argument pair -------------------

example_args(Dict, A, B) :-
    is_dict(Dict),
    ( get_dict(kind, Dict, "fraction_pair") ; get_dict(kind, Dict, 'fraction_pair') ),
    !,
    get_dict(left, Dict, L), get_dict(right, Dict, R),
    get_dict(n, L, N1), get_dict(d, L, D1),
    get_dict(n, R, N2), get_dict(d, R, D2),
    A = fraction_pair(N1, D1, N2, D2),
    B = unit(whole).
example_args(Dict, A, B) :-
    is_dict(Dict),
    ( get_dict(kind, Dict, "decimal_pair") ; get_dict(kind, Dict, 'decimal_pair') ),
    !,
    get_dict(left, Dict, L), get_dict(right, Dict, R),
    get_dict(numeral, L, N1), get_dict(scale, L, S1),
    get_dict(numeral, R, N2), get_dict(scale, R, S2),
    A = decimal_pair(N1, S1, N2, S2),
    B = ignored.
example_args(Dict, A, B) :-
    is_dict(Dict),
    kindmatch(Dict, "fraction_addend_pair"), !,
    fraction_of(Dict, left, L), fraction_of(Dict, right, R),
    A = fraction_addend_pair(L, R), B = unit(whole).
example_args(Dict, A, B) :-
    is_dict(Dict),
    kindmatch(Dict, "fraction_minuend_subtrahend"), !,
    fraction_of(Dict, left, L), fraction_of(Dict, right, R),
    A = fraction_minuend_subtrahend(L, R), B = unit(whole).
example_args(Dict, A, B) :-
    is_dict(Dict),
    kindmatch(Dict, "cardinality"), !,
    get_dict(count, Dict, A0), get_dict(base, Dict, Base),
    A = A0, B = base(Base).
example_args(Dict, A, B) :-
    is_dict(Dict),
    kindmatch(Dict, "fraction_solve"), !,
    get_dict(coefficient, Dict, C),
    get_dict(n, C, N), get_dict(d, C, D),
    get_dict(total, Dict, B),
    A = solve(N, D).
example_args(Dict, A, B) :-
    is_dict(Dict),
    kindmatch(Dict, "rational_limit"), !,
    get_dict(numerator, Dict, Nd), get_dict(denominator, Dict, Dd),
    get_dict(coefficients, Nd, NC), get_dict(coefficients, Dd, DC),
    get_dict(at, Dict, At),
    A = rational_expression(NC, DC),
    B = limit_at(At).
example_args(Dict, A, B) :-
    is_dict(Dict),
    kindmatch(Dict, "terminal_path_tree"), !,
    get_dict(paths, Dict, Paths0),
    maplist(json_path, Paths0, Paths),
    get_dict(stake, Dict, Stake),
    A = Paths, B = stake(Stake).
example_args(Dict, A, B) :-
    is_dict(Dict),
    kindmatch(Dict, "collection_pair"), !,
    get_dict(left, Dict, L), get_dict(right, Dict, R),
    get_dict(left_extent, Dict, LE), get_dict(right_extent, Dict, RE),
    A = counts(L, R), B = extents(LE, RE).
example_args(Dict, A, B) :-
    is_dict(Dict),
    kindmatch(Dict, "count_pair"), !,
    get_dict(left, Dict, L), get_dict(right, Dict, R),
    get_dict(base, Dict, Base),
    A = counts(L, R), B = base(Base).
example_args(Dict, A, B) :-
    is_dict(Dict),
    get_dict(a, Dict, A), get_dict(b, Dict, B), !.

kindmatch(Dict, K) :-
    get_dict(kind, Dict, V),
    ( V == K -> true ; atom_string(V, K) ).

fraction_of(Dict, Side, frac(N, D)) :-
    get_dict(Side, Dict, F),
    get_dict(n, F, N), get_dict(d, F, D).

json_path(P, terminal(Winner, probability(N, D), Events)) :-
    get_dict(winner, P, W0), to_atom(W0, Winner),
    get_dict(probability, P, Pr),
    get_dict(n, Pr, N), get_dict(d, Pr, D),
    get_dict(events, P, Es0), maplist(to_atom, Es0, Events).

to_atom(X, A) :- ( atom(X) -> A = X ; atom_string(A, X) ).

% --- one row --------------------------------------------------------------

audit_row(Op, Kind, Verdict) :-
    automaton_input_contract(Op, Kind, _Shape, ExampleAtom, _),
    atom_string(ExampleAtom, S),
    atom_json_dict(S, Dict, []),
    (   \+ example_args(Dict, _, _)
    ->  Verdict = unmapped_shape
    ;   example_args(Dict, A, B),
        (   catch(run_action_automaton(Op, Kind, A, B, Outcome, _Trace), E,
                  ( Verdict = errored(E), fail ))
        ->  outcome_verdict(Outcome, Verdict)
        ;   ( var(Verdict) -> Verdict = did_not_run ; true )
        )
    ).

outcome_verdict(action_outcome(_, Fields), Verdict) :-
    (   memberchk(validity(V), Fields)
    ->  (   memberchk(result(Res), Fields), memberchk(expected(Exp), Fields)
        ->  validity_pair_verdict(V, Res, Exp, Verdict)
        ;   Verdict = no_expected(V)
        )
    ;   Verdict = no_validity_claim
    ).

validity_pair_verdict(V, Res, Exp, Verdict) :-
    (   validity_expectation(V, Relation, Category)
    ->  (   pair_relation_holds(Relation, Res, Exp)
        ->  ( Category == standard
            -> Verdict = ok(V)
            ;  Verdict = nonstandard_consistent(V) )
        ;   Verdict = purport_broken(V, result(Res), expected(Exp))
        )
    ;   Verdict = validity_not_auditable(V)
    ).

validity_expectation(correct, equal, standard).
validity_expectation(correct_but_inefficient, equal, standard).
validity_expectation(incorrect, different, standard).
validity_expectation(contextually_correct, equal, nonstandard).
validity_expectation(contextually_incorrect, different, nonstandard).
validity_expectation(accidentally_correct, equal, nonstandard).

pair_relation_holds(equal, R, E) :- R == E.
pair_relation_holds(different, R, E) :- R \== E.



% --- layer 2: independent ground truth ------------------------------------
%
% Where the contract example determines a mathematical answer, compute it
% here with plain arithmetic — never by reading the outcome — and check
% kinds that claim correct against it. Self-certifying rows
% (expected sharing result's variable in the source) pass layer 1 by
% construction; this layer is the one that can catch them.

truth(addition, _, A, B, number(T)) :- integer(A), integer(B), T is A + B.
% compare_by_matching_difference answers "how many more", an unsigned
% count; the signed-difference reading was a false positive of this
% audit's first pass.
truth(subtraction, compare_by_matching_difference, A, B, number(T)) :-
    !, integer(A), integer(B), T is abs(A - B).
truth(subtraction, _, A, B, number(T)) :- integer(A), integer(B), T is A - B.
truth(multiplication, Kind, A, B, number(T)) :-
    \+ non_product_multiplication_kind(Kind),
    integer(A), integer(B), T is A * B.
truth(division, Kind, A, B, T) :-
    integer(A), integer(B), B =\= 0, Q is A // B, R is A mod B,
    (   result_is_quotient_remainder(Kind) -> T = qr(Q, R)
    ;   R =:= 0 -> T = number(Q)
    ;   T = qr(Q, R)
    ).

truth(counting, _, Count, base(_), number(Count)) :- integer(Count).
truth(counting, _, counts(A, B), _, order(O)) :- cmp_order(A, B, O).
truth(fraction, Kind, fraction_pair(N1, D1, N2, D2), unit(whole), T) :-
    V1 is N1 rdiv D1, V2 is N2 rdiv D2,
    (   ( sub_atom(Kind, _, _, _, part_of_part)
        ; sub_atom(Kind, _, _, _, cross_multiplication) )
    ->  V is V1 * V2, T = rat(V)
    ;   sub_atom(Kind, _, _, _, measurement_division)
    ->  V is V1 / V2, T = rat(V)
    ;   cmp_order(V1, V2, O), T = order(O)
    ).
truth(fraction, _, fraction_addend_pair(frac(N1, D1), frac(N2, D2)),
      unit(whole), rat(V)) :-
    V is N1 rdiv D1 + N2 rdiv D2.
truth(fraction, _, fraction_minuend_subtrahend(frac(N1, D1), frac(N2, D2)),
      unit(whole), rat(V)) :-
    V is N1 rdiv D1 - N2 rdiv D2.
truth(decimal, Kind, decimal_pair(N1, S1, N2, S2), _, T) :-
    V1 is N1 rdiv S1, V2 is N2 rdiv S2,
    (   sub_atom(Kind, _, _, _, comparison)
    ->  cmp_order(V1, V2, O), T = order(O)
    ;   sub_atom(Kind, _, _, _, add) -> V is V1 + V2, T = rat(V)
    ;   sub_atom(Kind, _, _, _, subtract) -> V is V1 - V2, T = rat(V)
    ;   sub_atom(Kind, _, _, _, multiplication) -> V is V1 * V2, T = rat(V)
    ;   fail
    ).

% These tasks compute factor or multiple structures, not products. They
% remain explicitly without a Layer-2 adapter until their list-shaped
% results and gcd/lcm/factor-list truths are normalized together.
non_product_multiplication_kind(common_factor_intersection).
non_product_multiplication_kind(common_multiple_sequence).
non_product_multiplication_kind(add_numbers_as_common_multiple).
non_product_multiplication_kind(factors_of_first_number_only).

result_is_quotient_remainder(long_division).
result_is_quotient_remainder(partial_quotient_chunking).
result_is_quotient_remainder(stop_after_first_partial_quotient).

% Value equivalence: a quotient-remainder with zero remainder and the
% bare quotient are the same answer in different dress.
results_equal(X, X) :- !.
results_equal(qr(Q, 0), number(Q)) :- !.
results_equal(number(Q), qr(Q, 0)) :- !.

cmp_order(V1, V2, greater_than) :- V1 > V2, !.
cmp_order(V1, V2, less_than) :- V1 < V2, !.
cmp_order(_, _, equal).

% normalize_result(+ResultTerm, -Normal): defensive, extended as result
% shapes are met; unknown shapes are reported, never guessed at.
normalize_result(R, number(R)) :- number(R), !.
normalize_result(share_size(S), number(S)) :- number(S), !.
normalize_result(quotient_remainder(Q, Rem), qr(Q, Rem)) :- !.
normalize_result(fraction(N, D), rat(V)) :- !, V is N rdiv D.
normalize_result(sum(N, D), rat(V)) :- integer(N), integer(D), !, V is N rdiv D.
normalize_result(greater_than, order(greater_than)) :- !.
normalize_result(less_than, order(less_than)) :- !.
normalize_result(equal, order(equal)) :- !.
normalize_result(equal_value, order(equal)) :- !.
normalize_result(R, rat(V)) :- R = N rdiv D, integer(N), integer(D), !, V is N rdiv D.
normalize_result(_, unknown).

truth_verdict(Op, Kind, A, B, Fields, TV) :-
    (   \+ truth(Op, Kind, A, B, _)
    ->  TV = no_truth_adapter
    ;   truth(Op, Kind, A, B, Truth),
        memberchk(result(Res), Fields),
        normalize_result(Res, Norm),
        (   Norm == unknown
        ->  TV = result_shape_unknown(Res)
        ;   memberchk(validity(V), Fields),
            (   validity_expectation(V, Relation, _)
            ->  truth_relation_verdict(Relation, V, Norm, Truth, TV)
            ;   TV = validity_not_auditable(V)
            )
        )
    ).

truth_relation_verdict(equal, V, Norm, Truth, TV) :-
    ( results_equal(Norm, Truth) -> TV = truth_ok(V)
    ; TV = wrong_while_purporting_correct(V, Norm, Truth) ).
truth_relation_verdict(different, V, Norm, Truth, TV) :-
    ( results_equal(Norm, Truth) -> TV = right_while_purporting_incorrect(V, Norm)
    ; TV = truth_ok(V) ).

audit_truth :-
    format('~n=== LAYER 2: independent ground truth (catches self-certifying rows) ===~n'),
    findall(Op-Kind-TV,
            ( automaton_input_contract(Op, Kind, _, ExampleAtom, _),
              atom_string(ExampleAtom, S),
              atom_json_dict(S, Dict, []),
              example_args(Dict, A, B),
              catch(run_action_automaton(Op, Kind, A, B,
                                         action_outcome(_, Fields), _), _, fail),
              truth_verdict(Op, Kind, A, B, Fields, TV)
            ),
            Rows),
    include([_-_-truth_ok(_)]>>true, Rows, OkR),
    include([_-_-wrong_while_purporting_correct(_,_,_)]>>true, Rows, WrongR),
    include([_-_-right_while_purporting_incorrect(_,_)]>>true, Rows, RightR),
    include([_-_-no_truth_adapter]>>true, Rows, NoAd),
    include([_-_-result_shape_unknown(_)]>>true, Rows, NoShape),
    include([_-_-validity_not_auditable(_)]>>true, Rows, NoValidity),
    length(Rows, N), length(OkR, NOk), length(WrongR, NW),
    length(RightR, NRt), length(NoAd, NNa), length(NoShape, NNs),
    length(NoValidity, NNV),
    format('rows with executable outcome: ~w~n', [N]),
    format('  truth check passes:                        ~w~n', [NOk]),
    format('  WRONG while purporting correct:            ~w~n', [NW]),
    format('  RIGHT while purporting incorrect (example fails to witness the bug): ~w~n', [NRt]),
    format('  no truth adapter for family/shape yet:     ~w~n', [NNa]),
    format('  result shape not yet normalizable:         ~w~n', [NNs]),
    format('  validity atom not auditable:                ~w~n', [NNV]),
    ( NW > 0 ->
        format('~n--- wrong while purporting correct ---~n'),
        forall(member(Op-K-wrong_while_purporting_correct(V, Got, Want), WrongR),
               format('  ~w/~w (~w): computed ~w, truth ~w~n', [Op, K, V, Got, Want]))
    ; true ),
    ( NRt > 0 ->
        format('~n--- deformations not witnessed by their own contract example ---~n'),
        forall(member(Op-K-right_while_purporting_incorrect(V, Got), RightR),
               ( format('  ~w/~w (~w): example yields the true answer ~w', [Op, K, V, Got]),
                 ( separating_example(Op, K, SA, SB)
                 -> format('; separating example found: ~w, ~w~n', [SA, SB])
                 ;  format('; no separating example in the search grid~n', []) )
               ))
    ; true ),
    NW =:= 0,
    NRt =:= 0,
    NNV =:= 0.

% Search a small grid for an input on which the deformation's result
% differs from the truth — the example a contract needs in order to
% witness the bug it claims.
separating_example(Op, Kind, A, B) :-
    candidate_input(Op, A, B),
    deformation_separates_on(Op, Kind, input(A, B), _),
    !.

%!  deformation_separates_on(+Operation, +Kind, +Input, -Evidence) is semidet.
%
%   Decide whether this concrete input separates a deformation's executed
%   result from independently computed truth. Unlike separating_example/4,
%   this predicate does not search or substitute its own input.
deformation_separates_on(Op, Kind, input(A, B),
                          evidence(result(Norm), truth(Truth))) :-
    catch(run_action_automaton(Op, Kind, A, B,
                               action_outcome(_, Fields), _), _, fail),
    memberchk(classification(deformation), Fields),
    truth(Op, Kind, A, B, Truth),
    memberchk(result(Res), Fields),
    normalize_result(Res, Norm),
    Norm \== unknown,
    \+ results_equal(Norm, Truth).

candidate_input(division, A, B) :-
    member(A, [96, 84, 75, 47]), member(B, [4, 6, 7, 28]).
candidate_input(fraction, fraction_pair(N1, D1, N2, D2), unit(whole)) :-
    member(N1-D1-N2-D2,
           [ 1-4-2-3, 2-3-3-8, 1-2-3-5, 5-6-7-9, 3-4-5-7 ]).
candidate_input(addition, A, B) :-
    member(A, [47, 38, 29]), member(B, [28, 17, 6]).
candidate_input(decimal, decimal_pair(N1, S1, N2, S2), ignored) :-
    member(N1-S1-N2-S2,
           [ 3-10-25-100,     % 0.3 vs 0.25: bare-numeral comparison inverts
             7-10-65-100,
             12-100-3-10 ]).

% --- report ---------------------------------------------------------------

audit :-
    format('AUDIT: purported vs computed validity, one contract example per kind~n~n'),
    findall(Op-Kind-V,
            ( automaton_input_contract(Op, Kind, _, _, _),
              ( audit_row(Op, Kind, V) -> true ; V = errored_or_failed )
            ),
            Rows),
    length(Rows, NRows),
    partition_verdicts(Rows, Ok, Broken, NoExp, NoRun, Odd),
    length(Ok, NOk), length(Broken, NB), length(NoExp, NE),
    length(NoRun, NR), length(Odd, NO),
    format('contracted kinds audited: ~w~n', [NRows]),
    format('  claim holds on execution:      ~w~n', [NOk]),
    format('  PURPORT BROKEN:                ~w~n', [NB]),
    format('  purports validity, no expected: ~w~n', [NE]),
    format('  did not run / errored:         ~w~n', [NR]),
    format('  nonstandard / not auditable:    ~w~n~n', [NO]),
    ( NB > 0 ->
        format('--- purport broken ---~n'),
        forall(member(Op-K-V, Broken), format('  ~w/~w: ~w~n', [Op, K, V])), nl
    ; true ),
    ( NE > 0 ->
        format('--- unauditable: validity claimed, no expected field ---~n'),
        forall(member(Op-K-no_expected(V), NoExp),
               format('  ~w/~w claims ~w~n', [Op, K, V])), nl
    ; true ),
    ( NR > 0 ->
        format('--- failed on own verified example ---~n'),
        forall(member(Op-K-V, NoRun), format('  ~w/~w: ~w~n', [Op, K, V])), nl
    ; true ),
    report_nonstandard(Odd),
    aggregate_all(count, member(_-_-validity_not_auditable(_), Odd), NUnknown),
    NB =:= 0,
    NE =:= 0,
    NR =:= 0,
    NUnknown =:= 0,
    coverage_gap,
    audit_truth.

partition_verdicts([], [], [], [], [], []).
partition_verdicts([R|Rs], Ok, Br, NE, NRun, Odd) :-
    partition_verdicts(Rs, Ok0, Br0, NE0, NRun0, Odd0),
    (   R = _-_-ok(_)                -> Ok = [R|Ok0], Br=Br0, NE=NE0, NRun=NRun0, Odd=Odd0
    ;   R = _-_-purport_broken(_,_,_)-> Br = [R|Br0], Ok=Ok0, NE=NE0, NRun=NRun0, Odd=Odd0
    ;   R = _-_-no_expected(_)       -> NE = [R|NE0], Ok=Ok0, Br=Br0, NRun=NRun0, Odd=Odd0
    ;   ( R = _-_-did_not_run ; R = _-_-errored(_) ; R = _-_-errored_or_failed )
                                     -> NRun = [R|NRun0], Ok=Ok0, Br=Br0, NE=NE0, Odd=Odd0
    ;   Odd = [R|Odd0], Ok=Ok0, Br=Br0, NE=NE0, NRun=NRun0
    ).

report_nonstandard([]).
report_nonstandard(Rows) :-
    Rows \== [],
    format('--- nonstandard validity categories ---~n'),
    findall(V, member(_-_-nonstandard_consistent(V), Rows), Consistent0),
    msort(Consistent0, Consistent), clumped(Consistent, ConsistentCounts),
    forall(member(V-N, ConsistentCounts),
           format('  ~w, per-input claim consistent: ~w~n', [V, N])),
    findall(V, member(_-_-validity_not_auditable(V), Rows), Unknown0),
    msort(Unknown0, Unknown), clumped(Unknown, UnknownCounts),
    forall(member(V-N, UnknownCounts),
           format('  ~w, not auditable: ~w~n', [V, N])),
    forall(( member(Op-K-Verdict, Rows),
             Verdict \= nonstandard_consistent(_),
             Verdict \= validity_not_auditable(_) ),
           format('  ~w/~w: ~w~n', [Op, K, Verdict])),
    nl.

coverage_gap :-
    format('--- coverage gap: registered kinds with NO contract (not yet auditable) ---~n'),
    findall(Op, ( action_automaton_signature(Op, Kind, _, _),
                  \+ automaton_input_contract(Op, Kind, _, _, _) ), Ops),
    msort(Ops, Sorted),
    clumped(Sorted, Counts),
    forall(member(Op-N, Counts), format('  ~w: ~w~n', [Op, N])),
    length(Ops, Total),
    aggregate_all(count, action_automaton_signature(_, _, _, _), NSig),
    format('  total: ~w of ~w registered kinds~n', [Total, NSig]).
