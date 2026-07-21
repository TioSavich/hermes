/** <module> canonical_all — loads + re-exports every canonical vocabulary query.
 *
 *  Auto-generated loader (parsed from each module's real export list).
 *  Re-exports every *_unified / registry predicate; canonical_concept/2 and
 *  vocabulary_source/2 stay module-local (query them module-qualified).
 */
:- module(canonical_all,
          [ contract/3,        % contract(?Canonical, ?Module, ?LegacyFunctors)
            legal_term/1,      % legal_term(?CanonicalName)  — a legal canonical vocabulary term
            legacy_term/2,     % legacy_term(?LegacyFunctor, ?Canonical)
            crosswalk_family/1,
            crosswalk_family_count/1,
            validate_crosswalk_families/0
          ]).

:- reexport(crosswalk(canonical_vocabulary), [incompatible/3, incoherent/2]).
:- reexport(crosswalk('families/cw_driver'), [accommodation_unified/2]).
:- reexport(crosswalk('families/cw_driver'), [action_cluster_unified/4]).
:- reexport(crosswalk('families/cw_driver'), [algebra_claim_unified/3]).
:- reexport(crosswalk('families/cw_driver'), [arithmetic_property_unified/3]).
:- reexport(crosswalk('families/cw_driver'), [axiom_pack_unified/2, axiom_pack_control/4]).
:- reexport(crosswalk('families/cw_driver'), [calculus_claim_unified/3]).
:- reexport(crosswalk('families/cw_counting_claim'), [counting_claim_unified/3]).
:- reexport(crosswalk('families/cw_driver'), [decimal_claim_unified/3]).
:- reexport(crosswalk('families/cw_driver'), [deontic_incoherence_unified/3]).
:- reexport(crosswalk('families/cw_driver'), [domain_context_unified/3]).
:- reexport(crosswalk('families/cw_driver'), [executable_practice_unified/4]).
:- reexport(crosswalk('families/cw_fraction_claim'), [fraction_claim_unified/3]).
:- reexport(crosswalk('families/cw_driver'), [fraction_extra_claim_unified/3]).
:- reexport(crosswalk('families/cw_driver'), [fsm_engine_unified/2]).
:- reexport(crosswalk('families/cw_driver'), [godel_primes_unified/3]).
:- reexport(crosswalk('families/cw_driver'), [grounded_arith_unified/4]).
:- reexport(crosswalk('families/cw_driver'), [grounding_metaphor_unified/3]).
:- reexport(crosswalk('families/cw_driver'), [integer_signed_claim_unified/3]).
:- reexport(crosswalk('families/cw_driver'), [magnitude_equivalence_claim_unified/3]).
:- reexport(crosswalk('families/cw_driver'), [material_inference_unified/4]).
:- reexport(crosswalk('families/cw_driver'), [metaphor_break_unified/4]).
:- reexport(crosswalk('families/cw_driver'), [misconception_hook_unified/5]).
:- reexport(crosswalk('families/cw_driver'), [modal_context_unified/3]).
:- reexport(crosswalk('families/cw_driver'), [mua_coherence_unified/4]).
:- reexport(crosswalk('families/cw_driver'), [multiplication_division_claim_unified/3]).
:- reexport(crosswalk('families/cw_driver'), [normative_crisis_unified/3, normative_crisis_variant/2]).
:- reexport(crosswalk('families/cw_driver'), [orr_entry_unified/4]).
% cw_place_value_number_claim exports whole_number_claim_unified/3 (same name as
% cw_whole_number_claim). Reexported here under an alias to avoid an import clash;
% the canonical surface (legal_term/legacy_term) reaches it module-qualified via
% the crosswalk_module(cw_place_value_number_claim) fact below regardless of name.
:- reexport(crosswalk('families/cw_place_value_number_claim'),
            [whole_number_claim_unified/3 as place_value_number_claim_unified]).
