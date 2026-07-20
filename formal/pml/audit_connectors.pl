/** <module> Audit of cross-module Prolog connectors
 *
 * This module exposes a single entry-point predicate `audit_connectors/1`
 * that walks every bridge between the project's Prolog modules and
 * reports its current state. It exists because the registry has grown
 * to the point where the surface between modules is bigger than any
 * one module's documentation describes, and a small mechanical check
 * is the cheapest way to keep the surface honest as the modules drift.
 *
 * The connectors audited:
 *
 *   A. MUA practice -> executable surface coverage
 *      Every practice/2 in formal/pml/mua_relations.pl should resolve either
 *      through practice_kind/3 back to the action registry OR through a
 *      declared runtime predicate via practice_predicate/2.
 *
 *   B. practice_kind/3 entries that don't dispatch in the registry
 *      (a stale MUA practice pointing at a removed kind).
 *
 *   C. Registry kinds without a corresponding MUA practice. By design
 *      MUA is a curated subset (the LX-relevant productives plus the
 *      newer diagnostic/calculus/algebraic axes); this audit reports
 *      the count and the names so the gap is visible, not so it must
 *      be filled.
 *
 *   D. mua_relations:grounding_metaphor/2 entries that the
 *      grounding_metaphors module cannot resolve to a full metaphor
 *      id via grounding_metaphor_for_practice/2.
 *
 *   E. grounding_metaphor_definition/4 entries without
 *      metaphor_kind/2 (would mean the MUDs page would get a
 *      missing-field record).
 *
 *   F. The deontic scorekeeper -> sequent bridge: probes
 *      proves_via_sequent_core/1 with a reflexive sequent to confirm
 *      the bridge loads and the prover answers.
 *
 *   G. lx_for/3 meta-vocabularies that no practice deploys via
 *      pv_sufficient/2 (the LX relation would be unreachable from
 *      any practice).
 *
 *   H. pp_sufficient/3 elaboration targets without an executable surface
 *      (the MUA-derived material inference would land on a phantom).
 *
 * `audit_connectors(report)` prints a human-readable report.
 * `audit_connectors(strict)` prints the same report AND fails if any
 * connector that is *meant* to be exhaustive (A, B, D, E, F, G, H)
 * is not. C is informational only.
 */

:- module(audit_connectors,
          [ audit_connectors/1,
            connector_status/2,
            connector_witness/2
          ]).

:- use_module(pml(mua_relations)).
:- use_module(pml(mua_health), [ practice_executable/1 ]).
:- use_module(formalization(grounding_metaphors)).
:- use_module(math(action_automata_registry)).
:- use_module(learner(deontic_scorekeeper)).


%!  audit_connectors(+Mode) is semidet.
%
%   Mode is `report` (always succeeds, prints a summary) or `strict`
%   (succeeds iff every exhaustive bridge is clean; informational
%   bridges are still printed). Strict mode is suitable for the
%   validation harness.
audit_connectors(report) :-
    print_audit(_).
audit_connectors(strict) :-
    print_audit(Failed),
    Failed =:= 0.


print_audit(FailedCount) :-
    a_practice_to_kind(AFail),
    b_practice_kind_to_registry(BFail),
    c_registry_to_mua_practice(_),  % informational; never fails
    d_mua_grounding_to_metaphor(DFail),
    e_metaphor_kind_coverage(EFail),
    f_sequent_bridge(FFail),
    g_lx_meta_voc_pv_reach(GFail),
    h_pp_sufficient_to_kind(HFail),
    FailedCount is AFail + BFail + DFail + EFail + FFail + GFail + HFail,
    format('~n[audit_connectors] summary: ~w exhaustive-bridge failure(s); ~w informational gap section(s) reported.~n',
           [FailedCount, 1]).


%% ---- A ---- %%
a_practice_to_kind(Fail) :-
    findall(P, practice(P, _), Ps), length(Ps, N),
    findall(P, (practice(P, _), \+ practice_executable(P)), Bad),
    length(Bad, Fail),
    format('A. MUA practices: ~w; without executable surface: ~w~n', [N, Fail]),
    forall(member(P, Bad), format('     - ~w~n', [P])).


%% ---- B ---- %%
b_practice_kind_to_registry(Fail) :-
    findall(P-Op-K, practice_kind(P, Op, K), Ks), length(Ks, N),
    findall(P-Op-K,
            ( member(P-Op-K, Ks),
              \+ action_automaton_cluster(Op, K, _)
            ),
            Bad),
    length(Bad, Fail),
    format('B. practice_kind/3 entries: ~w; without registry dispatch: ~w~n',
           [N, Fail]),
    forall(member(B, Bad), format('     - ~w~n', [B])).


