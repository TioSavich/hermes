/** <module> attested_representation_objects
 *
 * GENERATED, additive metavocabulary over the REALLMs figure corpus.
 * Do NOT hand-edit; regenerate from docling_classifications.json.
 *
 * This layer aggregates the per-figure ground facts
 * (curriculum/im/docling_figures_interpreted.pl) up to the
 * language / spatial-object / domain level. It is a corpus-attested
 * companion to knowledge/strategies/render/representation_grammar.pl's
 * representation_object/2 -- it never edits that grammar, and it is honest
 * about gaps in both directions.
 *
 * Membership: figures REALLMs flagged as student work
 * (has_handwriting_or_student_work = true), the same membership rule the
 * per-figure file uses.
 *
 * Facts:
 *   attested_representation_object(Language, SpatialObject, FigureCount,
 *       DomainList, ExampleFigures)
 *     -- DomainList: article-level domains (descending corpus frequency)
 *     -- ExampleFigures: up to 3 tag(BibtexKey, Basename) witnesses
 *
 *   proposed_representation_object(Language, Object, FigureCount,
 *       attested_not_in_grammar)
 *     -- a (Language, Object) the corpus attests that representation_object/2
 *        does not list. A candidate to add to the grammar, NOT an assertion
 *        that the grammar is wrong.
 *
 *   grammar_object_unattested(Language, Object)
 *     -- a representation_object/2 entry with zero student-work attestation in
 *        this corpus. Honest gap: the grammar licenses it; the corpus has not
 *        (yet) shown a student-work instance.
 *
 * Counts and coverage are reported in the harness, not asserted in prose here.
 */
:- module(attested_objects,
          [ attested_representation_object/5,
            proposed_representation_object/4,
            grammar_object_unattested/2 ]).

