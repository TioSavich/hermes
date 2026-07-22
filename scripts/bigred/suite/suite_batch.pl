:- module(suite_batch, [main/1]).

:- use_module(library(apply)).
:- use_module(library(filesex)).
:- use_module(library(http/json)).
:- use_module(library(lists)).
:- use_module(crosswalk('families/cw_driver'), []).
:- use_module(strategies('meta/automaton_analyzer'), []).
:- use_module(carving(strategy_machine)).
:- use_module(incompat(find_emergent_hyperedges)).
:- use_module(incompat(incompatibility_sets)).
:- use_module(math(action_automata_registry)).
:- use_module(strategies(inferential_strength)).
:- use_module(lessons(im/lesson_monitoring)).

main(hyperedges) :- !, run_hyperedges.
main(search_traces) :- !, run_search_traces.
main(predicate_carving) :- !, run_predicate_carving.
main(learner_paths) :- !, run_learner_paths.
main(Scenario) :- throw(error(domain_error(bigred_scenario, Scenario), _)).

output_dir(Dir) :-
    getenv('BIGRED_OUTPUT_DIR', Dir),
    make_directory_path(Dir).

limit(Limit) :-
    ( getenv('BIGRED_LIMIT', Text), catch(atom_number(Text, Limit), _, fail) -> true ; Limit = 0 ).

take_limit(0, List, List) :- !.
take_limit(Limit, List, Prefix) :-
    length(Prefix, Limit), append(Prefix, _, List), !.
take_limit(_, List, List).

write_json(Path, Dict) :-
    setup_call_cleanup(open(Path, write, Out, [encoding(utf8)]),
                       ( json_write_dict(Out, Dict, [width(0)]), nl(Out) ),
                       close(Out)).

term_text(Term, Text) :- term_string(Term, Text, [quoted(true), numbervars(true)]).

run_hyperedges :-
    output_dir(Dir), limit(Limit),
    directory_file_path(Dir, 'search.md', Markdown),
    setup_call_cleanup(open(Markdown, write, Out, [encoding(utf8)]),
                       with_output_to(Out, find_emergent_hyperedges:run_search),
                       close(Out)),
    findall(Text, ( find_emergent_hyperedges:emergent_in_discovery_layer(Set), term_text(Set, Text) ), Sets0),
    sort(Sets0, Sets), take_limit(Limit, Sets, Limited),
    length(Sets, Total), length(Limited, Returned),
    directory_file_path(Dir, 'hyperedges.json', Json),
    write_json(Json, _{scenario:"hyperedges", scope:"finite live re-check", total_emergent_sets:Total,
                       returned_sets:Returned, limit:Limit, emergent_sets:Limited,
                       markdown:"search.md"}).

trace_target(add_count_on, add, 3, 2, 1, m1, 6).
trace_target(add_make_ten, add, 8, 5, 2, m2, 8).
trace_target(add_overshoot, add, 7, 8, 2, m1, 8).
trace_target(subtract_count_up, sub, 9, 4, 2, m1, 7).

run_search_traces :-
    output_dir(Dir), limit(Limit),
    findall(target(Id, Op, A, B, Level, Seed, Bound), trace_target(Id, Op, A, B, Level, Seed, Bound), Targets0),
    take_limit(Limit, Targets0, Targets),
    maplist(write_trace_target(Dir), Targets),
    length(Targets, Count),
    directory_file_path(Dir, 'index.json', Index),
    write_json(Index, _{scenario:"search_traces", target_count:Count, limit:Limit,
                         ordered_step_license:"Every step records its source transition predicate and any unit or recall fact used."}).

