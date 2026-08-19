:- encoding(utf8).
/** <module> Attributed store for rewrite-consultation admitted sentences
 *
 * scripts/language/rewrite_consultation.py asks a model to restate a
 * sentence the deterministic reader refused, then gates the restatement on
 * three checks: every numeral preserved, every name preserved, and the
 * reader parsing the restatement into a non-empty fact set. A restatement
 * that clears all three is testimony, never ground truth, so it is kept
 * apart from any hand-authored store, attributed to its model and job, and
 * anchored back to the refused sentence it restates and the lesson that
 * sentence came from.
 *
 * Rows come from two model-restatement jobs, both model gemma-4-26B-A4B-it
 * on Big Red, and every row is attributed to whichever of the two actually
 * produced it:
 *
 *   - Job 7971523 (2026-08-15), source structure_task_rows: 1,885 refused
 *     sentences drawn from lessons the defrag builder never admitted. 16
 *     restatements cleared every gate, copied from
 *     .bigred-collected/2026-08-15-rewrite-consult/rewrite_consultation_unadmitted.jsonl
 *     (the collected file keeps its job-time name; every row in it that
 *     carries gate=="admitted" is a row here and no others are).
 *
 *   - An earlier ledger-mode run (source: the pusu_results.jsonl refusal
 *     ledger, rewrite_consultation.py's --source default), collected to
 *     hermes/app/runtime/experiments/language/rewrite_consultation_bigred.jsonl
 *     with mtime 2026-08-14 and read by commit 3a3311cc the same evening
 *     ("the consultation loop... admits its first rows"). 10 restatements
 *     cleared every gate. This run's Big Red job id is not recoverable: no
 *     .out/.err log for it was collected (unlike job 7971523's), and no
 *     memory note or handoff records the number 3a3311cc's session used.
 *     These 10 rows are attributed by source file and collection date
 *     instead, and their testimony says so in the term itself
 *     (`job(unrecovered(file(...)))`) rather than implying a job id that
 *     was never verified.
 *
 * check_rewrite_consultation_admitted/0 re-derives every row's facts by
 * calling TODAY's narrow reader on the stored restatement and requires an
 * exact match against the facts the job recorded, and re-hashes the stored
 * original sentence and requires an exact match against the stored anchor
 * sha. Reader drift or a transcription error fails loudly here, not later —
 * this matters most for the 2026-08-14 rows, collected before the
 * 2026-08-15 anchor-decoder and G1-currency-grammar changes; all 10
 * reproduced their stored facts unchanged when re-checked against today's
 * reader, so none carried a silent drift.
 *
 * Check from the repository root:
 * `swipl -q -l paths.pl -l knowledge/strategies/abstraction/rewrite_consultation_admitted_pilot.pl -g rewrite_consultation_admitted_pilot:check_rewrite_consultation_admitted -t halt`
 */

:- module(rewrite_consultation_admitted_pilot,
          [ rewrite_admitted_sentence/7,
            rewrite_consultation_admitted_summary/1,
            check_rewrite_consultation_admitted/0
          ]).

:- use_module(library(sha)).
:- use_module('word_problem_reader_pilot.pl').

:- dynamic rewrite_admitted_sentence/7.

rewrite_consultation_admitted_summary(
    summary(role(orphan_consultation_sentences), row_count(Count),
            model(gemma_4_26b_a4b_it),
            by_provenance([job('7971523')-Job7971523Count,
                           file('rewrite_consultation_bigred.jsonl')-FileCount]))) :-
    aggregate_all(count, rewrite_admitted_sentence(_, _, _, _, _, _, _), Count),
    aggregate_all(count,
                  rewrite_admitted_sentence(_, _, _, _, _,
                                            testimony(_, job('7971523'), _), _),
                  Job7971523Count),
    aggregate_all(count,
                  rewrite_admitted_sentence(_, _, _, _, _,
                                            testimony(_, job(unrecovered(_)), _), _),
                  FileCount).

