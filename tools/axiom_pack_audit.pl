% Axiom pack audit and hierarchy witnesses.
%
% Run from the repository root:
%   swipl -q -s tools/axiom_pack_audit.pl -g run_audit -t halt

:- module(axiom_pack_audit,
          [ run_audit/0,
            audit_passes/0,
            audit_result/3,
            hierarchy_proof_witness/2,
            hierarchy_witness/1,
            print_eml_hierarchy/0,
            print_domain_hierarchy/0,
            print_number_theory_hierarchy/0
          ]).

:- user:ensure_loaded('../paths').
:- user:ensure_loaded(arche_trace(load)).

:- use_module(library(lists), [subtract/3]).

:- op(500, fx, comp_nec).
:- op(500, fx, exp_nec).
:- op(500, fx, exp_poss).
:- op(500, fx, comp_poss).
:- op(500, fx, neg).
:- op(1050, xfy, =>).
:- op(550, xfy, rdiv).

:- dynamic audit_failure/2.

run_audit :-
    retractall(audit_failure(_, _)),
    nl,
    writeln('=== Axiom Pack Audit ==='),
    print_enabled_packs,
    forall(audit_obligation(Name, Description, Goal),
           run_obligation(Name, Description, Goal)),
    print_hierarchy_witnesses,
    findall(Name-Reason, audit_failure(Name, Reason), Failures),
    (   Failures = []
    ->  writeln(''),
        writeln('Axiom pack audit passed.')
    ;   writeln(''),
        writeln('Axiom pack audit failed:'),
        forall(member(Failure, Failures),
               format('  ~q~n', [Failure])),
        fail
    ).

audit_passes :-
    \+ ( audit_result(_, _, Result),
         Result \== pass
       ).

audit_result(Name, Description, Result) :-
    audit_obligation(Name, Description, Goal),
    (   catch(call(Goal), Error, true)
    ->  (   var(Error)
        ->  Result = pass
        ;   Result = error(Error)
        )
    ;   Result = failed
    ).

print_enabled_packs :-
    findall(Pack, sequent_engine:enabled_axiom_pack(Pack), Packs0),
    sort(Packs0, Packs),
    format('enabled_packs(~q).~n', [Packs]).

run_obligation(Name, Description, Goal) :-
    (   catch(call(Goal),
              Error,
              ( assertz(audit_failure(Name, error(Error))),
                fail ))
    ->  format('ok(~w).  % ~w~n', [Name, Description])
    ;   ( audit_failure(Name, _)
        -> true
        ;  assertz(audit_failure(Name, failed(Description)))
        ),
        format('fail(~w).  % ~w~n', [Name, Description])
    ).

safe(Sequent, Packs) :-
    sequent_engine:safe_proves(Sequent,
                                          [time_limit(2), packs(Packs)]).

not_safe(Sequent, Packs) :-
    \+ safe(Sequent, Packs).

with_domain(Domain, Goal) :-
    (   sequent_engine:current_domain(Saved)
    ->  true
    ;   Saved = n
    ),
    setup_call_cleanup(
        sequent_engine:set_domain(Domain),
        call(Goal),
        sequent_engine:set_domain(Saved)
    ).

throws_normative_crisis(Goal, Context) :-
    catch((sequent_engine:check_norms(Goal), fail),
          normative_crisis(_, Context),
          true).

all_default_packs_enabled :-
    enabled_packs(Packs),
    Packs == [domains, eml, geometry, number_theory, robinson].

enabled_packs(Packs) :-
    findall(Pack, sequent_engine:enabled_axiom_pack(Pack), Packs0),
    sort(Packs0, Packs).

audit_obligation(default_packs_enabled,
                 'all five default axiom packs are enabled after load',
                 all_default_packs_enabled).

audit_obligation(geometry_strength_square_rectangle,
                 'geometry proves square as inferentially stronger than rectangle',
                 safe([n(square(x))] => [n(rectangle(x))], [geometry])).

