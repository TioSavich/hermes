:- module(json_writer, [
    write_json_facts/1
]).

:- use_module(library(http/json)).
:- use_module(library(lists)).
:- use_module(pattern_taxonomy).

%!  write_json_facts(+Path:atom) is det.
%
%   Emit a JSON file with schema:
%   { generated_at, taxonomy[], strategies[], elaborations[], unclassified[],
%     uncovered_modules[] }.
write_json_facts(Path) :-
    build_json(Dict),
    setup_call_cleanup(
        open(Path, write, S),
        json_write_dict(S, Dict, [width(80)]),
        close(S)
    ).

build_json(json{
    generated_at: Stamp,
    taxonomy: Taxonomy,
    strategies: Strategies,
    elaborations: Elaborations,
    unclassified: Unclassified,
    uncovered_modules: Uncovered
}) :-
    get_time(T), format_time(string(Stamp), "%FT%T%z", T),
    build_taxonomy(Taxonomy),
    build_strategies(Strategies),
    build_elaborations(Elaborations),
    build_unclassified(Unclassified),
    build_uncovered(Uncovered).

build_taxonomy(Taxonomy) :-
    findall(O-json{name: NameStr, category: CatStr, justification: JustStr, order: O},
            ( pattern(Name, Cat, Just),
              pattern_order(Name, O),
              atom_to_s(Name, NameStr),
              atom_to_s(Cat, CatStr),
              atom_to_s(Just, JustStr)
            ),
            Pairs),
    keysort(Pairs, Keyed),
    pairs_values(Keyed, Taxonomy).

pairs_values([], []).
pairs_values([_-V|T], [V|VT]) :- pairs_values(T, VT).

build_strategies(Strategies) :-
    automaton_analyzer:all_strategy_patterns(SPs),
    findall(json{name: NameStr, op: OpStr, module: ModStr, patterns: PatStrs},
            ( automaton_analyzer:strategy_registry(Name, Op, Mod, _),
              ( member(sp(Name, Pats), SPs) -> true ; Pats = [] ),
              atom_to_s(Name, NameStr),
              atom_to_s(Op, OpStr),
              atom_to_s(Mod, ModStr),
              maplist(atom_to_s, Pats, PatStrs)
            ),
            Strategies).

build_elaborations(Elaborations) :-
    automaton_analyzer:all_elaborations(Elabs),
    findall(json{
                base: BStr,
                elaborated: EStr,
                shared: ShStrs,
                type: TStr,
                confidence_max: CM,
                confidence_jaccard: CJ,
                direction_asymmetry: A
            },
            ( member(el(B, E, Sh, T, CM, CJ, A), Elabs),
              atom_to_s(B, BStr),
              atom_to_s(E, EStr),
              atom_to_s(T, TStr),
              maplist(atom_to_s, Sh, ShStrs)
            ),
            Elaborations).

build_unclassified(Unclassified) :-
    automaton_analyzer:all_unclassified(UCs),
    findall(json{strategy: NStr, reason: RStr},
            ( member(uc(N, R), UCs),
              atom_to_s(N, NStr),
              atom_to_s(R, RStr)
            ),
            Unclassified).

build_uncovered(Uncovered) :-
    automaton_analyzer:all_uncovered(Paths),
    findall(PStr,
            ( member(P, Paths),
              atom_to_s(P, PStr)
            ),
            Uncovered).

atom_to_s(A, S) :-
    ( atom(A) -> atom_string(A, S)
    ; string(A) -> S = A
    ; number(A) -> atom_number(Atom, A), atom_string(Atom, S)
    ; format(string(S), "~w", [A])
    ).
