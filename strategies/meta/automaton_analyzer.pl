:- module(automaton_analyzer, [
    analyze_all/0,
    analyze_all/1,
    strategy_registry/4,
    strategy_patterns/2,
    pattern_evidence/3,
    unclassified/2,
    uncovered_module/1,
    elaborates/7,
    all_strategy_patterns/1,
    all_pattern_evidence/1,
    all_elaborations/1,
    all_unclassified/1,
    all_uncovered/1,
    run_and_emit/0,
    run_and_emit/1,
    clear_analysis/0
]).

:- use_module(introspection).
:- use_module(pattern_taxonomy).
:- use_module(pattern_detectors).
:- use_module(elaboration_detector).
:- use_module(fact_writer).
:- use_module(json_writer).
:- use_module(library(lists)).

:- dynamic(strategy_patterns/2).
:- dynamic(pattern_evidence/3).
:- dynamic(unclassified/2).
:- dynamic(uncovered_module/1).
:- dynamic(elaborates/7).

%!  strategy_registry(?Name:atom, ?Op:atom, ?Module:atom, ?FilePath:atom) is nondet.
%
%   The 20 canonical strategies dispatched by hermeneutic_calculator.pl.
strategy_registry('COBO',                  '+', sar_add_cobo,              'strategies/math/sar_add_cobo.pl').
strategy_registry('Chunking',              '+', sar_add_chunking,          'strategies/math/sar_add_chunking.pl').
strategy_registry('RMB',                   '+', sar_add_rmb,               'strategies/math/sar_add_rmb.pl').
strategy_registry('Rounding',              '+', sar_add_rounding,          'strategies/math/sar_add_rounding.pl').
strategy_registry('COBO (Missing Addend)', '-', sar_sub_cobo_missing_addend, 'strategies/math/sar_sub_cobo_missing_addend.pl').
strategy_registry('CBBO (Take Away)',      '-', sar_sub_cbbo_take_away,    'strategies/math/sar_sub_cbbo_take_away.pl').
strategy_registry('Decomposition',         '-', sar_sub_decomposition,     'strategies/math/sar_sub_decomposition.pl').
strategy_registry('Sub Rounding',          '-', sar_sub_rounding,          'strategies/math/sar_sub_rounding.pl').
strategy_registry('Sliding',               '-', sar_sub_sliding,           'strategies/math/sar_sub_sliding.pl').
strategy_registry('Chunking A',            '-', sar_sub_chunking_a,        'strategies/math/sar_sub_chunking_a.pl').
strategy_registry('Chunking B',            '-', sar_sub_chunking_b,        'strategies/math/sar_sub_chunking_b.pl').
strategy_registry('Chunking C',            '-', sar_sub_chunking_c,        'strategies/math/sar_sub_chunking_c.pl').
strategy_registry('C2C',                   '*', smr_mult_c2c,              'strategies/math/smr_mult_c2c.pl').
strategy_registry('CBO',                   '*', smr_mult_cbo,              'strategies/math/smr_mult_cbo.pl').
strategy_registry('Commutative Reasoning', '*', smr_mult_commutative_reasoning, 'strategies/math/smr_mult_commutative_reasoning.pl').
strategy_registry('DR',                    '*', smr_mult_dr,               'strategies/math/smr_mult_dr.pl').
strategy_registry('CGOB',        '/', smr_div_cbo,               'strategies/math/smr_div_cbo.pl').
strategy_registry('Dealing by Ones',       '/', smr_div_dealing_by_ones,   'strategies/math/smr_div_dealing_by_ones.pl').
strategy_registry('IDP',                   '/', smr_div_idp,               'strategies/math/smr_div_idp.pl').
strategy_registry('UCR',                   '/', smr_div_ucr,               'strategies/math/smr_div_ucr.pl').

%!  clear_analysis is det.
clear_analysis :-
    retractall(strategy_patterns(_, _)),
    retractall(pattern_evidence(_, _, _)),
    retractall(unclassified(_, _)),
    retractall(uncovered_module(_)),
    retractall(elaborates(_, _, _, _, _, _, _)).

