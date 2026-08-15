:- encoding(utf8).
/** <module> Persistent Prolog worker for the PUSU language harness
 *
 * The Python harness sends one defragged task statement at a time.  This
 * worker keeps the incumbent reader, APE, its generated user lexicon, and the
 * referent saturation predicates loaded across statements.  It returns one
 * complete JSON receipt per input line.
 */

:- module(pusu_harness_runner, []).

:- ensure_loaded('../../paths.pl').  % file_search_path aliases, so the
                                     % truth-decision route can reach
                                     % grounded arithmetic from any caller
:- use_module(library(http/json)).
:- use_module(library(porter_stem), [tokenize_atom/2]).
:- use_module(library(readutil), [read_line_to_string/2]).
:- use_module('../../knowledge/strategies/abstraction/word_problem_reader_pilot.pl').
:- use_module('../../knowledge/strategies/abstraction/ape_reader_pilot.pl').
:- use_module('../../knowledge/strategies/abstraction/pedagogy_force_pilot.pl').
:- use_module('../../knowledge/strategies/abstraction/printed_expression_reader_pilot.pl').
:- use_module('../../knowledge/strategies/abstraction/english_morphology.pl', []).
:- use_module('../../hermes/math_claim_language.pl', []).
:- use_module('../../hermes/math_claim_checker.pl', []).

:- initialization(main, main).

main :-
    prompt_loop.

prompt_loop :-
    read_line_to_string(user_input, Line),
    ( Line == end_of_file
    -> true
    ; catch(process_line(Line, Reply), Error, error_reply(Error, Reply)),
      json_write_dict(user_output, Reply, [width(0)]), nl,
      flush_output(user_output),
      prompt_loop
    ).

process_line(Line, Reply) :-
    atom_json_dict(Line, Request, []),
    get_dict(sentences, Request, Sentences),
    request_sentence_spans(Request, Sentences, SentenceSpans),
    read_sentences(Sentences, SentenceSpans, 0, SentenceRows0, ScopedProgram),
    contextualize_questions(Sentences, SentenceRows0, SentenceRows, Candidates),
    ( get_dict(source_statement, Request, SourceStatement0)
    -> SourceStatement = SourceStatement0
    ;  SourceStatement = ""
    ),
    select_program(Candidates, Sentences, SourceStatement, ScopedProgram,
                   SentenceProgram0, SentenceBasis),
    merge_discrete_kinds(SentenceProgram0, SentenceProgram),
    completion_receipt(SentenceProgram, SentenceCompletion),
    expression_reading(Request, ExpressionRow, ExpressionProgram,
                       ExpressionCompletion),
    select_completion(ExpressionRow, ExpressionProgram, ExpressionCompletion,
                      SentenceProgram, SentenceCompletion, SentenceBasis,
                      Program, Completion, ProgramBasis, CompletionCarrier),
    maplist(term_text, Program, ProgramStrings),
    maplist(term_text, SentenceProgram, SentenceProgramStrings),
    maplist(term_text, ExpressionProgram, ExpressionProgramStrings),
    Reply = _{ok:true, sentences:SentenceRows,
              program:ProgramStrings, program_basis:ProgramBasis,
              programs:_{sentence:SentenceProgramStrings,
                         printed_expression:ExpressionProgramStrings},
              printed_expression:ExpressionRow,
              expression_completion:ExpressionCompletion,
              completion_carrier:CompletionCarrier,
              completion:Completion}.

error_reply(Error, _{ok:false, error:Text}) :-
    message_to_string(Error, Text).

expression_reading(Request, Row, Program, Completion) :-
    get_dict(source_statement, Request, Source),
    get_dict(complete_statement, Request, Complete),
    get_dict(referents, Request, Referents),
    get_dict(source_statement_spans, Request, Spans),
    !,
    printed_expression_reader_pilot:printed_expression_result(
        Source, Complete, Referents, Spans, Result),
    expression_result_row(Result, Source, Row, Program, Completion).
expression_reading(_Request,
                   _{status:not_requested,class:null,program:[],refusal:null,
                     truth:null,fact_provenance:[]},
                   [],
                   _{status:not_parsed,reason:no_expression_request,
                     asks:[],ask_targets:[],answers:[]}).

expression_result_row(parsed(Class, Program, Receipt), Source, Row, Program,
                      Completion) :-
    term_text(Class, ClassText),
    maplist(term_text, Program, ProgramStrings),
    receipt_fact_provenance(Receipt.fact_provenance, FactProvenance),
    ( expression_truth_class(Class)
    -> truth_receipt(Source, Truth),
       truth_completion(Truth, Completion)
    ; completion_receipt(Program, Completion),
      Truth = null
    ),
    Row = _{status:parsed,class:ClassText,program:ProgramStrings,
            refusal:null,truth:Truth,
            ask:Receipt.ask,route:Receipt.route,target:Receipt.target,
            recovered:Receipt.recovered,
            fact_provenance:FactProvenance}.
