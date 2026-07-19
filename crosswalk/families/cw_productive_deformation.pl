/** <module> cw_productive_deformation -- crosswalk family data. */
:-module(cw_productive_deformation,[cw_family/1,cw_rule/1,edge/5]).
:-use_module(strategies('math/action_automata_registry'),[]).
:-use_module(strategies('math/sar_add_action_pairs'),[]).
:-use_module(strategies('math/fraction_action_pairs'),[]).
cw_family(cw_productive_deformation).
edge(action_automata_registry,action_automaton_pair/4,[addition,count_on],[3,4],registry_projection).
cw_rule((productive_deformation_unified(A,B,C,D,E):-productive_deformation_witness(A,B,C,D,E,_16268))).
cw_rule((productive_deformation_witness(A,B,C,D,registry,E):-catch(action_automata_registry:action_automaton_pair(A,B,C,D),_16410,fail),pair_witness(A,B,C,D,registry,action_automata_registry,action_automaton_pair/4,operation_tagged_registry_union,E))).
cw_rule((productive_deformation_witness(addition,A,B,C,addition,D):-catch(sar_add_action_pairs:productive_deformation(A,B,C),_16584,fail),pair_witness(addition,A,B,C,addition,sar_add_action_pairs,productive_deformation/3,fixed_operation_projection(addition),D))).
cw_rule((productive_deformation_witness(fraction,A,B,C,fraction,D):-catch(fraction_action_pairs:productive_fraction_deformation(A,B,C),_16750,fail),pair_witness(fraction,A,B,C,fraction,fraction_action_pairs,productive_fraction_deformation/3,fixed_operation_projection(fraction),D))).
cw_rule((pair_witness(A,B,C,D,E,F,G,H,I):-witness_dict:witness_dict(productive_deformation_crosswalk,closed_world_finite_verified_productive_deformation_pairs,_16938{deformation:C,deformation_witness:M,derivation:owner_predicate_pair_check,family:D,operation:A,productive:B,productive_witness:L,projection:H,source:E,source_witness:_{deformation:C,family:D,kind:productive_deformation_pair_row,module:F,operation:A,predicate:G,productive:B}},I),action_kind_witness(A,B,L),action_kind_witness(A,C,M))).
cw_rule((action_kind_witness(A,B,_17228{action_kind:B,cluster:D,kind:action_automaton_kind_metadata,module:action_automata_registry,operation:A,vocabulary:E}):-catch(action_automata_registry:action_automaton_cluster(A,B,D),_,fail),catch(action_automata_registry:action_automaton_vocabulary(A,B,E),_,fail),!)).
cw_rule(action_kind_witness(A,B,_17462{action_kind:B,boundary:owner_pair_proved_without_registry_kind_metadata,kind:action_automaton_kind_metadata_absent,module:action_automata_registry,operation:A})).
cw_rule(canonical_concept('action_automata_registry:action_automaton_pair/4',productive_deformation_unified)).
cw_rule(canonical_concept('sar_add_action_pairs:productive_deformation/3',productive_deformation_unified)).
cw_rule(canonical_concept('fraction_action_pairs:productive_fraction_deformation/3',productive_deformation_unified)).
cw_rule(vocabulary_source(productive_deformation_unified,['action_automata_registry:action_automaton_pair/4','sar_add_action_pairs:productive_deformation/3','fraction_action_pairs:productive_fraction_deformation/3'])).
