/** <module> cw_fraction_claim — canonical crosswalk family for fraction CLAIM concepts
 *
 * Wave-3 of the canonical-vocabulary pass. The eight fraction-claim concepts the
 * PML checker adjudicates (math_claim_checker:check_math_claim/2) were resolvable
 * only as raw literature `c_*` commitment atoms — they had no crosswalk home, so
 * the knowledge spine leaned on the literature surface as a fallback. This family
 * promotes them to first-class canonical terms (legal_term/1) and records, for
 * each, the legacy sources that express it: the literature canonical_commitment
 * atom, the checker claim shape, and the code surfaces that back it.
 *
 * 2026-07-01 (Wave-3 completion): two rows — fraction_number_line_measure and
 * fraction_magnitude_common_whole — originally carried no code edge; they
 * resolved through the literature atom and the checker sample alone. They now
 * carry verified edges into the lesson-monitoring chart registry
 * (lesson_monitoring:chart_registry_cluster/3) and the native misconception
 * harness (test_harness:arith_misconception/6), so every row in this family
 * reaches at least one surface outside the literature and the checker.
 *
 * Same shape as the other crosswalk families: it RENAMES nothing and OWNS no
 * facts — vocabulary_source/2 is the contract the aggregator (canonical_all)
 * ranges over, canonical_concept/2 is the reverse map, and
 * fraction_claim_unified/3 is the live query that pulls the literature gloss and
 * the checker shape per canonical term.
 *
 * Family slug: fraction_claim.
 */
:- module(cw_fraction_claim,
          [ fraction_claim_unified/3,    % fraction_claim_unified(-Canonical, -Detail, -Source)
            fraction_claim_witness/4,    % fraction_claim_witness(?Canonical, ?Detail, ?Source, -Witness)
            claim_literature_atom/2,     % claim_literature_atom(?Canonical, ?LiteratureAtom)
            canonical_concept/2,         % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2,         % vocabulary_source(Canonical, ListOfLegacyFunctors)
            edge/5
          ]).

:- use_module(misconceptions(literature_vocabulary), []).
:- use_module(hermes(math_claim_checker), []).
:- use_module(math(divaded_fractional_units), []).
:- use_module(math(fraction_iterating), []).
:- use_module(strategies('math/action_automata_registry'), []).
:- use_module(formalization(grounded_arithmetic), [ integer_to_recollection/2 ]).
:- use_module(lessons('im/lesson_monitoring'), []).
:- use_module(misconceptions(test_harness), []).
:- use_module(misconceptions(misconceptions_fraction), []).
:- use_module(standards('indiana/standard_3_ns_2'), []).
:- use_module(standards('indiana/standard_3_ns_5'), []).
:- use_module(library(lists), [ member/2, append/2 ]).

edge(standard_3_ns_2,make_unit_fraction_witness/3,[recollection([tally,tally,tally,tally])],[2,3],call_once_bind_out).
edge(standard_3_ns_5,compare_fractions_witness/4,[fraction(recollection([tally]),recollection([tally,tally,tally,tally])),fraction(recollection([tally,tally,tally]),recollection([tally,tally,tally,tally]))],[3,4],call_once_bind_out).

%! fc(?Canonical, ?LiteratureAtom, ?CheckerLabel, ?ExtraLegacyFunctors) is nondet.
%
%  The family table. Each row: the canonical claim concept; the real literature
%  canonical_commitment atom (verified present — 239 such atoms exist); the
%  check_math_claim/2 claim shape; and the further legacy functors that already
%  express the concept. The extra column spans grounded/strategy predicates,
%  lesson-monitoring chart-registry rows, and native misconception-harness rows;
%  each is proven by its own fraction_extra_source_witness/2 clause below.
fc(fraction_equivalence,             c_fraction_equivalence_multiplicative_scaling, 'equivalence/2',          ['divaded_fractional_units:co_measure_fractions/7']).
fc(fraction_completes_whole,         c_fraction_n_over_n_equals_one,                'n_over_n_is_one/1',      ['divaded_fractional_units:iterative_fraction/6']).
fc(fraction_exceeds_whole,           c_fraction_can_equal_or_exceed_one,            'improper/1',             ['action_automata_registry:action_automaton_cluster/3(fraction,improper_fraction_iteration)']).
fc(fraction_number_line_measure,     c_fraction_number_line_measure,                'number_line_position/2',
   [ 'lesson_monitoring:chart_registry_cluster/3(fraction,number_line_unit_interval)',
     'test_harness:arith_misconception/6(db_row(37572),count_marks_not_intervals)',
     'test_harness:arith_misconception/6(db_row(38638),number_line_requires_whole_number)' ]).
