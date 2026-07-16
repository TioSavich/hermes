/** <module> Standard 1.NS.2 — Two-digit place value
 *
 * Indiana: 1.NS.2 — "Model place value concepts of two-digit numbers,
 *          multiples of 10, and equivalent forms of whole numbers using
 *          objects and drawings." (E)
 * CCSS:    1.NBT.B.2 — "Understand that the two digits of a two-digit
 *                       number represent amounts of tens and ones."
 *
 * VPV MAPPING:
 *   V  (target vocabulary): "tens place", "ones place", "__ tens and
 *      __ ones", multiples of ten (10, 20, ..., 90)
 *   P  (practices): decomposing any two-digit number into tens and ones;
 *      composing from tens and ones; recognizing multiples of ten as
 *      special cases (N tens and 0 ones); understanding 10 as ten ones
 *      (generalized from K.NS.7)
 *   V' (metavocabulary): "how many tens?", "how many ones?",
 *      "what number has ___ tens and ___ ones?"
 *
 * BUILDS UPON: K.NS.7 (teen place value, one ten-group only)
 * BUILDS TOWARD: 2.NBT (three-digit place value, hundreds)
 *
 * BRANDOM CONNECTION: Full two-digit place value is the first
 *   vocabulary that is genuinely STRONGER than counting. "47" as
 *   "four tens and seven ones" contains structural information
 *   that "forty-seven" (a mere name) does not. The practice of
 *   decomposition elaborates the counting vocabulary into the
 *   place-value vocabulary. This is the algorithmic elaboration
 *   that makes addition strategies possible: you can only add
 *   "by tens and ones" if you can see a number AS tens and ones.
 *
 * CONNECTION TO EXISTING CODE:
 *   grounded_utils.pl has decompose_base10/3 which does structural
 *   decomposition. This module wraps it with curriculum-appropriate
 *   interface and connects to the naming layer.
 *
 * BOUNDARIES:
 *   - This is the closed-world finite two-place base-ten case. A supplied
 *     finite recollection is decomposed by repeatedly subtracting one ten
 *     until fewer than ten ones remain.
 *   - The Indiana 1.NS.2 classroom surface is two-digit numbers and multiples
 *     of ten. Existing compatibility behavior for 0-9 is retained and marked
 *     as below the two-digit range; values above 99 are computable by the same
 *     finite checker but marked outside the 1.NS.2 bound.
 *   - Objects and drawings are represented only by supplied grounded
 *     recollections. The module proves the symbolic tens/ones relation; it
 *     does not model perceptual grouping or physical manipulation.
 */

:- module(standard_1_ns_2, [
    decompose_two_digit/3, % +Number, -Tens, -Ones
    decompose_two_digit_witness/4, % +Number, -Tens, -Ones, -Witness
    compose_two_digit/3,   % +Tens, +Ones, -Number
    compose_two_digit_witness/4, % +Tens, +Ones, -Number, -Witness
    is_multiple_of_ten/1,  % +Number
    is_multiple_of_ten_witness/3, % +Number, -Result, -Witness
    describe_two_digit/2,  % +Number, -Description
    describe_two_digit_witness/3 % +Number, -Description, -Witness
]).

:- use_module(formalization(grounded_utils), [predecessor_rec/2]).
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

% ============================================================
% Decompose any two-digit number into tens and ones
% ============================================================

%!  decompose_two_digit(+Number, -Tens, -Ones) is det.
%
%   Decompose a number (0-99) into tens count and ones count.
%   Both Tens and Ones are recollection structures.
%
%   Example: decompose_two_digit(47) → Tens=4, Ones=7
%
%   This generalizes K.NS.7's decompose_teen (which only
%   handled 0-1 tens) to 0-9 tens.

decompose_two_digit(Number, Tens, Ones) :-
    decompose_two_digit_witness(Number, Tens, Ones, _).

