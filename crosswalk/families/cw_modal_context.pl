/** <module> Canonical vocabulary family — PML modal context determination
 *
 * Wave 2 of the canonical-vocabulary pass (same pattern as
 * crosswalk/canonical_vocabulary.pl: union query, source-tagged, catch-guarded).
 *
 * Concept: "given a modal term, what is its PML modal posture?" Three scattered
 * functors all denote roughly this, at different layers and arities:
 *
 *   - meta_interpreter:is_modal_operator/2  (learner/meta_interpreter.pl)
 *       is_modal_operator(?Goal, ?ModalContext). Fact table over the four
 *       polarized operators (comp_nec/comp_poss -> compressive,
 *       exp_nec/exp_poss -> expansive). Used by solve/4 to switch inference
 *       cost. Enumerable (it is a fact table), so it also serves as the
 *       generator when Term is unbound.
 *
 *   - embodied_prover:determine_modal_context/2  (arche-trace/embodied_prover.pl)
 *       determine_modal_context(+ModalOperatorTerm, -Context). Same mapping as
 *       above but computed via functor/3 + (->) rather than facts; it is det and
 *       requires Term bound (an unbound Term leaves the (->) chain with nothing
 *       to dispatch on, so it simply fails — caught and contributes nothing).
 *
 *   - embodied_prover:is_pml_modality/1  (arche-trace/embodied_prover.pl)
 *       is_pml_modality(+M). A recognizer (arity 1) for a MODE-WRAPPED operator:
 *       M = D(OpTerm) with D in {s,o,n} and OpTerm one of the four polarized
 *       operators. This sits one layer up from the other two: it confirms a term
 *       is a well-formed S/O/N-mode PML modality, but returns no compressive/
 *       expansive context of its own.
 *
 * PROJECTION to a common shape, modal_context_unified(?Term, ?Context, -Source):
 *   - For meta_interpreter and embodied_prover the native shape is already
 *     (Term, Context); Term is a bare polarized operator and Context is
 *     compressive|expansive.
 *   - For is_pml_modality (arity 1, recognizer-only) we project to arity 2 by
 *     peeling the inner polarized operator out of the mode wrapper and deriving
 *     the same compressive|expansive Context from its polarity. So a mode-wrapped
 *     term s(comp_nec(P)) yields Context=compressive under Source=pml_modality.
 *     This projection is read-only and lossless of the recognizer's own verdict
 *     (it still requires is_pml_modality/1 to succeed first).
 *
 * Every source call is wrapped in catch(Goal, _, fail). All three sources are
 * pure semidet checks/fact lookups (no assert/retract, no proof search), so no
 * once/1 guarding is required. This is a read-only union view; nothing existing
 * is renamed or rewritten.
 */
