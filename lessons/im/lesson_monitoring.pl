/** <module> Monitoring charts for encoded Illustrative Mathematics lessons */
:- module(lesson_monitoring,
          [ monitoring_chart/2,
            monitoring_chart_export/2,
            licensed_but_unanticipated/2,
            monitoring_chart_cluster/4,
            encoded_lesson/6,
            encoded_im_lesson/6,
            im_lesson/6,
            traditional_lesson/6,
            lesson_standard/4,
            explicit_lesson_standard/4,
            lesson_strategy/4,
            lesson_misconception/4,
            vision_lesson_strategy/4,
            cluster_lesson_strategy/4,
            cluster_lesson_misconception/4,
            enact_lesson_misconception/3
          ]).

:- use_module(library(http/json)).
:- use_module(library(readutil)).
:- absolute_file_name(geometry(schema),
                      GeometrySchema,
                      [file_type(prolog), access(read)]),
   (   source_file(GeometrySchema)
   ->  true
   ;   ensure_loaded(GeometrySchema)
   ).
:- absolute_file_name(geometry(query),
                      GeometryQuery,
                      [file_type(prolog), access(read)]),
   (   source_file(GeometryQuery)
   ->  true
   ;   ensure_loaded(GeometryQuery)
   ).

:- use_module(math(action_automata_registry),
              [ action_automaton_cluster/3,
                action_automaton_pair/4,
                action_automaton_vocabulary/3
              ]).
:- use_module('generated/compiled_action_mappings',
              [compiled_lesson_strategy/4]).
:- use_module(arche_trace(incompatibility_discovery),
              [ classify_candidate_set/3
              ]).
:- use_module(misconceptions(misconception_registry),
              [ misconception_registry_entry/5,
                incompatibility_with_witness/3
              ]).
:- use_module(misconceptions(misconception_scorekeeping),
              [ enact_misconception/2
              ]).
:- use_module(pml(text_interpreter),
              [ interpret_lesson_text/2
              ]).
:- use_module(standards(indiana/standard_1_ca_1), []).

:- multifile explicit_lesson_strategy/4, explicit_lesson_misconception/4, explicit_lesson_standard/4.
:- multifile traditional_lesson/6, scope_sequence_only_lesson/1.
:- multifile scope_sequence_mapped_lesson/1.
% vision_lesson_strategy/4: vision-attested execution demands (generated
% grade_*_vision.pl). Deliberately outside the lesson_strategy/monitoring-chart
% join — activity_contract builds vision_attested obligations from it — so
% cluster-derived charts and their citations stay intact.
:- multifile vision_lesson_strategy/4.
:- discontiguous vision_lesson_strategy/4.
:- discontiguous explicit_lesson_strategy/4, explicit_lesson_misconception/4, explicit_lesson_standard/4.
:- discontiguous traditional_lesson/6, scope_sequence_only_lesson/1.
:- discontiguous scope_sequence_mapped_lesson/1.
:- dynamic cached_lesson_topics/2.
% Dynamic so tests can assert a fixture lesson under setup/cleanup (the
% lesson_task_instance/3 pattern in learner/activity_contract.pl).
:- dynamic explicit_lesson_strategy/4.

:- ensure_loaded(grade_k).
:- ensure_loaded(grade_1).
:- ensure_loaded(grade_2).
:- ensure_loaded(grade_3).
:- ensure_loaded(grade_4).
:- ensure_loaded(grade_5).
:- ensure_loaded(grade_6).
:- ensure_loaded(grade_6_vision).
:- ensure_loaded(grade_7).
:- ensure_loaded(grade_7_vision).
:- ensure_loaded(grade_8).
:- ensure_loaded(lessons('traditional/rays_new_practical')).
% Reason-tagged residue of the grade 6-7 arithmetic units (Phase 5 boundary
% closure): every scope_sequence_only lesson in G6-U4, G6-U5, G7-U5 that the
% explicit mappings leave unmapped carries exactly one grind_boundary/2 reason.
:- ensure_loaded(grind_boundary).


%!  monitoring_chart(+LessonCode, -Chart) is semidet.
monitoring_chart(Code, monitoring_chart(Code, Lesson, Standards, Strategies, Misconceptions, PMLFacts)) :-
    encoded_lesson(Code, ConceptId, Title, Grade, Unit, LessonNumber),
    Lesson = lesson(ConceptId, Title, Grade, Unit, LessonNumber),
    findall(standard(Framework, StandardCode, Statement),
            lesson_monitoring:lesson_standard(Code, Framework, StandardCode, Statement),
            Standards0),
    sort(Standards0, Standards),
    findall(strategy(Operation, Kind, Info),
            lesson_monitoring:lesson_strategy(Code, Operation, Kind, Info),
            Strategies0),
    sort(Strategies0, Strategies),
    findall(misconception(Operation, Name, Info),
            lesson_monitoring:lesson_misconception(Code, Operation, Name, Info),
            Misconceptions0),
    sort(Misconceptions0, Misconceptions),
    lesson_pml_facts(Code, PMLFacts).


%!  monitoring_chart_export(+LessonCode, -Export) is semidet.
%
%   Teacher-facing chart bundle for a lesson. The first six fields preserve
%   the executable lesson chart; the final field adds DB-derived cluster rows
%   from the generated monitoring-chart cluster maps.
monitoring_chart_export(Code,
                        monitoring_chart_export(Code,
                                                Lesson,
                                                Standards,
                                                Strategies,
                                                Misconceptions,
                                                PMLFacts,
                                                Clusters)) :-
    monitoring_chart(Code, monitoring_chart(Code,
                                            Lesson,
                                            Standards,
                                            Strategies,
                                            Misconceptions,
                                            PMLFacts)),
    findall(chart_cluster(Source, ClusterId, Info),
            monitoring_chart_cluster(Code, Source, ClusterId, Info),
            Clusters).


%!  licensed_but_unanticipated(+LessonCode, -OperationGaps) is det.
%
%   The monitoring chart records the strategies a lesson anticipates. The
%   action-automata registry records, per operation, the action kinds the
%   practice licenses (productive strategies together with their deformations),
%   independent of any one lesson. For each operation this lesson anticipates at
%   least one strategy in, this predicate returns the licensed kinds the chart
%   does not anticipate: the registry's licensed set minus the lesson's
%   anticipated set. The gap is computed from records already present; it marks
%   where the anticipation runs out, not a defect to close.
%
%   Each element is
%   operation_gap(Operation, LicensedCount, AnticipatedCount, Unanticipated),
%   where Unanticipated is the sorted list of licensed-but-unanticipated kinds.
%   Operations with no registry licensed-move source (e.g. geometry, whose
%   lesson "strategies" are concept ids, not action kinds) produce no row, so
%   the field is never a stand-in for an absent source.
licensed_but_unanticipated(Code, OperationGaps) :-
    (   setof(Operation, anticipated_registry_operation(Code, Operation), Operations)
    ->  findall(operation_gap(Operation, LicensedCount, AnticipatedCount, Unanticipated),
                ( member(Operation, Operations),
                  operation_licensed_unanticipated(Code, Operation,
                                                   LicensedCount, AnticipatedCount,
                                                   Unanticipated)
                ),
                OperationGaps)
    ;   OperationGaps = []
    ).

anticipated_registry_operation(Code, Operation) :-
    lesson_monitoring:lesson_strategy(Code, Operation, _Kind, _Info),
    licensed_action_kinds(Operation, _Licensed).