%! check_rewrite_consultation_admitted is det.
%
%  Anchors must be unique (no two rows claim the same refused sentence
%  slot), every stored sha must reproduce from the stored original text,
%  and every stored fact list must reproduce from the stored restatement
%  through the same reader the job used to admit it.
check_rewrite_consultation_admitted :-
    findall(Id, rewrite_admitted_sentence(Id, _, _, _, _, _, _), Ids),
    sort(Ids, Unique),
    length(Ids, Count),
    length(Unique, Count),
    forall(rewrite_admitted_sentence(Id, Text, Restatement, Facts, Anchor,
                                     Testimony, Receipt),
           check_stored_row(Id, Text, Restatement, Facts, Anchor, Testimony,
                            Receipt)),
    format('rewrite_consultation_admitted_pilot: all ~d row receipts passed~n',
           [Count]).

check_stored_row(Id, Text, Restatement, Facts, Anchor, Testimony, Receipt) :-
    Anchor = anchor(lesson(Lesson), grade(Grade), sentence_form(Form),
                    source(Source), sentence_sha(Sha), prompt_sha(PromptSha)),
    atom(Lesson), atom(Grade), atom(Form), atom(Source), atom(Sha),
    atom(PromptSha),
    ( valid_testimony(Testimony)
    -> true
    ;  throw(error(rewrite_consultation_admitted_pilot(bad_testimony(Id, Testimony)), _))
    ),
    Receipt == receipt(swipl_test([reader_reproduces_facts,
                                   sentence_sha_verified])),
    Facts \== [],
    sha256_hex(Text, ComputedSha),
    ( ComputedSha == Sha
    -> true
    ;  throw(error(rewrite_consultation_admitted_pilot(sha_mismatch(Id, ComputedSha, Sha)), _))
    ),
    catch(word_problem_reader_pilot:word_problem_facts(Restatement, Reparsed),
          Error,
          throw(error(rewrite_consultation_admitted_pilot(reparse_failed(Id, Error)), _))),
    ( Reparsed == Facts
    -> true
    ;  throw(error(rewrite_consultation_admitted_pilot(fact_mismatch(Id, Reparsed, Facts)), _))
    ).

%! valid_testimony(+Testimony) is semidet.
%
%  Two attributions are honest, and no others. A row either carries the Big
%  Red job id that produced it, or — when that id was never recorded and is
%  not recoverable from any collected log — the source file and collection
%  date stand in its place, and the term says `unrecovered` rather than
%  guessing a job id that was never verified.
valid_testimony(testimony(model(gemma_4_26b_a4b_it), job('7971523'),
                          date('2026-08-15'))).
valid_testimony(testimony(model(gemma_4_26b_a4b_it),
                          job(unrecovered(file('rewrite_consultation_bigred.jsonl'))),
                          date('2026-08-14'))).

%! sha256_hex(+Text, -HexAtom) is det.
%
%  The same digest scripts/language/rewrite_consultation.py takes over the
%  UTF-8 bytes of the sentence text, so a stored sha anchors a row to the
%  exact bytes the job read rather than to a re-typed approximation.
sha256_hex(Text, Atom) :-
    text_to_string(Text, String),
    sha_hash(String, Hash, [algorithm(sha256), encoding(utf8)]),
    hash_atom(Hash, Atom).

% GENERATED ROWS FOLLOW. Installed 2026-08-18 from the 16 gate=="admitted"
% rows of .bigred-collected/2026-08-15-rewrite-consult/
% rewrite_consultation_unadmitted.jsonl (Big Red job 7971523, 2026-08-15),
% after each row's swipl re-parse reproduced the job's recorded facts
% exactly. No row was rejected.

rewrite_admitted_sentence('IM-G4-U4-L7#8', "Here are 4 numbers.", "There are 4 numbers.", [quantity(there_number_initial,4,number),discrete_kinds([number])],
    anchor(lesson('IM-G4-U4-L7'), grade('4'), sentence_form('mixed'),
           source('structure_task_rows'), sentence_sha('63c729914018e7302d51e242b15ce9ec84a87350436c9b7e99d50441acc0e153'),
           prompt_sha('ec6e1ce39deb8993f7f557300477505e2ead8275aa7545a66295c78103b6dc73')),
    testimony(model(gemma_4_26b_a4b_it), job('7971523'), date('2026-08-15')),
    receipt(swipl_test([reader_reproduces_facts, sentence_sha_verified]))).

