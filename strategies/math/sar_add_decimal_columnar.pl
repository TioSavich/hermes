/** <module> Coordinated Decimal Column Addition (Correct Elaboration)
 *
 * Column-wise decimal addition as a coordinated finite-state machine.
 * Companion to Benny's Rule 4 (decimal-point-stripping addition) in
 * `misconceptions/benny.pl`. Where Benny's rule collapses decimal addition
 * into a single "sum the digits and sprinkle a point" step, this automaton
 * makes the coordination structural — place-value alignment is its own
 * state, per-column addition is its own state, carry propagation is its
 * own state. Benny's deformation is legible as an edit to the elaboration
 * chain: his FSM lacks the `q_align_decimal_points` and `q_carry_up`
 * sub-abilities this automaton invokes.
 *
 * States:
 *   q_init                     — parse A and B to decimal-stack
 *                                representations; license each digit via
 *                                is_recollection before it lands in a slot.
 *   q_align_decimal_points     — ensure both stacks cover the same set of
 *                                place slots (pad with zeros where one
 *                                input is shorter in either direction).
 *                                This is the place-value alignment
 *                                sub-ability Benny's deformation lacks.
 *   q_add_column(Place)        — for each column from thousandths up to
 *                                hundreds: pull the digit from each input,
 *                                sum via add_grounded, split into
 *                                (column-digit, carry) if the sum ≥ 10.
 *   q_carry_up                 — propagate a carry of 1 into the next
 *                                higher place (handled inline in the
 *                                column-walk; the name is documentary).
 *   q_emit                     — write the column digit into the sum stack.
 *   q_accept                   — halt; expose the final sum stack.
 *
 * Sub-abilities (direct module-qualified, per the jason_fsm precedent):
 *   * grounded_arithmetic:add_grounded/3   — per-column add.
 *     (Digit + Digit + Carry could itself be a tiny sub-automaton — a
 *     "count on from D1 by D2 by carry" COBO run — but inlining via
 *     add_grounded keeps the primitive explicit without obscuring the
 *     column structure. The elaboration is one level shallow here by
 *     choice.)
 *   * counting2:empty_decimal_stack/1, set_digit_at_place/4,
 *     stack_to_number/2, render_stack_decimal/2 — stack representation.
 *
 * is_recollection gates fire at every arithmetic-result point: each digit
 * of each input, each per-column sum, each carry, and the final
 * column-digit. Matches the discipline introduced in smr_div_long.pl.
 *
 * Input shapes (see `to_decimal_stack/2`):
 *   * integer (e.g. 2) — written into ones/tens/hundreds as needed.
 *   * float   (e.g. 0.3, 1.5, 2.25) — canonical ~w rendering is parsed
 *     and digits are placed at the right slots. No float arithmetic is
 *     performed; the float is treated as a numeral (surface string) from
 *     which we read the positional digits.
 *   * decimal(I, F, P) — a literal stack-value term as produced by
 *     `counting2:stack_to_number/2`.
 *   * a counting2 stack list — used as-is.
 *
 * Hard constraint: stays within 3 decimal places (thousandths) because
 * `counting2:empty_decimal_stack/1` is defined to that depth. Wider
 * inputs would need to widen the stack first.
 */
:- module(sar_add_decimal_columnar,
          [ run_decimal_column_add/4
          ]).

:- use_module(library(lists)).
:- use_module(formalization(grounded_arithmetic),
              [ add_grounded/3,
                integer_to_recollection/2,
                recollection_to_integer/2,
                incur_cost/1
              ]).
:- use_module(formalization(robinson_q), [is_recollection/2]).
:- use_module(strategies(math/counting2),
              [ empty_decimal_stack/1,
                set_digit_at_place/4,
                stack_to_number/2,
                render_stack_decimal/2
              ]).

% Columns walked from lowest to highest. Order matters — carry propagates
% upward, so the fractional-most place is processed first.
column_order([thousandths, hundredths, tenths, ones, tens, hundreds]).

% Next-higher place for carry propagation. `hundreds` has no higher slot
% in `empty_decimal_stack/1`; overflow past hundreds throws.
next_place_up(thousandths, hundredths).
next_place_up(hundredths, tenths).
next_place_up(tenths, ones).
next_place_up(ones, tens).
next_place_up(tens, hundreds).

