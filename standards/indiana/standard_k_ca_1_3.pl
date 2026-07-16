/** <module> Standards K.CA.1-3 — Addition, subtraction, decomposition within 10
 *
 * Indiana: K.CA.1 — "Solve real-world problems that involve addition and
 *          subtraction within 10 using modeling with objects or drawings."
 *          K.CA.2 — "Use objects or drawings to model the decomposition of
 *          numbers less than 10 into pairs in more than one way."
 *          K.CA.3 — "Find the number that makes 10 when added to the given
 *          number for any number from 1 to 9."
 * CCSS:    K.OA.A.1-4
 *
 * VPV MAPPING:
 *   V  (target vocabulary): "add", "subtract", "put together",
 *      "take apart", "makes ten", "how many more to make ten"
 *   P  (practices): counting-all for addition (count both groups
 *      together); counting-all for subtraction (remove and recount);
 *      decomposition (find all pairs summing to N); complement
 *      finding (what + given = 10)
 *   V' (metavocabulary): "how many altogether?", "how many are left?",
 *      "what are all the ways to break apart 5?", "what do you add
 *      to 7 to make 10?"
 *
 * BRANDOM CONNECTION: Addition and subtraction are the first operations
 *   that deploy the counting vocabulary inferentially. "3 + 2 = 5"
 *   is a material inference: anyone who has mastered counting (K.NS.1)
 *   and cardinality (K.NS.3) is entitled to conclude that combining
 *   groups of 3 and 2 produces a group of 5. Decomposition makes
 *   this bidirectional: 5 can be decomposed into 3+2 OR 4+1 OR 5+0.
 *   "Makes ten" is the first constraint-based problem — the learner
 *   must find a specific complement, not just combine or decompose.
 *
 * CONNECTION TO EXISTING AUTOMATA:
 *   The addition here is "counting all" — the predecessor to
 *   sar_add_counting_on.pl. Counting-all enumerates both addends
 *   from scratch (cost: O(A+B)). Counting-on (K.NS.1's count_on_from)
 *   starts from A (cost: O(B)). The crisis that drives the transition
 *   from counting-all to counting-on is the efficiency gap.
 *
 * BOUNDARIES:
 *   - This is the closed-world finite K.CA.1-3 operation case for supplied
 *     object lists and grounded recollections.
 *   - "Objects or drawings" are represented by supplied object lists. The
 *     module proves the arithmetic relation and does not parse real-world
 *     story problems or visual drawings.
 *   - Decomposition enumerates the finite kindergarten case for numbers
 *     through ten. The witness marks values outside that classroom bound
 *     rather than presenting the enumeration as an open-ended solver.
 */

:- module(standard_k_ca_1_3, [
    add_objects/3,         % +GroupA, +GroupB, -Total
    add_objects_witness/4, % +GroupA, +GroupB, -Total, -Witness
    subtract_objects/3,    % +Group, +Remove, -Remaining
    subtract_objects_witness/4, % +Group, +Remove, -Remaining, -Witness
    decompose_pairs/2,     % +Number, -Pairs
    decompose_pairs_witness/3, % +Number, -Pairs, -Witness
    find_complement_to_ten/2, % +Given, -Complement
    find_complement_to_ten_witness/3 % +Given, -Complement, -Witness
]).

:- use_module(formalization(grounded_arithmetic), [
    zero/1,
    equal_to/2,
    smaller_than/2,
    add_grounded/3,
    subtract_grounded/3,
    integer_to_recollection/2,
    recollection_to_integer/2,
    incur_cost/1
]).

:- use_module(standard_k_ns_3, [
    count_collection_witness/4
]).

% ============================================================
% K.CA.1: Addition within 10 (counting-all strategy)
% ============================================================

%!  add_objects(+GroupA, +GroupB, -Total) is det.
%
%   Add two groups of objects by combining them and counting
%   the total. This is the counting-all strategy: physically
%   put both groups together, then count everything.
%
%   GroupA and GroupB are lists of objects.
%   Total is the count as a recollection.

add_objects(GroupA, GroupB, Total) :-
    add_objects_witness(GroupA, GroupB, Total, _).

%!  add_objects_witness(+GroupA, +GroupB, -Total, -Witness) is det.
%
%   Witness-bearing counting-all addition. The proof records the supplied
%   object lists, the combined list, and the K.NS.3 count witness for the
%   resulting group.

