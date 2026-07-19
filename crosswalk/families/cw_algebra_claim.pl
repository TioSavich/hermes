/** <module> cw_algebra_claim — canonical crosswalk family for the "algebra" bucket
 *
 * Bucket: algebra. Seven literature commitments about variables, functions,
 * substitution, structural generalization, relational strategy choice, and the
 * real-number extension each earn a crosswalk home because each has verified
 * cross-surface presence — a real, existing non-literature legacy functor (an
 * action-automaton vocabulary/cluster, a grounding-metaphor break point, or a
 * misconception incompatibility) expresses the same concept outside the
 * literature vocabulary:
 *
 *   value_substitution_into_expression  (c_substitution_semantics)
 *     - the algebraic programming-expression-evaluation vocabulary
 *       (variable_substitution / variable_assignment), and
 *     - two calculus substitution clusters (direct_substitution,
 *       factor_cancel_substitute) whose vocabularies carry substitution /
 *       function_value.
 *
 *   variable_as_indeterminate_quantity  (c_variable_as_generalized_quantity)
 *     - the algebraic programming-expression-evaluation vocabulary
 *       (algebraic_expression / variable_assignment), and
 *     - the algebraic linear-pattern contextual-rule vocabulary
 *       (contextual_generalization / explicit_rule).
 *
 *   function_evaluation_at_argument  (c_function_notation_evaluation)
 *     - the algebraic programming-expression-evaluation vocabulary
 *       (evaluate_as_program / procedural_evaluation / integer_value), and
 *     - the calculus direct-substitution vocabulary
 *       (evaluation_at_a_point / function_value).
 *
 *   function_as_univalent_correspondence  (c_function_as_arbitrary_correspondence)
 *     - the functions-are-sets-of-ordered-pairs metaphor break (rule vs
 *       extension), and
 *     - the functions-are-curves metaphor break (monster functions without
 *       tangents or continuity). Both mark where the familiar formula/graph
 *       reading fails and the arbitrary-correspondence reading is needed.
 *
 *   explicit_rule_generalization  (c_structural_generalization)
 *     - the algebraic linear-pattern contextual-rule vocabulary
 *       (explicit_rule / contextual_generalization / far_term_prediction), and
 *     - a registered deformation incompatibility (guess-and-check against one
 *       instance, which loses the explicit structural rule).
 *
 *   relational_strategy_over_brute_count  (c_relational_strategy_choice)
 *     - the additive derived-fact-adjustment vocabulary
 *       (anchor_fact / relation_between_problems / adjustment), and
 *     - the subtraction constant-difference cluster and the addition
 *       compensation cluster (structural shortcuts vs unit-by-unit counting).
 *
 *   irrational_extension_of_number_system  (c_real_extension_solvability)
 *     - the arithmetic-is-object-collection metaphor break at irrational
 *       numbers (no collection referent), and
 *     - the arithmetic-is-object-construction metaphor break at irrational
 *       numbers (not finitely constructible). Both mark where the rationals
 *       are extended to the reals.
 *
 * Same shape as the other crosswalk families (see cw_integer_signed_claim): it
 * RENAMES nothing and OWNS no facts on the legacy surfaces. vocabulary_source/2
 * is the contract the aggregator (canonical_all) ranges over; canonical_concept/2
 * is the reverse map; algebra_claim_unified/3 is the live query that pulls the
 * literature gloss plus one row per verified legacy edge.
 *
 * Every legacy edge recorded here was loaded and queried against the live system
 * before promotion. Edges flagged unverified upstream are NOT recorded.
 *
 * Family slug: algebra_claim.
 */
