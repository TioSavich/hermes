/** <module> Grounded Arithmetic Operations
 *
 * This module implements arithmetic operations without relying on Prolog's
 * built-in arithmetic operators. All operations are grounded in embodied
 * practice and work with recollection structures that represent the history
 * of counting actions.
 *
 * This implements the UMEDCA thesis that "Numerals are Pronouns" - numbers
 * are anaphoric recollections of the act of counting, not abstract entities.
 * 
 * All operations emit cognitive cost signals to support embodied learning.
 *
 * @author UMEDCA System
 * 
 */
:- module(grounded_arithmetic, [
    % Core grounded operations
    add_grounded/3,
    subtract_grounded/3,
    multiply_grounded/3,
    divide_grounded/3,

    % Comparison operations
    smaller_than/2,
    greater_than/2,
    equal_to/2,

    % Utility predicates
    successor/2,
    predecessor/2,
    zero/1,

    % Place-value operations
    leading_place_value/3,
    leading_digit_chunk/3,
    integer_to_digit_list/2,
    integer_to_digit_list/3,

    % Conversion predicates (for interfacing with existing code during transition)
    integer_to_recollection/2,
    recollection_to_integer/2,

    % Cognitive cost support
    incur_cost/1,
    direct_cost_accumulated/1,
    reset_direct_cost_accumulator/0
]).

% --- Core Representations ---

%!      zero(?Recollection) is det.
%
%       Defines the recollection structure for zero - an empty counting history.
zero(recollection([])).

%!      successor(+Recollection, -NextRecollection) is det.
%
%       Implements the successor operation by adding one more tally to the history.
%       This is the embodied act of counting one more.
successor(recollection(History), recollection([tally|History])) :-
    incur_cost(unit_count).

%!      predecessor(+Recollection, -PrevRecollection) is det.
%
%       Implements the predecessor operation by removing one tally.
%       Fails for zero (cannot count backwards from nothing).
predecessor(recollection([tally|History]), recollection(History)) :-
    incur_cost(unit_count).

% --- Comparison Operations ---

%!      smaller_than(+A, +B) is semidet.
%
%       A is smaller than B if A's history is a proper prefix of B's history.
%       This captures the embodied intuition of "having counted fewer times."
smaller_than(recollection(HistoryA), recollection(HistoryB)) :-
    append(HistoryA, Suffix, HistoryB),
    Suffix \= [],
    incur_cost(inference).

%!      greater_than(+A, +B) is semidet.
%
%       A is greater than B if B is smaller than A.
greater_than(A, B) :-
    smaller_than(B, A).

%!      equal_to(+A, +B) is semidet.
%
%       Two recollections are equal if they have the same counting history.
equal_to(recollection(History), recollection(History)) :-
    incur_cost(inference).

% --- Core Arithmetic Operations ---

%!      add_grounded(+A, +B, -Sum) is det.
%
%       Addition is the concatenation of two counting histories.
%       This represents the embodied act of "counting on" from A by B more.
add_grounded(recollection(HistoryA), recollection(HistoryB), recollection(HistorySum)) :-
    incur_cost(inference),
    append(HistoryA, HistoryB, HistorySum).

%!      subtract_grounded(+Minuend, +Subtrahend, -Difference) is semidet.
%
%       Subtraction removes a counting history from another.
%       Fails if trying to subtract more than is present (embodied constraint).
subtract_grounded(recollection(HistoryM), recollection(HistoryS), recollection(HistoryDiff)) :-
    incur_cost(inference),
    append(HistoryDiff, HistoryS, HistoryM).

%!      multiply_grounded(+A, +B, -Product) is det.
%
%       Multiplication is repeated addition - adding A to itself B times.
%       This captures the embodied understanding of multiplication as iteration.
multiply_grounded(_A, recollection([]), Zero) :-
    zero(Zero),
    incur_cost(inference).

