/** <module> Canonical vocabulary — unified query layer over scattered functors
 *
 * Problem this solves: the vocabulary crosswalk (docs/crosswalk/) found that
 * the Brandomian core concepts are each carried by several different functor
 * names across modules. They are NOT redundant duplicates — they sit at
 * different layers (deontic, material, geometric, hypergraph; sequent vs
 * defeasible) with different arities. Renaming them into one functor would
 * collapse the principled discursive-levels splits and break the provers.
 *
 * So this module does not rename anything. It adds CANONICAL QUERY predicates
 * that range over every underlying source and tag which source a result came
 * from. The underlying predicates are untouched and keep working; this is a
 * read-only union view. Every source call is guarded with catch/3 so a source
 * module that is absent or errors simply contributes nothing.
 *
 * Canonical query predicates (the start of the neurosymbolic legal-vocabulary
 * contract — the terms the LLM half may emit and swipl judges):
 *   - incompatible/3       : incompatible(?A, ?B, -Source)
 *   - incoherent/2         : incoherent(?Context, -Source)
 *   - deontic_incoherent/3 : deontic_incoherent(?Bearer, ?Reason, -Source)
 *
 * canonical_concept/2 and vocabulary_source/2 record the crosswalk so callers
 * (and the LLM contract) can query which legacy functors each canonical term
 * subsumes.
 *
 * Wave 1 (incompatible/3, incoherent/2) set the pattern: union query,
 * source-tagged, guarded. Wave 2 delta (2026-07-02, Gate-G deontic slice):
 * deontic_incoherent/3 unions the three incoherence layers the deontic and
 * sequent-proof routes call — the scorekeeper's deontic_incoherent/2, the
 * sequent engine's is_incoherent/1, and the Brandomian bridge's b_incoherent/1.
 * This module does not import the bridge directly; the full canonical
 * vocabulary dependency graph may still make it available through
 * incompatibility-set routes, and when it is absent the guarded call fails
 * silently instead of raising existence_error. Within-scorekeeper surface unions
 * (relation vs scorecard dict) belong to the family modules
 * (`cw_deontic_incoherence` in knowledge/crosswalk/families/cw_edges.pl); this module unions ACROSS
 * engine layers.
 *
 * Wave 2 refusal, recorded here so the Wave-1 promise of further families
 * does not prompt a re-attempt: no entitled/3 or
 * commitment_without_entitlement/3 union. Verified by reading
 * the candidate layers (2026-07-02): only formal/learner/deontic_scorekeeper.pl
 * carries an attributed entitlement status — entitlement/2 is dynamic
 * (Agent, Proposition) state. defeasible_inference:material_inference/3 is a
 * standing, agent-free inference license (Id, Premises, Conclusion): a rule,
 * not a deontic status, and unioning the two would flatten the
 * status-vs-license distinction the scorekeeper exists to keep. The sequent
 * engine imports the scorekeeper's entitlement/2 rather than exposing its
 * own, so it is the same store, not a second source. The Brandomian layer
 * has no entitlement notion. Commitment-without-entitlement detection
 * therefore lives in exactly one layer, and its within-layer union already
 * exists as cw_deontic_incoherence:deontic_incoherence_unified/3; a
 * one-source "union" here would only rename it. The
 * commitment_without_entitlement(P) reasons still surface through
 * deontic_incoherent/3's deontic source.
 */
