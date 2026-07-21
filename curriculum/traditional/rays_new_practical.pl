% curriculum/traditional/rays_new_practical.pl
%
% Cited comparison lessons drawn from Ray's arithmetic texts. The encodings are
% intentionally fair: they put efficient written algorithms and fact practice in
% play, while also naming real misconception surfaces from the existing registry.
:- multifile traditional_lesson/6.
:- discontiguous traditional_lesson/6.
:- multifile explicit_lesson_standard/4.
:- discontiguous explicit_lesson_standard/4.
:- multifile explicit_lesson_strategy/4.
:- discontiguous explicit_lesson_strategy/4.
:- multifile explicit_lesson_misconception/4.
:- discontiguous explicit_lesson_misconception/4.
:- multifile text_interpreter:explicit_lesson_text_source/2.
:- discontiguous text_interpreter:explicit_lesson_text_source/2.

ray_source(
    primary,
    source(
        ray_new_primary_arithmetic,
        "Ray's New Primary Arithmetic for Young Learners",
        "Smithsonian National Museum of American History object nmah_1842659",
        "https://www.si.edu/object/nmah_1842659")).
ray_source(
    practical,
    source(
        ray_new_practical_arithmetic,
        "Ray's New Practical Arithmetic",
        "Open Library edition OL7111104M / Google Books scan 1s5EAAAAIAAJ",
        "https://openlibrary.org/books/OL7111104M/Ray%27s_New_practical_arithmetic")).

ray_strategy_info(Operation, Kind, SourceKey, CitationKey, Note, Info) :-
    ray_source(SourceKey, Source),
    strategy_info(Operation, Kind, BaseInfo),
    append([ provenance(source_characterization),
             Source,
             citation(CitationKey, Note)
           ],
           BaseInfo,
           Info).

ray_misconception_info(Name, SourceKey, CitationKey, SourceNote, Info) :-
    ray_source(SourceKey, Source),
    misconception_registry_entry(Name, _Operation, Citation, Commitment, EntitlementLacked),
    misconception_info(Name,
                       Citation,
                       Commitment,
                       EntitlementLacked,
                       [ provenance(source_characterization),
                         Source,
                         citation(CitationKey, SourceNote)
                       ],
                       Info).

text_interpreter:explicit_lesson_text_source(Code, Path) :-
    traditional_lesson(Code, _, _, _, _, _),
    absolute_file_name(lessons('traditional/sources/rays_new_practical_notes.md'),
                       Path,
                       [access(read)]).

traditional_lesson('TRAD-RAY-G1-OA-C6-ADD-FACTS',
                   trad_ray_g1_addition_facts,
                   "Ray-style addition facts and word problems within 20",
                   grade(1),
                   unit(ray_primary),
                   lesson(addition_facts_within_20)).

explicit_lesson_standard('TRAD-RAY-G1-OA-C6-ADD-FACTS',
                         ccss,
                         '1.OA.C.6',
                         "Add and subtract within 20, demonstrating fluency for addition and subtraction within 10.").
explicit_lesson_standard('TRAD-RAY-G1-OA-C6-ADD-FACTS',
                         in_indiana,
                         '1.CA.1',
                         "Demonstrate fluency with addition facts and corresponding subtraction facts within 20.").

explicit_lesson_strategy('TRAD-RAY-G1-OA-C6-ADD-FACTS', addition, known_fact_retrieval, Info) :-
    ray_strategy_info(addition,
                      known_fact_retrieval,
                      primary,
                      ray_new_primary_arithmetic,
                      "Smithsonian characterizes Ray's New Primary Arithmetic as containing simple lessons on the four operations, largely equations and word problems.",
                      Info).
explicit_lesson_strategy('TRAD-RAY-G1-OA-C6-ADD-FACTS', addition, count_on_from_larger, Info) :-
    ray_strategy_info(addition,
                      count_on_from_larger,
                      primary,
                      ray_new_primary_arithmetic,
                      "A fair traditional facts lesson can include counting-on practice while centering accurate recall and written exercises.",
                      Info).
explicit_lesson_misconception('TRAD-RAY-G1-OA-C6-ADD-FACTS', Operation, count_all_instead_of_known_fact, Info) :-
    misconception_registry_entry(count_all_instead_of_known_fact, Operation, _Citation, _Commitment, _Entitlement),
    ray_misconception_info(count_all_instead_of_known_fact,
                           primary,
                           ray_new_primary_arithmetic,
                           "Fact-practice lessons can still put procedural counting instead of fact retrieval in play; this is an attested registry misconception, not an invented weakness.",
                           Info).

traditional_lesson('TRAD-RAY-G2-NBT-B5-COLUMN-ADD-SUB',
                   trad_ray_g2_column_add_sub,
                   "Ray-style column addition and subtraction within 100",
                   grade(2),
                   unit(ray_practical),
                   lesson(column_addition_subtraction_within_100)).

