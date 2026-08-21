/** <module> Paired fraction-comparison scene compiler */

:- module(fraction_comparison_scene,
          [ fraction_comparison_compare_json/2
          ]).

:- use_module(strategies(math/fraction_action_pairs),
              [ run_fraction_action/5,
                productive_fraction_deformation/3
              ]).
:- use_module(strategies(math/decimal_action_pairs),
              [ run_decimal_action/5,
                productive_decimal_deformation/3
              ]).
:- use_module(math(integer_helpers), [multiply_ints/3]).
:- use_module(render(render_common), [term_to_string/2]).
:- use_module(library(lists), [max_list/2]).


%!  fraction_comparison_compare_json(+Spec, -Dict) is det.
fraction_comparison_compare_json(compare_spec(Family, N1, D1, N2, D2), Dict) :-
    !,
    (   family_kinds(Family, ProductiveKind, DeformationKind)
    ->  comparison_document(Family, ProductiveKind, DeformationKind,
                            N1, D1, N2, D2, Dict)
    ;   error_document(Family, unknown_family,
                       "This comparison family is not available.", Dict)
    ).
fraction_comparison_compare_json(Spec, Dict) :-
    term_to_string(Spec, SpecText),
    Dict = _{ error: "Expected compare_spec(Family,N1,D1,N2,D2).",
              request: SpecText,
              productive: _{frames: []}, deformation: _{frames: []} }.


comparison_document(Family, ProductiveKind, DeformationKind,
                    N1, D1, N2, D2, Dict) :-
    (   once(run_pair(Family, ProductiveKind, DeformationKind,
                      N1, D1, N2, D2,
                      ProductiveOutcome, ProductiveTrace,
                      DeformationOutcome, DeformationTrace))
    ->  (   comparison_scenes(Family, N1, D1, N2, D2,
                              ProductiveTrace, DeformationTrace,
                              ProductiveOutcome, DeformationOutcome,
                              ProductiveScene, DeformationScene)
        ->  outcome_side(ProductiveOutcome, ProductiveTrace,
                         ProductiveScene, Productive),
            outcome_side(DeformationOutcome, DeformationTrace,
                         DeformationScene, Deformation),
            document_fields(Family, ProductiveKind, DeformationKind,
                            N1, D1, N2, D2,
                            ProductiveOutcome, DeformationOutcome,
                            Productive, Deformation, Dict)
        ;   error_document(Family, geometry_not_drawn,
                           "These inputs do not have an honest layout in this comparison format.",
                           Dict)
        )
    ;   error_document(Family, malformed_inputs,
                       "The comparison automata did not accept these four integers.", Dict)
    ).

document_fields(Family, ProductiveKind, DeformationKind,
                N1, D1, N2, D2,
                ProductiveOutcome, DeformationOutcome,
                Productive, Deformation, Dict) :-
    maplist(term_to_string,
            [Family, ProductiveKind, DeformationKind],
            [FamilyText, ProductiveText, DeformationText]),
    outcome_note(Family, DeformationOutcome, Note),
    Base = _{ productiveKind: ProductiveText,
              deformationKind: DeformationText,
              family: FamilyText,
              inputs: _{n1:N1, d1:D1, n2:N2, d2:D2},
              canvas: _{width:900, height:420},
              productive: Productive,
              deformation: Deformation,
              note: Note },
    outcome_result(ProductiveOutcome, ProductiveResult),
    outcome_result(DeformationOutcome, DeformationResult),
    (   ProductiveResult == DeformationResult
    ->  WithDivergence = Base
    ;   WithDivergence = Base.put(divergence,
            _{productiveResult:ProductiveResult,
              deformationResult:DeformationResult})
    ),
    (   outcome_viability(DeformationOutcome, Viability)
    ->  viability_dict(Viability, ViabilityDict),
        ViabilityWithInputs = ViabilityDict.put(inputs,
            _{n1:N1, d1:D1, n2:N2, d2:D2}),
        Dict = WithDivergence.put(viability, ViabilityWithInputs)
    ;   Dict = WithDivergence
    ).

