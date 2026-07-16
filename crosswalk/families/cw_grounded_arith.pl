/** <module> Crosswalk family: grounded numeration & arithmetic primitives
 *
 * Slug: grounded_arith
 *
 * Concept: arithmetic done over recollection/1 structures (counting
 * histories of `tally` atoms) rather than Prolog's built-in numbers, plus
 * the ontological "is this a validly constructed number" predicate. These
 * scattered functors all denote one concept — grounded numeration and the
 * primitive operations on it — but sit at different layers and arities:
 *
 *   - grounded_arithmetic:add_grounded/3        addition as history concat
 *   - grounded_arithmetic:subtract_grounded/3   subtraction as history removal
 *   - grounded_arithmetic:successor/2           count one more
 *   - grounded_utils:base_decompose_grounded/4  split into base groups + remainder
 *   - robinson_q:is_recollection/2              constructive number-hood + trace
 *
 * This module does NOT rename or rewrite any of them. It adds a single
 * read-only union query, grounded_arith_unified/4, that ranges over every
 * source and tags which one answered. The underlying predicates are
 * untouched. Every source call is guarded with catch/3 so an absent or
 * erroring source contributes nothing.
 *
 * PROJECTION (arities differ, so we normalize to a common queryable shape):
 *
 *   grounded_arith_unified(Op, Inputs, Output, Source)
 *
 * where Op is the operation atom, Inputs is a list of the operands, and
 * Output is the result term:
 *
 *   add        | [A,B]    | Sum            | grounded_arithmetic
 *   subtract   | [M,S]    | Difference     | grounded_arithmetic
 *   successor  | [N]      | Next           | grounded_arithmetic
 *   base_decompose | [Number,Base] | bases_remainder(Bases,Remainder) | grounded_utils
 *   is_recollection | [N] | history(History) | robinson_q
 *
 * SIDE EFFECTS / why this stays a query: add_grounded/3, subtract_grounded/3,
 * successor/2 and (transitively) base_decompose_grounded/4 each call
 * grounded_arithmetic:incur_cost/1, which retract/assertz's a dynamic
 * direct_cost_accumulator/1. To keep grounded_arith_unified/4 net
 * side-effect-free we snapshot the accumulator before the call and restore
 * it after (see with_cost_snapshot/1). is_recollection/2 is pure.
 *
 * NOT wired (sources_dropped):
 *   - formalization/axioms_robinson.pl is_recollection/2 — not a module
 *     (an :- include/1 file gated by robinson_pack_enabled), and CLAUDE.md
 *     forbids co-loading it with robinson_q.pl. The robinson_q.pl module
 *     owner is wired instead.
 *
 * Wave 2 of the canonical-vocabulary pass; same union/guarded/source-tagged
 * style as crosswalk/canonical_vocabulary.pl.
 */