explicit_lesson_standard('TRAD-RAY-G2-NBT-B5-COLUMN-ADD-SUB',
                         ccss,
                         '2.NBT.B.5',
                         "Fluently add and subtract within 100 using strategies based on place value, properties of operations, and/or the relationship between addition and subtraction.").
explicit_lesson_standard('TRAD-RAY-G2-NBT-B5-COLUMN-ADD-SUB',
                         in_indiana,
                         '2.CA.2',
                         "Use number sense and place value strategies to add and subtract within 1,000, including composing and decomposing tens and hundreds.").

explicit_lesson_strategy('TRAD-RAY-G2-NBT-B5-COLUMN-ADD-SUB', addition, column_addition_with_carrying, Info) :-
    ray_strategy_info(addition,
                      column_addition_with_carrying,
                      practical,
                      ray_new_practical_arithmetic,
                      "Ray's New Practical Arithmetic includes sections for addition and subtraction with columnar written work and rules for operation.",
                      Info).
explicit_lesson_strategy('TRAD-RAY-G2-NBT-B5-COLUMN-ADD-SUB', addition, base_ones_chunking, Info) :-
    ray_strategy_info(addition,
                      base_ones_chunking,
                      practical,
                      ray_new_practical_arithmetic,
                      "Column addition depends on place-value decomposition into base chunks and ones, even when the written algorithm is foregrounded.",
                      Info).
explicit_lesson_strategy('TRAD-RAY-G2-NBT-B5-COLUMN-ADD-SUB', subtraction, decompose_base_for_ones, Info) :-
    ray_strategy_info(subtraction,
                      decompose_base_for_ones,
                      practical,
                      ray_new_practical_arithmetic,
                      "A fair traditional subtraction lesson foregrounds decomposition/regrouping for the written algorithm.",
                      Info).
explicit_lesson_misconception('TRAD-RAY-G2-NBT-B5-COLUMN-ADD-SUB', Operation, drop_carry_to_next_column, Info) :-
    misconception_registry_entry(drop_carry_to_next_column, Operation, _Citation, _Commitment, _Entitlement),
    ray_misconception_info(drop_carry_to_next_column,
                           practical,
                           ray_new_practical_arithmetic,
                           "The carried ten is a real risk surface in column addition, and the misconception registry supplies attested evidence for omitted carry.",
                           Info).
explicit_lesson_misconception('TRAD-RAY-G2-NBT-B5-COLUMN-ADD-SUB', Operation, borrow_without_reducing_bases, Info) :-
    misconception_registry_entry(borrow_without_reducing_bases, Operation, _Citation, _Commitment, _Entitlement),
    ray_misconception_info(borrow_without_reducing_bases,
                           practical,
                           ray_new_practical_arithmetic,
                           "The regrouping exchange in written subtraction can be performed incompletely; this is registry-attested.",
                           Info).

traditional_lesson('TRAD-RAY-G4-NBT-B4-MULTIDIGIT',
                   trad_ray_g4_multidigit_add_sub,
                   "Ray-style multi-digit addition and subtraction standard algorithms",
                   grade(4),
                   unit(ray_practical),
                   lesson(multidigit_addition_subtraction_algorithms)).

explicit_lesson_standard('TRAD-RAY-G4-NBT-B4-MULTIDIGIT',
                         ccss,
                         '4.NBT.B.4',
                         "Fluently add and subtract multi-digit whole numbers using the standard algorithm.").

explicit_lesson_strategy('TRAD-RAY-G4-NBT-B4-MULTIDIGIT', addition, column_addition_with_carrying, Info) :-
    ray_strategy_info(addition,
                      column_addition_with_carrying,
                      practical,
                      ray_new_practical_arithmetic,
                      "Ray's practical arithmetic treats written addition as a standard column algorithm for larger numbers.",
                      Info).
explicit_lesson_strategy('TRAD-RAY-G4-NBT-B4-MULTIDIGIT', subtraction, decompose_base_for_ones, Info) :-
    ray_strategy_info(subtraction,
                      decompose_base_for_ones,
                      practical,
                      ray_new_practical_arithmetic,
                      "Written subtraction with regrouping is represented here as decomposition of a base unit for ones.",
                      Info).
explicit_lesson_strategy('TRAD-RAY-G4-NBT-B4-MULTIDIGIT', subtraction, borrow_across_zero_cascade, Info) :-
    ray_strategy_info(subtraction,
                      borrow_across_zero_cascade,
                      practical,
                      ray_new_practical_arithmetic,
                      "Multi-digit subtraction practice puts in play the special case of borrowing across zeros.",
                      Info).
