/** <module> Crosswalk family: misconception / deformation hook extraction
 *
 * Problem this solves: several functors across the strategies and
 * misconceptions modules all answer roughly the same question — "given a
 * (possibly deformed) action outcome, what misconception family does it
 * belong to and what is the hook that lets downstream code respond to it?"
 * They sit at different layers and arities and are NOT redundant:
 *
 *   - strategies/math/action_automata_registry: action_automaton_hook/4
 *       (Operation, Outcome, -Family, -Hook) — the cross-domain registry
 *       surface. Dispatches by Operation into the per-domain hook predicates
 *       (additive, multiplicative, fraction, decimal, ...). Pure (reads the
 *       Outcome's classification fields), side-effect free.
 *   - strategies/math/fraction_action_pairs: fraction_action_misconception_hook/3
 *       (Outcome, -Family, -Hook) — the fraction-domain extractor. This is the
 *       predicate action_automaton_hook(fraction, ...) delegates to, so it is
 *       wired here too with Operation pinned to `fraction`. Pure.
 *   - misconceptions/misconception_registry: misconception_registry_entry/5
 *       (Name, Operation, Citation, Commitment, Entitlement) — the
 *       literature-attested registry view. Different shape (no action Outcome;
 *       a named, cited misconception with a commitment/entitlement pair). It
 *       can run heavy search (DB rows, harness replays), so it is called under
 *       once/1 + catch and projected into the common shape (see notes).
 *
 * This module renames nothing. It adds ONE read-only union query,
 * misconception_hook_unified/5, that ranges over every source and tags which
 * source each result came from. Every source call is wrapped in catch/3 so a
 * missing or erroring source contributes nothing.
 *
 * Dropped: misconceptions/misconception_scorekeeping:enact_misconception/2.
 * It is a side-effecting EXECUTOR — it undertakes a commitment in the deontic
 * scorekeeper (asserts state). It denotes "make this misconception move",
 * not "extract the hook for this outcome", so it does not belong in a
 * value-returning, side-effect-free union query.
 *
 * Common projected shape:
 *   misconception_hook_unified(?Operation, ?Outcome, ?Family, ?Hook, -Source)
 *     Operation : operation/domain atom (e.g. multiplication, fraction);
 *                 for the registry source this is the registry's Operation.
 *     Outcome   : the action_outcome/2 term, OR — for the registry source —
 *                 misconception(Name), since the registry has no action outcome.
 *     Family    : the misconception family atom.
 *     Hook      : the action_misconception_hook(...) term, OR — for the
 *                 registry source — registry_hook(Commitment, Entitlement, Citation).
 *     Source    : action_registry | fraction_action | literature_registry
 */