multiply_grounded(A, B, Product) :-
    B \= recollection([]),
    predecessor(B, BPrev),
    multiply_grounded(A, BPrev, PartialProduct),
    add_grounded(PartialProduct, A, Product).

%!      divide_grounded(+Dividend, +Divisor, -Quotient) is semidet.
%
%       Division is repeated subtraction - how many times can we subtract Divisor from Dividend.
%       Fails if Divisor is zero (embodied constraint).
divide_grounded(Dividend, Divisor, Quotient) :-
    \+ zero(Divisor),
    divide_helper(Dividend, Divisor, recollection([]), Quotient).

% Helper for division by repeated subtraction
divide_helper(Remainder, Divisor, AccQuotient, Quotient) :-
    ( subtract_grounded(Remainder, Divisor, NewRemainder) ->
        successor(AccQuotient, NewAccQuotient),
        divide_helper(NewRemainder, Divisor, NewAccQuotient, Quotient)
    ;
        Quotient = AccQuotient
    ).

% --- Place-Value Operations ---
%
% These replace the transcendental log/^ shortcut used in chunking strategies.
% A child who has counted through 0-999 knows that 234 "starts with hundreds"
% because 100 <= 234 < 1000. They don't compute floor(log10(234)) = 2.
% They count up through place values: ones, tens, hundreds... stop when
% the next place would overshoot. That's what these predicates do.
%
% The gear here is the same gear as the DPDA carry mechanism in counting2.pl:
% each time you overflow a place (units wrapping past 9 to tens), you've
% discovered a new place value. This predicate counts those carries.

%!  leading_place_value(+N:integer, +Base:integer, -PlaceValue:integer) is det.
%
%   Finds the largest power of Base that is <= N.
%   Grounded equivalent of Base^floor(log_Base(N)).
%
%   Example: leading_place_value(234, 10, 100).
%   The child counts: 1... 10... 100... 1000 is too big. So 100.
%
leading_place_value(N, Base, PlaceValue) :-
    N > 0,
    leading_place_value_(N, Base, 1, PlaceValue).

leading_place_value_(N, Base, Current, PlaceValue) :-
    Next is Current * Base,
    (   Next > N
    ->  PlaceValue = Current
    ;   incur_cost(inference),
        leading_place_value_(N, Base, Next, PlaceValue)
    ).

