/** <module> Object-Level Knowledge Base
 *
 * PRIMORDIAL STATE: This module has been simplified to contain ONLY the
 * most primitive arithmetic capability - the "Counting All" strategy for
 * addition via enumerate/1.
 *
 * This represents the machine at "Sense-Certainty" - the most immediate,
 * unabstracted form of mathematical knowledge. All other operations
 * (subtract, multiply, divide) have been REMOVED and must be LEARNED
 * through crisis-driven bootstrapping.
 *
 * The `add/3` predicate is deliberately inefficient, designed to fail
 * via resource_exhaustion on problems like add(8,5), thus triggering
 * the first productive crisis and forcing dialectical development.
 *
 * ARCHITECTURAL ENFORCEMENT: subtract/3, multiply/3, and divide/3 are
 * NO LONGER EXPORTED. They must emerge through learning, not be given.
 * 
 */
:- module(object_level, [add/3]).

:- use_module(formalization(grounded_arithmetic)).

:- dynamic add/3.
% PRIMORDIAL STATE: Only add/3 is available. All other operations removed.
% They must be learned, not given.

% enumerate/1
% Helper to force enumeration of a Peano number. Its primary purpose
% in this context is to consume inference steps in the meta-interpreter,
% making the initial `add/3` implementation inefficient and prone to
% resource exhaustion, which acts as a trigger for reorganization.
enumerate(0).
enumerate(s(N)) :- enumerate(N).

% recursive_add/3
% This is the standard, efficient, recursive definition of addition for
% Peano numbers. It serves as the "correct" implementation that the
% reorganization engine will synthesize and assert when the initial,
% inefficient `add/3` rule is retracted.
recursive_add(0, B, B).
recursive_add(s(A), B, s(Sum)) :-
    recursive_add(A, B, Sum).

%!      add(?A, ?B, ?Sum) is nondet.
%
%       PRIMORDIAL "COUNTING ALL" STRATEGY.
%
%       This is the most primitive form of addition - a direct computational
%       model of physically counting all objects. It treats numbers not as
%       abstract concepts but as particular collections to be exhaustively
%       enumerated.
%
%       This predicate is designed to simulate a "counting-all" strategy. It
%       works by first completely grounding the two inputs `A` and `B` by
%       recursively calling `enumerate/1`. This process is computationally
%       expensive and is intended to fail (by resource exhaustion) for larger
%       numbers, thus triggering the ORR learning cycle.
%
%       PHILOSOPHICAL GROUNDING: This is "Sense-Certainty" - the belief that
%       we can grasp pure particularity directly. Like Hegel's sense-certainty,
%       this strategy will encounter contradiction when it tries to handle
%       anything beyond immediate simplicity.
%
%       @param A A Peano number representing the first addend.
%       @param B A Peano number representing the second addend.
%       @param Sum The Peano number representing the sum of A and B.
add(A, B, Sum) :-
    enumerate(A),
    enumerate(B),
    recursive_add(A, B, Sum).

% ═══════════════════════════════════════════════════════════════════════
% ALL OTHER OPERATIONS REMOVED
% ═══════════════════════════════════════════════════════════════════════
%
% The following operations have been intentionally removed from the
% primordial state:
%   - subtract/3
%   - multiply/3  
%   - divide/3
%   - recursive_subtract/3
%   - recursive_multiply/3
%   - recursive_divide/3
%   - recursive_divide_helper/4
%
% These capabilities must EMERGE through crisis-driven learning.
% They are not given; they must be bootstrapped.
%
% This enforces the core UMEDCA principle: mathematical knowledge is not
% a static formalism to be applied, but an emergent structure built through
% embodied practice, crisis, and recognition.
% ═══════════════════════════════════════════════════════════════════════