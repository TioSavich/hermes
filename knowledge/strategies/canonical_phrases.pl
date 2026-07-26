% Authored by hand; not generated.
%
% WHAT THIS IS FOR. hermes/strategy_recognizer.pl aligns transcript spans to
% automaton transitions, and its recognition surface is one phrase per LOCAL
% action label. 808 labels now sit in the transition tables; 24 of them carry a
% hand-written classroom phrasing, covering about five strategies. Every other
% label falls back to its own identifier split on underscores, so a student who
% says "I started from the bigger number and counted on" is not recognized while
% one who says "choose larger addend as start hold other addend as count" is
% recognized at confidence 1. That was checked against the running server rather
% than read off the source: see docs/research/2026-07-25-can-they-parse.md.
%
% THE ABSTRACTION IS THE SAME ONE THIS WHOLE ARC OPENED WITH. 638 labels each
% needing individual treatment became 122 canonical actions in
% knowledge/strategies/action_vocabulary_map.pl. The recognizer's wall is the
% same wall: 808 phrase-authoring decisions, 3% done. Ninety canonical actions
% carry mapping rows, so a phrase authored once here reaches every local label
% that maps to it -- one phrasing for align_to_common_unit serves the decimal,
% fraction and counting machines that each named it differently.
%
% WHAT A PHRASE IS AND IS NOT. These are reviewed classroom phrasings: things a
% student plausibly says while doing that step. They are recognition surfaces,
% not claims about how any particular student talks, and not a controlled
% language students should be taught. A phrase matching is evidence that a span
% aligns with a transition; it is not a diagnosis. The same discipline the
% recognizer's own docstring states applies to every row here.
%
% COVERAGE IS PARTIAL AND THE COUNT IS IN THE CHECK. Phrases are authored for
% the canonical actions carrying the most of the corpus first.
% scripts/checks/canonical_phrases.py reports how many of the 90 in-use actions
% have a phrase and how many mapping rows that reaches, so the gap is a number
% on every run rather than an impression.
%
% NO NEW VOCABULARY. Every phrase uses ordinary classroom words. Where a
% canonical action's name carries a technical term the alphabet cites
% (disembedding, unitizing, commensurate), the phrase says what a student would
% say instead, and the citation stays in action_vocabulary_map.pl where it
% belongs.

:- module(canonical_phrases,
          [ canonical_phrase/2
          ]).

% canonical_phrase(CanonicalAction, ListOfWords).

% -- constitution ---------------------------------------------------------
canonical_phrase(register_givens, [i,looked,at,the,numbers]).
canonical_phrase(register_givens, [i,read,the,problem]).
canonical_phrase(register_givens, [i,started,with,what,it,gave,me]).
canonical_phrase(read_operand_attribute, [i,noticed,how,big,they,were]).
canonical_phrase(read_operand_attribute, [i,checked,what,kind,of,numbers,they,were]).
canonical_phrase(read_operand_attribute, [i,saw,what,the,numbers,were,like]).
canonical_phrase(assign_roles, [i,worked,out,which,number,was,which]).
canonical_phrase(assign_roles, [i,decided,which,one,was,the,groups]).
canonical_phrase(assign_roles, [i,figured,out,what,each,number,stood,for]).
canonical_phrase(unitize_referent, [i,decided,what,counted,as,one,whole]).
canonical_phrase(unitize_referent, [i,picked,the,whole]).
canonical_phrase(unitize_referent, [i,said,this,is,the,unit]).
canonical_phrase(select_unit_scale, [i,chose,what,to,count,in]).
canonical_phrase(select_unit_scale, [i,picked,the,unit,to,work,in]).
canonical_phrase(select_unit_scale, [i,decided,to,use,tens]).
canonical_phrase(establish_reference_frame, [i,drew,the,number,line]).
canonical_phrase(establish_reference_frame, [i,started,from,zero]).
canonical_phrase(establish_reference_frame, [i,set,up,the,axes]).
canonical_phrase(initiate, [i,started]).
canonical_phrase(initiate, [first]).
canonical_phrase(conflate_roles, [i,mixed,up,which,number,was,which]).
canonical_phrase(conflate_roles, [i,thought,they,were,the,same,thing]).
canonical_phrase(misread_intermediate_value, [i,read,it,wrong]).
canonical_phrase(misread_intermediate_value, [i,carried,the,wrong,number]).
canonical_phrase(substitute_symbol_reading, [the,equals,sign,means,work,it,out]).
canonical_phrase(substitute_symbol_reading, [equals,means,the,answer,goes,here]).

