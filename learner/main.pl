/** <module> Main Entry Point for Command-Line Execution
 *
 * This module provides a simple, non-interactive entry point for running the
 * cognitive modeling system from the command line. It is primarily used for
 * testing and demonstration purposes.
 *
 * When executed, it invokes the ORR (Observe, React, Reorganize) cycle
 * with a predefined goal and prints the final result to the console.
 *
 * 
 * 
 */
:- use_module(execution_handler).
:- ensure_loaded(primordial_start).

%!      main is det.
%
%       The main predicate for command-line execution.
%
%       It runs a predefined query, `add(5, 5, X)`, using the `run_computation/2`
%       predicate from the `execution_handler`. This triggers the full ORR
%       cycle. After the cycle completes, it prints the final result for `X`
%       and halts the Prolog system. The number 5 is represented using
%       Peano arithmetic (`s(s(s(s(s(0)))))`).
main :-
    % Use a reasonable inference step limit so the ORR cycle can trigger
    % reorganization if resource exhaustion occurs.
    Limit = 30,
    Goal = add(s(s(s(s(s(0))))), s(s(s(s(s(0))))), X),
    execution_handler:run_computation(Goal, Limit),
    format('Final Result (may be unbound if not solved): ~w~n', [X]),
    halt.

% This directive makes it so that running the script from the command line
% will automatically call the main/0 predicate.
:- initialization(main, main).
