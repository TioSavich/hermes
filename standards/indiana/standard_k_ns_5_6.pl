/** <module> Standards K.NS.5-6 — Comparing groups and numerals
 *
 * Indiana: K.NS.5 — "Identify whether the number of objects in one group
 *          is greater than, less than, or equal to the number of objects
 *          in another group (e.g., by using matching and counting)."
 *          K.NS.6 — "Compare the values of two numbers from 1 to 20
 *          presented as written numerals."
 * CCSS:    K.CC.C.6 — compare groups by matching and counting
 *          K.CC.C.7 — compare two written numerals (1-10)
 *
 * VPV MAPPING:
 *   V  (target vocabulary): "greater than", "less than", "equal to",
 *      "more", "fewer", "the same number"
 *   P  (practices): matching strategy (pair objects one-to-one, check
 *      for leftovers); counting strategy (count both, compare counts);
 *      numeral comparison (compare written numerals via their quantities)
 *   V' (metavocabulary): "which group has more?", "are they the same?",
 *      "which number is bigger?", "how do you know?"
 *
 * BRANDOM CONNECTION: Comparison introduces incompatibility into the
 *   number vocabulary. "Five is greater than three" is a material
 *   inference with exclusionary force: if five > three, then NOT
 *   five < three, and NOT five = three. This three-way partition
 *   (greater/less/equal) is an XOR structure in the meaning field
 *   (design/01). The learner who masters comparison has acquired
 *   the incompatibility relations that structure the number line.
 *
 * BOUNDARIES:
 *   - This is the closed-world finite list case for comparison: each supplied
 *     list element is treated as one object, and matching is proved by pairing
 *     list positions until one side is exhausted. Spatial arrangement and
 *     physical movement are outside this symbolic checker.
 *   - Quantity comparison is computed over the loaded grounded-arithmetic
 *     relation. The module exposes the finite comparison witness and its
 *     excluded alternatives; it does not model the learner's discovery that
 *     counting and matching are equivalent strategies.
 */

:- module(standard_k_ns_5_6, [
    compare_groups/3,      % +GroupA, +GroupB, -Result
    compare_groups_witness/4, % +GroupA, +GroupB, -Result, -Witness
    compare_by_matching/3, % +GroupA, +GroupB, -Result
    compare_by_matching_witness/4, % +GroupA, +GroupB, -Result, -Witness
    compare_by_counting/3, % +GroupA, +GroupB, -Result
    compare_by_counting_witness/4, % +GroupA, +GroupB, -Result, -Witness
    compare_numerals/3,    % +NameA, +NameB, -Result
    compare_numerals_witness/4 % +NameA, +NameB, -Result, -Witness
]).

:- use_module(formalization(grounded_arithmetic), [
    smaller_than/2,
    greater_than/2,
    equal_to/2,
    recollection_to_integer/2,
    incur_cost/1
]).

:- use_module(standard_k_ns_3, [
    count_collection_witness/4
]).

:- use_module(standard_k_ns_2, [
    read_numeral_witness/3
]).

% ============================================================
% K.NS.5: Compare groups of objects
% ============================================================

%!  compare_groups(+GroupA, +GroupB, -Result) is det.
%
%   Compare two groups of objects. Returns one of:
%     greater_than — GroupA has more objects
%     less_than    — GroupA has fewer objects
%     equal_to     — same number of objects
%
%   Uses counting strategy (count both, compare counts).

compare_groups(GroupA, GroupB, Result) :-
    compare_groups_witness(GroupA, GroupB, Result, _).

%!  compare_groups_witness(+GroupA, +GroupB, -Result, -Witness) is det.
%
%   Witness-bearing group comparison. The public group-comparison API uses the
%   counting strategy, then exposes both K.NS.3 count witnesses and the
%   K.NS.5-6 quantity-comparison witness that excludes the two other result
%   alternatives.
compare_groups_witness(GroupA, GroupB, Result, Witness) :-
    compare_by_counting_witness(GroupA, GroupB, Result, CountingWitness),
    get_dict(count_a, CountingWitness, CountA),
    get_dict(count_b, CountingWitness, CountB),
    get_dict(count_a_value, CountingWitness, CountAValue),
    get_dict(count_b_value, CountingWitness, CountBValue),
    get_dict(count_a_witness, CountingWitness, CountAWitness),
    get_dict(count_b_witness, CountingWitness, CountBWitness),
    get_dict(comparison_witness, CountingWitness, ComparisonWitness),
    incompatible_results(Result, Incompatible),
    Witness = _{ kind: standard_k_ns_5_6_group_comparison,
                 scope: closed_world_finite_supplied_object_lists,
                 standard: in_k_ns_5_6,
                 source_predicate: compare_groups/3,
                 strategy: counting,
                 group_a: GroupA,
                 group_b: GroupB,
                 count_a: CountA,
                 count_b: CountB,
                 count_a_value: CountAValue,
                 count_b_value: CountBValue,
                 result: Result,
                 incompatible_results: Incompatible,
                 derivation: count_both_groups_then_compare_quantities,
                 boundary: supplied_lists_and_grounded_arithmetic_order,
                 count_a_witness: CountAWitness,
                 count_b_witness: CountBWitness,
                 comparison_witness: ComparisonWitness,
                 strategy_witness: CountingWitness }.