operation_licensed_unanticipated(Code, Operation,
                                 LicensedCount, AnticipatedCount, Unanticipated) :-
    licensed_action_kinds(Operation, Licensed),
    findall(Kind,
            lesson_monitoring:lesson_strategy(Code, Operation, Kind, _Info),
            Anticipated0),
    sort(Anticipated0, Anticipated),
    subtract(Licensed, Anticipated, Unanticipated),
    length(Licensed, LicensedCount),
    length(Anticipated, AnticipatedCount).

licensed_action_kinds(Operation, Licensed) :-
    setof(Kind,
          Cluster^action_automaton_cluster(Operation, Kind, Cluster),
          Licensed).


%!  monitoring_chart_cluster(+LessonCode, -Source, -ClusterId, -Info) is nondet.
%
%   Link a lesson to generated monitoring-chart clusters through the IM unit
%   anchor. Cluster files are derived from research_corpus/research.db and
%   already contain the productive core, deformation, questions, standards,
%   IM anchors, and evidence samples.
monitoring_chart_cluster(Code, Source, ClusterId, Info) :-
    lesson_unit_anchor(Code, UnitAnchor),
    monitoring_cluster_source(Source, RelativePath),
    monitoring_cluster_dict(RelativePath, Cluster),
    dict_value(Cluster, im_anchors, Anchors),
    cluster_anchor_matches(Code, UnitAnchor, Anchors),
    dict_value(Cluster, id, ClusterId),
    cluster_matches_lesson_topic(Code, Source, ClusterId),
    cluster_info(Cluster, Info).


%!  im_lesson(+Code, -ConceptId, -Title, -Grade, -Unit, -LessonNumber) is semidet.
im_lesson(Code, ConceptId, Title, Grade, Unit, LessonNumber) :-
    encoded_im_lesson(Code, ConceptId, Title, Grade, Unit, LessonNumber).


%!  encoded_lesson(?Code, ?ConceptId, ?Title, ?Grade, ?Unit, ?LessonNumber) is nondet.
%
%   Unified lesson anchor surface for IM and cited traditional comparison
%   lessons. Existing IM callers can keep using im_lesson/6; comparison/report
%   code can ask for any encoded lesson.
encoded_lesson(Code, ConceptId, Title, Grade, Unit, LessonNumber) :-
    encoded_im_lesson(Code, ConceptId, Title, Grade, Unit, LessonNumber).
encoded_lesson(Code, ConceptId, Title, Grade, Unit, LessonNumber) :-
    traditional_lesson(Code, ConceptId, Title, Grade, Unit, LessonNumber).


%!  encoded_im_lesson(?Code, ?ConceptId, ?Title, ?Grade, ?Unit, ?LessonNumber) is nondet.
%
%   Lesson-level IM anchors currently come from standards/im/lesson_anchors.pl
%   for K-5 and from geometry/corpus/im_scope_and_sequence for grades 6-8.
%   Grades 6-8 use the existing unit-level IM anchors for standards.
encoded_im_lesson(Code, ConceptId, Title, grade(Grade), unit(Unit), lesson(LessonNumber)) :-
    loaded_standard_anchor(ConceptId, im_lesson, CodeString, _Statement),
    atom_string(Code, CodeString),
    im_lesson_code_parts(Code, Grade, Unit, LessonNumber),
    loaded_geom_concept(ConceptId, Title, developmental, _Bands).
encoded_im_lesson(Code, ConceptId, Title, grade(Grade), unit(Unit), lesson(LessonNumber)) :-
    scope_sequence_im_lesson(Code, ConceptId, Title, Grade, Unit, LessonNumber).


%!  lesson_standard(?LessonCode, ?Framework, ?StandardCode, ?Statement) is nondet.
%
%   Public standard surface. Source data may carry duplicate lesson anchors
%   across generated scope-sequence rows and explicit facts; callers should not
%   have to know which underlying source is safe to enumerate.
lesson_standard(Code, Framework, StandardCode, Statement) :-
    distinct(Code-Framework-StandardCode-Statement,
             lesson_standard_source(Code, Framework, StandardCode, Statement)).

lesson_standard_source(Code, Framework, StandardCode, Statement) :-
    explicit_lesson_standard(Code, Framework, StandardCode, Statement).
lesson_standard_source(Code, im_lesson, Code, Statement) :-
    im_lesson(Code, ConceptId, _, _, _, _),
    atom_string(Code, CodeString),
    loaded_standard_anchor(ConceptId, im_lesson, CodeString, Statement).
lesson_standard_source(Code, im_lesson, UnitAnchor, Statement) :-
    im_lesson(Code, ConceptId, _, _, _, _),
    lesson_unit_anchor(Code, UnitAnchor),
    UnitAnchor \== Code,
    atom_string(UnitAnchor, UnitAnchorString),
    loaded_standard_anchor(ConceptId, im_lesson, UnitAnchorString, Statement).
lesson_standard_source(Code, Framework, StandardCode, Statement) :-
    im_lesson(Code, ConceptId, _, _, _, _),
    Framework \== im_lesson,
    loaded_standard_anchor(ConceptId, Framework, StandardCode, Statement).

lesson_standard_source('IM-G1-U3-L17',
                ccss,
                '1.OA.B.3',
                "Apply properties of operations as strategies to add and subtract.").
lesson_standard_source('IM-G1-U3-L17',
                ccss,
                '1.OA.C.6',
                "Add and subtract within 20, demonstrating fluency for addition and subtraction within 10.").
lesson_standard_source('IM-G1-U3-L17',
                in_indiana,
                '1.CA.1',
                "Demonstrate fluency with addition facts and corresponding subtraction facts within 20 using strategies such as counting on, making ten, and decomposing to ten.").


lesson_has_explicit_attachments(Code) :-
    ( explicit_lesson_strategy(Code, _, _, _)
    ; explicit_lesson_misconception(Code, _, _, _)
      ).

lesson_has_compiled_attachments(Code) :-
    compiled_lesson_strategy(Code, _, _, _).

lesson_has_specific_attachments(Code) :-
    ( lesson_has_explicit_attachments(Code)
    ; lesson_has_compiled_attachments(Code)
    ).

%!  lesson_strategy(+LessonCode, -Operation, -Kind, -Info) is nondet.
lesson_strategy(Code, Operation, Kind, Info) :-
    findall(Operation0-Kind0,
            lesson_monitoring:lesson_strategy_candidate(Code, Operation0, Kind0, _Info0),
            Keys0),
    sort(Keys0, Keys),
    member(Operation-Kind, Keys),
    preferred_lesson_strategy_candidate(Code, Operation, Kind, Info).

lesson_strategy_candidate(Code, Operation, Kind, Info) :-
    lesson_monitoring:explicit_lesson_strategy(Code, Operation, Kind, Info0),
    add_provenance(text_evidenced, Info0, Info).
lesson_strategy_candidate(Code, Operation, Kind, Info) :-
    compiled_lesson_strategy(Code, Operation, Kind, Evidence),
    \+ lesson_monitoring:explicit_lesson_strategy(Code, Operation, Kind, _),
    strategy_info(Operation, Kind, Info0),
    add_provenance(compiled_text_evidence,
                   [source(Evidence), confidence(high)|Info0],
                   Info).
lesson_strategy_candidate(Code, Operation, Kind, Info) :-
    \+ lesson_has_specific_attachments(Code),
    lesson_monitoring:cluster_lesson_strategy_candidate(Code, Operation, Kind, Info).