rewrite_admitted_sentence('IM-G4-U5-L15#5', "Is Elena’s tower more than 6 feet?", "Elena has 6 feet.", [quantity(elena_feet_initial,6,feet),discrete_kinds([feet])],
    anchor(lesson('IM-G4-U5-L15'), grade('4'), sentence_form('mixed'),
           source('structure_task_rows'), sentence_sha('3b73ae38d4f501f8e5656e2c1b7b0795c14aa31f551ae28ea2c75ee6905680d3'),
           prompt_sha('db5e0a16b1522e4ab56c690b668b70fe477cc57c6b4a0df98bc4ab383c4f6164')),
    testimony(model(gemma_4_26b_a4b_it), job('7971523'), date('2026-08-15')),
    receipt(swipl_test([reader_reproduces_facts, sentence_sha_verified]))).

rewrite_admitted_sentence('IM-GK-U7-L6#8', "Are there any ways to make 10 that are missing from our list?", "How many ways to make 10 are missing from our list?", [quantity(lane_question_result,unknown,way),asks(result,lane_question_result),discrete_kinds([way])],
    anchor(lesson('IM-GK-U7-L6'), grade('K'), sentence_form('discussion_prompt'),
           source('structure_task_rows'), sentence_sha('b74b64e12704be07b01b2878e94fb795c0373a23b0cb58e61d52e5451c562080'),
           prompt_sha('e86b9951929c83e05f568f4016b84562a8e29da4ffccf7db1ae4da70bd1a1d93')),
    testimony(model(gemma_4_26b_a4b_it), job('7971523'), date('2026-08-15')),
    receipt(swipl_test([reader_reproduces_facts, sentence_sha_verified]))).

rewrite_admitted_sentence('IM-G2-U5-L1#7', "What is the value of his blocks now?", "How many blocks does he have now?", [quantity(he_block_demanded,unknown,block),asks(result,he_block_demanded),discrete_kinds([block])],
    anchor(lesson('IM-G2-U5-L1'), grade('2'), sentence_form('mixed'),
           source('structure_task_rows'), sentence_sha('3f542f20884686d7863106c4479de9cbe70cf64f74e6f2e58eae1b9e0c93baac'),
           prompt_sha('d92d6031ed6e51a270e462e8d115254763bd78ead7e11398aefc08769e072446')),
    testimony(model(gemma_4_26b_a4b_it), job('7971523'), date('2026-08-15')),
    receipt(swipl_test([reader_reproduces_facts, sentence_sha_verified]))).

rewrite_admitted_sentence('IM-GK-U6-L12#7', "Write a number to show how many shapes there are.", "How many shapes are there?", [quantity(generic_shape_demanded,unknown,shape),asks(result,generic_shape_demanded),discrete_kinds([shape])],
    anchor(lesson('IM-GK-U6-L12'), grade('K'), sentence_form('mixed'),
           source('structure_task_rows'), sentence_sha('eba2465f3ba3dba8bb0c0e197c37f4225e4bcf6910520b25b33e259274fa3ebf'),
           prompt_sha('ca865baf5d28af92d0119b4d0375a1bce84d9594b29ce073209e40dea2df2f71')),
    testimony(model(gemma_4_26b_a4b_it), job('7971523'), date('2026-08-15')),
    receipt(swipl_test([reader_reproduces_facts, sentence_sha_verified]))).

rewrite_admitted_sentence('IM-GK-U2-L18#5', "Write a number on the sticky note to show how many objects are in each bag.", "How many objects are in each bag?", [quantity(lane_question_result,unknown,object),asks(result,lane_question_result),discrete_kinds([object])],
    anchor(lesson('IM-GK-U2-L18'), grade('K'), sentence_form('discussion_prompt'),
           source('structure_task_rows'), sentence_sha('942da257e12b477577cf06bc72436295f23fd705be1fd3df979e813516883553'),
           prompt_sha('4bd9c7bb1dcb699396f69fed6d735c50ce994cd83dca5ca5d150c70166f435f0')),
    testimony(model(gemma_4_26b_a4b_it), job('7971523'), date('2026-08-15')),
    receipt(swipl_test([reader_reproduces_facts, sentence_sha_verified]))).

