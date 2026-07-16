:- module(up_leveling,
          [ entitlement_gap/1,            % +Incoherence
            within_level_closed/2,         % +Agent, +Incoherence
            discharge_status/2,            % +Incoherence, -Status
            up_level/3,                    % +Agent, +Incoherence, -Witness
            up_level_scorecard/2           % +Agent, -Witnesses
          ]).

/** <module> Up-leveling: objectivating a deontic gap the within-level layer cannot close

This module represents one move: when the deontic scoreboard's within-level
inferential evolution (algorithmic elaboration) cannot discharge an incoherence,
the gap can be *objectivated* — lifted into a new object of discourse at a higher
discursive level. This is the formal correlate of "talking about talking."

It is a REPRESENTATION, not an implementation of Gödelian diagonalization or of
Carspecken's reflection. What runs here detects a within-level limit and emits a
structured witness for the level-jump; the *content* of the new level — which
pragmatic metavocabulary actually resolves the objectivated topic — is not
supplied by this code. That hand-off is marked explicitly in the witness as an
`erasure` field. This is a structural rhyme with — not the same mechanism as —
the arche-trace prover's `erasure`: the prover's erasure is proof-theoretic
(`contains_trace/1` finds an arche_trace-attributed variable in a sequent under
proof search and voids the justification), whereas this erasure is a detector
hand-off with no sequent, no proof search, and no trace variable. Deriving this
field from the prover would mean fabricating a trace-tainted sequent purely to
harvest an erasure atom, so the marker stays a local atom on purpose.

## Grounding (sources, not decoration)

- Within-level evolution is what Zhang & Carspecken (2013) call moving along
  "paths" in a content inference field: argumentation that presupposes
  higher-level agreements. The deontic scoreboard's `commitment_consequence/3`
  (mechanism `algorithmic_elaboration_decomposition_and_transfer`) is one such
  path layer.
- The level-jump is their "objectivation" — "the inferential relations that had
  been at work are now made the content of a new topic for discussion" — and
  "up-leveling": "articulating previously assumed principles, definitions, or
  truths in order to problematize them" (Zhang & Carspecken 2013, pp. 206, 220).
- The manuscript already names the mechanism that carries the jump:
  `o(comp_nec(algorithmic_elaboration(P))) -> ... -> o(higher_discursive_level)`
  via a Brandomian `pragmatic_metavocabulary`.

## Why the trigger is structural, not heuristic

The scoreboard's algorithmic elaboration propagates *commitments*
(`commitment_consequence/3`); it never produces *entitlements*
(`grant_entitlement/2` is the only entitlement source). So a
`commitment_without_entitlement(_)` incoherence that survives the full
consequence closure is, by construction, unreachable by the within-level layer.
That persistence — not a tuning threshold — is the evidence that an up-level
move is the only inferential option left short of an external grant.

The honest reading of the manuscript thesis: the within-level scoreboard is the
"algorithmic" part of social interaction; the up-level move is where the
formalism reaches its boundary and must hand off (erasure), or where a genuinely
new discursive level is bootstrapped. This module makes that boundary queryable;
it does not cross it.
*/

:- use_module(learner(deontic_scorekeeper),
              [ commitment/2,
                deontic_incoherent/2,
                commitment_consequence/3,
                requires_entitlement_witness/2
              ]).
:- use_module(library(lists), [ member/2, memberchk/2 ]).

%!  entitlement_gap(+Incoherence) is semidet.
%
%   True for the incoherence shapes that are *entitlement* gaps — the kind the
%   within-level commitment-consequence closure structurally cannot discharge,
%   because elaboration yields commitments, not entitlements.
entitlement_gap(commitment_without_entitlement(_)).

%!  within_level_closed(+Agent, +Incoherence) is semidet.
%
%   True when Agent's within-level layer is exhausted with respect to
%   Incoherence: the incoherence still holds after the full commitment-
%   consequence closure (which `undertake_commitment/2` runs eagerly), AND no
%   current commitment has a consequence that would clear it. Consequences
%   never grant entitlement, so for an entitlement gap the second conjunct can
%   fail only when some consequence deploys the grounding vocabulary — the
%   within-level move that would license an entitlement grant.
within_level_closed(Agent, Incoherence) :-
    deontic_scorekeeper:deontic_incoherent(Agent, Incoherence),
    \+ consequence_would_clear(Agent, Incoherence).

%   Shape-specific resolvers, not a general closure check; `discharge_status/2`
%   records which case actually ran.
%
%   Area-model case: a consequence "would clear" the gap when some current
%   commitment elaborates into deploying the area-model vocabulary. Deployment
%   here removes the reported incoherence itself, because the scorekeeper's
%   cross-multiply clause checks for deployed area-model vocabulary directly.
consequence_would_clear(Agent, commitment_without_entitlement(area_model_justification_missing)) :-
    deontic_scorekeeper:commitment(Agent, P),
    deontic_scorekeeper:commitment_consequence(Agent, P, Q),
    ( Q = deployed_vocabulary(v_area_model)
    ; Q = area_model_part_of_part(_, _, _, _)
    ).
%   MUA-witnessed case: when `requires_entitlement_witness/2` grounds the gap
%   in the LX graph, the witness names the base vocabulary whose deployment is
%   the grounding move, and a consequence that deploys it counts as clearing.
%   One asymmetry with the area-model case, stated so the caveat stays honest:
%   the scorekeeper's general commitment_without_entitlement clause tracks
%   entitlement only, so the reported gap persists on the scoreboard until
%   `grant_entitlement/2` runs. What this clause establishes is narrower and
%   still decisive for up-leveling: the grounding deployment is reachable
%   within-level, so the layer is not exhausted and objectivation is not the
%   only move left.
consequence_would_clear(Agent, commitment_without_entitlement(P)) :-
    mua_base_vocabulary(P, BaseV),
    deontic_scorekeeper:commitment(Agent, Held),
    deontic_scorekeeper:commitment_consequence(Agent, Held,
                                               deployed_vocabulary(BaseV)).