:- module(cw_algebra_claim,
          [ algebra_claim_unified/3,   % algebra_claim_unified(-Canonical, -Detail, -Source)
            algebra_claim_witness/4,   % algebra_claim_witness(?Canonical, ?Detail, ?Source, -Witness)
            claim_literature_atom/2,    % claim_literature_atom(?Canonical, ?LiteratureAtom)
            canonical_concept/2,        % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2         % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

:- use_module(misconceptions(literature_vocabulary), []).
:- use_module(strategies('math/action_automata_registry'), []).
:- use_module(formalization(grounding_metaphors), []).
:- use_module(misconceptions(misconception_registry), []).
:- use_module(library(lists), [ member/2 ]).

%! ac(?Canonical, ?LiteratureAtom, ?Edges) is nondet.
%
%  The family table. Each row: the canonical algebra concept; the real
%  literature canonical_commitment atom (verified present); and the list of
%  verified non-literature legacy edges that express the same concept. Each
%  edge is edge(Functor, Surface): Functor is the 'Module:Name/Arity(args)'
%  identifier string, Surface is the human-readable gloss of that edge.
ac(value_substitution_into_expression,
   c_substitution_semantics,
   [ edge('action_automata_registry:action_automaton_vocabulary/3(algebraic,programming_expression_evaluation)',
          "Algebraic program-evaluation vocabulary carrying variable_substitution and variable_assignment."),
     edge('action_automata_registry:action_automaton_cluster/3(calculus,direct_substitution)',
          "Calculus limit-by-continuity cluster whose vocabulary carries substitution and function_value."),
     edge('action_automata_registry:action_automaton_cluster/3(calculus,factor_cancel_substitute)',
          "Calculus removable-discontinuity cluster that cancels then substitutes — substitution after factoring.")
   ]).
ac(variable_as_indeterminate_quantity,
   c_variable_as_generalized_quantity,
   [ edge('action_automata_registry:action_automaton_vocabulary/3(algebraic,programming_expression_evaluation)',
          "Algebraic program-evaluation vocabulary carrying algebraic_expression and variable_assignment — variables as assignable indeterminates."),
     edge('action_automata_registry:action_automaton_vocabulary/3(algebraic,linear_pattern_contextual_rule)',
          "Algebraic linear-pattern vocabulary carrying contextual_generalization and explicit_rule — the term standing for a generalized quantity in a relation.")
   ]).
ac(function_evaluation_at_argument,
   c_function_notation_evaluation,
   [ edge('action_automata_registry:action_automaton_vocabulary/3(algebraic,programming_expression_evaluation)',
          "Algebraic program-evaluation vocabulary carrying evaluate_as_program, procedural_evaluation, and integer_value — computing the value at an assignment."),
     edge('action_automata_registry:action_automaton_vocabulary/3(calculus,direct_substitution)',
          "Calculus direct-substitution vocabulary carrying evaluation_at_a_point and function_value.")
   ]).
ac(function_as_univalent_correspondence,
   c_function_as_arbitrary_correspondence,
   [ edge('grounding_metaphors:metaphor_breaks_at/3(functions_are_sets_of_ordered_pairs,conceptual_distinction_between_rule_and_extension)',
          "Break point: the ordered-pairs reading collapses two conceptually distinct rules that share an extension, marking where rule and extension come apart."),
     edge('grounding_metaphors:metaphor_breaks_at/3(functions_are_curves,monster_functions_lacking_tangents_or_continuity)',
          "Break point: pathological functions (continuous nowhere-differentiable, space-filling) cannot be grounded as smooth curves, forcing the arbitrary-correspondence reading.")
   ]).
ac(explicit_rule_generalization,
   c_structural_generalization,
   [ edge('action_automata_registry:action_automaton_vocabulary/3(algebraic,linear_pattern_contextual_rule)',
          "Algebraic linear-pattern vocabulary carrying explicit_rule, contextual_generalization, and far_term_prediction — a structural rule that holds across all cases."),
     edge('misconception_registry:incompatibility_with/2(guess_and_check_rule,strategy(algebraic,linear_pattern_contextual_rule))',
          "Registered deformation incompatibility: guess-and-check against one instance loses the explicit structural rule.")
   ]).
ac(relational_strategy_over_brute_count,
   c_relational_strategy_choice,
   [ edge('action_automata_registry:action_automaton_vocabulary/3(addition,derived_fact_adjustment)',
          "Additive derived-fact vocabulary carrying anchor_fact, relation_between_problems, and adjustment — exploiting a known fact's relation to the target."),
     edge('action_automata_registry:action_automaton_cluster/3(subtraction,sliding_constant_difference)',
          "Subtraction constant-difference shortcut: shift both terms to preserve the difference rather than counting unit-by-unit."),
     edge('action_automata_registry:action_automaton_cluster/3(addition,unbalanced_make_base_compensation)',
          "Addition compensation/conservation shortcut: adjust to a base and compensate rather than counting unit-by-unit.")
   ]).
ac(irrational_extension_of_number_system,
   c_real_extension_solvability,
   [ edge('grounding_metaphors:metaphor_breaks_at/3(arithmetic_is_object_collection,irrational_numbers)',
          "Break point: irrationals have no source-domain referent as a collection, marking where the rationals are extended to the reals."),
     edge('grounding_metaphors:metaphor_breaks_at/3(arithmetic_is_object_construction,irrational_numbers)',
          "Break point: irrationals are not constructible by finite assembly of unit parts, marking where finite construction fails.")
   ]).

%! claim_literature_atom(?Canonical, ?LiteratureAtom) is nondet.
%  The literature commitment atom a canonical algebra concept resolves to.
claim_literature_atom(Canonical, LitAtom) :- ac(Canonical, LitAtom, _).

% The legacy functor strings for a canonical term: the literature commitment
% functor plus each verified edge functor, all as 'Module:Name/Arity(args)'
% style atoms (matching the convention used by the other families).
legacy_list(Canonical, [LitFunctor | EdgeFunctors]) :-
    ac(Canonical, Lit, Edges),
    atomic_list_concat(['literature_vocabulary:canonical_commitment/2(', Lit, ')'], LitFunctor),
    findall(F, member(edge(F, _), Edges), EdgeFunctors).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(Canonical, Legacies) :- legacy_list(Canonical, Legacies).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
canonical_concept(Legacy, Canonical) :-
    legacy_list(Canonical, Legacies),
    member(Legacy, Legacies).

%! algebra_claim_unified(?Canonical, ?Detail, ?Source) is nondet.
%
%  Source = literature_commitment: Detail = commitment(Atom, Gloss) — the real
%  canonical_commitment gloss for this concept's literature atom.
%  Source = <edge functor string>: Detail = edge_surface(Surface) — one row per
%  verified non-literature legacy edge that expresses the concept.
algebra_claim_unified(Canonical, Detail, Source) :-
    algebra_claim_witness(Canonical, Detail, Source, _).

%! algebra_claim_witness(?Canonical, ?Detail, ?Source, -Witness) is nondet.
%
%  Witnessed form of `algebra_claim_unified/3`. This is a closed-world finite
%  check over the currently loaded algebra crosswalk table and its owner
%  predicates. The table supplies candidate literature/edge alignments; this
%  predicate succeeds only when the owning source predicate proves the
%  referenced literature commitment or legacy edge.
algebra_claim_witness(Canonical,
                      commitment(Lit, GlossS),
                      literature_commitment,
                      WitnessDict181) :-
    witness_dict:witness_dict(algebra_claim_crosswalk, closed_world_finite_verified_algebra_claim_edges,
                              _{canonical: Canonical,
                         detail: commitment(Lit, GlossS),
                         source: literature_commitment,
                         literature_atom: Lit,
                         projection: literature_commitment_gloss,
                         derivation: literature_canonical_commitment_lookup,
                         source_witness: _{ kind: literature_commitment_row,
                                            module: literature_vocabulary,
                                            predicate: canonical_commitment/2,
                                            atom: Lit,
                                            gloss: GlossS } }, WitnessDict181),
    ac(Canonical, Lit, _),
    catch(literature_vocabulary:canonical_commitment(Lit, Gloss), _, fail),
    ( string(Gloss) -> GlossS = Gloss ; format(string(GlossS), "~w", [Gloss]) ).
algebra_claim_witness(Canonical,
                      edge_surface(Surface),
                      Functor,
                      WitnessDict200) :-
    witness_dict:witness_dict(algebra_claim_crosswalk, closed_world_finite_verified_algebra_claim_edges,
                              _{canonical: Canonical,
                         detail: edge_surface(Surface),
                         source: Functor,
                         legacy_functor: Functor,
                         projection: verified_legacy_edge_surface,
                         derivation: owner_predicate_edge_check,
                         source_witness: SourceWitness }, WitnessDict200),
    ac(Canonical, _, Edges),
    member(edge(Functor, Surface), Edges),
    algebra_edge_source_witness(Functor, SourceWitness).

algebra_edge_source_witness(
    'action_automata_registry:action_automaton_vocabulary/3(algebraic,programming_expression_evaluation)',
    _{ kind: action_automaton_vocabulary_edge,
       module: action_automata_registry,
       predicate: action_automaton_vocabulary/3,
       operation: algebraic,
       action_kind: programming_expression_evaluation,
       vocabulary: Vocabulary }) :-
    catch(action_automata_registry:action_automaton_vocabulary(
              algebraic, programming_expression_evaluation, Vocabulary),
          _, fail).
algebra_edge_source_witness(
    'action_automata_registry:action_automaton_vocabulary/3(algebraic,linear_pattern_contextual_rule)',
    _{ kind: action_automaton_vocabulary_edge,
       module: action_automata_registry,
       predicate: action_automaton_vocabulary/3,
       operation: algebraic,
       action_kind: linear_pattern_contextual_rule,
       vocabulary: Vocabulary }) :-
    catch(action_automata_registry:action_automaton_vocabulary(
              algebraic, linear_pattern_contextual_rule, Vocabulary),
          _, fail).
algebra_edge_source_witness(
    'action_automata_registry:action_automaton_vocabulary/3(calculus,direct_substitution)',
    _{ kind: action_automaton_vocabulary_edge,
       module: action_automata_registry,
       predicate: action_automaton_vocabulary/3,
       operation: calculus,
       action_kind: direct_substitution,
       vocabulary: Vocabulary }) :-
    catch(action_automata_registry:action_automaton_vocabulary(
              calculus, direct_substitution, Vocabulary),
          _, fail).
algebra_edge_source_witness(
    'action_automata_registry:action_automaton_vocabulary/3(addition,derived_fact_adjustment)',
    _{ kind: action_automaton_vocabulary_edge,
       module: action_automata_registry,
       predicate: action_automaton_vocabulary/3,
       operation: addition,
       action_kind: derived_fact_adjustment,
       vocabulary: Vocabulary }) :-
    catch(action_automata_registry:action_automaton_vocabulary(
              addition, derived_fact_adjustment, Vocabulary),
          _, fail).
algebra_edge_source_witness(
    'action_automata_registry:action_automaton_cluster/3(calculus,direct_substitution)',
    _{ kind: action_automaton_cluster_edge,
       module: action_automata_registry,
       predicate: action_automaton_cluster/3,
       operation: calculus,
       action_kind: direct_substitution,
       cluster: Cluster }) :-
    catch(action_automata_registry:action_automaton_cluster(
              calculus, direct_substitution, Cluster),
          _, fail).
algebra_edge_source_witness(
    'action_automata_registry:action_automaton_cluster/3(calculus,factor_cancel_substitute)',
    _{ kind: action_automaton_cluster_edge,
       module: action_automata_registry,
       predicate: action_automaton_cluster/3,
       operation: calculus,
       action_kind: factor_cancel_substitute,
       cluster: Cluster }) :-
    catch(action_automata_registry:action_automaton_cluster(
              calculus, factor_cancel_substitute, Cluster),
          _, fail).
algebra_edge_source_witness(
    'action_automata_registry:action_automaton_cluster/3(subtraction,sliding_constant_difference)',
    _{ kind: action_automaton_cluster_edge,
       module: action_automata_registry,
       predicate: action_automaton_cluster/3,
       operation: subtraction,
       action_kind: sliding_constant_difference,
       cluster: Cluster }) :-
    catch(action_automata_registry:action_automaton_cluster(
              subtraction, sliding_constant_difference, Cluster),
          _, fail).
algebra_edge_source_witness(
    'action_automata_registry:action_automaton_cluster/3(addition,unbalanced_make_base_compensation)',
    _{ kind: action_automaton_cluster_edge,
       module: action_automata_registry,
       predicate: action_automaton_cluster/3,
       operation: addition,
       action_kind: unbalanced_make_base_compensation,
       cluster: Cluster }) :-
    catch(action_automata_registry:action_automaton_cluster(
              addition, unbalanced_make_base_compensation, Cluster),
          _, fail).
algebra_edge_source_witness(
    'grounding_metaphors:metaphor_breaks_at/3(functions_are_sets_of_ordered_pairs,conceptual_distinction_between_rule_and_extension)',
    _{ kind: grounding_metaphor_break_edge,
       module: grounding_metaphors,
       predicate: metaphor_breaks_at/3,
       metaphor: functions_are_sets_of_ordered_pairs,
       target_inference: conceptual_distinction_between_rule_and_extension,
       reason: Reason }) :-
    catch(grounding_metaphors:metaphor_breaks_at(
              functions_are_sets_of_ordered_pairs,
              conceptual_distinction_between_rule_and_extension,
              Reason),
          _, fail).
algebra_edge_source_witness(
    'grounding_metaphors:metaphor_breaks_at/3(functions_are_curves,monster_functions_lacking_tangents_or_continuity)',
    _{ kind: grounding_metaphor_break_edge,
       module: grounding_metaphors,
       predicate: metaphor_breaks_at/3,
       metaphor: functions_are_curves,
       target_inference: monster_functions_lacking_tangents_or_continuity,
       reason: Reason }) :-
    catch(grounding_metaphors:metaphor_breaks_at(
              functions_are_curves,
              monster_functions_lacking_tangents_or_continuity,
              Reason),
          _, fail).
algebra_edge_source_witness(
    'grounding_metaphors:metaphor_breaks_at/3(arithmetic_is_object_collection,irrational_numbers)',
    _{ kind: grounding_metaphor_break_edge,
       module: grounding_metaphors,
       predicate: metaphor_breaks_at/3,
       metaphor: arithmetic_is_object_collection,
       target_inference: irrational_numbers,
       reason: Reason }) :-
    catch(grounding_metaphors:metaphor_breaks_at(
              arithmetic_is_object_collection,
              irrational_numbers,
              Reason),
          _, fail).
algebra_edge_source_witness(
    'grounding_metaphors:metaphor_breaks_at/3(arithmetic_is_object_construction,irrational_numbers)',
    _{ kind: grounding_metaphor_break_edge,
       module: grounding_metaphors,
       predicate: metaphor_breaks_at/3,
       metaphor: arithmetic_is_object_construction,
       target_inference: irrational_numbers,
       reason: Reason }) :-
    catch(grounding_metaphors:metaphor_breaks_at(
              arithmetic_is_object_construction,
              irrational_numbers,
              Reason),
          _, fail).
algebra_edge_source_witness(
    'misconception_registry:incompatibility_with/2(guess_and_check_rule,strategy(algebraic,linear_pattern_contextual_rule))',
    _{ kind: misconception_registry_incompatibility_edge,
       module: misconception_registry,
       predicate: incompatibility_with_witness/3,
       move: guess_and_check_rule,
       conflict: strategy(algebraic, linear_pattern_contextual_rule),
       registry_witness: RegistryWitness }) :-
    catch(misconception_registry:incompatibility_with_witness(
              guess_and_check_rule,
              strategy(algebraic, linear_pattern_contextual_rule),
              RegistryWitness),
          _, fail).
