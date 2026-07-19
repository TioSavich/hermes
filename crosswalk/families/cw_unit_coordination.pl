/** <module> cw_unit_coordination -- crosswalk family data. */
:-module(cw_unit_coordination,[cw_family/1,cw_rule/1,edge/5]).
:-use_module(math(divaded_fractional_units),[]).
:-use_module(misconceptions(literature_incompatibility_facts),[]).
cw_family(cw_unit_coordination).
edge(divaded_fractional_units,coordinate_units/4,[1,2],[3,4],call_bind_out).
cw_rule((unit_coordination_unified(lit(A,B),commitment(C,D,E,F),literature_commitment):-unit_coordination_witness(lit(A,B),commitment(C,D,E,F),literature_commitment,_23332))).
cw_rule((unit_coordination_unified(compose(A,B),composite(C),strategy_compose):-unit_coordination_witness(compose(A,B),composite(C),strategy_compose,_23488))).
cw_rule((unit_coordination_witness(A,B,C,D):-witness_dict:witness_dict(unit_coordination_crosswalk,closed_world_finite_loaded_unit_coordination_sources,_23584{derivation:G,detail:B,key:A,legacy_functor:F,source:C,source_witness:H},D),unit_coordination_source(C,F),source_unit_coordination_witness(C,A,B,G,H))).
cw_rule(unit_coordination_source(strategy_compose,'divaded_fractional_units:coordinate_units/4')).
cw_rule(unit_coordination_source(literature_commitment,'literature_incompatibility_facts:lit_derived/9(Topic=unit_coordination)')).
cw_rule((source_unit_coordination_witness(literature_commitment,lit(A,B),commitment(C,D,E,F),literature_topic_lookup,_23896{confidence:I,domain:B,id:A,incompatible_with:E,kind:unit_coordination_literature_commitment,level:H,student_rule:C,topic:unit_coordination,valence:F,valid_domain:D}):-catch(literature_incompatibility_facts:lit_derived(A,B,unit_coordination,C,D,E,F,H,I),_,fail))).
cw_rule((source_unit_coordination_witness(strategy_compose,compose(A,B),composite(C),deterministic_strategy_demo,_24162{composite_int:C,composite_recollection:H,demonstration:fixed_ground_strategy_demo,kind:unit_coordination_strategy_composition,trace:E,unit_count:B,unit_count_recollection:G,unit_size:A,unit_size_recollection:F}):-A=2,B=3,int_to_rec(A,F),int_to_rec(B,G),catch(once(divaded_fractional_units:coordinate_units(F,G,H,E)),_,fail),divaded_fractional_units:rec_to_int(H,C))).
cw_rule((int_to_rec(A,recollection(B)):-integer(A),A>=0,length(B,A),maplist(=(tally),B))).
cw_rule(canonical_concept('divaded_fractional_units:coordinate_units/4',unit_coordination)).
cw_rule(canonical_concept('literature_incompatibility_facts:lit_derived/9(Topic=unit_coordination)',unit_coordination)).
cw_rule(vocabulary_source(unit_coordination,['divaded_fractional_units:coordinate_units/4','literature_incompatibility_facts:lit_derived/9(Topic=unit_coordination)'])).
