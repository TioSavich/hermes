/** <module> Base-parametric pushdown counter and decimal compatibility stack
 *
 * The integer counter stores the lowest place at the head of an unbounded list.
 * A carry recurses through that list as a stack operation and allocates a new
 * place whenever the existing digits complete a base cycle. Its digit(Value,
 * Glyph) terms are shared with recursive_unit_actions' positional numerals.
 *
 * `run_counter/2` preserves the decimal API, while `run_counter/3` selects any
 * base >= 2. There is no ones/tens/hundreds ceiling in the integer path.
 *
 * ## Decimal extension (structural, not symbolic)
 *
 * The stack encoding is extended downward to cover fractional place-value.
 * A decimal number like `0.75` is represented as the stack
 * `[U0, T0, H0, '.', D7, C5, '#']` — integer region up top, then a
 * structural boundary atom `'.'` (not a syntactic marker but the stack
 * position that separates integer-region overflow-up from fractional-region
 * overflow-up-into-integer), then the fractional region:
 *
 *   * `D0..D9` — tenths
 *   * `C0..C9` — hundredths
 *   * `M0..M9` — thousandths
 *
 * The older long-division and decimal-column automata still use their named
 * decimal slot list. That API remains as an explicit compatibility surface:
 *
 *   * `stack_to_number/2` — read full stack (integer + optional decimal).
 *   * `render_stack_decimal/2` — printable string representation.
 *   * `set_digit_at_place/4` — write a digit at a named place.
 *   * `empty_decimal_stack/1` — a blank all-zero stack with the boundary
 *     in place and decimal slots allocated down to thousandths.
 */
:- module(counting2,
          [ run_counter/2,
            run_counter/3,
            run_counter_numeral/4,
            run_counter_events/4,
            integer_count_stack/3,
            count_stack_value/2,
            count_stack_numeral/2,
            count_stack_transition/4,
            stack_to_number/2,
            render_stack_decimal/2,
            set_digit_at_place/4,
            empty_decimal_stack/1
          ]).

:- use_module(library(lists)).
:- use_module(math(recursive_unit_actions),
              [ integer_numeral/3,
                numeral_integer/2,
                numeral_well_formed/1,
                digit_sign/3
              ]).
:- use_module(formalization(grounded_arithmetic), [integer_to_recollection/2,
                                     recollection_to_integer/2,
                                     add_grounded/3,
                                     multiply_grounded/3]).

%!  run_counter(+N:integer, -FinalValue:integer) is semidet.
%
%   Decimal compatibility wrapper for run_counter/3.
run_counter(N, FinalValue) :-
    run_counter(N, 10, FinalValue).


%!  run_counter(+N:integer, +Base:integer, -FinalValue:integer) is semidet.
run_counter(N, Base, FinalValue) :-
    integer(N), N >= 0,
    integer_count_stack(0, Base, Initial),
    count_steps(N, Initial, FinalStack),
    count_stack_value(FinalStack, FinalValue).


%!  run_counter_numeral(+N, +Base, -Numeral, -Trace) is semidet.
run_counter_numeral(N, Base, Numeral, Trace) :-
    integer(N), N >= 0,
    integer_count_stack(0, Base, Initial),
    count_steps_trace(N, Initial, FinalStack, Trace),
    count_stack_numeral(FinalStack, Numeral).


%!  run_counter_events(+Start, +Events, +Base, -FinalValue) is semidet.
%
%   Execute tick/tock events from a non-negative starting value. Tock from zero
%   fails, preserving the whole-number boundary rather than wrapping underflow.
run_counter_events(Start, Events, Base, FinalValue) :-
    integer(Start), Start >= 0,
    is_list(Events),
    integer_count_stack(Start, Base, Initial),
    count_events(Events, Initial, Final),
    count_stack_value(Final, FinalValue).


%!  integer_count_stack(+Integer, +Base, -Stack) is semidet.
integer_count_stack(Integer, Base, count_stack(Base, LowDigits)) :-
    integer(Integer), Integer >= 0,
    integer_numeral(Integer, Base, Numeral),
    Numeral = numeral(Base, _Sign, _Radix, HighDigits),
    reverse(HighDigits, LowDigits).


