/** <module> Canonical vocabulary family — deontic commitment-without-entitlement
 *
 * Slug: deontic_incoherence. Wave 2 of the canonical-vocabulary pass; same
 * shape as crosswalk/canonical_vocabulary.pl (Wave 1).
 *
 * Problem this solves: "an agent is committed to a claim it is not entitled
 * to" is detected by two predicates in learner/deontic_scorekeeper.pl that
 * sit at different layers and arities:
 *
 *   - deontic_incoherent(+Agent, -Reason)  — the base nondet fact query over
 *     the dynamic commitment/2 and entitlement/2 state. Reads only; no
 *     side effects. Reason is one of commitment_without_entitlement(_),
 *     entitlement_to_incompatible(_, _), committed_to_negation_of_consequence(_, _).
 *   - scorecard(+Agent, -Card)  — a det aggregator that runs the same
 *     deontic_incoherent/2 via findall and packs the sorted results into
 *     the `incoherences` field of a scorecard{} dict. Reads only.
 *
 * These are NOT redundant: scorecard is the dict-shaped summary surface,
 * deontic_incoherent is the underlying relation. Renaming would collapse
 * that summary-vs-relation split. This module does not rename anything; it
 * adds ONE canonical, read-only, source-tagged union query and the crosswalk
 * bookkeeping predicates. The union query now delegates through
 * deontic_incoherence_witness/4 so the accepting scorekeeper surface, finite
 * state boundary, and scorecard projection are inspectable.
 *
 * Canonical query predicate:
 *   - deontic_incoherence_unified(?Agent, ?Reason, -Source)
 *
 * Projection (see notes): both sources are normalized to (Agent, Reason)
 * pairs. The `scorecard` source unfolds the `incoherences` list of each
 * scorecard back into one (Agent, Reason) per element, so it ranges over the
 * SAME logical facts as `deontic` but reached through the dict aggregator.
 * To make the scorecard branch enumerable without a bound Agent, it draws
 * the agent set from deontic_scorekeeper:commitment/2 (an exported dynamic
 * predicate). Every source goal is wrapped in catch(Goal, _, fail) so an
 * absent or erroring source contributes nothing.
 *
 * Dropped source:
 *   - hermes_event_scoring:score_event/2 (hermes/event_scoring.pl). It loads
 *     clean, but it does NOT denote commitment-without-entitlement detection:
 *     it takes a fully-structured runtime-event dict (requiring nested pml,
 *     carspecken, actor, substrate fields) and reshapes it into a Score dict.
 *     It neither reads the deontic commitment/entitlement state nor computes
 *     incoherence; it surfaces already-supplied missing_requirements /
 *     incompatibilities fields. Wiring it would require synthesizing a rich
 *     input dict that has no canonical (Agent, Reason) shape, so it is out of
 *     this family. Recorded here for audit.
 */