fc(fraction_magnitude_common_whole,  c_fraction_magnitude_common_whole,             'midpoint/1',
   [ 'lesson_monitoring:chart_registry_cluster/3(fraction,comparison_same_denominator_numerator)',
     'test_harness:arith_misconception/6(db_row(37586),denominator_only_compare)' ]).
fc(fraction_multiplication,          c_fraction_multiplication_part_of_part,        'multiplication/3',       ['action_automata_registry:action_automaton_cluster/3(fraction,area_model_part_of_part)']).
fc(fraction_subtraction_common_unit, c_fraction_subtraction_common_unit,            'difference/3',           ['divaded_fractional_units:subtract_fractions_by_co_measurement/7']).
fc(unit_fraction_iterable_measure,   c_unit_fraction_iterable_measure,              'iterate_to_whole/2',     ['fraction_iterating:partition_iterate_inverse/2']).

%! claim_literature_atom(?Canonical, ?LiteratureAtom) is nondet.
%  The literature commitment atom a canonical claim concept resolves to.
claim_literature_atom(Canonical, LitAtom) :- fc(Canonical, LitAtom, _, _).

% The legacy functor strings for a canonical term: literature commitment +
% checker claim + any extra backing predicate, all as 'Module:Functor/Arity'
% style atoms (matching the convention used by the other families).
legacy_list(Canonical, Legacies) :-
    fc(Canonical, Lit, CheckerLabel, Extra),
    atomic_list_concat(['literature_vocabulary:canonical_commitment/2(', Lit, ')'], LitFunctor),
    atomic_list_concat(['math_claim_checker:check_math_claim/2(', CheckerLabel, ')'], CheckerFunctor),
    append([[LitFunctor, CheckerFunctor], Extra], Legacies).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(Canonical, Legacies) :- legacy_list(Canonical, Legacies).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
canonical_concept(Legacy, Canonical) :-
    legacy_list(Canonical, Legacies),
    member(Legacy, Legacies).

%! fraction_claim_unified(?Canonical, ?Detail, ?Source) is nondet.
%
%  Source = literature_commitment: Detail = commitment(Atom, Gloss) — the real
%  canonical_commitment gloss for this concept's literature atom.
%  Source = checker_claim: Detail = checker(ClaimShape) — the check_math_claim/2
%  shape that adjudicates this concept.
%  Source = <legacy functor string>: Detail = edge(Functor) — one row per
%  verified extra backing surface.
fraction_claim_unified(Canonical, Detail, Source) :-
    fraction_claim_witness(Canonical, Detail, Source, _).

%! fraction_claim_witness(?Canonical, ?Detail, ?Source, -Witness) is nondet.
%
%  Witnessed form of `fraction_claim_unified/3`. This is a closed-world finite
%  check over the loaded fraction-claim table and the source predicates that own
%  each listed row. The table proposes alignments; this predicate succeeds only
%  when the owning source proves the referenced literature commitment,
%  math-claim checker sample, fraction-unit predicate, action cluster, or
%  partition-iteration inverse.
fraction_claim_witness(
    Canonical,
    commitment(Lit, GlossS),
    literature_commitment,
    WitnessDict113) :-
    witness_dict:witness_dict(fraction_claim_crosswalk, closed_world_finite_verified_fraction_claim_edges,
                              _{canonical: Canonical,
       detail: commitment(Lit, GlossS),
       source: literature_commitment,
       literature_atom: Lit,
       projection: literature_commitment_gloss,
       derivation: literature_canonical_commitment_lookup,
       source_witness: _{ kind: literature_commitment_row,
                          module: literature_vocabulary,
                          predicate: canonical_commitment/2,
                          atom: Lit,
                          gloss: GlossS } }, WitnessDict113),
    fc(Canonical, Lit, _, _),
    catch(literature_vocabulary:canonical_commitment(Lit, Gloss), _, fail),
    ( string(Gloss) -> GlossS = Gloss ; format(string(GlossS), "~w", [Gloss]) ).
