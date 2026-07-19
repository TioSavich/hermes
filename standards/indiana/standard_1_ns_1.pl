/** <module> Standard 1.NS.1 — Count to 120 by ones, fives, tens
 *
 * Indiana: 1.NS.1 — "Count to at least 120 by ones, fives, and tens
 *          from any given number. In this range, read and write numerals
 *          and represent a number of objects with a written numeral." (E)
 * CCSS:    1.NBT.A.1 — "Count to 120, starting at any number less than
 *                       120. In this range, read and write numerals and
 *                       represent a number of objects with a written
 *                       numeral."
 *
 * VPV MAPPING:
 *   V  (target vocabulary): number words to 120; decade words to 120;
 *      "skip count by fives"
 *   P  (practices): forward counting by 1s/5s/10s from any start;
 *      backward counting by 1s and 10s; reading and writing numerals
 *      beyond 20
 *   V' (metavocabulary): "count by fives", "count backward", "start
 *      at ___ and count to ___", "what comes before/after"
 *
 * LEARNING COMPONENTS (from LearningCommons KG v1.7.0):
 *   - Count up from zero by 1s to 120
 *   - Count up from zero by 10s to 120
 *   - Count up by 1s from non-zero to 120
 *   - Count up by 10s from non-zero to 120
 *   - Count down by 1s within 120
 *   - Count down by 10s within 120
 *   - Read/write numerals to 120
 *   - Represent objects up to 120 with numeral
 *
 * BUILDS UPON: K.NS.1 (counting to 100), K.NS.2 (naming to 20)
 * BUILDS TOWARD: 1.NBT.B.2 (two-digit place value)
 *
 * BRANDOM CONNECTION: Extending the counting range from 100 to 120
 *   crosses the century boundary — the first time the learner
 *   experiences the place-value system recycling (100→101 mirrors
 *   0→1). Counting by fives introduces a new skip-counting practice
 *   that deploys the "five" vocabulary differently from subitizing
 *   (K.NS.4). Backward counting is genuinely new: predecessor
 *   iteration is a distinct practice from successor iteration, and
 *   the discovery that they are inverses is non-trivial.
 *
 * BOUNDARIES:
 *   - This is the closed-world finite counting-to-120 case. Counting traces
 *     are generated over supplied finite recollections and the loaded
 *     grounded successor, predecessor, addition, and subtraction relations.
 *   - The numeral extension from 21 through 120 uses the finite naming rows
 *     generated in this module. It records the row used; it does not model the
 *     full morphology of spoken English number words.
 *   - Backward counting by fives is outside the Indiana 1.NS.1 surface modeled
 *     here. The implemented backward practices are by ones and by tens.
 */

:- module(standard_1_ns_1, [
    count_by_fives/3,          % +From, +To, -Trace
    count_by_fives_witness/4,  % +From, +To, -Trace, -Witness
    count_backward_by_ones/3,  % +From, +To, -Trace
    count_backward_by_ones_witness/4, % +From, +To, -Trace, -Witness
    count_backward_by_tens/3,  % +From, +To, -Trace
    count_backward_by_tens_witness/4, % +From, +To, -Trace, -Witness
    teach_numerals_to_120/0,
    teach_numerals_to_120_witness/1
]).

:- use_module(formalization(grounded_arithmetic), [
    predecessor/2,
    equal_to/2,
    smaller_than/2,
    greater_than/2,
    add_grounded/3,
    subtract_grounded/3,
    integer_to_recollection/2,
    recollection_to_integer/2,
    incur_cost/1
]).

:- use_module(standard_k_ns_2, [
    learn_numeral_witness/3
]).

:- dynamic stored_trace_1/4.
%% stored_trace_1(+From, +To, +Direction, +Trace)

% ============================================================
% Count by fives (new for Grade 1)
% ============================================================

%!  count_by_fives(+From, +To, -Trace) is semidet.
%
%   Skip-count from From to To by fives. Each step adds five
%   using grounded addition. Fails if To is not reachable
%   from From by exact steps of five.

count_by_fives(From, To, Trace) :-
    count_by_fives_witness(From, To, Trace, _).

