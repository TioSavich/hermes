:- module(pattern_detectors, [
    detect_patterns/4
]).

:- use_module(introspection).
:- use_module(pattern_taxonomy).
:- use_module(library(lists)).

%!  detect_patterns(+Strategy:atom, +Clauses:list, -Patterns:list, -Evidence:list) is det.
%
%   Run every detector against Clauses. Patterns is the sorted, deduped set
%   of pat_* atoms that fired. Evidence is a list of
%   evidence(Pattern, ClauseHead, Goal) triples.
detect_patterns(_Strategy, Clauses, Patterns, Evidence) :-
    collect_body_goals(Clauses, AllGoals),
    collect_state_names(Clauses, AllStateNames),
    findall(P-E,
            ( all_patterns(Ps),
              member(P, Ps),
              run_detector(P, Clauses, AllGoals, AllStateNames, E)
            ),
            Hits),
    pairs_to_patterns_evidence(Hits, Patterns, Evidence).

pairs_to_patterns_evidence(Hits, Patterns, Evidence) :-
    findall(P, member(P-_, Hits), Ps0),
    sort(Ps0, Patterns),
    findall(evidence(P, H, G),
            member(P-evidence(H, G), Hits),
            Evidence).

collect_body_goals([], []).
collect_body_goals([clause(_H, B)|T], Goals) :-
    walk_body(B, G1),
    collect_body_goals(T, G2),
    append(G1, G2, Goals).

collect_state_names(Clauses, Names) :-
    findall(N,
            ( member(clause(H, B), Clauses),
              ( state_term_names(H, Ns1) ; state_term_names(B, Ns1) ),
              member(N, Ns1)
            ),
            Raw),
    collect_bare_state_atoms(Clauses, Bare),
    append(Raw, Bare, All),
    sort(All, Names).

%   Bare state-atom transitions (e.g. transition(q_init, q_determine_order, Label))
%   have head args that are atoms, not state(...) terms. Harvest those too.
collect_bare_state_atoms([], []).
collect_bare_state_atoms([clause(H, _)|T], Atoms) :-
    ( H = transition(A, B, _), atom(A), atom(B) -> Atoms1 = [A, B]
    ; H = transition(A, _Base, B, _), atom(A), atom(B) -> Atoms1 = [A, B]
    ; Atoms1 = []
    ),
    collect_bare_state_atoms(T, Atoms2),
    append(Atoms1, Atoms2, Atoms).

%!  run_detector(+Pattern:atom, +Clauses, +Goals, +StateNames, -Evidence) is semidet.

run_detector(pat_successor_loop, Clauses, _Goals, _SN, evidence(Head, Pair)) :-
    member(clause(Head, Body), Clauses),
    walk_body(Body, G),
    has_functor(G, successor/2, SuccG),
    ( has_functor(G, smaller_than/2, GuardG)
    ; has_functor(G, (<)/2, GuardG)
    ; has_functor(G, (>)/2, GuardG)
    ; has_functor(G, (=<)/2, GuardG)
    ; has_functor(G, (>=)/2, GuardG)
    ),
    !,
    Pair = (GuardG, SuccG).

run_detector(pat_predecessor_loop, Clauses, _Goals, _SN, evidence(Head, Witness)) :-
    member(clause(Head, Body), Clauses),
    walk_body(Body, G),
    ( has_functor(G, predecessor/2, Witness)
    ; has_functor(G, subtract_grounded/3, Witness),
      has_functor(G, integer_to_recollection/2, ItoR),
      ItoR = integer_to_recollection(1, _)
    ),
    !.

run_detector(pat_accumulator_addition, Clauses, _Goals, _SN, evidence(Head, AddG)) :-
    member(clause(Head, Body), Clauses),
    walk_body(Body, G),
    has_functor(G, add_grounded/3, AddG),
    clause_next_state_matches_source_register(Head, Body),
    !.

run_detector(pat_base_decomposition, _Clauses, Goals, _SN, evidence(meta, Witness)) :-
    has_functor(Goals, base_decompose_grounded/4, Witness),
    !.

run_detector(pat_base_recomposition, _Clauses, Goals, _SN, evidence(meta, Witness)) :-
    has_functor(Goals, base_recompose_grounded/4, Witness),
    !.

run_detector(pat_target_base_adjustment, Clauses, Goals, _SN, evidence(meta, Witness)) :-
    ( has_functor(Goals, calculate_next_base_grounded/2, Witness)
    ; has_functor(Goals, multiply_grounded/3, MulG),
      member(clause(_, Body), Clauses),
      walk_body(Body, BG),
      has_functor(BG, successor/2, SuccG),
      has_functor(BG, multiply_grounded/3, MulG),
      Witness = (SuccG, MulG)
    ),
    !.

run_detector(pat_leading_chunk_extraction, _Clauses, Goals, _SN, evidence(meta, Witness)) :-
    ( has_functor(Goals, leading_digit_chunk/3, Witness)
    ; has_functor(Goals, leading_place_value/3, Witness)
    ),
    !.