%!  run_decimal_column_add(+A:term, +B:term, -Sum:term, -History:list) is det.
%
%   Column-wise decimal addition. A and B may be integers, floats,
%   `decimal(I,F,P)` terms, or counting2 stack lists. Sum is returned as
%   a counting2 stack list; History is a list of hist(State, Detail)
%   terms describing the FSM trajectory.
%
%   Examples:
%     run_decimal_column_add(2, 0.3, Sum, _),  render_stack_decimal(Sum, "2.3").
%     run_decimal_column_add(1.5, 2.25, Sum, _), render_stack_decimal(Sum, "3.75").
%     run_decimal_column_add(0.7, 0.5, Sum, _), render_stack_decimal(Sum, "1.2").
%     run_decimal_column_add(2, 3, Sum, _),    render_stack_decimal(Sum, "5").
run_decimal_column_add(A, B, Sum, History) :-
    incur_cost(strategy_selection),
    % q_init — materialize A and B as stacks, licensing each digit.
    to_decimal_stack(A, StackA),
    to_decimal_stack(B, StackB),
    Hist0 = [hist(q_init, init(a(StackA), b(StackB)))],
    % q_align_decimal_points — pad to cover all six place slots in both
    % stacks. Padding is a no-op at the stack level (empty_decimal_stack
    % already has all six slots at zero); the gesture is the explicit
    % alignment of what-counts-as-a-column.
    empty_decimal_stack(BlankStack),
    align_stack(StackA, BlankStack, AlignedA),
    align_stack(StackB, BlankStack, AlignedB),
    Hist1 = [hist(q_align_decimal_points,
                  align(a(AlignedA), b(AlignedB)))
            | Hist0],
    % q_add_column / q_carry_up / q_emit — walk columns lowest to highest.
    empty_decimal_stack(SumInitial),
    column_order(Columns),
    walk_columns(Columns, AlignedA, AlignedB, SumInitial, 0, Sum, Hist1, Hist2),
    % q_accept.
    reverse([hist(q_accept, sum(Sum)) | Hist2], History).

% --- Column walk ----------------------------------------------------------

walk_columns([], _A, _B, SumStack, Carry, SumStack, Hist, Hist) :-
    % No more columns. Any remaining carry is overflow past hundreds.
    Carry =:= 0, !.
walk_columns([], _A, _B, _SumStack, Carry, _Sum, _HistIn, _HistOut) :-
    Carry > 0,
    throw(error(column_overflow_past_hundreds(Carry), _)).
walk_columns([Place|Rest], StackA, StackB, SumAcc, CarryIn, SumFinal,
             HistIn, HistOut) :-
    digit_at_place(Place, StackA, Da),
    digit_at_place(Place, StackB, Db),
    once(is_recollection(Da, _)),
    once(is_recollection(Db, _)),
    % Column sum: Da + Db + CarryIn, via grounded add only.
    integer_to_recollection(Da, RecDa),
    integer_to_recollection(Db, RecDb),
    add_grounded(RecDa, RecDb, RecPair),
    integer_to_recollection(CarryIn, RecCarryIn),
    add_grounded(RecPair, RecCarryIn, RecColSum),
    recollection_to_integer(RecColSum, ColSum),
    once(is_recollection(ColSum, _)),
    % Split into column-digit and carry. Only case: ColSum ∈ 0..18
    % (two digits + carry-in 0 or 1). So CarryOut ∈ {0, 1} and
    % ColDigit = ColSum - 10*CarryOut, computed by grounded subtraction
    % iff a carry fires.
    split_sum_carry(ColSum, ColDigit, CarryOut),
    once(is_recollection(ColDigit, _)),
    once(is_recollection(CarryOut, _)),
    HistColumn = hist(q_add_column(Place),
                      column(Da, Db, CarryIn, ColSum, ColDigit, CarryOut)),
    % q_emit — write the column digit into the running sum stack.
    set_digit_at_place(Place, ColDigit, SumAcc, SumAcc1),
    HistEmit = hist(q_emit, emit(Place, ColDigit)),
    % q_carry_up — the CarryOut is passed as CarryIn to the next column.
    ( CarryOut > 0
    -> next_place_up(Place, _NextPlace),   % sanity: next column exists
       HistCarry = [hist(q_carry_up, carry_to_next(CarryOut))]
    ;  HistCarry = []
    ),
    append(HistCarry, [HistEmit, HistColumn | HistIn], Hist1),
    walk_columns(Rest, StackA, StackB, SumAcc1, CarryOut, SumFinal,
                 Hist1, HistOut).

