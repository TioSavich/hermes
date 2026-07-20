/** <module> Reorganization Engine for Cognitive Accommodation
 *
 * This module implements the "Reorganize" stage of the ORR cycle. It is
 * responsible for `accommodate/1`, the process of modifying the system's
 * own knowledge base (`object_level.pl`) in response to a state of
 * disequilibrium detected by the `reflective_monitor.pl`.
 *
 * The engine currently handles failures by:
 * 1.  Identifying the predicate causing the most "conceptual stress" (i.e.,
 *     the one involved in the most failures).
 * 2.  Applying a predefined transformation strategy to that predicate.
 *
 * The only transformation implemented is `specialize_add_rule`, which
 * replaces a failing `add/3` implementation with a more robust, recursive
 * one based on the Peano axioms.
 *
 * 
 * 
 */
:- module(reorganization_engine, [accommodate/1, handle_normative_crisis/2, handle_incoherence/1, reorganize_system/2]).

:- use_module(object_level).
:- use_module(reflective_monitor).
:- use_module(reorganization_log).
:- use_module(more_machine_learner).
:- use_module(reorganize, [reorganize/4]).
:- use_module('reorg_domains/arithmetic').
:- use_module(sequent(sequent_engine)).
:- use_module(strategies(strategies)). % Load all defined strategies
:- use_module(deontic_scorekeeper, []).  % qualified calls in retract_commitment/1 (deontic clause)
:- use_module(peano_utils, [peano_to_int/2]).

% 'learned_knowledge.pl' is consulted into the learner's module at runtime
% (see more_machine_learner:load_knowledge/0). It is not a separate module, so
% attempting to reexport from it causes a domain error. Remove the faulty
% reexport directive.
% :- reexport(learned_knowledge, [learned_rule/1]).

%!      reorganize_system(+Goal:term, +Trace:list) is semidet.
%
%       The main entry point for the reorganization process, triggered when
%       a perturbation (e.g., resource exhaustion) occurs. This predicate
%       orchestrates the analysis, synthesis, validation, and integration of
%       a new, more efficient strategy.
%
%       @param Goal The goal that failed.
%       @param Trace The execution trace leading to the failure.
reorganize_system(Goal, _Trace) :-
    % Deconstruct the goal to get the arguments
    Goal =.. [Pred, A, B, _Result],
    ( (Pred = add ; Pred = multiply) ->
        % Convert Peano numbers to integers for the learner
        peano_to_int(A, IntA),
        peano_to_int(B, IntB),
        reorganization_domain(Pred, IntA, IntB, Domain, Problem, Level),
        reorganize(Domain, Problem, Level, Outcome),
        Outcome = reorganized(_, _, _),
        format('Reorganization search found: ~w~n', [Outcome])
    ;
        format('Reorganization for predicate ~w is not supported.~n', [Pred]),
        fail
    ).

reorganization_domain(add, IntA, IntB, arithmetic(10), add(IntA, IntB), 1).

%!      integrate_new_rule(+Rule:term) is det.
%
%       Integrates a validated new rule into the system's knowledge base.
%       It retracts the old, inefficient rule and asserts the new one in
%       the `object_level` module.
integrate_new_rule((Head :- Body)) :-
    functor(Head, Name, Arity),
    retractall(object_level:Name/Arity),
    assertz(object_level:(Head :- Body)),
    log_event(reorganized(from(Name/Arity), to(Head :- Body))).

%!      save_learned_rule(+Rule:term) is det.
%
%       Persists a newly learned rule to the `learned_knowledge.pl` file
%       so that it can be reused across sessions.
save_learned_rule(Rule) :-
    open('learned_knowledge.pl', append, Stream),
    format(Stream, 'learned_rule(~q).~n', [Rule]),
    close(Stream).

%!      accommodate(+Trigger:term) is semidet.
%
%       Attempts to accommodate a state of disequilibrium by modifying the
%       knowledge base. This is the main entry point for the reorganization engine.
%
%       It dispatches to different handlers based on the type of `Trigger`:
%       - `goal_failure` or `perturbation`: Calls `handle_failure/1` to attempt
%         a knowledge repair based on conceptual stress.
%       - `incoherence`: Currently a placeholder; fails as this type of
%         reorganization is not yet implemented.
%
%       Succeeds if a transformation is successfully applied. Fails otherwise.
%
%       @param Trigger The term describing the disequilibrium, provided by the
%       reflective monitor.
accommodate(Trigger) :-
    (   (Trigger = goal_failure(_); Trigger = perturbation(_)) ->
        handle_failure(Trigger)
    ;   Trigger = incoherence(Commitments) ->
        handle_incoherence(Commitments)
    ;   format('Unknown trigger type: ~w. Cannot accommodate.~n', [Trigger]),
        fail
    ).