rewrite_admitted_sentence('IM-GK-U7-L11#4', "Write a number to show how many shapes are in each group.", "How many shapes are in each group?", [quantity(lane_question_result,unknown,shape),asks(result,lane_question_result),discrete_kinds([shape])],
    anchor(lesson('IM-GK-U7-L11'), grade('K'), sentence_form('mixed'),
           source('structure_task_rows'), sentence_sha('e3862ea90a96b7f201c3d2a64d4f908d48e69279c10d9fdf5eaaf249f24159f8'),
           prompt_sha('63a7e0bed1198f111e420f472610a1e25bd3ab94e936d6860e46b214e4509928')),
    testimony(model(gemma_4_26b_a4b_it), job('7971523'), date('2026-08-15')),
    receipt(swipl_test([reader_reproduces_facts, sentence_sha_verified]))).

rewrite_admitted_sentence('IM-GK-U3-L5#8', "Write a number to show how many triangles you colored.", "How many triangles did you color?", [quantity(lane_question_result,unknown,triangle),asks(result,lane_question_result),discrete_kinds([triangle])],
    anchor(lesson('IM-GK-U3-L5'), grade('K'), sentence_form('construction_or_drawing'),
           source('structure_task_rows'), sentence_sha('19f9e0e01e223d09e79d4f1024e146fc94ad3df5bbb760758f2767de1a87993b'),
           prompt_sha('59fe6d1c13073e1768c20e7016850ce8efe199da9e68ac139538752e693754a7')),
    testimony(model(gemma_4_26b_a4b_it), job('7971523'), date('2026-08-15')),
    receipt(swipl_test([reader_reproduces_facts, sentence_sha_verified]))).

rewrite_admitted_sentence('IM-GK-U8-L14#11', "What other expressions also make 5?", "How many expressions also make 5?", [quantity(lane_question_result,unknown,expression),asks(result,lane_question_result),discrete_kinds([expression])],
    anchor(lesson('IM-GK-U8-L14'), grade('K'), sentence_form('discussion_prompt'),
           source('structure_task_rows'), sentence_sha('a24349b87fd20f872e03db0769c76a80280cbbf9cda68d1878da0b802de8e56e'),
           prompt_sha('6136f7f7196529aead15156c51240c90bc571543dfd24caa2bc267f008e8ab86')),
    testimony(model(gemma_4_26b_a4b_it), job('7971523'), date('2026-08-15')),
    receipt(swipl_test([reader_reproduces_facts, sentence_sha_verified]))).

rewrite_admitted_sentence('IM-G3-U4-L13#4', "There were 6 buckets of sunflowers at the farmers market.", "There are 6 buckets of sunflowers.", [quantity(there_bucket_initial,6,bucket),discrete_kinds([bucket])],
    anchor(lesson('IM-G3-U4-L13'), grade('3'), sentence_form('word_problem'),
           source('structure_task_rows'), sentence_sha('3527486f208aca271961bdc757c4e334f19c3a6bc11f612c61f6631de3bf1c73'),
           prompt_sha('4926adcd6e8caa17ad743c3b9bdca7827e5eb61e9deef5d470d072590d1122d4')),
    testimony(model(gemma_4_26b_a4b_it), job('7971523'), date('2026-08-15')),
    receipt(swipl_test([reader_reproduces_facts, sentence_sha_verified]))).

rewrite_admitted_sentence('IM-GK-U6-L4#24', "“There are 20 objects in a line.", "There are 20 objects in a line.", [quantity(there_object_initial,20,object),discrete_kinds([object])],
    anchor(lesson('IM-GK-U6-L4'), grade('K'), sentence_form('discussion_prompt'),
           source('structure_task_rows'), sentence_sha('5a426783433a161ea0180cb682d50cc29b35a4c4e21e4af6d3f3c7e66c9848bd'),
           prompt_sha('c072cc85103cba1c45f23ebf4be29a57afb715e46d158deee245f3d239ae2559')),
    testimony(model(gemma_4_26b_a4b_it), job('7971523'), date('2026-08-15')),
    receipt(swipl_test([reader_reproduces_facts, sentence_sha_verified]))).

