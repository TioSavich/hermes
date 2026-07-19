/** <module> cw_normative_crisis — canonical view of normative-crisis handling
 *
 * Wave 2 of the canonical-vocabulary pass (see crosswalk/canonical_vocabulary.pl
 * for the Wave 1 style this follows: catch-guarded, source-tagged clauses +
 * canonical_concept/2 + vocabulary_source/2, with empty-import use_module of the
 * real source modules).
 *
 * Concept family: "Normative crisis handling" — the learner detecting that a
 * core arithmetic operation is prohibited in the current mathematical domain
 * (e.g. subtracting a larger from a smaller in the naturals), and the recovery
 * that expands the domain (N -> Z -> Q).
 *
 * The four scattered functors do NOT share an arity or a kind. The audit found
 * two distinct roles, so this module does NOT force a single value-returning
 * union (decision: registry_only). It provides:
 *
 *   1. normative_crisis_unified(?Context, ?Goal, -Source) — a SAFE, side-effect
 *      -free union query. Only the one genuinely fact-shaped, non-mutating
 *      member (prohibition/2) is wired into it. It enumerates the
 *      domain/operation pairs that count as a normative crisis. Source is
 *      `prohibition` for that member. The query now delegates through
 *      normative_crisis_witness/4, which records the live finite configuration
 *      needed for the prohibition to hold.
 *
 *   2. normative_crisis_variant/2 — the registry: each legacy functor mapped to
 *      its real module:functor/arity and its role, so a caller can see the whole
 *      family (including the two executors that must NOT be called from a
 *      side-effect-free query).
 *
 * Why registry_only rather than a full union:
 *   - prohibition/2        (sequent_engine, via include of learner/axioms_domains)
 *       a fact-rule: prohibition(Context, Goal). Queryable, non-mutating. Depends
 *       on the `domains` axiom pack being enabled and a current_domain set — the
 *       canonical predicate does NOT enable/set these (no global mutation); it
 *       reports whatever the live configuration yields. WIRED.
 *   - normative_crisis/2   (sequent_engine, declared :- dynamic, 0 clauses)
 *       used as a THROWN EXCEPTION TERM normative_crisis(Goal, Context), not as
 *       stored facts. As a predicate it has no clauses, so it contributes nothing
 *       to a query. Recorded in the registry as role exception_term. NOT wired.
 *   - check_norms/1        (sequent_engine)
 *       an EXECUTOR: throws normative_crisis(...) or calls incur_cost/1. Side
 *       -effecting; a value-returning union cannot safely call it. Registry only.
 *   - handle_normative_crisis/2 (reorganization_engine)
 *       an EXECUTOR: writeln/2, set_domain, assertz, log_event. Heavily
 *       side-effecting recovery driver. Registry only.
 *
 * Read-only: nothing here renames, rewrites, or calls a side-effecting source.
 * Every source call is wrapped in catch/3 so an absent/erroring source
 * contributes nothing.
 */