run_detector(pat_partial_product_accumulation, _Clauses, _Goals, StateNames, evidence(meta, Witness)) :-
    substrategy_signature(ppa_shape, Shape),
    proper_superset(StateNames, Shape),
    Witness = subset_of(ppa_shape),
    !.

run_detector(pat_fact_lookup, _Clauses, Goals, _SN, evidence(meta, Witness)) :-
    ( has_functor(Goals, find_best_fact/4, Witness)
    ; has_functor(Goals, find_largest_known_multiple/4, Witness)
    ; has_functor(Goals, find_known_fact/3, Witness)
    ),
    !.

run_detector(pat_list_redistribution, Clauses, Goals, _SN, evidence(meta, Witness)) :-
    % (a) update_list/4 co-occurring with nth0/3-4 anywhere in the goals.
    ( has_functor(Goals, update_list/4, UpG),
      ( has_functor(Goals, nth0/4, NG)
      ; has_functor(Goals, nth0/3, NG)
      ; has_functor(Goals, nth1/3, NG)
      ),
      Witness = (NG, UpG)
    % (b) twin nth0/4 idiom in the same clause body: extract + reinsert.
    ; member(clause(_, Body), Clauses),
      walk_body(Body, GL),
      findall(G, (member(G, GL), goal_functor(G, nth0/4)), Nth0s),
      length(Nth0s, N), N >= 2,
      Witness = (twin_nth0_4, Nth0s)
    ),
    !.

run_detector(pat_error_branch, _Clauses, _Goals, StateNames, evidence(meta, q_error)) :-
    member(q_error, StateNames),
    !.

run_detector(pat_sub_strategy_invocation, _Clauses, _Goals, StateNames, evidence(meta, Shape)) :-
    substrategy_signature(Shape, Sig),
    \+ Shape = ppa_shape,
    proper_superset(StateNames, Sig),
    !.

%!  has_functor(+Goals:list, +FA:term, -MatchingGoal:term) is semidet.
%
%   True if some goal in Goals has functor/arity matching FA (module qualifier
%   stripped). MatchingGoal is the first such goal.
has_functor(Goals, F/A, G) :-
    member(G0, Goals),
    goal_functor(G0, F/A),
    !,
    strip_module_qualifier(G0, G).

%!  proper_superset(+Set:list, +Sub:list) is semidet.
%
%   True if every element of Sub is in Set, and Set has at least one element
%   not in Sub. Both expected sorted (or at least atomic).
proper_superset(Set, Sub) :-
    forall(member(X, Sub), memberchk(X, Set)),
    member(Y, Set),
    \+ memberchk(Y, Sub),
    !.

%!  clause_next_state_matches_source_register(+Head:compound, +Body:term) is semidet.
%
%   For pat_accumulator_addition: the add_grounded call in Body binds a
%   variable that is threaded through both the In and Out state slots of
%   Head's state(...) terms. Detect this by: Head has two state(...) terms
%   (In and Out positions), both of shape state(_, ...), and the variable
%   appearing in one positional slot of In equals the variable that, after
%   add_grounded(X, _, Y), gets bound to Y via a recollection_to_integer/2
%   round-trip in Out's corresponding slot. Implementation: check that at
%   least one of Head's state-term positional slots is occupied by a
%   variable that is mentioned as an input to add_grounded and a different
%   variable appears in the corresponding slot of Out AND is the output of
%   a recollection_to_integer/2. We approximate with a looser syntactic
%   check: there exist state(_, ..., X, ...) and state(_, ..., Y, ...) in
%   Head with X \== Y, plus add_grounded(RecX, _, RecY) in Body plus
%   integer_to_recollection(X, RecX) and recollection_to_integer(RecY, Y)
%   in Body.
clause_next_state_matches_source_register(Head, Body) :-
    walk_body(Body, Gs),
    has_functor(Gs, add_grounded/3, add_grounded(RecIn, _, RecOut)),
    has_functor(Gs, integer_to_recollection/2, integer_to_recollection(In, RecIn2)),
    RecIn == RecIn2,
    has_functor(Gs, recollection_to_integer/2, recollection_to_integer(RecOut2, Out)),
    RecOut == RecOut2,
    head_states(Head, InStateArgs, OutStateArgs),
    nth_slot(InStateArgs, In, P),
    nth_slot(OutStateArgs, Out, P),
    !.

head_states(transition(S1, S2, _), A1, A2) :-
    compound(S1), functor(S1, state, _), S1 =.. [_|A1],
    compound(S2), functor(S2, state, _), S2 =.. [_|A2].
head_states(transition(S1, _Base, S2, _), A1, A2) :-
    compound(S1), functor(S1, state, _), S1 =.. [_|A1],
    compound(S2), functor(S2, state, _), S2 =.. [_|A2].

nth_slot([H|_], X, 1) :- H == X.
nth_slot([_|T], X, N) :- nth_slot(T, X, N0), N is N0 + 1.
