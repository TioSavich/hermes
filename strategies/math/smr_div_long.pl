/** <module> Coordinated Long Division (Correct Elaboration)
 *
 * This module implements long division as a *coordinated* finite state
 * machine in Brandom's sense: the complex ability "divide arbitrary
 * naturals" is specified by an algorithm that invokes simpler sub-abilities
 * (multiplication for quotient-digit estimation; subtraction with borrow
 * for the partial-dividend step). The elaboration is made structural —
 * visible in the FSM topology — rather than collapsed into a single
 * primitive.
 *
 * This is the *correct* companion to Benny's Rule 1 (`misconceptions/benny.pl`).
 * Benny's rule compresses this ~15-state machine into ~4 states by replacing
 * content-carrying operations (division, sub-dividend comparison) with a
 * single surface-syntactic step (sum the numerator and denominator).
 *
 * Design decisions (per build spec):
 *   * Borrow depth capped at 2 digits of partial dividend. `sar_sub_decomposition`
 *     enforces this cap; the automaton does not try to extend it. Safe zone:
 *     single-digit divisors (partial ≤ 98). Documented gap; not fixed in this pass.
 *   * Quotient-digit estimation via trial Q=9,8,...,0. Up to 9 multiplication
 *     invocations per quotient digit. Slow is the point — cognitive faithfulness
 *     to a student working without a division table.
 *   * Quotient digits are accumulated left-to-right as positional digit
 *     lists. Results that fit the historical counting2 stack retain that
 *     representation; wider results return a positional_quotient/3 term.
 *     The string API renders directly from the digit lists in either case.
 *   * Sub-automaton calls are direct and module-qualified — not routed through
 *     the meta-interpreter's `solve/6`. Precedent: `jason_fsm.pl` calls `run_pfs`
 *     directly from `run_fcs`.
 *   * `is_recollection` gates fire at every arithmetic-result point. This is
 *     the first FSM in the repo to enforce that discipline explicitly. Prior
 *     automata left the licensing chain implicit in the `recollection(History)`
 *     struct structure; here it is a transition-level check.
 *
 * Precision: 4 decimal digits past the decimal point by default. Configurable
 * via `max_decimal_digits/1` if a future pass needs to widen it.
 */
:- module(smr_div_long,
          [ run_long_division/5,
            run_long_division_string/5,
            max_decimal_digits/1
          ]).

:- use_module(library(lists)).
:- use_module(formalization(grounded_arithmetic),
              [ integer_to_digit_list/2,
                incur_cost/1
              ]).
:- use_module(formalization(robinson_q), [is_recollection/2]).
:- use_module(strategies(math/smr_mult_commutative_reasoning),
              [ run_commutative_mult/4 ]).
:- use_module(strategies(math/sar_sub_decomposition),
              [ run_decomposition/4 ]).
:- use_module(strategies(math/counting2),
              [ empty_decimal_stack/1,
                set_digit_at_place/4
              ]).

:- discontiguous transition/5.

%! max_decimal_digits(-N:integer) is det.
%
%  Default precision (digits past the decimal point). 4 keeps runs tractable
%  while giving enough room to exhibit the terminating case (3/4 = 0.75)
%  and the non-terminating truncation case (1/3 = 0.3333).
max_decimal_digits(4).

%! run_long_division(+Dividend:integer, +Divisor:integer, -Quotient, -Remainder:integer, -History:list) is det.
%
%  Quotient is a counting2 place-value stack when the result fits its legacy
%  three integer and three fractional places. Wider results use
%  positional_quotient/3. Example (3/4):
%    run_long_division(3, 4, [U0,T0,H0,'.',D7,C5,M0,'#'], 0, _).
%
%  For a stable rendered representation use `run_long_division_string/5`.
run_long_division(Dividend, Divisor, QuotientStack, Remainder, History) :-
    run_long_division_state(Dividend, Divisor, FinalState, History),
    quotient_state_term(FinalState, QuotientStack),
    Remainder = FinalState.partial.