%!  count_by_fives_witness(+From, +To, -Trace, -Witness) is semidet.
%
%   Skip-count by fives over finite recollections until `To` is reached exactly.
%   The witness records every grounded addition step and the trace row asserted
%   for later inspection.
count_by_fives_witness(From, To, Trace, Witness) :-
    incur_cost(inference),
    integer_to_recollection(5, Five),
    count_fives_witness_(From,
                         To,
                         Five,
                         [state(From, start)],
                         [],
                         RevTrace,
                         RevSteps),
    reverse(RevTrace, Trace),
    reverse(RevSteps, StepWitnesses),
    stored_trace_1_witness(From, To, forward_by_fives, Trace, StoredWitness),
    counting_trace_witness(standard_1_ns_1_count_by_fives,
                           count_by_fives/3,
                           forward_by_fives,
                           add_grounded_by_five,
                           5,
                           From,
                           To,
                           Trace,
                           exact_step_reachable,
                           StepWitnesses,
                           StoredWitness,
                           Witness).

count_fives_witness_(Current, Target, _Five, Acc, Steps, Acc, Steps) :-
    equal_to(Current, Target), !.
count_fives_witness_(Current, Target, Five, Acc, Steps0, Trace, Steps) :-
    smaller_than(Current, Target),
    add_grounded(Current, Five, Next),
    step_witness(five_step,
                 add_grounded(Current, Five, Next),
                 Current,
                 Next,
                 StepWitness),
    count_fives_witness_(Next,
                         Target,
                         Five,
                         [state(Next, five_step)|Acc],
                         [StepWitness|Steps0],
                         Trace,
                         Steps).


% ============================================================
% Count backward by ones (new practice)
% ============================================================

%!  count_backward_by_ones(+From, +To, -Trace) is semidet.
%
%   Count backward from From to To by predecessor iteration.
%   From must be greater than or equal to To.
%   This is a genuinely distinct practice from forward counting.

count_backward_by_ones(From, To, Trace) :-
    count_backward_by_ones_witness(From, To, Trace, _).

%!  count_backward_by_ones_witness(+From, +To, -Trace, -Witness) is semidet.
%
%   Count backward by predecessor iteration until `To` is reached exactly.
count_backward_by_ones_witness(From, To, Trace, Witness) :-
    incur_cost(inference),
    count_back_ones_witness_(From, To, [state(From, start)], [], RevTrace, RevSteps),
    reverse(RevTrace, Trace),
    reverse(RevSteps, StepWitnesses),
    stored_trace_1_witness(From, To, backward_by_ones, Trace, StoredWitness),
    counting_trace_witness(standard_1_ns_1_count_backward_by_ones,
                           count_backward_by_ones/3,
                           backward_by_ones,
                           predecessor,
                           1,
                           From,
                           To,
                           Trace,
                           exact_step_reachable,
                           StepWitnesses,
                           StoredWitness,
                           Witness).

count_back_ones_witness_(Current, Target, Acc, Steps, Acc, Steps) :-
    equal_to(Current, Target), !.
count_back_ones_witness_(Current, Target, Acc, Steps0, Trace, Steps) :-
    greater_than(Current, Target),
    predecessor(Current, Prev),
    step_witness(predecessor,
                 predecessor(Current, Prev),
                 Current,
                 Prev,
                 StepWitness),
    count_back_ones_witness_(Prev,
                             Target,
                             [state(Prev, predecessor)|Acc],
                             [StepWitness|Steps0],
                             Trace,
                             Steps).


% ============================================================
% Count backward by tens
% ============================================================

%!  count_backward_by_tens(+From, +To, -Trace) is semidet.
%
%   Count backward from From to To by subtracting ten at each
%   step. Fails if To is not reachable by exact decade steps.

count_backward_by_tens(From, To, Trace) :-
    count_backward_by_tens_witness(From, To, Trace, _).

%!  count_backward_by_tens_witness(+From, +To, -Trace, -Witness) is semidet.
%
%   Count backward by subtracting ten at each step until `To` is reached
%   exactly.
count_backward_by_tens_witness(From, To, Trace, Witness) :-
    incur_cost(inference),
    integer_to_recollection(10, Ten),
    count_back_tens_witness_(From,
                             To,
                             Ten,
                             [state(From, start)],
                             [],
                             RevTrace,
                             RevSteps),
    reverse(RevTrace, Trace),
    reverse(RevSteps, StepWitnesses),
    stored_trace_1_witness(From, To, backward_by_tens, Trace, StoredWitness),
    counting_trace_witness(standard_1_ns_1_count_backward_by_tens,
                           count_backward_by_tens/3,
                           backward_by_tens,
                           subtract_grounded_by_ten,
                           10,
                           From,
                           To,
                           Trace,
                           exact_step_reachable,
                           StepWitnesses,
                           StoredWitness,
                           Witness).

