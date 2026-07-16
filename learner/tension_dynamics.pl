/** <module> Tension Dynamics — Continuous State for Catastrophe Geometry

    This module replaces the binary crisis model (counter hits zero → crisis)
    with a continuous tension accumulator that has memory (hysteresis).

    The key idea: crisis is not a threshold crossing but a LOSS OF STABILITY.
    Tension accumulates as the system works. When the second derivative of
    tension goes negative, the system has entered the catastrophe zone —
    any perturbation can trigger a snap. This maps directly onto the Zeeman
    catastrophe machine's cusp geometry.

    The tension state persists across problems (hysteresis). A student who
    just snapped on addition is in a different energy state when they
    encounter subtraction than a student who hasn't. After crisis, tension
    partially relaxes — it doesn't reset to zero.

    This is a metaphor made computational. It does not literally implement
    the Zeeman machine's physics. What it does is give the Prolog system
    a continuous state variable that behaves like the catastrophe surface,
    so the More Machine can visualize the formalization's internal dynamics
    as catastrophe geometry.

    Usage:
        reset_tension,
        ... (run ORR cycle — meta_interpreter calls accumulate_tension) ...
        get_tension_state(State).
*/
:- module(tension_dynamics, [
    reset_tension/0,
    accumulate_tension/2,    % accumulate_tension(+Cost, +ModalContext)
    get_tension_state/1,     % get_tension_state(-StateDict)
    check_stability/1,       % check_stability(-Stability)
    check_crisis/0,          % check_crisis — throws perturbation(tension_instability) if unstable
    relax_tension/0,         % partial relaxation after crisis (hysteresis)
    get_tension_history/1    % get_tension_history(-History) — full history for visualization
]).

:- use_module(event_log, [emit/2]).

% ═══════════════════════════════════════════════════════════════════════
% Dynamic state
% ═══════════════════════════════════════════════════════════════════════

:- dynamic tension_level/1.       % Current accumulated tension (float)
:- dynamic tension_history/1.     % List of recent tension values (newest first)
:- dynamic tension_full_log/1.    % Complete log for visualization: list of t(Step, Level, Stability, Ctx)
:- dynamic crisis_count/1.        % Number of crises experienced
:- dynamic computation_step/1.    % Monotonic step counter (time axis)

% ═══════════════════════════════════════════════════════════════════════
% Configuration
% ═══════════════════════════════════════════════════════════════════════

% Rolling window for derivative computation.
% Larger = smoother stability estimate, slower to react.
history_window(20).

% How much tension drops after crisis. 0.0 = full reset, 1.0 = no change.
% 0.4 means tension drops to 40% of its pre-crisis value.
% This is hysteresis: the system remembers that it was stressed.
relaxation_rate(0.4).

% Damping: tension naturally decays slightly each step.
% Models the student "settling" between inferences.
% 0.0 = no decay, 1.0 = instant decay. 0.02 = very gentle.
natural_damping(0.02).

% ═══════════════════════════════════════════════════════════════════════
% Initialization
% ═══════════════════════════════════════════════════════════════════════

reset_tension :-
    retractall(tension_level(_)),
    retractall(tension_history(_)),
    retractall(tension_full_log(_)),
    retractall(crisis_count(_)),
    retractall(computation_step(_)),
    assert(tension_level(0.0)),
    assert(tension_history([])),
    assert(tension_full_log([])),
    assert(crisis_count(0)),
    assert(computation_step(0)).

% Initialize on module load
:- reset_tension.

% ═══════════════════════════════════════════════════════════════════════
% Tension Accumulation
% ═══════════════════════════════════════════════════════════════════════

