/** <module> cw_grounding_metaphor — union query over the scattered
 *  Lakoff & Núñez grounding-metaphor functors
 *
 * Problem this solves: "an L&N grounding metaphor" is named by four
 * different functors at four different layers, none of which is a
 * renaming of another:
 *
 *   - formalization(grounding_metaphors):grounding_metaphor_definition/4
 *       (MetaphorId, SourceDomain, TargetDomain, Description)
 *       The canonical arithmetic table: the four arithmetic Gs plus the
 *       named repair metaphors (rotation-by-180, Zero Collection, Zero
 *       Object). Its second clause already delegates to ln_metaphor/4,
 *       so this predicate ALSO ranges over the extensions — see the
 *       projection note below.
 *   - formalization(grounding_metaphors_extended):ln_metaphor/4
 *       (MetaphorId, SourceDomain, TargetDomain, Description)
 *       Extensions beyond arithmetic (algebra, BMI, calculus,
 *       set theory). Staged for review; a distinct module/functor.
 *   - pml(mua_relations):grounding_metaphor/2
 *       (Practice, MetaphorShortName)
 *       The per-PRACTICE assignment: which short-named metaphor grounds
 *       each arithmetic practice id. This is the authoritative
 *       practice->metaphor table for the MUA layer.
 *   - user:metaphor_source/4   (geometry KB, multifile)
 *       (ConceptId, MetaphorName, Mapping, Citation)
 *       The geometry-anchored records: which metaphor grounds each
 *       geometric CONCEPT, with the source/target mapping and a citation.
 *
 * These sit at genuinely different layers (a definition table, an
 * extension table, a practice assignment, a geometry-concept anchor)
 * with different arities and different keys. Renaming them into one
 * functor would collapse those layers. So this module does not rename
 * anything. It adds ONE read-only, source-tagged union query that now
 * delegates through grounding_metaphor_witness/4 so each projection carries
 * the source details the shared `(Metaphor, Anchor)` shape omits.
 *
 * Canonical query predicate:
 *   - grounding_metaphor_unified(?Metaphor, ?Anchor, -Source)
 *
 * PROJECTION (how four arities normalize to one shape):
 *   Every source denotes "metaphor M is anchored to/grounds X". We
 *   project to a (Metaphor, Anchor) pair plus a -Source tag:
 *     * definition  -> Metaphor = MetaphorId,
 *                      Anchor   = domains(SourceDomain, TargetDomain)
 *     * extension   -> Metaphor = MetaphorId,
 *                      Anchor   = domains(SourceDomain, TargetDomain)
 *     * mua_practice-> Metaphor = MetaphorShortName,
 *                      Anchor   = practice(Practice)
 *     * geometry    -> Metaphor = MetaphorName,
 *                      Anchor   = concept(ConceptId)
 *   Descriptions, geometry mappings, and citations are NOT carried in
 *   the union shape; callers that need them query the owning predicate
 *   directly. The union answers "which metaphor, anchored where, from
 *   which layer", not "everything every layer records".
 *
 * NOTE on overlap (intentional, not a bug): grounding_metaphor_definition/4
 * delegates to ln_metaphor/4 in its second clause, so the `definition`
 * source already yields every extension metaphor in addition to the
 * arithmetic table. The separate `extension` source is still wired
 * because the task family lists ln_metaphor/4 as its own functor and
 * because a caller may want to know an answer came specifically from the
 * staged extension module. Expect extension metaphors to appear under
 * BOTH `definition` and `extension` Source tags.
 *
 * Every source call is wrapped in catch/3 so a source that is absent or
 * errors simply contributes nothing. The geometry KB is a loose
 * multifile fact set in the `user` module (no module entry point); it is
 * brought in by a catch-guarded ensure_loaded of geometry/schema.pl,
 * which itself ensure_loads the metaphor files. If that load fails the
 * geometry clause contributes nothing.
 *
 * Read-only union view; no asserts, no retracts, no search.
 *
 * Wave: canonical-vocabulary family pass (grounding_metaphor).
 */
