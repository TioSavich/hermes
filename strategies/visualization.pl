:- module(visualization, [
    strategy_jumps/3,
    strategy_jumps_witness/3,
    misconception_jumps_witness/5,
    history_to_dicts/3
]).

:- use_module(library(lists)).
:- use_module(strategies('math/action_automata_registry'), []).

%!  strategy_jumps(+Strategy:atom, +History:list, -Jumps:list) is det.
%
%   Extract number-line jumps from a strategy's execution history.
%   Each jump is a dict: _{from: Int, to: Int, label: String}.
%   Jumps are the consecutive pairs (prev_sum, this_sum) where sum changed.
%   For strategies whose step shape is not yet handled, Jumps = [].
strategy_jumps(Strategy, History, Jumps) :-
    strategy_jumps_witness(Strategy, History, Witness),
    !,
    get_dict(jumps, Witness, Jumps).
strategy_jumps(_, _, []).

%!  strategy_jumps_witness(+Strategy:atom, +History:list, -Witness:dict) is semidet.
%
%   Witness-bearing form of strategy_jumps/3. This is a closed-world finite
%   extraction over currently known FSM history shapes plus a generic state
%   fallback: when each history step has a state(Name, RunningValue, ...)
%   shape, the second state argument is read as the running number-line value.
strategy_jumps_witness(Strategy, History, Witness) :-
    step_sum_trace_with_source(Strategy, History, RawSums, Extraction),
    normalized_sum_trace(RawSums, Sums),
    sums_to_jumps(Sums, Jumps),
    Jumps \== [],
    length(Sums, SampleCount),
    length(Jumps, JumpCount),
    Witness = _{ kind: strategy_number_line_jumps,
                 scope: closed_world_finite_strategy_history_step_shapes,
                 strategy: Strategy,
                 extraction: Extraction,
                 source_predicate: strategy_jumps/3,
                 derivation: running_sum_trace_collapsed_to_deltas,
                 sums: Sums,
                 sample_count: SampleCount,
                 jump_count: JumpCount,
                 jumps: Jumps }.

step_sum_trace_with_source(Strategy, History, Sums, strategy_specific_step_shape) :-
    step_sum_trace(Strategy, History, Sums),
    normalized_sum_trace(Sums, [_|_]).
step_sum_trace_with_source(_, History, Sums, generic_state_running_value) :-
    generic_state_sum_trace(History, Sums),
    normalized_sum_trace(Sums, [_|_]).

normalized_sum_trace(Sums0, Sums) :-
    include(number, Sums0, Sums).

generic_state_sum_trace(History, Sums) :-
    findall(Value,
            ( member(Step, History),
              step_state_and_interp(Step, State, _),
              state_running_value(State, Value)
            ),
            Sums).

state_running_value(State, Value) :-
    compound(State),
    functor(State, state, Arity),
    Arity >= 2,
    arg(2, State, Value),
    number(Value).

%!  misconception_jumps_witness(+Operation, +DeformationKind, +A, +B, -Witness) is semidet.
%
%   Run a deformation action automaton and expose the part of its trace that can
%   be drawn on a number line. The current closed-world trace parser covers the
%   additive rounding-without-compensation family and any later action trace
%   terms that are explicitly added to trace_step_jump/2.
misconception_jumps_witness(Operation, DeformationKind, A, B, Witness) :-
    integer(A),
    integer(B),
    catch(action_automata_registry:run_action_automaton(
              Operation,
              DeformationKind,
              A,
              B,
              Outcome,
              Trace),
          _, fail),
    Outcome = action_outcome(DeformationKind, Fields),
    member(classification(deformation), Fields),
    member(deformation_of(ProductiveKind), Fields),
    member(misconception_family(Family), Fields),
    member(result(Result), Fields),
    member(expected(Expected), Fields),
    member(validity(Validity), Fields),
    trace_number_line_jumps(Trace, Jumps),
    Jumps \== [],
    omitted_number_line_jumps(Trace, OmittedJumps),
    maplist(term_display_string, Trace, TraceTerms),
    length(Jumps, JumpCount),
    pair_source(Operation, ProductiveKind, DeformationKind, Family, PairSource),
    Witness = _{ kind: misconception_number_line_jumps,
                 scope: closed_world_finite_action_trace_number_line_patterns,
                 operation: Operation,
                 deformation: DeformationKind,
                 productive: ProductiveKind,
                 family: Family,
                 input: _{a: A, b: B},
                 result: Result,
                 expected: Expected,
                 validity: Validity,
                 jumps: Jumps,
                 omitted_jumps: OmittedJumps,
                 jump_count: JumpCount,
                 trace_terms: TraceTerms,
                 pair_source: PairSource,
                 source_predicate: action_automata_registry:run_action_automaton/6,
                 derivation: parsed_deformation_action_trace }.

pair_source(Operation, ProductiveKind, DeformationKind, Family,
            action_automata_registry:action_automaton_pair/4) :-
    catch(action_automata_registry:action_automaton_pair(
              Operation,
              ProductiveKind,
              DeformationKind,
              Family),
          _, fail),
    !.
