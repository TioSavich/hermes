/** <module> Crisis Processor
 *
 * Monitors cognitive crisis and reorganization when system hits
 * inference limits and computational thresholds
 */

:- module(crisis_processor, [
    process_crisis_curriculum/1,
    run_crisis_demo/0
]).

:- use_module(curriculum_processor, [process_task/1]).
:- use_module(reorganization_engine, [reorganize_system/2]).
:- use_module(config, [max_inferences/1, cognitive_cost/2]).
:- use_module(execution_handler, [run_computation/2]).
:- use_module(meta_interpreter, [solve/4]).
:- use_module(peano_utils, [int_to_peano/2]).
% Import specific strategies directly to avoid conflicts
:- use_module(math(sar_add_chunking), [run_chunking/4]).
:- use_module(math(smr_mult_c2c), [run_c2c/4]).

% Monitor inference costs and crisis points
:- dynamic(inference_crisis/3).
:- dynamic(reorganization_event/4).
:- dynamic(strategy_change/3).
:- discontiguous process_task_with_monitoring/1.

% Use config.pl max_inferences directly - no custom tracking needed

process_crisis_curriculum(File) :-
    writeln(''),
    writeln('COGNITIVE CRISIS AND REORGANIZATION DEMONSTRATION'),
    writeln('=' * 55),
    writeln('Testing system behavior at inference limits'),
    writeln(''),
    reset_crisis_monitoring,
    open(File, read, Stream),
    process_crisis_lines(Stream),
    close(Stream),
    analyze_reorganization_events.

reset_crisis_monitoring :-
    retractall(inference_crisis(_, _, _)),
    retractall(reorganization_event(_, _, _, _)),
    retractall(strategy_change(_, _, _)).

process_crisis_lines(Stream) :-
    read_line_to_string(Stream, Line),
    (   Line == end_of_file
    ->  true
    ;   (   string_concat('#', _, Line)  % Skip comments
        ->  true
        ;   Line == ""  % Skip empty lines
        ->  true
        ;   parse_and_monitor_crisis(Line)
        ),
        process_crisis_lines(Stream)
    ).

parse_and_monitor_crisis(Line) :-
    atom_string(_Atom, Line),
    (   catch(term_string(Term, Line), _, fail)
    ->  format('~nProcessing crisis task: ~w~n', [Term]),
        monitor_task_execution(Term)
    ;   format('Could not parse crisis task: ~w~n', [Line])
    ).

monitor_task_execution(Task) :-
    get_time(StartTime),
    (   catch(
            process_task_with_monitoring(Task),
            Error,
            handle_crisis_error(Task, Error)
        )
    ->  get_time(EndTime),
        ExecutionTime is EndTime - StartTime,
        check_for_crisis_indicators(Task, ExecutionTime)
    ;   record_crisis_failure(Task)
    ).

process_task_with_monitoring(count(N)) :-
    % Use proper meta-interpreter with inference limits
    max_inferences(Limit),
    % Convert to Peano representation for meta-interpreter
    int_to_peano(N, PeanoN),
    Goal = count(PeanoN),
    (   catch(
            meta_interpreter:solve(Goal, Limit, _, Trace),
            perturbation(resource_exhaustion),
            (format('   INFERENCE CRISIS: count(~w) exceeded ~w-step limit~n', [N, Limit]),
             assertz(inference_crisis(count(N), resource_exhaustion, Limit)),
             fail)
        )
    ->  format('   SUCCESS: count(~w) completed within limits~n', [N]),
        % Extract result and store as learned fact  
        assertz(learned_fact(count(N), meta_result(Trace)))
    ;   % Crisis detected - attempt reorganization
        format('   ATTEMPTING REORGANIZATION: count(~w) hit inference limit~n', [N]),
        check_reorganization_response(count(N)),
        attempt_chunking_count(N)
    ).

process_task_with_monitoring(add(A, B)) :-
    % Use proper meta-interpreter with inference limits
    max_inferences(Limit),
    % Convert to Peano representation
    int_to_peano(A, PeanoA),
    int_to_peano(B, PeanoB),
    Goal = add(PeanoA, PeanoB, _Result),
    (   catch(
            meta_interpreter:solve(Goal, Limit, _, Trace),
            perturbation(resource_exhaustion),
            (format('   INFERENCE CRISIS: add(~w,~w) exceeded ~w-step limit~n', [A, B, Limit]),
             assertz(inference_crisis(add(A, B), resource_exhaustion, Limit)),
             fail)
        )
    ->  format('   SUCCESS: add(~w,~w) completed within limits~n', [A, B]),
        assertz(learned_fact(add(A, B), meta_result(Trace)))
    ;   % Crisis detected - attempt reorganization  
        format('   ATTEMPTING REORGANIZATION: add(~w,~w) hit inference limit~n', [A, B]),
        attempt_chunking_addition(A, B)
    ).

