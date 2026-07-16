/** <module> Bounded finite incompatibility-set discovery
 *
 * This module discovers candidate incompatibility sets under a deliberately
 * finite bound. It does not prove global material incompatibility. Candidate
 * terms come from the loaded program's vocabulary, are asserted only into a
 * scratch context, and are classified with an inference limit so loops are
 * recorded as bounded nontermination rather than hanging the run.
 *
 * Consolidation (2026-07): the canonical incompatibility relation lives in
 * `arche-trace/brandomian_incompatibility.pl`; this module is a FEEDER for
 * it. Classification here never changes the canonical relation by itself. A
 * caller that wants discovered sets recorded as hyperedges runs
 * `install_discovered_hyperedges/2` explicitly (discovery proposes, the
 * relational engine records), and `uninstall_discovered_hyperedges/0`
 * reverses exactly that contribution. Bounded nontermination is never
 * installed: it is a search result under an inference limit, not a verdict
 * that a set cannot be jointly held. The Big Red cache route through
 * `arche-trace/incompatibility_sets.pl` is unchanged.
 */
:- module(incompatibility_discovery,
          [ discover_incompatibility_set/2,
            discover_incompatibility_set_witness/3,
            classify_candidate_set/3,
            classify_candidate_set_witness/4,
            candidate_set/2,
            candidate_vocabulary/2,
            install_discovered_hyperedges/2,   % +Context, -NewlyInstalled
            uninstall_discovered_hyperedges/0,
            discovery_hyperedge/2              % ?Context, ?Set (bookkeeping)
          ]).

:- use_module(library(lists)).
:- use_module(misconceptions(misconception_registry),
              [ incompatibility_with/2,
                misconception_registry_entry/5
              ]).
:- use_module(math(action_automata_registry),
              [ action_automaton_pair/4
              ]).
:- use_module(arche_trace(defeasible_inference),
              [ material_inference/3,
                defeater_vocabulary/1,
                classify_defeat/3
              ]).
:- use_module(arche_trace(brandomian_incompatibility),
              [ incompatible_set/1,
                add_incompatible_set/1,
                retract_incompatible_set/1
              ]).

:- dynamic scratch_fact/2.
:- dynamic scratch_rule/2.
:- dynamic cached_registry_pairs/1.
:- dynamic registry_cache_loaded/0.


%!  discover_incompatibility_set(?Context, -Set) is nondet.
%
%   True when Set is a bounded candidate set whose scratch execution in
%   Context reaches incoherence or an inference-bound nontermination.
discover_incompatibility_set(Context, Set) :-
    discover_incompatibility_set_witness(Context, Set, _).


%!  discover_incompatibility_set_witness(?Context, -Set, -Witness) is nondet.
%
%   Witnessed form of `discover_incompatibility_set/2`. This is the
%   closed-world finite case: candidates are generated from the local finite
%   vocabulary for Context, then classified under the configured inference
%   bound. It is not a global incompatibility oracle for an open language.
%   Registry-neighborhood discovery prefers the tracked Big Red cache because
%   live registry enumeration is a slow fallback, not the maintained cold path.
discover_incompatibility_set_witness(registry_neighborhood, Set,
                                     _{ kind: bounded_finite_incompatibility_discovery,
                                        scope: bigred_cached_registry_neighborhood_grid,
                                        requested_context: registry_neighborhood,
                                        context: registry_neighborhood,
                                        set: Set,
                                        source: bigred_cache,
                                        cache_file: Cache,
                                        outcome: incoherent(cached_bigred_discovery),
                                        classifier_witness: _{
                                            kind: bigred_cached_candidate_classification,
                                            context: registry_neighborhood,
                                            source: bigred_cache
                                        } }) :-
    registry_cache_file(Cache),
    ensure_registry_cache_loaded(Cache),
    incompatibility_sets:discovered_set_fact(registry_neighborhood, Set),
    Set = [_, _ | _].
