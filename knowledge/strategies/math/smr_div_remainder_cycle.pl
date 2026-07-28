/** <module> Decimal expansion decided by the remainder cycle
 *
 * PURPOSE: decide whether the decimal expansion of P/Q terminates, and when
 * it does not, return the transient and the repeating block, by carrying the
 * remainder rather than a digit count.
 *
 * The remainder at a step fixes everything that comes after it, so this
 * machine has two halts and each one is a proof rather than a cutoff:
 *
 *   - a remainder of zero. Nothing is left to bring down, so the fractional
 *     digits already emitted are the whole expansion and it terminates.
 *   - a remainder equal to one already recorded. The machine is in a state it
 *     has occupied before, so the digits emitted between the two occurrences
 *     recur without end, and that block is returned.
 *
 * Only remainders 1..Q-1 can ever be recorded, because a remainder of zero
 * halts instead. The record therefore holds at most Q-1 entries and the Qth
 * step must either halt or repeat. That bound is the pigeonhole on
 * remainders, not a precision setting: `record_within_pigeonhole/2` states it
 * as an invariant over the record and throws if it is ever exceeded, so the
 * machine has no number in it that a caller could raise to get a different
 * verdict.
 *
 * Relation to `smr_div_long`. That automaton emits digits under
 * `max_decimal_digits/1` and stops there, which answers a different question.
 * Measured on the live tree: 1/32 comes back "0.0312" with remainder 16 and
 * 1/3 comes back "0.3333" with remainder 1, so an expansion that terminates
 * after five digits and one that never terminates arrive in the same shape.
 * Raising the bound moves that boundary without removing it. For a rendered
 * quotient at a fixed precision `smr_div_long` is still the automaton to
 * call; this one answers whether the expansion ends.
 *
 * Grounded arithmetic. Each step is performed on recollection structures
 * rather than delegated to `//` and `mod`: `multiply_grounded/3` brings down
 * the zero and `base_decompose_grounded/4` counts out how many divisor-groups
 * the scaled remainder holds, which yields the quotient digit and the next
 * remainder together. The recurrence test is `equal_to/2` over those same
 * structures. Two comparisons are not grounded arithmetic and are marked
 * where they occur: the pigeonhole invariant, which counts entries in the
 * machine's own record, and the position at which a remainder was first
 * recorded, which indexes the digit list. Neither reads a quantity in the
 * division.
 *
 * Domain. P a non-negative integer and Q a positive integer. Anything else
 * returns `refused(Reason)` with a history entry naming the condition that
 * failed; the machine does not produce a verdict for input it cannot divide.
 *
 * What this does not decide. Its inputs are ratios of integers, so every
 * non-terminating expansion it can meet is periodic, and it has no input
 * whose expansion is non-terminating and aperiodic. It also has no input
 * whose repeating block is all nines: long division of P/Q emits the
 * terminating representation of such a value and halts on a zero remainder.
 * Both absences are measured by `run_smr_div_remainder_cycle_tests/0` rather
 * than argued for here.
 */
:- module(smr_div_remainder_cycle,
          [ run_remainder_cycle_division/4,
            run_remainder_cycle_division_string/4,
            expansion_verdict/2,
            render_decimal_expansion/2,
            run_smr_div_remainder_cycle_tests/0
          ]).

:- use_module(library(lists)).
:- use_module(formalization(grounded_arithmetic),
              [ integer_to_recollection/2,
                recollection_to_integer/2,
                integer_to_digit_list/2,
                multiply_grounded/3,
                equal_to/2,
                incur_cost/1
              ]).
:- use_module(formalization(grounded_utils),
              [ base_decompose_grounded/4,
                is_zero_grounded/1
              ]).
:- use_module(formalization(robinson_q), [is_recollection/2]).
:- use_module(strategies(math/smr_div_long),
              [ trim_leading_zero_digits/2,
                digit_list_string/2
              ]).

:- discontiguous transition/5.