:- module(cw_normative_crisis,
          [ normative_crisis_unified/3,   % normative_crisis_unified(?Context, ?Goal, -Source)
            normative_crisis_witness/4,   % normative_crisis_witness(?Context, ?Goal, ?Source, -Witness)
            normative_crisis_variant/2,   % normative_crisis_variant(LegacyFunctor, ModuleFunctorArity:Role)
            canonical_concept/2,          % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2           % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

% Source modules. Both load clean and co-load clean (verified). prohibition/2,
% normative_crisis/2, check_norms/1 are exported by sequent_engine (which
% :- include's learner/axioms_domains where they are actually defined).
% handle_normative_crisis/2 is exported by reorganization_engine. Empty import
% lists: we call everything module-qualified, no names pulled into this module.
:- use_module(arche_trace(sequent_engine), []).
:- use_module(learner(reorganization_engine), []).

%! normative_crisis_unified(?Context, ?Goal, -Source) is nondet.
%
%  True when operating Goal in mathematical Context constitutes a normative
%  crisis (a prohibited operation in the current domain), according to the one
%  fact-shaped, non-mutating member of the family. Source identifies it.
%
%  Source:
%   - prohibition : sequent_engine:prohibition/2 (via learner/axioms_domains).
%
%  Side-effect-free: this does NOT enable the `domains` axiom pack nor set the
%  current domain; it reports whatever the live configuration yields. With the
%  pack disabled it simply succeeds zero times. once/1 guards against any
%  backtracking-into-cost behaviour in the underlying grounded-arithmetic checks.
normative_crisis_unified(Context, Goal, prohibition) :-
    normative_crisis_witness(Context, Goal, prohibition, _).


%! normative_crisis_witness(?Context, ?Goal, ?Source, -Witness) is nondet.
%
%  Witnessed form of `normative_crisis_unified/3`. This is a closed-world
%  finite query over the currently loaded domain axiom pack and current domain.
%  It does not decide every possible normative crisis in an open arithmetic
%  language; it records the live configuration under which the non-mutating
%  prohibition relation accepted this Context/Goal pair.
normative_crisis_witness(Context, Goal, Source,
                         WitnessDict92) :-
    witness_dict:witness_dict(normative_crisis, closed_world_finite_live_domain_configuration,
                              _{source: Source,
                            legacy_functor: LegacyFunctor,
                            context: Context,
                            goal: Goal,
                            goal_family: GoalFamily,
                            derivation: Derivation,
                            support: Support }, WitnessDict92),
    normative_crisis_source(Source, LegacyFunctor),
    source_normative_crisis_witness(Source,
                                    Context,
                                    Goal,
                                    GoalFamily,
                                    Derivation,
                                    Support).


normative_crisis_source(prohibition,
                        'sequent_engine:prohibition/2').


source_normative_crisis_witness(prohibition,
                                Context,
                                Goal,
                                GoalFamily,
                                non_mutating_prohibition_query,
                                _{ domains_pack_enabled: DomainsEnabled,
                                   current_domain: CurrentDomain,
                                   current_context: CurrentContext }) :-
    catch(once(sequent_engine:prohibition(Context, Goal)), _, fail),
    domains_pack_enabled(DomainsEnabled),
    catch(sequent_engine:current_domain(CurrentDomain), _, CurrentDomain = unknown),
    catch(sequent_engine:current_domain_context(CurrentContext), _, CurrentContext = unknown),
    goal_family(Goal, GoalFamily).


domains_pack_enabled(true) :-
    catch(sequent_engine:enabled_axiom_pack(domains), _, fail),
    !.
domains_pack_enabled(false).


goal_family(subtract(Minuend, Subtrahend, _),
            subtract_larger_from_smaller_in_naturals) :-
    number(Minuend),
    number(Subtrahend),
    Subtrahend > Minuend,
    !.
goal_family(subtract(_, _, _), subtraction_not_closed_in_current_domain) :-
    !.
goal_family(divide(_, _, _), division_not_closed_in_current_domain) :-
    !.
goal_family(Goal, other_core_operation) :-
    nonvar(Goal).

%! normative_crisis_variant(?LegacyFunctor, ?Spec) is nondet.
%
%  The registry. Spec = ModuleFunctorArity : Role.
%  Role is one of: queryable_fact, exception_term, executor.
normative_crisis_variant(prohibition/2,
    'sequent_engine:prohibition/2' : queryable_fact).
normative_crisis_variant(normative_crisis/2,
    'sequent_engine:normative_crisis/2' : exception_term).
normative_crisis_variant(check_norms/1,
    'sequent_engine:check_norms/1' : executor).
normative_crisis_variant(handle_normative_crisis/2,
    'reorganization_engine:handle_normative_crisis/2' : executor).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
canonical_concept('sequent_engine:prohibition/2',                    normative_crisis).
canonical_concept('sequent_engine:normative_crisis/2',               normative_crisis).
canonical_concept('sequent_engine:check_norms/1',                    normative_crisis).
canonical_concept('reorganization_engine:handle_normative_crisis/2', normative_crisis).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is det.
vocabulary_source(normative_crisis,
    [ 'sequent_engine:prohibition/2',
      'sequent_engine:normative_crisis/2',
      'sequent_engine:check_norms/1',
      'reorganization_engine:handle_normative_crisis/2' ]).