% -- partition ------------------------------------------------------------
canonical_phrase(partition_into_equal_parts, [i,cut,it,into,equal,parts]).
canonical_phrase(partition_into_equal_parts, [i,split,it,evenly]).
canonical_phrase(partition_into_equal_parts, [i,shared,it,into,equal,pieces]).
canonical_phrase(decompose_by_place, [i,broke,it,into,tens,and,ones]).
canonical_phrase(decompose_by_place, [i,split,it,by,place,value]).
canonical_phrase(decompose_operand, [i,broke,the,other,number,up]).
canonical_phrase(decompose_operand, [i,split,one,of,them,apart]).
canonical_phrase(decompose_region, [i,cut,the,shape,into,pieces]).
canonical_phrase(decompose_region, [i,unfolded,it,flat]).
canonical_phrase(disembed_part, [i,took,one,piece,out,and,kept,track,of,the,whole]).
canonical_phrase(disembed_part, [i,pulled,out,one,part]).
canonical_phrase(disembed_part, [i,took,one,share,without,losing,the,whole]).
canonical_phrase(select_part, [i,picked,one,of,them]).
canonical_phrase(select_part, [i,chose,that,piece]).

% -- iteration and counting ----------------------------------------------
canonical_phrase(iterate_unit, [i,kept,copying,the,piece]).
canonical_phrase(iterate_unit, [i,repeated,it,over,and,over]).
canonical_phrase(iterate_unit, [i,laid,it,down,again,and,again]).
canonical_phrase(iterate_composite_unit, [i,counted,by,groups]).
canonical_phrase(iterate_composite_unit, [i,skip,counted]).
canonical_phrase(iterate_composite_unit, [i,counted,each,group,as,one]).
% TalkMoves full corpus: recurring band (10-24 student sentences per form).
canonical_phrase(iterate_composite_unit, [count,by]).
canonical_phrase(iterate_composite_unit, [counted,by]).
canonical_phrase(iterate_composite_unit, [counting,by]).
canonical_phrase(count_units, [i,counted,them]).
canonical_phrase(count_units, [i,counted,how,many]).
canonical_phrase(count_on_from, [i,started,from,the,bigger,number,and,counted,on]).
canonical_phrase(count_on_from, [i,counted,on,from,there]).
canonical_phrase(count_on_from, [i,kept,going,from,that,number]).
canonical_phrase(count_back_from, [i,counted,backwards]).
canonical_phrase(count_back_from, [i,counted,back,from,it]).
canonical_phrase(count_up_to_target, [i,counted,up,until,i,got,there]).
canonical_phrase(count_up_to_target, [i,counted,how,far,it,was]).
canonical_phrase(count_up_to_target, [i,worked,out,the,distance]).
canonical_phrase(accumulate_total, [i,added,them,all,up]).
canonical_phrase(accumulate_total, [i,kept,a,running,total]).
% TalkMoves full corpus: common/recurring bands (28 and 15 student sentences).
canonical_phrase(accumulate_total, [in,all]).
canonical_phrase(accumulate_total, [all,together]).
canonical_phrase(traverse_boundary, [i,went,round,the,outside]).
canonical_phrase(traverse_boundary, [i,walked,along,each,side]).
canonical_phrase(measure_quantity, [i,measured,each,one]).
canonical_phrase(measure_quantity, [i,worked,out,how,much,each,was]).
canonical_phrase(halt_before_completion, [i,stopped,there]).
canonical_phrase(halt_before_completion, [i,did,not,finish,going,round]).
canonical_phrase(double_count, [i,counted,some,of,them,twice]).