%!  compare_by_matching(+GroupA, +GroupB, -Result) is det.
%
%   Compare by one-to-one matching: pair objects from each group
%   until one runs out. If A runs out first, A < B. If B runs
%   out first, A > B. If both run out together, A = B.
%
%   This is the concrete matching strategy children use before
%   they can count reliably.

compare_by_matching(GroupA, GroupB, Result) :-
    compare_by_matching_witness(GroupA, GroupB, Result, _).

%!  compare_by_matching_witness(+GroupA, +GroupB, -Result, -Witness) is det.
%
%   Prove comparison by one-to-one matching over the supplied finite lists.
%   The terminal case records which side ran out first, making the exclusionary
%   force of the result inspectable rather than implicit in the recursion.
compare_by_matching_witness(GroupA, GroupB, Result, Witness) :-
    matching_comparison_witness(GroupA,
                                GroupB,
                                1,
                                Result,
                                MatchedPairs,
                                Steps,
                                TerminalCase),
    incompatible_results(Result, Incompatible),
    length(GroupA, SizeA),
    length(GroupB, SizeB),
    length(MatchedPairs, MatchedPairCount),
    Witness = _{ kind: standard_k_ns_5_6_matching_comparison,
                 scope: closed_world_finite_supplied_object_lists,
                 standard: in_k_ns_5_6,
                 source_predicate: compare_by_matching/3,
                 group_a: GroupA,
                 group_b: GroupB,
                 size_a: SizeA,
                 size_b: SizeB,
                 matched_pairs: MatchedPairs,
                 matched_pair_count: MatchedPairCount,
                 result: Result,
                 incompatible_results: Incompatible,
                 terminal_case: TerminalCase,
                 derivation: one_to_one_matching_until_exhaustion,
                 boundary: supplied_lists_are_the_compared_object_groups,
                 steps: Steps }.

%!  compare_by_counting(+GroupA, +GroupB, -Result) is det.
%
%   Compare by counting both groups and comparing the counts.
%   More sophisticated than matching — requires cardinality
%   understanding (K.NS.3).

compare_by_counting(GroupA, GroupB, Result) :-
    compare_by_counting_witness(GroupA, GroupB, Result, _).

%!  compare_by_counting_witness(+GroupA, +GroupB, -Result, -Witness) is det.
%
%   Prove comparison by counting each supplied finite list using K.NS.3, then
%   comparing the resulting recollections with the grounded-arithmetic order.
compare_by_counting_witness(GroupA, GroupB, Result, Witness) :-
    incur_cost(inference),
    count_collection_witness(GroupA, CountA, PairingA, CountAWitness),
    count_collection_witness(GroupB, CountB, PairingB, CountBWitness),
    comparison_relation_witness(CountA, CountB, Result, ComparisonWitness),
    incompatible_results(Result, Incompatible),
    recollection_to_integer(CountA, CountAValue),
    recollection_to_integer(CountB, CountBValue),
    Witness = _{ kind: standard_k_ns_5_6_counting_comparison,
                 scope: closed_world_finite_supplied_object_lists,
                 standard: in_k_ns_5_6,
                 source_predicate: compare_by_counting/3,
                 group_a: GroupA,
                 group_b: GroupB,
                 count_a: CountA,
                 count_b: CountB,
                 count_a_value: CountAValue,
                 count_b_value: CountBValue,
                 pairing_a: PairingA,
                 pairing_b: PairingB,
                 result: Result,
                 incompatible_results: Incompatible,
                 derivation: count_both_groups_then_compare_quantities,
                 boundary: supplied_lists_and_grounded_arithmetic_order,
                 count_a_witness: CountAWitness,
                 count_b_witness: CountBWitness,
                 comparison_witness: ComparisonWitness }.


% ============================================================
% K.NS.6: Compare written numerals
% ============================================================

%!  compare_numerals(+NameA, +NameB, -Result) is semidet.
%
%   Compare two number words by resolving them to their
%   recollection structures and comparing. Fails if either
%   name is unknown.
%
%   This models K.NS.6: comparing written numerals requires
%   knowing what quantities they represent (K.NS.2) and
%   being able to compare quantities (K.NS.5).

