/** <module> Finite incompatibility-set surface for Brandomian hyperedges
 *
 * This module is the target surface for genuine material incompatibility sets:
 * a Context has an incompatible SET of commitments, not only a binary
 * productive/deformation pair. Lesson sets are still registry-lifted, while
 * discovered sets are sourced from the bounded finite discovery engine.
 *
 * Incompatibility entailment is not computable as a complete relation over an
 * open-ended language here. This module computes the closed-world finite case:
 * the known hyperedges are the hand-listed lesson rows plus the bounded Big Red
 * discovery cache (or the same finite discovery engine for tiny local proof
 * contexts).
 *
 * Reader's rule of thumb:
 *   - `incompatibility_set/2` names a finite set that cannot be jointly held.
 *   - `incompatibility_entails/2` says A entails B when A can replace B in
 *     every known incompatibility profile for B and the profile stays
 *     incompatible.
 *   - `incompatibility_entailment_witness/3` returns the profiles checked, so
 *     the entailment is inspectable rather than a black-box yes/no.
 */
:- module(incompatibility_sets,
          [ incompatibility_set/2,
            incompatibility_entails/2,
            incompatibility_entailment_witness/3
          ]).

:- use_module(library(lists)).
:- use_module(incompat(incompatibility_discovery),
              [ discover_incompatibility_set/2
              ]).
:- use_module(incompat(brandomian_incompatibility), []).
:- use_module(misconceptions(misconception_registry),
              [ misconception_registry_entry/5 ]).

% Cached discovery results produced on Big Red (iteration7) and pulled home.
% Loading them is instant; recomputing on a laptop is the thing we are avoiding.
% Stable tracked home: formal/incompatibility/incompatibility_sets_discovered.pl
% (provenance header inside the file; regeneration steps in
% docs/bigred-incompatibility-RUNBOOK.md).
:- dynamic discovered_set_fact/2.
:- dynamic discovered_set_kind/3.   % Context, Set, Kind (emergent/defeated/...)

%!  discovered_cache_file(-Cache) is semidet.
%
%   Resolves the discovery cache through the incompat search path
%   (paths.pl), falling back to this module's own directory so a direct
%   load of this file still finds the cache. Fails when the cache file
%   is absent.
discovered_cache_file(Cache) :-
    absolute_file_name(incompat(incompatibility_sets_discovered),
                       Cache,
                       [ access(read), file_errors(fail) ]),
    !.
discovered_cache_file(Cache) :-
    prolog_load_context(directory, Dir),
    directory_file_path(Dir, 'incompatibility_sets_discovered.pl', Cache),
    exists_file(Cache).

%!  discovered_cache_load_action(+Cache, -Action) is det.
%
%   Classifies how the module should proceed for a candidate cache path.
%   This keeps the missing-cache behavior testable without moving the
%   tracked cache out of the repository.
discovered_cache_load_action(Cache, consult_cache(Cache)) :-
    exists_file(Cache),
    !.
discovered_cache_load_action(_Cache, live_discovery_fallback).


load_discovered_cache_action(consult_cache(Cache)) :-
    consult(Cache).
load_discovered_cache_action(live_discovery_fallback) :-
    warn_missing_discovery_cache.


