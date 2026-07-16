/** <module> Standard K.NS.3 — One-to-one correspondence and cardinality
 *
 * Indiana: K.NS.3 — "Say the number names in standard order when counting
 *          objects, pairing each object with one and only one number name
 *          and each number name with one and only one object. Understand
 *          that the last number name said describes the number of objects
 *          counted and that the number of objects is the same regardless
 *          of their arrangement or the order in which they were counted.
 *          Count out the number of objects, given a number from 1 to 20."
 * CCSS:    K.CC.B.4 — "Understand the relationship between numbers and
 *                      quantities; connect counting to cardinality."
 *          K.CC.B.4.a — one-to-one correspondence
 *          K.CC.B.4.b — last number = count (cardinality principle)
 *          K.CC.B.4.c — each successive number is one larger
 *          K.CC.B.5 — "Count to answer 'how many?' questions..."
 *
 * VPV MAPPING:
 *   V  (target vocabulary): "how many", cardinal answers ("there are five"),
 *      "the same number", arrangement-independent quantity
 *   P  (practices): one-to-one correspondence (pairing each object with
 *      exactly one count); cardinality principle (last count = total);
 *      counting out (given a number, produce that many objects);
 *      order-independence (re-counting produces same result)
 *   V' (metavocabulary): "the last number you said tells how many",
 *      "one for each", "count out five for me", "does it matter
 *      what order you count them?"
 *
 * LEARNING COMPONENTS (from LearningCommons KG v1.7.0):
 *   K.CC.B.4:
 *   - Connect counting to cardinality
 *   - Connect numbers to quantities or amounts
 *   K.CC.B.5:
 *   - Count "how many?" for 20 things in a line/array/circle
 *   - Count "how many?" for 10 things scattered
 *   - Given a number 1-20, count out that many objects
 *
 * BRANDOM CONNECTION: The cardinality principle is a paradigmatic
 *   material inference — from "I said 'five' last while counting"
 *   to "there are five objects." This inference is not formally
 *   valid (it depends on one-to-one correspondence holding), but
 *   it is materially good: anyone who has mastered counting is
 *   entitled to make it. The order-independence claim is that
 *   this inference is invariant under permutation of the
 *   counting sequence — a symmetry property the learner must
 *   discover.
 *
 * BOUNDARIES:
 *   - "Arrangement" (line, array, circle, scattered) is not modeled.
 *     This is the closed-world finite list case: each supplied list element is
 *     treated as one countable object, and one-to-one correspondence is proved
 *     by the pairing trace over that list.
 *   - Order-independence is verified by re-counting a permuted list,
 *     but the philosophical point — that the learner discovers this
 *     invariance through experience — is outside this read-only checker. The
 *     module proves the finite equality case for the supplied list and its
 *     reverse.
 */

:- module(standard_k_ns_3, [
    count_collection/3,    % +Objects, -Count, -Pairing
    count_collection_witness/4, % +Objects, -Count, -Pairing, -Witness
    how_many/2,            % +Objects, -Name
    how_many_witness/3,    % +Objects, -Name, -Witness
    count_out/2,           % +Name, -Objects
    count_out_witness/3,   % +Name, -Objects, -Witness
    cardinality/2,         % +Trace, -Count
    cardinality_witness/3, % +Trace, -Count, -Witness
    verify_order_independence/2, % +Objects, -Result
    verify_order_independence_witness/3 % +Objects, -Result, -Witness
]).

:- use_module(formalization(grounded_arithmetic), [
    successor/2,
    zero/1,
    equal_to/2,
    recollection_to_integer/2,
    incur_cost/1
]).

:- use_module(standard_k_ns_2, [
    write_numeral_witness/3,
    read_numeral_witness/3
]).

% ============================================================
% One-to-one correspondence: pair each object with a count
% ============================================================

%!  count_collection(+Objects, -Count, -Pairing) is det.
%
%   Count a list of objects by pairing each with a successive
%   number. Returns the final count (recollection) and the
%   pairing as a list of pair(Object, Recollection) terms.
%
%   This models one-to-one correspondence: each object gets
%   exactly one number, each number gets exactly one object.

