/** <module> Crosswalk family: unit coordination
 *
 * One concept — UNIT COORDINATION: the disposition to build, hold, and operate
 * on a composite unit (a unit made of units) without collapsing it to a flat
 * count. It is the Steffe/Hackenberg/Norton multiplicative-reasoning primitive
 * the manuscript leans on for both whole-number multiplication and the fraction
 * cliff. Two scattered, genuinely different-layer carriers:
 *
 *   - divaded_fractional_units:coordinate_units/4
 *       (strategies/math/divaded_fractional_units.pl)
 *       The EXECUTABLE strategy layer. coordinate_units(+UnitSize, +UnitCount,
 *       -Composite, -Trace): builds a composite recollection by inserting a
 *       UnitSize tally into each of UnitCount units, returning the composite and
 *       an insert/2 trace. This is the "doing" of unit coordination.
 *
 *   - literature_incompatibility_facts:lit_derived/9 rows whose Topic field is
 *       the atom unit_coordination
 *       (misconceptions/literature_incompatibility_facts.pl)
 *       The LITERATURE / commitment layer. A derived misconception row naming
 *       unit_coordination as the topic where a student rule (conflate group
 *       count with group size) is incompatible with a target commitment (the
 *       unit-role distinction in a partition). This is the "saying" of the same
 *       concept — what the practice presupposes and where it breaks.
 *
 * WHY a union query and not a rename: the two carriers sit at incompatible
 * layers (an executable recollection-tally builder vs a deontic fact about a
 * commitment) with different arities and different argument meanings. Renaming
 * either into the other would conflate computing with justifying — exactly the
 * solve/6-vs-proves/1 split CLAUDE.md forbids collapsing. So this module adds a
 * single read-only, source-tagged union view and touches nothing.
 *
 * PROJECTION (different arities normalized to a common shape): the canonical
 * predicate yields unit_coordination_unified(-Key, -Detail, -Source).
 *   - Key    : a ground descriptor of the instance.
 *   - Detail : a source-specific payload term (see below).
 *   - Source : strategy_compose | literature_commitment.
 * The strategy layer is value-RETURNING but side-effecting (it calls
 * incur_cost/1 and runs a tally recursion), so it is exposed only through a
 * single deterministic, ground demonstration binding wrapped in once/1 + catch
 * — never invoked on arbitrary or unbound input from this query. The literature
 * layer is pure facts and is unioned directly. Callers who want to run the
 * strategy on their own inputs should dispatch
 * divaded_fractional_units:coordinate_units/4 themselves; this crosswalk only
 * demonstrates that the wire resolves.
 *
 * No existing predicate is renamed or rewritten. use_module import lists are
 * empty: we call both sources fully module-qualified and pull no names in.
 * Part of the canonical-vocabulary crosswalk (same style as
 * crosswalk/canonical_vocabulary.pl). Family slug: unit_coordination.
 */
