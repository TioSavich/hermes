/** <module> Primordial Machine Entry Point
 *
 * This is the bootstrap kernel for the UMEDCA computational model.
 * It represents the machine at its most primitive state, possessing only:
 *   1. The capacity for embodied counting (recollection/tally/successor)
 *   2. The most inefficient "Counting All" addition strategy
 *   3. A mechanism to learn from failure (ORR cycle)
 *
 * This file architecturally enforces the separation between the primordial
 * machine and the normative oracle (pre-defined strategy library). The
 * machine begins with minimal cognitive tools and must bootstrap all other
 * capabilities through crisis-driven learning.
 *
 * PHILOSOPHICAL GROUNDING:
 * This kernel represents "Sense-Certainty" from Hegel's Phenomenology - the
 * most immediate, concrete form of knowledge. The "Counting All" strategy
 * is the computational equivalent of pre-conceptual immediacy, treating each
 * number as a particular collection of tally tokens rather than an abstract
 * concept.
 *
 * The system's first crisis will be the computational refutation of its own
 * primitive immediacy, forcing dialectical progression to more abstract forms.
 *
 * @author UMEDCA System
 * @version Primordial Bootstrap 1.0
 */

% Load ONLY the essential kernel modules
:- use_module(config).                    % System-wide settings and inference limits
:- use_module(formalization(grounded_arithmetic)).       % Foundational embodiment: recollection/tally/successor
:- use_module(object_level).              % Dynamic knowledge base (will be simplified)
:- use_module(meta_interpreter).          % ORR cycle: Observe (exports solve/4)
:- use_module(reflective_monitor).        % ORR cycle: Reflect  
:- use_module(reorganization_engine).     % ORR cycle: Reorganize
:- use_module(execution_handler).         % ORR cycle controller
% Note: more_machine_learner is loaded by execution_handler, so we don't load it directly
% to avoid solve/4 conflict between meta_interpreter and more_machine_learner

% Ensure the system starts in primordial state
:- writeln('═══════════════════════════════════════════════════════════').
:- writeln('  PRIMORDIAL MACHINE INITIALIZED').
:- writeln('  Bootstrap Kernel: Sense-Certainty Stage').
:- writeln('  Capabilities: Embodied Counting + Crisis-Driven Learning').
:- writeln('═══════════════════════════════════════════════════════════').

% Display initial configuration
:- config:max_inferences(Limit),
   format('  Max Inference Limit: ~w (enforces finitude)~n', [Limit]).

:- writeln('  Initial Knowledge: add/3 via "Counting All" (enumerate-based)').
:- writeln('  Strategy Library: NONE (must be learned)').
:- writeln('  Oracle: Not yet loaded (Phase 2)').
:- writeln('═══════════════════════════════════════════════════════════').
:- writeln('').

%!      primordial_test is det.
%
%       A simple test to verify the primordial machine is functioning.
%       This should succeed for small problems but fail for larger ones.
primordial_test :-
    writeln('Testing primordial machine...'),
    writeln('Test 1: add(2,3) - should succeed'),
    (   execution_handler:run_computation(object_level:add(s(s(0)), s(s(s(0))), Result1), 50)
    ->  format('  SUCCESS: Result = ~w~n', [Result1])
    ;   writeln('  FAILED')
    ),
    writeln(''),
    writeln('Test 2: add(8,5) - should trigger resource_exhaustion crisis'),
    (   execution_handler:run_computation(
            object_level:add(s(s(s(s(s(s(s(s(0)))))))), s(s(s(s(s(0))))), Result2),
            10)
    ->  format('  Result = ~w (crisis should have been resolved)~n', [Result2])
    ;   writeln('  FAILED: Crisis not resolved')
    ).

% Export the test predicate
:- export(primordial_test/0).