%! run_remainder_cycle_division(+P:integer, +Q:integer, -Expansion, -History:list) is det.
%
%  Expansion is either `refused(Reason)` or
%
%    decimal_expansion(Verdict,
%                      integer_digits(Is),
%                      preperiod_digits(Ps),
%                      repeating_digits(Rs),
%                      preperiod_length(K),
%                      period_length(L),
%                      halt(Proof))
%
%  Verdict is `terminating` or `repeating`. When it terminates, Ps holds every
%  fractional digit, K is how many there are, Rs is empty, L is 0, and Proof is
%  `remainder_zero`. When it repeats, Ps holds the transient of length K, Rs
%  holds the block of length L, and Proof is `remainder_recurred(R)` naming the
%  remainder that came round again.
%
%  Examples:
%    run_remainder_cycle_division(1, 32, E, _).  % terminating, five digits
%    run_remainder_cycle_division(1, 6,  E, _).  % repeating, K = 1, block [6]
run_remainder_cycle_division(P, Q, Expansion, History) :-
    (   refusal(P, Q, Reason)
    ->  Expansion = refused(Reason),
        History = [ hist(q_init, offered(dividend(P), divisor(Q))),
                    hist(q_refuse, refuse(Reason))
                  ]
    ;   run_decided(P, Q, Expansion, History)
    ).

%! run_remainder_cycle_division_string(+P, +Q, -String:string, -History:list) is det.
%
%  The same run, rendered. A terminating expansion reads "0.03125"; a repeating
%  one puts the block in parentheses, so 1/6 reads "0.1(6)" and 1/3 reads
%  "0.(3)". A refusal renders as "refused(divisor_is_zero)" rather than as a
%  numeral, so a caller that only reads the string still cannot mistake it for
%  an answer.
run_remainder_cycle_division_string(P, Q, String, History) :-
    run_remainder_cycle_division(P, Q, Expansion, History),
    render_decimal_expansion(Expansion, String).

%! expansion_verdict(+Expansion, -Verdict) is det.
%
%  Verdict is `terminating`, `repeating`, or `refused(Reason)`.
expansion_verdict(refused(Reason), refused(Reason)) :- !.
expansion_verdict(decimal_expansion(Verdict, _, _, _, _, _, _), Verdict).

% --- Refusal --------------------------------------------------------------
%
% Named conditions, checked before any arithmetic runs. Q = 0 is the case that
% has no quotient at all; the negative cases are outside what a long-division
% machine over counted collections represents.
refusal(P, _, non_integer_dividend) :- \+ integer(P), !.
refusal(_, Q, non_integer_divisor)  :- \+ integer(Q), !.
refusal(_, 0, divisor_is_zero)      :- !.
refusal(_, Q, negative_divisor)     :- Q < 0, !.
refusal(P, _, negative_dividend)    :- P < 0.

% --- State-machine driver -------------------------------------------------

run_decided(P, Q, Expansion, History) :-
    once(is_recollection(P, _)),
    once(is_recollection(Q, _)),
    integer_to_recollection(Q, RecQ),
    State0 = state{
        dividend: P,
        divisor: Q,
        divisor_rec: RecQ,
        integer_digits: [],
        fractional_digits: [],
        remainder_rec: none,
        scaled_rec: none,
        seen: [],
        expansion: pending
    },
    incur_cost(strategy_selection),
    Hist0 = [hist(q_init, init(dividend(P), divisor(Q)))],
    run(q_init, State0, Hist0, RevHistory, FinalState),
    reverse(RevHistory, History),
    Expansion = FinalState.expansion.

run(q_terminates, State, Hist, Hist, State) :- !.
run(q_repeats, State, Hist, Hist, State) :- !.
run(Current, State, HistIn, HistOut, Final) :-
    transition(Current, State, Next, NewState, Entry),
    run(Next, NewState, [hist(Current, Entry)|HistIn], HistOut, Final).

% --- Transitions ----------------------------------------------------------

% q_init: the inputs were licensed in run_decided/4. Move straight into the
% integer step.
transition(q_init, State, q_divide_integer_part, State,
           transition(q_init_to_integer_part)).

