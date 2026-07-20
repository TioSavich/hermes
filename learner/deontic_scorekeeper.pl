/** <module> Deontic scorekeeper: commitment vs entitlement
 *
 * Brandomian motivation. *Making It Explicit* distinguishes two
 * deontic statuses an agent can hold toward a proposition: a
 * commitment is the undertaking of a claim; an entitlement is having
 * reasons that license the claim. A learner can be committed to
 * `(3/4)*(2/5) = 6/20` (writes it down) without being entitled to it
 * (lacks the area-model elaboration that grounds the cross-multiplication
 * rule). The existing crisis machinery (`learner/meta_interpreter.pl`,
 * `learner/execution_handler.pl`) registers crisis at the level of
 * strategy execution; the scorekeeper sits alongside it and makes the
 * commitment / entitlement distinction available at the propositional
 * level.
 *
 * Canonical entry point: the cross-multiplication-without-grounding
 * case. The strategies module already encodes the productive /
 * deformation pair at the action level
 * (`strategies/math/fraction_action_pairs.pl`). The deformation's
 * `validity(correct)` field records that the answer is numerically
 * right; the scorekeeper records that the agent is *not entitled* to
 * that answer because the area-model LX-elaboration (per
 * `pml/mua_relations.pl`) was not deployed.
 *
 * Integration boundary.
 *
 *   - In: `pml(mua_relations)` supplies `lx_for/3`, `pp_sufficient/3`,
 *     and `pv_sufficient/2`. The scorekeeper consults them to decide
 *     whether a proposition (typically `result_of(Practice, ...)`)
 *     requires an entitlement and to seed the `material_inference/3`
 *     table.
 *   - Out: `crisis_from_deontic_incoherence/3` exposes a crisis
 *     descriptor. Its call site is
 *     `execution_handler:deontic_crisis_check/2`, which raises the
 *     descriptor through the ORR perturbation protocol and hands the
 *     offending commitments (via `deontic_incoherence_commitments/3`)
 *     to `reorganization_engine:handle_incoherence/1` for belief
 *     revision.
 *
 * Closed-world finite boundary. The `material_inference/3` table is a
 * small in-module seed plus the practice-elaboration entries derived
 * from `pp_sufficient/3` in MUA. The local `incompatible/2` clauses
 * cover explicit result conflicts and explicit negation in this finite
 * scorekeeping layer. Open-ended incompatibility entailment belongs to
 * the sequent prover in `arche-trace/`; this module exposes
 * `proves_via_arche_trace/1`
 * as an optional bridge without making proof search part of ordinary
 * deontic state updates.
 *
 * Single-agent by default. The `Agent` argument is preserved on every
 * exported predicate so a future multi-agent dialogue can layer on
 * top without changing the surface.
 */
:- module(deontic_scorekeeper,
          [ commitment/2,
            entitlement/2,
            undertake_commitment/2,
            grant_entitlement/2,
            withdraw_commitment/2,
            commitment_consequence/3,
            entitlement_consequence/3,
            deontic_incoherent/2,
            deontic_incoherence_commitments/3,
            scorecard/2,
            crisis_from_deontic_incoherence/3,
            entitlement_grounding_requirement/2,
            ungrounded_grant_attempt/3,
            reset_scorekeeper/1,
            reset_scorekeeper/0,
            entitlement_preserving/1,
            material_inference/3,
            mua_derived_material_inference/3,
            mua_derived_material_inference_witness/4,
            incompatible/2,
            requires_entitlement/1,
            requires_entitlement_via_mua/1,
            requires_entitlement_witness/2,
            commitment_consequence_witness/4,
            proves_via_arche_trace/1
          ]).

:- use_module(pml(mua_relations),
              [ pp_sufficient/3,
                pv_sufficient/2,
                lx_for/3,
                practice_kind/3
              ]).


%% ----------------------------------------------------------------------
%% Dynamic deontic state
%%
%% Both `commitment/2` and `entitlement/2` are dynamic facts indexed
%% by Agent. `commitment_support/3` records, for each commitment, the
%% list of commitments whose existence justified the consequence
%% derivation that produced it; an empty list means the commitment was
%% undertaken directly (not by consequence). The support list is used
%% by `withdraw_commitment/2` to ripple-retract dependents.