%!  count_stack_value(+Stack, -Value) is semidet.
count_stack_value(Stack, Value) :-
    count_stack_numeral(Stack, Numeral),
    numeral_integer(Numeral, Value).


%!  count_stack_numeral(+Stack, -Numeral) is semidet.
count_stack_numeral(count_stack(Base, LowDigits), Numeral) :-
    LowDigits = [_|_],
    reverse(LowDigits, HighDigits),
    length(HighDigits, Radix),
    stack_sign(HighDigits, Sign),
    Numeral = numeral(Base, Sign, radix(Radix), HighDigits),
    numeral_well_formed(Numeral).


%!  count_stack_transition(+Event, +Stack0, -Stack, -Evidence) is semidet.
count_stack_transition(tick, count_stack(Base, Digits0),
                       count_stack(Base, Digits), carry_depth(Depth)) :-
    increment_digits(Digits0, Base, Digits, Depth).
count_stack_transition(tock, count_stack(Base, Digits0),
                       count_stack(Base, Digits), borrow_depth(Depth)) :-
    decrement_digits(Digits0, Base, Digits1, Depth),
    normalize_low_digits(Digits1, Digits).


count_steps(0, Stack, Stack) :- !.
count_steps(Remaining, Stack0, Stack) :-
    Remaining > 0,
    count_stack_transition(tick, Stack0, Stack1, _),
    Next is Remaining - 1,
    count_steps(Next, Stack1, Stack).

count_steps_trace(0, Stack, Stack, []) :- !.
count_steps_trace(Remaining, Stack0, Stack,
                  [count_transition(tick, Stack0, Stack1, Evidence)|Trace]) :-
    Remaining > 0,
    count_stack_transition(tick, Stack0, Stack1, Evidence),
    Next is Remaining - 1,
    count_steps_trace(Next, Stack1, Stack, Trace).

count_events([], Stack, Stack).
count_events([Event|Events], Stack0, Stack) :-
    memberchk(Event, [tick, tock]),
    count_stack_transition(Event, Stack0, Stack1, _),
    count_events(Events, Stack1, Stack).

increment_digits([], Base, [Digit], 0) :-
    make_digit(Base, 1, Digit).
increment_digits([digit(Value, _Glyph)|Rest], Base,
                 [Digit|Rest], 0) :-
    Value < Base - 1,
    !,
    Next is Value + 1,
    make_digit(Base, Next, Digit).
increment_digits([digit(Value, _Glyph)|Rest], Base,
                 [Zero|NextRest], Depth) :-
    Value =:= Base - 1,
    make_digit(Base, 0, Zero),
    increment_digits(Rest, Base, NextRest, InnerDepth),
    Depth is InnerDepth + 1.

decrement_digits([digit(Value, _Glyph)|Rest], Base,
                 [Digit|Rest], 0) :-
    Value > 0,
    !,
    Next is Value - 1,
    make_digit(Base, Next, Digit).
decrement_digits([digit(0, _Glyph)|Rest], Base,
                 [MaxDigit|NextRest], Depth) :-
    Rest = [_|_],
    Max is Base - 1,
    make_digit(Base, Max, MaxDigit),
    decrement_digits(Rest, Base, NextRest, InnerDepth),
    Depth is InnerDepth + 1.

make_digit(Base, Value, digit(Value, Glyph)) :-
    digit_sign(Base, Value, Glyph).

normalize_low_digits(Digits0, Digits) :-
    reverse(Digits0, High0),
    trim_high_zeros(High0, High),
    reverse(High, Digits).

trim_high_zeros([digit(0, _), Next|Rest], High) :-
    !,
    trim_high_zeros([Next|Rest], High).
trim_high_zeros(High, High).

stack_sign(Digits, zero) :-
    maplist(zero_digit, Digits),
    !.
stack_sign(_Digits, positive).

zero_digit(digit(0, _Glyph)).


