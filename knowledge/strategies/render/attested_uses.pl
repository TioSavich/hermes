/** <module> attested_representation_use
 *
 * Corpus-attested metavocabulary over the logical grammar in
 * knowledge/strategies/render/representation_grammar.pl. ADDITIVE: it records what each
 * representational language is USED TO DO in the student-work figure corpus,
 * generalized to the (language, domain, use_pattern) level. It does not edit
 * or override the grammar.
 *
 * Source: REALLMs figure classifications, joined to article domains, surfaced as
 *   curriculum/im/docling_figures_interpreted.pl  (docling_figure_rich/8).
 * Generalization: per-figure student_strategy_description + transcribed math are
 *   abstracted into a SMALL controlled vocabulary of use patterns (a denotation
 *   verb), then counted per (language, domain). One fact per
 *   (language, domain, use_pattern), NOT one per figure.
 *
 * Honesty: "none" is the REALLMs label for a figure with no recognized spatial
 * representation language (symbolic algebra, calculus, column arithmetic). The
 * grammar has no representation_language(none); those use patterns are real in
 * the corpus but the grammar cannot denote them. They are recorded under
 * language=none and flagged by denotation_gap/3.
 *
 * Predicates:
 *   attested_use_pattern(UsePattern, Gloss)
 *     - the controlled vocabulary, with a one-line gloss.
 *   attested_representation_use(Language, Domain, UsePattern, FigureCount, Examples)
 *     - per (language, domain) use pattern with corpus support and example figures.
 *   use_pattern_denotes(UsePattern, GrammarTask)
 *     - join to representation_grammar scene_denotes/render_spec_denotes task terms,
 *       where a spatial use pattern maps to something the grammar can denote.
 *   denotation_gap(Language, UsePattern, FigureCount)
 *     - a use pattern the grammar cannot denote (no render_spec / no language).
 *
 * GENERATED FILE -- regenerate, do not hand-edit.
 */
:- module(attested_uses,
          [ attested_use_pattern/2,
            attested_representation_use/5,
            use_pattern_denotes/2,
            denotation_gap/3 ]).

% --- controlled vocabulary of use patterns ------------------------------
% (UsePattern, one-line gloss). 31 patterns, generalized from the corpus.
attested_use_pattern(area_model_for_fraction, 'use an area / region model for a fraction or fraction product').
attested_use_pattern(area_model_for_measurement, 'use an area model for area / tiling measurement').
attested_use_pattern(area_model_for_multiplication, 'use an array / area model for whole-number multiplication').
attested_use_pattern(balance_for_equation, 'use a balance to preserve an equation').
attested_use_pattern(bar_model_for_multiplicative_reasoning, 'use a tape / bar model for multiplicative reasoning').
attested_use_pattern(base_ten_blocks_for_place_value, 'build a number from base-ten blocks (place value)').
attested_use_pattern(base_ten_blocks_for_regrouping, 'regroup base-ten blocks for addition / subtraction').
attested_use_pattern(compute_with_written_algorithm, 'compute with a written column / long-division algorithm').
attested_use_pattern(count_collection_with_counters, 'count a discrete collection with counters/tallies').
attested_use_pattern(cross_multiply_proportion, 'cross-multiply or compute a unit rate symbolically').
attested_use_pattern(double_number_line_for_proportion, 'use a double number line for proportion / rate / percent').
attested_use_pattern(enumerate_combinations, 'enumerate combinations / partitions that meet a target').
attested_use_pattern(equal_groups_for_multiplication, 'arrange equal groups to denote multiplication').
attested_use_pattern(evaluate_expression_symbolically, 'evaluate / simplify an expression, order of operations').
attested_use_pattern(group_for_division_or_sharing, 'partition a collection for division / fair sharing').
attested_use_pattern(manipulate_algebraic_expression, 'factor / expand / distribute an algebraic expression').
attested_use_pattern(manipulate_symbolic_notation, 'manipulate symbolic notation (no spatial model)').
attested_use_pattern(mark_intervals_on_number_line, 'mark intervals / points / a timeline on a number line').
attested_use_pattern(number_line_jumps_for_arithmetic, 'jump on a number line to add or subtract').
attested_use_pattern(one_to_one_correspondence, 'connect two sets element by element').
attested_use_pattern(partition_for_fraction_comparison, 'partition to compare two fractions').
attested_use_pattern(partition_region_into_sections, 'partition a region into sections (unequal or unlabeled)').
attested_use_pattern(partition_whole_into_equal_parts, 'partition a whole into equal parts to name a fraction').
attested_use_pattern(place_value_chart_for_columns, 'organize digits in a place-value chart with regrouping').
attested_use_pattern(pose_or_solve_word_problem, 'pose or solve a word problem in prose + arithmetic').
attested_use_pattern(represent_quantity_spatially, 'represent a quantity spatially without a more specific verb').
attested_use_pattern(shade_part_to_name_fraction, 'shade part of a whole to name a fraction').
attested_use_pattern(sketch_graph_on_axes, 'sketch a function / graph on coordinate axes').
attested_use_pattern(solve_equation_symbolically, 'solve an equation symbolically (zero-product, roots)').
attested_use_pattern(subitize_or_make_ten, 'perceive small quantities or compose ten on a frame').
attested_use_pattern(symbolic_calculus_argument, 'argue about limits / derivatives / convergence symbolically').

% --- join to the grammar denotation vocabulary --------------------------
% use_pattern_denotes(UsePattern, GrammarTask): GrammarTask is a task term the
% grammar can denote via scene_denotes/2 or render_spec_denotes/3. Patterns
% absent here are denotation gaps (see denotation_gap/3).
use_pattern_denotes(area_model_for_fraction, fraction_product(_, _, _, _)).
use_pattern_denotes(area_model_for_multiplication, multiplication(_, _)).
use_pattern_denotes(balance_for_equation, equation(linear(_, _, _))).
use_pattern_denotes(base_ten_blocks_for_place_value, whole_number(_)).
use_pattern_denotes(base_ten_blocks_for_regrouping, whole_number_subtraction(_, _)).
use_pattern_denotes(count_collection_with_counters, whole_number(_)).
use_pattern_denotes(equal_groups_for_multiplication, multiplication(_, _)).
use_pattern_denotes(number_line_jumps_for_arithmetic, whole_number_addition(_, _)).
use_pattern_denotes(partition_whole_into_equal_parts, fraction(_, _)).
use_pattern_denotes(place_value_chart_for_columns, whole_number_addition(_, _)).
use_pattern_denotes(shade_part_to_name_fraction, fraction(_, _)).
use_pattern_denotes(subitize_or_make_ten, subitizing(_)).