lesson_strategy_candidate(Code, geometry, ConceptId, Info) :-
    geometry_concept_fallback_allowed(Code),
    lesson_monitoring:cluster_lesson_geometry_strategy(Code, ConceptId, Info).


explicit_lesson_strategy('IM-G1-U3-L17', addition, make_ten_split_leftover, Info) :-
    strategy_info(addition, make_ten_split_leftover, Info).
explicit_lesson_strategy('IM-G1-U3-L17', addition, count_on_from_larger, Info) :-
    strategy_info(addition, count_on_from_larger, Info).
explicit_lesson_strategy('IM-G2-U1-L3', subtraction, count_up_missing_addend, Info) :-
    strategy_info(subtraction, count_up_missing_addend, Info).


%!  lesson_misconception(+LessonCode, -Operation, -Name, -Info) is nondet.
lesson_misconception(Code, Operation, Name, Info) :-
    findall(Operation0-Name0,
            lesson_monitoring:lesson_misconception_candidate(Code, Operation0, Name0, _Info0),
            Keys0),
    sort(Keys0, Keys),
    member(Operation-Name, Keys),
    preferred_lesson_misconception_candidate(Code, Operation, Name, Info).

preferred_lesson_strategy_candidate(Code, Operation, Kind, Info) :-
    findall(Info0,
            lesson_monitoring:lesson_strategy_candidate(Code, Operation, Kind, Info0),
            Infos),
    preferred_info(Code, Infos, Info).

preferred_lesson_misconception_candidate(Code, Operation, Name, Info) :-
    findall(Info0,
            lesson_monitoring:lesson_misconception_candidate(Code, Operation, Name, Info0),
            Infos),
    preferred_info(Code, Infos, Info).

preferred_info([Info], Info) :-
    !.
preferred_info(Infos, Info) :-
    preferred_info(_, Infos, Info).

preferred_info(_Code, [Info], Info) :-
    !.
preferred_info(Code, Infos, Info) :-
    findall(Priority-TieIndex-Info0,
            ( nth1(Index, Infos, Info0),
              info_sort_key(Code, Info0, Index, Priority, TieIndex)
            ),
            Pairs0),
    keysort(Pairs0, [_BestPriority-_BestIndex-Info|_]).

info_sort_key(Code, Info, Index, Priority, TieIndex) :-
    member(source(cluster(Source, _ClusterId)), Info),
    !,
    source_priority(Code, Source, Info, Priority),
    source_tie_index(Source, Index, TieIndex).
info_sort_key(_Code, _Info, Index, 100, Index).

source_priority(Code, geometry, Info, -10) :-
    nonvar(Code),
    member(source(cluster(geometry, ClusterId)), Info),
    preferred_geometry_cluster(Code, ClusterId),
    !.
source_priority(_Code, fraction, _Info, 0) :- !.
source_priority(_Code, geometry, _Info, 0) :- !.
source_priority(_Code, k8_operations, _Info, 20) :- !.
source_priority(_Code, _Source, _Info, 10).

source_tie_index(geometry, Index, TieIndex) :-
    !,
    TieIndex is -Index.
source_tie_index(_Source, Index, Index).

preferred_geometry_cluster(Code, ClusterId) :-
    lesson_unit_anchor(Code, UnitAnchor),
    preferred_geometry_unit_cluster(UnitAnchor, ClusterId).

preferred_geometry_unit_cluster('IM-G2-U8', compose_decompose_shapes).
preferred_geometry_unit_cluster('IM-G3-U2', area_tiling_unit_iteration).
preferred_geometry_unit_cluster('IM-G3-U5', equal_shares_fraction_geometry).
preferred_geometry_unit_cluster('IM-G7-U1', scale_drawings_geometric_proportionality).


add_provenance(_Provenance, Info, Info) :-
    memberchk(provenance(_), Info),
    !.
add_provenance(Provenance, Info, [provenance(Provenance)|Info]).


cluster_fallback_allowed(Code, Operation, _Source, _ClusterId) :-
    nonvar(Code),
    \+ lesson_has_specific_attachments(Code),
    operation_matches_lesson_topic(Code, Operation).

misconception_cluster_fallback_allowed(Code, Operation, _Source, _ClusterId) :-
    nonvar(Code),
    (   \+ lesson_has_specific_attachments(Code)
    ;   \+ lesson_has_explicit_attachments(Code),
        compiled_lesson_strategy(Code, Operation, Kind, _),
        action_automaton_cluster(Operation, Kind, RegistryClusterId),
        monitoring_chart_cluster(Code, Source, ClusterId, _),
        chart_registry_cluster(Source, ClusterId, RegistryClusterId)
    ),
    operation_matches_lesson_topic(Code, Operation).

% Compiled actions augment the richer geometry-concept bundle. Only a
% hand-reviewed explicit geometry attachment suppresses this fallback.
geometry_concept_fallback_allowed(Code) :-
    nonvar(Code),
    operation_matches_lesson_topic(Code, geometry),
    \+ explicit_attachment_operation(Code, geometry).


operation_matches_lesson_topic(Code, Operation) :-
    lesson_topic(Code, Topic),
    operation_topic(Operation, Topic),
    !.


lesson_topic(Code, Topic) :-
    lesson_topics(Code, Topics),
    member(Topic, Topics).


lesson_topics(Code, Topics) :-
    nonvar(Code),
    cached_lesson_topics(Code, Topics),
    !.
lesson_topics(Code, Topics) :-
    findall(Topic, lesson_primary_topic_evidence(Code, Topic), Primary0),
    sort(Primary0, Primary),
    (   Primary \== []
    ->  Topics = Primary
    ;   findall(Topic, lesson_secondary_standard_topic_evidence(Code, Topic), Secondary0),
        sort(Secondary0, Secondary),
        (   Secondary \== []
        ->  Topics = Secondary
        ;   findall(Topic, lesson_concept_topic_evidence(Code, Topic), Topics0),
            sort(Topics0, Topics)
        )
    ),
    (   nonvar(Code)
    ->  assertz(cached_lesson_topics(Code, Topics))
    ;   true
    ).


lesson_primary_topic_evidence(Code, Topic) :-
    im_lesson(Code, ConceptId, Title, _, _, _),
    (   topic_from_text(Title, Topic)
    ;   lesson_specific_im_lesson_text(Code, ConceptId, Statement),
        topic_from_text(Statement, Topic)
    ).


lesson_secondary_standard_topic_evidence(Code, Topic) :-
    im_lesson(Code, ConceptId, _Title, _, _, _),
    loaded_standard_anchor(ConceptId, Framework, _StandardCode, Statement),
    Framework \== im_lesson,
    topic_from_text(Statement, Topic).


lesson_concept_topic_evidence(Code, Topic) :-
    im_lesson(Code, ConceptId, _Title, _, _, _),
    topic_from_text(ConceptId, Topic).


lesson_specific_im_lesson_text(Code, ConceptId, Statement) :-
    loaded_standard_anchor(ConceptId, im_lesson, StandardCode, Statement),
    standard_code_matches_lesson(Code, StandardCode).


standard_code_matches_lesson(Code, StandardCode) :-
    atom_string(Code, CodeString),
    (   StandardCode == Code
    ;   StandardCode == CodeString
    ).


