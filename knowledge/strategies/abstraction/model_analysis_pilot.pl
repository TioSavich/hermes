:- encoding(utf8).
/** <module> Attributed store for coverage-grind model-authored problem analyses
 *
 * Nothing imports this module; rows are vetoable one by one; admission to
 * anything canonical happens only by ceremony.
 *
 * scripts/coverage/propose_verify_driver.py asks a small local model to
 * analyze one IM story problem into quantities (each anchored to a verbatim
 * substring of the problem), a restated ask, arithmetic steps, and an
 * answer. Five deterministic gates decide admission on the node and again
 * at collection (scripts/coverage/merge_and_regate.py replays every gate
 * locally before a row is trusted); nothing the model said becomes a row
 * here without surviving them. A gate-admitted row still carries an oracle
 * tier from gate 5: `oracle_matched` (the answer matches a known-correct
 * oracle value), `unoracled_executable` (no oracle exists to check
 * against, but the steps execute exactly to the stated answer), or
 * `oracle_mismatched_held` (the answer executes but disagrees with an
 * oracle that does exist — most often because the oracle itself answers an
 * intermediate sub-problem, the pattern this repo calls the Han 33/4
 * pattern). HELD-tier rows are excluded from this store and await
 * adjudication; scripts/coverage/build_model_analysis_store.py counts them
 * in model_analysis_held_excluded/1 rather than dropping them from sight.
 *
 * VOCABULARY DIVERSITY RULE. The model's own kind and operation vocabulary
 * — "unit_or_kind" on a quantity, "operation" on a step, "kind" on an
 * answer — is recorded verbatim as a quoted Prolog string, exactly as the
 * model wrote it, under the 2026-08-18 diversity-over-abstraction ruling.
 * "meters east of the camera" and "dollars per egg" sit beside "number"
 * unchanged; none of it is mapped onto this repository's canonical
 * quantity or operation vocabulary. Two model backends contributed rows —
 * a local llama-server on Big Red (`model('local')`) and REALLMS-hosted
 * gemma-4-31B-it (`model('gemma-4-31B-it')`) — and each row is attributed
 * to whichever one actually produced it.
 *
 * check_model_analysis_pilot/0 re-derives every stored row's arithmetic
 * independently: every step's operands and result are decoded into exact
 * SWI rationals through g8_quantity_input.pl's g8_quantity/2 (the same
 * decoder the six grade-8 pilots use; `rationalize/1` recovers the exact
 * decimal a JSON float like 0.00034 or 11.55 was written from, verified
 * against every distinct float the ledger contains at each rebuild), the
 * operation name is read through a hand-built table naming every operation
 * string this module has ever seen, and the folded result must equal the
 * stored result exactly — `=:=` on exact rationals, never `=~=` on floats.
 * The stored answer must equal ANY step's result, not only the last one —
 * verified live by im_defrag_c9877aaf92acf187936f38a6_1 (a divide-then-
 * verify-by-multiplying problem, tier unoracled_executable), whose answer
 * names an earlier step rather than its last one: the built store still
 * exercises the any-step-not-just-the-last rule this store's check shares
 * with propose_verify_driver.py's gate 3. Every stored statement sha is
 * re-hashed from the stored statement text and compared to the stored
 * anchor; every stored tier is checked against the two tiers this store
 * admits. Any failure throws, naming the row.
 *
 * Check from the repository root:
 * `swipl -q -l paths.pl -l knowledge/strategies/abstraction/model_analysis_pilot.pl -g model_analysis_pilot:check_model_analysis_pilot -t halt`
 *
 * PROVENANCE (content shas, not timestamps):
 *   ledger  sha256=a02d69e1afb54df43e4ecd9358e0ed61561606e7f451d6a1a906f7c30cf6e515  (hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl)
 *   targets sha256=48b380398462a54ed9a3eabf81decd40e1ea497a9c5606488de1fabc4e35b8f2  (hermes/app/runtime/experiments/coverage_grind/uncovered_targets.jsonl)
 *   targets sha256=6bc4ecf73dc93f821b6f43c45e64a44b2263aebeaa016b9e15f9bf128f4b016d  (hermes/app/runtime/experiments/coverage_grind/retry_targets.jsonl)
 */

:- module(model_analysis_pilot,
          [ model_analysis_row/6,
            model_analysis_held_excluded/1,
            model_analysis_summary/1,
            check_model_analysis_pilot/0
          ]).

:- use_module(library(sha)).
:- use_module(strategies('abstraction/g8_quantity_input'), [ g8_quantity/2 ]).

:- dynamic model_analysis_row/6.

%! check_model_analysis_pilot is det.
%
%  Record ids are unique, every row's steps reproduce its answer under
%  exact rational arithmetic, every statement sha reproduces from the
%  stored statement text, and every tier is one this store admits.
check_model_analysis_pilot :-
    findall(Id, model_analysis_row(Id, _, _, _, _, _), Ids),
    sort(Ids, Unique),
    length(Ids, Count),
    length(Unique, Count),
    forall(model_analysis_row(Id, Text, Analysis, Anchor, Testimony, Receipt),
           check_stored_row(Id, Text, Analysis, Anchor, Testimony, Receipt)),
    format('model_analysis_pilot: all ~d row receipts passed~n', [Count]).

check_stored_row(Id, Text, Analysis, Anchor, Testimony, Receipt) :-
    Anchor = anchor(lesson(Lesson), grade(Grade), record_id(Id), statement_sha(Sha)),
    atom(Lesson), atom(Grade), atom(Sha),
    Testimony = testimony(model(_), backend(_), job(_), date(_), tier(Tier)),
    ( valid_stored_tier(Tier)
    -> true
    ;  throw(error(model_analysis_pilot(bad_tier(Id, Tier)), _))
    ),
    Receipt == receipt(swipl_test([steps_reproduce_answer, statement_sha_verified,
                                   tier_valid])),
    sha256_hex(Text, ComputedSha),
    ( ComputedSha == Sha
    -> true
    ;  throw(error(model_analysis_pilot(sha_mismatch(Id, ComputedSha, Sha)), _))
    ),
    Analysis = analysis(quantities(Qs), ask(_), steps(Steps), answer(AnswerValue, _),
                        missing_doing(_)),
    is_list(Qs),
    is_list(Steps),
    Steps \== [],
    forall(member(step(Op, Operands, Result), Steps),
           ( verify_step(Op, Operands, Result)
           -> true
           ;  throw(error(model_analysis_pilot(step_not_reproduced(Id, Op, Operands, Result)), _))
           )),
    findall(R, member(step(_, _, R), Steps), Results),
    ( member(R2, Results), answer_matches(AnswerValue, R2)
    -> true
    ;  throw(error(model_analysis_pilot(answer_not_a_step_result(Id, AnswerValue, Results)), _))
    ).

%! valid_stored_tier(+Tier) is semidet.
%
%  Only the two tiers this store admits. oracle_mismatched_held rows never
%  reach model_analysis_row/6 in the first place (the builder excludes
%  them), so seeing that tier here would mean the builder's own exclusion
%  broke, not that the row is merely unwelcome.
valid_stored_tier(oracle_matched).
valid_stored_tier(unoracled_executable).

%! verify_step(+Operation, +Operands, +Result) is semidet.
%
%  A claim-verdict step (compare_equal) decodes both operands and compares
%  them for exact rational equality against the stored boolean result. An
%  arithmetic step decodes every operand, left-folds the named operation
%  across them exactly as propose_verify_driver.py's gate 3 does (operand
%  list order matters for - and /), and requires the fold to equal the
%  decoded stored result exactly.
verify_step(Op, [A, B], Result) :-
    claim_operation(Op),
    !,
    g8_quantity(A, RA),
    g8_quantity(B, RB),
    ( RA =:= RB -> Computed = true ; Computed = false ),
    Result == Computed.
verify_step(Op, Operands, Result) :-
    op_symbol(Op, Sym),
    Operands = [_ | Rest],
    Rest \== [],
    maplist(g8_quantity, Operands, [RFirst | RRest]),
    foldl(apply_symbol(Sym), RRest, RFirst, Computed),
    g8_quantity(Result, Expected),
    Computed =:= Expected.

apply_symbol(+, B, A, R) :- R is A + B.
apply_symbol(-, B, A, R) :- R is A - B.
apply_symbol(*, B, A, R) :- R is A * B.
apply_symbol(/, B, A, R) :- B =\= 0, R is A / B.
apply_symbol(^, B, A, R) :- integer(B), R is A ^ B.

%! op_symbol(+OperationString, -Symbol) is semidet.
%
%  Every verbatim arithmetic step-operation string the ledger contains,
%  read off the ledger itself as merges land, not invented ahead of it.
%  "addition_of_decimal_places" names a step that really does add two
%  decimal-place counts, so it maps to +, matching
%  propose_verify_driver.py's own OP_TABLE substring match on "addition".
op_symbol("addition", +).
op_symbol("add", +).
op_symbol("addition_of_decimal_places", +).
op_symbol("subtraction", -).
op_symbol("subtract", -).
op_symbol("-", -).
op_symbol("multiplication", *).
op_symbol("multiply", *).
op_symbol("*", *).
op_symbol("division", /).
op_symbol("divide", /).
op_symbol("exponentiation", ^).

%! claim_operation(+OperationString) is semidet.
%
%  Claim-verdict operation strings the ledger contains. Both compare a
%  step's two operands for exact equality and check the claimed boolean
%  against that — compare_less_equal is not decoded as a genuine <=, it is
%  admitted under propose_verify_driver.py gate 3's own substring rule
%  (any operation name containing "compare"/"equal"/"verify"/"check" is
%  read as an equality claim), and this predicate mirrors that reading
%  rather than inventing a stricter comparison the admission gate never
%  applied.
claim_operation("compare_equal").
claim_operation("compare_less_equal").

%! answer_matches(+AnswerValue, +StepResult) is semidet.
%
%  A boolean answer must meet an identical boolean step result; a numeric
%  answer must meet a numeric step result at exact rational equality. A
%  boolean is never compared to a number or vice versa.
answer_matches(true, R) :- !, R == true.
answer_matches(false, R) :- !, R == false.
answer_matches(V, R) :-
    R \== true, R \== false,
    g8_quantity(V, RV),
    g8_quantity(R, RR),
    RV =:= RR.

%! sha256_hex(+Text, -HexAtom) is det.
%
%  The same digest scripts/coverage/build_model_analysis_store.py takes
%  over the UTF-8 bytes of the statement text, so a stored sha anchors a
%  row to the exact bytes the model read rather than a re-typed
%  approximation.
sha256_hex(Text, Atom) :-
    text_to_string(Text, String),
    sha_hash(String, Hash, [algorithm(sha256), encoding(utf8)]),
    hash_atom(Hash, Atom).

%! model_analysis_summary(-Summary) is det.
model_analysis_summary(summary(row_count(RowCount), held_excluded(HeldCount),
                               by_tier(TierPairs), by_grade(GradePairs))) :-
    aggregate_all(count, model_analysis_row(_, _, _, _, _, _), RowCount),
    model_analysis_held_excluded(HeldCount),
    by_tier_counts(TierPairs),
    by_grade_counts(GradePairs).

by_tier_counts(Pairs) :-
    findall(T, model_analysis_row(_, _, _, _, testimony(_, _, _, _, tier(T)), _), Ts),
    sort(Ts, Tiers),
    findall(T-N,
           ( member(T, Tiers),
             aggregate_all(count,
                           model_analysis_row(_, _, _, _, testimony(_, _, _, _, tier(T)), _),
                           N)
           ),
           Pairs).

by_grade_counts(Pairs) :-
    findall(G, model_analysis_row(_, _, _, anchor(_, grade(G), _, _), _, _), Gs),
    sort(Gs, Grades),
    findall(G-N,
           ( member(G, Grades),
             aggregate_all(count,
                           model_analysis_row(_, _, _, anchor(_, grade(G), _, _), _, _),
                           N)
           ),
           Pairs).


% GENERATED ROWS FOLLOW. Do not edit by hand; re-run
% scripts/coverage/build_model_analysis_store.py. Source: the 760 gate=="admitted" rows of
% hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl,
% minus 21 tier=="oracle_mismatched_held" rows held for adjudication (counted below, not stored).
% 739 rows follow, sorted by record_id.

model_analysis_held_excluded(21).

model_analysis_row('im_defrag_001da0ea156ff2f9ed7ff1dd_1', "Find the value of 10² + 5²",
    analysis(
        quantities([quantity(10, "number", "10"), quantity(5, "number", "5")]),
        ask("What is the value of 10 squared plus 5 squared?"),
        steps([step("exponentiation", [10, 2], 100), step("exponentiation", [5, 2], 25), step("addition", [100, 25], 125)]),
        answer(125, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U7-L5'), grade('6'), record_id('im_defrag_001da0ea156ff2f9ed7ff1dd_1'), statement_sha('b3499c054877b48b72bb2358ad48d0f434e4c7065ed42f4f80c9de6630125038')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_009fe39a7e03b19a480c971c_1', "64 = 50 + 14",
    analysis(
        quantities([quantity(64, "number", "64"), quantity(50, "number", "50"), quantity(14, "number", "14")]),
        ask("Is 64 equal to the sum of 50 and 14?"),
        steps([step("addition", [50, 14], 64), step("compare_equal", [64, 64], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U2-L6'), grade('2'), record_id('im_defrag_009fe39a7e03b19a480c971c_1'), statement_sha('da893311e309dc6552422374d3e100b49397f4a15d78f795326f82a2a17d8e2f')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_00c368b6357cc4463ab6a3ff_1', "2. Some students play with chalk. 7 students draw pictures. 2 students write their names. How many students play with chalk altogether?",
    analysis(
        quantities([quantity(7, "students", "7 students"), quantity(2, "students", "2 students")]),
        ask("How many students play with chalk altogether?"),
        steps([step("addition", [7, 2], 9)]),
        answer(9, "students"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U2-L19'), grade('1'), record_id('im_defrag_00c368b6357cc4463ab6a3ff_1'), statement_sha('53d52c7d76aaf87432bc4d624386d01bddb2fd6e7054cee07df72e1a55ed6a23')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_01751b2e178ff2478c88306d_1', "12 eggs for $3. How much is the cost per egg?",
    analysis(
        quantities([quantity(12, "eggs", "12 eggs"), quantity(3, "dollars", "$3")]),
        ask("What is the cost of a single egg?"),
        steps([step("division", [3, 12], 0.25)]),
        answer(0.25, "dollars per egg"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L8'), grade('6'), record_id('im_defrag_01751b2e178ff2478c88306d_1'), statement_sha('861eea7b4a045aaebbd67a94aba0a7c1149cec7f70a1ceb212848c2384b37222')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_019cf3f01712af8e5aa6e56b_1', "If the big red wagon is 27 feet long, 13 feet wide, and 2 feet deep, what is the volume of the wagon?",
    analysis(
        quantities([quantity(27, "feet", "27 feet"), quantity(13, "feet", "13 feet"), quantity(2, "feet", "2 feet")]),
        ask("What is the volume of the big red wagon?"),
        steps([step("multiply", [27, 13], 351), step("multiply", [351, 2], 702)]),
        answer(702, "cubic feet"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U8-L7'), grade('5'), record_id('im_defrag_019cf3f01712af8e5aa6e56b_1'), statement_sha('13027ee1c9a6ecbce0c90950f1bfd023f332c6969e7be1a48cc4c26d176fffb5')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_01bc6760061fdc506f9ce23c_1', "1. Clare donates 48 books. Clare donates 6 times as many books as Andre. a. Draw a diagram to represent the situation. b. How many books does Andre donate? Explain your reasoning. 2. Han says he can figure out the number of books Andre donates, using division. Tyler says we have to use multiplication because it says “times as many.” a. Do you agree with Han or Tyler? Explain your reasoning. b. Write an equation to represent Tyler’s thinking. c. Write an equation to represent Han’s thinking. 3. Elena donates 9 times as many books as Diego. Elena donates 81 books. Use multiplication or division to find the number of books Diego donates.",
    analysis(
        quantities([quantity(48, "books", "48 books"), quantity(6, "times", "6 times"), quantity(9, "times", "9 times"), quantity(81, "books", "81 books")]),
        ask("Find the number of books Diego donates given that Elena donates 81 books, which is 9 times as many as Diego."),
        steps([step("division", [81, 9], 9)]),
        answer(9, "books"),
        missing_doing("conceptual understanding of part-whole relationships")),
    anchor(lesson('IM-G4-U5-L3'), grade('4'), record_id('im_defrag_01bc6760061fdc506f9ce23c_1'), statement_sha('346cfe21a6607d8c3338d1a5c10aa8885eba1ab4a4441fcbbe38ee6cc34a4904')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_0201fc4c1d991d9d488e73cb_1', "4 × 10 = 40 × 1",
    analysis(
        quantities([quantity(4, "number", "4"), quantity(10, "number", "10"), quantity(40, "number", "40"), quantity(1, "number", "1")]),
        ask("Check if 4 times 10 equals 40 times 1."),
        steps([step("multiplication", [4, 10], 40), step("multiplication", [40, 1], 40), step("compare_equal", [40, 40], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L19'), grade('3'), record_id('im_defrag_0201fc4c1d991d9d488e73cb_1'), statement_sha('9f8189c81806be072ce4f2f4dd4c32557e23a81ebd54e6d9e3eadbe0fa46bdd2')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_02270dc87a3c3ee1d46a8f31_1', "How much would 860 bottles be worth? 860 ÷ 20 = 43",
    analysis(
        quantities([quantity(860, "bottles", "860 bottles"), quantity(20, "bottles per pack", "20")]),
        ask("How much would 860 bottles be worth?"),
        steps([step("divide", [860, 20], 43)]),
        answer(43, "units of value"),
        missing_doing("the problem does not specify the price per unit/pack, so the 'worth' is calculated as the number of units of 20")),
    anchor(lesson('IM-G7-U2-L6'), grade('7'), record_id('im_defrag_02270dc87a3c3ee1d46a8f31_1'), statement_sha('7ccdc88d18a0dcad203e2f1be2b2378b33ad3aacfa7446ac1ba8cc25f58b0b24')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_3.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_02598cd1c14ff86e41789a12_1', "10 + 4 = 10 + 5",
    analysis(
        quantities([quantity(10, "number", "10"), quantity(4, "number", "4"), quantity(10, "number", "10"), quantity(5, "number", "5")]),
        ask("Check if the equation 10 + 4 = 10 + 5 is true."),
        steps([step("addition", [10, 4], 14), step("addition", [10, 5], 15), step("compare_equal", [14, 15], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L11'), grade('1'), record_id('im_defrag_02598cd1c14ff86e41789a12_1'), statement_sha('ec371ee4f45235cf9aa9b3854a1cdca63053c157a20b935e01369ed90c08a6dd')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_026e5ff8d631eb59d3553ca1_1', "Complete the table. Explain or show your reasoning. meters centimeters millimeters 6.5",
    analysis(
        quantities([quantity(6.5, "meters", "6.5")]),
        ask("Complete the table by converting 6.5 meters into centimeters and millimeters."),
        steps([step("multiply", [6.5, 100], 650), step("multiply", [6.5, 1000], 6500)]),
        answer(6500, "millimeters"),
        missing_doing("table completion")),
    anchor(lesson('IM-G5-U6-L3'), grade('5'), record_id('im_defrag_026e5ff8d631eb59d3553ca1_1'), statement_sha('acec5bdeae1267f8177fd96ea564f55d37e175b02e6299534f61fea7c151f22d')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_5.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_02b67b58832ed15741984cb9_1', "Find the value of 6² ÷ 4",
    analysis(
        quantities([quantity(6, "number", "6"), quantity(4, "number", "4")]),
        ask("What is the value of 6 squared divided by 4?"),
        steps([step("exponentiation", [6, 2], 36), step("division", [36, 4], 9)]),
        answer(9, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U7-L5'), grade('6'), record_id('im_defrag_02b67b58832ed15741984cb9_1'), statement_sha('5bc7745760830769e54f6252820b4517620ebc5f0de181c7ac95083587a886c4')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_02c050451023457b96f769cf_1', "Lin has 5 bingo chips on her board. She also has some chips on the table. All together she has 7 bingo chips. How many bingo chips does Lin have on the table? Circle 2 equations that match the story problem.",
    analysis(
        quantities([quantity(5, "bingo chips", "5 bingo chips"), quantity(7, "bingo chips", "7 bingo chips")]),
        ask("How many bingo chips does Lin have on the table?"),
        steps([step("subtraction", [7, 5], 2)]),
        answer(2, "bingo chips"),
        missing_doing("selecting the correct equations from a set of choices")),
    anchor(lesson('IM-G1-U2-L17'), grade('1'), record_id('im_defrag_02c050451023457b96f769cf_1'), statement_sha('a0bb39adc15fa7c9107fcec7cc8ba275d7a55b1104eba0ed8714c2583e19d907')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_02e7b67c102d90340436b3d7_1', "There is a 10% off sale on laptop computers. If someone saves $35 on a laptop, what was its original cost?",
    analysis(
        quantities([quantity(10, "percent", "10%"), quantity(35, "dollars", "$35")]),
        ask("What was the original cost of the laptop?"),
        steps([step("divide", [35, 0.1], 350)]),
        answer(350, "dollars"),
        missing_doing("translating a percentage relationship into a division operation")),
    anchor(lesson('IM-G6-U3-L13'), grade('6'), record_id('im_defrag_02e7b67c102d90340436b3d7_1'), statement_sha('672f8301ac95ec4ab9e420c156c211438a8ca5069b242a449543dc3a80b41581')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_02ffb3f32ab4c6856f2bee3c_1', "3 × 45 = 180- 90",
    analysis(
        quantities([quantity(3, "multiplier", "3"), quantity(45, "multiplicand", "45"), quantity(180, "minuend", "180"), quantity(90, "subtrahend", "90")]),
        ask("Is the product of 3 and 45 equal to the difference between 180 and 90?"),
        steps([step("multiplication", [3, 45], 135), step("subtraction", [180, 90], 90), step("compare_equal", [135, 90], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U7-L9'), grade('4'), record_id('im_defrag_02ffb3f32ab4c6856f2bee3c_1'), statement_sha('9e77958c9abb6e95e25f54dbdccdd63d45796ba9b479bd0e58b8bb33387df5d6')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_030ad6d0a1d3e38a980e1eb8_1', "The triangle has side lengths 7, 10, and 12. Is it a right triangle? Explain your reasoning.",
    analysis(
        quantities([quantity(7, "side length", "7"), quantity(10, "side length", "10"), quantity(12, "side length", "12")]),
        ask("Is a triangle with side lengths 7, 10, and 12 a right triangle?"),
        steps([step("multiply", [7, 7], 49), step("multiply", [10, 10], 100), step("add", [49, 100], 149), step("multiply", [12, 12], 144), step("compare_equal", [149, 144], false)]),
        answer(false, "claim_verdict"),
        missing_doing("applying the Pythagorean theorem to check the condition for a right triangle")),
    anchor(lesson('IM-G8-U8-L10'), grade('8'), record_id('im_defrag_030ad6d0a1d3e38a980e1eb8_1'), statement_sha('52904418cb530f5faeb87fafb7f514a0f768272f7d40bc56495b8d017d22dbd1')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_0357b906700152388b3751f0_1', "28 + 5 = 30 + 3",
    analysis(
        quantities([quantity(28, "number", "28"), quantity(5, "number", "5"), quantity(30, "number", "30"), quantity(3, "number", "3")]),
        ask("Determine if the equation 28 + 5 = 30 + 3 is true."),
        steps([step("addition", [28, 5], 33), step("addition", [30, 3], 33), step("compare_equal", [33, 33], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U1-L16'), grade('2'), record_id('im_defrag_0357b906700152388b3751f0_1'), statement_sha('d3faa5d568579d7246d62ddc3412044a7ec6eb41d24b855383c5b051c7af921b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_0399f85fb0edb258e121c2ec_1', "Find the value of each quotient mentally. 24 ÷ 12",
    analysis(
        quantities([quantity(24, "number", "24"), quantity(12, "number", "12")]),
        ask("What is the value of 24 divided by 12?"),
        steps([step("division", [24, 12], 2)]),
        answer(2, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L8'), grade('6'), record_id('im_defrag_0399f85fb0edb258e121c2ec_1'), statement_sha('0569e3b4b0a5ac70ef34776cfe42c64b24443379b2a7c5ba060f6b0d9cd50d94')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_03a754b5ab40597a59c39d3f_1', "Find the value of each quotient. Show your reasoning. Use vertical calculations at least once. 1. 1,332 ÷ 9",
    analysis(
        quantities([quantity(1332, "number", "1,332"), quantity(9, "number", "9")]),
        ask("What is the value of 1,332 divided by 9?"),
        steps([step("division", [1332, 9], 148)]),
        answer(148, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U5-L10'), grade('6'), record_id('im_defrag_03a754b5ab40597a59c39d3f_1'), statement_sha('b9b8b40cdb27a9267deb63453578275c7a0234693e852982dad09eebeb34709b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_03a9cc01686578a62f94ff53_1', "Find the value of each expression mentally. 5,000 ÷ 2,500",
    analysis(
        quantities([quantity(5000, "number", "5,000"), quantity(2500, "number", "2,500")]),
        ask("What is the value of 5,000 divided by 2,500?"),
        steps([step("divide", [5000, 2500], 2)]),
        answer(2, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U4-L1'), grade('6'), record_id('im_defrag_03a9cc01686578a62f94ff53_1'), statement_sha('d51324dc52cb177e24bd271a99d2c3b72d3d62d3aa3a9e830c7981a6210f23ce')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_03c11e5b7ca05c007f5fc8e9_1', "Complete the table so ratios in each row are equivalent to 7:5. Row: 28 fl oz vinegar (=7*4), find soy sauce.",
    analysis(
        quantities([quantity(7, "ratio unit vinegar", "7"), quantity(5, "ratio unit soy sauce", "5"), quantity(28, "fl oz vinegar", "28 fl oz vinegar")]),
        ask("Find the amount of soy sauce that makes the ratio 28 fl oz vinegar to soy sauce equivalent to 7:5."),
        steps([step("division", [28, 7], 4), step("multiplication", [5, 4], 20)]),
        answer(20, "fl oz soy sauce"),
        missing_doing("proportional reasoning")),
    anchor(lesson('IM-G6-U2-L11'), grade('6'), record_id('im_defrag_03c11e5b7ca05c007f5fc8e9_1'), statement_sha('cd5528666f959e9f549115dedc06c800244bd12eb590369567f73df97c4f3c71')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_03d40db91d05c219a8b919ed_1', "1. Elena has 6 counters. She gets some more. Now she has 18 counters. How many more counters did Elena get?",
    analysis(
        quantities([quantity(6, "counters", "6 counters"), quantity(18, "counters", "18 counters")]),
        ask("How many more counters did Elena get?"),
        steps([step("subtraction", [18, 6], 12)]),
        answer(12, "counters"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L26'), grade('1'), record_id('im_defrag_03d40db91d05c219a8b919ed_1'), statement_sha('630a419d677bdd67b96ab7e8b4fbe1914bd4d3adf55c220f9c5213c23144f763')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_03defb2dc848f8d6a1f23d9c_1', "10 = 8 + 2",
    analysis(
        quantities([quantity(10, "number", "10"), quantity(8, "number", "8"), quantity(2, "number", "2")]),
        ask("Is 10 equal to 8 plus 2?"),
        steps([step("addition", [8, 2], 10), step("compare_equal", [10, 10], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U1-L6'), grade('1'), record_id('im_defrag_03defb2dc848f8d6a1f23d9c_1'), statement_sha('1df6b171b71453114e4cd7627448cbf4d5614935a1b1de567eeada9706d5cf00')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_03fca82fa990dc22dfea64b7_1', "There are 80 sweaters in piles on a shelf. Each pile has 8 sweaters. How many piles of sweaters are on the shelf?",
    analysis(
        quantities([quantity(80, "sweaters", "80 sweaters"), quantity(8, "sweaters per pile", "8 sweaters")]),
        ask("How many piles of sweaters are on the shelf?"),
        steps([step("division", [80, 8], 10)]),
        answer(10, "piles"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U1-L15'), grade('3'), record_id('im_defrag_03fca82fa990dc22dfea64b7_1'), statement_sha('9782c97207c93b8847305dbb1f805b98412dcbbe51a95f3a06a3c211b561d0d2')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_0411e72d049a6ba93cc98732_1', "Find the value of 2³ · 3",
    analysis(
        quantities([quantity(2, "number", "2"), quantity(3, "exponent", "3"), quantity(3, "number", "3")]),
        ask("What is the value of 2 raised to the power of 3 multiplied by 3?"),
        steps([step("exponentiation", [2, 3], 8), step("multiplication", [8, 3], 24)]),
        answer(24, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U7-L5'), grade('6'), record_id('im_defrag_0411e72d049a6ba93cc98732_1'), statement_sha('dee00e3520d438dc0b0e62438133226b7c49afdea34df1fb2a646507c265d23a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_043aa95239c1110ca8050ab3_1', "6 people come to story time. 3 more people join the group. How many people are at story time now?",
    analysis(
        quantities([quantity(6, "people", "6 people"), quantity(3, "people", "3 more people")]),
        ask("How many people are at story time now?"),
        steps([step("addition", [6, 3], 9)]),
        answer(9, "people"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U2-L2'), grade('1'), record_id('im_defrag_043aa95239c1110ca8050ab3_1'), statement_sha('2e767eb745cbaaf7a35b1658bb0eead1b8e3983c52af1d90a5fd4963eed4d384')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_045fab659b829ae96c438096_1', "A farmer puts 24 apples A farmer packs 20 in boxes. She puts 8 apples in 4 boxes. apples in each box. She packs the same How many boxes are number of apples in there? each box. How many apples are in each box? Discuss with your partner: • How are these problems alike? • How are they different? • What is alike and what is different about how these problems are represented and solved?",
    analysis(
        quantities([quantity(24, "apples", "24 apples"), quantity(20, "apples", "20 in boxes"), quantity(8, "apples", "8 apples"), quantity(4, "boxes", "4 boxes")]),
        ask("How many apples are in each box if a farmer packs 24 apples into boxes and puts 8 apples in 4 boxes (based on the context of the prompt's conflicting sentence structure, the core question is how many apples are in each box given 8 apples in 4 boxes)?"),
        steps([step("division", [8, 4], 2)]),
        answer(2, "apples per box"),
        missing_doing("interpreting ambiguous/malformed text")),
    anchor(lesson('IM-G3-U4-L2'), grade('3'), record_id('im_defrag_045fab659b829ae96c438096_1'), statement_sha('30f0fd8c0b05f00ad7c206cdc847b57f122889d69f3fc0148b7e987c6c4bc71b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_05456eef4f6f55b4fb492213_1', "9 + 4 = 9 + 1 + 3",
    analysis(
        quantities([quantity(9, "number", "9"), quantity(4, "number", "4"), quantity(9, "number", "9"), quantity(1, "number", "1"), quantity(3, "number", "3")]),
        ask("Check if 9 + 4 is equal to 9 + 1 + 3."),
        steps([step("addition", [9, 4], 13), step("addition", [9, 1], 10), step("addition", [10, 3], 13), step("compare_equal", [13, 13], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U1-L13'), grade('2'), record_id('im_defrag_05456eef4f6f55b4fb492213_1'), statement_sha('d1c6e432787e0d92879ac5596e7bde69e6f3938178ae7fc80ab7fdf7799dbdcc')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_058bb1a5462403ce886b2c7d_1', "1. 4 sandwiches are equally shared by 5 students. How much sandwich does each student get? Explain or show your reasoning. 2. Write a division expression to represent the situation.",
    analysis(
        quantities([quantity(4, "sandwiches", "4 sandwiches"), quantity(5, "students", "5 students")]),
        ask("How much sandwich does each student get and what is the division expression for this situation?"),
        steps([step("division", [4, 5], 0.8)]),
        answer(0.8, "sandwich"),
        missing_doing("writing a division expression")),
    anchor(lesson('IM-G5-U2-L2'), grade('5'), record_id('im_defrag_058bb1a5462403ce886b2c7d_1'), statement_sha('c528a2633e459b7754cc7231aa93a64311e978d3cdf2b09a393ae5025eae4532')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_05961771ec6bea2c0c2ff0cf_1', "Suppose you need 80 ml of maroon paint. How much blue paint? (10 batches, 3 ml blue per batch)",
    analysis(
        quantities([quantity(80, "ml", "80 ml"), quantity(10, "batches", "10 batches"), quantity(3, "ml", "3 ml")]),
        ask("How much blue paint is needed for 10 batches if each batch requires 3 ml of blue paint?"),
        steps([step("multiplication", [10, 3], 30)]),
        answer(30, "ml"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L15'), grade('6'), record_id('im_defrag_05961771ec6bea2c0c2ff0cf_1'), statement_sha('bb6a66019927f106a1e4738b5eebe0c16886ecd6944fcb5e370aac116c05d0f1')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_07690fe523db3112f93a6222_1', "Find the value of 14- 6 . Show your thinking using drawings, words, or numbers.",
    analysis(
        quantities([quantity(14, "number", "14"), quantity(6, "number", "6")]),
        ask("What is the value of 14 minus 6?"),
        steps([step("subtraction", [14, 6], 8)]),
        answer(8, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L23'), grade('1'), record_id('im_defrag_07690fe523db3112f93a6222_1'), statement_sha('ecb326e89b18643ddba1cf7245ec88bcab625219049b553f26023d8f6cb4a865')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_082313a107242d82c7168b85_1', "Find the value of each subtraction expression: 3 − 2",
    analysis(
        quantities([quantity(3, "number", "3"), quantity(2, "number", "2")]),
        ask("What is the value of the expression 3 minus 2?"),
        steps([step("subtraction", [3, 2], 1)]),
        answer(1, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U5-L6'), grade('7'), record_id('im_defrag_082313a107242d82c7168b85_1'), statement_sha('2dd0806701f36b318c61ee1077f17e7e76b57fb923a34b0dbe6818b9b156ac8a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_08321220894a9813bb9b817a_1', "Use the standard algorithm to find the value of 203 × 23.",
    analysis(
        quantities([quantity(203, "number", "203"), quantity(23, "number", "23")]),
        ask("Use the standard algorithm to find the value of 203 × 23."),
        steps([step("multiplication", [203, 3], 609), step("multiplication", [203, 20], 4060), step("addition", [609, 4060], 4669)]),
        answer(4669, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U4-L5'), grade('5'), record_id('im_defrag_08321220894a9813bb9b817a_1'), statement_sha('2ae4f1e90861304883a7a14ca30bccd5ca97150272c04157ba3b8f2293f0457d')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_0.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_08a340c42d86f3717c549445_1', "Find each quotient. Show your reasoning. b. 356 ÷ 4",
    analysis(
        quantities([quantity(356, "number", "356"), quantity(4, "number", "4")]),
        ask("What is the quotient of 356 divided by 4?"),
        steps([step("division", [356, 4], 89)]),
        answer(89, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U5-L9'), grade('6'), record_id('im_defrag_08a340c42d86f3717c549445_1'), statement_sha('6a5f7976b36814c221ac9032036a5f68c358cd19cc6c31333aecc1f59adcc23b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_0924482b0cb893320b04b110_1', "2 + 2 + 2 + 2 + 2 + 2 = 5 + 5",
    analysis(
        quantities([quantity(2, "number", "2"), quantity(5, "number", "5")]),
        ask("Check if the sum of six 2s is equal to the sum of two 5s."),
        steps([step("addition", [2, 2, 2, 2, 2, 2], 12), step("addition", [5, 5], 10), step("compare_equal", [12, 10], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U8-L13'), grade('2'), record_id('im_defrag_0924482b0cb893320b04b110_1'), statement_sha('c237232b4b6ea3fcea03b9043a7bcc6f4fc4b309dce84abaedcfa9b086887fd8')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_09786f46016ce014b903590e_1', "What could each division expression mean in the situation with the bags of clay? Draw a diagram and write a multiplication equation... 12 ÷ 2",
    analysis(
        quantities([quantity(12, "clay", "12"), quantity(2, "bags", "2")]),
        ask("What does the division expression 12 ÷ 2 mean in the context of bags of clay, and what is the corresponding multiplication equation?"),
        steps([step("divide", [12, 2], 6)]),
        answer(6, "clay per bag"),
        missing_doing("contextual interpretation and diagramming")),
    anchor(lesson('IM-G6-U4-L2'), grade('6'), record_id('im_defrag_09786f46016ce014b903590e_1'), statement_sha('cef3d2d61898113d96c934f39ce62785ae4dd9e8fe29569e8447e7e7ebedb94e')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_0a22f7fde0da4afd6f6c52e2_1', "Lin runs for 25 seconds at 8 meters per second. What is her finish point?",
    analysis(
        quantities([quantity(25, "seconds", "25 seconds"), quantity(8, "meters per second", "8 meters per second")]),
        ask("How many meters did Lin run?"),
        steps([step("multiplication", [25, 8], 200)]),
        answer(200, "meters"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U5-L8'), grade('7'), record_id('im_defrag_0a22f7fde0da4afd6f6c52e2_1'), statement_sha('347022f12a7510a06a7de8b22fe27a5404e24b78b8666e05c8335a58df154d90')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_0a8ff15b4d6ea753f091a88b_1', "4. The Ferris wheel holds 20 people. The swings hold 14 people. How many fewer people do the swings hold than the Ferris wheel?",
    analysis(
        quantities([quantity(20, "people", "20 people"), quantity(14, "people", "14 people")]),
        ask("How many fewer people do the swings hold than the Ferris wheel?"),
        steps([step("subtraction", [20, 14], 6)]),
        answer(6, "people"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U8-L6'), grade('1'), record_id('im_defrag_0a8ff15b4d6ea753f091a88b_1'), statement_sha('8b1ccbe5ca6c47c57908dea966152432c5de910194ee07e3efff46292fa51a76')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_0a9ad33ab3b2f4fc5b8f5b21_1', "Find the value of 18 + 55. Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(18, "number", "18"), quantity(55, "number", "55")]),
        ask("What is the value of 18 + 55?"),
        steps([step("addition", [18, 55], 73)]),
        answer(73, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U5-L9'), grade('1'), record_id('im_defrag_0a9ad33ab3b2f4fc5b8f5b21_1'), statement_sha('1228f90f0bd13badb4f4ea16c253bdc56a588d522078be53aea4c8eda4519305')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_0b520839120d288aa18338cb_1', "Find the value of 62 × 35.",
    analysis(
        quantities([quantity(62, "number", "62"), quantity(35, "number", "35")]),
        ask("Find the value of 62 × 35."),
        steps([step("multiplication", [62, 30], 1860), step("multiplication", [62, 5], 310), step("addition", [1860, 310], 2170)]),
        answer(2170, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U4-L2'), grade('5'), record_id('im_defrag_0b520839120d288aa18338cb_1'), statement_sha('b9eb56f214ab0fd7305d4538a4f3638c78d7ee05b1aff131133303602b93b636')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_4.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_0bb2e75b1e77229a31f3c998_1', "2 + 2 + 2 + 2 = 4 + 4",
    analysis(
        quantities([quantity(2, "number", "2"), quantity(4, "number", "4")]),
        ask("Determine if the sum of four 2s is equal to the sum of two 4s."),
        steps([step("addition", [2, 2, 2, 2], 8), step("addition", [4, 4], 8), step("compare_equal", [8, 8], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U8-L13'), grade('2'), record_id('im_defrag_0bb2e75b1e77229a31f3c998_1'), statement_sha('bace6078ab349c2f3839a08c568a0db5884335a2017fd0f16ddd8c7c48bfd93c')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_0beee921cc567e2799cb5455_1', "Movie tickets are $9 each. The theater sells the same number of tickets 2 days in a row. The theater made $3,132 from ticket sales on the first day. 1. Record and answer one question of your choice from the list the class generated. Discuss your strategy with your partner. 2. Use the given information about movie tickets to complete the following statement: __________ tickets were sold on the first and second days. 3. A medium drink is $7 and small popcorn is $5. If each ticket holder purchases popcorn and a drink, how much money will the theater collect from the sales of popcorn and drinks?",
    analysis(
        quantities([quantity(9, "dollars", "$9"), quantity(3132, "dollars", "$3,132"), quantity(7, "dollars", "$7"), quantity(5, "dollars", "$5")]),
        ask("How much money will the theater collect from the sales of popcorn and drinks if each ticket holder purchases popcorn and a drink?"),
        steps([step("division", [3132, 9], 348), step("multiplication", [348, 2], 696), step("addition", [7, 5], 12), step("multiplication", [696, 12], 8352)]),
        answer(8352, "dollars"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U6-L22'), grade('4'), record_id('im_defrag_0beee921cc567e2799cb5455_1'), statement_sha('3c9a3140c6e5814ec6be37822040a65a13e6294ee5274e7cd394c3fff8a20862')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_0c11c464882f3e70c8095778_1', "There are 6 hands on the table. Each hand has 5 fingers. 5. 6.",
    analysis(
        quantities([quantity(6, "hands", "6 hands"), quantity(5, "fingers per hand", "5 fingers")]),
        ask("How many fingers are there in total?"),
        steps([step("multiply", [6, 5], 30)]),
        answer(30, "fingers"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U1-L13'), grade('3'), record_id('im_defrag_0c11c464882f3e70c8095778_1'), statement_sha('ce92be998c1909313ebd54d716c8d5ba9abc54e0e0c3dc84c70ccd80cd1e2261')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_0.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_0c7d556f193901e98d88b895_1', "Prepare to discuss a time when representing 241 as 2 hundreds, 3 tens, and 11 ones might be helpful.",
    analysis(
        quantities([quantity(241, "number", "241"), quantity(2, "hundreds", "2 hundreds"), quantity(3, "tens", "3 tens"), quantity(11, "ones", "11 ones")]),
        ask("Discuss a scenario where representing 241 as 2 hundreds, 3 tens, and 11 ones might be useful."),
        steps([step("multiply", [2, 100], 200), step("multiply", [3, 10], 30), step("multiply", [11, 1], 11), step("add", [200, 30], 230), step("add", [230, 11], 241)]),
        answer(241, "number"),
        missing_doing("conceptualizing context for non-standard decomposition")),
    anchor(lesson('IM-G2-U9-L6'), grade('2'), record_id('im_defrag_0c7d556f193901e98d88b895_1'), statement_sha('e2fdc14dd65e1457e3ac4e0d7192e9c777635dfa79ae06e7b2458063042342a4')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_0ccd5f39409f8f3c0cd5502d_1', "Rectangle Z has a perimeter of 180 inches. a. Complete this statement: The perimeter of Rectangle Z is __________ times the perimeter of Rectangle Y. b. If the length of Rectangle Z is 70 inches, how many inches is its width? Explain or show your reasoning.",
    analysis(
        quantities([quantity(180, "inches", "180 inches"), quantity(70, "inches", "70 inches")]),
        ask("Complete the statement regarding the ratio of the perimeter of Rectangle Z to Rectangle Y, and find the width of Rectangle Z if its length is 70 inches."),
        steps([step("subtract", [180, 140], 40), step("divide", [40, 2], 20)]),
        answer(20, "inches"),
        missing_doing("The problem is underspecified because the perimeter of Rectangle Y is not provided, making part 'a' impossible to solve.")),
    anchor(lesson('IM-G4-U5-L16'), grade('4'), record_id('im_defrag_0ccd5f39409f8f3c0cd5502d_1'), statement_sha('fb7fd063b123fd2d3fd3a9caaff2c1b72a092c775be9f0bf6c7f8ab14ede2d5c')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_0d09838d485f78f3aa07e7a2_1', "Noah has $40 on his fare card. Every time he rides public transportation, $2.50 is subtracted from the amount available on his card. 1. How much money, in dollars, is available on his card after he takes a. 0 rides? b. 1 ride? c. 2 rides? d. rides? 2. How many rides can Noah take before the card runs out of money? Where would you see this number of rides on a graph? 3. Graph the relationship between amount of money on the card and number of rides.",
    analysis(
        quantities([quantity(40, "dollars", "$40"), quantity(2.5, "dollars", "$2.50")]),
        ask("Determine the amount of money remaining after 0, 1, 2, and d rides, find the total number of rides possible before the card runs out, and describe/graph the relationship."),
        steps([step("subtraction", [40, 0], 40), step("subtraction", [40, 2.5], 37.5), step("subtraction", [37.5, 2.5], 35), step("division", [40, 2.5], 16)]),
        answer(16, "rides"),
        missing_doing("graphing and interpreting visual data")),
    anchor(lesson('IM-G8-U3-L9'), grade('8'), record_id('im_defrag_0d09838d485f78f3aa07e7a2_1'), statement_sha('f3cf7e9c5b7da934a49f0d9f4197254776bd42c9d5b62e062b7991872f923e2a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_0d13887031e599c8f64e1882_1', "3 + 2 = 3 + 2",
    analysis(
        quantities([quantity(3, "number", "3"), quantity(2, "number", "2"), quantity(3, "number", "3"), quantity(2, "number", "2")]),
        ask("Is the equation 3 + 2 = 3 + 2 true?"),
        steps([step("addition", [3, 2], 5), step("addition", [3, 2], 5), step("compare_equal", [5, 5], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L14'), grade('1'), record_id('im_defrag_0d13887031e599c8f64e1882_1'), statement_sha('ee294214b9652bea6f5f77aeb1ca7084047f55214455f75d1eee4fd1a2bb0fd3')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_0d547f6d3b95bff2bd6738b5_1', "A different group of 4,632 dancers make groups of 8. 1.",
    analysis(
        quantities([quantity(4632, "dancers", "4,632 dancers"), quantity(8, "dancers per group", "8")]),
        ask("How many groups of 8 dancers can be made from 4,632 dancers?"),
        steps([step("division", [4632, 8], 579)]),
        answer(579, "groups"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U4-L9'), grade('5'), record_id('im_defrag_0d547f6d3b95bff2bd6738b5_1'), statement_sha('c80aa2c732adb51fae5c2abee070ef04d1c19a99a34756bacee35d4998300b06')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_0dd77ef6e4844cee4332180c_1', "A car is traveling east at 12 meters per second. Where will it be 10 seconds after it passes the camera?",
    analysis(
        quantities([quantity(12, "meters per second", "12 meters per second"), quantity(10, "seconds", "10 seconds")]),
        ask("How far east from the camera will the car be after 10 seconds?"),
        steps([step("*", [12, 10], 120)]),
        answer(120, "meters east of the camera"),
        missing_doing("modeling motion")),
    anchor(lesson('IM-G7-U5-L8'), grade('7'), record_id('im_defrag_0dd77ef6e4844cee4332180c_1'), statement_sha('a59d6c3f3f026f6aa8874024b0e4085121691f27e80f44952f0dac8b6b9f6d7a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_0e01204ea5bbf9c3e188d27e_1', "9 + 5 = 10 + 6",
    analysis(
        quantities([quantity(9, "number", "9"), quantity(5, "number", "5"), quantity(10, "number", "10"), quantity(6, "number", "6")]),
        ask("Is the sum of 9 and 5 equal to the sum of 10 and 6?"),
        steps([step("addition", [9, 5], 14), step("addition", [10, 6], 16), step("compare_equal", [14, 16], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U1-L13'), grade('2'), record_id('im_defrag_0e01204ea5bbf9c3e188d27e_1'), statement_sha('9d6dbca1b996376a97624e58c6b17d228a3f4383a25db55becb2551303831f7b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_0e11c8a6ac0e85d53d64e41d_1', "Tyler spills 5 red counters and 3 yellow counters. How many counters did he spill in all? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(5, "red counters", "5 red counters"), quantity(3, "yellow counters", "3 yellow counters")]),
        ask("How many counters did Tyler spill in all?"),
        steps([step("addition", [5, 3], 8)]),
        answer(8, "counters"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L2'), grade('1'), record_id('im_defrag_0e11c8a6ac0e85d53d64e41d_1'), statement_sha('548e8dc3bebc085c93fff240672d62b835140341d5407e9e3bda616090fa8314')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_0e19bfca41a19926da13cac5_1', "Use long division to find the value of each expression. 90 ÷ 12",
    analysis(
        quantities([quantity(90, "dividend", "90"), quantity(12, "divisor", "12")]),
        ask("Find the value of 90 divided by 12."),
        steps([step("divide", [90, 12], 7.5)]),
        answer(7.5, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U5-L12'), grade('6'), record_id('im_defrag_0e19bfca41a19926da13cac5_1'), statement_sha('aea05b39237b1d1093df11c8ee1103cb331fc3c43be2e6c487a46c1c7edb98ab')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_0e3d0078a315efcf482c1830_1', "57 + 20 = 59",
    analysis(
        quantities([quantity(57, "number", "57"), quantity(20, "number", "20"), quantity(59, "number", "59")]),
        ask("Is 57 plus 20 equal to 59?"),
        steps([step("addition", [57, 20], 77), step("compare_equal", [77, 59], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U8-L5'), grade('1'), record_id('im_defrag_0e3d0078a315efcf482c1830_1'), statement_sha('e15ce435bd81da36e7545aa66b5386592ff7e8450ebaa5f3dbb7a8b3c2c0eea3')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_0e4cc73c7ee97fe5a442ec23_1', "The Statue of Liberty is 305 feet tall. The Brooklyn Bridge is 135 feet tall. How much taller is the Statue of Liberty than the Brooklyn Bridge? Explain or show your reasoning.",
    analysis(
        quantities([quantity(305, "feet", "305 feet"), quantity(135, "feet", "135 feet")]),
        ask("How much taller is the Statue of Liberty than the Brooklyn Bridge?"),
        steps([step("subtraction", [305, 135], 170)]),
        answer(170, "feet"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U3-L2'), grade('3'), record_id('im_defrag_0e4cc73c7ee97fe5a442ec23_1'), statement_sha('fb52f638a0114b6a8d2b22330ea36d8d0fc123e0f7b2889b4b11f284947cad22')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_0e5d411e92efc54488eb4c05_1', "Solve each equation mentally: d · 50 = 49",
    analysis(
        quantities([quantity(50, "multiplier", "50"), quantity(49, "product", "49")]),
        ask("Find the value of d such that d multiplied by 50 equals 49."),
        steps([step("division", [49, 50], 0.98)]),
        answer(0.98, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U4-L8'), grade('7'), record_id('im_defrag_0e5d411e92efc54488eb4c05_1'), statement_sha('7afc263bf1ca57af269e2bee408ae3a1c1bd6f048c6f49818d979db590ceab76')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_0e7e2b8bc16ee0bf0646eb18_1', "Clare spills 2 red counters and 8 yellow counters. How many counters did she spill in all? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(2, "red counters", "2 red counters"), quantity(8, "yellow counters", "8 yellow counters")]),
        ask("How many total counters did Clare spill?"),
        steps([step("addition", [2, 8], 10)]),
        answer(10, "counters"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L2'), grade('1'), record_id('im_defrag_0e7e2b8bc16ee0bf0646eb18_1'), statement_sha('a013d375e8186ab98b06dab861185c2aa58824a0b676432034ce883421df9501')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_0ebb136aa0619a9f2a4335af_1', "Use long division to find each quotient. Show your computation, and write your answer as a decimal. 2. 7 ÷ 8",
    analysis(
        quantities([quantity(2, "number", "2"), quantity(7, "number", "7"), quantity(8, "number", "8")]),
        ask("What is the decimal value of 7 divided by 8?"),
        steps([step("division", [7, 8], 0.875)]),
        answer(0.875, "decimal"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U5-L12'), grade('6'), record_id('im_defrag_0ebb136aa0619a9f2a4335af_1'), statement_sha('dccc7b582e465d10ee2ab11309a2d21298e9f50764651e53a140e2574b086583')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_0efed5ff670199a146045361_1', "Tyler had 6 pennies, 2 dimes, 2 quarters, and 2 nickels in his pocket. How many cents does Tyler have? Show your thinking, using drawings, numbers, words, or an equation.",
    analysis(
        quantities([quantity(6, "pennies", "6 pennies"), quantity(2, "dimes", "2 dimes"), quantity(2, "quarters", "2 quarters"), quantity(2, "nickels", "2 nickels")]),
        ask("How many cents does Tyler have in total?"),
        steps([step("multiply", [6, 1], 6), step("multiply", [2, 10], 20), step("multiply", [2, 25], 50), step("multiply", [2, 5], 10), step("add", [6, 20], 26), step("add", [26, 50], 76), step("add", [76, 10], 86)]),
        answer(86, "cents"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U6-L16'), grade('2'), record_id('im_defrag_0efed5ff670199a146045361_1'), statement_sha('032d73a5092e81bf1a8e91f8fe6cc2f7b6e62f645acfee8203d0813bbd46599a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_1065e40935b31e6536dd8546_1', "Here is how Lin calculated 62 ÷ 5. ... d. What value did Lin find for 62 ÷ 5?",
    analysis(
        quantities([quantity(62, "number", "62"), quantity(5, "number", "5")]),
        ask("What is the value of 62 divided by 5?"),
        steps([step("division", [62, 5], 12.4)]),
        answer(12.4, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U5-L12'), grade('6'), record_id('im_defrag_1065e40935b31e6536dd8546_1'), statement_sha('c6fde45cd9ded2c66e90ef6a2b1cb2f4ecbaee115000953a286d5abb39f6ba0a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_10a86abcf0320cb94d8b0a3a_1', "A theater has 8 rows of seats and 27 seats in each row. How many seats are in the theater? Show your reasoning.",
    analysis(
        quantities([quantity(8, "rows", "8 rows"), quantity(27, "seats per row", "27 seats in each row")]),
        ask("How many seats are in the theater in total?"),
        steps([step("multiplication", [8, 27], 216)]),
        answer(216, "seats"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U6-L5'), grade('4'), record_id('im_defrag_10a86abcf0320cb94d8b0a3a_1'), statement_sha('a02806e2337c65e564779c980628fea5c7048d83b04c81c2bf7ce485215f0476')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_112ee543661cd5194fd26b2b_1', "Wyoming is 600 kilometers wide and 452 kilometers long. What is the area of Wyoming?",
    analysis(
        quantities([quantity(600, "kilometers", "600 kilometers"), quantity(452, "kilometers", "452 kilometers")]),
        ask("What is the area of Wyoming?"),
        steps([step("multiplication", [600, 452], 271200)]),
        answer(271200, "square kilometers"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U4-L18'), grade('5'), record_id('im_defrag_112ee543661cd5194fd26b2b_1'), statement_sha('95f984188e822a37dab3ae7f75181b3b306025aa5036607195c3ffeedc4e254c')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_120e745187d8b3d2fa6379bd_1', "Diego gathers 22 seeds from yellow flowers. He gathers 48 seeds from blue flowers. How many seeds does he gather in all? a.",
    analysis(
        quantities([quantity(22, "seeds", "22 seeds"), quantity(48, "seeds", "48 seeds")]),
        ask("How many seeds does Diego gather in total?"),
        steps([step("addition", [22, 48], 70)]),
        answer(70, "seeds"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U2-L13'), grade('2'), record_id('im_defrag_120e745187d8b3d2fa6379bd_1'), statement_sha('c648c9fa8394d008ddf027cd41a561856d06e1ef107bb49a043c5bbf4d110d24')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_1213e06b592b828ee7f0efb3_1', "Find the value of 24 × 17. Explain or show your reasoning.",
    analysis(
        quantities([quantity(24, "number", "24"), quantity(17, "number", "17")]),
        ask("Find the value of 24 × 17."),
        steps([step("multiplication", [24, 10], 240), step("multiplication", [24, 7], 168), step("addition", [240, 168], 408)]),
        answer(408, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U6-L8'), grade('4'), record_id('im_defrag_1213e06b592b828ee7f0efb3_1'), statement_sha('daf7b26774ce75da49088ee6ac1c5390a601fb8711a454763af673ef7bf10c28')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_5.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_1229366f8515a1d6caefd096_1', "1. Find the value of each expression. Explain or show your reasoning. a. 75.2- 4.37 b. 236.87 + 5.15",
    analysis(
        quantities([quantity(75.2, "number", "75.2"), quantity(4.37, "number", "4.37")]),
        ask("Find the value of the expression 75.2 - 4.37."),
        steps([step("subtraction", [75.2, 4.37], 70.83)]),
        answer(70.83, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U5-L16'), grade('5'), record_id('im_defrag_1229366f8515a1d6caefd096_1'), statement_sha('3f70082e074891f960760bd8f5d760f89a119363c14e0a527022ed12a8741482')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_0.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_1235ead9bcc73dc2b0270c3c_1', "1. Find the value of 622.35 - 71.4 . Explain or show your reasoning. 2. Elena and Andre try to find the value of 622.35 - 71.4 . Who do you agree with? Explain or show your reasoning.",
    analysis(
        quantities([quantity(622.35, "number", "622.35"), quantity(71.4, "number", "71.4")]),
        ask("Find the value of 622.35 minus 71.4."),
        steps([step("subtraction", [622.35, 71.4], 550.95)]),
        answer(550.95, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U5-L15'), grade('5'), record_id('im_defrag_1235ead9bcc73dc2b0270c3c_1'), statement_sha('0915b43fc4ab98ad5d5d5602d4d7f8fb351eaac997829bbb73b9ee6631843769')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_128cfa08923cf1cf45cab211_1', "Mai walked 1/8 of a 30-mile walking trail. How many miles did Mai walk? (Sample reasoning: 1/8 of 30 is 30 ÷ 8 = 3.75)",
    analysis(
        quantities([quantity(0.125, "fraction", "1/8"), quantity(30, "miles", "30-mile")]),
        ask("How many miles did Mai walk?"),
        steps([step("division", [30, 8], 3.75)]),
        answer(3.75, "miles"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U5-L12'), grade('6'), record_id('im_defrag_128cfa08923cf1cf45cab211_1'), statement_sha('46b497e36346b145158ff6e8a46be01ccf190d19168f04b667465185e20b7fcb')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_1335bcc0b3d87f060ad4a775_1', "Andre found the value of 739- 255 . His work is shown. Explain how he subtracted and the value he found for 739- 255 .",
    analysis(
        quantities([quantity(739, "number", "739"), quantity(255, "number", "255")]),
        ask("Explain Andre's subtraction process and identify the value of 739 minus 255."),
        steps([step("subtraction", [739, 255], 484)]),
        answer(484, "number"),
        missing_doing("explanation of process")),
    anchor(lesson('IM-G3-U3-L9'), grade('3'), record_id('im_defrag_1335bcc0b3d87f060ad4a775_1'), statement_sha('d53ef3729d92a45e51dfd1c8acc256906a526072a86fd03b4ff210ddfc7f2741')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_13d3ade1d2573c37ffa6f0c4_1', "Four students share a $271 prize from a science competition. How much does each student get if the prize is shared equally?",
    analysis(
        quantities([quantity(4, "students", "Four students"), quantity(271, "dollars", "$271")]),
        ask("How much money does each student receive if the $271 prize is shared equally among the four students?"),
        steps([step("division", [271, 4], 67.75)]),
        answer(67.75, "dollars"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U5-L9'), grade('6'), record_id('im_defrag_13d3ade1d2573c37ffa6f0c4_1'), statement_sha('e8d25bb652ccd8210a19553f18dab16fd495a3e9ba703b23f7db50d5b0cdc684')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_13debd6919059ec40025916e_1', "9 is 25% of what number?",
    analysis(
        quantities([quantity(9, "number", "9"), quantity(25, "percent", "25%")]),
        ask("What number is 9 equal to 25% of?"),
        steps([step("divide", [25, 100], 0.25), step("divide", [9, 0.25], 36)]),
        answer(36, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U3-L13'), grade('6'), record_id('im_defrag_13debd6919059ec40025916e_1'), statement_sha('d3b567dd9c29a7c1841626fd68903be31c09f2e42f93aafc470fb30dbdd03329')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_1467d355fdf7b5c27b1d5cfe_1', "10 + 15 = 15 + 10",
    analysis(
        quantities([quantity(10, "number", "10"), quantity(15, "number", "15"), quantity(15, "number", "15"), quantity(10, "number", "10")]),
        ask("Determine if the equation 10 + 15 = 15 + 10 is true."),
        steps([step("addition", [10, 15], 25), step("addition", [15, 10], 25), step("compare_equal", [25, 25], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U7-L15'), grade('1'), record_id('im_defrag_1467d355fdf7b5c27b1d5cfe_1'), statement_sha('d1c9734d09cfd63018bf1851000b666e18f2b478b1e67e065355cdadab8917bd')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_146da87b58cef452b1bfaa30_1', "b. Is the decimal for 18/50 also 0.36? Use long division to support your answer.",
    analysis(
        quantities([quantity(18, "numerator", "18"), quantity(50, "denominator", "50"), quantity(0.36, "decimal", "0.36")]),
        ask("Is the decimal representation of the fraction 18/50 equal to 0.36?"),
        steps([step("division", [18, 50], 0.36), step("compare_equal", [0.36, 0.36], true)]),
        answer(true, "claim_verdict"),
        missing_doing("long division")),
    anchor(lesson('IM-G6-U5-L12'), grade('6'), record_id('im_defrag_146da87b58cef452b1bfaa30_1'), statement_sha('323561b3afda562a3e918978062020ce7f7428a4936f495c17a0aa26a22bc516')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_1559c36f6597cc5c69eb12a6_1', "4 × 20 = 4 × 2 × 10",
    analysis(
        quantities([quantity(4, "number", "4"), quantity(20, "number", "20"), quantity(4, "number", "4"), quantity(2, "number", "2"), quantity(10, "number", "10")]),
        ask("Check if 4 multiplied by 20 is equal to 4 multiplied by 2 multiplied by 10."),
        steps([step("multiplication", [4, 20], 80), step("multiplication", [4, 2], 8), step("multiplication", [8, 10], 80), step("compare_equal", [80, 80], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L19'), grade('3'), record_id('im_defrag_1559c36f6597cc5c69eb12a6_1'), statement_sha('16770afde13dadcef6f637d6ca79d6bf0e206100ea34f178ee2111a8230d255a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_158edc2f75221a75b32f5196_1', "150 of the 0.01-ounce weights",
    analysis(
        quantities([quantity(150, "weights", "150"), quantity(0.01, "ounce", "0.01-ounce")]),
        ask("What is the total weight of 150 weights that each weigh 0.01 ounce?"),
        steps([step("multiply", [150, 0.01], 1.5)]),
        answer(1.5, "ounce"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U5-L4'), grade('5'), record_id('im_defrag_158edc2f75221a75b32f5196_1'), statement_sha('20f36c533a9708a05f6330f055dd95f910fac7488b017291de2d2b595ff86bec')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_0.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_171c79588a7e40f2f49a15ae_1', "142,571 + 10,909",
    analysis(
        quantities([quantity(142571, "number", "142,571"), quantity(10909, "number", "10,909")]),
        ask("What is the sum of 142,571 and 10,909?"),
        steps([step("addition", [142571, 10909], 153480)]),
        answer(153480, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U4-L20'), grade('4'), record_id('im_defrag_171c79588a7e40f2f49a15ae_1'), statement_sha('1fab2b9dcd762e2105f24f0ce0c7c932237e8816424b16ba335eff054801899c')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_180e61bc3bb7e5b980d00952_1', "80 + 5 = 5 + 80",
    analysis(
        quantities([quantity(80, "number", "80"), quantity(5, "number", "5"), quantity(5, "number", "5"), quantity(80, "number", "80")]),
        ask("Is 80 + 5 equal to 5 + 80?"),
        steps([step("addition", [80, 5], 85), step("addition", [5, 80], 85), step("compare_equal", [85, 85], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U4-L11'), grade('1'), record_id('im_defrag_180e61bc3bb7e5b980d00952_1'), statement_sha('716443639a428ac84586724d45bdeb8a896de386b4cc6cc29bf3e9f98987a576')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_18646d288e67da7c2e0417bf_1', "The class used 234 square sticky notes to cover their classroom door completely, leaving no gaps or overlaps between the notes. It takes 9 square notes to cover the width of the door. How many square notes does it take to cover the full height of the door?",
    analysis(
        quantities([quantity(234, "square notes", "234 square sticky notes"), quantity(9, "square notes", "9 square notes")]),
        ask("How many square notes are needed to cover the full height of the door?"),
        steps([step("division", [234, 9], 26)]),
        answer(26, "square notes"),
        missing_doing("recognizing the relationship between area and dimensions (area = width * height)")),
    anchor(lesson('IM-G4-U6-L14'), grade('4'), record_id('im_defrag_18646d288e67da7c2e0417bf_1'), statement_sha('aed090724d122912d7c96c59e8484966cbe941cdbf68ea49781c0c5f6a172db5')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_1871cc56be3e6f6b2d862cc5_1', "Han has 14 tops. He shares the tops equally between 2 boxes. How many tops will be in each box? Select all the ways that we could represent the situation. A. B. C. D.",
    analysis(
        quantities([quantity(14, "tops", "14 tops"), quantity(2, "boxes", "2 boxes")]),
        ask("How many tops will be in each box if 14 tops are shared equally between 2 boxes?"),
        steps([step("division", [14, 2], 7)]),
        answer(7, "tops"),
        missing_doing("selecting the correct mathematical representations from multiple choice options")),
    anchor(lesson('IM-G3-U4-L4'), grade('3'), record_id('im_defrag_1871cc56be3e6f6b2d862cc5_1'), statement_sha('ee80b9a6d584ff4511f5a87c4478e4dccaf9cf95e3c45e2cc4fde500f24a1606')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_188b9ba6129d801a7feff4e5_1', "4. Mai made 8 frogs. Diego made 17 frogs. How many more frogs did Diego make than Mai?",
    analysis(
        quantities([quantity(8, "frogs", "8 frogs"), quantity(17, "frogs", "17 frogs")]),
        ask("How many more frogs did Diego make than Mai?"),
        steps([step("subtraction", [17, 8], 9)]),
        answer(9, "frogs"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U6-L15'), grade('1'), record_id('im_defrag_188b9ba6129d801a7feff4e5_1'), statement_sha('037fd475d1ed7b12ca255c922eff8487f234428ef3445cf6937f31c69126d3e1')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_18bfc3f274ac5a1713cd34b4_1', "Find the quotient of 511 ÷ 5. Show your reasoning.",
    analysis(
        quantities([quantity(511, "number", "511"), quantity(5, "number", "5")]),
        ask("Find the quotient of 511 divided by 5."),
        steps([step("divide", [511, 5], 102.2)]),
        answer(102.2, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U5-L9'), grade('6'), record_id('im_defrag_18bfc3f274ac5a1713cd34b4_1'), statement_sha('b3c032ce4ab7a7b07c4ef5a6c6ff741388db5d0fc363b1cd5f1081c6c47e5607')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_18c01fc6cc3e772cbdc9976f_1', "$3 for a 12-oz cup, or $5 for a 20-oz cup. Which horchata special is a better deal?",
    analysis(
        quantities([quantity(3, "dollars", "$3"), quantity(12, "oz", "12-oz"), quantity(5, "dollars", "$5"), quantity(20, "oz", "20-oz")]),
        ask("Which horchata special is a better deal?"),
        steps([step("division", [3, 12], 0.25), step("division", [5, 20], 0.25)]),
        answer(0.25, "dollars per oz"),
        missing_doing("comparing unit rates")),
    anchor(lesson('IM-G6-U3-L6'), grade('6'), record_id('im_defrag_18c01fc6cc3e772cbdc9976f_1'), statement_sha('42e4c1cca220509fb7b82a466e7717018949c02660ac6f52f6e817c42214ccc2')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_2.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_1a9c60972f4b23e64cf2f219_1', "Solve each problem. Show your thinking using objects, a drawing, or a diagram. 1. A vendor at a farmers’ market has 7 dozen eggs. How many eggs does the vendor have? 2. The farmers’ market has a space for shows. The space has 5 rows of chairs, and each row has 15 chairs. How many chairs are in the space? 3. A booth at the farmers’ market has a rectangular tabletop. Its sides are 4 feet and 16 feet long. What is the area of the tabletop?",
    analysis(
        quantities([quantity(7, "dozen", "7 dozen")]),
        ask("How many eggs does the vendor have?"),
        steps([step("multiplication", [7, 12], 84)]),
        answer(84, "eggs"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L13'), grade('3'), record_id('im_defrag_1a9c60972f4b23e64cf2f219_1'), statement_sha('8624efbc5017bf34b8381cefa9c5cdd1321c5aec121f7ee9431a8ce8dc587529')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_1aaf651fb29e1c5d1012940b_1', "Find the value of each expression mentally. 7 ÷ 100",
    analysis(
        quantities([quantity(7, "number", "7"), quantity(100, "number", "100")]),
        ask("What is the value of the expression 7 divided by 100?"),
        steps([step("division", [7, 100], 0.07)]),
        answer(0.07, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U4-L9'), grade('7'), record_id('im_defrag_1aaf651fb29e1c5d1012940b_1'), statement_sha('b7f2079b62928f65cf47ee5f06157a2505ec72c9c9b1af4b8fabbc1eeb360a42')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_1ab26c9b0746e64b9adc0299_1', "Tyler put 26 apples into his basket. Clare put 35 apples into her basket. Ask and answer a math question about this situation.",
    analysis(
        quantities([quantity(26, "apples", "26 apples"), quantity(35, "apples", "35 apples")]),
        ask("How many apples did Tyler and Clare put in their baskets altogether?"),
        steps([step("add", [26, 35], 61)]),
        answer(61, "apples"),
        missing_doing("formulating a question")),
    anchor(lesson('IM-G2-U9-L10'), grade('2'), record_id('im_defrag_1ab26c9b0746e64b9adc0299_1'), statement_sha('beebe7c83a15408e047000bab078c2fbd5b1e41115965453049a4690c95e1868')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_3.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_1ad68336902574b1c95dd090_1', "The school band wants to raise $1,700 for a music festival. They have raised $175 each week for the past 6 weeks. Write a question that could be asked about this situation and answer it. Show your reasoning.",
    analysis(
        quantities([quantity(1700, "dollars", "$1,700"), quantity(175, "dollars per week", "$175"), quantity(6, "weeks", "6 weeks")]),
        ask("The problem asks to write a question about the situation and answer it."),
        steps([step("multiply", [175, 6], 1050), step("subtract", [1700, 1050], 650)]),
        answer(650, "dollars"),
        missing_doing("creative writing")),
    anchor(lesson('IM-G4-U9-L9'), grade('4'), record_id('im_defrag_1ad68336902574b1c95dd090_1'), statement_sha('9111f416564d88b30f1a9e3fd137843066534a86c76372c1f771d8f79d9c570e')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_1b3f6b68111fac9712525076_1', "Find the value of 15 × 43. Show your reasoning.",
    analysis(
        quantities([quantity(15, "number", "15"), quantity(43, "number", "43")]),
        ask("What is the value of 15 multiplied by 43?"),
        steps([step("multiplication", [15, 40], 600), step("multiplication", [15, 3], 45), step("addition", [600, 45], 645)]),
        answer(645, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U6-L10'), grade('4'), record_id('im_defrag_1b3f6b68111fac9712525076_1'), statement_sha('4296bc45c117049d1ede5d2065916e4ac6aa9fd31eb4c6d9bc3eb6de6a44bcc1')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_1c0b73476712e730de914fe3_1', "Kiran is setting up a game of mancala (mahn-KAH-lah). He has a jar of 122 stones. From the jar, he takes 3 stones to put in each of the 6 pits on his side of the board. How many stones are in the jar now? 1. Write an equation to represent the situation. Use a letter for the unknown quantity. 2. Solve the problem. Explain or show your reasoning. 3. Explain how you know your answer makes sense.",
    analysis(
        quantities([quantity(122, "stones", "122 stones"), quantity(3, "stones", "3 stones"), quantity(6, "pits", "6 pits")]),
        ask("How many stones are left in the jar after Kiran takes 3 stones for each of the 6 pits?"),
        steps([step("multiplication", [3, 6], 18), step("subtraction", [122, 18], 104)]),
        answer(104, "stones"),
        missing_doing("formulating an algebraic equation and providing qualitative reasoning")),
    anchor(lesson('IM-G3-U3-L19'), grade('3'), record_id('im_defrag_1c0b73476712e730de914fe3_1'), statement_sha('5af83f806eb6762582a90815460b1d9813b21752bf1bc034c64253def16d7428')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_1cbbdec71a1b0c84e002aa2b_1', "If someone uses 455 liters of soda water, how much orange juice would they need? [solution: 455=5*91]",
    analysis(
        quantities([quantity(455, "liters of soda water", "455 liters of soda water"), quantity(5, "ratio", "5")]),
        ask("How much orange juice would they need if they use 455 liters of soda water?"),
        steps([step("divide", [455, 5], 91)]),
        answer(91, "liters of orange juice"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L11'), grade('6'), record_id('im_defrag_1cbbdec71a1b0c84e002aa2b_1'), statement_sha('141f11a591cc52eb4192dd1ac23b62e38f310779343349da74e58afca0b41686')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_1d38f2d1ca2433b43ca0b149_1', "A certain type of car has room for 4 passengers. How many passengers could fit in 78 cars?",
    analysis(
        quantities([quantity(4, "passengers", "4 passengers"), quantity(78, "cars", "78 cars")]),
        ask("How many passengers can fit in 78 cars if each car holds 4 passengers?"),
        steps([step("multiplication", [4, 78], 312)]),
        answer(312, "passengers"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U4-L6'), grade('7'), record_id('im_defrag_1d38f2d1ca2433b43ca0b149_1'), statement_sha('18aa4f8eeb6d2e4e45156b11e7e9f161c5caf52e7c83a226750991678dc77cc7')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_1d7706acfef81e68af70b376_1', "Andre has 8 boxes. Each box has 10 cars in it. He has 80 cars altogether.",
    analysis(
        quantities([quantity(8, "boxes", "8 boxes"), quantity(10, "cars per box", "10 cars"), quantity(80, "cars", "80 cars")]),
        ask("The problem is a statement of fact rather than a question, but it asserts that 8 boxes of 10 cars equals 80 cars."),
        steps([step("multiplication", [8, 10], 80), step("compare_equal", [80, 80], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U1-L13'), grade('3'), record_id('im_defrag_1d7706acfef81e68af70b376_1'), statement_sha('b092dcd499e839aea5351990c27ce234f6d1be5b2a2bc3db922b9d6541d383ea')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_1ea1b9c80c3b82b69ec78f99_1', "At the market, avocados cost $1 each and pineapples cost $2 each. 1. Noah has $10 to spend at the produce market. Can he buy 7 avocados and 2 pineapples? Explain or show your reasoning. 2. What combinations of avocados and pineapples can Noah buy if he spends all of his $10? 3. Write an equation that represents $10 combinations of avocados and pineapples, using for the number of avocados and for the number of pineapples. 4. What are 3 combinations of avocados and pineapples that make your equation true? What are three combinations of avocados and pineapples that make it false?",
    analysis(
        quantities([quantity(1, "dollars per avocado", "$1 each"), quantity(2, "dollars per pineapple", "$2 each"), quantity(10, "dollars", "$10"), quantity(7, "avocados", "7 avocados"), quantity(2, "pineapples", "2 pineapples")]),
        ask("Can Noah buy 7 avocados and 2 pineapples with $10?"),
        steps([step("multiply", [7, 1], 7), step("multiply", [2, 2], 4), step("add", [7, 4], 11), step("compare_less_equal", [11, 10], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G8-U3-L13'), grade('8'), record_id('im_defrag_1ea1b9c80c3b82b69ec78f99_1'), statement_sha('b898e0fb17696ccb7e1ec183f0e08404bdf8ef396b0943ea00e711dc953c8d01')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/reallms_g68.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_1ee83ca96bb5e2420f99e382_1', "If the original recipe is for one batch of maroon paint, how many batches are in 80 ml of maroon paint? (each batch 5+3 = 8 ml)",
    analysis(
        quantities([quantity(80, "ml", "80 ml"), quantity(5, "ml", "5"), quantity(3, "ml", "3")]),
        ask("How many batches of maroon paint are contained in 80 ml, given that each batch consists of 5 ml plus 3 ml?"),
        steps([step("addition", [5, 3], 8), step("division", [80, 8], 10)]),
        answer(10, "batches"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L15'), grade('6'), record_id('im_defrag_1ee83ca96bb5e2420f99e382_1'), statement_sha('8235913cd3d8594d22903fb142a8cd87cb65badbbd9aef1f410ad58564b5d50c')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_21acc16040bd227e7ea0041c_1', "Solve each equation mentally: b · 50 = 60",
    analysis(
        quantities([quantity(50, "number", "50"), quantity(60, "number", "60")]),
        ask("Find the value of b that satisfies the equation b times 50 equals 60."),
        steps([step("division", [60, 50], 1.2)]),
        answer(1.2, "number"),
        missing_doing("algebraic manipulation")),
    anchor(lesson('IM-G7-U4-L8'), grade('7'), record_id('im_defrag_21acc16040bd227e7ea0041c_1'), statement_sha('d708e073db0885eb981029bdd019200208ef633817d26981409a182a4030c473')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_2225324d9981c3b9156941b1_1', "4 + 6 = 3 + 7",
    analysis(
        quantities([quantity(4, "number", "4"), quantity(6, "number", "6"), quantity(3, "number", "3"), quantity(7, "number", "7")]),
        ask("Check if 4 + 6 is equal to 3 + 7."),
        steps([step("addition", [4, 6], 10), step("addition", [3, 7], 10), step("compare_equal", [10, 10], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L14'), grade('1'), record_id('im_defrag_2225324d9981c3b9156941b1_1'), statement_sha('0a13b93f955230775d56493278c0e357d04b3be4c66f176347d9f64d4ac645a0')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_22294ed89d49933f8e4258da_1', "Elena buys 4 mangoes. Her grandfather buys 2 pineapples. How many pieces of fruit did they buy?",
    analysis(
        quantities([quantity(4, "mangoes", "4 mangoes"), quantity(2, "pineapples", "2 pineapples")]),
        ask("How many total pieces of fruit did Elena and her grandfather buy?"),
        steps([step("addition", [4, 2], 6)]),
        answer(6, "pieces of fruit"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U5-L5'), grade('K'), record_id('im_defrag_22294ed89d49933f8e4258da_1'), statement_sha('fbdb2270ac6b88cc9213ec5cb477af91b034d656848dfbf2e3d9e5452846877a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_22524c2421499c7bb516a2b9_1', "Jada goes to the park. She sees 8 dogs, 4 ducks, and 7 frogs. How many animals does she see? Show your thinking using drawings, numbers, or words. Equation:",
    analysis(
        quantities([quantity(8, "dogs", "8 dogs"), quantity(4, "ducks", "4 ducks"), quantity(7, "frogs", "7 frogs")]),
        ask("How many total animals does Jada see at the park?"),
        steps([step("addition", [8, 4], 12), step("addition", [12, 7], 19)]),
        answer(19, "animals"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L20'), grade('1'), record_id('im_defrag_22524c2421499c7bb516a2b9_1'), statement_sha('5e255b19b72d29bcd8ec71509954461aaf1f248fc9f0e0ca36f82c7048169437')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_22cbd56e42185c2c5e8983b7_1', "9 students play bingo. 3 students use blue chips to cover their boards. The other students use yellow chips. How many students use yellow chips? Explain how each equation matches the story problem. Show your thinking using drawings, numbers, or words. 1. Clare writes . 2. Jada writes .",
    analysis(
        quantities([quantity(9, "students", "9 students"), quantity(3, "students", "3 students")]),
        ask("How many students use yellow chips?"),
        steps([step("subtraction", [9, 3], 6)]),
        answer(6, "students"),
        missing_doing("explanation and modeling")),
    anchor(lesson('IM-G1-U2-L17'), grade('1'), record_id('im_defrag_22cbd56e42185c2c5e8983b7_1'), statement_sha('85c9f8f5f9e084f2655e55e8367943dc764301cf3aaa438d4c01d767f5b1b615')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_22d48c5e41ba610ab1f1dfe0_1', "16- 5 = 11",
    analysis(
        quantities([quantity(16, "number", "16"), quantity(5, "number", "5"), quantity(11, "number", "11")]),
        ask("Check if 16 minus 5 equals 11."),
        steps([step("subtraction", [16, 5], 11), step("compare_equal", [11, 11], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U6-L14'), grade('1'), record_id('im_defrag_22d48c5e41ba610ab1f1dfe0_1'), statement_sha('8fd3e3366abf318aadd3a38c4a0e4e4358b4629b75b2660800e115ddb3eb3abf')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_22da88b44b3380497dfe8788_1', "50,000- 999 = 49,001",
    analysis(
        quantities([quantity(50000, "number", "50,000"), quantity(999, "number", "999"), quantity(49001, "number", "49,001")]),
        ask("Is the statement 50,000 - 999 = 49,001 true?"),
        steps([step("subtraction", [50000, 999], 49001), step("compare_equal", [49001, 49001], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U6-L24'), grade('4'), record_id('im_defrag_22da88b44b3380497dfe8788_1'), statement_sha('1f185b66f93d0e1cf2d98ddea0e9f545c8652aaf8eb739d242f67c68a97c98fa')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_2373ba95b121fc7c000241c3_1', "3 liters of water are shared equally by 5 people. How much water does each person get? Write a division equation to represent the situation. Draw a diagram if it is helpful.",
    analysis(
        quantities([quantity(3, "liters", "3 liters"), quantity(5, "people", "5 people")]),
        ask("How much water does each person get?"),
        steps([step("division", [3, 5], 0.6)]),
        answer(0.6, "liters"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U2-L3'), grade('5'), record_id('im_defrag_2373ba95b121fc7c000241c3_1'), statement_sha('1b1d3d74c97584dc120af88c30d1d45deb8caf0bdb8b704f09878b092ddbfc84')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_2373cf0d1beace9ccb5d3f9a_1', "Find the value of each expression mentally. 5,000 ÷ 10,000",
    analysis(
        quantities([quantity(5000, "number", "5,000"), quantity(10000, "number", "10,000")]),
        ask("What is the value of the expression 5,000 divided by 10,000?"),
        steps([step("division", [5000, 10000], 0.5)]),
        answer(0.5, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U4-L1'), grade('6'), record_id('im_defrag_2373cf0d1beace9ccb5d3f9a_1'), statement_sha('99aadbfbf4a55f4268dfd912ff60415209d1e54020da8cf9111d1532011f8c34')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_242408ebae1e8f21061d6ea6_1', "300- 100 = 100- 300",
    analysis(
        quantities([quantity(300, "number", "300"), quantity(100, "number", "100"), quantity(100, "number", "100"), quantity(300, "number", "300")]),
        ask("Determine if 300 minus 100 is equal to 100 minus 300."),
        steps([step("subtraction", [300, 100], 200), step("subtraction", [100, 300], -200), step("compare_equal", [200, -200], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U3-L9'), grade('3'), record_id('im_defrag_242408ebae1e8f21061d6ea6_1'), statement_sha('0e65868022c86a4457d1b4229a5c5567ff0f6bbd32ee24859a51aef339a134e7')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_244e7d7cda9e801b29f266cd_1', "Kiran’s pet snake is 47 cm long. It is 26 cm shorter than Han’s pet snake. How long is Han’s pet snake? 1. Circle the diagram that matches the story. 2. Solve. Show your thinking using drawings, numbers, or words. Han’s snake is _______________ cm long.",
    analysis(
        quantities([quantity(47, "cm", "47 cm"), quantity(26, "cm", "26 cm")]),
        ask("How long is Han's pet snake?"),
        steps([step("addition", [47, 26], 73)]),
        answer(73, "cm"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U3-L6'), grade('2'), record_id('im_defrag_244e7d7cda9e801b29f266cd_1'), statement_sha('0e5dbdf0399824a4104142a71fe198bb49fa9d234a1dca3dfaeaa3dc357455d8')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_246272022aee4fa7acefd39e_1', "10- 4 = 6",
    analysis(
        quantities([quantity(10, "number", "10"), quantity(4, "number", "4"), quantity(6, "number", "6")]),
        ask("Check if 10 minus 4 equals 6."),
        steps([step("subtraction", [10, 4], 6), step("compare_equal", [6, 6], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U2-L19'), grade('1'), record_id('im_defrag_246272022aee4fa7acefd39e_1'), statement_sha('0e0a72190e63403ba0285f4116e048d472e3bb8633d5c3b61350f49cddad0897')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_24a4bf02a5a6c2cca05dd1a2_1', "10 + 4 = 10 + 5",
    analysis(
        quantities([quantity(10, "number", "10"), quantity(4, "number", "4"), quantity(10, "number", "10"), quantity(5, "number", "5")]),
        ask("Is the equation 10 + 4 = 10 + 5 true?"),
        steps([step("addition", [10, 4], 14), step("addition", [10, 5], 15), step("compare_equal", [14, 15], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L11'), grade('1'), record_id('im_defrag_24a4bf02a5a6c2cca05dd1a2_1'), statement_sha('ec371ee4f45235cf9aa9b3854a1cdca63053c157a20b935e01369ed90c08a6dd')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_2531ee6d5cf1cb18782d4a09_1', "4 × 45 = 2 × 90",
    analysis(
        quantities([quantity(4, "number", "4"), quantity(45, "number", "45"), quantity(2, "number", "2"), quantity(90, "number", "90")]),
        ask("Is 4 times 45 equal to 2 times 90?"),
        steps([step("multiply", [4, 45], 180), step("multiply", [2, 90], 180), step("compare_equal", [180, 180], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U7-L9'), grade('4'), record_id('im_defrag_2531ee6d5cf1cb18782d4a09_1'), statement_sha('cf7a110f91e551f591e980901c6c79490121ca57660b3dabdcb2e7f0f4780fe0')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_2572d85a1e7839a3cd7b5bee_1', "A diagram of the base-ten blocks that represent 138 + 425 is shown. Use an algorithm you learned in today's lesson to find the value of the sum.",
    analysis(
        quantities([quantity(138, "number", "138"), quantity(425, "number", "425")]),
        ask("What is the sum of 138 and 425?"),
        steps([step("addition", [138, 425], 563)]),
        answer(563, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U3-L4'), grade('3'), record_id('im_defrag_2572d85a1e7839a3cd7b5bee_1'), statement_sha('106bd7246df3354c61e4c19ec413a49fca8616771998575286970a1e292e1aba')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_2720bfaafca03d9a017b991d_1', "48 - 22 = ? Find the number that makes the equation true. Represent your thinking on the number line.",
    analysis(
        quantities([quantity(48, "number", "48"), quantity(22, "number", "22")]),
        ask("Find the number that makes the equation 48 - 22 = ? true."),
        steps([step("subtraction", [48, 22], 26)]),
        answer(26, "number"),
        missing_doing("representing thinking on a number line")),
    anchor(lesson('IM-G2-U4-L10'), grade('2'), record_id('im_defrag_2720bfaafca03d9a017b991d_1'), statement_sha('9ab00da1aee1068d264dfad5ce1dce87d130c38e68715ffadda0d64559f57d18')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_2.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_27359bf24a4a4ce614353541_1', "Tyler gathers 42 sunflower seeds. Birds eat 28 of the seeds. How many seeds does Tyler have now? Show your thinking.",
    analysis(
        quantities([quantity(42, "sunflower seeds", "42 sunflower seeds"), quantity(28, "sunflower seeds", "28 of the seeds")]),
        ask("How many sunflower seeds does Tyler have remaining?"),
        steps([step("subtraction", [42, 28], 14)]),
        answer(14, "sunflower seeds"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U2-L11'), grade('2'), record_id('im_defrag_27359bf24a4a4ce614353541_1'), statement_sha('693bb1cd5241e3a77ce3af2daffdd7c3dff60e6c2ab2a3b7683f36d852154121')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_275241891c3b752ff1533837_1', "Mai picks apples. She picks 5 yellow apples and 2 red apples.",
    analysis(
        quantities([quantity(5, "yellow apples", "5"), quantity(2, "red apples", "2")]),
        ask("How many apples did Mai pick in total?"),
        steps([step("add", [5, 2], 7)]),
        answer(7, "apples"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U5-L6'), grade('K'), record_id('im_defrag_275241891c3b752ff1533837_1'), statement_sha('9cf3d24ccaeac5e2ea2255ee3466b21651a835ac66a373c4851da10309c51b8e')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_3.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_275e5110838ff66c19335dfc_1', "1. Use the digits 3, 4, 6, and 8 to make the greatest product. Use each digit only once. 2. Explain your reasoning.",
    analysis(
        quantities([quantity(3, "digit", "3"), quantity(4, "digit", "4"), quantity(6, "digit", "6"), quantity(8, "digit", "8")]),
        ask("What is the greatest product that can be made using the digits 3, 4, 6, and 8 exactly once?"),
        steps([step("multiply", [8, 6], 48), step("multiply", [4, 3], 12), step("multiply", [48, 12], 576)]),
        answer(576, "product"),
        missing_doing("optimization strategy for multi-digit multiplication")),
    anchor(lesson('IM-G5-U8-L1'), grade('5'), record_id('im_defrag_275e5110838ff66c19335dfc_1'), statement_sha('50f9a00bc0dd6b35c5df1f78ad34326d2e5cbfe864418602e7347c7007222d43')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_276e1a627c2ee532ffc64670_1', "Find the value of 162 × 35.",
    analysis(
        quantities([quantity(162, "number", "162"), quantity(35, "number", "35")]),
        ask("Find the value of 162 × 35."),
        steps([step("multiply", [162, 35], 5670)]),
        answer(5670, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U4-L2'), grade('5'), record_id('im_defrag_276e1a627c2ee532ffc64670_1'), statement_sha('901e2421285d772b2a78b70b05a3f1f2df401c0289052a91e502cb875ec3ac49')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_5.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_27c9b827a8a24c329ddc9e60_1', "Use long division to find each quotient. Write your answer as a decimal. b. 216 ÷ 5",
    analysis(
        quantities([quantity(216, "number", "216"), quantity(5, "number", "5")]),
        ask("What is the quotient of 216 divided by 5 expressed as a decimal?"),
        steps([step("division", [216, 5], 43.2)]),
        answer(43.2, "decimal"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U5-L12'), grade('6'), record_id('im_defrag_27c9b827a8a24c329ddc9e60_1'), statement_sha('d95d465aef1b8fdfd161de4940d3af9249583b6f33335e0cc103fa5c07e56957')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_2938600509cc127a585447a3_1', "Han made a tower with 10 cubes. He broke his tower into 2 parts and hid 1 part. He shows 4 cubes. How many cubes is Han hiding?",
    analysis(
        quantities([quantity(10, "cubes", "10 cubes"), quantity(4, "cubes", "4 cubes")]),
        ask("How many cubes is Han hiding?"),
        steps([step("subtraction", [10, 4], 6)]),
        answer(6, "cubes"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U5-L14'), grade('K'), record_id('im_defrag_2938600509cc127a585447a3_1'), statement_sha('3d323c8ca03a94c9fa05b80b2fdd1cdc433d9032e34a8b7792ff204d6e78e17a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_2ad912409465b5a64c65db80_1', "6 × 40 = 24 × 10",
    analysis(
        quantities([quantity(6, "number", "6"), quantity(40, "number", "40"), quantity(24, "number", "24"), quantity(10, "number", "10")]),
        ask("Check if 6 multiplied by 40 is equal to 24 multiplied by 10."),
        steps([step("multiplication", [6, 40], 240), step("multiplication", [24, 10], 240), step("compare_equal", [240, 240], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U7-L2'), grade('3'), record_id('im_defrag_2ad912409465b5a64c65db80_1'), statement_sha('99ed8694a60e7e7e8b06bbf5e3545be92ccdf38a37caf3039f946f10963f0151')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_2ae1532f8e7aba099e5442eb_1', "Show your thinking using objects, drawings, numbers, or words. 2. 5 books are on the table. 2 of the books fall on the floor. How many books are still on the table?",
    analysis(
        quantities([quantity(5, "books", "5 books"), quantity(2, "books", "2 of the books")]),
        ask("How many books are still on the table?"),
        steps([step("subtraction", [5, 2], 3)]),
        answer(3, "books"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U2-L1'), grade('1'), record_id('im_defrag_2ae1532f8e7aba099e5442eb_1'), statement_sha('7a0e223419cb06a9f7d44382798c9c04b1158d19ebc1d72244d765b5648152a8')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_2b89248612be1155dfeabdf9_1', "She draws 3 birds in a nest and 9 birds flying. How many birds did she draw?",
    analysis(
        quantities([quantity(3, "birds", "3 birds"), quantity(9, "birds", "9 birds")]),
        ask("How many birds did she draw in total?"),
        steps([step("addition", [3, 9], 12)]),
        answer(12, "birds"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L17'), grade('1'), record_id('im_defrag_2b89248612be1155dfeabdf9_1'), statement_sha('01bdbc5d4b79fccbb6d65f205b8136a3892a1766c48594d24e0a8345e198ee34')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_2bba5a45a198399cb60267ff_1', "Noah collects game pieces. He has 19 game pieces arranged like this in his bin. Noah takes out 8 game pieces to play with. How many game pieces are left in the bin? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(19, "game pieces", "19 game pieces"), quantity(8, "game pieces", "8 game pieces")]),
        ask("How many game pieces are left in the bin?"),
        steps([step("subtraction", [19, 8], 11)]),
        answer(11, "game pieces"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L12'), grade('1'), record_id('im_defrag_2bba5a45a198399cb60267ff_1'), statement_sha('9065b5d650e593dedefc25112df7ec716cc3f240ffd55c05258fed7be5707c80')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_2c1eb1b61e668fbc353b0c0d_1', "If someone uses 455 liters of soda water, how much orange juice would they need? [OJ = 4*91; solution: 4*91=364]",
    analysis(
        quantities([quantity(455, "liters", "455 liters"), quantity(4, "multiplier", "4"), quantity(91, "multiplier", "91")]),
        ask("How much orange juice would be needed if 455 liters of soda water are used?"),
        steps([step("multiplication", [4, 91], 364)]),
        answer(364, "liters"),
        missing_doing("interpreting the parenthetical equation as the definition of the quantity needed")),
    anchor(lesson('IM-G6-U2-L11'), grade('6'), record_id('im_defrag_2c1eb1b61e668fbc353b0c0d_1'), statement_sha('de4485bdd67de4296a5d82421e792c7a13e95e19b1bbf91bd6f8ff4256840c95')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_2cefee171e6d8ccfbb509c6a_1', "Find the value of 3.57- 1.4 . Explain or show your reasoning.",
    analysis(
        quantities([quantity(3.57, "number", "3.57"), quantity(1.4, "number", "1.4")]),
        ask("What is the value of 3.57 minus 1.4?"),
        steps([step("subtraction", [3.57, 1.4], 2.17)]),
        answer(2.17, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U5-L14'), grade('5'), record_id('im_defrag_2cefee171e6d8ccfbb509c6a_1'), statement_sha('dba58c293d075e3a7acd3db508092ccfaba2a750009b2cf0dee13bacd03f550d')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_2d01d37dd0dbbfd15cb943b6_1', "Complete the tape diagram to represent the question: \"How many groups of 2 are in 7?\"",
    analysis(
        quantities([quantity(2, "group size", "2"), quantity(7, "total", "7")]),
        ask("How many groups of 2 are in 7?"),
        steps([step("division", [7, 2], 3.5)]),
        answer(3.5, "groups"),
        missing_doing("drawing a tape diagram")),
    anchor(lesson('IM-G6-U4-L6'), grade('6'), record_id('im_defrag_2d01d37dd0dbbfd15cb943b6_1'), statement_sha('9a09c449294fa9a0324cc479a8de980aa0a7dd494566c02212e6b8fb1418458d')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_2d3c8b3a36af219db1f6093c_1', "Mai finds 3 rocks. Diego finds 6 rocks. How many rocks did Diego and Mai find?",
    analysis(
        quantities([quantity(3, "rocks", "3 rocks"), quantity(6, "rocks", "6 rocks")]),
        ask("How many rocks did Diego and Mai find in total?"),
        steps([step("addition", [3, 6], 9)]),
        answer(9, "rocks"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U4-L18'), grade('K'), record_id('im_defrag_2d3c8b3a36af219db1f6093c_1'), statement_sha('5ba8357cbd44541a2bacc17e1d4f1e05431aaa3be712a8a3609a735bf539dbab')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_2d6f633f067f557028b3b471_1', "Use long division to show that: 5 ÷ 4, or 5/4, is 1.25.",
    analysis(
        quantities([quantity(5, "number", "5"), quantity(4, "number", "4"), quantity(1.25, "number", "1.25")]),
        ask("Verify if 5 divided by 4 is equal to 1.25 using long division."),
        steps([step("division", [5, 4], 1.25), step("compare_equal", [1.25, 1.25], true)]),
        answer(true, "claim_verdict"),
        missing_doing("long division algorithm execution")),
    anchor(lesson('IM-G6-U5-L12'), grade('6'), record_id('im_defrag_2d6f633f067f557028b3b471_1'), statement_sha('ee1a6322730dfb27aee16bfe87c776379446f9d34d12890a89da813870eae2d4')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_2de11ec05e035064f5f78b43_1', "How does knowing 7 + 2 = 9 help you with 2 + 7 = ? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(7, "number", "7"), quantity(2, "number", "2"), quantity(9, "number", "9"), quantity(2, "number", "2"), quantity(7, "number", "7")]),
        ask("How does the fact that 7 + 2 = 9 help you determine the result of 2 + 7?"),
        steps([step("add", [2, 7], 9)]),
        answer(9, "number"),
        missing_doing("applying the commutative property of addition")),
    anchor(lesson('IM-G1-U3-L2'), grade('1'), record_id('im_defrag_2de11ec05e035064f5f78b43_1'), statement_sha('ae10049461849f6bd303232abcdc3516c979b0936e02d4f637fe0f12f292dbde')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_5.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_2e632d5ce2cf4853a853e1da_1', "If the bug starts at 1 and jumps 4 units to the right, where does it end up? How far away from 0 is this? b.",
    analysis(
        quantities([quantity(1, "position", "1"), quantity(4, "units", "4 units")]),
        ask("What is the bug's final position after jumping 4 units to the right from position 1, and how far is that position from 0?"),
        steps([step("addition", [1, 4], 5), step("subtraction", [5, 0], 5)]),
        answer(5, "position and distance"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U7-L6'), grade('6'), record_id('im_defrag_2e632d5ce2cf4853a853e1da_1'), statement_sha('0456cf42e9ed5676b8a696bcf6f886ca1aff314e9e3bffa3290def8e50bdc3e9')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_2eb01d78ed3c025b17962bb1_1', "Find the value of 6 × 83. Use a diagram if it is helpful.",
    analysis(
        quantities([quantity(6, "multiplier", "6"), quantity(83, "multiplicand", "83")]),
        ask("What is the value of 6 multiplied by 83?"),
        steps([step("multiplication", [6, 80], 480), step("multiplication", [6, 3], 18), step("addition", [480, 18], 498)]),
        answer(498, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U6-L6'), grade('4'), record_id('im_defrag_2eb01d78ed3c025b17962bb1_1'), statement_sha('2e5b0de4f158bb602076eaf4b4107a0bf6c13f9b0612700d086fc5b0c41cb747')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_2ecac72555a6df2dd0264f15_1', "Each person needed 6 ounces of dough and 4 ounces of sauce ... A total of 130 ounces ... How many people were at the party?",
    analysis(
        quantities([quantity(6, "ounces of dough", "6 ounces of dough"), quantity(4, "ounces of sauce", "4 ounces of sauce"), quantity(130, "ounces", "130 ounces")]),
        ask("How many people were at the party?"),
        steps([step("addition", [6, 4], 10), step("division", [130, 10], 13)]),
        answer(13, "people"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L16'), grade('6'), record_id('im_defrag_2ecac72555a6df2dd0264f15_1'), statement_sha('a21b66b47a72a891385e62994957cf84245ef4a8611d3515e083365f6366d218')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_2f2e1a53ebe06849b457299e_1', "Han saw 4 shooting stars. Lin also saw some shooting stars. Together, they saw 12 shooting stars. How many shooting stars did Lin see? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(4, "shooting stars", "4 shooting stars"), quantity(12, "shooting stars", "12 shooting stars")]),
        ask("How many shooting stars did Lin see?"),
        steps([step("subtraction", [12, 4], 8)]),
        answer(8, "shooting stars"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U8-L5'), grade('1'), record_id('im_defrag_2f2e1a53ebe06849b457299e_1'), statement_sha('5f343e6d8adcda4af6ea331c1dfa80f0ae53826b255cb2321cc82d6a15663b50')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_2f8b8ba31ea15e371c27f06b_1', "Find the value of 132 ÷ 4. Show your thinking using diagrams, symbols, or other representations.",
    analysis(
        quantities([quantity(132, "number", "132"), quantity(4, "number", "4")]),
        ask("Find the value of 132 ÷ 4."),
        steps([step("division", [132, 4], 33)]),
        answer(33, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U6-L16'), grade('4'), record_id('im_defrag_2f8b8ba31ea15e371c27f06b_1'), statement_sha('72061956a3ecbd620034db6b582f4351b21a846ef5d051784a7adebb2e057065')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_1.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_2faf05d90faf4cd242c94aaa_1', "What do you notice? What do you wonder? Priya has a ribbon that is 44 inches long. She cuts off 18 inches. How long is it now? Andre draws this diagram to help him think about the problem. 1. What does the “?” represent in the story? 2. Why do you think there is a dotted line between the parts? 3. Find the unknown value. Show your thinking using drawings, numbers, or words. 4. Priya’s ribbon is __________________ long.",
    analysis(
        quantities([quantity(44, "inches", "44 inches"), quantity(18, "inches", "18 inches")]),
        ask("How long is the ribbon now after Priya cuts off 18 inches from her 44-inch ribbon?"),
        steps([step("subtraction", [44, 18], 26)]),
        answer(26, "inches"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U3-L11'), grade('2'), record_id('im_defrag_2faf05d90faf4cd242c94aaa_1'), statement_sha('e0d2fccdaa800b2d1d088ca6c2b0cf3b705d4db28be9e22cf5554b94d27e99e7')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_2fc2a68f1e98314ee9459ff5_1', "A worker packs 20 apples in 4 boxes. She packs the same number of apples in each box. How many apples are in each box?",
    analysis(
        quantities([quantity(20, "apples", "20 apples"), quantity(4, "boxes", "4 boxes")]),
        ask("How many apples are in each box?"),
        steps([step("division", [20, 4], 5)]),
        answer(5, "apples"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L2'), grade('3'), record_id('im_defrag_2fc2a68f1e98314ee9459ff5_1'), statement_sha('1df7feb7f8634d224ed6070be1b511aa628e18b190d2142c34d522019e094280')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_2fcc6f7dfbb7ed4869d7af61_1', "Lin runs for 25 seconds at 8 meters per second. What is her finish point?",
    analysis(
        quantities([quantity(25, "seconds", "25 seconds"), quantity(8, "meters per second", "8 meters per second")]),
        ask("What is the distance Lin runs?"),
        steps([step("multiplication", [25, 8], 200)]),
        answer(200, ""),
        missing_doing(null)),
    anchor(lesson('IM-G7-U5-L8'), grade('7'), record_id('im_defrag_2fcc6f7dfbb7ed4869d7af61_1'), statement_sha('347022f12a7510a06a7de8b22fe27a5404e24b78b8666e05c8335a58df154d90')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_300926c1ded9a98e90be5522_1', "How much is 10% of 10 liters of milk? c.",
    analysis(
        quantities([quantity(10, "percent", "10%"), quantity(10, "liters", "10 liters")]),
        ask("How much is 10% of 10 liters of milk?"),
        steps([step("multiply", [0.1, 10], 1.0)]),
        answer(1.0, "liters"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U3-L13'), grade('6'), record_id('im_defrag_300926c1ded9a98e90be5522_1'), statement_sha('a3f416807fa2283bec377ac5069c45dc1f8d6e5cc092665c23cca8098c505c93')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_304c9bfdd1a6c8c4138707d5_1', "A copy machine can print 480 copies every 4 minutes. b. A teacher printed 720 copies. How long did it take to print?",
    analysis(
        quantities([quantity(480, "copies", "480 copies"), quantity(4, "minutes", "4 minutes"), quantity(720, "copies", "720 copies")]),
        ask("How long did it take the teacher to print 720 copies?"),
        steps([step("division", [480, 4], 120), step("division", [720, 120], 6)]),
        answer(6, "minutes"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U3-L9'), grade('6'), record_id('im_defrag_304c9bfdd1a6c8c4138707d5_1'), statement_sha('bb2ccce7bf3e9afa1621cfa1da9e73739006758d7da921d537a37a649b56eed8')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_30763146ba0f7e9cc36e79df_1', "How much is 50% of 10 liters of milk? b.",
    analysis(
        quantities([quantity(50, "percent", "50%"), quantity(10, "liters", "10 liters")]),
        ask("What is 50% of 10 liters of milk?"),
        steps([step("division", [50, 100], 0.5), step("multiplication", [0.5, 10], 5)]),
        answer(5, "liters"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U3-L13'), grade('6'), record_id('im_defrag_30763146ba0f7e9cc36e79df_1'), statement_sha('66c15e4ba9dce79c6bc4888c5b6ae69261ab0fdffdf3fc0ae5419f28522bcb65')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_309074fb924393ce648f58d4_1', "6 × 45 = 45 + 90 + 135",
    analysis(
        quantities([quantity(6, "number", "6"), quantity(45, "number", "45"), quantity(45, "number", "45"), quantity(90, "number", "90"), quantity(135, "number", "135")]),
        ask("Determine if 6 times 45 is equal to the sum of 45, 90, and 135."),
        steps([step("multiplication", [6, 45], 270), step("addition", [45, 90], 135), step("addition", [135, 135], 270), step("compare_equal", [270, 270], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U7-L9'), grade('4'), record_id('im_defrag_309074fb924393ce648f58d4_1'), statement_sha('3b8c6f0d5d43b09cfa30c7ed3a2c32988fb95fda738ec5a04094c0e6af28ccb4')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_30ecf7a41a9c9ce6300ee946_1', "4 × 10 = 40 × 1",
    analysis(
        quantities([quantity(4, "number", "4"), quantity(10, "number", "10"), quantity(40, "number", "40"), quantity(1, "number", "1")]),
        ask("Check if 4 multiplied by 10 is equal to 40 multiplied by 1."),
        steps([step("multiplication", [4, 10], 40), step("multiplication", [40, 1], 40), step("compare_equal", [40, 40], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L19'), grade('3'), record_id('im_defrag_30ecf7a41a9c9ce6300ee946_1'), statement_sha('9f8189c81806be072ce4f2f4dd4c32557e23a81ebd54e6d9e3eadbe0fa46bdd2')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_3216e88e192d432e482335c8_1', "There are 7 kids on the bus. 1 more kid gets on the bus. How many kids are on the bus?",
    analysis(
        quantities([quantity(7, "kids", "7 kids"), quantity(1, "kid", "1 more kid")]),
        ask("How many kids are on the bus in total?"),
        steps([step("addition", [7, 1], 8)]),
        answer(8, "kids"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U8-L3'), grade('K'), record_id('im_defrag_3216e88e192d432e482335c8_1'), statement_sha('40a568fc1e3d70cec8a23d547967726e846f04e51860bec59c65e7db31d406e1')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_322a5281e5f09c10bd9cc226_1', "Find the value of 58 - 24. Show your thinking using a base-ten diagram.",
    analysis(
        quantities([quantity(58, "number", "58"), quantity(24, "number", "24")]),
        ask("What is the value of 58 minus 24?"),
        steps([step("subtraction", [58, 24], 34)]),
        answer(34, "number"),
        missing_doing("representing numbers visually with a base-ten diagram")),
    anchor(lesson('IM-G2-U4-L10'), grade('2'), record_id('im_defrag_322a5281e5f09c10bd9cc226_1'), statement_sha('39aa559b6daa3b95c770cef59008ac886f0a41b525ead49605cc0198f41e15c4')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_322e7e05dba5d4384d650b5c_1', "Consider these 2 situations. A. Han has 21 toy cars. B. Han has 21 toy He puts the same cars. He wants to number of cars in each put 3 cars in each of 3 boxes. How many box. How many cars are in each box? boxes will he need? Which situation does the expression represent? Explain your reasoning.",
    analysis(
        quantities([quantity(21, "toy cars", "21 toy cars"), quantity(21, "toy cars", "21 toy"), quantity(3, "cars", "3 cars"), quantity(3, "boxes", "3 boxes")]),
        ask("The problem asks for several things: how many cars are in each box (given the context), how many boxes are needed, which situation the expression represents, and an explanation."),
        steps([step("division", [21, 3], 7)]),
        answer(7, "boxes"),
        missing_doing("interpretive reasoning and expression matching")),
    anchor(lesson('IM-G3-U4-L4'), grade('3'), record_id('im_defrag_322e7e05dba5d4384d650b5c_1'), statement_sha('baff67ac03b329b4b2664b408e9bcc6a65090918cadcf6f193c0548bb17f095c')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_323020fe9d7b0a207c0349be_1', "Find the value of 258 + 217. Explain or show your reasoning.",
    analysis(
        quantities([quantity(258, "number", "258"), quantity(217, "number", "217")]),
        ask("Find the value of 258 + 217."),
        steps([step("add", [258, 217], 475)]),
        answer(475, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U3-L3'), grade('3'), record_id('im_defrag_323020fe9d7b0a207c0349be_1'), statement_sha('13c653bc87ba999bb90c9df104d40b5a69cde700dbfbb56a0534e3888918525c')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_0.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_323975f3bb6116638c16fb31_1', "7 + 8 = 15",
    analysis(
        quantities([quantity(7, "number", "7"), quantity(8, "number", "8"), quantity(15, "number", "15")]),
        ask("Is 7 + 8 equal to 15?"),
        steps([step("addition", [7, 8], 15), step("compare_equal", [15, 15], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U1-L13'), grade('3'), record_id('im_defrag_323975f3bb6116638c16fb31_1'), statement_sha('f05e92f739c520a4c57e388ff30d00642471ca238a98b118636a8c0a67d8f26e')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_326f8d9a5935b4f10324494e_1', "$3 for a 12-oz cup, or $5 for a 20-oz cup. Which horchata special is a better deal?",
    analysis(
        quantities([quantity(3, "dollars", "$3"), quantity(12, "oz", "12-oz"), quantity(5, "dollars", "$5"), quantity(20, "oz", "20-oz")]),
        ask("Which horchata special is a better deal?"),
        steps([step("divide", [3, 12], 0.25), step("divide", [5, 20], 0.25), step("compare_equal", [0.25, 0.25], true)]),
        answer(true, "equal_deals"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U3-L6'), grade('6'), record_id('im_defrag_326f8d9a5935b4f10324494e_1'), statement_sha('42e4c1cca220509fb7b82a466e7717018949c02660ac6f52f6e817c42214ccc2')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_33054e0c558059adc6415f4e_1', "Complete the table so ratios in each row are equivalent to 7:5. Row: 56 fl oz vinegar (=7*8), find soy sauce.",
    analysis(
        quantities([quantity(7, "ratio part 1", "7"), quantity(5, "ratio part 2", "5"), quantity(56, "fl oz vinegar", "56 fl oz vinegar")]),
        ask("Find the amount of soy sauce needed to make the ratio 56 fl oz vinegar to soy sauce equivalent to 7:5."),
        steps([step("divide", [56, 7], 8), step("multiply", [5, 8], 40)]),
        answer(40, "fl oz soy sauce"),
        missing_doing("proportional reasoning")),
    anchor(lesson('IM-G6-U2-L11'), grade('6'), record_id('im_defrag_33054e0c558059adc6415f4e_1'), statement_sha('617a60b979981a8d2dc3b4721a58b1ab150a12dd42ef34c48aba09bbed824cb6')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_3306197fd19110d4229997ef_1', "Find the value of each expression mentally. 3 ÷ 6",
    analysis(
        quantities([quantity(3, "number", "3"), quantity(6, "number", "6")]),
        ask("What is the value of the expression 3 divided by 6?"),
        steps([step("division", [3, 6], 0.5)]),
        answer(0.5, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U2-L12'), grade('7'), record_id('im_defrag_3306197fd19110d4229997ef_1'), statement_sha('8a51b3e424caf5acb91ed7c67802dbc1e328ec2eda13b8b9c0ac3817cffe559b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_3318d879cebfe21aa9532872_1', "Use long division to show that: 4 ÷ 5, or 4/5, is 0.8.",
    analysis(
        quantities([quantity(4, "number", "4"), quantity(5, "number", "5"), quantity(0.8, "decimal", "0.8")]),
        ask("Show that 4 divided by 5 is equal to 0.8."),
        steps([step("division", [4, 5], 0.8), step("compare_equal", [0.8, 0.8], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U5-L12'), grade('6'), record_id('im_defrag_3318d879cebfe21aa9532872_1'), statement_sha('f7b3d97cf8e2c5bf87962adcbdaa0e6ab37ba5c052f2867447c9dda2e21a54f3')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_33331e5031130f0656241f08_1', "10 counters in a cup. 4 of the counters fall out. How many counters are still in the cup?",
    analysis(
        quantities([quantity(10, "counters", "10 counters"), quantity(4, "counters", "4 of the counters")]),
        ask("How many counters remain in the cup?"),
        steps([step("subtraction", [10, 4], 6)]),
        answer(6, "counters"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L6'), grade('1'), record_id('im_defrag_33331e5031130f0656241f08_1'), statement_sha('73a76f15ee25d11132b27ea323e3bde336e49e2741142d2f62dbdbceb60a30db')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_33aa8d767563b0ce6a81c8c5_1', "Priya watches a football game. The home team scores 35 points. Then they score 6 more points. How many points do they score all together? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(35, "points", "35 points"), quantity(6, "points", "6 more points")]),
        ask("How many points did the home team score in total?"),
        steps([step("addition", [35, 6], 41)]),
        answer(41, "points"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U5-L8'), grade('1'), record_id('im_defrag_33aa8d767563b0ce6a81c8c5_1'), statement_sha('3df05a1101694c0e30858d4b3e36965e13bdba3731c3958b7eb767f7789cdc8b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_34483b2c64a16de69a99f15d_1', "Kiran ran 6,300 meters in 1/2 hour. At what rate did he run?",
    analysis(
        quantities([quantity(6300, "meters", "6,300 meters"), quantity(0.5, "hours", "1/2 hour")]),
        ask("What was Kiran's running rate in meters per hour?"),
        steps([step("division", [6300, 0.5], 12600)]),
        answer(12600, "meters per hour"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U3-L4'), grade('6'), record_id('im_defrag_34483b2c64a16de69a99f15d_1'), statement_sha('ace3e20591deae772c21b794a6f0c9608f0f85a4e8407c81231d14ff7fad213b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_34852920aeaba708aa6f437e_1', "Mai’s school has a book drive. They collect 48 children’s books. They collect 27 adult books. How many books do they collect all together? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(48, "children's books", "48 children’s books"), quantity(27, "adult books", "27 adult books")]),
        ask("How many books did the school collect in total?"),
        steps([step("addition", [48, 27], 75)]),
        answer(75, "books"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U5-L12'), grade('1'), record_id('im_defrag_34852920aeaba708aa6f437e_1'), statement_sha('308a2bdfe4891a223919dce8566305ae32b59e0e47303d5387463f621076124d')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_34d4305f31cf588607aa6a3f_1', "Find the value of 465 ÷ 5. Explain or show your reasoning.",
    analysis(
        quantities([quantity(465, "number", "465"), quantity(5, "number", "5")]),
        ask("What is the value of 465 divided by 5?"),
        steps([step("divide", [465, 5], 93)]),
        answer(93, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U6-L17'), grade('4'), record_id('im_defrag_34d4305f31cf588607aa6a3f_1'), statement_sha('6580e44764666048af64f82f8efb8493a9c7dbac7bea4cf3ba32f62c1ef0a17e')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_350f467d7e56afcff01ccaee_1', "125 + 200 = 200 + 125",
    analysis(
        quantities([quantity(125, "number", "125"), quantity(200, "number", "200"), quantity(200, "number", "200"), quantity(125, "number", "125")]),
        ask("Determine if the sum of 125 and 200 is equal to the sum of 200 and 125."),
        steps([step("addition", [125, 200], 325), step("addition", [200, 125], 325), step("compare_equal", [325, 325], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U3-L9'), grade('3'), record_id('im_defrag_350f467d7e56afcff01ccaee_1'), statement_sha('deddcd39a5656f3fab251c2801bc5fc5eae6f8eaa1e7aadf9c54b05cf1100565')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_35a1b0bc3f0a7538043617a8_1', "89 students were at the zoo. 41 students left the zoo on the first bus. How many students are at the zoo now? Show your thinking.",
    analysis(
        quantities([quantity(89, "students", "89 students"), quantity(41, "students", "41 students")]),
        ask("How many students are left at the zoo after 41 students left?"),
        steps([step("subtraction", [89, 41], 48)]),
        answer(48, "students"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U2-L3'), grade('2'), record_id('im_defrag_35a1b0bc3f0a7538043617a8_1'), statement_sha('b2989a325bbc5c97a8fa7af56437c4a6e2588d33ee4add85ffffe69605126cbc')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_35afd0bbaa16168060c34910_1', "10- 4 = 6",
    analysis(
        quantities([quantity(10, "number", "10"), quantity(4, "number", "4"), quantity(6, "number", "6")]),
        ask("Is the equation 10 - 4 = 6 true?"),
        steps([step("subtraction", [10, 4], 6), step("compare_equal", [6, 6], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U7-L4'), grade('K'), record_id('im_defrag_35afd0bbaa16168060c34910_1'), statement_sha('0e0a72190e63403ba0285f4116e048d472e3bb8633d5c3b61350f49cddad0897')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_365984e612140bf60f24eed1_1', "80 = 32 + 37",
    analysis(
        quantities([quantity(80, "number", "80"), quantity(32, "number", "32"), quantity(37, "number", "37")]),
        ask("Is the equation 80 = 32 + 37 true?"),
        steps([step("addition", [32, 37], 69), step("compare_equal", [80, 69], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U8-L10'), grade('1'), record_id('im_defrag_365984e612140bf60f24eed1_1'), statement_sha('40b8342e77ddb5b066ecc36971b5498874c040e5fac4181b942b7d6a35ed7c34')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_36f6e13e8225b53bf9ecdfe6_1', "Complete the table so ratios in each row are equivalent to 7:5. Row: 10 fl oz soy sauce (=5*2), find vinegar.",
    analysis(
        quantities([quantity(7, "ratio part", "7"), quantity(5, "ratio part", "5"), quantity(10, "fl oz soy sauce", "10 fl oz soy sauce")]),
        ask("Find the amount of vinegar needed to maintain a ratio of 7:5 when there are 10 fl oz of soy sauce, given that the soy sauce corresponds to the '5' part of the ratio."),
        steps([step("divide", [10, 5], 2), step("multiply", [7, 2], 14)]),
        answer(14, "fl oz vinegar"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L11'), grade('6'), record_id('im_defrag_36f6e13e8225b53bf9ecdfe6_1'), statement_sha('9d173a6d779359d0dcd86e8628d1e09b386f62131a7da638c51ce51141bd9ff6')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_370afc28e0756ea18aefae7b_1', "1. Is a whole number? Explain or show your reasoning. 2. Write 2 as a fraction. Explain or show your reasoning.",
    analysis(
        quantities([quantity(2, "number", "2")]),
        ask("Determine if 2 is a whole number and write 2 as a fraction."),
        steps([step("divide", [2, 1], 2)]),
        answer(2, "multi-part response"),
        missing_doing("mathematical reasoning and explanation")),
    anchor(lesson('IM-G3-U5-L13'), grade('3'), record_id('im_defrag_370afc28e0756ea18aefae7b_1'), statement_sha('73e26e3c1248659b20beb477ec29be8397bea8e3f3b590923475a5c221be1c5e')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_2.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_375dec66dcd6330d5f1445a0_1', "4 + 6 = 10",
    analysis(
        quantities([quantity(4, "number", "4"), quantity(6, "number", "6"), quantity(10, "number", "10")]),
        ask("Is the equation 4 + 6 = 10 true?"),
        steps([step("addition", [4, 6], 10), step("compare_equal", [10, 10], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U1-L6'), grade('1'), record_id('im_defrag_375dec66dcd6330d5f1445a0_1'), statement_sha('3ae7b0d51c2a23a26fdb32ff00ad4af95988729cbe6c9cef5dc1673367fd1637')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_378b7c38118a28abf1739dbf_1', "1. Use the table to find the total distance, in kilometers, Tyler ran during the week. Explain or show your reasoning. distance day (km) Monday 8.5 Tuesday 6.25 Wednesday 10.3 Thursday 5.75 Friday 9.25 2. Use the table to find the total distance, in meters, Clare ran during the week. Explain or show your reasoning. distance day (m) Monday 5,400 Tuesday 7,500 Wednesday 8,250 Thursday 6,750 Friday 7,250 3. Who ran farther, Clare or Tyler? How much farther? Explain or show your reasoning.",
    analysis(
        quantities([quantity(8.5, "km", "8.5"), quantity(6.25, "km", "6.25"), quantity(10.3, "km", "10.3"), quantity(5.75, "km", "5.75"), quantity(9.25, "km", "9.25"), quantity(5400, "m", "5,400"), quantity(7500, "m", "7,500"), quantity(8250, "m", "8,250"), quantity(6750, "m", "6,750"), quantity(7250, "m", "7,250")]),
        ask("Find Tyler's total distance in km, Clare's total distance in meters, and determine who ran farther and by how much."),
        steps([step("addition", [8.5, 6.25, 10.3, 5.75, 9.25], 40.05), step("addition", [5400, 7500, 8250, 6750, 7250], 35150), step("multiplication", [40.05, 1000], 40050), step("subtraction", [40050, 35150], 4900)]),
        answer(4900, "m"),
        missing_doing("The problem asks three distinct questions; providing a single answer requires selecting the most complex comparison result.")),
    anchor(lesson('IM-G5-U6-L5'), grade('5'), record_id('im_defrag_378b7c38118a28abf1739dbf_1'), statement_sha('60b79956f80955f7dcab50160849d75e10e82ee1293c099a2410cc9beb2a7904')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_4.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_37da5e7c839bd0c8e0c366e0_1', "Central Park is a large park in Manhattan. It is about 3.85 kilometers long and 0.79 kilometer wide. What is the approximate area of Central Park? Record an estimate that is: about too too low right high",
    analysis(
        quantities([quantity(3.85, "kilometers", "3.85 kilometers"), quantity(0.79, "kilometer", "0.79 kilometer")]),
        ask("What is the approximate area of Central Park?"),
        steps([step("multiply", [3.85, 0.79], 3.0415)]),
        answer(3.0415, "square kilometers"),
        missing_doing("estimating")),
    anchor(lesson('IM-G5-U5-L21'), grade('5'), record_id('im_defrag_37da5e7c839bd0c8e0c366e0_1'), statement_sha('88041a952540a99ec8ed7f42bab934b7474f64d3741483d578642c3caa17f471')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_37f31ec1a146a3abce77ca3f_1', "125 + 200 = 200 + 125",
    analysis(
        quantities([quantity(125, "number", "125"), quantity(200, "number", "200"), quantity(200, "number", "200"), quantity(125, "number", "125")]),
        ask("Check if the sum of 125 and 200 is equal to the sum of 200 and 125."),
        steps([step("addition", [125, 200], 325), step("addition", [200, 125], 325), step("compare_equal", [325, 325], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U3-L9'), grade('3'), record_id('im_defrag_37f31ec1a146a3abce77ca3f_1'), statement_sha('deddcd39a5656f3fab251c2801bc5fc5eae6f8eaa1e7aadf9c54b05cf1100565')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_3819cdbae9ccc18611ec7acf_1', "Mai is making personal pizzas. For 4 pizzas, she uses 10 ounces of cheese. How much cheese does Mai use per pizza?",
    analysis(
        quantities([quantity(4, "pizzas", "4 pizzas"), quantity(10, "ounces", "10 ounces")]),
        ask("How many ounces of cheese does Mai use for each pizza?"),
        steps([step("division", [10, 4], 2.5)]),
        answer(2.5, "ounces"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L12'), grade('6'), record_id('im_defrag_3819cdbae9ccc18611ec7acf_1'), statement_sha('2964352a23c783587f281c7f07347f19b7df2b6a0d5d74ea795059f350d109a5')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_381a7c72f9a476502b702b94_1', "A different group of 4,632 dancers make groups of 8. 1. Write a division expression to represent the situation. 2. How many groups of 8 are there? Explain or show your thinking.",
    analysis(
        quantities([quantity(4632, "dancers", "4,632 dancers"), quantity(8, "dancers per group", "8")]),
        ask("How many groups of 8 dancers can be made from 4,632 dancers?"),
        steps([step("division", [4632, 8], 579)]),
        answer(579, "groups"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U4-L9'), grade('5'), record_id('im_defrag_381a7c72f9a476502b702b94_1'), statement_sha('e176dfc002a176ecf36923a4115c7b67835559c5662600fda43a5517fac2536a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_3830cd4f55eddc668ccc39b0_1', "A rectangular swimming pool has a perimeter of 94 feet. If it is 32 feet on one side, what are the lengths of the other three sides? Explain or show your reasoning.",
    analysis(
        quantities([quantity(94, "feet", "94 feet"), quantity(32, "feet", "32 feet")]),
        ask("What are the lengths of the other three sides of the rectangular swimming pool?"),
        steps([step("multiply", [32, 2], 64), step("subtract", [94, 64], 30), step("divide", [30, 2], 15)]),
        answer(15, "feet"),
        missing_doing("stating the set of side lengths")),
    anchor(lesson('IM-G3-U7-L9'), grade('3'), record_id('im_defrag_3830cd4f55eddc668ccc39b0_1'), statement_sha('ffbfe4056db35c7003334190a4641d7440e7d3b53b11d642d1c27c9af2016aaf')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_1.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_388b0c18c91079300f746b78_1', "2 × 45 = 6 × 15",
    analysis(
        quantities([quantity(2, "number", "2"), quantity(45, "number", "45"), quantity(6, "number", "6"), quantity(15, "number", "15")]),
        ask("Check if 2 multiplied by 45 is equal to 6 multiplied by 15."),
        steps([step("multiplication", [2, 45], 90), step("multiplication", [6, 15], 90), step("compare_equal", [90, 90], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U7-L9'), grade('4'), record_id('im_defrag_388b0c18c91079300f746b78_1'), statement_sha('96d07d9135b509335170afd9068fcb8ffb10bce16d6cc1cba61944a25dcffbe9')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_390600f8f4b7b9b5d5ec75ea_1', "Mai and Andre found some connecting cubes and took turns building towers made of single cubes stacked on top of each other. Mai went first and built a tower 2 cubes tall. Andre went second and built a tower 4 cubes tall. Mai went third and built a tower 8 cubes tall. They each tried to build a tower that was double the height of the previous tower. 1. How many cubes would be needed to build the 7th tower? Explain your reasoning. 2. The number of cubes needed to build the 25th tower is very, very large. Write an expression to represent this number without computing its value. 3. The 28th tower would require even more cubes than the 25th tower. How many times as many cubes are needed to build the 28th tower as are needed for the 25th tower?",
    analysis(
        quantities([quantity(2, "cubes", "2"), quantity(4, "cubes", "4"), quantity(8, "cubes", "8"), quantity(7, "tower number", "7th"), quantity(25, "tower number", "25th"), quantity(28, "tower number", "28th"), quantity(25, "tower number", "25th")]),
        ask("Find the number of cubes for the 7th tower, an expression for the 25th tower, and the ratio of the 28th tower's cubes to the 25th tower's cubes."),
        steps([step("exponentiation", [2, 1], 2), step("exponentiation", [2, 2], 4), step("exponentiation", [2, 3], 8), step("exponentiation", [2, 7], 128), step("subtraction", [28, 25], 3), step("exponentiation", [2, 3], 8)]),
        answer(8, "ratio"),
        missing_doing("The problem asks for multiple distinct answers (a value, an expression, and a ratio); a single numeric answer format is insufficient to capture the full response.")),
    anchor(lesson('IM-G8-U7-L1'), grade('8'), record_id('im_defrag_390600f8f4b7b9b5d5ec75ea_1'), statement_sha('d50393544a5345908ca5fae3d2801327af13db26a6b5447fea589988bbf4e5ef')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_5.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_390dc24835c9254e6fafa1f9_1', "Here are some measurements that were taken when the photo was taken. It was impossible to directly measure the height of the lamppost, so that cell is blank. | | height (inches) | shadow length (inches) | |-------------|-------------------|--------------------------| | younger boy | 43 | 29 | | man | 72 | 48 | | older boy | 51 | 34 | | lamppost | | 114 | 1. What relationships do you notice between an object's height and the length of its shadow? 2. Make a conjecture about the height of the lamppost and explain your thinking.",
    analysis(
        quantities([quantity(43, "inches", "43"), quantity(29, "inches", "29"), quantity(72, "inches", "72"), quantity(48, "inches", "48"), quantity(51, "inches", "51"), quantity(34, "inches", "34"), quantity(114, "inches", "114")]),
        ask("Based on the relationship between the objects' heights and shadow lengths, what is the height of the lamppost?"),
        steps([step("divide", [72, 48], 1.5), step("multiply", [114, 1.5], 171)]),
        answer(171, "inches"),
        missing_doing("identify_proportional_relationship")),
    anchor(lesson('IM-G8-U2-L13'), grade('8'), record_id('im_defrag_390dc24835c9254e6fafa1f9_1'), statement_sha('296912be5527f5f10ba0a95e857704b0038e40938fd94a473bae74229a3a7627')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_392522100fe79d6a90c556c4_1', "If 25% of a show is 11 minutes, how many minutes is the show?",
    analysis(
        quantities([quantity(25, "percent", "25%"), quantity(11, "minutes", "11 minutes")]),
        ask("How many minutes long is the entire show?"),
        steps([step("divide", [11, 0.25], 44)]),
        answer(44, "minutes"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U3-L13'), grade('6'), record_id('im_defrag_392522100fe79d6a90c556c4_1'), statement_sha('5b7654fd363e1ff56242dca4b5d5a094805e0996fc282470cd92e2f686c31220')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_396fc69ee8db8e044088f16b_1', "24 + 30 = 44",
    analysis(
        quantities([quantity(24, "number", "24"), quantity(30, "number", "30"), quantity(44, "number", "44")]),
        ask("Is the equation 24 + 30 = 44 true?"),
        steps([step("addition", [24, 30], 54), step("compare_equal", [54, 44], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U6-L10'), grade('1'), record_id('im_defrag_396fc69ee8db8e044088f16b_1'), statement_sha('9dd4c55bc5b95623156068c7211f64ee99b32c28bbafa3cc24c04355502d04f2')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_398afa04827d88f2508dba08_1', "Use long division to calculate each quotient. a. 1001 ÷ 7",
    analysis(
        quantities([quantity(1001, "number", "1001"), quantity(7, "number", "7")]),
        ask("Calculate the quotient of 1001 divided by 7."),
        steps([step("division", [1001, 7], 143)]),
        answer(143, "quotient"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U5-L11'), grade('6'), record_id('im_defrag_398afa04827d88f2508dba08_1'), statement_sha('498d3af1e9987c7a5e705156f2b9b9c061c65adc9dd62fac6c19f34775981b5f')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_39eacf89472134e650f303ca_1', "Find the value of 6 × 218. Show your thinking using diagrams, symbols, or other representations.",
    analysis(
        quantities([quantity(6, "number", "6"), quantity(218, "number", "218")]),
        ask("Find the value of 6 × 218."),
        steps([step("multiplication", [6, 200], 1200), step("multiplication", [6, 10], 60), step("multiplication", [6, 8], 48), step("addition", [1200, 60, 48], 1308)]),
        answer(1308, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U6-L7'), grade('4'), record_id('im_defrag_39eacf89472134e650f303ca_1'), statement_sha('bf75d590b491a9d4bc926523ef8af6f75a4fb5908e88bc4b2b52de1ade49b00a')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_1.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_3a1c749e04cfebb41e608e8b_1', "Sketch a graph that shows the relationship between grams of honey and grams of salt needed for a bakery recipe. Show on the graph how much honey is needed for 70 grams of salt. | salt (grams) | honey (grams) | |----------------|-----------------| | 10 | 14 | | 25 | 35 |",
    analysis(
        quantities([quantity(10, "grams of salt", "10"), quantity(14, "grams of honey", "14"), quantity(25, "grams of salt", "25"), quantity(35, "grams of honey", "35"), quantity(70, "grams of salt", "70")]),
        ask("Determine how many grams of honey are needed for 70 grams of salt based on the given relationship."),
        steps([step("division", [14, 10], 1.4), step("multiplication", [70, 1.4], 98)]),
        answer(98, "grams of honey"),
        missing_doing("graphing")),
    anchor(lesson('IM-G8-U3-L3'), grade('8'), record_id('im_defrag_3a1c749e04cfebb41e608e8b_1'), statement_sha('fbe4938a605b9a51dd54613858882cc1006343e23bff537fa9ec453172c7d210')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_3a57a42d5f1fde265df48f80_1', "How many dogs are at the kennel? Dogs are 5 parts at 3 animals per part.",
    analysis(
        quantities([quantity(5, "parts", "5 parts"), quantity(3, "animals per part", "3 animals per part")]),
        ask("How many dogs are at the kennel?"),
        steps([step("multiplication", [5, 3], 15)]),
        answer(15, "dogs"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L15'), grade('6'), record_id('im_defrag_3a57a42d5f1fde265df48f80_1'), statement_sha('dffa0d7c4c9d39887039a25eb1ab08bdd1602852a97f4c380e61eea36e63e086')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_3af61f24066c247aa0ba0658_1', "30 + 9",
    analysis(
        quantities([quantity(30, "number", "30"), quantity(9, "number", "9")]),
        ask("What is the sum of 30 and 9?"),
        steps([step("addition", [30, 9], 39)]),
        answer(39, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U4-L10'), grade('1'), record_id('im_defrag_3af61f24066c247aa0ba0658_1'), statement_sha('9367c569052d65952bc119978beef60ea86aaf9e0e0eb880d96c4e7b5bce0727')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_3b82ceedfb7a28535eff28d4_1', "What is the volume of a giant cube that measures 10,000 km on each side? Be prepared to explain your reasoning.",
    analysis(
        quantities([quantity(10000, "km", "10,000 km")]),
        ask("What is the volume of a giant cube that measures 10,000 km on each side?"),
        steps([step("multiplication", [10000, 10000, 10000], 1000000000000)]),
        answer(1000000000000, "km^3"),
        missing_doing(null)),
    anchor(lesson('IM-G8-U7-L3'), grade('8'), record_id('im_defrag_3b82ceedfb7a28535eff28d4_1'), statement_sha('525341a68fffcb0494ccc96d0f908d380ff2370b2ff7599ef8550e7930ed55a3')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_3b8b0b7849290172c5ce7258_1', "Lin has 30 apples to share with her friends. She is putting them in bags, with 6 apples in each bag. How many bags does she need? Explain or show your reasoning.",
    analysis(
        quantities([quantity(30, "apples", "30 apples"), quantity(6, "apples per bag", "6 apples in each bag")]),
        ask("How many bags does Lin need to hold all 30 apples if each bag contains 6 apples?"),
        steps([step("division", [30, 6], 5)]),
        answer(5, "bags"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L1'), grade('3'), record_id('im_defrag_3b8b0b7849290172c5ce7258_1'), statement_sha('b4361c2bb1ec54d81a34036f0edd1e0fcc802706b32a36d934a3178a661fe308')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_3b8ddc76113c8763c32a209c_1', "Solve each equation mentally: a · 50 = 10",
    analysis(
        quantities([quantity(50, "number", "50"), quantity(10, "number", "10")]),
        ask("Find the value of a in the equation a · 50 = 10."),
        steps([step("divide", [10, 50], 0.2)]),
        answer(0.2, "a"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U4-L8'), grade('7'), record_id('im_defrag_3b8ddc76113c8763c32a209c_1'), statement_sha('43c6221e4fe1e88935a020492e41ea778637ce4377d68f17687d4e68e6ffe9ae')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_3bcdf8f77b95b91ad0018e2f_1', "1. The first steps of 2 algorithms are shown. Algorithm A, Step 1 Algorithm B, Step 1 How are the steps different? 2. Use each algorithm to find the value of 824- 541 .",
    analysis(
        quantities([quantity(824, "number", "824"), quantity(541, "number", "541")]),
        ask("What is the value of 824 minus 541 using the provided algorithms?"),
        steps([step("subtraction", [824, 541], 283)]),
        answer(283, "number"),
        missing_doing("interpreting visual algorithm steps")),
    anchor(lesson('IM-G3-U3-L11'), grade('3'), record_id('im_defrag_3bcdf8f77b95b91ad0018e2f_1'), statement_sha('3ea30d7bb79e0a8ef2ceb993ac2cb46d782eb7981fe6a3d214430faa8fbbe4ac')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_3bd515fee2addc5deee1ec41_1', "37 cubes. He adds 39 more to make the train longer. How many cubes does he use?",
    analysis(
        quantities([quantity(37, "cubes", "37 cubes"), quantity(39, "cubes", "39 more")]),
        ask("How many cubes does he use in total?"),
        steps([step("addition", [37, 39], 76)]),
        answer(76, "cubes"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U4-L13'), grade('2'), record_id('im_defrag_3bd515fee2addc5deee1ec41_1'), statement_sha('0395870b60b6c9ee13941e25459faefe8764f1bd870c1ac2f9d76d1fcdb0efd9')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_3c589811b6727bfa16d52e56_1', "6 + 4 = 5 + 3",
    analysis(
        quantities([quantity(6, "number", "6"), quantity(4, "number", "4"), quantity(5, "number", "5"), quantity(3, "number", "3")]),
        ask("Check if 6 + 4 is equal to 5 + 3."),
        steps([step("addition", [6, 4], 10), step("addition", [5, 3], 8), step("compare_equal", [10, 8], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L3'), grade('1'), record_id('im_defrag_3c589811b6727bfa16d52e56_1'), statement_sha('4e7c0a30455f0ecf2fdd001e8570cfef17b5974e6be806f3ea7f11207d83e049')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_4.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_3d8ceb73a89e744f9b5674f2_1', "Find the value of each quotient. Show your reasoning. Use vertical calculations at least once. 3. 432 ÷ 16",
    analysis(
        quantities([quantity(432, "dividend", "432"), quantity(16, "divisor", "16")]),
        ask("What is the value of the quotient 432 divided by 16?"),
        steps([step("division", [432, 16], 27)]),
        answer(27, "quotient"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U5-L10'), grade('6'), record_id('im_defrag_3d8ceb73a89e744f9b5674f2_1'), statement_sha('42f92d9a2f744f5f87589b7e6e28223586db05bcfe551ef5949c42dc0dbbf72d')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_3dfd67f610b58e23c89ecae7_1', "How long is 10% of a 24-hour day? d.",
    analysis(
        quantities([quantity(10, "percent", "10%"), quantity(24, "hours", "24-hour")]),
        ask("How many hours is 10% of a 24-hour day?"),
        steps([step("multiply", [0.1, 24], 2.4)]),
        answer(2.4, "hours"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U3-L13'), grade('6'), record_id('im_defrag_3dfd67f610b58e23c89ecae7_1'), statement_sha('59e54a891d38ab8db4a9b87504d5aac18605c339bc72e4e0e7936d191372b9e6')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_3e253f093911047fbcf87595_1', "2 pattern blocks. Jada adds 5 more. How many pattern blocks?",
    analysis(
        quantities([quantity(2, "pattern blocks", "2 pattern blocks"), quantity(5, "pattern blocks", "5 more")]),
        ask("How many pattern blocks does Jada have in total?"),
        steps([step("addition", [2, 5], 7)]),
        answer(7, "pattern blocks"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U7-L5'), grade('K'), record_id('im_defrag_3e253f093911047fbcf87595_1'), statement_sha('8217ded99092580d6fc4db22c13b0607cbf66db02d2b776d34a6c23b641740f7')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_3f10b0e1a2417fdeec26937a_1', "Complete the table to show the position of each vehicle. (car C: velocity +9 m/s, time +5 s)",
    analysis(
        quantities([quantity(9, "m/s", "9 m/s"), quantity(5, "s", "5 s")]),
        ask("Determine the position of car C given its velocity and time."),
        steps([step("multiplication", [9, 5], 45)]),
        answer(45, "m"),
        missing_doing("interpreting the context of the table and the physics relationship between position, velocity, and time")),
    anchor(lesson('IM-G7-U5-L8'), grade('7'), record_id('im_defrag_3f10b0e1a2417fdeec26937a_1'), statement_sha('610468a3a2121cea29159c50bf3b63fe2fcef7f675e04452bedd0bfb98998fa4')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_3f43ef3f16686e6391282844_1', "Find the value of each expression mentally. 4 ÷ 5",
    analysis(
        quantities([quantity(4, "number", "4"), quantity(5, "number", "5")]),
        ask("What is the value of the expression 4 divided by 5?"),
        steps([step("division", [4, 5], 0.8)]),
        answer(0.8, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U2-L12'), grade('7'), record_id('im_defrag_3f43ef3f16686e6391282844_1'), statement_sha('62de76d028a888491c403cf17308a11171a2f9a173e761821a9c9d076e230b72')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_3f5ffb958ed1c55552d02195_1', "1. Clare draws some birds. She draws 3 birds in a nest and 9 birds flying. How many birds did she draw? Show your thinking using drawings, numbers, or words. 2. Clare draws birds that like warm weather. She draws 6 toucans and 8 parrots. How many birds did she draw? Show your thinking using drawings, numbers, or words. 3. Clare draws birds that like cold weather. She draws 7 penguins and 5 owls. How many birds did she draw? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(3, "birds", "3 birds"), quantity(9, "birds", "9 birds"), quantity(6, "toucans", "6 toucans"), quantity(8, "parrots", "8 parrots"), quantity(7, "penguins", "7 penguins"), quantity(5, "owls", "5 owls")]),
        ask("How many birds did Clare draw in each of the three scenarios?"),
        steps([step("addition", [3, 9], 12), step("addition", [6, 8], 14), step("addition", [7, 5], 12)]),
        answer(12, "birds"),
        missing_doing("multi-part question resolution")),
    anchor(lesson('IM-G1-U3-L17'), grade('1'), record_id('im_defrag_3f5ffb958ed1c55552d02195_1'), statement_sha('e6627568fee2f2a8c9860fe464bc22352e022f7d05c4a429b7b77758b72e437d')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_1.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_3f9b266ccdb1efb6082d4f30_1', "32- 21 = 50",
    analysis(
        quantities([quantity(32, "number", "32"), quantity(21, "number", "21"), quantity(50, "number", "50")]),
        ask("Is the equation 32 - 21 = 50 true?"),
        steps([step("subtraction", [32, 21], 11), step("compare_equal", [11, 50], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U2-L15'), grade('2'), record_id('im_defrag_3f9b266ccdb1efb6082d4f30_1'), statement_sha('863434e8c21a6dc855043312ad58188aa4a3dab6466dcaade4d2597fd36a8c78')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_403806d1b28f4ea82bdeaa92_1', "There are 1,000 meters in 1 kilometer. 1. The shaded section of the track is the length of a 100-meter race. How many 100-meter races does it take to travel 1 kilometer? 2. Your teacher will give you images of something with a length or a height measured in meters. About how many of the items in the handout are needed to make 1 kilometer? Explain or show how you know. 3. Work with your group to write a number in the blank so that each statement is true. Decide if your length is “about” or “exactly” 1 kilometer, and circle the correct word. a. One kilometer is the length of (about, exactly) __________ soccer fields. b. One kilometer is the length of (about, exactly) __________ Statues of Liberty. c. One kilometer is the length of (about, exactly) __________ Olympic-size swimming pools. d. One kilometer is the length of (about, exactly) __________ basketball courts. 4. Estimate where you might end up if you travel 1 kilometer from your school’s front door.",
    analysis(
        quantities([quantity(1000, "meters", "1,000 meters"), quantity(1, "kilometer", "1 kilometer"), quantity(100, "meters", "100-meter")]),
        ask("How many 100-meter races does it take to travel 1 kilometer?"),
        steps([step("divide", [1000, 100], 10)]),
        answer(10, "races"),
        missing_doing("estimation and context-based comparison")),
    anchor(lesson('IM-G4-U5-L8'), grade('4'), record_id('im_defrag_403806d1b28f4ea82bdeaa92_1'), statement_sha('0f86dcb477bfb6f7342c4381b77a48f0fe6746c02ea2eadd35f7dae17207af82')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_40516f315c507185f77159ed_1', "3. Jada reads 47 pages. Noah reads 20 pages. How many fewer pages does Noah read?",
    analysis(
        quantities([quantity(47, "pages", "47 pages"), quantity(20, "pages", "20 pages")]),
        ask("How many fewer pages did Noah read compared to Jada?"),
        steps([step("subtraction", [47, 20], 27)]),
        answer(27, "pages"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U1-L16'), grade('2'), record_id('im_defrag_40516f315c507185f77159ed_1'), statement_sha('e676da299cfcf0b507b1f384b1abade600eecdc7c8f7a9f81cfa9bf413321144')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_405bcea9deb44dd1669b06b7_1', "Kiran has 4 boxes. Each box has 5 pencils in it.",
    analysis(
        quantities([quantity(4, "boxes", "4 boxes"), quantity(5, "pencils", "5 pencils")]),
        ask("How many pencils does Kiran have in total?"),
        steps([step("multiply", [4, 5], 20)]),
        answer(20, "pencils"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U1-L12'), grade('3'), record_id('im_defrag_405bcea9deb44dd1669b06b7_1'), statement_sha('fca041172e1d3c33c599e7336cfb8026a2ce6d019b2801c0d93f2cad560fadd8')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_5.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_409a8024ffc3f2cfe77292e9_1', "Mai plays a game with seeds. She has some seeds in her hands and 29 seeds on the gameboard. She has 53 seeds altogether. How many seeds are in Mai’s hands? 1. Circle the diagram that best matches the story problem. A. B. C. 2. Explain your choice.",
    analysis(
        quantities([quantity(29, "seeds", "29 seeds"), quantity(53, "seeds", "53 seeds")]),
        ask("How many seeds are in Mai's hands?"),
        steps([step("subtraction", [53, 29], 24)]),
        answer(24, "seeds"),
        missing_doing("selecting a diagram and explaining a choice")),
    anchor(lesson('IM-G2-U2-L12'), grade('2'), record_id('im_defrag_409a8024ffc3f2cfe77292e9_1'), statement_sha('02f8c9c2207312724e0fc677827185af27730d923cb00fef2960478df548668a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_40be5daa4827fd8b56af095b_1', "Some students sit on a bus. 34 more students get on the bus. Now there are 55 students. How many students were on the bus at first?",
    analysis(
        quantities([quantity(34, "students", "34 more students"), quantity(55, "students", "55 students")]),
        ask("How many students were on the bus initially?"),
        steps([step("subtraction", [55, 34], 21)]),
        answer(21, "students"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U2-L3'), grade('2'), record_id('im_defrag_40be5daa4827fd8b56af095b_1'), statement_sha('76c4aa70747c437164caaf4d81933e21e0a5df5bb872952aa2f018c1b916642f')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_40f1b0d2565453a33ca87f7f_1', "9 is 50% of what number?",
    analysis(
        quantities([quantity(9, "number", "9"), quantity(50, "percent", "50%")]),
        ask("What number is 9 equal to 50% of?"),
        steps([step("division", [50, 100], 0.5), step("division", [9, 0.5], 18)]),
        answer(18, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U3-L13'), grade('6'), record_id('im_defrag_40f1b0d2565453a33ca87f7f_1'), statement_sha('951f1e7492b672358ac8ac3fba3b9ebb3b7028f0e0a3596b8a9ddb95811f903b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_41382cc2b4c40275f924bbb3_1', "2 pattern blocks. Jada adds 5 more. How many pattern blocks?",
    analysis(
        quantities([quantity(2, "pattern blocks", "2 pattern blocks"), quantity(5, "pattern blocks", "5 more")]),
        ask("How many pattern blocks does Jada have in total?"),
        steps([step("addition", [2, 5], 7)]),
        answer(7, "pattern blocks"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U7-L5'), grade('K'), record_id('im_defrag_41382cc2b4c40275f924bbb3_1'), statement_sha('8217ded99092580d6fc4db22c13b0607cbf66db02d2b776d34a6c23b641740f7')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_42008ae2bf4c91b3d8ae4352_1', "32 apples in boxes. She put 4 apples in each box. How many boxes are there?",
    analysis(
        quantities([quantity(32, "apples", "32 apples"), quantity(4, "apples per box", "4 apples in each box")]),
        ask("How many boxes are there?"),
        steps([step("division", [32, 4], 8)]),
        answer(8, "boxes"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L1'), grade('3'), record_id('im_defrag_42008ae2bf4c91b3d8ae4352_1'), statement_sha('8b8aff39251c8f22e33dccc8efc56aebb3ad40bb3af459aca217fac089d30827')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_4265e379e4c0f71d3621289e_1', "Jada’s class gave away 19 books. That is 5 fewer books than Diego’s class gave away. How many books did Diego’s class give away? Show your thinking using diagrams, symbols, or other representations.",
    analysis(
        quantities([quantity(19, "books", "19 books"), quantity(5, "books", "5 fewer books")]),
        ask("How many books did Diego's class give away?"),
        steps([step("addition", [19, 5], 24)]),
        answer(24, "books"),
        missing_doing("interpreting the comparative relationship 'fewer than' to determine the correct arithmetic operation")),
    anchor(lesson('IM-G2-U9-L9'), grade('2'), record_id('im_defrag_4265e379e4c0f71d3621289e_1'), statement_sha('1451c34ebd29118ce78458da079e161908a4ac749b4e32c5129c0e669e17e722')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_427758c45270a692afdc597f_1', "1. Lin and Han run a 3-mile relay race as a team. They each run the same distance. Draw a diagram to represent the situation. 2. Take turns describing to your partner how your diagrams represent the situation. 3. How far does each person run?",
    analysis(
        quantities([quantity(3, "miles", "3-mile")]),
        ask("How far does each person run?"),
        steps([step("division", [3, 2], 1.5)]),
        answer(1.5, "miles"),
        missing_doing("modeling")),
    anchor(lesson('IM-G5-U2-L6'), grade('5'), record_id('im_defrag_427758c45270a692afdc597f_1'), statement_sha('2f3111b99bf82be06796156c527dd32bd9f00a4905108c9a3dac8e4813bb6067')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_427e66aad4eb2c42b6cfd482_1', "Han has a rectangular piece of paper that is 96 inches by 36 inches. He is using it to create a banner for Awards Day. Last year the banner measured 2,304 square inches. 1. Will the new banner fit in the same area that the old banner was located? Explain or show your reasoning. 2. What is the difference in square inches between the area of last year’s banner and this year’s banner?",
    analysis(
        quantities([quantity(96, "inches", "96 inches"), quantity(36, "inches", "36 inches"), quantity(2304, "square inches", "2,304 square inches")]),
        ask("Will the new banner fit in the same area that the old banner was located, and what is the difference in square inches between the area of last year's banner and this year's banner?"),
        steps([step("multiplication", [96, 36], 3456), step("subtraction", [3456, 2304], 1152)]),
        answer(1152, "square inches"),
        missing_doing("interpreting the comparison between areas to answer the 'Will it fit' question")),
    anchor(lesson('IM-G4-U6-L23'), grade('4'), record_id('im_defrag_427e66aad4eb2c42b6cfd482_1'), statement_sha('200bccd782c14101dc09cd2376fccd09d66f51dbf2f5901a216acfbe108f7e90')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_43214771ada1f10021f2fe71_1', "2. Lin’s tower has 7 cubes. Kiran’s tower has 3 cubes. How many more cubes are in Lin’s tower?",
    analysis(
        quantities([quantity(7, "cubes", "7 cubes"), quantity(3, "cubes", "3 cubes")]),
        ask("How many more cubes are in Lin’s tower than in Kiran’s tower?"),
        steps([step("subtraction", [7, 3], 4)]),
        answer(4, "cubes"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U2-L14'), grade('1'), record_id('im_defrag_43214771ada1f10021f2fe71_1'), statement_sha('2769c18a6c0d1e1a1618bd7ecc6d8a49f584f974c06090956b7e595086bb6983')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_438ee095f77d2013f7e8e0fc_1', "1. Complete each table with the first 10 numbers of these 2 patterns. Jada’s rule: Start with 0 and keep adding 5. 2. Priya’s rule: Start with 0 and keep adding 10. 3. What number will be in Priya’s pattern when Jada’s pattern has 100? 4. What relationship do you notice between corresponding numbers in the two patterns?",
    analysis(
        quantities([quantity(0, "starting number", "0"), quantity(5, "increment", "5"), quantity(0, "starting number", "0"), quantity(10, "increment", "10"), quantity(100, "number in Jada's pattern", "100")]),
        ask("What number will be in Priya's pattern when Jada's pattern has 100, and what is the relationship between the two patterns?"),
        steps([step("divide", [100, 5], 20), step("multiply", [20, 10], 200)]),
        answer(200, "number"),
        missing_doing("pattern recognition and generalization")),
    anchor(lesson('IM-G5-U7-L9'), grade('5'), record_id('im_defrag_438ee095f77d2013f7e8e0fc_1'), statement_sha('d8473021f111db859b4ebbbf7d98f63178e76eacd461b80b9ddc068fb473b4aa')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_43f1bcb0d850db5807b3f068_1', "So far, he has 14 rocks. He gets 3 more. How many rocks does Kiran have now? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(14, "rocks", "14 rocks"), quantity(3, "rocks", "3 more")]),
        ask("How many rocks does Kiran have now?"),
        steps([step("addition", [14, 3], 17)]),
        answer(17, "rocks"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L11'), grade('1'), record_id('im_defrag_43f1bcb0d850db5807b3f068_1'), statement_sha('f43492ef4d3b0a5a06ca09fc08668912f4b505fd8012b9e167dc7832a0299d58')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_44475e6d4cfece0c4988adbc_1', "Find the value of 5 × 1,023. Show your thinking using diagrams, symbols, or other representations.",
    analysis(
        quantities([quantity(5, "multiplier", "5"), quantity(1023, "multiplicand", "1,023")]),
        ask("What is the value of 5 multiplied by 1,023?"),
        steps([step("multiplication", [5, 1000], 5000), step("multiplication", [5, 20], 100), step("multiplication", [5, 3], 15), step("addition", [5000, 100, 15], 5115)]),
        answer(5115, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U6-L9'), grade('4'), record_id('im_defrag_44475e6d4cfece0c4988adbc_1'), statement_sha('57eae81d2cc2ce3cd31973e4cea72a27e6ded768f909d8addb6ed88a9557db8d')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_45646e7aad7d44bd46f81751_1', "If there are 33 students, all wearing sneakers or boots (11 parts total), what is the value of each part?",
    analysis(
        quantities([quantity(33, "students", "33 students"), quantity(11, "parts", "11 parts")]),
        ask("What is the value of each part?"),
        steps([step("division", [33, 11], 3)]),
        answer(3, "value per part"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L15'), grade('6'), record_id('im_defrag_45646e7aad7d44bd46f81751_1'), statement_sha('b619541a2ab865fb54212737c6c671d18aa08db3cd092e75c0d23b77df62300b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_45c3eb8d2996a79610b9867d_1', "1. Decide whether each statement is true or false. For each statement that is false, replace one of the numbers to make it true. A different number should be shown on either side of the equal sign. a. b. c. d. e. f. g. h. 2. Jada says if you locate the numbers 0.05, 0.5, and 0.50 on the number line, you should have only 2 points. Do you agree? Explain your reasoning.",
    analysis(
        quantities([quantity(0.05, "number", "0.05"), quantity(0.5, "number", "0.5"), quantity(0.5, "number", "0.50"), quantity(2, "points", "2 points")]),
        ask("Do you agree with Jada's claim that locating the numbers 0.05, 0.5, and 0.50 on the number line results in only 2 points?"),
        steps([step("compare_equal", [0.5, 0.5], true)]),
        answer(true, "claim_verdict"),
        missing_doing("evaluating qualitative reasoning")),
    anchor(lesson('IM-G4-U4-L2'), grade('4'), record_id('im_defrag_45c3eb8d2996a79610b9867d_1'), statement_sha('20694e7745337cb2cb3e608f0e80cd30326bc4e71c84488298c69af5c795ac5b')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_0.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_45d15e2e0e6042c9568ab1dd_1', "180 = 3 × 60",
    analysis(
        quantities([quantity(180, "number", "180"), quantity(3, "number", "3"), quantity(60, "number", "60")]),
        ask("Check if 180 is equal to 3 times 60."),
        steps([step("multiplication", [3, 60], 180), step("compare_equal", [180, 180], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U7-L2'), grade('3'), record_id('im_defrag_45d15e2e0e6042c9568ab1dd_1'), statement_sha('3ab6e695fc58c71196e614edac00e7810765395f9160b817ee58ca36dc8796ec')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_461bb3bd3bd60fa7d3616a7f_1', "1. Discuss with your partner how the drawing shows each problem. a. Elena has 15 beads in a box. She uses 5 to make a bracelet. How many beads does Elena have left? b. Elena has some beads in a box. She uses 5 to make a bracelet. She has 10 beads left. How many beads were in Elena’s box? c. Elena has 15 beads in a box. She uses some to make a bracelet. She has 10 beads left. How many beads did Elena use to make a bracelet?",
    analysis(
        quantities([quantity(15, "beads", "15 beads"), quantity(5, "beads", "5")]),
        ask("How many beads does Elena have left?"),
        steps([step("subtraction", [15, 5], 10)]),
        answer(10, "beads"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U6-L13'), grade('1'), record_id('im_defrag_461bb3bd3bd60fa7d3616a7f_1'), statement_sha('33f33c06967abb789cfd3281ea8db3afc8e7ee4b4f82b7f6a8ca87547da85f6a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_462d3d8d4cae89ea54efe7dc_1', "60 × 10 = 30 × 20",
    analysis(
        quantities([quantity(60, "number", "60"), quantity(10, "number", "10"), quantity(30, "number", "30"), quantity(20, "number", "20")]),
        ask("Determine if 60 multiplied by 10 is equal to 30 multiplied by 20."),
        steps([step("multiplication", [60, 10], 600), step("multiplication", [30, 20], 600), step("compare_equal", [600, 600], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U5-L18'), grade('5'), record_id('im_defrag_462d3d8d4cae89ea54efe7dc_1'), statement_sha('0dcb65e084bc3dd057dde0a11931a0ef4cdf0d13ef76c13792624d2861bfa13a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_468fe229a27d6e1781f04c5c_1', "Jada ran 15.25 kilometers. Han ran 8,500 meters. Who ran farther? How much farther? Explain or show your reasoning.",
    analysis(
        quantities([quantity(15.25, "kilometers", "15.25 kilometers"), quantity(8500, "meters", "8,500 meters")]),
        ask("Who ran farther and by how much distance?"),
        steps([step("multiply", [8500, 0.001], 8.5), step("subtract", [15.25, 8.5], 6.75)]),
        answer(6.75, "kilometers"),
        missing_doing("unit conversion and comparison")),
    anchor(lesson('IM-G5-U6-L5'), grade('5'), record_id('im_defrag_468fe229a27d6e1781f04c5c_1'), statement_sha('68feaf2b98c1a730562ac18feb76d58f2d5aba56ff3a0804f1dc7cce9f48fac6')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_4698a878771a436f4a2d38dd_1', "Mai put 4 books on the shelf. Then Noah put 3 books on the shelf. How many books are on the shelf now? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(4, "books", "4 books"), quantity(3, "books", "3 books")]),
        ask("How many books are on the shelf in total?"),
        steps([step("addition", [4, 3], 7)]),
        answer(7, "books"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U2-L2'), grade('1'), record_id('im_defrag_4698a878771a436f4a2d38dd_1'), statement_sha('ab65e4d2fe7cfb40d4808b60477d23150a2e2e8a747245de0e0c9df33fd2d107')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_47c4c32a5b329f39816b2d53_1', "Priya read some pages on Monday. Jada read 63 pages, which is 7 times as many pages as Priya read. 1. Write an equation to show the comparison. Use a symbol for the unknown. 2. How many pages did Priya read?",
    analysis(
        quantities([quantity(63, "pages", "63 pages"), quantity(7, "times", "7 times")]),
        ask("How many pages did Priya read?"),
        steps([step("division", [63, 7], 9)]),
        answer(9, "pages"),
        missing_doing("equation modeling")),
    anchor(lesson('IM-G4-U5-L4'), grade('4'), record_id('im_defrag_47c4c32a5b329f39816b2d53_1'), statement_sha('c7254228951d871fb603598b394c2434fe59c83a01d030afc246df520ffc7c14')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_47d34acf11eb3710d0f11621_1', "8 + 5 = 10 + 3",
    analysis(
        quantities([quantity(8, "number", "8"), quantity(5, "number", "5"), quantity(10, "number", "10"), quantity(3, "number", "3")]),
        ask("Check if 8 + 5 is equal to 10 + 3."),
        steps([step("addition", [8, 5], 13), step("addition", [10, 3], 13), step("compare_equal", [13, 13], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U9-L2'), grade('2'), record_id('im_defrag_47d34acf11eb3710d0f11621_1'), statement_sha('0ffc91885f16394452cf29812b080e1e521573e125cf18df698d8466f2a28f6c')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_47ddd6d6f677a44855e393e1_1', "Find the value of 17 + 36. Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(17, "number", "17"), quantity(36, "number", "36")]),
        ask("What is the value of 17 + 36?"),
        steps([step("addition", [17, 36], 53)]),
        answer(53, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U5-L9'), grade('1'), record_id('im_defrag_47ddd6d6f677a44855e393e1_1'), statement_sha('00bc747065efb0140e59c60ca5d6da87c0a1939e9babba26d34cc66af15fe12a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_47e93dcd3f3e2b0faabbe8ee_1', "6 + 2 = 8 + 1",
    analysis(
        quantities([quantity(6, "number", "6"), quantity(2, "number", "2"), quantity(8, "number", "8"), quantity(1, "number", "1")]),
        ask("Is the equation 6 + 2 = 8 + 1 true?"),
        steps([step("addition", [6, 2], 8), step("addition", [8, 1], 9), step("compare_equal", [8, 9], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L3'), grade('1'), record_id('im_defrag_47e93dcd3f3e2b0faabbe8ee_1'), statement_sha('5b2f28eb500bc9bd323a998aa4083d2f86b623e14bb344e8283bc24c80d61252')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_4894d1a3b8cca12d5226e77c_1', "Use long division to find each quotient. Write your answer as a decimal. 2,106 ÷ 25",
    analysis(
        quantities([quantity(2106, "number", "2,106"), quantity(25, "number", "25")]),
        ask("Find the quotient of 2,106 divided by 25 expressed as a decimal."),
        steps([step("division", [2106, 25], 84.24)]),
        answer(84.24, "decimal"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U5-L13'), grade('6'), record_id('im_defrag_4894d1a3b8cca12d5226e77c_1'), statement_sha('6068ddf929fbbb252d84b3b05250518fbebb2c0ceb2bed947368033fed529d21')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_48a6b8c3be01798937fd0364_1', "24 + 40 = 64",
    analysis(
        quantities([quantity(24, "number", "24"), quantity(40, "number", "40"), quantity(64, "number", "64")]),
        ask("Check if 24 + 40 equals 64."),
        steps([step("addition", [24, 40], 64), step("compare_equal", [64, 64], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U6-L10'), grade('1'), record_id('im_defrag_48a6b8c3be01798937fd0364_1'), statement_sha('7fc37176cec9cda77aae04db6684917880de40490afbc1e0ba54bd2a9b45687d')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_498b58ba6f28e2cde13358ba_1', "17 + 76 = 59",
    analysis(
        quantities([quantity(17, "number", "17"), quantity(76, "number", "76"), quantity(59, "number", "59")]),
        ask("Is the equation 17 + 76 = 59 true?"),
        steps([step("addition", [17, 76], 93), step("compare_equal", [93, 59], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U8-L5'), grade('1'), record_id('im_defrag_498b58ba6f28e2cde13358ba_1'), statement_sha('feaaeb9163bdbebe47738d5746927b05649a5d90218cfee82828449dd823a22f')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_49d945d895886bbf1e9401c7_1', "Mai and her classmates volunteer to clean up the local park. They pick up 37 plastic bottles and 25 paper wrappers. How many pieces of litter did they pick up all together? Jada, Kiran, and Tyler find the value of . Jada’s way: Kiran’s way: Tyler’s way:",
    analysis(
        quantities([quantity(37, "plastic bottles", "37 plastic bottles"), quantity(25, "paper wrappers", "25 paper wrappers")]),
        ask("How many pieces of litter did Mai and her classmates pick up all together?"),
        steps([step("addition", [37, 25], 62)]),
        answer(62, "pieces of litter"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U5-L11'), grade('1'), record_id('im_defrag_49d945d895886bbf1e9401c7_1'), statement_sha('a913c296ce38555262529dc5486dd19d0b46545132dd0a84325088496328b725')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_49dc1788782db6ed4a2b47be_1', "Lin has 30 apples to share with her friends. She is putting them in bags, with 6 apples in each bag.",
    analysis(
        quantities([quantity(30, "apples", "30 apples"), quantity(6, "apples per bag", "6 apples")]),
        ask("How many bags of apples will Lin have?"),
        steps([step("division", [30, 6], 5)]),
        answer(5, "bags"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L1'), grade('3'), record_id('im_defrag_49dc1788782db6ed4a2b47be_1'), statement_sha('115b9709f96e4974527173c91abe9c732cc556d18b7d17cce7fdfebe00fd1f5f')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_4b08a86938ffc3430b0fb3ed_1', "Find each difference. ... a. 9 - 4",
    analysis(
        quantities([quantity(9, "number", "9"), quantity(4, "number", "4")]),
        ask("Find the difference of 9 minus 4."),
        steps([step("subtraction", [9, 4], 5)]),
        answer(5, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U5-L5'), grade('7'), record_id('im_defrag_4b08a86938ffc3430b0fb3ed_1'), statement_sha('c6ce313fbf359b6b6dcbd882caa77d9047ebfd910d3bf0b16d883eb878198fd2')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_4b692c044be5fd14335ce0ad_1', "Clare played a round of Shake and Spill—Cover using 9 counters. Her counters look like this. How many counters are under the cup? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(9, "counters", "9 counters")]),
        ask("How many counters are under the cup?"),
        steps([step("subtract", [9, 0], 9)]),
        answer(9, ""),
        missing_doing("interpreting the visual information of the counters' appearance")),
    anchor(lesson('IM-G1-U2-L8'), grade('1'), record_id('im_defrag_4b692c044be5fd14335ce0ad_1'), statement_sha('c4f57eb35039ab771faea255c918f2f204b3c071066ab8e0c9eb4c746fb18598')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_2.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_4bc8a2c80339a512863f6507_1', "10 kids on the bus. 1 kid gets off the bus. How many kids are on the bus?",
    analysis(
        quantities([quantity(10, "kids", "10 kids"), quantity(1, "kid", "1 kid")]),
        ask("How many kids are left on the bus?"),
        steps([step("subtraction", [10, 1], 9)]),
        answer(9, "kids"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U8-L3'), grade('K'), record_id('im_defrag_4bc8a2c80339a512863f6507_1'), statement_sha('7923b6ae45942cd284462bd6b77ac34876c3f767c4f9aa0ba82da0c239dbb52e')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_4bcafdf450a9f974193b1dc8_1', "1. There are students standing in the classroom. Some of the students sit down on the rug. There are still some students standing. 2. There are 15 students standing in the classroom. Some of the students sit down on the rug. There are still 5 students standing. How many students sat down on the rug? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(15, "students", "15 students"), quantity(5, "students", "5 students")]),
        ask("How many students sat down on the rug?"),
        steps([step("subtraction", [15, 5], 10)]),
        answer(10, "students"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L13'), grade('1'), record_id('im_defrag_4bcafdf450a9f974193b1dc8_1'), statement_sha('4dfaf208cd466fb709ab70063278f9b0963a79764828a533512a45d9ed46244a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_4cbc5e18a53ff574748eb0c2_1', "2. Kiran has 4 counters in a cup. He puts more counters in. Now he has 7 counters in his cup. How many more counters did Kiran put in his cup?",
    analysis(
        quantities([quantity(4, "counters", "4 counters"), quantity(7, "counters", "7 counters")]),
        ask("How many more counters did Kiran put in his cup?"),
        steps([step("subtraction", [7, 4], 3)]),
        answer(3, "counters"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L6'), grade('1'), record_id('im_defrag_4cbc5e18a53ff574748eb0c2_1'), statement_sha('d5dc0d57daa9ca3e5bddec961b17a9f5bc8e1fb2841e6eb66928c0426c490e3a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_4cbcbd4b9cd90d7fa7df27ca_1', "Solve each problem. Explain or show your reasoning. 1. Iguazu Falls (ee-gwah-SOO fawlz) in South America marks the border between Brazil and Argentina. It is the largest waterfall system in the world. The system has more than one drop. Suppose the water falls 115 feet down the first drop and 131 feet down the next drop. How far would the water fall altogether? 2. In Washington, D.C., there are many monuments that honor important people in American history. The Lincoln Memorial is 99 feet tall. The Washington Monument is 555 feet tall. How much taller is the Washington Monument than the Lincoln Memorial? 3. The Eiffel Tower (AYE-fuhl TAOW-ur) in Paris, France, has 674 steps that go from the ground to the second floor. There are 327 steps from the ground to the first floor. How many steps are there from the first floor to the second floor?",
    analysis(
        quantities([quantity(674, "steps", "674 steps"), quantity(327, "steps", "327 steps")]),
        ask("How many steps are there from the first floor to the second floor?"),
        steps([step("subtraction", [674, 327], 347)]),
        answer(347, "steps"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U3-L2'), grade('3'), record_id('im_defrag_4cbcbd4b9cd90d7fa7df27ca_1'), statement_sha('89a206fa7c8a30cfba9ec4c0903c34d5a81f88d1869169d91ef3279ff495bb94')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_4d69d7b83ef3db5fd81deeb6_1', "How many liters of olive oil can this orchard produce in a year? [100 lb row: oil = 3*5 = 15 L]",
    analysis(
        quantities([quantity(100, "lb row", "100 lb row"), quantity(3, "multiplier", "3"), quantity(5, "liters per unit", "5")]),
        ask("How many liters of olive oil can this orchard produce in a year?"),
        steps([step("multiply", [3, 5], 15)]),
        answer(15, "liters"),
        missing_doing("interpreting the bracketed shorthand notation")),
    anchor(lesson('IM-G6-U2-L11'), grade('6'), record_id('im_defrag_4d69d7b83ef3db5fd81deeb6_1'), statement_sha('963e0818b4b9c5b8cc45a3b057dec9c4ca0732aee71f7189252b1e8d8ea871e2')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_4db2d925511bc11c82086de7_1', "3 apple slices at the picnic. Tyler brought 5 more. How many now?",
    analysis(
        quantities([quantity(3, "apple slices", "3 apple slices"), quantity(5, "apple slices", "5 more")]),
        ask("How many apple slices are there in total now?"),
        steps([step("addition", [3, 5], 8)]),
        answer(8, "apple slices"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U4-L10'), grade('K'), record_id('im_defrag_4db2d925511bc11c82086de7_1'), statement_sha('85932667d16ad2f5c75029fc58fdbe141aa8d14cb457e08846f5e422f776a9cf')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_4e6e15d46116b59a407e5025_1', "Andre’s rule for a pattern is “start with 9, keep adding 9.” Use what you’ve noticed about Andre’s pattern to make some predictions. 1. Complete the table with the first 10 numbers in keep adding Andre’s pattern. 9 What do you notice about the numbers in Andre’s pattern? Make at least 2 observations to share with your partner. 2. Choose one observation you or your partner made. Explain or show why you think it happens. a. What is the 12th number in Andre’s pattern? b. What is the 15th number? c. What is the 25th number?",
    analysis(
        quantities([quantity(9, "starting number", "9"), quantity(9, "increment", "adding 9"), quantity(12, "position", "12th")]),
        ask("What is the 12th number in Andre's pattern?"),
        steps([step("multiply", [9, 12], 108)]),
        answer(108, "number"),
        missing_doing("The problem contains multiple parts (a, b, and c), making it impossible to provide a single numeric answer for the entire text.")),
    anchor(lesson('IM-G4-U6-L3'), grade('4'), record_id('im_defrag_4e6e15d46116b59a407e5025_1'), statement_sha('d2fa34b841d73e545c7378b05ebf29ee90be320eb3894e398b96868fb7d7491b')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_4.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_4f36cb6d21b3d0a9d85c4672_1', "Han’s bracelet is 4 cubes longer than Priya’s bracelet. Priya’s bracelet is 10 cubes long. How long is Han’s bracelet? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(4, "cubes", "4 cubes"), quantity(10, "cubes", "10 cubes")]),
        ask("How long is Han's bracelet?"),
        steps([step("addition", [10, 4], 14)]),
        answer(14, "cubes"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U6-L12'), grade('1'), record_id('im_defrag_4f36cb6d21b3d0a9d85c4672_1'), statement_sha('573d869ef2cb1fd2ee3146bc2b52effd0f2c198c767b0990ca4e6766a41e71a9')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_504a934c07a1758fa1570ac6_1', "1. Andre has 3 hundreds. Tyler has 5 tens. Mai has 7 ones. They want to represent the amount with an expression. Write an expression to represent the sum of their values. __________ + __________ + __________ Write the total value as a 3-digit number. _______________ Write each number as the sum of hundreds, tens, and ones. This is called expanded form. Then write the 3-digit number. 2. Expanded form: _________________________ 3-digit number: _________________________ 3. Expanded form: _________________________ 3-digit number: _________________________ 4. Expanded form: _________________________ 3-digit number: _________________________ 5. Expanded form: _________________________ 3-digit number: _________________________",
    analysis(
        quantities([quantity(3, "hundreds", "3 hundreds"), quantity(5, "tens", "5 tens"), quantity(7, "ones", "7 ones")]),
        ask("Write an expression for the sum of their values, find the total value as a 3-digit number, and provide the expanded form."),
        steps([step("multiply", [3, 100], 300), step("multiply", [5, 10], 50), step("multiply", [7, 1], 7), step("add", [300, 50], 350), step("add", [350, 7], 357)]),
        answer(357, "3-digit number"),
        missing_doing("formatting output according to multiple template prompts")),
    anchor(lesson('IM-G2-U5-L5'), grade('2'), record_id('im_defrag_504a934c07a1758fa1570ac6_1'), statement_sha('d69c14072d17293d1d1afc8df1828906bfcceb75339167c84959a4645da3a107')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_504baefbb62324d61165bbea_1', "At noon, the temperature was 5 degrees Celsius. By late afternoon, it had risen 6 degrees Celsius. What was the temperature late in the afternoon? b.",
    analysis(
        quantities([quantity(5, "degrees Celsius", "5 degrees Celsius"), quantity(6, "degrees Celsius", "6 degrees Celsius")]),
        ask("What was the temperature late in the afternoon?"),
        steps([step("addition", [5, 6], 11)]),
        answer(11, "degrees Celsius"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U7-L1'), grade('6'), record_id('im_defrag_504baefbb62324d61165bbea_1'), statement_sha('628d3f5ddd5421196707703a57ee4145c8bebbac3edec74e85cd3d87b9146cce')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_504fd2e7e09db2bcb1a1e902_1', "32 + 45 = 76",
    analysis(
        quantities([quantity(32, "number", "32"), quantity(45, "number", "45"), quantity(76, "number", "76")]),
        ask("Check if 32 plus 45 equals 76."),
        steps([step("addition", [32, 45], 77), step("compare_equal", [77, 76], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U6-L10'), grade('1'), record_id('im_defrag_504fd2e7e09db2bcb1a1e902_1'), statement_sha('c7c94304e1fdbac82d86f719ca6dea4e17a64cd7c4871244bba571d1067f881a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_51a6271376ef3ab87ab02a7e_1', "A rectangular playground is 6 yards by 14 yards. a. How much fencing is needed to fence in the playground? b.",
    analysis(
        quantities([quantity(6, "yards", "6 yards"), quantity(14, "yards", "14 yards")]),
        ask("How much fencing is needed to enclose a rectangular playground that is 6 yards by 14 yards?"),
        steps([step("addition", [6, 14], 20), step("multiplication", [2, 20], 40)]),
        answer(40, "yards"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U7-L13'), grade('3'), record_id('im_defrag_51a6271376ef3ab87ab02a7e_1'), statement_sha('f5f223fa002901ab2b900bdd3860e5efeb2630d3843aa87ed8616343f95cd267')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_51a66d69b68451b272afe0ec_1', "There are 6 gallons of water in a 20-gallon fish tank. What fraction of the tank is filled?",
    analysis(
        quantities([quantity(6, "gallons", "6 gallons"), quantity(20, "gallons", "20-gallon")]),
        ask("What fraction of the tank is filled with water?"),
        steps([step("divide", [6, 20], 0.3)]),
        answer(0.3, "fraction"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U4-L7'), grade('6'), record_id('im_defrag_51a66d69b68451b272afe0ec_1'), statement_sha('20e3a7122c8838cbabfafb112496a2e9d0868739fb281276c02df6b16247c619')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_51bc02258dff71778f481722_1', "At the football game, 9 fans cheer for the visiting team. There were 45 fans who cheer for the home team. How many fans are at the game all together? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(9, "fans", "9 fans"), quantity(45, "fans", "45 fans")]),
        ask("How many fans are at the game in total?"),
        steps([step("addition", [9, 45], 54)]),
        answer(54, "fans"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U5-L8'), grade('1'), record_id('im_defrag_51bc02258dff71778f481722_1'), statement_sha('90c8d50e79978f163d8a612b2a33cbce9676df1d910ec56909e7ddf21058b540')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_525aa387f45e3d21b03dd9a7_1', "702- 244",
    analysis(
        quantities([quantity(702, "number", "702"), quantity(244, "number", "244")]),
        ask("What is the result of subtracting 244 from 702?"),
        steps([step("subtraction", [702, 244], 458)]),
        answer(458, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U7-L17'), grade('2'), record_id('im_defrag_525aa387f45e3d21b03dd9a7_1'), statement_sha('610d10343f0ab24c51573ed6bac5bc4ccf1791fcbe2caa8bc232a69a58abfa2e')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_52adf2f41cb08f82e1b333a7_1', "Elena has 10 fewer paper stars than Priya. Priya has 20 paper stars. How many paper stars does Elena have? Write an equation that represents the problem. Put a box around the answer to the problem.",
    analysis(
        quantities([quantity(10, "paper stars", "10"), quantity(20, "paper stars", "20")]),
        ask("How many paper stars does Elena have?"),
        steps([step("subtraction", [20, 10], 10)]),
        answer(10, "paper stars"),
        missing_doing("formulating an equation and formatting the output")),
    anchor(lesson('IM-G1-U6-L15'), grade('1'), record_id('im_defrag_52adf2f41cb08f82e1b333a7_1'), statement_sha('5fc8ede6d8fe40c2ec41335e73f791e1eafb204de501dd6c32e06afc0c28e67c')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_53160bdf7865e67f4be83292_1', "Priya and Han make friendship bracelets. Han’s bracelet is 14 cubes long. Priya’s bracelet is 4 cubes shorter than Han’s bracelet. How long is Priya’s bracelet? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(14, "cubes", "14 cubes"), quantity(4, "cubes", "4 cubes shorter")]),
        ask("How long is Priya's bracelet in cubes?"),
        steps([step("subtraction", [14, 4], 10)]),
        answer(10, "cubes"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U6-L12'), grade('1'), record_id('im_defrag_53160bdf7865e67f4be83292_1'), statement_sha('7f70f3d262d0a5f9820cd460c880cef631540b75d65cdc6de2255f6f122b4a10')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_5352ddc2293355e028f7316f_1', "2 × 40 = 8 × 10",
    analysis(
        quantities([quantity(2, "number", "2"), quantity(40, "number", "40"), quantity(8, "number", "8"), quantity(10, "number", "10")]),
        ask("Determine if 2 times 40 is equal to 8 times 10."),
        steps([step("multiplication", [2, 40], 80), step("multiplication", [8, 10], 80), step("compare_equal", [80, 80], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L17'), grade('3'), record_id('im_defrag_5352ddc2293355e028f7316f_1'), statement_sha('3580b8ed1f36bb83d6a9987f3972a1562c2454ec76c95c4f545baabdf0deae86')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_2.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_53b298e136d647c7878b166e_1', "What do you notice? What do you wonder? 4 + 5 = 9",
    analysis(
        quantities([quantity(4, "number", "4"), quantity(5, "number", "5"), quantity(9, "number", "9")]),
        ask("What do you notice and what do you wonder about 4 + 5 = 9?"),
        steps([step("addition", [4, 5], 9), step("compare_equal", [9, 9], true)]),
        answer(true, "claim_verdict"),
        missing_doing("mathematical reflection")),
    anchor(lesson('IM-G1-U2-L23'), grade('1'), record_id('im_defrag_53b298e136d647c7878b166e_1'), statement_sha('5536ea0cc6eece93923d3b9e568f5e053120f6f1c6ee6dfdc2558a568a78d0c0')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_5.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_53c4931ce112250a03131cfe_1', "Elena and her mother plant a community garden. They plant 18 strawberry plants. They plant 24 cucumber plants. How many plants did they plant all together? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(18, "strawberry plants", "18 strawberry plants"), quantity(24, "cucumber plants", "24 cucumber plants")]),
        ask("How many plants did Elena and her mother plant in total?"),
        steps([step("addition", [18, 24], 42)]),
        answer(42, "plants"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U5-L12'), grade('1'), record_id('im_defrag_53c4931ce112250a03131cfe_1'), statement_sha('2da4a2d9be2ebaef5101d3f635fab16433c81575d503996c21cd048677182871')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_53f8f9373add60adcd3f12c6_1', "They count all the counters and • Monitor for students who represent 5 and 2: write 7 as the total.",
    analysis(
        quantities([quantity(5, "counters", "5"), quantity(2, "counters", "2"), quantity(7, "total", "7")]),
        ask("write 7 as the total for students who represent 5 and 2"),
        steps([step("addition", [5, 2], 7)]),
        answer(7, "total"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U2-L1'), grade('1'), record_id('im_defrag_53f8f9373add60adcd3f12c6_1'), statement_sha('93511b16e899b0a282652740aeedf56a71defeb9a7bbef1ff4b75ec4db715dd5')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_0.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_547d170fb581a8209f6c76a4_1', "Noah covers 4 pictures on his board. His brother covers 10 pictures. How many fewer pictures does Noah have covered than his brother? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(4, "pictures", "4 pictures"), quantity(10, "pictures", "10 pictures")]),
        ask("How many fewer pictures does Noah have covered than his brother?"),
        steps([step("subtraction", [10, 4], 6)]),
        answer(6, "pictures"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U2-L20'), grade('1'), record_id('im_defrag_547d170fb581a8209f6c76a4_1'), statement_sha('583a823835a2416b96a189e8abc90a4b9a83c6c8150126997598a6de4a931705')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_55829a9a4d2a9cd6429d40fb_1', "Andre and Elena divide 2,315 by 5. Before they begin, Andre says, “I can already tell that the quotient is going to be less than 500.” 1. Decide if you agree with Andre without doing any calculations. Explain your reasoning. 2. Here is Andre and Elena’s work. Each student made one or more errors. Identify the errors each student made. Then show a correct computation. Andre’s Elena’s Work Work",
    analysis(
        quantities([quantity(2315, "number", "2,315"), quantity(5, "number", "5"), quantity(500, "number", "500")]),
        ask("Decide if Andre's claim that the quotient of 2,315 divided by 5 is less than 500 is correct, identify errors in provided work (not visible in text), and show the correct computation."),
        steps([step("divide", [2315, 5], 463)]),
        answer(463, "quotient"),
        missing_doing("error identification and reasoning")),
    anchor(lesson('IM-G4-U6-L18'), grade('4'), record_id('im_defrag_55829a9a4d2a9cd6429d40fb_1'), statement_sha('73eb1192d7e9ad14bc5b03ef8fc93edd8019632d2ea14ce04ca3ae2ab66d1f47')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_2.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_55b73ca03bbfc22ea4eef962_1', "Andre poured 27 ounces of rice into 6 bags. If all bags have the same amount of rice, how many ounces are in each bag?",
    analysis(
        quantities([quantity(27, "ounces", "27 ounces"), quantity(6, "bags", "6 bags")]),
        ask("How many ounces of rice are in each bag?"),
        steps([step("division", [27, 6], 4.5)]),
        answer(4.5, "ounces"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U4-L3'), grade('6'), record_id('im_defrag_55b73ca03bbfc22ea4eef962_1'), statement_sha('eda1c602e06589666b871ec1544d75bc30f1b006cb16bc8233951056b2bde623')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_55bb221c2eb933e519c7c54d_1', "The storage container is 4 feet wide, 9 feet long, and 5 feet high. What is the volume of her container?",
    analysis(
        quantities([quantity(4, "feet", "4 feet"), quantity(9, "feet", "9 feet"), quantity(5, "feet", "5 feet")]),
        ask("What is the volume of the storage container?"),
        steps([step("multiplication", [4, 9], 36), step("multiplication", [36, 5], 180)]),
        answer(180, "cubic feet"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U1-L11'), grade('5'), record_id('im_defrag_55bb221c2eb933e519c7c54d_1'), statement_sha('3895c842ee68c73e8462e42cdf8b63b4a3464c29fb7212056732adc3ecb4ea59')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_55c615a47f04586517e41ad8_1', "1. Select all the expressions that are equivalent to 15 × 0.19. A. 15 × 19 × 0.01 B. (15 × 0.1) + (15 × 0.09) C. 15 × 19 × 0.1 D. (15 × 0.2)- (15 × 0.01) 2. Choose one expression to find the value of 15 × 0.19.",
    analysis(
        quantities([quantity(15, "number", "15"), quantity(0.19, "number", "0.19")]),
        ask("Select all expressions equivalent to 15 × 0.19 and choose one expression to find its value."),
        steps([step("multiply", [15, 0.19], 2.85), step("multiply", [15, 19, 0.01], 2.85), step("add", [1.5, 1.35], 2.85), step("multiply", [15, 19, 0.1], 28.5), step("subtract", [3.0, 0.15], 2.85)]),
        answer(2.85, "number"),
        missing_doing("multiple choice selection")),
    anchor(lesson('IM-G5-U5-L19'), grade('5'), record_id('im_defrag_55c615a47f04586517e41ad8_1'), statement_sha('c08754864a0cf9e1534620ae0aecc24b3a6738d49ae126e89bdf615e2d98c2db')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_3.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_55d03cf37fdd86842b4a034a_1', "1. Which estimate for the product 18 × 149 is most reasonable? Explain or show your reasoning. A. 2,000 B. 4,000 C. 3,000 D. 1,500 2. Are any of the estimates unreasonable? Explain or show your reasoning. 3. Do you think the actual product is greater than or less than your estimate? Explain or show your reasoning.",
    analysis(
        quantities([quantity(18, "number", "18"), quantity(149, "number", "149")]),
        ask("Which estimate for the product 18 × 149 is most reasonable, are any estimates unreasonable, and is the actual product greater than or less than the chosen estimate?"),
        steps([step("multiply", [20, 150], 3000), step("multiply", [18, 149], 2682)]),
        answer(3000, "estimate"),
        missing_doing("evaluating qualitative reasoning and multiple-choice options")),
    anchor(lesson('IM-G5-U4-L1'), grade('5'), record_id('im_defrag_55d03cf37fdd86842b4a034a_1'), statement_sha('bb4f8dd2cb8721641bb26261a86a33ce38f9663170566960ec76d3bb9cc04346')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_5.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_56ecb19905546125f7e674b2_1', "How many are wearing sneakers? Sneakers are 5 parts at 3 students per part.",
    analysis(
        quantities([quantity(5, "parts", "5 parts"), quantity(3, "students per part", "3 students per part")]),
        ask("How many students are wearing sneakers?"),
        steps([step("multiplication", [5, 3], 15)]),
        answer(15, "students"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L15'), grade('6'), record_id('im_defrag_56ecb19905546125f7e674b2_1'), statement_sha('5e05f617f99ab604af652440f99cbac0bcf4b78be42c624c8bab16efd7c08595')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_57a6e839586a765510efb86e_1', "2. The cotton candy booth sells 17 bags of blue cotton candy. They sell 7 bags of pink cotton candy. How many more bags of blue candy do they sell than pink candy?",
    analysis(
        quantities([quantity(17, "bags", "17 bags"), quantity(7, "bags", "7 bags")]),
        ask("How many more bags of blue cotton candy were sold than pink cotton candy?"),
        steps([step("subtraction", [17, 7], 10)]),
        answer(10, "bags"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U8-L6'), grade('1'), record_id('im_defrag_57a6e839586a765510efb86e_1'), statement_sha('e3cac0bc4035cfc3118e537d5638ee8cd3aeb33646841d1b170304a362a118c4')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_57bb5e015a3cf0c7cc8cf2a2_1', "Cups are delivered 2,000 at a time. On Thursday the change is +1,719. How many cups do you think were used on Thursday?",
    analysis(
        quantities([quantity(2000, "cups", "2,000"), quantity(1719, "cups", "1,719")]),
        ask("How many cups were used on Thursday?"),
        steps([step("subtraction", [2000, 1719], 281)]),
        answer(281, "cups"),
        missing_doing("interpreting the meaning of 'change' in the context of inventory")),
    anchor(lesson('IM-G7-U5-L7'), grade('7'), record_id('im_defrag_57bb5e015a3cf0c7cc8cf2a2_1'), statement_sha('d1ae5dc2abad3c49de50d29560385c118f99742d97769297d53e9ced642f79f7')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_580a23d990366fcb34dd4a20_1', "She draws 6 toucans and 8 parrots. How many birds did she draw?",
    analysis(
        quantities([quantity(6, "toucans", "6 toucans"), quantity(8, "parrots", "8 parrots")]),
        ask("How many birds did she draw in total?"),
        steps([step("addition", [6, 8], 14)]),
        answer(14, "birds"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L17'), grade('1'), record_id('im_defrag_580a23d990366fcb34dd4a20_1'), statement_sha('70dec0fefffaad87deac9d4110bae414e6f7ac6ea0f9f874b896c9b8bd15afcd')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_589165105b60e93da0e57811_1', "Which 3 go together? A B C D 4 tens + 2 ones + 3 tens + 7 ones",
    analysis(
        quantities([quantity(4, "tens", "4 tens"), quantity(2, "ones", "2 ones"), quantity(3, "tens", "3 tens"), quantity(7, "ones", "7 ones")]),
        ask("Which three of the options A, B, C, or D are equal to the sum of 4 tens, 2 ones, 3 tens, and 7 ones?"),
        steps([step("multiply", [4, 10], 40), step("multiply", [2, 1], 2), step("multiply", [3, 10], 30), step("multiply", [7, 1], 7), step("add", [40, 2], 42), step("add", [42, 30], 72), step("add", [72, 7], 79)]),
        answer(79, "number"),
        missing_doing("matching the calculated sum to the provided multiple-choice options A, B, C, and D which are not listed in the text")),
    anchor(lesson('IM-G2-U9-L7'), grade('2'), record_id('im_defrag_589165105b60e93da0e57811_1'), statement_sha('e8fd3bf7b1437c510e6480dccc64b59b917187a6be6b438c7d6b1030df722a59')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_3.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_58e8e16fea26ec7f596458c0_1', "A different shipping container is 40 feet long, 9 feet wide, and 8 feet tall. 1. What is the volume of this container? Explain or show your thinking. 2. A school makes 24 cubic feet of recyclable plastic each day. How many days does it take the school to fill this container? Explain or show your thinking.",
    analysis(
        quantities([quantity(40, "feet", "40 feet"), quantity(9, "feet", "9 feet"), quantity(8, "feet", "8 feet"), quantity(24, "cubic feet", "24 cubic feet")]),
        ask("What is the volume of the container and how many days does it take the school to fill it?"),
        steps([step("multiplication", [40, 9], 360), step("multiplication", [360, 8], 2880), step("division", [2880, 24], 120)]),
        answer(120, "days"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U4-L19'), grade('5'), record_id('im_defrag_58e8e16fea26ec7f596458c0_1'), statement_sha('2683d8a8dd5a65eabde82ab7fac9ba41e7777a7de96a8c4c8b199c5132b25e44')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_4.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_58ee77ef3d01e827bd08ba6a_1', "Priya’s mom makes 85 gulab jamuns for the class to share. Priya gives 5 gulab jamuns to each student in the class. How many students are in Priya’s class? Explain or show your reasoning.",
    analysis(
        quantities([quantity(85, "gulab jamuns", "85 gulab jamuns"), quantity(5, "gulab jamuns per student", "5 gulab jamuns")]),
        ask("How many students are in Priya's class?"),
        steps([step("division", [85, 5], 17)]),
        answer(17, "students"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U6-L13'), grade('4'), record_id('im_defrag_58ee77ef3d01e827bd08ba6a_1'), statement_sha('56f5ae57b381c51b52e1121da4009ea1a62042ea0f893fdc6141e12958776446')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_591a58169a39d17df0fe974e_1', "Write the letter next to the story problem it represents. A B C D 1. A basketball costs $39 less than a soccer ball and a football together. The soccer ball costs $29. The football costs $68. How many dollars does the basketball cost? _____ 2. Jada is saving to buy a giant set of building bricks. The set costs $68. Jada has $39. How much more does she need? _____ 3. A pair of pants costs $39. A shirt costs $29. A pair of shoes costs $68. How many more dollars do the shirt and the shoes cost than the pants? _____ 4. Diego has $39. He gets some money for his birthday. Now he has $68. How much money does Diego get for his birthday? _____",
    analysis(
        quantities([quantity(39, "dollars", "$39"), quantity(29, "dollars", "$29"), quantity(68, "dollars", "$68")]),
        ask("How many dollars does the basketball cost?"),
        steps([step("addition", [29, 68], 97), step("subtraction", [97, 39], 58)]),
        answer(58, "dollars"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U6-L19'), grade('2'), record_id('im_defrag_591a58169a39d17df0fe974e_1'), statement_sha('2d7f747b7f8449dfcb318b38f4c6e0ee7bc0189a9d3a00429fbae9dbcc8f550c')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_59a934dfb5bf640aa6a67cac_1', "3 × 50 = 15 × 10",
    analysis(
        quantities([quantity(3, "number", "3"), quantity(50, "number", "50"), quantity(15, "number", "15"), quantity(10, "number", "10")]),
        ask("Is 3 times 50 equal to 15 times 10?"),
        steps([step("multiplication", [3, 50], 150), step("multiplication", [15, 10], 150), step("compare_equal", [150, 150], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L17'), grade('3'), record_id('im_defrag_59a934dfb5bf640aa6a67cac_1'), statement_sha('20e36bfe08c90347d758266489959b8c3aa13e107a680c36b69c58ada0e5958d')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_3.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_59f0c01b83b788e27b2b3c80_1', "The school has 6 bags. Each bag has 10 basketballs in it.",
    analysis(
        quantities([quantity(6, "bags", "6 bags"), quantity(10, "basketballs", "10 basketballs")]),
        ask("How many basketballs are there in total in the 6 bags?"),
        steps([step("multiply", [6, 10], 60)]),
        answer(60, "basketballs"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U1-L14'), grade('3'), record_id('im_defrag_59f0c01b83b788e27b2b3c80_1'), statement_sha('aad43d1d1db69ed8ce6d027a78bbdb5890ed33a9e85918705163ca4babd58b15')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_0.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_59fc416175f75e7c1886ab5b_1', "How many liters of olive oil can this orchard produce in a year? [3000 lb row: oil = 15*30 = 450 L]",
    analysis(
        quantities([quantity(3000, "lb", "3000"), quantity(15, "ratio", "15"), quantity(30, "ratio", "30")]),
        ask("How many liters of olive oil can this orchard produce in a year?"),
        steps([step("multiply", [15, 30], 450)]),
        answer(450, "L"),
        missing_doing("interpreting the provided hint/notes as the calculation logic")),
    anchor(lesson('IM-G6-U2-L11'), grade('6'), record_id('im_defrag_59fc416175f75e7c1886ab5b_1'), statement_sha('3d4c4d363e5cda0ea062b7dab2aca1a5ef805550e424cccc346469e3c7e97f14')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_5a48c0374c644c841d4d60bf_1', "8 - 4 = 10- 6",
    analysis(
        quantities([quantity(8, "number", "8"), quantity(4, "number", "4"), quantity(10, "number", "10"), quantity(6, "number", "6")]),
        ask("Determine if the equation 8 - 4 = 10 - 6 is true."),
        steps([step("subtraction", [8, 4], 4), step("subtraction", [10, 6], 4), step("compare_equal", [4, 4], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U3-L10'), grade('2'), record_id('im_defrag_5a48c0374c644c841d4d60bf_1'), statement_sha('564471db028cfc396f934f763188806bd009e59db9d0ccbafe6a9aec70aaf528')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_5a4f73199dbbcc34e7ee6d75_1', "If there were 30 days in the month (5 units total), how many days were rainy?",
    analysis(
        quantities([quantity(30, "days", "30 days"), quantity(5, "units", "5 units total")]),
        ask("How many days were rainy if there are 30 days in the month representing 5 total units?"),
        steps([step("divide", [30, 5], 6)]),
        answer(6, "days"),
        missing_doing("interpreting the relationship between units and days")),
    anchor(lesson('IM-G6-U2-L15'), grade('6'), record_id('im_defrag_5a4f73199dbbcc34e7ee6d75_1'), statement_sha('13a02ca82959777b4c3178ace27b7c12c3d734e0b197d9179b3391363c61a96d')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_4.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_5a72d3ca25649b27839db31f_1', "3 + 2 = 5",
    analysis(
        quantities([quantity(3, "number", "3"), quantity(2, "number", "2"), quantity(5, "number", "5")]),
        ask("Check if 3 + 2 equals 5."),
        steps([step("addition", [3, 2], 5), step("compare_equal", [5, 5], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U2-L15'), grade('1'), record_id('im_defrag_5a72d3ca25649b27839db31f_1'), statement_sha('fd7b1071d8776052bc29ff49fc58f8093421e844dfd9f1e3c27c3c1ce3a40cc2')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_5ad11d05d8564fe608c58168_1', "8 - 4 = 10- 6",
    analysis(
        quantities([quantity(8, "number", "8"), quantity(4, "number", "4"), quantity(10, "number", "10"), quantity(6, "number", "6")]),
        ask("Determine if 8 minus 4 is equal to 10 minus 6."),
        steps([step("subtraction", [8, 4], 4), step("subtraction", [10, 6], 4), step("compare_equal", [4, 4], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U3-L10'), grade('2'), record_id('im_defrag_5ad11d05d8564fe608c58168_1'), statement_sha('564471db028cfc396f934f763188806bd009e59db9d0ccbafe6a9aec70aaf528')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_5afa555f796ffa4245bc1604_1', "Tyler has 3 boxes. He has 5 baseballs in each box. How many baseballs does he have altogether?",
    analysis(
        quantities([quantity(3, "boxes", "3 boxes"), quantity(5, "baseballs", "5 baseballs")]),
        ask("How many baseballs does Tyler have in total?"),
        steps([step("multiplication", [3, 5], 15)]),
        answer(15, "baseballs"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U1-L12'), grade('3'), record_id('im_defrag_5afa555f796ffa4245bc1604_1'), statement_sha('83d3286f65c79a12682b4a5854addc26322640d9bb29952c646e04a219f098b4')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_5b10b6c3d1b8b04b5f9c73f3_1', "70 + 1 = 80 + 1",
    analysis(
        quantities([quantity(70, "number", "70"), quantity(1, "number", "1"), quantity(80, "number", "80"), quantity(1, "number", "1")]),
        ask("Is the equation 70 + 1 = 80 + 1 true?"),
        steps([step("addition", [70, 1], 71), step("addition", [80, 1], 81), step("compare_equal", [71, 81], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U4-L11'), grade('1'), record_id('im_defrag_5b10b6c3d1b8b04b5f9c73f3_1'), statement_sha('a41f7aea888b5242fbd3544b826baf97282d6d3d3f215d2455f1c303cc37eeb5')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_5c6b23072688f3edefb66971_1', "Use the standard algorithm to find the product 251 × 34.",
    analysis(
        quantities([quantity(251, "number", "251"), quantity(34, "number", "34")]),
        ask("What is the product of 251 and 34 using the standard algorithm?"),
        steps([step("multiplication", [251, 4], 1004), step("multiplication", [251, 30], 7530), step("addition", [1004, 7530], 8534)]),
        answer(8534, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U4-L6'), grade('5'), record_id('im_defrag_5c6b23072688f3edefb66971_1'), statement_sha('2d0b40f0ca9fd228920e3f5f868a6039599298a3b6f95671f5ef777a455a2847')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_5c7837ea78c94bd53d35abf7_1', "Kiran donated 28 books to the book drive. Jada donated some books, too. Kiran donated 4 times as many books as Jada. How many books did Jada donate? Explain or show your reasoning.",
    analysis(
        quantities([quantity(28, "books", "28 books"), quantity(4, "times", "4 times")]),
        ask("How many books did Jada donate?"),
        steps([step("division", [28, 4], 7)]),
        answer(7, "books"),
        missing_doing("modeling the relationship between the variables")),
    anchor(lesson('IM-G4-U5-L3'), grade('4'), record_id('im_defrag_5c7837ea78c94bd53d35abf7_1'), statement_sha('94b8534940ddc9e5e17d37f3bb6d99ed983c85ba8051248702777d59bea0583b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_5d45e404461d5d3559c5b964_1', "60 = 25 + 45",
    analysis(
        quantities([quantity(60, "number", "60"), quantity(25, "number", "25"), quantity(45, "number", "45")]),
        ask("Determine if the equation 60 = 25 + 45 is true."),
        steps([step("addition", [25, 45], 70), step("compare_equal", [60, 70], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U8-L10'), grade('1'), record_id('im_defrag_5d45e404461d5d3559c5b964_1'), statement_sha('b50815eca59bdd6deb2f2a000a834d60a7f95c9ba1e7d9692031b679c0f0786e')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_5de73969fb198966a949e5bf_1', "5 students play with beans. 8 students play with small rocks. How many more students play with rocks than beans? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(5, "students", "5 students"), quantity(8, "students", "8 students")]),
        ask("How many more students play with rocks than beans?"),
        steps([step("subtraction", [8, 5], 3)]),
        answer(3, "students"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U2-L20'), grade('1'), record_id('im_defrag_5de73969fb198966a949e5bf_1'), statement_sha('cc10d71ef44f73cbc546d85eea91d36e8d1edd5878ab2578c92fcb0e20149ff3')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_5f5b875c98dabec4b0ba55be_1', "How long is 10% of 60 minutes?",
    analysis(
        quantities([quantity(10, "percent", "10%"), quantity(60, "minutes", "60 minutes")]),
        ask("How many minutes is 10% of 60 minutes?"),
        steps([step("multiply", [0.1, 60], 6)]),
        answer(6, "minutes"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U3-L13'), grade('6'), record_id('im_defrag_5f5b875c98dabec4b0ba55be_1'), statement_sha('5efdb20cb8859470c324888f2dfc4998a90decbbf2d070fa8edd45a2a5321a3a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_60d0291b06ab5bb0f0a3746a_1', "Four students share a $271 prize from a science competition. How much does each student get if the prize is shared equally?",
    analysis(
        quantities([quantity(4, "students", "Four students"), quantity(271, "dollars", "$271")]),
        ask("How much money does each student receive if the $271 prize is shared equally among the four students?"),
        steps([step("division", [271, 4], 67.75)]),
        answer(67.75, "dollars"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U5-L9'), grade('6'), record_id('im_defrag_60d0291b06ab5bb0f0a3746a_1'), statement_sha('e8d25bb652ccd8210a19553f18dab16fd495a3e9ba703b23f7db50d5b0cdc684')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_6105e04c27d13ef759b08c0e_1', "4,799 = 5,000- 311",
    analysis(
        quantities([quantity(4799, "number", "4,799"), quantity(5000, "number", "5,000"), quantity(311, "number", "311")]),
        ask("Is 4,799 equal to 5,000 minus 311?"),
        steps([step("subtraction", [5000, 311], 4689), step("compare_equal", [4799, 4689], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U6-L24'), grade('4'), record_id('im_defrag_6105e04c27d13ef759b08c0e_1'), statement_sha('fe4856834edd6edc196a9a45b78c4fc1e57caa9a42a486a6a46830cf94a3acc4')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_6109fb49f911e7cd3548ff7e_1', "A car is traveling at a constant speed of 60 miles per hour. How far does the car travel in: b. 5 hours?",
    analysis(
        quantities([quantity(60, "miles per hour", "60 miles per hour"), quantity(5, "hours", "5 hours")]),
        ask("How far does the car travel in 5 hours if it is traveling at a constant speed of 60 miles per hour?"),
        steps([step("multiplication", [60, 5], 300)]),
        answer(300, "miles"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U5-L8'), grade('7'), record_id('im_defrag_6109fb49f911e7cd3548ff7e_1'), statement_sha('342672ec6897ba1aac95b110ce6061a7cde545f78a56ac20713fdcff6065997c')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_6198867e843840b3204863a1_1', "8 + 5 = 10 + 3",
    analysis(
        quantities([quantity(8, "number", "8"), quantity(5, "number", "5"), quantity(10, "number", "10"), quantity(3, "number", "3")]),
        ask("Check if 8 + 5 is equal to 10 + 3."),
        steps([step("addition", [8, 5], 13), step("addition", [10, 3], 13), step("compare_equal", [13, 13], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U9-L2'), grade('2'), record_id('im_defrag_6198867e843840b3204863a1_1'), statement_sha('0ffc91885f16394452cf29812b080e1e521573e125cf18df698d8466f2a28f6c')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_61dd0bbb6a54399e03b74fad_1', "For this year’s book fair, a school ordered 15 science experiment books and 6 times as many picture books. Last year, the school ordered 4 times as many picture books and 4 times as many science experiment books than they did this year. 1. How many picture books were ordered last year? Show or explain your reasoning. 2. How many total books were ordered last year? Show or explain your reasoning.",
    analysis(
        quantities([quantity(15, "science experiment books", "15 science experiment books"), quantity(6, "multiplier", "6 times as many"), quantity(4, "multiplier", "4 times as many")]),
        ask("How many picture books were ordered last year and how many total books were ordered last year?"),
        steps([step("multiply", [15, 6], 90), step("multiply", [90, 4], 360), step("multiply", [15, 4], 60), step("add", [360, 60], 420)]),
        answer(420, "total books last year"),
        missing_doing("multi-part question answering")),
    anchor(lesson('IM-G4-U5-L5'), grade('4'), record_id('im_defrag_61dd0bbb6a54399e03b74fad_1'), statement_sha('4c6eb3943d950c3916f41b60d74a0d64b7bfa6d7b402dbb68289c4f15a5b4dda')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_0.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_61f12d56baee13adb19b3095_1', "70 + 1 = 80 + 1",
    analysis(
        quantities([quantity(70, "number", "70"), quantity(1, "number", "1"), quantity(80, "number", "80"), quantity(1, "number", "1")]),
        ask("Is 70 + 1 equal to 80 + 1?"),
        steps([step("addition", [70, 1], 71), step("addition", [80, 1], 81), step("compare_equal", [71, 81], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U4-L11'), grade('1'), record_id('im_defrag_61f12d56baee13adb19b3095_1'), statement_sha('a41f7aea888b5242fbd3544b826baf97282d6d3d3f215d2455f1c303cc37eeb5')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_62b74d8114b71b241f10b7e7_1', "On day 4, he hikes up 732 meters to Lava Tower and then back down 641 meters. He ends the day at 3,986 meters. What elevation did he start the day at?",
    analysis(
        quantities([quantity(732, "meters", "732 meters"), quantity(641, "meters", "641 meters"), quantity(3986, "meters", "3,986 meters")]),
        ask("What was his starting elevation at the beginning of day 4?"),
        steps([step("subtract", [732, 641], 91), step("subtract", [3986, 91], 3895)]),
        answer(3895, "meters"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U5-L7'), grade('7'), record_id('im_defrag_62b74d8114b71b241f10b7e7_1'), statement_sha('fb77c331464a283997e1a51583d583aa20dea9c9b7634da8f65f45bd94ccd909')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_63000aa34f41af80ac0a516d_1', "Twelve large bottles of water cost $9. a. How many bottles can you buy for $3? b.",
    analysis(
        quantities([quantity(12, "bottles", "Twelve large bottles"), quantity(9, "dollars", "$9"), quantity(3, "dollars", "$3")]),
        ask("How many bottles can be purchased for $3?"),
        steps([step("division", [9, 12], 0.75), step("division", [3, 0.75], 4)]),
        answer(4, "bottles"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L8'), grade('6'), record_id('im_defrag_63000aa34f41af80ac0a516d_1'), statement_sha('f2ff73de473ad406d9f42c6c579478fa939932ca7bc80e1275cda337d61c6d2d')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_63878bdd8ea266361e594ece_1', "The ratio of students wearing sneakers to those wearing boots is 5 to 6. How many total parts (5+6)?",
    analysis(
        quantities([quantity(5, "sneakers ratio", "5"), quantity(6, "boots ratio", "6")]),
        ask("What is the sum of the parts in the ratio of 5 to 6?"),
        steps([step("addition", [5, 6], 11)]),
        answer(11, "total parts"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L15'), grade('6'), record_id('im_defrag_63878bdd8ea266361e594ece_1'), statement_sha('4cda036f297ab1a2813a2e1fa63d2fc5c3e285fc4736f3ab4a33a81b87c4f787')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_64513eb8fa9ab6c7677c4d07_1', "How far is 50% of a 2,000-kilometer trip? c.",
    analysis(
        quantities([quantity(50, "percent", "50%"), quantity(2000, "kilometers", "2,000-kilometer")]),
        ask("How many kilometers is 50% of a 2,000-kilometer trip?"),
        steps([step("multiplication", [0.5, 2000], 1000)]),
        answer(1000, "kilometers"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U3-L13'), grade('6'), record_id('im_defrag_64513eb8fa9ab6c7677c4d07_1'), statement_sha('88f2a1b6ad32ca0c5445effd2db57e5f0e1e87a5bedc673114038359299ecaf7')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_64cfaa76e82c2b9316b02e4b_1', "Twenty-four legs belong to 4 ants. All ants have the same number of legs. 1. Write a division expression to represent this situation. 2. How many legs does each ant have? Explain or show your reasoning.",
    analysis(
        quantities([quantity(24, "legs", "Twenty-four legs"), quantity(4, "ants", "4 ants")]),
        ask("How many legs does each ant have?"),
        steps([step("division", [24, 4], 6)]),
        answer(6, "legs"),
        missing_doing("formulating a division expression")),
    anchor(lesson('IM-G3-U4-L5'), grade('3'), record_id('im_defrag_64cfaa76e82c2b9316b02e4b_1'), statement_sha('03f5ca0261764f67524eb769de6fef304c261d0ce5ec44dbabfd00764b83cc2b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_654bc0bdd3ff65f1f04a6acb_1', "2 × 40 = 2 × 4 × 10",
    analysis(
        quantities([quantity(2, "number", "2"), quantity(40, "number", "40"), quantity(2, "number", "2"), quantity(4, "number", "4"), quantity(10, "number", "10")]),
        ask("Check if 2 multiplied by 40 is equal to 2 multiplied by 4 multiplied by 10."),
        steps([step("multiplication", [2, 40], 80), step("multiplication", [2, 4], 8), step("multiplication", [8, 10], 80), step("compare_equal", [80, 80], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L17'), grade('3'), record_id('im_defrag_654bc0bdd3ff65f1f04a6acb_1'), statement_sha('b3ce89bceb78d963b740280b11b0a566abd14b7d321fb7942ba13838c3b70cdf')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_6575e06e8dc4b7583336f9c9_1', "Andre has 4 pattern blocks. He adds 4 more. How many pattern blocks? _______________ Equation:",
    analysis(
        quantities([quantity(4, "pattern blocks", "4"), quantity(4, "pattern blocks", "4")]),
        ask("How many pattern blocks does Andre have in total?"),
        steps([step("addition", [4, 4], 8)]),
        answer(8, "pattern blocks"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U7-L5'), grade('K'), record_id('im_defrag_6575e06e8dc4b7583336f9c9_1'), statement_sha('cea98229cb6c97cf8ca69e10a9dc582b3086da7b44b3f1b31caad8704329ee2b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_6594fc3e57bf32a74b0614cf_1', "There were 64 seeds in a bag. Then 25 of the seeds were planted in the garden. How many seeds are in the bag now? 1. Some students estimated how many seeds were left. Beside each estimate, circle too high, too low, or about right. a. 4 seeds too high too low about right b. 80 seeds too high too low about right c. 40 seeds too high too low about right d. 100 seeds too high too low about right 2. Explain how you know the answer you chose as about right is reasonable.",
    analysis(
        quantities([quantity(64, "seeds", "64 seeds"), quantity(25, "seeds", "25 of the seeds")]),
        ask("How many seeds are in the bag now?"),
        steps([step("subtraction", [64, 25], 39)]),
        answer(39, "seeds"),
        missing_doing("evaluating estimates")),
    anchor(lesson('IM-G2-U2-L15'), grade('2'), record_id('im_defrag_6594fc3e57bf32a74b0614cf_1'), statement_sha('004a4f2d14cdf242da94f0bcef69f3428582f804d71b37798fcb22cfadbfa880')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_65e7e6e59a67fa87d74e421f_1', "3 + 6 = 6 + 4",
    analysis(
        quantities([quantity(3, "number", "3"), quantity(6, "number", "6"), quantity(6, "number", "6"), quantity(4, "number", "4")]),
        ask("Check if 3 + 6 is equal to 6 + 4."),
        steps([step("addition", [3, 6], 9), step("addition", [6, 4], 10), step("compare_equal", [9, 10], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L3'), grade('1'), record_id('im_defrag_65e7e6e59a67fa87d74e421f_1'), statement_sha('b8475106c93f4118853185a6b1fa544c16c3cdcf65aedc4dc6549c5d9cad5a8b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_65ebe0923b99cfb8b8fb457b_1', "1. Tyler’s teacher collected 37 dollars for the field trip. Then someone brought in 7 more dollars. How much money did Tyler’s teacher collect? Show your thinking using drawings, numbers, or words. 2. Tyler’s teacher wants to know how many students are in the classroom. There are 8 students sitting at tables. There are 26 students on the rug. How many students are in the classroom? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(8, "students", "8 students"), quantity(26, "students", "26 students")]),
        ask("How many students are in the classroom?"),
        steps([step("addition", [8, 26], 34)]),
        answer(34, "students"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U5-L5'), grade('1'), record_id('im_defrag_65ebe0923b99cfb8b8fb457b_1'), statement_sha('0f24c8c6d6f21a1903bd86508786cde06a1a1deeeabc0ef7e92b787dce60fa34')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_6652e73efd7d1fed0973f113_1', "Clare mowed the lawn of a community center for 2 hours and earned $30. Which jobs paid better than others?",
    analysis(
        quantities([quantity(2, "hours", "2 hours"), quantity(30, "dollars", "$30")]),
        ask("The problem asks to compare Clare's earnings rate to other jobs, but since no other jobs are mentioned, it is asking for Clare's hourly rate to provide a baseline."),
        steps([step("divide", [30, 2], 15)]),
        answer(15, "dollars per hour"),
        missing_doing("comparison to unspecified data")),
    anchor(lesson('IM-G6-U3-L9'), grade('6'), record_id('im_defrag_6652e73efd7d1fed0973f113_1'), statement_sha('174a18a75fc6afcaf900964188b0f76f862b18eae5a10ca990084b09ac922a76')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_0.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_66a6539bc2d5296b3aff8542_1', "1. How many thousands are in 12,000? 2. Draw a diagram to represent 15,400.",
    analysis(
        quantities([quantity(12000, "number", "12,000")]),
        ask("How many thousands are in 12,000?"),
        steps([step("division", [12000, 1000], 12)]),
        answer(12, "thousands"),
        missing_doing("drawing a diagram")),
    anchor(lesson('IM-G4-U4-L6'), grade('4'), record_id('im_defrag_66a6539bc2d5296b3aff8542_1'), statement_sha('34a7074b4656ed585a603b05ef356f62be4f6e0aeee9217254bd1b981e87dc04')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_66abc8cb22c9a9b9c4841b7e_1', "80 + 5 = 5 + 80",
    analysis(
        quantities([quantity(80, "number", "80"), quantity(5, "number", "5"), quantity(5, "number", "5"), quantity(80, "number", "80")]),
        ask("Check if 80 + 5 is equal to 5 + 80."),
        steps([step("addition", [80, 5], 85), step("addition", [5, 80], 85), step("compare_equal", [85, 85], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U4-L11'), grade('1'), record_id('im_defrag_66abc8cb22c9a9b9c4841b7e_1'), statement_sha('716443639a428ac84586724d45bdeb8a896de386b4cc6cc29bf3e9f98987a576')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_66d2f6a0c5313b2e2e01a417_1', "6 + 4 = 5 + 3",
    analysis(
        quantities([quantity(6, "number", "6"), quantity(4, "number", "4"), quantity(5, "number", "5"), quantity(3, "number", "3")]),
        ask("Determine if the equation 6 + 4 = 5 + 3 is true."),
        steps([step("addition", [6, 4], 10), step("addition", [5, 3], 8), step("compare_equal", [10, 8], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L3'), grade('1'), record_id('im_defrag_66d2f6a0c5313b2e2e01a417_1'), statement_sha('4e7c0a30455f0ecf2fdd001e8570cfef17b5974e6be806f3ea7f11207d83e049')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_4.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_670080b146579f5bc525cc9e_1', "Complete the table to represent a cheetah running at a constant speed. (25 seconds at speed 30)",
    analysis(
        quantities([quantity(25, "seconds", "25 seconds"), quantity(30, "speed", "speed 30")]),
        ask("Complete the table to represent a cheetah running at a constant speed given that it runs for 25 seconds at a speed of 30."),
        steps([step("multiply", [25, 30], 750)]),
        answer(750, "distance"),
        missing_doing("table completion")),
    anchor(lesson('IM-G6-U3-L6'), grade('6'), record_id('im_defrag_670080b146579f5bc525cc9e_1'), statement_sha('9d5c2e4de8a8ae33adbdd4ea3382fd3692697e0e4c2f5f29600421944ca157b2')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_6702fd5ace5dd953e854f571_1', "A rectangle is 6 feet by 15 feet. What is the area of the rectangle? Explain or show your reasoning.",
    analysis(
        quantities([quantity(6, "feet", "6"), quantity(15, "feet", "15")]),
        ask("What is the area of the rectangle?"),
        steps([step("multiplication", [6, 15], 90)]),
        answer(90, "square feet"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L15'), grade('3'), record_id('im_defrag_6702fd5ace5dd953e854f571_1'), statement_sha('6dd79cd9e485c00cc1d78ccc1ce2070d862d8b48bb03d41f2b96a92f2060ecd1')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_674c80bc4b0152315eb43b3c_1', "4 movie tickets cost $48. At this rate, what is the cost of b. 11 movie tickets?",
    analysis(
        quantities([quantity(4, "movie tickets", "4 movie tickets"), quantity(48, "dollars", "$48"), quantity(11, "movie tickets", "11 movie tickets")]),
        ask("What is the cost of 11 movie tickets at the same rate?"),
        steps([step("division", [48, 4], 12), step("multiplication", [12, 11], 132)]),
        answer(132, "dollars"),
        missing_doing("proportional reasoning")),
    anchor(lesson('IM-G6-U2-L8'), grade('6'), record_id('im_defrag_674c80bc4b0152315eb43b3c_1'), statement_sha('f8fbb88a06abc15b5250ab725323cdf38c6b7462bac21f7167dc346824f0a7a7')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_676cbe2cd83250c98c3ba0ae_1', "4 + 2 = 2 + 4",
    analysis(
        quantities([quantity(4, "number", "4"), quantity(2, "number", "2"), quantity(2, "number", "2"), quantity(4, "number", "4")]),
        ask("Check if the equation 4 + 2 = 2 + 4 is true."),
        steps([step("addition", [4, 2], 6), step("addition", [2, 4], 6), step("compare_equal", [6, 6], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L3'), grade('1'), record_id('im_defrag_676cbe2cd83250c98c3ba0ae_1'), statement_sha('004f712e1fbaaea7c2d516d935b4c4c3f914b5d67312d282507589ba76bcf10b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_683e286c2111fc5c6f43c1e8_1', "Elena used 23 cubes to make a train. Jada used 36 cubes to make a train. How many more cubes did Jada use than Elena? Show your thinking.",
    analysis(
        quantities([quantity(23, "cubes", "23 cubes"), quantity(36, "cubes", "36 cubes")]),
        ask("How many more cubes did Jada use than Elena?"),
        steps([step("subtraction", [36, 23], 13)]),
        answer(13, "cubes"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U2-L1'), grade('2'), record_id('im_defrag_683e286c2111fc5c6f43c1e8_1'), statement_sha('0875647744930792635eb5d8e0041ae5c73a90adf66aeece3e3fc4886c9e164b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_68782d6f1ccddbcc7ec2f3bc_1', "12- 2 = 10",
    analysis(
        quantities([quantity(12, "number", "12"), quantity(2, "number", "2"), quantity(10, "number", "10")]),
        ask("Check if 12 minus 2 equals 10."),
        steps([step("subtraction", [12, 2], 10), step("compare_equal", [10, 10], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U1-L6'), grade('1'), record_id('im_defrag_68782d6f1ccddbcc7ec2f3bc_1'), statement_sha('1045bc7754abeffdd6bca553de17887f5e6a2de66264cb66f4932afd3294c9b9')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_68d10193612c126f215a00eb_1', "The area of a rectangular garden is 832 square feet and its length is 16 feet. What is its width?",
    analysis(
        quantities([quantity(832, "square feet", "832 square feet"), quantity(16, "feet", "16 feet")]),
        ask("What is the width of the rectangular garden?"),
        steps([step("division", [832, 16], 52)]),
        answer(52, "feet"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U4-L14'), grade('5'), record_id('im_defrag_68d10193612c126f215a00eb_1'), statement_sha('4c84e8d23bee19025c58b90fa6f149d1d43c68d3eb318cf2ba0b74a4ccbb7341')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_691bf3382a90d2c7de9f1ea9_1', "4 markers at school. Elena brought 3 more markers to school. How many markers are at school now?",
    analysis(
        quantities([quantity(4, "markers", "4 markers"), quantity(3, "markers", "3 more markers")]),
        ask("How many markers are at school in total now?"),
        steps([step("addition", [4, 3], 7)]),
        answer(7, "markers"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U4-L9'), grade('K'), record_id('im_defrag_691bf3382a90d2c7de9f1ea9_1'), statement_sha('f52f1ab20f6927229507cb7aa142194c2f68f7af97c5f53b7752a604e5dfdd16')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_69332f348cec7787b16198f2_1', "Find the value of each quotient. Show your reasoning. Use vertical calculations at least once. 2. 1,115 ÷ 5",
    analysis(
        quantities([quantity(1115, "number", "1,115"), quantity(5, "number", "5")]),
        ask("What is the value of the quotient of 1,115 divided by 5?"),
        steps([step("division", [1115, 5], 223)]),
        answer(223, "quotient"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U5-L10'), grade('6'), record_id('im_defrag_69332f348cec7787b16198f2_1'), statement_sha('535747e6db52c8261f380334b5397c911036cc988e49e985ade2c744b08eb620')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_6a6ea0cfaf1daf06dd78bf04_1', "5 ducks swim in the pond. 4 more come. How many now?",
    analysis(
        quantities([quantity(5, "ducks", "5 ducks"), quantity(4, "ducks", "4 more")]),
        ask("How many ducks are in the pond now?"),
        steps([step("addition", [5, 4], 9)]),
        answer(9, "ducks"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U4-L12'), grade('K'), record_id('im_defrag_6a6ea0cfaf1daf06dd78bf04_1'), statement_sha('8fa687d1c6f94ec2b0a1c745e95b4d3f18afacb9a4d9859cf7b1978b3b1b6142')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_6a8f38326d21d80c5ce40dbc_1', "The 11 slices of cheddar cheese in this package weigh 308 grams. At the same weight per slice, how much would 18 slices of cheddar cheese weigh?",
    analysis(
        quantities([quantity(11, "slices", "11 slices"), quantity(308, "grams", "308 grams"), quantity(18, "slices", "18 slices")]),
        ask("How much would 18 slices of cheddar cheese weigh if the weight per slice remains the same?"),
        steps([step("division", [308, 11], 28), step("multiplication", [28, 18], 504)]),
        answer(504, "grams"),
        missing_doing("unit rate calculation")),
    anchor(lesson('IM-G6-U3-L9'), grade('6'), record_id('im_defrag_6a8f38326d21d80c5ce40dbc_1'), statement_sha('8799163468760de8bd881202164516e9c00da54d97a33a33d7c7a57738c8dbc5')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_6a907e08a7ffea05caf39995_1', "Noah wanted to find the value of 301 - 167 and wrote: Elena said that we can’t subtract this way because we would need more ones to subtract 7 ones, but there’s a zero in the tens place of 301. 1. Do you agree with Elena's statement? Explain your reasoning. 2. Show how you would use an algorithm (either Noah's or another algorithm) to find the difference between 301 and 167.",
    analysis(
        quantities([quantity(301, "number", "301"), quantity(167, "number", "167")]),
        ask("Do you agree with Elena's statement regarding the subtraction process, and what is the difference between 301 and 167?"),
        steps([step("subtraction", [301, 167], 134)]),
        answer(134, "number"),
        missing_doing("mathematical reasoning and explanation")),
    anchor(lesson('IM-G3-U3-L11'), grade('3'), record_id('im_defrag_6a907e08a7ffea05caf39995_1'), statement_sha('70dd588e8939c3806e79f0566f95076ee3dc5b6c2cfc52acc480b8d25b527c4c')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_6a93cb13103193c9fcbdecd1_1', "Diego gathers 42 orange seeds. Jada gathers 16 apple seeds. How many more seeds does Diego gather than Jada? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(42, "orange seeds", "42 orange seeds"), quantity(16, "apple seeds", "16 apple seeds")]),
        ask("How many more seeds does Diego gather than Jada?"),
        steps([step("subtraction", [42, 16], 26)]),
        answer(26, "seeds"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U2-L11'), grade('2'), record_id('im_defrag_6a93cb13103193c9fcbdecd1_1'), statement_sha('8810b0b8f184955e532377aaa85647404d32469409bbf9cb1f7a59255e1b02a3')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_6b83452da2f1560ea21324c4_1', "1. Lin and Clare make cube trains. What do you notice? What do you wonder? 2. Make cube trains. partner number of cubes Partner A 46 Partner B 22 3. Find the total number of cubes you both used. Show your thinking using drawings, numbers, or words. 4. Find the difference between the number of cubes you each used. Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(46, "cubes", "46"), quantity(22, "cubes", "22")]),
        ask("Find the total number of cubes used and the difference between the number of cubes used by Partner A and Partner B."),
        steps([step("addition", [46, 22], 68), step("subtraction", [46, 22], 24)]),
        answer(68, "cubes"),
        missing_doing("multi-part question")),
    anchor(lesson('IM-G2-U2-L1'), grade('2'), record_id('im_defrag_6b83452da2f1560ea21324c4_1'), statement_sha('7304e909fbb3d395bda89ecde648d652ef438f42111f3189fedd763c77e07919')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_0.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_6b92c067a8bffebab6f8f1f0_1', "24 + 3 = 54",
    analysis(
        quantities([quantity(24, "number", "24"), quantity(3, "number", "3"), quantity(54, "number", "54")]),
        ask("Is the equation 24 + 3 = 54 true?"),
        steps([step("addition", [24, 3], 27), step("compare_equal", [27, 54], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U5-L11'), grade('1'), record_id('im_defrag_6b92c067a8bffebab6f8f1f0_1'), statement_sha('1a3d1cb22de99f4fb804a947c8dca6d77054db2ee55012d74785bd88a74b093c')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_6bdb001c4298b039acc6b061_1', "Complete the table below. Equation Situation 5 children share 4 cups of milk so each child gets the same amount of milk. How many cups of milk will each child get? Diagram",
    analysis(
        quantities([quantity(5, "children", "5 children"), quantity(4, "cups of milk", "4 cups of milk")]),
        ask("How many cups of milk will each child get?"),
        steps([step("division", [4, 5], 0.8)]),
        answer(0.8, "cups of milk"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U2-L4'), grade('5'), record_id('im_defrag_6bdb001c4298b039acc6b061_1'), statement_sha('8e731d204b696a8c196acff5540a383f4a7f70ab644a80e7f2f4d1565019defe')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_6c240ac33a694cc8850c498d_1', "1. There are 65 students in the monkey house. 23 left to see the hippos. How many are still in the monkey house?",
    analysis(
        quantities([quantity(65, "students", "65 students"), quantity(23, "students", "23")]),
        ask("How many students are still in the monkey house?"),
        steps([step("subtraction", [65, 23], 42)]),
        answer(42, "students"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U2-L3'), grade('2'), record_id('im_defrag_6c240ac33a694cc8850c498d_1'), statement_sha('f0438fbeeaee75e70b498fcb422c13346095b0a5e14471add938f45a38a8c343')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_6c68532e1b4b65b77fd35129_1', "Elena picks 29 apples. She picks 14 fewer apples than Han. Han picks 15 more apples than Diego. 1. Write a question someone could answer with this information. 2. Answer your question. Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(29, "apples", "29 apples"), quantity(14, "apples", "14 fewer apples"), quantity(15, "apples", "15 more apples")]),
        ask("The problem asks to write a question that can be answered using the information provided and then to provide an answer to that question."),
        steps([step("add", [29, 14], 43), step("subtract", [43, 15], 28)]),
        answer(28, "apples"),
        missing_doing("problem formulation")),
    anchor(lesson('IM-G2-U9-L10'), grade('2'), record_id('im_defrag_6c68532e1b4b65b77fd35129_1'), statement_sha('41d4b3914de432b0578d85b43e58ff4d453e883c8b995d1475c2065d46f89aa0')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_2.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_6c7abe015446d2a70abc541b_1', "Is the decimal for 18/50 also 0.36? Use long division to support your answer.",
    analysis(
        quantities([quantity(18, "numerator", "18"), quantity(50, "denominator", "50"), quantity(0.36, "decimal", "0.36")]),
        ask("Is the decimal representation of the fraction 18/50 equal to 0.36?"),
        steps([step("division", [18, 50], 0.36), step("compare_equal", [0.36, 0.36], true)]),
        answer(true, "claim_verdict"),
        missing_doing("long division")),
    anchor(lesson('IM-G6-U5-L12'), grade('6'), record_id('im_defrag_6c7abe015446d2a70abc541b_1'), statement_sha('5a5d75fe334c26dd42d60e518c52eb7b62a7f8b96b0d36dd27fb1696fc8759a5')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_6c8836ef34774bfd25a40108_1', "3 × 60 = 9 × 10",
    analysis(
        quantities([quantity(3, "number", "3"), quantity(60, "number", "60"), quantity(9, "number", "9"), quantity(10, "number", "10")]),
        ask("Check if 3 times 60 is equal to 9 times 10."),
        steps([step("multiplication", [3, 60], 180), step("multiplication", [9, 10], 90), step("compare_equal", [180, 90], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U7-L2'), grade('3'), record_id('im_defrag_6c8836ef34774bfd25a40108_1'), statement_sha('667192a07b598873ddbd8eca355a932a093b96a574dcd52fac3bcb15093d1cc1')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_6ce1ee90180459b9bcbc8b81_1', "Complete the table so ratios in each row are equivalent to 7:5. Row: 250 fl oz soy sauce (=5*50), find vinegar.",
    analysis(
        quantities([quantity(7, "ratio_part_1", "7"), quantity(5, "ratio_part_2", "5"), quantity(250, "fl oz soy sauce", "250 fl oz soy sauce")]),
        ask("Find the amount of vinegar that makes the ratio 7:5 equivalent to the ratio of 250 fl oz soy sauce to vinegar."),
        steps([step("division", [250, 5], 50), step("multiplication", [7, 50], 350)]),
        answer(350, "fl oz vinegar"),
        missing_doing("proportional reasoning")),
    anchor(lesson('IM-G6-U2-L11'), grade('6'), record_id('im_defrag_6ce1ee90180459b9bcbc8b81_1'), statement_sha('619b3e2532a64f12749c93da8ae1e16b48d4b0adc61ba8af6bd62c800096dbad')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_6d1e68445da9193f23824876_1', "244- 67",
    analysis(
        quantities([quantity(244, "number", "244"), quantity(67, "number", "67")]),
        ask("What is 244 minus 67?"),
        steps([step("subtraction", [244, 67], 177)]),
        answer(177, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U7-L14'), grade('2'), record_id('im_defrag_6d1e68445da9193f23824876_1'), statement_sha('28c5a1080ea4ec332bfd02539d8e71c880df3e0c34d86a8762573554af1cdd18')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_6da86444cc4e82afe2e9c335_1', "Find the value of 82- 9 . Show your thinking using objects, drawings, numbers, or words.",
    analysis(
        quantities([quantity(82, "number", "82"), quantity(9, "number", "9")]),
        ask("What is the value of 82 minus 9?"),
        steps([step("subtraction", [82, 9], 73)]),
        answer(73, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U2-L5'), grade('2'), record_id('im_defrag_6da86444cc4e82afe2e9c335_1'), statement_sha('76a66a34ce806cdbfc0ea56e98a324e12cfce4b797d7c6d94096502e69c5c002')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_6df7d082a6de0e4ecc6db826_1', "At a used book sale, 5 books cost $15. b. At this rate, how many books can you buy for $21?",
    analysis(
        quantities([quantity(5, "books", "5 books"), quantity(15, "dollars", "$15"), quantity(21, "dollars", "$21")]),
        ask("How many books can be bought for $21 at the same rate?"),
        steps([step("division", [15, 5], 3), step("division", [21, 3], 7)]),
        answer(7, "books"),
        missing_doing("unit rate calculation")),
    anchor(lesson('IM-G6-U2-L8'), grade('6'), record_id('im_defrag_6df7d082a6de0e4ecc6db826_1'), statement_sha('d8d9230fcf27c776ee7e6e07326330c06842abaa5d5773962cdcb16eb24e4109')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_6e063caec34a4f85fc3adaeb_1', "1. 5 students play basketball at recess. 2 students go inside to get water. 2. 3 students play on the swings at recess. 1 more student comes to play on the swings. 3. 5 students play tag at recess. 4 students go inside.",
    analysis(
        quantities([quantity(5, "students", "5 students play basketball"), quantity(2, "students", "2 students go inside"), quantity(3, "students", "3 students play on the swings"), quantity(1, "student", "1 more student comes to play on the swings"), quantity(5, "students", "5 students play tag"), quantity(4, "students", "4 students go inside")]),
        ask("How many total students are playing at recess after these changes?"),
        steps([step("subtract", [5, 2], 3), step("add", [3, 1], 4), step("subtract", [5, 4], 1), step("add", [3, 4, 1], 8)]),
        answer(8, "students"),
        missing_doing("summation of different activity groups")),
    anchor(lesson('IM-GK-U4-L7'), grade('K'), record_id('im_defrag_6e063caec34a4f85fc3adaeb_1'), statement_sha('36c0aef91047533e2815c8ca8f85abc330026c3360efcb9a283559d8ceec078d')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_0.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_6e39328ae02682bf15ebffa6_1', "The teacher also keeps track of the number of steps she took during the weekend. The data from Saturday and Sunday of that same week are shown. Here are 2 strategies to compute the total number of steps she took over the weekend. Strategy A Strategy B 1. Analyze the strategies. Discuss with your partner: ◦ What is happening in each strategy? ◦ How are they alike? How are they different? 2. Use both strategies to find the difference between the number of steps the teacher took on Saturday and on Sunday. 3. The following week, the teacher took 26,815 steps during the weekdays and 11,403 steps during the weekend. Use both strategies to find the total number of steps she took that week.",
    analysis(
        quantities([quantity(26815, "steps", "26,815 steps"), quantity(11403, "steps", "11,403 steps")]),
        ask("Find the total number of steps the teacher took during the following week."),
        steps([step("addition", [26815, 11403], 38218)]),
        answer(38218, "steps"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U4-L18'), grade('4'), record_id('im_defrag_6e39328ae02682bf15ebffa6_1'), statement_sha('06db79c4ce3b8527dd39d7c35be50ee3dae3d0b0944421115bb1fc05c193d1a2')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_70311b6ba7e358a0806ed353_1', "7,000 + 3,000 = 10,000",
    analysis(
        quantities([quantity(7000, "number", "7,000"), quantity(3000, "number", "3,000"), quantity(10000, "number", "10,000")]),
        ask("Check if 7,000 plus 3,000 equals 10,000."),
        steps([step("addition", [7000, 3000], 10000), step("compare_equal", [10000, 10000], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U4-L22'), grade('4'), record_id('im_defrag_70311b6ba7e358a0806ed353_1'), statement_sha('1f285e2884c8523ef90012bb9fe4db567982b17fbfc3c304b821817455eb9b9c')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_7038d7da9b546c3de928cad7_1', "There are 3 rows of chairs. Each row has 5 chairs. b.",
    analysis(
        quantities([quantity(3, "rows", "3 rows"), quantity(5, "chairs per row", "5 chairs")]),
        ask("How many chairs are there in total?"),
        steps([step("multiplication", [3, 5], 15)]),
        answer(15, "chairs"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U1-L18'), grade('3'), record_id('im_defrag_7038d7da9b546c3de928cad7_1'), statement_sha('ddcec35e9c4d9f3d3a4804a511bb8700c0b801fb0b80d605ba89bbca11a322b3')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_709c37d66bfb55f3cb9044e0_1', "In a leap year, the month of February has 29 days. How many hours are in that month? Explain or show your reasoning.",
    analysis(
        quantities([quantity(29, "days", "29 days")]),
        ask("How many hours are in the month of February during a leap year?"),
        steps([step("multiply", [29, 24], 696)]),
        answer(696, "hours"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U6-L12'), grade('4'), record_id('im_defrag_709c37d66bfb55f3cb9044e0_1'), statement_sha('82d276829326ef11aabee04c493044824fdad47c0da0879737acf7ec21d05058')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_70b9a61443e46ce3997a3d9b_1', "1. Diego starts with 5 tens and 5 ones. Show his blocks with base-ten blocks. How many does he have? 2. Diego takes away 2 tens. a. Draw a diagram to show what Diego does with his blocks. b. Write an equation. 3. Then Diego takes away 8 ones. a. Draw a diagram to show what Diego does with his blocks. b. Write a new equation.",
    analysis(
        quantities([quantity(5, "tens", "5 tens"), quantity(5, "ones", "5 ones"), quantity(2, "tens", "2 tens"), quantity(8, "ones", "8 ones")]),
        ask("The problem asks to represent Diego's starting amount, determine how many blocks he has, and then track the changes after taking away 2 tens and 8 ones."),
        steps([step("multiply", [5, 10], 50), step("add", [50, 5], 55), step("multiply", [2, 10], 20), step("subtract", [55, 20], 35), step("subtract", [35, 8], 27)]),
        answer(27, "blocks"),
        missing_doing("representing quantities via visual diagrams")),
    anchor(lesson('IM-G2-U2-L5'), grade('2'), record_id('im_defrag_70b9a61443e46ce3997a3d9b_1'), statement_sha('1d6e2a817d11b220deea8185e119129c0b585d23363e3f6e708c09fb0ef8f320')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_71d614ac80ff0bedf14d8eb6_1', "Order these objects from heaviest to lightest. grand piano: 15,840 ounces. (1 pound is 16 ounces.)",
    analysis(
        quantities([quantity(15840, "ounces", "15,840 ounces"), quantity(1, "pound", "1 pound"), quantity(16, "ounces", "16 ounces")]),
        ask("Order the objects from heaviest to lightest, specifically determining the weight of the grand piano in pounds."),
        steps([step("division", [15840, 16], 990)]),
        answer(990, "pounds"),
        missing_doing("ordering items")),
    anchor(lesson('IM-G6-U3-L9'), grade('6'), record_id('im_defrag_71d614ac80ff0bedf14d8eb6_1'), statement_sha('dead1ee75f80db76bb643b824c530b763a5b2671844961fc68e5b41032791671')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_0.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_71dd6deb3f6f73808e293cf5_1', "Jada and Kiran each found the value of 391 - 215. Their work is shown. Jada’s drawing Kiran’s algorithm 1. Explain how Kiran’s algorithm starts. 2. Explain how Kiran recorded decomposing 1 ten into more ones. 3. Finish Kiran’s work.",
    analysis(
        quantities([quantity(391, "number", "391"), quantity(215, "number", "215")]),
        ask("Explain how Kiran's algorithm starts, explain how the decomposition was recorded, and finish the calculation for 391 - 215."),
        steps([step("subtraction", [391, 215], 176)]),
        answer(176, "number"),
        missing_doing("verbal explanation of mathematical reasoning")),
    anchor(lesson('IM-G3-U3-L8'), grade('3'), record_id('im_defrag_71dd6deb3f6f73808e293cf5_1'), statement_sha('9d4788c907322e58606d2926274bb26bbba206de65a32b94e90eb6a8601cee4e')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_72565cc8c95c212103a3083d_1', "Han plays Shake and Spill. He has some counters in his cup. Then he puts 3 more counters in his cup. Now he has 10 counters in his cup. How many counters did he start with? Show your thinking using drawings, numbers, or words. Equation:",
    analysis(
        quantities([quantity(3, "counters", "3 more counters"), quantity(10, "counters", "10 counters")]),
        ask("How many counters did Han start with in his cup?"),
        steps([step("subtraction", [10, 3], 7)]),
        answer(7, "counters"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L6'), grade('1'), record_id('im_defrag_72565cc8c95c212103a3083d_1'), statement_sha('2f848097e27a1f611287cc7fd309cf020afe80e8e0e1689424f58713b1a29f2e')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_72fd335fe8103546d09f8eed_1', "A worker packs 45 apples in 9 boxes. She packs Le the same number of apples in each box. How many apples are in each box?",
    analysis(
        quantities([quantity(45, "apples", "45 apples"), quantity(9, "boxes", "9 boxes")]),
        ask("How many apples are in each box?"),
        steps([step("division", [45, 9], 5)]),
        answer(5, "apples"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L2'), grade('3'), record_id('im_defrag_72fd335fe8103546d09f8eed_1'), statement_sha('9a73688a2cf480d126dd0420ecefdc3d1318a7dab07fe1718f8e01956c112a7e')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_73f1a4589b12a79ea6a79882_1', "Find the value of 96 ÷ 6. Explain or show your reasoning.",
    analysis(
        quantities([quantity(96, "number", "96"), quantity(6, "number", "6")]),
        ask("Find the value of 96 ÷ 6."),
        steps([step("division", [96, 6], 16)]),
        answer(16, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L20'), grade('3'), record_id('im_defrag_73f1a4589b12a79ea6a79882_1'), statement_sha('b82377a3652abcedc18eb81ec52daa86232123a08a31cab3dd44c714e6114c3e')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_4.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_73fb3c8e73d830a83fa558a0_1', "3. Tyler picks a prize. There are 13 toys and 9 stuffed animals. How many fewer stuffed animals are there than toys?",
    analysis(
        quantities([quantity(13, "toys", "13 toys"), quantity(9, "stuffed animals", "9 stuffed animals")]),
        ask("How many fewer stuffed animals are there than toys?"),
        steps([step("subtraction", [13, 9], 4)]),
        answer(4, "stuffed animals"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U8-L6'), grade('1'), record_id('im_defrag_73fb3c8e73d830a83fa558a0_1'), statement_sha('8b647c8c19a04c6a9699a2381bbd10344489e8d40c386ac4a7775cb6f62ecb4b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_73fd35c817b0849d5d69b1b8_1', "A theater has 8 rows of seats and 27 seats in each row. How many seats are in the theater?",
    analysis(
        quantities([quantity(8, "rows", "8 rows"), quantity(27, "seats per row", "27 seats in each row")]),
        ask("How many seats are in the theater in total?"),
        steps([step("multiplication", [8, 27], 216)]),
        answer(216, "seats"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U6-L5'), grade('4'), record_id('im_defrag_73fd35c817b0849d5d69b1b8_1'), statement_sha('549879692084aea63ef798d22e7556062fdd021242251aa8ea52fa13b0f7e91c')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_73feb1717f86bbd837741779_1', "Diego can type 140 words in 4 minutes. At this rate, how long will it take him to type 385 words?",
    analysis(
        quantities([quantity(140, "words", "140 words"), quantity(4, "minutes", "4 minutes"), quantity(385, "words", "385 words")]),
        ask("How long will it take Diego to type 385 words at his current rate?"),
        steps([step("division", [140, 4], 35), step("division", [385, 35], 11)]),
        answer(11, "minutes"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L14'), grade('6'), record_id('im_defrag_73feb1717f86bbd837741779_1'), statement_sha('dd39e97a4c90bbb450a3e68fe881828a9ef4cb726fb7570f1aa7914e314bbb1e')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_74648f1ade69019b70b56569_1', "Andre had 451 beads. 125 beads were blue. 223 beads were pink. The rest of the beads were yellow. How many beads were yellow? Which equation matches this situation? Explain your reasoning. A. 451 + 125 + 223 = ? B. ? + 125 + 223 = 451 C. 451 = 125 + 223-?",
    analysis(
        quantities([quantity(451, "beads", "451 beads"), quantity(125, "blue beads", "125 beads were blue"), quantity(223, "pink beads", "223 beads were pink")]),
        ask("How many beads were yellow and which equation (A, B, or C) matches the situation?"),
        steps([step("addition", [125, 223], 348), step("subtraction", [451, 348], 103)]),
        answer(103, "yellow beads"),
        missing_doing("selecting the correct equation and providing reasoning")),
    anchor(lesson('IM-G3-U3-L18'), grade('3'), record_id('im_defrag_74648f1ade69019b70b56569_1'), statement_sha('0c9dba921aa97f1384dc4701a9f83c9ea560e8b0ad0109414a4eae5cfb8f8d42')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_746634e904373b0cef778c42_1', "Find the value of each expression mentally. 5 ÷ 4",
    analysis(
        quantities([quantity(5, "number", "5"), quantity(4, "number", "4")]),
        ask("What is the value of the expression 5 divided by 4?"),
        steps([step("division", [5, 4], 1.25)]),
        answer(1.25, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U2-L12'), grade('7'), record_id('im_defrag_746634e904373b0cef778c42_1'), statement_sha('1e6ef15231b3b039458f27bb51cfaff7db8fb590c094c61b3c930fdd95219362')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_74e5df0f38634225b0900ebe_1', "66- 4 = 62",
    analysis(
        quantities([quantity(66, "number", "66"), quantity(4, "number", "4"), quantity(62, "number", "62")]),
        ask("Is the equation 66 - 4 = 62 true?"),
        steps([step("subtraction", [66, 4], 62), step("compare_equal", [62, 62], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U8-L5'), grade('1'), record_id('im_defrag_74e5df0f38634225b0900ebe_1'), statement_sha('fe2126af97b7cd30afd4b611ac2668128b8c15631005a53aeabf12fbec727bc5')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_751eb3493db93023a6406c79_1', "Here are some different diagrams that represent 315 × 24. For each diagram, write a multiplication expression inside each rectangle to represent the products. 1. 2. 3. 4. Use one of the diagrams to find the value of 315 × 24. 5. Explain why you chose that diagram to find the product.",
    analysis(
        quantities([quantity(315, "number", "315"), quantity(24, "number", "24")]),
        ask("Find the value of 315 multiplied by 24 using one of the provided diagrams."),
        steps([step("multiplication", [315, 24], 7560)]),
        answer(7560, "number"),
        missing_doing("visualizing/interpreting diagrams")),
    anchor(lesson('IM-G5-U4-L2'), grade('5'), record_id('im_defrag_751eb3493db93023a6406c79_1'), statement_sha('52000810d588ce3d8a01f909ee63ba27cc9a0001eb356cba852b43f00611b6e3')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_75243a0980af8f1f30c29df3_1', "Tyler spills 5 red counters and 3 yellow counters.",
    analysis(
        quantities([quantity(5, "red counters", "5 red counters"), quantity(3, "yellow counters", "3 yellow counters")]),
        ask("How many counters did Tyler spill in total?"),
        steps([step("add", [5, 3], 8)]),
        answer(8, "counters"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L2'), grade('1'), record_id('im_defrag_75243a0980af8f1f30c29df3_1'), statement_sha('f81ea9319b602b1b5642eb8cf7db63a2274aa43b937656f7351073028f1f41f9')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_0.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_757b8cd9e1f738f6d65ca00f_1', "1 + 40",
    analysis(
        quantities([quantity(1, "number", "1"), quantity(40, "number", "40")]),
        ask("What is the sum of 1 and 40?"),
        steps([step("addition", [1, 40], 41)]),
        answer(41, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U4-L10'), grade('1'), record_id('im_defrag_757b8cd9e1f738f6d65ca00f_1'), statement_sha('3ccc818e709146fcad12cc17c8b003c28895bb569a05b860a702daa0c781cf14')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_7583ae63afba463fbc644042_1', "Are You Ready for More: 15 teaspoons of ground cumin used for the 2 parts, so each part is how much?",
    analysis(
        quantities([quantity(15, "teaspoons", "15 teaspoons"), quantity(2, "parts", "2 parts")]),
        ask("How much ground cumin is in each of the two parts if 15 teaspoons are used for 2 parts?"),
        steps([step("division", [15, 2], 7.5)]),
        answer(7.5, "teaspoons"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L15'), grade('6'), record_id('im_defrag_7583ae63afba463fbc644042_1'), statement_sha('ea3a7821f7746794a4a79ed2b0becc0292140af5d610581ffc48391a04c5c331')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_7589b0fece6c3ff77b01fb36_1', "1. Consider the statement below. Decide whether you agree, disagree, or are unsure. agree disagree unsure Round 1: The greatest product using the digits 7, 5, and 2 is 75 × 2 because 75 is the greatest number you can make. Round 2: The greatest product using the digits 7, 5, and 2 is 75 × 2 because 75 is the greatest number you can make. Write about something new that you learned from your group or something you still wonder about: 2. Use the digits 6, 3, and 1 to make the greatest product. (Use each digit only once.) Explain your reasoning.",
    analysis(
        quantities([quantity(6, "digit", "6"), quantity(3, "digit", "3"), quantity(1, "digit", "1")]),
        ask("Use the digits 6, 3, and 1 to make the greatest product using each digit only once."),
        steps([step("multiply", [6, 3], 18), step("multiply", [18, 1], 18), step("multiply", [6, 1], 6), step("multiply", [6, 31], 186), step("multiply", [3, 61], 183), step("multiply", [1, 63], 63), step("multiply", [3, 16], 48), step("multiply", [6, 3], 18), step("multiply", [31, 6], 186)]),
        answer(186, "product"),
        missing_doing("combinatorial optimization")),
    anchor(lesson('IM-G5-U8-L1'), grade('5'), record_id('im_defrag_7589b0fece6c3ff77b01fb36_1'), statement_sha('0c45c5d7fd072d8aceba5bb0143749a5c5e074700b84a93e7e48b4db8363b66d')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_4.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_75b36eb7ff2621b6416965d2_1', "Find the value of each expression mentally. 3 ÷ 6",
    analysis(
        quantities([quantity(3, "number", "3"), quantity(6, "number", "6")]),
        ask("What is the value of the expression 3 divided by 6?"),
        steps([step("division", [3, 6], 0.5)]),
        answer(0.5, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U2-L12'), grade('7'), record_id('im_defrag_75b36eb7ff2621b6416965d2_1'), statement_sha('8a51b3e424caf5acb91ed7c67802dbc1e328ec2eda13b8b9c0ac3817cffe559b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_76d0b1fe109989395e6c88c6_1', "On day 4, he hikes up 732 meters to Lava Tower and then back down 641 meters. He ends the day at an elevation of 3,986 meters. What elevation did he start the day at?",
    analysis(
        quantities([quantity(732, "meters", "732 meters"), quantity(641, "meters", "641 meters"), quantity(3986, "meters", "3,986 meters")]),
        ask("What was the hiker's starting elevation on day 4?"),
        steps([step("subtraction", [732, 641], 91), step("subtraction", [3986, 91], 3895)]),
        answer(3895, "meters"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U5-L7'), grade('7'), record_id('im_defrag_76d0b1fe109989395e6c88c6_1'), statement_sha('87d5c727194298d1dfb4b108e5097c44cc301b2667162b7103c271c46901e9b7')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_778927e7e40701418b64c639_1', "Lin ran 29 meters in 10 seconds. She ran at a constant speed. How far did Lin run every second?",
    analysis(
        quantities([quantity(29, "meters", "29 meters"), quantity(10, "seconds", "10 seconds")]),
        ask("How many meters does Lin run per second?"),
        steps([step("division", [29, 10], 2.9)]),
        answer(2.9, "meters"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U7-L9'), grade('6'), record_id('im_defrag_778927e7e40701418b64c639_1'), statement_sha('61269da257791b1c2c7dec912fd561e02e8649ec979190fe61b7dcc42b0345d9')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_77a44a6bb344e621137b306a_1', "1. Tyler bought 5 cartons of milk. Each carton contains liter. How many liters of milk did Tyler buy? Explain or show your reasoning. 2. Han bought 3 cartons of chocolate milk. Each carton contains liter. Did Han buy the same amount of milk as Tyler? Explain or show your reasoning.",
    analysis(
        quantities([quantity(5, "cartons", "5 cartons"), quantity(3, "cartons", "3 cartons")]),
        ask("How many liters of milk did Tyler buy, and did Han buy the same amount of milk as Tyler?"),
        steps([step("multiply", [5, 1], 5), step("multiply", [3, 1], 3), step("compare_equal", [5, 3], false)]),
        answer(false, "claim_verdict"),
        missing_doing("The problem contains grammatical errors where the quantity of liters per carton is omitted (e.g., 'contains liter'), making the specific numerical value of '1' an assumption.")),
    anchor(lesson('IM-G4-U3-L6'), grade('4'), record_id('im_defrag_77a44a6bb344e621137b306a_1'), statement_sha('9f384acaebd791a0ad5997df5d59a2e48ce38a506e44c19b06e5c178ee9c1a57')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_77bde1f499bf91dc6439546b_1', "A rectangular flower bed has a fence that measures 32 feet around. One side of the flower bed measures 12 feet. What are the lengths of the other sides?",
    analysis(
        quantities([quantity(32, "feet", "32 feet"), quantity(12, "feet", "12 feet")]),
        ask("What are the lengths of the other sides of the rectangular flower bed?"),
        steps([step("subtract", [32, 12], 20), step("subtract", [20, 12], 8), step("divide", [8, 2], 4)]),
        answer(4, "feet"),
        missing_doing("inferring the properties of a rectangle to determine that there are two sides of 12 feet and two sides of unknown length")),
    anchor(lesson('IM-G3-U7-L9'), grade('3'), record_id('im_defrag_77bde1f499bf91dc6439546b_1'), statement_sha('5186a8376782bb8f69c69ccfa68dbc6a519bf757b619586c0fc731ec2091c46b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_77e2acfafca735a5ae64dfc4_1', "A bear ate 3 blueberries. He ate 6 raspberries. How many berries did the bear eat?",
    analysis(
        quantities([quantity(3, "blueberries", "3 blueberries"), quantity(6, "raspberries", "6 raspberries")]),
        ask("How many total berries did the bear eat?"),
        steps([step("addition", [3, 6], 9)]),
        answer(9, "berries"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U5-L5'), grade('K'), record_id('im_defrag_77e2acfafca735a5ae64dfc4_1'), statement_sha('007986594607c0fe0ecb4183adca790e1563f3c376f3aafa82ff173d29dcb70e')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_78ba940da867b3e564f6432b_1', "Han spills 3 red counters and 6 yellow counters. How many counters did he spill in all? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(3, "red counters", "3 red counters"), quantity(6, "yellow counters", "6 yellow counters")]),
        ask("How many counters did Han spill in total?"),
        steps([step("addition", [3, 6], 9)]),
        answer(9, "counters"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L2'), grade('1'), record_id('im_defrag_78ba940da867b3e564f6432b_1'), statement_sha('92f459a39858cc870d11e5a8eda2a432bb8d1e2bed35270489846d86125ca070')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_78defbf7607ba33b4943307e_1', "Han collected 4 leaves at the park. Priya gave him 5 more leaves. How many leaves does Han have now? Show your thinking using objects, drawings, numbers, or words.",
    analysis(
        quantities([quantity(4, "leaves", "4 leaves"), quantity(5, "leaves", "5 more leaves")]),
        ask("How many leaves does Han have now?"),
        steps([step("addition", [4, 5], 9)]),
        answer(9, "leaves"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U4-L11'), grade('K'), record_id('im_defrag_78defbf7607ba33b4943307e_1'), statement_sha('94eaaef9e8029bbed352b4c46637381dab2b3e45efab00ef4b5e74c8306fe70c')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_78e84d6dad652189164c4487_1', "Jada went to the zoo with her family. They saw reptiles. They saw 8 snakes, 7 iguanas, and 5 turtles. How many reptiles did Jada’s family see? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(8, "snakes", "8 snakes"), quantity(7, "iguanas", "7 iguanas"), quantity(5, "turtles", "5 turtles")]),
        ask("How many reptiles did Jada’s family see in total?"),
        steps([step("addition", [8, 7], 15), step("addition", [15, 5], 20)]),
        answer(20, "reptiles"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L20'), grade('1'), record_id('im_defrag_78e84d6dad652189164c4487_1'), statement_sha('593aaef6875dbf3339c9e4939d6f47323333c841907ac4858404c588abb47059')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_7a4a4b382a0e2db74a2c5d20_1', "1. 2 rocks in Lin’s jar Lin put in 4 more. How many rocks now? 3 + 3 6- 2 2 + 4 2. 8 kids play. 3 leave. How many now? 8 + 3 3 - 3 8 - 3",
    analysis(
        quantities([quantity(2, "rocks", "2 rocks"), quantity(4, "rocks", "4 more")]),
        ask("How many rocks are in Lin's jar now?"),
        steps([step("addition", [2, 4], 6)]),
        answer(6, "rocks"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U4-L14'), grade('K'), record_id('im_defrag_7a4a4b382a0e2db74a2c5d20_1'), statement_sha('da2ff22de3f0223680cfb0c87e80b0775da10b2d9f3670e02d0e26e8ace7ae9e')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_7ac621039101056121e248c3_1', "The community soup kitchen has lots of volunteers who help serve food. They have 35 volunteers during the week. They have 56 volunteers on the weekend. How many volunteers do they have all together? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(35, "volunteers", "35 volunteers"), quantity(56, "volunteers", "56 volunteers")]),
        ask("How many volunteers does the community soup kitchen have in total?"),
        steps([step("addition", [35, 56], 91)]),
        answer(91, "volunteers"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U5-L12'), grade('1'), record_id('im_defrag_7ac621039101056121e248c3_1'), statement_sha('7d3cd98a0e141f8dd8ff084cda93fb28fad481bf94285a85780d818f90788c70')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_7b67028057cdea02b49a767f_1', "Diego has $67. Diego has $16 less than Mai. How much money does Mai have? Show your thinking. Write your final answer with the dollar sign ($). If it helps, use a diagram.",
    analysis(
        quantities([quantity(67, "dollars", "$67"), quantity(16, "dollars", "$16")]),
        ask("How much money does Mai have?"),
        steps([step("addition", [67, 16], 83)]),
        answer(83, "dollars"),
        missing_doing("modeling the relationship between Diego and Mai")),
    anchor(lesson('IM-G2-U6-L19'), grade('2'), record_id('im_defrag_7b67028057cdea02b49a767f_1'), statement_sha('582d0dbd6c71c4e880682e0250206ac13a821d6f1b621bde9249ead70b24fb20')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_7b8f4c502bcabf1d3ff8ce88_1', "24 = 10 + 14",
    analysis(
        quantities([quantity(24, "number", "24"), quantity(10, "number", "10"), quantity(14, "number", "14")]),
        ask("Is 24 equal to the sum of 10 and 14?"),
        steps([step("addition", [10, 14], 24), step("compare_equal", [24, 24], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U3-L12'), grade('2'), record_id('im_defrag_7b8f4c502bcabf1d3ff8ce88_1'), statement_sha('a950fe2b3c41f3641e00dc7d16c616279aa4bd96a66534f99e12be6738de321e')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_7c13efb65aee06028a62f74d_1', "Find the value of each quotient mentally. 6 ÷ 12",
    analysis(
        quantities([quantity(6, "number", "6"), quantity(12, "number", "12")]),
        ask("What is the value of the quotient of 6 divided by 12?"),
        steps([step("division", [6, 12], 0.5)]),
        answer(0.5, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L8'), grade('6'), record_id('im_defrag_7c13efb65aee06028a62f74d_1'), statement_sha('6ebfef081efc13bf66e371bbff56450b8df8c0623bbab1903a427af31343bd08')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_7ca4bb450890ef5a63b70c91_1', "Find the value of each expression mentally. 5,000 ÷ 5",
    analysis(
        quantities([quantity(5000, "number", "5,000"), quantity(5, "number", "5")]),
        ask("Find the value of the expression 5,000 divided by 5."),
        steps([step("division", [5000, 5], 1000)]),
        answer(1000, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U4-L1'), grade('6'), record_id('im_defrag_7ca4bb450890ef5a63b70c91_1'), statement_sha('e500d3163e556c8cdc70272e8e39f142bb5284e028256db4ef07f685953d75f5')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_7ccbd750b41012672c728913_1', "9 + 4 = 10 + 3",
    analysis(
        quantities([quantity(9, "number", "9"), quantity(4, "number", "4"), quantity(10, "number", "10"), quantity(3, "number", "3")]),
        ask("Check if 9 + 4 is equal to 10 + 3."),
        steps([step("addition", [9, 4], 13), step("addition", [10, 3], 13), step("compare_equal", [13, 13], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U1-L13'), grade('2'), record_id('im_defrag_7ccbd750b41012672c728913_1'), statement_sha('131dad0db86b77db945ced960ab39f0e914a2c6fac372b1e7ead36879d515892')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_7d35041b3c42fcd980918890_1', "1. Diego collected 72 seeds. 25 seeds are orange seeds. The rest are apple seeds. How many of Diego’s seeds are apple seeds? Circle the 2 equations that match this story problem. A. 25 + ? = 72 B. 72 + 25 = ? C. 72- 25 = ? D. ? + 72 = 25 2. Solve the problem. Show your thinking. Draw a diagram if it helps.",
    analysis(
        quantities([quantity(72, "seeds", "72 seeds"), quantity(25, "seeds", "25 seeds")]),
        ask("How many of Diego's seeds are apple seeds and which two equations match the story problem?"),
        steps([step("subtraction", [72, 25], 47)]),
        answer(47, "seeds"),
        missing_doing("multiple choice selection")),
    anchor(lesson('IM-G2-U2-L13'), grade('2'), record_id('im_defrag_7d35041b3c42fcd980918890_1'), statement_sha('8dda54d4f557f168fe51cc79049ecf3534c405f51f6b8a299303e0dac42f9433')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_7d47a7cbbd0d21c97f4adb21_1', "Lin has 30 apples. She makes 6 bags with the same number of apples in each bag to give to her friends. How many apples are in each bag? Explain or show your reasoning.",
    analysis(
        quantities([quantity(30, "apples", "30 apples"), quantity(6, "bags", "6 bags")]),
        ask("How many apples are in each bag?"),
        steps([step("division", [30, 6], 5)]),
        answer(5, "apples"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L2'), grade('3'), record_id('im_defrag_7d47a7cbbd0d21c97f4adb21_1'), statement_sha('60c1382b22daaf668f2d4790cd48c5377ee841c96b574e826e372f7de667f2c7')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_7d880b45533faaffc686bcee_1', "4 × 5 = 5 × 4",
    analysis(
        quantities([quantity(4, "number", "4"), quantity(5, "number", "5"), quantity(5, "number", "5"), quantity(4, "number", "4")]),
        ask("Check if 4 multiplied by 5 is equal to 5 multiplied by 4."),
        steps([step("multiplication", [4, 5], 20), step("multiplication", [5, 4], 20), step("compare_equal", [20, 20], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U3-L9'), grade('3'), record_id('im_defrag_7d880b45533faaffc686bcee_1'), statement_sha('4d21febd33befb26b8e81c9f7071dd489ab2a77f6809849f17dd919b1c5e1ba4')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_5.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_7da299b828df7703acd4b545_1', "If someone uses 400 liters of orange juice, how much soda water would they need? [scale factor: 4*?=400]",
    analysis(
        quantities([quantity(400, "liters", "400 liters"), quantity(4, "scale factor", "4")]),
        ask("How much soda water is needed if 400 liters of orange juice are used, given a scale factor of 4?"),
        steps([step("division", [400, 4], 100)]),
        answer(100, "liters"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L11'), grade('6'), record_id('im_defrag_7da299b828df7703acd4b545_1'), statement_sha('1b10e12ebb2bdaf88aa08a3ce4cba64d1648c08bb985413fc39a0e8194da0292')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_7daa60d6daa3c321715d9182_1', "4 + 2 = 2 + 4",
    analysis(
        quantities([quantity(4, "number", "4"), quantity(2, "number", "2"), quantity(2, "number", "2"), quantity(4, "number", "4")]),
        ask("Determine if 4 + 2 is equal to 2 + 4."),
        steps([step("addition", [4, 2], 6), step("addition", [2, 4], 6), step("compare_equal", [6, 6], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L3'), grade('1'), record_id('im_defrag_7daa60d6daa3c321715d9182_1'), statement_sha('004f712e1fbaaea7c2d516d935b4c4c3f914b5d67312d282507589ba76bcf10b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_7dc3abc134656e3d8140a575_1', "Clare counts 8 sharks swimming. Then some more sharks swim by. Clare counts 13 sharks all together. How many more sharks swim by? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(8, "sharks", "8 sharks"), quantity(13, "sharks", "13 sharks")]),
        ask("How many more sharks swam by after the initial 8 were counted?"),
        steps([step("subtraction", [13, 8], 5)]),
        answer(5, "sharks"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U8-L4'), grade('1'), record_id('im_defrag_7dc3abc134656e3d8140a575_1'), statement_sha('fb936016a1a4026f0b8aab85d5ee2870187841a1d1bb605b13c57623e7c6ea21')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_7dcf821eb54faacba75d23e8_1', "1. Represent 22- 5 = 17 on the number line. 2. Write an equation to show what’s represented on the number line.",
    analysis(
        quantities([quantity(22, "number", "22"), quantity(5, "number", "5"), quantity(17, "number", "17")]),
        ask("Represent the equation 22 - 5 = 17 on a number line and write an equation representing the number line."),
        steps([step("subtraction", [22, 5], 17), step("compare_equal", [17, 17], true)]),
        answer(true, "claim_verdict"),
        missing_doing("geometric representation")),
    anchor(lesson('IM-G2-U4-L8'), grade('2'), record_id('im_defrag_7dcf821eb54faacba75d23e8_1'), statement_sha('8635b115da5e99256c6630f3fbb17369a39a209d30c10187f6483507f74ee693')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_7e3d908175b84a70eb4c4ba0_1', "407 = 70 + 400",
    analysis(
        quantities([quantity(407, "number", "407"), quantity(70, "number", "70"), quantity(400, "number", "400")]),
        ask("Determine if 407 is equal to the sum of 70 and 400."),
        steps([step("addition", [70, 400], 470), step("compare_equal", [407, 470], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U5-L5'), grade('2'), record_id('im_defrag_7e3d908175b84a70eb4c4ba0_1'), statement_sha('061aadac02710c53e99808bce48d6c9f79346fe8c288321e540663b282c21962')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_7f5d61828f76372260b9781b_1', "Here is a diagram that represents 222 × 14. Find the value of 222 × 14. Use the diagram if it is helpful. Explain or show your reasoning.",
    analysis(
        quantities([quantity(222, "number", "222"), quantity(14, "number", "14")]),
        ask("What is the value of 222 multiplied by 14?"),
        steps([step("multiplication", [222, 10], 2220), step("multiplication", [222, 4], 888), step("addition", [2220, 888], 3108)]),
        answer(3108, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U4-L2'), grade('5'), record_id('im_defrag_7f5d61828f76372260b9781b_1'), statement_sha('c9b04e833882dd5fd1005b8b9c6ec40576888d0e83fbaa1a07e881a795268899')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_806d4c8ab0dafa1693bce22b_1', "At the kennel, the ratio of cats to dogs is 4:5. How many total parts (4+5)?",
    analysis(
        quantities([quantity(4, "cats", "4"), quantity(5, "dogs", "5")]),
        ask("What is the sum of the parts in the ratio 4:5?"),
        steps([step("addition", [4, 5], 9)]),
        answer(9, "total parts"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L15'), grade('6'), record_id('im_defrag_806d4c8ab0dafa1693bce22b_1'), statement_sha('ef6959b2211a5553b57f0e19e0d497c52a8bb84388b33c093aa6f91437283532')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_80a427aa9687269e438b6fce_1', "6 = 2 + 4",
    analysis(
        quantities([quantity(6, "number", "6"), quantity(2, "number", "2"), quantity(4, "number", "4")]),
        ask("Determine if the equation 6 = 2 + 4 is true."),
        steps([step("addition", [2, 4], 6), step("compare_equal", [6, 6], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U2-L19'), grade('1'), record_id('im_defrag_80a427aa9687269e438b6fce_1'), statement_sha('abf18a3bcdb4e37b099e915cc7c057c1cd642241cfc8ec2d24fa602f90263a96')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_80bc015ecec94fa00a14c075_1', "compare 681 and 618",
    analysis(
        quantities([quantity(681, "number", "681"), quantity(618, "number", "618")]),
        ask("Compare the numbers 681 and 618."),
        steps([step("compare_equal", [681, 618], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U5-L9'), grade('2'), record_id('im_defrag_80bc015ecec94fa00a14c075_1'), statement_sha('c152a4d6b7ca127899e13c0c6ccf0115103b0391223f81fa37278261ed33caf6')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_8132a8dd32dd8ae04c0f9988_1', "How many bottles does it take to hold 51 fluid ounces of water? 3 bottles, because 51 ÷ 17 = 3",
    analysis(
        quantities([quantity(51, "fluid ounces", "51 fluid ounces"), quantity(17, "fluid ounces per bottle", "17")]),
        ask("How many bottles are needed to hold 51 fluid ounces of water?"),
        steps([step("division", [51, 17], 3)]),
        answer(3, "bottles"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U2-L6'), grade('7'), record_id('im_defrag_8132a8dd32dd8ae04c0f9988_1'), statement_sha('926375821b2e67957bf85246646a53811d6121dbca22fbed7e74151d18c6b6bf')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_815ea0a405d57da70275d806_1', "Tyler and Clare want to know how many pets they have together. Tyler has 2 turtles. Clare has 4 dogs. Tyler writes 2 + 4. Clare writes 4 + 2. Who do you agree with? Show your thinking using objects, drawings, numbers, or words.",
    analysis(
        quantities([quantity(2, "turtles", "2 turtles"), quantity(4, "dogs", "4 dogs")]),
        ask("Determine if Tyler's expression (2 + 4) and Clare's expression (4 + 2) are both correct ways to find the total number of pets they have together."),
        steps([step("addition", [2, 4], 6), step("addition", [4, 2], 6), step("compare_equal", [6, 6], true)]),
        answer(true, "claim_verdict"),
        missing_doing("recognizing the commutative property of addition")),
    anchor(lesson('IM-G1-U2-L6'), grade('1'), record_id('im_defrag_815ea0a405d57da70275d806_1'), statement_sha('252f925cc880e4d9fbe53c07142ae4e2725a9aebb5cf523fff6f13c0ff0a001b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_817ee3ca7d3f48e936ee4c17_1', "Find the value of each quotient mentally. 30 ÷ 12",
    analysis(
        quantities([quantity(30, "number", "30"), quantity(12, "number", "12")]),
        ask("What is the value of 30 divided by 12?"),
        steps([step("division", [30, 12], 2.5)]),
        answer(2.5, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L8'), grade('6'), record_id('im_defrag_817ee3ca7d3f48e936ee4c17_1'), statement_sha('5e1752acabbc8de1ed6e02dbb7f2b80d821feee73b112aef3b2cb9ef29b71cfd')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_820e13ad49b1b9e0839636db_1', "5 crayons. Jada gave him 4 more. How many crayons does Noah have now?",
    analysis(
        quantities([quantity(5, "crayons", "5 crayons"), quantity(4, "crayons", "4 more")]),
        ask("How many crayons does Noah have now?"),
        steps([step("addition", [5, 4], 9)]),
        answer(9, "crayons"),
        missing_doing("inferring that 'him' refers to Noah")),
    anchor(lesson('IM-GK-U4-L8'), grade('K'), record_id('im_defrag_820e13ad49b1b9e0839636db_1'), statement_sha('7a15f1b5c94857ef3b9ba24d1d9c46677cfd8bc67da21f9823c39ddd882cff06')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_822e026ea9fc84f664eaadf6_1', "There are 8 glue sticks and 3 scissors at the art station. How many fewer scissors are there than glue sticks? Mai creates a picture.",
    analysis(
        quantities([quantity(8, "glue sticks", "8 glue sticks"), quantity(3, "scissors", "3 scissors")]),
        ask("How many fewer scissors are there than glue sticks?"),
        steps([step("-", [8, 3], 5)]),
        answer(5, "scissors"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U2-L18'), grade('1'), record_id('im_defrag_822e026ea9fc84f664eaadf6_1'), statement_sha('a13f7c0061351fe85791cb075999d448a359d278a1622d9b2af18d74841a604a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_8295e5af971d0d201b652bf3_1', "4 + 6 = 3 + 7",
    analysis(
        quantities([quantity(4, "number", "4"), quantity(6, "number", "6"), quantity(3, "number", "3"), quantity(7, "number", "7")]),
        ask("Determine if the sum of 4 and 6 is equal to the sum of 3 and 7."),
        steps([step("addition", [4, 6], 10), step("addition", [3, 7], 10), step("compare_equal", [10, 10], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L14'), grade('1'), record_id('im_defrag_8295e5af971d0d201b652bf3_1'), statement_sha('0a13b93f955230775d56493278c0e357d04b3be4c66f176347d9f64d4ac645a0')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_8383df19a6666a27fc99e215_1', "Here is an incomplete calculation of 534 ÷ 6. Write the missing numbers (marked with \"?\") that would make the calculation complete.",
    analysis(
        quantities([quantity(534, "number", "534"), quantity(6, "number", "6")]),
        ask("Identify the missing numbers marked with '?' that complete the division calculation of 534 divided by 6."),
        steps([step("division", [534, 6], 89)]),
        answer(89, "quotient"),
        missing_doing("pattern recognition of long division steps")),
    anchor(lesson('IM-G6-U5-L10'), grade('6'), record_id('im_defrag_8383df19a6666a27fc99e215_1'), statement_sha('fa50232c75fa4fba21dd1a2c85367f066e598187c6f27b058c4b4be939d8428e')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_84b897ec0b8c37673bf776cf_1', "4 + 2 = 6",
    analysis(
        quantities([quantity(4, "number", "4"), quantity(2, "number", "2"), quantity(6, "number", "6")]),
        ask("Is the equation 4 + 2 = 6 true?"),
        steps([step("addition", [4, 2], 6), step("compare_equal", [6, 6], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U1-L6'), grade('1'), record_id('im_defrag_84b897ec0b8c37673bf776cf_1'), statement_sha('5b9c07f5c6d48e880ffadf18e3f30817405a61789a07184ec66fa8e96750c1be')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_85db6b4838d90cee6eec8d99_1', "7,106 + 2,835",
    analysis(
        quantities([quantity(7106, "number", "7,106"), quantity(2835, "number", "2,835")]),
        ask("What is the sum of 7,106 and 2,835?"),
        steps([step("addition", [7106, 2835], 9941)]),
        answer(9941, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U4-L20'), grade('4'), record_id('im_defrag_85db6b4838d90cee6eec8d99_1'), statement_sha('ef211fba55ce341212ee662c45dbaf117a21b880c6dcfd14b8d68b9af8c3bfdc')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_85e00ddb00cd313ce20cc905_1', "Solve each equation mentally: c · 50 = 51",
    analysis(
        quantities([quantity(50, "multiplier", "50"), quantity(51, "product", "51")]),
        ask("What is the value of c in the equation c times 50 equals 51?"),
        steps([step("division", [51, 50], 1.02)]),
        answer(1.02, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U4-L8'), grade('7'), record_id('im_defrag_85e00ddb00cd313ce20cc905_1'), statement_sha('d5447ad8ddf7d62df26b2f01d9081387dbffee3d1c06bb5f5df0d4631f96762b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_860766965add2fab600c986c_1', "1. Solve 1 of the problems. Explain or show your reasoning. a. Jada has 326 beads. She gives her friend 32 beads. Then Jada uses 84 beads to make a bracelet. How many beads does Jada have now? b. Noah starts an art project on Monday by using 624 beads. On Tuesday, he uses 132 more beads. On Wednesday, he finishes the project by using 48 more beads. How many beads did Noah use on his art project? 2. Trade work with a partner. Decide whether your partner’s answer for their problem makes sense. On their paper, explain your reasoning.",
    analysis(
        quantities([quantity(326, "beads", "326 beads"), quantity(32, "beads", "32 beads"), quantity(84, "beads", "84 beads")]),
        ask("How many beads does Jada have left after giving some to her friend and using some for a bracelet?"),
        steps([step("subtraction", [326, 32], 294), step("subtraction", [294, 84], 210)]),
        answer(210, "beads"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U3-L17'), grade('3'), record_id('im_defrag_860766965add2fab600c986c_1'), statement_sha('6e6e831f526e89e50116bd4ca673d6464e018f0e87036640fca92f38c289960a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_86626791a78bd61a437e4d19_1', "Each student counted and showed a collection. • Clare drew • Han drew • Kiran wrote 3 ones and 7 tens. • Priya wrote 70 + 3. Did the students count the same number of objects? How do you know? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(3, "ones", "3 ones"), quantity(7, "tens", "7 tens"), quantity(70, "value", "70"), quantity(3, "value", "3")]),
        ask("Did the students count the same number of objects?"),
        steps([step("multiplication", [7, 10], 70), step("addition", [70, 3], 73), step("addition", [70, 3], 73), step("compare_equal", [73, 73], true)]),
        answer(true, "claim_verdict"),
        missing_doing("The problem is incomplete as it does not provide the quantities for Clare and Han, making it impossible to verify if all students counted the same number.")),
    anchor(lesson('IM-G1-U4-L8'), grade('1'), record_id('im_defrag_86626791a78bd61a437e4d19_1'), statement_sha('5146f8950435b4110fe4fd9a10b5619a24044d86026bc05a90063b7577351485')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_8722a0e06bef7d1349796a76_1', "Are You Ready for More: 9 teaspoons of garlic powder used for the 1 part, so each part is how much?",
    analysis(
        quantities([quantity(9, "teaspoons", "9 teaspoons"), quantity(1, "part", "1 part")]),
        ask("If 9 teaspoons of garlic powder are used for 1 part, how much is in each part?"),
        steps([step("division", [9, 1], 9)]),
        answer(9, "teaspoons"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L15'), grade('6'), record_id('im_defrag_8722a0e06bef7d1349796a76_1'), statement_sha('2aedefb4e4b99773d069d541ae9b66abb5fe4bf31834fbfe38bea0b77d65c250')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_873d80420cd12048b12ae753_1', "Find the value of 354 + 75. Show your thinking.",
    analysis(
        quantities([quantity(354, "number", "354"), quantity(75, "number", "75")]),
        ask("What is the value of 354 + 75?"),
        steps([step("addition", [354, 75], 429)]),
        answer(429, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U7-L7'), grade('2'), record_id('im_defrag_873d80420cd12048b12ae753_1'), statement_sha('217626a790f0fbd8ba93f8127f94fe8fc9ce14372095dbf7d793283eba0981be')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_3.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_87508e6e829759a8f09ab710_1', "5 + 3 = 1 + 7",
    analysis(
        quantities([quantity(5, "number", "5"), quantity(3, "number", "3"), quantity(1, "number", "1"), quantity(7, "number", "7")]),
        ask("Check if 5 + 3 is equal to 1 + 7."),
        steps([step("addition", [5, 3], 8), step("addition", [1, 7], 8), step("compare_equal", [8, 8], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L3'), grade('1'), record_id('im_defrag_87508e6e829759a8f09ab710_1'), statement_sha('8204429bb5f78265a474323f61cf49c67ec69dd6c659c0e6ccc00243eeaa0eee')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_4.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_877f7451aa5bab6959f526b2_1', "Find the value of 8 + 57. Write equations to show how you found the value.",
    analysis(
        quantities([quantity(8, "number", "8"), quantity(57, "number", "57")]),
        ask("What is the value of 8 + 57?"),
        steps([step("addition", [8, 57], 65)]),
        answer(65, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U5-L7'), grade('1'), record_id('im_defrag_877f7451aa5bab6959f526b2_1'), statement_sha('eb145fff3d9e54b09a681c6e08616f6c6be8abd5884063167a6ba9dc805cc8c5')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_87defed0a0ee6470e1438464_1', "4 rolls of toilet paper for $2. How much is the cost per roll?",
    analysis(
        quantities([quantity(4, "rolls", "4 rolls"), quantity(2, "dollars", "$2")]),
        ask("What is the cost of one roll of toilet paper?"),
        steps([step("division", [2, 4], 0.5)]),
        answer(0.5, "dollars per roll"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L8'), grade('6'), record_id('im_defrag_87defed0a0ee6470e1438464_1'), statement_sha('ee7ff5b6423d76c83c868c423dfec35e2a136f6ab367c01b831b3b47b5ee08ff')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_88933e47189fe83a772cbcb7_1', "Clare leaves school at 3:25 p.m. Her soccer practice begins at 4:15 p.m. How much time does she have between school and practice? Explain or show your reasoning.",
    analysis(
        quantities([quantity(3, "hour", "3"), quantity(25, "minute", "25"), quantity(4, "hour", "4"), quantity(15, "minute", "15")]),
        ask("How much time does Clare have between leaving school at 3:25 p.m. and the start of soccer practice at 4:15 p.m.?"),
        steps([step("subtract", [60, 25], 35), step("add", [35, 15], 50)]),
        answer(50, "minute"),
        missing_doing("time_interval_calculation")),
    anchor(lesson('IM-G3-U6-L10'), grade('3'), record_id('im_defrag_88933e47189fe83a772cbcb7_1'), statement_sha('5c882157354f1ffb23f2909072cdb1c4345d4823d404b9c7a6547bdaa3512bf8')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_894d0dd63d030293ac6d1e5e_1', "5 books are on the table. 2 of the books fall on the floor. How many books are still on the table? Show your thinking using objects, drawings, numbers, or words.",
    analysis(
        quantities([quantity(5, "books", "5 books"), quantity(2, "books", "2 of the books")]),
        ask("How many books remain on the table?"),
        steps([step("subtraction", [5, 2], 3)]),
        answer(3, "books"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U2-L1'), grade('1'), record_id('im_defrag_894d0dd63d030293ac6d1e5e_1'), statement_sha('c2cc5466d7f770c5ba54f72c9d12a197b808d854f078c968abee8d01d62f407c')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_898290f9a1ea47b88852e220_1', "20 + 6 = 6 + 30",
    analysis(
        quantities([quantity(20, "number", "20"), quantity(6, "number", "6"), quantity(6, "number", "6"), quantity(30, "number", "30")]),
        ask("Determine if the equation 20 + 6 = 6 + 30 is true."),
        steps([step("addition", [20, 6], 26), step("addition", [6, 30], 36), step("compare_equal", [26, 36], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U4-L11'), grade('1'), record_id('im_defrag_898290f9a1ea47b88852e220_1'), statement_sha('b3a5491272d97260fee8076435d1c1f2ff0f75191a3326cb80c83cfcf8b399d6')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_89ee2b5e4ddf06621ceaffee_1', "7 kids play soccer in the park. 3 kids leave to go play on the swings. How many now?",
    analysis(
        quantities([quantity(7, "kids", "7 kids"), quantity(3, "kids", "3 kids")]),
        ask("How many kids are playing soccer in the park now?"),
        steps([step("subtraction", [7, 3], 4)]),
        answer(4, "kids"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U4-L11'), grade('K'), record_id('im_defrag_89ee2b5e4ddf06621ceaffee_1'), statement_sha('98fbe75529965b420172488e4ca3f653403d71e167608283bd0074c673467a78')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_8a0aeba02e6889a14057788b_1', "Find the numbers that make each equation true. 1. 638 = ____________ ones + ____________ hundreds + ____________ tens 2. 7 tens + 2 ones + 4 hundreds = ____________",
    analysis(
        quantities([quantity(7, "tens", "7 tens"), quantity(2, "ones", "2 ones"), quantity(4, "hundreds", "4 hundreds")]),
        ask("What is the sum of 7 tens, 2 ones, and 4 hundreds?"),
        steps([step("multiply", [7, 10], 70), step("multiply", [2, 1], 2), step("multiply", [4, 100], 400), step("add", [70, 2, 400], 472)]),
        answer(472, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U5-L4'), grade('2'), record_id('im_defrag_8a0aeba02e6889a14057788b_1'), statement_sha('cf700f38731a5fc8e80cd9d4821be5a660f865a6296ea56c10ece11e15d0cc5a')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_5.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_8a11fe287923cf1eb16528a4_1', "Han ran 12,500 meters last week. How many kilometers is that? Explain or show your reasoning.",
    analysis(
        quantities([quantity(12500, "meters", "12,500 meters")]),
        ask("How many kilometers is 12,500 meters?"),
        steps([step("division", [12500, 1000], 12.5)]),
        answer(12.5, "kilometers"),
        missing_doing("unit conversion")),
    anchor(lesson('IM-G5-U6-L4'), grade('5'), record_id('im_defrag_8a11fe287923cf1eb16528a4_1'), statement_sha('5097273c0771231e6161ed6000953095f9cc6b18cb71c1b0390bb8361a34cecc')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_8a6223b59bae159dca28699d_1', "Find the value of 465 ÷ 15. Explain or show your reasoning.",
    analysis(
        quantities([quantity(465, "dividend", "465"), quantity(15, "divisor", "15")]),
        ask("What is the value of 465 divided by 15?"),
        steps([step("division", [465, 15], 31)]),
        answer(31, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U4-L10'), grade('5'), record_id('im_defrag_8a6223b59bae159dca28699d_1'), statement_sha('447444e638cc941dbbf5b6d6ee1a070ad183627698fa6c1b65ccfb9f8d277ae6')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_8b021efa3eb556d25e4a3c75_1', "Clare and Andre both do chores on weekends. 1. Each month, Clare spends 6 hours on chores. How many minutes does Clare spend on chores each month? 2. Andre says, “I spend about 400 minutes on chores each month, which is about 8 hours.” Do you agree that Andre spends 8 hours on chores? Explain your reasoning.",
    analysis(
        quantities([quantity(6, "hours", "6 hours"), quantity(400, "minutes", "400 minutes"), quantity(8, "hours", "8 hours")]),
        ask("How many minutes does Clare spend on chores each month, and do you agree with Andre's claim that 400 minutes is about 8 hours?"),
        steps([step("multiply", [6, 60], 360), step("multiply", [8, 60], 480), step("subtract", [480, 400], 80), step("compare_equal", [400, 480], false)]),
        answer(false, "claim_verdict"),
        missing_doing("evaluating the reasonableness of an approximation")),
    anchor(lesson('IM-G4-U5-L12'), grade('4'), record_id('im_defrag_8b021efa3eb556d25e4a3c75_1'), statement_sha('1d8252ff230c8437947e0c9f6ed1a69760d354dd3ee8d10222339e905a098886')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_3.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_8c5a2b3a95e4ec6f44ae8e68_1', "Train B: distance traveled 0 to 100 meters, elapsed time 0 to 4 seconds. Which train is traveling faster?",
    analysis(
        quantities([quantity(100, "meters", "100 meters"), quantity(4, "seconds", "4 seconds")]),
        ask("What is the speed of Train B and how does it compare to Train A to determine which is faster?"),
        steps([step("division", [100, 4], 25)]),
        answer(25, "meters per second"),
        missing_doing("comparison with Train A")),
    anchor(lesson('IM-G6-U2-L9'), grade('6'), record_id('im_defrag_8c5a2b3a95e4ec6f44ae8e68_1'), statement_sha('39ecb439433cf4c509f933afe81630b13c583a3ad17b03be961e48e4b9570847')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_5.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_8c610468155925de2e2f54e4_1', "Find the value of 23 + 68. Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(23, "number", "23"), quantity(68, "number", "68")]),
        ask("Find the value of 23 + 68."),
        steps([step("addition", [23, 68], 91)]),
        answer(91, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U5-L11'), grade('1'), record_id('im_defrag_8c610468155925de2e2f54e4_1'), statement_sha('f6f8e80058675fdea4e25d51814540c3b74bba126a3c321931933aeb8eccb4b7')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_0.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_8cd091ac7f2def71e74bfc39_1', "Fill in the missing numbers. [table] transaction 3 amount 90, applied to running balance 53 (from transaction 2). New balance?",
    analysis(
        quantities([quantity(90, "amount", "90"), quantity(53, "running balance", "53")]),
        ask("What is the new balance after applying a transaction amount of 90 to a running balance of 53?"),
        steps([step("addition", [53, 90], 143)]),
        answer(143, "new balance"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U5-L4'), grade('7'), record_id('im_defrag_8cd091ac7f2def71e74bfc39_1'), statement_sha('bb44dfb7aa4b8b87373237fc200ad6ce6061b455f1967288b9ff72be22aa2ac7')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_8ce361d9e68d672eea9885f8_1', "Clare says 15. Andre says 16. Noah says 17. Can they all be right?",
    analysis(
        quantities([quantity(15, "number", "15"), quantity(16, "number", "16"), quantity(17, "number", "17")]),
        ask("Can the three different values provided by Clare, Andre, and Noah all be correct at the same time?"),
        steps([step("compare_equal", [15, 16], false), step("compare_equal", [16, 17], false), step("compare_equal", [15, 17], false)]),
        answer(false, "claim_verdict"),
        missing_doing("determining logical consistency")),
    anchor(lesson('IM-GK-U6-L3'), grade('K'), record_id('im_defrag_8ce361d9e68d672eea9885f8_1'), statement_sha('9004d8d157ff6eddaad0a8811f696c7ced3ac3968e7c85292d8e2cfdb07f1866')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_2.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_8d3cb6b8e6ba56dc93de61f9_1', "So far, he has 14 rocks. He gets 3 more.",
    analysis(
        quantities([quantity(14, "rocks", "14 rocks"), quantity(3, "rocks", "3 more")]),
        ask("How many rocks does he have now?"),
        steps([step("addition", [14, 3], 17)]),
        answer(17, "rocks"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L11'), grade('1'), record_id('im_defrag_8d3cb6b8e6ba56dc93de61f9_1'), statement_sha('9354abe7c9e25bced6352350306513cb8d4d7fdc0800ef4340f1071f0ed73ce4')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_8d6388ca9d17714715aca434_1', "An art teacher and a kindergarten teacher are getting clay from the craft store. The art teacher buys 6 pounds of clay. This amount is 4 times as much clay as what the kindergarten teacher buys. How many ounces of clay do the two teachers buy all together? Explain or show your reasoning.",
    analysis(
        quantities([quantity(6, "pounds", "6 pounds"), quantity(4, "times", "4 times as much")]),
        ask("How many total ounces of clay did both teachers buy combined?"),
        steps([step("division", [6, 4], 1.5), step("multiplication", [1.5, 16], 24), step("multiplication", [6, 16], 96), step("addition", [96, 24], 120)]),
        answer(120, "ounces"),
        missing_doing("unit conversion")),
    anchor(lesson('IM-G4-U5-L14'), grade('4'), record_id('im_defrag_8d6388ca9d17714715aca434_1'), statement_sha('346461d3794b14c366a2b71d53e2607a39e739166ee31152a9639cfe57164ddc')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_8d798a8dd1bc47f8207abf03_1', "Clare is paid $90 for 5 hours of work. At this rate, how many seconds does it take for her to earn 25 cents?",
    analysis(
        quantities([quantity(90, "dollars", "$90"), quantity(5, "hours", "5 hours"), quantity(25, "cents", "25 cents")]),
        ask("How many seconds does it take Clare to earn 25 cents at her given rate of pay?"),
        steps([step("multiply", [90, 100], 9000), step("multiply", [5, 3600], 18000), step("divide", [9000, 18000], 0.5), step("divide", [25, 0.5], 50)]),
        answer(50, "seconds"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L12'), grade('6'), record_id('im_defrag_8d798a8dd1bc47f8207abf03_1'), statement_sha('670034b966efb7de2bedc72ec80ee49e0d22e21b2209283427a902a1ab09aa86')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_8d7c8444dab292ebfc49dc88_1', "Write ... a division equation that this diagram could represent. [54 over three segments labeled 18, 18, 18]",
    analysis(
        quantities([quantity(54, "total", "54"), quantity(3, "segments", "three segments"), quantity(18, "segment value", "18")]),
        ask("What division equation represents a diagram showing a total of 54 divided into three segments of 18?"),
        steps([step("divide", [54, 3], 18)]),
        answer(18, "segment value"),
        missing_doing("formulate_equation")),
    anchor(lesson('IM-G6-U4-L3'), grade('6'), record_id('im_defrag_8d7c8444dab292ebfc49dc88_1'), statement_sha('6984834e26c55a0451f4ff6568bfb317408f109b2d90bbb44008892fb1b1b1ce')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_8dd7788082581315d61ab490_1', "Find the value of 2,617 × 4. Show your reasoning.",
    analysis(
        quantities([quantity(2617, "number", "2,617"), quantity(4, "number", "4")]),
        ask("Find the value of 2,617 × 4."),
        steps([step("multiplication", [2617, 4], 10468)]),
        answer(10468, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U9-L5'), grade('4'), record_id('im_defrag_8dd7788082581315d61ab490_1'), statement_sha('8757fd0617a151606345fb185412929cda368296fbf16157d37bed41f7fda8e6')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_2.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_8f010cbab93cf9e6303136bc_1', "7,180 + 3,920 = 10,100",
    analysis(
        quantities([quantity(7180, "number", "7,180"), quantity(3920, "number", "3,920"), quantity(10100, "number", "10,100")]),
        ask("Is the sum of 7,180 and 3,920 equal to 10,100?"),
        steps([step("addition", [7180, 3920], 11100), step("compare_equal", [11100, 10100], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U4-L22'), grade('4'), record_id('im_defrag_8f010cbab93cf9e6303136bc_1'), statement_sha('2d8a4404a45b76778b9652482b2cd85aadf99a3501bf987a8e6e9c7f372d30db')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_8f0e6efd295873140b0affa6_1', "1. Lin's pet lizard is 62 cm long. It is 19 cm shorter than Jada's. How long is Jada's pet lizard? a. Whose pet is longer? ________________________________ b. Circle the diagram that matches the story. c. Solve. Show your thinking using drawings, numbers, or words. Jada’s pet lizard is ____________ cm long. 2. Diego and Mai have pet snakes. Mai’s pet snake is 17 cm longer than Diego’s. Her snake is 71 cm. How long is his pet snake? a. Whose pet is shorter? ________________________________ b. Circle the diagram that matches the story. c. Solve. Show your thinking using drawings, numbers, or words. Diego’s pet snake is ____________ cm long.",
    analysis(
        quantities([quantity(62, "cm", "62 cm"), quantity(19, "cm", "19 cm")]),
        ask("How long is Jada's pet lizard?"),
        steps([step("addition", [62, 19], 81)]),
        answer(81, "cm"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U3-L6'), grade('2'), record_id('im_defrag_8f0e6efd295873140b0affa6_1'), statement_sha('d0a8b9ec4efed59d3f2d3a7cf7e2dbc65ac97c64f6e66a352b5b3b81e0c07e06')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_8f5afd57712b1126f12ad1fa_1', "A worker packs 36 apples in 6 boxes. He packs the same number of apples in each box. How many apples are in each box?",
    analysis(
        quantities([quantity(36, "apples", "36 apples"), quantity(6, "boxes", "6 boxes")]),
        ask("How many apples are in each box if the same number of apples are packed in each of the 6 boxes?"),
        steps([step("division", [36, 6], 6)]),
        answer(6, "apples"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L2'), grade('3'), record_id('im_defrag_8f5afd57712b1126f12ad1fa_1'), statement_sha('e19bb4c39829d617fae855ccd261d7fd1d647ec4f42502df61e9d7155c9f86f7')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_8f5edcc9638fce32b64ab940_1', "Tyler ran 4,200 meters in 30 minutes. At what rate did he run?",
    analysis(
        quantities([quantity(4200, "meters", "4,200 meters"), quantity(30, "minutes", "30 minutes")]),
        ask("At what rate did Tyler run in meters per minute?"),
        steps([step("division", [4200, 30], 140)]),
        answer(140, "meters per minute"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U3-L4'), grade('6'), record_id('im_defrag_8f5edcc9638fce32b64ab940_1'), statement_sha('25dcde4b3ae254771f5e2f953551532a8d79c659d4f0874c25f42dd41a08ec00')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_8fa63a723b4f9551f408bc79_1', "Here’s another problem about time: At 6:32 p.m., Elena got on a bus to go home. She got off the bus at 7:10 p.m. How long was her bus ride? Which strategy or representation would you use when solving a problem like this? Explain your reasoning.",
    analysis(
        quantities([quantity(6, "hour", "6"), quantity(32, "minute", "32"), quantity(7, "hour", "7"), quantity(10, "minute", "10")]),
        ask("How long was Elena's bus ride from 6:32 p.m. to 7:10 p.m.?"),
        steps([step("subtract", [60, 32], 28), step("add", [28, 10], 38)]),
        answer(38, "minute"),
        missing_doing("modeling elapsed time across an hour boundary")),
    anchor(lesson('IM-G3-U6-L10'), grade('3'), record_id('im_defrag_8fa63a723b4f9551f408bc79_1'), statement_sha('9b97dad20c82bc84c6007a8919b5abcacc054f68ee5517f49f5343bf4ab88a7a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_8fd94269d16927b8f5428f5e_1', "Mai has 3 books. She gets some more books from the library. Now she has 7. How many more books did Mai get? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(3, "books", "3 books"), quantity(7, "books", "7")]),
        ask("How many more books did Mai get from the library?"),
        steps([step("subtraction", [7, 3], 4)]),
        answer(4, "books"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U2-L4'), grade('1'), record_id('im_defrag_8fd94269d16927b8f5428f5e_1'), statement_sha('b8cb93906e36be75ec4ef82c07b8505f76c93a8e53fb3e50f6a7724a999f790f')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_900ec019f02e22895b9f1f84_1', "1. Jada and Priya created rules for patterns. Complete each table with the first 10 numbers of their pattern. Jada’s rule: Start with 0 and add 3. Priya’s rule: Start with 0 and add 4. 2. Kiran says that when Jada’s number is 45, Priya’s corresponding number will be 90. Do you agree? Why or why not?",
    analysis(
        quantities([quantity(0, "start number", "0"), quantity(3, "increment", "3"), quantity(0, "start number", "0"), quantity(4, "increment", "4"), quantity(45, "Jada's number", "45"), quantity(90, "Priya's number", "90")]),
        ask("Do you agree with Kiran's claim that when Jada's number is 45, Priya's corresponding number will be 90?"),
        steps([step("divide", [45, 3], 15), step("multiply", [15, 4], 60), step("compare_equal", [60, 90], false)]),
        answer(false, "claim_verdict"),
        missing_doing("modeling the relationship between two arithmetic sequences")),
    anchor(lesson('IM-G5-U7-L10'), grade('5'), record_id('im_defrag_900ec019f02e22895b9f1f84_1'), statement_sha('7c0a687daaa5446d4522d2cccbccee7bb2e8a830b7614e8380a0e0889dbbe2a0')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_90262a448b3a62443e81ea3c_1', "Find the value of 4² / 2",
    analysis(
        quantities([quantity(4, "number", "4"), quantity(2, "number", "2")]),
        ask("What is the value of 4 squared divided by 2?"),
        steps([step("exponentiation", [4, 2], 16), step("division", [16, 2], 8)]),
        answer(8, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U7-L5'), grade('6'), record_id('im_defrag_90262a448b3a62443e81ea3c_1'), statement_sha('e87666be55ec35077b8699b031ef0dd190845dba28a1b290614ddf81cc9a7594')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_9049d1f7a41be1710a21b0a5_1', "Priya and Tyler play a game with seeds. Priya starts with 22 seeds. She captures 7 seeds in the first round. Then she captures 18 more seeds in the second round. How many seeds does she have now? Solve the problem in any way that makes sense to you. Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(22, "seeds", "22 seeds"), quantity(7, "seeds", "7 seeds"), quantity(18, "seeds", "18 more seeds")]),
        ask("How many seeds does Priya have now?"),
        steps([step("addition", [22, 7], 29), step("addition", [29, 18], 47)]),
        answer(47, "seeds"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U2-L14'), grade('2'), record_id('im_defrag_9049d1f7a41be1710a21b0a5_1'), statement_sha('0292af4125dc6e2f0c30997c91e3532b630a39e9f55d5c219bc0ad1d1e2562a4')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_904baaa321cb32052cee1323_1', "A triangle weighs 3 grams, and a circle weighs 6 grams. 1. Write an equation to represent the hanger. 2. Find the weight of a square in the hanger. Show or explain your reasoning.",
    analysis(
        quantities([quantity(3, "grams", "3 grams"), quantity(6, "grams", "6 grams")]),
        ask("Find the weight of a square in the hanger, assuming the hanger is balanced."),
        steps([step("subtract", [6, 3], 3)]),
        answer(3, "grams"),
        missing_doing("inferring the physical state of equilibrium from the context of a hanger")),
    anchor(lesson('IM-G8-U4-L2'), grade('8'), record_id('im_defrag_904baaa321cb32052cee1323_1'), statement_sha('5a741b18c977e5a72303a7b7d6d332fd08525c03f80e7ed4def5aeda20034827')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_90c7921fd32f48956bc91859_1', "1. Lin and Han ran a 5 mile relay race as a team. They each ran the same distance. Draw a diagram to represent the situation. 2. How far did each student run?",
    analysis(
        quantities([quantity(5, "mile", "5 mile")]),
        ask("How far did each student run?"),
        steps([step("division", [5, 2], 2.5)]),
        answer(2.5, "mile"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U2-L6'), grade('5'), record_id('im_defrag_90c7921fd32f48956bc91859_1'), statement_sha('42aff4b258d7e026bccb67f34a23342890e63213b0958ddac2630b25988582ca')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_2.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_90e122569285a9056ba00553_1', "What is the cost of kitchen plumbing and 18 square feet of tile? Explain your reasoning. item cost flooring: tile $5 for each square foot wood $4 for each square foot carpet $2 for each square foot $25 for each gallon paint (up to 400 square feet) bathroom plumbing $379 toilet $138 bathroom sink and faucet $112 kitchen plumbing $253 kitchen sink and faucet $227 cabinets $90 for each foot shelving $20 for each foot item cost Prices vary. dishes, cups, forks, spoons, etc. Research or estimate cost. dishwasher $389 portable stove $174 Prices vary. furniture Research or estimate cost. compact washer- $225 dryer combination bed $189",
    analysis(
        quantities([quantity(18, "square feet", "18 square feet"), quantity(5, "dollars per square foot", "tile $5 for each square foot"), quantity(253, "dollars", "kitchen plumbing $253")]),
        ask("What is the total cost of kitchen plumbing and 18 square feet of tile?"),
        steps([step("multiplication", [18, 5], 90), step("addition", [253, 90], 343)]),
        answer(343, "dollars"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U8-L5'), grade('3'), record_id('im_defrag_90e122569285a9056ba00553_1'), statement_sha('afd0a3072e3c7c6599c2f607800b616098ec481ddf9d5a96c4ef9429f8f42c5c')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_9143218bc1683ec225a34c47_1', "There are 5 pencils. There are 8 markers. Are there more pencils or markers? How many more? Show your thinking using objects, drawings, numbers, or words.",
    analysis(
        quantities([quantity(5, "pencils", "5 pencils"), quantity(8, "markers", "8 markers")]),
        ask("Which are more numerous, pencils or markers, and what is the difference between them?"),
        steps([step("subtraction", [8, 5], 3)]),
        answer(3, "markers"),
        missing_doing("comparing quantities")),
    anchor(lesson('IM-G1-U2-L12'), grade('1'), record_id('im_defrag_9143218bc1683ec225a34c47_1'), statement_sha('ed15e9d0e3da8156aabcbe117cbd7734a71187fc4f7295ba20f35df20920820b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_9169465e0e21de975d8879c3_1', "Use the standard algorithm to find the product 372 × 83.",
    analysis(
        quantities([quantity(372, "number", "372"), quantity(83, "number", "83")]),
        ask("What is the product of 372 and 83 using the standard algorithm?"),
        steps([step("multiply", [372, 3], 1116), step("multiply", [372, 80], 29760), step("add", [1116, 29760], 30876)]),
        answer(30876, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U4-L7'), grade('5'), record_id('im_defrag_9169465e0e21de975d8879c3_1'), statement_sha('963a09348b9eb54c3bbe5c65331d64e78512971036401578e48b13f44abdc8dd')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_919b6e85a20c5cb563c81a3f_1', "15 - 2 = 13 - 0",
    analysis(
        quantities([quantity(15, "number", "15"), quantity(2, "number", "2"), quantity(13, "number", "13"), quantity(0, "number", "0")]),
        ask("Check if 15 minus 2 is equal to 13 minus 0."),
        steps([step("subtraction", [15, 2], 13), step("subtraction", [13, 0], 13), step("compare_equal", [13, 13], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U3-L10'), grade('2'), record_id('im_defrag_919b6e85a20c5cb563c81a3f_1'), statement_sha('e0edd3b75bfe1441aad62ed475fd0a3b11a31f25432e74ab673aa9a39855adae')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_92a4d29f9984ff15f3d8f461_1', "On the coordinate plane shown, one line shows combinations of dimes and quarters that are worth $3. The other line shows combinations of dimes and quarters that total to 12 coins. 1. Name one combination of 12 coins shown on the graph. How does the graph show that the combination is true? 2. Name one combination of coins shown on the graph that total to $3. 3. How many quarters and dimes would you need to have both 12 coins and $3 at the same time? How does the graph show that this is true?",
    analysis(
        quantities([quantity(3, "dollars", "$3"), quantity(12, "coins", "12 coins")]),
        ask("How many quarters and dimes would you need to have both 12 coins and $3 at the same time?"),
        steps([step("multiply", [0.1, 12], 1.2), step("subtract", [3, 1.2], 1.8), step("subtract", [0.25, 0.1], 0.15), step("divide", [1.8, 0.15], 12), step("subtract", [12, 12], 0)]),
        answer(12, "quarters and 0 dimes"),
        missing_doing("solving_system_of_equations")),
    anchor(lesson('IM-G8-U4-L10'), grade('8'), record_id('im_defrag_92a4d29f9984ff15f3d8f461_1'), statement_sha('96856aca32a89fe588d7017462c0f9a9a5c3349205f320a279290eca456055ff')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/reallms_g68.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_9314ba7e5e54721580f1f293_1', "3 × 50 = 15 × 10",
    analysis(
        quantities([quantity(3, "number", "3"), quantity(50, "number", "50"), quantity(15, "number", "15"), quantity(10, "number", "10")]),
        ask("Is 3 multiplied by 50 equal to 15 multiplied by 10?"),
        steps([step("multiplication", [3, 50], 150), step("multiplication", [15, 10], 150), step("compare_equal", [150, 150], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L17'), grade('3'), record_id('im_defrag_9314ba7e5e54721580f1f293_1'), statement_sha('20e36bfe08c90347d758266489959b8c3aa13e107a680c36b69c58ada0e5958d')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_4.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_935c3b0731fa52883d86d9a9_1', "How far is 10% of a 2,000-kilometer trip? b.",
    analysis(
        quantities([quantity(10, "percent", "10%"), quantity(2000, "kilometers", "2,000-kilometer")]),
        ask("How far is 10% of a 2,000-kilometer trip?"),
        steps([step("multiply", [0.1, 2000], 200)]),
        answer(200, "kilometers"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U3-L13'), grade('6'), record_id('im_defrag_935c3b0731fa52883d86d9a9_1'), statement_sha('71aa573d6fdadde4f1afa4f9de6d6f8ab1e4c24e00c704b5adea82e9bf34d0ec')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_946636a67f8259392d0adadf_1', "How many milliliters are in 3 gallons? 3,785 times 3 = 11,355",
    analysis(
        quantities([quantity(3, "gallons", "3 gallons"), quantity(3785, "milliliters per gallon", "3,785")]),
        ask("How many milliliters are in 3 gallons?"),
        steps([step("multiply", [3785, 3], 11355)]),
        answer(11355, "milliliters"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U3-L3'), grade('6'), record_id('im_defrag_946636a67f8259392d0adadf_1'), statement_sha('5689311018e143bb240f88bc1a2ec8abfde0dc2a109091bb53f503e6ad436d3c')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_95389f41c3335e10ae72b7e1_1', "Are You Ready for More: 32 teaspoons of chili powder used for the 4 parts, so each part is how much?",
    analysis(
        quantities([quantity(32, "teaspoons", "32 teaspoons"), quantity(4, "parts", "4 parts")]),
        ask("How many teaspoons of chili powder are in each of the 4 parts if 32 teaspoons are used in total?"),
        steps([step("division", [32, 4], 8)]),
        answer(8, "teaspoons"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L15'), grade('6'), record_id('im_defrag_95389f41c3335e10ae72b7e1_1'), statement_sha('907329e8d93ae58ad388ada575e518eabaeb2777b43ac6be0190c93493ec2f87')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_958de7cb83e704f33216501c_1', "Solve each equation mentally: c + 389 = 721",
    analysis(
        quantities([quantity(389, "number", "389"), quantity(721, "number", "721")]),
        ask("Find the value of c in the equation c + 389 = 721."),
        steps([step("subtraction", [721, 389], 332)]),
        answer(332, "number"),
        missing_doing("algebraic manipulation")),
    anchor(lesson('IM-G7-U5-L6'), grade('7'), record_id('im_defrag_958de7cb83e704f33216501c_1'), statement_sha('21fa2bff1a9d62b87c1fc7b2cd9116106e86614a9a652c90f15abaddf8d292ca')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_95dbaba7631bba76ef1620e2_1', "9 books are on a cart. The librarian takes 2 of the books. How many books are still on the cart? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(9, "books", "9 books"), quantity(2, "books", "2 of the books")]),
        ask("How many books are still on the cart?"),
        steps([step("subtraction", [9, 2], 7)]),
        answer(7, "books"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U2-L2'), grade('1'), record_id('im_defrag_95dbaba7631bba76ef1620e2_1'), statement_sha('b62c461e6f64b4d2fcf70403727a90419400242948ada05291e06eab752ca19f')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_95e6836c2e770aa507544dfc_1', "Elena has 12 colored pencils. She has 2 boxes and wants to put the same number of colored pencils in each box.",
    analysis(
        quantities([quantity(12, "colored pencils", "12 colored pencils"), quantity(2, "boxes", "2 boxes")]),
        ask("How many colored pencils should Elena put in each box if she wants to distribute them equally?"),
        steps([step("division", [12, 2], 6)]),
        answer(6, "colored pencils"),
        missing_doing("interpreting the goal of equal distribution")),
    anchor(lesson('IM-G3-U4-L3'), grade('3'), record_id('im_defrag_95e6836c2e770aa507544dfc_1'), statement_sha('4e4bc884adae0be440c353e8cb90adad9f38cc4de0d572bbc551aec49e580c1f')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_971a582d1b9efa4ac5d36dd1_1', "How much warmer is 82° than 40°?",
    analysis(
        quantities([quantity(82, "degrees", "82°"), quantity(40, "degrees", "40°")]),
        ask("How much warmer is 82° than 40°?"),
        steps([step("subtraction", [82, 40], 42)]),
        answer(42, "degrees"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U5-L6'), grade('7'), record_id('im_defrag_971a582d1b9efa4ac5d36dd1_1'), statement_sha('e7d93d3ee3630450cc9aec334a5549fa83e6f346c45ef72b2195bc6c092ae346')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_2.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_9776020bc1ee432f4f228142_1', "Find the value of 68 - 39.",
    analysis(
        quantities([quantity(68, "number", "68"), quantity(39, "number", "39")]),
        ask("Find the value of 68 - 39."),
        steps([step("subtraction", [68, 39], 29)]),
        answer(29, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U4-L11'), grade('2'), record_id('im_defrag_9776020bc1ee432f4f228142_1'), statement_sha('ff61fab0cff8278943c12c5a044b20756e897f05bc46b9cabd37d222bbe6bf48')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_4.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_9803f4ff09015f380d59c677_1', "8 birds sit in a tree. 6 birds sit on the grass. How many birds are there in all? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(8, "birds", "8 birds"), quantity(6, "birds", "6 birds")]),
        ask("How many birds are there in total?"),
        steps([step("addition", [8, 6], 14)]),
        answer(14, "birds"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L17'), grade('1'), record_id('im_defrag_9803f4ff09015f380d59c677_1'), statement_sha('492dc56bfc90563230fa9d143cad566793e3d8d156e910805d68666932393d05')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_98b1a21461449952d7d09bbe_1', "Find the value of each expression mentally. 20 · 5",
    analysis(
        quantities([quantity(20, "number", "20"), quantity(5, "number", "5")]),
        ask("What is the value of the expression 20 multiplied by 5?"),
        steps([step("multiplication", [20, 5], 100)]),
        answer(100, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U5-L8'), grade('6'), record_id('im_defrag_98b1a21461449952d7d09bbe_1'), statement_sha('87e8a108abdf4bd5097046b8c382042ff386f9f834d00f168250f44c67df21af')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_99134d88300f4f0e4864c1e0_1', "9 + 5 = 10 + 6",
    analysis(
        quantities([quantity(9, "number", "9"), quantity(5, "number", "5"), quantity(10, "number", "10"), quantity(6, "number", "6")]),
        ask("Is the equation 9 + 5 = 10 + 6 true?"),
        steps([step("addition", [9, 5], 14), step("addition", [10, 6], 16), step("compare_equal", [14, 16], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U1-L13'), grade('2'), record_id('im_defrag_99134d88300f4f0e4864c1e0_1'), statement_sha('9d6dbca1b996376a97624e58c6b17d228a3f4383a25db55becb2551303831f7b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_996f6ccc412f7f3e566aa8b4_1', "Mai has 5 books about space. She checks out 4 more. How many books about space does Mai have? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(5, "books", "5 books"), quantity(4, "books", "4 more")]),
        ask("How many books about space does Mai have in total?"),
        steps([step("addition", [5, 4], 9)]),
        answer(9, "books"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U2-L3'), grade('1'), record_id('im_defrag_996f6ccc412f7f3e566aa8b4_1'), statement_sha('d2b6488f9902e6fd085fd49579d8eeada7301ff9b3ce8e7129b14892ed17b72e')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_99793e58c8454a913cde6ef4_1', "A sculptor is 5 feet 8 inches tall. Her height is 4 times the height of a stone tower she built. How tall is her tower in inches? Explain or show your reasoning.",
    analysis(
        quantities([quantity(5, "feet", "5 feet"), quantity(8, "inches", "8 inches"), quantity(4, "times", "4 times")]),
        ask("How tall is the stone tower in inches?"),
        steps([step("multiply", [5, 12], 60), step("add", [60, 8], 68), step("divide", [68, 4], 17)]),
        answer(17, "inches"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U5-L15'), grade('4'), record_id('im_defrag_99793e58c8454a913cde6ef4_1'), statement_sha('9d68f528c9fd96eaa26d7a41ca2ed26e9b1109e3e72fb7b2a974b64253f235d6')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_998f79e66611a6ca542f4c0f_1', "2 + 7 = 10",
    analysis(
        quantities([quantity(2, "number", "2"), quantity(7, "number", "7"), quantity(10, "number", "10")]),
        ask("Is the equation 2 + 7 = 10 true?"),
        steps([step("addition", [2, 7], 9), step("compare_equal", [9, 10], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U2-L5'), grade('1'), record_id('im_defrag_998f79e66611a6ca542f4c0f_1'), statement_sha('592a5a88817c87962d40fd7bc255ada2079202c814fe3e5036c93c9b05e05f00')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_99bd698b14be238810e2350f_1', "If a project needs 42 gallons of concrete in all (6 parts), how much per part?",
    analysis(
        quantities([quantity(42, "gallons", "42 gallons"), quantity(6, "parts", "6 parts")]),
        ask("How many gallons of concrete are needed per part?"),
        steps([step("division", [42, 6], 7)]),
        answer(7, "gallons"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L15'), grade('6'), record_id('im_defrag_99bd698b14be238810e2350f_1'), statement_sha('0bc9d9c92f72a608930da430b53137129a3d95305911b8f374976043e31bab21')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_9a1c82baf0fe2d8cc8a6fe91_1', "There are 7 windows. Each window has 2 pieces of glass.",
    analysis(
        quantities([quantity(7, "windows", "7 windows"), quantity(2, "pieces of glass", "2 pieces of glass")]),
        ask("How many pieces of glass are there in total?"),
        steps([step("multiplication", [7, 2], 14)]),
        answer(14, "pieces of glass"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U1-L12'), grade('3'), record_id('im_defrag_9a1c82baf0fe2d8cc8a6fe91_1'), statement_sha('e02b30eac0b0f63253288f04beb8d1df5fcd6122db9ab1e7c36d011aed32655f')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_9a953228149072f9e0fa8702_1', "711 ÷ 3",
    analysis(
        quantities([quantity(711, "number", "711"), quantity(3, "number", "3")]),
        ask("What is the quotient of 711 divided by 3?"),
        steps([step("division", [711, 3], 237)]),
        answer(237, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U6-L20'), grade('4'), record_id('im_defrag_9a953228149072f9e0fa8702_1'), statement_sha('a0dd1318595039e412d339d213c38fdb23015215adc37048be8fc8cd33918239')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_9ac16913f086a38d460267c3_1', "1. Explain why 2.5 × 6.4 and (25 × 64) × 0.01 have the same value. 2. Find the value of 2.5 × 6.4.",
    analysis(
        quantities([quantity(2.5, "number", "2.5"), quantity(6.4, "number", "6.4"), quantity(25, "number", "25"), quantity(64, "number", "64"), quantity(0.01, "number", "0.01")]),
        ask("Explain why 2.5 × 6.4 and (25 × 64) × 0.01 are equal and find the value of 2.5 × 6.4."),
        steps([step("multiply", [25, 64], 1600), step("multiply", [1600, 0.01], 16), step("multiply", [2.5, 6.4], 16)]),
        answer(16, "number"),
        missing_doing("mathematical explanation of decimal scaling")),
    anchor(lesson('IM-G5-U5-L21'), grade('5'), record_id('im_defrag_9ac16913f086a38d460267c3_1'), statement_sha('8a5c206040c0152713958f8d2a4a073377629c5a7356e8255e3e6d208f0d23e6')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_9b1b73ff0e1443234be73a0a_1', "Solve each problem. Explain or show your reasoning. 1. Two friends live 7 miles apart. One Saturday, the two friends set out on their bikes at 8 a.m. and started riding toward each other. One rides at 0.2 miles per minute, and the other rides at 0.15 miles per minute. At what time will the two friends meet? 2. Students are selling school spirit gear for a fundraiser. Bracelets with the school mascot on them cost $1 each, and shirts with the school crest cost $10 each. They sold 100 items and made $307. How many bracelets did they sell? 3. Jada earns $7 per hour mowing her neighbors' lawns. Andre gets paid $5 per hour for the first hour of babysitting and $8 per hour for any additional hours he babysits. What is the number of hours they both can work so that they get paid the same amount? 4. Pause here so your teacher can review your work. Then, invent another problem that is like one of these, but with different numbers. Solve your problem. 5. Create a visual display that includes: The new problem you wrote, without the solution.",
    analysis(
        quantities([quantity(7, "miles", "7 miles"), quantity(8, "a.m.", "8 a.m."), quantity(0.2, "miles per minute", "0.2 miles per minute"), quantity(0.15, "miles per minute", "0.15 miles per minute")]),
        ask("At what time will the two friends meet?"),
        steps([step("add", [0.2, 0.15], 0.35), step("divide", [7, 0.35], 20)]),
        answer(20, "minutes after 8 a.m."),
        missing_doing("time_addition")),
    anchor(lesson('IM-G8-U4-L16'), grade('8'), record_id('im_defrag_9b1b73ff0e1443234be73a0a_1'), statement_sha('0769a15dd6c2f86feb9767f8e3ea39e60a9877363ee8bdd073e0e7656941ede2')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/reallms_g68.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_9b20c2eb28ad502f8fde87ef_1', "Two schools buy science books for $8 each from a publisher to sell at their book fairs. School A sells the books for $12. School B sells the books for $12.90 1. Who do you think sells more science books? Explain or show your reasoning. 2. How much profit does each school make if they each sell 35 books? 3. School B sells 10 science books. How many science books does School A have to sell to raise about the same amount of money?",
    analysis(
        quantities([quantity(8, "dollars", "$8"), quantity(12, "dollars", "$12"), quantity(12.9, "dollars", "$12.90"), quantity(35, "books", "35 books"), quantity(10, "books", "10 science books")]),
        ask("1. Predict who sells more books and explain. 2. Calculate the profit for each school if they each sell 35 books. 3. Determine how many books School A must sell to match the profit of School B selling 10 books."),
        steps([step("subtraction", [12, 8], 4), step("subtraction", [12.9, 8], 4.9), step("multiplication", [4, 35], 140), step("multiplication", [4.9, 35], 171.5), step("multiplication", [4.9, 10], 49), step("division", [49, 4], 12.25)]),
        answer(12.25, "books"),
        missing_doing("subjective prediction and qualitative reasoning")),
    anchor(lesson('IM-G5-U5-L26'), grade('5'), record_id('im_defrag_9b20c2eb28ad502f8fde87ef_1'), statement_sha('3ace7d4aa25b86615cbcd43f598bc503eac400d7f1e669f26368bea43e7d7d24')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_9b6b9139e9bbdc306f0c46fc_1', "64 = 30 + 24",
    analysis(
        quantities([quantity(64, "number", "64"), quantity(30, "number", "30"), quantity(24, "number", "24")]),
        ask("Is 64 equal to the sum of 30 and 24?"),
        steps([step("addition", [30, 24], 54), step("compare_equal", [64, 54], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U2-L6'), grade('2'), record_id('im_defrag_9b6b9139e9bbdc306f0c46fc_1'), statement_sha('d1574a027923b85d0b9e233e0a0ec360444c2d8f13cb094ffb050c8cdef3d0eb')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_9bd485c0a7ff83ccb722e73f_1', "Andre has 8 boxes. Each box has 10 cars in it.",
    analysis(
        quantities([quantity(8, "boxes", "8 boxes"), quantity(10, "cars per box", "10 cars")]),
        ask("How many cars does Andre have in total?"),
        steps([step("multiplication", [8, 10], 80)]),
        answer(80, "cars"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U1-L13'), grade('3'), record_id('im_defrag_9bd485c0a7ff83ccb722e73f_1'), statement_sha('ffd26b6ad59acd68c198af83408a52a76f0f9c02e2ce65cbe0fa4cb509c551b6')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_9be850aa029fa81246ac7dae_1', "Use long division to find each quotient. Write your answer as a decimal. 1,097 ÷ 5",
    analysis(
        quantities([quantity(1097, "number", "1,097"), quantity(5, "number", "5")]),
        ask("Find the quotient of 1,097 divided by 5 as a decimal."),
        steps([step("division", [1097, 5], 219.4)]),
        answer(219.4, "decimal"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U5-L13'), grade('6'), record_id('im_defrag_9be850aa029fa81246ac7dae_1'), statement_sha('9d08c7d0a72635592c2d56f916439b059f0e4b9d842836ed62e0201760b51850')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_9cf2247c94b813d54ae8d724_1', "If the image of the pattern is a rectangle with side lengths of 9 inches by 6 inches, what is the perimeter? Explain your reasoning.",
    analysis(
        quantities([quantity(9, "inches", "9 inches"), quantity(6, "inches", "6 inches")]),
        ask("What is the perimeter of a rectangle with side lengths of 9 inches by 6 inches?"),
        steps([step("addition", [9, 6], 15), step("multiplication", [15, 2], 30)]),
        answer(30, "inches"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U7-L14'), grade('3'), record_id('im_defrag_9cf2247c94b813d54ae8d724_1'), statement_sha('96d8676196bee141f5f7205b383c9cd0b0b6d99ec8726bc15fdb25205bad3157')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_9d716319458fde87c7f728ec_1', "A group of students are cleaning 96 desks after an art project. If 6 students each clean the same number of desks, how many desks does each student clean? Explain or show your reasoning.",
    analysis(
        quantities([quantity(96, "desks", "96 desks"), quantity(6, "students", "6 students")]),
        ask("How many desks does each student clean if 6 students clean 96 desks equally?"),
        steps([step("division", [96, 6], 16)]),
        answer(16, "desks"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U6-L13'), grade('4'), record_id('im_defrag_9d716319458fde87c7f728ec_1'), statement_sha('092a440d71a6d92f73cac03d79b24647dece4da976e0534d3e6464825e4ffe51')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_9e061acc6436335b7ff2643b_1', "Use long division to show that the fraction and decimal in each pair are equal. 3/4 and 0.75",
    analysis(
        quantities([quantity(3, "numerator", "3"), quantity(4, "denominator", "4"), quantity(0.75, "decimal", "0.75")]),
        ask("Show that the fraction 3/4 and the decimal 0.75 are equal using long division."),
        steps([step("divide", [3, 4], 0.75), step("compare_equal", [0.75, 0.75], true)]),
        answer(true, "claim_verdict"),
        missing_doing("long division")),
    anchor(lesson('IM-G6-U5-L12'), grade('6'), record_id('im_defrag_9e061acc6436335b7ff2643b_1'), statement_sha('dda734faf9e3d5a5150ef5180517dde17818f6cdd4c1e9ba2fb64f17c2a70fee')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_9ecdde20b608e169ee1393d3_1', "Find the value of 278 + 65. Show your thinking.",
    analysis(
        quantities([quantity(278, "number", "278"), quantity(65, "number", "65")]),
        ask("Find the value of 278 + 65."),
        steps([step("addition", [278, 65], 343)]),
        answer(343, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U7-L8'), grade('2'), record_id('im_defrag_9ecdde20b608e169ee1393d3_1'), statement_sha('ffec46f833584af65cd31affe53ddf4c64135eaf1afb6c43c88536cd443b8523')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_2.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_9f22b4f0bd5f4569d348e96c_1', "4 + 3 = 7",
    analysis(
        quantities([quantity(4, "number", "4"), quantity(3, "number", "3"), quantity(7, "number", "7")]),
        ask("Is 4 + 3 equal to 7?"),
        steps([step("addition", [4, 3], 7), step("compare_equal", [7, 7], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U7-L4'), grade('K'), record_id('im_defrag_9f22b4f0bd5f4569d348e96c_1'), statement_sha('e1001dcd8de85451404515d71019a63650cee5f1e94b4ad1c9f653c6448c3c18')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_9fbf903c76165387ee0d7cc7_1', "A car is traveling at a constant speed of 60 miles per hour. How far does the car travel in: b. 5 hours?",
    analysis(
        quantities([quantity(60, "miles per hour", "60 miles per hour"), quantity(5, "hours", "5 hours")]),
        ask("How far does the car travel in 5 hours?"),
        steps([step("multiplication", [60, 5], 300)]),
        answer(300, "miles"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U5-L8'), grade('7'), record_id('im_defrag_9fbf903c76165387ee0d7cc7_1'), statement_sha('342672ec6897ba1aac95b110ce6061a7cde545f78a56ac20713fdcff6065997c')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_9feb5745871f50c831ddb71e_1', "4 + 6 = 10",
    analysis(
        quantities([quantity(4, "number", "4"), quantity(6, "number", "6"), quantity(10, "number", "10")]),
        ask("Is 4 plus 6 equal to 10?"),
        steps([step("addition", [4, 6], 10), step("compare_equal", [10, 10], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U2-L19'), grade('1'), record_id('im_defrag_9feb5745871f50c831ddb71e_1'), statement_sha('3ae7b0d51c2a23a26fdb32ff00ad4af95988729cbe6c9cef5dc1673367fd1637')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_9ffb5e179dd7040c802a63e2_1', "488 ÷ 4",
    analysis(
        quantities([quantity(488, "number", "488"), quantity(4, "number", "4")]),
        ask("What is the result of dividing 488 by 4?"),
        steps([step("division", [488, 4], 122)]),
        answer(122, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U6-L15'), grade('4'), record_id('im_defrag_9ffb5e179dd7040c802a63e2_1'), statement_sha('3f247a7284a044f06a12cfea814fdc24d935958e2f8434c1187fbaf284578013')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_9ffcec2e658030a00486d3d9_1', "28 + 5 = 30 + 3",
    analysis(
        quantities([quantity(28, "number", "28"), quantity(5, "number", "5"), quantity(30, "number", "30"), quantity(3, "number", "3")]),
        ask("Check if 28 + 5 is equal to 30 + 3."),
        steps([step("addition", [28, 5], 33), step("addition", [30, 3], 33), step("compare_equal", [33, 33], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U1-L16'), grade('2'), record_id('im_defrag_9ffcec2e658030a00486d3d9_1'), statement_sha('d3faa5d568579d7246d62ddc3412044a7ec6eb41d24b855383c5b051c7af921b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a05e81e7ca340c914b0b3ad4_1', "3. Lin’s tower has 2 cubes. Kiran’s tower has 9 cubes. How many fewer cubes are in Lin’s tower?",
    analysis(
        quantities([quantity(2, "cubes", "2 cubes"), quantity(9, "cubes", "9 cubes")]),
        ask("How many fewer cubes are in Lin's tower than in Kiran's tower?"),
        steps([step("subtraction", [9, 2], 7)]),
        answer(7, "cubes"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U2-L14'), grade('1'), record_id('im_defrag_a05e81e7ca340c914b0b3ad4_1'), statement_sha('d39809e9939cee086733e8597350d271752f2f9b90a3151db537b7ee7b972fbb')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a076ea703f3fb8211299d055_1', "12- 4 = 10- 3",
    analysis(
        quantities([quantity(12, "number", "12"), quantity(4, "number", "4"), quantity(10, "number", "10"), quantity(3, "number", "3")]),
        ask("Is 12 minus 4 equal to 10 minus 3?"),
        steps([step("subtraction", [12, 4], 8), step("subtraction", [10, 3], 7), step("compare_equal", [8, 7], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U3-L10'), grade('2'), record_id('im_defrag_a076ea703f3fb8211299d055_1'), statement_sha('5999fc98fd466a5ece763da1c2e2f9465fd59f7a2164d0b5a963f74b62ef3c1c')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a077e07e05c14eedf5b915a3_1', "9 ducks swim in the pond. 4 ducks leave. How many now?",
    analysis(
        quantities([quantity(9, "ducks", "9 ducks"), quantity(4, "ducks", "4 ducks")]),
        ask("How many ducks are left in the pond?"),
        steps([step("subtraction", [9, 4], 5)]),
        answer(5, "ducks"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U4-L12'), grade('K'), record_id('im_defrag_a077e07e05c14eedf5b915a3_1'), statement_sha('4ceced167ac3e26e9340dad0b4208061ce67fb47fbded77745f48b6c083b1797')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a0a5b8b31cc27c721111ce66_1', "Solve each equation mentally: a · 50 = 10",
    analysis(
        quantities([quantity(50, "factor", "50"), quantity(10, "product", "10")]),
        ask("Find the value of 'a' in the equation a * 50 = 10."),
        steps([step("division", [10, 50], 0.2)]),
        answer(0.2, "number"),
        missing_doing("algebraic manipulation")),
    anchor(lesson('IM-G7-U4-L8'), grade('7'), record_id('im_defrag_a0a5b8b31cc27c721111ce66_1'), statement_sha('43c6221e4fe1e88935a020492e41ea778637ce4377d68f17687d4e68e6ffe9ae')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a1067e9ee777b7c342f63962_1', "The school donated books to 3 different places. The school donated 275 books to each place. How many books did the school donate in all?",
    analysis(
        quantities([quantity(3, "places", "3 different places"), quantity(275, "books", "275 books")]),
        ask("How many books did the school donate in all?"),
        steps([step("multiply", [275, 3], 825)]),
        answer(825, "books"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U7-L19'), grade('2'), record_id('im_defrag_a1067e9ee777b7c342f63962_1'), statement_sha('428c905a095f048ebe47b3b514c860926aef80e71c6b1f98b77f0862b8f072ee')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a114ad0561d956b517362220_1', "Find the value of 22 + 49.",
    analysis(
        quantities([quantity(22, "number", "22"), quantity(49, "number", "49")]),
        ask("What is the value of 22 plus 49?"),
        steps([step("addition", [22, 49], 71)]),
        answer(71, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U4-L11'), grade('2'), record_id('im_defrag_a114ad0561d956b517362220_1'), statement_sha('b4e312ae69999e487abfadffedd863a27388574699269faa1af5841c541e9cb2')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a1488264087f82f73b4a7546_1', "pencils erasers crayons 9 4 7 How many fewer erasers than pencils are there? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(9, "pencils", "9"), quantity(4, "erasers", "4"), quantity(7, "crayons", "7")]),
        ask("How many fewer erasers are there than pencils?"),
        steps([step("subtraction", [9, 4], 5)]),
        answer(5, "erasers"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U2-L13'), grade('1'), record_id('im_defrag_a1488264087f82f73b4a7546_1'), statement_sha('32b4584ecabd6c0d2a6f2306079518e1096074f81a4554cd89ca046f18e579af')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a1bbe962222c7842e371f91e_1', "1. I started on 59 and jumped to 68. How far did I jump? a. Write an equation to represent the problem with a ? for the unknown. b. Find the number that makes the equation true. c. Represent your thinking on the number line.",
    analysis(
        quantities([quantity(59, "number", "59"), quantity(68, "number", "68")]),
        ask("How far was the jump from 59 to 68?"),
        steps([step("subtraction", [68, 59], 9)]),
        answer(9, "number"),
        missing_doing("representing on a number line")),
    anchor(lesson('IM-G2-U4-L12'), grade('2'), record_id('im_defrag_a1bbe962222c7842e371f91e_1'), statement_sha('4713d9caf276990305a37ba38d79ce75553eeb626f0684fee50403975b7a387e')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a1c6186bc9342e1aea1ef682_1', "Use long division to find each quotient. Write your answer as a decimal. a. 99 ÷ 12",
    analysis(
        quantities([quantity(99, "dividend", "99"), quantity(12, "divisor", "12")]),
        ask("Find the quotient of 99 divided by 12 expressed as a decimal."),
        steps([step("divide", [99, 12], 8.25)]),
        answer(8.25, "decimal"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U5-L12'), grade('6'), record_id('im_defrag_a1c6186bc9342e1aea1ef682_1'), statement_sha('a6ce7476936cf1cf8602bd09394bd532ea59eb609af40f62eb794466ff972b95')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a21758ad1ed67da8a167116f_1', "43 + 48 = 50",
    analysis(
        quantities([quantity(43, "number", "43"), quantity(48, "number", "48"), quantity(50, "number", "50")]),
        ask("Is 43 + 48 equal to 50?"),
        steps([step("addition", [43, 48], 91), step("compare_equal", [91, 50], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U2-L15'), grade('2'), record_id('im_defrag_a21758ad1ed67da8a167116f_1'), statement_sha('94604057fd125e4fa5304d9e722d1e2bee53d1c7426abc4086e015ab7d39f4bd')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a263dc9441894a3ed668b500_1', "Find the value of each product. Explain or show your reasoning. 1. 4 × 798 2. 8 × 2,864",
    analysis(
        quantities([quantity(4, "number", "4"), quantity(798, "number", "798"), quantity(8, "number", "8"), quantity(2864, "number", "2,864")]),
        ask("Find the value of the product 4 × 798."),
        steps([step("multiplication", [4, 798], 3192)]),
        answer(3192, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U6-L11'), grade('4'), record_id('im_defrag_a263dc9441894a3ed668b500_1'), statement_sha('695c2d8d313625cd0b3250b7f9b5a576ef78fbf4bc9e28fa5411c41d4532a085')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_4.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a29b5c3d825167d9bcbbc573_1', "Find the value of 37 + 26. Priya's work How did Priya find the value?",
    analysis(
        quantities([quantity(37, "number", "37"), quantity(26, "number", "26")]),
        ask("What is the value of 37 + 26?"),
        steps([step("addition", [37, 26], 63)]),
        answer(63, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U5-L10'), grade('1'), record_id('im_defrag_a29b5c3d825167d9bcbbc573_1'), statement_sha('9e2ffba5ddc79a854e59c330b228cc1fe77e07860a79c483f120a3eeeb3bef45')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a29e493ed04b58b8f417da40_1', "A fashion designer orders leather by the square meter. Do the values show a proportional relationship? Table row: 40 sq m -> $740.00; price / area = 18.5.",
    analysis(
        quantities([quantity(40, "sq m", "40 sq m"), quantity(740, "dollars", "$740.00"), quantity(18.5, "price / area", "18.5")]),
        ask("Do the values provided in the table show a proportional relationship?"),
        steps([step("division", [740, 40], 18.5), step("compare_equal", [18.5, 18.5], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U2-L4'), grade('7'), record_id('im_defrag_a29e493ed04b58b8f417da40_1'), statement_sha('f81bc0947ede3bef64b059cd2b265c0cc3ed14831fba9c0d14721f93f8810c69')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a319b3db1d8aa960f06120d4_1', "Show your thinking, using drawings, numbers, or words. Label your final answer with the dollar sign ($). 1. Mai has $27, Elena has $48, and Jada has $16. How much money do they have in all? 2. Tyler has $45, Andre has $36, and Noah has $28. How much less money does Tyler have than Andre and Noah together? 3. Lin has $19. Lin and Han have $45 in all. Then Han gets $17 more. How much money does he have now?",
    analysis(
        quantities([quantity(19, "dollars", "$19"), quantity(45, "dollars", "$45"), quantity(17, "dollars", "$17")]),
        ask("How much money does Han have now?"),
        steps([step("subtraction", [45, 19], 26), step("addition", [26, 17], 43)]),
        answer(43, "dollars"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U6-L19'), grade('2'), record_id('im_defrag_a319b3db1d8aa960f06120d4_1'), statement_sha('a938b94ec35df8ef87328456c9df627d37edabacc2c82ff41102ca4367b4e237')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a33f1c660b53b02dfc18d09f_1', "8 + 5 = 8 + 2 + 5",
    analysis(
        quantities([quantity(8, "number", "8"), quantity(5, "number", "5"), quantity(8, "number", "8"), quantity(2, "number", "2"), quantity(5, "number", "5")]),
        ask("Is the equation 8 + 5 = 8 + 2 + 5 true?"),
        steps([step("addition", [8, 5], 13), step("addition", [8, 2], 10), step("addition", [10, 5], 15), step("compare_equal", [13, 15], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U9-L2'), grade('2'), record_id('im_defrag_a33f1c660b53b02dfc18d09f_1'), statement_sha('c4e5a526123efac40ca64b8e4551a1b0985255c191a69af7540bbc614f2c145e')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a38d6526a4418583ab172eca_1', "6 people come to story time. 3 more people join the group.",
    analysis(
        quantities([quantity(6, "people", "6 people"), quantity(3, "people", "3 more people")]),
        ask("How many people are in the group in total?"),
        steps([step("addition", [6, 3], 9)]),
        answer(9, "people"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U2-L2'), grade('1'), record_id('im_defrag_a38d6526a4418583ab172eca_1'), statement_sha('7acdb7fc7eac1d40f485714ff70023c30a748c208c928a7890e4b6d5a5d6c026')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a4865ff525a96c40582e0e90_1', "4 little speckled frogs sat on a speckled log, eating the most delicious bugs. Yum! Yum! 1 jumped into the pool, where it was nice and cool. Now there are 3 green speckled frogs. Glub! Glub!",
    analysis(
        quantities([quantity(4, "frogs", "4 little speckled frogs"), quantity(1, "frog", "1 jumped into the pool")]),
        ask("How many speckled frogs are left on the log?"),
        steps([step("subtraction", [4, 1], 3)]),
        answer(3, "frogs"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U1-L10'), grade('K'), record_id('im_defrag_a4865ff525a96c40582e0e90_1'), statement_sha('16a0b7f680c3463eb78615c568c55717f0946a91c81adb27d36bf53d209f2ed7')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_2.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a49d51aed4834c8167877967_1', "5 + 1 = 5 + 2",
    analysis(
        quantities([quantity(5, "number", "5"), quantity(1, "number", "1"), quantity(5, "number", "5"), quantity(2, "number", "2")]),
        ask("Check if the equation 5 + 1 = 5 + 2 is true."),
        steps([step("addition", [5, 1], 6), step("addition", [5, 2], 7), step("compare_equal", [6, 7], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L14'), grade('1'), record_id('im_defrag_a49d51aed4834c8167877967_1'), statement_sha('e58bbdd70bbfc74fa03efed57bd05bac165f1d0f88b0321521235bbf4e1c702d')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a4f6b52842a33d834084f2e2_1', "1. Use the digits 7, 3, 2, and 5 to make the greatest product. Use each digit only once. 2. Explain your reasoning.",
    analysis(
        quantities([quantity(7, "digit", "7"), quantity(3, "digit", "3"), quantity(2, "digit", "2"), quantity(5, "digit", "5")]),
        ask("What is the greatest product that can be made using each of the digits 7, 3, 2, and 5 exactly once?"),
        steps([step("multiply", [7, 5], 35), step("multiply", [3, 2], 6), step("multiply", [35, 6], 210), step("multiply", [7, 3], 21), step("multiply", [5, 2], 10), step("multiply", [21, 10], 210), step("multiply", [7, 2], 14), step("multiply", [5, 3], 15), step("multiply", [14, 15], 210)]),
        answer(210, "product"),
        missing_doing("combinatorial optimization")),
    anchor(lesson('IM-G5-U8-L1'), grade('5'), record_id('im_defrag_a4f6b52842a33d834084f2e2_1'), statement_sha('057ff9130cc5b4ade761a21a2fb578707d79193c1a7cdf2dbf3a46843286205b')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_5.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a504f4467cd004829ea46913_1', "Noah went 50 meters in 10 seconds... b. How far did Noah go in 1 second? [50 ÷ 10 = 5]",
    analysis(
        quantities([quantity(50, "meters", "50 meters"), quantity(10, "seconds", "10 seconds")]),
        ask("How far did Noah go in 1 second?"),
        steps([step("division", [50, 10], 5)]),
        answer(5, "meters"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U4-L8'), grade('6'), record_id('im_defrag_a504f4467cd004829ea46913_1'), statement_sha('f6923e24d4602e61006ca6cb530d357e83d800d733c75224444417dc527426fc')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a5ddf709ce17596b451ceef1_1', "Kiran has 6 books. His friend gives him some more books. Now Kiran has 8 books. How many books did Kiran get from his friend? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(6, "books", "6 books"), quantity(8, "books", "8 books")]),
        ask("How many books did Kiran get from his friend?"),
        steps([step("subtraction", [8, 6], 2)]),
        answer(2, "books"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U2-L3'), grade('1'), record_id('im_defrag_a5ddf709ce17596b451ceef1_1'), statement_sha('598d335a282c537f8437f6ac974b347061252c28717a997b4255eef2c57af3aa')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a6423a9d0e6b4c1a2a28735c_1', "18 + 5 = 18 + 2 + 3",
    analysis(
        quantities([quantity(18, "number", "18"), quantity(5, "number", "5"), quantity(18, "number", "18"), quantity(2, "number", "2"), quantity(3, "number", "3")]),
        ask("Check if 18 + 5 is equal to 18 + 2 + 3."),
        steps([step("add", [18, 5], 23), step("add", [18, 2], 20), step("add", [20, 3], 23), step("compare_equal", [23, 23], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U1-L16'), grade('2'), record_id('im_defrag_a6423a9d0e6b4c1a2a28735c_1'), statement_sha('576513a5c63e2e6cde6d9ea045216106f4f61e7cce65c44785ca15abc92f5d42')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a68c2e49a644461ff2b01b36_1', "If someone uses 400 liters of orange juice, how much soda water would they need? [soda = 5*100; solution: 5*100=500]",
    analysis(
        quantities([quantity(400, "liters of orange juice", "400 liters of orange juice"), quantity(5, "ratio multiplier", "5")]),
        ask("How much soda water is needed if 400 liters of orange juice are used, given the ratio provided?"),
        steps([step("multiplication", [5, 100], 500)]),
        answer(500, "liters of soda water"),
        missing_doing("interpreting the cryptic parenthetical instruction")),
    anchor(lesson('IM-G6-U2-L11'), grade('6'), record_id('im_defrag_a68c2e49a644461ff2b01b36_1'), statement_sha('7a9401f83dc262d9ea80c2250c94db5cfa68d3e1bc98ee4128715fc37c903e9a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a718cfdeb38c5724dc95a054_1', "Find the value of 432 ÷ 6. Show your thinking using diagrams, symbols, or other representations.",
    analysis(
        quantities([quantity(432, "number", "432"), quantity(6, "number", "6")]),
        ask("What is the value of 432 divided by 6?"),
        steps([step("division", [432, 6], 72)]),
        answer(72, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U6-L16'), grade('4'), record_id('im_defrag_a718cfdeb38c5724dc95a054_1'), statement_sha('4d380e8b9cdf44eadbc505e027c1011db6e93d75fb7f9009020eff878d6de4f2')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a729d8516be493c35d155181_1', "Complete the table to show the position of each vehicle after traveling at a constant velocity for the given amount of time. car C: velocity +9, time +5",
    analysis(
        quantities([quantity(9, "velocity", "velocity +9"), quantity(5, "time", "time +5")]),
        ask("What is the position of car C after traveling at a velocity of 9 for a time of 5?"),
        steps([step("multiplication", [9, 5], 45)]),
        answer(45, "position"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U5-L8'), grade('7'), record_id('im_defrag_a729d8516be493c35d155181_1'), statement_sha('ab16094043176cbd7c0948aefc239f357bf55f900e449fca311d56bc19dd3aa9')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a730d6dd748c8bcde382f15c_1', "Draw a diagram to show how much sandwich each person will get. 3 sandwiches are equally shared by 4 people. 2.",
    analysis(
        quantities([quantity(3, "sandwiches", "3 sandwiches"), quantity(4, "people", "4 people")]),
        ask("How much sandwich will each person get if 3 sandwiches are shared equally among 4 people?"),
        steps([step("division", [3, 4], 0.75)]),
        answer(0.75, "sandwiches"),
        missing_doing("visualizing partitioning via diagram")),
    anchor(lesson('IM-G5-U2-L1'), grade('5'), record_id('im_defrag_a730d6dd748c8bcde382f15c_1'), statement_sha('97b47cc9bfbd51be4716869fc12cdb108d21546fca8096f0329285f9298c28e8')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a81c334023905d6daa831900_1', "A leap year has 366 days. A non-leap year has 365 days. How many days are in 3 leap years?",
    analysis(
        quantities([quantity(366, "days", "366 days"), quantity(3, "leap years", "3 leap years")]),
        ask("How many days are in 3 leap years?"),
        steps([step("multiplication", [366, 3], 1098)]),
        answer(1098, "days"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U6-L12'), grade('4'), record_id('im_defrag_a81c334023905d6daa831900_1'), statement_sha('13ee0eb27d1dad52306d40bdf8601d8d43d90546d8f026f6f9dab4143170782a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a8464a56a4752a483f939560_1', "Partner A: How many 3s are in 12? Division equation:",
    analysis(
        quantities([quantity(3, "number", "3s"), quantity(12, "number", "12")]),
        ask("How many 3s are in 12?"),
        steps([step("divide", [12, 3], 4)]),
        answer(4, "count"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U4-L10'), grade('6'), record_id('im_defrag_a8464a56a4752a483f939560_1'), statement_sha('d439d97c3b51623bd0989a3407a0d55d3480b04571967d054e4ed0afd432ba19')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a89ce67f08845955a1521e5b_1', "Write a multiplication expression to match each situation, drawing, or diagram. Explain your reasoning. 1. 2. 3. There were 2 packs of water. Each pack had 6 bottles of water.",
    analysis(
        quantities([quantity(2, "packs", "2 packs"), quantity(6, "bottles", "6 bottles")]),
        ask("Write a multiplication expression that matches the situation where there are 2 packs of water and each pack has 6 bottles."),
        steps([step("multiplication", [2, 6], 12)]),
        answer(12, "bottles"),
        missing_doing("formulating an expression")),
    anchor(lesson('IM-G3-U1-L11'), grade('3'), record_id('im_defrag_a89ce67f08845955a1521e5b_1'), statement_sha('63cbf64162db60cb26f64039ea0fc60c123f9f4b3045656e3ec8149e8f7097e3')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_0.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a8a9520b07bec440ec97cb49_1', "Find the value of each quotient. Explain or show your reasoning. Organize your work so it can be followed by others. 1. 80 ÷ 5 2. 68 ÷ 4 3. 91 ÷ 7 If you have time: The 84 students on a field trip are put into groups. Each group has 14 students. How many groups are there?",
    analysis(
        quantities([quantity(80, "number", "80"), quantity(5, "number", "5"), quantity(68, "number", "68"), quantity(4, "number", "4"), quantity(91, "number", "91"), quantity(7, "number", "7"), quantity(84, "students", "84 students"), quantity(14, "students per group", "14 students")]),
        ask("Find the value of 80 ÷ 5, 68 ÷ 4, 91 ÷ 7, and the number of groups of 14 students that can be formed from 84 students."),
        steps([step("division", [80, 5], 16), step("division", [68, 4], 17), step("division", [91, 7], 13), step("division", [84, 14], 6)]),
        answer(6, "groups"),
        missing_doing("the problem asks for a list of multiple answers, which cannot be represented as a single number")),
    anchor(lesson('IM-G3-U4-L20'), grade('3'), record_id('im_defrag_a8a9520b07bec440ec97cb49_1'), statement_sha('8122fa71ce5b0454d1f46fda767fd54c06aaf03bc2b610548443246d3c7982b7')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_1.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a8aa82594be6c07741905a65_1', "Solve each problem. Explain or show your reasoning. 1. A rectangular mural has side lengths of 17 feet and 4 feet. What is the area of the mural? 2. Noah makes a rectangular mosaic with 1-inch tiles. The mosaic has 12 rows and 8 columns of tiles. What is the area of the mosaic? 3. Noah uses chalk to help decorate a rectangular patio that is 6 feet wide and 14 feet long. What is the area of the patio? 4. Noah buys a pack of stickers. There are 5 sheets in the pack, and each sheet has 16 stickers. How many stickers are in the pack?",
    analysis(
        quantities([quantity(5, "sheets", "5 sheets"), quantity(16, "stickers", "16 stickers")]),
        ask("How many stickers are in the pack?"),
        steps([step("multiplication", [5, 16], 80)]),
        answer(80, "stickers"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L15'), grade('3'), record_id('im_defrag_a8aa82594be6c07741905a65_1'), statement_sha('ec7423b90f2516f5b9166976f1098295c3758b1e85045fbd67239ac678c91b16')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a8ddce14528b6a12a0dff707_1', "A booth at the apple orchard has 225 apples. 165 apples are not in baskets. The rest of the apples are in 6 baskets with the same number of apples in each basket. How many apples are in each basket? 1. Write an equation to represent this situation. Use a letter for the unknown quantity. 2. Solve the problem. Explain or show your reasoning.",
    analysis(
        quantities([quantity(225, "apples", "225 apples"), quantity(165, "apples", "165 apples"), quantity(6, "baskets", "6 baskets")]),
        ask("How many apples are in each basket?"),
        steps([step("subtraction", [225, 165], 60), step("division", [60, 6], 10)]),
        answer(10, "apples"),
        missing_doing("modeling the situation with an equation")),
    anchor(lesson('IM-G3-U4-L21'), grade('3'), record_id('im_defrag_a8ddce14528b6a12a0dff707_1'), statement_sha('d8d0d1040563130e406f3487333484c277eb34e3530d1efa1b8b664d46d41c6f')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a9162dd2353ded2db9aed7dd_1', "Write the number that makes 10 when added to each number. 5 _______________ 1 _______________",
    analysis(
        quantities([quantity(10, "sum", "10"), quantity(5, "number", "5"), quantity(1, "number", "1")]),
        ask("Find the numbers that, when added to 5 and 1 respectively, result in 10."),
        steps([step("subtraction", [10, 5], 5), step("subtraction", [10, 1], 9)]),
        answer(5, "number"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U5-L13'), grade('K'), record_id('im_defrag_a9162dd2353ded2db9aed7dd_1'), statement_sha('a41b6de94f83fae20b781ea8dafc63f91a8bff5a37a0eaebe164f41952baac32')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_2.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a93f2b9ec5ba9e191f9aae37_1', "Find the value of 14 + 53. Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(14, "number", "14"), quantity(53, "number", "53")]),
        ask("What is the value of 14 + 53?"),
        steps([step("addition", [14, 53], 67)]),
        answer(67, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U5-L3'), grade('1'), record_id('im_defrag_a93f2b9ec5ba9e191f9aae37_1'), statement_sha('7601ee393f2b8e7b4b4c7ea16bf6b131d4c03b0c67b0fefa9cb18d3017b2433f')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_a9bcbd069b9f1173779ad5c7_1', "Circle 2 equations that can be used to solve each problem. 1. Noah paints 9 white stars. He also paints some yellow stars. Noah paints 17 stars all together. How many yellow stars does Noah paint? A. 17- 9 = B. 9 + 17 = C. 2. Kiran sees 16 objects in the sky. 11 of the objects are stars. The rest of the objects are planets. How many of the objects are planets? A. 16 + 11 = B. C. 16- 11 = If you have time: Solve each problem using both equations.",
    analysis(
        quantities([quantity(16, "objects in the sky", "16 objects in the sky"), quantity(11, "stars", "11 of the objects are stars")]),
        ask("How many of the objects are planets?"),
        steps([step("-", [16, 11], 5)]),
        answer(5, "planets"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U8-L5'), grade('1'), record_id('im_defrag_a9bcbd069b9f1173779ad5c7_1'), statement_sha('54540079638892fd03d594897c7a5653f3ab7c14188d3ce2c789e72096a91a18')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_aad914ff332f266c9f5ad607_1', "15 - 2 = 13 - 0",
    analysis(
        quantities([quantity(15, "number", "15"), quantity(2, "number", "2"), quantity(13, "number", "13"), quantity(0, "number", "0")]),
        ask("Check if the equation 15 - 2 = 13 - 0 is true."),
        steps([step("subtraction", [15, 2], 13), step("subtraction", [13, 0], 13), step("compare_equal", [13, 13], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U3-L10'), grade('2'), record_id('im_defrag_aad914ff332f266c9f5ad607_1'), statement_sha('e0edd3b75bfe1441aad62ed475fd0a3b11a31f25432e74ab673aa9a39855adae')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_ab117df20ac9e3ba4792f88d_1', "10- 0 = 12- 2",
    analysis(
        quantities([quantity(10, "number", "10"), quantity(0, "number", "0"), quantity(12, "number", "12"), quantity(2, "number", "2")]),
        ask("Determine if 10 minus 0 is equal to 12 minus 2."),
        steps([step("subtraction", [10, 0], 10), step("subtraction", [12, 2], 10), step("compare_equal", [10, 10], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U3-L10'), grade('2'), record_id('im_defrag_ab117df20ac9e3ba4792f88d_1'), statement_sha('efeb0538f5120374d9220f32307b7a33349559b82d4d3443c56ed1ad33a31b8d')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_ab76b65b5f1892f183bdb617_1', "Here is a box of pasta and a cylindrical container. The two objects are the same height, and the cylinder is just wide enough for the box to fit inside with all 4 vertical edges of the box touching the inside of the cylinder. If the box of pasta fits 8 cups of rice, estimate how many cups of rice will fit inside the cylinder. Explain or show your reasoning.",
    analysis(
        quantities([quantity(8, "cups of rice", "8 cups of rice")]),
        ask("Estimate how many cups of rice will fit inside the cylinder."),
        steps([step("divide", [8, 2], 4), step("multiply", [4, 3.14], 12.56)]),
        answer(12.56, "cups of rice"),
        missing_doing("assume the box has a square base")),
    anchor(lesson('IM-G8-U5-L12'), grade('8'), record_id('im_defrag_ab76b65b5f1892f183bdb617_1'), statement_sha('eb798694188fc2b80e95cb0134d33d062884a43e9525cf3eaa924e0525bd5b0f')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/reallms_g68.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_aba394c5f8bc3d81a60008d0_1', "Find the value of each expression mentally. 4 ÷ 5",
    analysis(
        quantities([quantity(4, "number", "4"), quantity(5, "number", "5")]),
        ask("What is the value of the expression 4 divided by 5?"),
        steps([step("division", [4, 5], 0.8)]),
        answer(0.8, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U2-L12'), grade('7'), record_id('im_defrag_aba394c5f8bc3d81a60008d0_1'), statement_sha('62de76d028a888491c403cf17308a11171a2f9a173e761821a9c9d076e230b72')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_abad35fb49812ad92c64c4e9_1', "Priya had a piece of ribbon that was 74 inches long. She cut off 17 in. How long is Priya’s ribbon now? Show your thinking using drawings, numbers, or words. Use a diagram if it helps. Don’t forget the unit in your answer.",
    analysis(
        quantities([quantity(74, "inches", "74 inches"), quantity(17, "inches", "17 in.")]),
        ask("How long is Priya's ribbon after she cuts off 17 inches from the original 74 inches?"),
        steps([step("subtraction", [74, 17], 57)]),
        answer(57, "inches"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U3-L11'), grade('2'), record_id('im_defrag_abad35fb49812ad92c64c4e9_1'), statement_sha('a0ea6e5debe6feff594208ff20dde452c876376f9cd16d7597e011a92f5f5d66')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_acc5a97b295130386343348b_1', "20 + 6 = 6 + 30",
    analysis(
        quantities([quantity(20, "number", "20"), quantity(6, "number", "6"), quantity(6, "number", "6"), quantity(30, "number", "30")]),
        ask("Determine if the equation 20 + 6 = 6 + 30 is true or false."),
        steps([step("addition", [20, 6], 26), step("addition", [6, 30], 36), step("compare_equal", [26, 36], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U4-L11'), grade('1'), record_id('im_defrag_acc5a97b295130386343348b_1'), statement_sha('b3a5491272d97260fee8076435d1c1f2ff0f75191a3326cb80c83cfcf8b399d6')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_ad0b473ee5a8669d45b5ff43_1', "Priya spills 7 red counters and 2 yellow counters. How many counters did she spill in all? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(7, "red counters", "7 red counters"), quantity(2, "yellow counters", "2 yellow counters")]),
        ask("How many counters did Priya spill in all?"),
        steps([step("addition", [7, 2], 9)]),
        answer(9, "counters"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L2'), grade('1'), record_id('im_defrag_ad0b473ee5a8669d45b5ff43_1'), statement_sha('96fc05aae18a7f5d9b42e786be04758cad6dae6ff91a30e37b89500e76a79bbf')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_ad3be923b9803bbdafcded71_1', "Use long division to show that the fraction and decimal in each pair are equal. 3/50 and 0.06",
    analysis(
        quantities([quantity(3, "numerator", "3"), quantity(50, "denominator", "50"), quantity(0.06, "decimal", "0.06")]),
        ask("Show that the fraction 3/50 is equal to the decimal 0.06 using long division."),
        steps([step("division", [3, 50], 0.06), step("compare_equal", [0.06, 0.06], true)]),
        answer(true, "claim_verdict"),
        missing_doing("verification of equality")),
    anchor(lesson('IM-G6-U5-L12'), grade('6'), record_id('im_defrag_ad3be923b9803bbdafcded71_1'), statement_sha('42885a470bd248768e8b98caeab7aab1909f9e746894d8be323eff9d5c08f21f')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_ae16022836cfe25a2cf8757a_1', "A strawberry patch has 56 strawberry plants in rows. There are 8 strawberry plants in each row. a. How many rows of strawberry plants are in the patch? b.",
    analysis(
        quantities([quantity(56, "strawberry plants", "56 strawberry plants"), quantity(8, "strawberry plants per row", "8 strawberry plants in each row")]),
        ask("How many rows of strawberry plants are in the patch?"),
        steps([step("division", [56, 8], 7)]),
        answer(7, "rows"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L22'), grade('3'), record_id('im_defrag_ae16022836cfe25a2cf8757a_1'), statement_sha('d25745a431581460d9ae2369512dfcfb61e4bbcaa1e12e5d2f92d019cb010dd8')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_af8d3ebeaed8af6e1779d9ee_1', "Tyler has 3 boxes. He has 5 baseballs in each box.",
    analysis(
        quantities([quantity(3, "boxes", "3 boxes"), quantity(5, "baseballs", "5 baseballs")]),
        ask("The problem does not ask a question, but implies finding the total number of baseballs."),
        steps([step("multiply", [3, 5], 15)]),
        answer(15, "baseballs"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U1-L12'), grade('3'), record_id('im_defrag_af8d3ebeaed8af6e1779d9ee_1'), statement_sha('23a5a91806b81c10c87ad3fd3c7cbf8c77d99a4be49f2d90d5fc801de05e561f')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_af8f8a4f144703e20173c3ff_1', "4 × 45 = 2 × 90",
    analysis(
        quantities([quantity(4, "number", "4"), quantity(45, "number", "45"), quantity(2, "number", "2"), quantity(90, "number", "90")]),
        ask("Check if 4 multiplied by 45 is equal to 2 multiplied by 90."),
        steps([step("multiply", [4, 45], 180), step("multiply", [2, 90], 180), step("compare_equal", [180, 180], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U7-L9'), grade('4'), record_id('im_defrag_af8f8a4f144703e20173c3ff_1'), statement_sha('cf7a110f91e551f591e980901c6c79490121ca57660b3dabdcb2e7f0f4780fe0')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_2.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_affa8e52e5c9cd398ea73b0d_1', "24 apples in boxes. She puts 8 apples in each box. How many boxes are there?",
    analysis(
        quantities([quantity(24, "apples", "24 apples"), quantity(8, "apples per box", "8 apples in each box")]),
        ask("How many boxes are there?"),
        steps([step("division", [24, 8], 3)]),
        answer(3, "boxes"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L1'), grade('3'), record_id('im_defrag_affa8e52e5c9cd398ea73b0d_1'), statement_sha('529d314a630942c199e602c2fde21a50b4d7c06dfb5acf1502b89dbfc3ae70b6')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_b0193da0036735340e98dcf8_1', "Solve each equation mentally: 247 + c = 458",
    analysis(
        quantities([quantity(247, "number", "247"), quantity(458, "number", "458")]),
        ask("Find the value of the constant c that satisfies the equation 247 + c = 458."),
        steps([step("subtraction", [458, 247], 211)]),
        answer(211, "number"),
        missing_doing("solving an algebraic equation")),
    anchor(lesson('IM-G7-U5-L6'), grade('7'), record_id('im_defrag_b0193da0036735340e98dcf8_1'), statement_sha('fdd413616208d674eff8e925a7b8dedef381cdd8a357c43533c9088774cb0937')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_b044a6134e3c5eecbadaac0b_1', "At recess, 42 students played a game. There were 3 teams with the same number of students on each team. How many students were on each team? Show your thinking using diagrams, symbols, or other representations.",
    analysis(
        quantities([quantity(42, "students", "42 students"), quantity(3, "teams", "3 teams")]),
        ask("How many students were on each team?"),
        steps([step("division", [42, 3], 14)]),
        answer(14, "students"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L18'), grade('3'), record_id('im_defrag_b044a6134e3c5eecbadaac0b_1'), statement_sha('076d1e98febb0a4e0c5d8e6c1d28833140c2b01f651abac4b1483e7dc4d66824')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_b099096220789cb705a8b867_1', "Represent the story with drawings and count all or count on from 6. • Represent the story with 6 + 3 and count on from 6.",
    analysis(
        quantities([quantity(6, "number", "6"), quantity(3, "number", "3")]),
        ask("Represent the story with 6 + 3 and count on from 6."),
        steps([step("addition", [6, 3], 9)]),
        answer(9, "number"),
        missing_doing("visual representation and counting-on strategy")),
    anchor(lesson('IM-G1-U2-L2'), grade('1'), record_id('im_defrag_b099096220789cb705a8b867_1'), statement_sha('a38753c305c77ff402735e349d01fec1ff27ace1a2810ebe920d97e5ad9e4924')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_b0d92ecc9faae5688d81db03_1', "60 × 10 = 30 × 20",
    analysis(
        quantities([quantity(60, "number", "60"), quantity(10, "number", "10"), quantity(30, "number", "30"), quantity(20, "number", "20")]),
        ask("Determine if the equation 60 × 10 = 30 × 20 is true."),
        steps([step("multiplication", [60, 10], 600), step("multiplication", [30, 20], 600), step("compare_equal", [600, 600], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U5-L18'), grade('5'), record_id('im_defrag_b0d92ecc9faae5688d81db03_1'), statement_sha('0dcb65e084bc3dd057dde0a11931a0ef4cdf0d13ef76c13792624d2861bfa13a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_b11c0d36684d60cfa72cab3e_1', "The calculation below has an error. 1. Explain the error. 2. Find the correct value of 38.7 + 9.46.",
    analysis(
        quantities([quantity(38.7, "number", "38.7"), quantity(9.46, "number", "9.46")]),
        ask("Find the correct value of 38.7 + 9.46."),
        steps([step("addition", [38.7, 9.46], 48.16)]),
        answer(48.16, "number"),
        missing_doing("error analysis")),
    anchor(lesson('IM-G5-U5-L13'), grade('5'), record_id('im_defrag_b11c0d36684d60cfa72cab3e_1'), statement_sha('ddf156a1647d389db24de5f038a364a5cb0c82f49c6f197663c7e3d62351a615')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_b1e3d00adc5367f410c523c0_1', "Find the value of 65 - 18.",
    analysis(
        quantities([quantity(65, "number", "65"), quantity(18, "number", "18")]),
        ask("Find the value of 65 - 18."),
        steps([step("subtraction", [65, 18], 47)]),
        answer(47, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U4-L11'), grade('2'), record_id('im_defrag_b1e3d00adc5367f410c523c0_1'), statement_sha('d7a6d8ee1e4883503db4d49b6984e95e0f975541a55ab8ee8b3de7c753f695b4')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_5.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_b1e674e89f655723f3090e66_1', "Clare has 14 roses. She wants to give each of her teachers 2 roses. How many teachers can she give roses to? Write a multiplication equation and a division equation to represent the situation. Use symbols for the unknown and explain your reasoning.",
    analysis(
        quantities([quantity(14, "roses", "14 roses"), quantity(2, "roses per teacher", "2 roses")]),
        ask("How many teachers can Clare give roses to, and what are the multiplication and division equations that represent this situation?"),
        steps([step("division", [14, 2], 7)]),
        answer(7, "teachers"),
        missing_doing("formulating mathematical equations and explaining reasoning")),
    anchor(lesson('IM-G3-U4-L7'), grade('3'), record_id('im_defrag_b1e674e89f655723f3090e66_1'), statement_sha('a0b995d1c81a63aae168dc47a838d30f19166d4e4ae846d933144dda7354cbe5')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_b1fd0b2348d3bd6577f5d288_1', "10 people ride bikes. 6 people stop. How many now?",
    analysis(
        quantities([quantity(10, "people", "10 people"), quantity(6, "people", "6 people")]),
        ask("How many people are still riding bikes?"),
        steps([step("subtraction", [10, 6], 4)]),
        answer(4, "people"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U4-L14'), grade('K'), record_id('im_defrag_b1fd0b2348d3bd6577f5d288_1'), statement_sha('10f26c6ea6d7115e643062e45906a2307d4c0c37066d8bec4b9a8457ee26ef0c')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_b21fd4fb3681a9422420de1c_1', "For each situation: • Write an equation to represent the situation. Use a symbol to represent the unknown. • Draw a diagram to show the comparison. • Answer the question about the situation. 1. Lin read 7 books. Diego read 8 times as many A books as Lin. a. Equation: b. Diagram: c. How many books did Diego read? 2. Tyler has some books. Clare has 72 books, which is 12 times as many books as Tyler. a. Equation: b. Diagram: c. How many books does Tyler have? 3. Noah read 13 books. Elena read 130 books. a. Equation: b. Diagram: c. Complete the statement: _______________ read _____ times as many books as _______________.",
    analysis(
        quantities([quantity(13, "books", "13 books"), quantity(130, "books", "130 books")]),
        ask("How many times as many books as Noah did Elena read?"),
        steps([step("division", [130, 13], 10)]),
        answer(10, "times"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U5-L4'), grade('4'), record_id('im_defrag_b21fd4fb3681a9422420de1c_1'), statement_sha('d0cfde17030890b3e748e5fbdbd9f3954feb9cc1772566e0d49712b8251afec8')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_0.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_b22cbf3814462f65d2926c8b_1', "Explain how the product of 3 and 65 could be used to find (0.03) · (0.65). [3 times 65 equals 195]",
    analysis(
        quantities([quantity(3, "number", "3"), quantity(65, "number", "65"), quantity(0.03, "number", "0.03"), quantity(0.65, "number", "0.65"), quantity(195, "number", "195")]),
        ask("How can the product of 3 and 65 be used to find the product of 0.03 and 0.65?"),
        steps([step("multiply", [3, 65], 195), step("divide", [195, 10000], 0.0195)]),
        answer(0.0195, "number"),
        missing_doing("explain decimal placement")),
    anchor(lesson('IM-G6-U5-L8'), grade('6'), record_id('im_defrag_b22cbf3814462f65d2926c8b_1'), statement_sha('c467939f790ff5b992f5a49bb9b7bc7cff27def21b0ffc1782f8473725ea1b17')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_b3cfcb414f290f4d421ce6a2_1', "Mai walked 1/8 of a 30-mile walking trail. How many miles did Mai walk? (1/8 of 30 is 30/8 = 3.75)",
    analysis(
        quantities([quantity(0.125, "fraction", "1/8"), quantity(30, "miles", "30-mile")]),
        ask("How many miles did Mai walk?"),
        steps([step("multiplication", [0.125, 30], 3.75)]),
        answer(3.75, "miles"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U5-L12'), grade('6'), record_id('im_defrag_b3cfcb414f290f4d421ce6a2_1'), statement_sha('7375f5aa458babfd40f21af896df4166a99d4f26571061449830758d4850463b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_b3f53d4dbeb26bd7047b4be3_1', "7 + 40",
    analysis(
        quantities([quantity(7, "number", "7"), quantity(40, "number", "40")]),
        ask("What is the sum of 7 and 40?"),
        steps([step("addition", [7, 40], 47)]),
        answer(47, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U4-L10'), grade('1'), record_id('im_defrag_b3f53d4dbeb26bd7047b4be3_1'), statement_sha('7bc79078bb89b1ddf80dc2fa02d2bd24b0f5547693a1c8d24fb2446372c80d94')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_b414b2f16cbc6135122b0e4f_1', "Suppose you need 80 ml of maroon paint. How much red paint? (10 batches, 5 ml red per batch)",
    analysis(
        quantities([quantity(80, "ml", "80 ml"), quantity(10, "batches", "10 batches"), quantity(5, "ml", "5 ml")]),
        ask("How much red paint is needed for 10 batches if each batch requires 5 ml of red paint?"),
        steps([step("multiplication", [10, 5], 50)]),
        answer(50, "ml"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L15'), grade('6'), record_id('im_defrag_b414b2f16cbc6135122b0e4f_1'), statement_sha('e2c32ea7269a1797f921b69974ca9f31cc5b2a8f35dc5605adad6577d436c77f')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_b45414ee0cac56d2068d1dc1_1', "3 × 40 = 7 × 10",
    analysis(
        quantities([quantity(3, "number", "3"), quantity(40, "number", "40"), quantity(7, "number", "7"), quantity(10, "number", "10")]),
        ask("Determine if 3 multiplied by 40 is equal to 7 multiplied by 10."),
        steps([step("multiplication", [3, 40], 120), step("multiplication", [7, 10], 70), step("compare_equal", [120, 70], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L17'), grade('3'), record_id('im_defrag_b45414ee0cac56d2068d1dc1_1'), statement_sha('527cf78d2cb58d7e82fc740d34b083c9c13f70cfc7f1a2ea40ae7a298126a58a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_b48821e5751e0c1e2df429f9_1', "Find the value of each subtraction expression: 7 − 4",
    analysis(
        quantities([quantity(7, "number", "7"), quantity(4, "number", "4")]),
        ask("What is the value of the subtraction expression 7 minus 4?"),
        steps([step("subtraction", [7, 4], 3)]),
        answer(3, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U5-L6'), grade('7'), record_id('im_defrag_b48821e5751e0c1e2df429f9_1'), statement_sha('e7a7d07a1391393997860fa23a4b09126838fa19558f78dfea8828071ccc5eea')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_b48fdb43ee757766222f47a8_1', "Children found shells and rocks at the beach. They found 8 more shells than rocks. They found 19 rocks. How many shells did the children find? 1. Circle the diagram that matches the story problem. 2. Explain how you know the diagram matches the story.",
    analysis(
        quantities([quantity(8, "shells", "8 more shells"), quantity(19, "rocks", "19 rocks")]),
        ask("How many shells did the children find?"),
        steps([step("addition", [19, 8], 27)]),
        answer(27, "shells"),
        missing_doing("diagram selection and verbal explanation")),
    anchor(lesson('IM-G2-U1-L15'), grade('2'), record_id('im_defrag_b48fdb43ee757766222f47a8_1'), statement_sha('a150244c5333e5b1fc1668f1aedf45d4c6e9fe7d1acb1c09656e266f26b0fe6e')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_b4c7e648761ae2dfaa3f41ca_1', "24 × 10 = 240",
    analysis(
        quantities([quantity(24, "number", "24"), quantity(10, "number", "10"), quantity(240, "number", "240")]),
        ask("Is 24 multiplied by 10 equal to 240?"),
        steps([step("multiplication", [24, 10], 240), step("compare_equal", [240, 240], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U7-L2'), grade('3'), record_id('im_defrag_b4c7e648761ae2dfaa3f41ca_1'), statement_sha('cd96ba4121795eab6416fbc7b100f839d37fbdb8e21006dcf7b7b1ea47e2c01b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_b663459c9ba4b5df0ffb91e8_1', "There are 30 muffins for the bake sale. Each box has 6 muffins. How many boxes are there?",
    analysis(
        quantities([quantity(30, "muffins", "30 muffins"), quantity(6, "muffins per box", "6 muffins")]),
        ask("How many boxes are needed to hold the 30 muffins if each box holds 6 muffins?"),
        steps([step("division", [30, 6], 5)]),
        answer(5, "boxes"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L6'), grade('3'), record_id('im_defrag_b663459c9ba4b5df0ffb91e8_1'), statement_sha('d47e12716fd6e81c86334fa42a7991a74931fdefd8a33e793843e786ba713c41')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_b6658d242ccf6e8ccbe0701b_1', "Sixteen socks are put into pairs. How many pairs are there?",
    analysis(
        quantities([quantity(16, "socks", "Sixteen")]),
        ask("How many pairs of socks can be made from sixteen socks?"),
        steps([step("division", [16, 2], 8)]),
        answer(8, "pairs"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U4-L2'), grade('6'), record_id('im_defrag_b6658d242ccf6e8ccbe0701b_1'), statement_sha('db337f8b1b226ebb1a5f82f74485c0e868b5cf86f7722c85865addb3b0cdba44')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_0.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_b69904e16850b39a13f16cd9_1', "3,005 = 4,000- 1,995",
    analysis(
        quantities([quantity(3005, "number", "3,005"), quantity(4000, "number", "4,000"), quantity(1995, "number", "1,995")]),
        ask("Is the equation 3,005 = 4,000 - 1,995 true?"),
        steps([step("subtraction", [4000, 1995], 2005), step("compare_equal", [3005, 2005], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U6-L24'), grade('4'), record_id('im_defrag_b69904e16850b39a13f16cd9_1'), statement_sha('1e69359bfdcf44b083911f9c8bf98e78474c99e0c3281774fac27b764b056ee6')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_b6db041605c0cb541bb724b4_1', "1. Elena’s string is much too long. The string is 65 inches long. Elena cuts 33 inches off the length. How long is the string now? Choose 2 number lines that show a way to find the length of Elena’s string. a. b. c. 2. Han has 87 inches of string. He cuts off 85 inches of it. How much string does he have left? a. Write an equation to represent the problem. Use a ? for the unknown. b. Find the number that makes the equation true. c. Show your thinking using the number line. 3. Find someone who used a different method. Show their method on the number line.",
    analysis(
        quantities([quantity(65, "inches", "65 inches"), quantity(33, "inches", "33 inches"), quantity(87, "inches", "87 inches"), quantity(85, "inches", "85 inches")]),
        ask("The problem contains multiple tasks: 1. Find the remaining length of Elena's 65-inch string after cutting off 33 inches. 2. Find how much string Han has left after cutting 85 inches off an 87-inch string, including writing an equation and solving it."),
        steps([step("subtraction", [65, 33], 32), step("subtraction", [87, 85], 2)]),
        answer(32, "inches"),
        missing_doing("multiple tasks")),
    anchor(lesson('IM-G2-U4-L9'), grade('2'), record_id('im_defrag_b6db041605c0cb541bb724b4_1'), statement_sha('b95350ea63f3cf179f29564ec0ba448cd2d3f0273531677cb47265721c421ae3')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_2.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_b7a0ae73b2f490a10669827f_1', "3 + 3 = 6",
    analysis(
        quantities([quantity(3, "number", "3"), quantity(3, "number", "3"), quantity(6, "number", "6")]),
        ask("Is the equation 3 + 3 = 6 true?"),
        steps([step("addition", [3, 3], 6), step("compare_equal", [6, 6], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U7-L4'), grade('K'), record_id('im_defrag_b7a0ae73b2f490a10669827f_1'), statement_sha('ee340ae51a322ad001c68d5c860e63c9510634a2a15da33e6447e2c7901ca6e0')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_b7f68b5d73ebc388252aa83b_1', "Clare paid full price. Han bought the same item for 80% of the full price. Did Clare pay 125% of what Han paid?",
    analysis(
        quantities([quantity(80, "percent", "80%"), quantity(125, "percent", "125%")]),
        ask("Did Clare pay 125% of what Han paid?"),
        steps([step("divide", [125, 100], 1.25), step("multiply", [1.25, 80], 100), step("compare_equal", [100, 100], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U3-L13'), grade('6'), record_id('im_defrag_b7f68b5d73ebc388252aa83b_1'), statement_sha('98cab545db14e9e660fc345d003bfe6f89f3c46313dd994d8abf2a6e8869c428')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_b80965fdc4815c1562766220_1', "There are 6 counters outside the cup. Some of the counters are under the cup. There are 10 counters total. How many counters are under the cup?",
    analysis(
        quantities([quantity(6, "counters", "6 counters"), quantity(10, "counters", "10 counters total")]),
        ask("How many counters are under the cup?"),
        steps([step("-", [10, 6], 4)]),
        answer(4, "counters"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U2-L8'), grade('1'), record_id('im_defrag_b80965fdc4815c1562766220_1'), statement_sha('20bcfba9cb26bd4174c99690b5502fc6c4674e5670acf171f77d1174031b34e2')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_b82622765d5323399ba38498_1', "compare 420 and 590",
    analysis(
        quantities([quantity(420, "number", "420"), quantity(590, "number", "590")]),
        ask("Compare the numbers 420 and 590."),
        steps([step("compare_equal", [420, 590], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U5-L9'), grade('2'), record_id('im_defrag_b82622765d5323399ba38498_1'), statement_sha('a40d40e68637976301000bf886d548f825efec30296dd15a591fa7782cf4c631')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_b872b0c1dfc7544b97c89a53_1', "How many 4s are in 12?",
    analysis(
        quantities([quantity(4, "4s", "4s"), quantity(12, "number", "12")]),
        ask("How many 4s are in 12?"),
        steps([step("divide", [12, 4], 3)]),
        answer(3, "4s"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U4-L10'), grade('6'), record_id('im_defrag_b872b0c1dfc7544b97c89a53_1'), statement_sha('20ea79611c9c1b6533bc38dfd14e861fc0d0dc6f445b4f6d9d97f857ce5a39ea')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_b9f5b7b8c385cbbb5d88c06f_1', "3 + 6 = 6 + 4",
    analysis(
        quantities([quantity(3, "number", "3"), quantity(6, "number", "6"), quantity(6, "number", "6"), quantity(4, "number", "4")]),
        ask("Is the equation 3 + 6 = 6 + 4 true?"),
        steps([step("addition", [3, 6], 9), step("addition", [6, 4], 10), step("compare_equal", [9, 10], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L3'), grade('1'), record_id('im_defrag_b9f5b7b8c385cbbb5d88c06f_1'), statement_sha('b8475106c93f4118853185a6b1fa544c16c3cdcf65aedc4dc6549c5d9cad5a8b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_ba30c7bbad71667765a4345e_1', "8 × 20 = 16 × 10",
    analysis(
        quantities([quantity(8, "number", "8"), quantity(20, "number", "20"), quantity(16, "number", "16"), quantity(10, "number", "10")]),
        ask("Is 8 times 20 equal to 16 times 10?"),
        steps([step("multiplication", [8, 20], 160), step("multiplication", [16, 10], 160), step("compare_equal", [160, 160], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L19'), grade('3'), record_id('im_defrag_ba30c7bbad71667765a4345e_1'), statement_sha('9c656732ffb46b66549a1a0ef3df288c230594c5105f44f2b89402411e391f99')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_ba4dee1fe8cf48fcb3690742_1', "Clare starts with 24 cubes and adds some more. She makes a train with 42 cubes. How many cubes does she add on?",
    analysis(
        quantities([quantity(24, "cubes", "24 cubes"), quantity(42, "cubes", "42 cubes")]),
        ask("How many cubes did Clare add to her initial 24 cubes to make a train of 42 cubes?"),
        steps([step("subtraction", [42, 24], 18)]),
        answer(18, "cubes"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U4-L13'), grade('2'), record_id('im_defrag_ba4dee1fe8cf48fcb3690742_1'), statement_sha('66a9258a2d75d3ef1eb8077487192f4712be99ec316132aaa9620dc9cd624719')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_ba7972acf3e52ac315674505_1', "Complete the table to represent a cheetah running at a constant speed. (120 meters in 4 seconds, find speed)",
    analysis(
        quantities([quantity(120, "meters", "120 meters"), quantity(4, "seconds", "4 seconds")]),
        ask("What is the constant speed of the cheetah in meters per second?"),
        steps([step("division", [120, 4], 30)]),
        answer(30, "meters per second"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U3-L6'), grade('6'), record_id('im_defrag_ba7972acf3e52ac315674505_1'), statement_sha('0b1077204a55ab3865fd72c5fdf892f32711610e4f32738f003f27fa5a39cf52')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_bae04d34db51ae947db4bbbd_1', "How would you find the value of 700- 599 ? Explain your reasoning.",
    analysis(
        quantities([quantity(700, "number", "700"), quantity(599, "number", "599")]),
        ask("What is the value of 700 minus 599?"),
        steps([step("subtraction", [700, 599], 101)]),
        answer(101, "number"),
        missing_doing("explanation of reasoning")),
    anchor(lesson('IM-G3-U3-L12'), grade('3'), record_id('im_defrag_bae04d34db51ae947db4bbbd_1'), statement_sha('dedd4c46648efe5eac22023cd36d12fae1d31b0fdfb0acb8cfd7ff7f16d1425d')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_bb0b21ab32a15a3023b3540a_1', "The table shows the pounds of food that 3 species of birds consume in a week. bird pounds of food a week ounces of food a week golden eagle 7 pelican 20 cardinal Complete the table to show how many ounces of food each species eats in a week.",
    analysis(
        quantities([quantity(3, "species", "3 species"), quantity(7, "pounds", "7"), quantity(20, "pounds", "20")]),
        ask("Calculate the number of ounces of food each of the three bird species eats in a week, given their consumption in pounds."),
        steps([step("multiply", [7, 16], 112), step("multiply", [20, 16], 320)]),
        answer(112, "ounces"),
        missing_doing("completing a table")),
    anchor(lesson('IM-G4-U5-L11'), grade('4'), record_id('im_defrag_bb0b21ab32a15a3023b3540a_1'), statement_sha('78eadf22ee216fe86e4a8f1790c12d1b8e22b3ca25b4691ae4414b263e5bb752')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_0.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_bb22e4711faf849b6de97d57_1', "How much higher is 500 than 400 m? (from Unit 5, Lesson 6)",
    analysis(
        quantities([quantity(500, "m", "500"), quantity(400, "m", "400 m")]),
        ask("What is the difference in height between 500 m and 400 m?"),
        steps([step("subtraction", [500, 400], 100)]),
        answer(100, "m"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U5-L12'), grade('7'), record_id('im_defrag_bb22e4711faf849b6de97d57_1'), statement_sha('c8ee96c6f9bf844130ea02722a52cb1c69ffba46f237b2703bd90bace91768c0')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_bb31f801769b3a37b0210666_1', "Jada has some stamps. She gives Tyler 4 stamps. Now Jada has 9 stamps left. How many stamps did Jada have before she gave some to Tyler? Circle the 2 equations that match the story. A. B. C. D.",
    analysis(
        quantities([quantity(4, "stamps", "4 stamps"), quantity(9, "stamps", "9 stamps")]),
        ask("How many stamps did Jada have originally?"),
        steps([step("addition", [4, 9], 13)]),
        answer(13, "stamps"),
        missing_doing("selecting the correct equations from multiple choice options")),
    anchor(lesson('IM-G1-U6-L14'), grade('1'), record_id('im_defrag_bb31f801769b3a37b0210666_1'), statement_sha('b96b5124f9ff942b75c916a20f1cf93a648d21c80f39f3e3c2f5aa6b047817cc')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_bc53b4cd1cc684780f180a27_1', "Use the grid to create a rectangular area that represents the expression 7 × 4. Explain your reasoning.",
    analysis(
        quantities([quantity(7, "number", "7"), quantity(4, "number", "4")]),
        ask("Create a rectangular area on a grid that represents the expression 7 × 4 and explain the reasoning."),
        steps([step("multiplication", [7, 4], 28)]),
        answer(28, "area"),
        missing_doing("drawing a grid-based rectangle")),
    anchor(lesson('IM-G3-U2-L5'), grade('3'), record_id('im_defrag_bc53b4cd1cc684780f180a27_1'), statement_sha('09f297dd011e5583ca8068f37fca3cc4d007f94a2dd5d82c4a1c160bab4fefe0')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_bc6a541c24d5fd6b08eea9e5_1', "Use long division to express each fraction as a decimal. 9/25",
    analysis(
        quantities([quantity(9, "numerator", "9"), quantity(25, "denominator", "25")]),
        ask("Express the fraction 9/25 as a decimal using long division."),
        steps([step("division", [9, 25], 0.36)]),
        answer(0.36, "decimal"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U4-L5'), grade('7'), record_id('im_defrag_bc6a541c24d5fd6b08eea9e5_1'), statement_sha('2f83165c4487811b1cf08bc6e35a93bc69c8442edeae4ac0d28c53f11f678cf1')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_bd4de44cb53d349ded9c13d5_1', "How long will it take until the tank starts overflowing or the fish get sick? (needs 2,000 more liters, rising at 10 L/min)",
    analysis(
        quantities([quantity(2000, "liters", "2,000 more liters"), quantity(10, "L/min", "10 L/min")]),
        ask("How many minutes will it take for the tank to need 2,000 more liters to overflow, given it is rising at 10 L/min?"),
        steps([step("division", [2000, 10], 200)]),
        answer(200, "minutes"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U5-L12'), grade('7'), record_id('im_defrag_bd4de44cb53d349ded9c13d5_1'), statement_sha('d5d5a2a8c53ed9290839b32d2ca106e275ca1807f8b6b055f61beab26680ae77')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_bd7b1015947b80572941758f_1', "6 + 2 = 8 + 1",
    analysis(
        quantities([quantity(6, "number", "6"), quantity(2, "number", "2"), quantity(8, "number", "8"), quantity(1, "number", "1")]),
        ask("Determine if the equation 6 + 2 = 8 + 1 is true."),
        steps([step("addition", [6, 2], 8), step("addition", [8, 1], 9), step("compare_equal", [8, 9], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L3'), grade('1'), record_id('im_defrag_bd7b1015947b80572941758f_1'), statement_sha('5b2f28eb500bc9bd323a998aa4083d2f86b623e14bb344e8283bc24c80d61252')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_bd7dc33e6f4df781b20e34c4_1', "For each problem: a. Write an equation to represent the situation. Use a letter for the unknown quantity. b. Solve the problem. Explain or show your reasoning. 1. Kiran made paper rings each day at school for a party. From Monday to Thursday, he was able to complete 156 rings. On Friday, Kiran and 2 friends made more rings. Each of them made 9 rings. How many rings were complete at the end of the week? 2. Mai has 168 muffins. She put 104 of the muffins in a basket. She packs the rest of the muffins into 8 boxes, with the same number of muffins in each box. How many muffins are in each box? 3. There are 184 chairs in stacks. Jada puts some of the chairs at 3 tables. She puts 8 chairs at each table. How many chairs are still in stacks?",
    analysis(
        quantities([quantity(156, "rings", "156 rings"), quantity(2, "friends", "2 friends"), quantity(9, "rings", "9 rings")]),
        ask("How many rings were complete at the end of the week?"),
        steps([step("addition", [1, 2], 3), step("multiplication", [3, 9], 27), step("addition", [156, 27], 183)]),
        answer(183, "rings"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L17'), grade('3'), record_id('im_defrag_bd7dc33e6f4df781b20e34c4_1'), statement_sha('f975946f0a7e0b7965883ca19e44a9b997046b7eb6b4ff4198020b6547130f27')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_bd8ccbd23a46ade715940827_1', "There are 4 soccer fields. Two teams are on each field.",
    analysis(
        quantities([quantity(4, "soccer fields", "4 soccer fields"), quantity(2, "teams", "Two teams")]),
        ask("How many teams are there in total?"),
        steps([step("multiply", [4, 2], 8)]),
        answer(8, "teams"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U1-L12'), grade('3'), record_id('im_defrag_bd8ccbd23a46ade715940827_1'), statement_sha('81c337d235f20e611d6247f6f8cec7a0517f597fd012baac2593fec4223ec8ce')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_4.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_bd9e532897fd3ca2d7a861ea_1', "6 + 3 = 8",
    analysis(
        quantities([quantity(6, "number", "6"), quantity(3, "number", "3"), quantity(8, "number", "8")]),
        ask("Is the equation 6 + 3 = 8 true?"),
        steps([step("addition", [6, 3], 9), step("compare_equal", [9, 8], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L4'), grade('1'), record_id('im_defrag_bd9e532897fd3ca2d7a861ea_1'), statement_sha('24431b39ec08fc22ae54bcafe32d44c134e4099b908fd6c0f99847304936d98c')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_bd9e81cbed9e43e81a4bd2e2_1', "Find the value of 75 - 9. Show your thinking.",
    analysis(
        quantities([quantity(75, "number", "75"), quantity(9, "number", "9")]),
        ask("What is the value of 75 minus 9?"),
        steps([step("subtraction", [75, 9], 66)]),
        answer(66, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U2-L5'), grade('2'), record_id('im_defrag_bd9e81cbed9e43e81a4bd2e2_1'), statement_sha('8efcf743530a31ac971782d10637fd481e33fb02e549654113972e835a6000c7')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_be59d214d8dba62772be299a_1', "1. On Thursday, Mai purchased a biography for $9 and a comic book for $4. The amount of total sales that day at the book fair was 8 times as much money as Mai spent. What was the amount of total sales for the book fair on Thursday? 2. On Friday, the sales at the book fair were $13 in the morning and 8 times as much as that in the afternoon. What was the amount of total sales for the book fair on Friday?",
    analysis(
        quantities([quantity(9, "$", "$9"), quantity(4, "$", "$4"), quantity(8, "times", "8 times"), quantity(13, "$", "$13"), quantity(8, "times", "8 times")]),
        ask("What was the amount of total sales for the book fair on Thursday and Friday?"),
        steps([step("addition", [9, 4], 13), step("multiplication", [13, 8], 104), step("multiplication", [13, 8], 104), step("addition", [13, 104], 117)]),
        answer(117, "dollars"),
        missing_doing("The problem asks for two separate values (Thursday and Friday sales).")),
    anchor(lesson('IM-G4-U5-L5'), grade('4'), record_id('im_defrag_be59d214d8dba62772be299a_1'), statement_sha('bf22bf94b49a478a6c810407c31e3b9dc0afc99c8a35af2aea45af3278e7d94d')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_0.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_beb76f121d55f718c3dd8707_1', "Elena has some bottles of water that each holds 17 fluid ounces. How much water is in 51 bottles? 17 · 51 = 867",
    analysis(
        quantities([quantity(17, "fluid ounces", "17 fluid ounces"), quantity(51, "bottles", "51 bottles")]),
        ask("How many fluid ounces of water are in 51 bottles if each bottle holds 17 fluid ounces?"),
        steps([step("multiplication", [17, 51], 867)]),
        answer(867, "fluid ounces"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U2-L6'), grade('7'), record_id('im_defrag_beb76f121d55f718c3dd8707_1'), statement_sha('3ef034eb1c4fcebee91e58034421d406a063f4163a8d210e7fb584099d0eaec3')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_beda8bf214273ce7477c30a9_1', "For each question, show your thinking using diagrams, symbols, or other representations. 1. On another field trip, 72 students and teachers rode in 3 buses to a science museum. The same number of people rode in each bus. How many people rode in each bus? 2. During lunch, the 72 people sat at long tables. There were 12 people at each table. How many tables did they use?",
    analysis(
        quantities([quantity(72, "people", "72 people"), quantity(12, "people per table", "12 people at each table")]),
        ask("How many tables did they use?"),
        steps([step("division", [72, 12], 6)]),
        answer(6, "tables"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L18'), grade('3'), record_id('im_defrag_beda8bf214273ce7477c30a9_1'), statement_sha('5c7b4c3fa4cbd6301e10f7d8a56bc48513aef97fdeb7eefd0be97ff56dd3339e')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_1.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_bef4d348619e1c49dca889c9_1', "Find the value of 241 × 23.",
    analysis(
        quantities([quantity(241, "number", "241"), quantity(23, "number", "23")]),
        ask("Find the value of 241 × 23."),
        steps([step("multiply", [241, 23], 5543)]),
        answer(5543, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U4-L6'), grade('5'), record_id('im_defrag_bef4d348619e1c49dca889c9_1'), statement_sha('d5eaf1b1e87d128dd3898a536be3c37cf70fc411f6efcfc3ba02deefd4d8d10d')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_2.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_bf0427bcde79e25d5f18baa7_1', "5 books are on a shelf. Clare puts 2 more books on the shelf.",
    analysis(
        quantities([quantity(5, "books", "5 books"), quantity(2, "books", "2 more books")]),
        ask("How many books are on the shelf now?"),
        steps([step("addition", [5, 2], 7)]),
        answer(7, "books"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U2-L1'), grade('1'), record_id('im_defrag_bf0427bcde79e25d5f18baa7_1'), statement_sha('e2e128e4710d25d759d3f939838b6c4c680aa2d4ee877ef9aab5c6190b8a8e2e')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_bf4556122d1d14fe5cac4af6_1', "Priya needs sand and rocks for her fish tank. She needs 3 pounds of sand. That amount is 4 times as much as the amount of rocks that she needs. How many ounces of rocks does she need? Explain or show your reasoning.",
    analysis(
        quantities([quantity(3, "pounds", "3 pounds"), quantity(4, "times", "4 times as much")]),
        ask("How many ounces of rocks does Priya need?"),
        steps([step("divide", [3, 4], 0.75), step("multiply", [0.75, 16], 12)]),
        answer(12, "ounces"),
        missing_doing("unit conversion")),
    anchor(lesson('IM-G4-U5-L13'), grade('4'), record_id('im_defrag_bf4556122d1d14fe5cac4af6_1'), statement_sha('981474ef36cd2432cad55faa19796186f0d8d7ba3702413c5d1c3faec38fc666')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_bf99600b556e393354124d59_1', "4 little speckled frogs sat on a speckled log, eating the most delicious bugs. Yum! Yum! 1 jumped into the pool, where it was nice and cool. Now there are 3 green speckled frogs. Glub! Glub! Kindergarten",
    analysis(
        quantities([quantity(4, "frogs", "4 little speckled frogs"), quantity(1, "frog", "1 jumped into the pool"), quantity(3, "frogs", "3 green speckled frogs")]),
        ask("The problem provides a narrative statement rather than asking a question, but it implies checking if the number of frogs remaining is correct."),
        steps([step("subtraction", [4, 1], 3)]),
        answer(3, "frogs"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U1-L11'), grade('K'), record_id('im_defrag_bf99600b556e393354124d59_1'), statement_sha('b2229ea1cfcf972e9169cece0dcd5461bd2ad7b8f326bd3ad88211a4b1aed843')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_bffcaf09cd532354f9777730_1', "5 books. He gets 1 more book. How many books does Diego have now?",
    analysis(
        quantities([quantity(5, "books", "5 books"), quantity(1, "book", "1 more book")]),
        ask("How many books does Diego have now?"),
        steps([step("addition", [5, 1], 6)]),
        answer(6, "books"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U2-L21'), grade('K'), record_id('im_defrag_bffcaf09cd532354f9777730_1'), statement_sha('7e807c50f5ee628ba7a309fd89aa77368c740abf4e17dfa61e717e3e85bc79f5')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c0092d6289f66ad6233c36ef_1', "5 + 3 = 1 + 7",
    analysis(
        quantities([quantity(5, "number", "5"), quantity(3, "number", "3"), quantity(1, "number", "1"), quantity(7, "number", "7")]),
        ask("Is the equation 5 + 3 = 1 + 7 true?"),
        steps([step("addition", [5, 3], 8), step("addition", [1, 7], 8), step("compare_equal", [8, 8], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L3'), grade('1'), record_id('im_defrag_c0092d6289f66ad6233c36ef_1'), statement_sha('8204429bb5f78265a474323f61cf49c67ec69dd6c659c0e6ccc00243eeaa0eee')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c00f594b125ff2eafe97bb87_1', "At $4 per pint, how much will 8 pints of raspberries cost?",
    analysis(
        quantities([quantity(4, "dollars per pint", "$4 per pint"), quantity(8, "pints", "8 pints")]),
        ask("How much will 8 pints of raspberries cost at a price of $4 per pint?"),
        steps([step("multiplication", [4, 8], 32)]),
        answer(32, "dollars"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U3-L5'), grade('6'), record_id('im_defrag_c00f594b125ff2eafe97bb87_1'), statement_sha('f81b40254c649a6611af99b8355befb02aba32064dca23db2370167c22f88bf2')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c08d6a69399afadead60da5c_1', "Find the value of each expression. Use the diagrams if they are helpful. 1. 0.3 × 0.6 2. 1.3 × 0.6",
    analysis(
        quantities([quantity(0.3, "number", "0.3"), quantity(0.6, "number", "0.6")]),
        ask("What is the value of 0.3 × 0.6?"),
        steps([step("multiplication", [0.3, 0.6], 0.18)]),
        answer(0.18, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U5-L20'), grade('5'), record_id('im_defrag_c08d6a69399afadead60da5c_1'), statement_sha('a2cc3227af33afd6f49c69bdb4f0db791cd14035d3bb72c9ba81f40f5941b67f')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c0c78b0e97e8a8f0200e4ca9_1', "1. The large square represents 1. It is divided into 10 equal-size rectangles. What number does the shaded rectangle represent? Explain or show your reasoning. 2. Each rectangle part from the previous diagram is now divided into 10 equal-size small squares. What number does the shaded small square represent? Explain or show your reasoning. 3. The shaded small square from the previous diagram is now divided into 10 equal-size small rectangles. One of those small rectangles is shaded. What number does the shaded small rectangle represent? Explain or show your reasoning. 4. How do you think is written as a decimal? Explain fract or show your reasoning.",
    analysis(
        quantities([quantity(1, "large square", "large square represents 1"), quantity(10, "rectangles", "10 equal-size rectangles"), quantity(10, "small squares per rectangle", "divided into 10 equal-size small squares"), quantity(10, "small rectangles per small square", "divided into 10 equal-size small rectangles")]),
        ask("What decimal represents the final shaded small rectangle?"),
        steps([step("division", [1, 10], 0.1), step("division", [0.1, 10], 0.01), step("division", [0.01, 10], 0.001)]),
        answer(0.001, "decimal"),
        missing_doing("visualizing spatial subdivision")),
    anchor(lesson('IM-G5-U5-L1'), grade('5'), record_id('im_defrag_c0c78b0e97e8a8f0200e4ca9_1'), statement_sha('087146225f55d81b4e4420ea9e2297da16f05adc1cd3fb38372940315ac23356')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c140e9224aab6df630226d1b_1', "4 × 18 Record an estimate that is: too low about right too",
    analysis(
        quantities([quantity(4, "number", "4"), quantity(18, "number", "18")]),
        ask("Provide an estimate for 4 times 18 and classify it as too low, about right, or too high."),
        steps([step("multiply", [4, 18], 72)]),
        answer(72, "number"),
        missing_doing("evaluating the quality of an estimate")),
    anchor(lesson('IM-G3-U4-L13'), grade('3'), record_id('im_defrag_c140e9224aab6df630226d1b_1'), statement_sha('a7dc728d553701ed5c42be47d9007171139b60cc07f4c5d61b98cede3df5cede')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_3.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c14dbafcc0cfd50db5d8b322_1', "30 + 45 = 75",
    analysis(
        quantities([quantity(30, "number", "30"), quantity(45, "number", "45"), quantity(75, "number", "75")]),
        ask("Is the equation 30 + 45 = 75 true?"),
        steps([step("addition", [30, 45], 75), step("compare_equal", [75, 75], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U6-L10'), grade('1'), record_id('im_defrag_c14dbafcc0cfd50db5d8b322_1'), statement_sha('69f5b6335ab03d06350aaa1824044e92c268d3f43862432dec2fefe9983dd5fe')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c16068fab5049d9b47934bae_1', "There are 6 students. There are 4 paint brushes. Are there more students or paint brushes? How many more? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(6, "students", "6 students"), quantity(4, "paint brushes", "4 paint brushes")]),
        ask("Are there more students or paint brushes, and what is the difference between the two quantities?"),
        steps([step("subtraction", [6, 4], 2)]),
        answer(2, "students"),
        missing_doing("comparison")),
    anchor(lesson('IM-G1-U2-L12'), grade('1'), record_id('im_defrag_c16068fab5049d9b47934bae_1'), statement_sha('516eed86c07737f9d8ebf7c8a330c044087fff3d16c7933355a35fb6bcc21193')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c17a84a7754b0abe5aae0422_1', "Show your thinking using drawings, numbers, or words. 1. Jada sees birds at the zoo. She sees 3 herons, 6 hawks, and 7 hummingbirds. How many birds does Jada see? 2. Jada sees large cats. There were 8 lions, 4 tigers, and 3 cheetahs. How many large cats are there? 3. Jada goes to the petting zoo. She pets 8 goats, 7 sheep, and 4 pigs. How many animals does Jada pet?",
    analysis(
        quantities([quantity(3, "herons", "3 herons"), quantity(6, "hawks", "6 hawks"), quantity(7, "hummingbirds", "7 hummingbirds"), quantity(8, "lions", "8 lions"), quantity(4, "tigers", "4 tigers"), quantity(3, "cheetahs", "3 cheetahs"), quantity(8, "goats", "8 goats"), quantity(7, "sheep", "7 sheep"), quantity(4, "pigs", "4 pigs")]),
        ask("How many birds does Jada see, how many large cats are there, and how many animals does Jada pet?"),
        steps([step("addition", [3, 6, 7], 16), step("addition", [8, 4, 3], 15), step("addition", [8, 7, 4], 19)]),
        answer(19, "animals"),
        missing_doing("The problem asks for three separate answers, making it impossible to provide a single numeric answer.")),
    anchor(lesson('IM-G1-U3-L20'), grade('1'), record_id('im_defrag_c17a84a7754b0abe5aae0422_1'), statement_sha('bd689a0800e8ae156f12ca36598409c4539a12137f8b832f61e0c68365c695ef')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_5.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c25af2b8b2200849121f48b9_1', "Write a multiplication equation ... this diagram could represent. [54 over three segments labeled 18, 18, 18]",
    analysis(
        quantities([quantity(54, "total", "54"), quantity(3, "number of segments", "three segments"), quantity(18, "segment length", "18")]),
        ask("What multiplication equation could the diagram represent?"),
        steps([step("multiply", [3, 18], 54)]),
        answer(54, "total"),
        missing_doing("formulate_equation")),
    anchor(lesson('IM-G6-U4-L3'), grade('6'), record_id('im_defrag_c25af2b8b2200849121f48b9_1'), statement_sha('12b8ab478d20e1d49f458b7c676c7556d941447d4b5558b131b766dc8757133f')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c2cc89a5da74ded920e58cf9_1', "3 + 2 = 3 + 2",
    analysis(
        quantities([quantity(3, "number", "3"), quantity(2, "number", "2"), quantity(3, "number", "3"), quantity(2, "number", "2")]),
        ask("Check if 3 + 2 is equal to 3 + 2."),
        steps([step("addition", [3, 2], 5), step("addition", [3, 2], 5), step("compare_equal", [5, 5], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L14'), grade('1'), record_id('im_defrag_c2cc89a5da74ded920e58cf9_1'), statement_sha('ee294214b9652bea6f5f77aeb1ca7084047f55214455f75d1eee4fd1a2bb0fd3')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c340e9c2b484afd7792ac6c6_1', "38 + 4 = 40 + 3",
    analysis(
        quantities([quantity(38, "number", "38"), quantity(4, "number", "4"), quantity(40, "number", "40"), quantity(3, "number", "3")]),
        ask("Check if 38 + 4 is equal to 40 + 3."),
        steps([step("addition", [38, 4], 42), step("addition", [40, 3], 43), step("compare_equal", [42, 43], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U1-L16'), grade('2'), record_id('im_defrag_c340e9c2b484afd7792ac6c6_1'), statement_sha('d452e37a23278cf3ec066703f65577d22f9150fe704c2ebf6ef9e2f515945424')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_0.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c36bb72a3327d4a45767023a_1', "[diagram] 10 cups over four boxes each labeled ?",
    analysis(
        quantities([quantity(10, "cups", "10 cups"), quantity(4, "boxes", "four boxes")]),
        ask("How many cups are in each box if 10 cups are distributed equally over four boxes?"),
        steps([step("division", [10, 4], 2.5)]),
        answer(2.5, "cups"),
        missing_doing("division")),
    anchor(lesson('IM-G6-U4-L3'), grade('6'), record_id('im_defrag_c36bb72a3327d4a45767023a_1'), statement_sha('f3530f76344c8b5f8491101121d91d255b8f81ba0d465e7787e8e359beabff2a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c37f9d5b654ac7efcc45f06f_1', "Diego had some counters in his cup. His teacher put 4 more counters in his cup. Now he has 9 counters in the cup. How many counters did Diego have before his teacher gave him more? Show your thinking using drawings, numbers, or words. Equation: __________________________",
    analysis(
        quantities([quantity(4, "counters", "4 more counters"), quantity(9, "counters", "9 counters")]),
        ask("How many counters did Diego have before his teacher gave him more?"),
        steps([step("subtraction", [9, 4], 5)]),
        answer(5, "counters"),
        missing_doing("modeling the relationship between the unknown initial quantity and the final total")),
    anchor(lesson('IM-G1-U3-L6'), grade('1'), record_id('im_defrag_c37f9d5b654ac7efcc45f06f_1'), statement_sha('89d046998bf5bcc71316c7d5ddf99cca7025a761fae8e1ff18ae0a9273206904')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c40c34704278ca24f3ac2170_1', "27 of the 0.1-ounce weights",
    analysis(
        quantities([quantity(27, "weights", "27"), quantity(0.1, "ounce", "0.1-ounce")]),
        ask("What is the total weight of 27 weights that are each 0.1 ounce?"),
        steps([step("multiplication", [27, 0.1], 2.7)]),
        answer(2.7, "ounce"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U5-L4'), grade('5'), record_id('im_defrag_c40c34704278ca24f3ac2170_1'), statement_sha('af59e331fac6b3b9f795919c7e9282662cc097dc23816cc00056ed26d83ff72d')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c4180fbb624b8d20d3a66d30_1', "10 + 15 = 15 + 10",
    analysis(
        quantities([quantity(10, "number", "10"), quantity(15, "number", "15"), quantity(15, "number", "15"), quantity(10, "number", "10")]),
        ask("Check if the sum of 10 and 15 is equal to the sum of 15 and 10."),
        steps([step("addition", [10, 15], 25), step("addition", [15, 10], 25), step("compare_equal", [25, 25], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U7-L15'), grade('1'), record_id('im_defrag_c4180fbb624b8d20d3a66d30_1'), statement_sha('d1c9734d09cfd63018bf1851000b666e18f2b478b1e67e065355cdadab8917bd')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c420a4f49b22bc76fcd5c892_1', "It took the Trieste about 3 hours to ascend back to sea level... What is the value of k in this situation? (3 * 60 * 60 = 10,800 seconds)",
    analysis(
        quantities([quantity(3, "hours", "3 hours"), quantity(10800, "seconds", "10,800 seconds")]),
        ask("What is the value of k in the situation where 3 hours is converted to 10,800 seconds using the equation 3 * 60 * 60 = k?"),
        steps([step("multiply", [3, 60], 180), step("multiply", [180, 60], 10800)]),
        answer(10800, "seconds"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U5-L12'), grade('7'), record_id('im_defrag_c420a4f49b22bc76fcd5c892_1'), statement_sha('399db51b3a72620c9d4c5df2cc59404632fbe0df638dccf0a2ff7a6f36460226')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c50985ed695c7a63df74fee0_1', "Kiran has 4 boxes. Each box has 5 pencils in it. How many pencils does Kiran have?",
    analysis(
        quantities([quantity(4, "boxes", "4 boxes"), quantity(5, "pencils per box", "5 pencils")]),
        ask("How many pencils does Kiran have in total?"),
        steps([step("multiplication", [4, 5], 20)]),
        answer(20, "pencils"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U1-L12'), grade('3'), record_id('im_defrag_c50985ed695c7a63df74fee0_1'), statement_sha('6bbc6a80600b74ea05c2db05dd6070a9a42477fd8169f7ae4634e2732bf0bed6')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c54990262b7aa3b0965d32c8_1', "1. Draw a diagram to show how much sandwich each person will get. 3 sandwiches are equally shared by 4 people. 2. Explain or show how you know that each person gets the same amount of sandwich.",
    analysis(
        quantities([quantity(3, "sandwiches", "3 sandwiches"), quantity(4, "people", "4 people")]),
        ask("How much sandwich will each person get if 3 sandwiches are shared equally among 4 people?"),
        steps([step("division", [3, 4], 0.75)]),
        answer(0.75, "sandwich"),
        missing_doing("visual representation")),
    anchor(lesson('IM-G5-U2-L1'), grade('5'), record_id('im_defrag_c54990262b7aa3b0965d32c8_1'), statement_sha('7af3b857200d0308e8b96199266ac50e152485dc72916a61c582dea77639df21')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c570834c77bfe20c84484503_1', "Solve. Show your thinking using drawings, numbers, or words. Write the units. 1. Andre’s ribbon is 50 inches long. He cuts off 26 inches of ribbon. Mai’s ribbon is now 8 inches longer than his ribbon. How long is her ribbon? 2. Han has 62 inches of ribbon. He cuts off 28 inches of ribbon. He keeps the rest. Clare has a ribbon that is 27 inches long. How much longer is Han’s ribbon than Clare’s ribbon?",
    analysis(
        quantities([quantity(50, "inches", "50 inches"), quantity(26, "inches", "26 inches"), quantity(8, "inches", "8 inches")]),
        ask("How long is Mai's ribbon?"),
        steps([step("subtraction", [50, 26], 24), step("addition", [24, 8], 32)]),
        answer(32, "inches"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U3-L12'), grade('2'), record_id('im_defrag_c570834c77bfe20c84484503_1'), statement_sha('35a947f81ab0cdc9340e1a603296bc9d9b570ef4a53f5cb5d5c3698907c42a33')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c57d42a419b143a8c71693ef_1', "Find the value of 8 + 47. Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(8, "number", "8"), quantity(47, "number", "47")]),
        ask("What is the value of 8 + 47?"),
        steps([step("addition", [8, 47], 55)]),
        answer(55, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U5-L5'), grade('1'), record_id('im_defrag_c57d42a419b143a8c71693ef_1'), statement_sha('639d551d1b56d40c32dbc19ef5933b5b60368f9f776f75d273479b1e71a906e0')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c5e731bef36092167e70021b_1', "1972- 63",
    analysis(
        quantities([quantity(1972, "number", "1972"), quantity(63, "number", "63")]),
        ask("What is the result of 1972 minus 63?"),
        steps([step("subtraction", [1972, 63], 1909)]),
        answer(1909, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U4-L19'), grade('4'), record_id('im_defrag_c5e731bef36092167e70021b_1'), statement_sha('3ad78dd5f6cca141e76839504a7e82c52be2fb61dfce94c726e30378782a0bc9')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c61089213a57f3c0a260a294_1', "7 pattern blocks. Her brother takes 3. How many now?",
    analysis(
        quantities([quantity(7, "pattern blocks", "7 pattern blocks"), quantity(3, "pattern blocks", "3")]),
        ask("How many pattern blocks are left after her brother takes 3?"),
        steps([step("subtraction", [7, 3], 4)]),
        answer(4, "pattern blocks"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U7-L5'), grade('K'), record_id('im_defrag_c61089213a57f3c0a260a294_1'), statement_sha('8a1962c22035171fddaf61293eeeb00915c50d0e10d2aaaaddf23be3dd0ddd9e')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c6996203b1aca8b485f84f00_1', "Clare’s shoe is 9 cubes long. Han’s shoe is 7 cubes long. How many cubes long are their shoes together?",
    analysis(
        quantities([quantity(9, "cubes", "9 cubes"), quantity(7, "cubes", "7 cubes")]),
        ask("How many cubes long are Clare's and Han's shoes combined?"),
        steps([step("addition", [9, 7], 16)]),
        answer(16, "cubes"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U6-L11'), grade('1'), record_id('im_defrag_c6996203b1aca8b485f84f00_1'), statement_sha('6b19e4d3573dfdcf32ee333425d37b147b6dd48bc8161b206c9e70040ddeb8e8')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c6f4a8e859b575b98082c117_1', "Use an algorithm of your choice to find the value of 365 + 182.",
    analysis(
        quantities([quantity(365, "number", "365"), quantity(182, "number", "182")]),
        ask("What is the value of 365 + 182?"),
        steps([step("addition", [365, 182], 547)]),
        answer(547, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U3-L5'), grade('3'), record_id('im_defrag_c6f4a8e859b575b98082c117_1'), statement_sha('9382b96f2b96c917ce74cc11d9616cadf68d912abbaff23b4768f90a38370215')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c6f856be515b0d94a3fde502_1', "Elena uses 189 square tiles to create a rectangular mural for the art club. The mural is 7 tiles wide. 1. How many tiles long is Elena’s mural? Explain or show your reasoning. 2. Write one or more equations that show how you solved this problem.",
    analysis(
        quantities([quantity(189, "square tiles", "189 square tiles"), quantity(7, "tiles wide", "7 tiles wide")]),
        ask("How many tiles long is Elena's mural?"),
        steps([step("division", [189, 7], 27)]),
        answer(27, "tiles long"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U6-L14'), grade('4'), record_id('im_defrag_c6f856be515b0d94a3fde502_1'), statement_sha('3df409571bbee53de7f21bb868750d3e9293f272be364c10563b24b60048f282')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c7defccecc434f2c2eb090e7_1', "Find the value of 6 × 40. Explain or show your reasoning.",
    analysis(
        quantities([quantity(6, "number", "6"), quantity(40, "number", "40")]),
        ask("What is the value of 6 multiplied by 40?"),
        steps([step("multiplication", [6, 40], 240)]),
        answer(240, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L12'), grade('3'), record_id('im_defrag_c7defccecc434f2c2eb090e7_1'), statement_sha('f22e28e7116444973f4878505f9ebe18750bec1607316f77f54cfaa411a3390f')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c7e53cf97304be1f478d2595_1', "A dance team used 60 bottles of water during their practices last week. Each bottle holds 750 mL. How many liters of water did the dance team drink during their practices?",
    analysis(
        quantities([quantity(60, "bottles", "60 bottles"), quantity(750, "mL", "750 mL")]),
        ask("How many liters of water did the dance team drink during their practices?"),
        steps([step("multiplication", [60, 750], 45000), step("division", [45000, 1000], 45)]),
        answer(45, "liters"),
        missing_doing("unit conversion")),
    anchor(lesson('IM-G5-U6-L6'), grade('5'), record_id('im_defrag_c7e53cf97304be1f478d2595_1'), statement_sha('7e440ff1f0a1b7dbf7368c41ab15db467f7e735ebf7e0532166569ab54ad6ff8')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c80674e5f8a503b9bdcd5954_1', "There are 5 balls on the playground. Diego brought 5 inside. How many now?",
    analysis(
        quantities([quantity(5, "balls", "5 balls"), quantity(5, "balls", "5 inside")]),
        ask("How many balls are there in total now?"),
        steps([step("addition", [5, 5], 10)]),
        answer(10, "balls"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U4-L9'), grade('K'), record_id('im_defrag_c80674e5f8a503b9bdcd5954_1'), statement_sha('bde9022472aa66d28831c1ce272dfde890d5b33879ba072cc2214e32c4530596')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c81decab1b0a6a7b13ee821c_1', "30 × 2 × 10 = 6 × 10",
    analysis(
        quantities([quantity(30, "number", "30"), quantity(2, "number", "2"), quantity(10, "number", "10"), quantity(6, "number", "6"), quantity(10, "number", "10")]),
        ask("Determine if the equation 30 × 2 × 10 = 6 × 10 is true."),
        steps([step("multiplication", [30, 2], 60), step("multiplication", [60, 10], 600), step("multiplication", [6, 10], 60), step("compare_equal", [600, 60], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U5-L18'), grade('5'), record_id('im_defrag_c81decab1b0a6a7b13ee821c_1'), statement_sha('32cdc5f2437893c2f3693effcb03eeedcd7d33f45a6f206a0d520cd053ec9d24')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c822ebcfdb3d4fbb10ace77a_1', "Find the value of each quotient mentally. 246 ÷ 12",
    analysis(
        quantities([quantity(246, "number", "246"), quantity(12, "number", "12")]),
        ask("What is the quotient of 246 divided by 12?"),
        steps([step("divide", [246, 12], 20.5)]),
        answer(20.5, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L8'), grade('6'), record_id('im_defrag_c822ebcfdb3d4fbb10ace77a_1'), statement_sha('d07ed51cdf94718d93e48344de9fe30a8051bf341f0bbb365adf13e86ce60df1')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c843ba007d12ac57c410a378_1', "42 + 5 = 47",
    analysis(
        quantities([quantity(42, "number", "42"), quantity(5, "number", "5"), quantity(47, "number", "47")]),
        ask("Is the equation 42 + 5 = 47 true?"),
        steps([step("addition", [42, 5], 47), step("compare_equal", [47, 47], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U5-L11'), grade('1'), record_id('im_defrag_c843ba007d12ac57c410a378_1'), statement_sha('944dac9da698f9279d705e8043d4da0faed9560de92802438ce9899ce081a772')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c845407fa290d32c2b303836_1', "How might Andre calculate 896 ÷ 4? Explain or show your reasoning.",
    analysis(
        quantities([quantity(896, "number", "896"), quantity(4, "number", "4")]),
        ask("How might Andre calculate the result of dividing 896 by 4?"),
        steps([step("division", [896, 4], 224)]),
        answer(224, "number"),
        missing_doing("explaining reasoning")),
    anchor(lesson('IM-G6-U5-L10'), grade('6'), record_id('im_defrag_c845407fa290d32c2b303836_1'), statement_sha('93f369a7db7549937f3a1a3ceb048cf51827bb27db826dda1d5a823400aa1fef')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c878d8848781a8df983b5577_1', "A rectangle is 6 feet by 15 feet. What is the area of the rectangle?",
    analysis(
        quantities([quantity(6, "feet", "6 feet"), quantity(15, "feet", "15 feet")]),
        ask("What is the area of the rectangle?"),
        steps([step("multiplication", [6, 15], 90)]),
        answer(90, "square feet"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L15'), grade('3'), record_id('im_defrag_c878d8848781a8df983b5577_1'), statement_sha('da87c86e50ca191b2680018c96a1724c5887b1eb3121cf6108bccff278f59f82')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c8bafaaef7babe7eb855ba3d_1', "A shop sells bagels for $5 per dozen. At this rate, how much would 6 bagels cost?",
    analysis(
        quantities([quantity(5, "dollars per dozen", "$5 per dozen"), quantity(12, "bagels per dozen", "dozen"), quantity(6, "bagels", "6 bagels")]),
        ask("How much would 6 bagels cost if a dozen bagels cost $5?"),
        steps([step("divide", [6, 12], 0.5), step("multiply", [0.5, 5], 2.5)]),
        answer(2.5, "dollars"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L12'), grade('6'), record_id('im_defrag_c8bafaaef7babe7eb855ba3d_1'), statement_sha('010beb8e2599f43feb3e0fb8cf30be14cfc1e1e138302d5e8cce64a2bba716a2')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c8bd609b43623007ee9772b1_1', "How many 6s are in 12?",
    analysis(
        quantities([quantity(6, "number", "6s"), quantity(12, "number", "12")]),
        ask("How many 6s are in 12?"),
        steps([step("division", [12, 6], 2)]),
        answer(2, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U4-L10'), grade('6'), record_id('im_defrag_c8bd609b43623007ee9772b1_1'), statement_sha('0f4842a277f3d886551fde737f45c4180d76798815d6fba4d180ae4ffeb6af9c')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c8cc2ebcc68696cc87e92ad4_1', "10- 0 = 12- 2",
    analysis(
        quantities([quantity(10, "number", "10"), quantity(0, "number", "0"), quantity(12, "number", "12"), quantity(2, "number", "2")]),
        ask("Is the equation 10 - 0 = 12 - 2 true?"),
        steps([step("subtraction", [10, 0], 10), step("subtraction", [12, 2], 10), step("compare_equal", [10, 10], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U3-L10'), grade('2'), record_id('im_defrag_c8cc2ebcc68696cc87e92ad4_1'), statement_sha('efeb0538f5120374d9220f32307b7a33349559b82d4d3443c56ed1ad33a31b8d')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c8de70e155818e900c3d01f1_1', "6 = 4 + 2",
    analysis(
        quantities([quantity(6, "number", "6"), quantity(4, "number", "4"), quantity(2, "number", "2")]),
        ask("Is 6 equal to 4 plus 2?"),
        steps([step("addition", [4, 2], 6), step("compare_equal", [6, 6], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U7-L4'), grade('K'), record_id('im_defrag_c8de70e155818e900c3d01f1_1'), statement_sha('4752d81d45027b5934456ad8acb0d61c4312ded4758c8620b17bb1e63336ab91')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c9877aaf92acf187936f38a6_1', "Use long division to find the value of 1,875 ÷ 5. Then check your answer by multiplying it by 5.",
    analysis(
        quantities([quantity(1875, "number", "1,875"), quantity(5, "number", "5")]),
        ask("Find the value of 1,875 divided by 5 and verify it by multiplying the result by 5."),
        steps([step("division", [1875, 5], 375), step("multiplication", [375, 5], 1875), step("compare_equal", [1875, 1875], true)]),
        answer(375, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U5-L11'), grade('6'), record_id('im_defrag_c9877aaf92acf187936f38a6_1'), statement_sha('5266877418ea9246c62242ae6fb13cd1e62d010532bd52b00e529ad68544ee91')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c9c02d97fa8109096552f207_1', "There are 4 bags. Each bag has 2 strawberries. b.",
    analysis(
        quantities([quantity(4, "bags", "4 bags"), quantity(2, "strawberries", "2 strawberries")]),
        ask("How many strawberries are there in total?"),
        steps([step("multiplication", [4, 2], 8)]),
        answer(8, "strawberries"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U1-L10'), grade('3'), record_id('im_defrag_c9c02d97fa8109096552f207_1'), statement_sha('41f2ed6d2629eb85cd951fd8477ebf259ad2cf1d2c53f7ae2a511831b3f791f6')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_c9d3d82869329267aabc1249_1', "There were 6 buckets of sunflowers at the farmers market. Each bucket had 11 sunflowers. How many sunflowers were in the buckets? Show your thinking using objects, a drawing, or a diagram.",
    analysis(
        quantities([quantity(6, "buckets", "6 buckets"), quantity(11, "sunflowers per bucket", "11 sunflowers")]),
        ask("How many sunflowers were in the buckets in total?"),
        steps([step("multiplication", [6, 11], 66)]),
        answer(66, "sunflowers"),
        missing_doing("representing the multiplication with a drawing or diagram")),
    anchor(lesson('IM-G3-U4-L13'), grade('3'), record_id('im_defrag_c9d3d82869329267aabc1249_1'), statement_sha('e20143c3130b0fdabb08fac749e6f835b4594f3f14c4e5f55df6bf4ac4f9f80c')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_ca0de041cc54d6e876fd6dc4_1', "1. There are 45 students going on a field trip to a museum. Tickets for the museum are $18 each. Teachers have $900 to buy tickets for the trip. Will this be enough money to buy a ticket for every student? If yes, will there be any leftover money? How much? If no, how much more money is needed? 2. Your teacher will show 5 strategies for answering the first question. Analyze the strategies. a. Which strategy is closest to yours? With a partner, take turns explaining how your strategy is close to the poster you chose. b. Discuss a different strategy with your partner. Try using this strategy to find the value of .",
    analysis(
        quantities([quantity(45, "students", "45 students"), quantity(18, "dollars per ticket", "$18"), quantity(900, "dollars", "$900")]),
        ask("Will $900 be enough to buy tickets for 45 students at $18 each, and if so, how much money will be left over, or if not, how much more is needed?"),
        steps([step("multiplication", [45, 18], 810), step("subtraction", [900, 810], 90)]),
        answer(90, "dollars"),
        missing_doing("decision making")),
    anchor(lesson('IM-G4-U6-L22'), grade('4'), record_id('im_defrag_ca0de041cc54d6e876fd6dc4_1'), statement_sha('00931e7dfe5afaca25a9ef66128d6ef9b39942350ff056883fd38ed6cc174ef1')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_ca59762ee3a0e7f2e12ff9f1_1', "Find the value of 61 - 32. Show your thinking.",
    analysis(
        quantities([quantity(61, "number", "61"), quantity(32, "number", "32")]),
        ask("Find the value of 61 - 32."),
        steps([step("subtraction", [61, 32], 29)]),
        answer(29, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U2-L7'), grade('2'), record_id('im_defrag_ca59762ee3a0e7f2e12ff9f1_1'), statement_sha('ea374291cf41ff97af06e5e9b754f0b911b0cfe227efb4e52a1be7fdb33ee24f')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_1.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_cb06cc78d6c6d1281d7c74a5_1', "5 + 1 = 5 + 2",
    analysis(
        quantities([quantity(5, "number", "5"), quantity(1, "number", "1"), quantity(5, "number", "5"), quantity(2, "number", "2")]),
        ask("Determine if the equation 5 + 1 = 5 + 2 is true or false."),
        steps([step("addition", [5, 1], 6), step("addition", [5, 2], 7), step("compare_equal", [6, 7], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L14'), grade('1'), record_id('im_defrag_cb06cc78d6c6d1281d7c74a5_1'), statement_sha('e58bbdd70bbfc74fa03efed57bd05bac165f1d0f88b0321521235bbf4e1c702d')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_cb14a1bf9f167f06f639097b_1', "64 = 60 + 4",
    analysis(
        quantities([quantity(64, "number", "64"), quantity(60, "number", "60"), quantity(4, "number", "4")]),
        ask("Check if 64 is equal to the sum of 60 and 4."),
        steps([step("addition", [60, 4], 64), step("compare_equal", [64, 64], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U2-L6'), grade('2'), record_id('im_defrag_cb14a1bf9f167f06f639097b_1'), statement_sha('d28c548baef6339a2a983eb8c107aaa6fd60af02e9260d1f81772ef9068f670f')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_cbaa5b2a642ed155f5e00cc6_1', "To make a birdhouse for a screech owl, the recommended area of the floor is 8 inches by 8 inches and the recommended height is 12 inches to 15 inches. What is the recommended range of volumes for a screech owl birdhouse? Explain or show your thinking.",
    analysis(
        quantities([quantity(8, "inches", "8"), quantity(8, "inches", "8"), quantity(12, "inches", "12"), quantity(15, "inches", "15")]),
        ask("What is the recommended range of volumes for a screech owl birdhouse?"),
        steps([step("multiply", [8, 8], 64), step("multiply", [64, 12], 768), step("multiply", [64, 15], 960)]),
        answer(768, "cubic inches"),
        missing_doing("representing a range of values")),
    anchor(lesson('IM-G5-U4-L8'), grade('5'), record_id('im_defrag_cbaa5b2a642ed155f5e00cc6_1'), statement_sha('df910e29e96536909a5c9d94fc801c30674aa7b8dad72bc9a445bae9cdcdf5a6')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_5.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_cbc655ed624709c69ff541d4_1', "Priya can bike 150 meters in 20 seconds. At this rate, how long would it take her to bike 3,000 meters?",
    analysis(
        quantities([quantity(150, "meters", "150 meters"), quantity(20, "seconds", "20 seconds"), quantity(3000, "meters", "3,000 meters")]),
        ask("How long would it take Priya to bike 3,000 meters at her current rate?"),
        steps([step("division", [150, 20], 7.5), step("division", [3000, 7.5], 400)]),
        answer(400, "seconds"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L13'), grade('6'), record_id('im_defrag_cbc655ed624709c69ff541d4_1'), statement_sha('ef5474f0cb0975058f24c8e61a5b95a5a88de9bf5430343b07d0b486c87d3585')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_cbe10d23ec817ffb7996e9e6_1', "Solve. 12 = x · 3",
    analysis(
        quantities([quantity(12, "value", "12"), quantity(3, "multiplier", "3")]),
        ask("Find the value of x such that 12 equals x multiplied by 3."),
        steps([step("division", [12, 3], 4)]),
        answer(4, "value"),
        missing_doing("solving an equation")),
    anchor(lesson('IM-G7-U5-L15'), grade('7'), record_id('im_defrag_cbe10d23ec817ffb7996e9e6_1'), statement_sha('2e5838d2d4a936d556de879f3a7d953934dd823536bc55b36c1ae00b81db0ce6')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_cc27292871f0bf9248dbebe3_1', "Andre and Clare found the value of 528 - 271. How they started their work is shown. Andre's algorithm Clare's algorithm 1. Complete both algorithms to find the difference. 2. Andre and Clare started their subtraction in different ways. How did their way of starting affect the steps needed to find the difference?",
    analysis(
        quantities([quantity(528, "number", "528"), quantity(271, "number", "271")]),
        ask("Find the difference of 528 minus 271 and describe how the different starting methods affect the subtraction steps."),
        steps([step("subtraction", [528, 271], 257)]),
        answer(257, "number"),
        missing_doing("qualitative comparison of algorithmic strategies")),
    anchor(lesson('IM-G3-U3-L10'), grade('3'), record_id('im_defrag_cc27292871f0bf9248dbebe3_1'), statement_sha('b5ef913b644562d99cf5c352e632bc300e2c5c66e076510c4087b6cd50456c61')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_cc28f0b4d6df9407377372ca_1', "Lin finds a piece of ribbon that is 92 cm long. She cuts a piece for Noah that is 35 cm. Then Lin cuts off 28 cm of her ribbon. She gives it to Jada. How much ribbon does Lin have left?",
    analysis(
        quantities([quantity(92, "cm", "92 cm"), quantity(35, "cm", "35 cm"), quantity(28, "cm", "28 cm")]),
        ask("How much ribbon does Lin have left after giving pieces to Noah and Jada?"),
        steps([step("subtraction", [92, 35], 57), step("subtraction", [57, 28], 29)]),
        answer(29, "cm"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U3-L12'), grade('2'), record_id('im_defrag_cc28f0b4d6df9407377372ca_1'), statement_sha('e81d59036f8bc0d046476709ee1e22d08292ed551327a8c70c0a3aea33cbc117')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_cc57bc7633c68f59b5bfbca0_1', "Elena has a bag of beads. She takes out 9 beads. 11 beads are left in the bag. How many beads were in the bag to start? Solve the story problem. Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(9, "beads", "9 beads"), quantity(11, "beads", "11 beads")]),
        ask("How many beads were in the bag to start?"),
        steps([step("addition", [9, 11], 20)]),
        answer(20, "beads"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U6-L13'), grade('1'), record_id('im_defrag_cc57bc7633c68f59b5bfbca0_1'), statement_sha('312cfcf5407bee4a8d5dd3b8a068f822909e405f9db43210aeef6c70cd491e0f')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_cc763c65f90974736d40ae24_1', "Use partial quotients to find 1,032 ÷ 43.",
    analysis(
        quantities([quantity(1032, "number", "1,032"), quantity(43, "number", "43")]),
        ask("Find the result of dividing 1,032 by 43 using partial quotients."),
        steps([step("multiply", [43, 10], 430), step("multiply", [43, 20], 860), step("subtract", [1032, 860], 172), step("multiply", [43, 4], 172), step("subtract", [172, 172], 0), step("add", [20, 4], 24)]),
        answer(24, "number"),
        missing_doing("partial quotients estimation/decomposition")),
    anchor(lesson('IM-G6-U5-L10'), grade('6'), record_id('im_defrag_cc763c65f90974736d40ae24_1'), statement_sha('3c769cd223b51a4ac98ab963bafceece295e832612f4c2afe24bfda73c2ba685')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_ccc765231cbb9d14066ec8e8_1', "38 + 4 = 40 + 3",
    analysis(
        quantities([quantity(38, "number", "38"), quantity(4, "number", "4"), quantity(40, "number", "40"), quantity(3, "number", "3")]),
        ask("Check if 38 + 4 is equal to 40 + 3."),
        steps([step("addition", [38, 4], 42), step("addition", [40, 3], 43), step("compare_equal", [42, 43], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U1-L16'), grade('2'), record_id('im_defrag_ccc765231cbb9d14066ec8e8_1'), statement_sha('d452e37a23278cf3ec066703f65577d22f9150fe704c2ebf6ef9e2f515945424')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_ccece3c9d85030744f60e54e_1', "Jada’s prism has 4 layers and each layer has 9 unit cubes. 1. Circle the prism that is Jada's. A B C D 2. Find the volume of Jada’s prism. Explain or show your reasoning.",
    analysis(
        quantities([quantity(4, "layers", "4 layers"), quantity(9, "unit cubes per layer", "9 unit cubes")]),
        ask("What is the volume of Jada's prism?"),
        steps([step("multiplication", [4, 9], 36)]),
        answer(36, "unit cubes"),
        missing_doing("visual identification")),
    anchor(lesson('IM-G5-U1-L3'), grade('5'), record_id('im_defrag_ccece3c9d85030744f60e54e_1'), statement_sha('9a72e367b88a165be14b0791032c3202815d292750698edac1efd2f14538d67f')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_cd114a5e29b5a299525ee4e4_1', "Use long division to show that the fraction and decimal in each pair are equal. 7/25 and 0.28",
    analysis(
        quantities([quantity(7, "numerator", "7"), quantity(25, "denominator", "25"), quantity(0.28, "decimal", "0.28")]),
        ask("Show that the fraction 7/25 is equal to the decimal 0.28 using long division."),
        steps([step("division", [7, 25], 0.28), step("compare_equal", [0.28, 0.28], true)]),
        answer(true, "claim_verdict"),
        missing_doing("long division process")),
    anchor(lesson('IM-G6-U5-L12'), grade('6'), record_id('im_defrag_cd114a5e29b5a299525ee4e4_1'), statement_sha('2eba04768720caa93450057c97fd0c99f56aa4693f3acf255837690c211d7768')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_cd5ab9f33ec268dd1bcc0eba_1', "3 + 5 = 5 + 3",
    analysis(
        quantities([quantity(3, "number", "3"), quantity(5, "number", "5"), quantity(5, "number", "5"), quantity(3, "number", "3")]),
        ask("Check if the equation 3 + 5 = 5 + 3 is true."),
        steps([step("addition", [3, 5], 8), step("addition", [5, 3], 8), step("compare_equal", [8, 8], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L4'), grade('1'), record_id('im_defrag_cd5ab9f33ec268dd1bcc0eba_1'), statement_sha('c6dbc033b67fa9ca49de149d507f1b68251d8c1e0090ad93c55eeebbff6498cd')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_5.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_ce21ecc532be54251705fe21_1', "Jada and her brother made 6 paletas (pah-LAY- tuhs). They made 2 flavors: lime and coconut. How many are lime? How many are coconut? Kindergarten",
    analysis(
        quantities([quantity(6, "paletas", "6 paletas"), quantity(2, "flavors", "2 flavors")]),
        ask("How many paletas are lime and how many are coconut, assuming there is an equal number of each flavor?"),
        steps([step("divide", [6, 2], 3)]),
        answer(3, "paletas"),
        missing_doing("making an assumption of equal distribution")),
    anchor(lesson('IM-GK-U5-L7'), grade('K'), record_id('im_defrag_ce21ecc532be54251705fe21_1'), statement_sha('d4ebf48ab000f61d4d4cfbbb6034dbae7e2b75e13ce817df913e4e67ee384d5d')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_1.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_ceb72f36742f76229b41231e_1', "Use the method shown in the first question to calculate (16.5) · (0.7). 165 · 7 = 1,155",
    analysis(
        quantities([quantity(16.5, "number", "16.5"), quantity(0.7, "number", "0.7"), quantity(165, "number", "165"), quantity(7, "number", "7"), quantity(1155, "number", "1,155")]),
        ask("Calculate the product of 16.5 and 0.7 using the provided multiplication logic."),
        steps([step("multiplication", [165, 7], 1155), step("addition_of_decimal_places", [1, 1], 2), step("division", [1155, 100], 11.55)]),
        answer(11.55, "number"),
        missing_doing("applying decimal place logic based on the number of decimal places in the factors")),
    anchor(lesson('IM-G6-U5-L8'), grade('6'), record_id('im_defrag_ceb72f36742f76229b41231e_1'), statement_sha('f9fd32fcd835bf6e750d26bbe0cf73667805969748cfd0e15af63b911e5670e2')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_cee3db1653315660ca82a422_1', "1. A pitcher contains 3 cups of watermelon juice. If you pour each of these amounts from the full pitcher, how many cups are left after each pour? a. cup b. cups c. cups d. cups 2. A second pitcher contains 4 cups of water. If you pour each of these amounts from the full pitcher, how many cups are left after each pour? Explain or show your reasoning. Use diagrams or equations, if they are helpful. a. cup b. cups c. cups",
    analysis(
        quantities([quantity(3, "cups", "3 cups"), quantity(4, "cups", "4 cups")]),
        ask("How many cups are left after each pour for a pitcher with 3 cups and a pitcher with 4 cups?"),
        steps([step("subtraction", [3, 1], 2), step("subtraction", [2, 1], 1), step("subtraction", [1, 1], 0), step("subtraction", [4, 1], 3), step("subtraction", [3, 1], 2), step("subtraction", [2, 1], 1), step("subtraction", [1, 1], 0)]),
        answer(0, "cups"),
        missing_doing("interpreting multiple questions and sequence of events")),
    anchor(lesson('IM-G4-U3-L10'), grade('4'), record_id('im_defrag_cee3db1653315660ca82a422_1'), statement_sha('7cb60e8c3d0af1d2bacfe44c580568f7e6e8c579a05f8a7f312500cf7a78a31c')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_2.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_cf0ee2435481b5a67da6fff6_1', "7 kids on the bus. 1 more kid gets on the bus. How many kids are on the bus?",
    analysis(
        quantities([quantity(7, "kids", "7 kids"), quantity(1, "kid", "1 more kid")]),
        ask("How many kids are on the bus in total?"),
        steps([step("addition", [7, 1], 8)]),
        answer(8, "kids"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U8-L3'), grade('K'), record_id('im_defrag_cf0ee2435481b5a67da6fff6_1'), statement_sha('f796154830a9efa2a7f4cc924895074350795893ba024a4832467a0f19a63949')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_cf6d599389632bbe8c84f1a2_1', "1. Circle the representations that show 263. A. B. C. 2 hundreds + 4 tens + 23 ones 2. Represent 263 in a different way.",
    analysis(
        quantities([quantity(263, "number", "263"), quantity(2, "hundreds", "2 hundreds"), quantity(4, "tens", "4 tens"), quantity(23, "ones", "23 ones")]),
        ask("Identify which representation equals 263 and provide a different way to represent 263."),
        steps([step("multiply", [2, 100], 200), step("multiply", [4, 10], 40), step("add", [200, 40], 240), step("add", [240, 23], 263)]),
        answer(263, "number"),
        missing_doing("generating alternative representations")),
    anchor(lesson('IM-G2-U9-L5'), grade('2'), record_id('im_defrag_cf6d599389632bbe8c84f1a2_1'), statement_sha('0c6096268e3348a8ce4a9530d523b725dec3227fb0d42392243c69c6a1dbdea0')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_4.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_cfeee35efb2cae19ca5497f8_1', "Last month, there were 4 sunny days for every rainy day. How many total units (4+1)?",
    analysis(
        quantities([quantity(4, "sunny days", "4"), quantity(1, "rainy day", "1")]),
        ask("What is the total sum of the 4 sunny days and 1 rainy day?"),
        steps([step("addition", [4, 1], 5)]),
        answer(5, "units"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L15'), grade('6'), record_id('im_defrag_cfeee35efb2cae19ca5497f8_1'), statement_sha('e56f4bcab2c005171efef6a44064253cf9ce92a38dbee2007cc8965d85abc07b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_d008ed40e5ae9e7110983724_1', "Clare has some beads. She uses 7 beads to make a bracelet. She has 8 beads left. How many beads did Clare have to start? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(7, "beads", "7 beads"), quantity(8, "beads", "8 beads")]),
        ask("How many beads did Clare have at the beginning?"),
        steps([step("addition", [7, 8], 15)]),
        answer(15, "beads"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U6-L13'), grade('1'), record_id('im_defrag_d008ed40e5ae9e7110983724_1'), statement_sha('4e759389a2c023d25775a5fed046ca6e42a178dd8fe7998e55ffd6575dc1d435')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_d00a304dd54b367f4e06b812_1', "Use long division to show that: 1 ÷ 8, or 1/8, is 0.125.",
    analysis(
        quantities([quantity(1, "number", "1"), quantity(8, "number", "8"), quantity(0.125, "number", "0.125")]),
        ask("Show that 1 divided by 8 is 0.125."),
        steps([step("divide", [1, 8], 0.125), step("compare_equal", [0.125, 0.125], true)]),
        answer(true, "claim_verdict"),
        missing_doing("long_division")),
    anchor(lesson('IM-G6-U5-L12'), grade('6'), record_id('im_defrag_d00a304dd54b367f4e06b812_1'), statement_sha('8eead02ec7c596387b30348483de10371baea0503ab5832ab2d4ad5d6b2bc964')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_d113340594c5e5733b6af2f2_1', "Find the quotient of 511 ÷ 5. Show your reasoning.",
    analysis(
        quantities([quantity(511, "number", "511"), quantity(5, "number", "5")]),
        ask("What is the quotient of 511 divided by 5?"),
        steps([step("division", [511, 5], 102.2)]),
        answer(102.2, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U5-L9'), grade('6'), record_id('im_defrag_d113340594c5e5733b6af2f2_1'), statement_sha('b3c032ce4ab7a7b07c4ef5a6c6ff741388db5d0fc363b1cd5f1081c6c47e5607')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_d1324b0c173621a8fe1c5cdb_1', "There are 17,564 students in a city, who each drink a carton of milk at lunch one day. Each carton of milk is about 240 cubic centimeters. About how many cubic centimeters of milk do the students drink altogether? Explain or show your reasoning.",
    analysis(
        quantities([quantity(17564, "students", "17,564 students"), quantity(240, "cubic centimeters", "240 cubic centimeters")]),
        ask("Approximately how many cubic centimeters of milk do all the students drink in total?"),
        steps([step("multiplication", [17564, 240], 4215360)]),
        answer(4215360, "cubic centimeters"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U4-L17'), grade('5'), record_id('im_defrag_d1324b0c173621a8fe1c5cdb_1'), statement_sha('a5dcf81814cbe55cb740818666ccc3514ba242ee76d3d253e7046d2e9306dae8')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_d16efca14cb3700474a34fd1_1', "20 + 5",
    analysis(
        quantities([quantity(20, "number", "20"), quantity(5, "number", "5")]),
        ask("What is the sum of 20 and 5?"),
        steps([step("addition", [20, 5], 25)]),
        answer(25, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U4-L10'), grade('1'), record_id('im_defrag_d16efca14cb3700474a34fd1_1'), statement_sha('64e28ae3f4c9260d166ffc792bcdbb776db9f98580b3a6e34f7d708f880a16a1')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_d1748e8692cbb8414f6dd290_1', "Clare made a train that was 15 cubes long. Then she added some more cubes. Now her train is 28 cubes long. How many cubes did she add to her train? Show your thinking.",
    analysis(
        quantities([quantity(15, "cubes", "15 cubes"), quantity(28, "cubes", "28 cubes")]),
        ask("How many cubes did Clare add to her train?"),
        steps([step("subtraction", [28, 15], 13)]),
        answer(13, "cubes"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U4-L13'), grade('2'), record_id('im_defrag_d1748e8692cbb8414f6dd290_1'), statement_sha('150769de803d4d7ac8794c29071394b14139605e8330feabe69f998245f2ed58')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_d1aacf5e3fad5e46fb29b8df_1', "42 + 30 = 45",
    analysis(
        quantities([quantity(42, "number", "42"), quantity(30, "number", "30"), quantity(45, "number", "45")]),
        ask("Is 42 plus 30 equal to 45?"),
        steps([step("addition", [42, 30], 72), step("compare_equal", [72, 45], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U5-L11'), grade('1'), record_id('im_defrag_d1aacf5e3fad5e46fb29b8df_1'), statement_sha('cacea414e835cd2c2d94e8d8b6ff2c7eece5ef5369185510f89666fcef7ec608')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_d3c9e39ba752db5f278bfba7_1', "A recipe for maroon paint says, \"Mix 5 ml of red paint with 3 ml of blue paint.\" How many milliliters of maroon paint will there be?",
    analysis(
        quantities([quantity(5, "ml", "5 ml"), quantity(3, "ml", "3 ml")]),
        ask("How many milliliters of maroon paint will be produced by mixing the red and blue paint?"),
        steps([step("addition", [5, 3], 8)]),
        answer(8, "ml"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L15'), grade('6'), record_id('im_defrag_d3c9e39ba752db5f278bfba7_1'), statement_sha('d92e955880dd581aca6e496cc4d2ff2f95b3d4777383c5fc7db4cdc4744efa17')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_d47f8d486b289ab3f19a8a53_1', "The hose fills the aquarium at a constant rate of 15 liters per minute. What will the sensor read at the time 5 minutes?",
    analysis(
        quantities([quantity(15, "liters per minute", "15 liters per minute"), quantity(5, "minutes", "5 minutes")]),
        ask("What will the sensor read (the volume of water in the aquarium) after 5 minutes?"),
        steps([step("multiplication", [15, 5], 75)]),
        answer(75, "liters"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U5-L14'), grade('7'), record_id('im_defrag_d47f8d486b289ab3f19a8a53_1'), statement_sha('2756825299cccaed145e3290c08afc24e25a9abe77c412ac5502738b0310948d')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_d56757bf109684aceb71672e_1', "Andre checks out 3 books from the library. Mai gives him some more books. Now Andre has 9 books. How many books did Mai give him? Lin made this drawing.",
    analysis(
        quantities([quantity(3, "books", "3 books"), quantity(9, "books", "9 books")]),
        ask("How many books did Mai give to Andre?"),
        steps([step("-", [9, 3], 6)]),
        answer(6, "books"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U2-L4'), grade('1'), record_id('im_defrag_d56757bf109684aceb71672e_1'), statement_sha('2afdc38c3f6fcc0902a660ab4afc875c4f1f94ddbcedbb636bc01c68d81fc7c8')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_d56c58882f1f67288dc3e425_1', "Complete the table to represent a cheetah running at a constant speed. (270 meters at speed 30, find time)",
    analysis(
        quantities([quantity(270, "meters", "270 meters"), quantity(30, "meters per second", "speed 30")]),
        ask("Find the time it takes for a cheetah to run 270 meters at a constant speed of 30 meters per unit of time."),
        steps([step("division", [270, 30], 9)]),
        answer(9, "units of time"),
        missing_doing("unit_inference")),
    anchor(lesson('IM-G6-U3-L6'), grade('6'), record_id('im_defrag_d56c58882f1f67288dc3e425_1'), statement_sha('be11d13088950adb2cb553de92dd2110d1e68d3a618861669bfa558be7e9c226')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_d60df46fd98120a9f97ce1c0_1', "Find the value of each expression mentally. 5 ÷ 4",
    analysis(
        quantities([quantity(5, "number", "5"), quantity(4, "number", "4")]),
        ask("What is the value of the expression 5 divided by 4?"),
        steps([step("division", [5, 4], 1.25)]),
        answer(1.25, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U2-L12'), grade('7'), record_id('im_defrag_d60df46fd98120a9f97ce1c0_1'), statement_sha('1e6ef15231b3b039458f27bb51cfaff7db8fb590c094c61b3c930fdd95219362')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_d68fbb61791ed27d4d2621b6_1', "There are 27 animals in all (9 parts). What is the value of each small rectangle?",
    analysis(
        quantities([quantity(27, "animals", "27 animals"), quantity(9, "parts", "9 parts")]),
        ask("What is the value of each small rectangle?"),
        steps([step("division", [27, 9], 3)]),
        answer(3, ""),
        missing_doing("interpreting the visual model represented by 'small rectangle' and 'parts'")),
    anchor(lesson('IM-G6-U2-L15'), grade('6'), record_id('im_defrag_d68fbb61791ed27d4d2621b6_1'), statement_sha('873daa70e950b56d9e72231dbc93f50459f32e756f823c915a8afa28a1603663')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_d6a0ace3e490884937b3f4cf_1', "Label the diagram. Find the unknown value. Show your thinking using drawings, numbers, or words. Write the units. 1. Elena starts with 58 inches of ribbon. She gives Clare 27 inches of ribbon. How much did Elena keep? 2. Han has a piece of ribbon that is 64 inches long. He cuts off 28 inches to make a necklace for his sister. How much ribbon is left? 3. Priya cuts off 25 inches of ribbon. She has 38 inches of ribbon left. How much ribbon did Priya start with?",
    analysis(
        quantities([quantity(25, "inches", "25 inches"), quantity(38, "inches", "38 inches")]),
        ask("How much ribbon did Priya start with?"),
        steps([step("addition", [25, 38], 63)]),
        answer(63, "inches"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U3-L11'), grade('2'), record_id('im_defrag_d6a0ace3e490884937b3f4cf_1'), statement_sha('faa795928c9fccd917143d850df4542c23a3ef8ac637fb537d88684975eb79ca')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_d6b8bcdc3170213099af4b8c_1', "Priya’s shoe is 6 cubes long. Her teacher’s shoe is 13 cubes long. How much longer is the teacher’s shoe than Priya’s shoe? Show your thinking using drawings, numbers, words, or equations.",
    analysis(
        quantities([quantity(6, "cubes", "6 cubes"), quantity(13, "cubes", "13 cubes")]),
        ask("How much longer is the teacher's shoe than Priya's shoe?"),
        steps([step("subtraction", [13, 6], 7)]),
        answer(7, "cubes"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U6-L11'), grade('1'), record_id('im_defrag_d6b8bcdc3170213099af4b8c_1'), statement_sha('b5bbd57f313f8c715086b54866f36e4993565f181b6687542d526b321c4e2fb1')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_d70edcde43873d34b75bbdb1_1', "1. Complete the table with the first 5 numbers for the pattern that follows the rule, “start with 100, keep doubling it. keep doubling 100 2. Write 2 things that you notice about this pattern. Explain or show your reasoning.",
    analysis(
        quantities([quantity(100, "starting number", "100"), quantity(5, "count", "first 5 numbers")]),
        ask("What are the first 5 numbers in a pattern that starts with 100 and doubles each time?"),
        steps([step("multiply", [100, 2], 200), step("multiply", [200, 2], 400), step("multiply", [400, 2], 800), step("multiply", [800, 2], 1600)]),
        answer(1600, "sequence_end_value"),
        missing_doing("listing a sequence")),
    anchor(lesson('IM-G4-U6-L4'), grade('4'), record_id('im_defrag_d70edcde43873d34b75bbdb1_1'), statement_sha('0a5cfc5b0a529e29c6adb9a41a567edb9af5d47e8fd4442ff76858dcbcb4170f')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_1.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_d797b4d66e6ab0c29fdd2a78_1', "Han buys an item with a normal price of $15, and uses a 10% off coupon. How much does he save?",
    analysis(
        quantities([quantity(15, "dollars", "$15"), quantity(10, "percent", "10%")]),
        ask("How much money does Han save using the coupon?"),
        steps([step("multiply", [15, 0.1], 1.5)]),
        answer(1.5, "dollars"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U3-L13'), grade('6'), record_id('im_defrag_d797b4d66e6ab0c29fdd2a78_1'), statement_sha('1eb20188dad37c59ebb7705044608eebe67e0e77e535e571de949f30d2fe7563')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_d82948988e68657cd7fc2994_1', "What do you notice? What do you wonder? 54- 16 = ?",
    analysis(
        quantities([quantity(54, "number", "54"), quantity(16, "number", "16")]),
        ask("What do you notice? What do you wonder? 54- 16 = ?"),
        steps([step("subtraction", [54, 16], 38)]),
        answer(38, "number"),
        missing_doing("reflection")),
    anchor(lesson('IM-G2-U3-L11'), grade('2'), record_id('im_defrag_d82948988e68657cd7fc2994_1'), statement_sha('4251945f03e64fd987895dfafdd8514fbabeca2cdc5a2178f811563bc0a1c0e9')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_5.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_d84a2965a1f5527fda043029_1', "Find the value of 38 + 28. Represent your thinking on the number line.",
    analysis(
        quantities([quantity(38, "number", "38"), quantity(28, "number", "28")]),
        ask("Find the value of 38 + 28."),
        steps([step("addition", [38, 28], 66)]),
        answer(66, "number"),
        missing_doing("visualizing on a number line")),
    anchor(lesson('IM-G2-U4-L11'), grade('2'), record_id('im_defrag_d84a2965a1f5527fda043029_1'), statement_sha('7b8ecad67d61347f5d5a56aedde8deea55981a6ee0a5c652c7d4b232b7dbd84e')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_1.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_d8da83fc7c8c120f9f607cfd_1', "There are 3 counters outside the cup. Some of the counters are under the cup. There are 8 counters total. How many counters are under the cup?",
    analysis(
        quantities([quantity(3, "counters", "3 counters"), quantity(8, "counters", "8 counters total")]),
        ask("How many counters are under the cup?"),
        steps([step("subtraction", [8, 3], 5)]),
        answer(5, "counters"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U2-L8'), grade('1'), record_id('im_defrag_d8da83fc7c8c120f9f607cfd_1'), statement_sha('dbeca4b765f5512124ec964a78624f9069c98129e36fd85cae11c29adc77376b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_d913806ec9f71f8ac934c8ad_1', "Jada read 17 pages. Noah read 9 more pages than Jada. How many pages did Noah read? Show your thinking using drawings, numbers, words, or an equation. If it helps, you can use the diagram.",
    analysis(
        quantities([quantity(17, "pages", "17 pages"), quantity(9, "pages", "9 more pages")]),
        ask("How many pages did Noah read?"),
        steps([step("addition", [17, 9], 26)]),
        answer(26, "pages"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U1-L16'), grade('2'), record_id('im_defrag_d913806ec9f71f8ac934c8ad_1'), statement_sha('6b47dfcc34e8a039cbe13ac422d99679ee3962885e6fe3d46d9e33aa610a8617')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_d935ab03758ba70b7fc1165e_1', "Elena makes taco seasoning using 4 parts chili powder, 1 part garlic powder, and 2 parts ground cumin. If Elena uses 20 teaspoons of ground cumin (2 parts), how much per part?",
    analysis(
        quantities([quantity(4, "parts", "4 parts"), quantity(1, "parts", "1 part"), quantity(2, "parts", "2 parts"), quantity(20, "teaspoons", "20 teaspoons"), quantity(2, "parts", "2 parts")]),
        ask("How many teaspoons are in one part of the seasoning?"),
        steps([step("division", [20, 2], 10)]),
        answer(10, "teaspoons"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L15'), grade('6'), record_id('im_defrag_d935ab03758ba70b7fc1165e_1'), statement_sha('4789cbcb83e28ac8884e784d4fe404ba82caa68467d951edc77547709c868d2c')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_d93f2104c4e124172bc275cb_1', "Philadelphia is a diverse city and home to people of different backgrounds. • “Wha The table shows 2020 data on some languages • 1 min spoken in Philadelphia and the numbers of people • Share who speak them. number of speakers in Activity language Philadelphia • 5 min English only 1,131,303 • Monit ◦ Th Spanish 159,343 th Other Indo- ◦ Th 81,924 European ad fi Asian 77,706 1. Use the data to determine if there are more Activity people in Philadelphia who only speak English • Selec or more people who speak a language other reaso than English. Show how you know. • If no 2. What is the difference between the number of estim people who speak only English and those who • Discu speak another language? Show how you know. would 3. Chicago is a city with a similar population to group Philadelphia. so it shoul This table shows data on some types of for e languages spoken by people in Chicago. estim number of speakers in language Chicago English only 1,634,103 Spanish 600,655 Other Indo- 150,354 European Asian 105,790 a. How many more speakers of Spanish and other Indo-European languages are in Chicago than in Philadelphia? Explain or show your reasoning. b. How do you know your answer is reasonable?",
    analysis(
        quantities([quantity(1131303, "people", "1,131,303"), quantity(159343, "people", "159,343"), quantity(81924, "people", "81,924"), quantity(77706, "people", "77,706"), quantity(600655, "people", "600,655"), quantity(150354, "people", "150,354")]),
        ask("How many more speakers of Spanish and other Indo-European languages are in Chicago than in Philadelphia?"),
        steps([step("addition", [159343, 81924, 77706], 318973), step("addition", [600655, 150354], 751009), step("subtraction", [751009, 318973], 432036)]),
        answer(432036, "people"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U6-L25'), grade('4'), record_id('im_defrag_d93f2104c4e124172bc275cb_1'), statement_sha('4928690cbc9b0cfb89b14a95dfebd78914a3d18067fd4b350286793c68d4bbb5')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_d98723ebc2328957c0d0d576_1', "A one-room movie theater has 278 seats. Its goal is to sell 2,600 tickets every weekend. The theater plays a movie 5 times each Saturday and 4 times each Sunday. Last weekend, the movie theater was completely full for every movie played on Saturday and Sunday. Did the movie theater meet its goal?",
    analysis(
        quantities([quantity(278, "seats", "278 seats"), quantity(2600, "tickets", "2,600 tickets"), quantity(5, "times", "5 times"), quantity(4, "times", "4 times")]),
        ask("Did the movie theater meet its goal of selling 2,600 tickets last weekend?"),
        steps([step("add", [5, 4], 9), step("multiply", [278, 9], 2502), step("compare_equal", [2502, 2600], false)]),
        answer(false, "goal_met"),
        missing_doing("comparing the total tickets sold to the goal")),
    anchor(lesson('IM-G4-U6-L22'), grade('4'), record_id('im_defrag_d98723ebc2328957c0d0d576_1'), statement_sha('986fdd4128a813bb28445fcdd07c3a601b55e8d0a4ff504d00d694481d6af020')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_0.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_da104dbf591f02b874429163_1', "Find the value of 2,023 ÷ 7. Use partial quotients to show your reasoning.",
    analysis(
        quantities([quantity(2023, "number", "2,023"), quantity(7, "number", "7")]),
        ask("Find the value of 2,023 ÷ 7."),
        steps([step("division", [2023, 7], 289)]),
        answer(289, "number"),
        missing_doing("partial quotients method")),
    anchor(lesson('IM-G4-U6-L18'), grade('4'), record_id('im_defrag_da104dbf591f02b874429163_1'), statement_sha('3468f075a1c836fe35e4fd28b4991eab8802b9e6a89f63d0222f0be7cf640bcc')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_2.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_da2ce2ec2f5a1b013333c186_1', "3 + 5 = 5 + 3",
    analysis(
        quantities([quantity(3, "number", "3"), quantity(5, "number", "5"), quantity(5, "number", "5"), quantity(3, "number", "3")]),
        ask("Check if 3 + 5 is equal to 5 + 3."),
        steps([step("addition", [3, 5], 8), step("addition", [5, 3], 8), step("compare_equal", [8, 8], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L4'), grade('1'), record_id('im_defrag_da2ce2ec2f5a1b013333c186_1'), statement_sha('c6dbc033b67fa9ca49de149d507f1b68251d8c1e0090ad93c55eeebbff6498cd')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_da3f7c580890f4d906952a8c_1', "12- 4 = 10- 3",
    analysis(
        quantities([quantity(12, "number", "12"), quantity(4, "number", "4"), quantity(10, "number", "10"), quantity(3, "number", "3")]),
        ask("Determine if the equation 12 - 4 = 10 - 3 is true."),
        steps([step("subtraction", [12, 4], 8), step("subtraction", [10, 3], 7), step("compare_equal", [8, 7], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U3-L10'), grade('2'), record_id('im_defrag_da3f7c580890f4d906952a8c_1'), statement_sha('5999fc98fd466a5ece763da1c2e2f9465fd59f7a2164d0b5a963f74b62ef3c1c')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_4.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_da755605bd39291c7e1a17aa_1', "Draw a picture to show the number of cubes the students have in each situation. 1. Andre has the following cubes and Han has 4 times as many. 2. Priya has the following cubes and Jada has 6 times as many. 3. Tyler has the following cubes and Mai has 8 times as many. 4. What number represents “8 times as many as 2”? Show your reasoning.",
    analysis(
        quantities([quantity(8, "times", "8 times"), quantity(2, "number", "2")]),
        ask("What number represents 8 times as many as 2?"),
        steps([step("multiplication", [8, 2], 16)]),
        answer(16, "number"),
        missing_doing("drawing a picture")),
    anchor(lesson('IM-G4-U5-L1'), grade('4'), record_id('im_defrag_da755605bd39291c7e1a17aa_1'), statement_sha('10d02036be3bd6bb4853613c6c19d1e585860481110cb40b056229b51d8a3b11')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_dbc1f9cbd2d3d5d6c5d9fdd7_1', "A sixth-grade science club needs $180 to pay for the tickets to a science museum. What could 180 ÷ 15 mean in this situation? Then, find the quotient and explain what it means in each case.",
    analysis(
        quantities([quantity(180, "dollars", "$180"), quantity(15, "unknown", "15")]),
        ask("What could the expression 180 ÷ 15 represent in this context, what is its quotient, and what does that quotient represent?"),
        steps([step("division", [180, 15], 12)]),
        answer(12, "unknown"),
        missing_doing("interpreting the mathematical model in context")),
    anchor(lesson('IM-G6-U4-L2'), grade('6'), record_id('im_defrag_dbc1f9cbd2d3d5d6c5d9fdd7_1'), statement_sha('e8634391865886bead0503ba5db38a8d426b29fc09c7e9c1789c5d8f71ec66b3')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_dc21c47bedae3f4381a0ef4c_1', "5 books are on a shelf. Clare puts 2 more books on the shelf. How many books are on the shelf now? Show your thinking using objects, drawings, numbers, or words.",
    analysis(
        quantities([quantity(5, "books", "5 books"), quantity(2, "books", "2 more books")]),
        ask("How many books are on the shelf now?"),
        steps([step("addition", [5, 2], 7)]),
        answer(7, "books"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U2-L1'), grade('1'), record_id('im_defrag_dc21c47bedae3f4381a0ef4c_1'), statement_sha('29f90ceb8eb1c6dc22c8cee56fb542dd09ca3d078be5bf5701eba471d50c3cc9')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_dcae376fc0545993fdca4879_1', "10 = 6 + 4",
    analysis(
        quantities([quantity(10, "number", "10"), quantity(6, "number", "6"), quantity(4, "number", "4")]),
        ask("Check if the equation 10 = 6 + 4 is true."),
        steps([step("addition", [6, 4], 10), step("compare_equal", [10, 10], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U6-L14'), grade('1'), record_id('im_defrag_dcae376fc0545993fdca4879_1'), statement_sha('44df61f1ecc460dd2f69e9777cbd4d6870cb98cbbeed6fde37e86575d6df7758')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_dcee0906a01839f3bb684ca1_1', "8 + 5 = 8 + 2 + 3",
    analysis(
        quantities([quantity(8, "number", "8"), quantity(5, "number", "5"), quantity(8, "number", "8"), quantity(2, "number", "2"), quantity(3, "number", "3")]),
        ask("Determine if the equation 8 + 5 = 8 + 2 + 3 is true."),
        steps([step("addition", [8, 5], 13), step("addition", [8, 2], 10), step("addition", [10, 3], 13), step("compare_equal", [13, 13], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U9-L2'), grade('2'), record_id('im_defrag_dcee0906a01839f3bb684ca1_1'), statement_sha('902175a3e94a237fbbb78c06e59195db183b4d4358b04963b40cfbd8b9f957b9')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_dcf87aff040e8b2d37c6b490_1', "2 × 40 = 8 × 10",
    analysis(
        quantities([quantity(2, "number", "2"), quantity(40, "number", "40"), quantity(8, "number", "8"), quantity(10, "number", "10")]),
        ask("Check if 2 multiplied by 40 is equal to 8 multiplied by 10."),
        steps([step("multiplication", [2, 40], 80), step("multiplication", [8, 10], 80), step("compare_equal", [80, 80], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L17'), grade('3'), record_id('im_defrag_dcf87aff040e8b2d37c6b490_1'), statement_sha('3580b8ed1f36bb83d6a9987f3972a1562c2454ec76c95c4f545baabdf0deae86')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_0.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_dd1627f0c32ff3af38321085_1', "Priya’s family rented a moving truck to move their belongings to their new house. The space inside the back of the moving truck is 15 feet long, 5 feet wide, and 8 feet tall. What is the volume of the back of the moving truck? Explain or show your reasoning. (Remember to include the cubic unit of measure.)",
    analysis(
        quantities([quantity(15, "feet", "15 feet"), quantity(5, "feet", "5 feet"), quantity(8, "feet", "8 feet")]),
        ask("What is the volume of the back of the moving truck?"),
        steps([step("multiply", [15, 5], 75), step("multiply", [75, 8], 600)]),
        answer(600, "cubic feet"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U1-L7'), grade('5'), record_id('im_defrag_dd1627f0c32ff3af38321085_1'), statement_sha('5473d865d49f2c5a5a8fa403f48c5e48b40c8d328bd56195bac2c9ef2ec22885')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_dd2487e9264ae19a37f7568d_1', "A standard cargo container for a ship measures 20 feet long, 8 feet wide, and 8 feet tall. What is the volume of the container?",
    analysis(
        quantities([quantity(20, "feet", "20 feet"), quantity(8, "feet", "8 feet"), quantity(8, "feet", "8 feet")]),
        ask("What is the volume of the container?"),
        steps([step("multiply", [20, 8], 160), step("multiply", [160, 8], 1280)]),
        answer(1280, "cubic feet"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U4-L19'), grade('5'), record_id('im_defrag_dd2487e9264ae19a37f7568d_1'), statement_sha('3e459345c40f43e5d53bf3279df628db32927cfcad03026bf77bd17c142289b1')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_dd2bb2615128316a1a275a3c_1', "compare 378 and 387",
    analysis(
        quantities([quantity(378, "number", "378"), quantity(387, "number", "387")]),
        ask("Compare the numbers 378 and 387."),
        steps([step("compare_equal", [378, 387], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U5-L9'), grade('2'), record_id('im_defrag_dd2bb2615128316a1a275a3c_1'), statement_sha('d21e8c40b700e1082d965e7cd1bca047805320c0cdbce0488f9d27c369b0c700')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_dd2e2dd076c5a882a8bb657a_1', "Which stack of foam blocks is taller: • Two -foot blocks and one -foot block, or • One -foot block and two -foot blocks? Explain or show your reasoning.",
    analysis(
        quantities([quantity(2, "foot", "Two -foot blocks"), quantity(1, "foot", "one -foot block"), quantity(1, "foot", "One -foot block"), quantity(2, "foot", "two -foot blocks")]),
        ask("Which stack of foam blocks is taller: two -foot blocks and one -foot block, or one -foot block and two -foot blocks?"),
        steps([step("addition", [2, 1], 3), step("addition", [1, 2], 3)]),
        answer(3, "foot"),
        missing_doing("comparison")),
    anchor(lesson('IM-G4-U3-L15'), grade('4'), record_id('im_defrag_dd2e2dd076c5a882a8bb657a_1'), statement_sha('66c57f28254002692fd64d559e23cb3bb6635b2d6bf5b874e0baea2cc5019672')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_1.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_dd4026f8ffbc0e11b40d3902_1', "9 meters long. What is that length in centimeters?",
    analysis(
        quantities([quantity(9, "meters", "9 meters")]),
        ask("What is the length of 9 meters in centimeters?"),
        steps([step("multiplication", [9, 100], 900)]),
        answer(900, "centimeters"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U5-L7'), grade('4'), record_id('im_defrag_dd4026f8ffbc0e11b40d3902_1'), statement_sha('c76a129f49b092ccfc442862478aa0a90d4d5fc7bd0693768aa92de810b946a7')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_dd46fcc3b1c68498e9ada50c_1', "A scooter travels 30 feet in 2 seconds at a constant speed. What is the speed of the scooter in feet per second?",
    analysis(
        quantities([quantity(30, "feet", "30 feet"), quantity(2, "seconds", "2 seconds")]),
        ask("What is the speed of the scooter in feet per second?"),
        steps([step("division", [30, 2], 15)]),
        answer(15, "feet per second"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L9'), grade('6'), record_id('im_defrag_dd46fcc3b1c68498e9ada50c_1'), statement_sha('dd4470d2368675384b1fe35bb6d8a44164f48417f824e109e9542fea95c5df49')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_dd662bdd6d087a65973b6dee_1', "Addressing 8.G.A.5 Tyler has 3 right angles. Can he use them to make a triangle? Explain your reasoning.",
    analysis(
        quantities([quantity(3, "right angles", "3 right angles")]),
        ask("Can Tyler use 3 right angles to make a triangle?"),
        steps([step("multiply", [3, 90], 270), step("compare_equal", [270, 180], false)]),
        answer(false, "boolean"),
        missing_doing("knowledge of the sum of interior angles of a triangle")),
    anchor(lesson('IM-G8-U1-L15'), grade('8'), record_id('im_defrag_dd662bdd6d087a65973b6dee_1'), statement_sha('d77204bb0f43ac4c824b62f235d021505335055083ab1ec131ab8a0e584b1da0')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_de53f4463bb8ecfde2dea156_1', "There are 48 students going on a field trip to the aquarium. They visit the exhibits in groups of 4 students. How many groups will there be? Show your thinking using diagrams, symbols, or other representations.",
    analysis(
        quantities([quantity(48, "students", "48 students"), quantity(4, "students per group", "4 students")]),
        ask("How many groups of 4 students will there be if 48 students are going on the field trip?"),
        steps([step("division", [48, 4], 12)]),
        answer(12, "groups"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L18'), grade('3'), record_id('im_defrag_de53f4463bb8ecfde2dea156_1'), statement_sha('3754f0760f36ada36b9d54341e994b45c6c5a694dd6fafc18855a95c8c8db2bb')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_df0430da51839530137478d2_1', "At a book fair, students spent $27 on comics and 5 times as much on posters. How much money did students spend on comics and posters during the book fair? Explain or show your reasoning.",
    analysis(
        quantities([quantity(27, "dollars", "$27"), quantity(5, "times", "5 times as much")]),
        ask("How much money did students spend on comics and posters in total?"),
        steps([step("multiplication", [27, 5], 135), step("addition", [27, 135], 162)]),
        answer(162, "dollars"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U5-L5'), grade('4'), record_id('im_defrag_df0430da51839530137478d2_1'), statement_sha('cc021b93a414fb3aabec10355c8f3a6cb69f79ae1d10acfc0a1897db3eb8116a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_df94ffc1dd26648745bee16e_1', "70 = 24 + 46",
    analysis(
        quantities([quantity(70, "number", "70"), quantity(24, "number", "24"), quantity(46, "number", "46")]),
        ask("Is 70 equal to the sum of 24 and 46?"),
        steps([step("addition", [24, 46], 70), step("compare_equal", [70, 70], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U8-L10'), grade('1'), record_id('im_defrag_df94ffc1dd26648745bee16e_1'), statement_sha('0a1f66d46231f70354080ad3a7a640c2fa208872b1e8f249ad076170b5b5135c')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_dfe849a308cdce558954af35_1', "Here are the data on the numbers of children and senior citizens in Philadelphia as of 2017. age number of people under 5 years 107,736 5–14 years 184,323 15–17 years 53,530 65 years and over 203,007 1. As of 2017, what is the number of people under the age of 18 in Philadelphia? 2. How do you know your answer to the first problem is reasonable?",
    analysis(
        quantities([quantity(107736, "people", "107,736"), quantity(184323, "people", "184,323"), quantity(53530, "people", "53,530")]),
        ask("What was the total number of people under the age of 18 in Philadelphia as of 2017?"),
        steps([step("addition", [107736, 184323], 292059), step("addition", [292059, 53530], 345589)]),
        answer(345589, "people"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U6-L25'), grade('4'), record_id('im_defrag_dfe849a308cdce558954af35_1'), statement_sha('df3056ab521262e913814c2f4d9bd8a27b50aff626302364b04a8620a173f62b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e1aeba58e9d5458b208562c8_1', "1. There are 17 students in the classroom. 4 students go home. How many students are still in the classroom? Show your thinking using drawings, numbers, or words. 2. There are 17 students in the classroom. Some students go home. Now there are 4 students in the classroom. How many students went home? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(17, "students", "17 students"), quantity(4, "students", "4 students"), quantity(17, "students", "17 students"), quantity(4, "students", "4 students")]),
        ask("The problem asks two questions: how many students are still in the classroom if 4 leave from 17, and how many students went home if 4 are left from 17."),
        steps([step("subtraction", [17, 4], 13), step("subtraction", [17, 4], 13)]),
        answer(13, "students"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L13'), grade('1'), record_id('im_defrag_e1aeba58e9d5458b208562c8_1'), statement_sha('90eaecbaae7d7a3c77a76047cedfd918ea8bd49d0fe8494506b757356469e222')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_5.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e2e9874abcad70c1e74741b5_1', "9 students were on the bus. Then 1 student got off the bus. How many students are on the bus now? Show your thinking, using objects, drawings, numbers, or words. _______________",
    analysis(
        quantities([quantity(9, "students", "9 students"), quantity(1, "student", "1 student")]),
        ask("How many students are on the bus now?"),
        steps([step("subtraction", [9, 1], 8)]),
        answer(8, "students"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U8-L3'), grade('K'), record_id('im_defrag_e2e9874abcad70c1e74741b5_1'), statement_sha('215dbe91ac8a7a87884c1ee79a594f168044033b21ac136e232418aa6e660d24')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e39f6635ea2bc8c367ac7915_1', "What is a possible volume for this cylinder if the diameter is 8 cm? Explain your reasoning.",
    analysis(
        quantities([quantity(8, "cm", "8 cm")]),
        ask("What is a possible volume for a cylinder with a diameter of 8 cm?"),
        steps([step("divide", [8, 2], 4), step("multiply", [4, 4], 16), step("multiply", [16, 3.14], 50.24), step("multiply", [50.24, 10], 502.4)]),
        answer(502.4, "cm^3"),
        missing_doing("modeling/assumption of height")),
    anchor(lesson('IM-G8-U5-L14'), grade('8'), record_id('im_defrag_e39f6635ea2bc8c367ac7915_1'), statement_sha('1fd9b842420f70a2746eb037eb9370a4cfd07a2cc401137422d10fa059366fb6')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_0.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e3ab878be6861867e9219340_1', "A rectangular mural is being made for a park that will take up 64 square feet. Give 2 possible perimeters for the mural. Explain or show your reasoning.",
    analysis(
        quantities([quantity(64, "square feet", "64 square feet")]),
        ask("Find two possible perimeters for a rectangular mural with an area of 64 square feet."),
        steps([step("multiply", [8, 8], 64), step("add", [8, 8], 16), step("multiply", [2, 16], 32), step("multiply", [4, 16], 64), step("add", [4, 16], 20), step("multiply", [2, 20], 40)]),
        answer(32, "feet"),
        missing_doing("providing multiple valid answers")),
    anchor(lesson('IM-G3-U7-L13'), grade('3'), record_id('im_defrag_e3ab878be6861867e9219340_1'), statement_sha('f82f50802e3b5cc818719ec890a911c1ceaf061952a60e3c38b61592667173ac')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_1.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e461eb8c39b12d65f3ffddc7_1', "1. Kiran collects baseball caps. He has 5. He gets some more. Now he has 15. How many baseball caps did he get? Show your thinking using drawings, numbers, or words. Equation: ___ Equation: ___ 2. Priya collects comic books. She gets 3 new comic books. Now she has 13. How many comic books did she have to start? Show your thinking using drawings, numbers, or words. Equation: ___ Equation: ___",
    analysis(
        quantities([quantity(5, "baseball caps", "5"), quantity(15, "baseball caps", "15")]),
        ask("How many baseball caps did Kiran get?"),
        steps([step("subtraction", [15, 5], 10)]),
        answer(10, "baseball caps"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L10'), grade('1'), record_id('im_defrag_e461eb8c39b12d65f3ffddc7_1'), statement_sha('963a162ff9da314a927bb38deafd231ba5d06168e7a81560270073026890bb73')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e562a8324ac58afb01cc5f71_1', "Find the value of 1,736 ÷ 28.",
    analysis(
        quantities([quantity(1736, "number", "1,736"), quantity(28, "number", "28")]),
        ask("What is the value of 1,736 divided by 28?"),
        steps([step("division", [1736, 28], 62)]),
        answer(62, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U4-L13'), grade('5'), record_id('im_defrag_e562a8324ac58afb01cc5f71_1'), statement_sha('bb8ac3bada165264cffe1e742915f6831e967bd812d80975263dd2a0920f43b1')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e5ac978af243399878a0ea40_1', "Find each quotient. Show your reasoning. a. 195 ÷ 3",
    analysis(
        quantities([quantity(195, "number", "195"), quantity(3, "number", "3")]),
        ask("What is the quotient of 195 divided by 3?"),
        steps([step("division", [195, 3], 65)]),
        answer(65, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U5-L9'), grade('6'), record_id('im_defrag_e5ac978af243399878a0ea40_1'), statement_sha('026dc0c4fc6cb5edcca5801615f1069a795aa9296ecdaa311835802344a92caa')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e5b1583e091f64cf1dc2a1e8_1', "She draws 7 penguins and 5 owls. How many birds did she draw?",
    analysis(
        quantities([quantity(7, "penguins", "7 penguins"), quantity(5, "owls", "5 owls")]),
        ask("How many birds did she draw in total?"),
        steps([step("addition", [7, 5], 12)]),
        answer(12, "birds"),
        missing_doing("categorizing penguins and owls as birds")),
    anchor(lesson('IM-G1-U3-L17'), grade('1'), record_id('im_defrag_e5b1583e091f64cf1dc2a1e8_1'), statement_sha('b1ea078fda718a635bca187edd27581f840ba57d6358e72b64b430048381f57c')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e60e2c7862fedc1ab03b565d_1', "3 × 60 = 9 × 10",
    analysis(
        quantities([quantity(3, "number", "3"), quantity(60, "number", "60"), quantity(9, "number", "9"), quantity(10, "number", "10")]),
        ask("Determine if 3 multiplied by 60 is equal to 9 multiplied by 10."),
        steps([step("multiplication", [3, 60], 180), step("multiplication", [9, 10], 90), step("compare_equal", [180, 90], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U7-L2'), grade('3'), record_id('im_defrag_e60e2c7862fedc1ab03b565d_1'), statement_sha('667192a07b598873ddbd8eca355a932a093b96a574dcd52fac3bcb15093d1cc1')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e632941a3b3bcb40f76cc132_1', "1. Find the value of 2.26- 1.32 . Explain or show your reasoning. 2. What questions do you have about subtracting decimals?",
    analysis(
        quantities([quantity(2.26, "decimal", "2.26"), quantity(1.32, "decimal", "1.32")]),
        ask("Find the value of 2.26 minus 1.32."),
        steps([step("subtraction", [2.26, 1.32], 0.94)]),
        answer(0.94, "decimal"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U5-L14'), grade('5'), record_id('im_defrag_e632941a3b3bcb40f76cc132_1'), statement_sha('1323bb54ad0a5c078bb8959e819d23f9998c0a22fbfbc236c2852eb96cdf4afa')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e6557e467ce33b812658dd84_1', "The aquarium requires 2 chaperones for every 15 students ... orders a total of 85 tickets. How many tickets are for chaperones?",
    analysis(
        quantities([quantity(2, "chaperones", "2 chaperones"), quantity(15, "students", "15 students"), quantity(85, "tickets", "85 tickets")]),
        ask("How many tickets are for chaperones?"),
        steps([step("addition", [2, 15], 17), step("division", [85, 17], 5), step("multiplication", [5, 2], 10)]),
        answer(10, "tickets"),
        missing_doing("modeling the ratio as a single group size")),
    anchor(lesson('IM-G6-U2-L16'), grade('6'), record_id('im_defrag_e6557e467ce33b812658dd84_1'), statement_sha('cf06cd6f331c502727cf4cc4dc7d1d2d59b2c098a704d2e6d623368b9af6f8e6')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e663be73d0317fc23966c804_1', "7 blue birds fly in the sky. 8 brown birds sit in a tree. 3 baby birds sit in a nest. How many birds are there altogether? Show your thinking using objects, drawings, numbers, or words.",
    analysis(
        quantities([quantity(7, "blue birds", "7 blue birds"), quantity(8, "brown birds", "8 brown birds"), quantity(3, "baby birds", "3 baby birds")]),
        ask("How many birds are there altogether?"),
        steps([step("addition", [7, 8], 15), step("addition", [15, 3], 18)]),
        answer(18, "birds"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L15'), grade('1'), record_id('im_defrag_e663be73d0317fc23966c804_1'), statement_sha('674f185be6dd44e2392b8368676d7551d5143380e185fdc06b1f3c9e6dd21e95')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e67f26dfca5ecf984bf3a875_1', "Elena went 60 meters in 15 seconds... a. How far did Elena go in 1 second? [60 ÷ 15 = 4]",
    analysis(
        quantities([quantity(60, "meters", "60 meters"), quantity(15, "seconds", "15 seconds")]),
        ask("How far did Elena go in 1 second?"),
        steps([step("division", [60, 15], 4)]),
        answer(4, "meters"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U4-L8'), grade('6'), record_id('im_defrag_e67f26dfca5ecf984bf3a875_1'), statement_sha('0f7d251efae88a41fba687a66e04d2753ce052184e44bf2fb56f35a0defd17d0')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e6b6213f51a8722429a32cf9_1', "Kiran said that this diagram can show the solution to 16 ÷ 8 = ? ... [16 over two segments of 8]",
    analysis(
        quantities([quantity(16, "number", "16"), quantity(8, "number", "8")]),
        ask("What is the solution to 16 ÷ 8?"),
        steps([step("divide", [16, 8], 2)]),
        answer(2, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U4-L3'), grade('6'), record_id('im_defrag_e6b6213f51a8722429a32cf9_1'), statement_sha('7e6346c4351a586d54518c2b925f5a1687dbe936dd87c1d9bfbcd46c35870da9')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e6bfe7746c910b8006f4fa63_1', "Clare has $54 in her bank account. A store credits her account with a $10 refund. How much does she now have in the bank?",
    analysis(
        quantities([quantity(54, "dollars", "$54"), quantity(10, "dollars", "$10")]),
        ask("How much money does Clare have in her bank account now?"),
        steps([step("addition", [54, 10], 64)]),
        answer(64, "dollars"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U5-L4'), grade('7'), record_id('im_defrag_e6bfe7746c910b8006f4fa63_1'), statement_sha('361e4046cca3211c31c232a6a928a04d5209d14bdeaf7d22bda67240d7bf3d4a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e75b0aa058f7909c28280fd9_1', "How far does the car travel in 14 hours? [solution: multiply 140 by 7 to get 980 kilometers]",
    analysis(
        quantities([quantity(14, "hours", "14 hours"), quantity(140, "km/h", "140"), quantity(7, "hours", "7")]),
        ask("How far does the car travel in 14 hours?"),
        steps([step("multiply", [140, 7], 980)]),
        answer(980, "kilometers"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L11'), grade('6'), record_id('im_defrag_e75b0aa058f7909c28280fd9_1'), statement_sha('06f74a20f4637d1c73b7efbadc2b6c8ade0956db2e7d0d93cbc4d35d19b9c57e')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_0.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e7a8300bc4fd5dfea488f5f6_1', "2 + 2 + 2 = 3 + 3",
    analysis(
        quantities([quantity(2, "number", "2"), quantity(3, "number", "3")]),
        ask("Check if the sum of three 2s is equal to the sum of two 3s."),
        steps([step("addition", [2, 2, 2], 6), step("addition", [3, 3], 6), step("compare_equal", [6, 6], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U8-L10'), grade('2'), record_id('im_defrag_e7a8300bc4fd5dfea488f5f6_1'), statement_sha('2558a296302a5d4bf0a2fe5886fe95adf57070dfa3fffa592d820a49f188097f')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e7e39e7cbf9cf16aa69c026d_1', "1. There are many possible rectangles whose perimeter is 50 units. Complete the table with lengths, , and widths, , of at least 10 such rectangles. 2. On the graph, plot the length and width of rectangles whose perimeter is 50 units using the values from your table. Using a straightedge, draw the line that passes through these points. 3. What is the slope of this line? What does the slope mean in this situation? 4. Write an equation for this line. [Recovered figure from image_000049_fcef6427671d0cade105eafa3fe7194fc957d8d8597bc1b0f09d42d778160226.png] Named points: O=(0, 0).",
    analysis(
        quantities([quantity(50, "units", "50")]),
        ask("Determine the slope and the meaning of the slope, and write an equation for the line representing the relationship between the length and width of rectangles with a perimeter of 50 units."),
        steps([step("division", [50, 2], 25), step("subtraction", [25, 1], 24), step("subtraction", [25, 2], 23), step("subtraction", [25, 10], 15), step("division", [-1, 1], -1)]),
        answer(-1, "slope"),
        missing_doing("modeling a relationship between variables")),
    anchor(lesson('IM-G8-U3-L12'), grade('8'), record_id('im_defrag_e7e39e7cbf9cf16aa69c026d_1'), statement_sha('fcbc8b4bfc8b1a815bc1d5984dfe0e6bfff3d3a965c900506c2652b67c5aae37')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e7e5685efcbc7378e820c8cf_1', "A car is traveling east at 12 meters per second. Where will it be 10 seconds after it passes the camera? (car A: +12, +10)",
    analysis(
        quantities([quantity(12, "meters per second", "12 meters per second"), quantity(10, "seconds", "10 seconds")]),
        ask("What is the position of the car 10 seconds after it passes the camera?"),
        steps([step("multiply", [12, 10], 120)]),
        answer(120, "meters east"),
        missing_doing("modeling position relative to a reference point")),
    anchor(lesson('IM-G7-U5-L8'), grade('7'), record_id('im_defrag_e7e5685efcbc7378e820c8cf_1'), statement_sha('56f05872c69af618bc6b34dc761448ca9dde5871dbaf3e92f79c8b910f2f271a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e7eb876fb084d7441911dfcf_1', "Diego has 7 pets. He has 4 dogs. He has some cats. How many cats does Diego have? Show your thinking using drawings, numbers, or words",
    analysis(
        quantities([quantity(7, "pets", "7 pets"), quantity(4, "dogs", "4 dogs")]),
        ask("How many cats does Diego have?"),
        steps([step("subtraction", [7, 4], 3)]),
        answer(3, "cats"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U2-L9'), grade('1'), record_id('im_defrag_e7eb876fb084d7441911dfcf_1'), statement_sha('bc224803ba40269d37e6ce6727b4ba713a87bf9dc0e58c8c4f18a5462654fe70')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e850b9e7597516ff3bc3a2c3_1', "4 movie tickets cost $48. At this rate, what is the cost of a. 5 movie tickets?",
    analysis(
        quantities([quantity(4, "movie tickets", "4 movie tickets"), quantity(48, "dollars", "$48"), quantity(5, "movie tickets", "5 movie tickets")]),
        ask("What is the cost of 5 movie tickets at the same rate?"),
        steps([step("division", [48, 4], 12), step("multiplication", [12, 5], 60)]),
        answer(60, "dollars"),
        missing_doing("unit rate calculation")),
    anchor(lesson('IM-G6-U2-L8'), grade('6'), record_id('im_defrag_e850b9e7597516ff3bc3a2c3_1'), statement_sha('5cfd857bd83f567317656a110f8781bdbc4f22346564be3655879f3af7c6ca52')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e85d2a2d919e83b3d389c96b_1', "15 + 12 = 27",
    analysis(
        quantities([quantity(15, "number", "15"), quantity(12, "number", "12"), quantity(27, "number", "27")]),
        ask("Is the equation 15 + 12 = 27 true?"),
        steps([step("addition", [15, 12], 27), step("compare_equal", [27, 27], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U3-L12'), grade('2'), record_id('im_defrag_e85d2a2d919e83b3d389c96b_1'), statement_sha('ad5c3c9406b9307a8f9a2efb4fee3cc14ac3fa36dccd3b710185521ca921a000')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e869aa709b0bf0fab602b502_1', "Find the value of 23 + 24. Show your thinking using the number line.",
    analysis(
        quantities([quantity(23, "number", "23"), quantity(24, "number", "24")]),
        ask("Find the value of 23 + 24."),
        steps([step("addition", [23, 24], 47)]),
        answer(47, "number"),
        missing_doing("visualizing on a number line")),
    anchor(lesson('IM-G2-U4-L10'), grade('2'), record_id('im_defrag_e869aa709b0bf0fab602b502_1'), statement_sha('57253d36d2865c9a682cba914116ec4e1534d2db4af2f17b255603b1e30a0ede')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_5.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e87d2c38b3b3559800af04ab_1', "1. Find the value of 621.45 + 72.3. Explain or show your reasoning. 2. Elena and Andre try to find the value of 621.45 + 72.3. Who do you agree with? Explain or show your reasoning.",
    analysis(
        quantities([quantity(621.45, "number", "621.45"), quantity(72.3, "number", "72.3")]),
        ask("Find the sum of 621.45 and 72.3."),
        steps([step("addition", [621.45, 72.3], 693.75)]),
        answer(693.75, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U5-L13'), grade('5'), record_id('im_defrag_e87d2c38b3b3559800af04ab_1'), statement_sha('54fd9bef3695d42d2dc12f69fb1ffa3aebe5646b48d901c7ca08f06414f83596')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e8d71029b991adc0117ed932_1', "• Seven teachers go to the park. • Each teacher takes 7 students. • Each student brings 7 fishbowls. • Each fishbowl has 7 fish. How many go to the park? Record an estimate that is: too low about right too high",
    analysis(
        quantities([quantity(7, "teachers", "Seven teachers"), quantity(7, "students per teacher", "7 students"), quantity(7, "fishbowls per student", "7 fishbowls"), quantity(7, "fish per fishbowl", "7 fish")]),
        ask("How many total living things (teachers, students, and fish) go to the park?"),
        steps([step("multiplication", [7, 7], 49), step("multiplication", [49, 7], 343), step("multiplication", [343, 7], 2401), step("addition", [7, 49, 343, 2401], 2800)]),
        answer(2800, "living things"),
        missing_doing("interpreting the ambiguity of 'How many go to the park?' (whether it refers to people or all entities mentioned) and performing estimation judgment")),
    anchor(lesson('IM-G4-U9-L5'), grade('4'), record_id('im_defrag_e8d71029b991adc0117ed932_1'), statement_sha('db3dc47ece06a75f8f0893faf943dc5b7ec5507f813a05b6c04759698554677e')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e905eedb6982e4395dbc8726_1', "1. 5 cubes 4 cylinders 6 cones How many shapes did you use? _______________ 2. 3 cones 4 cubes 5 cylinders How many? _______________",
    analysis(
        quantities([quantity(5, "cubes", "5 cubes"), quantity(4, "cylinders", "4 cylinders"), quantity(6, "cones", "6 cones"), quantity(3, "cones", "3 cones"), quantity(4, "cubes", "4 cubes"), quantity(5, "cylinders", "5 cylinders")]),
        ask("What is the total number of shapes in the first set and the second set?"),
        steps([step("addition", [5, 4, 6], 15), step("addition", [3, 4, 5], 12)]),
        answer(15, "shapes"),
        missing_doing("resolving multiple independent questions")),
    anchor(lesson('IM-GK-U7-L15'), grade('K'), record_id('im_defrag_e905eedb6982e4395dbc8726_1'), statement_sha('09e9a0f6343f650209866b3945513cd7d3d0533175b7add9f0fbc88a71880f78')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_3.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e927763d9ff1c83a33873351_1', "Find the value of 448 ÷ 16. Show your thinking.",
    analysis(
        quantities([quantity(448, "number", "448"), quantity(16, "number", "16")]),
        ask("Find the value of 448 ÷ 16."),
        steps([step("divide", [448, 16], 28)]),
        answer(28, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U4-L11'), grade('5'), record_id('im_defrag_e927763d9ff1c83a33873351_1'), statement_sha('6f593ed7042505f205f1b4f79211fb2875c53f39846095de4d18b9ce80dab83e')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_4.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e95f7f14a95e0d3c998a8a9c_1', "supplies cost notebook 26¢ colored pencil 18¢ pencil box 39¢ glue stick 44¢ 1. Solve 1 of the problems. Show your thinking, using drawings, numbers, or words. a. Andre buys a glue stick and a notebook. He has 15 cents left over. How much money did he start with? b. Jada buys a pencil box and 2 colored pencils. Lin buys 2 glue sticks. Who spends more? How much more? 2. Trade work with a partner. Decide whether your partner’s answer makes sense. Explain your reasoning.",
    analysis(
        quantities([quantity(26, "cents", "26¢"), quantity(18, "cents", "18¢"), quantity(39, "cents", "39¢"), quantity(44, "cents", "44¢"), quantity(15, "cents", "15 cents")]),
        ask("For part a, how much money did Andre start with if he buys a glue stick and a notebook and has 15 cents left over?"),
        steps([step("addition", [44, 26], 70), step("addition", [70, 15], 85)]),
        answer(85, "cents"),
        missing_doing("problem selection")),
    anchor(lesson('IM-G2-U6-L20'), grade('2'), record_id('im_defrag_e95f7f14a95e0d3c998a8a9c_1'), statement_sha('027871948ba0c005b292fe03f3908efd1f7ec846eed53e0f70ebe71ae1329b3d')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e9a4916d46980207972a565f_1', "Lin has a watch that counts the number of steps she takes during the day. The watch displays her steps in centimeters, meters, or kilometers. 1. Here is a list of activities Lin did on Monday. Next to each activity, write whether it would make sense to display the distance in centimeters, meters, or kilometers. ◦ walked to her friend’s desk ◦ walked to the front of the classroom ◦ walked from her classroom to the bus ◦ ran twice around the playground 2. The table shows the amount of steps Lin’s watch displayed for each activity. If each of Lin’s steps is 50 centimeters, how many centimeters and how many meters did she walk for each activity? number distance distance activity of steps (cm) (m) walked to her friend’s 5 desk walked to the front 12 of the classroom walked from her 250 classroom to the bus ran twice around the 1,000 playground 3. At the end of the day, Lin’s watch displayed 8,500 steps. Should her watch record the distance in centimeters, meters, or kilometers? Explain your reasoning. 4. How many kilometers did Lin walk on Monday?",
    analysis(
        quantities([quantity(50, "centimeters", "50 centimeters"), quantity(5, "steps", "5"), quantity(12, "steps", "12"), quantity(250, "steps", "250"), quantity(1000, "steps", "1,000"), quantity(8500, "steps", "8,500")]),
        ask("How many kilometers did Lin walk on Monday?"),
        steps([step("multiplication", [5, 50], 250), step("multiplication", [12, 50], 600), step("multiplication", [250, 50], 12500), step("multiplication", [1000, 50], 50000), step("addition", [250, 600, 12500, 50000], 63350), step("division", [63350, 1000], 63.35)]),
        answer(63.35, "kilometers"),
        missing_doing("summing the total distance of all activities mentioned in the table to find the day's total distance before converting to kilometers")),
    anchor(lesson('IM-G5-U6-L5'), grade('5'), record_id('im_defrag_e9a4916d46980207972a565f_1'), statement_sha('7dfb477025284b64d2249640ee6b5620f3b027dbeaf525354ec30981afa5844f')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e9aaafe3bb4c17f02ff050f2_1', "Find the value of each quotient mentally. 80 ÷ 4",
    analysis(
        quantities([quantity(80, "number", "80"), quantity(4, "number", "4")]),
        ask("What is the quotient of 80 divided by 4?"),
        steps([step("division", [80, 4], 20)]),
        answer(20, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U5-L12'), grade('6'), record_id('im_defrag_e9aaafe3bb4c17f02ff050f2_1'), statement_sha('b669679d2430460330a5062d82f266cf52441a8abeea5ef5ed297ad7df2e9cd7')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_e9f4b0c9777b1f33be066a3a_1', "There are 10 kids on the bus. 1 kid gets off the bus. How many kids are on the bus?",
    analysis(
        quantities([quantity(10, "kids", "10 kids"), quantity(1, "kid", "1 kid")]),
        ask("How many kids are remaining on the bus?"),
        steps([step("subtraction", [10, 1], 9)]),
        answer(9, "kids"),
        missing_doing(null)),
    anchor(lesson('IM-GK-U8-L3'), grade('K'), record_id('im_defrag_e9f4b0c9777b1f33be066a3a_1'), statement_sha('2adef4829a6e302f186ae5866c44cb8f195fd364b8829c32fc25db91a34036c1')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_ea0396ccb9fabccde08950f2_1', "3 × 40 = 7 × 10",
    analysis(
        quantities([quantity(3, "number", "3"), quantity(40, "number", "40"), quantity(7, "number", "7"), quantity(10, "number", "10")]),
        ask("Determine if 3 times 40 is equal to 7 times 10."),
        steps([step("multiplication", [3, 40], 120), step("multiplication", [7, 10], 70), step("compare_equal", [120, 70], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L17'), grade('3'), record_id('im_defrag_ea0396ccb9fabccde08950f2_1'), statement_sha('527cf78d2cb58d7e82fc740d34b083c9c13f70cfc7f1a2ea40ae7a298126a58a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_ea82c4159840672019e8bf4c_1', "Mai ran 6.3 kilometers in 45 minutes. At what rate did she run?",
    analysis(
        quantities([quantity(6.3, "kilometers", "6.3 kilometers"), quantity(45, "minutes", "45 minutes")]),
        ask("What was Mai's running rate?"),
        steps([step("division", [6.3, 45], 0.14)]),
        answer(0.14, "kilometers per minute"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U3-L4'), grade('6'), record_id('im_defrag_ea82c4159840672019e8bf4c_1'), statement_sha('0126598da4f89a980211dbf472e7979c139e27fb37355e69f0957724db22e661')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_eaf6c4c8e139e7ce13993449_1', "If you poured 15 teaspoons of salt into an empty graduated cylinder, about how many milliliters would it fill?",
    analysis(
        quantities([quantity(15, "teaspoons", "15 teaspoons")]),
        ask("About how many milliliters would 15 teaspoons of salt fill in a graduated cylinder?"),
        steps([step("multiply", [15, 5], 75)]),
        answer(75, "milliliters"),
        missing_doing("unit conversion")),
    anchor(lesson('IM-G6-U3-L2'), grade('6'), record_id('im_defrag_eaf6c4c8e139e7ce13993449_1'), statement_sha('be4045fba9aca50c9cd9503dc023c7fc6cb766b3242b9c5514e3df14aa67ca9d')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_eb4ba9b04e5462e147885c24_1', "How much would 1,000 raffle tickets cost at $4 per ticket?",
    analysis(
        quantities([quantity(1000, "tickets", "1,000 raffle tickets"), quantity(4, "dollars per ticket", "$4 per ticket")]),
        ask("How much would 1,000 raffle tickets cost if each ticket is $4?"),
        steps([step("multiplication", [1000, 4], 4000)]),
        answer(4000, "dollars"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U3-L5'), grade('6'), record_id('im_defrag_eb4ba9b04e5462e147885c24_1'), statement_sha('086f58f042582e299060a1e11e6e86c70a24a45fc0fa2a026d5779c99c2f444a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_eb542a3140f1ac075f3231d9_1', "Find the value of 51 ÷ 3. Use base-ten blocks if they are helpful.",
    analysis(
        quantities([quantity(51, "number", "51"), quantity(3, "number", "3")]),
        ask("What is the value of 51 divided by 3?"),
        steps([step("division", [51, 3], 17)]),
        answer(17, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L19'), grade('3'), record_id('im_defrag_eb542a3140f1ac075f3231d9_1'), statement_sha('6e34d5ed96d1aa0beb72a81037a11af3fc61bd0cc9b30c94436cc9dba468b87f')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_eb71214c7a0390feead6d22f_1', "Mai needs 26 fl oz of water ... The only measuring tool she has is a 4-fl oz scoop. How many scoops will it take to measure 26 fl oz of water?",
    analysis(
        quantities([quantity(26, "fl oz", "26 fl oz"), quantity(4, "fl oz", "4-fl oz")]),
        ask("How many 4-fl oz scoops are required to measure 26 fl oz of water?"),
        steps([step("division", [26, 4], 6.5)]),
        answer(6.5, "scoops"),
        missing_doing("interpreting if a partial scoop is allowed in a real-world context")),
    anchor(lesson('IM-G6-U4-L3'), grade('6'), record_id('im_defrag_eb71214c7a0390feead6d22f_1'), statement_sha('940d4337dbf7ad81c4e48a3d6fd98083bbddc3850c072b98a0a53f2f080bb451')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_eb759f7ac3299c852a9b119c_1', "Find the product of 18 and 14 in two ways: a. Calculate numerically. b. Find the area of this 18-by-14 rectangle.",
    analysis(
        quantities([quantity(18, "length", "18"), quantity(14, "width", "14")]),
        ask("Find the product of 18 and 14 using numerical calculation and by finding the area of an 18-by-14 rectangle."),
        steps([step("multiplication", [18, 14], 252)]),
        answer(252, "product"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U5-L7'), grade('6'), record_id('im_defrag_eb759f7ac3299c852a9b119c_1'), statement_sha('fca755ab881f1feb8d65ec50aadf6f49a9423e11bae89a84312d9a65bcaa6965')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_ebd599e4de2b45e997b25ef9_1', "8 × 20 = 8 × 2 × 1",
    analysis(
        quantities([quantity(8, "number", "8"), quantity(20, "number", "20"), quantity(8, "number", "8"), quantity(2, "number", "2"), quantity(1, "number", "1")]),
        ask("Check if 8 times 20 is equal to 8 times 2 times 1."),
        steps([step("multiplication", [8, 20], 160), step("multiplication", [8, 2], 16), step("multiplication", [16, 1], 16), step("compare_equal", [160, 16], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L19'), grade('3'), record_id('im_defrag_ebd599e4de2b45e997b25ef9_1'), statement_sha('df5d31c299a2bb6f764f164914e58a34ff29eb58240b08cad173710104d468e3')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_ed2020c7304e818be2ac81e1_1', "How long is 50% of a 24-hour day? d.",
    analysis(
        quantities([quantity(50, "percent", "50%"), quantity(24, "hours", "24-hour")]),
        ask("How many hours is 50% of a 24-hour day?"),
        steps([step("multiplication", [0.5, 24], 12)]),
        answer(12, "hours"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U3-L13'), grade('6'), record_id('im_defrag_ed2020c7304e818be2ac81e1_1'), statement_sha('d499aa0497901c275b52fa8b2d0251ebce4dfff70f5c7d0f3ea39bb00be1bd6b')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_edcfecc289fb2a5bffc6d99d_1', "2. 58 students want to see the bears. 27 students want to see the lions. How many more students want to see the bears than the lions?",
    analysis(
        quantities([quantity(58, "students", "58 students"), quantity(27, "students", "27 students")]),
        ask("How many more students want to see the bears than the lions?"),
        steps([step("subtraction", [58, 27], 31)]),
        answer(31, "students"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U2-L3'), grade('2'), record_id('im_defrag_edcfecc289fb2a5bffc6d99d_1'), statement_sha('bf981cc2788c2dbef921323d10fb425ff5831519893293e2667e08481e7a2abc')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_ee35a9562e59194d9494895f_1', "24 + 29 = 50",
    analysis(
        quantities([quantity(24, "number", "24"), quantity(29, "number", "29"), quantity(50, "number", "50")]),
        ask("Is the equation 24 + 29 = 50 true?"),
        steps([step("add", [24, 29], 53), step("compare_equal", [53, 50], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U2-L15'), grade('2'), record_id('im_defrag_ee35a9562e59194d9494895f_1'), statement_sha('e033acc9a857c337bd5b5290888d2f15514311b37ded5a28e73dce1765d58e4d')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_ee6cdc802b38e60ce3c46e8a_1', "1. Complete the table. volume base height (cubic feet) (square feet) (feet) 375 15 1,176 28 2. Clare wants to find the height of a rectangular prism with these measurements. volume length width height (cubic feet) (feet) (feet) (feet) 882 6 7 a. First, Clare finds the quotient 882 ÷ 6. What could she do next to find the height? b. Find the unknown height to finish the problem for Clare. 3. Complete the table. volume length width height (cubic feet) (feet) (feet) (feet) 936 8 9 1,536 48 2 1,008 36",
    analysis(
        quantities([quantity(882, "cubic feet", "882"), quantity(6, "feet", "6"), quantity(7, "feet", "7")]),
        ask("What is the height of the rectangular prism with a volume of 882 cubic feet, length of 6 feet, and width of 7 feet?"),
        steps([step("division", [882, 6], 147), step("division", [147, 7], 21)]),
        answer(21, "feet"),
        missing_doing("understanding the relationship between volume, length, width, and height in a rectangular prism")),
    anchor(lesson('IM-G5-U4-L14'), grade('5'), record_id('im_defrag_ee6cdc802b38e60ce3c46e8a_1'), statement_sha('c41e57a5cec785fe4fbf94e002e556786c04d3603c7e377e7b9e33009e19d452')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_ef76c9a317b9432fa1f34925_1', "There were 4,704 people at the record-breaking folk dance in Peru. How many groups of 8 dancers were there? Explain or show your thinking.",
    analysis(
        quantities([quantity(4704, "people", "4,704 people"), quantity(8, "dancers per group", "8 dancers")]),
        ask("How many groups of 8 dancers were there in total?"),
        steps([step("division", [4704, 8], 588)]),
        answer(588, "groups"),
        missing_doing(null)),
    anchor(lesson('IM-G5-U4-L9'), grade('5'), record_id('im_defrag_ef76c9a317b9432fa1f34925_1'), statement_sha('7d60aaaf67d35b5c7e49341204956d2233fe0635ba894f308acab81a96cc91b2')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_efc2e0f89eb7dc627d5d5c6c_1', "4 + 6 = 10",
    analysis(
        quantities([quantity(4, "number", "4"), quantity(6, "number", "6"), quantity(10, "number", "10")]),
        ask("Is 4 plus 6 equal to 10?"),
        steps([step("addition", [4, 6], 10), step("compare_equal", [10, 10], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U2-L5'), grade('1'), record_id('im_defrag_efc2e0f89eb7dc627d5d5c6c_1'), statement_sha('3ae7b0d51c2a23a26fdb32ff00ad4af95988729cbe6c9cef5dc1673367fd1637')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_f04079a002cabeae1b47fe52_1', "A stack of books is 72 inches tall. Each book is 2 inches thick. Which expression tells us how many books are in the stack? 72 ÷ 2",
    analysis(
        quantities([quantity(72, "inches", "72 inches"), quantity(2, "inches", "2 inches")]),
        ask("How many books are in the stack?"),
        steps([step("divide", [72, 2], 36)]),
        answer(36, "books"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U4-L1'), grade('6'), record_id('im_defrag_f04079a002cabeae1b47fe52_1'), statement_sha('29140bf5183b60c249ccfec196f09089481e1e42ae1294db3dc9d778e8925c68')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_f117399b7e57dfb7a0af27cd_1', "Clare has 48 markers. She puts 8 markers into each goodie bag for her birthday party. How many bags will she use? Which drawing matches the situation? Explain your reasoning. A B",
    analysis(
        quantities([quantity(48, "markers", "48 markers"), quantity(8, "markers per bag", "8 markers into each goodie bag")]),
        ask("How many goodie bags will Clare use?"),
        steps([step("division", [48, 8], 6)]),
        answer(6, "bags"),
        missing_doing("visual matching and explanation")),
    anchor(lesson('IM-G3-U4-L3'), grade('3'), record_id('im_defrag_f117399b7e57dfb7a0af27cd_1'), statement_sha('4e33269191e79c2f9706b744331b0305a0d7ebf873eaa5d57bea2efd4b8f9d39')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_f14a74e83e4e1c8779aa9fe7_1', "900,000 + 20,000 + 3,000 = 920,000 + 3,000",
    analysis(
        quantities([quantity(900000, "number", "900,000"), quantity(20000, "number", "20,000"), quantity(3000, "number", "3,000"), quantity(920000, "number", "920,000"), quantity(3000, "number", "3,000")]),
        ask("Determine if the equation 900,000 + 20,000 + 3,000 = 920,000 + 3,000 is true."),
        steps([step("addition", [900000, 20000], 920000), step("addition", [920000, 3000], 923000), step("addition", [920000, 3000], 923000), step("compare_equal", [923000, 923000], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U4-L9'), grade('4'), record_id('im_defrag_f14a74e83e4e1c8779aa9fe7_1'), statement_sha('1ba858d7778cb55a6a806938499de2e515c31847fc62da5a2e364de0a7bb1540')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_f179badb4ebfdba5828172ab_1', "4 × 5 = 5 × 4",
    analysis(
        quantities([quantity(4, "number", "4"), quantity(5, "number", "5"), quantity(5, "number", "5"), quantity(4, "number", "4")]),
        ask("Check if 4 times 5 is equal to 5 times 4."),
        steps([step("multiplication", [4, 5], 20), step("multiplication", [5, 4], 20), step("compare_equal", [20, 20], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U3-L9'), grade('3'), record_id('im_defrag_f179badb4ebfdba5828172ab_1'), statement_sha('4d21febd33befb26b8e81c9f7071dd489ab2a77f6809849f17dd919b1c5e1ba4')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_1.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_f17e29e6e0b07ab2d11c8dc4_1', "There are 7 folders. There are 9 pens. Are there fewer folders or pens? How many fewer? Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(7, "folders", "7 folders"), quantity(9, "pens", "9 pens")]),
        ask("Determine whether there are fewer folders or pens, and calculate by how many."),
        steps([step("subtraction", [9, 7], 2)]),
        answer(2, "fewer folders"),
        missing_doing("comparative reasoning")),
    anchor(lesson('IM-G1-U2-L12'), grade('1'), record_id('im_defrag_f17e29e6e0b07ab2d11c8dc4_1'), statement_sha('a0daf43747f0d859a056d63531cb2e49a08579a11e06365095bc3c4f9f272fe8')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_f1b80c854e6ace37f04206b2_1', "Jada fills 4 jars with salsa. Each jar has 10 ounces of salsa. How many ounces of salsa are in all the jars?",
    analysis(
        quantities([quantity(4, "jars", "4 jars"), quantity(10, "ounces", "10 ounces")]),
        ask("How many total ounces of salsa are in all the jars?"),
        steps([step("multiplication", [4, 10], 40)]),
        answer(40, "ounces"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U4-L3'), grade('6'), record_id('im_defrag_f1b80c854e6ace37f04206b2_1'), statement_sha('a2dae09d45f07d4cefd2aa620f0a586fa752f0e9df27a7727ba8985e68625ced')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_f1ba2a2f94034264153f2be6_1', "Use long division to find each quotient. Write your answer as a decimal. c. 1,988 ÷ 8",
    analysis(
        quantities([quantity(1988, "number", "1,988"), quantity(8, "number", "8")]),
        ask("Find the quotient of 1,988 divided by 8 and write the answer as a decimal."),
        steps([step("division", [1988, 8], 248.5)]),
        answer(248.5, "decimal"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U5-L12'), grade('6'), record_id('im_defrag_f1ba2a2f94034264153f2be6_1'), statement_sha('6723be5d76d15c738b7c07df321354f1941dbc46769055097ac25d9ea0befdab')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_f1c28ab260a535c127b66406_1', "Solve the problem. Show your thinking using drawings, numbers, or words. Use a diagram if it helps. Elena has 64 inches of ribbon. She cut off 24 inches and kept the rest. Mai’s ribbon is 35 inches long. How much longer is Elena’s ribbon than Mai’s?",
    analysis(
        quantities([quantity(64, "inches", "64 inches"), quantity(24, "inches", "24 inches"), quantity(35, "inches", "35 inches")]),
        ask("How much longer is Elena's remaining ribbon than Mai's ribbon?"),
        steps([step("subtraction", [64, 24], 40), step("subtraction", [40, 35], 5)]),
        answer(5, "inches"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U3-L12'), grade('2'), record_id('im_defrag_f1c28ab260a535c127b66406_1'), statement_sha('2abc5a3a1ebfec137a328f34634c08a636ebacb1986f811561270fe43d95869c')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_f1e2a73915d16d4e617c036f_1', "Here is an unfinished number line diagram that represents a sum of 8. ... Mai writes 3 + ? = 8. Tyler writes 8 - 3 = ?.",
    analysis(
        quantities([quantity(8, "sum", "8"), quantity(3, "number", "3")]),
        ask("Find the value of the missing number in the equations 3 + ? = 8 and 8 - 3 = ?."),
        steps([step("subtraction", [8, 3], 5)]),
        answer(5, ""),
        missing_doing(null)),
    anchor(lesson('IM-G7-U5-L5'), grade('7'), record_id('im_defrag_f1e2a73915d16d4e617c036f_1'), statement_sha('f9f335de91d07ceac98b8810f588b03da8c61b7e6de6f8d2b554361505cd682e')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_f264364af673c8319b46a8e5_1', "3 + 5 = 8",
    analysis(
        quantities([quantity(3, "number", "3"), quantity(5, "number", "5"), quantity(8, "number", "8")]),
        ask("Is 3 plus 5 equal to 8?"),
        steps([step("add", [3, 5], 8), step("compare_equal", [8, 8], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L4'), grade('1'), record_id('im_defrag_f264364af673c8319b46a8e5_1'), statement_sha('fd7ffe60acb56f3e1215b31baa6560048e465106f4a0454f4cf9fb3e5bc35e4f')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_f354673fbf226a5e614dcc73_1', "463 - 52",
    analysis(
        quantities([quantity(463, "number", "463"), quantity(52, "number", "52")]),
        ask("What is the result of subtracting 52 from 463?"),
        steps([step("subtraction", [463, 52], 411)]),
        answer(411, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U7-L14'), grade('2'), record_id('im_defrag_f354673fbf226a5e614dcc73_1'), statement_sha('5fe135d49bb807867e6fd5debe18eb0694e7618db165b6c2f111d7eae1bac90f')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_f3949a3c18abd80525a4bf0c_1', "Lin’s class has 6 tables. Each table has 2 bags of clay.",
    analysis(
        quantities([quantity(6, "tables", "6 tables"), quantity(2, "bags of clay", "2 bags of clay")]),
        ask("How many bags of clay are there in Lin's class?"),
        steps([step("multiply", [6, 2], 12)]),
        answer(12, "bags of clay"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U1-L15'), grade('3'), record_id('im_defrag_f3949a3c18abd80525a4bf0c_1'), statement_sha('fc2ccbf5a2965095b3570ccf0b733ddc418682b5e595fe3be7e80fb4af119c1b')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_3.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_f3fd0066d1cfda4b1840cd21_1', "A 2,100-square-foot home in Cheyenne, Wyoming, costs $110 per square foot. How much does this home cost?",
    analysis(
        quantities([quantity(2100, "square feet", "2,100-square-foot"), quantity(110, "dollars per square foot", "$110 per square foot")]),
        ask("How much does the 2,100-square-foot home cost?"),
        steps([step("multiply", [2100, 110], 231000)]),
        answer(231000, "dollars"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U3-L4'), grade('6'), record_id('im_defrag_f3fd0066d1cfda4b1840cd21_1'), statement_sha('35cffb16f1da9883f8957790b33a8bce34a7f47434cac71deb7785b930b85d34')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_f435712afe34fb52b5e08bf9_1', "Find the value of 59 + 27.",
    analysis(
        quantities([quantity(59, "number", "59"), quantity(27, "number", "27")]),
        ask("Find the value of 59 + 27."),
        steps([step("addition", [59, 27], 86)]),
        answer(86, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U4-L11'), grade('2'), record_id('im_defrag_f435712afe34fb52b5e08bf9_1'), statement_sha('cdae55b7c2076d0d00820825693ce90d8484c7ac2d3756f192cdd219fc321391')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_0.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_f4693e7d2c08262d0ab116e4_1', "2 × 45 = 6 × 15",
    analysis(
        quantities([quantity(2, "multiplier", "2"), quantity(45, "multiplicand", "45"), quantity(6, "multiplier", "6"), quantity(15, "multiplicand", "15")]),
        ask("Check if 2 times 45 is equal to 6 times 15."),
        steps([step("multiplication", [2, 45], 90), step("multiplication", [6, 15], 90), step("compare_equal", [90, 90], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U7-L9'), grade('4'), record_id('im_defrag_f4693e7d2c08262d0ab116e4_1'), statement_sha('96d07d9135b509335170afd9068fcb8ffb10bce16d6cc1cba61944a25dcffbe9')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_f4fe78be6d47351e9d4c67c3_1', "Use the numbers 6, 7, 8, and 9 to make the greatest product. Explain how you know it is the greatest product.",
    analysis(
        quantities([quantity(6, "number", "6"), quantity(7, "number", "7"), quantity(8, "number", "8"), quantity(9, "number", "9")]),
        ask("What is the greatest product that can be made using the numbers 6, 7, 8, and 9?"),
        steps([step("multiplication", [6, 7, 8, 9], 3024)]),
        answer(3024, "product"),
        missing_doing("combinatorial optimization and exhaustive verification")),
    anchor(lesson('IM-G5-U3-L19'), grade('5'), record_id('im_defrag_f4fe78be6d47351e9d4c67c3_1'), statement_sha('8615718017a6cc964e2e0fb9bef6fe917b092ab7e67b09fad336c037117ef3b8')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_f508309819fc07bd61546942_1', "3 × 45 = 180- 90",
    analysis(
        quantities([quantity(3, "number", "3"), quantity(45, "number", "45"), quantity(180, "number", "180"), quantity(90, "number", "90")]),
        ask("Determine if 3 multiplied by 45 is equal to 180 minus 90."),
        steps([step("multiplication", [3, 45], 135), step("subtraction", [180, 90], 90), step("compare_equal", [135, 90], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U7-L9'), grade('4'), record_id('im_defrag_f508309819fc07bd61546942_1'), statement_sha('9e77958c9abb6e95e25f54dbdccdd63d45796ba9b479bd0e58b8bb33387df5d6')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_f5a5c0e025c2e5145066c0b2_1', "Clare watches 16 bullfrogs at the aquarium. Then some of them swim away. Now Clare can only see 9 bullfrogs. How many bullfrogs swim away? Andre wrote , but he doesn’t know how to find the unknown number. Show Andre how you would find the unknown number. Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(16, "bullfrogs", "16 bullfrogs"), quantity(9, "bullfrogs", "9 bullfrogs")]),
        ask("How many bullfrogs swam away?"),
        steps([step("subtraction", [16, 9], 7)]),
        answer(7, "bullfrogs"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U8-L4'), grade('1'), record_id('im_defrag_f5a5c0e025c2e5145066c0b2_1'), statement_sha('09ddbb4758186e46a4b2aab339278484cf0270c7705381e5c2a53c420592f7d1')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_f5d02274d6c49ac3a8cf2ed0_1', "2 + 2 + 2 = 3 + 3",
    analysis(
        quantities([quantity(2, "number", "2"), quantity(3, "number", "3")]),
        ask("Determine if the equation 2 + 2 + 2 = 3 + 3 is true."),
        steps([step("addition", [2, 2, 2], 6), step("addition", [3, 3], 6), step("compare_equal", [6, 6], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U8-L13'), grade('2'), record_id('im_defrag_f5d02274d6c49ac3a8cf2ed0_1'), statement_sha('2558a296302a5d4bf0a2fe5886fe95adf57070dfa3fffa592d820a49f188097f')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_f63c1c4cd2c30cd93ceb5058_1', "1. Some children listen to a story. Then some more children join the group. What do you notice? What do you wonder? 2. 6 children listen to a story. Then 4 more children join the group. How many children listen to the story now? 3. Some children are at the library. Then some of the children go home. What do you notice? What do you wonder? 4. 8 children are at the library. Then 2 of the children go home. How many children are at the library now?",
    analysis(
        quantities([quantity(6, "children", "6 children"), quantity(4, "children", "4 more children"), quantity(8, "children", "8 children"), quantity(2, "children", "2 of the children")]),
        ask("How many children listen to the story now and how many are at the library now?"),
        steps([step("addition", [6, 4], 10), step("subtraction", [8, 2], 6)]),
        answer(10, "children"),
        missing_doing("handling multiple questions")),
    anchor(lesson('IM-G1-U2-L1'), grade('1'), record_id('im_defrag_f63c1c4cd2c30cd93ceb5058_1'), statement_sha('2566782775a3279834c41130b001f6059711662ad4d9e2838fc785642fcfdb6a')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_3.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_f685bc6e3fb5254cee339429_1', "1. Partner A: Build a rectangular prism with 12 cubes. 2. Partner B: Build a rectangular prism with 10 cubes. 3. Put your 2 rectangular prisms together to make one figure. What is the volume of the new figure? Explain or show your reasoning. 4. Diego and Jada put together 2 rectangular prisms to make this figure. a. What is the volume of the figure Diego and Jada made? b. Which rectangular prisms could Diego and Jada each have built? Show your thinking. Organize your work so it can be followed by others.",
    analysis(
        quantities([quantity(12, "cubes", "12 cubes"), quantity(10, "cubes", "10 cubes")]),
        ask("What is the volume of the new figure formed by putting the two rectangular prisms together?"),
        steps([step("addition", [12, 10], 22)]),
        answer(22, "cubes"),
        missing_doing("interpreting the visual information and making inferences about possible component prisms for part b")),
    anchor(lesson('IM-G5-U1-L8'), grade('5'), record_id('im_defrag_f685bc6e3fb5254cee339429_1'), statement_sha('2c3616f00296e3afe8c20b8c19537339f8758bdb11c9088a9c949c96bc752053')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_f8066b4c0286480b4ea69193_1', "42 apples in boxes. She puts 6 apples in each box. How many boxes are there?",
    analysis(
        quantities([quantity(42, "apples", "42 apples"), quantity(6, "apples per box", "6 apples")]),
        ask("How many boxes are needed for 42 apples if each box contains 6 apples?"),
        steps([step("division", [42, 6], 7)]),
        answer(7, "boxes"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L1'), grade('3'), record_id('im_defrag_f8066b4c0286480b4ea69193_1'), statement_sha('6cc00cf98605f839af27c3439e75822d90680f164869143d18a846d50b79cbf6')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_f814df555f748faf892da9ac_1', "The black fabric is 9 yards by 2 yards. The purple fabric is 4 yards by 5 yards. Which piece of fabric has a larger area?",
    analysis(
        quantities([quantity(9, "yards", "9"), quantity(2, "yards", "2"), quantity(4, "yards", "4"), quantity(5, "yards", "5")]),
        ask("Which piece of fabric has a larger area?"),
        steps([step("multiplication", [9, 2], 18), step("multiplication", [4, 5], 20)]),
        answer(20, "square yards"),
        missing_doing("selection")),
    anchor(lesson('IM-G3-U2-L10'), grade('3'), record_id('im_defrag_f814df555f748faf892da9ac_1'), statement_sha('8ba3c32e2c2e2d0755094f5c8d259f965d198c14ba69563eb2d4fd26c83be2ea')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_2.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_f829c6bcb5408d8fc2fcbd70_1', "2,000- 1,234 = 1,876",
    analysis(
        quantities([quantity(2000, "number", "2,000"), quantity(1234, "number", "1,234"), quantity(1876, "number", "1,876")]),
        ask("Is 2,000 minus 1,234 equal to 1,876?"),
        steps([step("subtraction", [2000, 1234], 766), step("compare_equal", [766, 1876], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U6-L24'), grade('4'), record_id('im_defrag_f829c6bcb5408d8fc2fcbd70_1'), statement_sha('7e0eac3e7df4073341fd1f249567e7e01eaa9e7824c6ecb80cacbc948add20d9')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_f845edfcc71849a441a5c08f_1', "There are 124 beads in the bin before 96 more beads are added. Then 53 beads are used to make a bracelet. Tyler says there are 273 beads in the bin now. Explain why Tyler’s statement doesn’t make sense.",
    analysis(
        quantities([quantity(124, "beads", "124 beads"), quantity(96, "beads", "96 more beads"), quantity(53, "beads", "53 beads"), quantity(273, "beads", "273 beads")]),
        ask("Explain why Tyler's claim that there are 273 beads in the bin is incorrect."),
        steps([step("addition", [124, 96], 220), step("subtraction", [220, 53], 167), step("compare_equal", [167, 273], false)]),
        answer(false, "claim_verdict"),
        missing_doing("argumentation")),
    anchor(lesson('IM-G3-U3-L17'), grade('3'), record_id('im_defrag_f845edfcc71849a441a5c08f_1'), statement_sha('8901a366c2aeea201efa609841d06bf86b528724117461121172902c323c5aca')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_f8c5705690c4f4f3cd414e10_1', "8 × 20 = 16 × 10",
    analysis(
        quantities([quantity(8, "number", "8"), quantity(20, "number", "20"), quantity(16, "number", "16"), quantity(10, "number", "10")]),
        ask("Check if 8 multiplied by 20 is equal to 16 multiplied by 10."),
        steps([step("multiplication", [8, 20], 160), step("multiplication", [16, 10], 160), step("compare_equal", [160, 160], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U4-L19'), grade('3'), record_id('im_defrag_f8c5705690c4f4f3cd414e10_1'), statement_sha('9c656732ffb46b66549a1a0ef3df288c230594c5105f44f2b89402411e391f99')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_4.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_f98b67a466c053b2ed06172e_1', "Clare has 3 baskets. She put 4 eggs into each basket. How many eggs did she put in baskets? b.",
    analysis(
        quantities([quantity(3, "baskets", "3 baskets"), quantity(4, "eggs", "4 eggs")]),
        ask("How many eggs did Clare put in the baskets in total?"),
        steps([step("multiply", [3, 4], 12)]),
        answer(12, "eggs"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U3-L1'), grade('4'), record_id('im_defrag_f98b67a466c053b2ed06172e_1'), statement_sha('dbf427b71eb9572dd996dc7156d4c58d8474a86247d475a988991225d5c28419')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_fa282baa3c1b5b69a1e5a757_1', "Find the value of each quotient mentally. 12 ÷ 4",
    analysis(
        quantities([quantity(12, "dividend", "12"), quantity(4, "divisor", "4")]),
        ask("What is the value of the quotient of 12 divided by 4?"),
        steps([step("division", [12, 4], 3)]),
        answer(3, "quotient"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U5-L12'), grade('6'), record_id('im_defrag_fa282baa3c1b5b69a1e5a757_1'), statement_sha('920382e3c5d5fe22e015cbe99a13d5311efc4393d1408255a65c0d32eb693c60')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_fa54c65e289c45dbd6b32136_1', "Use long division to find the value of each expression. 126 ÷ 8",
    analysis(
        quantities([quantity(126, "number", "126"), quantity(8, "number", "8")]),
        ask("What is the value of the expression 126 divided by 8?"),
        steps([step("division", [126, 8], 15.75)]),
        answer(15.75, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U5-L12'), grade('6'), record_id('im_defrag_fa54c65e289c45dbd6b32136_1'), statement_sha('c07756eb2e4ce2dfc3540ffbbccf921642767e4bdadec7611434b1d00177c3d7')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_fb390562e49e7e5b142cc111_1', "Find 180 · 9.",
    analysis(
        quantities([quantity(180, "number", "180"), quantity(9, "number", "9")]),
        ask("Find 180 · 9."),
        steps([step("multiplication", [180, 9], 1620)]),
        answer(1620, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U5-L11'), grade('6'), record_id('im_defrag_fb390562e49e7e5b142cc111_1'), statement_sha('672a078bda721fc6af674c863af5dd299366d9122be74a266c153587fd45d957')),
    testimony(model('local'), backend('openai'), job(source_file('.bigred-collected/2026-08-18-coverage-grind/second_pass/grind_shard_3.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_fbb9a30a2ad25d6af6f72bb1_1', "423,450- 42,345 = 105",
    analysis(
        quantities([quantity(423450, "number", "423,450"), quantity(42345, "number", "42,345"), quantity(105, "number", "105")]),
        ask("Check if 423,450 minus 42,345 equals 105."),
        steps([step("subtraction", [423450, 42345], 381105), step("compare_equal", [381105, 105], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U4-L22'), grade('4'), record_id('im_defrag_fbb9a30a2ad25d6af6f72bb1_1'), statement_sha('71a9d7c1b695e556eeda9fc9d3f1e48b62a02811413284aa41879d15a7e3075a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_fbc6c2c1cc0c29db550e15e1_1', "Andre has 196 beads. He uses 48 beads to make a craft. Then he gives 30 beads to a friend. How many beads does Andre have left? 1. Write an equation with a letter for the unknown quantity to represent this situation. 2. Solve the problem. Explain or show your reasoning.",
    analysis(
        quantities([quantity(196, "beads", "196 beads"), quantity(48, "beads", "48 beads"), quantity(30, "beads", "30 beads")]),
        ask("How many beads does Andre have left?"),
        steps([step("subtraction", [196, 48], 148), step("subtraction", [148, 30], 118)]),
        answer(118, "beads"),
        missing_doing("formulating an algebraic equation")),
    anchor(lesson('IM-G3-U3-L19'), grade('3'), record_id('im_defrag_fbc6c2c1cc0c29db550e15e1_1'), statement_sha('8e99969071ad8a09d4cd3ee80c50e9a5fb3c674438168c8d681b0f6e2bb2c3e3')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_fc15f5c4193888470599dadf_1', "400,000- 99,999 = 311,111",
    analysis(
        quantities([quantity(400000, "number", "400,000"), quantity(99999, "number", "99,999"), quantity(311111, "number", "311,111")]),
        ask("Check if 400,000 minus 99,999 is equal to 311,111."),
        steps([step("subtraction", [400000, 99999], 300001), step("compare_equal", [300001, 311111], false)]),
        answer(false, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G4-U4-L22'), grade('4'), record_id('im_defrag_fc15f5c4193888470599dadf_1'), statement_sha('d04c79e4df339d384045e265c512f00562113b6b7c12d9b0f1109900db90321e')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_fc34c3bb6e6597019cb60d1f_1', "Diego has 55 shells. Lin has 20 fewer shells than Diego. 1. Use the story problem to complete the diagram. 2. Write an equation to find the unknown number of shells. Use ? to represent the unknown.",
    analysis(
        quantities([quantity(55, "shells", "55 shells"), quantity(20, "shells", "20 fewer shells")]),
        ask("Find the number of shells Lin has and write an equation representing the situation."),
        steps([step("subtraction", [55, 20], 35)]),
        answer(35, "shells"),
        missing_doing("modeling")),
    anchor(lesson('IM-G2-U1-L15'), grade('2'), record_id('im_defrag_fc34c3bb6e6597019cb60d1f_1'), statement_sha('13becbbac55481afefa07d317051c878096a50805d14985d1c57b67c3fd8d8c5')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_fc5beeac74a8a4ba5b1ca3a7_1', "Find each quotient. a. (long-division bracket) 5)465",
    analysis(
        quantities([quantity(5, "divisor", "5"), quantity(465, "dividend", "465")]),
        ask("What is the quotient of 465 divided by 5?"),
        steps([step("division", [465, 5], 93)]),
        answer(93, "quotient"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U5-L11'), grade('6'), record_id('im_defrag_fc5beeac74a8a4ba5b1ca3a7_1'), statement_sha('1e151b32806e85fd00f35aa17e0996a4f044bb1c207b8d38952740dfa6a5683a')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_fc7065f80cea269f67fdb19d_1', "Use long division to express each fraction as a decimal. 9/25",
    analysis(
        quantities([quantity(9, "numerator", "9"), quantity(25, "denominator", "25")]),
        ask("Express the fraction 9/25 as a decimal."),
        steps([step("divide", [9, 25], 0.36)]),
        answer(0.36, "decimal"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U4-L5'), grade('7'), record_id('im_defrag_fc7065f80cea269f67fdb19d_1'), statement_sha('2f83165c4487811b1cf08bc6e35a93bc69c8442edeae4ac0d28c53f11f678cf1')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_fd31ab0481d8189e663b811c_1', "9 + 4 = 10 + 3",
    analysis(
        quantities([quantity(9, "number", "9"), quantity(4, "number", "4"), quantity(10, "number", "10"), quantity(3, "number", "3")]),
        ask("Check if 9 + 4 is equal to 10 + 3."),
        steps([step("addition", [9, 4], 13), step("addition", [10, 3], 13), step("compare_equal", [13, 13], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G2-U1-L13'), grade('2'), record_id('im_defrag_fd31ab0481d8189e663b811c_1'), statement_sha('131dad0db86b77db945ced960ab39f0e914a2c6fac372b1e7ead36879d515892')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_fde6f89ab34316eae85751f6_1', "Find the value of 23 + 45. Show your thinking using drawings, numbers, or words.",
    analysis(
        quantities([quantity(23, "number", "23"), quantity(45, "number", "45")]),
        ask("What is the value of 23 + 45?"),
        steps([step("add", [23, 45], 68)]),
        answer(68, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U5-L2'), grade('1'), record_id('im_defrag_fde6f89ab34316eae85751f6_1'), statement_sha('fbbc23dc51bd577c5062e239628a3f42c2e2dab54c2fa4dcd0f68e1b5b3e8f73')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_fdeb98edb51bc8b65058740e_1', "How many cats are at the kennel? Cats are 4 parts at 3 animals per part.",
    analysis(
        quantities([quantity(4, "parts", "4 parts"), quantity(3, "animals per part", "3 animals per part")]),
        ask("How many cats are at the kennel?"),
        steps([step("multiplication", [4, 3], 12)]),
        answer(12, "cats"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U2-L15'), grade('6'), record_id('im_defrag_fdeb98edb51bc8b65058740e_1'), statement_sha('bbfb0ea5bb2faca708feb9ad65e73fdd7d0c0806bcd759f47c3e64d4546528f0')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_fe6394db441ac61a38cec29a_1', "What could each division expression mean in the situation with the bags of clay? Draw a diagram and write a multiplication equation... 12 ÷ 4",
    analysis(
        quantities([quantity(12, "clay", "12"), quantity(4, "bags", "4")]),
        ask("What could the division expression 12 ÷ 4 mean in a situation involving bags of clay, and how can it be represented by a diagram and a multiplication equation?"),
        steps([step("divide", [12, 4], 3)]),
        answer(3, "clay_per_bag_or_bags"),
        missing_doing("interpret_context_draw_diagram_and_write_equation")),
    anchor(lesson('IM-G6-U4-L2'), grade('6'), record_id('im_defrag_fe6394db441ac61a38cec29a_1'), statement_sha('2df6bcf756efb596bc91567493264cb17f4b3c3a92e36cac1cfc371951276208')),
    testimony(model('gemma-4-31B-it'), backend('reallms'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_fe7aa11db773a2edfc10f829_1', "9 is 10% of what number?",
    analysis(
        quantities([quantity(9, "number", "9"), quantity(10, "percent", "10%")]),
        ask("What number is 9 equal to 10% of?"),
        steps([step("divide", [9, 0.1], 90)]),
        answer(90, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U3-L13'), grade('6'), record_id('im_defrag_fe7aa11db773a2edfc10f829_1'), statement_sha('89b7822c05d362052875c6fca04bdb852fe53d62d63895937755549e0450a87e')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_fec65b9f2a6c026b04918a1a_1', "Find the value of each expression mentally. 14 ÷ 100",
    analysis(
        quantities([quantity(14, "number", "14"), quantity(100, "number", "100")]),
        ask("What is the value of the expression 14 divided by 100?"),
        steps([step("division", [14, 100], 0.14)]),
        answer(0.14, "number"),
        missing_doing(null)),
    anchor(lesson('IM-G7-U4-L9'), grade('7'), record_id('im_defrag_fec65b9f2a6c026b04918a1a_1'), statement_sha('96ae1c55b1c60f7bb5a2589ca8744e8911df49016c6e9599f9fa4387ab0e1c72')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_ff1d550617d17ab1254523d5_1', "A large bucket of 200 golf balls is divided into 4 smaller buckets. How many golf balls are in each small bucket?",
    analysis(
        quantities([quantity(200, "golf balls", "200 golf balls"), quantity(4, "smaller buckets", "4 smaller buckets")]),
        ask("How many golf balls are in each small bucket?"),
        steps([step("division", [200, 4], 50)]),
        answer(50, "golf balls"),
        missing_doing(null)),
    anchor(lesson('IM-G6-U4-L2'), grade('6'), record_id('im_defrag_ff1d550617d17ab1254523d5_1'), statement_sha('9a525ddcd3f8e672fae5f66f518b37552319dacf8d4515ce79ee347192cdcf42')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(oracle_matched)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_ff5cb3b54429179cbb379277_1', "Show your thinking using drawings, numbers, or words. 1. 12 pencils are on the table. The teacher picks up 7. How many pencils are still on the table? 2. Clare gets 8 glue sticks from the red table. She gets some more from the blue table. Now she has 15 glue sticks. How many did she get from the blue table? 3. Kiran has 17 crayons. He gives some to his friends. Now he has 9 crayons. How many did he give to his friends?",
    analysis(
        quantities([quantity(17, "crayons", "17 crayons"), quantity(9, "crayons", "9 crayons")]),
        ask("How many crayons did Kiran give to his friends?"),
        steps([step("subtraction", [17, 9], 8)]),
        answer(8, "crayons"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U3-L25'), grade('1'), record_id('im_defrag_ff5cb3b54429179cbb379277_1'), statement_sha('a427809dc5f2aba70e878e8286c7ed2e541867aeec0451869fac23332ec6fc62')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_ff7008ce305e86afd08a39b7_1', "6 × 40 = 24 × 10",
    analysis(
        quantities([quantity(6, "number", "6"), quantity(40, "number", "40"), quantity(24, "number", "24"), quantity(10, "number", "10")]),
        ask("Determine if 6 times 40 is equal to 24 times 10."),
        steps([step("multiplication", [6, 40], 240), step("multiplication", [24, 10], 240), step("compare_equal", [240, 240], true)]),
        answer(true, "claim_verdict"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U7-L2'), grade('3'), record_id('im_defrag_ff7008ce305e86afd08a39b7_1'), statement_sha('99ed8694a60e7e7e8b06bbf5e3545be92ccdf38a37caf3039f946f10963f0151')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_ff80fea865cbf37090cdee53_1', "Solve each problem. Show your thinking using drawings, numbers, or words. 1. There are 7 first graders and some second graders at the planetarium. There are 18 students at the planetarium. How many second graders are at the planetarium? 2. There are 18 stars in the sky. 13 stars are bright. Some of the stars are dim. How many stars are dim? 3. Diego and Tyler see 15 shooting stars during the show. Diego sees 6 shooting stars. Tyler sees the rest. How many shooting stars does Tyler see? 4. Elena buys 12 star stickers. She also buys some planet stickers. Elena buys 20 stickers. How many planet stickers does she buy?",
    analysis(
        quantities([quantity(12, "star stickers", "12 star stickers"), quantity(20, "stickers", "20 stickers")]),
        ask("How many planet stickers does Elena buy?"),
        steps([step("subtraction", [20, 12], 8)]),
        answer(8, "planet stickers"),
        missing_doing(null)),
    anchor(lesson('IM-G1-U8-L5'), grade('1'), record_id('im_defrag_ff80fea865cbf37090cdee53_1'), statement_sha('c6e9e4e045b5c59a04ba9024268c43a7c8080e188e2f92ad27843091c378def3')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_ffc40a4e55fc3ce4e54cbb36_1', "A school’s track teams raised $41,560 from fundraisers and concession sales. In the fall, the teams paid $3,180 for uniforms, $1,425 in entry fees for track meets, and $18,790 in travel costs. In the spring, the teams paid $10,475 in equipment replacement, $1,160 for competition expenses, and $912 for awards and trophies. 1. Is the amount collected enough to cover all the payments? Explain how you know. 2. If the amount collected is enough, how much money do the track teams have left after paying all the expenses? If it is not enough, how much money did the track teams overspend? Explain how you know.",
    analysis(
        quantities([quantity(41560, "dollars", "$41,560"), quantity(3180, "dollars", "$3,180"), quantity(1425, "dollars", "$1,425"), quantity(18790, "dollars", "$18,790"), quantity(10475, "dollars", "$10,475"), quantity(1160, "dollars", "$1,160"), quantity(912, "dollars", "$912")]),
        ask("Determine if the total amount collected is enough to cover all expenses, and calculate the remaining amount or the overspent amount."),
        steps([step("addition", [3180, 1425, 18790, 10475, 1160, 912], 35942), step("subtraction", [41560, 35942], 5618)]),
        answer(5618, "dollars"),
        missing_doing("comparison and logical reasoning")),
    anchor(lesson('IM-G4-U4-L22'), grade('4'), record_id('im_defrag_ffc40a4e55fc3ce4e54cbb36_1'), statement_sha('71d1c5481bbc237ae20b9e3b0f6c726a756ee2f9b0f801f020ca2c510a65941d')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).

model_analysis_row('im_defrag_ffed8fd4fbf039b5328bcce5_1', "The winning pig weighed 48 kilograms when his owner decided to show him at the fair. At the fair weigh-off, the pig weighed 124 kilograms. How much weight did the pig gain? Explain or show your reasoning.",
    analysis(
        quantities([quantity(48, "kilograms", "48 kilograms"), quantity(124, "kilograms", "124 kilograms")]),
        ask("How much weight did the pig gain?"),
        steps([step("subtraction", [124, 48], 76)]),
        answer(76, "kilograms"),
        missing_doing(null)),
    anchor(lesson('IM-G3-U6-L13'), grade('3'), record_id('im_defrag_ffed8fd4fbf039b5328bcce5_1'), statement_sha('5d680e6a91a6477e117069cda745693aa1dff2715fe58249dfa5a8e026c1debe')),
    testimony(model('local'), backend('openai'), job(source_file('hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl')), date('2026-08-18'), tier(unoracled_executable)),
    receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))).
