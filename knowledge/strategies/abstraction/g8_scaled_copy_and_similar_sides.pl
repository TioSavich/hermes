:- encoding(utf8).
/** <module> Grade 8 draft: deciding whether one figure is a scaled copy of another
 *
 * WHAT THIS IS. A draft automaton for the demand that opens grade 8 unit 2
 * and returns at its end. The published pilot `g8_plane_transformation`
 * dilates a figure whose vertices are given as coordinates. The corrected
 * tasks ask something the coordinates are not needed for: correction 62 gives
 * a 9-inch by 12-inch rectangle and six candidates named only by their side
 * lengths, and asks which are scaled copies; correction 113 gives a triangle
 * with sides 4, 5 and 7 and three scale factors, and asks for the side
 * lengths and then for the quotients of sides within each triangle.
 *
 * ONE FACTOR OR NONE. A candidate is a scaled copy exactly when ONE number
 * multiplies every corresponding side of the original into it. The run pairs
 * the sides shortest to shortest, divides, and reports either the single
 * factor or the two sides whose factors disagreed — so the verdict carries
 * its own witness rather than arriving as a yes or a no.
 *
 * THE QUOTIENT THAT DOES NOT MOVE. Correction 113's second table is the
 * lesson's point: the quotient of two sides WITHIN a triangle is the same for
 * the triangle and for every scaled copy of it, because the factor cancels.
 * `quotients_within_a_figure` computes them, and the check below runs all four
 * of the correction's triangles and shows the three quotients repeating.
 *
 * DEFORMATION PARTNER. `add_the_same_amount_to_every_side` reads scaling
 * additively. The research corpus attests the shape at rows 38034 and 38046
 * (students use additive operations instead of multiplicative ratios when
 * comparing two objects; children apply an additive model computing constant
 * differences instead of multiplicative ratios). Correction 62's own
 * distractor N, 14 by 11 against a 9 by 12 original, is 9 + 2 and 12 + 2: the
 * printed task appears to have been built with this reading in mind, and the
 * deformation accepts N where the doing refuses it.
 *
 * QUARANTINE. Nothing imports this module; it is a draft under
 * `.superpowers/sdd/g8-round2/`. Check:
 * `check_g8_scaled_copy_and_similar_sides/0`.
 */

:- module(g8_scaled_copy_and_similar_sides,
          [ run_g8_scaled_copy/4,
            g8_scaled_copy_from_json/2,
            g8_scaled_copy_states/1,
            g8_scaled_copy_state_label/4,
            g8_scaled_copy_summary/1,
            g8_scaled_copy_receipt/5,
            check_g8_scaled_copy_and_similar_sides/0
          ]).

:- use_module(strategies('abstraction/g8_quantity_input'),
              [ g8_quantity/2, g8_rational_text/2 ]).

% ==========================================================================
% 1. INPUT CONTRACT
%
%   {"kind":"scaled_copy_candidate",
%    "original":{"name":"Rectangle G","sides":[9,12]},
%    "candidate":{"name":"Rectangle N","sides":[14,11]}}
%   {"kind":"figure_scaling",
%    "original":{"name":"ABC","sides":[4,5,7]},"scale_factor":2,
%    "image_name":"DEF"}
%   {"kind":"figure_quotients","figure":{"name":"ABC","sides":[4,5,7]}}
%
% Sides arrive as printed, in any order; the run sorts them before pairing,
% because the page names a rectangle 4 by 3 and another 3 by 6 without meaning
% anything by the order.
% ==========================================================================

g8_scaled_copy_input_contract(
    '{\"kind\":\"scaled_copy_candidate\",\"original\":{\"name\":\"string\",\"sides\":[\"number\"]},\"candidate\":{\"name\":\"string\",\"sides\":[\"number\"]}}',
    '{\"kind\":\"scaled_copy_candidate\",\"original\":{\"name\":\"Rectangle G\",\"sides\":[9,12]},\"candidate\":{\"name\":\"Rectangle N\",\"sides\":[14,11]}}').