expression_result_row(refused(Reason, _Receipt), _Source, Row, [], Completion) :-
    term_text(Reason, ReasonText),
    Row = _{status:refused,class:null,program:[],refusal:ReasonText,
            truth:null,fact_provenance:[]},
    Completion = _{status:not_parsed,reason:expression_refused,
                   asks:[],ask_targets:[],answers:[]}.

expression_truth_class(decide_truth).
expression_truth_class(recovered_from_statement(decide_truth)).

receipt_fact_provenance([], []).
receipt_fact_provenance([fact_trace(Index,Fact,Spans)|Rows],
                        [_{fact_index:Index,fact:FactText,spans:Spans}|Receipts]) :-
    term_text(Fact, FactText),
    receipt_fact_provenance(Rows, Receipts).

truth_receipt(Source, Receipt) :-
    math_claim_language:math_claims_in_text(Source, Claims),
    ( Claims = [Claim]
    -> term_text(Claim, ClaimText),
       math_claim_checker:check_math_claim(Claim, Verdict),
       Receipt = _{status:checked,module:"hermes/math_claim_checker.pl",
                   predicate:"check_math_claim/2",worker_required:false,
                   claim:ClaimText,verdict:Verdict}
    ; maplist(term_text, Claims, ClaimTexts),
      Receipt = _{status:refused,module:"hermes/math_claim_language.pl",
                  predicate:"math_claims_in_text/2",worker_required:false,
                  reason:non_unique_math_claim,claims:ClaimTexts}
    ).

truth_completion(Truth, Completion) :-
    get_dict(status, Truth, checked),
    get_dict(verdict, Truth, Verdict),
    get_dict(verdict, Verdict, Decision),
    memberchk(Decision, [holds,refuted]),
    !,
    Completion = _{status:truth_decided,reason:incumbent_math_claim_checker,
                   asks:[],ask_targets:[],answers:[],truth:Truth}.
truth_completion(Truth,
                 _{status:parsed_not_completed,reason:truth_not_checked,
                   asks:[],ask_targets:[],answers:[],truth:Truth}).

select_completion(_ExpressionRow, ExpressionProgram, ExpressionCompletion,
                  _SentenceProgram, _SentenceCompletion, _SentenceBasis,
                  ExpressionProgram, ExpressionCompletion,
                  _{kind:printed_expression,question_index:null,
                    base_sentence_indices:[]}, printed_expression) :-
    completion_succeeds(ExpressionCompletion), !.
select_completion(_ExpressionRow, _ExpressionProgram, _ExpressionCompletion,
                  SentenceProgram, SentenceCompletion, SentenceBasis,
                  SentenceProgram, SentenceCompletion, SentenceBasis,
                  complete_statement) :-
    completion_succeeds(SentenceCompletion), !.
select_completion(ExpressionRow, ExpressionProgram, ExpressionCompletion,
                  _SentenceProgram, _SentenceCompletion, _SentenceBasis,
                  ExpressionProgram, ExpressionCompletion,
                  _{kind:printed_expression,question_index:null,
                    base_sentence_indices:[]}, printed_expression) :-
    get_dict(status, ExpressionRow, parsed), !.
select_completion(_ExpressionRow, _ExpressionProgram, _ExpressionCompletion,
                  SentenceProgram, SentenceCompletion, SentenceBasis,
                  SentenceProgram, SentenceCompletion, SentenceBasis,
                  complete_statement).

completion_succeeds(Completion) :-
    get_dict(status, Completion, Status),
    memberchk(Status, [completed,truth_decided]).

% Each sentence may carry the byte spans its surface was decoded from.  The
% Python harness derives them by rebuilding the complete statement from the
% row's ordered source segments and mapping each normalized character home;
% a sentence without a verified anchor arrives as [].
request_sentence_spans(Request, Sentences, SentenceSpans) :-
    length(Sentences, Count),
    ( get_dict(sentence_spans, Request, SentenceSpans0),
      is_list(SentenceSpans0),
      length(SentenceSpans0, Count)
    -> SentenceSpans = SentenceSpans0
    ;  length(SentenceSpans, Count),
       maplist(=([]), SentenceSpans)
    ).

read_sentences([], [], _Index, [], []).
read_sentences([Text|Texts], [SentenceSpans|SpanRows], Index, [Row|Rows],
               Program) :-
    sentence_form(Text, Form),
    sentence_force_tag(Text, Force, ForceFrame),
    arbitration_result(Text, Form, SentenceSpans, Row0, Facts),
    put_dict(_{force:Force, force_frame:ForceFrame}, Row0, Row),
    namespace_facts(Index, Facts, ScopedFacts),
    Next is Index + 1,
    read_sentences(Texts, SpanRows, Next, Rows, Rest),
    append(ScopedFacts, Rest, Program).