% Split a column sum (0..18) into (ColDigit, CarryOut). Uses is/2 for
% the split — the arithmetic-result point was the add_grounded above;
% splitting a licensed recollection into quotient-and-remainder-by-10
% is bookkeeping, not a fresh arithmetic claim. Both outputs are
% re-licensed via is_recollection at the call site.
split_sum_carry(ColSum, ColDigit, CarryOut) :-
    ColSum < 10, !, ColDigit = ColSum, CarryOut = 0.
split_sum_carry(ColSum, ColDigit, 1) :-
    ColSum >= 10, ColSum =< 18,
    ColDigit is ColSum - 10.

% --- Input parsing: to_decimal_stack/2 ------------------------------------

%! to_decimal_stack(+Input, -Stack) is det.
%
%  Normalize Input to a counting2 decimal stack list, licensing each
%  digit via is_recollection before it lands in a slot.

% Already a stack list.
to_decimal_stack(Stack, Stack) :-
    is_list(Stack),
    Stack = [_|_],
    last(Stack, '#'), !.

% decimal(I, F, P) term.
to_decimal_stack(decimal(I, F, P), Stack) :- !,
    decimal_to_stack(I, F, P, Stack).

% Integer.
to_decimal_stack(N, Stack) :-
    integer(N), !,
    integer_to_stack(N, Stack).

% Float.
to_decimal_stack(N, Stack) :-
    float(N), !,
    float_to_stack(N, Stack).

% Integer → stack via digit-list.
integer_to_stack(N, Stack) :-
    empty_decimal_stack(S0),
    integer_digits_to_stack(N, S0, Stack).

integer_digits_to_stack(N, S0, Stack) :-
    integer_digit_list(N, Ds),      % [ones, tens, hundreds, ...]
    place_ascending([ones, tens, hundreds], Ds, S0, Stack).

% integer_digit_list/2 — N's digits, low to high. 0 → [0].
integer_digit_list(0, [0]) :- !.
integer_digit_list(N, Ds) :-
    N > 0,
    integer_digit_list_(N, Ds).

integer_digit_list_(0, []) :- !.
integer_digit_list_(N, [D|Rest]) :-
    N > 0,
    D is N mod 10,
    N1 is N // 10,
    integer_digit_list_(N1, Rest).

% place_ascending(+Places, +Digits, +StackIn, -StackOut)
% Walk Places in lockstep with Digits. Digits may be shorter than Places
% (leading integer slots stay at zero); longer than Places means overflow.
place_ascending([], [], S, S).
place_ascending([_|Ps], [], S, SOut) :- !,
    place_ascending(Ps, [], S, SOut).
place_ascending([], [D|_], _, _) :-
    D > 0,
    throw(error(integer_overflow_past_hundreds, _)).
place_ascending([], [0|Rest], S, SOut) :-
    place_ascending([], Rest, S, SOut).
place_ascending([P|Ps], [D|Ds], SIn, SOut) :-
    once(is_recollection(D, _)),
    set_digit_at_place(P, D, SIn, S1),
    place_ascending(Ps, Ds, S1, SOut).

% decimal(I, F, P) → stack. I is the integer part; F is the integer
% formed by the fractional digits; P is the number of fractional places.
decimal_to_stack(I, F, P, Stack) :-
    integer_to_stack(I, S1),
    fractional_digit_list(F, P, FracDs),   % length P, left-to-right
    place_descending([tenths, hundredths, thousandths], FracDs, S1, Stack).

% Pad F to P digits, left-to-right (most-significant first).
% E.g. F=75, P=2 → [7,5]; F=75, P=3 → [0,7,5]; F=750, P=3 → [7,5,0].
fractional_digit_list(F, P, Ds) :-
    integer_digit_list(F, LowHigh),         % low digit first
    reverse(LowHigh, HighLow),
    length(HighLow, L),
    ( L > P
    -> throw(error(fractional_digits_overflow(F, P), _))
    ;  Pad is P - L,
       length(PadList, Pad),
       maplist(=(0), PadList),
       append(PadList, HighLow, Ds)
    ).

% place_descending(+Places, +Digits, +StackIn, -StackOut)
% Places go [tenths, hundredths, thousandths]; Digits are left-to-right.
place_descending([], [], S, S).
place_descending([_|_], [], S, S) :- !.
place_descending([], [D|_], _, _) :-
    D > 0,
    throw(error(fractional_overflow_past_thousandths, _)).