g8_scaled_copy_from_json(Dict, candidate(Original, Candidate)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "scaled_copy_candidate"), !,
    get_dict(original, Dict, O), figure_of(O, Original),
    get_dict(candidate, Dict, C), figure_of(C, Candidate),
    Original = figure(_, SidesA), Candidate = figure(_, SidesB),
    length(SidesA, N), length(SidesB, N).
g8_scaled_copy_from_json(Dict, scaling(Original, Factor, ImageName)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "figure_scaling"), !,
    get_dict(original, Dict, O), figure_of(O, Original),
    get_dict(scale_factor, Dict, F0), g8_quantity(F0, Factor), Factor > 0,
    ( get_dict(image_name, Dict, I), string(I) -> ImageName = I
    ; ImageName = "the image" ).
g8_scaled_copy_from_json(Dict, quotients(Figure)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "figure_quotients"),
    get_dict(figure, Dict, F), figure_of(F, Figure).

figure_of(Dict, figure(Name, Sorted)) :-
    ( get_dict(name, Dict, N), string(N) -> Name = N ; Name = "figure" ),
    get_dict(sides, Dict, Raw),
    Raw = [_, _|_],
    maplist(g8_quantity, Raw, Sides),
    forall(member(S, Sides), S > 0),
    msort(Sides, Sorted).

% ==========================================================================
% 2. STATES
% ==========================================================================

g8_scaled_copy_states(
    [ q_read_both_figures,
      q_pair_the_sides_shortest_to_shortest,
      q_divide_each_pair,
      q_accept_one_scale_factor,
      q_name_the_sides_whose_factors_disagree,
      q_multiply_every_side_by_the_factor,
      q_report_the_image_side_lengths,
      q_divide_the_sides_within_one_figure,
      q_report_the_quotients,
      q_add_the_same_amount_to_every_side ]).

% g8_scaled_copy_state_label(State, Tradition, Label, Citation).
g8_scaled_copy_state_label(q_pair_the_sides_shortest_to_shortest,
    illustrative_mathematics,
    "corresponding sides",
    "IM Grade 8 Unit 2 Lesson 1, Projecting and Scaling").
g8_scaled_copy_state_label(q_accept_one_scale_factor,
    illustrative_mathematics,
    "one scale factor takes every side of the original to the copy",
    "IM Grade 8 Unit 2 Lesson 1, Activity 1.3, the scaled copies of Rectangle G").
g8_scaled_copy_state_label(q_accept_one_scale_factor, ccss,
    "two figures are similar if one can be obtained from the other by a sequence of rotations, reflections, translations, and dilations",
    "CCSS 8.G.A.4, via IM Grade 8 Unit 2 Lesson 6").
g8_scaled_copy_state_label(q_divide_the_sides_within_one_figure,
    illustrative_mathematics,
    "the quotient of two side lengths of a triangle does not change under dilation",
    "IM Grade 8 Unit 2 Lesson 9, Side Length Quotients in Similar Triangles").
g8_scaled_copy_state_label(q_name_the_sides_whose_factors_disagree, provisional,
    "the pair of sides whose factors differ",
    "provisional; no community label sourced for naming the disagreeing pair").
g8_scaled_copy_state_label(q_add_the_same_amount_to_every_side,
    research_corpus,
    "scaling read as adding the same amount to each side",
    "research corpus rows 38034 and 38046, additive operations used instead of multiplicative ratios").

% ==========================================================================
% 3. TRANSITIONS
% ==========================================================================

g8_scaled_copy_transition(scaled_copy_test,
    q_read_both_figures, pair_the_sides_shortest_to_shortest,
    q_pair_the_sides_shortest_to_shortest).
g8_scaled_copy_transition(scaled_copy_test,
    q_pair_the_sides_shortest_to_shortest, divide_each_pair, q_divide_each_pair).
g8_scaled_copy_transition(scaled_copy_test,
    q_divide_each_pair, accept_one_scale_factor, q_accept_one_scale_factor).