rewrite_admitted_sentence('IM-G3-U2-L1#1', "Here are 2 triangles.", "There are 2 triangles.", [quantity(there_triangle_initial,2,triangle),discrete_kinds([triangle])],
    anchor(lesson('IM-G3-U2-L1'), grade('3'), sentence_form('mixed'),
           source('structure_task_rows'), sentence_sha('a2c20aba14c30eaa4ea410fc93813071953b1846ab01561915d9d92885e9fb21'),
           prompt_sha('c01cf3ba2f3758b74045a166513f474c04b4a9486938fa6c61885032e76b4d82')),
    testimony(model(gemma_4_26b_a4b_it), job('7971523'), date('2026-08-15')),
    receipt(swipl_test([reader_reproduces_facts, sentence_sha_verified]))).

rewrite_admitted_sentence('IM-G3-U1-L11#3', "There were 6 envelopes.", "There are 6 envelopes.", [quantity(there_envelope_initial,6,envelope),discrete_kinds([envelope])],
    anchor(lesson('IM-G3-U1-L11'), grade('3'), sentence_form('word_problem'),
           source('structure_task_rows'), sentence_sha('c620b4267167dbb14eb94777ad4efafa6255b124efea6311dacea1437e3743a9'),
           prompt_sha('0aabea8896225442331aaf9adf72fd47f67825bff07db54a340a95b3be6e5ace')),
    testimony(model(gemma_4_26b_a4b_it), job('7971523'), date('2026-08-15')),
    receipt(swipl_test([reader_reproduces_facts, sentence_sha_verified]))).

rewrite_admitted_sentence('IM-GK-U6-L5#3', "figure out how many dots there are.", "How many dots are there?", [quantity(generic_dot_demanded,unknown,dot),asks(result,generic_dot_demanded),discrete_kinds([dot])],
    anchor(lesson('IM-GK-U6-L5'), grade('K'), sentence_form('mixed'),
           source('structure_task_rows'), sentence_sha('53d5309ce3eaf219b79581163e924483691e8090d7c9656bcdf60081fc3c2ec7'),
           prompt_sha('85decf4922555cf89e529741d1a124512c461d2d54764185b4ac40be5c7a1dde')),
    testimony(model(gemma_4_26b_a4b_it), job('7971523'), date('2026-08-15')),
    receipt(swipl_test([reader_reproduces_facts, sentence_sha_verified]))).

rewrite_admitted_sentence('IM-G4-U2-L12#2', "Here are 25 fractions in a table.", "There are 25 fractions in a table.", [quantity(there_fraction_initial,25,fraction),discrete_kinds([fraction])],
    anchor(lesson('IM-G4-U2-L12'), grade('4'), sentence_form('mixed'),
           source('structure_task_rows'), sentence_sha('d9cdc7dca76213e6ea38c93fc84eaf9d40bd87c554b7c8c125dfadb780bf6826'),
           prompt_sha('922e2828b34a04f683b0788613445c5e723e791bea90b3ebe94f74902694ebff')),
    testimony(model(gemma_4_26b_a4b_it), job('7971523'), date('2026-08-15')),
    receipt(swipl_test([reader_reproduces_facts, sentence_sha_verified]))).

rewrite_admitted_sentence('IM-GK-U8-L20#3', "Elena says about 11 snowflakes.", "Elena has 11 snowflakes.", [quantity(elena_snowflake_initial,11,snowflake),discrete_kinds([snowflake])],
    anchor(lesson('IM-GK-U8-L20'), grade('K'), sentence_form('mixed'),
           source('structure_task_rows'), sentence_sha('da9212e3bfa8a68ca72fa24ae3f8a22901522c5a7baf79cb3f9b4efcc9ec5239'),
           prompt_sha('ea11af50887a5ba2bc51b21af6bf41187500ecd50619cf01eafe867ad098816b')),
    testimony(model(gemma_4_26b_a4b_it), job('7971523'), date('2026-08-15')),
    receipt(swipl_test([reader_reproduces_facts, sentence_sha_verified]))).

