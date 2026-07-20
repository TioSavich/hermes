/** <module> cw_godel_primes -- crosswalk family data. */
:-module(cw_godel_primes,[cw_family/1,cw_rule/1,edge/5]).
:-use_module(sequent(automata),[]).
:-use_module(sequent(sequent_engine),[]).
cw_family(cw_godel_primes).
edge(automata,is_prime/1,[2],[],call_match_ground).
cw_rule((godel_primes_unified(is_prime(A),true,automata):-godel_primes_witness(is_prime(A),true,automata,_20532))).
cw_rule((godel_primes_unified(nth_prime(A),B,automata):-godel_primes_witness(nth_prime(A),B,automata,_20616))).
cw_rule((godel_primes_unified(product_of_list(A),B,sequent_engine):-godel_primes_witness(product_of_list(A),B,sequent_engine,_20712))).
cw_rule((godel_primes_witness(A,B,C,D):-witness_dict:witness_dict(godel_prime_utility_crosswalk,closed_world_finite_loaded_godel_prime_utilities,_20796{derivation:G,legacy_functor:F,query:A,result:B,source:C,source_witness:H},D),godel_prime_source(C,F),source_godel_prime_witness(C,A,B,G,H))).
cw_rule(godel_prime_source(automata,'automata:is_prime/1 or automata:nth_prime/2')).
cw_rule(godel_prime_source(sequent_engine,'sequent_engine:product_of_list/2')).
cw_rule((source_godel_prime_witness(automata,is_prime(A),true,automata_primality_check,B):-catch(once(automata:is_prime(A)),_21124,fail),prime_check_witness(A,B))).
cw_rule((source_godel_prime_witness(automata,nth_prime(A),B,automata_prime_enumeration,_21216{final_prime_witness:E,index:A,kind:nth_prime_enumeration,prefix:D,prefix_length:A,prime:B}):-positive_integer(A),catch(once(automata:nth_prime(A,B)),_,fail),prime_prefix(A,D),last(D,B),prime_check_witness(B,E))).
cw_rule((source_godel_prime_witness(sequent_engine,product_of_list(A),B,sequent_engine_product_fold,_21448{identity:1,kind:product_of_list_fold,list:A,product:B,steps:D}):-catch(once(sequent_engine:product_of_list(A,B)),_,fail),product_trace(A,1,B,D))).
cw_rule((positive_integer(A):-integer(A),A>0)).
cw_rule((prime_check_witness(2,_21708{kind:primality_check,number:2,reason:first_prime,result:prime}):-!)).
cw_rule((prime_check_witness(A,_21780{candidates_checked:D,divisor_search:finite_odd_divisors_up_to_floor_sqrt,kind:primality_check,number:A,parity:odd,rejected_divisors:D,result:prime,upper_bound:C}):-integer(A),A>2,A mod 2=\=0,floor_sqrt(A,C),odd_divisor_candidates(3,C,D),no_divides(A,D))).
cw_rule((floor_sqrt(A,B):-B is floor(sqrt(A)))).
cw_rule((odd_divisor_candidates(A,B,[]):-A>B,!)).
cw_rule((odd_divisor_candidates(A,B,[A|C]):-A=<B,D is A+2,odd_divisor_candidates(D,B,C))).
cw_rule(no_divides(_22304,[])).
cw_rule((no_divides(A,[B|C]):-A mod B=\=0,no_divides(A,C))).
cw_rule((prime_prefix(A,B):-findall(C,(between(1,A,D),catch(once(automata:nth_prime(D,C)),_22502,fail)),B),length(B,A))).
cw_rule(product_trace([],A,A,[])).
cw_rule((product_trace([A|B],C,D,[_22700{accumulator_in:C,accumulator_out:F,factor:A}|G]):-number(A),F is C*A,product_trace(B,F,D,G))).
cw_rule(canonical_concept('automata:is_prime/1',godel_primes_unified)).
cw_rule(canonical_concept('automata:nth_prime/2',godel_primes_unified)).
cw_rule(canonical_concept('sequent_engine:product_of_list/2',godel_primes_unified)).
cw_rule(canonical_concept('axioms_number_theory:is_prime/1',godel_primes_unified)).
cw_rule(canonical_concept('axioms_number_theory:product_of_list/2',godel_primes_unified)).
cw_rule(vocabulary_source(godel_primes_unified,['automata:is_prime/1','automata:nth_prime/2','sequent_engine:product_of_list/2','axioms_number_theory:is_prime/1','axioms_number_theory:product_of_list/2'])).
