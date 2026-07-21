/** <module> cw_driver -- shared execution for mechanical crosswalk families.
 *
 * The claim-table family files contain only recorded clauses as cw_rule/1
 * data.  This module supplies their query surface and executes those recorded
 * clauses in family context.  Each data family also records its owner-predicate
 * edges with one of the seven probe archetypes below.
 */
:- module(cw_driver,
          [ algebra_claim_unified/3,
            archetype/1,
            accommodation_unified/2,
            action_cluster_unified/4,
            arithmetic_property_unified/3,
            axiom_pack_unified/2,
            axiom_pack_control/4,
            calculus_claim_unified/3,
            decimal_claim_unified/3,
            deontic_incoherence_unified/3,
            domain_context_unified/3,
            executable_practice_unified/4,
            fraction_extra_claim_unified/3,
            family_edge/6,
            fsm_engine_unified/2,
            godel_primes_unified/3,
            grounded_arith_unified/4,
            grounding_metaphor_unified/3,
            integer_signed_claim_unified/3,
            magnitude_equivalence_claim_unified/3,
            material_inference_unified/4,
            metaphor_break_unified/4,
            misconception_hook_unified/5,
            modal_context_unified/3,
            mua_coherence_unified/4,
            mua_coherence_source_witness/5,
            multiplication_division_claim_unified/3,
            normative_crisis_unified/3,
            normative_crisis_variant/2,
            orr_entry_unified/4,
            practice_vocabulary_unified/3,
            productive_deformation_unified/5,
            ratio_proportion_claim_unified/3,
            sequent_proof_unified/2,
            strategy_action_kind_unified/3,
            stress_map_unified/3,
            unit_coordination_unified/3,
            viability_unified/3,
            whole_number_addsub_claim_unified/3
          ]).

:- use_module(library(error), [must_be/2]).
:- use_module(library(lists), [append/2, member/2]).

% Owner predicates needed by the mechanical family rows.
:- use_module(sequent(sequent_engine), []).
:- use_module(formalization(grounded_arithmetic), []).
:- use_module(formalization(grounding_metaphors), []).
:- use_module(misconceptions(literature_vocabulary), []).
:- use_module(misconceptions(misconception_registry), []).
:- use_module(strategies('math/action_automata_registry'), []).
:- use_module(strategies('math/fraction_action_pairs'), []).

% One keyed table holds the recorded clauses and owner-predicate edges for all
% driver-backed families. The four own-surface families remain separate.
:- use_module(crosswalk('families/cw_edges'), []).

data_family(Family) :-
    cw_edges:family(Family).

%! family_edge(+Family, ?Module, ?Predicate, ?Args, ?Outputs, ?Archetype) is nondet.
family_edge(Family, Module, Predicate, Args, Outputs, Archetype) :-
    data_family(Family),
    cw_edges:edge(Family, Module, Predicate, Args, Outputs, Archetype).

% Closed enum for how a recorded edge probes its owner predicate.
archetype(call_bind_out).
archetype(call_match_ground).
archetype(call_once_bind_out).
archetype(call_guarded_numeric).
archetype(call_with_snapshot).
archetype(call_aggregate).
archetype(registry_projection).

%! family_witness(+Family, +Predicate, ?Canonical, ?Detail, ?Source, -Witness) is nondet.
family_witness(Family, Predicate, A, B, Witness) :-
    must_be(atom, Predicate),
    Goal =.. [Predicate, A, B, Witness],
    family_call(Family, Goal).
family_witness(Family, Predicate, Canonical, Detail, Source, Witness) :-
    must_be(atom, Predicate),
    Goal =.. [Predicate, Canonical, Detail, Source, Witness],
    family_call(Family, Goal).
family_witness(Family, Predicate, A, B, C, D, Witness) :-
    must_be(atom, Predicate),
    Goal =.. [Predicate, A, B, C, D, Witness],
    family_call(Family, Goal).
family_witness(Family, Predicate, A, B, C, D, E, Witness) :-
    must_be(atom, Predicate),
    Goal =.. [Predicate, A, B, C, D, E, Witness],
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