% -- transformation ------------------------------------------------------
canonical_phrase(align_to_common_unit, [i,gave,them,the,same,denominator]).
canonical_phrase(align_to_common_unit, [i,put,them,in,the,same,units]).
canonical_phrase(align_to_common_unit, [i,made,the,bottoms,match]).
canonical_phrase(re_express_equivalently, [i,rewrote,it,the,same,amount]).
canonical_phrase(re_express_equivalently, [i,wrote,it,a,different,way]).
canonical_phrase(regroup_to_base, [i,made,a,ten,out,of,them]).
canonical_phrase(regroup_to_base, [i,traded,ten,ones,for,a,ten]).
canonical_phrase(regroup_to_base, [i,carried,the,ten]).
canonical_phrase(exchange_base_down, [i,broke,a,ten,into,ones]).
canonical_phrase(exchange_base_down, [i,borrowed,from,the,next,column]).
canonical_phrase(scale_multiplicatively, [i,scaled,them,both,up]).
canonical_phrase(scale_multiplicatively, [i,multiplied,them,by,the,same,thing]).
canonical_phrase(transfer_between_operands, [i,took,some,from,one,and,gave,it,to,the,other]).
canonical_phrase(transfer_between_operands, [i,moved,both,numbers,the,same,amount]).
canonical_phrase(round_to_landmark, [i,rounded,it,to,a,friendly,number]).
canonical_phrase(round_to_landmark, [i,made,it,up,to,the,nearest,ten]).
canonical_phrase(restore_adjustment, [i,took,the,extra,back,off]).
canonical_phrase(restore_adjustment, [i,adjusted,at,the,end]).
canonical_phrase(commute_operands, [i,swapped,them,round]).
canonical_phrase(commute_operands, [i,did,it,the,other,way,round]).
canonical_phrase(distribute_over_partition, [i,gave,each,part,the,same,factor]).
canonical_phrase(distribute_over_partition, [i,broke,it,apart,and,multiplied,each,bit]).
canonical_phrase(substitute_values, [i,put,the,numbers,in]).
canonical_phrase(substitute_values, [i,swapped,the,letters,for,numbers]).
canonical_phrase(recompose_total, [i,put,the,parts,back,together]).
canonical_phrase(recompose_total, [i,joined,them,back,up]).
canonical_phrase(compose_expression, [i,wrote,it,as,an,equation]).
canonical_phrase(compose_expression, [i,built,the,expression]).
canonical_phrase(retain_unchanged, [i,left,that,one,alone]).
canonical_phrase(retain_unchanged, [i,kept,it,as,it,was]).
canonical_phrase(retain_what_must_survive, [i,kept,the,leftover]).
canonical_phrase(retain_what_must_survive, [i,held,onto,the,unit]).
canonical_phrase(retain_where_change_was_due, [i,left,the,other,one,the,same]).
canonical_phrase(retain_where_change_was_due, [i,did,not,change,the,other,side]).
canonical_phrase(rename_in_place_of_transforming, [i,just,changed,what,i,called,it]).
canonical_phrase(rename_in_place_of_transforming, [i,kept,the,number,and,changed,the,unit]).

% -- grounded operation --------------------------------------------------
canonical_phrase(combine_quantities, [i,added,them]).
canonical_phrase(combine_quantities, [i,put,them,together]).
% TalkMoves full corpus: common/recurring bands (39, 10, and 6 sentences).
canonical_phrase(combine_quantities, [add,it]).
canonical_phrase(combine_quantities, [added,it]).
canonical_phrase(combine_quantities, [adding,it]).
canonical_phrase(remove_quantity, [i,took,it,away]).
canonical_phrase(remove_quantity, [i,subtracted,it]).
% TalkMoves full corpus: very common/sparse bands (50, 6, and 8 sentences).
canonical_phrase(remove_quantity, [take,away]).
canonical_phrase(remove_quantity, [took,away]).
canonical_phrase(remove_quantity, [taking,away]).
canonical_phrase(replicate_equal_groups, [i,made,equal,groups]).
canonical_phrase(replicate_equal_groups, [i,did,that,many,groups,of,that,many]).
canonical_phrase(share_into_known_groups, [i,dealt,them,out,one,each]).
canonical_phrase(share_into_known_groups, [i,shared,them,between,the,groups]).
canonical_phrase(measure_out_group_size, [i,kept,taking,that,many,away]).
canonical_phrase(measure_out_group_size, [i,counted,how,many,groups,fit]).
canonical_phrase(compute_product, [i,multiplied,them]).
canonical_phrase(compute_product, [i,timesed,them]).
% TalkMoves full corpus: common/recurring bands (44, 26, and 10 sentences).
canonical_phrase(compute_product, [multiply,by]).
canonical_phrase(compute_product, [multiplied,by]).
canonical_phrase(compute_product, [multiplying,by]).
canonical_phrase(compute_quotient, [i,divided,them]).
canonical_phrase(compute_quotient, [i,halved,it]).
canonical_phrase(apply_stored_rule, [i,used,the,rule]).
canonical_phrase(apply_stored_rule, [i,did,the,steps,i,was,taught]).
canonical_phrase(apply_quantity_change, [i,changed,the,amount]).
canonical_phrase(retrieve_known_fact, [i,just,knew,it]).
canonical_phrase(retrieve_known_fact, [i,remembered,that,one]).
canonical_phrase(retrieve_known_fact, [i,knew,a,near,one]).
canonical_phrase(exhaust_resource, [i,could,not,remember,it]).
canonical_phrase(exhaust_resource, [there,was,no,way,back]).
canonical_phrase(evaluate_expression, [i,worked,out,what,it,came,to]).
canonical_phrase(substitute_operation, [i,added,them,instead]).
canonical_phrase(substitute_operation, [i,did,the,other,operation]).

