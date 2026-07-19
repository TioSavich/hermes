/** <module> Standard K.NS.4 — Subitizing (identify quantity without counting)
 *
 * Indiana: K.NS.4 — "Identify sets of 1 to 10 objects in patterned
 *          arrangements and tell how many without counting." (E)
 * CCSS:    No direct equivalent. Implicit in K.OA and K.CC work.
 *          Indiana includes this explicitly.
 *
 * VPV MAPPING:
 *   V  (target vocabulary): immediate quantity judgments ("that's five"),
 *      pattern names (dice pattern, ten-frame, domino)
 *   P  (practices): perceptual subitizing (instant recognition of 1-4);
 *      conceptual subitizing (decompose 5-10 into recognized sub-groups
 *      and combine); pattern matching (dice, ten-frame, finger patterns)
 *   V' (metavocabulary): "how many without counting?", "what do you see?",
 *      "I see a group of ___ and a group of ___"
 *
 * BRANDOM CONNECTION: Subitizing is non-inferential recognition — the
 *   learner grasps "five" directly from the pattern without performing
 *   the counting inference. This is Brandom's distinction between
 *   inferential and non-inferential (observational) reports. The
 *   interesting question: is a subitized "five" the SAME "five" as a
 *   counted "five"? The cardinality principle (K.NS.3) says yes, but
 *   the routes to the judgment are different. The system must discover
 *   that subitized quantities match counted quantities — this is a
 *   co-referentiality discovery (design/04).
 *
 * COST SIGNIFICANCE: Subitizing is O(1) per recognized pattern.
 *   Counting the same quantity is O(n). This cost gap makes subitizing
 *   the first "efficiency strategy" — not a crisis-driven synthesis
 *   but a perceptual shortcut. The connection to crisis-driven learning:
 *   subitizing provides the building blocks (recognized sub-groups)
 *   that conceptual subitizing and later addition strategies combine.
 *
 * BOUNDARIES:
 *   - Spatial arrangement (line, array, circle, scattered) is modeled
 *     as finite pattern terms, not actual spatial layouts. This module proves
 *     recognition against the loaded closed-world pattern table.
 *   - Perceptual subitizing range (1-4) is hardcoded. Developmentally,
 *     some children subitize up to 5 or 6 perceptually; the module
 *     follows the research consensus of 1-4.
 *   - The "without counting" aspect is modeled as pattern-matching
 *     (no successor iteration), but the module cannot enforce that
 *     the learner truly recognizes the pattern perceptually vs.
 *     rapidly counting mentally.
 */

:- module(standard_k_ns_4, [
    subitize/2,            % +Pattern, -Count
    subitize_witness/3,    % +Pattern, -Count, -Witness
    conceptual_subitize/3, % +Pattern, -Count, -Decomposition
    conceptual_subitize_witness/4, % +Pattern, -Count, -Decomposition, -Witness
    verify_subitizing/2,   % +Pattern, -Match
    verify_subitizing_witness/3, % +Pattern, -Match, -Witness
    known_pattern/2,       % ?PatternType, ?Quantity
    known_pattern_witness/3 % ?PatternType, ?Quantity, -Witness
]).

:- use_module(formalization(grounded_arithmetic), [
    equal_to/2,
    add_grounded/3,
    integer_to_recollection/2,
    recollection_to_integer/2,
    incur_cost/1
]).

:- use_module(standard_k_ns_3, [
    count_collection_witness/4
]).