%% ---- C ---- %%
%% Informational. Registry kinds without an MUA practice are tracked
%% but not flagged as failure; MUA is a curated subset by design.
c_registry_to_mua_practice(Gap) :-
    findall(Op:K, action_automaton_cluster(Op, K, _), Rks),
    sort(Rks, Sorted),
    length(Sorted, N),
    findall(Op:K,
            ( member(Op:K, Sorted),
              \+ practice_kind(_, Op, K)
            ),
            Gap0),
    sort(Gap0, Gap),
    length(Gap, GapN),
    format('C. Registry (operation, kind) entries: ~w; without MUA practice: ~w [informational]~n', [N, GapN]).


%% ---- D ---- %%
d_mua_grounding_to_metaphor(Fail) :-
    findall(P-Short,
            ( mua_relations:grounding_metaphor(P, Short),
              Short \== no_metaphor_grounding,
              \+ grounding_metaphor_for_practice(P, _)
            ),
            Bad),
    length(Bad, Fail),
    format('D. MUA grounding_metaphor/2 -> grounding_metaphors module unmappable: ~w~n', [Fail]),
    forall(member(B, Bad), format('     - ~w~n', [B])).


%% ---- E ---- %%
e_metaphor_kind_coverage(Fail) :-
    findall(M, grounding_metaphor_definition(M, _, _, _), Mids),
    findall(M, (member(M, Mids), \+ metaphor_kind(M, _)), Bad),
    length(Mids, N), length(Bad, Fail),
    format('E. Metaphor definitions: ~w; without metaphor_kind/2: ~w~n',
           [N, Fail]),
    forall(member(M, Bad), format('     - ~w~n', [M])).


%% ---- F ---- %%
%% Reflexive sequent of an arbitrary atom; if the sequent core is loaded
%% and answering, this always proves. If the catch in
%% proves_via_sequent_core/1 swallows a load error and silently fails,
%% the audit reports it as a failure here.
f_sequent_bridge(Fail) :-
    ( deontic_scorekeeper:proves_via_sequent_core(
                              ([s(audit_sentinel)] => [s(audit_sentinel)]))
    -> Fail = 0,
       format('F. Sequent bridge: callable; reflexive sequent proved.~n')
    ;  Fail = 1,
       format('F. Sequent bridge: failed to prove reflexive sequent (check that sequent_engine loads cleanly).~n')
    ).


%% ---- G ---- %%
g_lx_meta_voc_pv_reach(Fail) :-
    findall(VM, lx_for(VM, _, _), VMs),
    sort(VMs, Unique),
    findall(VM,
            ( member(VM, Unique),
              \+ pv_sufficient(_, VM)
            ),
            Bad),
    length(Unique, N), length(Bad, Fail),
    format('G. Distinct LX-meta vocabularies: ~w; without any practice that deploys them: ~w~n', [N, Fail]),
    forall(member(V, Bad), format('     - ~w~n', [V])).


%% ---- H ---- %%
h_pp_sufficient_to_kind(Fail) :-
    findall(E,
            ( pp_sufficient(_, E, _),
              \+ practice_executable(E)
            ),
            Bad),
    length(Bad, Fail),
    format('H. PP-sufficient elaboration targets without executable surface: ~w~n',
           [Fail]),
    forall(member(E, Bad), format('     - ~w~n', [E])).


%!  connector_status(?ConnectorTag, ?Status) is nondet.
%
%   Programmatic accessor. Tag is one of {a,b,c,d,e,f,g,h};
%   Status is `clean(N)` (N is the count audited) or
%   `fail(N, Items)` for exhaustive connectors that have failures,
%   or `info(N, GapItems)` for the informational C connector.
connector_status(a, Status) :-
    a_count(N, Bad),
    ( Bad == [] -> Status = clean(N) ; length(Bad, NB), Status = fail(NB, Bad) ).
connector_status(b, Status) :-
    b_count(N, Bad),
    ( Bad == [] -> Status = clean(N) ; length(Bad, NB), Status = fail(NB, Bad) ).
connector_status(c, info(N, Gap)) :- c_count(N, Gap).
connector_status(d, Status) :-
    d_count(Bad),
    ( Bad == [] -> Status = clean(0) ; length(Bad, NB), Status = fail(NB, Bad) ).
connector_status(e, Status) :-
    e_count(N, Bad),
    ( Bad == [] -> Status = clean(N) ; length(Bad, NB), Status = fail(NB, Bad) ).
connector_status(f, Status) :-
    ( deontic_scorekeeper:proves_via_sequent_core(
                              ([s(audit_sentinel)] => [s(audit_sentinel)]))
    -> Status = clean(1)
    ;  Status = fail(1, [sequent_bridge_does_not_answer])
    ).