%   The base vocabulary the MUA LX graph names as the grounding for P's
%   entitlement requirement. Fails for the manual whitelist shapes (their
%   witness carries no base vocabulary) and for non-result_of propositions.
mua_base_vocabulary(P, BaseV) :-
    compound(P),
    deontic_scorekeeper:requires_entitlement_witness(P, Witness),
    get_dict(kind, Witness, mua_lx_entitlement_requirement),
    get_dict(base_vocabulary, Witness, BaseV).

%!  discharge_status(+Incoherence, -Status) is det.
%
%   Honest record of what discharge check applies to this incoherence shape.
%   Three verdicts:
%
%   - `closure_checked_no_discharge`: a concrete `consequence_would_clear/2`
%     resolver exists and ran (area-model case; MUA-witnessed
%     commitment_without_entitlement gaps, where the witness names the base
%     vocabulary whose deployment would count).
%   - `withdrawal_required_consequence_closure_is_monotone`: for
%     entitlement_to_incompatible/2 and hyperedge_incoherence/1 no consequence
%     can discharge the incoherence, as a matter of structure rather than a
%     missing case: `propagate_consequences` only ever asserts commitments,
%     and these shapes are discharged only by `withdraw_commitment/2` —
%     withdrawing one side of the incompatible pair (withdrawal retracts the
%     entitlement too) or any one member of the jointly-held hyperedge.
%     Withdrawal is a scoreboard retraction, not a consequence, so no
%     `consequence_would_clear/2` clause could honestly exist for them.
%   - `discharge_check_not_implemented_for_this_shape`: every other shape.
%     No shape-specific check ran, so we say so rather than asserting the
%     closure was exhausted. (The architectural argument that
%     commitment-consequence never yields entitlement still applies, but this
%     field reports the *check*, not the architecture.)
discharge_status(commitment_without_entitlement(area_model_justification_missing),
                 closure_checked_no_discharge) :- !.
discharge_status(commitment_without_entitlement(P),
                 closure_checked_no_discharge) :-
    mua_base_vocabulary(P, _),
    !.
discharge_status(entitlement_to_incompatible(_, _),
                 withdrawal_required_consequence_closure_is_monotone) :- !.
discharge_status(hyperedge_incoherence(_),
                 withdrawal_required_consequence_closure_is_monotone) :- !.
discharge_status(_, discharge_check_not_implemented_for_this_shape).

%!  up_level(+Agent, +Incoherence, -Witness) is nondet.
%
%   When Incoherence is an entitlement gap the within-level layer has not
%   discharged, emit the objectivation witness: the gap becomes a new object of
%   discourse one level up (Zhang & Carspecken 2013, objectivation/up-leveling).
%
%   HONESTY (adversarial review 2026-06-18, see the research doc): this is a
%   detector, not an enactment. It builds a witness term and changes no state.
%   The witness is annotated in a diagonalization-flavoured shape, but that is a
%   structural RHYME, not Cantorian diagonalization: the meta-object escapes the
%   commitment set only by functor distinctness (`objectivated/1`), NOT by
%   diagonal self-application + pointwise negation, and there is no
%   necessary-novelty proof. The `caveat` field carries this; the `escapes`
%   value is now computed, not asserted.
up_level(Agent, Incoherence, Witness) :-
    entitlement_gap(Incoherence),
    within_level_closed(Agent, Incoherence),
    discharge_status(Incoherence, DischargeStatus),
    findall(C, deontic_scorekeeper:commitment(Agent, C), Commitments),
    NewObject = objectivated(Incoherence),
    ( memberchk(NewObject, Commitments) -> Escapes = false ; Escapes = true ),
    Witness = up_level_witness{
        kind: up_leveling,
        move: objectivation,
        source_concept: 'Zhang & Carspecken 2013: objectivation / up-leveling',
        within_level: algorithmic_elaboration,
        within_level_status: DischargeStatus,
        objectivated: Incoherence,
        new_discursive_level: meta,
        new_object_of_discourse: NewObject,
        enactment: detector_only_no_state_change,
        self_reference_form: _{
            note: 'structural rhyme with diagonalization, NOT a construction',
            base_set: Commitments,
            references_gap: absent_entitlement_for(Incoherence),
            new_object: NewObject,
            escapes_base_set: Escapes,
            escapes_reason: functor_distinctness_not_diagonal_negation
        },
        sublation_form: _{ preserves: Commitments, negates: Incoherence,
                           elevates_to: meta, content_supplied: false },
        erasure: pragmatic_metavocabulary_not_supplied_by_formalism,
        caveat: 'Self-reference, not Cantorian diagonalization. No diagonal self-application, no pointwise negation, no necessary-novelty proof. Detector only: emits a witness, changes no scoreboard state. See docs/research/2026-06-18-up-leveling-and-diagonalization.md (adversarial review).',
        interpretation: representational
    }.

%!  up_level_scorecard(+Agent, -Witnesses) is det.
%
%   All up-level moves available for Agent's current undischarged entitlement
%   gaps. Empty when the within-level layer is coherent or its gaps are
%   dischargeable.
up_level_scorecard(Agent, Witnesses) :-
    findall(W, up_level(Agent, _, W), Witnesses0),
    sort(Witnesses0, Witnesses).