explicit_lesson_misconception('TRAD-RAY-G4-NBT-B4-MULTIDIGIT', Operation, wrong_carry_amount_to_next_column, Info) :-
    misconception_registry_entry(wrong_carry_amount_to_next_column, Operation, _Citation, _Commitment, _Entitlement),
    ray_misconception_info(wrong_carry_amount_to_next_column,
                           practical,
                           ray_new_practical_arithmetic,
                           "Carrying the wrong amount is an attested risk in multi-digit written addition.",
                           Info).
explicit_lesson_misconception('TRAD-RAY-G4-NBT-B4-MULTIDIGIT', Operation, smaller_from_larger_in_column, Info) :-
    misconception_registry_entry(smaller_from_larger_in_column, Operation, _Citation, _Commitment, _Entitlement),
    ray_misconception_info(smaller_from_larger_in_column,
                           practical,
                           ray_new_practical_arithmetic,
                           "Always subtracting the smaller digit from the larger is an attested risk in column subtraction.",
                           Info).

traditional_lesson('TRAD-RAY-G3-OA-C7-MULT-FACTS',
                   trad_ray_g3_multiplication_facts,
                   "Ray-style multiplication facts and equal-groups practice",
                   grade(3),
                   unit(ray_primary),
                   lesson(multiplication_facts_within_100)).

explicit_lesson_standard('TRAD-RAY-G3-OA-C7-MULT-FACTS',
                         ccss,
                         '3.OA.C.7',
                         "Fluently multiply and divide within 100 using strategies such as the relationship between multiplication and division or properties of operations.").

explicit_lesson_strategy('TRAD-RAY-G3-OA-C7-MULT-FACTS', multiplication, multiplication_fact_retrieval, Info) :-
    ray_strategy_info(multiplication,
                      multiplication_fact_retrieval,
                      primary,
                      ray_new_primary_arithmetic,
                      "Ray's primary arithmetic includes multiplication lessons and equation practice; a fair encoding foregrounds fact retrieval.",
                      Info).
explicit_lesson_strategy('TRAD-RAY-G3-OA-C7-MULT-FACTS', multiplication, repeat_equal_groups, Info) :-
    ray_strategy_info(multiplication,
                      repeat_equal_groups,
                      primary,
                      ray_new_primary_arithmetic,
                      "Word problems in a traditional arithmetic text can still put equal-groups interpretation in play.",
                      Info).
explicit_lesson_misconception('TRAD-RAY-G3-OA-C7-MULT-FACTS', Operation, context_free_fact_family_guess, Info) :-
    misconception_registry_entry(context_free_fact_family_guess, Operation, _Citation, _Commitment, _Entitlement),
    ray_misconception_info(context_free_fact_family_guess,
                           primary,
                           ray_new_primary_arithmetic,
                           "Fact retrieval can become disconnected from the contextualized unit structure; the misconception is registry-attested.",
                           Info).

traditional_lesson('TRAD-RAY-G5-NF-A1-FRACTION-ADD',
                   trad_ray_g5_fraction_addition,
                   "Ray-style common-denominator fraction addition",
                   grade(5),
                   unit(ray_practical),
                   lesson(unlike_denominator_fraction_addition)).

explicit_lesson_standard('TRAD-RAY-G5-NF-A1-FRACTION-ADD',
                         ccss,
                         '5.NF.A.1',
                         "Add and subtract fractions with unlike denominators by replacing given fractions with equivalent fractions.").
explicit_lesson_standard('TRAD-RAY-G5-NF-A1-FRACTION-ADD',
                         in_indiana,
                         '5.CA.3',
                         "Add and subtract fractions and mixed numbers with unlike denominators using strategies or the standard algorithm.").

explicit_lesson_strategy('TRAD-RAY-G5-NF-A1-FRACTION-ADD', fraction, co_denominator_make_base_transfer, Info) :-
    ray_strategy_info(fraction,
                      co_denominator_make_base_transfer,
                      practical,
                      ray_new_practical_arithmetic,
                      "Ray's New Practical Arithmetic includes common fractions and fraction addition; the fair encoding is common-denominator transformation before addition.",
                      Info).
explicit_lesson_strategy('TRAD-RAY-G5-NF-A1-FRACTION-ADD', fraction, co_denominator_count_on_from_larger, Info) :-
    ray_strategy_info(fraction,
                      co_denominator_count_on_from_larger,
                      practical,
                      ray_new_practical_arithmetic,
                      "After common-denominator transformation, same-unit numerator accumulation can reuse additive counting structure.",
                      Info).
explicit_lesson_misconception('TRAD-RAY-G5-NF-A1-FRACTION-ADD', Operation, add_across_unlike, Info) :-
    misconception_registry_entry(add_across_unlike, Operation, _Citation, _Commitment, _Entitlement),
    ray_misconception_info(add_across_unlike,
                           practical,
                           ray_new_practical_arithmetic,
                           "Procedural fraction addition can put the attested add-across-unlike-denominators risk in play.",
                           Info).