% -- comparison and search -----------------------------------------------
canonical_phrase(compare_magnitudes, [i,worked,out,which,was,bigger]).
canonical_phrase(compare_magnitudes, [i,compared,them]).
canonical_phrase(match_one_to_one, [i,matched,them,up,one,to,one]).
canonical_phrase(match_one_to_one, [i,paired,them,off]).
canonical_phrase(judge_against_benchmark, [i,checked,each,against,a,half]).
canonical_phrase(judge_against_benchmark, [i,saw,which,side,of,a,half,they,were]).
canonical_phrase(compare_residuals, [i,looked,at,how,much,was,left,over,in,each]).
canonical_phrase(compare_additive_gaps, [i,looked,at,the,gap,between,top,and,bottom]).
canonical_phrase(order_by_magnitude, [i,put,them,in,order]).
canonical_phrase(order_by_magnitude, [i,lined,them,up,smallest,first]).
canonical_phrase(locate_position, [i,found,where,it,goes]).
canonical_phrase(locate_position, [i,marked,it,on,the,line]).
canonical_phrase(test_criteria, [i,checked,whether,it,fit]).
canonical_phrase(test_criteria, [i,tested,if,that,was,true]).
canonical_phrase(enumerate_candidates, [i,listed,all,the,ones,i,could,find]).
canonical_phrase(enumerate_candidates, [i,tried,them,all]).
canonical_phrase(filter_by_constraint, [i,kept,the,ones,that,worked]).
canonical_phrase(filter_by_constraint, [i,threw,out,the,ones,that,did,not,fit]).
canonical_phrase(intersect_candidate_sets, [i,found,the,ones,in,both,lists]).
canonical_phrase(select_extremal, [i,took,the,biggest,one]).
canonical_phrase(select_extremal, [i,picked,the,smallest,that,worked]).
canonical_phrase(isolate_unknown, [i,got,the,unknown,on,its,own]).
canonical_phrase(isolate_unknown, [i,worked,out,what,the,missing,one,was]).
canonical_phrase(set_aside_irrelevant_attribute, [it,does,not,matter,which,way,round,it,is]).
canonical_phrase(set_aside_irrelevant_attribute, [i,ignored,that,because,it,does,not,change,it]).
canonical_phrase(substitute_appearance_for_measure, [it,looked,bigger]).
canonical_phrase(substitute_appearance_for_measure, [i,went,by,how,it,looked]).
canonical_phrase(substitute_count_for_measure, [i,counted,the,pieces]).
canonical_phrase(substitute_count_for_measure, [i,counted,the,marks]).
canonical_phrase(substitute_additive_for_multiplicative, [i,looked,at,the,difference,instead]).
canonical_phrase(substitute_scalar_for_structured_quantity, [i,ignored,the,minus,sign]).
canonical_phrase(substitute_scalar_for_structured_quantity, [i,just,used,how,far,it,was]).

% -- delegation and closure ----------------------------------------------
canonical_phrase(dispatch_to_kernel, [i,checked,it,with,a,drawing]).
canonical_phrase(dispatch_to_kernel, [i,worked,that,bit,out,separately]).
canonical_phrase(receive_kernel_outcome, [that,gave,me,the,answer,to,use]).
canonical_phrase(verify_invariant, [i,checked,it,still,held]).
canonical_phrase(verify_invariant, [i,made,sure,they,were,the,same,size]).
canonical_phrase(verify_by_substitution, [i,put,it,back,in,to,check]).
canonical_phrase(name_result, [so,the,answer,is]).
canonical_phrase(name_result, [that,gives]).
canonical_phrase(name_result, [i,got]).
canonical_phrase(inscribe_result, [i,wrote,it,down]).
canonical_phrase(inscribe_result, [i,put,the,digits,in]).
canonical_phrase(emit_result, [so,that,one,is,bigger]).
canonical_phrase(emit_result, [that,is,my,answer]).
canonical_phrase(record_conservation, [it,is,still,the,same,amount]).
canonical_phrase(record_conservation, [nothing,got,lost]).
canonical_phrase(record_loss, [i,lost,track,of,something]).
canonical_phrase(record_loss, [that,is,not,the,same,amount,any,more]).
canonical_phrase(record_viability, [it,depends,on,the,numbers]).
canonical_phrase(attach_units_coordination, [i,can,count,past,the,whole,now]).
canonical_phrase(misname_result, [i,gave,the,wrong,thing,as,the,answer]).
canonical_phrase(misname_result, [i,answered,a,different,question]).
canonical_phrase(omit_required_step, [i,skipped,that,step]).
canonical_phrase(omit_required_step, [i,did,not,do,that,part]).
canonical_phrase(treat_relevant_as_irrelevant, [i,ignored,that,bit]).
canonical_phrase(treat_relevant_as_irrelevant, [i,did,not,think,it,mattered]).
canonical_phrase(accept_without_check, [i,did,not,check,they,were,equal]).
canonical_phrase(accept_without_check, [i,just,took,it,as,given]).
