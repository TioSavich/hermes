:- module(introspection, [
    collect_transition_clauses/2,
    collect_strategy_clauses/2,
    walk_body/2,
    goal_functor/2,
    state_term_names/2,
    next_state_names/2,
    strip_module_qualifier/2
]).

%!  collect_transition_clauses(+Module:atom, -Clauses:list) is det.
%
%   Gather every transition/3 and transition/4 clause defined in Module.
%   Clauses is a list of clause(Head, Body) terms with the Head's module
%   qualifier stripped. Uses clause/2 against the live, loaded module.
%   If the module defines neither, returns [].
collect_transition_clauses(Module, Clauses) :-
    findall(clause(Head, Body),
            ( current_predicate(Module:transition/3),
              Head0 = transition(_,_,_),
              clause(Module:Head0, Body),
              Head = Head0
            ),
            Cs3),
    findall(clause(Head, Body),
            ( current_predicate(Module:transition/4),
              Head0 = transition(_,_,_,_),
              clause(Module:Head0, Body),
              Head = Head0
            ),
            Cs4),
    append(Cs3, Cs4, Clauses).

%!  collect_strategy_clauses(+Module:atom, -Clauses:list) is det.
%
%   Wider collection: every clause of transition/{3,4}, setup_strategy/4,
%   final_interpretation/2, and any helper predicate defined in the module
%   that appears in a transition clause body. Helpers are detected by
%   scanning transition bodies for calls to predicates defined (has a clause)
%   in the same module and not already in the initial set. Returns the union.
collect_strategy_clauses(Module, Clauses) :-
    collect_transition_clauses(Module, TClauses),
    findall(clause(Head, Body),
            ( current_predicate(Module:setup_strategy/4),
              H = setup_strategy(_,_,_,_),
              clause(Module:H, Body),
              Head = H
            ),
            SClauses),
    findall(clause(Head, Body),
            ( current_predicate(Module:final_interpretation/2),
              H = final_interpretation(_,_),
              clause(Module:H, Body),
              Head = H
            ),
            FClauses),
    append([TClauses, SClauses, FClauses], Base),
    collect_helper_clauses(Module, Base, HClauses),
    append(Base, HClauses, Clauses).

%!  collect_helper_clauses(+Module, +SeedClauses, -HelperClauses) is det.
%
%   Scan bodies of SeedClauses for module-internal helper goals (predicates
%   that have a clause/2 in Module). Return every clause of each such helper.
%   Single-level (do not recurse into helpers-of-helpers); sufficient for the
%   actual strategy modules which are shallow.
collect_helper_clauses(Module, Seeds, Helpers) :-
    findall(F/A,
            ( member(clause(_, Body), Seeds),
              walk_body(Body, Goals),
              member(G, Goals),
              strip_module_qualifier(G, GBare),
              compound(GBare),
              functor(GBare, F, A),
              \+ seed_head_functor(Seeds, F/A),
              \+ builtin_or_library(F/A),
              current_predicate(Module:F/A),
              \+ predicate_property(Module:GBare, imported_from(_))
            ),
            FAs0),
    sort(FAs0, FAs),
    findall(clause(H, B),
            ( member(F/A, FAs),
              functor(H, F, A),
              clause(Module:H, B)
            ),
            Helpers).

seed_head_functor(Seeds, F/A) :-
    member(clause(H, _), Seeds),
    functor(H, F, A).

builtin_or_library(F/A) :-
    functor(G, F, A),
    ( predicate_property(G, built_in)
    ; predicate_property(G, foreign)
    ; predicate_property(G, iso)
    ).

%!  walk_body(+Body:term, -Goals:list) is det.
%
%   Flatten a clause body into a list of atomic goals. Handles conjunction
%   (,)/2, disjunction (;)/2, if-then (->)/2, soft-cut (*->)/2, negation
%   (\+)/1, and once/1 / not/1 / call/1 wrappers. Module qualifiers are
%   preserved on the enumerated goals (downstream detectors strip them).
walk_body(true, []) :- !.
walk_body((A,B), Goals) :- !, walk_body(A, Ga), walk_body(B, Gb), append(Ga, Gb, Goals).
walk_body((A;B), Goals) :- !, walk_body(A, Ga), walk_body(B, Gb), append(Ga, Gb, Goals).
walk_body((A->B), Goals) :- !, walk_body(A, Ga), walk_body(B, Gb), append(Ga, Gb, Goals).
walk_body((A*->B), Goals) :- !, walk_body(A, Ga), walk_body(B, Gb), append(Ga, Gb, Goals).
walk_body(\+(A), Goals) :- !, walk_body(A, Goals).
walk_body(not(A), Goals) :- !, walk_body(A, Goals).
walk_body(once(A), Goals) :- !, walk_body(A, Goals).
walk_body(call(A), Goals) :- !, walk_body(A, Goals).
walk_body(Goal, [Goal]).