process_task_with_monitoring(multiply(A, B)) :-
    % Use proper meta-interpreter with inference limits
    max_inferences(Limit),
    % Convert to Peano representation
    int_to_peano(A, PeanoA),
    int_to_peano(B, PeanoB),
    Goal = multiply(PeanoA, PeanoB, _Result),
    (   catch(
            meta_interpreter:solve(Goal, Limit, _, Trace),
            perturbation(resource_exhaustion),
            (format('   INFERENCE CRISIS: multiply(~w,~w) exceeded ~w-step limit~n', [A, B, Limit]),
             assertz(inference_crisis(multiply(A, B), resource_exhaustion, Limit)),
             fail)
        )
    ->  format('   SUCCESS: multiply(~w,~w) completed within limits~n', [A, B]),
        assertz(learned_fact(multiply(A, B), meta_result(Trace)))
    ;   % Crisis detected - attempt reorganization
        format('   ATTEMPTING REORGANIZATION: multiply(~w,~w) hit inference limit~n', [A, B]),
        attempt_strategic_multiplication(A, B)
    ).

process_task_with_monitoring(Task) :-
    % Fallback for other tasks - use regular processing
    process_task(Task).

handle_crisis_error(Task, Error) :-
    format('   CRISIS ERROR in ~w: ~w~n', [Task, Error]),
    assertz(inference_crisis(Task, error, Error)).

check_for_crisis_indicators(Task, ExecutionTime) :-
    (   ExecutionTime > 5.0
    ->  format('   PERFORMANCE CRISIS: Task ~w took ~2f seconds~n', [Task, ExecutionTime]),
        assertz(inference_crisis(Task, performance, ExecutionTime))
    ;   true
    ).

check_reorganization_response(Task) :-
    % Check if system shows signs of reorganization
    % This would detect if the system switches strategies
    format('   Checking for reorganization response to ~w~n', [Task]),
    
    % Add stress to trigger reorganization engine (simple version)
    assertz(conceptual_stress(Task, high)),
    
    % Attempt to trigger reorganization
    (   catch(reorganize_system(Task, []), Error, 
             (format('   REORGANIZATION ERROR: ~w~n', [Error]), fail))
    ->  format('   REORGANIZATION SUCCESS: System adapted strategy~n'),
        assertz(reorganization_event(Task, strategy_switch, tally_counting, strategic_chunking))
    ;   format('   REORGANIZATION ATTEMPT: Traditional mechanisms tried~n'),
        assertz(reorganization_event(Task, attempted, tally_counting, none))
    ).

% New reorganization strategies for large counts
attempt_chunking_count(N) :-
    format('   CHUNKING COUNT: Breaking ~w into manageable chunks~n', [N]),
    % Use base-10 chunking: 157 = 100 + 50 + 7
    Hundreds is N // 100,
    Remainder1 is N mod 100,
    Tens is Remainder1 // 10,
    Ones is Remainder1 mod 10,
    
    format('   CHUNKED: ~w = ~w×100 + ~w×10 + ~w×1~n', [N, Hundreds, Tens, Ones]),
    
    % Build result through chunking rather than massive tally
    ChunkedResult = chunked_count(hundreds(Hundreds), tens(Tens), ones(Ones)),
    assertz(learned_fact(count(N), ChunkedResult)),
    format('   SUCCESS: Learned chunked representation for ~w~n', [N]).

attempt_chunking_addition(A, B) :-
    format('   CHUNKING ADDITION: Using base decomposition for ~w + ~w~n', [A, B]),
    % Use chunking strategy instead of massive tally concatenation
    
    % Try to use existing chunking strategy through meta-interpreter (subject to limits)
    config:max_inferences(Limit),
    (   catch(meta_interpreter:solve(run_chunking(A, B, Result, _History), Limit, _, _), 
              perturbation(resource_exhaustion), 
              fail)
    ->  format('   SUCCESS: Chunking strategy completed within limits~n'),
        assertz(learned_fact(add(A, B), chunked_result(Result))),
        assertz(reorganization_event(add(A, B), strategy_switch, tally_concatenation, chunking_strategy))
    ;   % Fallback also fails - even reorganization exceeds limits!
        format('   REORGANIZATION FAILURE: Even chunking strategy exceeds ~w-step limit~n', [Limit]),
        fail
    ).