write_trace_target(Dir, target(Id, Op, A, B, Level, Seed, Bound)) :-
    carving_strategy_machine:set_seed(Seed),
    carving_strategy_machine:initial_state(Op, A, B, Level, Initial),
    carving_strategy_machine:all_paths(Op, A, B, Level, Bound, Paths),
    maplist(trace_dict(Initial, Level), Paths, TraceDicts),
    length(Paths, Count), atom_string(Id, IdText), atom_concat(Id, '.json', JsonName),
    directory_file_path(Dir, JsonName, JsonPath),
    write_json(JsonPath, _{target:IdText, operation:Op, inputs:_{a:A,b:B}, level:Level,
                           seed:Seed, bound:Bound, path_count:Count, paths:TraceDicts}),
    atom_concat(Id, '.md', MdName), directory_file_path(Dir, MdName, MdPath),
    setup_call_cleanup(open(MdPath, write, Out, [encoding(utf8)]),
                       write_trace_markdown(Out, IdText, Op, A, B, Level, Seed, Bound, TraceDicts),
                       close(Out)).

trace_dict(Initial, Level, path(Cost, Moves), _{cost:Cost, steps:Steps}) :-
    path_steps(Initial, Level, Moves, Steps).

path_steps(_, _, [], []).
path_steps(State0, Level, [Move|Moves], [Step|Steps]) :-
    once(carving_strategy_machine:move(State0, Move, State1, Cost)),
    term_text(State0, Before), term_text(Move, MoveText), term_text(State1, After),
    step_licenses(Move, Level, Licenses),
    Step = _{before:Before, move:MoveText, after:After, cost:Cost, licensing_facts:Licenses},
    path_steps(State1, Level, Moves, Steps).

step_licenses(recall(A, B, Value), _, ["carving_strategy_machine:move/4", Fact]) :- !,
    format(string(Fact), "carving_strategy_machine:known_fact(~w,~w,~w)", [A, B, Value]).
step_licenses(add_unit(Unit), Level, ["carving_strategy_machine:move/4", Fact]) :- !,
    format(string(Fact), "carving_strategy_machine:unit_for_level(~w,~w)", [Level, Unit]).
step_licenses(sub_unit(Unit), Level, ["carving_strategy_machine:move/4", Fact]) :- !,
    format(string(Fact), "carving_strategy_machine:unit_for_level(~w,~w)", [Level, Unit]).
step_licenses(_, _, ["carving_strategy_machine:move/4"]).

write_trace_markdown(Out, Id, Op, A, B, Level, Seed, Bound, Traces) :-
    format(Out, "# Ordered search trace: ~w~n~n", [Id]),
    format(Out, "Input: `~w(~w, ~w)`, level ~w, seed `~w`, bound ~w.~n~n", [Op, A, B, Level, Seed, Bound]),
    forall(nth1(N, Traces, Trace), write_one_trace(Out, N, Trace)).

write_one_trace(Out, N, Trace) :-
    format(Out, "## Path ~w (cost ~w)~n~n", [N, Trace.cost]),
    forall(nth1(I, Trace.steps, Step),
           ( atomics_to_string(Step.licensing_facts, "; ", LicenseText),
             format(Out, "~w. `~s` -> `~s` -> `~s` [~s]~n", [I, Step.before, Step.move, Step.after, LicenseText]) )).

run_predicate_carving :-
    output_dir(Dir), limit(Limit),
    lesson_codes(LessonCodes0), take_limit(Limit, LessonCodes0, LessonCodes),
    maplist(lesson_row, LessonCodes, LessonRows),
    operation_rows(Limit, OperationRows),
    containment_rows(Limit, ContainmentRows),
    directory_file_path(Dir, 'predicate-carving.json', Json),
    write_json(Json, _{scenario:"predicate_carving", scope:"closed-world finite inferential-strength and incompatibility profiles",
                       limit:Limit, lessons:LessonRows, operations:OperationRows, containment_verdicts:ContainmentRows}),
    directory_file_path(Dir, 'README-results.md', Markdown),
    setup_call_cleanup(open(Markdown, write, Out, [encoding(utf8)]),
                       write_carving_markdown(Out, LessonRows, OperationRows, ContainmentRows), close(Out)).

lesson_codes(Codes) :-
    findall(Code,
            ( lesson_monitoring:encoded_lesson(Code, _, _, _, _, _),
              atom(Code) ),
            Raw),
    sort(Raw, Codes).