:- module(cw_unit_coordination,
          [ unit_coordination_unified/3, % unit_coordination_unified(-Key, -Detail, -Source)
            unit_coordination_witness/4, % unit_coordination_witness(-Key, -Detail, ?Source, -Witness)
            canonical_concept/2,          % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2           % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

% Load the owning modules so their predicates exist; empty import lists because
% every call below is module-qualified. Both confirmed to load and co-load clean
% under paths.pl.
:- use_module(math(divaded_fractional_units), []).
:- use_module(misconceptions(literature_incompatibility_facts), []).

%! unit_coordination_unified(-Key, -Detail, -Source) is nondet.
%
%  The canonical query for the unit-coordination family. Each solution names one
%  instance of the concept and the Source layer it came from.
%
%  Source = literature_commitment:
%    Key    = lit(Id, Domain)
%    Detail = commitment(StudentRule, ValidDomain, IncompatibleWith, Valence)
%    Drawn directly from lit_derived/9 rows whose Topic is unit_coordination.
%
%  Source = strategy_compose:
%    Key    = compose(UnitSizeInt, UnitCountInt)
%    Detail = composite(CompositeInt)
%    A single deterministic ground demonstration that the executable strategy
%    wire resolves: coordinate_units/4 builds a composite of UnitSizeInt-sized
%    tallies over UnitCountInt units (here 2 over 3 -> 6). Wrapped in once/1 +
%    catch so its incur_cost/1 side effect runs at most once and an error
%    contributes nothing. Not a general computation surface — see module header.
unit_coordination_unified(lit(Id, Domain),
                          commitment(StudentRule, ValidDomain, IncompatibleWith, Valence),
                          literature_commitment) :-
    unit_coordination_witness(lit(Id, Domain),
                              commitment(StudentRule, ValidDomain, IncompatibleWith, Valence),
                              literature_commitment,
                              _).
unit_coordination_unified(compose(UnitSizeInt, UnitCountInt),
                          composite(CompositeInt),
                          strategy_compose) :-
    unit_coordination_witness(compose(UnitSizeInt, UnitCountInt),
                              composite(CompositeInt),
                              strategy_compose,
                              _).

%! unit_coordination_witness(-Key, -Detail, ?Source, -Witness) is nondet.
%
%  Witnessed form of `unit_coordination_unified/3`. This is a closed-world
%  finite projection over the currently loaded unit-coordination sources. It
%  does not decide the open-ended mathematical or developmental relation in
%  general; it records which loaded source produced this concrete crosswalk row.
unit_coordination_witness(Key, Detail, Source,
                          _{ kind: unit_coordination_crosswalk,
                             scope: closed_world_finite_loaded_unit_coordination_sources,
                             source: Source,
                             legacy_functor: LegacyFunctor,
                             key: Key,
                             detail: Detail,
                             derivation: Derivation,
                             source_witness: SourceWitness }) :-
    unit_coordination_source(Source, LegacyFunctor),
    source_unit_coordination_witness(Source,
                                     Key,
                                     Detail,
                                     Derivation,
                                     SourceWitness).

unit_coordination_source(strategy_compose,
                         'divaded_fractional_units:coordinate_units/4').
unit_coordination_source(literature_commitment,
                         'literature_incompatibility_facts:lit_derived/9(Topic=unit_coordination)').

source_unit_coordination_witness(literature_commitment,
                                 lit(Id, Domain),
                                 commitment(StudentRule, ValidDomain, IncompatibleWith, Valence),
                                 literature_topic_lookup,
                                 _{ kind: unit_coordination_literature_commitment,
                                    id: Id,
                                    domain: Domain,
                                    topic: unit_coordination,
                                    student_rule: StudentRule,
                                    valid_domain: ValidDomain,
                                    incompatible_with: IncompatibleWith,
                                    valence: Valence,
                                    level: Level,
                                    confidence: Confidence }) :-
    catch(literature_incompatibility_facts:lit_derived(Id, Domain, unit_coordination,
                                                        StudentRule, ValidDomain,
                                                        IncompatibleWith, Valence,
                                                        Level, Confidence),
          _, fail).
source_unit_coordination_witness(strategy_compose,
                                 compose(UnitSizeInt, UnitCountInt),
                                 composite(CompositeInt),
                                 deterministic_strategy_demo,
                                 _{ kind: unit_coordination_strategy_composition,
                                    demonstration: fixed_ground_strategy_demo,
                                    unit_size: UnitSizeInt,
                                    unit_count: UnitCountInt,
                                    unit_size_recollection: SizeRec,
                                    unit_count_recollection: CountRec,
                                    composite_recollection: Composite,
                                    composite_int: CompositeInt,
                                    trace: Trace }) :-
    UnitSizeInt = 2,
    UnitCountInt = 3,
    int_to_rec(UnitSizeInt, SizeRec),
    int_to_rec(UnitCountInt, CountRec),
    catch(once(divaded_fractional_units:coordinate_units(SizeRec, CountRec,
                                                         Composite, Trace)),
          _, fail),
    divaded_fractional_units:rec_to_int(Composite, CompositeInt).

%! int_to_rec(+Int, -Recollection) is det.
%
%  Local integer -> recollection([_|...]) marshaller. Kept private (not exported)
%  so it cannot be mistaken for the canonical vocabulary; it only feeds the
%  strategy demonstration binding above.
int_to_rec(Int, recollection(L)) :-
    integer(Int), Int >= 0,
    length(L, Int).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
%
%  Maps each scattered legacy functor to this family's canonical name.
canonical_concept('divaded_fractional_units:coordinate_units/4',     unit_coordination).
canonical_concept('literature_incompatibility_facts:lit_derived/9(Topic=unit_coordination)',
                  unit_coordination).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(unit_coordination,
    [ 'divaded_fractional_units:coordinate_units/4',
      'literature_incompatibility_facts:lit_derived/9(Topic=unit_coordination)' ]).