connector_status(g, Status) :-
    g_count(N, Bad),
    ( Bad == [] -> Status = clean(N) ; length(Bad, NB), Status = fail(NB, Bad) ).
connector_status(h, Status) :-
    h_count(Bad),
    ( Bad == [] -> Status = clean(0) ; length(Bad, NB), Status = fail(NB, Bad) ).

%!  connector_witness(?ConnectorTag, -Witness) is nondet.
%
%   Human-readable proof object for a connector audit section. This predicate
%   keeps connector_status/2 as the compact compatibility API while exposing
%   the evidence predicates, exhaustiveness policy, failures, and caveat needed
%   by delegated sanitation agents.
connector_witness(Tag,
                  _{ tag: Tag,
                     name: Name,
                     status: StatusAtom,
                     audited_count: AuditedCount,
                     failure_count: FailureCount,
                     failures: Failures,
                     exhaustive: Exhaustive,
                     evidence_predicates: EvidencePredicates,
                     caveat: Caveat }) :-
    connector_metadata(Tag, Name, Exhaustive, EvidencePredicates, Caveat),
    connector_status(Tag, Status),
    normalize_connector_status(Status, StatusAtom, AuditedCount, FailureCount, Failures).

normalize_connector_status(clean(N), clean, N, 0, []).
normalize_connector_status(fail(N, Items), fail, N, N, Items).
normalize_connector_status(info(N, Items), info, N, GapCount, Items) :-
    length(Items, GapCount).

connector_metadata(a,
                   mua_practice_executable_surface_coverage,
                   true,
                   [practice/2, practice_executable/1],
                   every_mua_practice_must_resolve_to_registry_or_runtime_surface).
connector_metadata(b,
                   practice_kind_registry_dispatch,
                   true,
                   [practice_kind/3, action_automaton_cluster/3],
                   every_declared_practice_kind_must_dispatch_in_registry).
connector_metadata(c,
                   registry_kind_without_mua_practice,
                   false,
                   [action_automaton_cluster/3, practice_kind/3],
                   mua_is_curated_subset_so_registry_gap_is_informational).
connector_metadata(d,
                   mua_grounding_metaphor_resolution,
                   true,
                   [grounding_metaphor/2, grounding_metaphor_for_practice/2],
                   non_no_metaphor_grounding_entries_must_resolve_to_metaphor_id).
connector_metadata(e,
                   metaphor_definition_kind_coverage,
                   true,
                   [grounding_metaphor_definition/4, metaphor_kind/2],
                   every_metaphor_definition_needs_kind_for_muds_page_records).
connector_metadata(f,
                   deontic_sequent_bridge,
                   true,
                   [proves_via_sequent_core/1],
                   bridge_must_prove_reflexive_sentinel_sequent).
connector_metadata(g,
                   lx_meta_vocabulary_reachability,
                   true,
                   [lx_for/3, pv_sufficient/2],
                   lx_claim_is_reachable_only_when_meta_vocabulary_has_deploying_practice).
connector_metadata(h,
                   pp_sufficient_target_executable_surface,
                   true,
                   [pp_sufficient/3, practice_executable/1],
                   pp_sufficient_material_inference_must_land_on_executable_practice).

a_count(N, Bad) :-
    findall(P, practice(P, _), Ps), length(Ps, N),
    findall(P, (practice(P, _), \+ practice_executable(P)), Bad).
b_count(N, Bad) :-
    findall(P-Op-K, practice_kind(P, Op, K), Ks), length(Ks, N),
    findall(P-Op-K,
            ( member(P-Op-K, Ks),
              \+ action_automaton_cluster(Op, K, _)
            ), Bad).
c_count(N, Gap) :-
    findall(Op:K, action_automaton_cluster(Op, K, _), Rks),
    sort(Rks, Sorted),
    length(Sorted, N),
    findall(Op:K,
            ( member(Op:K, Sorted),
              \+ practice_kind(_, Op, K)
            ),
            Gap0),
    sort(Gap0, Gap).
d_count(Bad) :-
    findall(P-Short,
            ( mua_relations:grounding_metaphor(P, Short),
              Short \== no_metaphor_grounding,
              \+ grounding_metaphor_for_practice(P, _)
            ),
            Bad).
e_count(N, Bad) :-
    findall(M, grounding_metaphor_definition(M, _, _, _), Mids),
    length(Mids, N),
    findall(M, (member(M, Mids), \+ metaphor_kind(M, _)), Bad).
g_count(N, Bad) :-
    findall(VM, lx_for(VM, _, _), VMs),
    sort(VMs, Unique),
    length(Unique, N),
    findall(VM, (member(VM, Unique), \+ pv_sufficient(_, VM)), Bad).
h_count(Bad) :-
    findall(E,
            ( pp_sufficient(_, E, _),
              \+ practice_executable(E)
            ),
            Bad).