accommodation_unified(A, B) :- family_call(cw_accommodation, accommodation_unified(A, B)).
action_cluster_unified(A, B, C, D) :- family_call(cw_action_cluster, action_cluster_unified(A, B, C, D)).
axiom_pack_unified(A, B) :- family_call(cw_axiom_pack, axiom_pack_unified(A, B)).
axiom_pack_control(A, B, C, D) :- family_call(cw_axiom_pack, axiom_pack_control(A, B, C, D)).
deontic_incoherence_unified(A, B, C) :- family_call(cw_deontic_incoherence, deontic_incoherence_unified(A, B, C)).
domain_context_unified(A, B, C) :- family_call(cw_domain_context, domain_context_unified(A, B, C)).
executable_practice_unified(A, B, C, D) :- family_call(cw_executable_practice, executable_practice_unified(A, B, C, D)).
fsm_engine_unified(A, B) :- family_call(cw_fsm_engine, fsm_engine_unified(A, B)).
godel_primes_unified(A, B, C) :- family_call(cw_godel_primes, godel_primes_unified(A, B, C)).
grounded_arith_unified(A, B, C, D) :- family_call(cw_grounded_arith, grounded_arith_unified(A, B, C, D)).
grounding_metaphor_unified(A, B, C) :- family_call(cw_grounding_metaphor, grounding_metaphor_unified(A, B, C)).
material_inference_unified(A, B, C, D) :- family_call(cw_material_inference, material_inference_unified(A, B, C, D)).
metaphor_break_unified(A, B, C, D) :- family_call(cw_metaphor_break, metaphor_break_unified(A, B, C, D)).
misconception_hook_unified(A, B, C, D, E) :- family_call(cw_misconception_hook, misconception_hook_unified(A, B, C, D, E)).
modal_context_unified(A, B, C) :- family_call(cw_modal_context, modal_context_unified(A, B, C)).
mua_coherence_unified(A, B, C, D) :- family_call(cw_mua_coherence, mua_coherence_unified(A, B, C, D)).
mua_coherence_source_witness(A, B, C, D, E) :- family_call(cw_mua_coherence, mua_coherence_source_witness(A, B, C, D, E)).
normative_crisis_unified(A, B, C) :- family_call(cw_normative_crisis, normative_crisis_unified(A, B, C)).
normative_crisis_variant(A, B) :- family_call(cw_normative_crisis, normative_crisis_variant(A, B)).
orr_entry_unified(A, B, C, D) :- family_call(cw_orr_entry, orr_entry_unified(A, B, C, D)).
practice_vocabulary_unified(A, B, C) :- family_call(cw_practice_vocabulary, practice_vocabulary_unified(A, B, C)).
productive_deformation_unified(A, B, C, D, E) :- family_call(cw_productive_deformation, productive_deformation_unified(A, B, C, D, E)).
sequent_proof_unified(A, B) :- family_call(cw_sequent_proof, sequent_proof_unified(A, B)).
stress_map_unified(A, B, C) :- family_call(cw_stress_map, stress_map_unified(A, B, C)).
unit_coordination_unified(A, B, C) :- family_call(cw_unit_coordination, unit_coordination_unified(A, B, C)).
viability_unified(A, B, C) :- family_call(cw_viability, viability_unified(A, B, C)).

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
solve_family_goal(Family, call(Goal)) :- !,
    solve_family_goal(Family, Goal).
solve_family_goal(Family, ignore(Goal)) :- !,
    ignore(solve_family_goal(Family, Goal)).
solve_family_goal(Family, catch(Goal, Error, Handler)) :- !,
    catch(solve_family_goal(Family, Goal),
          Error,
          solve_family_goal(Family, Handler)).
solve_family_goal(Family, findall(Template, Goal, List)) :- !,
    findall(Template, solve_family_goal(Family, Goal), List).
solve_family_goal(Family, forall(Generator, Test)) :- !,
    forall(solve_family_goal(Family, Generator), solve_family_goal(Family, Test)).
solve_family_goal(Family, maplist(Predicate, List)) :- !,
    maplist(family_apply(Family, Predicate), List).
solve_family_goal(Family, maplist(Predicate, Left, Right)) :- !,
    maplist(family_apply(Family, Predicate), Left, Right).
solve_family_goal(Family, setup_call_cleanup(Setup, Goal, Cleanup)) :- !,
    setup_call_cleanup(solve_family_goal(Family, Setup),
                       solve_family_goal(Family, Goal),
                       solve_family_goal(Family, Cleanup)).
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
    once(( family_rule(Family, Rule),
           rule_head(Rule, Head),
           functor(Head, Name, Arity) )).

family_clause(Family, Goal, Body) :-
    family_rule(Family, Rule),
    rule_clause(Rule, Head, Body),
    Goal = Head.

family_rule(Family, Rule) :-
    cw_edges:rule(Family, Rule).

rule_head((Head :- _), Head) :- !.
rule_head(Head, Head).

rule_clause((Head :- Body), Head, Body) :- !.
rule_clause(Head, Head, true).

call_expanded(Goal) :-
    expand_goal(Goal, Expanded),
    call(Expanded).

family_apply(Family, Predicate, A) :-
    extend_goal(Predicate, [A], Goal),
    solve_family_goal(Family, Goal).
family_apply(Family, Predicate, A, B) :-
    extend_goal(Predicate, [A, B], Goal),
    solve_family_goal(Family, Goal).

extend_goal(Module:Closure, Extra, Module:Goal) :- !,
    extend_goal(Closure, Extra, Goal).
extend_goal(Closure, Extra, Goal) :-
    Closure =.. Parts,
    append(Parts, Extra, GoalParts),
    Goal =.. GoalParts.