audit_obligation(geometry_rejects_rectangle_square_converse,
                 'geometry rejects the invalid rectangle-to-square converse',
                 not_safe([n(rectangle(x))] => [n(square(x))], [geometry])).

audit_obligation(geometry_hard_no_incoherence,
                 'geometry detects a hard-no restriction as incoherent',
                 sequent_engine:incoherent([n(square(x)), n(r6(x))])).

audit_obligation(robinson_arithmetic_grounding,
                 'Robinson arithmetic proves a grounded addition fact',
                 safe([] => [o(plus(3, 2, 5))], [robinson, domains])).

audit_obligation(robinson_rejects_wrong_sum,
                 'Robinson arithmetic rejects a false addition fact',
                 not_safe([] => [o(plus(3, 2, 6))], [robinson, domains])).

audit_obligation(robinson_q1_incoherence,
                 'Robinson Q1 marks successor-zero identity as incoherent',
                 sequent_engine:incoherent([o(eq(succ(0), 0))])).

audit_obligation(domain_n_to_z_expansion,
                 'natural-number subtraction crisis is resolved by integer expansion',
                 ( with_domain(n, throws_normative_crisis(subtract(2, 3, _),
                                                          natural_numbers)),
                   with_domain(z, safe([] => [o(minus(2, 3, -1))],
                                       [robinson, domains]))
                 )).

audit_obligation(domain_n_to_q_expansion,
                 'natural-number division crisis is resolved by rational partitioning',
                 ( with_domain(n, throws_normative_crisis(divide(1, 2, _),
                                                          natural_numbers)),
                   with_domain(q, sequent_engine:check_norms(divide(1, 2, _))),
                   safe([] => [o(partition(1, 2, 1 rdiv 2))],
                        [robinson, domains])
                 )).

audit_obligation(number_theory_prime_grounding,
                 'number theory proves primality for Euclid witness 31',
                 safe([] => [n(prime(31))], [number_theory])).

audit_obligation(number_theory_completeness_self_defeat,
                 'finite prime-list completeness derives its own negation',
                 safe([n(is_complete([2, 3, 5]))] =>
                      [n(neg(is_complete([2, 3, 5])))],
                      [number_theory])).

audit_obligation(eml_direct_modal_commitment,
                 'EML proves the direct letting-go modal commitment',
                 safe([s(lg)] => [s(exp_nec(u_prime))], [eml])).

audit_obligation(eml_necessity_cashout,
                 'EML necessity cashes out into a material state transition',
                 safe([s(lg)] => [s(u_prime)], [eml])).

audit_obligation(pack_isolation,
                 'a geometry-only horizon does not prove arithmetic facts',
                 not_safe([] => [o(plus(1, 2, 3))], [geometry])).

shape(square).
shape(rectangle).
shape(rhombus).
shape(parallelogram).
shape(kite).
shape(trapezoid).
shape(quadrilateral).

restriction_set(Shape, Restrictions) :-
    findall(R, sequent_engine:incompatible_pair(Shape, R), Raw),
    sort(Raw, Restrictions).

strength_value(Shape, Strength) :-
    restriction_set(Shape, Restrictions),
    length(Restrictions, Strength).

geometry_strength_profile(Shape, Strength, Restrictions) :-
    shape(Shape),
    strength_value(Shape, Strength),
    restriction_set(Shape, Restrictions).

proper_entails(Strong, Weak) :-
    Strong \== Weak,
    sequent_engine:entails_via_incompatibility(Strong, Weak).

shape_term(Shape, X, Term) :-
    Term =.. [Shape, X].

proved_geometry_edge(Strong, Weak) :-
    shape_term(Strong, x, StrongTerm),
    shape_term(Weak, x, WeakTerm),
    safe([n(StrongTerm)] => [n(WeakTerm)], [geometry]).