%!  goal_functor(+Goal:term, -FA:term) is det.
%
%   Return a Functor/Arity key for Goal, with any module qualifier stripped.
%   Variables and atoms are handled safely.
goal_functor(Goal, Functor/Arity) :-
    strip_module_qualifier(Goal, Bare),
    ( compound(Bare)
    -> functor(Bare, Functor, Arity)
    ; atom(Bare)
    -> Functor = Bare, Arity = 0
    ; Functor = '<var>', Arity = 0
    ).

%!  strip_module_qualifier(+Goal:term, -Bare:term) is det.
%
%   Strip a leading Module:Goal qualifier. Idempotent on non-qualified goals.
strip_module_qualifier(_:Bare, Bare) :- !.
strip_module_qualifier(G, G).

%!  state_term_names(+Body:term, -Names:list) is det.
%
%   Collect every StateName atom appearing as the first argument of
%   state(Name, ...) in Body, anywhere in the term. Sorted, deduped.
state_term_names(Body, Names) :-
    findall(N, sub_state_name(Body, N), Raw),
    sort(Raw, Names).

sub_state_name(Term, Name) :-
    nonvar(Term),
    Term = state(Name0, _, _, _, _, _, _, _, _, _, _, _), atom(Name0), Name = Name0.
sub_state_name(Term, Name) :-
    nonvar(Term),
    Term = state(Name0, _, _, _, _, _, _, _, _, _, _), atom(Name0), Name = Name0.
sub_state_name(Term, Name) :-
    nonvar(Term),
    Term = state(Name0, _, _, _, _, _, _, _, _, _), atom(Name0), Name = Name0.
sub_state_name(Term, Name) :-
    nonvar(Term),
    Term = state(Name0, _, _, _, _, _, _, _, _), atom(Name0), Name = Name0.
sub_state_name(Term, Name) :-
    nonvar(Term),
    Term = state(Name0, _, _, _, _, _, _, _), atom(Name0), Name = Name0.
sub_state_name(Term, Name) :-
    nonvar(Term),
    Term = state(Name0, _, _, _, _, _, _), atom(Name0), Name = Name0.
sub_state_name(Term, Name) :-
    nonvar(Term),
    Term = state(Name0, _, _, _, _, _), atom(Name0), Name = Name0.
sub_state_name(Term, Name) :-
    nonvar(Term),
    Term = state(Name0, _, _, _, _), atom(Name0), Name = Name0.
sub_state_name(Term, Name) :-
    nonvar(Term),
    Term = state(Name0, _, _, _), atom(Name0), Name = Name0.
sub_state_name(Term, Name) :-
    nonvar(Term),
    Term = state(Name0, _, _), atom(Name0), Name = Name0.
sub_state_name(Term, Name) :-
    nonvar(Term),
    Term = state(Name0, _), atom(Name0), Name = Name0.
sub_state_name(Term, Name) :-
    nonvar(Term),
    compound(Term),
    Term =.. [_|Args],
    member(Arg, Args),
    sub_state_name(Arg, Name).

%!  next_state_names(+Clause:compound, -Names:list) is det.
%
%   Collect the state-name atoms that appear in the "next state" slot of
%   transition clause heads. For transition/3: Head = transition(In, Next, _).
%   For transition/4: Head = transition(In, _Base, Next, _). If Next is not a
%   state(...) compound (some modules use the form transition(qA, qB, Label) to
%   denote bare state-atom transitions), Names is still collected.
next_state_names(clause(transition(_, Next, _), _), Names) :-
    !,
    collect_names_from_next_slot(Next, Names).
next_state_names(clause(transition(_, _, Next, _), _), Names) :-
    !,
    collect_names_from_next_slot(Next, Names).
next_state_names(_, []).

collect_names_from_next_slot(Next, Names) :-
    ( atom(Next) -> Names = [Next]
    ; compound(Next), functor(Next, state, _) ->
        Next =.. [state, N | _],
        ( atom(N) -> Names = [N] ; Names = [] )
    ; Names = []
    ).