error_document(Family, Code, Message, Dict) :-
    term_to_string(Family, FamilyText),
    term_to_string(Code, CodeText),
    Dict = _{ family: FamilyText,
              error: Message, errorCode: CodeText,
              productive: _{frames: []}, deformation: _{frames: []} }.


family_kinds(number_line_fraction_comparison,
             number_line_fraction_comparison,
             number_line_count_marks_not_intervals).
family_kinds(area_model_fraction_comparison,
             area_model_fraction_comparison,
             area_model_unequal_partition_piece_count).
family_kinds(set_model_fraction_comparison,
             set_model_fraction_comparison,
             set_model_subset_size_focus).
family_kinds(benchmark_fraction_comparison,
             benchmark_fraction_comparison,
             gap_thinking_fraction_comparison).
family_kinds(common_unit_fraction_comparison,
             common_unit_fraction_comparison,
             add_numerator_denominator_comparison).
family_kinds(decimal_fraction_place_value_comparison,
             decimal_fraction_place_value_comparison,
             decimal_scale_loss_comparison).
family_kinds(positional_decimal_reading,
             positional_decimal_reading,
             decimal_whole_number_reading).
family_kinds(decimal_comparison_by_aligned_units,
             decimal_comparison_by_aligned_units,
             decimal_numeral_comparison_without_scale_alignment).
family_kinds(decimal_addition_by_aligned_units,
             decimal_addition_by_aligned_units,
             decimal_add_unaligned_numerals).
family_kinds(decimal_subtraction_by_aligned_units,
             decimal_subtraction_by_aligned_units,
             decimal_subtract_unaligned_numerals).
family_kinds(decimal_place_unit_regrouping,
             decimal_place_unit_regrouping,
             change_decimal_place_name_without_regrouping).
family_kinds(decimal_multiplication_rule,
             decimal_multiplication_rule,
             decimal_point_rule_misapplication).

run_pair(Family, ProductiveKind, DeformationKind,
         N1, S1, N2, S2,
         ProductiveOutcome, ProductiveTrace,
         DeformationOutcome, DeformationTrace) :-
    decimal_pair_family(Family),
    productive_decimal_deformation(ProductiveKind, DeformationKind, _),
    decimal_action_input(Family, N1, S1, N2, S2, Input, Scale),
    run_decimal_action(ProductiveKind, Input, Scale,
                       ProductiveOutcome, ProductiveTrace),
    run_decimal_action(DeformationKind, Input, Scale,
                       DeformationOutcome, DeformationTrace).
run_pair(Family, ProductiveKind, DeformationKind,
         N1, D1, N2, D2,
         ProductiveOutcome, ProductiveTrace,
         DeformationOutcome, DeformationTrace) :-
    \+ decimal_pair_family(Family),
    productive_fraction_deformation(ProductiveKind, DeformationKind, _),
    Pair = fraction_pair(N1, D1, N2, D2),
    run_fraction_action(ProductiveKind, Pair, unit(whole),
                        ProductiveOutcome, ProductiveTrace),
    run_fraction_action(DeformationKind, Pair, unit(whole),
                        DeformationOutcome, DeformationTrace).

decimal_pair_family(decimal_fraction_place_value_comparison).
decimal_pair_family(positional_decimal_reading).
decimal_pair_family(decimal_comparison_by_aligned_units).
decimal_pair_family(decimal_addition_by_aligned_units).
decimal_pair_family(decimal_subtraction_by_aligned_units).
decimal_pair_family(decimal_place_unit_regrouping).
decimal_pair_family(decimal_multiplication_rule).

decimal_action_input(positional_decimal_reading, Numeral, Scale, _, _,
                     Numeral, Scale).
decimal_action_input(decimal_place_unit_regrouping,
                     Count, FromScale, ToScale, _,
                     decimal_unit_conversion(Count, FromScale, ToScale), ignored).