discover_incompatibility_set_witness(Context0, Set,
                                     _{ kind: bounded_finite_incompatibility_discovery,
                                        scope: closed_world_finite_candidate_grid,
                                        requested_context: Context0,
                                        context: Context,
                                        set: Set,
                                        outcome: Outcome,
                                        classifier_witness: ClassificationWitness }) :-
    canonical_context(Context0, Context),
    candidate_set(Context, Set),
    classify_candidate_set_witness(Context, Set, Outcome, ClassificationWitness),
    discovered_outcome(Outcome).



%!  classify_candidate_set(+Context, +Set, -Outcome) is det.
%
%   Outcome is one of coherent, incoherent(Witness), or nonterminating(Bound).
classify_candidate_set(Context, Set, Outcome) :-
    classify_candidate_set_witness(Context, Set, Outcome, _).


%!  classify_candidate_set_witness(+Context, +Set, -Outcome, -Witness) is det.
%
%   Classify Set under the finite closed-world Context and return the concrete
%   reason the bounded engine used. Nontermination is a bounded search result,
%   recorded with the inference limit, not an assertion about the open system.
classify_candidate_set_witness(Context0, Set0, Outcome,
                               _{ kind: bounded_candidate_classification,
                                  scope: Scope,
                                  requested_context: Context0,
                                  context: Context,
                                  requested_set: Set0,
                                  normalized_set: Set,
                                  inference_bound: Bound,
                                  outcome: Outcome,
                                  classifier_witness: ClassifierWitness,
                                  outcome_witness: OutcomeWitness }) :-
    canonical_context(Context0, Context),
    normalized_candidate_set(Context, Set0, Set),
    inference_bound(Bound),
    context_scope(Context, Scope),
    classify_candidate_set_core(Context, Set, Outcome, ClassifierWitness, OutcomeWitness).


% Defeasible material-inference cells: a candidate is an inference plus a set of
% commitments hotswapped into its context; the outcome is read off the
% consequence relation (survives / defeated / emergent), not asserted.
classify_candidate_set_core(defeasible_inference, Set, Outcome,
                            _{ kind: defeasible_inference_classification,
                               inference: Id,
                               defeaters: Defeaters,
                               classifier: classify_defeat },
                            _{ kind: defeasible_inference_classifier_result,
                               inference: Id,
                               defeaters: Defeaters,
                               outcome: Outcome }) :-
    !,
    ( Set = [inference(Id)|Defeaters]
    ->  classify_defeat(Id, Defeaters, Outcome)
    ;   Outcome = coherent
    ).
classify_candidate_set_core(Context, Set, Outcome,
                            _{ kind: scratch_context_classification,
                               asserted_set: Set,
                               limit_result: Result,
                               scratch_witness: ScratchWitness },
                            ScratchWitness) :-
    inference_bound(Bound),
    setup_call_cleanup(
        assert_candidate_set(Context, Set),
        call_with_limit_result(classify_scratch(Context, Bound, Outcome0, ScratchWitness0),
                               Bound,
                               Result),
        clear_scratch_context(Context)
    ),
    inference_result_outcome(Result, Bound, Outcome0, Outcome),
    scratch_witness(Result, Bound, Outcome, ScratchWitness0, ScratchWitness).


%!  candidate_set(?Context, -Set) is nondet.
%
%   Enumerate a small finite candidate grid from program vocabulary.
candidate_set(Context0, Set) :-
    nonvar(Context0),
    !,
    canonical_context(Context0, Context),
    candidate_set_core(Context, Set).
candidate_set(Context, Set) :-
    candidate_set_core(Context, Set).


candidate_set_core(finite_three_rule_program, Set) :-
    candidate_vocabulary(finite_three_rule_program, Vocabulary),
    between(1, 3, K),
    choose_n(K, Vocabulary, Set).
candidate_set_core(finite_loop_program, Set) :-
    candidate_vocabulary(finite_loop_program, Vocabulary),
    between(1, 1, K),
    choose_n(K, Vocabulary, Set).