:- module(cw_grounding_metaphor,
          [ grounding_metaphor_unified/3,  % grounding_metaphor_unified(?Metaphor, ?Anchor, -Source)
            grounding_metaphor_witness/4,  % grounding_metaphor_witness(?Metaphor, ?Anchor, ?Source, -Witness)
            canonical_concept/2,           % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2            % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

% Module sources are called module-qualified; empty import lists are
% intentional (no predicates pulled into this module's namespace).
:- use_module(formalization(grounding_metaphors), []).
:- use_module(formalization(grounding_metaphors_extended), []).
:- use_module(pml(mua_relations), []).

% The geometry metaphor_source/4 records are NOT a module: schema.pl
% ensure_loads the metaphor fact files. We load it into the `user` module
% (where the multifile metaphor_source/4 facts are intended to live, and
% where the geometry tests put them) rather than into this module, so the
% union query below can find them via user:metaphor_source/4. Bring the KB
% in once, guarded, at module-load time. A failure here is non-fatal: the
% geometry clause of the union query is independently catch-guarded.
:- catch(user:ensure_loaded('geometry/schema.pl'), _, true).

%! grounding_metaphor_unified(?Metaphor, ?Anchor, -Source) is nondet.
%
%  True when Metaphor is an L&N grounding metaphor anchored to Anchor
%  according to some layer. Source names the layer:
%   - definition    : grounding_metaphors:grounding_metaphor_definition/4
%                     (arithmetic table + delegated extensions);
%                     Anchor = domains(SourceDomain, TargetDomain)
%   - extension     : grounding_metaphors_extended:ln_metaphor/4
%                     (algebra/BMI/calculus/set-theory extensions);
%                     Anchor = domains(SourceDomain, TargetDomain)
%   - mua_practice  : mua_relations:grounding_metaphor/2
%                     (per-practice assignment); Anchor = practice(Practice)
%   - geometry      : user:metaphor_source/4 (geometry KB);
%                     Anchor = concept(ConceptId)
grounding_metaphor_unified(Metaphor, domains(SourceDomain, TargetDomain), definition) :-
    grounding_metaphor_witness(Metaphor, domains(SourceDomain, TargetDomain), definition, _).
grounding_metaphor_unified(Metaphor, domains(SourceDomain, TargetDomain), extension) :-
    grounding_metaphor_witness(Metaphor, domains(SourceDomain, TargetDomain), extension, _).
grounding_metaphor_unified(Metaphor, practice(Practice), mua_practice) :-
    grounding_metaphor_witness(Metaphor, practice(Practice), mua_practice, _).
grounding_metaphor_unified(Metaphor, concept(ConceptId), geometry) :-
    grounding_metaphor_witness(Metaphor, concept(ConceptId), geometry, _).


%! grounding_metaphor_witness(?Metaphor, ?Anchor, ?Source, -Witness) is nondet.
%
%  Witnessed form of `grounding_metaphor_unified/3`. This is a closed-world
%  finite union over the currently loaded grounding-metaphor sources. It does
%  not decide every possible grounding metaphor or anchor in an open system; it
%  records which loaded layer accepted the concrete `(Metaphor, Anchor)` pair
%  and what source details were preserved outside the shared projection.
grounding_metaphor_witness(Metaphor, Anchor, Source,
                           WitnessDict130) :-
    witness_dict:witness_dict(grounding_metaphor_crosswalk, closed_world_finite_loaded_grounding_metaphor_sources,
                              _{source: Source,
                              legacy_functor: LegacyFunctor,
                              metaphor: Metaphor,
                              anchor: Anchor,
                              projection: Projection,
                              derivation: Derivation,
                              source_witness: SourceWitness }, WitnessDict130),
    grounding_metaphor_source(Source, LegacyFunctor),
    source_grounding_metaphor_witness(Source,
                                      Metaphor,
                                      Anchor,
                                      Projection,
                                      Derivation,
                                      SourceWitness).


grounding_metaphor_source(definition,
                          'grounding_metaphors:grounding_metaphor_definition/4').
grounding_metaphor_source(extension,
                          'grounding_metaphors_extended:ln_metaphor/4').
grounding_metaphor_source(mua_practice,
                          'mua_relations:grounding_metaphor/2').
grounding_metaphor_source(geometry,
                          'geometry:metaphor_source/4').


source_grounding_metaphor_witness(definition,
                                  Metaphor,
                                  domains(SourceDomain, TargetDomain),
                                  domains_projection,
                                  definition_table_lookup,
                                  SourceWitness) :-
    catch(grounding_metaphors:grounding_metaphor_definition(
              Metaphor,
              SourceDomain,
              TargetDomain,
              _Description
          ), _, fail),
    (   catch(grounding_metaphors:grounding_metaphor_definition_witness(
                  Metaphor,
                  SourceWitness
              ), _, fail)
    ->  true
    ;   source_definition_witness(Metaphor,
                                  SourceDomain,
                                  TargetDomain,
                                  SourceWitness)
    ).
source_grounding_metaphor_witness(extension,
                                  Metaphor,
                                  domains(SourceDomain, TargetDomain),
                                  domains_projection,
                                  extension_table_lookup,
                                  _{ kind: ln_metaphor_definition,
                                     metaphor_id: Metaphor,
                                     source_domain: SourceDomain,
                                     target_domain: TargetDomain,
                                     description: Description,
                                     citations: Citations,
                                     metaphor_kind: Kind }) :-
    catch(grounding_metaphors_extended:ln_metaphor(
              Metaphor,
              SourceDomain,
              TargetDomain,
              Description
          ), _, fail),
    findall(Citation,
            catch(grounding_metaphors_extended:ln_metaphor_citation(Metaphor, Citation),
                  _, fail),
            Citations),
    (   catch(grounding_metaphors_extended:ln_metaphor_kind(Metaphor, Kind), _, fail)
    ->  true
    ;   Kind = unknown
    ).
source_grounding_metaphor_witness(mua_practice,
                                  Metaphor,
                                  practice(Practice),
                                  practice_anchor_projection,
                                  mua_practice_assignment_lookup,
                                  SourceWitness) :-
    catch(mua_relations:grounding_metaphor(Practice, Metaphor), _, fail),
    mua_practice_source_witness(Practice, Metaphor, SourceWitness).
source_grounding_metaphor_witness(geometry,
                                  Metaphor,
                                  concept(ConceptId),
                                  concept_anchor_projection,
                                  geometry_metaphor_source_lookup,
                                  _{ kind: geometry_metaphor_source,
                                     concept: ConceptId,
                                     metaphor: Metaphor,
                                     mapping: Mapping,
                                     citation: Citation,
                                     geometry_witness: GeometryWitness }) :-
    catch(user:metaphor_source(ConceptId, Metaphor, Mapping, Citation), _, fail),
    geometry_metaphor_source_witness(ConceptId, Metaphor, GeometryWitness).


source_definition_witness(Metaphor,
                          SourceDomain,
                          TargetDomain,
                          _{ kind: grounding_metaphor_definition,
                             metaphor_id: Metaphor,
                             source_domain: SourceDomain,
                             target_domain: TargetDomain,
                             source: grounding_metaphors_definition_lookup }).


mua_practice_source_witness(Practice, Metaphor,
                            _{ kind: mua_grounding_metaphor_assignment,
                               practice: Practice,
                               mua_short_label: Metaphor,
                               translated_metaphor_id: FullMetaphorId,
                               bridge_witness: BridgeWitness }) :-
    catch(grounding_metaphors:grounding_metaphor_for_practice_witness(
              Practice,
              FullMetaphorId,
              BridgeWitness
          ), _, fail),
    !.
mua_practice_source_witness(Practice, Metaphor,
                            _{ kind: mua_grounding_metaphor_assignment,
                               practice: Practice,
                               mua_short_label: Metaphor,
                               translated_metaphor_id: none,
                               bridge_witness: none }).


geometry_metaphor_source_witness(ConceptId, Metaphor, Witness) :-
    catch(user:lakoff_nunez_metaphor_witness(ConceptId, Metaphor, Witness), _, fail),
    !.
geometry_metaphor_source_witness(ConceptId, Metaphor, Witness) :-
    catch(user:measuring_stick_metaphor_witness(ConceptId, Metaphor, Witness), _, fail),
    !.
geometry_metaphor_source_witness(_ConceptId, _Metaphor, none).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
%
%  Maps each scattered legacy functor to its canonical query predicate.
canonical_concept('grounding_metaphors:grounding_metaphor_definition/4', grounding_metaphor).
canonical_concept('grounding_metaphors_extended:ln_metaphor/4',          grounding_metaphor).
canonical_concept('mua_relations:grounding_metaphor/2',                  grounding_metaphor).
canonical_concept('geometry:metaphor_source/4',                          grounding_metaphor).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(grounding_metaphor,
    [ 'grounding_metaphors:grounding_metaphor_definition/4',
      'grounding_metaphors_extended:ln_metaphor/4',
      'mua_relations:grounding_metaphor/2',
      'geometry:metaphor_source/4' ]).
