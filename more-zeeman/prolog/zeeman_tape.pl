/** <module> Zeeman machine — consumable event tape

    Runs a control-point drag path through the physics core and emits an ordered
    tape any other module can query. A snap is a discontinuous jump of the
    occupied basin; the quiet stretches between snaps are recorded as no_snap
    intervals carrying the real tension (spring potential energy) that rose and
    fell over the stretch.

    Tape terms:
      event(Step, snap(Letter, TensionBefore, ThetaFrom, ThetaTo))
      event(Step, settle(Theta))
      interval(FromStep, ToStep, no_snap(Kind, TensionRise, TensionFall))
        Kind in { held_rigid, released_pre_threshold, wandering_slack }

    The interval Kind is a coarse heuristic over the tension trajectory; the
    reported Rise/Fall are exact, so a consumer can reclassify. This module
    performs no interpretation; the opt-in candidate mapping lives in
    zeeman_pml_bridge.pl. See
    docs/proposals/2026-07-09-zeeman-pml-automaton-bridges.md.
*/
:- module(zeeman_tape, [
    quasi_static_tape/4,   % quasi_static_tape(+Theta0, +Path, +Params, -Tape)
    dynamic_tape/5         % dynamic_tape(+State0, +Path, +Dt, +Params, -Tape)
]).

:- use_module(zeeman(zeeman_machine)).

snap_threshold(0.6).       % angular jump that counts as a snap (matches JS)
slack_range(0.05).         % tension variation below this reads as slack
release_drop(0.05).        % tension falling this far from its peak reads as release

% ── Quasi-static tape ──────────────────────────────────────────────────────

quasi_static_tape(Theta0, [C0 | Cs], Params, Tape) :-
    zeeman_machine:settle(Theta0, C0, Params, Th0),
    node_at(Th0, C0, Params, nosnap, 0, N0),
    q_nodes(Cs, 1, Th0, Params, Ns),
    Nodes = [N0 | Ns],
    nodes_events(Nodes, Events),
    nodes_intervals(Nodes, Intervals),
    append(Events, Intervals, Tape).

q_nodes([], _, _, _, []).
q_nodes([C | Cs], Step, ThPrev, Params, [Node | Ns]) :-
    zeeman_machine:settle(ThPrev, C, Params, Th),
    ang_dist(Th, ThPrev, D),
    snap_threshold(Thr),
    ( D > Thr ->
        zeeman_machine:potential(ThPrev, C, Params, TensionBefore),
        Snap = snap(ThPrev, TensionBefore)
    ;   Snap = nosnap ),
    node_at(Th, C, Params, Snap, Step, Node),
    Step1 is Step + 1,
    q_nodes(Cs, Step1, Th, Params, Ns).

% ── Dynamic tape (RK4) ─────────────────────────────────────────────────────

dynamic_tape(state(Th0, Om0), [C0 | Cs], Dt, Params, Tape) :-
    node_at(Th0, C0, Params, nosnap, 0, N0),
    zeeman_machine:letter_of(Th0, L0),
    d_nodes(Cs, 1, state(Th0, Om0), Dt, Params, L0, Ns),
    Nodes = [N0 | Ns],
    nodes_events(Nodes, Events),
    nodes_intervals(Nodes, Intervals),
    append(Events, Intervals, Tape).

d_nodes([], _, _, _, _, _, []).
d_nodes([C | Cs], Step, State0, Dt, Params, LPrev, [Node | Ns]) :-
    segment_integrate(State0, C, Dt, Params, 10, state(Th, Om)),
    zeeman_machine:letter_of(Th, L),
    ( L \== LPrev ->
        state_theta(State0, ThPrev),
        zeeman_machine:potential(ThPrev, C, Params, TensionBefore),
        Snap = snap(ThPrev, TensionBefore)
    ;   Snap = nosnap ),
    node_at(Th, C, Params, Snap, Step, Node),
    Step1 is Step + 1,
    d_nodes(Cs, Step1, state(Th, Om), Dt, Params, L, Ns).

state_theta(state(Th, _), Th).

segment_integrate(S, _, _, _, 0, S) :- !.
segment_integrate(S, C, Dt, Params, N, Out) :-
    zeeman_machine:rk4_step(S, C, Dt, Params, S1),
    N1 is N - 1,
    segment_integrate(S1, C, Dt, Params, N1, Out).

% ── Nodes → events / intervals ─────────────────────────────────────────────
% node(Step, Theta, Tension, Letter, Snap) where Snap is nosnap or
% snap(ThetaFrom, TensionBefore).

node_at(Theta, Control, Params, Snap, Step, node(Step, Theta, Tension, Letter, Snap)) :-
    zeeman_machine:potential(Theta, Control, Params, Tension),
    zeeman_machine:letter_of(Theta, Letter).

nodes_events([], []).
nodes_events([node(Step, Theta, _, Letter, Snap) | Ns], [Ev | Evs]) :-
    ( Snap = snap(ThFrom, TensionBefore) ->
        Ev = event(Step, snap(Letter, TensionBefore, ThFrom, Theta))
    ;   Ev = event(Step, settle(Theta)) ),
    nodes_events(Ns, Evs).

% Maximal runs of consecutive nosnap nodes become no_snap intervals.
nodes_intervals(Nodes, Intervals) :-
    nosnap_runs(Nodes, Runs),
    findall(Interval,
            ( member(Run, Runs), summarize_run(Run, Interval) ),
            Intervals).

nosnap_runs([], []).
nosnap_runs([node(_, _, _, _, snap(_, _)) | Ns], Runs) :-
    !, nosnap_runs(Ns, Runs).
nosnap_runs([node(Step, Th, T, L, nosnap) | Ns], [[node(Step, Th, T, L, nosnap) | Run] | Runs]) :-
    grow_nosnap(Ns, Run, Rest),
    nosnap_runs(Rest, Runs).

grow_nosnap([node(Step, Th, T, L, nosnap) | Ns], [node(Step, Th, T, L, nosnap) | Run], Rest) :-
    !, grow_nosnap(Ns, Run, Rest).
grow_nosnap(Ns, [], Ns).

summarize_run(Run, interval(From, To, no_snap(Kind, Rise, Fall))) :-
    Run = [node(From, _, FirstT, _, _) | _],
    last(Run, node(To, _, LastT, _, _)),
    findall(T, member(node(_, _, T, _, _), Run), Ts),
    max_list(Ts, MaxT), min_list(Ts, MinT),
    Rise is MaxT - FirstT,
    Fall is MaxT - LastT,
    Range is MaxT - MinT,
    classify_interval(Range, Fall, Kind).

classify_interval(Range, Fall, Kind) :-
    slack_range(Slack),
    release_drop(Drop),
    ( Range < Slack -> Kind = wandering_slack
    ; Fall > Drop   -> Kind = released_pre_threshold
    ; Kind = held_rigid ).

% ── Geometry ────────────────────────────────────────────────────────────────

ang_dist(A, B, D) :-
    Raw is abs(A - B),
    D is min(Raw, 2 * pi - Raw).
