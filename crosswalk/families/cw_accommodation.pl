/** <module> cw_accommodation -- crosswalk family data. */
:-module(cw_accommodation,[cw_family/1,cw_rule/1,edge/5]).
:-use_module(arche_trace(critique),[]).
:-use_module(learner(reorganization_engine),[]).
cw_family(cw_accommodation).
edge(critique,accommodate/1,[conceptual_change],[],call_match_ground).
cw_rule((accommodation_unified(A,B):-accommodation_witness(A,B,_2806))).
cw_rule((accommodation_witness(A,B,C):-witness_dict:witness_dict(accommodation_registry_entry,closed_world_finite_loaded_accommodation_registry,_2888{effect:G,invocation_policy:registry_only_no_executor_call,legacy_functor:E,side_effect_boundary:H,source:B,target:A,target_witness:I,trigger_shape:F},C),registry(A,B,G,F,H,E),target_defined_witness(A,I))).
cw_rule((registry(A,B,C):-registry(A,B,C,_3128,_,_))).
cw_rule(registry(critique:accommodate/1,arche_trace_critique,'sequent/commitment sublation; increments stress map, writes diagnostics, and fails to signal external intervention','perturbation(resource_exhaustion, Sequent) | incoherence(Commitments) | pathology(bad_infinite, Cycle) | Trigger',stress_map_and_stdout,'critique:accommodate/1')).
cw_rule(registry(reorganization_engine:accommodate/1,learner_reorg,'learner accommodation; dispatches to belief revision or conceptual-stress repair on object_level','goal_failure(_) | perturbation(_) | incoherence(Commitments) | Trigger',object_level_stress_map_log_and_stdout,'reorganization_engine:accommodate/1')).
cw_rule(registry(reorganization_engine:reorganize_system/2,learner_reorg,'ORR Reorganize entry point; current finite crisis-recovery path reports the archived FSM-synthesis boundary and fails','Goal, Trace',stdout_and_external_recovery_signal,'reorganization_engine:reorganize_system/2')).
cw_rule((target_defined_witness(A:B/C,_3476{arity:C,kind:loaded_predicate_presence,module:A,name:B,properties:E}):-catch(once((current_predicate(A:B/C);functor(F,B,C),predicate_property(A:F,defined))),_,fail),findall(H,target_property(A,B,C,H),I),sort(I,E))).
cw_rule((target_property(A,B,C,defined):-functor(D,B,C),predicate_property(A:D,defined))).
cw_rule((target_property(A,B,C,exported):-functor(D,B,C),predicate_property(A:D,exported))).
cw_rule(canonical_concept('critique:accommodate/1',accommodation)).
cw_rule(canonical_concept('reorganization_engine:accommodate/1',accommodation)).
cw_rule(canonical_concept('reorganization_engine:reorganize_system/2',accommodation)).
cw_rule(vocabulary_source(accommodation,['critique:accommodate/1','reorganization_engine:accommodate/1','reorganization_engine:reorganize_system/2'])).
