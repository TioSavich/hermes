/** <module> Standards 3.CA.3-4 — Multiplication and division models
 *
 * Indiana: 3.CA.3 — "Model the concept of multiplication of whole
 *          numbers using equal-sized groups, arrays, area models,
 *          and equal intervals on a number line." (E)
 *          3.CA.4 — "Model the concept of division of whole numbers
 *          with partitioning, sharing, and an inverse of multiplication."
 * CCSS:    3.OA.A.1 (mult as equal groups), 3.OA.A.2 (div as partition)
 *
 * VPV MAPPING:
 *   V  (target vocabulary): "times", "groups of", "rows and columns",
 *      "divided into", "shared equally", "how many in each group"
 *   P  (practices): equal-group formation; array construction;
 *      repeated addition for multiplication; partitioning for
 *      division; inverse relationship (mult↔div)
 *   V' (metavocabulary): "how many groups of ___?", "how many in
 *      each group?", "what times what equals?", "___ divided by"
 *
 * CONNECTION TO EXISTING AUTOMATA:
 *   Multiplication models connect to:
 *   - smr_mult_c2c.pl — coordinating two counts (most primitive)
 *   - smr_mult_cbo.pl — count by ones (repeated addition)
 *   Division models connect to:
 *   - smr_div_dealing_by_ones.pl — dealing (partitioning model)
 *   - smr_div_cbo.pl — repeated subtraction
 *
 * BRANDOM CONNECTION: Multiplication introduces a genuinely new
 *   vocabulary that cannot be reduced to addition. "3 groups of 4"
 *   and "3 + 3 + 3 + 3" produce the same result (12) but express
 *   different inferential commitments. The multiplication vocabulary
 *   makes the GROUP STRUCTURE visible. Division makes the INVERSE
 *   STRUCTURE visible. These vocabularies are algorithmically
 *   elaborated from addition/subtraction but are not eliminable
 *   into them.
 *
 * CRISIS CONNECTION: Multiplication is where the system's first
 *   efficiency crisis in a new domain appears. Repeated addition
 *   of 7×8 costs 8 additions (O(n)). Skip counting costs O(n)
 *   steps. Derived facts (7×8 = 7×7+7 = 49+7 = 56) are O(1)
 *   if the component facts are known. This parallels the
 *   counting-on → place-value transition in addition.
 *
 * BOUNDARIES:
 *   - This is the closed-world finite 3.CA.3-4 model case for supplied
 *     grounded recollections. It proves multiplication and division models by
 *     executing finite grounded multiplication/division or finite repeated
 *     addition/subtraction traces over the supplied inputs.
 *   - The module proves the model relation for the finite recollection terms
 *     supplied to it; it does not claim a universal account of all
 *     multiplication or division representations.
 *   - The strategy automata listed above are conceptual anchors here. This
 *     module records the finite model proof and does not execute each FSM.
 */

:- module(standard_3_ca_3_4, [
    multiply_equal_groups/3,   % +NumGroups, +GroupSize, -Product
    multiply_equal_groups_witness/4, % +NumGroups, +GroupSize, -Product, -Witness
    multiply_array/3,          % +Rows, +Cols, -Product
    multiply_array_witness/4,  % +Rows, +Cols, -Product, -Witness
    multiply_repeated_add/3,   % +Factor, +Times, -Product
    multiply_repeated_add_witness/4, % +Factor, +Times, -Product, -Witness
    divide_partition/3,        % +Total, +NumGroups, -GroupSize
    divide_partition_witness/4, % +Total, +NumGroups, -GroupSize, -Witness
    divide_repeated_sub/3,     % +Total, +Divisor, -Quotient
    divide_repeated_sub_witness/4, % +Total, +Divisor, -Quotient, -Witness
    mult_div_family/4,         % +A, +B, -Product, -Facts
    mult_div_family_witness/5  % +A, +B, -Product, -Facts, -Witness
]).

:- use_module(formalization(grounded_arithmetic), [
    zero/1,
    successor/2,
    predecessor/2,
    equal_to/2,
    smaller_than/2,
    add_grounded/3,
    subtract_grounded/3,
    multiply_grounded/3,
    divide_grounded/3,
    integer_to_recollection/2,
    recollection_to_integer/2,
    incur_cost/1
]).

% ============================================================
% Multiplication models
% ============================================================

%!  multiply_equal_groups(+NumGroups, +GroupSize, -Product) is det.
%
%   Multiplication as equal-sized groups: NumGroups groups,
%   each with GroupSize items. Uses grounded multiplication
%   (which IS repeated addition internally).

multiply_equal_groups(NumGroups, GroupSize, Product) :-
    multiply_equal_groups_witness(NumGroups, GroupSize, Product, _).