:- module(cw_modal_context,
          [ modal_context_unified/3,   % modal_context_unified(?Term, ?Context, -Source)
            modal_context_witness/4,   % modal_context_witness(?Term, ?Context, ?Source, -Witness)
            canonical_concept/2,        % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2         % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

% Source modules are called module-qualified, so empty import lists are
% intentional (no names pulled into this module; no clashes).
:- use_module(learner(meta_interpreter), []).
:- use_module(arche_trace(embodied_prover), []).

%! modal_context_unified(?Term, ?Context, -Source) is nondet.
%
%  True when Term carries a PML modal posture Context (compressive|expansive)
%  according to ANY layer. Source names the layer:
%   - meta_interpreter : is_modal_operator/2 fact table (bare polarized op).
%                        Also the generator when Term is unbound.
%   - embodied_prover  : determine_modal_context/2 (bare polarized op; requires
%                        Term bound).
%   - pml_modality     : is_pml_modality/1 recognizer over a MODE-WRAPPED op
%                        (s/o/n D-wrapper); Context derived from the inner
%                        polarized operator's polarity (see module projection note).
modal_context_unified(Term, Context, meta_interpreter) :-
    modal_context_witness(Term, Context, meta_interpreter, _).
modal_context_unified(Term, Context, embodied_prover) :-
    modal_context_witness(Term, Context, embodied_prover, _).
modal_context_unified(Term, Context, pml_modality) :-
    modal_context_witness(Term, Context, pml_modality, _).


%! modal_context_witness(?Term, ?Context, ?Source, -Witness) is nondet.
%
%  Witnessed form of `modal_context_unified/3`. This is a closed-world finite
%  source-union view over the currently loaded modal-context predicates. It does
%  not decide every possible modal vocabulary; it records which loaded source
%  accepted this concrete modal term and how the compressive/expansive context
%  was derived.
modal_context_witness(Term, Context, Source,
                      WitnessDict84) :-
    witness_dict:witness_dict(modal_context, closed_world_finite_loaded_modal_sources,
                              _{source: Source,
                         legacy_functor: LegacyFunctor,
                         term: Term,
                         context: Context,
                         polarity: Polarity,
                         shape: Shape,
                         derivation: Derivation }, WitnessDict84),
    modal_context_source(Source, LegacyFunctor),
    source_modal_context_witness(Source, Term, Context, Polarity, Shape, Derivation).


modal_context_source(meta_interpreter, 'meta_interpreter:is_modal_operator/2').
modal_context_source(embodied_prover, 'embodied_prover:determine_modal_context/2').
modal_context_source(pml_modality, 'embodied_prover:is_pml_modality/1').


source_modal_context_witness(meta_interpreter, Term, Context, Polarity,
                             bare_polarized_operator,
                             fact_table_lookup) :-
    catch(meta_interpreter:is_modal_operator(Term, Context), _, fail),
    modal_operator_polarity(Term, Polarity).
source_modal_context_witness(embodied_prover, Term, Context, Polarity,
                             bare_polarized_operator,
                             functor_dispatch) :-
    catch(embodied_prover:determine_modal_context(Term, Context), _, fail),
    modal_operator_polarity(Term, Polarity).
source_modal_context_witness(pml_modality, Term, Context, Polarity,
                             mode_wrapped_pml_operator,
                             mode_wrapper_recognizer_plus_inner_polarity) :-
    catch(( embodied_prover:is_pml_modality(Term),
            Term =.. [_Mode, OpTerm],
            functor(OpTerm, Op, _),
            operator_context(Op, Context)
          ), _, fail),
    modal_operator_polarity(OpTerm, Polarity).


modal_operator_polarity(Term, Polarity) :-
    nonvar(Term),
    functor(Term, Operator, _),
    operator_polarity(Operator, Polarity).

%! operator_polarity(+Operator, -Polarity) is semidet.
%
%  Maps a polarized PML operator functor to necessity/possibility polarity.
%  Local to this module (does not redefine anything in the source modules).
operator_polarity(comp_nec,  compressive_necessity).
operator_polarity(comp_poss, compressive_possibility).
operator_polarity(exp_nec,   expansive_necessity).
operator_polarity(exp_poss,  expansive_possibility).


polarity_context(compressive_necessity, compressive).
polarity_context(compressive_possibility, compressive).
polarity_context(expansive_necessity, expansive).
polarity_context(expansive_possibility, expansive).


operator_context(Operator, Context) :-
    operator_polarity(Operator, Polarity),
    polarity_context(Polarity, Context).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
%
%  Maps each scattered legacy functor to its canonical query predicate.
canonical_concept('meta_interpreter:is_modal_operator/2',      modal_context_unified).
canonical_concept('embodied_prover:determine_modal_context/2', modal_context_unified).
canonical_concept('embodied_prover:is_pml_modality/1',         modal_context_unified).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(modal_context_unified,
    [ 'meta_interpreter:is_modal_operator/2',
      'embodied_prover:determine_modal_context/2',
      'embodied_prover:is_pml_modality/1' ]).