% Re-run the incumbent over a bounded suffix of its accepted quantitative
% sentences plus each question.  This preserves the reader's own state and
% comparison rules while leaving refused pedagogy sentences in their original
% ledger rows.  A question is context-recovered only when the combined text
% yields an ask and a five-form program.
contextualize_questions(Sentences, Rows0, Rows, Candidates) :-
    contextualize_questions(Sentences, Rows0, 0, [], Rows, Candidates).

contextualize_questions([], [], _Index, _Prior, [], []).
contextualize_questions([Text|Texts], [Row0|Rows0], Index, Prior0,
                        [Row|Rows], Candidates) :-
    ( get_dict(sentence_form, Row0, question),
      best_context_candidate(Prior0, Text, Index, Candidate)
    -> context_question_row(Row0, Candidate, Row),
       Candidates = [Candidate|RestCandidates]
    ;  Row = Row0, Candidates = RestCandidates
    ),
    ( ( get_dict(reader, Row0, incumbent)
      ; contextual_support_sentence(Text)
      )
    -> append(Prior0, [indexed_text(Index,Text)], Prior1),
       last_n(6, Prior1, Prior)
    ;  Prior = Prior0
    ),
    Next is Index + 1,
    contextualize_questions(Texts, Rows0, Next, Prior, Rows, RestCandidates).

% A pronoun transfer is deliberately refused sentence-locally because it has
% no owner or carried kind there.  Retain only that bounded syntax as possible
% context so the combined incumbent reading can resolve it against a preceding
% named state.  Other refused sentences do not enter contextual programs.
contextual_support_sentence(Text) :-
    string_lower(Text, Lower), tokenize_atom(Lower, Tokens),
    phrase(word_problem_reader_pilot:problem_event(
               transfer(_Subject,_Action,_Number,_Kind,_Recipient,_Span)),
           Tokens).

best_context_candidate(Prior, Question, Index,
                       candidate(Index,Program,BaseIndices,DerivesAll)) :-
    append(_Dropped, Suffix, Prior),
    findall(Text, member(indexed_text(_,Text), Suffix), BaseTexts),
    append(BaseTexts, [Question], ProgramTexts),
    atomics_to_string(ProgramTexts, " ", Combined),
    word_problem_reader_pilot:word_problem_facts(Combined, Program),
    member(asks(result,_), Program), program_has_support(Program),
    findall(BaseIndex, member(indexed_text(BaseIndex,_), Suffix), BaseIndices),
    ( program_derives_all_asks(Program) -> DerivesAll = true
    ; DerivesAll = false
    ), !.

context_question_row(Row0, candidate(_Index,Program,BaseIndices,_), Row) :-
    question_program_facts(Program, QuestionFacts),
    maplist(term_text, QuestionFacts, FactStrings),
    Context = _{base_sentence_indices:BaseIndices,
                rule:contextual_incumbent_question},
    ( get_dict(parsed, Row0, true)
    -> put_dict(_{contextual_recovery:Context}, Row0, Row)
    ; put_dict(_{parsed:true,reader:incumbent_context,
                 facts:FactStrings,fact_spans:[],
                 rewrite_rules:["contextual_incumbent_question"],
                 contextual_recovery:Context}, Row0, Row)
    ).

question_program_facts(Program, Facts) :-
    findall(Fact,
            ( member(asks(result,Name), Program),
              ( Fact = asks(result,Name)
              ; member(Fact, Program), Fact = quantity(Name,_,_)
              ; member(Fact, Program), Fact = relation(Name,_,_)
              )
            ), Facts0),
    sort(Facts0, Facts).

% A defragged row names one sub-problem of a statement that may pose several.
% Selecting the last deriving candidate answers the statement's final question
% for every row that shares the statement, so seven rows about seven different
% sub-problems returned one number.  Bind to the row's own sub-problem first:
% prefer a candidate whose question sentence occurs inside this row's
% `source_statement`.  When the row carries no such question, the previous
% order stands and the basis says which rule chose.
select_program(Candidates, Sentences, SourceStatement, _Fallback, Program,
               _{kind:contextual,question_index:Index,
                 selection:source_statement_bound_deriving,
                 base_sentence_indices:BaseIndices}) :-
    SourceStatement \== "",
    include(deriving_candidate, Candidates, Deriving), Deriving \== [],
    include(candidate_in_source(Sentences, SourceStatement), Deriving, Bound),
    Bound \== [], !,
    last(Bound, candidate(Index,Program,BaseIndices,_)).
select_program(Candidates, Sentences, SourceStatement, _Fallback, Program,
               _{kind:contextual,question_index:Index,
                 selection:source_statement_bound,
                 base_sentence_indices:BaseIndices}) :-
    SourceStatement \== "",
    include(candidate_in_source(Sentences, SourceStatement), Candidates, Bound),
    Bound \== [], !,
    last(Bound, candidate(Index,Program,BaseIndices,_)).
