/** <module> Zeeman machine — bifurcation sweep

    Counts stable equilibria across control positions, reproducing the
    bistability/cusp map that more-zeeman/bifurcation_verify.py draws. Used as a
    feature (the catastrophe map) and as a cross-check that the Prolog core
    reproduces the existing artifact rather than only its own claims.
*/
:- module(zeeman_bifurcation, [
    stable_count/3,   % stable_count(+Control, +Params, -N)
    sweep_line/5,     % sweep_line(+P0, +P1, +Steps, +Params, -Counts)
    bistable/2        % bistable(+Control, +Params)
]).

:- use_module(zeeman(zeeman_machine)).

stable_count(Control, Params, N) :-
    zeeman_machine:stable_equilibria(Control, Params, S),
    length(S, N).

bistable(Control, Params) :-
    stable_count(Control, Params, N),
    N >= 2.

sweep_line(point(X0, Y0), point(X1, Y1), Steps, Params, Counts) :-
    findall(point(X, Y)-N,
            ( between(0, Steps, I),
              F is I / Steps,
              X is X0 + F * (X1 - X0),
              Y is Y0 + F * (Y1 - Y0),
              stable_count(point(X, Y), Params, N) ),
            Counts).