% ============================================================
% Known patterns (the teacher's visual repertoire)
% ============================================================

%% known_pattern(+PatternType, +Quantity)
%% Patterns the system has been taught to recognize.
%% Quantity is an integer (will be converted to recollection).

% Dice patterns (1-6)
known_pattern(dice(1), 1).
known_pattern(dice(2), 2).
known_pattern(dice(3), 3).
known_pattern(dice(4), 4).
known_pattern(dice(5), 5).
known_pattern(dice(6), 6).

% Finger patterns (1-10)
known_pattern(fingers(1), 1).
known_pattern(fingers(2), 2).
known_pattern(fingers(3), 3).
known_pattern(fingers(4), 4).
known_pattern(fingers(5), 5).
known_pattern(fingers(6), 6).
known_pattern(fingers(7), 7).
known_pattern(fingers(8), 8).
known_pattern(fingers(9), 9).
known_pattern(fingers(10), 10).

% Ten-frame patterns (1-10)
known_pattern(ten_frame(1), 1).
known_pattern(ten_frame(2), 2).
known_pattern(ten_frame(3), 3).
known_pattern(ten_frame(4), 4).
known_pattern(ten_frame(5), 5).
known_pattern(ten_frame(6), 6).
known_pattern(ten_frame(7), 7).
known_pattern(ten_frame(8), 8).
known_pattern(ten_frame(9), 9).
known_pattern(ten_frame(10), 10).

% Domino patterns (common pairs)
known_pattern(domino(1, 1), 2).
known_pattern(domino(2, 1), 3).
known_pattern(domino(2, 2), 4).
known_pattern(domino(3, 2), 5).
known_pattern(domino(3, 3), 6).
known_pattern(domino(4, 3), 7).
known_pattern(domino(4, 4), 8).
known_pattern(domino(5, 4), 9).
known_pattern(domino(5, 5), 10).

%!  known_pattern_witness(?Pattern, ?Quantity, -Witness) is nondet.
%
%   Inspect the finite pattern-recognition table used by K.NS.4.
known_pattern_witness(Pattern, Quantity,
                      WitnessDict125) :-
    witness_dict:witness_dict(standard_k_ns_4_known_pattern, closed_world_finite_standard_k_ns_4_pattern_table,
                              _{standard: in_k_ns_4,
                         source_predicate: known_pattern/2,
                         pattern: Pattern,
                         pattern_family: Family,
                         quantity: Quantity,
                         derivation: loaded_pattern_table_row,
                         boundary: pattern_rows_loaded_in_standard_k_ns_4 }, WitnessDict125),
    known_pattern(Pattern, Quantity),
    pattern_family(Pattern, Family).

pattern_family(dice(_), dice).
pattern_family(fingers(_), fingers).
pattern_family(ten_frame(_), ten_frame).
pattern_family(domino(_, _), domino).

% ============================================================
% Perceptual subitizing (direct recognition, O(1))
% ============================================================

%!  subitize(+Pattern, -Count) is semidet.
%
%   Recognize a known pattern and return the count as a
%   recollection. No counting occurs — this is direct
%   recognition. Cost is O(1): one inference, no successor
%   iteration.
%
%   Fails if the pattern is not recognized.

subitize(Pattern, Count) :-
    subitize_witness(Pattern, Count, _).

%!  subitize_witness(+Pattern, -Count, -Witness) is semidet.
%
%   Direct pattern recognition over the finite K.NS.4 table. This witness
%   records the pattern row used and the route by which the count was produced.
subitize_witness(Pattern, Count,
                 WitnessDict163) :-
    witness_dict:witness_dict(standard_k_ns_4_subitize, closed_world_finite_standard_k_ns_4_pattern_table,
                              _{standard: in_k_ns_4,
                    source_predicate: subitize/2,
                    pattern: Pattern,
                    quantity: N,
                    count: Count,
                    route: perceptual_pattern_recognition,
                    derivation: known_pattern_quantity_to_recollection,
                    boundary: pattern_rows_loaded_in_standard_k_ns_4,
                    pattern_witness: PatternWitness }, WitnessDict163),
    known_pattern_witness(Pattern, N, PatternWitness),
    incur_cost(inference),
    integer_to_recollection(N, Count).

% ============================================================
% Conceptual subitizing (decompose and combine)
% ============================================================

%!  conceptual_subitize(+Pattern, -Count, -Decomposition) is semidet.
%
%   For patterns 5-10, decompose into recognized sub-groups
%   and combine. Returns the total count and the decomposition.
%
%   Example: conceptual_subitize(domino(3,2), Count, Decomp)
%   → Count = 5, Decomp = decomposed(3, 2, 5)
%
%   Cost: O(1) for each sub-recognition + O(n) for the
%   grounded addition. Still cheaper than counting from scratch.

conceptual_subitize(Pattern, Count, Decomposition) :-
    conceptual_subitize_witness(Pattern, Count, Decomposition, _).

%!  conceptual_subitize_witness(+Pattern, -Count, -Decomposition, -Witness) is semidet.
%
%   Conceptual subitizing with inspectable decomposition evidence. The finite
%   cases here are domino part-plus-part rows and ten-frame five-plus-extra rows.
conceptual_subitize_witness(domino(A, B), Count, decomposed(A, B, Total),
                            Witness) :-
    known_pattern_witness(domino(A, B), Total, PatternWitness),
    incur_cost(inference),
    integer_to_recollection(A, RecA),
    integer_to_recollection(B, RecB),
    add_grounded(RecA, RecB, Count),
    conceptual_subitizing_witness(domino(A, B),
                                  decomposed(A, B, Total),
                                  Count,
                                  conceptual_decomposition_and_grounded_addition,
                                  [part(A, RecA), part(B, RecB)],
                                  PatternWitness,
                                  Witness).

conceptual_subitize_witness(ten_frame(N), Count, decomposed(FiveOrLess, Extra, N),
                            Witness) :-
    N > 5,
    known_pattern_witness(ten_frame(N), N, PatternWitness),
    incur_cost(inference),
    FiveOrLess = 5,
    Extra is N - 5,
    integer_to_recollection(FiveOrLess, RecFive),
    integer_to_recollection(Extra, RecExtra),
    add_grounded(RecFive, RecExtra, Count),
    conceptual_subitizing_witness(ten_frame(N),
                                  decomposed(FiveOrLess, Extra, N),
                                  Count,
                                  conceptual_five_frame_plus_extra,
                                  [part(FiveOrLess, RecFive), part(Extra, RecExtra)],
                                  PatternWitness,
                                  Witness).

conceptual_subitizing_witness(Pattern,
                              Decomposition,
                              Count,
                              Route,
                              PartWitnesses,
                              PatternWitness,
                              WitnessDict239) :-
    witness_dict:witness_dict(standard_k_ns_4_conceptual_subitize, closed_world_finite_standard_k_ns_4_pattern_table,
                              _{standard: in_k_ns_4,
                                 source_predicate: conceptual_subitize/3,
                                 pattern: Pattern,
                                 decomposition: Decomposition,
                                 count: Count,
                                 route: Route,
                                 derivation: decompose_known_pattern_then_add_parts,
                                 boundary: domino_and_ten_frame_rows_loaded_in_standard_k_ns_4,
                                 pattern_witness: PatternWitness,
                                 part_witnesses: PartWitnesses }, WitnessDict239).

% ============================================================
% Verification: does subitizing agree with counting?
% ============================================================

%!  verify_subitizing(+Pattern, -Match) is semidet.
%
%   Subitize a pattern, then count the same quantity, and
%   check if they agree. This is the co-referentiality test:
%   subitized "five" = counted "five"?
%
%   Returns match(SubCount, CountCount) if they agree,
%   mismatch(SubCount, CountCount) if they don't (should
%   never happen, but documenting the check is the point).