%!  leading_digit_chunk(+N:integer, +Base:integer, -Chunk:integer) is det.
%
%   Computes the leading-digit chunk of N in the given Base.
%   This is what chunking strategies need: given 234 in base 10,
%   returns 200 (the leading digit times its place value).
%
%   Grounded equivalent of floor(N / Base^floor(log_Base(N))) * Base^floor(log_Base(N)).
%
%   Example: leading_digit_chunk(234, 10, 200).
%
leading_digit_chunk(N, Base, Chunk) :-
    leading_place_value(N, Base, PV),
    Chunk is (N // PV) * PV.

%!  integer_to_digit_list(+N:integer, -Digits:list) is det.
%
%   Decimal compatibility wrapper for integer_to_digit_list/3.
integer_to_digit_list(N, Digits) :-
    integer_to_digit_list(N, 10, Digits).

%!  integer_to_digit_list(+N:integer, +Base:integer, -Digits:list) is det.
%
%   Left-to-right digit-value list of a non-negative integer in Base.
%   Used by long-division automata to peel off dividend digits one at a time.
%
%   Example: integer_to_digit_list(1234, [1,2,3,4]).
%            integer_to_digit_list(49, 7, [1,0,0]).
integer_to_digit_list(0, Base, [0]) :-
    integer(Base), Base >= 2,
    !.
integer_to_digit_list(N, Base, Digits) :-
    integer(N), N > 0,
    integer(Base), Base >= 2,
    integer_to_digit_list_(N, Base, [], Digits).

integer_to_digit_list_(0, _Base, Acc, Acc) :- !.
integer_to_digit_list_(N, Base, Acc, Digits) :-
    D is N mod Base,
    Rest is N div Base,
    integer_to_digit_list_(Rest, Base, [D|Acc], Digits).

% --- Conversion Utilities (for transition period) ---

%!      integer_to_recollection(+Integer, -Recollection) is det.
%
%       Converts a Prolog integer to a recollection structure.
%       Used during the transition period to interface with existing code.
integer_to_recollection(0, recollection([])) :- !.
integer_to_recollection(N, recollection(History)) :-
    N > 0,
    length(History, N),
    maplist(=(tally), History).

%!      recollection_to_integer(+Recollection, -Integer) is det.
%
%       Converts a recollection structure back to a Prolog integer.
%       Used during the transition period for compatibility.
recollection_to_integer(recollection(History), Integer) :-
    length(History, Integer).

% --- Cognitive Cost Support ---

%!      incur_cost(+Action) is det.
%
%       Records the cognitive cost of an embodied action.
%
%       When the goal is routed through learner/meta_interpreter.pl:solve/6,
%       the meta-interpreter intercepts this call, looks up the cost in
%       learner:config:cognitive_cost/2, applies the modal-context multiplier,
%       and decrements the interpreter's inference budget directly. The
%       grounded_arithmetic:incur_cost/1 body below is only reached for
%       *direct* callers — principally the FSM automata in strategies/math/,
%       which run outside the meta-interpreter and would otherwise leave
%       the cost unaccounted-for.
%
%       Fix landed 2026-04-16 after the Phase 5 audit flagged that direct
%       calls were hitting a `true` body (a no-op). See
%       `docs/phase5/fact-sheet-formalization.md` §What the module does NOT do
%       for the pre-fix state.

:- dynamic(direct_cost_accumulator/1).
direct_cost_accumulator(0).

incur_cost(Action) :-
    cost_for_action(Action, Cost),
    retract(direct_cost_accumulator(Current)),
    New is Current + Cost,
    assertz(direct_cost_accumulator(New)).

%!      cost_for_action(+Action:atom, -Cost:number) is det.
%
%       Local copy of the cost table. Kept in sync with learner/config.pl's
%       cognitive_cost/2. If the learner's config is loaded on the same
%       Prolog instance, its table wins; otherwise the local_cost/2 fallback
%       applies. Drift between the two tables is a risk flagged in the
%       fact-sheet; the canonical values live in learner/config.pl.
cost_for_action(Action, Cost) :-
    (   config_cost_for_action(Action, C)
    ->  Cost = C
    ;   once(local_cost(Action, Cost))
    ).

config_cost_for_action(Action, Cost) :-
    config:current_predicate(cognitive_cost/2),
    functor(Goal, cognitive_cost, 2),
    arg(1, Goal, Action),
    arg(2, Goal, Cost),
    catch(@(Goal, config), _, fail).

local_cost(inference,         1).
local_cost(unit_count,        5).
local_cost(slide_step,        2).
local_cost(fact_retrieval,    1).
local_cost(modal_shift,       3).
local_cost(recollection_step, 1).
local_cost(norm_check,        2).
local_cost(ens_partition,     3).
local_cost(ens_disembed,      1).
local_cost(ens_iterate,       2).
local_cost(_,                 1).   % default weight for any unnamed category

%!      direct_cost_accumulated(-Total:number) is det.
%       How much cost the direct accumulator has absorbed since the last
%       reset. Meta-interpreter-routed costs are not visible here; they
%       live in the interpreter's I_Out budget.
direct_cost_accumulated(Total) :-
    direct_cost_accumulator(Total).

%!      reset_direct_cost_accumulator is det.
%       Zero the direct accumulator. Call before starting a fresh
%       automaton run if you want to read off its total cost at the end.
reset_direct_cost_accumulator :-
    retractall(direct_cost_accumulator(_)),
    assertz(direct_cost_accumulator(0)).