run_long_division_state(Dividend, Divisor, FinalState, History) :-
    Divisor > 0,
    once(is_recollection(Dividend, _)),
    once(is_recollection(Divisor, _)),
    integer_to_digit_list(Dividend, DividendDigits),
    max_decimal_digits(MaxDec),
    empty_decimal_stack(InitialStack),
    State0 = state{
        stage: integer,
        digits_remaining: DividendDigits,
        partial: 0,
        divisor: Divisor,
        quotient_stack: InitialStack,
        integer_digits: [],
        fractional_digits: [],
        decimal_count: 0,
        max_decimal: MaxDec
    },
    incur_cost(strategy_selection),
    Hist0 = [hist(q_init, init(dividend(Dividend), divisor(Divisor), digits(DividendDigits)))],
    run(q_init, State0, Hist0, RevHistory, FinalState),
    reverse(RevHistory, History).

%! run_long_division_string(+Dividend:integer, +Divisor:integer, -String:string, -Remainder:integer, -History:list) is det.
%
%  Convenience wrapper around the same transition run that renders its
%  positional digit lists to a human-readable string. Examples:
%    run_long_division_string(3, 4, "0.75",  0, _).
%    run_long_division_string(7, 8, "0.875", 0, _).
%    run_long_division_string(1, 2, "0.5",   0, _).
run_long_division_string(Dividend, Divisor, String, Remainder, History) :-
    run_long_division_state(Dividend, Divisor, FinalState, History),
    render_quotient_digits(FinalState.integer_digits,
                           FinalState.fractional_digits, String),
    Remainder = FinalState.partial.

% --- State-machine driver -------------------------------------------------

run(q_accept, State, Hist, Hist, State) :- !.
run(Current, State, HistIn, HistOut, Final) :-
    transition(Current, State, Next, NewState, Entry),
    run(Next, NewState, [hist(Current, Entry)|HistIn], HistOut, Final).

% --- Transitions ----------------------------------------------------------

% q_init → q_bring_down_digit
% The init step has already licensed Dividend and Divisor in run_long_division/5.
% Transition immediately into the per-digit bring-down loop.
transition(q_init, State, q_bring_down_digit, State,
           transition(q_init_to_bring_down)).

% q_bring_down_digit: either pop next digit or (if none) decide whether to
% start a decimal expansion or accept.
transition(q_bring_down_digit, State, q_estimate_quotient_digit, NewState,
           bring_down(Digit, new_partial(NewPartial))) :-
    State.digits_remaining = [Digit|Rest],
    State.stage = integer,
    NewPartial is State.partial * 10 + Digit,
    once(is_recollection(NewPartial, _)),   % license the partial dividend
    NewState = State.put(_{digits_remaining: Rest, partial: NewPartial}).

transition(q_bring_down_digit, State, q_decide_after_integer, State,
           integer_digits_exhausted) :-
    State.digits_remaining = [],
    State.stage = integer.

% q_decide_after_integer: after the integer phase, either we have a zero
% remainder and accept, or we have a non-zero remainder and emit a decimal
% point (precision permitting).
transition(q_decide_after_integer, State, q_accept, State,
           accept(integer, remainder(0))) :-
    State.partial =:= 0, !.
transition(q_decide_after_integer, State, q_emit_decimal_point, State,
           switching_to_decimal_phase) :-
    State.partial > 0,
    State.max_decimal > 0.

% q_estimate_quotient_digit: trial Q=9,8,...,0; accept first Q whose
% Product = Q × Divisor is ≤ CurrentPartial. Each trial invokes the
% multiplication automaton.
transition(q_estimate_quotient_digit, State, q_subtract_with_borrow, NewState,
           estimate_q(Q, product(Product), trials(Trials))) :-
    estimate_digit(State.partial, State.divisor, 9, Q, Product, [], TrialsRev),
    reverse(TrialsRev, Trials),
    once(is_recollection(Q, _)),           % license the quotient digit
    once(is_recollection(Product, _)),     % license Q × Divisor
    NewState = State.put(_{current_q: Q, current_product: Product}).