lesson_row(Code, _{lesson:CodeText, report:ReportText}) :-
    inferential_strength:lesson_inferential_strength_for(Code, Report), term_text(Code, CodeText), term_text(Report, ReportText).

operation_rows(Limit, Rows) :-
    findall(Op, action_automata_registry:action_automaton_signature(Op, _, _, _), Ops0), sort(Ops0, Ops),
    take_limit(Limit, Ops, Selected), maplist(operation_row, Selected, Rows).

operation_row(Op, _{operation:OpText, registered_signatures:Count, path_model:PathText}) :-
    aggregate_all(count, action_automata_registry:action_automaton_signature(Op, _, _, _), Count),
    ( catch(inferential_strength:operation_path_power_for_vocabulary(Op, 1, 8, 3, Power), _, fail)
    -> term_text(Power, PathText)
    ;  PathText = "no supported carving-machine model"
    ),
    term_text(Op, OpText).

containment_rows(Limit, Rows) :-
    containment_targets(Targets0), take_limit(Limit, Targets0, Targets),
    findall(Row, ( member(From, Targets), member(To, Targets), From \== To, containment_row(From, To, Row) ), Rows).

containment_targets(Targets) :-
    findall(strategy(Op, Kind), lesson_monitoring:lesson_strategy(_, Op, Kind, _), Strategies),
    findall(Name, lesson_monitoring:lesson_misconception(_, _, Name, _), Names),
    append(Strategies, Names, Raw), sort(Raw, Targets).

containment_row(From, To, _{from:FromText, to:ToText, entails:Entails, witness:WitnessText}) :-
    ( incompatibility_sets:incompatibility_entailment_witness(From, To, Witness)
    -> Entails = true, term_text(Witness, WitnessText)
    ;  Entails = false, WitnessText = "no finite containment witness"
    ),
    term_text(From, FromText), term_text(To, ToText).

write_carving_markdown(Out, Lessons, Operations, Containments) :-
    length(Lessons, LessonCount), length(Operations, OperationCount), length(Containments, ContainmentCount),
    format(Out, "# Predicate carving batch results~n~n", []),
    format(Out, "Computed ~w lesson reports, ~w operation rows, and ~w ordered containment verdicts. `predicate-carving.json` holds the complete finite records for this run. A missing carving model is reported as such; it is not a failed automaton execution.\n", [LessonCount, OperationCount, ContainmentCount]).

% The graph is deliberately a record of the available relations, not a learner
% model.  A bounded run selects whole IM units, so --limit 2 is useful locally.
run_learner_paths :-
    output_dir(Dir), limit(Limit),
    selected_lessons(Limit, Units, Lessons),
    maplist(unit_record, Units, UnitRecords),
    lesson_nodes(Lessons, LessonNodes),
    action_strategy_nodes(ActionNodes),
    analyzer_strategy_nodes(AnalyzerNodes),
    crosswalk_nodes(CrosswalkNodes),
    append([LessonNodes, ActionNodes, AnalyzerNodes, CrosswalkNodes], Nodes0),
    sort(Nodes0, Nodes),
    lesson_sequence_edges(Lessons, SequenceEdges),
    lesson_strategy_edges(Lessons, MappingEdges),
    elaboration_edges(ElaborationEdges),
    crosswalk_edges(CrosswalkEdges),
    append([SequenceEdges, MappingEdges, ElaborationEdges, CrosswalkEdges], Edges0),
    sort(Edges0, Edges),
    graph_counts(Lessons, SequenceEdges, MappingEdges, ElaborationEdges,
                 CrosswalkEdges, Counts),
    directory_file_path(Dir, 'learner_paths.json', Json),
    write_json(Json, _{scenario:"learner_paths",
                       scope:"recorded curriculum and strategy relations; no learner simulation or path scoring",
                       limit_units:Limit, selected_units:UnitRecords,
                       prerequisite_edges:0,
                       prerequisite_note:"No explicit IM lesson-prerequisite predicate was found; none were inferred.",
                       counts:Counts, nodes:Nodes, edges:Edges}),
    directory_file_path(Dir, 'learner_paths.md', Markdown),
    setup_call_cleanup(open(Markdown, write, Out, [encoding(utf8)]),
                       write_learner_paths_markdown(Out, Units, Lessons, Counts),
                       close(Out)).