compare_numerals(NameA, NameB, Result) :-
    compare_numerals_witness(NameA, NameB, Result, _).

%!  compare_numerals_witness(+NameA, +NameB, -Result, -Witness) is semidet.
%
%   Resolve each written numeral through the current K.NS.2 taught-name table,
%   then expose the finite grounded-order comparison and the excluded result
%   alternatives.
compare_numerals_witness(NameA, NameB, Result, Witness) :-
    incur_cost(inference),
    read_numeral_witness(NameA, RecA, ReadAWitness),
    read_numeral_witness(NameB, RecB, ReadBWitness),
    comparison_relation_witness(RecA, RecB, Result, ComparisonWitness),
    incompatible_results(Result, Incompatible),
    recollection_to_integer(RecA, ValueA),
    recollection_to_integer(RecB, ValueB),
    Witness = _{ kind: standard_k_ns_5_6_numeral_comparison,
                 scope: closed_world_finite_dynamic_numeral_table,
                 standard: in_k_ns_5_6,
                 source_predicate: compare_numerals/3,
                 name_a: NameA,
                 name_b: NameB,
                 recollection_a: RecA,
                 recollection_b: RecB,
                 value_a: ValueA,
                 value_b: ValueB,
                 result: Result,
                 incompatible_results: Incompatible,
                 derivation: taught_name_lookup_then_quantity_comparison,
                 boundary: current_standard_k_ns_2_name_table_and_grounded_arithmetic_order,
                 read_a_witness: ReadAWitness,
                 read_b_witness: ReadBWitness,
                 comparison_witness: ComparisonWitness }.

matching_comparison_witness([], [], _Index, equal_to, [], [Step], both_exhausted) :-
    incur_cost(inference),
    Step = _{ kind: standard_k_ns_5_6_matching_terminal,
              terminal_case: both_exhausted,
              result: equal_to,
              derivation: both_groups_exhausted_together }.
matching_comparison_witness([], RemainingB, _Index, less_than, [], [Step], left_exhausted) :-
    incur_cost(inference),
    Step = _{ kind: standard_k_ns_5_6_matching_terminal,
              terminal_case: left_exhausted,
              remaining_b: RemainingB,
              result: less_than,
              derivation: group_a_exhausted_before_group_b }.
matching_comparison_witness(RemainingA, [], _Index, greater_than, [], [Step], right_exhausted) :-
    RemainingA = [_|_],
    incur_cost(inference),
    Step = _{ kind: standard_k_ns_5_6_matching_terminal,
              terminal_case: right_exhausted,
              remaining_a: RemainingA,
              result: greater_than,
              derivation: group_b_exhausted_before_group_a }.
matching_comparison_witness([A|RestA],
                            [B|RestB],
                            Index,
                            Result,
                            [pair(A, B)|Pairs],
                            [Step|Steps],
                            TerminalCase) :-
    incur_cost(inference),
    Step = _{ kind: standard_k_ns_5_6_matching_pair,
              ordinal_index: Index,
              object_a: A,
              object_b: B,
              pair: pair(A, B),
              derivation: remove_one_matched_pair_from_each_group },
    NextIndex is Index + 1,
    matching_comparison_witness(RestA,
                                RestB,
                                NextIndex,
                                Result,
                                Pairs,
                                Steps,
                                TerminalCase).

comparison_relation_witness(Left, Right, Result, Witness) :-
    comparison_relation(Result, Left, Right, Relation),
    incompatible_results(Result, Incompatible),
    recollection_to_integer(Left, LeftValue),
    recollection_to_integer(Right, RightValue),
    Witness = _{ kind: standard_k_ns_5_6_quantity_comparison,
                 scope: closed_world_finite_grounded_arithmetic_order,
                 standard: in_k_ns_5_6,
                 left: Left,
                 right: Right,
                 left_value: LeftValue,
                 right_value: RightValue,
                 result: Result,
                 incompatible_results: Incompatible,
                 relation: Relation,
                 derivation: grounded_arithmetic_three_way_order_partition,
                 boundary: loaded_grounded_arithmetic_order_for_finite_recollections }.

comparison_relation(equal_to, Left, Right, equal_to(Left, Right)) :-
    equal_to(Left, Right).
comparison_relation(less_than, Left, Right, smaller_than(Left, Right)) :-
    smaller_than(Left, Right).
comparison_relation(greater_than, Left, Right, greater_than(Left, Right)) :-
    greater_than(Left, Right).

incompatible_results(greater_than, [less_than, equal_to]).
incompatible_results(less_than, [greater_than, equal_to]).
incompatible_results(equal_to, [greater_than, less_than]).