% q_subtract_with_borrow: NewPartial = CurrentPartial - Product, via the
% two-digit borrow automaton. If the subtraction returns 'error' or
% exceeds the borrow depth, throw — this is a hard halt, not a silent fail.
transition(q_subtract_with_borrow, State, q_emit_quotient_digit, NewState,
           subtract(State.partial, State.current_product, NewPartial, SubHistory)) :-
    sar_sub_decomposition:run_decomposition(State.partial,
                                            State.current_product,
                                            NewPartial,
                                            SubHistory),
    ( integer(NewPartial)
    -> true
    ;  throw(error(borrow_depth_exceeded(partial(State.partial),
                                         product(State.current_product)), _))
    ),
    once(is_recollection(NewPartial, _)),  % license the new partial
    NewState = State.put(_{partial: NewPartial}).

% q_emit_quotient_digit: write Q into the quotient stack at the place
% that corresponds to the current emit position. Route by stage.
%
% Place semantics:
%   * integer stage — place is determined by how many dividend digits
%     remain in `digits_remaining` at emit time. 0 remaining → ones;
%     1 → tens; 2 → hundreds. (Dividend consumed left-to-right.)
%   * decimal stage — place is determined by `decimal_count` at emit
%     time (pre-increment). 0 → tenths; 1 → hundredths; 2 → thousandths.
%
% The `'.'` boundary was placed by q_emit_decimal_point *structurally*
% into the stack; no marker is being inserted here — `set_digit_at_place`
% just writes into the right region of the existing stack.
transition(q_emit_quotient_digit, State, Next, NewState,
           emit(State.current_q, stage(State.stage), place(Place))) :-
    emitted_place(State, Place),
    append_quotient_digit(State, State.current_q, DigitState),
    legacy_stack_after_emit(State, Place, State.current_q, NewStack),
    NewState0 = DigitState.put(_{quotient_stack: NewStack}),
    ( State.stage = integer
    -> ( State.digits_remaining = []
       -> Next = q_decide_after_integer
       ;  Next = q_bring_down_digit
       ),
       NewState = NewState0
    ;  % decimal stage: another "continue decimal" iteration or accept
       NewDec is State.decimal_count + 1,
       NewState = NewState0.put(_{decimal_count: NewDec}),
       decide_after_decimal_emit(NewState, Next)
    ).

% Integer stage: 0 remaining → ones, 1 → tens, 2 → hundreds.
emitted_place(State, Place) :-
    State.stage = integer, !,
    length(State.digits_remaining, R),
    integer_place_by_remaining(R, Place).
% Decimal stage: decimal_count 0 → tenths, 1 → hundredths, 2 → thousandths.
emitted_place(State, Place) :-
    State.stage = decimal, !,
    fractional_place_by_count(State.decimal_count, Place).

integer_place_by_remaining(0, ones).
integer_place_by_remaining(1, tens).
integer_place_by_remaining(2, hundreds).
integer_place_by_remaining(N, integer_place(N)) :- N > 2.

fractional_place_by_count(0, tenths).
fractional_place_by_count(1, hundredths).
fractional_place_by_count(2, thousandths).
fractional_place_by_count(N, fractional_place(N)) :- N >= 3.

append_quotient_digit(State, Digit, NewState) :-
    State.stage = integer,
    append(State.integer_digits, [Digit], Digits),
    NewState = State.put(_{integer_digits: Digits}).
append_quotient_digit(State, Digit, NewState) :-
    State.stage = decimal,
    append(State.fractional_digits, [Digit], Digits),
    NewState = State.put(_{fractional_digits: Digits}).

legacy_stack_after_emit(State, Place, Digit, NewStack) :-
    memberchk(Place, [ones, tens, hundreds, tenths, hundredths, thousandths]),
    !,
    set_digit_at_place(Place, Digit, State.quotient_stack, NewStack).
legacy_stack_after_emit(State, _Place, _Digit, State.quotient_stack).

quotient_state_term(State, Stack) :-
    length(State.integer_digits, IntegerCount),
    length(State.fractional_digits, FractionCount),
    IntegerCount =< 3,
    FractionCount =< 3,
    !,
    Stack = State.quotient_stack.
quotient_state_term(State,
                    positional_quotient(base(10),
                                        integer_digits(IntegerDigits),
                                        fractional_digits(State.fractional_digits))) :-
    trim_leading_zero_digits(State.integer_digits, IntegerDigits).

