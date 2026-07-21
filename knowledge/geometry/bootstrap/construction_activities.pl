% bootstrap/construction_activities.pl — Euclid-style constructions.
% Closed-world finite construction table for the current geometry KB.
% This file currently contributes no construction rows; future Euclid-style
% entries should add bootstrap/6, construction/5, and tier/4 evidence together.
% Schema: ../schema.pl

:- multifile bootstrap/6, construction/5, tier/4.
:- discontiguous bootstrap/6, construction/5, tier/4.

construction(perpendicular_bisector_paper_fold,
    "Construct a perpendicular bisector by folding paper",
    [paper, scissors],
    [fold_segment_endpoints_together,
     crease_the_fold,
     unfold_to_read_the_perpendicular_bisector],
    [n103_cd_3_1_perpendicular_bisector,
     medial_quadrilateral,
     equidistant_from_segment_endpoints]).

tier(ref(construction, perpendicular_bisector_paper_fold), 1,
     [n103_ch3],
     "N103 CD 3.1 turns a paper fold into a named construction/description activity; this row makes the construction schema slot non-empty without promoting every bootstrap activity to construction/5.").