count_collection(Objects, Count, Pairing) :-
    count_collection_witness(Objects, Count, Pairing, _).

%!  count_collection_witness(+Objects, -Count, -Pairing, -Witness) is det.
%
%   Witness-bearing version of count_collection/3. This is the closed-world
%   finite list case for K.NS.3: each supplied list element is paired with the
%   next successor count, and the final successor state is the collection's
%   cardinality.
count_collection_witness(Objects, Count, Pairing, Witness) :-
    incur_cost(inference),
    zero(Start),
    pair_objects_witness(Objects, Start, Count, Pairing, PairWitnesses),
    length(Objects, ObjectCount),
    length(Pairing, PairCount),
    Witness = _{ kind: standard_k_ns_3_count_collection,
                 scope: closed_world_finite_supplied_object_list,
                 standard: in_k_ns_3,
                 source_predicate: count_collection/3,
                 objects: Objects,
                 object_count: ObjectCount,
                 start_count: Start,
                 final_count: Count,
                 pairing: Pairing,
                 pair_count: PairCount,
                 derivation: successor_pairing_over_supplied_list,
                 boundary: supplied_list_elements_are_the_countable_objects,
                 pair_witnesses: PairWitnesses }.

pair_objects_witness(Objects, Start, Count, Pairing, PairWitnesses) :-
    pair_objects_witness_(Objects, 1, Start, Count, Pairing, PairWitnesses).

pair_objects_witness_([], _Index, Count, Count, [], []).
pair_objects_witness_([Obj|Rest],
                      Index,
                      Current,
                      FinalCount,
                      [pair(Obj, Next)|Pairs],
                      [PairWitness|PairWitnesses]) :-
    successor(Current, Next),
    PairWitness = _{ kind: standard_k_ns_3_one_to_one_pair,
                     object: Obj,
                     ordinal_index: Index,
                     previous_count: Current,
                     assigned_count: Next,
                     derivation: successor_assigns_next_number_to_next_object },
    NextIndex is Index + 1,
    pair_objects_witness_(Rest, NextIndex, Next, FinalCount, Pairs, PairWitnesses).


% ============================================================
% Cardinality principle: last count = "how many"
% ============================================================

%!  how_many(+Objects, -Name) is semidet.
%
%   The "how many?" question. Counts the objects and returns
%   the number word for the total. This IS the cardinality
%   principle in action: count, take the last number, name it.
%
%   Fails if the count exceeds the taught naming range (the
%   learner cannot answer "how many?" for numbers they cannot
%   name — a genuine developmental constraint).

how_many(Objects, Name) :-
    how_many_witness(Objects, Name, _).

%!  how_many_witness(+Objects, -Name, -Witness) is semidet.
%
%   Count a supplied finite object list, take the final count as cardinality,
%   and resolve that recollection through the current taught-name table.
how_many_witness(Objects, Name, Witness) :-
    incur_cost(inference),
    count_collection_witness(Objects, Count, Pairing, CountWitness),
    write_numeral_witness(Count, Name, NameWitness),
    Witness = _{ kind: standard_k_ns_3_how_many,
                 scope: closed_world_finite_supplied_object_list_and_taught_names,
                 standard: in_k_ns_3,
                 source_predicate: how_many/2,
                 objects: Objects,
                 count: Count,
                 name: Name,
                 pairing: Pairing,
                 derivation: cardinality_principle_then_taught_name_lookup,
                 boundary: supplied_list_and_current_standard_k_ns_2_name_table,
                 count_witness: CountWitness,
                 name_witness: NameWitness }.

%!  cardinality(+Trace, -Count) is det.
%
%   Extract the cardinality from a counting trace (as produced
%   by count_by_ones). The last state in the trace holds the
%   final count. This makes explicit what the cardinality
%   principle claims: the last number said IS the answer.

cardinality(Trace, Count) :-
    cardinality_witness(Trace, Count, _).

