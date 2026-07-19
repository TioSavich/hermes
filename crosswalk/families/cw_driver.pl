/** <module> cw_driver -- shared execution for mechanical crosswalk families.
 *
 * The claim-table family files contain only recorded clauses as cw_rule/1
 * data.  This module supplies their query surface and executes those recorded
 * clauses in family context.  Keeping the original clause terms intact makes
 * this collapse mechanical: it does not introduce a probe-archetype taxonomy.
 */
:- module(cw_driver,
          [ algebra_claim_unified/3,
            arithmetic_property_unified/3,
            calculus_claim_unified/3,
            decimal_claim_unified/3,
            fraction_extra_claim_unified/3,
            integer_signed_claim_unified/3,
            magnitude_equivalence_claim_unified/3,
            multiplication_division_claim_unified/3,
            ratio_proportion_claim_unified/3,
            strategy_action_kind_unified/3,
            whole_number_addsub_claim_unified/3
          ]).

:- use_module(library(error), [must_be/2]).
:- use_module(library(lists), [append/2, member/2]).

% Owner predicates needed by the mechanical family rows.
:- use_module(arche_trace(sequent_engine), []).
:- use_module(formalization(grounded_arithmetic), []).
:- use_module(formalization(grounding_metaphors), []).
:- use_module(misconceptions(literature_vocabulary), []).
:- use_module(misconceptions(misconception_registry), []).
:- use_module(strategies('math/action_automata_registry'), []).
:- use_module(strategies('math/fraction_action_pairs'), []).

% The eleven source modules are data containers. Loading them here also keeps
% canonical_all's named 38-family module contract intact.
:- use_module(crosswalk('families/cw_algebra_claim'), []).
:- use_module(crosswalk('families/cw_arithmetic_property_claim'), []).
:- use_module(crosswalk('families/cw_calculus_claim'), []).
:- use_module(crosswalk('families/cw_decimal_claim'), []).
:- use_module(crosswalk('families/cw_fraction_extra_claim'), []).
:- use_module(crosswalk('families/cw_integer_signed_claim'), []).
:- use_module(crosswalk('families/cw_magnitude_equivalence_claim'), []).
:- use_module(crosswalk('families/cw_multiplication_division_claim'), []).
:- use_module(crosswalk('families/cw_ratio_proportion_claim'), []).
:- use_module(crosswalk('families/cw_strategy_action_kind'), []).
:- use_module(crosswalk('families/cw_whole_number_addsub_claim'), []).

data_family(cw_algebra_claim).
data_family(cw_arithmetic_property_claim).
data_family(cw_calculus_claim).
data_family(cw_decimal_claim).
data_family(cw_fraction_extra_claim).
data_family(cw_integer_signed_claim).
data_family(cw_magnitude_equivalence_claim).
data_family(cw_multiplication_division_claim).
data_family(cw_ratio_proportion_claim).
data_family(cw_strategy_action_kind).
data_family(cw_whole_number_addsub_claim).

%! family_witness(+Family, +Predicate, ?Canonical, ?Detail, ?Source, -Witness) is nondet.
family_witness(Family, Predicate, Canonical, Detail, Source, Witness) :-
    must_be(atom, Predicate),
    Goal =.. [Predicate, Canonical, Detail, Source, Witness],
    family_call(Family, Goal).

%! family_vocabulary_source(+Family, ?Canonical, ?LegacyFunctors) is nondet.
family_vocabulary_source(Family, Canonical, LegacyFunctors) :-
    family_call(Family, vocabulary_source(Canonical, LegacyFunctors)).

algebra_claim_unified(Canonical, Detail, Source) :-
    family_call(cw_algebra_claim, algebra_claim_unified(Canonical, Detail, Source)).
arithmetic_property_unified(Canonical, Detail, Source) :-
    family_call(cw_arithmetic_property_claim, arithmetic_property_unified(Canonical, Detail, Source)).