% --- attested uses: (Language, Domain, UsePattern, FigureCount, Examples) 
% One fact per language-domain-pattern cell. Examples = up to 3 figure ids
% (article/png) drawn from that cell.
attested_representation_use(area_model, algebraic, partition_region_into_sections, 6, ['ESM_Hewitt_2012_Young/p17_2.png', 'JMTE_Cai_2017_Mathematical/p15_1.png', 'JRME_Ellis_2011_Generalizing-promoting/p14_1.png']).
attested_representation_use(area_model, algebraic, area_model_for_fraction, 5, ['ESM_Arcavi_2003_Role/p20_1.png', 'ESM_Brink_1993_Different/p2_1.png', 'IJSME_Ferrara_2014_How/p14_1.png']).
attested_representation_use(area_model, algebraic, bar_model_for_multiplicative_reasoning, 4, ['JMB_Ho_2014_Model/p6_1.png', 'JRME_Ng_2009_Model/p20_1.png', 'JRME_Ng_2009_Model/p27_1.png']).
attested_representation_use(area_model, algebraic, area_model_for_multiplication, 3, ['IJMEST_Koban_2015_Consequences/p16_1.png', 'JMTE_Caglayan_2013_Prospective/p12_2.png', 'MERJ_Hallagan_2006_Case/p16_1.png']).
attested_representation_use(area_model, algebraic, partition_whole_into_equal_parts, 3, ['ESM_Hackenberg_2016_Students''/p14_1.png', 'FLM_Watson_1988_Three/p7_1.png', 'JMB_Hackenberg_2013_Fractional/p12_1.png']).
attested_representation_use(area_model, algebraic, area_model_for_measurement, 1, ['ZDM_Depaepe_2010_Teachers''/p11_2.png']).
attested_representation_use(area_model, algebraic, shade_part_to_name_fraction, 1, ['JMB_Hackenberg_2013_Fractional/p12_2.png']).
attested_representation_use(area_model, combinatorial, partition_whole_into_equal_parts, 1, ['JMB_Hackenberg_2013_Fractional/p12_1.png']).
attested_representation_use(area_model, combinatorial, shade_part_to_name_fraction, 1, ['JMB_Hackenberg_2013_Fractional/p12_2.png']).
attested_representation_use(area_model, decimal, area_model_for_fraction, 4, ['ESM_Moskal_2000_Making/p10_1.png', 'JMB_Singer_2008_Between/p12_2.png', 'JMB_Singer_2008_Between/p13_1.png']).
attested_representation_use(area_model, decimal, partition_whole_into_equal_parts, 2, ['ZDM_Sembiring_2008_Reforming/p10_1.png', 'ZDM_Sembiring_2008_Reforming/p12_2.png']).
attested_representation_use(area_model, decimal, partition_region_into_sections, 1, ['JMTE_Cai_2017_Mathematical/p15_1.png']).
attested_representation_use(area_model, fraction, partition_whole_into_equal_parts, 48, ['ESM_Brizuela_2005_Young/p15_2.png', 'ESM_Cadez_2018_How/p17_1.png', 'ESM_Hackenberg_2016_Students''/p14_1.png']).
attested_representation_use(area_model, fraction, shade_part_to_name_fraction, 20, ['ESM_Cadez_2018_How/p11_2.png', 'ESM_Cadez_2018_How/p12_1.png', 'ESM_Cadez_2018_How/p14_2.png']).
attested_representation_use(area_model, fraction, area_model_for_fraction, 8, ['ESM_Glade_2017_Students''/p12_1.png', 'ESM_Pirie_1992_Creating/p8_1.png', 'IJMEST_Alenazi_2016_Examining/p17_2.png']).
attested_representation_use(area_model, fraction, area_model_for_multiplication, 5, ['ESM_Pirie_1992_Creating/p17_1.png', 'JMB_Osana_2011_Obstacles/p14_1.png', 'JMB_Webel_2016_Meaning/p10_2.png']).
attested_representation_use(area_model, fraction, bar_model_for_multiplicative_reasoning, 2, ['JRME_Ng_2009_Model/p20_1.png', 'JRME_Ng_2009_Model/p27_1.png']).
attested_representation_use(area_model, fraction, partition_for_fraction_comparison, 2, ['JMTE_Ryken_2009_Multiple/p11_1.png', 'JRME_Norton_2018_Brief/p10_1.png']).
attested_representation_use(area_model, fraction, partition_region_into_sections, 2, ['ESM_Cadez_2018_How/p14_1.png', 'IJMEST_Alenazi_2016_Examining/p17_1.png']).
attested_representation_use(area_model, geometric, area_model_for_fraction, 6, ['ESM_Arcavi_2003_Role/p20_1.png', 'ESM_Brink_1993_Different/p2_1.png', 'ESM_Douady_1989_Un/p21_1.png']).
attested_representation_use(area_model, geometric, partition_region_into_sections, 6, ['JMTE_Cai_2017_Mathematical/p15_1.png', 'JRME_Ellis_2011_Generalizing-promoting/p14_1.png', 'JRME_Lo_1997_Developing/p18_1.png']).
attested_representation_use(area_model, geometric, area_model_for_multiplication, 2, ['ESM_Baturo_1996_Student/p20_1.png', 'MERJ_Hallagan_2006_Case/p16_1.png']).
attested_representation_use(area_model, geometric, shade_part_to_name_fraction, 2, ['ESM_Hasemann_1995_Concept/p12_1.png', 'ESM_Hasemann_1995_Concept/p13_1.png']).
attested_representation_use(area_model, geometric, area_model_for_measurement, 1, ['JMTE_Baxter_2010_Social/p12_1.png']).
attested_representation_use(area_model, geometric, partition_whole_into_equal_parts, 1, ['ESM_Hasemann_1995_Concept/p9_1.png']).
attested_representation_use(area_model, measurement, area_model_for_multiplication, 13, ['ESM_Baturo_1996_Student/p20_1.png', 'JMB_Wickstrom_2017_Pre-service/p10_2.png', 'JMB_Wickstrom_2017_Pre-service/p12_1.png']).
attested_representation_use(area_model, measurement, area_model_for_measurement, 11, ['JMB_Wickstrom_2017_Pre-service/p10_3.png', 'JMB_Wickstrom_2017_Pre-service/p11_1.png', 'JMB_Wickstrom_2017_Pre-service/p12_2.png']).
attested_representation_use(area_model, measurement, area_model_for_fraction, 9, ['ESM_Douady_1989_Un/p21_1.png', 'JMB_Wickstrom_2017_Pre-service/p13_2.png', 'JMB_Wickstrom_2017_Pre-service/p9_1.png']).
attested_representation_use(area_model, measurement, partition_region_into_sections, 3, ['JMTE_Boote_2018_Abc/p15_1.png', 'JRME_Lo_1997_Developing/p18_1.png', 'JRME_Moore_2014_Quantitative/p23_2.png']).
attested_representation_use(area_model, measurement, partition_whole_into_equal_parts, 3, ['JMB_Hackenberg_2013_Fractional/p12_1.png', 'ZDM_Sembiring_2008_Reforming/p10_1.png', 'ZDM_Sembiring_2008_Reforming/p12_2.png']).
attested_representation_use(area_model, measurement, shade_part_to_name_fraction, 1, ['JMB_Hackenberg_2013_Fractional/p12_2.png']).
attested_representation_use(area_model, other, area_model_for_measurement, 1, ['ZDM_Depaepe_2010_Teachers''/p11_2.png']).
attested_representation_use(area_model, percent, area_model_for_fraction, 1, ['ESM_Heuvelpanhuizen_1994_Improvement/p29_1.png']).
attested_representation_use(area_model, percent, area_model_for_measurement, 1, ['JMTE_Baxter_2010_Social/p12_1.png']).
attested_representation_use(area_model, percent, shade_part_to_name_fraction, 1, ['MERJ_Wright_2014_Frequencies/p21_2.png']).
attested_representation_use(area_model, probability, area_model_for_fraction, 1, ['ZDM_Pfannkuch_2012_Conceptual/p7_1.png']).
attested_representation_use(area_model, proportional, area_model_for_fraction, 4, ['JMB_diSessa_1991_Inventing/p14_1.png', 'JMTE_Boote_2018_Abc/p12_1.png', 'JMTE_Orrill_2012_Making/p12_1.png']).
attested_representation_use(area_model, proportional, partition_region_into_sections, 3, ['JMTE_Boote_2018_Abc/p15_1.png', 'JRME_Ellis_2011_Generalizing-promoting/p14_1.png', 'JRME_Lo_1997_Developing/p18_1.png']).
attested_representation_use(area_model, proportional, partition_whole_into_equal_parts, 2, ['FLM_Watson_1988_Three/p7_1.png', 'JMTE_Orrill_2012_Making/p10_3.png']).
attested_representation_use(area_model, proportional, area_model_for_measurement, 1, ['ZDM_Depaepe_2010_Teachers''/p11_2.png']).
attested_representation_use(area_model, proportional, shade_part_to_name_fraction, 1, ['MERJ_Wright_2014_Frequencies/p21_2.png']).
attested_representation_use(area_model, ratio, shade_part_to_name_fraction, 1, ['MERJ_Wright_2014_Frequencies/p21_2.png']).
attested_representation_use(area_model, rational, partition_whole_into_equal_parts, 4, ['ESM_Reynolds_1995_Addressing/p16_1.png', 'ESM_Xie_2017_Examining/p13_1.png', 'JMB_Singer_2008_Between/p12_2.png']).
attested_representation_use(area_model, statistics, area_model_for_fraction, 1, ['ZDM_Pfannkuch_2012_Conceptual/p7_1.png']).
attested_representation_use(area_model, whole_number, area_model_for_fraction, 7, ['ESM_Brink_1993_Different/p2_1.png', 'JMB_Singer_2008_Between/p12_2.png', 'JMB_Singer_2008_Between/p13_1.png']).
attested_representation_use(area_model, whole_number, area_model_for_multiplication, 5, ['MTL_Izsak_2004_Teaching/p28_1.png', 'MTL_Izsak_2004_Teaching/p29_1.png', 'MTL_Izsak_2004_Teaching/p30_1.png']).
attested_representation_use(area_model, whole_number, partition_whole_into_equal_parts, 4, ['ESM_Reynolds_1995_Addressing/p16_1.png', 'JRME_Bray_2011_Collective/p19_1.png', 'ZDM_Sembiring_2008_Reforming/p10_1.png']).
attested_representation_use(area_model, whole_number, bar_model_for_multiplicative_reasoning, 2, ['JRME_Ng_2009_Model/p20_1.png', 'JRME_Ng_2009_Model/p27_1.png']).
attested_representation_use(area_model, whole_number, partition_region_into_sections, 2, ['JMTE_Cai_2017_Mathematical/p15_1.png', 'JRME_Lo_1997_Developing/p18_1.png']).
attested_representation_use(area_model, whole_number, area_model_for_measurement, 1, ['JMTE_Baxter_2010_Social/p12_1.png']).
attested_representation_use(balance_scale, algebraic, balance_for_equation, 1, ['JMB_Ramful_2008_Reversibility/p13_1.png']).
attested_representation_use(balance_scale, fraction, partition_for_fraction_comparison, 1, ['JMB_Olive_2006_Making/p16_1.png']).
attested_representation_use(balance_scale, proportional, balance_for_equation, 1, ['JMB_Ramful_2008_Reversibility/p13_1.png']).
attested_representation_use(base_ten_blocks, algebraic, base_ten_blocks_for_place_value, 6, ['ESM_Hackenberg_2016_Students''/p12_1.png', 'ESM_Hackenberg_2016_Students''/p12_2.png', 'ESM_Peck_2016_Reinventing/p11_1.png']).
attested_representation_use(base_ten_blocks, algebraic, base_ten_blocks_for_regrouping, 2, ['JMTE_Caglayan_2013_Prospective/p12_1.png', 'JRME_Cai_1995_Cognitive/p82_1.png']).
attested_representation_use(base_ten_blocks, calculus, base_ten_blocks_for_place_value, 1, ['JMB_Weber_2014_Duality/p9_2.png']).
attested_representation_use(base_ten_blocks, combinatorial, base_ten_blocks_for_place_value, 1, ['JMB_Weber_2014_Duality/p9_2.png']).
attested_representation_use(base_ten_blocks, decimal, base_ten_blocks_for_place_value, 1, ['JMB_Singer_2008_Between/p12_1.png']).
attested_representation_use(base_ten_blocks, fraction, base_ten_blocks_for_regrouping, 3, ['JMB_Boyce_2017_Dylans/p6_1.png', 'JMB_Yankelewitz_2010_Task/p6_1.png', 'JRME_Cai_1995_Cognitive/p82_1.png']).
attested_representation_use(base_ten_blocks, fraction, base_ten_blocks_for_place_value, 2, ['ESM_Hackenberg_2016_Students''/p12_2.png', 'JRME_Lamon_1996_Development/p18_1.png']).
attested_representation_use(base_ten_blocks, fraction, partition_whole_into_equal_parts, 2, ['ESM_Peck_2016_Reinventing/p11_1.png', 'JRME_Hackenberg_2015_Relationships/p25_1.png']).
attested_representation_use(base_ten_blocks, fraction, partition_for_fraction_comparison, 1, ['ESM_Hackenberg_2016_Students''/p12_1.png']).
attested_representation_use(base_ten_blocks, geometric, base_ten_blocks_for_place_value, 1, ['JMB_Singer_2008_Between/p12_1.png']).
attested_representation_use(base_ten_blocks, geometric, base_ten_blocks_for_regrouping, 1, ['JMB_Boyce_2017_Dylans/p6_1.png']).
attested_representation_use(base_ten_blocks, measurement, base_ten_blocks_for_regrouping, 3, ['JMB_Boyce_2017_Dylans/p6_1.png', 'JMTE_Santagata_2014_Learning/p13_1.png', 'JRME_Cai_1995_Cognitive/p82_1.png']).
attested_representation_use(base_ten_blocks, measurement, base_ten_blocks_for_place_value, 1, ['JMB_Superfine_2009_Translation/p12_1.png']).
attested_representation_use(base_ten_blocks, probability, base_ten_blocks_for_place_value, 1, ['JRME_English_2016_Development/p19_1.png']).
attested_representation_use(base_ten_blocks, proportional, base_ten_blocks_for_place_value, 1, ['JRME_Hackenberg_2015_Relationships/p25_1.png']).
attested_representation_use(base_ten_blocks, rational, base_ten_blocks_for_place_value, 1, ['JMB_Singer_2008_Between/p12_1.png']).
attested_representation_use(base_ten_blocks, rational, partition_whole_into_equal_parts, 1, ['JRME_Hackenberg_2015_Relationships/p25_1.png']).
attested_representation_use(base_ten_blocks, statistics, base_ten_blocks_for_regrouping, 1, ['JRME_Cai_1995_Cognitive/p82_1.png']).
attested_representation_use(base_ten_blocks, whole_number, base_ten_blocks_for_regrouping, 8, ['ESM_Son_2016_Moving/p22_1.png', 'ESM_Treffers_1991_Meeting/p7_1.png', 'JMB_Boyce_2017_Dylans/p6_1.png']).
attested_representation_use(base_ten_blocks, whole_number, base_ten_blocks_for_place_value, 6, ['ESM_Bednarz_1982_Understanding/p19_1.png', 'ESM_Bednarz_1982_Understanding/p20_1.png', 'JMB_Lee_2007_Making/p8_1.png']).
attested_representation_use(base_ten_blocks, whole_number, area_model_for_fraction, 1, ['ZDM_Gellert_2014_Students/p7_1.png']).
attested_representation_use(fraction_bars, algebraic, shade_part_to_name_fraction, 7, ['ESM_Pirie_1994_Growth/p11_1.png', 'IJSME_Lee_2014_Relationships/p14_1.png', 'JMB_Hackenberg_2013_Fractional/p11_1.png']).
attested_representation_use(fraction_bars, algebraic, partition_whole_into_equal_parts, 4, ['ESM_Hackenberg_2016_Students''/p11_1.png', 'ESM_Hackenberg_2016_Students''/p15_2.png', 'JRME_Hackenberg_2015_Relationships/p18_1.png']).
attested_representation_use(fraction_bars, algebraic, bar_model_for_multiplicative_reasoning, 3, ['FLM_Watson_1988_Three/p3_1.png', 'FLM_Watson_1988_Three/p4_4.png', 'JRME_Ng_2009_Model/p23_1.png']).
attested_representation_use(fraction_bars, algebraic, partition_region_into_sections, 2, ['JMB_Hackenberg_2013_Fractional/p11_2.png', 'JRME_Hackenberg_2015_Relationships/p21_1.png']).
attested_representation_use(fraction_bars, algebraic, represent_quantity_spatially, 2, ['JMB_Hackenberg_2013_Fractional/p17_1.png', 'ZDM_Garderen_2014_Challenges/p9_1.png']).
attested_representation_use(fraction_bars, algebraic, area_model_for_fraction, 1, ['ZDM_Trouche_2010_Handheld/p11_2.png']).
attested_representation_use(fraction_bars, algebraic, partition_for_fraction_comparison, 1, ['ESM_Hackenberg_2016_Students''/p15_1.png']).
attested_representation_use(fraction_bars, calculus, area_model_for_fraction, 1, ['ZDM_Trouche_2010_Handheld/p11_2.png']).
attested_representation_use(fraction_bars, combinatorial, shade_part_to_name_fraction, 2, ['JMB_Hackenberg_2013_Fractional/p11_1.png', 'JMB_Hackenberg_2013_Fractional/p17_2.png']).
attested_representation_use(fraction_bars, combinatorial, area_model_for_fraction, 1, ['JMB_Uptegrove_2015_Shared/p13_1.png']).
attested_representation_use(fraction_bars, combinatorial, partition_region_into_sections, 1, ['JMB_Hackenberg_2013_Fractional/p11_2.png']).
attested_representation_use(fraction_bars, combinatorial, represent_quantity_spatially, 1, ['JMB_Hackenberg_2013_Fractional/p17_1.png']).
attested_representation_use(fraction_bars, decimal, partition_for_fraction_comparison, 3, ['IJSME_Yang_2004_Study/p17_1.png', 'IJSME_Yang_2004_Study/p18_1.png', 'JMTE_Dyson_2013_Prospective/p8_1.png']).
attested_representation_use(fraction_bars, decimal, area_model_for_fraction, 1, ['ZDM_Sembiring_2008_Reforming/p12_3.png']).
attested_representation_use(fraction_bars, decimal, partition_whole_into_equal_parts, 1, ['ZDM_Sembiring_2008_Reforming/p12_4.png']).
attested_representation_use(fraction_bars, decimal, represent_quantity_spatially, 1, ['IJSME_Almeida_2016_Strategies/p8_1.png']).
attested_representation_use(fraction_bars, fraction, partition_whole_into_equal_parts, 56, ['ESM_Brizuela_2005_Young/p11_1.png', 'ESM_Brizuela_2005_Young/p14_1.png', 'ESM_Brizuela_2005_Young/p16_1.png']).
attested_representation_use(fraction_bars, fraction, shade_part_to_name_fraction, 33, ['ESM_Cadez_2018_How/p17_2.png', 'ESM_Hasemann_1981_Difficulties/p9_1.png', 'ESM_Hasemann_1995_Concept/p12_2.png']).
attested_representation_use(fraction_bars, fraction, partition_for_fraction_comparison, 16, ['ESM_Boaler_1993_Encouraging/p24_2.png', 'ESM_Hackenberg_2016_Students''/p15_1.png', 'ESM_Lee_2017_Pre-service/p13_1.png']).
attested_representation_use(fraction_bars, fraction, represent_quantity_spatially, 9, ['ESM_Lee_2017_Pre-service/p12_1.png', 'ESM_Lee_2017_Pre-service/p14_1.png', 'IJSME_Almeida_2016_Strategies/p8_1.png']).
attested_representation_use(fraction_bars, fraction, bar_model_for_multiplicative_reasoning, 5, ['ESM_Lee_2017_Pre-service/p16_1.png', 'FLM_Watson_1988_Three/p3_1.png', 'JMB_Norton_2009_Quantitative/p5_1.png']).
attested_representation_use(fraction_bars, fraction, area_model_for_fraction, 4, ['ESM_Courey_2012_Academic/p10_1.png', 'ESM_Klein_2012_How/p12_1.png', 'JRME_Lewis_2014_Difference/p29_1.png']).
attested_representation_use(fraction_bars, fraction, area_model_for_multiplication, 4, ['IJMEST_Alenazi_2016_Examining/p11_1.png', 'JMB_Webel_2016_Meaning/p12_2.png', 'JMTE_Lovin_2018_Pre-k-/p9_1.png']).
attested_representation_use(fraction_bars, fraction, partition_region_into_sections, 3, ['JRME_Lamon_1996_Development/p12_1.png', 'JRME_Lamon_1996_Development/p14_1.png', 'JRME_Lewis_2014_Difference/p28_1.png']).
attested_representation_use(fraction_bars, geometric, shade_part_to_name_fraction, 3, ['ESM_Hasemann_1995_Concept/p12_2.png', 'ESM_Pirie_1994_Growth/p11_1.png', 'JMB_Clements_2000_From/p24_1.png']).
attested_representation_use(fraction_bars, geometric, partition_whole_into_equal_parts, 1, ['ZDM_Confrey_2015_Design/p8_1.png']).
attested_representation_use(fraction_bars, measurement, represent_quantity_spatially, 3, ['IJSME_Almeida_2016_Strategies/p8_1.png', 'JMB_Hackenberg_2013_Fractional/p17_1.png', 'ZDM_Garderen_2014_Challenges/p9_1.png']).
attested_representation_use(fraction_bars, measurement, shade_part_to_name_fraction, 2, ['JMB_Hackenberg_2013_Fractional/p11_1.png', 'JMB_Hackenberg_2013_Fractional/p17_2.png']).
attested_representation_use(fraction_bars, measurement, area_model_for_fraction, 1, ['ZDM_Sembiring_2008_Reforming/p12_3.png']).
attested_representation_use(fraction_bars, measurement, partition_region_into_sections, 1, ['JMB_Hackenberg_2013_Fractional/p11_2.png']).
attested_representation_use(fraction_bars, measurement, partition_whole_into_equal_parts, 1, ['ZDM_Sembiring_2008_Reforming/p12_4.png']).
attested_representation_use(fraction_bars, other, area_model_for_fraction, 1, ['ESM_Klein_2012_How/p12_1.png']).
attested_representation_use(fraction_bars, other, represent_quantity_spatially, 1, ['ZDM_Garderen_2014_Challenges/p9_1.png']).
attested_representation_use(fraction_bars, other, shade_part_to_name_fraction, 1, ['JMB_Clements_2000_From/p24_1.png']).
attested_representation_use(fraction_bars, percent, area_model_for_fraction, 1, ['MERJ_Wright_2014_Frequencies/p16_1.png']).
attested_representation_use(fraction_bars, percent, bar_model_for_multiplicative_reasoning, 1, ['MERJ_Wright_2014_Frequencies/p19_1.png']).
attested_representation_use(fraction_bars, proportional, partition_whole_into_equal_parts, 6, ['JMB_Norton_2013_Cognitive/p9_1.png', 'JMB_SaenzLudlow_2003_Collective/p15_1.png', 'JRME_Empson_2003_Low-performing/p23_1.png']).
attested_representation_use(fraction_bars, proportional, shade_part_to_name_fraction, 5, ['JMB_Clements_2000_From/p24_1.png', 'JMB_SaenzLudlow_2003_Collective/p15_2.png', 'JRME_Hackenberg_2015_Relationships/p18_2.png']).
attested_representation_use(fraction_bars, proportional, bar_model_for_multiplicative_reasoning, 4, ['FLM_Watson_1988_Three/p3_1.png', 'FLM_Watson_1988_Three/p4_4.png', 'JRME_Izsak_2017_Preservice/p27_1.png']).
attested_representation_use(fraction_bars, proportional, partition_region_into_sections, 3, ['JMB_Norton_2013_Cognitive/p6_1.png', 'JRME_Hackenberg_2015_Relationships/p21_1.png', 'JRME_Izsak_2017_Preservice/p25_1.png']).
attested_representation_use(fraction_bars, proportional, area_model_for_fraction, 1, ['MERJ_Wright_2014_Frequencies/p16_1.png']).
attested_representation_use(fraction_bars, proportional, partition_for_fraction_comparison, 1, ['MERJ_Hackenberg_2010_Mathematical/p15_1.png']).
attested_representation_use(fraction_bars, ratio, area_model_for_fraction, 1, ['MERJ_Wright_2014_Frequencies/p16_1.png']).
attested_representation_use(fraction_bars, ratio, bar_model_for_multiplicative_reasoning, 1, ['MERJ_Wright_2014_Frequencies/p19_1.png']).
attested_representation_use(fraction_bars, ratio, partition_whole_into_equal_parts, 1, ['ZDM_Confrey_2015_Design/p8_1.png']).
attested_representation_use(fraction_bars, rational, partition_whole_into_equal_parts, 5, ['JMB_Norton_2013_Cognitive/p6_1.png', 'JMB_Norton_2013_Cognitive/p9_1.png', 'JRME_Hackenberg_2015_Relationships/p18_1.png']).
attested_representation_use(fraction_bars, rational, shade_part_to_name_fraction, 3, ['JRME_Hackenberg_2015_Relationships/p18_2.png', 'JRME_Hackenberg_2015_Relationships/p19_1.png', 'JRME_Hackenberg_2015_Relationships/p19_2.png']).
attested_representation_use(fraction_bars, statistics, partition_region_into_sections, 1, ['IJMEST_Zazkis_2013_Students''/p8_1.png']).
attested_representation_use(fraction_bars, whole_number, partition_whole_into_equal_parts, 5, ['JMB_SaenzLudlow_2003_Collective/p15_1.png', 'JMB_Ulrich_2016_Tacitly/p12_1.png', 'JMTE_Steinberg_2004_Inquiry/p19_1.png']).
attested_representation_use(fraction_bars, whole_number, area_model_for_fraction, 1, ['ZDM_Sembiring_2008_Reforming/p12_3.png']).
attested_representation_use(fraction_bars, whole_number, bar_model_for_multiplicative_reasoning, 1, ['JRME_Ng_2009_Model/p23_1.png']).
attested_representation_use(fraction_bars, whole_number, partition_for_fraction_comparison, 1, ['MERJ_Hackenberg_2010_Mathematical/p15_1.png']).
attested_representation_use(fraction_bars, whole_number, partition_region_into_sections, 1, ['JMB_Ulrich_2016_Tacitly/p9_1.png']).
attested_representation_use(fraction_bars, whole_number, represent_quantity_spatially, 1, ['ZDM_Garderen_2014_Challenges/p9_1.png']).
attested_representation_use(fraction_bars, whole_number, shade_part_to_name_fraction, 1, ['JMB_SaenzLudlow_2003_Collective/p15_2.png']).
attested_representation_use(none, algebraic, manipulate_symbolic_notation, 120, ['ESM_Arcavi_2003_Role/p23_1.png', 'ESM_Baruk_1987_Realite/p10_1.png', 'ESM_Baruk_1987_Realite/p14_2.png']).
attested_representation_use(none, algebraic, sketch_graph_on_axes, 36, ['ESM_Walter_2007_Teachers''/p23_1.png', 'IJSME_Ferrara_2014_How/p6_1.png', 'JMB_Bell_1995_Purpose/p21_1.png']).
attested_representation_use(none, algebraic, manipulate_algebraic_expression, 24, ['ESM_Baruk_1987_Realite/p12_1.png', 'ESM_Baruk_1987_Realite/p16_1.png', 'ESM_Baruk_1987_Realite/p17_1.png']).
attested_representation_use(none, algebraic, solve_equation_symbolically, 13, ['ESM_Adu_2015_Students''/p9_1.png', 'ESM_Baruk_1987_Realite/p12_2.png', 'ESM_Baruk_1987_Realite/p13_1.png']).
attested_representation_use(none, algebraic, evaluate_expression_symbolically, 8, ['ESM_Baruk_1987_Realite/p10_2.png', 'ESM_Baruk_1987_Realite/p11_1.png', 'ESM_Baruk_1987_Realite/p19_1.png']).
attested_representation_use(none, algebraic, pose_or_solve_word_problem, 5, ['FLM_Watson_1988_Three/p4_3.png', 'FLM_Watson_1988_Three/p6_3.png', 'FLM_Watson_1988_Three/p6_4.png']).
attested_representation_use(none, algebraic, cross_multiply_proportion, 4, ['ESM_Peck_2016_Reinventing/p22_1.png', 'ESM_Peck_2016_Reinventing/p23_1.png', 'JMB_Hohensee_2016_Student/p11_1.png']).
attested_representation_use(none, algebraic, symbolic_calculus_argument, 3, ['ESM_Baruk_1987_Realite/p25_1.png', 'ESM_Gray_1999_Knowledge/p16_1.png', 'JMB_Rensaa_2014_Impact/p11_2.png']).
attested_representation_use(none, algebraic, compute_with_written_algorithm, 2, ['ESM_Hitt_2017_Rupture/p12_1.png', 'ESM_Peck_2016_Reinventing/p20_1.png']).
attested_representation_use(none, algebraic, enumerate_combinations, 1, ['RME_Malek_2011_Effect/p18_1.png']).
attested_representation_use(none, calculus, manipulate_symbolic_notation, 17, ['ESM_Kidron_2008_Abstraction/p14_1.png', 'IJSME_Parameswaran_2007_Understanding/p13_1.png', 'JMB_Cooley_2002_Writing/p16_1.png']).
attested_representation_use(none, calculus, sketch_graph_on_axes, 16, ['ESM_Aspinwall_1997_Uncontrollable/p9_1.png', 'ESM_Kidron_2011_Tacit/p13_2.png', 'IJSME_Mcgee_2015_Impact/p20_1.png']).
attested_representation_use(none, calculus, symbolic_calculus_argument, 6, ['ESM_Alcock_2005_Convergence/p6_1.png', 'ESM_Gray_1999_Knowledge/p16_1.png', 'JMB_Rensaa_2014_Impact/p11_2.png']).
attested_representation_use(none, calculus, manipulate_algebraic_expression, 3, ['JMB_Rensaa_2014_Impact/p13_1.png', 'JMB_Rensaa_2014_Impact/p15_1.png', 'JMB_Rensaa_2014_Impact/p19_1.png']).
attested_representation_use(none, calculus, solve_equation_symbolically, 1, ['JMB_GuerreroOrtiz_2016_Representations/p12_1.png']).
attested_representation_use(none, combinatorial, manipulate_symbolic_notation, 2, ['JMB_Tillema_2013_Power/p10_1.png', 'JMB_Tillema_2014_Students''/p9_1.png']).
attested_representation_use(none, combinatorial, sketch_graph_on_axes, 2, ['JMB_Weber_2014_Duality/p7_1.png', 'JMB_Weber_2014_Duality/p9_1.png']).
attested_representation_use(none, combinatorial, enumerate_combinations, 1, ['JMB_Tillema_2014_Students''/p15_1.png']).
attested_representation_use(none, combinatorial, manipulate_algebraic_expression, 1, ['JMB_Tillema_2013_Power/p13_1.png']).
attested_representation_use(none, decimal, manipulate_symbolic_notation, 30, ['ESM_Bell_1981_Choice/p19_2.png', 'ESM_Gorgorio_2009_Social/p11_1.png', 'ESM_Moskal_2000_Making/p11_1.png']).
attested_representation_use(none, decimal, pose_or_solve_word_problem, 3, ['ESM_Bell_1984_Choice/p10_1.png', 'ESM_Bell_1984_Choice/p11_1.png', 'JMB_Karsenty_2007_Exploring/p8_1.png']).
attested_representation_use(none, decimal, sketch_graph_on_axes, 2, ['JMB_Karsenty_2007_Exploring/p15_1.png', 'JMB_Karsenty_2007_Exploring/p3_1.png']).
attested_representation_use(none, decimal, compute_with_written_algorithm, 1, ['ESM_Bell_1981_Choice/p17_1.png']).
attested_representation_use(none, decimal, enumerate_combinations, 1, ['ZDM_Sembiring_2008_Reforming/p4_1.png']).
attested_representation_use(none, fraction, manipulate_symbolic_notation, 73, ['ESM_Boaler_1993_Encouraging/p16_1.png', 'ESM_Boaler_1993_Encouraging/p18_1.png', 'ESM_Boaler_1993_Encouraging/p22_1.png']).
attested_representation_use(none, fraction, sketch_graph_on_axes, 11, ['ESM_Hasemann_1995_Concept/p15_1.png', 'ESM_Hasemann_1995_Concept/p16_1.png', 'ESM_Hasemann_1995_Concept/p20_1.png']).
attested_representation_use(none, fraction, cross_multiply_proportion, 4, ['ESM_Peck_2016_Reinventing/p22_1.png', 'ESM_Peck_2016_Reinventing/p23_1.png', 'JMB_Clark_2003_Comparison/p14_1.png']).
attested_representation_use(none, fraction, pose_or_solve_word_problem, 4, ['FLM_Watson_1988_Three/p4_3.png', 'FLM_Watson_1988_Three/p6_3.png', 'FLM_Watson_1988_Three/p6_4.png']).
attested_representation_use(none, fraction, enumerate_combinations, 3, ['ESM_Boaler_1993_Encouraging/p17_2.png', 'ESM_Pirie_1992_Creating/p9_1.png', 'ZDM_Sembiring_2008_Reforming/p4_1.png']).
attested_representation_use(none, fraction, compute_with_written_algorithm, 2, ['ESM_Boaler_1993_Encouraging/p17_1.png', 'ESM_Peck_2016_Reinventing/p20_1.png']).
attested_representation_use(none, fraction, manipulate_algebraic_expression, 1, ['JMB_Muzheve_2012_Exploration/p10_1.png']).
attested_representation_use(none, fraction, solve_equation_symbolically, 1, ['JMTE_Orrill_2012_Making/p10_1.png']).
attested_representation_use(none, geometric, manipulate_symbolic_notation, 18, ['ESM_Arcavi_2003_Role/p23_1.png', 'ESM_Douady_1989_Un/p22_1.png', 'ESM_Hasemann_1995_Concept/p10_1.png']).
attested_representation_use(none, geometric, sketch_graph_on_axes, 16, ['ESM_Bell_1993_Some/p19_1.png', 'ESM_Bell_1993_Some/p19_2.png', 'ESM_Bell_1993_Some/p8_1.png']).
attested_representation_use(none, integer, manipulate_symbolic_notation, 7, ['IJMEST_Olteanu_2012_Differences/p9_1.png', 'JMB_Komatsu_2010_Counter-examples/p7_1.png', 'JMB_Streefland_1996_Negative/p11_2.png']).
attested_representation_use(none, integer, sketch_graph_on_axes, 5, ['ESM_Bell_1993_Some/p19_1.png', 'ESM_Bell_1993_Some/p19_2.png', 'ESM_Bell_1993_Some/p8_1.png']).
attested_representation_use(none, integer, solve_equation_symbolically, 3, ['IJMEST_Olteanu_2012_Differences/p11_1.png', 'IJMEST_Olteanu_2012_Differences/p7_1.png', 'IJMEST_Olteanu_2012_Differences/p9_2.png']).
attested_representation_use(none, integer, compute_with_written_algorithm, 1, ['JMB_Streefland_1996_Negative/p9_1.png']).
attested_representation_use(none, measurement, manipulate_symbolic_notation, 37, ['ESM_Bell_1981_Choice/p19_2.png', 'ESM_Douady_1989_Un/p22_1.png', 'ESM_Moore_2013_Making/p16_1.png']).
attested_representation_use(none, measurement, sketch_graph_on_axes, 6, ['JMB_Lobato_2002_Quantitative/p14_1.png', 'JMB_diSessa_1991_Inventing/p25_1.png', 'JRME_Moore_2014_Quantitative/p21_1.png']).
attested_representation_use(none, measurement, compute_with_written_algorithm, 2, ['ESM_Bell_1981_Choice/p17_1.png', 'ZDM_Lobato_2015_Leveraging/p9_2.png']).
attested_representation_use(none, measurement, enumerate_combinations, 2, ['JMB_Superfine_2009_Translation/p9_1.png', 'ZDM_Sembiring_2008_Reforming/p4_1.png']).
attested_representation_use(none, measurement, pose_or_solve_word_problem, 2, ['JMTE_Boote_2018_Abc/p13_2.png', 'ZDM_Garderen_2014_Challenges/p7_1.png']).
attested_representation_use(none, measurement, cross_multiply_proportion, 1, ['JMTE_Boote_2018_Abc/p13_1.png']).
attested_representation_use(none, other, manipulate_symbolic_notation, 10, ['ESM_Gorgorio_2009_Social/p11_1.png', 'JMB_SotoJohnson_2014_Reasoning/p6_1.png', 'JMB_SotoJohnson_2014_Reasoning/p9_1.png']).
attested_representation_use(none, other, sketch_graph_on_axes, 9, ['JMB_Clements_2000_From/p19_1.png', 'JMB_SotoJohnson_2014_Reasoning/p10_2.png', 'JMB_SotoJohnson_2014_Reasoning/p11_3.png']).
attested_representation_use(none, other, manipulate_algebraic_expression, 2, ['MTL_McClain_2003_Supporting/p13_1.png', 'ZDM_Kaune_2006_Reflection/p6_1.png']).
attested_representation_use(none, other, pose_or_solve_word_problem, 1, ['ZDM_Garderen_2014_Challenges/p7_1.png']).
attested_representation_use(none, percent, manipulate_symbolic_notation, 7, ['ESM_Heuvelpanhuizen_1994_Improvement/p17_1.png', 'ESM_Heuvelpanhuizen_1994_Improvement/p29_2.png', 'ESM_Heuvelpanhuizen_1994_Improvement/p8_1.png']).
attested_representation_use(none, percent, pose_or_solve_word_problem, 1, ['MERJ_Wright_2014_Frequencies/p18_1.png']).
attested_representation_use(none, probability, manipulate_symbolic_notation, 7, ['ESM_Francisco_2013_Learning/p15_1.png', 'IJMEST_Watson_2007_Development/p14_1.png', 'JRME_English_2016_Development/p25_1.png']).
attested_representation_use(none, probability, sketch_graph_on_axes, 3, ['JMB_Brousseau_2002_Experiment/p28_1.png', 'JMB_Brousseau_2002_Experiment/p30_1.png', 'JRME_English_2016_Development/p17_1.png']).
attested_representation_use(none, probability, enumerate_combinations, 2, ['ESM_Francisco_2013_Learning/p13_1.png', 'ZDM_Nunes_2014_Cognitive/p9_1.png']).
attested_representation_use(none, proportional, manipulate_symbolic_notation, 32, ['ESM_Che_2012_Problem/p12_1.png', 'ESM_Moore_2013_Making/p16_1.png', 'FLM_Watson_1988_Three/p4_1.png']).
attested_representation_use(none, proportional, sketch_graph_on_axes, 7, ['JMB_Brousseau_2002_Experiment/p28_1.png', 'JMB_Brousseau_2002_Experiment/p30_1.png', 'JMB_Clements_2000_From/p19_1.png']).
attested_representation_use(none, proportional, cross_multiply_proportion, 5, ['ESM_Che_2012_Problem/p11_1.png', 'JMB_Clark_2003_Comparison/p14_1.png', 'JMB_Weinberg_2016_Students/p14_1.png']).
attested_representation_use(none, proportional, pose_or_solve_word_problem, 5, ['FLM_Watson_1988_Three/p4_3.png', 'FLM_Watson_1988_Three/p6_3.png', 'FLM_Watson_1988_Three/p6_4.png']).
attested_representation_use(none, proportional, compute_with_written_algorithm, 3, ['ESM_Che_2012_Problem/p13_1.png', 'ESM_Che_2012_Problem/p9_1.png', 'ZDM_Lobato_2015_Leveraging/p9_2.png']).
attested_representation_use(none, proportional, solve_equation_symbolically, 1, ['JMTE_Orrill_2012_Making/p10_1.png']).
attested_representation_use(none, ratio, manipulate_symbolic_notation, 5, ['ESM_Bell_1993_Principles/p18_1.png', 'JMB_Clark_2003_Comparison/p14_2.png', 'MERJ_Wright_2014_Frequencies/p21_1.png']).
attested_representation_use(none, ratio, compute_with_written_algorithm, 1, ['ZDM_Lobato_2015_Leveraging/p9_2.png']).
attested_representation_use(none, ratio, cross_multiply_proportion, 1, ['JMB_Clark_2003_Comparison/p14_1.png']).
attested_representation_use(none, ratio, pose_or_solve_word_problem, 1, ['MERJ_Wright_2014_Frequencies/p18_1.png']).
attested_representation_use(none, rational, manipulate_symbolic_notation, 13, ['ESM_Bell_1993_Principles/p18_1.png', 'ESM_Depaepe_2018_Stimulating/p14_1.png', 'ESM_Reynolds_1995_Addressing/p15_1.png']).
attested_representation_use(none, rational, sketch_graph_on_axes, 9, ['ESM_Reynolds_1995_Addressing/p36_1.png', 'ESM_Reynolds_1995_Addressing/p37_1.png', 'JMB_Brousseau_2002_Experiment/p28_1.png']).
attested_representation_use(none, rational, compute_with_written_algorithm, 1, ['RME_Zazkis_2014_Script/p14_1.png']).
attested_representation_use(none, rational, manipulate_algebraic_expression, 1, ['JMB_Muzheve_2012_Exploration/p10_1.png']).
attested_representation_use(none, statistics, manipulate_symbolic_notation, 4, ['IJMEST_Zazkis_2013_Students''/p9_1.png', 'JRME_Cai_1995_Cognitive/p80_1.png', 'JRME_Cai_1995_Cognitive/p85_1.png']).
attested_representation_use(none, statistics, sketch_graph_on_axes, 4, ['ESM_Bakker_2006_Historical/p16_1.png', 'ESM_Konold_2015_Data/p8_1.png', 'JMB_Brousseau_2002_Experiment/p28_1.png']).
attested_representation_use(none, whole_number, manipulate_symbolic_notation, 55, ['ESM_Baruk_1987_Realite/p10_1.png', 'ESM_Baruk_1987_Realite/p14_2.png', 'ESM_Baruk_1987_Realite/p15_1.png']).
attested_representation_use(none, whole_number, manipulate_algebraic_expression, 14, ['ESM_Baruk_1987_Realite/p12_1.png', 'ESM_Baruk_1987_Realite/p16_1.png', 'ESM_Baruk_1987_Realite/p17_1.png']).
attested_representation_use(none, whole_number, evaluate_expression_symbolically, 8, ['ESM_Baruk_1987_Realite/p10_2.png', 'ESM_Baruk_1987_Realite/p11_1.png', 'ESM_Baruk_1987_Realite/p19_1.png']).
attested_representation_use(none, whole_number, compute_with_written_algorithm, 7, ['ESM_Neuman_1999_Early/p18_1.png', 'ESM_Saenzludlow_1998_Third/p11_1.png', 'ESM_Treffers_1987_Integrated/p13_1.png']).
attested_representation_use(none, whole_number, solve_equation_symbolically, 7, ['ESM_Baruk_1987_Realite/p12_2.png', 'ESM_Baruk_1987_Realite/p13_1.png', 'ESM_Baruk_1987_Realite/p13_2.png']).
attested_representation_use(none, whole_number, sketch_graph_on_axes, 4, ['ESM_Reynolds_1995_Addressing/p36_1.png', 'ESM_Reynolds_1995_Addressing/p37_1.png', 'ZDM_Garderen_2014_Challenges/p8_1.png']).
attested_representation_use(none, whole_number, enumerate_combinations, 3, ['JMB_Superfine_2009_Translation/p9_1.png', 'JMB_Tillema_2014_Students''/p15_1.png', 'ZDM_Sembiring_2008_Reforming/p4_1.png']).
attested_representation_use(none, whole_number, pose_or_solve_word_problem, 3, ['ESM_Bell_1984_Choice/p10_1.png', 'ESM_Bell_1984_Choice/p11_1.png', 'ZDM_Garderen_2014_Challenges/p7_1.png']).
attested_representation_use(none, whole_number, symbolic_calculus_argument, 2, ['ESM_Baruk_1987_Realite/p25_1.png', 'ESM_Gray_1999_Knowledge/p16_1.png']).
attested_representation_use(number_line, algebraic, mark_intervals_on_number_line, 10, ['JMB_Ellis_2008_Hidden/p18_1.png', 'JMB_FerrariEscola_2016_Multiply/p11_1.png', 'JMB_Hackenberg_2013_Fractional/p15_1.png']).
attested_representation_use(number_line, algebraic, number_line_jumps_for_arithmetic, 10, ['JMB_Hackenberg_2013_Fractional/p14_1.png', 'JMB_Hohensee_2016_Student/p16_2.png', 'JMB_Karsenty_2007_Exploring/p13_1.png']).
attested_representation_use(number_line, algebraic, sketch_graph_on_axes, 10, ['ESM_Zahner_2015_Rise/p12_1.png', 'JMB_Karsenty_2007_Exploring/p12_1.png', 'JMB_SotoJohnson_2014_Reasoning/p10_1.png']).
attested_representation_use(number_line, algebraic, double_number_line_for_proportion, 6, ['JMB_Hohensee_2016_Student/p12_1.png', 'JMB_Hohensee_2016_Student/p13_1.png', 'JMB_Hohensee_2016_Student/p15_1.png']).
attested_representation_use(number_line, algebraic, represent_quantity_spatially, 3, ['ESM_Baruk_1987_Realite/p6_1.png', 'JRME_Even_1993_Subject-matter/p14_1.png', 'JRME_Hackenberg_2015_Relationships/p28_1.png']).
attested_representation_use(number_line, calculus, mark_intervals_on_number_line, 5, ['ESM_Thompson_1994_Images/p10_1.png', 'ZDM_Antonini_2011_Generating/p12_1.png', 'ZDM_Antonini_2011_Generating/p4_2.png']).
attested_representation_use(number_line, calculus, sketch_graph_on_axes, 3, ['JMB_Rasmussen_2007_Reinventing/p13_1.png', 'ZDM_Antonini_2011_Generating/p11_1.png', 'ZDM_Antonini_2011_Generating/p11_2.png']).
attested_representation_use(number_line, calculus, number_line_jumps_for_arithmetic, 1, ['ZDM_Antonini_2011_Generating/p9_2.png']).
attested_representation_use(number_line, combinatorial, number_line_jumps_for_arithmetic, 3, ['JMB_Hackenberg_2013_Fractional/p14_1.png', 'JMB_Tillema_2013_Power/p12_1.png', 'JMB_Tillema_2014_Students''/p14_1.png']).
attested_representation_use(number_line, combinatorial, mark_intervals_on_number_line, 1, ['JMB_Hackenberg_2013_Fractional/p15_1.png']).
attested_representation_use(number_line, decimal, represent_quantity_spatially, 4, ['IJEMST_Girit_2016_Pre/p10_1.png', 'IJEMST_Girit_2016_Pre/p5_1.png', 'IJEMST_Girit_2016_Pre/p6_1.png']).
attested_representation_use(number_line, decimal, count_collection_with_counters, 2, ['JMB_Widjaja_2011_Locating/p6_1.png', 'JMB_Widjaja_2011_Locating/p7_1.png']).
attested_representation_use(number_line, decimal, double_number_line_for_proportion, 2, ['ESM_Okazaki_2005_Characteristics/p12_1.png', 'ESM_Okazaki_2005_Characteristics/p23_1.png']).
attested_representation_use(number_line, decimal, number_line_jumps_for_arithmetic, 2, ['IJEMST_Girit_2016_Pre/p7_1.png', 'JMB_Karsenty_2007_Exploring/p13_1.png']).
attested_representation_use(number_line, decimal, partition_region_into_sections, 2, ['IJEMST_Girit_2016_Pre/p9_1.png', 'RME_OReilly_1999_Students''/p12_1.png']).
attested_representation_use(number_line, decimal, mark_intervals_on_number_line, 1, ['JMB_Widjaja_2011_Locating/p8_1.png']).
attested_representation_use(number_line, decimal, sketch_graph_on_axes, 1, ['JMB_Karsenty_2007_Exploring/p12_1.png']).
attested_representation_use(number_line, fraction, mark_intervals_on_number_line, 8, ['ESM_Yilmaz_2018_Investigation/p6_1.png', 'IJMEST_Alenazi_2016_Examining/p15_1.png', 'JMB_Hackenberg_2013_Fractional/p15_1.png']).
attested_representation_use(number_line, fraction, partition_whole_into_equal_parts, 8, ['IJMEST_Alenazi_2016_Examining/p16_1.png', 'JMB_Hackenberg_2009_Students''/p7_1.png', 'JMTE_Orrill_2012_Making/p17_1.png']).
attested_representation_use(number_line, fraction, represent_quantity_spatially, 6, ['JMTE_Lovin_2018_Pre-k-/p22_1.png', 'JMTE_Orrill_2012_Making/p19_1.png', 'JRME_Izsak_2008_Teaching/p16_1.png']).
attested_representation_use(number_line, fraction, double_number_line_for_proportion, 4, ['IJMEST_Alenazi_2016_Examining/p13_2.png', 'JMTE_Orrill_2012_Making/p10_2.png', 'JMTE_Orrill_2012_Making/p16_1.png']).
attested_representation_use(number_line, fraction, number_line_jumps_for_arithmetic, 2, ['ESM_Courey_2012_Academic/p9_1.png', 'JMB_Hackenberg_2013_Fractional/p14_1.png']).
attested_representation_use(number_line, fraction, partition_for_fraction_comparison, 2, ['JRME_Hackenberg_2015_Relationships/p28_1.png', 'RME_OReilly_1999_Students''/p12_1.png']).
attested_representation_use(number_line, integer, number_line_jumps_for_arithmetic, 4, ['ESM_Bishop_2014_Using/p15_1.png', 'JMB_Streefland_1996_Negative/p19_2.png', 'ZDM_Steinbring_2015_Mathematical/p11_3.png']).
attested_representation_use(number_line, integer, mark_intervals_on_number_line, 1, ['ZDM_Steinbring_2015_Mathematical/p11_2.png']).
attested_representation_use(number_line, integer, partition_region_into_sections, 1, ['RME_OReilly_1999_Students''/p12_1.png']).
attested_representation_use(number_line, integer, represent_quantity_spatially, 1, ['JMB_Streefland_1996_Negative/p14_1.png']).
attested_representation_use(number_line, measurement, number_line_jumps_for_arithmetic, 12, ['JMB_Hackenberg_2013_Fractional/p14_1.png', 'JMB_Superfine_2009_Translation/p13_1.png', 'JMB_Superfine_2009_Translation/p13_2.png']).
attested_representation_use(number_line, measurement, mark_intervals_on_number_line, 7, ['IJSME_Cheek_2012_Students''/p12_1.png', 'IJSME_Cheek_2012_Students''/p16_1.png', 'JMB_Hackenberg_2013_Fractional/p15_1.png']).
attested_representation_use(number_line, measurement, double_number_line_for_proportion, 2, ['ZDM_Lobato_2015_Leveraging/p10_1.png', 'ZDM_Lobato_2015_Leveraging/p9_1.png']).
attested_representation_use(number_line, measurement, represent_quantity_spatially, 2, ['ZDM_Lobato_2015_Leveraging/p13_1.png', 'ZDM_Lobato_2015_Leveraging/p14_1.png']).
attested_representation_use(number_line, other, sketch_graph_on_axes, 6, ['JMB_SotoJohnson_2014_Reasoning/p10_1.png', 'JMB_SotoJohnson_2014_Reasoning/p11_2.png', 'JMB_SotoJohnson_2014_Reasoning/p6_3.png']).
attested_representation_use(number_line, other, mark_intervals_on_number_line, 5, ['JMB_SotoJohnson_2014_Reasoning/p11_1.png', 'ZDM_Antonini_2011_Generating/p12_1.png', 'ZDM_Antonini_2011_Generating/p4_2.png']).
attested_representation_use(number_line, other, number_line_jumps_for_arithmetic, 3, ['JMB_SotoJohnson_2014_Reasoning/p6_2.png', 'ZDM_Antonini_2011_Generating/p9_2.png', 'ZDM_Garderen_2014_Challenges/p10_1.png']).
attested_representation_use(number_line, percent, double_number_line_for_proportion, 3, ['MERJ_Wright_2014_Frequencies/p12_1.png', 'MERJ_Wright_2014_Frequencies/p14_1.png', 'MERJ_Wright_2014_Frequencies/p15_1.png']).
attested_representation_use(number_line, percent, bar_model_for_multiplicative_reasoning, 1, ['ESM_Shreyar_2010_Thinking/p5_1.png']).
attested_representation_use(number_line, proportional, double_number_line_for_proportion, 9, ['JMTE_Orrill_2012_Making/p10_2.png', 'JMTE_Orrill_2012_Making/p16_1.png', 'JMTE_Orrill_2015_Tracing/p12_1.png']).
attested_representation_use(number_line, proportional, mark_intervals_on_number_line, 9, ['IJSME_Cheek_2012_Students''/p12_1.png', 'IJSME_Cheek_2012_Students''/p16_1.png', 'JMB_Ramful_2008_Reversibility/p9_1.png']).
attested_representation_use(number_line, proportional, represent_quantity_spatially, 5, ['JMTE_Orrill_2012_Making/p19_1.png', 'JRME_Hackenberg_2015_Relationships/p28_1.png', 'JRME_Izsak_2017_Preservice/p18_1.png']).
attested_representation_use(number_line, proportional, number_line_jumps_for_arithmetic, 4, ['ZDM_Lobato_2015_Leveraging/p11_1.png', 'ZDM_Lobato_2015_Leveraging/p12_1.png', 'ZDM_Lobato_2015_Leveraging/p14_2.png']).
attested_representation_use(number_line, proportional, partition_whole_into_equal_parts, 1, ['JMTE_Orrill_2012_Making/p17_1.png']).
attested_representation_use(number_line, ratio, double_number_line_for_proportion, 5, ['MERJ_Wright_2014_Frequencies/p12_1.png', 'MERJ_Wright_2014_Frequencies/p14_1.png', 'MERJ_Wright_2014_Frequencies/p15_1.png']).
attested_representation_use(number_line, ratio, number_line_jumps_for_arithmetic, 4, ['ZDM_Lobato_2015_Leveraging/p11_1.png', 'ZDM_Lobato_2015_Leveraging/p12_1.png', 'ZDM_Lobato_2015_Leveraging/p14_2.png']).
attested_representation_use(number_line, ratio, mark_intervals_on_number_line, 3, ['ZDM_Lobato_2015_Leveraging/p11_2.png', 'ZDM_Lobato_2015_Leveraging/p11_3.png', 'ZDM_Lobato_2015_Leveraging/p6_1.png']).
attested_representation_use(number_line, ratio, represent_quantity_spatially, 2, ['ZDM_Lobato_2015_Leveraging/p13_1.png', 'ZDM_Lobato_2015_Leveraging/p14_1.png']).
attested_representation_use(number_line, rational, represent_quantity_spatially, 1, ['JRME_Hackenberg_2015_Relationships/p28_1.png']).
attested_representation_use(number_line, statistics, mark_intervals_on_number_line, 2, ['ESM_Bakker_2006_Historical/p15_1.png', 'ESM_Konold_2015_Data/p11_1.png']).
attested_representation_use(number_line, statistics, sketch_graph_on_axes, 1, ['ESM_Bakker_2006_Historical/p10_1.png']).
attested_representation_use(number_line, whole_number, number_line_jumps_for_arithmetic, 21, ['ESM_Treffers_1991_Meeting/p9_1.png', 'JMB_Superfine_2009_Translation/p13_1.png', 'JMB_Superfine_2009_Translation/p13_2.png']).
attested_representation_use(number_line, whole_number, mark_intervals_on_number_line, 11, ['ESM_Treffers_1991_Meeting/p16_1.png', 'ESM_Treffers_1991_Meeting/p17_1.png', 'ESM_Treffers_1991_Meeting/p8_1.png']).
attested_representation_use(number_line, whole_number, double_number_line_for_proportion, 4, ['ZDM_Gellert_2014_Students/p10_1.png', 'ZDM_Lobato_2015_Leveraging/p10_1.png', 'ZDM_Lobato_2015_Leveraging/p9_1.png']).
attested_representation_use(number_line, whole_number, represent_quantity_spatially, 3, ['ESM_Baruk_1987_Realite/p6_1.png', 'ZDM_Lobato_2015_Leveraging/p13_1.png', 'ZDM_Lobato_2015_Leveraging/p14_1.png']).
attested_representation_use(place_value_chart, algebraic, place_value_chart_for_columns, 1, ['JMB_Ho_2014_Model/p9_1.png']).
attested_representation_use(place_value_chart, fraction, base_ten_blocks_for_place_value, 1, ['JMB_Neuberger_2012_Benefits/p12_2.png']).
attested_representation_use(place_value_chart, fraction, partition_whole_into_equal_parts, 1, ['JRME_Lamon_1996_Development/p19_1.png']).
attested_representation_use(place_value_chart, geometric, place_value_chart_for_columns, 1, ['JMTE_Project_2011_Measuring/p14_1.png']).
attested_representation_use(place_value_chart, other, place_value_chart_for_columns, 1, ['MTL_McClain_2003_Supporting/p16_1.png']).
attested_representation_use(place_value_chart, probability, place_value_chart_for_columns, 1, ['JMTE_Project_2011_Measuring/p14_1.png']).
attested_representation_use(place_value_chart, whole_number, place_value_chart_for_columns, 6, ['JMB_Thomas_2002_Children''s/p8_2.png', 'JMTE_Project_2011_Measuring/p14_1.png', 'MTL_McClain_2003_Supporting/p16_1.png']).
attested_representation_use(place_value_chart, whole_number, base_ten_blocks_for_regrouping, 2, ['ESM_Son_2016_Moving/p17_1.png', 'ZDM_Rivera_2014_From/p13_3.png']).
attested_representation_use(place_value_chart, whole_number, base_ten_blocks_for_place_value, 1, ['ZDM_Gellert_2014_Students/p8_1.png']).
attested_representation_use(set_grouping, algebraic, count_collection_with_counters, 18, ['ESM_Caglayan_2010_Eighth/p10_1.png', 'ESM_Caglayan_2010_Eighth/p9_1.png', 'ESM_Hitt_2017_Rupture/p10_1.png']).
attested_representation_use(set_grouping, algebraic, bar_model_for_multiplicative_reasoning, 2, ['IJSME_Lee_2014_Relationships/p16_1.png', 'JRME_Ng_2009_Model/p25_1.png']).
attested_representation_use(set_grouping, algebraic, group_for_division_or_sharing, 2, ['ESM_Peck_2016_Reinventing/p10_1.png', 'IJSME_Lee_2014_Relationships/p13_1.png']).
attested_representation_use(set_grouping, algebraic, base_ten_blocks_for_place_value, 1, ['ZDM_Garderen_2014_Challenges/p11_1.png']).
attested_representation_use(set_grouping, algebraic, one_to_one_correspondence, 1, ['JMB_Huang_2012_Prospective/p7_1.png']).
attested_representation_use(set_grouping, combinatorial, count_collection_with_counters, 6, ['JMB_Hackenberg_2013_Fractional/p10_1.png', 'JMB_Tillema_2013_Power/p9_1.png', 'JMB_Tillema_2014_Students''/p10_1.png']).
attested_representation_use(set_grouping, decimal, count_collection_with_counters, 1, ['JMB_Singer_2008_Between/p11_1.png']).
attested_representation_use(set_grouping, decimal, place_value_chart_for_columns, 1, ['RME_OReilly_1999_Students''/p10_1.png']).
attested_representation_use(set_grouping, fraction, count_collection_with_counters, 15, ['ESM_Hasemann_1995_Concept/p8_1.png', 'ESM_Pirie_1992_Creating/p17_2.png', 'ESM_Pirie_1992_Creating/p18_1.png']).
attested_representation_use(set_grouping, fraction, partition_whole_into_equal_parts, 7, ['FLM_Pirie_1988_Understanding/p3_1.png', 'JMB_Baek_2017_Preservice/p7_2.png', 'JMB_Hackenberg_2013_Fractional/p10_1.png']).
attested_representation_use(set_grouping, fraction, equal_groups_for_multiplication, 4, ['ESM_Levenson_2013_Exploring/p7_1.png', 'JMB_Baek_2017_Preservice/p7_1.png', 'JMB_Nabors_2003_From/p30_3.png']).
attested_representation_use(set_grouping, fraction, group_for_division_or_sharing, 4, ['ESM_Peck_2016_Reinventing/p10_1.png', 'IJSME_Lee_2014_Relationships/p13_1.png', 'JMB_Olive_2006_Making/p17_1.png']).
attested_representation_use(set_grouping, fraction, bar_model_for_multiplicative_reasoning, 2, ['IJSME_Lee_2014_Relationships/p16_1.png', 'JRME_Ng_2009_Model/p25_1.png']).
attested_representation_use(set_grouping, fraction, one_to_one_correspondence, 2, ['JMB_Hunt_2016_Levels/p13_1.png', 'JMB_Neuberger_2012_Benefits/p15_4.png']).
attested_representation_use(set_grouping, fraction, partition_for_fraction_comparison, 1, ['RME_OReilly_1999_Students''/p10_1.png']).
attested_representation_use(set_grouping, fraction, partition_region_into_sections, 1, ['JMTE_Lo_2012_Prospective/p15_1.png']).
attested_representation_use(set_grouping, fraction, subitize_or_make_ten, 1, ['ESM_Pirie_1992_Creating/p16_1.png']).
attested_representation_use(set_grouping, geometric, count_collection_with_counters, 3, ['ESM_Hasemann_1995_Concept/p8_1.png', 'JMB_Boyce_2017_Dylans/p9_2.png', 'JMB_Singer_2008_Between/p11_1.png']).
attested_representation_use(set_grouping, geometric, one_to_one_correspondence, 2, ['JRME_Lo_1997_Developing/p10_1.png', 'JRME_Lo_1997_Developing/p9_1.png']).
attested_representation_use(set_grouping, integer, count_collection_with_counters, 3, ['ESM_Abele_1978_Usage/p3_1.png', 'ESM_Abele_1978_Usage/p8_1.png', 'JMB_Whitacre_2012_Happy/p5_1.png']).
attested_representation_use(set_grouping, integer, place_value_chart_for_columns, 1, ['RME_OReilly_1999_Students''/p10_1.png']).
attested_representation_use(set_grouping, measurement, count_collection_with_counters, 4, ['JMB_Boyce_2017_Dylans/p9_2.png', 'JMB_Hackenberg_2013_Fractional/p10_1.png', 'MTL_Battista_2004_Applying/p16_1.png']).
attested_representation_use(set_grouping, measurement, one_to_one_correspondence, 3, ['JRME_Lo_1997_Developing/p10_1.png', 'JRME_Lo_1997_Developing/p9_1.png', 'ZDM_Lobato_2015_Leveraging/p8_2.png']).
attested_representation_use(set_grouping, measurement, base_ten_blocks_for_place_value, 1, ['ZDM_Garderen_2014_Challenges/p11_1.png']).
attested_representation_use(set_grouping, measurement, group_for_division_or_sharing, 1, ['ZDM_Lobato_2015_Leveraging/p8_1.png']).
attested_representation_use(set_grouping, measurement, subitize_or_make_ten, 1, ['JMB_Superfine_2009_Translation/p11_1.png']).
attested_representation_use(set_grouping, other, count_collection_with_counters, 4, ['JMB_Shiakalli_2014_Building/p11_1.png', 'JMB_Shiakalli_2014_Building/p11_2.png', 'JMB_Shiakalli_2014_Building/p12_1.png']).
attested_representation_use(set_grouping, other, base_ten_blocks_for_place_value, 1, ['ZDM_Garderen_2014_Challenges/p11_1.png']).
attested_representation_use(set_grouping, percent, count_collection_with_counters, 2, ['MERJ_Wright_2014_Frequencies/p10_1.png', 'MERJ_Wright_2014_Frequencies/p15_2.png']).
attested_representation_use(set_grouping, probability, count_collection_with_counters, 5, ['ESM_Abele_1978_Usage/p3_1.png', 'ESM_Abele_1978_Usage/p8_1.png', 'JRME_English_2016_Development/p18_1.png']).
attested_representation_use(set_grouping, proportional, count_collection_with_counters, 8, ['ESM_Bock_1998_Predominance/p9_1.png', 'ESM_Che_2012_Problem/p11_2.png', 'JMB_Nabors_2003_From/p30_1.png']).
attested_representation_use(set_grouping, proportional, one_to_one_correspondence, 3, ['JRME_Lo_1997_Developing/p10_1.png', 'JRME_Lo_1997_Developing/p9_1.png', 'ZDM_Lobato_2015_Leveraging/p8_2.png']).
attested_representation_use(set_grouping, proportional, group_for_division_or_sharing, 2, ['JRME_Empson_2003_Low-performing/p28_1.png', 'ZDM_Lobato_2015_Leveraging/p8_1.png']).
attested_representation_use(set_grouping, proportional, equal_groups_for_multiplication, 1, ['JMB_Nabors_2003_From/p30_3.png']).
attested_representation_use(set_grouping, ratio, count_collection_with_counters, 3, ['MERJ_Wright_2014_Frequencies/p10_1.png', 'MERJ_Wright_2014_Frequencies/p15_2.png', 'ZDM_Lobato_2015_Leveraging/p8_4.png']).
attested_representation_use(set_grouping, ratio, group_for_division_or_sharing, 1, ['ZDM_Lobato_2015_Leveraging/p8_1.png']).
attested_representation_use(set_grouping, ratio, one_to_one_correspondence, 1, ['ZDM_Lobato_2015_Leveraging/p8_2.png']).
attested_representation_use(set_grouping, rational, count_collection_with_counters, 1, ['JMB_Singer_2008_Between/p11_1.png']).
attested_representation_use(set_grouping, statistics, count_collection_with_counters, 1, ['ESM_Konold_2015_Data/p14_1.png']).
attested_representation_use(set_grouping, whole_number, count_collection_with_counters, 22, ['ESM_Neuman_1999_Early/p13_1.png', 'ESM_Neuman_1999_Early/p15_1.png', 'ESM_Treffers_1987_Integrated/p4_1.png']).
attested_representation_use(set_grouping, whole_number, equal_groups_for_multiplication, 13, ['ESM_Levenson_2013_Exploring/p7_1.png', 'ESM_Neuman_1999_Early/p17_1.png', 'ESM_Saenzludlow_1998_Third/p12_1.png']).
attested_representation_use(set_grouping, whole_number, group_for_division_or_sharing, 4, ['ESM_Neuman_1999_Early/p10_1.png', 'ESM_Neuman_1999_Early/p10_2.png', 'MTL_Whitenack_2001_Coordinating/p22_1.png']).
attested_representation_use(set_grouping, whole_number, one_to_one_correspondence, 3, ['JRME_Lo_1997_Developing/p10_1.png', 'JRME_Lo_1997_Developing/p9_1.png', 'ZDM_Lobato_2015_Leveraging/p8_2.png']).
attested_representation_use(set_grouping, whole_number, place_value_chart_for_columns, 2, ['ESM_Godino_2011_Why/p12_1.png', 'JMB_Lee_2007_Making/p10_2.png']).
attested_representation_use(set_grouping, whole_number, bar_model_for_multiplicative_reasoning, 1, ['JRME_Ng_2009_Model/p25_1.png']).
attested_representation_use(set_grouping, whole_number, base_ten_blocks_for_place_value, 1, ['ZDM_Garderen_2014_Challenges/p11_1.png']).
attested_representation_use(set_grouping, whole_number, subitize_or_make_ten, 1, ['JMB_Superfine_2009_Translation/p11_1.png']).