% q_divide_integer_part: count out how many whole divisor-groups the dividend
% holds. The group count is the integer part; what is left over is the
% remainder the fractional loop starts from.
transition(q_divide_integer_part, State, q_check_remainder, NewState,
           integer_part(quotient(IntQuotient), remainder(R0))) :-
    integer_to_recollection(State.dividend, RecP),
    base_decompose_grounded(RecP, State.divisor_rec, RecInt, RecR0),
    recollection_to_integer(RecInt, IntQuotient),
    recollection_to_integer(RecR0, R0),
    once(is_recollection(IntQuotient, _)),
    once(is_recollection(R0, _)),
    integer_to_digit_list(IntQuotient, IntegerDigits),
    incur_cost(inference),
    NewState = State.put(_{integer_digits: IntegerDigits,
                           remainder_rec: RecR0}).

% q_check_remainder: three exits, taken in this order.
%
%   zero        -> the expansion terminates, proved by there being nothing
%                  left to bring down.
%   already recorded -> the expansion repeats, proved by the machine having
%                  been in this state before; the block is the digits emitted
%                  since that earlier visit.
%   new         -> record it against the position of the digit it will
%                  produce, then carry on.
transition(q_check_remainder, State, q_terminates, NewState,
           halt(remainder_zero, terminates_after(K))) :-
    is_zero_grounded(State.remainder_rec),
    !,
    length(State.fractional_digits, K),
    Expansion = decimal_expansion(
                    terminating,
                    integer_digits(State.integer_digits),
                    preperiod_digits(State.fractional_digits),
                    repeating_digits([]),
                    preperiod_length(K),
                    period_length(0),
                    halt(remainder_zero)),
    NewState = State.put(_{expansion: Expansion}).
transition(q_check_remainder, State, q_repeats, NewState,
           halt(remainder_recurred(R), first_recorded_at(FirstIndex),
                period(L), repeating_block(Block))) :-
    recurrence_index(State.remainder_rec, State.seen, FirstIndex),
    !,
    recollection_to_integer(State.remainder_rec, R),
    % FirstIndex indexes the digit list, not a quantity in the division.
    split_at(FirstIndex, State.fractional_digits, Preperiod, Block),
    length(Block, L),
    Expansion = decimal_expansion(
                    repeating,
                    integer_digits(State.integer_digits),
                    preperiod_digits(Preperiod),
                    repeating_digits(Block),
                    preperiod_length(FirstIndex),
                    period_length(L),
                    halt(remainder_recurred(R))),
    NewState = State.put(_{expansion: Expansion}).
transition(q_check_remainder, State, q_scale_remainder, NewState,
           record_remainder(R, at_index(Index), records_held(Held))) :-
    recollection_to_integer(State.remainder_rec, R),
    length(State.fractional_digits, Index),
    length(State.seen, Held),
    record_within_pigeonhole(Held, State.divisor),
    append(State.seen, [seen(Index, State.remainder_rec)], Seen),
    incur_cost(inference),
    NewState = State.put(_{seen: Seen}).

% q_scale_remainder: bring down a zero, which is multiplying the remainder by
% ten.
transition(q_scale_remainder, State, q_emit_fraction_digit, NewState,
           bring_down_zero(scaled(Scaled))) :-
    integer_to_recollection(10, RecTen),
    multiply_grounded(State.remainder_rec, RecTen, RecScaled),
    recollection_to_integer(RecScaled, Scaled),
    once(is_recollection(Scaled, _)),
    NewState = State.put(_{scaled_rec: RecScaled}).

% q_emit_fraction_digit: count how many divisor-groups the scaled remainder
% holds. The count is the next fractional digit and the leftover is the next
% remainder, so one grounded decomposition yields both.
transition(q_emit_fraction_digit, State, q_check_remainder, NewState,
           emit_fraction_digit(Digit, new_remainder(R))) :-
    base_decompose_grounded(State.scaled_rec, State.divisor_rec, RecDigit, RecR),
    recollection_to_integer(RecDigit, Digit),
    recollection_to_integer(RecR, R),
    once(is_recollection(Digit, _)),
    once(is_recollection(R, _)),
    append(State.fractional_digits, [Digit], Digits),
    NewState = State.put(_{fractional_digits: Digits, remainder_rec: RecR}).