warn_missing_discovery_cache :-
    print_message(warning,
                  format("incompatibility_sets: Big Red discovery cache \c
                          NOT FOUND at formal/incompatibility/incompatibility_sets_discovered.pl. \c
                          incompatibility_set/2 will fall back to slow LIVE discovery for \c
                          uncached contexts. Restore the tracked cache file or regenerate \c
                          it per docs/bigred-incompatibility-RUNBOOK.md.", [])).


% Consult the cache at load. A missing cache is loud, not silent: without
% it, incompatibility_set/2 degrades to live discovery — the slow registry
% sweep the Big Red job exists to avoid.
:- (   discovered_cache_file(Cache)
   ->  discovered_cache_load_action(Cache, Action),
       load_discovered_cache_action(Action)
   ;   warn_missing_discovery_cache
   ).

%!  incompatibility_set(?Context, ?Set) is nondet.
%
%   True when Set is a finite incompatible commitment set in Context, tagged
%   with provenance as set(discovered, Terms) or set(hand_listed, Terms).
%
%   Discovered sets prefer the Big Red cache (discovered_set_fact/2). Live
%   discovery is a fallback only for contexts the cache does not cover, so a
%   machine with cached results never recomputes the expensive registry sweep.
incompatibility_set(Context, set(discovered, Set)) :-
    cached_discovered_set(Context, Set).
incompatibility_set(Context, set(discovered, Set)) :-
    discover_live_context(Context),
    discover_incompatibility_set(Context, Set),
    \+ cached_discovered_set(Context, Set).
incompatibility_set(Context, set(hand_listed, Set)) :-
    lesson_incompatibility_target(Context, Name),
    registry_incompatibility_set(Name, Set).
% The formally vetted Brandomian engine's declared hyperedges are a profile
% source here, so the entailments that relation licenses (and the ones its
% guards refuse) flow through this production path instead of living in a
% parallel module that shares no data. The engine ships seed hyperedges only;
% registry-scale data enters when a caller explicitly runs
% registry_incompatibility_adapter:load_registry_hyperedges/0.
incompatibility_set(brandomian_engine, set(brandomian, Set)) :-
    brandomian_incompatibility:incompatible_set(Set).

% Finite proof-check contexts stay live because they are intentionally small
% enough for local verification. The registry sweep runs live only when the
% Big Red cache has not supplied it.
discover_live_context(finite_three_rule_program).
discover_live_context(finite_loop_program).
discover_live_context(registry_neighborhood) :-
    \+ discovered_set_fact(registry_neighborhood, _).


cached_discovered_set(Context, Set) :-
    discovered_set_fact(Context, Set),
    public_discovery_context(Context).


public_discovery_context(defeasible_inference).
public_discovery_context(registry_neighborhood).
public_discovery_context(finite_three_rule_program).
public_discovery_context(finite_loop_program).


%!  incompatibility_entails(+A, +B) is semidet.
%
%   A entails B when every known incompatibility set containing B remains
%   incompatible after B is replaced by A. This is computed from
%   incompatibility profiles, not from sequent derivability.
incompatibility_entails(A, B) :-
    incompatibility_entailment_witness(A, B, _).


%!  incompatibility_entailment_witness(+Replacement, +Replaced, -Witness) is semidet.
%
%   Positive proof object for `incompatibility_entails(Replacement, Replaced)`.
%   Each checked profile says: in Context, Replaced appears in OriginalSet; after
%   replacing it with Replacement, the ReplacementSet still contains a known
%   incompatible subset. If there is no known profile for Replaced, or any
%   replacement fails to preserve incompatibility, this predicate fails.
incompatibility_entailment_witness(A, B,
                                  _{ kind: incompatibility_entailment,
                                     replacement: A,
                                     replaced: B,
                                     profiles_checked: WitnessProfiles }) :-
    findall(Context-Set,
            ( incompatibility_terms(Context, Set),
              member_term(B, Set)
            ),
            Profiles),
    Profiles \== [],
    maplist(profile_replacement_witness(A, B), Profiles, WitnessProfiles).


profile_replacement_witness(A, B, Context-OriginalSet,
                            _{ context: Context,
                               original_set: OriginalSet,
                               replacement_set: CandidateSet,
                               witness_subset: SupportSet,
                               support_witness: SupportWitness }) :-
    replace_term(B, A, OriginalSet, CandidateSet0),
    sort(CandidateSet0, CandidateSet),
    set_incompatible_witness(Context, CandidateSet, SupportSet, SupportWitness).


lesson_incompatibility_target('IM-G1-U3-L17', count_all_when_count_on_available).
lesson_incompatibility_target('IM-G1-U3-L17', make_ten_drop_leftover).
lesson_incompatibility_target('IM-G2-U1-L3', missing_addend_as_plain_sum).


registry_incompatibility_set(Name, [Commitment, Entitlement]) :-
    misconception_registry_entry(Name, _Operation, _Citation, Commitment, Entitlement).
registry_incompatibility_set(Name, [misconception(Name), Commitment, Entitlement]) :-
    misconception_registry_entry(Name, _Operation, _Citation, Commitment, Entitlement).


set_incompatible_witness(Context, CandidateSet, KnownSet,
                         _{ kind: known_incompatible_subset,
                            scope: closed_world_finite_incompatibility_table,
                            context: Context,
                            provenance: Provenance,
                            known_set: KnownSet,
                            candidate_set: CandidateSet,
                            subset_relation: all_known_terms_member_of_candidate }) :-
    incompatibility_set(Context, set(Provenance, KnownSet)),
    subset_terms(KnownSet, CandidateSet).


incompatibility_terms(Context, Set) :-
    incompatibility_set(Context, set(_Provenance, Set)).


subset_terms([], _).
subset_terms([Term|Rest], Set) :-
    member_term(Term, Set),
    subset_terms(Rest, Set).


member_term(Term, [Head|_]) :-
    Term == Head,
    !.
member_term(Term, [_|Rest]) :-
    member_term(Term, Rest).


replace_term(_Old, _New, [], []).
replace_term(Old, New, [Head|Rest], [New|Replaced]) :-
    Old == Head,
    !,
    replace_term(Old, New, Rest, Replaced).
replace_term(Old, New, [Head|Rest], [Head|Replaced]) :-
    replace_term(Old, New, Rest, Replaced).