operation_topic(geometry, geometry).
operation_topic(probability, probability).
operation_topic(ratio, ratio).
operation_topic(ratio, proportional).
operation_topic(fraction, fraction).
operation_topic(decimal, decimal).
operation_topic(integer, integer).
operation_topic(algebraic, algebraic).
operation_topic(order_of_operations, algebraic).
operation_topic(addition, addition).
operation_topic(subtraction, subtraction).
operation_topic(multiplication, multiplication).
operation_topic(division, division).
operation_topic(diagnostic, counting).
operation_topic(diagnostic, cardinality).
operation_topic(calculus, calculus).


topic_from_text(Text, Topic) :-
    text_lower_atom(Text, Lower),
    text_topic(Lower, Topic).


text_topic(Text, data) :-
    ( sub_atom(Text, _, _, _, data)
    ; sub_atom(Text, _, _, _, graph)
    ; sub_atom(Text, _, _, _, histogram)
    ; sub_atom(Text, _, _, _, "dot plot")
    ; sub_atom(Text, _, _, _, "box plot")
    ; sub_atom(Text, _, _, _, statistical)
    ).
text_topic(Text, probability) :-
    ( sub_atom(Text, _, _, _, probability)
    ; sub_atom(Text, _, _, _, chance)
    ; sub_atom(Text, _, _, _, likelihood)
    ).
text_topic(Text, geometry) :-
    ( sub_atom(Text, _, _, _, geometry)
    ; sub_atom(Text, _, _, _, shape)
    ; sub_atom(Text, _, _, _, polygon)
    ; sub_atom(Text, _, _, _, triangle)
    ; sub_atom(Text, _, _, _, square)
    ; sub_atom(Text, _, _, _, area)
    ; sub_atom(Text, _, _, _, perimeter)
    ; sub_atom(Text, _, _, _, plane)
    ; sub_atom(Text, _, _, _, coordinate)
    ; sub_atom(Text, _, _, _, grid)
    ; sub_atom(Text, _, _, _, transformation)
    ; sub_atom(Text, _, _, _, rotation)
    ; sub_atom(Text, _, _, _, reflection)
    ; sub_atom(Text, _, _, _, translation)
    ; sub_atom(Text, _, _, _, volume)
    ; sub_atom(Text, _, _, _, surface)
    ; sub_atom(Text, _, _, _, prism)
    ; sub_atom(Text, _, _, _, cube)
    ; sub_atom(Text, _, _, _, tiling)
    ).
text_topic(Text, ratio) :-
    ( sub_atom(Text, _, _, _, " ratio")
    ; sub_atom(Text, _, _, _, ratios)
    ; sub_atom(Text, _, _, _, rate)
    ; sub_atom(Text, _, _, _, percent)
    ).
text_topic(Text, proportional) :-
    ( sub_atom(Text, _, _, _, proportion)
    ; sub_atom(Text, _, _, _, "scale drawing")
    ; sub_atom(Text, _, _, _, "scale factor")
    ; sub_atom(Text, _, _, _, "scaled drawing")
    ; sub_atom(Text, _, _, _, similar)
    ).
text_topic(Text, fraction) :-
    ( sub_atom(Text, _, _, _, fraction)
    ; sub_atom(Text, _, _, _, numerator)
    ; sub_atom(Text, _, _, _, denominator)
    ).
text_topic(Text, decimal) :-
    sub_atom(Text, _, _, _, decimal).
text_topic(Text, algebraic) :-
    ( sub_atom(Text, _, _, _, equation)
    ; sub_atom(Text, _, _, _, expression)
    ; sub_atom(Text, _, _, _, variable)
    ; sub_atom(Text, _, _, _, algebra)
    ; sub_atom(Text, _, _, _, distributive)
    ; sub_atom(Text, _, _, _, input)
    ; sub_atom(Text, _, _, _, output)
    ; sub_atom(Text, _, _, _, function)
    ).
text_topic(Text, integer) :-
    ( sub_atom(Text, _, _, _, integer)
    ; sub_atom(Text, _, _, _, negative)
    ; sub_atom(Text, _, _, _, signed)
    ).
text_topic(Text, counting) :-
    ( sub_atom(Text, _, _, _, count)
    ; sub_atom(Text, _, _, _, counting)
    ).
text_topic(Text, cardinality) :-
    sub_atom(Text, _, _, _, cardinality).
text_topic(Text, addition) :-
    ( sub_atom(Text, _, _, _, add)
    ; sub_atom(Text, _, _, _, sum)
    ; sub_atom(Text, _, _, _, total)
    ).
text_topic(Text, subtraction) :-
    ( sub_atom(Text, _, _, _, subtract)
    ; sub_atom(Text, _, _, _, difference)
    ; sub_atom(Text, _, _, _, "how many more")
    ; sub_atom(Text, _, _, _, "how many less")
    ).
text_topic(Text, multiplication) :-
    ( sub_atom(Text, _, _, _, multiply)
    ; sub_atom(Text, _, _, _, multiplication)
    ; sub_atom(Text, _, _, _, multiplicative)
    ; sub_atom(Text, _, _, _, product)
    ; sub_atom(Text, _, _, _, factor)
    ; sub_atom(Text, _, _, _, array)
    ; sub_atom(Text, _, _, _, "times as many")
    ; sub_atom(Text, _, _, _, "equal group")
    ).
text_topic(Text, division) :-
    ( sub_atom(Text, _, _, _, divide)
    ; sub_atom(Text, _, _, _, division)
    ; sub_atom(Text, _, _, _, divisor)
    ; sub_atom(Text, _, _, _, quotient)
    ; sub_atom(Text, _, _, _, share)
    ; sub_atom(Text, _, _, _, "left over")
    ).


text_lower_atom(Value, Lower) :-
    text_string(Value, Text),
    string_lower(Text, LowerString),
    atom_string(Lower, LowerString).

lesson_misconception_candidate(Code, Operation, Name, Info) :-
    lesson_monitoring:explicit_lesson_misconception(Code, Operation, Name, Info0),
    add_provenance(text_evidenced, Info0, Info).
lesson_misconception_candidate(Code, Operation, Name, Info) :-
    lesson_monitoring:cluster_lesson_misconception_candidate(Code, Operation, Name, Info).
lesson_misconception_candidate(Code, geometry, Name, Info) :-
    geometry_concept_fallback_allowed(Code),
    lesson_monitoring:cluster_lesson_geometry_misconception(Code, Name, Info).


explicit_lesson_misconception('IM-G1-U3-L17', Operation, count_all_when_count_on_available, Info) :-
    misconception_registry_entry(count_all_when_count_on_available,
                                 Operation,
                                 Citation,
                                 Commitment,
                                 EntitlementLacked),
    misconception_info(count_all_when_count_on_available,
                       Citation,
                       Commitment,
                       EntitlementLacked,
                       [],
                       Info).
explicit_lesson_misconception('IM-G2-U1-L3', Operation, missing_addend_as_plain_sum, Info) :-
    misconception_registry_entry(missing_addend_as_plain_sum,
                                 Operation,
                                 Citation,
                                 Commitment,
                                 EntitlementLacked),
    misconception_info(missing_addend_as_plain_sum,
                       Citation,
                       Commitment,
                       EntitlementLacked,
                       [],
                       Info).


cluster_lesson_strategy(Code, Operation, Kind, Info) :-
    nonvar(Operation),
    nonvar(Kind),
    !,
    findall(Info0,
            lesson_monitoring:cluster_lesson_strategy_candidate(Code, Operation, Kind, Info0),
            Infos),
    Infos \== [],
    preferred_info(Code, Infos, Info).