g8_scaled_copy_transition(scaled_copy_test,
    q_divide_each_pair, name_the_sides_whose_factors_disagree,
    q_name_the_sides_whose_factors_disagree).
g8_scaled_copy_transition(side_lengths_under_a_scale_factor,
    q_read_both_figures, multiply_every_side_by_the_factor,
    q_multiply_every_side_by_the_factor).
g8_scaled_copy_transition(side_lengths_under_a_scale_factor,
    q_multiply_every_side_by_the_factor, report_the_image_side_lengths,
    q_report_the_image_side_lengths).
g8_scaled_copy_transition(quotients_within_a_figure,
    q_read_both_figures, divide_the_sides_within_one_figure,
    q_divide_the_sides_within_one_figure).
g8_scaled_copy_transition(quotients_within_a_figure,
    q_divide_the_sides_within_one_figure, report_the_quotients,
    q_report_the_quotients).
g8_scaled_copy_transition(add_the_same_amount_to_every_side,
    q_read_both_figures, add_the_same_amount_to_every_side,
    q_add_the_same_amount_to_every_side).

% ==========================================================================
% 4. THE RUN
% ==========================================================================

run_g8_scaled_copy(scaled_copy_test,
                   candidate(figure(NameA, SidesA), figure(NameB, SidesB)),
                   Outcome, Trace) :-
    factors_of(SidesA, SidesB, Factors),
    (   one_factor(Factors, Factor)
    ->  maplist([S, T]>>( T is S * Factor ), SidesA, Rebuilt),
        ( Rebuilt == SidesB -> Validity = correct ; Validity = unvindicated ),
        g8_rational_text(Factor, FactorText),
        State = q_accept_one_scale_factor,
        Answer = scaled_copy(NameB, FactorText),
        Step = accept_one_scale_factor(FactorText)
    ;   disagreeing_pair(SidesA, SidesB, Factors, SideA1, SideB1, F1,
                         SideA2, SideB2, F2),
        Validity = correct,
        g8_rational_text(F1, F1Text), g8_rational_text(F2, F2Text),
        g8_rational_text(SideA1, A1), g8_rational_text(SideB1, B1),
        g8_rational_text(SideA2, A2), g8_rational_text(SideB2, B2),
        State = q_name_the_sides_whose_factors_disagree,
        Answer = not_a_scaled_copy(NameB, pair(A1, B1, F1Text),
                                   pair(A2, B2, F2Text)),
        Step = name_the_sides_whose_factors_disagree(F1Text, F2Text)
    ),
    Outcome = action_outcome(
        scaled_copy_test,
        [ classification(productive),
          cluster(g8_dilations_and_similarity),
          automaton_state(State),
          vocabulary([scaled_copy, scale_factor, corresponding_sides,
                      similar_figures]),
          input(candidate(figure(NameA, SidesA), figure(NameB, SidesB))),
          result(Answer),
          expected(Answer),
          factors(Factors),
          invariant(one_factor_multiplies_every_corresponding_side),
          validity(Validity) ]),
    Trace = [ pair_the_sides_shortest_to_shortest(SidesA, SidesB),
              divide_each_pair(Factors),
              Step ].
run_g8_scaled_copy(side_lengths_under_a_scale_factor,
                   scaling(figure(Name, Sides), Factor, ImageName), Outcome,
                   Trace) :-
    maplist([S, T]>>( T is S * Factor ), Sides, Image),
    maplist(g8_rational_text, Image, Texts),
    maplist([T, S]>>( S is T rdiv Factor ), Image, Rebuilt),
    ( Rebuilt == Sides -> Validity = correct ; Validity = unvindicated ),
    g8_rational_text(Factor, FactorText),
    Outcome = action_outcome(
        side_lengths_under_a_scale_factor,
        [ classification(productive),
          cluster(g8_dilations_and_similarity),
          automaton_state(q_report_the_image_side_lengths),
          vocabulary([scale_factor, dilation, side_length, similar_triangles]),
          input(scaling(figure(Name, Sides), Factor, ImageName)),
          result(side_lengths(ImageName, Texts)),
          expected(side_lengths(ImageName, Texts)),
          scale_factor(FactorText),
          invariant(dividing_the_image_by_the_factor_returns_the_original),
          validity(Validity) ]),
    Trace = [ multiply_every_side_by_the_factor(FactorText),
              report_the_image_side_lengths(Texts) ].