count_back_tens_witness_(Current, Target, _Ten, Acc, Steps, Acc, Steps) :-
    equal_to(Current, Target), !.
count_back_tens_witness_(Current, Target, Ten, Acc, Steps0, Trace, Steps) :-
    greater_than(Current, Target),
    subtract_grounded(Current, Ten, Prev),
    step_witness(decade_back,
                 subtract_grounded(Current, Ten, Prev),
                 Current,
                 Prev,
                 StepWitness),
    count_back_tens_witness_(Prev,
                             Target,
                             Ten,
                             [state(Prev, decade_back)|Acc],
                             [StepWitness|Steps0],
                             Trace,
                             Steps).


% ============================================================
% Extended numeral teaching (21-120)
% ============================================================

%!  teach_numerals_to_120 is det.
%
%   Extend the numeral naming table from 21 to 120.
%   Uses a systematic naming rule for compositionality
%   (twenty-one, twenty-two, ..., one hundred twenty).

teach_numerals_to_120 :-
    teach_numerals_to_120_witness(_).

%!  teach_numerals_to_120_witness(-Witness) is det.
%
%   Extend the finite dynamic K.NS.2 naming table with generated rows from 21
%   through 120 and return the evidence for every row asserted or already known.
teach_numerals_to_120_witness(Witness) :-
    witness_dict:witness_dict(standard_1_ns_1_teach_numerals_to_120, closed_world_finite_integer_name_rows_21_to_120,
                              _{standard: in_1_ns_1,
                 source_predicate: teach_numerals_to_120/0,
                 first_taught: 21-'twenty-one',
                 last_taught: 120-'one hundred twenty',
                 taught_count: TaughtCount,
                 rows: RowWitnesses,
                 derivation: generate_finite_integer_name_rows_then_teacher_endorsement,
                 boundary: finite_rows_21_through_120_generated_by_this_module }, WitnessDict282),
    findall(RowWitness,
            teach_extended_numeral_row_witness(RowWitness),
            RowWitnesses),
    length(RowWitnesses, TaughtCount),
    Witness = WitnessDict282.

teach_extended_numeral_row_witness(Witness) :-
    witness_dict:witness_dict(standard_1_ns_1_extended_numeral_row, closed_world_finite_integer_name_rows_21_to_120,
                              _{integer: N,
                 recollection: Rec,
                 word: Word,
                 word_witness: WordWitness,
                 learn_witness: LearnWitness,
                 derivation: generated_number_word_then_k_ns_2_teacher_endorsement }, WitnessDict298),
    between(21, 120, N),
    integer_to_recollection(N, Rec),
    make_number_word_witness(N, Word, WordWitness),
    learn_numeral_witness(Rec, Word, LearnWitness),
    Witness = WitnessDict298.

%% Systematic English number word generation
make_number_word_witness(N,
                         Word,
                         WitnessDict310) :-
    witness_dict:witness_dict(standard_1_ns_1_number_word, closed_world_finite_integer_name_rows_21_to_120,
                              _{integer: N,
                            word: Word,
                            naming_case: one_hundred,
                            derivation: exact_hundred_name }, WitnessDict310),
    N =:= 100,
    !,
    Word = 'one hundred'.
make_number_word_witness(N,
                         Word,
                         WitnessDict321) :-
    witness_dict:witness_dict(standard_1_ns_1_number_word, closed_world_finite_integer_name_rows_21_to_120,
                              _{integer: N,
                            word: Word,
                            naming_case: one_hundred_plus_ones,
                            remainder: Ones,
                            remainder_word: OnesWord,
                            derivation: one_hundred_prefix_plus_under_twenty_row }, WitnessDict321),
    N >= 100, !,
    Ones is N - 100,
    make_number_word_witness(Ones, OnesWord, _),
    atomic_list_concat(['one hundred', OnesWord], ' ', Word).