%!  multiply_equal_groups_witness(+NumGroups, +GroupSize, -Product, -Witness) is det.
%
%   Witness-bearing equal-groups model. The proof records the finite number of
%   supplied groups, the size of each group, and the grounded multiplication
%   that gives the total.
multiply_equal_groups_witness(NumGroups, GroupSize, Product, Witness) :-
    incur_cost(inference),
    multiply_grounded(GroupSize, NumGroups, Product),
    equal_groups_witness(NumGroups, GroupSize, Product, Witness).

%!  multiply_array(+Rows, +Cols, -Product) is det.
%
%   Multiplication as array: Rows × Cols. Structurally
%   identical to equal groups but conceptually different —
%   arrays make commutativity visible (rotate the array).

multiply_array(Rows, Cols, Product) :-
    multiply_array_witness(Rows, Cols, Product, _).

%!  multiply_array_witness(+Rows, +Cols, -Product, -Witness) is det.
%
%   Witness-bearing array model. The proof records rows and columns plus the
%   rotated array relation that makes commutativity visible at this finite
%   model boundary.
multiply_array_witness(Rows, Cols, Product, Witness) :-
    incur_cost(inference),
    multiply_grounded(Rows, Cols, Product),
    array_witness(Rows, Cols, Product, Witness).

%!  multiply_repeated_add(+Factor, +Times, -Product) is det.
%
%   Multiplication as explicit repeated addition.
%   Product = Factor + Factor + ... (Times times).
%   This makes the connection to addition visible.

multiply_repeated_add(Factor, Times, Product) :-
    multiply_repeated_add_witness(Factor, Times, Product, _).

%!  multiply_repeated_add_witness(+Factor, +Times, -Product, -Witness) is det.
%
%   Witness-bearing repeated-addition model. Each finite step adds one more
%   copy of `Factor` until `Times` reaches zero.
multiply_repeated_add_witness(Factor, Times, Product, Witness) :-
    incur_cost(inference),
    zero(Zero),
    repeated_add_trace(Factor, Times, Zero, Product, Steps),
    repeated_add_witness(Factor, Times, Product, Steps, Witness).


% ============================================================
% Division models
% ============================================================

%!  divide_partition(+Total, +NumGroups, -GroupSize) is semidet.
%
%   Division as partitioning: divide Total into NumGroups
%   equal groups, find how many in each group.
%   This is the "sharing" model of division.

divide_partition(Total, NumGroups, GroupSize) :-
    divide_partition_witness(Total, NumGroups, GroupSize, _).

%!  divide_partition_witness(+Total, +NumGroups, -GroupSize, -Witness) is semidet.
%
%   Witness-bearing partition model. The proof records the finite sharing
%   relation and the inverse multiplication check: `NumGroups` groups of
%   `GroupSize` compose back to `Total`.
divide_partition_witness(Total, NumGroups, GroupSize, Witness) :-
    incur_cost(inference),
    divide_grounded(Total, NumGroups, GroupSize),
    multiply_grounded(GroupSize, NumGroups, Total),
    partition_witness(Total, NumGroups, GroupSize, Witness).

%!  divide_repeated_sub(+Total, +Divisor, -Quotient) is semidet.
%
%   Division as repeated subtraction: how many times can
%   Divisor be subtracted from Total?
%   This is the "measurement" model of division.

divide_repeated_sub(Total, Divisor, Quotient) :-
    divide_repeated_sub_witness(Total, Divisor, Quotient, _).

%!  divide_repeated_sub_witness(+Total, +Divisor, -Quotient, -Witness) is semidet.
%
%   Witness-bearing measurement division. Each finite step subtracts one
%   `Divisor` from the remaining total and counts one more measured group.
divide_repeated_sub_witness(Total, Divisor, Quotient, Witness) :-
    incur_cost(inference),
    zero(Zero),
    repeated_sub_trace(Total, Divisor, Zero, Quotient, Remainder, Steps),
    repeated_sub_witness(Total, Divisor, Quotient, Remainder, Steps, Witness).


% ============================================================
% Multiplication/division family (inverse relationship)
% ============================================================

%!  mult_div_family(+A, +B, -Product, -Facts) is det.
%
%   Given two factors, produce the complete family:
%   A×B=P, B×A=P, P÷A=B, P÷B=A

mult_div_family(A, B, Product, Facts) :-
    mult_div_family_witness(A, B, Product, Facts, _).