% =============================================================
% Decimal stack extension (additive; integer behavior above is untouched)
% =============================================================
%
% Place atoms used below:
%   'U0'..'U9'  ones
%   'T0'..'T9'  tens
%   'H0'..'H9'  hundreds
%   '.'          structural boundary (decimal point as stack position)
%   'D0'..'D9'  tenths
%   'C0'..'C9'  hundredths
%   'M0'..'M9'  thousandths
%   '#'          bottom-of-stack marker
%
% The mapping from logical place-name to atom prefix:
place_prefix(ones,        'U').
place_prefix(tens,        'T').
place_prefix(hundreds,    'H').
place_prefix(tenths,      'D').
place_prefix(hundredths,  'C').
place_prefix(thousandths, 'M').

integer_place(ones).
integer_place(tens).
integer_place(hundreds).
fractional_place(tenths).
fractional_place(hundredths).
fractional_place(thousandths).

% Order of integer places in the stack (stack head first):
integer_place_order([ones, tens, hundreds]).
% Order of fractional places (stack head first, after '.'):
fractional_place_order([tenths, hundredths, thousandths]).

% Recognize a slot atom: slot_atom(+Atom, -Place, -Digit)
slot_atom(Atom, Place, Digit) :-
    atom(Atom),
    place_prefix(Place, Prefix),
    atom_concat(Prefix, DStr, Atom),
    atom_number(DStr, Digit),
    integer(Digit),
    Digit >= 0, Digit =< 9.

make_slot(Place, Digit, Atom) :-
    place_prefix(Place, Prefix),
    integer(Digit), Digit >= 0, Digit =< 9,
    atom_concat(Prefix, Digit, Atom).


%!  empty_decimal_stack(-Stack:list) is det.
%
%   The initial quotient buffer used by long division. Integer region
%   goes up to hundreds; fractional region goes down to thousandths.
%   The `'.'` atom is the structural boundary.
empty_decimal_stack(['U0', 'T0', 'H0', '.', 'D0', 'C0', 'M0', '#']).


%!  set_digit_at_place(+Place:atom, +DigitInt:integer, +StackIn:list, -StackOut:list) is det.
%
%   Update StackIn so that the slot for Place holds DigitInt (0..9).
%   If StackIn has no slot for Place, the stack is extended (ones/tens/
%   hundreds for the integer region, or tenths/hundredths/thousandths
%   for the fractional region) preserving the canonical order.
%   The `'.'` boundary is inserted if the first fractional slot is added
%   to a stack that did not yet have one.
set_digit_at_place(Place, Digit, StackIn, StackOut) :-
    place_prefix(Place, _),
    integer(Digit), Digit >= 0, Digit =< 9,
    make_slot(Place, Digit, NewAtom),
    ( integer_place(Place)
    -> set_integer_slot(Place, NewAtom, StackIn, StackOut)
    ;  set_fractional_slot(Place, NewAtom, StackIn, StackOut)
    ).

% Integer region: slots appear before '.' or '#'. Rebuild the integer
% region with the new digit present, preserving any other existing
% integer slots and everything at '.' or '#' and beyond.
set_integer_slot(Place, NewAtom, StackIn, StackOut) :-
    split_stack(StackIn, IntSlotsIn, Tail),
    % Update or allocate the slot in IntSlotsIn.
    integer_place_order(Order),
    rebuild_region(Order, [Place-NewAtom], IntSlotsIn, integer, IntSlotsOut),
    append(IntSlotsOut, Tail, StackOut).

% Fractional region: slots appear after '.'. If there is no '.',
% allocate one (and a fresh fractional region) before '#'.
set_fractional_slot(Place, NewAtom, StackIn, StackOut) :-
    split_stack(StackIn, IntSlots, Tail),
    ( Tail = ['.' | FracAndRest]
    -> % '.' already present; split off fractional slots before '#'
       split_fractional(FracAndRest, FracSlotsIn, BottomRest),
       fractional_place_order(Order),
       rebuild_region(Order, [Place-NewAtom], FracSlotsIn, fractional, FracSlotsOut),
       append(['.'|FracSlotsOut], BottomRest, NewTail),
       append(IntSlots, NewTail, StackOut)
    ;  % No '.' yet; Tail is ['#'] or [].
       fractional_place_order(Order),
       rebuild_region(Order, [Place-NewAtom], [], fractional, FracSlotsOut),
       append(['.'|FracSlotsOut], Tail, NewTail),
       append(IntSlots, NewTail, StackOut)
    ).