:- reexport(crosswalk('families/cw_driver'), [practice_vocabulary_unified/3]).
:- reexport(crosswalk('families/cw_driver'), [productive_deformation_unified/5]).
:- reexport(crosswalk('families/cw_driver'), [ratio_proportion_claim_unified/3]).
:- reexport(crosswalk('families/cw_driver'), [sequent_proof_unified/2]).
:- reexport(crosswalk('families/cw_driver'), [strategy_action_kind_unified/3]).
:- reexport(crosswalk('families/cw_driver'), [stress_map_unified/3]).
:- reexport(crosswalk('families/cw_driver'), [unit_coordination_unified/3]).
:- reexport(crosswalk('families/cw_driver'), [viability_unified/3]).
:- reexport(crosswalk('families/cw_driver'), [whole_number_addsub_claim_unified/3]).
:- reexport(crosswalk('families/cw_whole_number_claim'), [whole_number_claim_unified/3]).

% --- Expected family registry and contract aggregator ---

crosswalk_family(cw_accommodation).
crosswalk_family(cw_action_cluster).
crosswalk_family(cw_algebra_claim).
crosswalk_family(cw_arithmetic_property_claim).
crosswalk_family(cw_axiom_pack).
crosswalk_family(cw_calculus_claim).
crosswalk_family(cw_counting_claim).
crosswalk_family(cw_decimal_claim).
crosswalk_family(cw_deontic_incoherence).
crosswalk_family(cw_domain_context).
crosswalk_family(cw_executable_practice).
crosswalk_family(cw_fraction_claim).
crosswalk_family(cw_fraction_extra_claim).
crosswalk_family(cw_fsm_engine).
crosswalk_family(cw_godel_primes).
crosswalk_family(cw_grounded_arith).
crosswalk_family(cw_grounding_metaphor).
crosswalk_family(cw_integer_signed_claim).
crosswalk_family(cw_magnitude_equivalence_claim).
crosswalk_family(cw_material_inference).
crosswalk_family(cw_metaphor_break).
crosswalk_family(cw_misconception_hook).
crosswalk_family(cw_modal_context).
crosswalk_family(cw_mua_coherence).
crosswalk_family(cw_multiplication_division_claim).
crosswalk_family(cw_normative_crisis).
crosswalk_family(cw_orr_entry).
crosswalk_family(cw_place_value_number_claim).
crosswalk_family(cw_practice_vocabulary).
crosswalk_family(cw_productive_deformation).
crosswalk_family(cw_ratio_proportion_claim).
crosswalk_family(cw_sequent_proof).
crosswalk_family(cw_strategy_action_kind).
crosswalk_family(cw_stress_map).
crosswalk_family(cw_unit_coordination).
crosswalk_family(cw_viability).
crosswalk_family(cw_whole_number_addsub_claim).
crosswalk_family(cw_whole_number_claim).

crosswalk_family_count(Count) :-
    aggregate_all(count, crosswalk_family(_), Count).

validate_crosswalk_families :-
    (   crosswalk_family(Family),
        \+ current_module(Family),
        current_predicate(cw_driver:data_family/1),
        \+ cw_driver:data_family(Family)
    ->  throw(error(existence_error(crosswalk_family, Family),
                    canonical_all:validate_crosswalk_families/0))
    ;   true
    ).

:- initialization(validate_crosswalk_families, after_load).

% Each family module keeps vocabulary_source/2 module-local; range over the
% explicit registry so validation and contract aggregation cannot drift apart.
crosswalk_module(canonical_vocabulary).
crosswalk_module(Module) :- crosswalk_family(Module).

%! contract(?Canonical, ?Module, ?LegacyFunctors) is nondet.
contract(Canonical, Module, Legacy) :-
    crosswalk_module(Module),
    (   cw_driver:data_family(Module)
    ->  catch(cw_driver:family_vocabulary_source(Module, Canonical, Legacy), _, fail)
    ;   catch(Module:vocabulary_source(Canonical, Legacy), _, fail)
    ).

%! legal_term(?Canonical) is nondet.  True when Canonical is a canonical vocabulary term.
legal_term(Canonical) :- contract(Canonical, _, _).

%! legacy_term(?Legacy, ?Canonical) is nondet.  Maps a scattered legacy functor to its canonical term.
legacy_term(Legacy, Canonical) :-
    contract(Canonical, _, Legacies),
    member(Legacy, Legacies).
