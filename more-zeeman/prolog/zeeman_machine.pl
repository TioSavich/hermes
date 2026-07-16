/** <module> Zeeman catastrophe machine — physics core

    Models the More Machine's disk-and-two-elastics geometry: a disk with one
    rim attachment point P(Theta) and two pull-only springs, one to a fixed
    anchor and one to a movable control point. One potential energy function
    grounds both the quasi-static catastrophe structure (equilibria, folds,
    M/W) and the dynamic motion (an inertial, damped disk integrated by RK4).

    Geometry is the JS/Python model (more-machine.js, bifurcation_verify.py)
    normalized by the rim radius, so equilibria are verifiable against them.

    Honest break-point: the quasi-static picture stops being faithful exactly
    where inertia and damping matter — which is why both models share one core
    rather than one standing in for the other.

    Side-effect free: no assert, no printing, no global state.
*/
:- module(zeeman_machine, [
    default_params/1,      % default_params(-Params)
    potential/4,           % potential(+Theta, +Control, +Params, -V)
    torque/4,              % torque(+Theta, +Control, +Params, -Tau)
    equilibria/3,          % equilibria(+Control, +Params, -Eqs)
    stable_equilibria/3,   % stable_equilibria(+Control, +Params, -Thetas)
    settle/4,              % settle(+Theta0, +Control, +Params, -ThetaStar)
    letter_of/2,           % letter_of(+Theta, -Letter)
    derivative/4,          % derivative(+State, +Control, +Params, -DState)
    rk4_step/5             % rk4_step(+State, +Control, +Dt, +Params, -State1)
]).

default_params(_{ k:2.0, l0:2.0, r:1.0, fixed:point(0.0, -4.8),
                  inertia:1.0, damping:0.4 }).

% --- Geometry helpers -------------------------------------------------------

rim_point(Theta, R, Px, Py) :-
    Px is R * cos(Theta),
    Py is R * sin(Theta).

spring_energy(Px, Py, Ax, Ay, K, L0, E) :-
    L is sqrt((Px - Ax)^2 + (Py - Ay)^2),
    ( L > L0 -> Stretch is L - L0, E is 0.5 * K * Stretch^2 ; E = 0.0 ).

% Contribution of one pull-only spring to dV/dTheta.
spring_dvdtheta(Px, Py, Ax, Ay, Theta, R, K, L0, D) :-
    L is sqrt((Px - Ax)^2 + (Py - Ay)^2),
    ( L > L0 ->
        D is K * (1 - L0 / L) * R * (Ax * sin(Theta) - Ay * cos(Theta))
    ; D = 0.0 ).

% --- Potential energy and torque -------------------------------------------

potential(Theta, point(Cx, Cy), Params, V) :-
    get_dict(r, Params, R), get_dict(k, Params, K), get_dict(l0, Params, L0),
    get_dict(fixed, Params, point(Fx, Fy)),
    rim_point(Theta, R, Px, Py),
    spring_energy(Px, Py, Fx, Fy, K, L0, E1),
    spring_energy(Px, Py, Cx, Cy, K, L0, E2),
    V is E1 + E2.

dV_dtheta(Theta, point(Cx, Cy), Params, DV) :-
    get_dict(r, Params, R), get_dict(k, Params, K), get_dict(l0, Params, L0),
    get_dict(fixed, Params, point(Fx, Fy)),
    rim_point(Theta, R, Px, Py),
    spring_dvdtheta(Px, Py, Fx, Fy, Theta, R, K, L0, D1),
    spring_dvdtheta(Px, Py, Cx, Cy, Theta, R, K, L0, D2),
    DV is D1 + D2.

torque(Theta, Control, Params, Tau) :-
    dV_dtheta(Theta, Control, Params, DV),
    Tau is -DV.

% --- Angles ----------------------------------------------------------------

wrap_angle(A, W) :- W is A - 2 * pi * floor(A / (2 * pi)).

% --- Equilibria and stability ----------------------------------------------

% Sample dV/dtheta on a MIDPOINT grid: the samples never land exactly on the
% symmetric angles 0, pi/2, pi, 3pi/2, where dV/dtheta touches zero without
% strictly crossing. Sampling those angles directly would miss the on-axis
% equilibria of the symmetric control geometry. Bracket each strict sign
% change, refine by bisection, and classify by the sign of the second
% derivative. The trailing cut commits to the single solution.

