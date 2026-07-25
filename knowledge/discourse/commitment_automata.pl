% Authored by hand; not generated. Same fact shape as
% knowledge/strategies/transition_tables/*.pl, so that every tool which reads
% automata reads this genre too.
%
% WHAT THIS IS. The strategy transition tables hold one genre of automaton:
% arithmetic and geometric computation, where a step does something to a
% quantity. This file holds a second genre, where a step does something to a
% deontic score. Its machines run over commitment and entitlement, and over
% Brandom's meaning-use relations between a vocabulary and the
% practice-or-ability that deploys it.
%
% WHY IT IS NOT NEW MACHINERY. Both halves already exist here.
% formal/learner/deontic_scorekeeper.pl carries commitment/2, entitlement/2,
% undertake_commitment/2, grant_entitlement/2, withdraw_commitment/2,
% incompatible/2, ungrounded_grant_attempt/3, material_inference/3, and
% crisis_from_deontic_incoherence/3. formal/pml/mua_relations.pl carries 24
% vocabularies, 32 practices, and the relations among them: pv_sufficient/2 (a
% practice suffices to deploy a vocabulary), vp_sufficient/2 (a vocabulary
% suffices to specify a practice), pp_sufficient/3 (one practice is
% algorithmically elaborated from another), lx_for/3 (a vocabulary is
% elaborated from and explicative of a practice implicit in every vocabulary).
% What was missing is the automaton form: those relations as steps a machine
% takes, in the same shape the computation automata already have, so that the
% two genres can be compared rather than only coexist.
%
% PROVENANCE. Every edge says which of the two it answers to.
%   authored(grounded(Ref))   -- a predicate in this repository carries this
%                                step; Ref names it.
%   authored(unmodelled(Ref)) -- the literature carries this step and no
%                                predicate here does yet. Ref names the source.
% The unmodelled edges are the finding, not the filler: they are the discursive
% doings this repository can describe and cannot yet run. Counting them is the
% point of recording them.
%
% NO CLAIM THAT THE CODE ENACTS BRANDOM. These machines model relations
% Brandom states; they do not perform assertion, and nothing here decides
% whether a real utterance undertakes a commitment. The deformation machines in
% particular are readings of ways a discursive practice can fail to keep what
% it must keep -- the same viability grammar the strategy corpus uses, applied
% to normative rather than quantitative material.

:- multifile automaton_tuple/6.
:- multifile automaton_transition/6.

% --- assertion: undertaking a commitment ---------------------------------

automaton_tuple(discourse, assertional_commitment, states([q_start, q_uttered, q_committed, q_authorized, q_responsible, q_accept]), actions([attend_to_utterance, undertake_commitment, authorize_deferral, assume_vindication_task, record_deontic_score]), start(q_start), accepting([q_accept])).
automaton_tuple(discourse, assertion_without_vindication_task, states([q_start, q_uttered, q_committed, q_authorized, q_unvindicated, q_accept]), actions([attend_to_utterance, undertake_commitment, authorize_deferral, omit_vindication_task, record_deontic_incoherence]), start(q_start), accepting([q_accept])).

automaton_transition(discourse, assertional_commitment, q_start, attend_to_utterance, q_uttered, provenance(authored(unmodelled('Brandom, Making It Explicit, ch. 3: an assertion is taken up as a move in a scorekeeping practice')))).
automaton_transition(discourse, assertional_commitment, q_uttered, undertake_commitment, q_committed, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:undertake_commitment/2')))).
automaton_transition(discourse, assertional_commitment, q_committed, authorize_deferral, q_authorized, provenance(authored(unmodelled('Brandom, Making It Explicit, ch. 3: asserting licenses others to defer to the asserter')))).
automaton_transition(discourse, assertional_commitment, q_authorized, assume_vindication_task, q_responsible, provenance(authored(unmodelled('Brandom, Making It Explicit, ch. 3: the asserter takes on the task-responsibility of vindicating entitlement')))).
automaton_transition(discourse, assertional_commitment, q_responsible, record_deontic_score, q_accept, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:scorecard/2')))).

automaton_transition(discourse, assertion_without_vindication_task, q_start, attend_to_utterance, q_uttered, provenance(authored(unmodelled('Brandom, Making It Explicit, ch. 3')))).
automaton_transition(discourse, assertion_without_vindication_task, q_uttered, undertake_commitment, q_committed, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:undertake_commitment/2')))).
automaton_transition(discourse, assertion_without_vindication_task, q_committed, authorize_deferral, q_authorized, provenance(authored(unmodelled('Brandom, Making It Explicit, ch. 3')))).
automaton_transition(discourse, assertion_without_vindication_task, q_authorized, omit_vindication_task, q_unvindicated, provenance(authored(unmodelled('Brandom, Making It Explicit, ch. 3: an assertion whose asserter declines the vindication task keeps its form and loses its force')))).
automaton_transition(discourse, assertion_without_vindication_task, q_unvindicated, record_deontic_incoherence, q_accept, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:crisis_from_deontic_incoherence/3')))).

% --- entitlement by deferral ---------------------------------------------

automaton_tuple(discourse, entitlement_by_deferral, states([q_start, q_attributed, q_challenged, q_deferred, q_entitled, q_accept]), actions([attribute_commitment, challenge_entitlement, defer_to_asserter, inherit_entitlement, record_deontic_score]), start(q_start), accepting([q_accept])).
automaton_tuple(discourse, deferral_regress, states([q_start, q_attributed, q_challenged, q_deferred, q_regressed, q_accept]), actions([attribute_commitment, challenge_entitlement, defer_to_asserter, regress_deferral, record_deontic_incoherence]), start(q_start), accepting([q_accept])).

automaton_transition(discourse, entitlement_by_deferral, q_start, attribute_commitment, q_attributed, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:commitment/2')))).
automaton_transition(discourse, entitlement_by_deferral, q_attributed, challenge_entitlement, q_challenged, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:requires_entitlement/1')))).
automaton_transition(discourse, entitlement_by_deferral, q_challenged, defer_to_asserter, q_deferred, provenance(authored(unmodelled('Brandom, Making It Explicit, ch. 4: deferral is one of the three routes to entitlement, alongside inference and authority')))).
automaton_transition(discourse, entitlement_by_deferral, q_deferred, inherit_entitlement, q_entitled, provenance(authored(unmodelled('Brandom, Making It Explicit, ch. 4: entitlement inherited along a chain of deferrals that terminates')))).
automaton_transition(discourse, entitlement_by_deferral, q_entitled, record_deontic_score, q_accept, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:scorecard/2')))).

automaton_transition(discourse, deferral_regress, q_start, attribute_commitment, q_attributed, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:commitment/2')))).
automaton_transition(discourse, deferral_regress, q_attributed, challenge_entitlement, q_challenged, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:requires_entitlement/1')))).
automaton_transition(discourse, deferral_regress, q_challenged, defer_to_asserter, q_deferred, provenance(authored(unmodelled('Brandom, Making It Explicit, ch. 4')))).
automaton_transition(discourse, deferral_regress, q_deferred, regress_deferral, q_regressed, provenance(authored(unmodelled('Brandom, Making It Explicit, ch. 4: a deferral chain that returns to its own origin terminates in no entitlement')))).
automaton_transition(discourse, deferral_regress, q_regressed, record_deontic_incoherence, q_accept, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:crisis_from_deontic_incoherence/3')))).

% --- entitlement by material inference -----------------------------------

automaton_tuple(discourse, entitlement_by_inference, states([q_start, q_acknowledged, q_inference, q_derived, q_entitled, q_accept]), actions([acknowledge_commitment, locate_material_inference, derive_consequent, grant_entitlement, record_deontic_score]), start(q_start), accepting([q_accept])).
automaton_tuple(discourse, entitlement_by_formal_schema, states([q_start, q_acknowledged, q_schema, q_derived, q_ungrounded, q_accept]), actions([acknowledge_commitment, substitute_formal_schema_for_material_inference, derive_consequent, grant_entitlement_without_grounding, record_deontic_incoherence]), start(q_start), accepting([q_accept])).

automaton_transition(discourse, entitlement_by_inference, q_start, acknowledge_commitment, q_acknowledged, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:commitment/2')))).
automaton_transition(discourse, entitlement_by_inference, q_acknowledged, locate_material_inference, q_inference, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:material_inference/3')))).
automaton_transition(discourse, entitlement_by_inference, q_inference, derive_consequent, q_derived, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:commitment_consequence/3')))).
automaton_transition(discourse, entitlement_by_inference, q_derived, grant_entitlement, q_entitled, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:grant_entitlement/2')))).
automaton_transition(discourse, entitlement_by_inference, q_entitled, record_deontic_score, q_accept, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:scorecard/2')))).

automaton_transition(discourse, entitlement_by_formal_schema, q_start, acknowledge_commitment, q_acknowledged, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:commitment/2')))).
automaton_transition(discourse, entitlement_by_formal_schema, q_acknowledged, substitute_formal_schema_for_material_inference, q_schema, provenance(authored(unmodelled('Brandom, Articulating Reasons, ch. 1: a formally valid schema is not what makes a material inference good')))).
automaton_transition(discourse, entitlement_by_formal_schema, q_schema, derive_consequent, q_derived, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:commitment_consequence/3')))).
automaton_transition(discourse, entitlement_by_formal_schema, q_derived, grant_entitlement_without_grounding, q_ungrounded, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:ungrounded_grant_attempt/3')))).
automaton_transition(discourse, entitlement_by_formal_schema, q_ungrounded, record_deontic_incoherence, q_accept, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:crisis_from_deontic_incoherence/3')))).

% --- entitlement by authority --------------------------------------------

automaton_tuple(discourse, entitlement_by_authority, states([q_start, q_uttered, q_acknowledged, q_responsible, q_entitled, q_accept]), actions([attend_to_utterance, acknowledge_commitment, assume_vindication_task, grant_entitlement, record_deontic_score]), start(q_start), accepting([q_accept])).
automaton_tuple(discourse, authority_where_inference_required, states([q_start, q_uttered, q_acknowledged, q_asserted_authority, q_ungrounded, q_accept]), actions([attend_to_utterance, acknowledge_commitment, substitute_authority_for_inference, grant_entitlement_without_grounding, record_deontic_incoherence]), start(q_start), accepting([q_accept])).

automaton_transition(discourse, entitlement_by_authority, q_start, attend_to_utterance, q_uttered, provenance(authored(unmodelled('Brandom, Making It Explicit, ch. 4')))).
automaton_transition(discourse, entitlement_by_authority, q_uttered, acknowledge_commitment, q_acknowledged, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:commitment/2')))).
automaton_transition(discourse, entitlement_by_authority, q_acknowledged, assume_vindication_task, q_responsible, provenance(authored(unmodelled('Brandom, Making It Explicit, ch. 4: reliability confers a default entitlement the reporter still stands behind')))).
automaton_transition(discourse, entitlement_by_authority, q_responsible, grant_entitlement, q_entitled, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:grant_entitlement/2')))).
automaton_transition(discourse, entitlement_by_authority, q_entitled, record_deontic_score, q_accept, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:scorecard/2')))).

automaton_transition(discourse, authority_where_inference_required, q_start, attend_to_utterance, q_uttered, provenance(authored(unmodelled('Brandom, Making It Explicit, ch. 4')))).
automaton_transition(discourse, authority_where_inference_required, q_uttered, acknowledge_commitment, q_acknowledged, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:commitment/2')))).
automaton_transition(discourse, authority_where_inference_required, q_acknowledged, substitute_authority_for_inference, q_asserted_authority, provenance(authored(unmodelled('Brandom, Making It Explicit, ch. 4: authority is one route to entitlement and not a substitute for inference where inference was what was asked for')))).
automaton_transition(discourse, authority_where_inference_required, q_asserted_authority, grant_entitlement_without_grounding, q_ungrounded, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:ungrounded_grant_attempt/3')))).
automaton_transition(discourse, authority_where_inference_required, q_ungrounded, record_deontic_incoherence, q_accept, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:crisis_from_deontic_incoherence/3')))).

% --- incompatibility ------------------------------------------------------

automaton_tuple(discourse, incompatibility_recognition, states([q_start, q_first, q_second, q_tested, q_repaired, q_accept]), actions([acknowledge_commitment, test_compatibility, withdraw_commitment, record_deontic_score]), start(q_start), accepting([q_accept])).
automaton_tuple(discourse, incompatible_commitments_held, states([q_start, q_first, q_second, q_held, q_accept]), actions([acknowledge_commitment, hold_incompatible_commitments, record_deontic_incoherence]), start(q_start), accepting([q_accept])).

automaton_transition(discourse, incompatibility_recognition, q_start, acknowledge_commitment, q_first, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:commitment/2')))).
automaton_transition(discourse, incompatibility_recognition, q_first, acknowledge_commitment, q_second, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:commitment/2')))).
automaton_transition(discourse, incompatibility_recognition, q_second, test_compatibility, q_tested, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:incompatible/2')))).
automaton_transition(discourse, incompatibility_recognition, q_tested, withdraw_commitment, q_repaired, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:withdraw_commitment/2')))).
automaton_transition(discourse, incompatibility_recognition, q_repaired, record_deontic_score, q_accept, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:scorecard/2')))).

automaton_transition(discourse, incompatible_commitments_held, q_start, acknowledge_commitment, q_first, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:commitment/2')))).
automaton_transition(discourse, incompatible_commitments_held, q_first, acknowledge_commitment, q_second, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:commitment/2')))).
automaton_transition(discourse, incompatible_commitments_held, q_second, hold_incompatible_commitments, q_held, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:deontic_incoherent/2')))).
automaton_transition(discourse, incompatible_commitments_held, q_held, record_deontic_incoherence, q_accept, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:crisis_from_deontic_incoherence/3')))).

% --- attribution against acknowledgement ---------------------------------

automaton_tuple(discourse, attribution_and_acknowledgement_kept_apart, states([q_start, q_uttered, q_attributed, q_acknowledged, q_tested, q_accept]), actions([attend_to_utterance, attribute_commitment, acknowledge_commitment, test_compatibility, record_deontic_score]), start(q_start), accepting([q_accept])).
automaton_tuple(discourse, attribution_taken_as_acknowledgement, states([q_start, q_uttered, q_attributed, q_conflated, q_accept]), actions([attend_to_utterance, attribute_commitment, conflate_attribution_with_acknowledgement, record_deontic_incoherence]), start(q_start), accepting([q_accept])).

automaton_transition(discourse, attribution_and_acknowledgement_kept_apart, q_start, attend_to_utterance, q_uttered, provenance(authored(unmodelled('Brandom, Making It Explicit, ch. 3: scorekeeping is two-sided, attributing to another and acknowledging as one own')))).
automaton_transition(discourse, attribution_and_acknowledgement_kept_apart, q_uttered, attribute_commitment, q_attributed, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:commitment/2')))).
automaton_transition(discourse, attribution_and_acknowledgement_kept_apart, q_attributed, acknowledge_commitment, q_acknowledged, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:commitment/2')))).
automaton_transition(discourse, attribution_and_acknowledgement_kept_apart, q_acknowledged, test_compatibility, q_tested, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:incompatible/2')))).
automaton_transition(discourse, attribution_and_acknowledgement_kept_apart, q_tested, record_deontic_score, q_accept, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:scorecard/2')))).

automaton_transition(discourse, attribution_taken_as_acknowledgement, q_start, attend_to_utterance, q_uttered, provenance(authored(unmodelled('Brandom, Making It Explicit, ch. 3')))).
automaton_transition(discourse, attribution_taken_as_acknowledgement, q_uttered, attribute_commitment, q_attributed, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:commitment/2')))).
automaton_transition(discourse, attribution_taken_as_acknowledgement, q_attributed, conflate_attribution_with_acknowledgement, q_conflated, provenance(authored(unmodelled('Brandom, Making It Explicit, ch. 3: the two sides of the score are not interchangeable, and treating what is attributed as acknowledged collapses the perspective the score keeps')))).
automaton_transition(discourse, attribution_taken_as_acknowledgement, q_conflated, record_deontic_incoherence, q_accept, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:crisis_from_deontic_incoherence/3')))).

% --- repair ---------------------------------------------------------------

automaton_tuple(discourse, commitment_repair, states([q_start, q_acknowledged, q_challenged, q_withdrawn, q_repaired, q_accept]), actions([acknowledge_commitment, challenge_entitlement, withdraw_commitment, repair_the_commitment, record_deontic_score]), start(q_start), accepting([q_accept])).

automaton_transition(discourse, commitment_repair, q_start, acknowledge_commitment, q_acknowledged, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:commitment/2')))).
automaton_transition(discourse, commitment_repair, q_acknowledged, challenge_entitlement, q_challenged, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:requires_entitlement/1')))).
automaton_transition(discourse, commitment_repair, q_challenged, withdraw_commitment, q_withdrawn, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:withdraw_commitment/2')))).
automaton_transition(discourse, commitment_repair, q_withdrawn, repair_the_commitment, q_repaired, provenance(authored(unmodelled('Brandom, Making It Explicit, ch. 3: withdrawal is a legitimate move, and what follows it is a revised commitment rather than silence')))).
automaton_transition(discourse, commitment_repair, q_repaired, record_deontic_score, q_accept, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:scorecard/2')))).

% --- meaning-use relations (Between Saying and Doing) ---------------------

automaton_tuple(discourse, algorithmic_elaboration, states([q_start, q_practice, q_elaborated, q_accept]), actions([register_givens, elaborate_practice_algorithmically, certify_meaning_use_relation]), start(q_start), accepting([q_accept])).
automaton_tuple(discourse, pragmatic_metavocabulary_construction, states([q_start, q_vocabulary, q_specified, q_deployed, q_accept]), actions([register_givens, specify_practice_in_vocabulary, deploy_vocabulary_from_practice, certify_meaning_use_relation]), start(q_start), accepting([q_accept])).
automaton_tuple(discourse, universally_lx_loop, states([q_start, q_practice, q_elaborated, q_deployed, q_explicated, q_accept]), actions([register_givens, elaborate_practice_algorithmically, deploy_vocabulary_from_practice, explicate_practice_in_elaborated_vocabulary, certify_meaning_use_relation]), start(q_start), accepting([q_accept])).

automaton_transition(discourse, algorithmic_elaboration, q_start, register_givens, q_practice, provenance(authored(grounded('formal/pml/mua_relations.pl:practice/2')))).
automaton_transition(discourse, algorithmic_elaboration, q_practice, elaborate_practice_algorithmically, q_elaborated, provenance(authored(grounded('formal/pml/mua_relations.pl:pp_sufficient/3')))).
automaton_transition(discourse, algorithmic_elaboration, q_elaborated, certify_meaning_use_relation, q_accept, provenance(authored(grounded('formal/pml/mua_relations.pl:kind_mua_coherence/3')))).

automaton_transition(discourse, pragmatic_metavocabulary_construction, q_start, register_givens, q_vocabulary, provenance(authored(grounded('formal/pml/mua_relations.pl:vocabulary/2')))).
automaton_transition(discourse, pragmatic_metavocabulary_construction, q_vocabulary, specify_practice_in_vocabulary, q_specified, provenance(authored(grounded('formal/pml/mua_relations.pl:vp_sufficient/2')))).
automaton_transition(discourse, pragmatic_metavocabulary_construction, q_specified, deploy_vocabulary_from_practice, q_deployed, provenance(authored(grounded('formal/pml/mua_relations.pl:pv_sufficient/2')))).
automaton_transition(discourse, pragmatic_metavocabulary_construction, q_deployed, certify_meaning_use_relation, q_accept, provenance(authored(grounded('formal/pml/mua_relations.pl:kind_mua_coherence/3')))).

automaton_transition(discourse, universally_lx_loop, q_start, register_givens, q_practice, provenance(authored(grounded('formal/pml/mua_relations.pl:practice/2')))).
automaton_transition(discourse, universally_lx_loop, q_practice, elaborate_practice_algorithmically, q_elaborated, provenance(authored(grounded('formal/pml/mua_relations.pl:pp_sufficient/3')))).
automaton_transition(discourse, universally_lx_loop, q_elaborated, deploy_vocabulary_from_practice, q_deployed, provenance(authored(grounded('formal/pml/mua_relations.pl:pv_sufficient/2')))).
automaton_transition(discourse, universally_lx_loop, q_deployed, explicate_practice_in_elaborated_vocabulary, q_explicated, provenance(authored(grounded('formal/pml/mua_relations.pl:lx_for/3')))).
automaton_transition(discourse, universally_lx_loop, q_explicated, certify_meaning_use_relation, q_accept, provenance(authored(grounded('formal/pml/mua_relations.pl:kind_mua_coherence/3')))).

% --- the tutorial interruption --------------------------------------------
%
% The owner's tutoring move: some words, in some contexts, have already lost
% the relation the utterance was going to be about, and the rest of the
% utterance cannot recover it. Stopping there is not impatience; it is where
% the conservation is kept. The pair below is that move and its absence, and
% knowledge/strategies/action_grammar.pl carries the token-in-context verdicts
% these two machines are the automaton form of.

automaton_tuple(discourse, tutorial_interruption_on_incompatible_token, states([q_start, q_attending, q_named, q_tested, q_interrupted, q_repaired, q_accept]), actions([attend_to_utterance, name_the_incompatible_token, test_compatibility, interrupt_before_completion, repair_the_commitment, record_deontic_score]), start(q_start), accepting([q_accept])).
automaton_tuple(discourse, utterance_run_to_its_loss, states([q_start, q_attending, q_named, q_ran, q_accept]), actions([attend_to_utterance, name_the_incompatible_token, let_the_utterance_run_on, record_deontic_incoherence]), start(q_start), accepting([q_accept])).

automaton_transition(discourse, tutorial_interruption_on_incompatible_token, q_start, attend_to_utterance, q_attending, provenance(authored(unmodelled('Brandom, Making It Explicit, ch. 3: the scorekeeper attends before the utterance is complete')))).
automaton_transition(discourse, tutorial_interruption_on_incompatible_token, q_attending, name_the_incompatible_token, q_named, provenance(authored(grounded('knowledge/strategies/action_grammar.pl:interruption_license/6')))).
automaton_transition(discourse, tutorial_interruption_on_incompatible_token, q_named, test_compatibility, q_tested, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:incompatible/2')))).
automaton_transition(discourse, tutorial_interruption_on_incompatible_token, q_tested, interrupt_before_completion, q_interrupted, provenance(authored(unmodelled('the owner tutoring practice this file records: stopping at the token rather than after the conclusion')))).
automaton_transition(discourse, tutorial_interruption_on_incompatible_token, q_interrupted, repair_the_commitment, q_repaired, provenance(authored(unmodelled('Brandom, Making It Explicit, ch. 3')))).
automaton_transition(discourse, tutorial_interruption_on_incompatible_token, q_repaired, record_deontic_score, q_accept, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:scorecard/2')))).

automaton_transition(discourse, utterance_run_to_its_loss, q_start, attend_to_utterance, q_attending, provenance(authored(unmodelled('Brandom, Making It Explicit, ch. 3')))).
automaton_transition(discourse, utterance_run_to_its_loss, q_attending, name_the_incompatible_token, q_named, provenance(authored(grounded('knowledge/strategies/action_grammar.pl:interruption_license/6')))).
automaton_transition(discourse, utterance_run_to_its_loss, q_named, let_the_utterance_run_on, q_ran, provenance(authored(unmodelled('the counterpart of the interruption: the token is recognized and the utterance is allowed to reach the conclusion the token had already lost')))).
automaton_transition(discourse, utterance_run_to_its_loss, q_ran, record_deontic_incoherence, q_accept, provenance(authored(grounded('formal/learner/deontic_scorekeeper.pl:crisis_from_deontic_incoherence/3')))).
