/** <module> Canonical vocabulary family — productive-to-deformation pairing
 *
 * Concept: a "productive" action automaton paired with its "deformation" — the
 * procedurally-adjacent move that drops the grounding the productive action
 * carries, yielding a named misconception family. This is the "built to break"
 * pairing the manuscript treats as load-bearing.
 *
 * Scattered functors that all denote roughly this one concept:
 *   - action_automaton_pair/4
 *       (strategies/math/action_automata_registry.pl) — the unifying surface
 *       over all 12 operation domains: action_automaton_pair(Operation,
 *       Productive, Deformation, Family).
 *   - productive_deformation/3
 *       (strategies/math/sar_add_action_pairs.pl) — the ADDITION-domain rows:
 *       productive_deformation(Productive, Deformation, Family). The registry's
 *       action_automaton_pair(addition, ...) clause delegates straight to this.
 *   - productive_fraction_deformation/3
 *       (strategies/math/fraction_action_pairs.pl) — the FRACTION-domain rows:
 *       productive_fraction_deformation(Productive, Deformation, Family). The
 *       registry's action_automaton_pair(fraction, ...) clause delegates to it.
 *
 * These are NOT redundant: the /3 functors are per-domain fact tables; the /4
 * registry is the union surface that tags each with its operation. Renaming
 * would collapse the per-domain split the registry intentionally preserves.
 *
 * This module renames nothing. It adds ONE canonical, side-effect-free,
 * source-tagged union query:
 *
 *   productive_deformation_unified(?Operation, ?Productive, ?Deformation,
 *                                  ?Family, -Source)
 *
 * PROJECTION NOTE. The common queryable shape is the registry's 4-arg tuple
 * (Operation, Productive, Deformation, Family). The two /3 sources lack an
 * explicit Operation column, so they are projected into the tuple with their
 * known fixed operation tag (addition / fraction respectively). The Source
 * argument records which underlying functor produced the row:
 *   - registry  : action_automata_registry:action_automaton_pair/4 (all domains)
 *   - addition  : sar_add_action_pairs:productive_deformation/3
 *   - fraction  : fraction_action_pairs:productive_fraction_deformation/3
 *
 * The registry source and the two per-domain sources overlap by design (the
 * registry delegates to them), so addition/fraction rows appear under more than
 * one Source. That is the point: a caller can ask for the union (any Source) or
 * pin a specific underlying functor.
 *
 * Every source call is wrapped in catch(Goal, _, fail) so a missing/erroring
 * source contributes nothing. The sources are pure fact lookups (no asserts, no
 * heavy search), so the query is side-effect-free.
 */
:- module(cw_productive_deformation,
          [ productive_deformation_unified/5, % (?Op,?Prod,?Deform,?Family,-Source)
            productive_deformation_witness/6, % (?Op,?Prod,?Deform,?Family,?Source,-Witness)
            canonical_concept/2,              % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2               % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

% Real source modules. Called module-qualified, so empty import lists are
% intentional (no predicates pulled into this module's namespace).
:- use_module(strategies('math/action_automata_registry'), []).
:- use_module(strategies('math/sar_add_action_pairs'), []).
:- use_module(strategies('math/fraction_action_pairs'), []).

%! productive_deformation_unified(?Operation, ?Productive, ?Deformation, ?Family, ?Source) is nondet.
%
%  True when (Productive, Deformation) is a registered productive-to-deformation
%  pair yielding misconception Family, in operation domain Operation, according
%  to ANY underlying source. Source names which functor produced the row.
productive_deformation_unified(Operation, Productive, Deformation, Family, Source) :-
    productive_deformation_witness(Operation, Productive, Deformation, Family, Source, _).

%! productive_deformation_witness(
%!     ?Operation, ?Productive, ?Deformation, ?Family, ?Source, -Witness
%! ) is nondet.
%
%  Witnessed form of `productive_deformation_unified/5`. This is the
%  closed-world finite case for currently loaded action-pair tables: a row is
%  visible only when the named owner predicate proves the productive action,
%  nearby deformation, and misconception family relation. The witness also
%  records available registry metadata for each action kind.
productive_deformation_witness(Operation, Productive, Deformation, Family, registry,
                               Witness) :-
    catch(action_automata_registry:action_automaton_pair(
              Operation,
              Productive,
              Deformation,
              Family),
          _, fail),
    pair_witness(Operation,
                 Productive,
                 Deformation,
                 Family,
                 registry,
                 action_automata_registry,
                 action_automaton_pair/4,
                 operation_tagged_registry_union,
                 Witness).
productive_deformation_witness(addition, Productive, Deformation, Family, addition,
                               Witness) :-
    catch(sar_add_action_pairs:productive_deformation(Productive, Deformation, Family),
          _, fail),
    pair_witness(addition,
                 Productive,
                 Deformation,
                 Family,
                 addition,
                 sar_add_action_pairs,
                 productive_deformation/3,
                 fixed_operation_projection(addition),
                 Witness).
productive_deformation_witness(fraction, Productive, Deformation, Family, fraction,
                               Witness) :-
    catch(fraction_action_pairs:productive_fraction_deformation(
              Productive,
              Deformation,
              Family),
          _, fail),
    pair_witness(fraction,
                 Productive,
                 Deformation,
                 Family,
                 fraction,
                 fraction_action_pairs,
                 productive_fraction_deformation/3,
                 fixed_operation_projection(fraction),
                 Witness).

pair_witness(Operation,
             Productive,
             Deformation,
             Family,
             Source,
             Module,
             Predicate,
             Projection,
             _{ kind: productive_deformation_crosswalk,
                scope: closed_world_finite_verified_productive_deformation_pairs,
                operation: Operation,
                productive: Productive,
                deformation: Deformation,
                family: Family,
                source: Source,
                projection: Projection,
                derivation: owner_predicate_pair_check,
                source_witness: _{ kind: productive_deformation_pair_row,
                                   module: Module,
                                   predicate: Predicate,
                                   operation: Operation,
                                   productive: Productive,
                                   deformation: Deformation,
                                   family: Family },
                productive_witness: ProductiveWitness,
                deformation_witness: DeformationWitness }) :-
    action_kind_witness(Operation, Productive, ProductiveWitness),
    action_kind_witness(Operation, Deformation, DeformationWitness).

action_kind_witness(Operation,
                    Kind,
                    _{ kind: action_automaton_kind_metadata,
                       module: action_automata_registry,
                       operation: Operation,
                       action_kind: Kind,
                       cluster: Cluster,
                       vocabulary: Vocabulary }) :-
    catch(action_automata_registry:action_automaton_cluster(Operation, Kind, Cluster),
          _, fail),
    catch(action_automata_registry:action_automaton_vocabulary(Operation, Kind, Vocabulary),
          _, fail),
    !.
action_kind_witness(Operation,
                    Kind,
                    _{ kind: action_automaton_kind_metadata_absent,
                       module: action_automata_registry,
                       operation: Operation,
                       action_kind: Kind,
                       boundary: owner_pair_proved_without_registry_kind_metadata }).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
%
%  Maps each scattered legacy functor to its canonical query predicate.
canonical_concept('action_automata_registry:action_automaton_pair/4', productive_deformation_unified).
canonical_concept('sar_add_action_pairs:productive_deformation/3',     productive_deformation_unified).
canonical_concept('fraction_action_pairs:productive_fraction_deformation/3', productive_deformation_unified).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(productive_deformation_unified,
    [ 'action_automata_registry:action_automaton_pair/4',
      'sar_add_action_pairs:productive_deformation/3',
      'fraction_action_pairs:productive_fraction_deformation/3' ]).
