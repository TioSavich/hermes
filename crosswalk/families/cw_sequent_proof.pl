/** <module> cw_sequent_proof — canonical union query for sequent proof construction
 *
 * Concept family: "Sequent proof construction" (slug: sequent_proof).
 *
 * The repo carries several functors that all denote roughly one concept —
 * "this Sequent (Premises => Conclusions) is derivable in a sequent
 * calculus" — but they sit at genuinely different layers and arities:
 *
 *   - sequent_engine:proves/1        — the scene-agnostic sequent prover
 *                                      (Identity, Explosion, structural and S5
 *                                      reduction rules). The system's default
 *                                      "is it derivable" entry point.
 *   - sequent_engine:safe_proves/2   — proves/1 wrapped in a time limit and
 *                                      optional axiom packs (catch on
 *                                      time_limit_exceeded). The bounded entry.
 *   - sequent_engine:proves_impl/2   — the internal driver of proves/1
 *                                      (Sequent, History). Same layer, lower API.
 *   - embodied_prover:proves/4       — the embodied/resource-tracked prover
 *                                      (Sequent, R_In, R_Out, Proof). Deducts
 *                                      cognitive resources and can emit erasure
 *                                      proof objects at the arche-trace boundary.
 *   - deontic_scorekeeper:proves_via_arche_trace/1
 *                                    — a thin catch-guarded bridge the deontic
 *                                      scorekeeper calls to consult the
 *                                      arche-trace sequent prover for
 *                                      high-stakes consistency checks.
 *
 * This module does NOT rename or rewrite any of them. It adds ONE read-only
 * canonical query that ranges over the real source predicates and tags each
 * result with the source layer it came from. The public yes/no query delegates
 * through sequent_proof_witness/3 so the finite source boundary, prover layer,
 * bounded options, and available proof witness are inspectable.
 *
 * Projection note: the sources have arities 1, 2, and 4. The common queryable
 * shape is "does Sequent have a sequent proof, and from which layer". The
 * canonical predicate sequent_proof_unified(?Sequent, -Source) therefore keeps
 * the legacy shared shape, while sequent_proof_witness/3 preserves the
 * layer-specific extras (bounded options, in/out resources, and proof term when
 * the source exposes one).
 *
 * Wave 2 of the canonical-vocabulary pass (cf. crosswalk/canonical_vocabulary.pl).
 */