%!  decompose_two_digit_witness(+Number, -Tens, -Ones, -Witness) is det.
%
%   Witness-bearing version of decompose_two_digit/3. The witness records the
%   exact finite repeated-subtraction trace that proves how many complete tens
%   fit and what ones remain.

decompose_two_digit_witness(Number, Tens, Ones, Witness) :-
    incur_cost(inference),
    integer_to_recollection(10, Ten),
    count_tens_trace_(Number, Ten, Tens, Ones, Steps),
    decompose_witness(Number, Tens, Ones, Ten, Steps, Witness).

%% Count how many tens fit, return remainder as ones, and retain a readable trace.
count_tens_trace_(Number, Ten, TensCount, Ones, Steps) :-
    zero(Zero),
    count_tens_trace_acc_(Number, Ten, Zero, TensCount, Ones, Steps).

count_tens_trace_acc_(Number, _Ten, Acc, Acc, Number, [Step]) :-
    zero(Zero),
    equal_to(Number, Zero), !,
    count_tens_terminal_step(exactly_zero, Number, Acc, Step).
count_tens_trace_acc_(Number, Ten, Acc, Acc, Number, [Step]) :-
    smaller_than(Number, Ten), !,
    count_tens_terminal_step(fewer_than_ten_remaining, Number, Acc, Step).
count_tens_trace_acc_(Number, Ten, Acc, TensCount, Ones, [Step|Rest]) :-
    subtract_grounded(Number, Ten, Remainder),
    successor_rec(Acc, NextAcc),
    count_tens_subtraction_step(Number, Acc, Remainder, NextAcc, Step),
    count_tens_trace_acc_(Remainder, Ten, NextAcc, TensCount, Ones, Rest).

count_tens_terminal_step(Case, Remainder, TensSoFar, Step) :-
    recollection_to_integer(Remainder, RemainderCount),
    recollection_to_integer(TensSoFar, TensCount),
    Step = _{ kind: standard_1_ns_2_tens_count_terminal,
              terminal_case: Case,
              tens_so_far: TensSoFar,
              tens_count: TensCount,
              remainder: Remainder,
              remainder_count: RemainderCount }.

count_tens_subtraction_step(Before, TensBefore, Remainder, TensAfter, Step) :-
    recollection_to_integer(Before, BeforeCount),
    recollection_to_integer(TensBefore, TensBeforeCount),
    recollection_to_integer(Remainder, RemainderCount),
    recollection_to_integer(TensAfter, TensAfterCount),
    Step = _{ kind: standard_1_ns_2_tens_count_step,
              before: Before,
              before_count: BeforeCount,
              subtract_unit_count: 10,
              tens_before: TensBefore,
              tens_before_count: TensBeforeCount,
              remainder: Remainder,
              remainder_count: RemainderCount,
              tens_after: TensAfter,
              tens_after_count: TensAfterCount }.

%% Increment a recollection by one (without importing successor
%% to avoid confusion with grounded_arithmetic:successor which
%% expects recollection format)
successor_rec(recollection(H), recollection([tally|H])).


% ============================================================
% Compose a number from tens and ones
% ============================================================

%!  compose_two_digit(+Tens, +Ones, -Number) is det.
%
%   Compose a number from tens count and ones count.
%   Number = Tens * 10 + Ones (done via grounded operations).

compose_two_digit(Tens, Ones, Number) :-
    compose_two_digit_witness(Tens, Ones, Number, _).

%!  compose_two_digit_witness(+Tens, +Ones, -Number, -Witness) is det.
%
%   Witness-bearing version of compose_two_digit/3. The proof multiplies the
%   tens count by repeated addition of ten, then adds the supplied ones.

compose_two_digit_witness(Tens, Ones, Number, Witness) :-
    incur_cost(inference),
    integer_to_recollection(10, Ten),
    multiply_tens_trace_(Tens, Ten, TensValue, Steps),
    add_grounded(TensValue, Ones, Number),
    compose_witness(Tens, Ones, Number, Ten, TensValue, Steps, Witness).

