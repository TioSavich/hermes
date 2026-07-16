/** <module> MUA codebook-health guard
 *
 * The standing validator for the codebook reframe. It checks that every
 * necessity/sufficiency relation in mua_relations.pl is DEMONSTRABLE against the
 * live code, not merely asserted:
 *
 *   - a PRACTICE is executable if it resolves to a real executable surface —
 *     either the action-automata registry (via practice_kind/3 + run_action_automaton)
 *     OR a runtime surface declared via practice_predicate/2 (e.g. Hermes/deontic
 *     scoring), whose predicate is actually defined.
 *   - a VOCABULARY must be declared.
 *   - an LX relation's META vocabulary must be deployed by an executable practice
 *     (the LX claim is about "the practices that deploy V_meta", so that set must
 *     be real and non-empty).
 *
 * relation_undemonstrable/2 is the drift alarm: it yields every relation that no
 * longer stands, with a reason. This is what makes the codebook self-validating
 * instead of prose that rots (Phase 1 of docs/proposals/2026-06-16-codebook-refactor.md).
 *
 * Run: swipl -q -l paths.pl -s pml/tests/test_mua_health.pl -g run_tests -t halt
 */
:- module(mua_health,
          [ practice_executable/1,        % +Practice
            relation_demonstration/2,     % ?Relation, -Witness
            relation_undemonstrable/2,    % -Relation, -Reason
            mua_health_report/1,          % -Dict
            mua_health_report_witness/1   % -Dict with status + caveat
          ]).

:- use_module(pml(mua_relations)).
:- use_module(math(action_automata_registry)).
:- use_module(hermes(event_scoring), []).   % loaded so its predicate is `defined`
:- use_module(learner(deontic_scorekeeper), []). % runtime surface for p_deontic_scorekeeping
:- use_module(render(balance_scale_scene), []). % runtime surface for p_relational_equals_balance_preservation
:- use_module(library(lists), [ member/2 ]).
:- use_module(library(apply), [ include/3 ]).

%!  practice_executable(+Practice) is semidet.
%
%   True when the practice resolves to a real executable surface.
practice_executable(P) :-
    mua_relations:practice_kind(P, Op, K),
    (   catch(action_automata_registry:action_automaton_cluster(Op, K, _), _, fail)
    ;   catch(action_automata_registry:action_automaton_vocabulary(Op, K, _), _, fail)
    ),
    !.
practice_executable(P) :-
    mua_relations:practice_predicate(P, Mod:Name/Arity),
    functor(Head, Name, Arity),
    catch(predicate_property(Mod:Head, defined), _, fail),
    !.

%!  relation_demonstration(?Relation, -Witness) is nondet.
%
%   Positive proof object for an MUA relation. These witnesses are deliberately
%   plain dictionaries: they name the declared relation and show the executable
%   practice surface or vocabulary declaration that makes the relation stand
%   against the loaded Prolog system.
relation_demonstration(pv_sufficient(P, V),
                       _{ kind: pv_sufficient,
                          practice: P,
                          vocabulary: V,
                          practice_surface: Surface,
                          vocabulary_description: VDesc }) :-
    mua_relations:pv_sufficient(P, V),
    practice_surface(P, Surface),
    mua_relations:vocabulary(V, VDesc).
relation_demonstration(vp_sufficient(V, P),
                       _{ kind: vp_sufficient,
                          vocabulary: V,
                          practice: P,
                          vocabulary_description: VDesc,
                          practice_surface: Surface }) :-
    mua_relations:vp_sufficient(V, P),
    mua_relations:vocabulary(V, VDesc),
    practice_surface(P, Surface).
relation_demonstration(pp_necessary(A, B),
                       _{ kind: pp_necessary,
                          necessary_practice: A,
                          dependent_practice: B,
                          necessary_surface: ASurface,
                          dependent_surface: BSurface }) :-
    mua_relations:pp_necessary(A, B),
    practice_surface(A, ASurface),
    practice_surface(B, BSurface).
relation_demonstration(pp_sufficient(A, B),
                       _{ kind: pp_sufficient,
                          base_practice: A,
                          elaborated_practice: B,
                          mechanism: Mechanism,
                          base_surface: ASurface,
                          elaborated_surface: BSurface }) :-
    mua_relations:pp_sufficient(A, B, Mechanism),
    practice_surface(A, ASurface),
    practice_surface(B, BSurface).
relation_demonstration(lx_for(Vm, Vb),
                       _{ kind: lx_for,
                          meta_vocabulary: Vm,
                          base_vocabulary: Vb,
                          principle: Principle,
                          meta_description: VmDesc,
                          base_description: VbDesc,
                          meta_practices: MetaPractices,
                          base_practices: BasePractices }) :-
    mua_relations:lx_for(Vm, Vb, Principle),
    mua_relations:vocabulary(Vm, VmDesc),
    mua_relations:vocabulary(Vb, VbDesc),
    executable_practices_for_vocabulary(Vm, MetaPractices),
    executable_practices_for_vocabulary(Vb, BasePractices),
    MetaPractices \== [],
    BasePractices \== [].