decimal_action_input(Family, N1, S1, N2, S2,
                     decimal_pair(N1, S1, N2, S2), ignored) :-
    memberchk(Family,
              [ decimal_fraction_place_value_comparison,
                decimal_comparison_by_aligned_units,
                decimal_addition_by_aligned_units,
                decimal_subtraction_by_aligned_units,
                decimal_multiplication_rule
              ]).


outcome_side(Outcome, Trace, Scene, Side) :-
    outcome_result(Outcome, Result),
    outcome_expected(Outcome, Expected),
    outcome_validity(Outcome, Validity),
    trace_frames(Trace, Scene, Frames),
    maplist(term_to_string, Trace, TraceStrings),
    Side = _{result:Result, expected:Expected, validity:Validity,
             trace:TraceStrings, frames:Frames}.

outcome_fields(action_outcome(_, Fields), Fields).
outcome_result(Outcome, Result) :-
    outcome_fields(Outcome, Fields), memberchk(result(Result), Fields).
outcome_expected(Outcome, Expected) :-
    outcome_fields(Outcome, Fields),
    ( memberchk(expected(Expected), Fields) -> true ; outcome_result(Outcome, Expected) ).
outcome_validity(Outcome, Validity) :-
    outcome_fields(Outcome, Fields), memberchk(validity(Validity), Fields).
outcome_viability(Outcome, Viability) :-
    outcome_fields(Outcome, Fields),
    (   memberchk(viability(Viability), Fields)
    ;   memberchk(viability_context(Viability), Fields),
        Viability = viability(_, _, _)
    ;   memberchk(viability_context(Viability), Fields),
        Viability = viability(_, _, _, _, _)
    ), !.

outcome_note(Family, _Outcome, Note) :- family_note(Family, Note), !.
outcome_note(_Family, _Outcome,
             "The right side applies a paired deformation to the same inputs.").

family_note(number_line_fraction_comparison,
    "The productive side counts intervals of a common unit fraction. The deformation counts marks instead, shifting each represented position by one interval.").
family_note(area_model_fraction_comparison,
    "The productive side compares parts made by equal partitions of the same whole. The deformation counts shaded pieces even though the pieces are not the same size.").
family_note(set_model_fraction_comparison,
    "The productive side compares each subset with the same whole collection. The deformation compares subset counts without coordinating the size of the whole.").
family_note(benchmark_fraction_comparison,
    "The productive side locates both fractions relative to a shared benchmark. The deformation compares uncoordinated gaps, so the distances do not name the same unit.").
family_note(common_unit_fraction_comparison,
    "The productive side rewrites both fractions in a common unit before comparing them. The deformation adds numerators and denominators component by component, changing the quantities.").
family_note(decimal_fraction_place_value_comparison,
    "The productive side preserves each decimal's place-value scale while aligning the quantities. The deformation drops that scale and compares the written numerals alone.").
family_note(positional_decimal_reading,
    "The productive side reads the decimal mark and assigns each digit a place value. The deformation reads the same digit string as a whole number and loses the decimal scale.").
family_note(decimal_comparison_by_aligned_units,
    "The productive side expresses both decimals in one common unit before comparing them. The deformation compares the unaligned written numerals, which can reverse their order.").
family_note(decimal_addition_by_aligned_units,
    "The productive side aligns decimal units before adding and then reinscribes the sum. The deformation adds the written numerals first and attaches a scale afterward.").
family_note(decimal_subtraction_by_aligned_units,
    "The productive side aligns decimal units before subtracting and then reinscribes the difference. The deformation subtracts the written numerals without first making their units alike.").
family_note(decimal_place_unit_regrouping,
    "The productive side changes the count when it names a finer decimal unit, preserving the quantity. The deformation changes the unit name but leaves the count unchanged.").
family_note(decimal_multiplication_rule,
    "The productive side adds the two fractional-place counts when placing the decimal point in the product. The deformation uses only the larger place count, changing the product's scale.").