add_objects_witness(GroupA, GroupB, Total, Witness) :-
    incur_cost(inference),
    append(GroupA, GroupB, Combined),
    count_collection_witness(Combined, Total, _Order, CountWitness),
    add_objects_witness_(GroupA, GroupB, Combined, Total, CountWitness, Witness).


% ============================================================
% K.CA.1: Subtraction within 10 (take-away strategy)
% ============================================================

%!  subtract_objects(+Group, +Remove, -Remaining) is semidet.
%
%   Subtract by removing objects from a group and counting
%   what remains. Remove is a count (recollection) of how
%   many to take away.
%
%   Fails if trying to remove more than available.

subtract_objects(Group, Remove, Remaining) :-
    subtract_objects_witness(Group, Remove, Remaining, _).

%!  subtract_objects_witness(+Group, +Remove, -Remaining, -Witness) is semidet.
%
%   Witness-bearing take-away subtraction. The proof records the K.NS.3 count
%   of the starting group and the grounded subtraction that produces the
%   remaining count.

subtract_objects_witness(Group, Remove, Remaining, Witness) :-
    incur_cost(inference),
    count_collection_witness(Group, GroupCount, _Order, CountWitness),
    subtract_grounded(GroupCount, Remove, Remaining),
    subtract_objects_witness_(Group, Remove, Remaining, GroupCount, CountWitness, Witness).


% ============================================================
% K.CA.2: Decomposition into pairs
% ============================================================

%!  decompose_pairs(+Number, -Pairs) is det.
%
%   Find all ways to decompose Number (a recollection) into
%   pairs (A, B) where A + B = Number and A ≤ B.
%   Returns a list of pair(A, B) terms.
%
%   Example: decompose_pairs(5) → [pair(0,5), pair(1,4), pair(2,3)]

decompose_pairs(Number, Pairs) :-
    decompose_pairs_witness(Number, Pairs, _).

%!  decompose_pairs_witness(+Number, -Pairs, -Witness) is det.
%
%   Witness-bearing finite decomposition. The proof enumerates all unordered
%   pairs A =< B whose grounded addition returns the supplied number.

decompose_pairs_witness(Number, Pairs, Witness) :-
    incur_cost(inference),
    recollection_to_integer(Number, N),
    findall(
        pair(RecA, RecB)-PairWitness,
        (   between(0, N, A),
            B is N - A,
            A =< B,
            integer_to_recollection(A, RecA),
            integer_to_recollection(B, RecB),
            add_grounded(RecA, RecB, Number),
            pair_witness(Number, RecA, RecB, PairWitness)
        ),
        PairEntries
    ),
    pairs_and_witnesses(PairEntries, Pairs, PairWitnesses),
    decompose_pairs_witness_(Number, Pairs, PairWitnesses, Witness).


% ============================================================
% K.CA.3: Find complement to make 10
% ============================================================

%!  find_complement_to_ten(+Given, -Complement) is semidet.
%
%   Given a number from 1 to 9, find what must be added
%   to make 10. This is the first constraint-satisfaction
%   problem: solve Given + ? = 10.
%
%   Fails if Given ≥ 10 or Given ≤ 0.

find_complement_to_ten(Given, Complement) :-
    find_complement_to_ten_witness(Given, Complement, _).

%!  find_complement_to_ten_witness(+Given, -Complement, -Witness) is semidet.
%
%   Witness-bearing complement-to-ten proof. The witness records the nonzero
%   and less-than-ten constraints plus the grounded subtraction from ten.

find_complement_to_ten_witness(Given, Complement, Witness) :-
    incur_cost(inference),
    integer_to_recollection(10, Ten),
    zero(Zero),
    \+ equal_to(Given, Zero),
    smaller_than(Given, Ten),
    subtract_grounded(Ten, Given, Complement),
    complement_witness(Given, Complement, Ten, Witness).

pairs_and_witnesses([], [], []).
pairs_and_witnesses([Pair-Witness|Rest], [Pair|Pairs], [Witness|Witnesses]) :-
    pairs_and_witnesses(Rest, Pairs, Witnesses).