selected_lessons(Limit, Units, Lessons) :-
    findall(lesson(Code, Grade, Unit, LessonNo, Title),
            ( lesson_monitoring:im_lesson(Code, _, Title, grade(Grade), unit(Unit), lesson(LessonNo)) ),
            All0),
    sort(All0, All),
    findall(unit(Grade, Unit), member(lesson(_, Grade, Unit, _, _), All), Units0),
    sort(Units0, AllUnits), take_limit(Limit, AllUnits, Units),
    include(in_selected_units(Units), All, Lessons).

in_selected_units(Units, lesson(_, Grade, Unit, _, _)) :- memberchk(unit(Grade, Unit), Units).

unit_record(unit(Grade, Unit), _{grade:Grade, unit:Unit}).

lesson_nodes(Lessons, Nodes) :- maplist(lesson_node, Lessons, Nodes).
lesson_node(lesson(Code, Grade, Unit, LessonNo, Title),
            _{id:Id, type:"lesson", code:CodeText, grade:Grade, unit:Unit,
              lesson_number:LessonNo, title:Title}) :-
    node_id(lesson(Code), Id), atom_string(Code, CodeText).

action_strategy_nodes(Nodes) :-
    findall(_{id:Id, type:"registered_action_strategy", operation:OperationText,
              kind:KindText, input_schema:InputText, output_schema:OutputText},
            ( action_automata_registry:action_automaton_signature(Operation, Kind, Input, Output),
              node_id(action_strategy(Operation, Kind), Id),
              term_text(Operation, OperationText), term_text(Kind, KindText),
              term_text(Input, InputText), term_text(Output, OutputText) ),
            Nodes0), sort(Nodes0, Nodes).

analyzer_strategy_nodes(Nodes) :-
    automaton_analyzer:analyze_all,
    findall(_{id:Id, type:"analyzer_strategy", name:NameText, operation:OperationText,
              module:ModuleText, source_path:PathText},
            ( automaton_analyzer:strategy_registry(Name, Operation, Module, Path),
              node_id(analyzer_strategy(Name), Id), term_text(Name, NameText),
              term_text(Operation, OperationText), term_text(Module, ModuleText), term_text(Path, PathText) ),
            Nodes0), sort(Nodes0, Nodes).

crosswalk_nodes(Nodes) :-
    findall(Node,
            ( cw_edges:edge(Family, Module, Predicate, _Args, _Outputs, _Archetype),
              crosswalk_edge_nodes(Family, Module, Predicate, Node) ),
            Nodes0), sort(Nodes0, Nodes).

crosswalk_edge_nodes(Family, _Module, _Predicate,
                     _{id:Id, type:"crosswalk_family", family:FamilyText}) :-
    node_id(crosswalk_family(Family), Id), term_text(Family, FamilyText).
crosswalk_edge_nodes(_Family, Module, Predicate,
                     _{id:Id, type:"crosswalk_predicate", module:ModuleText, predicate:PredicateText}) :-
    node_id(crosswalk_predicate(Module, Predicate), Id),
    term_text(Module, ModuleText), term_text(Predicate, PredicateText).

lesson_sequence_edges(Lessons, Edges) :-
    findall(Edge,
            ( select(lesson(From, Grade, Unit, LessonNo, _), Lessons, Rest),
              Next is LessonNo + 1,
              member(lesson(To, Grade, Unit, Next, _), Rest),
              node_id(lesson(From), FromId), node_id(lesson(To), ToId),
              Edge = _{from:FromId, to:ToId, type:"lesson_sequence",
                       provenance:"lesson_monitoring:im_lesson/6"} ),
            Edges0), sort(Edges0, Edges).