run_g8_scaled_copy(quotients_within_a_figure, quotients(figure(Name, Sides)),
                   Outcome, Trace) :-
    Sides = [Short, Medium, Long],
    LongOverShort is Long rdiv Short,
    LongOverMedium is Long rdiv Medium,
    MediumOverShort is Medium rdiv Short,
    maplist(g8_rational_text,
            [LongOverShort, LongOverMedium, MediumOverShort], Texts),
    Outcome = action_outcome(
        quotients_within_a_figure,
        [ classification(productive),
          cluster(g8_dilations_and_similarity),
          automaton_state(q_report_the_quotients),
          vocabulary([quotient, side_length, similar_triangles,
                      scale_factor_cancels]),
          input(quotients(figure(Name, Sides))),
          result(quotients(Name, Texts)),
          expected(quotients(Name, Texts)),
          invariant(the_quotients_do_not_change_under_a_scale_factor),
          validity(correct) ]),
    Trace = [ divide_the_sides_within_one_figure(Texts),
              report_the_quotients(Texts) ].
run_g8_scaled_copy(add_the_same_amount_to_every_side,
                   candidate(figure(NameA, SidesA), figure(NameB, SidesB)),
                   Outcome, Trace) :-
    % The deformation: one number ADDED to every side, where the doing asks
    % for one number multiplying every side.
    differences_of(SidesA, SidesB, Differences),
    one_factor(Differences, Difference),
    \+ ( factors_of(SidesA, SidesB, Factors), one_factor(Factors, _) ),
    g8_rational_text(Difference, DifferenceText),
    Outcome = action_outcome(
        add_the_same_amount_to_every_side,
        [ classification(deformation),
          cluster(g8_dilations_and_similarity),
          automaton_state(q_add_the_same_amount_to_every_side),
          vocabulary([scaled_copy, difference, scale_factor]),
          input(candidate(figure(NameA, SidesA), figure(NameB, SidesB))),
          result(scaled_copy_claimed(NameB, DifferenceText)),
          expected(not_a_scaled_copy(NameB)),
          deforms(scaled_copy_test),
          attested_by('research corpus rows 38034 and 38046'),
          validity(incorrect) ]),
    Trace = [ add_the_same_amount_to_every_side(DifferenceText) ].

factors_of([], [], []).
factors_of([A|As], [B|Bs], [F|Fs]) :-
    A =\= 0, F is B rdiv A,
    factors_of(As, Bs, Fs).

differences_of([], [], []).
differences_of([A|As], [B|Bs], [D|Ds]) :-
    D is B - A,
    differences_of(As, Bs, Ds).

one_factor([F|Rest], F) :-
    forall(member(G, Rest), G =:= F).

disagreeing_pair(SidesA, SidesB, Factors, A1, B1, F1, A2, B2, F2) :-
    Factors = [F1|_], SidesA = [A1|_], SidesB = [B1|_],
    nth0(Index, Factors, F2), F2 =\= F1,
    nth0(Index, SidesA, A2), nth0(Index, SidesB, B2),
    !.

% ==========================================================================
% 5. SELF-SUMMARY
% ==========================================================================

g8_scaled_copy_summary(
    summary{ module: g8_scaled_copy_and_similar_sides,
             status: draft_for_quarantine,
             generated: false,
             grade: 8,
             cluster: g8_dilations_and_similarity,
             doings: [ scaled_copy_test,
                       side_lengths_under_a_scale_factor,
                       quotients_within_a_figure,
                       add_the_same_amount_to_every_side ],
             verification:
                 [one_factor_multiplies_every_corresponding_side,
                  dividing_the_image_by_the_factor_returns_the_original,
                  the_quotients_do_not_change_under_a_scale_factor],
             arithmetic: exact_rational,
             beside: g8_plane_transformation,
             deformation_partners: [add_the_same_amount_to_every_side],
             imported_by: none }).