geometry_cover_edge(Strong, Weak, ExtraRejections) :-
    shape(Strong),
    shape(Weak),
    proper_entails(Strong, Weak),
    proved_geometry_edge(Strong, Weak),
    \+ ( shape(Middle),
         Middle \== Strong,
         Middle \== Weak,
         proper_entails(Strong, Middle),
         proper_entails(Middle, Weak)
       ),
    restriction_set(Strong, StrongRestrictions),
    restriction_set(Weak, WeakRestrictions),
    subtract(StrongRestrictions, WeakRestrictions, ExtraRejections).

%!  hierarchy_proof_witness(+Kind, -Witness) is semidet.
%
%   Structured proof object for hierarchy facts. This is the reusable surface
%   for graph exporters and semantic-sanitation agents; `hierarchy_witness/1`
%   remains as the compact compatibility predicate.
hierarchy_proof_witness(geometry_cover(Strong, Weak), Witness) :-
    geometry_cover_edge_witness(Strong, Weak, Witness).
hierarchy_proof_witness(eml_necessity_cashout(From, ActualTo), Witness) :-
    eml_necessity_cashout_hierarchy_witness(From, ActualTo, Witness).
hierarchy_proof_witness(domain_expansion(n_to_z), Witness) :-
    domain_expansion_n_to_z_witness(Witness).
hierarchy_proof_witness(domain_expansion(n_to_q), Witness) :-
    domain_expansion_n_to_q_witness(Witness).
hierarchy_proof_witness(number_theory_self_defeat(List), Witness) :-
    number_theory_self_defeat_hierarchy_witness(List, Witness).

geometry_cover_edge_witness(Strong, Weak,
                            _{ kind: geometry_cover,
                               strong: Strong,
                               weak: Weak,
                               extra_rejections: ExtraRejections,
                               entailment_witness: EntailmentWitness,
                               sequent: Sequent,
                               sequent_status: proved_by_geometry_pack,
                               cover_status: no_intermediate_shape,
                               intermediate_checks: IntermediateChecks }) :-
    geometry_cover_edge(Strong, Weak, ExtraRejections),
    sequent_engine:entails_via_incompatibility_witness(Strong, Weak, EntailmentWitness),
    shape_term(Strong, x, StrongTerm),
    shape_term(Weak, x, WeakTerm),
    Sequent = ([n(StrongTerm)] => [n(WeakTerm)]),
    safe(Sequent, [geometry]),
    findall(Check,
            ( shape(Middle),
              Middle \== Strong,
              Middle \== Weak,
              geometry_intermediate_check(Strong, Weak, Middle, Check)
            ),
            IntermediateChecks),
    \+ memberchk(_{result: valid_intermediate}, IntermediateChecks).

geometry_intermediate_check(Strong, Weak, Middle,
                            _{ kind: geometry_intermediate_check,
                               strong: Strong,
                               middle: Middle,
                               weak: Weak,
                               strong_entails_middle: StrongEntailsMiddle,
                               middle_entails_weak: MiddleEntailsWeak,
                               strong_middle_witness: StrongMiddleWitness,
                               middle_weak_witness: MiddleWeakWitness,
                               result: Result }) :-
    geometry_entailment_status(Strong, Middle,
                               StrongEntailsMiddle,
                               StrongMiddleWitness),
    geometry_entailment_status(Middle, Weak,
                               MiddleEntailsWeak,
                               MiddleWeakWitness),
    (   StrongEntailsMiddle == true,
        MiddleEntailsWeak == true
    ->  Result = valid_intermediate
    ;   Result = blocked
    ).

geometry_entailment_status(Entailer, Entailed, true, Witness) :-
    sequent_engine:entails_via_incompatibility_witness(Entailer, Entailed, Witness),
    !.
geometry_entailment_status(Entailer, Entailed, false,
                           _{ kind: missing_geometry_entailment,
                              entailer: Entailer,
                              entailed: Entailed }) :-
    \+ sequent_engine:entails_via_incompatibility(Entailer, Entailed).

