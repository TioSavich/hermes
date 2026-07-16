:- module(pattern_taxonomy, [
    pattern/3,
    pattern_order/2,
    all_patterns/1,
    substrategy_signature/2
]).

%!  pattern(?Name:atom, ?Category:atom, ?Justification:atom) is nondet.
%
%   The 12 elaboration patterns. Each is detected by walking parsed clause
%   bodies of transition/3 and transition/4. Justifications cite the
%   exemplar transition clause that motivated the pattern.

pattern(pat_successor_loop, counting,
        'successor/2 guarded by smaller_than/2: count up to a bound').
pattern(pat_predecessor_loop, counting,
        'predecessor/2 or subtract-by-one in a self-looping transition: count down').
pattern(pat_accumulator_addition, counting,
        'add_grounded into a register that appears in both source and target state').

pattern(pat_base_decomposition, place_value,
        'calls base_decompose_grounded/4 to split a quantity into quotient and remainder over the base').
pattern(pat_base_recomposition, place_value,
        'calls base_recompose_grounded/4 to rebuild a quantity from parts').
pattern(pat_target_base_adjustment, place_value,
        'computes next multiple of base via successor+multiply_grounded, or calls calculate_next_base_grounded').
pattern(pat_leading_chunk_extraction, place_value,
        'calls leading_digit_chunk/3 or leading_place_value/3 to pull a place-value slice').

pattern(pat_partial_product_accumulation, structural,
        'two distinct accumulator-named states (e.g., q_loop_P1 and q_loop_P2) or a bases+remainder split path').
pattern(pat_fact_lookup, structural,
        'greedy walk across a KB list of Multiple-Factor pairs, typically via find_best_fact/4 or analogous helper').
pattern(pat_list_redistribution, structural,
        'nth0/3-4 plus update_list/4 on a Groups list: move an element across a partitioned list').

pattern(pat_error_branch, control,
        'module produces state(q_error, ...) as a next-state in some transition clause').
pattern(pat_sub_strategy_invocation, control,
        'module state-name set properly contains a known sub-strategy shape (cobo_shape, k_count_shape, ppa_shape)').

%!  pattern_order(?Name:atom, ?Index:integer) is nondet.
%
%   Deterministic order for JSON/Prolog output. Lower index comes first.
pattern_order(pat_successor_loop,              1).
pattern_order(pat_predecessor_loop,            2).
pattern_order(pat_accumulator_addition,        3).
pattern_order(pat_base_decomposition,          4).
pattern_order(pat_base_recomposition,          5).
pattern_order(pat_target_base_adjustment,      6).
pattern_order(pat_leading_chunk_extraction,    7).
pattern_order(pat_partial_product_accumulation, 8).
pattern_order(pat_fact_lookup,                 9).
pattern_order(pat_list_redistribution,         10).
pattern_order(pat_error_branch,                11).
pattern_order(pat_sub_strategy_invocation,     12).

%!  all_patterns(-Patterns:list) is det.
all_patterns(Patterns) :-
    findall(P-I, pattern_order(P, I), Pairs0),
    keysort(Pairs0, Pairs),
    pairs_keys(Pairs, Keys),
    Patterns = Keys.

pairs_keys([], []).
pairs_keys([K-_|T], [K|KT]) :- pairs_keys(T, KT).

%!  substrategy_signature(?Shape:atom, ?StateNameSet:list) is nondet.
%
%   Canonical sub-strategy state-name signatures. A strategy exhibits
%   pat_sub_strategy_invocation iff its collected state-name set is a proper
%   superset of one of these.
substrategy_signature(cobo_shape_original, [q_add_bases, q_add_ones]).
substrategy_signature(cobo_shape_wrapped,  [q_loop_AddBases, q_loop_AddOnes]).
substrategy_signature(k_count_shape,       [q_init_K, q_loop_K]).
substrategy_signature(ppa_shape,           [q_loop_P1, q_loop_P2]).