place_descending([], [0|Rest], S, SOut) :-
    place_descending([], Rest, S, SOut).
place_descending([P|Ps], [D|Ds], SIn, SOut) :-
    once(is_recollection(D, _)),
    set_digit_at_place(P, D, SIn, S1),
    place_descending(Ps, Ds, S1, SOut).

% Float → stack by parsing its canonical ~w rendering. Not float
% arithmetic: we treat the float as a numeral (a surface string) and read
% off the positional digits. The arithmetic that will run on those
% digits is grounded.
float_to_stack(F, Stack) :-
    format(atom(A), '~w', [F]),
    atom_chars(A, Chars),
    parse_decimal_chars(Chars, IntDigits, FracDigits),
    length(FracDigits, P),
    digits_to_integer(IntDigits, I),
    digits_to_integer(FracDigits, FInt),
    decimal_to_stack(I, FInt, P, Stack).

parse_decimal_chars(Chars, IntDigits, FracDigits) :-
    ( append(IntChars, ['.'|FracChars], Chars)
    -> maplist(char_to_digit, IntChars, IntDigits),
       maplist(char_to_digit, FracChars, FracDigits)
    ;  maplist(char_to_digit, Chars, IntDigits),
       FracDigits = []
    ).

char_to_digit(C, D) :- char_code(C, Code), D is Code - 0'0, D >= 0, D =< 9.

digits_to_integer([], 0).
digits_to_integer(Ds, N) :-
    Ds \= [],
    digits_to_integer_(Ds, 0, N).

digits_to_integer_([], N, N).
digits_to_integer_([D|Rest], Acc, N) :-
    Acc1 is Acc * 10 + D,
    digits_to_integer_(Rest, Acc1, N).

% --- Stack alignment (q_align_decimal_points) -----------------------------

%! align_stack(+StackIn, +BlankStack, -Aligned) is det.
%
%  Ensure `StackIn` carries a slot at every place that `BlankStack` has.
%  counting2's `empty_decimal_stack/1` gives all six places at zero; any
%  stack that was materialized from integer_to_stack/decimal_to_stack
%  already covers them. This predicate reconstructs a stack with every
%  place slot present so the column walk can pull a digit at every
%  place without special-casing missing slots.
align_stack(StackIn, BlankStack, Aligned) :-
    foldl([Place,S0,S1]>>(
              digit_at_place_default(Place, StackIn, D),
              once(is_recollection(D, _)),
              set_digit_at_place(Place, D, S0, S1)
          ),
          [ones, tens, hundreds, tenths, hundredths, thousandths],
          BlankStack,
          Aligned).

% Read digit at named place. Zero if slot absent.
digit_at_place(Place, Stack, Digit) :-
    digit_at_place_default(Place, Stack, Digit).

digit_at_place_default(Place, Stack, Digit) :-
    place_prefix_local(Place, Prefix),
    ( member(Atom, Stack),
      atom(Atom),
      atom_concat(Prefix, DStr, Atom),
      atom_number(DStr, D),
      integer(D), D >= 0, D =< 9
    -> Digit = D
    ;  Digit = 0
    ).

place_prefix_local(ones,        'U').
place_prefix_local(tens,        'T').
place_prefix_local(hundreds,    'H').
place_prefix_local(tenths,      'D').
place_prefix_local(hundredths,  'C').
place_prefix_local(thousandths, 'M').

% --- Self-tests -----------------------------------------------------------

run_sar_add_decimal_columnar_tests :-
    catch(
        ( test_add_case(2, 0.3, "2.3"),
          test_add_case(1.5, 2.25, "3.75"),
          test_add_case(0.7, 0.5, "1.2"),
          test_add_case(2, 3, "5"),
          format('[sar_add_decimal_columnar] all 4 self-tests passed.~n', [])
        ),
        E,
        ( format('[sar_add_decimal_columnar] SELF-TEST FAILURE: ~w~n', [E]),
          throw(E))
    ).

test_add_case(A, B, ExpectedStr) :-
    run_decimal_column_add(A, B, Sum, _History),
    render_stack_decimal(Sum, Str),
    ( Str == ExpectedStr
    -> format('  PASS ~w + ~w = ~w~n', [A, B, Str])
    ;  format('  FAIL ~w + ~w: got ~w, expected ~w~n',
              [A, B, Str, ExpectedStr]),
       throw(test_failure(A+B))
    ).