:- dynamic
    commitment/2,
    entitlement/2,
    commitment_support/3,
    ungrounded_grant_attempt/3.


%!  reset_scorekeeper(+Agent) is det.
%
%   Clear all deontic state for Agent.
reset_scorekeeper(Agent) :-
    retractall(commitment(Agent, _)),
    retractall(entitlement(Agent, _)),
    retractall(commitment_support(Agent, _, _)),
    retractall(ungrounded_grant_attempt(Agent, _, _)).


%!  reset_scorekeeper is det.
%
%   Clear all deontic state for all agents.
reset_scorekeeper :-
    retractall(commitment(_, _)),
    retractall(entitlement(_, _)),
    retractall(commitment_support(_, _, _)),
    retractall(ungrounded_grant_attempt(_, _, _)).


%% ----------------------------------------------------------------------
%% Material inferences: the incompatibility-semantics interface
%%
%% A `material_inference(RuleName, P, Q)` fact records that holding P
%% materially commits the agent to Q under the named inference rule.
%% This is the closed-world finite scorekeeper interface to
%% incompatibility semantics; open-ended proof search remains in
%% `arche-trace/sequent_engine.pl`.
%%
%% `entitlement_preserving(RuleName)` marks rules that preserve
%% entitlement: if Agent is entitled to P and the rule applies, Agent
%% is entitled to Q. Not all material inferences preserve entitlement
%% — a rule that requires LX-elaboration to be entitlement-preserving
%% (e.g. `fraction_multiplication_via_area_model`) only fires when
%% that elaboration's vocabulary has been deployed.

:- multifile material_inference/3.
:- discontiguous material_inference/3.
:- multifile entitlement_preserving/1.
:- discontiguous entitlement_preserving/1.
:- multifile incompatible/2.
:- discontiguous incompatible/2.
:- multifile requires_entitlement/1.
:- discontiguous requires_entitlement/1.


%% Seed: the fraction-multiplication area-model inference.
%%
%% Committing to `result_of(cross_multiply, A, B, C, D, fraction(N, Den))`
%% with N = A*C and Den = B*D follows from committing to the area-model
%% practice. The rule is entitlement-preserving ONLY when the area-model
%% vocabulary is deployed; otherwise it is a procedural pattern recall.
material_inference(fraction_multiplication_via_area_model,
                   committed_to(area_model_part_of_part(A, B, C, D)),
                   result_of(cross_multiply, A, B, C, D,
                             fraction(N, Den))) :-
    integer(A), integer(B), integer(C), integer(D),
    N is A*C,
    Den is B*D.

entitlement_preserving(fraction_multiplication_via_area_model).


%% Finite seed: incompatibility of two distinct results for the same op.
incompatible(result_of(Op, A, B, C, D, R1),
             result_of(Op, A, B, C, D, R2)) :-
    R1 \== R2.

incompatible(result_of(Op, X, Y, R1),
             result_of(Op, X, Y, R2)) :-
    R1 \== R2.

incompatible(result_of(Name, Source, R1),
             result_of(Name, Source, R2)) :-
    R1 \== R2.

%% Finite seed: a proposition and its explicit negation are incompatible.
incompatible(P, not(P)).
incompatible(not(P), P).

%% Registry backing. The misconception registry's incompatibility_with/2
%% pairs (misconception vs. the strategy or entitlement it conflicts with)
%% back the local table, so adjudication over a real classroom reading is
%% non-empty instead of limited to the result_of/not(P) seeds above. The
%% calls are guarded the same way as proves_via_arche_trace/1: when the
%% misconceptions module is not loaded (standalone learner contexts), the
%% clauses fail silently and the local seeds are all there is.
incompatible(A, B) :- registry_backed_incompatible(A, B).

registry_backed_incompatible(A, B) :-
    catch(misconception_registry:incompatibility_with(A, B),
          error(existence_error(_, _), _),
          fail).
registry_backed_incompatible(A, B) :-
    catch(misconception_registry:incompatibility_with(B, A),
          error(existence_error(_, _), _),
          fail).