% ==========================================================================
% 6. RECEIPTS
%
% g8_scaled_copy_receipt(Correction, Lesson, Doing, Json, Expected).
% ==========================================================================

% correction 62, IM-G8-U2-L1: the six candidates against Rectangle G, 9 by 12
g8_scaled_copy_receipt(62, 'IM-G8-U2-L1', scaled_copy_test,
    _{kind: "scaled_copy_candidate",
      original: _{name: "Rectangle G", sides: [9, 12]},
      candidate: _{name: "H", sides: [4, 3]}},
    scaled_copy("H", "1/3")).
g8_scaled_copy_receipt(62, 'IM-G8-U2-L1', scaled_copy_test,
    _{kind: "scaled_copy_candidate",
      original: _{name: "Rectangle G", sides: [9, 12]},
      candidate: _{name: "J", sides: [6, 8]}},
    scaled_copy("J", "2/3")).
g8_scaled_copy_receipt(62, 'IM-G8-U2-L1', scaled_copy_test,
    _{kind: "scaled_copy_candidate",
      original: _{name: "Rectangle G", sides: [9, 12]},
      candidate: _{name: "K", sides: [3, 6]}},
    not_a_scaled_copy("K", pair("9", "3", "1/3"), pair("12", "6", "1/2"))).
g8_scaled_copy_receipt(62, 'IM-G8-U2-L1', scaled_copy_test,
    _{kind: "scaled_copy_candidate",
      original: _{name: "Rectangle G", sides: [9, 12]},
      candidate: _{name: "L", sides: [1, _{n: 3, d: 4}]}},
    scaled_copy("L", "1/12")).
g8_scaled_copy_receipt(62, 'IM-G8-U2-L1', scaled_copy_test,
    _{kind: "scaled_copy_candidate",
      original: _{name: "Rectangle G", sides: [9, 12]},
      candidate: _{name: "M", sides: [27, 36]}},
    scaled_copy("M", "3")).
g8_scaled_copy_receipt(62, 'IM-G8-U2-L1', scaled_copy_test,
    _{kind: "scaled_copy_candidate",
      original: _{name: "Rectangle G", sides: [9, 12]},
      candidate: _{name: "N", sides: [14, 11]}},
    not_a_scaled_copy("N", pair("9", "11", "11/9"), pair("12", "14", "7/6"))).
% correction 62 read through the deformation: N is 9 plus 2 and 12 plus 2
g8_scaled_copy_receipt(62, 'IM-G8-U2-L1', add_the_same_amount_to_every_side,
    _{kind: "scaled_copy_candidate",
      original: _{name: "Rectangle G", sides: [9, 12]},
      candidate: _{name: "N", sides: [14, 11]}},
    scaled_copy_claimed("N", "2")).
% correction 113, IM-G8-U2-L9: triangle ABC with sides 4, 5, 7 scaled by 2
g8_scaled_copy_receipt(113, 'IM-G8-U2-L9', side_lengths_under_a_scale_factor,
    _{kind: "figure_scaling",
      original: _{name: "ABC", sides: [4, 5, 7]}, scale_factor: 2,
      image_name: "DEF"},
    side_lengths("DEF", ["8", "10", "14"])).
% correction 113: scaled by 3
g8_scaled_copy_receipt(113, 'IM-G8-U2-L9', side_lengths_under_a_scale_factor,
    _{kind: "figure_scaling",
      original: _{name: "ABC", sides: [4, 5, 7]}, scale_factor: 3,
      image_name: "GHI"},
    side_lengths("GHI", ["12", "15", "21"])).