pair_source(_, _, _, _, action_outcome_fields).

trace_number_line_jumps(Trace, Jumps) :-
    findall(Jump,
            ( member(Term, Trace),
              trace_step_jump(Term, Jump)
            ),
            Jumps).

trace_step_jump(round_up_by(From, _K, To), Jump) :-
    jump_dict(From, To, rounding_up_to_base, Jump).
trace_step_jump(add_with_rounded_number(From, _Addend, To), Jump) :-
    jump_dict(From, To, add_rounded_number, Jump).
trace_step_jump(adjust_back_by(_K, From, To), Jump) :-
    jump_dict(From, To, compensation_adjustment, Jump).
trace_step_jump(add_base_chunk(From, _Chunk, To), Jump) :-
    jump_dict(From, To, add_base_chunk, Jump).
trace_step_jump(add_ones_chunk(From, _Chunk, To), Jump) :-
    jump_dict(From, To, add_ones_chunk, Jump).

omitted_number_line_jumps(Trace, Jumps) :-
    findall(Jump, omitted_trace_jump(Trace, Jump), Jumps).

omitted_trace_jump(Trace, Jump) :-
    member(omit_adjustment(_K), Trace),
    member(lose_total_conservation(expected(Expected), produced(Produced)), Trace),
    jump_dict(Produced, Expected, omitted_compensation_adjustment, Jump).

jump_dict(From, To, Reason, _{from: From, to: To, label: Label, reason: Reason}) :-
    number(From),
    number(To),
    Delta is To - From,
    delta_label(Delta, Label).

delta_label(Delta, Label) :-
    ( Delta >= 0
    -> format(string(Label), "+~w", [Delta])
    ;  format(string(Label), "~w", [Delta])
    ).

term_display_string(Term, String) :-
    term_string(Term, String, [numbervars(true)]).

%!  step_sum_trace(+Strategy, +History, -Sums) is semidet.
%
%   Per-strategy extraction of the running-sum trajectory. Returns a list
%   of integers in execution order.
step_sum_trace('Chunking', History, Sums) :-
    findall(Sum,
            member(step(state(_, Sum, _, _, _, _, _), _, _), History),
            Sums).
step_sum_trace('COBO', History, Sums) :-
    findall(Sum,
            member(step(_, Sum, _, _, _), History),
            Sums).
step_sum_trace('RMB', History, Sums) :-
    % RMB's history is step(state(Name, A, B, K, AT, BT, TB, B_init), _, Interp).
    % The "sum" users care about is the developing A_temp (AT) which slides
    % up toward the target base; the decomposition phase slides B_temp (BT)
    % down; then the final recombination is A+B. For the number-line view,
    % show AT as the running value.
    findall(AT,
            member(step(state(_, _, _, _, AT, _, _, _), _, _), History),
            Sums).
step_sum_trace('Rounding', History, Sums) :-
    % Addition Rounding. state: (Name, K, AR, TS, R, T, O, TB, BC, OC, A_in, B_in).
    % TS is the running sum through the COBO sub-phase.
    findall(TS,
            member(step(state(_, _, _, TS, _, _, _, _, _, _, _, _), _, _), History),
            Sums).

%% --- Subtraction strategies ------------------------------------------------

step_sum_trace('Sliding', History, Sums) :-
    % state: (Name, K, MSlid, SSlid, TB, S_running, M, S). Show S_running
    % climbing toward TB during the K-calc phase. The final q_adjust step
    % resets S_running to 0 — drop the trailing zero.
    findall(SR,
            member(step(state(_, _, _, _, _, SR, _, _), _, _), History),
            Raw),
    drop_trailing_zero(Raw, Sums).

step_sum_trace('COBO (Missing Addend)', History, Sums) :-
    % state: (Name, S_running, Distance, M_target). S_running climbs from S
    % up to M.
    findall(SR,
            member(step(state(_, SR, _, _), _, _), History),
            Sums).

step_sum_trace('CBBO (Take Away)', History, Sums) :-
    % state: (Name, CurrentVal, BC, OC). CurrentVal falls from M.
    findall(CV,
            member(step(state(_, CV, _, _), _, _), History),
            Sums).

step_sum_trace('Decomposition', History, Sums) :-
    % Legacy step shape: step(StateName, MT, MO, Interpretation). Running
    % value is MT*10 + MO. During decomposition the value is constant.
    findall(V,
            ( member(step(_, MT, MO, _), History),
              V is MT * 10 + MO
            ),
            Sums).

step_sum_trace('Sub Rounding', History, Sums) :-
    % state: (Name, K_M, K_S, RunningResult, _, _, M, S, RoundedM, RoundedS).
    % RunningResult is 0 until the intermediate subtraction; after that it
    % walks toward the final difference. Prepend M so the number line starts
    % at M and slides down to the answer. Drop the leading 0s.
    findall(V,
            member(step(state(_, _, _, V, _, _, _, _, _, _), _, _), History),
            Raw),
    drop_leading_zeros(Raw, Sums).

