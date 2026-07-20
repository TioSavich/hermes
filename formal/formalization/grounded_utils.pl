/** <module> Grounded Number Utilities
 *
 * This module provides utility predicates for working with numbers in
 * grounded arithmetic without using Prolog's built-in arithmetic operators.
 * It supports the transition from integer-based strategies to recollection-based
 * representations.
 *
 * @author UMEDCA System
 * 
 */
:- module(grounded_utils, [
    % Decomposition operations (for base-10 strategies)
    decompose_base10/3,
    decompose_to_peano/3,
    base_decompose_grounded/4,
    base_recompose_grounded/4,

    % Embodied operations
    count_down_by/3,
    count_up_by/3,

    % Grounded comparisons
    is_zero_grounded/1,
    is_positive_grounded/1,

    % Peano utilities
    peano_to_recollection/2,
    recollection_to_peano/2,

    % Recollection structural utilities
    predecessor_rec/2
]).

:- use_module(grounded_arithmetic).

% --- Recollection structural utilities ---

%!  predecessor_rec(+Rec, -PredRec) is semidet.
%
%   Structural predecessor on the recollection/1 list representation:
%   strip one leading element. Previously redefined identically in three
%   standards/indiana/*.pl files; consolidated here per predicate
%   carving (formal/tools/carving/predicate_carving.py).
predecessor_rec(recollection([_|H]), recollection(H)).

% --- Base-10 Decomposition ---

%!      decompose_base10(+Number, -Bases, -Ones) is det.
%
%       Decomposes a recollection into base-10 components without using arithmetic.
%       This is done by grouping tallies into groups of 10.
decompose_base10(recollection(History), recollection(Bases), recollection(Ones)) :-
    incur_cost(inference),
    group_by_tens(History, BasesHistory, OnesHistory),
    Bases = BasesHistory,
    Ones = OnesHistory.

% Helper to group tallies into tens
group_by_tens(History, Bases, Ones) :-
    group_by_tens_helper(History, [], Bases, Ones).

group_by_tens_helper([], Acc, Acc, []).
group_by_tens_helper(History, Acc, Bases, Ones) :-
    ( take_ten(History, Ten, Rest) ->
        group_by_tens_helper(Rest, [Ten|Acc], Bases, Ones)
    ;
        Ones = History,
        Bases = Acc
    ).

% Take exactly 10 tallies if available
take_ten([tally,tally,tally,tally,tally,tally,tally,tally,tally,tally|Rest], 
         [tally,tally,tally,tally,tally,tally,tally,tally,tally,tally], Rest).

%!      base_decompose_grounded(+Number, +Base, -BasesPart, -Remainder) is det.
%
%       Decomposes a number into base components without using arithmetic division.
%       For base-10, this separates tens from ones using grounded operations.
base_decompose_grounded(recollection(History), recollection(BaseHistory), recollection(BasesHistory), recollection(RemainderHistory)) :-
    % Count how many complete base groups are in the number
    count_base_groups_grounded(History, BaseHistory, [], BaseCount),
    BasesHistory = BaseCount,
    
    % Calculate remainder by subtracting all complete base groups
    multiply_base_by_count_grounded(BaseHistory, BaseCount, TotalBasesHistory),
    subtract_histories_grounded(History, TotalBasesHistory, RemainderHistory).

% Helper to count how many complete base groups fit in the history (grounded version)
count_base_groups_grounded(History, BaseHistory, Acc, Count) :-
    ( can_subtract_base_grounded(History, BaseHistory, Rest) ->
        append(Acc, [tally], NewAcc),
        count_base_groups_grounded(Rest, BaseHistory, NewAcc, Count)
    ;
        Count = Acc
    ).

% Check if we can subtract a base group from the history (grounded version)
can_subtract_base_grounded(History, BaseHistory, Rest) :-
    append(BaseHistory, Rest, History).

% Multiply base by count to get total bases (grounded version)
multiply_base_by_count_grounded(_, [], []).
multiply_base_by_count_grounded(BaseHistory, [_|CountRest], Result) :-
    multiply_base_by_count_grounded(BaseHistory, CountRest, Rest),
    append(BaseHistory, Rest, Result).

% Subtract one history from another (grounded version)
subtract_histories_grounded(History1, History2, Result) :-
    append(History2, Result, History1).

%!      base_recompose_grounded(+BasesPart, +Remainder, +Base, -Result) is det.
%
%       Recomposes a number from base components without using arithmetic multiplication.
base_recompose_grounded(recollection(BasesHistory), recollection(RemainderHistory), recollection(BaseHistory), recollection(ResultHistory)) :-
    % Multiply bases by base value
    multiply_histories(BasesHistory, BaseHistory, BasesValueHistory),
    % Add remainder
    append(BasesValueHistory, RemainderHistory, ResultHistory).

% Multiply two histories (repeated addition)
multiply_histories([], _, []).
multiply_histories([_|Rest], BaseHistory, Result) :-
    multiply_histories(Rest, BaseHistory, RestResult),
    append(BaseHistory, RestResult, Result).

%!      decompose_to_peano(+Number, -Bases, -Ones) is det.
%
%       Decomposes a Peano number into base-10 components.
%       Converts to recollection, decomposes, then back to Peano.
decompose_to_peano(PeanoNum, PeanoBases, PeanoOnes) :-
    peano_to_recollection(PeanoNum, Recollection),
    decompose_base10(Recollection, RecollectionBases, RecollectionOnes),
    recollection_to_peano(RecollectionBases, PeanoBases),
    recollection_to_peano(RecollectionOnes, PeanoOnes).

% --- Grounded Operations ---

%!      count_down_by(+Start, +Amount, -Result) is semidet.
%
%       Counts down from Start by Amount without using arithmetic.
count_down_by(Start, Amount, Result) :-
    grounded_arithmetic:subtract_grounded(Start, Amount, Result).

%!      count_up_by(+Start, +Amount, -Result) is det.
%
%       Counts up from Start by Amount without using arithmetic.
count_up_by(Start, Amount, Result) :-
    grounded_arithmetic:add_grounded(Start, Amount, Result).

%!      is_zero_grounded(+Number) is semidet.
%
%       Tests if a number is zero without using arithmetic comparison.
is_zero_grounded(recollection([])).
is_zero_grounded(0).  % Peano zero

%!      is_positive_grounded(+Number) is semidet.
%
%       Tests if a number is positive without using arithmetic comparison.
is_positive_grounded(recollection([_|_])).
is_positive_grounded(s(_)).  % Peano successor

% --- Peano-Recollection Conversion ---

%!      peano_to_recollection(+Peano, -Recollection) is det.
%
%       Converts Peano representation to recollection structure.
peano_to_recollection(0, recollection([])).
peano_to_recollection(s(N), recollection([tally|History])) :-
    peano_to_recollection(N, recollection(History)).

%!      recollection_to_peano(+Recollection, -Peano) is det.
%
%       Converts recollection structure to Peano representation.
recollection_to_peano(recollection([]), 0).
recollection_to_peano(recollection([tally|History]), s(N)) :-
    recollection_to_peano(recollection(History), N).