% handle_failure(+Trigger)
%
% Handles disequilibrium caused by goal failure. It identifies the most
% stressed predicate from the conceptual stress map and attempts to apply a
% transformation to repair it.
handle_failure(_Trigger) :-
    get_most_stressed_predicate(Signature),
    format('Highest conceptual stress found for predicate: ~w~n', [Signature]),
    log_event(reorganization_start(Signature)),
    apply_transformation(Signature).

% handle_incoherence/1 — full belief-revision implementation lives at
% line 289 below. The earlier stub-that-always-failed was removed;
% accommodate/1 dispatches directly to the real clause.

% get_most_stressed_predicate(-Signature)
%
% Finds the predicate with the highest stress count in the stress map
% maintained by the reflective monitor.
get_most_stressed_predicate(Signature) :-
    get_stress_map(StressMap),
    StressMap \= [],
    find_max_stress(StressMap, stress(_, 0), stress(Signature, _)), !.
get_most_stressed_predicate(_) :-
    format('Could not identify a stressed predicate. Reorganization failed.~n'),
    fail.

% find_max_stress(+StressMap, +CurrentMax, -Max)
%
% Helper predicate to find the maximum entry in the stress map list.
find_max_stress([], Max, Max).
find_max_stress([stress(S, C)|Rest], stress(_, MaxC), Max) :-
    C > MaxC, !, find_max_stress(Rest, stress(S, C), Max).
find_max_stress([_|Rest], Max, Result) :- find_max_stress(Rest, Max, Result).

% apply_transformation(+Signature)
%
% Dispatches to a specific transformation strategy based on the predicate
% signature. Currently, only a transformation for `add/3` exists.
apply_transformation(add/3) :-
    !, specialize_add_rule.
apply_transformation(Signature) :-
    format('No specific reorganization strategy available for ~w.~n', [Signature]),
    fail.

% --- Transformation Strategies ---

% specialize_add_rule/0
%
% A specific transformation strategy that replaces the existing `add/3` rules
% with a correct, recursive implementation based on Peano arithmetic. This
% represents a form of learning or knowledge repair.
specialize_add_rule :-
    format('Applying "Specialization" strategy to add/3.~n'),
    % Retract all existing rules for add/3 and log each one.
    forall(
        clause(object_level:add(A, B, C), Body),
        (   retract(object_level:add(A, B, C) :- Body),
            log_event(retracted((add(A, B, C) :- Body)))
        )
    ),
    % Synthesize and assert the new, correct rule and log it.
    NewHead = add(A, B, Sum),
    NewBody = recursive_add(A, B, Sum),
    assertz(object_level:(NewHead :- NewBody)),
    log_event(asserted((NewHead :- NewBody))),
    format('Asserted new specialized add/3 clause.~n'),
    % Synthesize and assert helper predicates if they don't exist.
    (   \+ predicate_property(object_level:recursive_add(_,_,_), defined) ->
        assert_and_log((object_level:recursive_add(0, X, X))),
        assert_and_log((object_level:recursive_add(s(N), Y, s(Z)) :- object_level:recursive_add(N, Y, Z))),
        format('Asserted helper predicate recursive_add/3.~n')
    ;   true
    ),
    log_event(reorganization_success).

% assert_and_log(+Clause)
%
% Helper to assert a clause and log the assertion event.
assert_and_log(Clause) :-
    assertz(Clause),
    log_event(asserted(Clause)).

% --- Normative Crisis Handlers ---

%!      handle_normative_crisis(+CrisisGoal:term, +Context:atom) is det.
%
%       Handles normative crises by shifting mathematical contexts to accommodate
%       previously prohibited operations. This implements the dialectical
%       expansion of mathematical understanding.
%
%       @param CrisisGoal The goal that violated current norms
%       @param Context The context in which the violation occurred
handle_normative_crisis(CrisisGoal, Context) :-
    log_event(normative_crisis(CrisisGoal, Context)),
    
    % Determine appropriate context shift
    propose_context_shift(Context, NewContext, CrisisGoal),
    
    % Perform the dialectical shift
    writeln('--- Conceptual Bootstrapping: Context Expansion ---'),
    format('Expanding context from ~w to ~w to accommodate ~w~n', [Context, NewContext, CrisisGoal]),
    
    % Update the current domain
    set_domain_from_context(NewContext),
    
    % Introduce new vocabulary for the expanded context
    introduce_vocabulary(NewContext, CrisisGoal),
    
    log_event(context_shift(Context, NewContext)).

%!      propose_context_shift(+Context:atom, -NewContext:atom, +Goal:term) is det.
%
%       Proposes an appropriate context expansion based on the nature of the crisis.
propose_context_shift(natural_numbers, integers, subtract(M, S, _)) :-
    % When subtraction fails in natural numbers, expand to integers
    grounded_arithmetic:smaller_than(M, S).