attempt_strategic_multiplication(A, B) :-
    format('   STRATEGIC MULTIPLICATION: Using counting strategies for ~w × ~w~n', [A, B]),
    % Try coordinating two counts (C2C) strategy through meta-interpreter
    config:max_inferences(Limit),
    (   catch(meta_interpreter:solve(smr_mult_c2c:run_c2c(A, B, Result, _History), Limit, _, _),
              perturbation(resource_exhaustion),
              fail)
    ->  format('   SUCCESS: C2C strategy completed within limits~n'),
        assertz(learned_fact(multiply(A, B), strategic_result(Result))),
        assertz(reorganization_event(multiply(A, B), strategy_switch, repeated_addition, c2c_strategy))
    ;   % Fallback also fails - even strategic multiplication exceeds limits!
        format('   REORGANIZATION FAILURE: Even C2C strategy exceeds ~w-step limit~n', [Limit]),
        fail
    ).

manual_chunking_addition(A, B, Result) :-
    % Decompose both numbers into place values
    A_hundreds is A // 100, A_tens is (A mod 100) // 10, A_ones is A mod 10,
    B_hundreds is B // 100, B_tens is (B mod 100) // 10, B_ones is B mod 10,
    
    % Add place values
    Sum_hundreds is A_hundreds + B_hundreds,
    Sum_tens is A_tens + B_tens, 
    Sum_ones is A_ones + B_ones,
    
    format('   PLACE VALUE ADDITION: (~w+~w)×100 + (~w+~w)×10 + (~w+~w)×1~n', 
           [A_hundreds, B_hundreds, A_tens, B_tens, A_ones, B_ones]),
    
    Result = place_value_sum(hundreds(Sum_hundreds), tens(Sum_tens), ones(Sum_ones)).

record_crisis_failure(Task) :-
    format('   CRISIS FAILURE: Task ~w completely failed~n', [Task]),
    assertz(inference_crisis(Task, complete_failure, none)).

analyze_reorganization_events :-
    writeln(''),
    writeln('CRISIS ANALYSIS RESULTS:'),
    writeln('=' * 30),
    
    findall(crisis, inference_crisis(_, _, _), Crises),
    length(Crises, NumCrises),
    format('Total crisis events detected: ~w~n', [NumCrises]),
    
    findall(reorg, reorganization_event(_, _, _, _), Reorgs),
    length(Reorgs, NumReorgs),
    format('Reorganization events detected: ~w~n', [NumReorgs]),
    
    writeln(''),
    writeln('DETAILED CRISIS EVENTS:'),
    forall(
        inference_crisis(Task, Type, Details),
        format('- ~w: ~w (~w)~n', [Task, Type, Details])
    ),
    
    writeln(''),
    writeln('REORGANIZATION ANALYSIS:'),
    forall(
        reorganization_event(Task, Type, Old, New),
        format('- ~w: ~w (~w -> ~w)~n', [Task, Type, Old, New])
    ),
    
    writeln(''),
    (   NumReorgs > 0
    ->  writeln('✅ REORGANIZATION DETECTED: System adapted to crisis')
    ;   NumCrises > 0
    ->  writeln('⚠️  CRISIS WITHOUT REORGANIZATION: System may need better adaptation mechanisms')
    ;   writeln('ℹ️  NO CRISIS DETECTED: Tasks within current system capabilities')
    ).

run_crisis_demo :-
    writeln(''),
    writeln('TESTING COGNITIVE CRISIS AND REORGANIZATION'),
    writeln('=' * 45),
    max_inferences(Limit),
    format('Testing with inference limit: ~w steps~n', [Limit]),
    writeln(''),
    test_inference_limits,
    writeln(''),
    writeln('CRISIS DEMONSTRATION COMPLETE'),
    writeln('This reveals how inference limits trigger reorganization').

test_inference_limits :-
    writeln('Testing simple operations:'),
    test_simple_operations,
    writeln(''),
    writeln('Testing complex operations that should exceed limits:'),
    test_complex_operations.

test_simple_operations :-
    writeln('  Simple count: count(5)'),
    reset_crisis_monitoring,
    (catch(monitor_task_execution(count(5)), _, true) -> true ; true),
    writeln('  Simple addition: add(3, 2)'),
    reset_crisis_monitoring,
    (catch(monitor_task_execution(add(3, 2)), _, true) -> true ; true).

test_complex_operations :-
    writeln('  Complex count: count(100) - should hit limit'),
    reset_crisis_monitoring,
    (catch(monitor_task_execution(count(100)), _, true) -> true ; true),
    writeln('  Complex multiplication: multiply(15, 8) - should hit limit'),
    reset_crisis_monitoring,
    (catch(monitor_task_execution(multiply(15, 8)), _, true) -> true ; true).