eml_necessity_cashout_hierarchy_witness(From, ActualTo,
                                        _{ kind: eml_necessity_cashout,
                                           from: From,
                                           modal_to: ModalTo,
                                           actual_to: ActualTo,
                                           modal_sequent: ModalSequent,
                                           actual_sequent: ActualSequent,
                                           modal_sequent_status: proved_by_eml_pack,
                                           actual_sequent_status: proved_by_eml_pack,
                                           transition_witness: TransitionWitness }) :-
    sequent_engine:eml_transition_witness(From, ActualTo, TransitionWitness),
    TransitionWitness.source == necessity_cashout,
    ModalTo = TransitionWitness.modal_to,
    ModalSequent = ([From] => [ModalTo]),
    ActualSequent = ([From] => [ActualTo]),
    safe(ModalSequent, [eml]),
    safe(ActualSequent, [eml]).

domain_expansion_n_to_z_witness(
    _{ kind: domain_expansion,
       expansion: n_to_z,
       blocked_domain: n,
       target_domain: z,
       operation: subtract(2, 3, -1),
       crisis_goal: subtract(2, 3, _),
       crisis_context: natural_numbers,
       crisis_witness: CrisisWitness,
       target_sequent: TargetSequent,
       target_sequent_status: proved_by_robinson_domains }) :-
    domain_crisis_witness(n, subtract(2, 3, _), natural_numbers, CrisisWitness),
    TargetSequent = ([] => [o(minus(2, 3, -1))]),
    with_domain(z, safe(TargetSequent, [robinson, domains])).

domain_expansion_n_to_q_witness(
    _{ kind: domain_expansion,
       expansion: n_to_q,
       blocked_domain: n,
       target_domain: q,
       operation: divide(1, 2, _),
       crisis_goal: divide(1, 2, _),
       crisis_context: natural_numbers,
       crisis_witness: CrisisWitness,
       target_operation: divide(1, 2, _),
       target_norm_status: accepted_by_target_domain,
       target_sequent: TargetSequent,
       target_sequent_status: proved_by_robinson_domains }) :-
    domain_crisis_witness(n, divide(1, 2, _), natural_numbers, CrisisWitness),
    with_domain(q, sequent_engine:check_norms(divide(1, 2, _))),
    TargetSequent = ([] => [o(partition(1, 2, 1 rdiv 2))]),
    safe(TargetSequent, [robinson, domains]).

domain_crisis_witness(Domain, Goal, Context,
                      _{ kind: domain_crisis,
                         source: normative_crisis_throw,
                         domain: Domain,
                         goal: Goal,
                         context: Context }) :-
    with_domain(Domain, throws_normative_crisis(Goal, Context)).

number_theory_self_defeat_hierarchy_witness(
    List,
    _{ kind: number_theory_self_defeat,
       list: List,
       assumption: Assumption,
       product: Product,
       euclid_number: EuclidNumber,
       prime_fact: PrimeFact,
       nonmembership: Nonmembership,
       conclusion: Conclusion,
       proof_status: finite_prime_list_refuted_by_euclid_number,
       proof_witness: ProofWitness }) :-
    sequent_engine:number_theory_self_defeat_witness(List, ProofWitness),
    Assumption = ProofWitness.assumption,
    Product = ProofWitness.product,
    EuclidNumber = ProofWitness.euclid_number,
    PrimeFact = ProofWitness.prime_case.prime_fact,
    Nonmembership = ProofWitness.prime_case.not_member,
    Conclusion = ProofWitness.conclusion.

hierarchy_witness(geometry_cover(edge(Strong, Weak,
                                      extra_rejections(ExtraRejections)))) :-
    hierarchy_proof_witness(geometry_cover(Strong, Weak), Witness),
    ExtraRejections = Witness.extra_rejections.

hierarchy_witness(domain_expansion(n_to_z(subtract(2, 3, -1)))) :-
    hierarchy_proof_witness(domain_expansion(n_to_z), _).