lesson_strategy_edges(Lessons, Edges) :-
    findall(Edge,
            ( member(lesson(Code, _, _, _, _), Lessons),
              lesson_monitoring:lesson_strategy(Code, Operation, Kind, _Info),
              action_automata_registry:action_automaton_signature(Operation, Kind, _, _),
              node_id(lesson(Code), FromId), node_id(action_strategy(Operation, Kind), ToId),
              Edge = _{from:FromId, to:ToId, type:"lesson_strategy_mapping",
                       provenance:"lesson_monitoring:lesson_strategy/4"} ),
            Edges0), sort(Edges0, Edges).

elaboration_edges(Edges) :-
    findall(Edge,
            ( automaton_analyzer:elaborates(Base, Elaborated, Shared, Type, CMax, CJac, Asymmetry),
              node_id(analyzer_strategy(Base), FromId), node_id(analyzer_strategy(Elaborated), ToId),
              term_text(Shared, SharedText), term_text(Type, TypeText),
              Edge = _{from:FromId, to:ToId, type:"strategy_elaboration",
                       relation:TypeText, shared_patterns:SharedText,
                       confidence_max:CMax, confidence_jaccard:CJac,
                       direction_asymmetry:Asymmetry,
                       provenance:"automaton_analyzer:elaborates/7"} ),
            Edges0), sort(Edges0, Edges).

crosswalk_edges(Edges) :-
    findall(Edge,
            ( cw_edges:edge(Family, Module, Predicate, Args, Outputs, Archetype),
              node_id(crosswalk_family(Family), FromId),
              node_id(crosswalk_predicate(Module, Predicate), ToId),
              term_text(Args, ArgsText), term_text(Outputs, OutputsText), term_text(Archetype, ArchetypeText),
              Edge = _{from:FromId, to:ToId, type:"crosswalk_family_edge",
                       arguments:ArgsText, outputs:OutputsText, archetype:ArchetypeText,
                       provenance:"cw_edges:edge/6"} ),
            Edges0), sort(Edges0, Edges).

node_id(Term, Id) :- term_text(Term, Id).

graph_counts(Lessons, SequenceEdges, MappingEdges, ElaborationEdges, CrosswalkEdges,
             _{lessons:LessonCount, lesson_sequence_edges:SequenceCount,
               lesson_strategy_edges:MappingCount, strategy_elaboration_edges:ElaborationCount,
               crosswalk_family_edges:CrosswalkCount, prerequisite_edges:0}) :-
    length(Lessons, LessonCount), length(SequenceEdges, SequenceCount),
    length(MappingEdges, MappingCount), length(ElaborationEdges, ElaborationCount),
    length(CrosswalkEdges, CrosswalkCount).

write_learner_paths_markdown(Out, Units, Lessons, Counts) :-
    format(Out, "# Learner-path graph\n\n", []),
    format(Out, "This artifact records existing curriculum and strategy relations. It does not simulate a learner or score a path.\n\n", []),
    format(Out, "Selected units: `~w`. Lesson nodes: ~w. Sequence edges: ~w. Lesson-strategy mappings: ~w. Strategy elaborations: ~w. Crosswalk family edges: ~w.\n\n",
           [Units, Counts.lessons, Counts.lesson_sequence_edges, Counts.lesson_strategy_edges,
            Counts.strategy_elaboration_edges, Counts.crosswalk_family_edges]),
    format(Out, "## Per-grade lesson counts\n\n| Grade | Lessons |\n| --- | ---: |\n", []),
    findall(Grade, member(lesson(_, Grade, _, _, _), Lessons), Grades0), sort(Grades0, Grades),
    forall(member(Grade, Grades),
           ( aggregate_all(count, member(lesson(_, Grade, _, _, _), Lessons), Count),
             format(Out, "| ~w | ~w |\n", [Grade, Count]) )),
    format(Out, "\nNo explicit IM lesson-prerequisite predicate was found, so this graph contains no prerequisite edges.\n", []).