select_program(Candidates, _Sentences, _SourceStatement, _Fallback, Program,
               _{kind:contextual,question_index:Index,
                 selection:last_deriving,
                 base_sentence_indices:BaseIndices}) :-
    include(deriving_candidate, Candidates, Deriving), Deriving \== [], !,
    last(Deriving, candidate(Index,Program,BaseIndices,_)).
select_program(Candidates, _Sentences, _SourceStatement, _Fallback, Program,
               _{kind:contextual,question_index:Index,
                 selection:last_candidate,
                 base_sentence_indices:BaseIndices}) :-
    Candidates \== [], !,
    last(Candidates, candidate(Index,Program,BaseIndices,_)).
select_program([], _Sentences, _SourceStatement, Fallback, Fallback,
               _{kind:sentence_scoped,question_index:null,
                 selection:sentence_scoped,
                 base_sentence_indices:[]}).

%! candidate_in_source(+Sentences, +SourceStatement, +Candidate) is semidet.
%
%  True when the candidate's question sentence is carried by this row's own
%  source statement.  Whitespace is normalized on both sides because the
%  sentence splitter and the defrag joiner space their output differently.
candidate_in_source(Sentences, SourceStatement, candidate(Index,_,_,_)) :-
    nth0(Index, Sentences, QuestionText),
    normalize_for_match(QuestionText, Needle),
    Needle \== "",
    normalize_for_match(SourceStatement, Haystack),
    sub_string(Haystack, _, _, _, Needle).

normalize_for_match(Text, Normalized) :-
    string_lower(Text, Lower),
    split_string(Lower, " \t\n\r", " \t\n\r", Parts0),
    exclude(==(""), Parts0, Parts),
    atomics_to_string(Parts, " ", Normalized).

deriving_candidate(candidate(_,_,_,true)).

program_derives_all_asks(Program) :-
    word_problem_reader_pilot:seed(Program),
    word_problem_reader_pilot:saturate(Program),
    forall(member(asks(result,Name), Program),
           word_problem_reader_pilot:derived(Name,_,_)).

program_has_support(Program) :- member(quantity(_,_,_), Program), !.
program_has_support(Program) :- member(relation(_,Recipe,_), Program),
    supported_recipe(Recipe), !.
program_has_support(Program) :- member(conversion(_,_,_,_), Program).

supported_recipe(convert(_,_)).
supported_recipe(scale(_,_)).
supported_recipe(sum(_)).
supported_recipe(difference(_,_)).
supported_recipe(quotient(_,_)).

last_n(Count, List, Tail) :-
    length(List, Length), Drop is max(0, Length - Count),
    length(Prefix, Drop), append(Prefix, Tail, List).

arbitration_result(Text, Form, SentenceSpans, Row, Facts) :-
    ( word_problem_reader_pilot:word_problem_reading(
          Text, IncumbentClass, IncumbentFacts)
    -> maplist(term_text, IncumbentFacts, FactStrings),
       term_text(IncumbentClass, ClassString),
       Row = _{parsed:true, reader:incumbent, sentence_form:Form,
               reader_class:ClassString,
               facts:FactStrings, fact_spans:[], rewrite_rules:[], refusals:_{}},
       Facts = IncumbentFacts
    ; incumbent_entry_token(Text, EntryToken),
      incumbent_refusal(Text, EntryToken, IncumbentRefusal),
      ape_reader_pilot:ape_reader_result(Text, ApeResult),
      ape_result_row(ApeResult, Text, SentenceSpans, IncumbentRefusal,
                     Form, Row, Facts)
    ).

incumbent_refusal(Text, EntryToken,
                  _{token:EntryToken,reason:ReasonString,
                    token_basis:named_language_lane_refusal}) :-
    word_problem_reader_pilot:word_problem_refusal(Text, Reason), !,
    term_text(Reason, ReasonString).
incumbent_refusal(_Text, EntryToken,
                  _{token:EntryToken,
                    token_basis:sentence_entry_no_failure_api}).

ape_result_row(parsed(Facts, FactSpans, Rules), _Text, _SentenceSpans,
               IncumbentRefusal, Form, Row, Facts) :-
    maplist(term_text, Facts, FactStrings),
    findall(_{fact_index:Index,start:Start,end:End,text:Text},
            member(fact_span(Index,Start,End,Text), FactSpans), SpanRows),
    maplist(term_text, Rules, RuleStrings),
    Row = _{parsed:true, reader:ape, sentence_form:Form,
            facts:FactStrings, fact_spans:SpanRows, rewrite_rules:RuleStrings,
            refusals:_{incumbent:IncumbentRefusal}}.
ape_result_row(refusal(Token,span(Start,End,Surface),Reason,Rules),
               Text, SentenceSpans, IncumbentRefusal, Form, Row, Facts) :-
    term_text(Reason, ReasonString),
    maplist(term_text, Rules, RuleStrings),
    Refusals = _{incumbent:IncumbentRefusal,
                 ape:_{token:Token,start:Start,end:End,text:Surface,
                       reason:ReasonString}},
    expression_segment_row(Text, SentenceSpans, Refusals, Form, RuleStrings,
                           Row, Facts).