cluster_lesson_strategy(Code, Operation, Kind, Info) :-
    findall(Operation0-Kind0,
            lesson_monitoring:cluster_lesson_strategy_candidate(Code, Operation0, Kind0, _Info0),
            Keys0),
    sort(Keys0, Keys),
    member(Operation-Kind, Keys),
    findall(Info0,
            lesson_monitoring:cluster_lesson_strategy_candidate(Code, Operation, Kind, Info0),
            Infos),
    preferred_info(Code, Infos, Info).

cluster_lesson_strategy_candidate(Code, Operation, Kind, Info) :-
    cluster_fallback_allowed(Code, Operation, _Source0, _ClusterId0),
    monitoring_chart_cluster(Code, Source, ClusterId, _ClusterInfo),
    chart_registry_cluster(Source, ClusterId, RegistryClusterId),
    action_automaton_cluster(Operation, Kind, RegistryClusterId),
    \+ action_automaton_pair(Operation, _Productive, Kind, _Family),
    strategy_info(Operation, Kind, StrategyInfo),
    add_provenance(unit_cluster_fallback,
                   [source(cluster(Source, ClusterId))|StrategyInfo],
                   Info).


cluster_lesson_misconception(Code, Operation, Name, Info) :-
    nonvar(Operation),
    nonvar(Name),
    !,
    findall(Info0,
            lesson_monitoring:cluster_lesson_misconception_candidate(Code, Operation, Name, Info0),
            Infos),
    Infos \== [],
    preferred_info(Code, Infos, Info).
cluster_lesson_misconception(Code, Operation, Name, Info) :-
    findall(Operation0-Name0,
            lesson_monitoring:cluster_lesson_misconception_candidate(Code, Operation0, Name0, _Info0),
            Keys0),
    sort(Keys0, Keys),
    member(Operation-Name, Keys),
    findall(Info0,
            lesson_monitoring:cluster_lesson_misconception_candidate(Code, Operation, Name, Info0),
            Infos),
    preferred_info(Code, Infos, Info).

cluster_lesson_misconception_candidate(Code, Operation, Name, Info) :-
    misconception_cluster_fallback_allowed(Code, Operation, _Source0, _ClusterId0),
    monitoring_chart_cluster(Code, Source, ClusterId, _ClusterInfo),
    chart_registry_cluster(Source, ClusterId, RegistryClusterId),
    misconception_registry_entry(Name, Operation, Citation, Commitment, EntitlementLacked),
    misconception_matches_cluster(Operation, Name, Commitment, RegistryClusterId),
    misconception_info(Name,
                       Citation,
                       Commitment,
                       EntitlementLacked,
                       [source(cluster(Source, ClusterId))],
                       Info0),
    add_provenance(unit_cluster_fallback, Info0, Info).