equilibria(Control, Params, Eqs) :-
    N = 1440,
    findall(s(Theta, DV),
            ( between(1, N, I),
              Theta is (I - 0.5) * 2 * pi / N,
              dV_dtheta(Theta, Control, Params, DV) ),
            Samples),
    Samples = [s(Th1, DV1) | _],
    ThWrap is Th1 + 2 * pi,
    append(Samples, [s(ThWrap, DV1)], Loop),
    scan_pairs(Loop, Control, Params, Eqs),
    !.

scan_pairs([_], _, _, []).
scan_pairs([s(A, DA), s(B, DB) | T], Control, Params, Eqs) :-
    ( DA * DB < 0 ->
        bisect_root(A, B, Control, Params, Root),
        classify_root(Root, Control, Params, Eq),
        Eqs = [Eq | Rest]
    ; Eqs = Rest ),
    scan_pairs([s(B, DB) | T], Control, Params, Rest).

classify_root(Root, Control, Params, eq(RootW, Kind)) :-
    wrap_angle(Root, RootW),
    H = 1.0e-5,
    RP is Root + H, RM is Root - H,
    dV_dtheta(RP, Control, Params, DP),
    dV_dtheta(RM, Control, Params, DM),
    D2 is (DP - DM) / (2 * H),
    ( D2 > 0 -> Kind = stable ; Kind = unstable ).

bisect_root(A, B, Control, Params, Root) :-
    ( B - A < 1.0e-9 ->
        Root is (A + B) / 2
    ; Mid is (A + B) / 2,
      dV_dtheta(A, Control, Params, DA),
      dV_dtheta(Mid, Control, Params, DM),
      ( DA * DM =< 0 -> bisect_root(A, Mid, Control, Params, Root)
      ; bisect_root(Mid, B, Control, Params, Root) ) ).

stable_equilibria(Control, Params, Thetas) :-
    equilibria(Control, Params, Eqs),
    findall(T, member(eq(T, stable), Eqs), Thetas).

% --- Quasi-static relaxation (gradient descent on V) -----------------------

settle(Theta0, Control, Params, ThetaStar) :-
    settle_(Theta0, Control, Params, 5000, ThetaStar).

settle_(Theta, _, _, 0, Theta) :- !.
settle_(Theta, Control, Params, N, Out) :-
    dV_dtheta(Theta, Control, Params, DV),
    ( abs(DV) < 1.0e-7 ->
        Out = Theta
    ; Step is max(-0.05, min(0.05, -0.01 * DV)),
      Theta1 is Theta + Step,
      wrap_angle(Theta1, Theta1w),
      N1 is N - 1,
      settle_(Theta1w, Control, Params, N1, Out) ).

% --- Oriented inscription ---------------------------------------------------
% M/W name which basin won from a viewing position, not a negation or a meaning.

letter_of(Theta, Letter) :-
    wrap_angle(Theta, T),
    ( T > pi / 2, T < 3 * pi / 2 -> Letter = 'W' ; Letter = 'M' ).

% --- Dynamics: inertial, damped disk ---------------------------------------

derivative(state(Theta, Omega), Control, Params, state(DTheta, DOmega)) :-
    get_dict(inertia, Params, I),
    get_dict(damping, Params, Cdamp),
    torque(Theta, Control, Params, Tau),
    DTheta is Omega,
    DOmega is Tau / I - Cdamp * Omega.

rk4_step(state(T, O), Control, Dt, Params, state(T1, O1)) :-
    derivative(state(T, O), Control, Params, state(K1T, K1O)),
    Ta is T + Dt / 2 * K1T, Oa is O + Dt / 2 * K1O,
    derivative(state(Ta, Oa), Control, Params, state(K2T, K2O)),
    Tb is T + Dt / 2 * K2T, Ob is O + Dt / 2 * K2O,
    derivative(state(Tb, Ob), Control, Params, state(K3T, K3O)),
    Tc is T + Dt * K3T, Oc is O + Dt * K3O,
    derivative(state(Tc, Oc), Control, Params, state(K4T, K4O)),
    T1 is T + Dt / 6 * (K1T + 2 * K2T + 2 * K3T + K4T),
    O1 is O + Dt / 6 * (K1O + 2 * K2O + 2 * K3O + K4O).