:- module(canonical_vocabulary,
          [ incompatible/3,          % incompatible(?A, ?B, -Source)
            incoherent/2,            % incoherent(?Context, -Source)
            deontic_incoherent/3,    % deontic_incoherent(?Bearer, ?Reason, -Source)
            canonical_concept/2,     % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2      % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

% Ensure the source modules are loaded; we call them module-qualified, so empty
% import lists are intentional (no name clashes pulled into this module).
:- use_module(learner(deontic_scorekeeper), []).
:- use_module(misconceptions(misconception_registry), []).
:- use_module(incompat(incompatibility_sets), []).
:- use_module(sequent(sequent_engine), []).
:- use_module(incompat(defeasible_inference), []).
:- use_module(library(lists), [select/3, member/2]).

%! incompatible(?A, ?B, -Source) is nondet.
%
%  True when commitments/terms A and B are materially incompatible according to
%  ANY layer. Source names the layer the verdict came from:
%   - deontic              : deontic_scorekeeper:incompatible/2 (commitment pairs)
%   - material_misconception : misconception_registry:incompatibility_with/2
%   - geometry             : sequent_engine:incompatible_pair/2 (shape/rule)
%   - hypergraph(Provenance): a pair drawn from incompatibility_sets:incompatibility_set/2
incompatible(A, B, deontic) :-
    catch(deontic_scorekeeper:incompatible(A, B), _, fail).
incompatible(A, B, material_misconception) :-
    catch(misconception_registry:incompatibility_with(A, B), _, fail).
incompatible(A, B, geometry) :-
    catch(sequent_engine:incompatible_pair(A, B), _, fail).
incompatible(A, B, hypergraph(Provenance)) :-
    catch(incompatibility_sets:incompatibility_set(_Ctx, set(Provenance, Set)), _, fail),
    is_list(Set),
    select(A, Set, Rest),
    member(B, Rest).

%! incoherent(?Context, -Source) is nondet.
%
%  True when Context is incoherent (proves falsum / holds clashing commitments)
%  according to ANY prover layer. Source:
%   - sequent    : sequent_engine:incoherent/1 (scene-agnostic sequent prover)
%   - defeasible : defeasible_inference:ctx_incoherent/1 (defeat-classifier context)
%  (The resource-tracked embodied_prover:incoherent/1 is intentionally not wired
%  in wave 1 — it runs a bounded proof search and is better called explicitly.)
incoherent(Context, sequent) :-
    catch(sequent_engine:incoherent(Context), _, fail).
incoherent(Context, defeasible) :-
    catch(defeasible_inference:ctx_incoherent(Context), _, fail).

%! deontic_incoherent(?Bearer, ?Reason, -Source) is nondet.
%
%  True when a commitment-bearer's jointly held contents cannot stand
%  together, according to ANY of the three incoherence layers the deontic
%  slice routes through. Bearer identifies whose commitments are judged: an
%  agent term for the deontic layer, an explicit content list for the sequent
%  and brandomian layers. An unbound Bearer skips the list layers (they judge
%  a given context; they cannot enumerate contexts) rather than diverging.
%  Source tags the layer:
%   - deontic    : deontic_scorekeeper:deontic_incoherent/2 over the dynamic
%                  commitment/entitlement state. Reason is the scorekeeper's
%                  own term (commitment_without_entitlement/1,
%                  entitlement_to_incompatible/2, ...).
%   - sequent    : sequent_engine:is_incoherent/1 — structural negation pairs
%                  plus axiom-pack incoherence, with NO proof search (unlike
%                  incoherent/2's incoherent/1 route, which can fall through
%                  to empty-succedent derivation). Reason is the engine's
%                  incoherent_witness/2 dict when one is derivable, else the
%                  atom incoherent_context.
%   - brandomian : sequent_brandom_bridge:b_incoherent/1. The bridge is called
%                  through a guard; when absent, this source contributes
%                  nothing (no existence_error escapes).
%                  Reason is declared_hyperedge when the Brandomian relation
%                  itself fires, classical_negation_pair when only the
%                  classical floor answers.
deontic_incoherent(Agent, Reason, deontic) :-
    catch(deontic_scorekeeper:deontic_incoherent(Agent, Reason), _, fail).
deontic_incoherent(Context, Reason, sequent) :-
    is_list(Context),
    catch(sequent_engine:is_incoherent(Context), _, fail),
    (   catch(sequent_engine:incoherent_witness(Context, Witness), _, fail)
    ->  Reason = Witness
    ;   Reason = incoherent_context
    ).
deontic_incoherent(Set, Reason, brandomian) :-
    is_list(Set),
    catch(sequent_brandom_bridge:b_incoherent(Set), _, fail),
    (   catch(brandomian_incompatibility:brandomian_incoherent(Set), _, fail)
    ->  Reason = declared_hyperedge
    ;   Reason = classical_negation_pair
    ).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
%
%  Maps each scattered legacy functor to its canonical query predicate. The
%  mapping is one-to-many where a legacy functor feeds more than one
%  canonical query (is_incoherent/1 feeds both incoherent/2 and
%  deontic_incoherent/3).
canonical_concept('deontic_scorekeeper:incompatible/2',        incompatible).
canonical_concept('misconception_registry:incompatibility_with/2', incompatible).
canonical_concept('sequent_engine:incompatible_pair/2',        incompatible).
canonical_concept('incompatibility_sets:incompatibility_set/2', incompatible).
canonical_concept('sequent_engine:incoherent/1',               incoherent).
canonical_concept('sequent_engine:is_incoherent/1',            incoherent).
canonical_concept('sequent_engine:incoherent_base/1',          incoherent).
canonical_concept('defeasible_inference:ctx_incoherent/1',     incoherent).
% deontic_incoherent/3 is deliberately NOT registered as a canonical_concept
% merge. The merge gate blocks it for principled reasons the union view does
% not override: deontic_scorekeeper:deontic_incoherent/2 attributes a status
% to an agent (Bearer, Reason) while the sequent/brandomian predicates report
% a property of a proposition set (arity 1 — a different argument structure,
% so a different inferential role), and sequent_brandom_bridge:b_incoherent/1
% may or may not be available depending on the entry point. deontic_incoherent/3
% below is a ROUTING SURFACE across the three layers, with Source preserving
% which layer answered; it makes no concept-identity claim.

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(incompatible,
    [ 'deontic_scorekeeper:incompatible/2',
      'misconception_registry:incompatibility_with/2',
      'sequent_engine:incompatible_pair/2',
      'incompatibility_sets:incompatibility_set/2' ]).
vocabulary_source(incoherent,
    [ 'sequent_engine:incoherent/1',
      'sequent_engine:is_incoherent/1',
      'sequent_engine:incoherent_base/1',
      'defeasible_inference:ctx_incoherent/1' ]).
vocabulary_source(deontic_incoherent,
    [ 'deontic_scorekeeper:deontic_incoherent/2',
      'sequent_engine:is_incoherent/1',
      'sequent_brandom_bridge:b_incoherent/1' ]).