cluster_lesson_misconception_candidate(Code, Operation, Name, Info) :-
    misconception_cluster_fallback_allowed(Code, Operation, _Source0, _ClusterId0),
    monitoring_chart_cluster(Code, Source, ClusterId, _ClusterInfo),
    chart_registry_misconception(Source, ClusterId, Name),
    misconception_registry_entry(Name, Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(Name,
                       Citation,
                       Commitment,
                       EntitlementLacked,
                       [source(cluster(Source, ClusterId))],
                       Info0),
    add_provenance(unit_cluster_fallback, Info0, Info).


cluster_lesson_geometry_strategy(Code, ConceptId, Info) :-
    geometry_concept_fallback_allowed(Code),
    monitoring_chart_cluster(Code, geometry, ClusterId, _ClusterInfo),
    geometry_cluster_concept(ClusterId, ConceptId),
    loaded_geometry_monitoring_bundle(
        ConceptId,
        geometry_monitoring_bundle(ConceptId,
                                   Concept,
                                   Related,
                                   Standards,
                                   Misconceptions,
                                   Metaphors,
                                   Markers,
                                   Arcs)
    ),
    add_provenance(unit_cluster_fallback,
                   [ source(cluster(geometry, ClusterId)),
                     Concept,
                     commitment_made(geometry_concept(ConceptId)),
                     entitlement_granted(geometry_concept(ConceptId)),
                     related_concepts(Related),
                     standards(Standards),
                     misconceptions(Misconceptions),
                     metaphors(Metaphors),
                     markers(Markers),
                     arcs(Arcs)
                   ],
                   Info).


cluster_lesson_geometry_misconception(Code, Name, Info) :-
    geometry_concept_fallback_allowed(Code),
    monitoring_chart_cluster(Code, geometry, ClusterId, _ClusterInfo),
    geometry_cluster_concept(ClusterId, ConceptId),
    loaded_geometry_monitoring_bundle(
        ConceptId,
        geometry_monitoring_bundle(ConceptId,
                                   _Concept,
                                   _Related,
                                   _Standards,
                                   Misconceptions,
                                   _Metaphors,
                                   _Markers,
                                   _Arcs)
    ),
    member(misconception(Name, TargetConcept, Title, _MatchedTrigger, Repair, Tier),
           Misconceptions),
    loaded_geom_misconception(Name, TargetConcept, Title, Triggers, Repair, Citation),
    Commitment = geometry_misconception(Name),
    EntitlementLacked = geometry_concept(TargetConcept),
    derived_incompatibility_terms(Name, Commitment, EntitlementLacked, ConflictTerms),
    add_provenance(unit_cluster_fallback,
                   [ source(cluster(geometry, ClusterId)),
                     concept(TargetConcept),
                     title(Title),
                     triggers(Triggers),
                     repair(Repair),
                     citation(Citation),
                     tier(Tier),
                     commitment_made(Commitment),
                     entitlement_lacked(EntitlementLacked)
                   | ConflictTerms ],
                   Info).


%!  geometry_strategy_info(+ClusterId, +ConceptId, -Info) is semidet.
%
%   Same Info shape as cluster_lesson_geometry_strategy/3, for a lesson whose
%   teacher guide has been read and confirmed to teach ConceptId. Lets
%   explicit_lesson_strategy/4 facts skip the lesson-topic discovery
%   (cluster_fallback_allowed/4) that drives the unit_cluster_fallback path.
geometry_strategy_info(ClusterId, ConceptId, Info) :-
    loaded_geometry_monitoring_bundle(
        ConceptId,
        geometry_monitoring_bundle(ConceptId,
                                   Concept,
                                   Related,
                                   Standards,
                                   Misconceptions,
                                   Metaphors,
                                   Markers,
                                   Arcs)
    ),
    add_provenance(text_evidenced,
                   [ source(cluster(geometry, ClusterId)),
                     Concept,
                     commitment_made(geometry_concept(ConceptId)),
                     entitlement_granted(geometry_concept(ConceptId)),
                     related_concepts(Related),
                     standards(Standards),
                     misconceptions(Misconceptions),
                     metaphors(Metaphors),
                     markers(Markers),
                     arcs(Arcs)
                   ],
                   Info).


%!  geometry_misconception_info(+ClusterId, +ConceptId, +Name, -Info) is semidet.
%
%   Same Info shape as cluster_lesson_geometry_misconception/3, for a
%   misconception a lesson's own teacher guide has been read and confirmed
%   to evidence (e.g. a documented anticipated student error), rather than
%   one merely attached at the concept-cluster level.
geometry_misconception_info(ClusterId, ConceptId, Name, Info) :-
    loaded_geometry_monitoring_bundle(
        ConceptId,
        geometry_monitoring_bundle(ConceptId,
                                   _Concept,
                                   _Related,
                                   _Standards,
                                   Misconceptions,
                                   _Metaphors,
                                   _Markers,
                                   _Arcs)
    ),
    member(misconception(Name, TargetConcept, Title, _MatchedTrigger, Repair, Tier),
           Misconceptions),
    loaded_geom_misconception(Name, TargetConcept, Title, Triggers, Repair, Citation),
    Commitment = geometry_misconception(Name),
    EntitlementLacked = geometry_concept(TargetConcept),
    derived_incompatibility_terms(Name, Commitment, EntitlementLacked, ConflictTerms),
    add_provenance(text_evidenced,
                   [ source(cluster(geometry, ClusterId)),
                     concept(TargetConcept),
                     title(Title),
                     triggers(Triggers),
                     repair(Repair),
                     citation(Citation),
                     tier(Tier),
                     commitment_made(Commitment),
                     entitlement_lacked(EntitlementLacked)
                   | ConflictTerms ],
                   Info).


misconception_info(Name, Citation, Commitment, EntitlementLacked, Prefix, Info) :-
    derived_incompatibility_terms(Name, Commitment, EntitlementLacked, ConflictTerms),
    append(Prefix,
           [ Citation,
             commitment_made(Commitment),
             entitlement_lacked(EntitlementLacked)
           | ConflictTerms ],
           Info).

derived_incompatibility_terms(Name, Commitment, EntitlementLacked, Terms) :-
    derived_incompatibility_witness(Name,
                                    Commitment,
                                    EntitlementLacked,
                                    ConflictTerm,
                                    ConflictWitness),
    BaseTerms = [ConflictTerm, incompatibility_witness(ConflictWitness)],
    (   discovered_incompatibility_set_witness(Name,
                                               Commitment,
                                               EntitlementLacked,
                                               SetWitness)
    ->  get_dict(set, SetWitness, Set),
        append(BaseTerms,
               [ incompatibility_set(discovered, Set),
                 incompatibility_set_witness(SetWitness)
               ],
               Terms)
    ;   Terms = BaseTerms
    ).

%!  derived_incompatibility_witness(+Name, +Commitment, +EntitlementLacked,
%!                                  -ConflictTerm, -Witness) is det.
%
%   The lesson-monitoring chart is a closed-world finite lesson surface. Its
%   incompatibility claim is derived from the loaded misconception registry
%   when possible; otherwise the chart records a commitment-entitlement gap
%   and the finite registry queries that did not produce a conflict.
derived_incompatibility_witness(Name,
                                Commitment,
                                _EntitlementLacked,
                                incompatibility(Conflict),
                                Witness) :-
    registry_incompatibility_query(Name,
                                   Commitment,
                                   Conflict,
                                   Query,
                                   RegistryWitness),
    !,
    Witness = _{ kind: lesson_monitoring_incompatibility,
                 source: registry_query,
                 query: Query,
                 conflict: Conflict,
                 registry_witness: RegistryWitness }.
derived_incompatibility_witness(Name,
                                Commitment,
                                EntitlementLacked,
                                commitment_entitlement_gap(
                                    no_registered_incompatibility(EntitlementLacked)),
                                Witness) :-
    incompatibility_queries(Name, Commitment, Queries),
    Witness = _{ kind: lesson_monitoring_commitment_entitlement_gap,
                 source: no_registered_incompatibility,
                 commitment: Commitment,
                 entitlement_lacked: EntitlementLacked,
                 checked_queries: Queries }.

registry_incompatibility_query(Name, Commitment, Conflict, Query, Witness) :-
    incompatibility_queries(Name, Commitment, Queries),
    member(Query, Queries),
    incompatibility_with_witness(Query, Conflict, Witness).

incompatibility_queries(Name, Commitment,
                        [ Name,
                          misconception(Name),
                          geometry_misconception(Name),
                          Commitment
                        ]).

%!  discovered_incompatibility_set_witness(+Name, +Commitment,
%!                                         +EntitlementLacked, -Witness) is semidet.
%
%   The Big Red neighborhood check is the closed-world finite case of an
%   open-ended incompatibility-entailment problem. It records the hyperedge
%   discovered by the bounded search and the classifier result that made the
%   set incoherent.
discovered_incompatibility_set_witness(Name, Commitment, EntitlementLacked, Witness) :-
    member(Set,
           [ [Name, EntitlementLacked],
             [misconception(Name), EntitlementLacked],
             [Commitment, EntitlementLacked]
           ]),
    classify_candidate_set(registry_neighborhood, Set, Classification),
    Classification = incoherent(_),
    Witness = _{ kind: bounded_big_red_incompatibility_set,
                 source: registry_neighborhood,
                 scope: closed_world_finite_big_red_search,
                 set: Set,
                 classification: Classification },
    !.


chart_registry_cluster(k8_operations, division_sharing_measurement, division_grouping_structures).
chart_registry_cluster(k8_operations, count_sequence_cardinality, diagnostic_cardinality_by_bijective_counting).
chart_registry_cluster(k8_operations, quantity_comparison_difference, quantity_comparison_difference).
chart_registry_cluster(k8_operations, additive_situation_structures, additive_strategy_fluency).
chart_registry_cluster(k8_operations, additive_situation_structures, subtractive_strategy_fluency).
chart_registry_cluster(k8_operations, data_statistics_probability, probability_weighted_terminal_tree).
chart_registry_cluster(k8_operations, decimal_place_value_operations, decimal_positional_notation).
chart_registry_cluster(k8_operations, decimal_place_value_operations, decimal_multiplication).
chart_registry_cluster(k8_operations, decimal_place_value_operations, decimal_division).
chart_registry_cluster(k8_operations, patterns_functions_linear_relationships, algebraic_linear_pattern_generalization).
chart_registry_cluster(k8_operations, base_ten_bundling_place_value, additive_column_algorithm).
chart_registry_cluster(k8_operations, base_ten_bundling_place_value, subtractive_strategy_fluency).
chart_registry_cluster(k8_operations, expressions_equations_balance, algebraic_expression_evaluation_as_program).
chart_registry_cluster(k8_operations, multidigit_add_sub_algorithms, additive_column_algorithm).
chart_registry_cluster(k8_operations, multidigit_add_sub_algorithms, subtractive_strategy_fluency).
chart_registry_cluster(k8_operations, multiplication_equal_groups_arrays, multiplicative_composite_units).
chart_registry_cluster(k8_operations, multiplicative_comparison_scaling, multiplicative_factor_relations).
chart_registry_cluster(k8_operations, ratio_rate_percent_proportionality, proportional_ratio_unit_coordination).
chart_registry_cluster(k8_operations, signed_number_operations, signed_number_combination).
chart_registry_cluster(fraction, equal_partitioning, fraction_unit_referent_operations).
chart_registry_cluster(fraction, unit_iteration_nonunit, fraction_unit_referent_operations).
chart_registry_cluster(fraction, number_line_unit_interval, fraction_unit_referent_operations).
chart_registry_cluster(fraction, beyond_one_and_whole_equivalence, fraction_unit_referent_operations).
chart_registry_cluster(fraction, equivalence_repartitioning, fraction_unit_referent_operations).
chart_registry_cluster(fraction, comparison_same_denominator_numerator, fraction_unit_referent_operations).
chart_registry_cluster(fraction, referent_control, fraction_unit_referent_operations).
chart_registry_cluster(fraction, fraction_composition, fraction_area_model_multiplication).
chart_registry_cluster(fraction, co_measurement_add_subtract, co_denominator_cgi_dispatch).
chart_registry_cluster(fraction, measurement_division_reversible_generator, division_sharing_measurement).
chart_registry_cluster(fraction, procedural_compression, fraction_area_model_multiplication).
chart_registry_cluster(_Source, ClusterId, ClusterId).


chart_registry_misconception(k8_operations,
                             count_sequence_cardinality,
                             write_full_counting_sequence).
chart_registry_misconception(k8_operations,
                             expressions_equations_balance,
                             left_to_right_ignores_precedence).


geometry_cluster_concept(transformations_congruence_similarity, similar_figures).
geometry_cluster_concept(transformations_congruence_similarity, tracing_paper_diagnostic).
geometry_cluster_concept(shape_attributes_informal, shape_attributes_informal).
geometry_cluster_concept(defining_attributes_classification, quadrilateral_hierarchy).
geometry_cluster_concept(compose_decompose_shapes, compose_decompose_shapes).
geometry_cluster_concept(coordinate_grid_location, coordinate_system_axes).
geometry_cluster_concept(equal_shares_fraction_geometry, partition_shapes_unit_fraction_area).
geometry_cluster_concept(scale_drawings_geometric_proportionality, scale_drawings).
geometry_cluster_concept(area_tiling_unit_iteration, area_as_2d_unit_iteration).
geometry_cluster_concept(perimeter_distance_around, perimeter_as_boundary_traversal).
geometry_cluster_concept(lines_angles_precision, points_lines_angles).
geometry_cluster_concept(surface_area_nets, nets_surface_area).
geometry_cluster_concept(circle_measurement, circle_area_circumference).
geometry_cluster_concept(volume_packing_layers, volume_as_3d_unit_iteration).
geometry_cluster_concept(pythagorean_distance, pythagorean_theorem).


misconception_matches_cluster(Operation, Name, _Commitment, ClusterId) :-
    action_automaton_cluster(Operation, Name, ClusterId).
misconception_matches_cluster(Operation,
                              Name,
                              deformed_action(Productive, Name, _Family),
                              ClusterId) :-
    action_automaton_cluster(Operation, Productive, ClusterId).


%!  enact_lesson_misconception(+LessonCode, +MisconceptionName, +Agent) is semidet.
enact_lesson_misconception(Code, Name, Agent) :-
    lesson_misconception(Code, _, Name, Info),
    member(commitment_made(Commitment), Info),
    enact_misconception(Agent, Commitment).


strategy_info(Operation, Kind, Info) :-
    action_automaton_cluster(Operation, Kind, Cluster),
    action_automaton_vocabulary(Operation, Kind, Vocabulary),
    Info = [ automaton_ref(action_automata_registry:Operation:Kind),
             cluster(Cluster),
             vocabulary(Vocabulary),
             commitment_made(strategy(Operation, Kind)),
             entitlement_granted(strategy(Operation, Kind))
           ].

loaded_geom_concept(ConceptId, Title, Topic, Bands) :-
    current_predicate(Module:geom_concept/4),
    call(Module:geom_concept(ConceptId, Title, Topic, Bands)),
    !.

loaded_standard_anchor(ConceptId, Framework, Code, Statement) :-
    current_predicate(Module:standard_anchor/4),
    call(Module:standard_anchor(ConceptId, Framework, Code, Statement)).

loaded_geometry_monitoring_bundle(ConceptId, Bundle) :-
    geometry_monitoring_bundle_provider(Module),
    call(Module:concept_monitoring_bundle(ConceptId, Bundle)).

geometry_monitoring_bundle_provider(Module) :-
    findall(Provider,
            ( current_predicate(Seen:concept_monitoring_bundle/2),
              (   predicate_property(Seen:concept_monitoring_bundle(_, _),
                                     imported_from(Imported))
              ->  Provider = Imported
              ;   Provider = Seen
              )
            ),
            Providers0),
    sort(Providers0, Providers),
    member(Module, Providers).

loaded_geom_misconception(Name, ConceptId, Title, Triggers, Repair, Citation) :-
    geom_misconception_provider(Module),
    call(Module:geom_misconception(Name, ConceptId, Title, Triggers, Repair, Citation)).

geom_misconception_provider(Module) :-
    findall(Provider,
            ( current_predicate(Seen:geom_misconception/6),
              (   predicate_property(Seen:geom_misconception(_, _, _, _, _, _),
                                     imported_from(Imported))
              ->  Provider = Imported
              ;   Provider = Seen
              )
            ),
            Providers0),
    sort(Providers0, Providers),
    member(Module, Providers).


lesson_pml_facts(Code, PMLFacts) :-
    interpret_lesson_text(Code, PMLFacts0),
    !,
    lesson_coverage_facts(Code, CoverageFacts),
    append(PMLFacts0, CoverageFacts, PMLFacts).
lesson_pml_facts(Code, PMLFacts) :-
    lesson_coverage_facts(Code, PMLFacts),
    !.
lesson_pml_facts(_, []).


lesson_coverage_facts(Code, Facts) :-
    findall(coverage(Coverage),
            lesson_coverage(Code, Coverage),
            Facts0),
    sort(Facts0, Facts).


lesson_coverage(Code, scope_sequence_only) :-
    scope_sequence_only_lesson(Code).
lesson_coverage(Code, scope_sequence_mapped) :-
    scope_sequence_mapped_lesson(Code).
lesson_coverage(Code, text_evidenced) :-
    lesson_has_explicit_attachments(Code).
lesson_coverage(Code, compiled_text_evidence) :-
    lesson_has_compiled_attachments(Code).
lesson_coverage(Code, unit_cluster_fallback) :-
    fallback_attachment_exists(Code).
lesson_coverage(Code, under_attached(no_confident_lesson_attachment)) :-
    \+ lesson_has_specific_attachments(Code),
    \+ fallback_attachment_exists(Code).


fallback_attachment_exists(Code) :-
    once(( lesson_monitoring:cluster_lesson_strategy_candidate(Code, _, _, _)
         ; lesson_monitoring:cluster_lesson_misconception_candidate(Code, _, _, _)
         ; lesson_monitoring:cluster_lesson_geometry_strategy(Code, _, _)
         ; lesson_monitoring:cluster_lesson_geometry_misconception(Code, _, _)
         )).


im_lesson_code_parts(Code, Grade, Unit, LessonNumber) :-
    atomic_list_concat(['IM', GradeToken, UnitToken, LessonToken], '-', Code),
    grade_token_number(GradeToken, Grade),
    prefixed_number('U', UnitToken, Unit),
    prefixed_number('L', LessonToken, LessonNumber).

grade_token_number('GK', 0) :- !.
grade_token_number(GradeToken, Grade) :-
    prefixed_number('G', GradeToken, Grade).

prefixed_number(Prefix, Token, Number) :-
    atom_concat(Prefix, NumberAtom, Token),
    atom_number(NumberAtom, Number).


lesson_unit_anchor(Code, UnitAnchor) :-
    atomic_list_concat(['IM', GradeToken, UnitToken | _Rest], '-', Code),
    atomic_list_concat(['IM', GradeToken, UnitToken], '-', UnitAnchor).

cluster_anchor_matches(Code, UnitAnchor, Anchors) :-
    lesson_cluster_anchor(Code, UnitAnchor, Candidate),
    member(Candidate, Anchors).

lesson_cluster_anchor(Code, _UnitAnchor, Code).
lesson_cluster_anchor(_Code, UnitAnchor, UnitAnchor).
lesson_cluster_anchor(_Code, UnitAnchor, Alias) :-
    atomic_list_concat(['IM', 'GK', UnitToken], '-', UnitAnchor),
    atomic_list_concat(['IM', 'K', UnitToken], '-', Alias).


cluster_matches_lesson_topic(Code, geometry, _ClusterId) :-
    lesson_export_operation(Code, geometry),
    !.
cluster_matches_lesson_topic(Code, Source, ClusterId) :-
    chart_registry_cluster(Source, ClusterId, RegistryClusterId),
    action_automaton_cluster(Operation, _Kind, RegistryClusterId),
    lesson_export_operation(Code, Operation),
    !.


lesson_export_operation(Code, Operation) :-
    lesson_has_specific_attachments(Code),
    !,
    specific_attachment_operation(Code, Operation).
lesson_export_operation(Code, Operation) :-
    operation_matches_lesson_topic(Code, Operation).


explicit_attachment_operation(Code, Operation) :-
    explicit_lesson_strategy(Code, Operation, _, _).
explicit_attachment_operation(Code, Operation) :-
    explicit_lesson_misconception(Code, Operation, _, _).

specific_attachment_operation(Code, Operation) :-
    explicit_attachment_operation(Code, Operation).
specific_attachment_operation(Code, Operation) :-
    compiled_lesson_strategy(Code, Operation, _, _).


scope_sequence_im_lesson(Code, ConceptId, Title, Grade, Unit, LessonNumber) :-
    between(6, 8, Grade),
    scope_sequence_file(Grade, RelativePath),
    repo_file(RelativePath, Path),
    read_file_to_string(Path, Content, []),
    split_string(Content, "\n", "\r", Lines),
    member(Line, Lines),
    scope_sequence_lesson_line(Line, Code, Title, Grade, Unit, LessonNumber),
    lesson_unit_anchor(Code, UnitAnchor),
    atom_string(UnitAnchor, UnitAnchorString),
    once(loaded_standard_anchor(ConceptId, im_lesson, UnitAnchorString, _Statement)).


scope_sequence_file(6, 'geometry/corpus/im_scope_and_sequence/grade6.md').
scope_sequence_file(7, 'geometry/corpus/im_scope_and_sequence/grade7.md').
scope_sequence_file(8, 'geometry/corpus/im_scope_and_sequence/grade8.md').


scope_sequence_lesson_line(Line, Code, Title, Grade, Unit, LessonNumber) :-
    LessonPrefix = "- **Lesson ",
    sub_string(Line, 0, _, _, LessonPrefix),
    string_length(LessonPrefix, PrefixLength),
    sub_string(Line, NumberEnd, 4, _, ":** "),
    NumberEnd > PrefixLength,
    NumberLength is NumberEnd - PrefixLength,
    sub_string(Line, PrefixLength, NumberLength, _, NumberString),
    number_string(LessonNumber, NumberString),
    TitleStart is PrefixLength + NumberLength + 4,
    sub_string(Line, DelimiterStart, 3, _, "  `"),
    DelimiterStart > TitleStart,
    TitleLength is DelimiterStart - TitleStart,
    sub_string(Line, TitleStart, TitleLength, _, Title),
    CodeStart is DelimiterStart + 3,
    string_length(Line, LineLength),
    CodeLength is LineLength - CodeStart - 1,
    CodeLength > 0,
    sub_string(Line, CodeStart, CodeLength, 1, CodeString),
    atom_string(Code, CodeString),
    im_lesson_code_parts(Code, Grade, Unit, LessonNumber).


monitoring_cluster_source(k8_operations,
                          'docs/research_assets/research/2026-05-11-k8-operations-monitoring-chart-clusters.json').
monitoring_cluster_source(fraction,
                          'docs/research_assets/research/2026-05-11-fraction-monitoring-chart-clusters.json').
monitoring_cluster_source(geometry,
                          'docs/research_assets/research/2026-05-11-geometry-monitoring-chart-clusters.json').


monitoring_cluster_dict(RelativePath, Cluster) :-
    repo_file(RelativePath, Path),
    setup_call_cleanup(
        open(Path, read, In),
        json_read_dict(In, Root, [value_string_as(atom)]),
        close(In)
    ),
    get_dict(clusters, Root, Clusters),
    member(Cluster, Clusters).


cluster_info(Cluster, Info) :-
    dict_value(Cluster, title, Title),
    dict_value(Cluster, productive_core, ProductiveCore),
    dict_value(Cluster, deformation, Deformation),
    dict_value(Cluster, assessing_questions, AssessingQuestions0),
    dict_value(Cluster, advancing_questions, AdvancingQuestions0),
    maplist(text_string, AssessingQuestions0, AssessingQuestions),
    maplist(text_string, AdvancingQuestions0, AdvancingQuestions),
    dict_value(Cluster, standards, Standards),
    dict_value(Cluster, im_anchors, IMAnchors),
    sample_terms(Cluster, strategy_samples, StrategySamples, _UncitedStrategyCount),
    sample_terms(Cluster, misconception_samples, MisconceptionSamples, UncitedMisconceptionCount),
    Info0 = [ title(Title),
              productive_core(ProductiveCore),
              deformation(Deformation),
              assessing_questions(AssessingQuestions),
              advancing_questions(AdvancingQuestions),
              standards(Standards),
              im_anchors(IMAnchors),
              strategy_samples(StrategySamples),
              misconception_samples(MisconceptionSamples)
            ],
    (   UncitedMisconceptionCount > 0
    ->  Info = [misconception_sample_gap(no_cited_samples(UncitedMisconceptionCount))|Info0]
    ;   Info = Info0
    ).


sample_terms(Cluster, Key, CitedSamples, UncitedCount) :-
    dict_value(Cluster, Key, Dicts),
    findall(Sample,
            ( member(Dict, Dicts),
              sample_term(Dict, Sample)
            ),
            Samples),
    include(cited_sample, Samples, CitedSamples),
    length(Samples, Total),
    length(CitedSamples, CitedCount),
    UncitedCount is Total - CitedCount.


sample_term(Dict, sample(Id, BibtexKey, Description, Domain, Topic, PageRefs)) :-
    dict_value(Dict, id, Id),
    dict_value(Dict, bibtex_key, BibtexKey),
    dict_value(Dict, description, Description),
    dict_value(Dict, domain, Domain),
    dict_value(Dict, topic, Topic),
    dict_value(Dict, page_refs, PageRefs).

cited_sample(sample(_, BibtexKey, _, _, _, _)) :-
    BibtexKey \== unknown,
    BibtexKey \== null,
    BibtexKey \== ''.


dict_value(Dict, Key, Value) :-
    get_dict(Key, Dict, Raw),
    !,
    normalize_json_value(Raw, Value).
dict_value(_, _, unknown).

normalize_json_value(@(null), unknown) :- !.
normalize_json_value(null, unknown) :- !.
normalize_json_value(Value, Value).


text_string(Value, String) :-
    string(Value),
    !,
    String = Value.
text_string(Value, String) :-
    atom(Value),
    !,
    atom_string(Value, String).
text_string(Value, Value).


repo_file(RelativePath, Path) :-
    repo_file_root(Root),
    directory_file_path(Root, RelativePath, Path).

repo_file_root(Root) :-
    getenv('UMEDCTA_DATA_ROOT', Root0),
    !,
    atom_string(Root, Root0).
repo_file_root(Root) :-
    getenv('UMEDCTA_ROOT', Root0),
    !,
    atom_string(Root, Root0).
repo_file_root(Root) :-
    absolute_file_name(im_lessons('../../'),
                       Root,
                       [file_type(directory), access(read)]).
