/** <module> cw_domain_context -- crosswalk family data. */
:-module(cw_domain_context,[cw_family/1,cw_rule/1,edge/5]).
:-use_module(sequent(sequent_engine),[]).
cw_family(cw_domain_context).
edge(sequent_engine,current_domain/1,[],[1],call_bind_out).
cw_rule((domain_context_unified(A,_13222,domain_atom):-domain_context_witness(A,not_projected_by_source,domain_atom,_))).
cw_rule((domain_context_unified(_13320,B,domain_context):-domain_context_witness(not_projected_by_source,B,domain_context,_))).
cw_rule((domain_context_witness(A,B,C,D):-witness_dict:witness_dict(domain_context_crosswalk,closed_world_finite_loaded_domain_state,_13430{context:B,derivation:G,domain:A,legacy_functor:F,setter_policy:set_domain_excluded_mutates_dynamic_state,source:C,source_witness:H,value_shape:I},D),source_domain_context_witness(C,A,B,F,I,G,H))).
cw_rule((source_domain_context_witness(domain_atom,A,not_projected_by_source,'sequent_engine:current_domain/1',bare_domain_atom,current_domain_dynamic_fact_read,_13672{domain:A,finite_domain_set:[n,z,q],kind:current_domain_dynamic_state,mapped_context:C,mapping_witness:D,module:sequent_engine,predicate:current_domain/1}):-catch(sequent_engine:current_domain(A),_,fail),domain_context_mapping_witness(A,C,D))).
cw_rule((source_domain_context_witness(domain_context,not_projected_by_source,A,'sequent_engine:current_domain_context/1',named_context_projection,current_domain_context_projection,_13884{context:A,current_domain:C,finite_context_set:[natural_numbers,integers,rationals],kind:current_domain_context_projection,mapping_witness:D,module:sequent_engine,predicate:current_domain_context/1}):-catch(sequent_engine:current_domain_context(A),_,fail),catch(sequent_engine:current_domain(C),_,fail),domain_context_mapping_witness(C,A,D))).
cw_rule((domain_context_mapping_witness(A,B,_14156{context:B,domain:A,kind:finite_domain_context_mapping,mapping_table:[n-natural_numbers,z-integers,q-rationals],source_file:'formal/learner/axioms_domains.pl'}):-domain_context_pair(A,B),catch(sequent_engine:domain_to_context(A,B),_,fail))).
cw_rule(domain_context_pair(n,natural_numbers)).
cw_rule(domain_context_pair(z,integers)).
cw_rule(domain_context_pair(q,rationals)).
cw_rule(canonical_concept('sequent_engine:current_domain/1',domain_context_unified)).
cw_rule(canonical_concept('sequent_engine:current_domain_context/1',domain_context_unified)).
cw_rule(canonical_concept('sequent_engine:set_domain/1',domain_context_unified)).
cw_rule(vocabulary_source(domain_context_unified,['sequent_engine:current_domain/1','sequent_engine:current_domain_context/1','sequent_engine:set_domain/1'])).