:- module(cw_grounded_arith,
          [ grounded_arith_unified/4,   % grounded_arith_unified(?Op, ?Inputs, ?Output, -Source)
            grounded_arith_witness/5,   % grounded_arith_witness(?Op, ?Inputs, ?Output, ?Source, -Witness)
            canonical_concept/2,        % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2         % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

% Source modules. Module-qualified calls only, so empty import lists are
% intentional (no names pulled into this module, no clashes).
:- use_module(formalization(grounded_arithmetic), []).
:- use_module(formalization(grounded_utils), []).
:- use_module(formalization(robinson_q), []).

%! with_cost_snapshot(:Goal) is semidet.
%
%  Run Goal, then restore grounded_arithmetic's direct_cost_accumulator to
%  whatever it was before, so the union query leaves no cost residue. Goal is
%  wrapped in once/1 + catch/3: at most one solution, and any error makes the
%  source contribute nothing. The snapshot/restore itself is guarded too.
with_cost_snapshot(Goal) :-
    with_cost_snapshot_witness(Goal, _).

with_cost_snapshot_witness(Goal,
                           _{ kind: grounded_arithmetic_cost_snapshot,
                              policy: restore_direct_cost_accumulator_after_read,
                              before: Snapshot,
                              after_goal: AfterGoal,
                              after_restore: AfterRestore }) :-
    ( catch(grounded_arithmetic:direct_cost_accumulated(Snapshot), _, fail) -> true
    ; Snapshot = none ),
    ( catch(once(Goal), _, fail) -> GoalStatus = succeeded ; GoalStatus = failed ),
    ( catch(grounded_arithmetic:direct_cost_accumulated(AfterGoal), _, fail) -> true
    ; AfterGoal = unavailable ),
    ( Snapshot == none -> true
    ; catch(restore_cost(Snapshot), _, true) ),
    ( catch(grounded_arithmetic:direct_cost_accumulated(AfterRestore), _, fail) -> true
    ; AfterRestore = unavailable ),
    GoalStatus == succeeded.

restore_cost(Snapshot) :-
    retractall(grounded_arithmetic:direct_cost_accumulator(_)),
    assertz(grounded_arithmetic:direct_cost_accumulator(Snapshot)).

%! grounded_arith_unified(?Op, ?Inputs, ?Output, ?Source) is nondet.
%
%  Union view over the grounded numeration/arithmetic primitives. Source
%  names the owning module. See module header for the projection table.
grounded_arith_unified(Op, Inputs, Output, Source) :-
    grounded_arith_witness(Op, Inputs, Output, Source, _).

%! grounded_arith_witness(?Op, ?Inputs, ?Output, ?Source, -Witness) is nondet.
%
%  Witnessed union view over the grounded numeration/arithmetic primitives.
%  This is the closed-world finite case for the currently loaded grounded
%  arithmetic modules: a row is visible only when the owning predicate proves
%  the operation for the supplied recollection or integer inputs.
grounded_arith_witness(add, [A, B], Sum, grounded_arithmetic, Witness) :-
    with_cost_snapshot_witness(
        grounded_arithmetic:add_grounded(A, B, Sum),
        CostWitness),
    grounded_operation_witness(add,
                               [A, B],
                               Sum,
                               grounded_arithmetic,
                               add_grounded/3,
                               recollection_history_concatenation,
                               CostWitness,
                               Witness).
grounded_arith_witness(subtract, [M, S], Difference, grounded_arithmetic, Witness) :-
    with_cost_snapshot_witness(
        grounded_arithmetic:subtract_grounded(M, S, Difference),
        CostWitness),
    grounded_operation_witness(subtract,
                               [M, S],
                               Difference,
                               grounded_arithmetic,
                               subtract_grounded/3,
                               recollection_history_removal,
                               CostWitness,
                               Witness).
grounded_arith_witness(successor, [N], Next, grounded_arithmetic, Witness) :-
    with_cost_snapshot_witness(
        grounded_arithmetic:successor(N, Next),
        CostWitness),
    grounded_operation_witness(successor,
                               [N],
                               Next,
                               grounded_arithmetic,
                               successor/2,
                               add_one_tally_to_history,
                               CostWitness,
                               Witness).
grounded_arith_witness(base_decompose,
                       [Number, Base],
                       bases_remainder(Bases, Remainder),
                       grounded_utils,
                       Witness) :-
    with_cost_snapshot_witness(
        grounded_utils:base_decompose_grounded(Number, Base, Bases, Remainder),
        CostWitness),
    grounded_operation_witness(base_decompose,
                               [Number, Base],
                               bases_remainder(Bases, Remainder),
                               grounded_utils,
                               base_decompose_grounded/4,
                               repeated_base_group_subtraction,
                               CostWitness,
                               Witness).
grounded_arith_witness(is_recollection, [N], history(History), robinson_q,
                       _{ kind: grounded_arith_crosswalk,
                          scope: closed_world_finite_verified_grounded_arithmetic_operations,
                          op: is_recollection,
                          inputs: [N],
                          output: history(History),
                          source: robinson_q,
                          projection: constructive_number_trace,
                          derivation: owner_predicate_operation_check,
                          source_witness: _{ kind: grounded_arithmetic_source_row,
                                             module: robinson_q,
                                             predicate: is_recollection/2,
                                             inputs: [N],
                                             output: history(History),
                                             evidence: History },
                          cost_witness: _{ kind: grounded_arithmetic_cost_snapshot,
                                           policy: source_predicate_is_pure,
                                           before: not_applicable,
                                           after_goal: not_applicable,
                                           after_restore: not_applicable } }) :-
    catch(robinson_q:is_recollection(N, History), _, fail).

grounded_operation_witness(Op,
                           Inputs,
                           Output,
                           Source,
                           Predicate,
                           Projection,
                           CostWitness,
                           _{ kind: grounded_arith_crosswalk,
                              scope: closed_world_finite_verified_grounded_arithmetic_operations,
                              op: Op,
                              inputs: Inputs,
                              output: Output,
                              source: Source,
                              projection: Projection,
                              derivation: owner_predicate_operation_check,
                              source_witness: _{ kind: grounded_arithmetic_source_row,
                                                 module: Source,
                                                 predicate: Predicate,
                                                 inputs: Inputs,
                                                 output: Output,
                                                 input_lengths: InputLengths,
                                                 output_length: OutputLength },
                              cost_witness: CostWitness }) :-
    maplist(recollection_length, Inputs, InputLengths),
    recollection_length(Output, OutputLength).

recollection_length(recollection(History), Length) :-
    !,
    length(History, Length).
recollection_length(bases_remainder(Bases, Remainder),
                    bases_remainder(BasesLength, RemainderLength)) :-
    !,
    recollection_length(Bases, BasesLength),
    recollection_length(Remainder, RemainderLength).
recollection_length(Value, not_recollection(Value)).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
canonical_concept('grounded_arithmetic:add_grounded/3',        grounded_arith_unified).
canonical_concept('grounded_arithmetic:subtract_grounded/3',   grounded_arith_unified).
canonical_concept('grounded_arithmetic:successor/2',           grounded_arith_unified).
canonical_concept('grounded_utils:base_decompose_grounded/4',  grounded_arith_unified).
canonical_concept('robinson_q:is_recollection/2',              grounded_arith_unified).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(grounded_arith_unified,
    [ 'grounded_arithmetic:add_grounded/3',
      'grounded_arithmetic:subtract_grounded/3',
      'grounded_arithmetic:successor/2',
      'grounded_utils:base_decompose_grounded/4',
      'robinson_q:is_recollection/2' ]).
