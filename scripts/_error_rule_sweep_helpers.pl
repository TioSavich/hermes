
sweep_choose_n(0, _List, []) :- !.
sweep_choose_n(N, [Head|Tail], [Head|Rest]) :-
    N > 0, N1 is N - 1,
    sweep_choose_n(N1, Tail, Rest).
sweep_choose_n(N, [_Head|Tail], Rest) :-
    N > 0,
    sweep_choose_n(N, Tail, Rest).

sweep_kind(incoherent(emergent_defeat(_, _)), emergent).
sweep_kind(incoherent(defeated(_, _)), defeated).