% --- The record of remainders ---------------------------------------------

%! recurrence_index(+Rec, +Seen:list, -Index:integer) is semidet.
%
%  Succeeds when Rec equals a recorded remainder, and returns the digit
%  position that earlier remainder was recorded against. The equality test is
%  grounded: two recollections are equal when their counting histories are.
recurrence_index(Rec, [seen(Index, Recorded)|_], Index) :-
    equal_to(Rec, Recorded),
    !.
recurrence_index(Rec, [_|Rest], Index) :-
    recurrence_index(Rec, Rest, Index).

%! record_within_pigeonhole(+Held:integer, +Divisor:integer) is det.
%
%  The invariant that makes the halt structural. Every recorded remainder is
%  non-zero and smaller than the divisor, so at most Divisor-1 of them exist
%  and a machine about to record the Divisor-th has contradicted its own
%  arithmetic. This counts entries in the record, not any quantity in the
%  division, so it uses ordinary comparison; it is a check on the machine and
%  is expected never to fire.
record_within_pigeonhole(Held, Divisor) :-
    Limit is Divisor - 1,
    (   Held < Limit
    ->  true
    ;   throw(error(remainder_record_exceeds_pigeonhole(held(Held),
                                                        divisor(Divisor)), _))
    ).

split_at(N, List, Prefix, Suffix) :-
    length(Prefix, N),
    append(Prefix, Suffix, List).

% --- Rendering ------------------------------------------------------------

%! render_decimal_expansion(+Expansion, -String:string) is det.
render_decimal_expansion(refused(Reason), String) :-
    !,
    format(string(String), "refused(~w)", [Reason]).
render_decimal_expansion(decimal_expansion(_Verdict,
                                           integer_digits(IntegerDigits0),
                                           preperiod_digits(Preperiod),
                                           repeating_digits(Block),
                                           preperiod_length(_),
                                           period_length(_),
                                           halt(_)),
                         String) :-
    trim_leading_zero_digits(IntegerDigits0, IntegerDigits),
    digit_list_string(IntegerDigits, IntegerString),
    fractional_string(Preperiod, Block, FractionalString),
    string_concat(IntegerString, FractionalString, String).

fractional_string([], [], "") :- !.
fractional_string(Preperiod, [], String) :-
    !,
    digit_list_string(Preperiod, Digits),
    string_concat(".", Digits, String).
fractional_string(Preperiod, Block, String) :-
    digit_list_string(Preperiod, PreperiodString),
    digit_list_string(Block, BlockString),
    format(string(String), ".~w(~w)", [PreperiodString, BlockString]).

% --- Self-tests -----------------------------------------------------------

%! run_smr_div_remainder_cycle_tests is det.
%
%  Five decided cases, one refusal, and two sweeps over 1..40 by 1..40 that
%  report what the machine never produces on that range.
run_smr_div_remainder_cycle_tests :-
    catch(
        ( test_terminating(1, 32, [0,3,1,2,5], "0.03125"),
          test_terminating(3, 4, [7,5], "0.75"),
          test_terminating(1, 16, [0,6,2,5], "0.0625"),
          test_repeating(1, 3, [], [3], "0.(3)"),
          test_repeating(1, 7, [], [1,4,2,8,5,7], "0.(142857)"),
          test_repeating(1, 6, [1], [6], "0.1(6)"),
          test_refusal(1, 0, divisor_is_zero),
          sweep_absences(40),
          format('[smr_div_remainder_cycle] all self-tests passed.~n', [])
        ),
        E,
        ( format('[smr_div_remainder_cycle] SELF-TEST FAILURE: ~w~n', [E]),
          throw(E)
        )
    ).