%% Multiply tens count by ten via repeated addition.
multiply_tens_trace_(Tens, _Ten, Result, Steps) :-
    zero(Zero),
    equal_to(Tens, Zero),
    Zero = Result,
    Steps = [_{ kind: standard_1_ns_2_tens_multiply_terminal,
                terminal_case: zero_tens,
                tens_count: 0,
                result: Zero,
                result_count: 0 }], !.
multiply_tens_trace_(Tens, Ten, Result, [Step|Rest]) :-
    predecessor_rec(Tens, PrevTens),
    multiply_tens_trace_(PrevTens, Ten, Partial, Rest),
    add_grounded(Partial, Ten, Result),
    recollection_to_integer(Tens, TensCount),
    recollection_to_integer(PrevTens, PrevTensCount),
    recollection_to_integer(Partial, PartialCount),
    recollection_to_integer(Result, ResultCount),
    Step = _{ kind: standard_1_ns_2_tens_multiply_step,
              tens: Tens,
              tens_count: TensCount,
              previous_tens: PrevTens,
              previous_tens_count: PrevTensCount,
              partial_value: Partial,
              partial_value_count: PartialCount,
              add_unit_count: 10,
              result: Result,
              result_count: ResultCount }.

% predecessor_rec/2 imported from formalization(grounded_utils).


% ============================================================
% Multiples of ten
% ============================================================

%!  is_multiple_of_ten(+Number) is semidet.
%
%   True if Number is a multiple of 10 (ones digit is zero).

is_multiple_of_ten(Number) :-
    is_multiple_of_ten_witness(Number, multiple_of_ten, _).

%!  is_multiple_of_ten_witness(+Number, -Result, -Witness) is det.
%
%   Result is `multiple_of_ten` when the decomposed ones place is zero and
%   `not_multiple_of_ten` otherwise. The compatibility predicate
%   is_multiple_of_ten/1 delegates to the positive result.

is_multiple_of_ten_witness(Number, Result, Witness) :-
    decompose_two_digit_witness(Number, Tens, Ones, DecompositionWitness),
    multiple_of_ten_result(Ones, Result, Relation),
    multiple_of_ten_witness(Number,
                            Tens,
                            Ones,
                            Result,
                            Relation,
                            DecompositionWitness,
                            Witness).


% ============================================================
% Description
% ============================================================

%!  describe_two_digit(+Number, -Description) is det.
%
%   Produce a structured place-value description.
%   Returns place_value(TensInt, OnesInt).

describe_two_digit(Number, place_value(TensInt, OnesInt)) :-
    describe_two_digit_witness(Number, place_value(TensInt, OnesInt), _).

%!  describe_two_digit_witness(+Number, -Description, -Witness) is det.
%
%   Produce the readable `place_value(Tens, Ones)` projection together with the
%   decomposition proof that justifies it.

describe_two_digit_witness(Number, place_value(TensInt, OnesInt), Witness) :-
    decompose_two_digit_witness(Number, Tens, Ones, DecompositionWitness),
    recollection_to_integer(Tens, TensInt),
    recollection_to_integer(Ones, OnesInt),
    projection_witness(place_value_description,
                       describe_two_digit/2,
                       Number,
                       place_value(TensInt, OnesInt),
                       DecompositionWitness,
                       Witness).

decompose_witness(Number,
                  Tens,
                  Ones,
                  Ten,
                  Steps,
                  _{ kind: standard_1_ns_2_decomposition,
                     scope: closed_world_finite_standard_1_ns_2_place_value,
                     standard: in_1_ns_2,
                     source_predicate: decompose_two_digit/3,
                     number: Number,
                     number_count: NumberCount,
                     tens: Tens,
                     ones: Ones,
                     place_counts: _{tens: TensCount, ones: OnesCount},
                     ten_unit_count: TenCount,
                     remainder: Ones,
                     remainder_count: OnesCount,
                     steps: Steps,
                     step_count: StepCount,
                     derivation: count_tens_by_repeated_subtraction,
                     projection: tens_ones_place_value,
                     boundary: supplied_grounded_recollection_up_to_99,
                     bound_status: BoundStatus }) :-
    recollection_to_integer(Number, NumberCount),
    recollection_to_integer(Tens, TensCount),
    recollection_to_integer(Ones, OnesCount),
    recollection_to_integer(Ten, TenCount),
    length(Steps, StepCount),
    place_value_bound_status(NumberCount, BoundStatus).