%!  mult_div_family_witness(+A, +B, -Product, -Facts, -Witness) is det.
%
%   Witness-bearing multiplication/division fact family. The facts are derived
%   from one finite multiplication proof and two finite inverse partition
%   proofs, not merely asserted as a list.
mult_div_family_witness(A, B, Product, Facts, Witness) :-
    incur_cost(inference),
    multiply_equal_groups_witness(A, B, Product, MultiplicationWitness),
    divide_partition_witness(Product, A, B, DivisionA),
    divide_partition_witness(Product, B, A, DivisionB),
    Facts = [
        mult(A, B, Product),
        mult(B, A, Product),
        div(Product, A, B),
        div(Product, B, A)
    ],
fact_family_witness(A, B, Product, Facts,
                        MultiplicationWitness, [DivisionA, DivisionB],
                        Witness).

repeated_add_trace(_Factor, Times, Acc, Acc, []) :-
    zero(Zero),
    equal_to(Times, Zero), !.
repeated_add_trace(Factor, Times, Acc, Product, [Step|Steps]) :-
    add_grounded(Acc, Factor, NewAcc),
    predecessor(Times, NewTimes),
    repeated_add_step(Factor, Times, Acc, NewTimes, NewAcc, Step),
    repeated_add_trace(Factor, NewTimes, NewAcc, Product, Steps).

repeated_sub_trace(Remainder, Divisor, Acc, Acc, Remainder, []) :-
    smaller_than(Remainder, Divisor), !.
repeated_sub_trace(Remainder, _Divisor, Acc, Acc, Remainder, []) :-
    zero(Zero),
    equal_to(Remainder, Zero), !.
repeated_sub_trace(Remainder, Divisor, Acc, Quotient, FinalRemainder, [Step|Steps]) :-
    subtract_grounded(Remainder, Divisor, NewRemainder),
    successor(Acc, NewAcc),
    repeated_sub_step(Remainder, Divisor, Acc, NewRemainder, NewAcc, Step),
    repeated_sub_trace(NewRemainder, Divisor, NewAcc, Quotient, FinalRemainder, Steps).

equal_groups_witness(NumGroups, GroupSize, Product,
                     _{ kind: standard_3_ca_3_4_equal_groups,
                        scope: closed_world_finite_standard_3_ca_3_4_whole_number_models,
                        standard: in_3_ca_3_4,
                        source_predicate: multiply_equal_groups/3,
                        model: equal_sized_groups,
                        num_groups: NumGroups,
                        num_groups_count: NumGroupsCount,
                        group_size: GroupSize,
                        group_size_count: GroupSizeCount,
                        product: Product,
                        product_count: ProductCount,
                        derivation: finite_grounded_multiplication_of_equal_groups,
                        boundary: supplied_grounded_recollections }) :-
    recollection_to_integer(NumGroups, NumGroupsCount),
    recollection_to_integer(GroupSize, GroupSizeCount),
    recollection_to_integer(Product, ProductCount).

array_witness(Rows, Cols, Product,
              _{ kind: standard_3_ca_3_4_array,
                 scope: closed_world_finite_standard_3_ca_3_4_whole_number_models,
                 standard: in_3_ca_3_4,
                 source_predicate: multiply_array/3,
                 model: rectangular_array,
                 rows: Rows,
                 rows_count: RowsCount,
                 cols: Cols,
                 cols_count: ColsCount,
                 product: Product,
                 product_count: ProductCount,
                 rotated_model:
                    _{ rows_count: ColsCount,
                       cols_count: RowsCount,
                       product_count: ProductCount,
                       relation: same_finite_cell_count_under_rotation },
                 derivation: finite_grounded_multiplication_of_rows_and_columns,
                 boundary: supplied_grounded_recollections }) :-
    recollection_to_integer(Rows, RowsCount),
    recollection_to_integer(Cols, ColsCount),
    recollection_to_integer(Product, ProductCount).

repeated_add_witness(Factor, Times, Product, Steps,
                     _{ kind: standard_3_ca_3_4_repeated_addition,
                        scope: closed_world_finite_standard_3_ca_3_4_whole_number_models,
                        standard: in_3_ca_3_4,
                        source_predicate: multiply_repeated_add/3,
                        model: repeated_addition,
                        factor: Factor,
                        factor_count: FactorCount,
                        times: Times,
                        times_count: TimesCount,
                        product: Product,
                        product_count: ProductCount,
                        steps: Steps,
                        derivation: finite_repeated_addition_trace,
                        boundary: supplied_grounded_recollections }) :-
    recollection_to_integer(Factor, FactorCount),
    recollection_to_integer(Times, TimesCount),
    recollection_to_integer(Product, ProductCount).