% Real candidate space: per-term neighborhoods. For each anchor term, enumerate
% the small (anchor + 1..MaxExtra) commitment sets drawn from that anchor's
% neighborhood (terms it already relates to via incompatibility_with). Every set
% INCLUDES the anchor, so each cell asks "does this anchor sit in a jointly
% incoherent small group?". Hard-bounded by env-overridable caps so a laptop run
% stays tiny and a Big Red run widens the same code. Honest scope: over the
% registry this surfaces neighborhoods containing a known clash; genuinely
% emergent hyperedges (no binary clash, jointly incoherent) need rule dynamics,
% which only the finite fixture programs carry today.
candidate_set_core(registry_neighborhood, Set) :-
    neighborhood_anchor(Anchor),
    neighborhood_of(Anchor, Neighbors),
    anchor_subset(Anchor, Neighbors, Set).

% Defeasible material-inference candidates: each material inference crossed with
% size 1..2 defeater subsets from the defeater vocabulary. The sweep asks, for
% each inference, which added commitments defeat it (and which do so only as a
% set — the emergent hyperedges).
candidate_set_core(defeasible_inference, [inference(Id)|Defeaters]) :-
    material_inference(Id, _, _),
    defeater_vocabulary(Vocabulary),
    between(1, 2, K),
    choose_n(K, Vocabulary, Defeaters).


canonical_context(Context, finite_three_rule_program) :-
    nonvar(Context),
    Context == toy_three_rule_program,
    !.
canonical_context(Context, finite_loop_program) :-
    nonvar(Context),
    Context == toy_loop_program,
    !.
canonical_context(Context, Context).


registry_cache_file(Cache) :-
    absolute_file_name(arche_trace('data/incompatibility_sets_discovered.pl'),
                       Cache,
                       [ access(read), file_errors(fail) ]).

ensure_registry_cache_loaded(Cache) :-
    registry_cache_loaded,
    !,
    exists_file(Cache).
ensure_registry_cache_loaded(Cache) :-
    consult(Cache),
    assertz(registry_cache_loaded).


context_scope(finite_three_rule_program,
              closed_world_finite_fixture_three_rule_closure).
context_scope(finite_loop_program,
              closed_world_finite_fixture_loop_with_inference_limit).
context_scope(registry_neighborhood,
              closed_world_finite_registry_neighborhood_grid).
context_scope(defeasible_inference,
              closed_world_finite_defeasible_inference_grid).
context_scope(_Context,
              closed_world_finite_candidate_grid).


%!  candidate_cap(+Key, -Value) is det.
%
%   Env-overridable bounds: ITER7_TERM_CAP anchors, ITER7_NEIGHBOR_CAP neighbors
%   per anchor, ITER7_MAX_EXTRA members beyond the anchor. Defaults laptop-small.
candidate_cap(term_cap, V)     :- env_int('ITER7_TERM_CAP', 40, V).
candidate_cap(neighbor_cap, V) :- env_int('ITER7_NEIGHBOR_CAP', 8, V).
candidate_cap(max_extra, V)    :- env_int('ITER7_MAX_EXTRA', 2, V).

env_int(Var, Default, Value) :-
    ( getenv(Var, Atom), atom_number(Atom, N), integer(N), N >= 0
    -> Value = N
    ;  Value = Default
    ).


%!  neighborhood_anchor(-Anchor) is nondet.
%
%   Ground left-hand sides of incompatibility_with/2, optionally restricted to a
%   set of new terms (ITER7_NEW_TERMS file) for incremental runs.
neighborhood_anchor(Anchor) :-
    findall(A, ( incompatibility_with(A, _), ground(A) ), As0),
    sort(As0, AllAnchors),
    restrict_to_new_terms(AllAnchors, Restricted),
    candidate_cap(term_cap, Cap),
    first_n(Cap, Restricted, Anchors),
    member(Anchor, Anchors).

restrict_to_new_terms(All, Restricted) :-
    ( getenv('ITER7_NEW_TERMS', Path), exists_file(Path)
    -> read_new_terms(Path, New),
       include(anchor_is_new(New), All, Restricted0),
       ( Restricted0 == [] -> Restricted = All ; Restricted = Restricted0 )
    ;  Restricted = All
    ).

anchor_is_new(New, Anchor) :-
    term_string(Anchor, AnchorText, [quoted(false)]),
    memberchk(AnchorText, New).