%% Propositions whose entitlement requires LX-elaboration.
%%
%% A proposition that records the result of applying a practice
%% requires entitlement when the practice has a registered LX-ancestor
%% in MUA: the procedural rule (e.g. cross-multiplication) is grounded
%% in a base practice (e.g. area-model). Applying the rule without the
%% LX-elaboration's vocabulary leaves the agent committed-without-entitlement.
%%
%% Two sources contribute:
%%   1. Manual whitelist facts here (legacy + cases the proposition
%%      shape doesn't naturally connect to a registry kind).
%%   2. The MUA `lx_for/3` graph (`requires_entitlement_via_mua/1`),
%%      which derives the requirement structurally: any proposition of
%%      form `result_of(Kind, ...)` whose Kind has a vocabulary V that
%%      appears as the *meta* side of an `lx_for(V, _Base, _)` fact
%%      requires entitlement.
%%
%% `requires_entitlement/1` consults both; callers should treat it as
%% the canonical predicate. The two underlying sources are exported in
%% case a consumer wants to inspect them separately.
requires_entitlement(P) :- requires_entitlement_witness(P, _).

:- multifile requires_entitlement_fact/1.
:- discontiguous requires_entitlement_fact/1.

%% Manual seed (kept for back-compat and as a worked example). The
%% MUA-derived path now covers cross_multiply too, but the manual fact
%% remains so that the seed is legible to a reader of this module
%% without first reading the MUA layer.
requires_entitlement_fact(result_of(cross_multiply, _, _, _, _, _)).


%!  requires_entitlement_via_mua(?Proposition) is nondet.
%
%   True when Proposition is `result_of(Kind, ...)` (any arity) and Kind
%   is registered as a practice in MUA whose deployed vocabulary V is
%   the *meta* side of some `lx_for(V, _Base, _Principle)` fact. This
%   makes "needs entitlement" structural rather than enumerated.
requires_entitlement_via_mua(P) :-
    requires_entitlement_witness(P, Witness),
    Witness.kind == mua_lx_entitlement_requirement.

requires_entitlement_witness(P,
                             _{ kind: manual_entitlement_requirement,
                                proposition: P,
                                source: requires_entitlement_fact }) :-
    requires_entitlement_fact(P),
    !.
requires_entitlement_witness(P,
                             _{ kind: mua_lx_entitlement_requirement,
                                proposition: P,
                                kind_name: Kind,
                                practice: Practice,
                                meta_vocabulary: V,
                                base_vocabulary: Base,
                                principle: Principle,
                                source: lx_for(V, Base, Principle),
                                reason: meta_vocabulary_requires_base_vocabulary_entitlement }) :-
    nonvar(P),
    P =.. [result_of, Kind | _Rest],
    atom(Kind),
    %% Find a practice for the kind (across any operation).
    practice_kind(Practice, _Op, Kind),
    %% Find a vocabulary the practice deploys.
    pv_sufficient(Practice, V),
    %% V is LX-elaborated from some Base; therefore deploying it
    %% without the LX coupling leaves the agent ungrounded.
    lx_for(V, Base, Principle),
    !.


%% ----------------------------------------------------------------------
%% MUA-derived material inferences
%%
%% `pp_sufficient(BasePractice, ElaboratedPractice, Mechanism)` in MUA
%% says mastering BasePractice is PP-sufficient for ElaboratedPractice.
%% At the propositional level: committing to having deployed
%% BasePractice materially commits the agent to ElaboratedPractice
%% (an elaboration the base practice already supports).
%%
%% Encoded as `mua_derived_material_inference(Mechanism, P_base, P_elab)`.
%% `commitment_consequence/3` consults both the in-module
%% `material_inference/3` table and this MUA-derived table.

%!  mua_derived_material_inference(?Mechanism, ?P_base, ?P_elab) is nondet.
mua_derived_material_inference(Mechanism,
                               committed_to(BasePractice),
                               committed_to(ElaboratedPractice)) :-
    mua_derived_material_inference_witness(Mechanism,
                                           committed_to(BasePractice),
                                           committed_to(ElaboratedPractice),
                                           _).

mua_derived_material_inference_witness(Mechanism,
                                       committed_to(BasePractice),
                                       committed_to(ElaboratedPractice),
                                       _{ kind: mua_pp_sufficient_material_inference,
                                          mechanism: Mechanism,
                                          base_practice: BasePractice,
                                          elaborated_practice: ElaboratedPractice,
                                          premise: committed_to(BasePractice),
                                          conclusion: committed_to(ElaboratedPractice),
                                          source: pp_sufficient(BasePractice,
                                                                ElaboratedPractice,
                                                                Mechanism) }) :-
    pp_sufficient(BasePractice, ElaboratedPractice, Mechanism).


%% ----------------------------------------------------------------------
%% Sequent-prover bridge (optional)
%%
%% The scorekeeper's `incompatible/2` and `material_inference/3` are
%% local and finite by design (cf. module header). For high-stakes
%% consistency checks a consumer can call `proves_via_arche_trace/1`
%% to consult `arche-trace/sequent_engine.pl`. That prover lives in
%% proof-search mode (sequent calculus); the
%% scorekeeper lives in tracking mode (commitment/entitlement state).
%% They are complementary: the sequent prover decides whether a sequent is
%% derivable; the scorekeeper tracks who is committed to what and
%% whether they have reasons.
%%
%% This predicate is a thin wrapper that catches load failures so the
%% scorekeeper remains usable in test environments without the full
%% sequent-prover module loaded.

%!  proves_via_arche_trace(+Sequent) is semidet.
%
%   Succeeds if Sequent is derivable in the sequent calculus under
%   `arche-trace/`. Returns silently false if that module is
%   unavailable in the current load context.
proves_via_arche_trace(Sequent) :-
    catch(
        ( use_module(arche_trace(sequent_engine), [proves/1]),
          sequent_engine:proves(Sequent) ),
        _Err,
        fail
    ).


%% ----------------------------------------------------------------------
%% Undertaking and ripple consequences

%!  undertake_commitment(+Agent, +Proposition) is det.
%
%   Record the commitment and propagate its material consequences.
%   Each consequence Q is recorded with Proposition as its support;
%   recursive propagation is bounded by what has already been
%   committed (cycle-safe via the existence check).
undertake_commitment(Agent, Proposition) :-
    ( commitment(Agent, Proposition)
    -> true
    ;  assertz(commitment(Agent, Proposition)),
       assertz(commitment_support(Agent, Proposition, []))
    ),
    propagate_consequences(Agent, Proposition).


propagate_consequences(Agent, P) :-
    findall(Q,
            commitment_consequence(Agent, P, Q),
            Qs0),
    sort(Qs0, Qs),
    forall(member(Q, Qs),
           record_consequence(Agent, P, Q)).


record_consequence(Agent, P, Q) :-
    ( commitment(Agent, Q)
    -> true
    ;  assertz(commitment(Agent, Q)),
       assertz(commitment_support(Agent, Q, [P])),
       propagate_consequences(Agent, Q)
    ).


%% ----------------------------------------------------------------------
%% Grounding requirements for grants (the bare-grant boundary)
%%
%% BOUNDARY, NAMED PRECISELY. Until this guard was added,
%% `grant_entitlement/2` checked only `commitment(Agent, Proposition)`.
%% A bare `grant_entitlement(kid, result_of(cross_multiply, ...))` on a
%% committed proposition therefore closed the
%% `commitment_without_entitlement(area_model_justification_missing)`
%% incoherence without any area-model vocabulary ever being deployed:
%% saying "entitled" substituted for doing the grounding work that the
%% module's own seed rule (`fraction_multiplication_via_area_model`,
%% above) reserves entitlement for. The guard below closes that bypass
%% for exactly the propositions whose incoherence clause consults
%% `deployed_area_model_vocabulary/1`. The refused move is not
%% discarded: it is recorded as `ungrounded_grant_attempt/3`, so the
%% old behavior stays queryable as a named boundary instead of
%% vanishing silently. The incoherence check itself is unchanged.