% split_stack(+Stack, -IntSlots, -Tail)
% IntSlots = leading slot atoms (U*/T*/H*); Tail = everything from first
% non-integer-slot (i.e. '.' or '#') onward, including that atom.
split_stack([], [], []).
split_stack([A|Rest], [A|IntSlots], Tail) :-
    slot_atom(A, Place, _), integer_place(Place), !,
    split_stack(Rest, IntSlots, Tail).
split_stack([A|Rest], [], [A|Rest]) :-
    ( A == '.' ; A == '#' ), !.

% split_fractional(+Tail, -FracSlots, -BottomRest)
% Tail starts after a '.'. Collect D*/C*/M* atoms until we hit '#'.
split_fractional([], [], []).
split_fractional([A|Rest], [A|FracSlots], BottomRest) :-
    slot_atom(A, Place, _), fractional_place(Place), !,
    split_fractional(Rest, FracSlots, BottomRest).
split_fractional([A|Rest], [], [A|Rest]) :-
    A == '#', !.

% rebuild_region(+Order, +Overrides:list(Place-Atom), +Existing:list(Atom),
%                +Region:atom, -Result:list(Atom))
%
% For each place in Order, emit an atom. Priority: Overrides > Existing.
% Stops at the last non-zero slot in fractional regions to keep the
% stack minimal, but always includes any place explicitly required.
rebuild_region([], _Overrides, _Existing, _Region, []).
rebuild_region([P|Ps], Overrides, Existing, Region, [Atom|Rest]) :-
    ( member(P-Atom, Overrides)
    -> true
    ;  find_existing(P, Existing, Atom)
    -> true
    ;  make_slot(P, 0, Atom)
    ),
    rebuild_region(Ps, Overrides, Existing, Region, Rest).

find_existing(Place, [A|_], A) :-
    slot_atom(A, Place, _), !.
find_existing(Place, [_|Rest], A) :-
    find_existing(Place, Rest, A).


%!  stack_to_number(+Stack:list, -Number) is det.
%
%   Read a full stack (integer region, optional '.' boundary, optional
%   fractional region) and produce either:
%     * an integer (for stacks with no '.'), identical in value to what
%       `stack_to_int/2` would yield;
%     * a term `decimal(IntegerPart, FractionalPart, FractionalPlaces)`
%       where FractionalPart is the integer formed by the fractional
%       digits and FractionalPlaces is the number of fractional slots.
%
%   The representation is unambiguous: `0.75` → `decimal(0, 75, 2)`,
%   `0.075` → `decimal(0, 75, 3)`, `0.750` → `decimal(0, 750, 3)`.
%   The fractional integer is assembled via `add_grounded` and
%   `multiply_grounded` — no `is/2` on the rational value.
stack_to_number(Stack, Number) :-
    split_stack(Stack, IntSlots, Tail),
    integer_part_value(IntSlots, IntVal),
    ( Tail = ['.' | FracAndRest]
    -> split_fractional(FracAndRest, FracSlots, _Bottom),
       fractional_part_value(FracSlots, FracVal, FracPlaces),
       Number = decimal(IntVal, FracVal, FracPlaces)
    ;  Number = IntVal
    ).

% integer_part_value(+IntSlots, -Value)
% Sum each slot's digit × 10^position, via grounded operations.
integer_part_value(IntSlots, Value) :-
    integer_part_value_(IntSlots, 0, 0, Value).