read_new_terms(Path, Terms) :-
    setup_call_cleanup(
        open(Path, read, In),
        read_string(In, _, Whole),
        close(In)
    ),
    split_string(Whole, "\n", " \t\r", Lines0),
    exclude(==(""), Lines0, Terms).


%!  neighborhood_of(+Anchor, -Neighbors) is det.
neighborhood_of(Anchor, Neighbors) :-
    findall(B,
            ( ( incompatibility_with(Anchor, B)
              ; incompatibility_with(B, Anchor)
              ),
              ground(B),
              B \== Anchor
            ),
            Bs0),
    sort(Bs0, Bs1),
    candidate_cap(neighbor_cap, NCap),
    first_n(NCap, Bs1, Neighbors).


%!  anchor_subset(+Anchor, +Neighbors, -Set) is nondet.
%
%   Sets of size anchor + 1..MaxExtra, always including the anchor.
anchor_subset(Anchor, Neighbors, [Anchor|Rest]) :-
    candidate_cap(max_extra, MaxExtra),
    between(1, MaxExtra, R),
    choose_n(R, Neighbors, Rest).


%!  candidate_vocabulary(?Context, -Vocabulary) is det.
candidate_vocabulary(Context0, Vocabulary) :-
    nonvar(Context0),
    !,
    canonical_context(Context0, Context),
    candidate_vocabulary_core(Context, Vocabulary).
candidate_vocabulary(Context, Vocabulary) :-
    candidate_vocabulary_core(Context, Vocabulary).


candidate_vocabulary_core(finite_three_rule_program,
                     [ rule(a_requires_b),
                       rule(b_requires_c),
                       rule(a_forbids_c)
                     ]).
candidate_vocabulary_core(finite_loop_program,
                     [ rule(loop_self)
                     ]).
candidate_vocabulary_core(registry_neighborhood, Vocabulary) :-
    bounded_registry_pairs(Pairs),
    pairs_terms(Pairs, Terms0),
    sort(Terms0, Vocabulary).


discovered_outcome(incoherent(_)).
discovered_outcome(nonterminating(_)).


inference_bound(50000).


call_with_limit_result(Goal, Bound, Result) :-
    (   call_with_inference_limit(Goal, Bound, Result0)
    ->  Result = Result0
    ;   Result = false
    ).


inference_result_outcome(inference_limit_exceeded, Bound, _Outcome0, nonterminating(Bound)) :-
    !.
inference_result_outcome(true, _Bound, Outcome, Outcome) :-
    !.
inference_result_outcome(!, _Bound, Outcome, Outcome) :-
    !.
inference_result_outcome(false, _Bound, _Outcome0, coherent) :-
    !.
inference_result_outcome(_Other, _Bound, Outcome, Outcome).


assert_candidate_set(Context, Set) :-
    forall(member(Term, Set),
           assert_candidate(Context, Term)).


assert_candidate(Context, rule(Name)) :-
    !,
    assertz(scratch_rule(Context, rule(Name))).
assert_candidate(Context, Term) :-
    assertz(scratch_fact(Context, Term)).


clear_scratch_context(Context) :-
    retractall(scratch_fact(Context, _)),
    retractall(scratch_rule(Context, _)).


classify_scratch(Context, _Bound, nonterminating(_),
                 _{ kind: finite_loop_detected,
                    rule: rule(loop_self) }) :-
    scratch_rule(Context, rule(loop_self)),
    !,
    loop_forever.
classify_scratch(finite_three_rule_program, _Bound, incoherent(Witness), Witness) :-
    !,
    finite_fixture_closure(finite_three_rule_program, Facts),
    finite_fixture_incoherence(Facts, Witness),
    !.
classify_scratch(finite_loop_program, _Bound, incoherent(Witness), Witness) :-
    !,
    finite_fixture_closure(finite_loop_program, Facts),
    finite_fixture_incoherence(Facts, Witness),
    !.
classify_scratch(registry_neighborhood, _Bound, incoherent(Witness), Witness) :-
    !,
    findall(Term, scratch_fact(registry_neighborhood, Term), Terms0),
    sort(Terms0, Terms),
    known_incompatible_pair_witness(Terms, Witness),
    !.