%!  entitlement_grounding_requirement(?Proposition, ?Evidence) is nondet.
%
%   Proposition can only be granted entitlement when the named
%   grounding Evidence is already deployed for the agent. The table
%   covers the propositions whose `deontic_incoherent/2` clause
%   consults vocabulary deployment; keep the two in step.
entitlement_grounding_requirement(result_of(cross_multiply, _, _, _, _, _),
                                  deployed_area_model_vocabulary).

%!  grounding_evidence_deployed(+Evidence, +Agent) is semidet.
grounding_evidence_deployed(deployed_area_model_vocabulary, Agent) :-
    deployed_area_model_vocabulary(Agent).


%!  grant_entitlement(+Agent, +Proposition) is semidet.
%
%   Record that Agent is entitled to Proposition. Granting entitlement
%   requires that Agent already be committed to Proposition: one
%   cannot be entitled to what one has not asserted. If not committed,
%   the predicate prints a diagnostic and fails.
%
%   For propositions with an `entitlement_grounding_requirement/2`
%   entry, the grant additionally requires the grounding evidence to
%   be deployed. A bare grant without that evidence is recorded as
%   `ungrounded_grant_attempt(Agent, Proposition, Evidence)` and
%   fails, so the corresponding incoherence stays open.
grant_entitlement(Agent, Proposition) :-
    commitment(Agent, Proposition),
    entitlement_grounding_requirement(Proposition, Evidence),
    \+ grounding_evidence_deployed(Evidence, Agent),
    !,
    assertz(ungrounded_grant_attempt(Agent, Proposition, Evidence)),
    format(user_error,
           "grant_entitlement/2: refusing ungrounded grant to agent ~w for ~w; required evidence ~w is not deployed (recorded as ungrounded_grant_attempt/3; incoherence stays open)~n",
           [Agent, Proposition, Evidence]),
    fail.