step_sum_trace('Chunking A', History, Sums) :-
    % state: (Name, CurrentValue, S_Remaining, Subtracted). CurrentValue
    % drops from M by chunks.
    findall(CV,
            member(step(state(_, CV, _, _), _, _), History),
            Sums).

step_sum_trace('Chunking B', History, Sums) :-
    % state: (Name, Current, Distance, DistanceCounter, Chunk, Iter, M).
    % Current climbs from S toward M. Arg 2 = Current.
    findall(C,
            member(step(state(_, C, _, _, _, _, _), _, _), History),
            Sums).

step_sum_trace('Chunking C', History, Sums) :-
    % state: (Name, CurrentValue, Distance, K_inner, TB, IS, S). CurrentValue
    % drops from M by chunks back toward S.
    findall(CV,
            member(step(state(_, CV, _, _, _, _, _), _, _), History),
            Sums).

%% --- Multiplication strategies ---------------------------------------------

step_sum_trace('C2C', History, Sums) :-
    % state: (Name, GroupsDone, ItemInGroup, Total, NumGroups, GroupSize).
    % Total is arg 4. Plot Total (the embodied count climbs by 1 per item).
    findall(T,
            member(step(state(_, _, _, T, _, _), _, _), History),
            Sums).

step_sum_trace('Commutative Reasoning', History, Sums) :-
    % state: (Name, A, B, Total, Counter). Total is arg 4. Counter ticks down,
    % Total grows by B per iteration.
    findall(T,
            member(step(state(_, _, _, T, _), _, _), History),
            Sums).

step_sum_trace('DR', History, Sums) :-
    % state: (Name, S1, S2, P1, P2, Final, _, N, S). The cleanest running
    % value is P1 + P2 + Final. P1 climbs first, then P2, then Final = sum.
    findall(V,
            ( member(step(state(_, _, _, P1, P2, Final, _, _, _), _, _), History),
              V is P1 + P2 + Final
            ),
            Sums).

%% --- Division strategies ---------------------------------------------------

step_sum_trace('Dealing by Ones', History, Sums) :-
    % state: (Name, ItemsRemaining, GroupsList, NextGroup). Plot the largest
    % group size (i.e., max of GroupsList) as it grows.
    findall(M,
            ( member(step(state(_, _, GL, _), _, _), History),
              GL = [_|_], max_list(GL, M)
            ; member(step(state(_, _, GL, _), _, _), History),
              GL == [], M = 0
            ),
            Sums).

step_sum_trace('UCR', History, Sums) :-
    % state: (Name, T_distributed, RoundCount, E, G). T (arg 2) accumulates
    % by G each round, climbing toward E.
    findall(T,
            member(step(state(_, T, _, _, _), _, _), History),
            Sums).

drop_trailing_zero(L, R) :-
    ( append(Front, [Last], L),
      number(Last),
      Last =:= 0
    -> drop_trailing_zero(Front, R)
    ;  R = L
    ).

drop_leading_zeros([], []).
drop_leading_zeros([0 | T], R) :- !, drop_leading_zeros(T, R).
drop_leading_zeros(L, L).

%!  sums_to_jumps(+Sums:list, -Jumps:list) is det.
%
%   Collapse consecutive-equal entries, emit a jump for each delta.
sums_to_jumps([], []).
sums_to_jumps([_], []).
sums_to_jumps([A, B | Rest], Jumps) :-
    A =:= B, !,
    sums_to_jumps([B | Rest], Jumps).
sums_to_jumps([A, B | Rest], [J | RestJumps]) :-
    Delta is B - A,
    ( Delta >= 0
    -> format(string(Label), "+~w", [Delta])
    ;  format(string(Label), "~w", [Delta])
    ),
    J = _{from: A, to: B, label: Label},
    sums_to_jumps([B | Rest], RestJumps).

%!  history_to_dicts(+Strategy, +History, -Dicts) is det.
%
%   Produce a JSON-serializable list of step dicts:
%     _{state: StateAtom, interpretation: InterpAtom}
history_to_dicts(_Strategy, History, Dicts) :-
    findall(_{state: StateAtom, interpretation: InterpAtom},
            ( member(Step, History),
              step_state_and_interp(Step, State, Interp),
              term_to_atom(State, StateAtom),
              interp_to_atom(Interp, InterpAtom)
            ),
            Dicts).

step_state_and_interp(step(S, _, I), S, I) :- !.
step_state_and_interp(step(S, _, _, _, I), S, I) :- !.
step_state_and_interp(step(S, _, _, _, _, I), S, I) :- !.
step_state_and_interp(Step, Step, '').

interp_to_atom(X, X) :- atom(X), !.
interp_to_atom(X, A) :- string(X), !, atom_string(A, X).
interp_to_atom(X, A) :- term_to_atom(X, A).