integer_part_value_([], _Pos, Acc, Acc).
integer_part_value_([A|Rest], Pos, Acc, Value) :-
    slot_atom(A, _Place, Digit),
    integer_to_recollection(Digit, RecDigit),
    place_value(Pos, RecPlaceValue),
    grounded_arithmetic:multiply_grounded(RecDigit, RecPlaceValue, RecTerm),
    integer_to_recollection(Acc, RecAcc),
    grounded_arithmetic:add_grounded(RecAcc, RecTerm, RecNew),
    recollection_to_integer(RecNew, NewAcc),
    NextPos is Pos + 1,
    integer_part_value_(Rest, NextPos, NewAcc, Value).

% place_value(+Pos, -Rec) — Pos=0 → 1, Pos=1 → 10, Pos=2 → 100, ...
% Uses multiply_grounded to build 10^Pos.
place_value(0, Rec) :- !, integer_to_recollection(1, Rec).
place_value(Pos, Rec) :-
    Pos > 0,
    Pos1 is Pos - 1,
    place_value(Pos1, RecPrev),
    integer_to_recollection(10, Rec10),
    grounded_arithmetic:multiply_grounded(RecPrev, Rec10, Rec).

% fractional_part_value(+FracSlots, -Value, -Places)
% Places = number of fractional slots.
% Value = integer formed by reading fractional digits left-to-right.
fractional_part_value(FracSlots, Value, Places) :-
    length(FracSlots, Places),
    fractional_part_value_(FracSlots, 0, Value).

fractional_part_value_([], Acc, Acc).
fractional_part_value_([A|Rest], Acc, Value) :-
    slot_atom(A, _Place, Digit),
    integer_to_recollection(Acc, RecAcc),
    integer_to_recollection(10, Rec10),
    grounded_arithmetic:multiply_grounded(RecAcc, Rec10, RecShifted),
    integer_to_recollection(Digit, RecDigit),
    grounded_arithmetic:add_grounded(RecShifted, RecDigit, RecNew),
    recollection_to_integer(RecNew, NewAcc),
    fractional_part_value_(Rest, NewAcc, Value).


%!  render_stack_decimal(+Stack:list, -String:string) is det.
%
%   Produce a human-readable string from a stack. Trailing zeros in the
%   fractional region are trimmed; if the entire fractional region is
%   zero, the decimal point is omitted and the result is an integer
%   string. Leading zeros in the integer region are trimmed (but a bare
%   "0" is preserved).
%
%   Examples:
%     [U0, T0, H0, '#']                  -> "0"
%     [U7, T1, H0, '#']                  -> "17"
%     [U0, T0, H0, '.', D7, C5, '#']     -> "0.75"
%     [U0, T0, H0, '.', D7, C5, M0, '#'] -> "0.75"
%     [U2, T0, H0, '.', D5, '#']        -> "2.5"
render_stack_decimal(Stack, String) :-
    split_stack(Stack, IntSlots, Tail),
    integer_digits_of(IntSlots, IntDigits),
    trim_leading_zeros(IntDigits, IntTrim),
    ( Tail = ['.' | FracAndRest]
    -> split_fractional(FracAndRest, FracSlots, _),
       fractional_digits_of(FracSlots, FracDigits),
       trim_trailing_zeros(FracDigits, FracTrim),
       ( FracTrim = []
       -> digits_to_string(IntTrim, String)
       ;  digits_to_string(IntTrim, IntStr),
          digits_to_string(FracTrim, FracStr),
          string_concat(IntStr, ".", Tmp),
          string_concat(Tmp, FracStr, String)
       )
    ;  digits_to_string(IntTrim, String)
    ).

% IntSlots are stack-order (ones, tens, hundreds); reverse for display.
integer_digits_of(IntSlots, Digits) :-
    maplist(slot_digit, IntSlots, Ds),
    reverse(Ds, Digits).

fractional_digits_of(FracSlots, Digits) :-
    maplist(slot_digit, FracSlots, Digits).

slot_digit(Atom, Digit) :- slot_atom(Atom, _, Digit).

trim_leading_zeros([], [0]).
trim_leading_zeros([D], [D]) :- !.
trim_leading_zeros([0|Rest], Trim) :- !, trim_leading_zeros(Rest, Trim).
trim_leading_zeros(Ds, Ds).