grant_entitlement(Agent, Proposition) :-
    ( commitment(Agent, Proposition)
    -> ( entitlement(Agent, Proposition)
       -> true
       ;  assertz(entitlement(Agent, Proposition))
       ),
       propagate_entitlement(Agent, Proposition)
    ;  format(user_error,
              "grant_entitlement/2: agent ~w is not committed to ~w; cannot grant entitlement~n",
              [Agent, Proposition]),
       fail
    ).


propagate_entitlement(Agent, P) :-
    findall(Q,
            entitlement_consequence(Agent, P, Q),
            Qs0),
    sort(Qs0, Qs),
    forall(member(Q, Qs),
           ( ( commitment(Agent, Q) -> true ; undertake_commitment(Agent, Q) ),
             ( entitlement(Agent, Q)
             -> true
             ;  assertz(entitlement(Agent, Q))
             )
           )).


%!  withdraw_commitment(+Agent, +Proposition) is det.
%
%   Retract the commitment and any commitment whose only support was
%   Proposition. A commitment with multiple supports (e.g. undertaken
%   directly AND derived as a consequence) is NOT ripple-retracted.
%   Entitlement to a withdrawn commitment is also retracted (an agent
%   cannot be entitled to a proposition they no longer assert).
withdraw_commitment(Agent, Proposition) :-
    withdraw_commitment_inner(Agent, Proposition, _).

withdraw_commitment_inner(Agent, Proposition, Ripple) :-
    retractall(commitment(Agent, Proposition)),
    retractall(entitlement(Agent, Proposition)),
    retractall(commitment_support(Agent, Proposition, _)),
    findall(Q,
            ( commitment_support(Agent, Q, [Proposition]) ),
            Dependents),
    forall(member(Q, Dependents),
           withdraw_commitment_inner(Agent, Q, _)),
    Ripple = Dependents.


%% ----------------------------------------------------------------------
%% Consequences

%!  commitment_consequence(+Agent, +P, -Q) is nondet.
%
%   Material inferential consequence of holding P. Consults the
%   in-module `material_inference/3` table and the MUA-derived
%   practice-elaboration inferences. Q is what Agent is materially
%   committed to by virtue of being committed to P. (Agent's existing
%   commitment is implicit — the consequence applies once Agent has
%   undertaken P, before or after propagation.)
commitment_consequence(Agent, P, Q) :-
    commitment_consequence_witness(Agent, P, Q, _).

commitment_consequence_witness(_Agent, P, Q,
                               _{ kind: local_material_inference_consequence,
                                  rule: Rule,
                                  premise: P,
                                  conclusion: Q }) :-
    material_inference(Rule, P, Q).