%!  cardinality_witness(+Trace, -Count, -Witness) is semidet.
%
%   The cardinality principle for a finite counting trace: the last state in
%   the supplied trace is the answer to "how many?".
cardinality_witness(Trace, Count,
                    _{ kind: standard_k_ns_3_cardinality,
                       scope: closed_world_finite_counting_trace,
                       standard: in_k_ns_3,
                       source_predicate: cardinality/2,
                       trace: Trace,
                       trace_length: TraceLength,
                       last_state: LastState,
                       count: Count,
                       derivation: last_count_state_is_cardinality,
                       boundary: supplied_trace_must_be_a_finite_counting_trace }) :-
    last(Trace, LastState),
    LastState = state(Count, _Transition),
    length(Trace, TraceLength).


% ============================================================
% Count out: given a number, produce objects
% ============================================================

%!  count_out(+Name, -Objects) is semidet.
%
%   Given a number word, produce a list of that many objects.
%   The inverse of how_many: "give me five" → [o,o,o,o,o].
%
%   Objects are represented as generic object atoms.
%   The standard says "count out the number of objects" which
%   is a production task, not just recognition.

count_out(Name, Objects) :-
    count_out_witness(Name, Objects, _).

%!  count_out_witness(+Name, -Objects, -Witness) is semidet.
%
%   Resolve a taught number name to a recollection and produce a finite list
%   with exactly that many generic object tokens.
count_out_witness(Name, Objects, Witness) :-
    incur_cost(inference),
    read_numeral_witness(Name, Count, ReadWitness),
    recollection_to_integer(Count, N),
    length(Objects, N),
    maplist(=(object), Objects),
    Witness = _{ kind: standard_k_ns_3_count_out,
                 scope: closed_world_finite_taught_name_to_object_list,
                 standard: in_k_ns_3,
                 source_predicate: count_out/2,
                 name: Name,
                 count: Count,
                 object_count: N,
                 objects: Objects,
                 derivation: taught_name_lookup_then_finite_list_construction,
                 boundary: current_standard_k_ns_2_name_table_and_generic_tokens,
                 read_witness: ReadWitness }.


% ============================================================
% Order independence
% ============================================================

%!  verify_order_independence(+Objects, -Result) is det.
%
%   Count the objects in original order and in reversed order.
%   If both counts are equal, Result = same(Count).
%   This is a verification, not a discovery — the learner
%   would need to be surprised by the result.

verify_order_independence(Objects, Result) :-
    verify_order_independence_witness(Objects, Result, _).

%!  verify_order_independence_witness(+Objects, -Result, -Witness) is det.
%
%   Count the supplied finite list and its reverse. The relation is witnessed by
%   both counting traces plus the grounded equality check between final counts.
verify_order_independence_witness(Objects, Result, Witness) :-
    incur_cost(inference),
    count_collection_witness(Objects, Count1, Pairing1, CountWitness1),
    reverse(Objects, Reversed),
    count_collection_witness(Reversed, Count2, Pairing2, CountWitness2),
    (   equal_to(Count1, Count2)
    ->  Result = same(Count1),
        ComparisonWitness = _{ kind: standard_k_ns_3_count_equality,
                               relation: equal_to,
                               left_count: Count1,
                               right_count: Count2,
                               result: same,
                               derivation: grounded_equal_to_confirms_same_cardinality }
    ;   Result = different(Count1, Count2),
        ComparisonWitness = _{ kind: standard_k_ns_3_count_equality,
                               relation: not_equal_to,
                               left_count: Count1,
                               right_count: Count2,
                               result: different,
                               derivation: grounded_equal_to_failed_for_recount }
    ),
    Witness = _{ kind: standard_k_ns_3_order_independence,
                 scope: closed_world_finite_list_and_reverse,
                 standard: in_k_ns_3,
                 source_predicate: verify_order_independence/2,
                 objects: Objects,
                 reversed_objects: Reversed,
                 original_count: Count1,
                 reversed_count: Count2,
                 result: Result,
                 original_pairing: Pairing1,
                 reversed_pairing: Pairing2,
                 derivation: recount_reverse_and_compare_final_cardinalities,
                 boundary: supplied_list_and_its_reverse_only,
                 original_count_witness: CountWitness1,
                 reversed_count_witness: CountWitness2,
                 comparison_witness: ComparisonWitness }.