:- module(cw_deontic_incoherence,
          [ deontic_incoherence_unified/3,  % deontic_incoherence_unified(?Agent, ?Reason, -Source)
            deontic_incoherence_witness/4,  % deontic_incoherence_witness(?Agent, ?Reason, ?Source, -Witness)
            canonical_concept/2,            % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2             % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

% Source module is called module-qualified; empty import list is intentional
% (no predicates pulled into this module's namespace, no name clashes).
:- use_module(learner(deontic_scorekeeper), []).
:- use_module(library(lists), [member/2]).

%! deontic_incoherence_unified(?Agent, ?Reason, -Source) is nondet.
%
%  True when Agent's deontic state is incoherent (committed without
%  entitlement, entitled to incompatibles, or committed to the negation of a
%  consequence) according to ANY scorekeeper surface. Source names the
%  surface the verdict was reached through:
%   - deontic   : deontic_scorekeeper:deontic_incoherent/2 (base relation)
%   - scorecard : the `incoherences` field of
%                 deontic_scorekeeper:scorecard/2, unfolded to (Agent, Reason)
%
%  Read-only. Each source goal is catch-guarded; the scorecard call is det
%  per agent and is wrapped in catch as well.
deontic_incoherence_unified(Agent, Reason, deontic) :-
    deontic_incoherence_witness(Agent, Reason, deontic, _).
deontic_incoherence_unified(Agent, Reason, scorecard) :-
    deontic_incoherence_witness(Agent, Reason, scorecard, _).


%! deontic_incoherence_witness(?Agent, ?Reason, ?Source, -Witness) is nondet.
%
%  Witnessed form of `deontic_incoherence_unified/3`. This is a closed-world
%  finite query over the currently loaded deontic scorekeeper state. It does not
%  decide whether every possible agent-state is deontically coherent in an open
%  system; it records which loaded scorekeeper surface accepted this concrete
%  Agent/Reason pair and how the source reached it.
deontic_incoherence_witness(Agent, Reason, Source,
                            _{ kind: deontic_incoherence,
                               scope: closed_world_finite_scorekeeper_state,
                               source: Source,
                               legacy_functor: LegacyFunctor,
                               agent: Agent,
                               reason: Reason,
                               reason_family: ReasonFamily,
                               derivation: Derivation,
                               support: Support }) :-
    deontic_incoherence_source(Source, LegacyFunctor),
    source_deontic_incoherence_witness(Source,
                                       Agent,
                                       Reason,
                                       Derivation,
                                       Support),
    reason_family(Reason, ReasonFamily).


deontic_incoherence_source(deontic,
                           'deontic_scorekeeper:deontic_incoherent/2').
deontic_incoherence_source(scorecard,
                           'deontic_scorekeeper:scorecard/2').


source_deontic_incoherence_witness(deontic,
                                   Agent,
                                   Reason,
                                   direct_relation_query,
                                   _{ commitments: Commitments,
                                      entitlements: Entitlements }) :-
    catch(deontic_scorekeeper:deontic_incoherent(Agent, Reason), _, fail),
    scorekeeper_state(Agent, Commitments, Entitlements).
source_deontic_incoherence_witness(scorecard,
                                   Agent,
                                   Reason,
                                   scorecard_incoherence_unfold,
                                   _{ scorecard: Card,
                                      incoherence_count: Count }) :-
    catch(scorecard_incoherence(Agent, Reason, Card), _, fail),
    get_dict(incoherences, Card, Incoherences),
    length(Incoherences, Count).


reason_family(commitment_without_entitlement(_),
              commitment_without_entitlement).
reason_family(entitlement_to_incompatible(_, _),
              entitlement_to_incompatible).
reason_family(committed_to_negation_of_consequence(_, _),
              committed_to_negation_of_consequence).
reason_family(Reason, other) :-
    nonvar(Reason),
    \+ Reason = commitment_without_entitlement(_),
    \+ Reason = entitlement_to_incompatible(_, _),
    \+ Reason = committed_to_negation_of_consequence(_, _).


scorekeeper_state(Agent, Commitments, Entitlements) :-
    findall(C, deontic_scorekeeper:commitment(Agent, C), Cs0),
    sort(Cs0, Commitments),
    findall(E, deontic_scorekeeper:entitlement(Agent, E), Es0),
    sort(Es0, Entitlements).

%! scorecard_incoherence(?Agent, ?Reason) is nondet.
%
%  Private helper. Enumerates agents that hold at least one commitment, builds
%  each agent's scorecard via the det aggregator, and unfolds the dict's
%  `incoherences` list into individual (Agent, Reason) pairs. distinct/1 keeps
%  the agent set free of duplicates from agents with many commitments.
scorecard_incoherence(Agent, Reason) :-
    scorecard_incoherence(Agent, Reason, _).


scorecard_incoherence(Agent, Reason, Card) :-
    distinct(Agent, deontic_scorekeeper:commitment(Agent, _)),
    deontic_scorekeeper:scorecard(Agent, Card),
    get_dict(incoherences, Card, Incoherences),
    member(Reason, Incoherences).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
%
%  Maps each scattered legacy functor to its canonical query predicate.
canonical_concept('deontic_scorekeeper:deontic_incoherent/2', deontic_incoherence_unified).
canonical_concept('deontic_scorekeeper:scorecard/2',          deontic_incoherence_unified).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(deontic_incoherence_unified,
    [ 'deontic_scorekeeper:deontic_incoherent/2',
      'deontic_scorekeeper:scorecard/2' ]).