:- module(cw_sequent_proof,
          [ sequent_proof_unified/2,   % sequent_proof_unified(?Sequent, -Source)
            sequent_proof_witness/3,   % sequent_proof_witness(?Sequent, ?Source, -Witness)
            canonical_concept/2,       % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2        % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

% Source modules are called module-qualified, so the import lists are empty
% (no predicates pulled into this module's namespace, no name clashes).
:- use_module(arche_trace(sequent_engine), []).
:- use_module(arche_trace(embodied_prover), []).
:- use_module(learner(deontic_scorekeeper), []).

%! sequent_proof_unified(?Sequent, -Source) is nondet.
%
%  True when Sequent (of the form Premises => Conclusions) is derivable in a
%  sequent calculus according to ANY wired prover layer. Source names the layer:
%
%   - sequent       : sequent_engine:proves/1 (scene-agnostic default prover)
%   - sequent_safe  : sequent_engine:safe_proves/2 (time-limited, no axiom packs)
%   - sequent_impl  : sequent_engine:proves_impl/2 (internal driver, history [])
%   - embodied      : embodied_prover:proves/4 (resource-tracked; fixed budget)
%   - deontic_bridge: deontic_scorekeeper:proves_via_arche_trace/1
%
sequent_proof_unified(Sequent, sequent) :-
    sequent_proof_witness(Sequent, sequent, _).
sequent_proof_unified(Sequent, sequent_safe) :-
    sequent_proof_witness(Sequent, sequent_safe, _).
sequent_proof_unified(Sequent, sequent_impl) :-
    sequent_proof_witness(Sequent, sequent_impl, _).
sequent_proof_unified(Sequent, embodied) :-
    sequent_proof_witness(Sequent, embodied, _).
sequent_proof_unified(Sequent, deontic_bridge) :-
    sequent_proof_witness(Sequent, deontic_bridge, _).

%! sequent_proof_witness(?Sequent, ?Source, -Witness) is nondet.
%
%  Witnessed form of `sequent_proof_unified/2`. This is a closed-world finite
%  union over the currently loaded sequent-proof sources. It does not decide
%  derivability in every possible proof system or axiom universe; it records
%  which loaded prover layer accepted the concrete Sequent and what proof or
%  bounded-call evidence that layer exposes.
sequent_proof_witness(Sequent, Source,
                      _{ kind: sequent_proof_crosswalk,
                         scope: closed_world_finite_loaded_sequent_sources,
                         source: Source,
                         legacy_functor: LegacyFunctor,
                         sequent: Sequent,
                         parameters: Parameters,
                         derivation: Derivation,
                         source_witness: SourceWitness }) :-
    sequent_proof_source(Source, LegacyFunctor),
    source_sequent_proof_witness(Source,
                                 Sequent,
                                 Parameters,
                                 Derivation,
                                 SourceWitness).


sequent_proof_source(sequent,
                     'sequent_engine:proves/1').
sequent_proof_source(sequent_safe,
                     'sequent_engine:safe_proves/2').
sequent_proof_source(sequent_impl,
                     'sequent_engine:proves_impl/2').
sequent_proof_source(embodied,
                     'embodied_prover:proves/4').
sequent_proof_source(deontic_bridge,
                     'deontic_scorekeeper:proves_via_arche_trace/1').


source_sequent_proof_witness(sequent,
                             Sequent,
                             _{ mode: default_loaded_axiom_packs },
                             sequent_engine_proves_call,
                             SourceWitness) :-
    catch(once(sequent_engine:proves(Sequent)), _, fail),
    sequent_engine_source_witness(Sequent, SourceWitness).
source_sequent_proof_witness(sequent_safe,
                             Sequent,
                             _{ time_limit_seconds: 2,
                                packs: current_enabled_axiom_packs },
                             bounded_safe_proves_call,
                             SourceWitness) :-
    catch(once(sequent_engine:safe_proves(Sequent, [time_limit(2)])), _, fail),
    sequent_engine_source_witness(Sequent, EngineWitness),
    SourceWitness = _{ kind: bounded_sequent_engine_proof,
                       bound: time_limit_seconds(2),
                       engine_witness: EngineWitness }.
source_sequent_proof_witness(sequent_impl,
                             Sequent,
                             _{ history: [] },
                             internal_driver_call,
                             SourceWitness) :-
    catch(once(sequent_engine:proves_impl(Sequent, [])), _, fail),
    sequent_engine_source_witness(Sequent, EngineWitness),
    SourceWitness = _{ kind: sequent_engine_internal_driver,
                       history: [],
                       engine_witness: EngineWitness }.
source_sequent_proof_witness(embodied,
                             Sequent,
                             _{ resources_in: 1000,
                                initial_context: neutral },
                             embodied_prover_witness_call,
                             SourceWitness) :-
    catch(once(embodied_prover:proves_witness(Sequent,
                                              1000,
                                              _ResourcesOut,
                                              _Proof,
                                              SourceWitness)), _, fail).
source_sequent_proof_witness(deontic_bridge,
                             Sequent,
                             _{ bridge: catch_guarded_arche_trace },
                             deontic_scorekeeper_bridge_call,
                             _{ kind: deontic_arche_trace_bridge,
                                bridge: proves_via_arche_trace,
                                engine_witness: EngineWitness }) :-
    catch(once(deontic_scorekeeper:proves_via_arche_trace(Sequent)), _, fail),
    sequent_engine_source_witness(Sequent, EngineWitness).


sequent_engine_source_witness((Premises => Conclusions),
                              _{ kind: sequent_engine_identity,
                                 rule: identity,
                                 shared_formula: Formula,
                                 premises: Premises,
                                 conclusions: Conclusions }) :-
    member(Formula, Premises),
    member(Formula, Conclusions),
    !.
sequent_engine_source_witness((Premises => Conclusions),
                              _{ kind: sequent_engine_explosion,
                                 rule: explosion,
                                 premises: Premises,
                                 conclusions: Conclusions,
                                 incoherence_witness: IncoherenceWitness }) :-
    catch(sequent_engine:incoherent_witness(Premises, IncoherenceWitness), _, fail),
    !.
sequent_engine_source_witness(Sequent,
                              _{ kind: sequent_engine_semidet_proof,
                                 rule: loaded_axiom_or_structural_reduction,
                                 sequent: Sequent }).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
%
%  Maps each scattered legacy functor to its canonical query predicate.
canonical_concept('sequent_engine:proves/1',                       sequent_proof).
canonical_concept('sequent_engine:safe_proves/2',                  sequent_proof).
canonical_concept('sequent_engine:proves_impl/2',                  sequent_proof).
canonical_concept('embodied_prover:proves/4',                      sequent_proof).
canonical_concept('deontic_scorekeeper:proves_via_arche_trace/1',  sequent_proof).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
%
%  The wired sources for the sequent_proof canonical concept. Two functors that
%  belong to the family conceptually are intentionally NOT wired here:
%   - formalization/robinson_q.pl proves/1 (+ its proves_impl/2): a standalone
%     duplicate of the sequent_engine layer. It must not co-load with
%     formalization/axioms_robinson.pl, which the sequent engine already
%     includes; wiring the engine owner and dropping the standalone is the
%     correct call (see sources_dropped in the crosswalk record).
%   - embodied_prover:proves_impl/7: the internal driver of proves/4, needing
%     History/Context/Resource arguments. It is subsumed by the proves/4 public
%     wrapper wired above as the `embodied` source.
vocabulary_source(sequent_proof,
    [ 'sequent_engine:proves/1',
      'sequent_engine:safe_proves/2',
      'sequent_engine:proves_impl/2',
      'embodied_prover:proves/4',
      'deontic_scorekeeper:proves_via_arche_trace/1' ]).