trim_trailing_zeros(Ds, Trim) :-
    reverse(Ds, Rev),
    trim_leading_frac_zeros(Rev, RevTrim),
    reverse(RevTrim, Trim).

trim_leading_frac_zeros([], []).
trim_leading_frac_zeros([0|Rest], Trim) :- !, trim_leading_frac_zeros(Rest, Trim).
trim_leading_frac_zeros(Ds, Ds).

digits_to_string([], "0").
digits_to_string([D|Ds], String) :-
    digits_to_chars([D|Ds], Chars),
    string_chars(String, Chars).

digits_to_chars([], []).
digits_to_chars([D|Ds], [C|Cs]) :-
    atom_number(A, D), atom_chars(A, [C]),
    digits_to_chars(Ds, Cs).


% =============================================================
% Self-tests for the decimal stack extension
% =============================================================

run_counting2_decimal_tests :-
    catch(
        ( test_stack_number([ 'U0','T0','H0','#' ], 0,
                            "0"),
          test_stack_number([ 'U7','T1','H0','#' ], 17,
                            "17"),
          test_stack_number([ 'U0','T0','H0','.', 'D0','C0','M0','#' ],
                            decimal(0, 0, 3), "0"),
          test_stack_number([ 'U0','T0','H0','.', 'D5','#' ],
                            decimal(0, 5, 1), "0.5"),
          test_stack_number([ 'U0','T0','H0','.', 'D7','C5','#' ],
                            decimal(0, 75, 2), "0.75"),
          test_stack_number([ 'U2','T0','H0','.', 'D5','#' ],
                            decimal(2, 5, 1), "2.5"),
          test_stack_number([ 'U3','T0','H0','.', 'D1','C4','#' ],
                            decimal(3, 14, 2), "3.14"),
          test_set_digit,
          test_empty_decimal_stack,
          format('[counting2] decimal-stack self-tests passed (9).~n', [])
        ),
        E,
        ( format('[counting2] SELF-TEST FAILURE: ~w~n', [E]), throw(E))
    ).

test_stack_number(Stack, ExpectedNum, ExpectedStr) :-
    stack_to_number(Stack, Num),
    ( Num == ExpectedNum
    -> true
    ;  format('  FAIL stack_to_number ~w: got ~w, expected ~w~n',
              [Stack, Num, ExpectedNum]),
       throw(test_failure(stack_to_number(Stack)))
    ),
    render_stack_decimal(Stack, Str),
    ( Str == ExpectedStr
    -> format('  PASS ~w -> ~w  (~w)~n', [Stack, Num, Str])
    ;  format('  FAIL render_stack_decimal ~w: got ~w, expected ~w~n',
              [Stack, Str, ExpectedStr]),
       throw(test_failure(render_stack_decimal(Stack)))
    ).

test_set_digit :-
    empty_decimal_stack(S0),
    set_digit_at_place(tenths, 7, S0, S1),
    set_digit_at_place(hundredths, 5, S1, S2),
    render_stack_decimal(S2, Str),
    ( Str == "0.75"
    -> format('  PASS set_digit (tenths=7, hundredths=5) -> "0.75"~n', [])
    ;  format('  FAIL set_digit: got ~w, expected "0.75"~n', [Str]),
       throw(test_failure(set_digit))
    ),
    set_digit_at_place(ones, 2, S2, S3),
    render_stack_decimal(S3, Str2),
    ( Str2 == "2.75"
    -> format('  PASS set_digit (ones=2 onto 0.75) -> "2.75"~n', [])
    ;  format('  FAIL set_digit ones: got ~w~n', [Str2]),
       throw(test_failure(set_digit_ones))
    ).

test_empty_decimal_stack :-
    empty_decimal_stack(S),
    ( S == ['U0','T0','H0','.','D0','C0','M0','#']
    -> format('  PASS empty_decimal_stack~n', [])
    ;  format('  FAIL empty_decimal_stack: got ~w~n', [S]),
       throw(test_failure(empty_decimal_stack))
    ).
