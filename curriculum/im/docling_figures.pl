/** <module> docling_figure facts for literature-exemplar figures
 *
 * GENERATED FILE -- do not hand-edit. Regenerate from the docling figure
 * extraction with the Phase 0 generator (see
 * docs/proposals/2026-06-18-student-work-images-todo.md).
 *
 * One fact per extracted figure whose bibtex_key is cited by a
 * lesson-attached misconception in knowledge/misconceptions/misconception_registry.pl.
 * This is the *bibkey-level* join: a figure here documents the cited
 * misconception's literature source, NOT a child's response to a specific
 * IM lesson's numerals. Label any rendered artifact as a literature exemplar.
 *
 * docling_figure(BibKey, RelPath, PageNo, OnCandidatePage, Caption).
 *   BibKey          -- bibtex key shared with citation/2 in the registry
 *   RelPath         -- repo-relative path to the cropped PNG
 *   PageNo          -- source page number (page-level precision, partial)
 *   OnCandidatePage -- docling's candidate-page flag (weak student-work signal)
 *   Caption         -- docling caption (largely empty; '' when absent)
 *
 * Source: docs/research_assets/research/2026-06-18-docling-figures.jsonl
 */
:- module(docling_figures, [ docling_figure/5 ]).

docling_figure('ESM_Bell_1981_Choice', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ESM_Bell_1981_Choice/p17_1.png', 17, false, '').
docling_figure('ESM_Bell_1981_Choice', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ESM_Bell_1981_Choice/p19_2.png', 19, false, '').
docling_figure('ESM_Gray_1999_Knowledge', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ESM_Gray_1999_Knowledge/p16_1.png', 16, false, '').
docling_figure('ESM_Hasemann_1981_Difficulties', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ESM_Hasemann_1981_Difficulties/p9_1.png', 9, false, '').
docling_figure('ESM_Kidron_2008_Abstraction', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ESM_Kidron_2008_Abstraction/p14_1.png', 14, false, '').
docling_figure('ESM_Neuman_1999_Early', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ESM_Neuman_1999_Early/p10_1.png', 10, false, '').
docling_figure('ESM_Neuman_1999_Early', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ESM_Neuman_1999_Early/p10_2.png', 10, false, '').
docling_figure('ESM_Neuman_1999_Early', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ESM_Neuman_1999_Early/p13_1.png', 13, false, '').
docling_figure('ESM_Neuman_1999_Early', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ESM_Neuman_1999_Early/p15_1.png', 15, false, '').
docling_figure('ESM_Neuman_1999_Early', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ESM_Neuman_1999_Early/p17_1.png', 17, false, '').
docling_figure('ESM_Neuman_1999_Early', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ESM_Neuman_1999_Early/p18_1.png', 18, false, '').
docling_figure('ESM_Son_2016_Moving', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ESM_Son_2016_Moving/p6_1.png', 6, false, '').
docling_figure('ESM_Son_2016_Moving', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ESM_Son_2016_Moving/p17_1.png', 17, true, '').
docling_figure('ESM_Son_2016_Moving', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ESM_Son_2016_Moving/p22_1.png', 22, true, '').
docling_figure('ESM_Treffers_1993_Wiskobas', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ESM_Treffers_1993_Wiskobas/p8_1.png', 8, false, '').
docling_figure('IJMEST_Herrera_2011_Addition', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/IJMEST_Herrera_2011_Addition/p11_1.png', 11, false, '').
docling_figure('IJMEST_Herrera_2011_Addition', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/IJMEST_Herrera_2011_Addition/p11_2.png', 11, false, '').
docling_figure('IJMEST_Herrera_2011_Addition', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/IJMEST_Herrera_2011_Addition/p11_3.png', 11, false, '').
docling_figure('IJMEST_Herrera_2011_Addition', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/IJMEST_Herrera_2011_Addition/p13_1.png', 13, false, '').
docling_figure('IJMEST_Herrera_2011_Addition', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/IJMEST_Herrera_2011_Addition/p15_1.png', 15, false, '').
docling_figure('IJMEST_Sahin_2016_Examining', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/IJMEST_Sahin_2016_Examining/p6_1.png', 6, false, '').
docling_figure('IJMEST_Sahin_2016_Examining', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/IJMEST_Sahin_2016_Examining/p8_1.png', 8, false, '').
docling_figure('IJMEST_Sahin_2016_Examining', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/IJMEST_Sahin_2016_Examining/p10_1.png', 10, false, '').
docling_figure('IJMEST_Sahin_2016_Examining', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/IJMEST_Sahin_2016_Examining/p12_1.png', 12, false, '').
docling_figure('IJMEST_Sahin_2016_Examining', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/IJMEST_Sahin_2016_Examining/p14_1.png', 14, false, '').
docling_figure('IJMEST_Sahin_2016_Examining', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/IJMEST_Sahin_2016_Examining/p16_1.png', 16, false, '').
docling_figure('IJMEST_Sahin_2016_Examining', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/IJMEST_Sahin_2016_Examining/p22_1.png', 22, false, '').
docling_figure('JMB_Ebby_2005_Powers', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JMB_Ebby_2005_Powers/p6_1.png', 6, true, '').
docling_figure('JMB_Norton_2015_Provoking', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JMB_Norton_2015_Provoking/p8_1.png', 8, true, '').
docling_figure('JMB_Norton_2015_Provoking', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JMB_Norton_2015_Provoking/p11_1.png', 11, true, '').
docling_figure('JMB_Norton_2015_Provoking', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JMB_Norton_2015_Provoking/p18_1.png', 18, true, '').
docling_figure('JMB_Nosrati_2015_Temporal', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JMB_Nosrati_2015_Temporal/p4_1.png', 4, true, '').
docling_figure('JMB_Nosrati_2015_Temporal', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JMB_Nosrati_2015_Temporal/p4_2.png', 4, true, '').
docling_figure('JMB_Nosrati_2015_Temporal', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JMB_Nosrati_2015_Temporal/p8_1.png', 8, true, '').
docling_figure('JMB_Nosrati_2015_Temporal', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JMB_Nosrati_2015_Temporal/p8_2.png', 8, true, '').
docling_figure('JMB_Nosrati_2015_Temporal', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JMB_Nosrati_2015_Temporal/p9_1.png', 9, true, '').
docling_figure('JMB_Nosrati_2015_Temporal', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JMB_Nosrati_2015_Temporal/p9_2.png', 9, true, '').
docling_figure('JMB_Nosrati_2015_Temporal', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JMB_Nosrati_2015_Temporal/p11_1.png', 11, true, '').
docling_figure('JMB_Olive_2006_Making', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JMB_Olive_2006_Making/p5_1.png', 5, true, '').
docling_figure('JMB_Olive_2006_Making', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JMB_Olive_2006_Making/p8_1.png', 8, true, '').
docling_figure('JMB_Olive_2006_Making', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JMB_Olive_2006_Making/p11_1.png', 11, true, '').
docling_figure('JMB_Olive_2006_Making', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JMB_Olive_2006_Making/p16_1.png', 16, true, '').
docling_figure('JMB_Olive_2006_Making', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JMB_Olive_2006_Making/p17_1.png', 17, true, '').
docling_figure('JMB_Olive_2006_Making', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JMB_Olive_2006_Making/p18_1.png', 18, true, '').
docling_figure('JMB_Olive_2006_Making', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JMB_Olive_2006_Making/p22_1.png', 22, true, '').
docling_figure('JMB_Olive_2006_Making', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JMB_Olive_2006_Making/p24_1.png', 24, true, '').
docling_figure('JMB_Olive_2006_Making', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JMB_Olive_2006_Making/p25_1.png', 25, true, '').
docling_figure('JMB_Osana_2011_Obstacles', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JMB_Osana_2011_Obstacles/p7_1.png', 7, true, '').
docling_figure('JMB_Osana_2011_Obstacles', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JMB_Osana_2011_Obstacles/p13_1.png', 13, true, '').
docling_figure('JMB_Osana_2011_Obstacles', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JMB_Osana_2011_Obstacles/p14_1.png', 14, true, '').
docling_figure('JMB_Osana_2011_Obstacles', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JMB_Osana_2011_Obstacles/p15_1.png', 15, true, '').
docling_figure('JMB_Osana_2011_Obstacles', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JMB_Osana_2011_Obstacles/p16_1.png', 16, true, '').
docling_figure('JMTE_Santagata_2014_Learning', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JMTE_Santagata_2014_Learning/p13_1.png', 13, true, '').
docling_figure('JMTE_Steinberg_2004_Inquiry', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JMTE_Steinberg_2004_Inquiry/p19_1.png', 19, true, '').
docling_figure('JRME_Bray_2011_Collective', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JRME_Bray_2011_Collective/p19_1.png', 19, true, '').
docling_figure('JRME_Bray_2011_Collective', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JRME_Bray_2011_Collective/p21_1.png', 21, true, '').
docling_figure('JRME_Bray_2011_Collective', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JRME_Bray_2011_Collective/p23_1.png', 23, true, '').
docling_figure('JRME_Izsak_2017_Preservice', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JRME_Izsak_2017_Preservice/p18_1.png', 18, true, '').
docling_figure('JRME_Izsak_2017_Preservice', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JRME_Izsak_2017_Preservice/p22_1.png', 22, true, '').
docling_figure('JRME_Izsak_2017_Preservice', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JRME_Izsak_2017_Preservice/p25_1.png', 25, true, '').
docling_figure('JRME_Izsak_2017_Preservice', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JRME_Izsak_2017_Preservice/p27_1.png', 27, true, '').
docling_figure('JRME_Izsak_2017_Preservice', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JRME_Izsak_2017_Preservice/p31_1.png', 31, true, '').
docling_figure('JRME_Izsak_2017_Preservice', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JRME_Izsak_2017_Preservice/p32_1.png', 32, true, '').
docling_figure('JRME_Izsak_2017_Preservice', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JRME_Izsak_2017_Preservice/p33_1.png', 33, true, '').
docling_figure('JRME_Whitacre_2016_Prospective', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/JRME_Whitacre_2016_Prospective/p21_1.png', 21, true, '').
docling_figure('MTL_Bonotto_2005_How', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/MTL_Bonotto_2005_How/p18_1.png', 18, false, '').
docling_figure('MTL_Izsak_2004_Teaching', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/MTL_Izsak_2004_Teaching/p28_1.png', 28, false, '').
docling_figure('MTL_Izsak_2004_Teaching', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/MTL_Izsak_2004_Teaching/p29_1.png', 29, false, '').
docling_figure('MTL_Izsak_2004_Teaching', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/MTL_Izsak_2004_Teaching/p30_1.png', 30, false, '').
docling_figure('MTL_Izsak_2004_Teaching', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/MTL_Izsak_2004_Teaching/p31_1.png', 31, false, '').
docling_figure('MTL_Izsak_2004_Teaching', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/MTL_Izsak_2004_Teaching/p33_1.png', 33, false, '').
docling_figure('MTL_Whitenack_2001_Coordinating', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/MTL_Whitenack_2001_Coordinating/p19_1.png', 19, false, '').
docling_figure('MTL_Whitenack_2001_Coordinating', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/MTL_Whitenack_2001_Coordinating/p22_1.png', 22, false, '').
docling_figure('MTL_Whitenack_2001_Coordinating', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/MTL_Whitenack_2001_Coordinating/p24_1.png', 24, false, '').
docling_figure('ZDM_Broza_2015_Contingent', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ZDM_Broza_2015_Contingent/p9_1.png', 9, true, '').
docling_figure('ZDM_Broza_2015_Contingent', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ZDM_Broza_2015_Contingent/p9_2.png', 9, true, '').
docling_figure('ZDM_Lobato_2015_Leveraging', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ZDM_Lobato_2015_Leveraging/p2_1.png', 2, true, '').
docling_figure('ZDM_Lobato_2015_Leveraging', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ZDM_Lobato_2015_Leveraging/p6_1.png', 6, true, '').
docling_figure('ZDM_Lobato_2015_Leveraging', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ZDM_Lobato_2015_Leveraging/p8_1.png', 8, true, '').
docling_figure('ZDM_Lobato_2015_Leveraging', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ZDM_Lobato_2015_Leveraging/p8_2.png', 8, true, '').
docling_figure('ZDM_Lobato_2015_Leveraging', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ZDM_Lobato_2015_Leveraging/p8_3.png', 8, true, '').
docling_figure('ZDM_Lobato_2015_Leveraging', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ZDM_Lobato_2015_Leveraging/p8_4.png', 8, true, '').
docling_figure('ZDM_Lobato_2015_Leveraging', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ZDM_Lobato_2015_Leveraging/p9_1.png', 9, true, '').
docling_figure('ZDM_Lobato_2015_Leveraging', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ZDM_Lobato_2015_Leveraging/p9_2.png', 9, true, '').
docling_figure('ZDM_Lobato_2015_Leveraging', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ZDM_Lobato_2015_Leveraging/p10_1.png', 10, true, '').
docling_figure('ZDM_Lobato_2015_Leveraging', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ZDM_Lobato_2015_Leveraging/p11_1.png', 11, true, '').
docling_figure('ZDM_Lobato_2015_Leveraging', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ZDM_Lobato_2015_Leveraging/p11_2.png', 11, true, '').
docling_figure('ZDM_Lobato_2015_Leveraging', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ZDM_Lobato_2015_Leveraging/p11_3.png', 11, true, '').
docling_figure('ZDM_Lobato_2015_Leveraging', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ZDM_Lobato_2015_Leveraging/p12_1.png', 12, true, '').
docling_figure('ZDM_Lobato_2015_Leveraging', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ZDM_Lobato_2015_Leveraging/p13_1.png', 13, true, '').
docling_figure('ZDM_Lobato_2015_Leveraging', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ZDM_Lobato_2015_Leveraging/p14_1.png', 14, true, '').
docling_figure('ZDM_Lobato_2015_Leveraging', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ZDM_Lobato_2015_Leveraging/p14_2.png', 14, true, '').
docling_figure('ZDM_Sembiring_2008_Reforming', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ZDM_Sembiring_2008_Reforming/p4_1.png', 4, false, '').
docling_figure('ZDM_Sembiring_2008_Reforming', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ZDM_Sembiring_2008_Reforming/p10_1.png', 10, false, '').
docling_figure('ZDM_Sembiring_2008_Reforming', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ZDM_Sembiring_2008_Reforming/p10_2.png', 10, false, '').
docling_figure('ZDM_Sembiring_2008_Reforming', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ZDM_Sembiring_2008_Reforming/p12_1.png', 12, false, '').
docling_figure('ZDM_Sembiring_2008_Reforming', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ZDM_Sembiring_2008_Reforming/p12_2.png', 12, false, '').
docling_figure('ZDM_Sembiring_2008_Reforming', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ZDM_Sembiring_2008_Reforming/p12_3.png', 12, false, '').
docling_figure('ZDM_Sembiring_2008_Reforming', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ZDM_Sembiring_2008_Reforming/p12_4.png', 12, false, '').
docling_figure('ZDM_Sriraman_2017_Mathematical', 'docs/research_assets/research/student_work_figures/2026-06-18-docling-figures/ZDM_Sriraman_2017_Mathematical/p6_1.png', 6, true, '').
