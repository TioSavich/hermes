/** <module> Bidirectional compatibility wrapper over the recursive count stack
 *
 * Counting forward and backward uses counting2's base-parametric stack. The
 * public run_counter/3 predicate keeps its historical decimal behavior;
 * run_counter/4 makes the operative base explicit. Carry and borrow therefore
 * share one implementation and neither is limited to hundreds.
 */

:- module(counting_on_back,
          [ run_counter/3,
            run_counter/4
          ]).

:- use_module(math(counting2), [run_counter_events/4]).


%!  run_counter(+Start, +Events, -FinalValue) is semidet.
%
%   Decimal compatibility wrapper for run_counter/4.
run_counter(Start, Events, FinalValue) :-
    run_counter(Start, Events, 10, FinalValue).


%!  run_counter(+Start, +Events, +Base, -FinalValue) is semidet.
run_counter(Start, Events, Base, FinalValue) :-
    run_counter_events(Start, Events, Base, FinalValue).