% correction 113: scaled by 1/2
g8_scaled_copy_receipt(113, 'IM-G8-U2-L9', side_lengths_under_a_scale_factor,
    _{kind: "figure_scaling",
      original: _{name: "ABC", sides: [4, 5, 7]},
      scale_factor: _{n: 1, d: 2}, image_name: "JKL"},
    side_lengths("JKL", ["2", "5/2", "7/2"])).
% correction 113: the printed quotient row for ABC, 7/4, 7/5 and 5/4
g8_scaled_copy_receipt(113, 'IM-G8-U2-L9', quotients_within_a_figure,
    _{kind: "figure_quotients", figure: _{name: "ABC", sides: [4, 5, 7]}},
    quotients("ABC", ["7/4", "7/5", "5/4"])).
% correction 113: the same quotients for the triangle scaled by 3
g8_scaled_copy_receipt(113, 'IM-G8-U2-L9', quotients_within_a_figure,
    _{kind: "figure_quotients", figure: _{name: "GHI", sides: [12, 15, 21]}},
    quotients("GHI", ["7/4", "7/5", "5/4"])).

% ==========================================================================
% 7. CHECK
% ==========================================================================

check_g8_scaled_copy_and_similar_sides :-
    check_receipts,
    check_the_quotients_repeat_across_all_four_triangles,
    check_negative,
    format('g8_scaled_copy_and_similar_sides: all checks ok~n').

check_receipts :-
    findall(Correction-Doing-Result,
            ( g8_scaled_copy_receipt(Correction, _, Doing, Json, Expected),
              g8_scaled_copy_from_json(Json, Figure),
              run_g8_scaled_copy(Doing, Figure, Outcome, _),
              outcome_property(Outcome, result(Result)),
              Result = Expected
            ), Rows),
    findall(C, g8_scaled_copy_receipt(C, _, _, _, _), All),
    length(All, Total), length(Rows, Passed),
    Total =:= Passed,
    format('  receipts: ~w/~w printed figures run~n', [Passed, Total]),
    forall(member(Correction-Doing-Result, Rows),
           format('    correction ~w  ~w -> ~q~n',
                  [Correction, Doing, Result])).

check_the_quotients_repeat_across_all_four_triangles :-
    % Correction 113's whole point: the three quotients are the same for ABC
    % and for all three of its scaled copies.
    findall(Texts,
            ( member(Sides, [[4, 5, 7], [8, 10, 14], [12, 15, 21],
                             [2, 2.5, 3.5]]),
              g8_scaled_copy_from_json(
                  _{kind: "figure_quotients",
                    figure: _{name: "triangle", sides: Sides}}, Figure),
              run_g8_scaled_copy(quotients_within_a_figure, Figure, Outcome, _),
              outcome_property(Outcome, result(quotients(_, Texts)))
            ), AllQuotients),
    sort(AllQuotients, [["7/4", "7/5", "5/4"]]),
    format('  the four triangles of correction 113 all return the quotients 7/4, 7/5 and 5/4~n').

check_negative :-
    % Figures with different numbers of sides are refused at decode.
    \+ g8_scaled_copy_from_json(
           _{kind: "scaled_copy_candidate",
             original: _{name: "G", sides: [9, 12]},
             candidate: _{name: "T", sides: [3, 4, 5]}}, _),
    % A side of zero is refused at decode.
    \+ g8_scaled_copy_from_json(
           _{kind: "scaled_copy_candidate",
             original: _{name: "G", sides: [9, 0]},
             candidate: _{name: "T", sides: [3, 4]}}, _),
    % A genuine scaled copy carries no additive reading to deform.
    g8_scaled_copy_from_json(
        _{kind: "scaled_copy_candidate",
          original: _{name: "Rectangle G", sides: [9, 12]},
          candidate: _{name: "M", sides: [27, 36]}}, Genuine),
    \+ run_g8_scaled_copy(add_the_same_amount_to_every_side, Genuine, _, _),
    format('  negative tests: unequal side counts and a zero side refuse at decode; a genuine copy carries no additive reading~n').

outcome_property(action_outcome(_, Props), Property) :-
    memberchk(Property, Props).