% --- attested objects (corpus-aggregated) ---
attested_representation_object(area_model, partition, 170, [fraction, measurement, algebraic, whole_number, geometric, proportional, decimal, rational, percent, combinatorial, ratio, other, probability, statistics], [tag('ESM_Arcavi_2003_Role', 'p20_1.png'), tag('ESM_Baturo_1996_Student', 'p20_1.png'), tag('ESM_Brink_1993_Different', 'p2_1.png')]).
attested_representation_object(fraction_bars, partition, 159, [fraction, algebraic, proportional, whole_number, measurement, rational, decimal, combinatorial, geometric, other, ratio, percent, statistics, calculus], [tag('ESM_Boaler_1993_Encouraging', 'p24_2.png'), tag('ESM_Brizuela_2005_Young', 'p11_1.png'), tag('ESM_Brizuela_2005_Young', 'p14_1.png')]).
attested_representation_object(number_line, axis, 144, [algebraic, whole_number, fraction, proportional, measurement, other, ratio, decimal, calculus, integer, percent, combinatorial, statistics, rational], [tag('ESM_Bakker_2006_Historical', 'p15_1.png'), tag('ESM_Bakker_2006_Historical', 'p10_1.png'), tag('ESM_Baruk_1987_Realite', 'p6_1.png')]).
attested_representation_object(fraction_bars, equal_part, 123, [fraction, algebraic, proportional, whole_number, measurement, decimal, rational, geometric, other, combinatorial, percent, ratio, calculus], [tag('ESM_Boaler_1993_Encouraging', 'p24_2.png'), tag('ESM_Brizuela_2005_Young', 'p14_1.png'), tag('ESM_Brizuela_2005_Young', 'p16_1.png')]).
attested_representation_object(set_grouping, counter, 120, [whole_number, fraction, algebraic, proportional, measurement, other, ratio, geometric, probability, integer, combinatorial, percent, statistics, decimal, rational], [tag('ESM_Abele_1978_Usage', 'p3_1.png'), tag('ESM_Caglayan_2010_Eighth', 'p9_1.png'), tag('ESM_Caglayan_2010_Eighth', 'p10_1.png')]).
attested_representation_object(number_line, jump, 109, [whole_number, algebraic, proportional, measurement, fraction, ratio, decimal, other, integer, calculus, combinatorial, statistics, percent], [tag('ESM_Bakker_2006_Historical', 'p15_1.png'), tag('ESM_Bakker_2006_Historical', 'p10_1.png'), tag('ESM_Bishop_2014_Using', 'p15_1.png')]).
attested_representation_object(area_model, equal_part, 77, [fraction, measurement, algebraic, geometric, proportional, whole_number, decimal, rational, combinatorial, percent, ratio], [tag('ESM_Brink_1993_Different', 'p2_1.png'), tag('ESM_Cadez_2018_How', 'p11_2.png'), tag('ESM_Brizuela_2005_Young', 'p15_2.png')]).
attested_representation_object(number_line, partition, 31, [fraction, algebraic, proportional, decimal, measurement, ratio, whole_number, percent, rational, integer, calculus, other], [tag('ESM_Heuvelpanhuizen_2003_Didactical', 'p14_1.png'), tag('ESM_Heuvelpanhuizen_2003_Didactical', 'p15_1.png'), tag('ESM_Heuvelpanhuizen_2003_Didactical', 'p15_2.png')]).
attested_representation_object(base_ten_blocks, ten_rod, 30, [whole_number, algebraic, fraction, measurement, geometric, rational, decimal, calculus, combinatorial, statistics, proportional], [tag('ESM_Bednarz_1982_Understanding', 'p19_1.png'), tag('ESM_Bednarz_1982_Understanding', 'p20_1.png'), tag('ESM_Font_2013_Emergence', 'p9_1.png')]).
attested_representation_object(base_ten_blocks, unit_cube, 28, [whole_number, algebraic, fraction, geometric, measurement, rational, decimal, calculus, combinatorial, statistics, probability, proportional], [tag('ESM_Bednarz_1982_Understanding', 'p19_1.png'), tag('ESM_Bednarz_1982_Understanding', 'p20_1.png'), tag('ESM_Font_2013_Emergence', 'p9_1.png')]).
attested_representation_object(set_grouping, partition, 27, [fraction, algebraic, whole_number, combinatorial, measurement, integer, probability, proportional, decimal, other], [tag('ESM_Abele_1978_Usage', 'p8_1.png'), tag('ESM_Bock_1998_Predominance', 'p9_1.png'), tag('ESM_Empson_2005_Fractions', 'p11_1.png')]).
attested_representation_object(place_value_chart, digit_column, 12, [whole_number, fraction, algebraic, geometric, probability, other], [tag('ESM_Son_2016_Moving', 'p17_1.png'), tag('JMB_Ho_2014_Model', 'p9_1.png'), tag('JMB_Neuberger_2012_Benefits', 'p12_2.png')]).
attested_representation_object(place_value_chart, ten_rod, 4, [whole_number, fraction], [tag('ESM_Son_2016_Moving', 'p17_1.png'), tag('JMB_Neuberger_2012_Benefits', 'p12_2.png'), tag('ZDM_Gellert_2014_Students', 'p8_1.png')]).
attested_representation_object(base_ten_blocks, digit_column, 3, [whole_number, measurement], [tag('ESM_Son_2016_Moving', 'p22_1.png'), tag('JMB_Superfine_2009_Translation', 'p12_1.png'), tag('ZDM_Rivera_2014_From', 'p9_1.png')]).
attested_representation_object(number_line, counter, 3, [decimal, fraction], [tag('JMB_Widjaja_2011_Locating', 'p6_1.png'), tag('JMB_Widjaja_2011_Locating', 'p7_1.png'), tag('MERJ_Zhang_2015_Enriching', 'p18_2.png')]).
attested_representation_object(place_value_chart, unit_cube, 3, [whole_number], [tag('ESM_Son_2016_Moving', 'p17_1.png'), tag('ZDM_Gellert_2014_Students', 'p8_1.png'), tag('ZDM_Rivera_2014_From', 'p13_3.png')]).
attested_representation_object(set_grouping, digit_column, 3, [whole_number, decimal, fraction, integer], [tag('JMB_Ding_2013_Preservice', 'p10_1.png'), tag('MTL_Whitenack_2001_Coordinating', 'p22_1.png'), tag('RME_OReilly_1999_Students\'', 'p10_1.png')]).
attested_representation_object(balance_scale, weight, 2, [fraction, algebraic, proportional], [tag('JMB_Olive_2006_Making', 'p16_1.png'), tag('JMB_Ramful_2008_Reversibility', 'p13_1.png')]).
attested_representation_object(base_ten_blocks, partition, 2, [algebraic, fraction, whole_number], [tag('ESM_Peck_2016_Reinventing', 'p11_1.png'), tag('ZDM_Gellert_2014_Students', 'p7_1.png')]).
attested_representation_object(set_grouping, axis, 2, [fraction, probability], [tag('JMTE_Lo_2012_Prospective', 'p15_1.png'), tag('JRME_English_2016_Development', 'p18_1.png')]).
attested_representation_object(set_grouping, ten_frame, 2, [fraction, measurement, whole_number], [tag('ESM_Pirie_1992_Creating', 'p16_1.png'), tag('JMB_Superfine_2009_Translation', 'p11_1.png')]).
attested_representation_object(area_model, axis, 1, [fraction], [tag('JMB_Lin_2013_Enhancing', 'p14_1.png')]).
attested_representation_object(area_model, counter, 1, [whole_number], [tag('JRME_Bray_2011_Collective', 'p19_1.png')]).
attested_representation_object(area_model, unit_cube, 1, [algebraic, geometric], [tag('MERJ_Hallagan_2006_Case', 'p13_1.png')]).
attested_representation_object(balance_scale, axis, 1, [algebraic, proportional], [tag('JMB_Ramful_2008_Reversibility', 'p13_1.png')]).
attested_representation_object(balance_scale, pan, 1, [fraction], [tag('JMB_Olive_2006_Making', 'p16_1.png')]).
attested_representation_object(base_ten_blocks, axis, 1, [algebraic], [tag('JMTE_Caglayan_2013_Prospective', 'p13_1.png')]).
attested_representation_object(base_ten_blocks, counter, 1, [whole_number], [tag('MTL_Whitenack_2001_Coordinating', 'p24_1.png')]).
attested_representation_object(base_ten_blocks, hundred_flat, 1, [whole_number], [tag('JMB_Lee_2007_Making', 'p8_1.png')]).
attested_representation_object(base_ten_blocks, ten_frame, 1, [measurement, whole_number], [tag('JMB_Superfine_2009_Translation', 'p12_1.png')]).
attested_representation_object(number_line, ten_rod, 1, [fraction, proportional], [tag('JMTE_Orrill_2012_Making', 'p18_1.png')]).
attested_representation_object(place_value_chart, counter, 1, [whole_number], [tag('ZDM_Rivera_2014_From', 'p16_1.png')]).
attested_representation_object(place_value_chart, hundred_flat, 1, [whole_number], [tag('ZDM_Rivera_2014_From', 'p13_3.png')]).
attested_representation_object(place_value_chart, partition, 1, [fraction], [tag('JRME_Lamon_1996_Development', 'p19_1.png')]).