classify_scratch(_Context, _Bound, coherent,
                 _{ kind: no_bounded_incoherence_found }).


loop_forever :-
    loop_forever.


finite_fixture_closure(Context, Facts) :-
    findall(Fact, finite_fixture_seed_fact(Context, Fact), Seeds0),
    findall(Fact, scratch_fact(Context, Fact), ScratchFacts),
    append(Seeds0, ScratchFacts, Facts0),
    sort(Facts0, Seeds),
    finite_fixture_closure(Context, Seeds, Facts).


finite_fixture_seed_fact(finite_three_rule_program, commitment(a)).
finite_fixture_seed_fact(finite_loop_program, commitment(a)).


finite_fixture_closure(Context, Facts0, Facts) :-
    findall(NewFact,
            ( scratch_rule(Context, rule(Rule)),
              finite_fixture_rule_fires(Rule, Facts0, NewFact),
              \+ memberchk(NewFact, Facts0)
            ),
            NewFacts0),
    sort(NewFacts0, NewFacts),
    (   NewFacts == []
    ->  Facts = Facts0
    ;   append(Facts0, NewFacts, Facts1),
        sort(Facts1, Facts2),
        finite_fixture_closure(Context, Facts2, Facts)
    ).


finite_fixture_rule_fires(a_requires_b, Facts, commitment(b)) :-
    memberchk(commitment(a), Facts).
finite_fixture_rule_fires(b_requires_c, Facts, commitment(c)) :-
    memberchk(commitment(b), Facts).
finite_fixture_rule_fires(a_forbids_c, Facts, forbidden(c)) :-
    memberchk(commitment(a), Facts).


finite_fixture_incoherence(Facts,
                           _{ kind: finite_fixture_incoherence,
                              facts: Facts,
                              commitment: commitment(Value),
                              forbidden: forbidden(Value),
                              reason: commitment_and_forbidden_same_value }) :-
    member(commitment(Value), Facts),
    memberchk(forbidden(Value), Facts).


known_incompatible_pair(Terms, A, B) :-
    select(A, Terms, Rest),
    member(B, Rest),
    terms_incompatible(A, B),
    !.


terms_incompatible(A, B) :-
    incompatibility_with(A, B),
    !.
terms_incompatible(A, B) :-
    incompatibility_with(B, A).


known_incompatible_pair_witness(Terms,
                                _{ kind: registry_neighborhood_incompatibility,
                                   terms_checked: Terms,
                                   pair: [A, B],
                                   relation: incompatibility_with }) :-
    known_incompatible_pair(Terms, A, B).


bounded_registry_pair(A, B) :-
    bounded_registry_pairs(Pairs),
    member(A-B, Pairs).


bounded_registry_pairs(Pairs) :-
    cached_registry_pairs(Pairs),
    !.
bounded_registry_pairs(Pairs) :-
    findall(A-B,
            ( registry_vocabulary_pair(A, B),
              ground(A),
              ground(B)
            ),
            Pairs0),
    sort(Pairs0, Sorted),
    first_n(24, Sorted, Pairs),
    assertz(cached_registry_pairs(Pairs)).


registry_vocabulary_pair(A, B) :-
    incompatibility_with(A, B).
registry_vocabulary_pair(Commitment, Entitlement) :-
    misconception_registry_entry(_Name,
                                 _Operation,
                                 _Citation,
                                 Commitment,
                                 Entitlement),
    Commitment \=@= Entitlement.
registry_vocabulary_pair(misconception(Name), Entitlement) :-
    misconception_registry_entry(Name,
                                 _Operation,
                                 _Citation,
                                 Commitment,
                                 Entitlement),
    Commitment \=@= Entitlement.
registry_vocabulary_pair(strategy(Operation, Productive),
                         misconception(Deformation)) :-
    action_automaton_pair(Operation, Productive, Deformation, _Family).


pairs_terms([], []).
pairs_terms([A-B|Pairs], [A, B|Terms]) :-
    pairs_terms(Pairs, Terms).


canonical_set(Set0, Set) :-
    sort(Set0, Set).


normalized_candidate_set(defeasible_inference, Set, Set) :-
    !.