render_quotient_digits(IntegerDigits0, FractionalDigits, String) :-
    trim_leading_zero_digits(IntegerDigits0, IntegerDigits),
    digit_list_string(IntegerDigits, IntegerString),
    (   FractionalDigits == []
    ->  String = IntegerString
    ;   digit_list_string(FractionalDigits, FractionalString),
        string_concat(IntegerString, ".", Prefix),
        string_concat(Prefix, FractionalString, String)
    ).

trim_leading_zero_digits([0|Digits], Trimmed) :-
    Digits = [_|_],
    !,
    trim_leading_zero_digits(Digits, Trimmed).
trim_leading_zero_digits([], [0]).
trim_leading_zero_digits(Digits, Digits).

digit_list_string(Digits, String) :-
    maplist(number_string, Digits, Parts),
    atomics_to_string(Parts, String).

decide_after_decimal_emit(State, q_accept) :-
    State.partial =:= 0, !.
decide_after_decimal_emit(State, q_accept) :-
    State.decimal_count >= State.max_decimal, !.
decide_after_decimal_emit(_, q_continue_decimal).

% q_emit_decimal_point: flip the stage to decimal and reset decimal_count.
% The `'.'` boundary is already in the stack from `empty_decimal_stack/1`;
% no list manipulation is needed. This transition is structural (stage
% change only), not an arithmetic-result point.
transition(q_emit_decimal_point, State, q_continue_decimal, NewState,
           emit_decimal_point) :-
    NewState = State.put(_{stage: decimal, decimal_count: 0}).

% q_continue_decimal: multiply partial by 10 (i.e., bring down an implicit zero).
transition(q_continue_decimal, State, q_estimate_quotient_digit, NewState,
           continue_decimal(NewPartial)) :-
    NewPartial is State.partial * 10,
    once(is_recollection(NewPartial, _)),  % license the scaled partial
    NewState = State.put(_{partial: NewPartial}).

% --- Quotient-digit estimation (trial multiplication) ---------------------
%
% Try Q = 9, 8, ..., 0. The first Q whose product is ≤ Partial wins.
% Each trial records (Q, Product, MulHistory).
estimate_digit(_Partial, _Divisor, -1, _, _, _, _) :-
    throw(error(quotient_digit_estimation_failed, _)).
estimate_digit(Partial, Divisor, Q, WinningQ, WinningProduct, Acc, Trials) :-
    Q >= 0,
    smr_mult_commutative_reasoning:run_commutative_mult(Q, Divisor, Product, MulHistory),
    Acc1 = [trial(Q, Product, MulHistory)|Acc],
    ( Product =< Partial
    -> WinningQ = Q, WinningProduct = Product, Trials = Acc1
    ;  NextQ is Q - 1,
       estimate_digit(Partial, Divisor, NextQ, WinningQ, WinningProduct, Acc1, Trials)
    ).

% --- Self-tests -----------------------------------------------------------

run_smr_div_long_tests :-
    catch(
        ( test_div_case(3, 4, "0.75",  0),
          test_div_case(1, 2, "0.5",   0),
          test_div_case(2, 5, "0.4",   0),
          test_div_case(7, 8, "0.875", 0),
          format('[smr_div_long] all 4 self-tests passed.~n', [])
        ),
        E,
        ( format('[smr_div_long] SELF-TEST FAILURE: ~w~n', [E]), throw(E))
    ).

% Compares the rendered string of the quotient stack against ExpectedStr.
% The stack itself is the primary product; the string is the legible
% projection for human readers.
test_div_case(N, D, ExpectedStr, ExpectedR) :-
    run_long_division_string(N, D, Str, R, _),
    ( Str == ExpectedStr, R == ExpectedR
    -> format('  PASS ~w/~w = ~w rem ~w~n', [N, D, Str, R])
    ;  format('  FAIL ~w/~w: got ~w rem ~w, expected ~w rem ~w~n',
              [N, D, Str, R, ExpectedStr, ExpectedR]),
       throw(test_failure(N/D))
    ).