propose_context_shift(integers, rationals, divide(_, _, _)).
    % When division doesn't yield integers, expand to rationals

propose_context_shift(Context, Context, _) :-
    % Default: no expansion needed
    true.

%!      set_domain_from_context(+Context:atom) is det.
%
%       Maps context names back to domain symbols for sequent_engine.
set_domain_from_context(natural_numbers) :- set_domain(n).
set_domain_from_context(integers) :- set_domain(z).
set_domain_from_context(rationals) :- set_domain(q).

%!      introduce_vocabulary(+Context:atom, +CrisisGoal:term) is det.
%
%       Introduces new mathematical vocabulary and operations for expanded contexts.
introduce_vocabulary(integers, subtract(M, S, _)) :-
    % Introduce negative numbers and debt representation
    writeln('Introducing negative number vocabulary...'),
    
    % Add rule for subtraction that yields negative results
    NewRule = (object_level:subtract(M, S, debt(R)) :-
        grounded_arithmetic:smaller_than(M, S),
        grounded_arithmetic:subtract_grounded(S, M, R)
    ),
    
    assert_and_log(NewRule),
    format('Introduced debt/1 representation for negative numbers.~n').

introduce_vocabulary(rationals, divide(_, _, _)) :-
    % Introduce rational number representation
    writeln('Introducing rational number vocabulary...'),
    
    % Add rule for division that yields fractions
    NewRule = (object_level:divide(Dividend, Divisor, fraction(Dividend, Divisor)) :-
        \+ grounded_arithmetic:zero(Divisor)
    ),
    
    assert_and_log(NewRule),
    format('Introduced fraction/2 representation for rational numbers.~n').

introduce_vocabulary(_, _) :-
    % Default: no new vocabulary needed
    true.

%!      handle_incoherence(+Commitments:list) is det.
%
%       Handles logical incoherence by identifying and retracting conflicting
%       beliefs. This implements belief revision in response to contradictions.
%
%       @param Commitments The set of commitments that form an incoherent set
handle_incoherence(Commitments) :-
    log_event(incoherence_detected(Commitments)),
    
    writeln('--- Belief Revision: Resolving Incoherence ---'),
    format('Analyzing incoherent commitments: ~w~n', [Commitments]),
    
    % Find the most stressed (frequently failing) commitment
    identify_stressed_commitment(Commitments, StressedCommitment),
    
    % Retract the problematic commitment
    format('Retracting stressed commitment: ~w~n', [StressedCommitment]),
    retract_commitment(StressedCommitment),
    
    log_event(commitment_retracted(StressedCommitment)).

%!      identify_stressed_commitment(+Commitments:list, -StressedCommitment:term) is det.
%
%       Identifies the most stressed commitment using the reflective monitor's
%       stress tracking system.
identify_stressed_commitment([SingleCommitment], SingleCommitment) :- !.
identify_stressed_commitment(Commitments, StressedCommitment) :-
    % Use stress tracking to find the most problematic commitment
    maplist(get_commitment_stress, Commitments, StressLevels),
    pairs_keys_values(Pairs, StressLevels, Commitments),
    keysort(Pairs, SortedPairs),
    reverse(SortedPairs, [_-StressedCommitment|_]).

%!      get_commitment_stress(+Commitment:term, -Stress:number) is det.
%
%       Gets the stress level of a commitment from the reflective monitor.
get_commitment_stress(Commitment, Stress) :-
    ( reflective_monitor:conceptual_stress(Commitment, Stress) ->
        true
    ;
        Stress = 1  % Default stress level
    ).

%!      retract_commitment(+Commitment:term) is det.
%
%       Retracts a commitment from the knowledge base.
%
%       Two commitment stores exist: object-level clauses (the
%       meta-interpreter's incoherence path) and the deontic
%       scorekeeper's commitment/2 facts (the deontic path, arriving as
%       crisis(incoherence, deontic, Agent, Reason) descriptors from
%       execution_handler:deontic_crisis_check/2). The deontic clause
%       withdraws ONE offending commitment — the same
%       one-revision-per-pass discipline as the object-level clause —
%       via deontic_scorekeeper:withdraw_commitment/2, which
%       ripple-retracts dependents.
retract_commitment(crisis(incoherence, deontic, Agent, Reason)) :-
    !,
    (   deontic_scorekeeper:deontic_incoherence_commitments(Agent, Reason, [C|_])
    ->  format('Withdrawing deontic commitment without ground: ~w~n', [C]),
        deontic_scorekeeper:withdraw_commitment(Agent, C)
    ;   writeln('Warning: deontic incoherence no longer backed by live commitments; nothing to withdraw')
    ).
retract_commitment(Commitment) :-
    ( retract(object_level:Commitment) ->
        true
    ;
        writeln('Warning: Could not retract commitment (may not exist)')
    ).