calculus_claim_unified(Canonical, Detail, Source) :-
    family_call(cw_calculus_claim, calculus_claim_unified(Canonical, Detail, Source)).
decimal_claim_unified(Canonical, Detail, Source) :-
    family_call(cw_decimal_claim, decimal_claim_unified(Canonical, Detail, Source)).
fraction_extra_claim_unified(Canonical, Detail, Source) :-
    family_call(cw_fraction_extra_claim, fraction_extra_claim_unified(Canonical, Detail, Source)).
integer_signed_claim_unified(Canonical, Detail, Source) :-
    family_call(cw_integer_signed_claim, integer_signed_claim_unified(Canonical, Detail, Source)).
magnitude_equivalence_claim_unified(Canonical, Detail, Source) :-
    family_call(cw_magnitude_equivalence_claim, magnitude_equivalence_claim_unified(Canonical, Detail, Source)).
multiplication_division_claim_unified(Canonical, Detail, Source) :-
    family_call(cw_multiplication_division_claim, multiplication_division_claim_unified(Canonical, Detail, Source)).
ratio_proportion_claim_unified(Canonical, Detail, Source) :-
    family_call(cw_ratio_proportion_claim, ratio_proportion_claim_unified(Canonical, Detail, Source)).
strategy_action_kind_unified(Canonical, Detail, Source) :-
    family_call(cw_strategy_action_kind, strategy_action_kind_unified(Canonical, Detail, Source)).
whole_number_addsub_claim_unified(Canonical, Detail, Source) :-
    family_call(cw_whole_number_addsub_claim, whole_number_addsub_claim_unified(Canonical, Detail, Source)).

family_call(Family, Goal) :-
    must_be(atom, Family),
    data_family(Family),
    solve_family_goal(Family, Goal).

solve_family_goal(_, true) :- !.
solve_family_goal(Family, (If -> Then ; Else)) :- !,
    (   solve_family_goal(Family, If)
    ->  solve_family_goal(Family, Then)
    ;   solve_family_goal(Family, Else)
    ).
solve_family_goal(Family, (If -> Then)) :- !,
    (   solve_family_goal(Family, If)
    ->  solve_family_goal(Family, Then)
    ).
solve_family_goal(Family, (Left, Right)) :- !,
    solve_family_goal(Family, Left),
    solve_family_goal(Family, Right).
solve_family_goal(Family, (Left ; Right)) :- !,
    (   solve_family_goal(Family, Left)
    ;   solve_family_goal(Family, Right)
    ).
solve_family_goal(Family, \+ Goal) :- !,
    \+ solve_family_goal(Family, Goal).
solve_family_goal(Family, once(Goal)) :- !,
    once(solve_family_goal(Family, Goal)).
solve_family_goal(Family, catch(Goal, Error, Handler)) :- !,
    catch(solve_family_goal(Family, Goal),
          Error,
          solve_family_goal(Family, Handler)).
solve_family_goal(Family, findall(Template, Goal, List)) :- !,
    findall(Template, solve_family_goal(Family, Goal), List).
solve_family_goal(_, Module:Goal) :- !,
    call_expanded(Module:Goal).
solve_family_goal(Family, Goal) :-
    (   family_predicate(Family, Goal)
    ->  family_clause(Family, Goal, Body),
        solve_family_goal(Family, Body)
    ;   call_expanded(Goal)
    ).

family_predicate(Family, Goal) :-
    functor(Goal, Name, Arity),
    once(( Family:cw_rule(Rule),
           rule_head(Rule, Head),
           functor(Head, Name, Arity) )).

family_clause(Family, Goal, Body) :-
    Family:cw_rule(Rule),
    rule_clause(Rule, Head, Body),
    Goal = Head.

rule_head((Head :- _), Head) :- !.
rule_head(Head, Head).

rule_clause((Head :- Body), Head, Body) :- !.
rule_clause(Head, Head, true).

call_expanded(Goal) :-
    expand_goal(Goal, Expanded),
    call(Expanded).