hierarchy_witness(domain_expansion(n_to_q(divide(1, 2, _),
                                           partition(1, 2, 1 rdiv 2)))) :-
    hierarchy_proof_witness(domain_expansion(n_to_q), _).

hierarchy_witness(eml_necessity_cashout(s(u), s(comp_nec(a)), s(a))) :-
    hierarchy_proof_witness(eml_necessity_cashout(s(u), s(a)), Witness),
    Witness.modal_to == s(comp_nec(a)).

hierarchy_witness(eml_necessity_cashout(s(lg),
                                        s(exp_nec(u_prime)),
                                        s(u_prime))) :-
    hierarchy_proof_witness(eml_necessity_cashout(s(lg), s(u_prime)), Witness),
    Witness.modal_to == s(exp_nec(u_prime)).

hierarchy_witness(number_theory_self_defeat(is_complete([2, 3, 5]))) :-
    hierarchy_proof_witness(number_theory_self_defeat([2, 3, 5]), _).

hierarchy_witness(number_theory_self_defeat_witness(Witness)) :-
    hierarchy_proof_witness(number_theory_self_defeat([2, 3, 5]), Summary),
    Witness = Summary.proof_witness.

print_hierarchy_witnesses :-
    writeln(''),
    writeln('=== Hierarchy Witnesses ==='),
    print_geometry_hierarchy,
    print_domain_hierarchy,
    print_eml_hierarchy,
    print_number_theory_hierarchy.

print_geometry_hierarchy :-
    writeln('geometry_incompatibility_strength:'),
    forall(geometry_strength_profile(Shape, Strength, Restrictions),
           format('  strength(~w, ~w, rejects(~q)).~n',
                  [Shape, Strength, Restrictions])),
    findall(Edge,
            hierarchy_witness(geometry_cover(Edge)),
            Edges),
    sort(Edges, Sorted),
    forall(member(Edge, Sorted),
           format('  cover(~q).~n', [Edge])).

print_domain_hierarchy :-
    writeln('domain_expansion_witnesses:'),
    forall(member(Kind, [domain_expansion(n_to_z), domain_expansion(n_to_q)]),
           ( hierarchy_proof_witness(Kind, Witness),
             canonical_atom(Witness.operation, Operation),
             format('  domain_expansion(name(~w), blocked_domain(~w), target_domain(~w), operation(~w), proof(~w)).~n',
                    [ Witness.expansion,
                      Witness.blocked_domain,
                      Witness.target_domain,
                      Operation,
                      Witness.target_sequent_status
                    ])
           )).

print_eml_hierarchy :-
    writeln('eml_necessity_witnesses:'),
    forall(member(Kind,
                  [ eml_necessity_cashout(s(u), s(a)),
                    eml_necessity_cashout(s(lg), s(u_prime))
                  ]),
           ( hierarchy_proof_witness(Kind, Witness),
             canonical_atom(Witness.from, From),
             canonical_atom(Witness.modal_to, ModalTo),
             canonical_atom(Witness.actual_to, ActualTo),
             Source = Witness.transition_witness.source,
             format('  necessity_cashout(from(~w), modal_to(~w), actual_to(~w), source(~w)).~n',
                    [From, ModalTo, ActualTo, Source])
           )).

canonical_atom(Term, Atom) :-
    with_output_to(atom(Atom), write_canonical(Term)).

print_number_theory_hierarchy :-
    writeln('number_theory_incoherence_witnesses:'),
    hierarchy_proof_witness(number_theory_self_defeat([2, 3, 5]), Witness),
    canonical_atom(Witness.list, List),
    canonical_atom(Witness.conclusion, Conclusion),
    format('  euclid_self_defeat(list(~w), product(~w), euclid_number(~w), conclusion(~w)).~n',
           [List, Witness.product, Witness.euclid_number, Conclusion]).