commitment_consequence_witness(_Agent, P, Q,
                               _{ kind: mua_mastery_pp_sufficient_consequence,
                                  mechanism: Mechanism,
                                  base_practice: Base,
                                  elaborated_practice: Elaborated,
                                  premise: P,
                                  conclusion: Q,
                                  source: pp_sufficient(Base, Elaborated, Mechanism) }) :-
    P = mastered(Base),
    Q = mastered(Elaborated),
    pp_sufficient(Base, Elaborated, Mechanism).
commitment_consequence_witness(_Agent, P, Q,
                               _{ kind: mua_pp_sufficient_commitment_consequence,
                                  mechanism: Mechanism,
                                  base_practice: Base,
                                  elaborated_practice: Elaborated,
                                  premise: P,
                                  conclusion: Q,
                                  material_witness: MaterialWitness }) :-
    mua_derived_material_inference_witness(Mechanism, P, Q, MaterialWitness),
    P = committed_to(Base),
    Q = committed_to(Elaborated).


%!  entitlement_consequence(+Agent, +P, -Q) is nondet.
%
%   Entitlement-preserving consequence: fires only when Agent is
%   entitled to P AND the rule is registered as
%   `entitlement_preserving/1`. MUA-derived inferences are
%   entitlement-preserving when the LX-elaboration's vocabulary has
%   been deployed as an entitlement-preserving material rule.
entitlement_consequence(Agent, P, Q) :-
    entitlement(Agent, P),
    material_inference(Rule, P, Q),
    entitlement_preserving(Rule).


%% ----------------------------------------------------------------------
%% Incoherence

%!  deontic_incoherent(+Agent, -Reason) is nondet.
%
%   Succeeds when Agent's deontic state is incoherent. Three families:
%
%     - commitment_without_entitlement(P): Agent committed to P but
%       not entitled, AND P is one for which entitlement is required
%       (per `requires_entitlement/1`, populated from MUA's LX graph).
%       For `result_of(cross_multiply, ...)` the reason is specialised
%       to `commitment_without_entitlement(area_model_justification_missing)`
%       — the LX-elaboration is the area-model practice.
%
%     - entitlement_to_incompatible(P1, P2): Agent entitled to two
%       propositions that are materially incompatible.
%
%     - committed_to_negation_of_consequence(P, Q): Agent committed
%       to P, P entails Q, Agent committed to a proposition
%       incompatible with Q.
deontic_incoherent(Agent, commitment_without_entitlement(area_model_justification_missing)) :-
    commitment(Agent, P),
    P = result_of(cross_multiply, _, _, _, _, _),
    \+ entitlement(Agent, P),
    \+ deployed_area_model_vocabulary(Agent).
deontic_incoherent(Agent, commitment_without_entitlement(P)) :-
    commitment(Agent, P),
    requires_entitlement(P),
    \+ P = result_of(cross_multiply, _, _, _, _, _),
    \+ entitlement(Agent, P).
deontic_incoherent(Agent, entitlement_to_incompatible(P1, P2)) :-
    entitlement(Agent, P1),
    entitlement(Agent, P2),
    P1 @< P2,
    incompatible(P1, P2).
deontic_incoherent(Agent, committed_to_negation_of_consequence(P, Q)) :-
    commitment(Agent, P),
    commitment_consequence(Agent, P, Q),
    commitment(Agent, NotQ),
    incompatible(Q, NotQ),
    NotQ \== Q.
%%     - hyperedge_incoherence(Set): Agent jointly holds every member of a
%%       declared material-incompatibility hyperedge. Pairwise incompatible/2
%%       cannot express this: the canonical emergent case (blackberry/red/ripe)
%%       has no incoherent pair, only the triple. Hyperedges come from the
%%       Brandomian engine's declared sets (arche-trace, guarded like
%%       proves_via_arche_trace/1) and from the misconception registry's
%%       pairs, so the deontic path reaches the same relation b_incoherent/1
%%       audits rather than topping out at the local seeds.
deontic_incoherent(Agent, hyperedge_incoherence(Set)) :-
    findall(P, commitment(Agent, P), Held),
    Held \== [],
    joint_hyperedge(Set),
    Set = [_, _|_],
    forall(member(Content, Set), memberchk_eq_dk(Content, Held)).