% ---- Expression-segment routing --------------------------------------------
%
% Both prose readers refused the sentence.  When its whole surface lies inside
% the printed-expression grammar's alphabet, the quarantined pilot reads it
% and the ledger records what the bytes state.  The policy, pinned by
% check_expression_routing/0:
%
%   - a hole-free expression states a composition: quantity and relation
%     facts with an unknown root, no ask, no evaluation;
%   - an equation with exactly one hole writes a demand for the number that
%     fills its blank: structure facts plus asks/2, and never a fact that the
%     equation holds, never a value for the hole;
%   - an equation without a hole is a truth claim; the sentence lane refuses
%     it because truth verdicts belong to the math-claim checker;
%   - everything else refuses with a named reason for the census.
%
% Routed facts stay out of the statement's answering program in this slice:
% the third argument of every clause below returns [] to the saturator, so
% every completion, answer, and verdict keeps its existing carrier.  A routed
% sentence must also name its own source bytes; without a verified anchor the
% route refuses rather than borrowing the statement's.
expression_segment_row(Text, SentenceSpans, Refusals, Form, RuleStrings,
                       Row, []) :-
    expression_segment_shaped(Text),
    expression_segment_reading(Text, SentenceSpans, Class, Ast, SegmentFacts),
    !,
    maplist(term_text, SegmentFacts, FactStrings),
    term_text(Ast, AstString),
    findall(_{fact_index:Index,fact:FactText,spans:SentenceSpans},
            ( nth0(Index, SegmentFacts, Fact),
              term_text(Fact, FactText)
            ),
            FactProvenance),
    Row = _{parsed:true, reader:printed_expression_segment,
            reader_class:Class, expression_ast:AstString,
            sentence_form:Form, facts:FactStrings, fact_spans:[],
            source_spans:SentenceSpans, fact_provenance:FactProvenance,
            rewrite_rules:RuleStrings, refusals:Refusals}.
expression_segment_row(Text, SentenceSpans, Refusals0, Form, RuleStrings,
                       Row, []) :-
    expression_segment_shaped(Text), !,
    expression_segment_refusal(Text, SentenceSpans, Reason),
    term_text(Reason, ReasonString),
    put_dict(_{expression_route:_{reason:ReasonString}}, Refusals0, Refusals),
    Row = _{parsed:false, reader:both_refused, sentence_form:Form,
            facts:[], fact_spans:[], rewrite_rules:RuleStrings,
            refusals:Refusals}.
expression_segment_row(_Text, _SentenceSpans, Refusals, Form, RuleStrings,
                       _{parsed:false, reader:both_refused, sentence_form:Form,
                         facts:[], fact_spans:[], rewrite_rules:RuleStrings,
                         refusals:Refusals}, []).

%! expression_segment_shaped(+Text) is semidet.
%
%  The sentence carries at least one digit and nothing outside the
%  printed-expression grammar's surface alphabet.  Prose keeps its existing
%  refusal receipt untouched; only surfaces the grammar could in principle
%  read gain an expression_route entry.
expression_segment_shaped(Text) :-
    string_codes(Text, Codes),
    include(digit_code, Codes, [_|_]),
    forall(member(Code, Codes), expression_surface_code(Code)).

digit_code(Code) :- code_type(Code, digit).