% --- gap (a): corpus-attested objects absent from representation_object/2 ---
proposed_representation_object(fraction_bars, partition, 159, attested_not_in_grammar).
proposed_representation_object(area_model, equal_part, 77, attested_not_in_grammar).
proposed_representation_object(number_line, partition, 31, attested_not_in_grammar).
proposed_representation_object(set_grouping, partition, 27, attested_not_in_grammar).
proposed_representation_object(place_value_chart, ten_rod, 4, attested_not_in_grammar).
proposed_representation_object(base_ten_blocks, digit_column, 3, attested_not_in_grammar).
proposed_representation_object(number_line, counter, 3, attested_not_in_grammar).
proposed_representation_object(place_value_chart, unit_cube, 3, attested_not_in_grammar).
proposed_representation_object(set_grouping, digit_column, 3, attested_not_in_grammar).
proposed_representation_object(base_ten_blocks, partition, 2, attested_not_in_grammar).
proposed_representation_object(set_grouping, axis, 2, attested_not_in_grammar).
proposed_representation_object(area_model, axis, 1, attested_not_in_grammar).
proposed_representation_object(area_model, counter, 1, attested_not_in_grammar).
proposed_representation_object(area_model, unit_cube, 1, attested_not_in_grammar).
proposed_representation_object(balance_scale, axis, 1, attested_not_in_grammar).
proposed_representation_object(base_ten_blocks, axis, 1, attested_not_in_grammar).
proposed_representation_object(base_ten_blocks, counter, 1, attested_not_in_grammar).
proposed_representation_object(base_ten_blocks, ten_frame, 1, attested_not_in_grammar).
proposed_representation_object(number_line, ten_rod, 1, attested_not_in_grammar).
proposed_representation_object(place_value_chart, counter, 1, attested_not_in_grammar).
proposed_representation_object(place_value_chart, hundred_flat, 1, attested_not_in_grammar).
proposed_representation_object(place_value_chart, partition, 1, attested_not_in_grammar).

% --- gap (b): representation_object/2 entries with zero student-work attestation ---
grammar_object_unattested(area_model, array_cell).
grammar_object_unattested(area_model, overlap_rectangle).
grammar_object_unattested(area_model, unit_square).
grammar_object_unattested(balance_scale, preserving_move).
grammar_object_unattested(base_ten_blocks, thousand_cube).
grammar_object_unattested(fraction_bars, common_unit).
grammar_object_unattested(fraction_bars, iterated_part).
grammar_object_unattested(fraction_bars, whole_bar).
grammar_object_unattested(number_line, benchmark).
grammar_object_unattested(number_line, scale_break).
grammar_object_unattested(number_line, segment).
grammar_object_unattested(place_value_chart, named_place).
grammar_object_unattested(place_value_chart, regrouping_arrow).
grammar_object_unattested(set_grouping, five_frame).
grammar_object_unattested(set_grouping, pair).