compose_witness(Tens,
                Ones,
                Number,
                Ten,
                TensValue,
                Steps,
                _{ kind: standard_1_ns_2_composition,
                   scope: closed_world_finite_standard_1_ns_2_place_value,
                   standard: in_1_ns_2,
                   source_predicate: compose_two_digit/3,
                   tens: Tens,
                   ones: Ones,
                   number: Number,
                   number_count: NumberCount,
                   place_counts: _{tens: TensCount, ones: OnesCount},
                   ten_unit_count: TenCount,
                   tens_value: TensValue,
                   tens_value_count: TensValueCount,
                   steps: Steps,
                   step_count: StepCount,
                   derivation: multiply_tens_then_add_ones,
                   projection: tens_ones_place_value,
                   boundary: supplied_grounded_recollection_up_to_99,
                   bound_status: BoundStatus }) :-
    recollection_to_integer(Tens, TensCount),
    recollection_to_integer(Ones, OnesCount),
    recollection_to_integer(Number, NumberCount),
    recollection_to_integer(Ten, TenCount),
    recollection_to_integer(TensValue, TensValueCount),
    length(Steps, StepCount),
    place_value_bound_status(NumberCount, BoundStatus).

multiple_of_ten_result(Ones, multiple_of_ten, equal_to(Ones, Zero)) :-
    zero(Zero),
    equal_to(Ones, Zero), !.
multiple_of_ten_result(Ones, not_multiple_of_ten, not_equal_to(Ones, Zero)) :-
    zero(Zero),
    \+ equal_to(Ones, Zero).

multiple_of_ten_witness(Number,
                        Tens,
                        Ones,
                        Result,
                        Relation,
                        DecompositionWitness,
                        _{ kind: standard_1_ns_2_multiple_of_ten,
                           scope: closed_world_finite_standard_1_ns_2_place_value,
                           standard: in_1_ns_2,
                           source_predicate: is_multiple_of_ten/1,
                           number: Number,
                           number_count: NumberCount,
                           place_counts: _{tens: TensCount, ones: OnesCount},
                           result: Result,
                           relation: Relation,
                           derivation: decompose_then_check_zero_ones,
                           boundary: supplied_grounded_recollection_up_to_99,
                           bound_status: BoundStatus,
                           decomposition_witness: DecompositionWitness }) :-
    recollection_to_integer(Number, NumberCount),
    recollection_to_integer(Tens, TensCount),
    recollection_to_integer(Ones, OnesCount),
    place_value_bound_status(NumberCount, BoundStatus).

projection_witness(Projection,
                   Predicate,
                   Number,
                   Output,
                   DecompositionWitness,
                   _{ kind: standard_1_ns_2_projection,
                      scope: closed_world_finite_standard_1_ns_2_place_value,
                      standard: in_1_ns_2,
                      source_predicate: Predicate,
                      number: Number,
                      number_count: NumberCount,
                      output: Output,
                      projection: Projection,
                      derivation: project_from_two_digit_decomposition,
                      boundary: supplied_grounded_recollection_up_to_99,
                      bound_status: BoundStatus,
                      decomposition_witness: DecompositionWitness }) :-
    recollection_to_integer(Number, NumberCount),
    place_value_bound_status(NumberCount, BoundStatus).

place_value_bound_status(Count, below_indiana_1_ns_2_two_digit_range) :-
    Count < 10, !.
place_value_bound_status(Count, within_indiana_1_ns_2_bound) :-
    Count =< 99, !.
place_value_bound_status(Count, outside_indiana_1_ns_2_bound(Count)).