expression_surface_code(Code) :- code_type(Code, digit), !.
expression_surface_code(Code) :- code_type(Code, space), !.
expression_surface_code(0'+).
expression_surface_code(0'-).
expression_surface_code(0'×).
expression_surface_code(0'x).
expression_surface_code(0'X).
expression_surface_code(0'*).
expression_surface_code(0'÷).
expression_surface_code(0'/).
expression_surface_code(0'=).
expression_surface_code(0'?).
expression_surface_code(0'_).
expression_surface_code(0'().
expression_surface_code(0')).
expression_surface_code(0',).
expression_surface_code(0'.).
expression_surface_code(0x2022).
expression_surface_code(0x25e6).

expression_segment_reading(Text, SentenceSpans, Class, Ast, Facts) :-
    SentenceSpans = [_|_],
    printed_expression_reader_pilot:printed_expression_ast(Text, Ast),
    printed_expression_reader_pilot:hole_count(Ast, Holes),
    expression_segment_compile(Ast, Holes, SentenceSpans, Class, Facts).

% The compile steps below are the pilot's own: one authority describes
% expression structure, and this router only decides which shapes the
% sentence lane may carry.  The pilot file itself is unchanged.
expression_segment_compile(Ast, no_holes, SentenceSpans,
                           segment_expression, Facts) :-
    Ast \= equation(_, _),
    printed_expression_reader_pilot:provenance_term(SentenceSpans, Span),
    printed_expression_reader_pilot:compile_tree(Ast, expr_1_value, Span,
                                                 Facts).
expression_segment_compile(equation(Left, Right), one_hole, SentenceSpans,
                           segment_equation_one_hole, Facts) :-
    printed_expression_reader_pilot:provenance_term(SentenceSpans, Span),
    printed_expression_reader_pilot:compile_missing_equation(
        Left, Right, Span, Facts, _Target).

expression_segment_refusal(_Text, [], no_sentence_byte_anchor) :- !.
expression_segment_refusal(Text, _SentenceSpans, Reason) :-
    ( printed_expression_reader_pilot:printed_expression_ast(Text, Ast)
    -> printed_expression_reader_pilot:hole_count(Ast, Holes),
       expression_segment_shape_refusal(Ast, Holes, Reason)
    ;  Reason = unsupported_expression_syntax
    ).

expression_segment_shape_refusal(equation(_, _), no_holes,
                                 equation_without_hole_is_a_truth_claim) :- !.
expression_segment_shape_refusal(equation(_, _), one_hole,
                                 hole_position_not_compilable) :- !.
expression_segment_shape_refusal(_Ast, multiple_holes,
                                 multiple_holes_underdetermined) :- !.
expression_segment_shape_refusal(_Ast, one_hole,
                                 hole_outside_equation_underdetermined) :- !.
expression_segment_shape_refusal(_Ast, _Holes,
                                 expression_route_not_compilable).

%! check_expression_routing is det.
%
%  Receipts for the routing policy, in both directions.  Run from the
%  repository root:
%  `swipl -q -l scripts/language/pusu_harness_runner.pl -g pusu_harness_runner:check_expression_routing -t halt`
check_expression_routing :-
    Span = _{path:"guide.md", line_start:4, line_end:4,
             byte_start:20, byte_end:29, sha256:"abc"},
    % A bare left-hand side yields operands, a relation with an unknown
    % result, and the blank's demand -- and no equality fact, no value.
    expression_segment_reading("15 - 10 =", [Span],
                               segment_equation_one_hole, _, FactsA),
    memberchk(quantity(expr_1_missing, unknown, number), FactsA),
    memberchk(relation(expr_1_missing, difference(_, _), _), FactsA),
    memberchk(asks(result, expr_1_missing), FactsA),
    \+ ( member(quantity(expr_1_missing, Value, _), FactsA), number(Value) ),
    % The bare right-hand side mirrors it.
    expression_segment_reading("= 13 - 3", [Span],
                               segment_equation_one_hole, _, FactsB),
    memberchk(asks(result, expr_1_missing), FactsB),
    % The other direction: a complete equation is a truth claim and the
    % sentence lane refuses it.
    \+ expression_segment_reading("15 - 10 = 5", [Span], _, _, _),
    expression_segment_refusal("15 - 10 = 5", [Span],
                               equation_without_hole_is_a_truth_claim),
    % A hole-free expression emits structure and asks nothing.
    expression_segment_reading("7 + 1", [Span], segment_expression, _, FactsC),
    memberchk(relation(expr_1_value, sum([_, _]), _), FactsC),
    \+ memberchk(asks(_, _), FactsC),
    % No verified byte anchor, no route.
    expression_segment_refusal("7 + 1", [], no_sentence_byte_anchor),
    % Terminal punctuation and item markers stay outside the grammar.
    expression_segment_refusal("7 + 12.", [Span],
                               unsupported_expression_syntax),
    expression_segment_refusal("2.", [Span], unsupported_expression_syntax),
    % Prose never gains an expression_route entry.
    \+ expression_segment_shaped("Lin has 7 cubes."),
    % The routed row itself: parsed, named route, facts present, and a
    % program contribution of exactly [].
    arbitration_result("15 - 10 =", declarative, [Span], RowA, ProgramA),
    ProgramA == [],
    get_dict(reader, RowA, printed_expression_segment),
    get_dict(facts, RowA, [_|_]),
    get_dict(source_spans, RowA, [Span]),
    % A refused route names its reason beside the prose refusals.
    arbitration_result("15 - 10 = 5", declarative, [Span], RowB, ProgramB),
    ProgramB == [],
    get_dict(refusals, RowB, RefusalsB),
    get_dict(expression_route, RefusalsB, RouteB),
    get_dict(reason, RouteB, "equation_without_hole_is_a_truth_claim"),
    format('check_expression_routing: ok receipts=13 evaluation=none~n').

incumbent_entry_token(Text, TokenString) :-
    string_lower(Text, Lower),
    tokenize_atom(Lower, Tokens),
    ( Tokens = [Entry|_] -> term_text(Entry, TokenString) ; TokenString = "" ).

sentence_form(Text, question) :-
    normalize_space(string(Trimmed), Text),
    sub_string(Trimmed, _, 1, 0, "?"), !.
sentence_form(Text, directive) :-
    string_lower(Text, Lower),
    tokenize_atom(Lower, Tokens0),
    drop_leading_markers(Tokens0, Tokens),
    Tokens = [Head|_], atom(Head),
    once(english_morphology:em_verb_base(Head, Head, _)), !.
sentence_form(_Text, declarative).

sentence_force_tag(Text, Force, FrameId) :-
    pedagogy_force_pilot:sentence_force(Text, Force, FrameId), !.
sentence_force_tag(_Text, unmarked, null).

drop_leading_markers([Token,'.'|Tokens], Rest) :-
    number(Token), !, drop_leading_markers(Tokens, Rest).
drop_leading_markers([Token|Tokens], Rest) :-
    memberchk(Token, ['\u2022','\u25e6','-']), !, drop_leading_markers(Tokens, Rest).
drop_leading_markers(Tokens, Tokens).

term_text(Term, Text) :-
    term_string(Term, Text, [quoted(true)]).

% A reader invocation is sentence-local.  Its referent names therefore need a
% sentence scope before several readings can share one saturation program;
% otherwise APE's book_1 in two different sentences would create a false join.
namespace_facts(_Index, [], []).
namespace_facts(Index, [Fact|Facts], [Scoped|ScopedFacts]) :-
    namespace_fact(Index, Fact, Scoped),
    namespace_facts(Index, Facts, ScopedFacts).

namespace_fact(Index, quantity(Name,Value,Kind), quantity(Scoped,Value,Kind)) :- !,
    scoped_name(Index, Name, Scoped).
namespace_fact(Index, asks(result,Name), asks(result,Scoped)) :- !,
    scoped_name(Index, Name, Scoped).
namespace_fact(Index, relation(Name,Recipe,Span), relation(Scoped,ScopedRecipe,Span)) :- !,
    scoped_name(Index, Name, Scoped),
    namespace_recipe(Index, Recipe, ScopedRecipe).
namespace_fact(_Index, Fact, Fact).

namespace_recipe(Index, convert(Source,Kind), convert(Scoped,Kind)) :- !,
    scoped_name(Index, Source, Scoped).
namespace_recipe(Index, scale(Scale,Source), scale(ScopedScale,ScopedSource)) :- !,
    scoped_name(Index, Scale, ScopedScale),
    scoped_name(Index, Source, ScopedSource).
namespace_recipe(Index, sum(Parts), sum(ScopedParts)) :- !,
    maplist(scoped_name(Index), Parts, ScopedParts).
namespace_recipe(Index, difference(Minuend,Subtrahend),
                 difference(ScopedMinuend,ScopedSubtrahend)) :- !,
    scoped_name(Index, Minuend, ScopedMinuend),
    scoped_name(Index, Subtrahend, ScopedSubtrahend).
namespace_recipe(Index, quotient(Dividend,Divisor),
                 quotient(ScopedDividend,ScopedDivisor)) :- !,
    scoped_name(Index, Dividend, ScopedDividend),
    scoped_name(Index, Divisor, ScopedDivisor).
namespace_recipe(_Index, Recipe, Recipe).

scoped_name(Index, Name, Scoped) :-
    format(atom(Scoped), 's~d_~w', [Index,Name]).

merge_discrete_kinds(Program0, Program) :-
    findall(Kind,
            ( member(discrete_kinds(Kinds), Program0), member(Kind, Kinds) ),
            Kinds0),
    sort(Kinds0, Kinds),
    exclude(is_discrete_kinds, Program0, Facts),
    ( Kinds == [] -> Program = Facts ; append(Facts, [discrete_kinds(Kinds)], Program) ).

is_discrete_kinds(discrete_kinds(_)).

completion_receipt([], _{status:not_parsed,reason:no_parsed_sentences,
                         asks:[],ask_targets:[],answers:[]}) :- !.
completion_receipt(Program, Receipt) :-
    findall(Name, member(asks(result,Name), Program), Asked0),
    sort(Asked0, Asked),
    ask_targets(Asked, Program, AskTargets),
    ( Asked == []
    -> Receipt = _{status:parsed_not_completed,reason:no_ask,
                   asks:[],ask_targets:[],answers:[]}
    ; \+ program_has_support(Program)
    -> Receipt = _{status:parsed_not_completed,reason:no_program_facts,
                   asks:Asked,ask_targets:AskTargets,answers:[]}
    ; program_incoherences(Program, Incoherences), Incoherences \== []
    -> Receipt = _{status:refused_incoherent_program,
                   reason:inconsistent_referent_bindings,
                   asks:Asked,ask_targets:AskTargets,answers:[],
                   incoherences:Incoherences}
    ; identity_target_names(AskTargets, IdentityNames), IdentityNames \== []
    -> Receipt = _{status:parsed_not_completable,reason:identity_demand,
                   asks:Asked,ask_targets:AskTargets,answers:[],
                   identity_asks:IdentityNames}
    ; word_problem_reader_pilot:seed(Program),
      word_problem_reader_pilot:saturate(Program),
      answer_rows(Asked, Answers),
      findall(Name, (member(Name,Asked), \+ answer_for(Name,Answers)), Missing),
      ( Missing \== []
      -> maplist(term_text, Missing, MissingStrings),
         Receipt = _{status:parsed_not_completed,reason:underdetermined,
                     asks:Asked,ask_targets:AskTargets,answers:Answers,
                     missing_asks:MissingStrings}
      ; conflicting_answer(Answers, Conflicting)
      -> term_text(Conflicting, ConflictString),
         Receipt = _{status:parsed_not_completed,reason:contradictory,
                     asks:Asked,ask_targets:AskTargets,answers:Answers,
                     conflicting_ask:ConflictString}
      ; non_integer_answer(Program, Answers, BadName, BadValue)
      -> term_text(BadName, BadNameString), term_text(BadValue, BadValueString),
         Receipt = _{status:parsed_not_completed,reason:non_integer_demand,
                     asks:Asked,ask_targets:AskTargets,answers:Answers,
                     non_integer:_{referent:BadNameString,value:BadValueString}}
      ; Receipt = _{status:completed,reason:derived_all_asks,
                    asks:Asked,ask_targets:AskTargets,answers:Answers}
      )
    ).

program_incoherences(Program, Rows) :-
    findall(conflict(Name,KindA,ValueA,KindB,ValueB),
            inconsistent_binding(Program, Name, KindA, ValueA, KindB, ValueB),
            Conflicts0),
    sort(Conflicts0, Conflicts),
    maplist(conflict_dict, Conflicts, Rows).

inconsistent_binding(Program, Name, KindA, ValueA, KindB, ValueB) :-
    member(quantity(Name,ValueA,KindA), Program), number(ValueA),
    member(quantity(Name,ValueB,KindB), Program), number(ValueB),
    quantity_binding_key(KindA,ValueA, First),
    quantity_binding_key(KindB,ValueB, Second), First @< Second,
    ( KindA \== KindB
    ; \+ word_problem_reader_pilot:close_enough(ValueA, ValueB)
    ).

quantity_binding_key(Kind, Value, Kind-Value).

conflict_dict(conflict(Name,KindA,ValueA,KindB,ValueB),
              _{referent:NameText,
                first:_{kind:KindAText,value:ValueAText},
                second:_{kind:KindBText,value:ValueBText}}) :-
    maplist(term_text,
            [Name,KindA,ValueA,KindB,ValueB],
            [NameText,KindAText,ValueAText,KindBText,ValueBText]).

ask_targets([], _Program, []).
ask_targets([Name|Names], Program, [Target|Targets]) :-
    ask_target(Name, Program, Target),
    ask_targets(Names, Program, Targets).

ask_target(Name, Program,
           _{referent:NameString,target_kind:identity,
             referent_class:KindString}) :-
    member(relation(Name,identity_demand(Kind),_), Program), !,
    term_text(Name, NameString), term_text(Kind, KindString).
ask_target(Name, Program,
           _{referent:NameString,target_kind:numeric,
             referent_class:KindString}) :-
    member(quantity(Name,_,Kind), Program), !,
    term_text(Name, NameString), term_text(Kind, KindString).
ask_target(Name, _Program,
           _{referent:NameString,target_kind:unknown,
             referent_class:unknown}) :-
    term_text(Name, NameString).

identity_target_names(Targets, Names) :-
    findall(Name,
            ( member(Target, Targets),
              get_dict(target_kind, Target, identity),
              get_dict(referent, Target, Name) ),
            Names).

answer_rows(Asked, Answers) :-
    findall(answer(Name,Value,How),
            ( member(Name, Asked),
              word_problem_reader_pilot:derived(Name,Value,How) ),
            Answers0),
    sort(Answers0, Unique),
    maplist(answer_dict, Unique, Answers).

answer_dict(answer(Name,Value,How),
            _{referent:NameString,value:ValueString,derivation:HowString}) :-
    term_text(Name, NameString),
    term_text(Value, ValueString),
    term_text(How, HowString).

answer_for(Name, Answers) :-
    term_text(Name, NameString),
    member(Answer, Answers), get_dict(referent, Answer, NameString), !.

conflicting_answer(Answers, Name) :-
    member(First, Answers), get_dict(referent, First, Name),
    findall(Value,
            ( member(Answer,Answers), get_dict(referent,Answer,Name),
              get_dict(value,Answer,Value) ), Values0),
    sort(Values0, Values), length(Values, Count), Count > 1, !.

non_integer_answer(Program, Answers, Name, Value) :-
    member(Answer, Answers),
    get_dict(referent, Answer, NameString), get_dict(value, Answer, ValueString),
    term_string(Name, NameString), term_string(Value, ValueString),
    member(quantity(Name,_,Kind), Program),
    member(discrete_kinds(Kinds), Program), memberchk(Kind, Kinds),
    Rounded is round(Value),
    \+ word_problem_reader_pilot:close_enough(Value, Rounded), !.