normalized_candidate_set(_Context, Set0, Set) :-
    canonical_set(Set0, Set).


scratch_witness(inference_limit_exceeded, Bound, nonterminating(Bound), _ScratchWitness,
                _{ kind: bounded_nontermination,
                   inference_bound: Bound,
                   reason: inference_limit_exceeded }) :-
    !.
scratch_witness(_Result, _Bound, _Outcome, ScratchWitness, ScratchWitness).


choose_n(0, _List, []) :-
    !.
choose_n(N, [Head|Tail], [Head|Rest]) :-
    N > 0,
    N1 is N - 1,
    choose_n(N1, Tail, Rest).
choose_n(N, [_Head|Tail], Rest) :-
    N > 0,
    choose_n(N, Tail, Rest).


first_n(N, List, Prefix) :-
    length(Prefix, N),
    append(Prefix, _Rest, List),
    !.
first_n(_N, List, List).


% =================================================================
% Bridge to the canonical relation
% (discovery proposes, the relational engine records)
% =================================================================

%!  discovery_hyperedge(?Context, ?Set) is nondet.
%
%   Bookkeeping: a hyperedge this module installed into
%   brandomian_incompatibility:incompatible_set/1, keyed by the discovery
%   context that proposed it. uninstall_discovered_hyperedges/0 retracts
%   exactly these; seeds and other feeders' sets are left alone.
:- dynamic discovery_hyperedge/2.


%!  install_discovered_hyperedges(+Context, -NewlyInstalled) is det.
%
%   Run bounded discovery over Context and record each set classified
%   incoherent(_) as a hyperedge in the canonical relation. Explicit and
%   reversible, matching the feeder contract documented in
%   brandomian_incompatibility.pl: nothing is installed by use_module, and
%   uninstall_discovered_hyperedges/0 restores the prior state.
%
%   Outcomes of nonterminating(_) are refused: bounded nontermination is a
%   search result under an inference limit, not a verdict that the set
%   cannot be jointly held. Sets already present in the relation (seeds, the
%   registry adapter, any other feeder) are skipped, not claimed.
%   NewlyInstalled counts only this call's additions, so an immediate
%   repeat yields 0.
install_discovered_hyperedges(Context0, NewlyInstalled) :-
    canonical_context(Context0, Context),
    findall(ContentSet,
            ( discover_incompatibility_set_witness(Context, Set, Witness),
              get_dict(outcome, Witness, incoherent(_)),
              discovered_content_set(Context, Set, ContentSet0),
              sort(ContentSet0, ContentSet),
              ContentSet = [_, _|_]      % hyperedges relate >= 2 contents
            ),
            Sets0),
    sort(Sets0, Sets),
    install_content_sets(Sets, Context, 0, NewlyInstalled).

install_content_sets([], _Context, N, N).
install_content_sets([Set|Sets], Context, N0, N) :-
    (   discovery_hyperedge(_, Set)
    ->  N1 = N0
    ;   incompatible_set(Set)
    ->  N1 = N0                          % pre-existing; not ours to manage
    ;   add_incompatible_set(Set),
        assertz(discovery_hyperedge(Context, Set)),
        N1 is N0 + 1
    ),
    install_content_sets(Sets, Context, N1, N).


%!  uninstall_discovered_hyperedges is det.
%
%   Retract exactly the hyperedges this module installed.
uninstall_discovered_hyperedges :-
    forall(retract(discovery_hyperedge(_, Set)),
           retract_incompatible_set(Set)).


%!  discovered_content_set(+Context, +DiscoveredSet, -ContentSet) is det.
%
%   Map a discovery candidate to the content set its classification
%   witnessed as jointly unholdable. Defeasible candidates have the shape
%   [inference(Id)|Defeaters]; the incoherent context there is the
%   inference's premises together with the added defeaters, so that combined
%   context is what the relation records. Every other context classifies the
%   candidate set itself.
discovered_content_set(defeasible_inference, [inference(Id)|Defeaters], ContentSet) :-
    !,
    material_inference(Id, Premises, _Conclusion),
    append(Premises, Defeaters, ContentSet).
discovered_content_set(_Context, Set, Set).
