/** <module> cw_domain_context — canonical query for the "domain context state" family
 *
 * Problem this solves: the learner's current mathematical domain (natural
 * numbers, integers, rationals) is read through more than one functor. The
 * raw reader returns a short atom (n / z / q); a second reader projects that
 * same state onto a named context (natural_numbers / integers / rationals).
 * Both are exported by the sequent_engine module (which :- includes
 * learner/axioms_domains.pl, the file that actually defines them). A third
 * functor, set_domain/1, is the SETTER for this state, not a reader.
 *
 * This module renames nothing. It adds ONE read-only canonical query,
 * domain_context_unified/3, that ranges over the two readers and tags which
 * one each answer came from. Every source call is guarded with catch/3 so an
 * absent or erroring source contributes nothing. The setter set_domain/1 is
 * deliberately NOT called here (it does retractall/assertz); it is recorded
 * in vocabulary_source/2 and canonical_concept/2 as a documented variant only.
 *
 * Projection note (different shapes normalized to one):
 *   - current_domain/1 yields the bare atom Domain (n/z/q). For this source
 *     Context is left unbound — the raw reader does not carry it.
 *   - current_domain_context/1 yields the named Context (natural_numbers/...).
 *     For this source Domain is left unbound — the context reader does not
 *     carry the bare atom.
 *   So domain_context_unified(?Domain, ?Context, -Source) is a union over two
 *   partial views of one underlying state; neither source fills both fields,
 *   which is faithful to how the code stores it (one dynamic fact, two readers).
 *
 * Owner-module choice: both readers are wired through arche_trace(sequent_engine),
 * the module the rest of the system already loads. learner/axioms_domains.pl is
 * an include-only file (no :- module, depends on includer-supplied predicates),
 * so it is intentionally NOT loaded standalone.
 */
:- module(cw_domain_context,
          [ domain_context_unified/3,   % domain_context_unified(?Domain, ?Context, -Source)
            domain_context_witness/4,   % domain_context_witness(?Domain, ?Context, ?Source, -Witness)
            canonical_concept/2,        % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2         % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

% Wire the owner module the rest of the system loads. Empty import list:
% we call it module-qualified, so nothing is pulled into this module's namespace.
:- use_module(arche_trace(sequent_engine), []).

%! domain_context_unified(?Domain, ?Context, -Source) is nondet.
%
%  True for the learner's current mathematical-domain state, read through ANY
%  reader layer. Source names which reader produced the answer:
%   - domain_atom    : sequent_engine:current_domain/1 (bare atom n/z/q;
%                      Context left unbound)
%   - domain_context : sequent_engine:current_domain_context/1 (named context
%                      natural_numbers/integers/rationals; Domain left unbound)
%
%  The setter sequent_engine:set_domain/1 is NOT wired here (it mutates state).
domain_context_unified(Domain, _Context, domain_atom) :-
    domain_context_witness(Domain, not_projected_by_source, domain_atom, _).
domain_context_unified(_Domain, Context, domain_context) :-
    domain_context_witness(not_projected_by_source, Context, domain_context, _).

%! domain_context_witness(?Domain, ?Context, ?Source, -Witness) is nondet.
%
%  Witnessed form of `domain_context_unified/3`. This is a closed-world finite
%  read of the currently loaded domain-state predicates. The witness records the
%  live dynamic value and the finite domain/context mapping from
%  `learner/axioms_domains.pl`; it does not call `set_domain/1`, which mutates
%  the dynamic domain state.
domain_context_witness(Domain, Context, Source,
                       _{ kind: domain_context_crosswalk,
                          scope: closed_world_finite_loaded_domain_state,
                          source: Source,
                          legacy_functor: LegacyFunctor,
                          domain: Domain,
                          context: Context,
                          value_shape: ValueShape,
                          derivation: Derivation,
                          setter_policy: set_domain_excluded_mutates_dynamic_state,
                          source_witness: SourceWitness }) :-
    source_domain_context_witness(Source,
                                  Domain,
                                  Context,
                                  LegacyFunctor,
                                  ValueShape,
                                  Derivation,
                                  SourceWitness).

source_domain_context_witness(domain_atom,
                              Domain,
                              not_projected_by_source,
                              'sequent_engine:current_domain/1',
                              bare_domain_atom,
                              current_domain_dynamic_fact_read,
                              _{ kind: current_domain_dynamic_state,
                                 module: sequent_engine,
                                 predicate: current_domain/1,
                                 domain: Domain,
                                 finite_domain_set: [n, z, q],
                                 mapped_context: MappedContext,
                                 mapping_witness: MappingWitness }) :-
    catch(sequent_engine:current_domain(Domain), _, fail),
    domain_context_mapping_witness(Domain, MappedContext, MappingWitness).
source_domain_context_witness(domain_context,
                              not_projected_by_source,
                              Context,
                              'sequent_engine:current_domain_context/1',
                              named_context_projection,
                              current_domain_context_projection,
                              _{ kind: current_domain_context_projection,
                                 module: sequent_engine,
                                 predicate: current_domain_context/1,
                                 context: Context,
                                 current_domain: Domain,
                                 finite_context_set: [natural_numbers, integers, rationals],
                                 mapping_witness: MappingWitness }) :-
    catch(sequent_engine:current_domain_context(Context), _, fail),
    catch(sequent_engine:current_domain(Domain), _, fail),
    domain_context_mapping_witness(Domain, Context, MappingWitness).

domain_context_mapping_witness(Domain, Context,
                               _{ kind: finite_domain_context_mapping,
                                  source_file: 'learner/axioms_domains.pl',
                                  domain: Domain,
                                  context: Context,
                                  mapping_table: [n-natural_numbers,
                                                  z-integers,
                                                  q-rationals] }) :-
    domain_context_pair(Domain, Context),
    catch(sequent_engine:domain_to_context(Domain, Context), _, fail).

domain_context_pair(n, natural_numbers).
domain_context_pair(z, integers).
domain_context_pair(q, rationals).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
%
%  Maps each scattered legacy functor in this family to its canonical query.
%  set_domain/1 is mapped too (so the crosswalk records it) but is the setter,
%  not a reader, and is not called by domain_context_unified/3.
canonical_concept('sequent_engine:current_domain/1',         domain_context_unified).
canonical_concept('sequent_engine:current_domain_context/1', domain_context_unified).
canonical_concept('sequent_engine:set_domain/1',             domain_context_unified).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(domain_context_unified,
    [ 'sequent_engine:current_domain/1',
      'sequent_engine:current_domain_context/1',
      'sequent_engine:set_domain/1' ]).