%!  analyze_all is det.
%!  analyze_all(+Options:list) is det.
%
%   Load every canonical strategy module, introspect its transition clauses,
%   assert strategy_patterns/2 and pattern_evidence/3 for each, surface
%   unclassified and uncovered modules, then compute pairwise elaborations.
analyze_all :-
    analyze_all([]).
analyze_all(_Options) :-
    clear_analysis,
    load_all_modules,
    forall(strategy_registry(Name, _Op, Mod, _Path),
           analyze_strategy(Name, Mod)),
    surface_uncovered,
    compute_and_assert_elaborations.

load_all_modules :-
    forall(strategy_registry(_, _, _Mod, Path),
           catch(load_files(Path, [if(not_loaded), imports([])]),
                 E,
                 format(user_error, "warn: could not load ~w: ~w~n", [Path, E])
           )).

analyze_strategy(Name, Mod) :-
    collect_strategy_clauses(Mod, Clauses),
    ( Clauses = [] ->
        assertz(unclassified(Name, no_transition_clauses_found))
    ;
        detect_patterns(Name, Clauses, Patterns, Evidence),
        ( Patterns = [] ->
            assertz(unclassified(Name, no_patterns_matched))
        ;
            assertz(strategy_patterns(Name, Patterns)),
            forall(member(evidence(P, H, G), Evidence),
                   assertz(pattern_evidence(Name, P, ev(H, G))))
        )
    ).

surface_uncovered :-
    findall(Path,
            ( expand_file_name('strategies/math/*.pl', Paths),
              member(Path, Paths)
            ),
            AllPaths),
    findall(Registered, strategy_registry(_, _, _, Registered), RegisteredPaths),
    forall(( member(P, AllPaths),
             \+ ( member(R, RegisteredPaths),
                  atom_concat(_, R, P)
                )
           ),
           assertz(uncovered_module(P))).

compute_and_assert_elaborations :-
    findall(Name-Patterns, strategy_patterns(Name, Patterns), SP),
    compute_elaborations(SP, Elabs),
    forall(member(elaboration(B, E, S, T, CM, CJ, A), Elabs),
           assertz(elaborates(B, E, S, T, CM, CJ, A))).

%!  run_and_emit is det.
%!  run_and_emit(+Options:list) is det.
%
%   Analyze and write outputs to docs/analysis/.
run_and_emit :-
    run_and_emit([]).
run_and_emit(Options) :-
    analyze_all(Options),
    option_or(Options, prolog_out, 'docs/analysis/elaborations.pl', PrologPath),
    option_or(Options, json_out,   'docs/analysis/elaborations.json', JsonPath),
    write_prolog_facts(PrologPath),
    write_json_facts(JsonPath),
    print_summary(user_output).

option_or(Options, Key, Default, Value) :-
    ( Member =.. [Key, Value],
      memberchk(Member, Options)
    -> true
    ;  Value = Default
    ).

all_strategy_patterns(L) :- findall(sp(N, Ps), strategy_patterns(N, Ps), L).
all_pattern_evidence(L) :- findall(pe(N, P, Ev), pattern_evidence(N, P, Ev), L).
all_elaborations(L) :- findall(el(B, E, Sh, T, CM, CJ, A), elaborates(B, E, Sh, T, CM, CJ, A), L).
all_unclassified(L) :- findall(uc(N, R), unclassified(N, R), L).
all_uncovered(L) :- findall(P, uncovered_module(P), L).

print_summary(Stream) :-
    aggregate_all(count, strategy_patterns(_, _), NClassified),
    aggregate_all(count, unclassified(_, _), NUnclassified),
    aggregate_all(count, elaborates(_, _, _, elaboration, _, _, _), NElab),
    aggregate_all(count, elaborates(_, _, _, peer, _, _, _), NPeer),
    aggregate_all(count, uncovered_module(_), NUncov),
    format(Stream, "~n== automaton_analyzer summary ==~n", []),
    format(Stream, "strategies classified:   ~w~n", [NClassified]),
    format(Stream, "strategies unclassified: ~w~n", [NUnclassified]),
    format(Stream, "elaboration pairs:       ~w~n", [NElab]),
    format(Stream, "peer pairs:              ~w~n", [NPeer]),
    format(Stream, "uncovered modules:       ~w~n", [NUncov]).