verify_subitizing(Pattern, Result) :-
    verify_subitizing_witness(Pattern, Result, _).

%!  verify_subitizing_witness(+Pattern, -Match, -Witness) is semidet.
%
%   Verify that direct recognition and finite list counting name the same
%   quantity for a recognized pattern.
verify_subitizing_witness(Pattern, Result,
                          WitnessDict274) :-
    witness_dict:witness_dict(standard_k_ns_4_verify_subitizing, closed_world_finite_pattern_count_agreement,
                              _{standard: in_k_ns_4,
                             source_predicate: verify_subitizing/2,
                             pattern: Pattern,
                             objects: Objects,
                             subitized_count: SubCount,
                             counted_count: CountCount,
                             result: Result,
                             derivation: subitize_then_count_equivalent_finite_list,
                             boundary: recognized_pattern_and_generated_object_list,
                             subitize_witness: SubitizeWitness,
                             count_witness: CountWitness,
                             comparison_witness: ComparisonWitness }, WitnessDict274),
    subitize_witness(Pattern, SubCount, SubitizeWitness),
    % Create a collection of N objects and count it
    recollection_to_integer(SubCount, N),
    length(Objects, N),
    maplist(=(obj), Objects),
    count_collection_witness(Objects, CountCount, _Pairing, CountWitness),
    (   equal_to(SubCount, CountCount)
    ->  Result = match(SubCount, CountCount),
        ComparisonWitness = _{ kind: standard_k_ns_4_subitize_count_comparison,
                               relation: equal_to,
                               result: match,
                               subitized_count: SubCount,
                               counted_count: CountCount,
                               derivation: grounded_equal_to_confirms_same_quantity }
    ;   Result = mismatch(SubCount, CountCount),
        ComparisonWitness = _{ kind: standard_k_ns_4_subitize_count_comparison,
                               relation: not_equal_to,
                               result: mismatch,
                               subitized_count: SubCount,
                               counted_count: CountCount,
                               derivation: grounded_equal_to_failed_for_recognition_count_pair }
    ).