practice_surface(P, registry{operation:Op, kind:K, cluster:Cluster}) :-
    mua_relations:practice_kind(P, Op, K),
    catch(action_automata_registry:action_automaton_cluster(Op, K, Cluster), _, fail),
    !.
practice_surface(P, registry{operation:Op, kind:K, vocabulary:Vocabulary}) :-
    mua_relations:practice_kind(P, Op, K),
    catch(action_automata_registry:action_automaton_vocabulary(Op, K, Vocabulary), _, fail),
    !.
practice_surface(P, runtime_predicate{module:Mod, name:Name, arity:Arity}) :-
    mua_relations:practice_predicate(P, Mod:Name/Arity),
    functor(Head, Name, Arity),
    catch(predicate_property(Mod:Head, defined), _, fail).

executable_practices_for_vocabulary(V, Practices) :-
    findall(P,
            ( mua_relations:pv_sufficient(P, V),
              practice_executable(P)
            ),
            Ps0),
    sort(Ps0, Practices).

%!  relation_undemonstrable(-Relation, -Reason) is nondet.
%
%   Enumerates each MUA relation that does NOT demonstrate, with a reason atom.
%   Empty result set == the whole MUA layer stands against the live code.
relation_undemonstrable(pv_sufficient(P, V), Reason) :-
    mua_relations:pv_sufficient(P, V),
    (   \+ practice_executable(P)        -> Reason = practice_not_executable(P)
    ;   \+ mua_relations:vocabulary(V, _) -> Reason = vocabulary_undeclared(V)
    ;   fail ).
relation_undemonstrable(vp_sufficient(V, P), Reason) :-
    mua_relations:vp_sufficient(V, P),
    (   \+ mua_relations:vocabulary(V, _) -> Reason = vocabulary_undeclared(V)
    ;   \+ practice_executable(P)         -> Reason = practice_not_executable(P)
    ;   fail ).
relation_undemonstrable(pp_necessary(A, B), Reason) :-
    mua_relations:pp_necessary(A, B),
    (   \+ practice_executable(A) -> Reason = practice_not_executable(A)
    ;   \+ practice_executable(B) -> Reason = practice_not_executable(B)
    ;   fail ).
relation_undemonstrable(pp_sufficient(A, B), Reason) :-
    mua_relations:pp_sufficient(A, B, _),
    (   \+ practice_executable(A) -> Reason = practice_not_executable(A)
    ;   \+ practice_executable(B) -> Reason = practice_not_executable(B)
    ;   fail ).
relation_undemonstrable(lx_for(Vm, Vb), Reason) :-
    mua_relations:lx_for(Vm, Vb, _),
    (   \+ mua_relations:vocabulary(Vm, _) -> Reason = vocabulary_undeclared(Vm)
    ;   \+ mua_relations:vocabulary(Vb, _) -> Reason = vocabulary_undeclared(Vb)
    ;   \+ ( mua_relations:pv_sufficient(P, Vm), practice_executable(P) )
        -> Reason = meta_vocabulary_not_deployed(Vm)
    ;   \+ ( mua_relations:pv_sufficient(P, Vb), practice_executable(P) )
        -> Reason = base_vocabulary_not_deployed(Vb)
    ;   fail ).

%!  mua_health_report(-Dict) is det.
%
%   Backward-compatible count surface. It is deliberately a projection of
%   `mua_health_report_witness/1`, so the bare report cannot drift away from the
%   witness-bearing explanation.
mua_health_report(Counts) :-
    mua_health_report_witness(Witness),
    Counts = Witness.counts.

mua_health_counts(_{ practices_total: NP,
                     practices_executable: NPX,
                     demonstrated_relation_count: ND,
                     undemonstrable_count: NU,
                     undemonstrable: U }) :-
    findall(P, mua_relations:practice(P, _), Ps0), sort(Ps0, Ps), length(Ps, NP),
    include(practice_executable, Ps, PsX), length(PsX, NPX),
    findall(R, relation_demonstration(R, _), Ds0), sort(Ds0, Ds), length(Ds, ND),
    findall(R-Why, relation_undemonstrable(R, Why), U0), sort(U0, U), length(U, NU).

%!  mua_health_report_witness(-Witness) is det.
%
%   Human-interpretable wrapper around the raw MUA health counts. The health
%   guard proves against the currently loaded registry/runtime surfaces, so the
%   witness records both status and the drift caveat.
mua_health_report_witness(_{ kind: mua_health_report,
                             source: live_mua_codebook,
                             status: Status,
                             counts: Counts,
                             caveat: runtime_and_registry_surfaces_can_drift,
                             evidence_predicates:
                               [ practice_executable/1,
                                 relation_demonstration/2,
                                 relation_undemonstrable/2
                               ],
                             undemonstrable: Undemonstrable }) :-
    mua_health_counts(Counts),
    Undemonstrable = Counts.undemonstrable,
    ( Counts.undemonstrable_count =:= 0
    -> Status = passing
    ;  Status = review
    ).