joint_hyperedge(Set) :-
    catch(brandomian_incompatibility:incompatible_set(Set),
          error(existence_error(_, _), _),
          fail).
joint_hyperedge(Set) :-
    catch(misconception_registry:incompatibility_with(A, B),
          error(existence_error(_, _), _),
          fail),
    sort([A, B], Set).

memberchk_eq_dk(X, [Y|_]) :- X == Y, !.
memberchk_eq_dk(X, [_|Ys]) :- memberchk_eq_dk(X, Ys).


%% The agent has deployed area-model vocabulary if they have committed
%% to `area_model_part_of_part(...)` or to any proposition recording
%% deployment of `v_area_model` vocabulary.
deployed_area_model_vocabulary(Agent) :-
    commitment(Agent, area_model_part_of_part(_, _, _, _)), !.
deployed_area_model_vocabulary(Agent) :-
    commitment(Agent, deployed_vocabulary(v_area_model)), !.


%% ----------------------------------------------------------------------
%% Scorecard

%!  scorecard(+Agent, -Card) is det.
%
%   Emit a structured summary of Agent's deontic state.
scorecard(Agent, Card) :-
    findall(C, commitment(Agent, C), Cs0),
    sort(Cs0, Cs),
    findall(E, entitlement(Agent, E), Es0),
    sort(Es0, Es),
    findall(R, deontic_incoherent(Agent, R), Rs0),
    sort(Rs0, Rs),
    Card = scorecard{
        agent: Agent,
        commitments: Cs,
        entitlements: Es,
        incoherences: Rs
    }.


%% ----------------------------------------------------------------------
%% Bridge to the ORR cycle
%%
%% The execution handler classifies crises in four families
%% (efficiency, unknown operation, normative violation, incoherence).
%% A deontic incoherence maps cleanly onto the `incoherence` family.
%% The call site is `execution_handler:deontic_crisis_check/2`, which
%% raises `perturbation(incoherence(Crises))` through the same
%% classify/emit protocol as the meta-interpreter's perturbations and
%% dispatches belief revision to
%% `reorganization_engine:handle_incoherence/1`.

%!  crisis_from_deontic_incoherence(+Agent, +Reason, -CrisisDescriptor) is det.
%
%   Map a deontic incoherence (as produced by `deontic_incoherent/2`)
%   to a crisis descriptor of the form
%   `crisis(incoherence, deontic, Agent, Reason)`. The bridge does not
%   register anything globally; raising and handling the crisis is the
%   execution handler's job.
crisis_from_deontic_incoherence(Agent, Reason,
                                crisis(incoherence, deontic, Agent, Reason)).


%!  deontic_incoherence_commitments(+Agent, +Reason, -Commitments) is semidet.
%
%   The commitments of Agent that participate in the incoherence
%   Reason. This is what belief revision needs: `deontic_incoherent/2`
%   names the incoherence, this predicate names the withdrawable
%   commitments behind it. Fails if the incoherence is no longer
%   backed by live commitments (state may have changed since the
%   reason was computed).
deontic_incoherence_commitments(Agent,
                                commitment_without_entitlement(area_model_justification_missing),
                                Commitments) :-
    !,
    findall(P,
            ( commitment(Agent, P),
              P = result_of(cross_multiply, _, _, _, _, _),
              \+ entitlement(Agent, P) ),
            Commitments),
    Commitments \== [].
deontic_incoherence_commitments(Agent, commitment_without_entitlement(P), [P]) :-
    !,
    commitment(Agent, P).
deontic_incoherence_commitments(Agent, entitlement_to_incompatible(P1, P2), Commitments) :-
    !,
    findall(P, ( member(P, [P1, P2]), commitment(Agent, P) ), Commitments),
    Commitments \== [].
deontic_incoherence_commitments(Agent, committed_to_negation_of_consequence(P, _Q), [P]) :-
    !,
    commitment(Agent, P).
deontic_incoherence_commitments(Agent, hyperedge_incoherence(Set), Commitments) :-
    findall(P, ( member(P, Set), commitment(Agent, P) ), Commitments),
    Commitments \== [].