test_terminating(P, Q, ExpectedDigits, ExpectedString) :-
    run_remainder_cycle_division_string(P, Q, String, _),
    run_remainder_cycle_division(P, Q, Expansion, _),
    length(ExpectedDigits, ExpectedCount),
    Wanted = decimal_expansion(terminating,
                               integer_digits(_),
                               preperiod_digits(ExpectedDigits),
                               repeating_digits([]),
                               preperiod_length(ExpectedCount),
                               period_length(0),
                               halt(remainder_zero)),
    (   Expansion = Wanted, String == ExpectedString
    ->  format('  PASS ~w/~w terminates after ~w digits: ~w~n',
               [P, Q, ExpectedCount, String])
    ;   format('  FAIL ~w/~w: got ~q rendered ~q~n', [P, Q, Expansion, String]),
        throw(test_failure(P/Q))
    ).

test_repeating(P, Q, ExpectedPreperiod, ExpectedBlock, ExpectedString) :-
    run_remainder_cycle_division_string(P, Q, String, _),
    run_remainder_cycle_division(P, Q, Expansion, _),
    length(ExpectedPreperiod, K),
    length(ExpectedBlock, L),
    Wanted = decimal_expansion(repeating,
                               integer_digits(_),
                               preperiod_digits(ExpectedPreperiod),
                               repeating_digits(ExpectedBlock),
                               preperiod_length(K),
                               period_length(L),
                               halt(remainder_recurred(_))),
    (   Expansion = Wanted, String == ExpectedString
    ->  format('  PASS ~w/~w does not terminate; pre-period ~w, period ~w, block ~w: ~w~n',
               [P, Q, K, L, ExpectedBlock, String])
    ;   format('  FAIL ~w/~w: got ~q rendered ~q~n', [P, Q, Expansion, String]),
        throw(test_failure(P/Q))
    ).

test_refusal(P, Q, ExpectedReason) :-
    run_remainder_cycle_division(P, Q, Expansion, History),
    (   Expansion == refused(ExpectedReason),
        memberchk(hist(q_refuse, refuse(ExpectedReason)), History)
    ->  format('  PASS ~w/~w refused: ~w~n', [P, Q, ExpectedReason])
    ;   format('  FAIL ~w/~w: got ~q with history ~q~n', [P, Q, Expansion, History]),
        throw(test_failure(P/Q))
    ).

%! sweep_absences(+Bound:integer) is det.
%
%  Runs every P/Q with 1 =< P =< Bound and 1 =< Q =< Bound and counts what
%  comes back. Two of the counts are what the module header claims the machine
%  never produces on rational input: a non-terminating expansion with no
%  period, and a repeating block made only of nines.
sweep_absences(Bound) :-
    numlist(1, Bound, Range),
    findall(Verdict-Block,
            ( member(P, Range),
              member(Q, Range),
              run_remainder_cycle_division(P, Q, Expansion, _),
              Expansion = decimal_expansion(Verdict, _, _,
                                            repeating_digits(Block),
                                            _, _, _)
            ),
            Results),
    length(Results, Total),
    include(terminating_result, Results, Terminating),
    length(Terminating, TerminatingCount),
    include(repeating_result, Results, Repeating),
    length(Repeating, RepeatingCount),
    include(periodless_nonterminating, Results, Periodless),
    length(Periodless, PeriodlessCount),
    include(all_nines_block, Results, AllNines),
    length(AllNines, AllNinesCount),
    (   PeriodlessCount =:= 0, AllNinesCount =:= 0
    ->  format('  PASS sweep 1..~w by 1..~w: ~w runs, ~w terminating, ~w repeating, ~w non-terminating without a period, ~w with an all-nine block~n',
               [Bound, Bound, Total, TerminatingCount, RepeatingCount,
                PeriodlessCount, AllNinesCount])
    ;   format('  FAIL sweep: ~w periodless and ~w all-nine results~n',
               [PeriodlessCount, AllNinesCount]),
        throw(test_failure(sweep(Bound)))
    ).

terminating_result(terminating-_).
repeating_result(repeating-_).
periodless_nonterminating(repeating-[]).
all_nines_block(repeating-Block) :-
    Block = [_|_],
    forall(member(Digit, Block), Digit =:= 9).