% SECOND GENERATED BATCH FOLLOWS. Installed 2026-08-18 from the 10
% gate=="admitted" rows of
% hermes/app/runtime/experiments/language/rewrite_consultation_bigred.jsonl
% (mtime 2026-08-14; read by commit 3a3311cc the same evening as "the
% consultation loop... admits its first rows"). This run's Big Red job id
% is not recoverable — no .out/.err log for it was collected, unlike job
% 7971523's, and no memory note or handoff records it — so these 10 rows
% are attributed by source file and collection date; see valid_testimony/1.
% Every row's restatement still carries the shape-label prefix the model
% volunteered ("change (add)      He gets 3 more."), because
% scripts/language/rewrite_consultation.py's SHAPE_LABEL-stripping fix
% postdates this run; the stored restatement is the exact string the
% reader was gated against, prefix included, and re-parsing it unchanged
% through today's reader reproduces the job's recorded facts exactly for
% all 10 rows. No row was rejected.

rewrite_admitted_sentence('im_defrag_402ec3f9f0e69e1126186afd_1', "He gets 3 more.", "change (add)      He gets 3 more.", [quantity(lane_add_more_get,3,more),discrete_kinds([more])],
    anchor(lesson('IM-G1-U3-L11'), grade('1'), sentence_form('declarative'),
           source('pusu_results_ledger'), sentence_sha('890ed7e7dc0ed7ffb7921b744391b0ccc5887fd13a9be8a3905f160fa4515c17'),
           prompt_sha('f051dfcbafbd8756847f35a6e97376885cd43ae322b58eef1cf4385d277855e9')),
    testimony(model(gemma_4_26b_a4b_it),
              job(unrecovered(file('rewrite_consultation_bigred.jsonl'))),
              date('2026-08-14')),
    receipt(swipl_test([reader_reproduces_facts, sentence_sha_verified]))).

rewrite_admitted_sentence('im_defrag_45bfd8056d15877b2b5b1557_1', "She gives 7 crayons to Diego.", "change (remove) She gives 7 crayons to Diego.", [quantity(lane_change_crayon_remove,7,crayon),discrete_kinds([crayon])],
    anchor(lesson('IM-G1-U3-L22'), grade('1'), sentence_form('declarative'),
           source('pusu_results_ledger'), sentence_sha('86a66f670cdc41a3556043861209b2e82a4b36638a43b2d638119b5d4341226f'),
           prompt_sha('b1dcb8a065906d62ae089b105e2ae1dd3503dbfd026a6410c1caa709730157b2')),
    testimony(model(gemma_4_26b_a4b_it),
              job(unrecovered(file('rewrite_consultation_bigred.jsonl'))),
              date('2026-08-14')),
    receipt(swipl_test([reader_reproduces_facts, sentence_sha_verified]))).

rewrite_admitted_sentence('im_defrag_e09043be9da9e9e18c44f2bd_1', "Elena used 23 cubes to make a train.", "change (remove)       Elena used 23 cubes.", [quantity(lane_change_cube_remove,23,cube),discrete_kinds([cube])],
    anchor(lesson('IM-G2-U2-L1'), grade('2'), sentence_form('declarative'),
           source('pusu_results_ledger'), sentence_sha('310d2798eec00c800fc0c520b4891a6318a06cb05b193915e38aef29a30200fe'),
           prompt_sha('91abbcb22dfa13f1dcb4bdd4134d9f7bc1e6963afd060d900943ed37e3153ad5')),
    testimony(model(gemma_4_26b_a4b_it),
              job(unrecovered(file('rewrite_consultation_bigred.jsonl'))),
              date('2026-08-14')),
    receipt(swipl_test([reader_reproduces_facts, sentence_sha_verified]))).

rewrite_admitted_sentence('im_defrag_35a1b0bc3f0a7538043617a8_1', "41 students left the zoo on the first bus.", "change (remove) 41 students left the zoo on the first bus.", [quantity(lane_change_student_remove,41,student),discrete_kinds([student])],
    anchor(lesson('IM-G2-U2-L3'), grade('2'), sentence_form('declarative'),
           source('pusu_results_ledger'), sentence_sha('64bf4ef3f71486928bdafcd75f074b7d3cc9582ec4a71ea9bc8c0dfbe69f5b6f'),
           prompt_sha('625b7e23217a300354631d633a14298bd89210e334d5f3bf980c5d6e2087284e')),
    testimony(model(gemma_4_26b_a4b_it),
              job(unrecovered(file('rewrite_consultation_bigred.jsonl'))),
              date('2026-08-14')),
    receipt(swipl_test([reader_reproduces_facts, sentence_sha_verified]))).

rewrite_admitted_sentence('im_defrag_047e9a1cc4e0cb2ea4b65c07_1', "Each row has 5 crayons.", "equal groups        Each row has 5 crayons.", [quantity(lane_rate_context_crayon_rate_total,5,crayon),quantity(lane_rate_context_row_rate_interval,1,row),quantity(lane_rate_context_crayon_per_row,unknown,rate(crayon,row)),relation(lane_rate_context_crayon_rate_total,scale(lane_rate_context_row_rate_interval,lane_rate_context_crayon_per_row),"equal groups each row has 5 crayons ."),discrete_kinds([crayon,row])],
    anchor(lesson('IM-G3-U1-L19'), grade('3'), sentence_form('declarative'),
           source('pusu_results_ledger'), sentence_sha('736382008be96aa3d4458a7d365c09fcda276f89fc33a745ad8705cd3b8829d2'),
           prompt_sha('d3da2edf21771e55690b56177388d6ac193aa0f199c803d9e1ec341255575379')),
    testimony(model(gemma_4_26b_a4b_it),
              job(unrecovered(file('rewrite_consultation_bigred.jsonl'))),
              date('2026-08-14')),
    receipt(swipl_test([reader_reproduces_facts, sentence_sha_verified]))).

rewrite_admitted_sentence('im_defrag_ba7972acf3e52ac315674505_1', "(120 meters in 4 seconds, find speed)", "rate 120 meters every 4 seconds.", [quantity(lane_rate_context_meter_rate_total,120,meter),quantity(lane_rate_context_second_rate_interval,4,second),quantity(lane_rate_context_meter_per_second,unknown,rate(meter,second)),relation(lane_rate_context_meter_rate_total,scale(lane_rate_context_second_rate_interval,lane_rate_context_meter_per_second),"rate 120 meters every 4 seconds ."),discrete_kinds([])],
    anchor(lesson('IM-G6-U3-L6'), grade('6'), sentence_form('declarative'),
           source('pusu_results_ledger'), sentence_sha('be888834b45abc88e212053f696dc00b83c4f89e58a81b5287783bad282f30a6'),
           prompt_sha('d1d5cf6715a8aa88048a2baff9f97dfd9c2b1219ce00c37680480c1783d129ee')),
    testimony(model(gemma_4_26b_a4b_it),
              job(unrecovered(file('rewrite_consultation_bigred.jsonl'))),
              date('2026-08-14')),
    receipt(swipl_test([reader_reproduces_facts, sentence_sha_verified]))).

rewrite_admitted_sentence('im_defrag_63ca74e8d5aaa6338539e328_1', "A box can hold 3 cups of rice.", "equal groups        Each box has 3 cups of rice in it.", [quantity(lane_rate_context_cup_rate_total,3,cup),quantity(lane_rate_context_box_rate_interval,1,box),quantity(lane_rate_context_cup_per_box,unknown,rate(cup,box)),relation(lane_rate_context_cup_rate_total,scale(lane_rate_context_box_rate_interval,lane_rate_context_cup_per_box),"equal groups each box has 3 cups of rice in it ."),discrete_kinds([box])],
    anchor(lesson('IM-G6-U4-L7'), grade('6'), sentence_form('declarative'),
           source('pusu_results_ledger'), sentence_sha('f6bb846ce07271804ef891ac90532c85aa9643ddb687fe25004d25339a098c74'),
           prompt_sha('ef75f76f10e596d788a3e33ff78ca25961b75da9b412860cb456893cbc80cf3a')),
    testimony(model(gemma_4_26b_a4b_it),
              job(unrecovered(file('rewrite_consultation_bigred.jsonl'))),
              date('2026-08-14')),
    receipt(swipl_test([reader_reproduces_facts, sentence_sha_verified]))).

rewrite_admitted_sentence('im_defrag_b5696ebd347cb4d330a15a3e_1', "Noah counts 8 heartbeats in 10 seconds.", "rate Noah counts 8 heartbeats every 10 seconds.", [quantity(lane_rate_context_heartbeat_rate_total,8,heartbeat),quantity(lane_rate_context_second_rate_interval,10,second),quantity(lane_rate_context_heartbeat_per_second,unknown,rate(heartbeat,second)),relation(lane_rate_context_heartbeat_rate_total,scale(lane_rate_context_second_rate_interval,lane_rate_context_heartbeat_per_second),"rate noah counts 8 heartbeats every 10 seconds ."),discrete_kinds([heartbeat])],
    anchor(lesson('IM-G7-U4-L5'), grade('7'), sentence_form('declarative'),
           source('pusu_results_ledger'), sentence_sha('6d83b61fa6b5a8e086855a18e7ae19b10e69bd027554457a26dcc1aa8a01f009'),
           prompt_sha('d6510747fb73387bc088670c12f44379f79cea65faa1a54a293081ae378ab8af')),
    testimony(model(gemma_4_26b_a4b_it),
              job(unrecovered(file('rewrite_consultation_bigred.jsonl'))),
              date('2026-08-14')),
    receipt(swipl_test([reader_reproduces_facts, sentence_sha_verified]))).

rewrite_admitted_sentence('im_defrag_3a1c749e04cfebb41e608e8b_1', "Show on the graph how much honey is needed for 70 grams of salt.", "rate              How much honey is needed for 70 grams of salt?", [quantity(lane_question_result,unknown,honey),asks(result,lane_question_result),discrete_kinds([honey])],
    anchor(lesson('IM-G8-U3-L3'), grade('8'), sentence_form('directive'),
           source('pusu_results_ledger'), sentence_sha('02279aceb244ed941186c8a649e39d030d34c1c87c406d5bd5ff9cd28edaa514'),
           prompt_sha('12512d0ef43abc321fe32c5a9f24a91ad0a685aa7733e7831fd3511a099a8e6e')),
    testimony(model(gemma_4_26b_a4b_it),
              job(unrecovered(file('rewrite_consultation_bigred.jsonl'))),
              date('2026-08-14')),
    receipt(swipl_test([reader_reproduces_facts, sentence_sha_verified]))).

rewrite_admitted_sentence('im_defrag_01e7ba82ca022702d470596f_1', "| | | | | At 100 minutes, I have 60 signs completed.", "rate              60 signs every 100 minutes.", [quantity(lane_rate_context_sign_rate_total,60,sign),quantity(lane_rate_context_minute_rate_interval,100,minute),quantity(lane_rate_context_sign_per_minute,unknown,rate(sign,minute)),relation(lane_rate_context_sign_rate_total,scale(lane_rate_context_minute_rate_interval,lane_rate_context_sign_per_minute),"rate 60 signs every 100 minutes ."),discrete_kinds([sign])],
    anchor(lesson('IM-G8-U4-L10'), grade('8'), sentence_form('declarative'),
           source('pusu_results_ledger'), sentence_sha('2a5397cbc4e95b1cfe9686b5ad6cc7265f9608fbb4cfc09d2ea0f9ab284be4a4'),
           prompt_sha('f7b7d27b5fca4d3d86d0eed64e1e6c902a7efafb6770778151158ae335143f3a')),
    testimony(model(gemma_4_26b_a4b_it),
              job(unrecovered(file('rewrite_consultation_bigred.jsonl'))),
              date('2026-08-14')),
    receipt(swipl_test([reader_reproduces_facts, sentence_sha_verified]))).