fraction_claim_witness(
    Canonical,
    checker(CheckerLabel),
    checker_claim,
    WitnessDict133) :-
    witness_dict:witness_dict(fraction_claim_crosswalk, closed_world_finite_verified_fraction_claim_edges,
                              _{canonical: Canonical,
       detail: checker(CheckerLabel),
       source: checker_claim,
       checker_label: CheckerLabel,
       projection: checker_claim_shape,
       derivation: math_claim_checker_sample,
       source_witness: SourceWitness }, WitnessDict133),
    fc(Canonical, _, CheckerLabel, _),
    checker_label_witness(CheckerLabel, SourceWitness).
fraction_claim_witness(
    Canonical,
    edge(Functor),
    Functor,
    WitnessDict148) :-
    witness_dict:witness_dict(fraction_claim_crosswalk, closed_world_finite_verified_fraction_claim_edges,
                              _{canonical: Canonical,
       detail: edge(Functor),
       source: Functor,
       legacy_functor: Functor,
       projection: verified_extra_legacy_edge,
       derivation: owner_predicate_edge_check,
       source_witness: SourceWitness }, WitnessDict148),
    fc(Canonical, _, _, Extra),
    member(Functor, Extra),
    fraction_extra_source_witness(Functor, SourceWitness).

checker_label_witness(CheckerLabel,
                      _{ kind: math_claim_checker_sample,
                         module: math_claim_checker,
                         predicate: check_math_claim/2,
                         checker_label: CheckerLabel,
                         sample_claim: SampleClaim,
                         verdict: Verdict,
                         checker_result: CheckerResult }) :-
    checker_label_sample(CheckerLabel, SampleClaim),
    catch(math_claim_checker:check_math_claim(SampleClaim, CheckerResult), _, fail),
    CheckerResult.status == "domain_checked",
    Verdict = CheckerResult.verdict.

checker_label_sample('equivalence/2',
                     equivalence(fraction(2, 4), fraction(1, 2))).
checker_label_sample('n_over_n_is_one/1',
                     n_over_n_is_one(fraction(3, 3))).
checker_label_sample('improper/1',
                     improper(fraction(4, 3))).
checker_label_sample('number_line_position/2',
                     number_line_position(fraction(2, 4), between(0, 1))).
checker_label_sample('midpoint/1',
                     midpoint(fraction(2, 4))).
checker_label_sample('multiplication/3',
                     multiplication(fraction(3, 4),
                                    fraction(2, 3),
                                    fraction(6, 12))).
checker_label_sample('difference/3',
                     difference(fraction(3, 4),
                                fraction(2, 3),
                                fraction(1, 12))).
checker_label_sample('iterate_to_whole/2',
                     iterate_to_whole(fraction(1, 4), times(4))).

fraction_extra_source_witness(
    'divaded_fractional_units:co_measure_fractions/7',
    _{ kind: fraction_co_measurement_edge,
       module: divaded_fractional_units,
       predicate: co_measure_fractions/7,
       sample: equivalence(fraction(2, 4), fraction(1, 2)),
       profile: mc3,
       state: State,
       trace: Trace }) :-
    recs([2, 4, 1, 2], [R2, R4, R1, R2b]),
    catch(divaded_fractional_units:co_measure_fractions(
              R2,
              R4,
              R1,
              R2b,
              mc3,
              State,
              Trace),
          _, fail).
fraction_extra_source_witness(
    'divaded_fractional_units:iterative_fraction/6',
    _{ kind: fraction_iterative_unit_edge,
       module: divaded_fractional_units,
       predicate: iterative_fraction/6,
       sample: n_over_n_is_one(fraction(3, 3)),
       state: State,
       trace: Trace }) :-
    recs([3], [R3]),
    catch(divaded_fractional_units:iterative_fraction(
              R3,
              R3,
              unit(whole),
              available_prior,
              State,
              Trace),
          _, fail).
fraction_extra_source_witness(
    'action_automata_registry:action_automaton_cluster/3(fraction,improper_fraction_iteration)',
    SourceWitness) :-
    action_cluster_witness(fraction, improper_fraction_iteration, SourceWitness).
fraction_extra_source_witness(
    'action_automata_registry:action_automaton_cluster/3(fraction,area_model_part_of_part)',
    SourceWitness) :-
    action_cluster_witness(fraction, area_model_part_of_part, SourceWitness).
