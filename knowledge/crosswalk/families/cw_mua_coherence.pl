/** <module> cw_mua_coherence -- crosswalk family data. */
:-module(cw_mua_coherence,[cw_family/1,cw_rule/1,edge/5]).
:-use_module(pml(mua_relations),[]).
:-use_module(hermes(encyclopedia),[]).
cw_family(cw_mua_coherence).
edge(mua_relations,kind_mua_coherence/3,[fraction,"unit fraction"],[3],call_bind_out).
cw_rule((mua_coherence_unified(A,B,C,pml_vocabulary):-mua_coherence_witness(A,B,C,pml_vocabulary,_7786))).
cw_rule((mua_coherence_unified(axiom_batch,A,B,pml_axiom_batch):-mua_coherence_witness(axiom_batch,A,B,pml_axiom_batch,_7890))).
cw_rule((mua_coherence_witness(A,B,C,D,E):-witness_dict:witness_dict(mua_coherence_crosswalk,closed_world_finite_loaded_mua_coherence_sources,_7976{derivation:H,input_scope:J,legacy_functor:G,score:C,score_meaning:K,source:D,source_witness:I,subject:A},E),mua_coherence_source(D,G),source_mua_coherence_witness(D,A,B,C,J,K,H,I))).
cw_rule((mua_coherence_source_witness(A,B,C,D,E):-mua_coherence_witness(A,B,C,D,F),get_dict(source_witness,F,E))).
cw_rule(mua_coherence_source(pml_vocabulary,'mua_relations:kind_mua_coherence/3')).
cw_rule(mua_coherence_source(pml_axiom_batch,'hermes_encyclopedia:pml_score_dict/2')).
cw_rule((source_mua_coherence_witness(pml_vocabulary,A,B,C,lower_cased_corpus_row_text,vocabulary_terms_hit_count,kind_vocabulary_hit_scan,D):-catch(mua_relations:kind_mua_coherence_witness(A,B,C,D),_8514,fail))).
cw_rule((source_mua_coherence_witness(pml_axiom_batch,axiom_batch,A,B,parsed_reader_axiom_clause_strings,valid_reader_axiom_count,pml_clause_validation,_8614{clause_count:D,kind:hermes_pml_axiom_batch_score,valid_count:B,validation:E}):-catch(hermes_encyclopedia:pml_score_dict(A,E),_,fail),get_dict(valid_count,E,B),get_dict(clause_count,E,D))).
cw_rule(canonical_concept('mua_relations:kind_mua_coherence/3',mua_coherence_unified)).
cw_rule(canonical_concept('hermes_encyclopedia:pml_score_dict/2',mua_coherence_unified)).
cw_rule(vocabulary_source(mua_coherence_unified,['mua_relations:kind_mua_coherence/3','hermes_encyclopedia:pml_score_dict/2'])).
