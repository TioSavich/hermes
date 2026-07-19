/** <module> cw_viability -- crosswalk family data. */
:-module(cw_viability,[cw_family/1,cw_rule/1,edge/5]).
:-use_module(arche_trace(embodied_prover),[]).
:-use_module(learner(meta_interpreter),[]).
cw_family(cw_viability).
edge(embodied_prover,check_viability/2,[5,1],[],call_guarded_numeric).
cw_rule((viability_unified(A,B,embodied_prover):-viability_witness(A,B,embodied_prover,_25258))).
cw_rule((viability_unified(A,B,meta_interpreter):-viability_witness(A,B,meta_interpreter,_25346))).
cw_rule((viability_witness(A,B,C,D):-witness_dict:witness_dict(inference_budget_viability,closed_world_finite_resource_check,_25430{caught_perturbation_boundary:insufficient_budget_throws_resource_exhaustion,comparison:G,cost:B,legacy_functor:F,relation:resources_cover_cost,resources:A,source:C},D),viability_source(C,F),must_be(number,A),must_be(number,B),A>=B,source_check_viability(C,A,B),G=..[>=,A,B])).
cw_rule(viability_source(embodied_prover,'embodied_prover:check_viability/2')).
cw_rule(viability_source(meta_interpreter,'meta_interpreter:check_viability/2')).
cw_rule((source_check_viability(embodied_prover,A,B):-catch(once(embodied_prover:check_viability(A,B)),_25808,fail))).
cw_rule((source_check_viability(meta_interpreter,A,B):-catch(once(meta_interpreter:check_viability(A,B)),_25910,fail))).
cw_rule(canonical_concept('embodied_prover:check_viability/2',viability)).
cw_rule(canonical_concept('meta_interpreter:check_viability/2',viability)).
cw_rule(vocabulary_source(viability,['embodied_prover:check_viability/2','meta_interpreter:check_viability/2'])).