viability_dict(viability(Status, condition(Condition), validity(Validity)), Dict) :-
    !,
    human_term(Condition, ConditionText),
    Dict = _{status:Status, condition:ConditionText, validity:Validity}.
viability_dict(viability(Status, condition(Condition),
                         expected(Expected), produced(Produced),
                         validity(Validity)), Dict) :-
    !,
    human_term(Condition, ConditionText),
    Dict = _{status:Status, condition:ConditionText,
             expected:Expected, produced:Produced, validity:Validity}.
viability_dict(Viability, _{record:Text}) :- term_to_string(Viability, Text).


trace_frames(Trace, Scene, Frames) :- trace_frames_(Trace, Scene, 1, Frames).

trace_frames_([], _, _, []).
trace_frames_([Hist|Rest], Scene, Step, [Frame|Frames]) :-
    trace_state(Hist, State),
    term_to_string(State, Verb),
    trace_caption(Hist, Caption),
    ( Step =:= 1 -> Changed = true ; Changed = false ),
    Frame = _{step:Step, verb:Verb, caption:Caption,
              sceneChanged:Changed, scene:Scene},
    Next is Step + 1,
    trace_frames_(Rest, Scene, Next, Frames).

trace_state(hist(State, _), State) :- !.
trace_state(Action, State) :-
    ( compound(Action) -> functor(Action, State, _) ; State = Action ).

trace_caption(hist(_State, Viability), Caption) :-
    Viability = viability(_, condition(Condition), _),
    !,
    human_term(Condition, ConditionText),
    format(string(Caption), "Viability condition: ~s.", [ConditionText]).
trace_caption(hist(_State, Viability), Caption) :-
    Viability = viability(_, condition(Condition), _, _, _),
    !,
    human_term(Condition, ConditionText),
    format(string(Caption), "Viability condition: ~s.", [ConditionText]).
trace_caption(hist(State, Payload), Caption) :-
    !,
    state_label(State, StateText),
    compact_payload(Payload, Compact),
    human_term(Compact, PayloadText),
    format(string(Caption), "~s: ~s.", [StateText, PayloadText]).
trace_caption(Action, Caption) :-
    term_to_string(Action, Raw),
    split_string(Raw, "_", "", Parts),
    atomics_to_string(Parts, " ", Caption0),
    format(string(Caption), "~s.", [Caption0]).

state_label(State, Text) :-
    ( atom_concat(q_, Tail, State) -> true ; Tail = State ),
    human_term(Tail, Text).

compact_payload(Value, trace_steps(Count)) :-
    is_list(Value), !, length(Value, Count).
compact_payload(Value, Compact) :-
    compound(Value), !,
    Value =.. [Functor|Args],
    maplist(compact_payload, Args, CompactArgs),
    Compact =.. [Functor|CompactArgs].
compact_payload(Value, Value).

human_term(Term, Text) :-
    term_to_string(Term, Raw),
    split_string(Raw, "_", "", Parts),
    atomics_to_string(Parts, " ", Text).