fraction_extra_source_witness(
    'divaded_fractional_units:subtract_fractions_by_co_measurement/7',
    _{ kind: fraction_subtraction_co_measurement_edge,
       module: divaded_fractional_units,
       predicate: subtract_fractions_by_co_measurement/7,
       sample: difference(fraction(3, 4), fraction(2, 3), fraction(1, 12)),
       profile: mc3,
       state: State,
       trace: Trace }) :-
    recs([3, 4, 2, 3], [R3, R4, R2, R3b]),
    catch(divaded_fractional_units:subtract_fractions_by_co_measurement(
              R3,
              R4,
              R2,
              R3b,
              mc3,
              State,
              Trace),
          _, fail).
fraction_extra_source_witness(
    'fraction_iterating:partition_iterate_inverse/2',
    _{ kind: fraction_partition_iterate_inverse_edge,
       module: fraction_iterating,
       predicate: partition_iterate_inverse/2,
       sample: iterate_to_whole(fraction(1, 4), times(4)),
       whole: unit(whole),
       base: 4 }) :-
    recs([4], [R4]),
    catch(fraction_iterating:partition_iterate_inverse(unit(whole), R4),
          _, fail).
fraction_extra_source_witness(
    'lesson_monitoring:chart_registry_cluster/3(fraction,number_line_unit_interval)',
    SourceWitness) :-
    chart_registry_cluster_witness(number_line_unit_interval, SourceWitness).
fraction_extra_source_witness(
    'lesson_monitoring:chart_registry_cluster/3(fraction,comparison_same_denominator_numerator)',
    SourceWitness) :-
    chart_registry_cluster_witness(comparison_same_denominator_numerator, SourceWitness).
fraction_extra_source_witness(
    'test_harness:arith_misconception/6(db_row(37572),count_marks_not_intervals)',
    SourceWitness) :-
    misconception_row_witness(db_row(37572), count_marks_not_intervals, SourceWitness).
fraction_extra_source_witness(
    'test_harness:arith_misconception/6(db_row(38638),number_line_requires_whole_number)',
    SourceWitness) :-
    misconception_row_witness(db_row(38638), number_line_requires_whole_number, SourceWitness).
fraction_extra_source_witness(
    'test_harness:arith_misconception/6(db_row(37586),denominator_only_compare)',
    SourceWitness) :-
    misconception_row_witness(db_row(37586), denominator_only_compare, SourceWitness).

% A lesson-monitoring chart-registry row for the fraction source: the chart
% cell id and the action-automata cluster it routes to. The witness proves the
% row against lesson_monitoring's registry table, skips the catch-all identity
% clause (Cluster \== CellId), and confirms the routed cluster is live in the
% action-automata registry (some fraction action kind dispatches into it).
chart_registry_cluster_witness(
    CellId,
    _{ kind: monitoring_chart_registry_edge,
       module: lesson_monitoring,
       predicate: chart_registry_cluster/3,
       source: fraction,
       cell: CellId,
       registry_cluster: Cluster,
       cluster_action_kind: Kind }) :-
    catch(lesson_monitoring:chart_registry_cluster(fraction, CellId, Cluster),
          _, fail),
    Cluster \== CellId,
    once(catch(action_automata_registry:action_automaton_cluster(fraction, Kind, Cluster),
               _, fail)).

% A registered native misconception row that denies the claim concept: the row
% exists in the misconception test harness AND its rule, run on the row's own
% input, computes something other than the recorded correct answer. The
% deviation is what makes the row a genuine incompatibility edge rather than a
% name match.
misconception_row_witness(
    Row,
    Name,
    _{ kind: registered_misconception_edge,
       module: test_harness,
       predicate: arith_misconception/6,
       row: Row,
       misconception: Name,
       rule: Rule,
       input: Input,
       misconception_answer: Got,
       correct_answer: Expected }) :-
    catch(test_harness:arith_misconception(Row, fraction, Name, Rule, Input, Expected),
          _, fail),
    catch(once(call(Rule, Input, Got)), _, fail),
    Got \== Expected.

action_cluster_witness(
    Operation,
    ActionKind,
    _{ kind: action_automaton_cluster_edge,
       module: action_automata_registry,
       predicate: action_automaton_cluster/3,
       operation: Operation,
       action_kind: ActionKind,
       cluster: Cluster,
       vocabulary: Vocabulary }) :-
    catch(action_automata_registry:action_automaton_cluster(Operation, ActionKind, Cluster),
          _, fail),
    catch(action_automata_registry:action_automaton_vocabulary(Operation, ActionKind, Vocabulary),
          _, fail).

recs(Ints, Recs) :-
    maplist(integer_to_recollection, Ints, Recs).