% --- denotation gaps ----------------------------------------------------
% A use pattern the grammar cannot denote: either it occurs under language=none
% (no spatial representation language) or it is a spatial verb the grammar has
% no render_spec for. FigureCount is the corpus support for the gap.
denotation_gap(none, manipulate_symbolic_notation, 437).
denotation_gap(none, sketch_graph_on_axes, 130).
denotation_gap(number_line, mark_intervals_on_number_line, 63).
denotation_gap(none, manipulate_algebraic_expression, 46).
denotation_gap(number_line, double_number_line_for_proportion, 35).
denotation_gap(number_line, represent_quantity_spatially, 27).
denotation_gap(none, solve_equation_symbolically, 26).
denotation_gap(none, pose_or_solve_word_problem, 25).
denotation_gap(area_model, partition_region_into_sections, 23).
denotation_gap(fraction_bars, partition_for_fraction_comparison, 22).
denotation_gap(number_line, sketch_graph_on_axes, 21).
denotation_gap(none, compute_with_written_algorithm, 20).
denotation_gap(fraction_bars, represent_quantity_spatially, 18).
denotation_gap(area_model, area_model_for_measurement, 17).
denotation_gap(none, evaluate_expression_symbolically, 16).
denotation_gap(fraction_bars, bar_model_for_multiplicative_reasoning, 15).
denotation_gap(none, cross_multiply_proportion, 15).
denotation_gap(set_grouping, one_to_one_correspondence, 15).
denotation_gap(set_grouping, group_for_division_or_sharing, 14).
denotation_gap(none, enumerate_combinations, 13).
denotation_gap(fraction_bars, partition_region_into_sections, 12).
denotation_gap(none, symbolic_calculus_argument, 11).
denotation_gap(area_model, bar_model_for_multiplicative_reasoning, 8).
denotation_gap(set_grouping, bar_model_for_multiplicative_reasoning, 5).
denotation_gap(number_line, partition_region_into_sections, 3).
denotation_gap(area_model, partition_for_fraction_comparison, 2).
denotation_gap(number_line, partition_for_fraction_comparison, 2).
denotation_gap(balance_scale, partition_for_fraction_comparison, 1).
denotation_gap(base_ten_blocks, partition_for_fraction_comparison, 1).
denotation_gap(number_line, bar_model_for_multiplicative_reasoning, 1).
denotation_gap(set_grouping, partition_for_fraction_comparison, 1).
denotation_gap(set_grouping, partition_region_into_sections, 1).