partition_witness(Total, NumGroups, GroupSize,
                  _{ kind: standard_3_ca_3_4_partition_division,
                     scope: closed_world_finite_standard_3_ca_3_4_whole_number_models,
                     standard: in_3_ca_3_4,
                     source_predicate: divide_partition/3,
                     model: equal_sharing_partition,
                     total: Total,
                     total_count: TotalCount,
                     num_groups: NumGroups,
                     num_groups_count: NumGroupsCount,
                     group_size: GroupSize,
                     group_size_count: GroupSizeCount,
                     inverse_multiplication:
                        _{ num_groups_count: NumGroupsCount,
                           group_size_count: GroupSizeCount,
                           product_count: TotalCount },
                     derivation: finite_grounded_division_checked_by_inverse_multiplication,
                     boundary: supplied_grounded_recollections }) :-
    recollection_to_integer(Total, TotalCount),
    recollection_to_integer(NumGroups, NumGroupsCount),
    recollection_to_integer(GroupSize, GroupSizeCount).

repeated_sub_witness(Total, Divisor, Quotient, Remainder, Steps,
                     _{ kind: standard_3_ca_3_4_repeated_subtraction_division,
                        scope: closed_world_finite_standard_3_ca_3_4_whole_number_models,
                        standard: in_3_ca_3_4,
                        source_predicate: divide_repeated_sub/3,
                        model: measurement_division,
                        total: Total,
                        total_count: TotalCount,
                        divisor: Divisor,
                        divisor_count: DivisorCount,
                        quotient: Quotient,
                        quotient_count: QuotientCount,
                        final_remainder: Remainder,
                        final_remainder_count: RemainderCount,
                        steps: Steps,
                        derivation: finite_repeated_subtraction_trace,
                        boundary: supplied_grounded_recollections }) :-
    recollection_to_integer(Total, TotalCount),
    recollection_to_integer(Divisor, DivisorCount),
    recollection_to_integer(Quotient, QuotientCount),
    recollection_to_integer(Remainder, RemainderCount).

fact_family_witness(A, B, Product, Facts, MultiplicationWitness, DivisionWitnesses,
                    _{ kind: standard_3_ca_3_4_multiplication_division_family,
                       scope: closed_world_finite_standard_3_ca_3_4_whole_number_models,
                       standard: in_3_ca_3_4,
                       source_predicate: mult_div_family/4,
                       a: A,
                       a_count: ACount,
                       b: B,
                       b_count: BCount,
                       product: Product,
                       product_count: ProductCount,
                       facts: Facts,
                       multiplication_witness: MultiplicationWitness,
                       division_witnesses: DivisionWitnesses,
                       derivation: multiplication_proof_plus_inverse_partition_proofs,
                       boundary: supplied_grounded_recollections }) :-
    recollection_to_integer(A, ACount),
    recollection_to_integer(B, BCount),
    recollection_to_integer(Product, ProductCount).

repeated_add_step(Factor, TimesBefore, AccBefore, TimesAfter, AccAfter,
                  _{ kind: standard_3_ca_3_4_repeated_addition_step,
                     addend: Factor,
                     addend_count: FactorCount,
                     times_before: TimesBefore,
                     times_before_count: TimesBeforeCount,
                     times_after: TimesAfter,
                     times_after_count: TimesAfterCount,
                     accumulator_before: AccBefore,
                     accumulator_before_count: AccBeforeCount,
                     accumulator_after: AccAfter,
                     accumulator_after_count: AccAfterCount,
                     derivation: add_one_group }) :-
    recollection_to_integer(Factor, FactorCount),
    recollection_to_integer(TimesBefore, TimesBeforeCount),
    recollection_to_integer(TimesAfter, TimesAfterCount),
    recollection_to_integer(AccBefore, AccBeforeCount),
    recollection_to_integer(AccAfter, AccAfterCount).

repeated_sub_step(RemainderBefore, Divisor, QuotientBefore, RemainderAfter, QuotientAfter,
                  _{ kind: standard_3_ca_3_4_repeated_subtraction_step,
                     remainder_before: RemainderBefore,
                     remainder_before_count: RemainderBeforeCount,
                     divisor: Divisor,
                     divisor_count: DivisorCount,
                     quotient_before: QuotientBefore,
                     quotient_before_count: QuotientBeforeCount,
                     remainder_after: RemainderAfter,
                     remainder_after_count: RemainderAfterCount,
                     quotient_after: QuotientAfter,
                     quotient_after_count: QuotientAfterCount,
                     derivation: subtract_one_group }) :-
    recollection_to_integer(RemainderBefore, RemainderBeforeCount),
    recollection_to_integer(Divisor, DivisorCount),
    recollection_to_integer(QuotientBefore, QuotientBeforeCount),
    recollection_to_integer(RemainderAfter, RemainderAfterCount),
    recollection_to_integer(QuotientAfter, QuotientAfterCount).