:- module(cw_misconception_hook,
          [ misconception_hook_unified/5,  % (?Operation,?Outcome,?Family,?Hook,-Source)
            misconception_hook_witness/6,  % (?Operation,?Outcome,?Family,?Hook,?Source,-Witness)
            canonical_concept/2,           % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2            % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

% Load the real source modules; called module-qualified so empty import lists
% keep their names out of this module.
:- use_module(strategies('math/action_automata_registry'), []).
:- use_module(strategies('math/fraction_action_pairs'), []).
:- use_module(misconceptions(misconception_registry), []).

%!  misconception_hook_unified(?Operation, ?Outcome, ?Family, ?Hook, -Source) is nondet.
%
%   True when (Operation, Outcome) carries a misconception/deformation Family
%   with response Hook, according to ANY source layer. Source names the layer.
%
%   - action_registry    : action_automata_registry:action_automaton_hook/4.
%                          The cross-domain surface; covers all operation
%                          domains including fraction.
%   - fraction_action    : fraction_action_pairs:fraction_action_misconception_hook/3,
%                          Operation pinned to `fraction`. The fraction-domain
%                          extractor that action_registry delegates to; wired
%                          directly so it is queryable on its own terms.
%   - literature_registry: misconception_registry:misconception_registry_entry/5,
%                          projected (see module header). Called under once/1
%                          because the registry can replay harness/DB search.
misconception_hook_unified(Operation, Outcome, Family, Hook, action_registry) :-
    misconception_hook_witness(Operation, Outcome, Family, Hook, action_registry, _).
misconception_hook_unified(fraction, Outcome, Family, Hook, fraction_action) :-
    misconception_hook_witness(fraction, Outcome, Family, Hook, fraction_action, _).
misconception_hook_unified(Operation, misconception(Name), Family, Hook, literature_registry) :-
    misconception_hook_witness(Operation, misconception(Name), Family, Hook,
                               literature_registry, _).

%!  misconception_hook_witness(?Operation, ?Outcome, ?Family, ?Hook, ?Source, -Witness) is nondet.
%
%   Witnessed form of `misconception_hook_unified/5`. This is a closed-world
%   finite union over the currently loaded hook extractors and literature
%   registry projection. Action-outcome sources are pure hook extractors over an
%   already supplied outcome; the literature source is bounded here by
%   `once/1`, matching the existing projection, because the registry may consult
%   harness and corpus-backed evidence.
misconception_hook_witness(Operation, Outcome, Family, Hook, Source,
                           WitnessDict92) :-
    witness_dict:witness_dict(misconception_hook_crosswalk, closed_world_finite_loaded_misconception_hook_sources,
                              _{operation: Operation,
                              outcome: Outcome,
                              family: Family,
                              hook: Hook,
                              source: Source,
                              legacy_functor: LegacyFunctor,
                              projection: Projection,
                              derivation: Derivation,
                              source_witness: SourceWitness }, WitnessDict92),
    source_misconception_hook_witness(Source,
                                      Operation,
                                      Outcome,
                                      Family,
                                      Hook,
                                      LegacyFunctor,
                                      Projection,
                                      Derivation,
                                      SourceWitness).

source_misconception_hook_witness(
    action_registry,
    Operation,
    Outcome,
    Family,
    Hook,
    'action_automata_registry:action_automaton_hook/4',
    action_outcome_hook_extraction,
    registry_operation_dispatch,
    _{ kind: action_automata_hook_dispatch,
       registry_predicate: 'action_automata_registry:action_automaton_hook/4',
       operation: Operation,
       dispatched_legacy_functor: DispatchedLegacyFunctor,
       outcome_kind: OutcomeKind,
       family: Family,
       hook_fields: HookFields }) :-
    catch(action_automata_registry:action_automaton_hook(Operation, Outcome, Family, Hook),
          _, fail),
    action_hook_dispatch(Operation, DispatchedLegacyFunctor),
    outcome_kind(Outcome, OutcomeKind),
    hook_fields(Hook, HookFields).
source_misconception_hook_witness(
    fraction_action,
    fraction,
    Outcome,
    Family,
    Hook,
    'fraction_action_pairs:fraction_action_misconception_hook/3',
    action_outcome_hook_extraction,
    direct_fraction_hook_extraction,
    _{ kind: direct_fraction_hook_extraction,
       module: fraction_action_pairs,
       predicate: fraction_action_misconception_hook/3,
       outcome_kind: OutcomeKind,
       family: Family,
       hook_fields: HookFields }) :-
    catch(fraction_action_pairs:fraction_action_misconception_hook(Outcome, Family, Hook),
          _, fail),
    outcome_kind(Outcome, OutcomeKind),
    hook_fields(Hook, HookFields).
source_misconception_hook_witness(
    literature_registry,
    Operation,
    misconception(Name),
    Operation,
    registry_hook(Commitment, Entitlement, Citation),
    'misconception_registry:misconception_registry_entry/5',
    registry_entry_projected_to_hook,
    bounded_literature_registry_projection,
    _{ kind: literature_registry_misconception_hook,
       module: misconception_registry,
       predicate: misconception_registry_entry/5,
       name: Name,
       operation: Operation,
       commitment: Commitment,
       entitlement: Entitlement,
       citation: Citation }) :-
    catch(once(misconception_registry:misconception_registry_entry(
                   Name, Operation, Citation, Commitment, Entitlement)),
          _, fail).

outcome_kind(action_outcome(Kind, _Fields), Kind).
outcome_kind(Outcome, unknown) :-
    nonvar(Outcome),
    Outcome \= action_outcome(_, _).

hook_fields(action_misconception_hook(Fields), Fields) :-
    !.
hook_fields(Hook, Hook).

action_hook_dispatch(addition, 'sar_add_action_pairs:action_misconception_hook/3').
action_hook_dispatch(subtraction, 'sar_sub_action_pairs:subtractive_action_misconception_hook/3').
action_hook_dispatch(multiplication, 'smr_mult_action_pairs:multiplicative_action_misconception_hook/3').
action_hook_dispatch(division, 'smr_div_action_pairs:division_action_misconception_hook/3').
action_hook_dispatch(fraction, 'fraction_action_pairs:fraction_action_misconception_hook/3').
action_hook_dispatch(decimal, 'decimal_action_pairs:decimal_action_misconception_hook/3').
action_hook_dispatch(integer, 'integer_action_pairs:integer_action_misconception_hook/3').
action_hook_dispatch(ratio, 'ratio_action_pairs:ratio_action_misconception_hook/3').
action_hook_dispatch(diagnostic, 'diagnostic_validation_action_pairs:diagnostic_action_misconception_hook/3').
action_hook_dispatch(calculus, 'calculus_limits_action_pairs:calculus_action_misconception_hook/3').
action_hook_dispatch(algebraic, 'algebraic_action_pairs:algebraic_action_misconception_hook/3').
action_hook_dispatch(probability, 'probability_action_pairs:probability_action_misconception_hook/3').

%!  canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
%
%   Maps each scattered legacy functor to its canonical query predicate.
canonical_concept('action_automata_registry:action_automaton_hook/4',            misconception_hook).
canonical_concept('fraction_action_pairs:fraction_action_misconception_hook/3',  misconception_hook).
canonical_concept('misconception_registry:misconception_registry_entry/5',       misconception_hook).

%!  vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(misconception_hook,
    [ 'action_automata_registry:action_automaton_hook/4',
      'fraction_action_pairs:fraction_action_misconception_hook/3',
      'misconception_registry:misconception_registry_entry/5' ]).