add_objects_witness_(GroupA,
                     GroupB,
                     Combined,
                     Total,
                     CountWitness,
                     _{ kind: standard_k_ca_1_3_add_objects,
                        scope: closed_world_finite_standard_k_ca_1_3_operations_within_10,
                        standard: in_k_ca_1,
                        source_predicate: add_objects/3,
                        group_a: GroupA,
                        group_b: GroupB,
                        combined: Combined,
                        group_a_count: GroupACount,
                        group_b_count: GroupBCount,
                        combined_length: CombinedLength,
                        total: Total,
                        total_count: TotalCount,
                        derivation: combine_supplied_object_lists_then_count,
                        boundary: supplied_finite_object_lists_within_kindergarten_operation_range,
                        bound_status: BoundStatus,
                        count_witness: CountWitness }) :-
    length(GroupA, GroupACount),
    length(GroupB, GroupBCount),
    length(Combined, CombinedLength),
    recollection_to_integer(Total, TotalCount),
    operation_bound_status(TotalCount, BoundStatus).

subtract_objects_witness_(Group,
                          Remove,
                          Remaining,
                          GroupCount,
                          CountWitness,
                          _{ kind: standard_k_ca_1_3_subtract_objects,
                             scope: closed_world_finite_standard_k_ca_1_3_operations_within_10,
                             standard: in_k_ca_1,
                             source_predicate: subtract_objects/3,
                             group: Group,
                             group_count: GroupCountValue,
                             remove: Remove,
                             remove_count: RemoveCount,
                             remaining: Remaining,
                             remaining_count: RemainingCount,
                             relation: subtract_grounded(GroupCount, Remove, Remaining),
                             derivation: count_group_then_subtract_removed_quantity,
                             boundary: supplied_finite_object_list_and_grounded_remove_count,
                             bound_status: BoundStatus,
                             count_witness: CountWitness }) :-
    recollection_to_integer(GroupCount, GroupCountValue),
    recollection_to_integer(Remove, RemoveCount),
    recollection_to_integer(Remaining, RemainingCount),
    operation_bound_status(GroupCountValue, BoundStatus).

pair_witness(Number,
             RecA,
             RecB,
             _{ kind: standard_k_ca_1_3_decomposition_pair,
                scope: closed_world_finite_standard_k_ca_1_3_operations_within_10,
                number: Number,
                number_count: NumberCount,
                a: RecA,
                a_count: ACount,
                b: RecB,
                b_count: BCount,
                relation: add_grounded(RecA, RecB, Number),
                ordering_constraint: ACount =< BCount,
                derivation: finite_pair_enumeration_with_grounded_addition }) :-
    recollection_to_integer(Number, NumberCount),
    recollection_to_integer(RecA, ACount),
    recollection_to_integer(RecB, BCount).

decompose_pairs_witness_(Number,
                         Pairs,
                         PairWitnesses,
                         _{ kind: standard_k_ca_1_3_decompose_pairs,
                            scope: closed_world_finite_standard_k_ca_1_3_operations_within_10,
                            standard: in_k_ca_2,
                            source_predicate: decompose_pairs/2,
                            number: Number,
                            number_count: NumberCount,
                            pairs: Pairs,
                            pair_count: PairCount,
                            pair_witnesses: PairWitnesses,
                            derivation: enumerate_unordered_pairs_with_grounded_sum,
                            boundary: finite_pair_enumeration_for_kindergarten_numbers_through_ten,
                            bound_status: BoundStatus }) :-
    recollection_to_integer(Number, NumberCount),
    length(Pairs, PairCount),
    operation_bound_status(NumberCount, BoundStatus).

complement_witness(Given,
                   Complement,
                   Ten,
                   _{ kind: standard_k_ca_1_3_complement_to_ten,
                      scope: closed_world_finite_standard_k_ca_1_3_operations_within_10,
                      standard: in_k_ca_3,
                      source_predicate: find_complement_to_ten/2,
                      given: Given,
                      given_count: GivenCount,
                      complement: Complement,
                      complement_count: ComplementCount,
                      ten: Ten,
                      ten_count: 10,
                      constraints: [not_equal_to_zero(Given),
                                    smaller_than(Given, Ten)],
                      relation: subtract_grounded(Ten, Given, Complement),
                      derivation: subtract_given_from_ten,
                      boundary: supplied_grounded_recollection_one_through_nine,
                      bound_status: within_indiana_k_ca_3_bound }) :-
    recollection_to_integer(Given, GivenCount),
    recollection_to_integer(Complement, ComplementCount).

operation_bound_status(Count, within_indiana_k_ca_1_3_bound) :-
    Count >= 0,
    Count =< 10,
    !.
operation_bound_status(Count, outside_indiana_k_ca_1_3_bound(Count)).
