/** <module> cw_stress_map — unified query over the commitment-stress / disequilibrium map
 *
 * Family: trace-based disequilibrium / commitment-stress map (slug: stress_map).
 *
 * Two modules independently carry "the conceptual stress map" — a record of how
 * often a commitment/predicate signature has been implicated in failure:
 *
 *   - arche_trace(critique)        : sequent-layer reflection. Salvaged the
 *                                    stress map from the old reflective_monitor.
 *                                    get_stress_map/1, commitment_stress/2.
 *   - learner(reflective_monitor)  : ORR-cycle "Reflect" stage over the
 *                                    meta-interpreter trace. get_stress_map/1.
 *
 * Both store the map as module-private dynamic stress/2 facts and both export
 * get_stress_map/1 returning the WHOLE map as a list of stress(Sig, Count). This
 * module does NOT rename or merge them: the two stress maps are distinct stores
 * (sequent layer vs learner layer) and merging them would conflate two layers'
 * failure histories. Instead it adds a read-only union view. The public union
 * delegates through stress_map_witness/4 so each entry keeps the source layer
 * and source-map snapshot visible.
 *
 * Projection (see notes): get_stress_map/1 hands back the entire list per source.
 * The canonical predicate UNNESTS that list into one solution per entry, so the
 * common queryable shape is stress_map_unified(?Signature, ?Count, -Source).
 * critique:commitment_stress/2 is also a pure read but of a SINGLE commitment;
 * it is recorded in canonical_concept/2 as a legacy variant but is NOT ranged
 * over by the union query (it needs a ground commitment as input, so it does not
 * enumerate the map). The side-effecting members of the family
 * (reflect/2, reset_stress_map/0, parse_trace/3) are likewise recorded as
 * legacy variants but never CALLED here: the canonical predicate is
 * side-effect-free.
 *
 * Every source call is wrapped in once/1 + catch/3: get_stress_map/1 is det per
 * source, and a source module that is absent or errors contributes nothing.
 *
 * Wave 2 of the canonical-vocabulary pass; same shape as
 * crosswalk/canonical_vocabulary.pl (Wave 1).
 *
 * Name-scope note: `stress_map_unified` is the commitment-stress /
 * disequilibrium map and nothing wider. canonical_concept/2 records eight
 * legacy functors under this term, but the union query ranges over only the two
 * get_stress_map/1 map-readers (sequent layer and learner layer). The other six
 * entries (the single-commitment reader commitment_stress/2 and the
 * side-effecting reflect/2, reset_stress_map/0, parse_trace/3 across both
 * layers) are recorded for provenance and stay out of the union. The shared
 * term marks a common map-reading concept; it does not merge eight predicates
 * into one queryable value.
 */
:- module(cw_stress_map,
          [ stress_map_unified/3,   % stress_map_unified(?Signature, ?Count, -Source)
            stress_map_witness/4,   % stress_map_witness(?Signature, ?Count, ?Source, -Witness)
            canonical_concept/2,    % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2     % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

% Load the two real owners module-qualified; empty import lists are intentional
% (both export the same names; we never pull them into this module's namespace).
:- use_module(arche_trace(critique), []).
:- use_module(learner(reflective_monitor), []).
:- use_module(library(lists), [member/2]).

%! stress_map_unified(?Signature, ?Count, -Source) is nondet.
%
%  Enumerates entries of every layer's commitment-stress map, tagged by Source:
%   - critique           : arche_trace(critique):get_stress_map/1 entries
%                          (sequent-layer reflection, salvaged stress map)
%   - reflective_monitor : learner(reflective_monitor):get_stress_map/1 entries
%                          (ORR "Reflect" stage over the meta-interpreter trace)
%
%  Each underlying get_stress_map/1 is det and read-only; we call it once/1 +
%  catch/3 and then member/2 over the returned stress(Signature, Count) list so
%  the projection is one solution per stress entry. With an empty map a source
%  simply yields no solutions.
stress_map_unified(Signature, Count, critique) :-
    stress_map_witness(Signature, Count, critique, _).
stress_map_unified(Signature, Count, reflective_monitor) :-
    stress_map_witness(Signature, Count, reflective_monitor, _).

%! stress_map_witness(?Signature, ?Count, ?Source, -Witness) is nondet.
%
%  Witnessed form of `stress_map_unified/3`. This is a closed-world finite
%  read of the currently loaded stress-map stores. It does not infer global
%  learner disequilibrium; it records that a concrete stress entry is present in
%  one loaded source map at query time.
stress_map_witness(Signature, Count, Source,
                   WitnessDict86) :-
    witness_dict:witness_dict(stress_map_entry, closed_world_finite_loaded_stress_map_snapshot,
                              _{source: Source,
                      legacy_functor: LegacyFunctor,
                      signature: Signature,
                      count: Count,
                      derivation: map_snapshot_membership,
                      source_witness: SourceWitness }, WitnessDict86),
    stress_map_source(Source, LegacyFunctor),
    source_stress_map_witness(Source, Signature, Count, SourceWitness).


stress_map_source(critique,
                  'critique:get_stress_map/1').
stress_map_source(reflective_monitor,
                  'reflective_monitor:get_stress_map/1').


source_stress_map_witness(critique,
                          Signature,
                          Count,
                          _{ kind: stress_map_snapshot_membership,
                             layer: arche_trace_critique,
                             map_reader: 'critique:get_stress_map/1',
                             entry: stress(Signature, Count),
                             map_size: MapSize,
                             map_snapshot: Map }) :-
    catch(once(critique:get_stress_map(Map)), _, fail),
    member(stress(Signature, Count), Map),
    length(Map, MapSize).
source_stress_map_witness(reflective_monitor,
                          Signature,
                          Count,
                          _{ kind: stress_map_snapshot_membership,
                             layer: learner_reflective_monitor,
                             map_reader: 'reflective_monitor:get_stress_map/1',
                             entry: stress(Signature, Count),
                             map_size: MapSize,
                             map_snapshot: Map }) :-
    catch(once(reflective_monitor:get_stress_map(Map)), _, fail),
    member(stress(Signature, Count), Map),
    length(Map, MapSize).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
%
%  Maps each scattered legacy functor to its canonical term. The map-reading
%  functors map to stress_map_unified; the side-effecting / single-commitment
%  functors are recorded under their concept but are not part of the union query
%  (see module header).
canonical_concept('critique:get_stress_map/1',             stress_map_unified).
canonical_concept('reflective_monitor:get_stress_map/1',   stress_map_unified).
% Legacy variants of the same family, intentionally NOT ranged over by the
% union query (side-effecting executors or single-commitment readers):
canonical_concept('critique:commitment_stress/2',          stress_map_unified).
canonical_concept('critique:reflect/2',                    stress_map_unified).
canonical_concept('critique:reset_stress_map/0',           stress_map_unified).
canonical_concept('reflective_monitor:reflect/2',          stress_map_unified).
canonical_concept('reflective_monitor:reset_stress_map/0', stress_map_unified).
canonical_concept('reflective_monitor:parse_trace/3',      stress_map_unified).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(stress_map_unified,
    [ 'critique:get_stress_map/1',
      'reflective_monitor:get_stress_map/1',
      'critique:commitment_stress/2',
      'critique:reflect/2',
      'critique:reset_stress_map/0',
      'reflective_monitor:reflect/2',
      'reflective_monitor:reset_stress_map/0',
      'reflective_monitor:parse_trace/3' ]).