comparison_scenes(decimal_comparison_by_aligned_units,
                  N1, S1, N2, S2, _, _, _, _,
                  ProductiveScene, DeformationScene) :-
    CommonScale is max(S1, S2),
    Aligned1 is N1 * (CommonScale // S1),
    Aligned2 is N2 * (CommonScale // S2),
    decimal_number_line_scene(CommonScale, Aligned1, Aligned2,
                              N1, S1, N2, S2, highlight, ProductiveScene),
    decimal_number_line_scene(1, N1, N2,
                              N1, S1, N2, S2, deformation, DeformationScene).
comparison_scenes(Family, _N1, _S1, _N2, _S2, _, _,
                  ProductiveOutcome, DeformationOutcome,
                  ProductiveScene, DeformationScene) :-
    decimal_result_family(Family),
    outcome_result(ProductiveOutcome, ProductiveResult),
    outcome_result(DeformationOutcome, DeformationResult),
    decimal_magnitude(ProductiveResult, ProductiveNumeral, ProductiveScale),
    decimal_magnitude(DeformationResult, DeformationNumeral, DeformationScale),
    CommonScale is max(ProductiveScale, DeformationScale),
    ProductiveAt is ProductiveNumeral * (CommonScale // ProductiveScale),
    DeformationAt is DeformationNumeral * (CommonScale // DeformationScale),
    max_list([1, ProductiveAt, DeformationAt], AxisMax),
    decimal_result_scene(CommonScale, AxisMax, ProductiveAt,
                         ProductiveResult, highlight, ProductiveScene),
    decimal_result_scene(CommonScale, AxisMax, DeformationAt,
                         DeformationResult, deformation, DeformationScene).
comparison_scenes(Family, N1, D1, N2, D2,
                  ProductiveTrace, DeformationTrace, _, _,
                  ProductiveScene, DeformationScene) :-
    comparison_scenes(Family, N1, D1, N2, D2,
                      ProductiveTrace, DeformationTrace,
                      ProductiveScene, DeformationScene).

decimal_result_family(positional_decimal_reading).
decimal_result_family(decimal_addition_by_aligned_units).
decimal_result_family(decimal_subtraction_by_aligned_units).
decimal_result_family(decimal_place_unit_regrouping).
decimal_result_family(decimal_multiplication_rule).

decimal_magnitude(decimal(Whole, fractional_digits(Fractional, Places), _),
                  Numeral, Scale) :-
    pow10(Places, Scale),
    Numeral is Whole * Scale + Fractional.
decimal_magnitude(whole_number(Numeral), Numeral, 1).
decimal_magnitude(equivalent_decimal_units(
                      Numeral, unit_fraction(1, Scale)), Numeral, Scale).

pow10(0, 1) :- !.
pow10(Places, Scale) :-
    Places > 0,
    Previous is Places - 1,
    pow10(Previous, Prior),
    Scale is Prior * 10.

decimal_result_scene(CommonScale, AxisMax, At, Result, Role, Scene) :-
    term_to_string(Result, Label),
    sort([0, At, AxisMax], Ticks),
    Scene = _{format:"number-line", version:2, mode:"decimal-result",
              coordinateDenominator:CommonScale,
              axis:_{min:0, max:AxisMax, ticks:Ticks}, jumps:[],
              marks:[_{at:At,label:Label,role:Role}]}.


comparison_scenes(number_line_fraction_comparison, N1, D1, N2, D2,
                  ProductiveTrace, DeformationTrace,
                  ProductiveScene, DeformationScene) :-
    number_line_trace_scene(ProductiveTrace,
                            fraction(N1,D1), fraction(N2,D2),
                            highlight, ProductiveScene),
    number_line_trace_scene(DeformationTrace,
                            fraction(N1,D1), fraction(N2,D2),
                            deformation, DeformationScene).
comparison_scenes(area_model_fraction_comparison, N1, D1, N2, D2,
                  _, _, ProductiveScene, DeformationScene) :-
    area_pair_scene(N1, D1, N2, D2, highlight, ProductiveScene),
    area_pair_scene(N1, D1, N2, D2, deformation, DeformationScene).
comparison_scenes(set_model_fraction_comparison, N1, D1, N2, D2,
                  ProductiveTrace, _, ProductiveScene, DeformationScene) :-
    multiply_ints(D1, D2, CollectionSize),
    CollectionSize =< 120,
    cross_counts(ProductiveTrace, ProductiveCount1, ProductiveCount2),
    ProductiveCount1 =< CollectionSize,
    ProductiveCount2 =< CollectionSize,
    N1 =< CollectionSize, N2 =< CollectionSize,
    set_pair_scene(CollectionSize, ProductiveCount1, ProductiveCount2,
                   N1, D1, N2, D2, highlight, ProductiveScene),
    set_pair_scene(CollectionSize, N1, N2,
                   N1, D1, N2, D2, deformation, DeformationScene).
comparison_scenes(benchmark_fraction_comparison, N1, D1, N2, D2,
                  _, _, ProductiveScene, DeformationScene) :-
    fraction_bar_pair_scene(N1, D1, N2, D2, benchmark, ProductiveScene),
    fraction_bar_pair_scene(N1, D1, N2, D2, gap_deformation, DeformationScene).
comparison_scenes(common_unit_fraction_comparison, N1, D1, N2, D2,
                  ProductiveTrace, _, ProductiveScene, DeformationScene) :-
    transformed_operands(ProductiveTrace, N1, D1, N2, D2,
                         PN1, PD1, PN2, PD2),
    fraction_bar_pair_scene(PN1, PD1, PN2, PD2, common_unit, ProductiveScene),
    fraction_bar_pair_scene(N1, D1, N2, D2, additive_deformation,
                            DeformationScene).
comparison_scenes(decimal_fraction_place_value_comparison, N1, S1, N2, S2,
                  ProductiveTrace, _, ProductiveScene, DeformationScene) :-
    aligned_decimal_positions(ProductiveTrace, CommonScale, A1, A2),
    decimal_number_line_scene(CommonScale, A1, A2, N1, S1, N2, S2,
                              highlight, ProductiveScene),
    decimal_number_line_scene(1, N1, N2, N1, S1, N2, S2,
                              deformation, DeformationScene).


number_line_trace_scene(Trace, First, Second, Role, Scene) :-
    memberchk(hist(q_measure_with_unit_fraction,
                   co_measure(unit_fraction(1, Base), _,
                              position(_, Position1, _),
                              position(_, Position2, _))), Trace),
    max_list([Base, Position1, Position2], AxisMax),
    sort([0, Base, Position1, Position2], Ticks),
    term_to_string(First, Label1), term_to_string(Second, Label2),
    Scene = _{format:"number-line", version:2, mode:"fraction-comparison",
              coordinateDenominator:Base,
              axis:_{min:0, max:AxisMax, ticks:Ticks}, jumps:[],
              marks:[_{at:Position1,label:Label1,role:Role},
                     _{at:Position2,label:Label2,role:Role}]}.

area_pair_scene(N1, D1, N2, D2, Role, Scene) :-
    D1 > 0, D2 > 0, N1 >= 0, N2 >= 0,
    area_cells(40, 50, N1, D1, Role, Cells1),
    area_cells(40, 170, N2, D2, Role, Cells2),
    append(Cells1, Cells2, Rects),
    Scene = _{format:"area-model", version:2, rows:2,
              cols:0, rects:Rects, gridlines:_{v:[],h:[]}}.

area_cells(X, Y, N, D, Role, Cells) :-
    Count is max(N, D),
    CellWidth is max(1, 420 // D),
    High is Count - 1,
    findall(_{x:CellX,y:Y,w:CellWidth,h:72,rows:1,cols:1,role:CellRole},
            ( between(0, High, Index),
              CellX is X + Index * CellWidth,
              ( Index < N -> CellRole = Role ; CellRole = whole )
            ), Cells).

cross_counts(Trace, Count1, Count2) :-
    memberchk(hist(q_compare_relative_size,
                   co_measure(cross_products(Count1, _, Count2, _), _)), Trace).

set_pair_scene(CollectionSize, Selected1, Selected2,
               N1, D1, N2, D2, Role, Scene) :-
    collection_geometry(40, 40, CollectionSize, Selected1, Role,
                        Dots1, Bin1),
    collection_geometry(480, 40, CollectionSize, Selected2, Role,
                        Dots2, Bin2),
    format(string(Label1), "~w/~w; ~w counters selected", [N1,D1,Selected1]),
    format(string(Label2), "~w/~w; ~w counters selected", [N2,D2,Selected2]),
    LabeledBin1 = Bin1.put(label, Label1),
    LabeledBin2 = Bin2.put(label, Label2),
    append(Dots1, Dots2, Dots),
    Scene = _{format:"set-grouping", version:2, dots:Dots,
              frames10:[], pairLines:[], bins:[LabeledBin1,LabeledBin2]}.

collection_geometry(X, Y, Count, Selected, Role, Dots, Bin) :-
    Columns is min(10, Count),
    Rows is (Count + Columns - 1) // Columns,
    Width is Columns * 34 + 24,
    Height is Rows * 34 + 46,
    Bin = _{x:X,y:Y,w:Width,h:Height,role:neutral},
    findall(_{x:DotX,y:DotY,r:11,role:DotRole,group:0,tag:"counter"},
            ( between(1, Count, Index),
              Zero is Index - 1,
              Col is Zero mod Columns,
              Row is Zero // Columns,
              DotX is X + 24 + Col * 34,
              DotY is Y + 22 + Row * 34,
              ( Index =< Selected -> DotRole = Role ; DotRole = whole )
            ), Dots).

fraction_bar_pair_scene(N1, D1, N2, D2, Mode, Scene) :-
    fraction_bar(0, N1, D1, Mode, Bar1),
    fraction_bar(1, N2, D2, Mode, Bar2),
    Scene = _{format:"fraction-bars", version:2,
              unitBarIndex:null, mats:[], bars:[Bar1,Bar2]}.

fraction_bar(Row, N, D, Mode, Bar) :-
    D > 0, N > 0,
    TotalParts is max(N, D),
    PartWidth is max(1, 420 // D),
    Width is TotalParts * PartWidth,
    Y is 45 + Row * 110,
    split_roles(0, TotalParts, N, PartWidth, Mode, Splits),
    format(string(Label), "~w/~w", [N,D]),
    Bar = _{x:40,y:Y,w:Width,h:54,size:Width,role:whole,
            isUnitBar:false,fraction:Label,label:Label,type:"bar",splits:Splits}.

split_roles(Index, Total, _, _, _, []) :- Index >= Total, !.
split_roles(Index, Total, N, PartWidth, Mode, [Split|Rest]) :-
    split_role(Mode, Index, N, Role),
    X is Index * PartWidth,
    Split = _{x:X,y:0,w:PartWidth,h:54,role:Role},
    Next is Index + 1,
    split_roles(Next, Total, N, PartWidth, Mode, Rest).

split_role(gap_deformation, Index, N, Role) :-
    !, ( Index < N -> Role = highlight ; Role = deformation ).
split_role(additive_deformation, Index, N, Role) :-
    !, ( Index < N -> Role = deformation ; Role = whole ).
split_role(_, Index, N, Role) :-
    ( Index < N -> Role = highlight ; Role = whole ).

transformed_operands(Trace, N1, D1, N2, D2, TN1, TD1, TN2, TD2) :-
    (   memberchk(hist(q_transform_commensurate_1,
                       transformed(_, fraction(TN1, TD1), _)), Trace),
        memberchk(hist(q_transform_commensurate_2,
                       transformed(_, fraction(TN2, TD2), _)), Trace)
    ->  true
    ;   TN1=N1, TD1=D1, TN2=N2, TD2=D2
    ).

aligned_decimal_positions(Trace, CommonScale, A1, A2) :-
    memberchk(hist(q_align_place_value_units,
                   common_scale(CommonScale, aligned_numerals(A1, A2))), Trace).

decimal_number_line_scene(CoordinateScale, Position1, Position2,
                          N1, S1, N2, S2, Role, Scene) :-
    max_list([CoordinateScale, Position1, Position2], AxisMax),
    sort([0, CoordinateScale, Position1, Position2], Ticks),
    format(string(Label1), "~w/~w", [N1,S1]),
    format(string(Label2), "~w/~w", [N2,S2]),
    Scene = _{format:"number-line", version:2, mode:"decimal-comparison",
              coordinateDenominator:CoordinateScale,
              axis:_{min:0,max:AxisMax,ticks:Ticks}, jumps:[],
              marks:[_{at:Position1,label:Label1,role:Role},
                     _{at:Position2,label:Label2,role:Role}]}.