%!  accumulate_tension(+BaseCost:number, +ModalContext:atom) is det.
%
%   Called by the meta-interpreter on each inference step.
%   Adds tension proportional to the inference cost, scaled by
%   modal context. Compressive context adds more tension (cognitive
%   narrowing increases strain). Expansive context adds less
%   (cognitive opening reduces strain).
%
%   Also applies natural damping — tension decays slightly each step,
%   modeling the student settling between inferences.
%
accumulate_tension(BaseCost, ModalContext) :-
    context_tension_multiplier(ModalContext, Mul),
    natural_damping(Damp),
    % Get current state
    retract(tension_level(T)),
    retract(computation_step(Step)),
    % Apply damping then add new tension
    T_damped is T * (1.0 - Damp),
    Increment is BaseCost * Mul,
    T_new is T_damped + Increment,
    Step1 is Step + 1,
    assert(tension_level(T_new)),
    assert(computation_step(Step1)),
    % Update rolling history
    update_history(T_new),
    % Compute stability for the log
    check_stability(Stab),
    % Append to full log for visualization
    retract(tension_full_log(Log)),
    Entry = t(Step1, T_new, Stab, ModalContext),
    append(Log, [Entry], Log1),
    assert(tension_full_log(Log1)),
    % Emit event every 3 steps (don't spam the log)
    (   Step1 mod 3 =:= 0
    ->  emit(tension_update, _{
            step: Step1,
            level: T_new,
            stability: Stab,
            context: ModalContext,
            increment: Increment
        })
    ;   true
    ).

%!  context_tension_multiplier(+Context:atom, -Multiplier:float) is det.
%
%   How much tension a given modal context generates per unit of
%   inference cost. Compressive = high tension (gripping, effortful).
%   Expansive = low tension (opening, releasing). Neutral = baseline.
%
context_tension_multiplier(compressive, 2.5).
context_tension_multiplier(neutral, 1.0).
context_tension_multiplier(expansive, 0.3).

% ═══════════════════════════════════════════════════════════════════════
% History Management
% ═══════════════════════════════════════════════════════════════════════

update_history(Value) :-
    retract(tension_history(H)),
    history_window(MaxLen),
    H1 = [Value | H],
    (   length(H1, L), L > MaxLen
    ->  length(Trimmed, MaxLen),
        append(Trimmed, _, H1),
        assert(tension_history(Trimmed))
    ;   assert(tension_history(H1))
    ).

% ═══════════════════════════════════════════════════════════════════════
% Stability Computation
% ═══════════════════════════════════════════════════════════════════════

%!  check_stability(-Stability:float) is det.
%
%   Approximates the second derivative of tension over time.
%
%   Stability > 0: tension is decelerating or decreasing.
%                   The system is in a stable region.
%   Stability ≈ 0: the system is at an inflection point.
%                   Approaching the catastrophe fold.
%   Stability < 0: tension is ACCELERATING.
%                   The system is in the unstable zone.
%                   Any perturbation can trigger a snap.
%
%   This maps onto the Zeeman machine: positive stability =
%   the ball sits in a well. Negative stability = the well
%   has become a hill. The ball must roll.
%
check_stability(Stability) :-
    tension_history(H),
    length(H, Len),
    (   Len >= 9
    ->  % Three windows of 3: recent, middle, older
        take_n(H, 3, Recent),
        drop_n(H, 3, R1),
        take_n(R1, 3, Middle),
        drop_n(R1, 3, R2),
        take_n(R2, 3, Older),
        avg(Recent, AvgR),
        avg(Middle, AvgM),
        avg(Older, AvgO),
        % First derivatives
        D1 is AvgR - AvgM,    % recent rate of change
        D0 is AvgM - AvgO,    % earlier rate of change
        % Second derivative (negated: positive = stable)
        Stability is -(D1 - D0)
    ;   Len >= 6
    ->  % Two windows of 3
        take_n(H, 3, Recent),
        drop_n(H, 3, R1),
        take_n(R1, 3, Middle),
        avg(Recent, AvgR),
        avg(Middle, AvgM),
        D1 is AvgR - AvgM,
        % Only first derivative available — treat accelerating tension as unstable
        Stability is -D1
    ;   % Not enough data — assume stable
        Stability is 1.0
    ).

% ═══════════════════════════════════════════════════════════════════════
% Crisis Detection — The Third Wire
% ═══════════════════════════════════════════════════════════════════════

%!  check_crisis is det.
%
%   Called by the meta-interpreter on each inference step (alongside
%   check_viability). If the tension history has enough data (>= 9
%   entries) AND stability is negative (tension accelerating), the
%   system has entered the catastrophe zone and any perturbation
%   should trigger a snap.
%
%   This is the third wire connecting catastrophe geometry to the ORR
%   cycle. The inference counter (Wire 1) checks whether resources
%   remain. This predicate checks whether the energy landscape has
%   gone unstable — the system may still have inferences left, but
%   the surface has tilted and the ball must roll.
%
%   Succeeds silently if conditions are not met (not enough history,
%   or stability is non-negative). Throws perturbation(tension_instability)
%   if the unstable zone is detected.
%
check_crisis :-
    tension_history(H),
    length(H, Len),
    Len >= 9,
    check_stability(Stab),
    Stab < 0,
    !,
    % Emit event before throwing — this is visible in the event log
    % even though the throw will unwind the computation.
    emit(tension_instability_detected, _{
        stability: Stab,
        history_length: Len
    }),
    throw(perturbation(tension_instability)).
check_crisis.
    % Not enough history or stability is non-negative — succeed silently.

% ═══════════════════════════════════════════════════════════════════════
% Post-Crisis Relaxation (Hysteresis)
% ═══════════════════════════════════════════════════════════════════════

%!  relax_tension is det.
%
%   Called after a crisis is resolved. Partially relaxes tension.
%   The system doesn't reset to zero — it remembers the stress.
%   Each successive crisis relaxes less (the student builds
%   tolerance, or equivalently, the elastic band stretches).
%
%   Relaxation rate decays with crisis count:
%     1st crisis: 40% retention (big relief)
%     2nd crisis: 52% retention (less relief)
%     3rd crisis: 61% retention (even less)
%     ...
%   Formula: effective_rate = base_rate + (1 - base_rate) * (1 - 1/(1 + N/3))
%
relax_tension :-
    retract(tension_level(T)),
    retract(crisis_count(N)),
    relaxation_rate(BaseRate),
    % Diminishing relaxation: each crisis provides less relief
    EffectiveRate is BaseRate + (1.0 - BaseRate) * (1.0 - 1.0 / (1.0 + N / 3.0)),
    T_relaxed is T * EffectiveRate,
    N1 is N + 1,
    assert(tension_level(T_relaxed)),
    assert(crisis_count(N1)),
    % Log the relaxation
    check_stability(Stab),
    computation_step(Step),
    emit(tension_relaxed, _{
        level_before: T,
        level_after: T_relaxed,
        effective_rate: EffectiveRate,
        crisis_number: N1,
        stability: Stab,
        step: Step
    }),
    % Add relaxation to full log
    retract(tension_full_log(Log)),
    Entry = t(Step, T_relaxed, Stab, relaxation),
    append(Log, [Entry], Log1),
    assert(tension_full_log(Log1)).

% ═══════════════════════════════════════════════════════════════════════
% State Retrieval
% ═══════════════════════════════════════════════════════════════════════

%!  get_tension_state(-State:dict) is det.
%
%   Returns the current tension state as a dict suitable for
%   JSON serialization and visualization.
%
get_tension_state(State) :-
    tension_level(Level),
    check_stability(Stability),
    crisis_count(Crises),
    computation_step(Step),
    State = _{
        level: Level,
        stability: Stability,
        crises: Crises,
        step: Step
    }.

%!  get_tension_history(-History:list) is det.
%
%   Returns the complete tension log for visualization.
%   Each entry is a dict with step, level, stability, context.
%
get_tension_history(History) :-
    tension_full_log(Log),
    maplist(tension_entry_to_dict, Log, History).

tension_entry_to_dict(t(Step, Level, Stab, Ctx), _{
    step: Step,
    level: Level,
    stability: Stab,
    context: Ctx
}).

% ═══════════════════════════════════════════════════════════════════════
% List Helpers
% ═══════════════════════════════════════════════════════════════════════

take_n(_, 0, []) :- !.
take_n([], _, []) :- !.
take_n([H|T], N, [H|R]) :- N > 0, N1 is N - 1, take_n(T, N1, R).

drop_n(L, 0, L) :- !.
drop_n([], _, []) :- !.
drop_n([_|T], N, R) :- N > 0, N1 is N - 1, drop_n(T, N1, R).

avg([], 0.0) :- !.
avg(L, A) :- sum_list(L, S), length(L, N), A is S / N.