make_number_word_witness(N,
                         Word,
                         WitnessDict335) :-
    witness_dict:witness_dict(standard_1_ns_1_number_word, closed_world_finite_integer_name_rows_21_to_120,
                              _{integer: N,
                            word: Word,
                            naming_case: decade_plus_ones,
                            tens_digit: Tens,
                            ones_digit: Ones,
                            decade_word: DecWord,
                            ones_word: OnesWord,
                            derivation: decade_row_plus_hyphenated_ones_row }, WitnessDict335),
    N >= 20,
    Tens is N // 10,
    Ones is N mod 10,
    Ones =\= 0,
    !,
    decade_word(Tens, DecWord),
    ones_word(Ones, OnesWord),
    atomic_list_concat([DecWord, '-', OnesWord], Word).
make_number_word_witness(N,
                         Word,
                         WitnessDict355) :-
    witness_dict:witness_dict(standard_1_ns_1_number_word, closed_world_finite_integer_name_rows_21_to_120,
                              _{integer: N,
                            word: Word,
                            naming_case: exact_decade,
                            tens_digit: Tens,
                            derivation: decade_word_row }, WitnessDict355),
    N >= 20,
    Tens is N // 10,
    Ones is N mod 10,
    Ones =:= 0,
    !,
    decade_word(Tens, Word).
make_number_word_witness(N,
                         Word,
                         WitnessDict370) :-
    witness_dict:witness_dict(standard_1_ns_1_number_word, closed_world_finite_integer_name_rows_21_to_120,
                              _{integer: N,
                            word: Word,
                            naming_case: under_twenty_row,
                            derivation: finite_ones_word_row }, WitnessDict370),
    ones_word(N, Word).

counting_trace_witness(Kind,
                       SourcePredicate,
                       Direction,
                       StepRelation,
                       StepSizeValue,
                       From,
                       To,
                       Trace,
                       ReachabilityStatus,
                       StepWitnesses,
                       StoredWitness,
                       Witness) :-
    witness_dict:witness_dict(Kind, closed_world_finite_counting_to_120,
                              _{standard: in_1_ns_1,
                 source_predicate: SourcePredicate,
                 from: From,
                 to: To,
                 from_value: FromValue,
                 to_value: ToValue,
                 direction: Direction,
                 step_relation: StepRelation,
                 step_size_value: StepSizeValue,
                 trace: Trace,
                 trace_length: TraceLength,
                 step_count: StepCount,
                 reachability_status: ReachabilityStatus,
                 derivation: finite_iterated_grounded_counting_trace,
                 boundary: supplied_recollections_and_loaded_grounded_arithmetic_relations,
                 steps: StepWitnesses,
                 stored_trace_witness: StoredWitness }, WitnessDict394),
    recollection_to_integer(From, FromValue),
    recollection_to_integer(To, ToValue),
    length(Trace, TraceLength),
    length(StepWitnesses, StepCount),
    Witness = WitnessDict394.

step_witness(StepKind, Relation, Current, Next,
             _{ kind: standard_1_ns_1_counting_step,
                step_kind: StepKind,
                relation: Relation,
                from: Current,
                to: Next,
                from_value: CurrentValue,
                to_value: NextValue,
                derivation: one_grounded_counting_transition }) :-
    recollection_to_integer(Current, CurrentValue),
    recollection_to_integer(Next, NextValue).

stored_trace_1_witness(From, To, Direction, Trace,
                       WitnessDict427) :-
    witness_dict:witness_dict(standard_1_ns_1_stored_trace, closed_world_finite_counting_to_120,
                              _{source_predicate: stored_trace_1/4,
                          from: From,
                          to: To,
                          direction: Direction,
                          trace_length: TraceLength,
                          derivation: asserted_trace_row_for_later_inspection,
                          boundary: dynamic_trace_rows_in_standard_1_ns_1 }, WitnessDict427),
    assertz(stored_trace_1(From, To, Direction, Trace)),
    length(Trace, TraceLength).

decade_word(2, twenty).
decade_word(3, thirty).
decade_word(4, forty).
decade_word(5, fifty).
decade_word(6, sixty).
decade_word(7, seventy).
decade_word(8, eighty).
decade_word(9, ninety).

ones_word(1, one).
ones_word(2, two).
ones_word(3, three).
ones_word(4, four).
ones_word(5, five).
ones_word(6, six).
ones_word(7, seven).
ones_word(8, eight).
ones_word(9, nine).
ones_word(10, ten).
ones_word(11, eleven).
ones_word(12, twelve).
ones_word(13, thirteen).
ones_word(14, fourteen).
ones_word(15, fifteen).
ones_word(16, sixteen).
ones_word(17, seventeen).
ones_word(18, eighteen).
ones_word(19, nineteen).
