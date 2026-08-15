:- encoding(utf8).
/** <module> Printed-expression reader pilot
 *
 * This quarantined DCG reads the expression isolated in a defragged task row
 * and emits only the five-form sidekick schema.  It describes arithmetic
 * structure; registered downstream machinery remains responsible for every
 * answer and truth verdict.
 *
 * Check from the repository root:
 * `swipl -q -s paths.pl -s knowledge/strategies/abstraction/printed_expression_reader_pilot.pl -g printed_expression_reader_pilot:check_printed_expression_reader_pilot -t halt`
 */

:- module(printed_expression_reader_pilot,
          [ printed_expression_result/5,
            printed_expression_ast/2,
            printed_expression_reader_pilot_summary/1,
            check_printed_expression_reader_pilot/0
          ]).

:- use_module(library(dcg/basics), [blanks//0, blank//0, digits//1]).
:- use_module(library(lists), [append/2, memberchk/2]).
:- use_module(library(porter_stem), [porter_stem/2, tokenize_atom/2]).
:- use_module(hermes(math_claim_checker), [check_math_claim/2]).

printed_expression_reader_pilot_summary(
    summary(role(orphan_printed_expression_reader),
            input(source_statement_with_referent_and_source_segments),
            ask_classes([find_value,find_missing_number,decide_truth,
                         recovered_from_statement]),
            output_contract(five_form_sidekick_schema),
            evaluation(none),
            parenthesized_corpus_rows(0),
            mixed_number_corpus_rows(5))).

%!  printed_expression_result(+Source, +Complete, +Referents, +Spans, -Result)
%   is det.
%
%   Result is parsed(Class, Program, Receipt) or refused(Reason, Receipt).
%   Program contains only quantity/3, conversion/4, relation/3, asks/2, and
%   discrete_kinds/1 terms.  Receipt maps every emitted fact back to the
%   source-statement segments supplied by the generated defrag store.
printed_expression_result(Source0, Complete0, Referents, Spans, Result) :-
    text_string(Source0, Source),
    text_string(Complete0, Complete),
    ( Spans == []
    -> refusal(Source, no_source_statement_provenance, Result)
    ; printed_expression_ast(Source, Ast)
    -> expression_result(Ast, Source, Complete, Referents, Spans, Result)
    ; refusal(Source, unsupported_expression_syntax, Result)
    ), !.

printed_expression_ast(Text0, Ast) :-
    text_string(Text0, Text),
    string_codes(Text, Codes),
    phrase(printed_surface(Ast), Codes).

printed_surface(Ast) -->
    blanks, optional_bullet, blanks, optional_item_number, blanks,
    ( comparison_surface(Ast)
    ; equation_surface(Ast)
    ; expression(Ast)
    ),
    blanks.

optional_bullet --> [0x2022], !.
optional_bullet --> [0x25e6], !.
optional_bullet --> [].

optional_item_number --> digits(_), ".", blank, !, blanks.
optional_item_number --> [Code], ".", blank,
    { code_type(Code, alpha) }, !, blanks.
optional_item_number --> [].

comparison_surface(comparison_chain(Left, FirstRelation, Middle,
                                    SecondRelation, Right)) -->
    comparison_side(Left), blanks, comparison_operator(FirstRelation), blanks,
    comparison_side(Middle), blanks, comparison_operator(SecondRelation), blanks,
    comparison_side(Right),
    { ( Left \== hole ; Middle \== hole ; Right \== hole ) }.
comparison_surface(comparison(Left, Relation, Right)) -->
    comparison_side(Left), blanks, comparison_operator(Relation), blanks,
    comparison_side(Right),
    { ( Left \== hole ; Right \== hole ) }.

comparison_side(Tree) --> expression(Tree).
comparison_operator(greater) --> ">".
comparison_operator(smaller) --> "<".

equation_surface(equation(Left, Right)) -->
    equation_side(Left), blanks, "=", blanks, equation_side(Right),
    { ( Left \== hole ; Right \== hole ) }.

equation_side(Tree) --> leading_hole_expression(Tree).
equation_side(Tree) --> trailing_hole_expression(Tree).
equation_side(Tree) --> expression(Tree).
equation_side(hole) --> [].

leading_hole_expression(Tree) --> additive_operator(Op), multiplicative(Right),
    { binary_tree(Op, hole, Right, Tree) }.
leading_hole_expression(Tree) --> multiplicative_operator(Op), primary(Right),
    { binary_tree(Op, hole, Right, Tree) }.

trailing_hole_expression(Tree) --> multiplicative(Left), additive_operator(Op),
    { binary_tree(Op, Left, hole, Tree) }.
trailing_hole_expression(Tree) --> primary(Left), multiplicative_operator(Op),
    { binary_tree(Op, Left, hole, Tree) }.

expression(Tree) --> multiplicative(Left), additive_rest(Left, Tree).

additive_rest(Left, Tree) -->
    additive_operator(Op), multiplicative(Right), !,
    { binary_tree(Op, Left, Right, Next) },
    additive_rest(Next, Tree).
additive_rest(Tree, Tree) --> [].

multiplicative(Tree) --> primary(Left), multiplicative_rest(Left, Tree).

multiplicative_rest(Left, Tree) -->
    multiplicative_operator(Op), primary(Right), !,
    { binary_tree(Op, Left, Right, Next) },
    multiplicative_rest(Next, Tree).
multiplicative_rest(Tree, Tree) --> [].

additive_operator(add) --> blanks, "+", blanks.
additive_operator(subtract) --> blanks, "-", blanks.

multiplicative_operator(multiply) --> blanks, "×", blanks.
multiplicative_operator(multiply) --> blanks, "x", blanks.
multiplicative_operator(multiply) --> blanks, "X", blanks.
multiplicative_operator(multiply) --> blanks, "*", blanks.
multiplicative_operator(divide) --> blanks, "÷", blanks.
multiplicative_operator(divide) --> blanks, "/", blanks.

%   A parenthesized group. The corpus writes these in grade 3 upward, as
%   "(2 × 10) + (3 × 5)" and "72 ÷ 6 = (60 ÷ 6) + (12 ÷ 6)". 38 anchored
%   expressions refused on the bracket alone.
primary(Tree) --> "(", blanks, expression(Tree), blanks, ")", !.

%   A written blank. The reader already carries `hole` for an operand the
%   layout dropped; the corpus also writes the unknown out, as "54- 16 = ?"
%   and "10 = 9 + ___". 58 anchored expressions refused on the marker alone.
%   The marker is read, never evaluated: it is the same hole either way.
primary(hole) --> written_blank, !.
primary(mixed(literal(Whole), Fraction)) -->
    numeric_literal(Whole), blank, blanks, fraction_literal(Fraction), !.
primary(Fraction) --> fraction_literal(Fraction), !.
primary(literal(Value)) --> numeric_literal(Value).

written_blank --> "?".
written_blank --> "_", "_", underscore_tail.

underscore_tail --> "_", !, underscore_tail.
underscore_tail --> [].

fraction_literal(literal(Value)) -->
    unsigned_integer(Numerator), "/", unsigned_integer(Denominator),
    { rational_literal(Numerator, Denominator, Value) }.

numeric_literal(Value) -->
    numeric_codes(Codes),
    { exclude(comma_code, Codes, PlainCodes),
      string_codes(Plain, PlainCodes),
      catch(number_string(Value, Plain), _, fail) }.

unsigned_integer(Value) -->
    digits(Codes),
    { string_codes(Text, Codes), number_string(Value, Text) }.

numeric_codes([Code|Codes]) -->
    [Code], { numeric_code(Code) }, !, numeric_codes_rest(Codes).

numeric_codes_rest([Code|Codes]) -->
    [Code], { numeric_code(Code) }, !, numeric_codes_rest(Codes).
numeric_codes_rest([]) --> [].

numeric_code(Code) :- code_type(Code, digit).
numeric_code(0',).
numeric_code(0'.).

comma_code(0',).

rational_literal(Numerator, Denominator, Value) :-
    dif(Denominator, 0),
    format(string(Text), "~wr~w", [Numerator, Denominator]),
    catch(term_string(Value, Text), _, fail),
    number(Value).

binary_tree(add, Left, Right, add(Left, Right)).
binary_tree(subtract, Left, Right, subtract(Left, Right)).
binary_tree(multiply, Left, Right, multiply(Left, Right)).
binary_tree(divide, Left, Right, divide(Left, Right)).

expression_result(Ast, Source, Complete, Referents, Spans, Result) :-
    ask_class(Referents, Complete, AskClass, AskReceipt),
    !,
    compile_for_ask(AskClass, Ast, Spans, Program, CompileReceipt),
    !,
    fact_provenance(Program, Spans, FactProvenance),
    put_dict(CompileReceipt,
             receipt{source_statement:Source, ask:AskReceipt,
                     fact_provenance:FactProvenance},
             Receipt),
    Result = parsed(AskClass, Program, Receipt).
expression_result(_Ast, Source, Complete, Referents, _Spans, Result) :-
    ask_refusal(Referents, Complete, Reason),
    refusal(Source, Reason, Result).

ask_class(Referents, Complete, recovered_from_statement(Class), Receipt) :-
    referent_antecedent(Referents, "", _Kind),
    demand_classes(Complete, [Class]),
    Receipt = ask{source:complete_statement,recovered_as:Class},
    !.
ask_class(Referents, _Complete, Class, Receipt) :-
    referent_antecedent(Referents, Antecedent, Kind),
    Antecedent \== "",
    demand_classes(Antecedent, Classes),
    Classes = [Class],
    class_kind(Class, Kind),
    Receipt = ask{source:referent_antecedent,kind:Kind},
    !.

ask_refusal(Referents, Complete, ambiguous_recovered_demands(Classes)) :-
    referent_antecedent(Referents, "", _),
    demand_classes(Complete, Classes),
    Classes = [_,_|_], !.
ask_refusal(Referents, Complete, recovery_not_determinate) :-
    referent_antecedent(Referents, "", _),
    demand_classes(Complete, []), !.
ask_refusal(Referents, _Complete, referent_kind_mismatch(Class, Kind)) :-
    referent_antecedent(Referents, Antecedent, Kind),
    Antecedent \== "",
    demand_classes(Antecedent, [Class]),
    \+ class_kind(Class, Kind), !.
ask_refusal(Referents, _Complete, ambiguous_referent_demands(Classes)) :-
    referent_antecedent(Referents, Antecedent, _),
    demand_classes(Antecedent, Classes),
    Classes = [_,_|_], !.
ask_refusal(_Referents, _Complete, unsupported_referent_demand).

referent_antecedent([Referent|_], Antecedent, Kind) :-
    get_dict(antecedent, Referent, Antecedent0),
    get_dict(kind, Referent, Kind0),
    text_string(Antecedent0, Antecedent),
    text_string(Kind0, Kind), !.
referent_antecedent([], "", "").

class_kind(find_value, "expression").
class_kind(find_missing_number, "equation").
class_kind(decide_truth, "equation").

demand_classes(Text0, Classes) :-
    text_string(Text0, Text),
    string_lower(Text, Lower),
    tokenize_atom(Lower, Tokens),
    findall(Class, demand_class(Tokens, Class), Classes0),
    sort(Classes0, Classes).

demand_class(Tokens, find_missing_number) :-
    ordered_roots(Tokens, [find,number,make]).
demand_class(Tokens, find_value) :-
    ordered_roots(Tokens, [find,value]).
demand_class(Tokens, decide_truth) :-
    ordered_roots(Tokens, [decid,whether]).
demand_class(Tokens, decide_truth) :-
    ordered_roots(Tokens, [determin,whether]).
%   The corpus asks for a truth decision far more often as "Decide if each
%   statement is true or false." than as "Decide whether". That one phrasing
%   carries 48 of the 328 asks the reader could not place on 2026-08-14.
demand_class(Tokens, decide_truth) :-
    ordered_roots(Tokens, [decid,true]).
demand_class(Tokens, decide_truth) :-
    ordered_roots(Tokens, [determin,true]).
%   "What is the value of each expression?" demands the same doing as
%   "Find the value of".
demand_class(Tokens, find_value) :-
    ordered_roots(Tokens, [what,valu]).

ordered_roots(Tokens, Roots) :-
    roots_in_order(Roots, Tokens).

roots_in_order([], _).
roots_in_order([Root|Roots], Tokens) :-
    append(_, [Token|Rest], Tokens),
    token_root(Token, Root),
    roots_in_order(Roots, Rest),
    !.

token_root(Token, Root) :-
    atom(Token),
    catch(porter_stem(Token, Root), _, fail), !.
token_root(Token, Token).

compile_for_ask(recovered_from_statement(Class), Ast, Spans, Program, Receipt) :-
    compile_for_ask(Class, Ast, Spans, Program, Receipt0),
    put_dict(_{recovered:true,recovered_as:Class}, Receipt0, Receipt).
compile_for_ask(decide_truth, equation(Left, Right), _Spans, [], Receipt) :-
    hole_count(equation(Left, Right), no_holes),
    Receipt = compile{route:check_math_claim,truth_surface:verbatim,
                      target:none,recovered:false}.
compile_for_ask(decide_truth, comparison(Left, Relation, Right), _Spans, [],
                Receipt) :-
    hole_count(comparison(Left, Relation, Right), no_holes),
    Receipt = compile{route:check_math_claim,truth_surface:verbatim,
                      target:none,recovered:false}.
compile_for_ask(find_missing_number, comparison(Left, Relation, Right), Spans,
                Program, Receipt) :-
    hole_count(comparison(Left, Relation, Right), one_hole),
    provenance_term(Spans, Span),
    compile_missing_comparison(Left, Relation, Right, Span, Program, Target),
    Receipt = compile{route:standards_router,target:Target,recovered:false}.
compile_for_ask(find_missing_number,
                comparison_chain(Left, FirstRelation, Middle,
                                 SecondRelation, Right), Spans,
                Program, Receipt) :-
    Ast = comparison_chain(Left, FirstRelation, Middle,
                           SecondRelation, Right),
    hole_count(Ast, one_hole),
    provenance_term(Spans, Span),
    compile_missing_comparison_chain(Left, FirstRelation, Middle,
                                     SecondRelation, Right, Span,
                                     Program, Target),
    Receipt = compile{route:standards_router,target:Target,recovered:false}.
compile_for_ask(find_missing_number, equation(Left, Right), Spans,
                Program, Receipt) :-
    hole_count(equation(Left, Right), one_hole),
    provenance_term(Spans, Span),
    compile_missing_equation(Left, Right, Span, Program, Target),
    Receipt = compile{route:standards_router,target:Target,recovered:false}.
compile_for_ask(find_value, equation(Left, Right), Spans, Program, Receipt) :-
    hole_count(equation(Left, Right), one_hole),
    provenance_term(Spans, Span),
    compile_missing_equation(Left, Right, Span, Program, Target),
    Receipt = compile{route:standards_router,target:Target,recovered:false}.
compile_for_ask(find_value, Ast, Spans, Program, Receipt) :-
    Ast \= equation(_, _),
    hole_count(Ast, no_holes),
    provenance_term(Spans, Span),
    compile_tree(Ast, expr_1_value, Span, Facts),
    append(Facts, [asks(result,expr_1_value)], Program),
    Receipt = compile{route:standards_router,target:expr_1_value,recovered:false}.

hole_count(Tree, Class) :-
    findall(hole, tree_hole(Tree), Holes),
    hole_cardinality(Holes, Class).

tree_hole(hole).
tree_hole(equation(Left, Right)) :- tree_hole(Left) ; tree_hole(Right).
tree_hole(comparison(Left, _, Right)) :- tree_hole(Left) ; tree_hole(Right).
tree_hole(comparison_chain(Left, _, Middle, _, Right)) :-
    tree_hole(Left) ; tree_hole(Middle) ; tree_hole(Right).
tree_hole(add(Left, Right)) :- tree_hole(Left) ; tree_hole(Right).
tree_hole(subtract(Left, Right)) :- tree_hole(Left) ; tree_hole(Right).
tree_hole(multiply(Left, Right)) :- tree_hole(Left) ; tree_hole(Right).
tree_hole(divide(Left, Right)) :- tree_hole(Left) ; tree_hole(Right).
tree_hole(mixed(Whole, Fraction)) :- tree_hole(Whole) ; tree_hole(Fraction).

hole_cardinality([], no_holes).
hole_cardinality([hole], one_hole).
hole_cardinality([hole,hole|_], multiple_holes).

compile_missing_comparison(Left, Relation, Right, Span, Program,
                           expr_1_missing) :-
    comparison_side_name(Left, expr_1_comparison_left, Span,
                         LeftName, LeftFacts),
    comparison_side_name(Right, expr_1_comparison_right, Span,
                         RightName, RightFacts),
    append([LeftFacts, RightFacts,
            [relation(expr_1_missing,
                      comparison_demand(Relation, LeftName, RightName), Span),
             asks(result,expr_1_missing)]], Program).

comparison_side_name(hole, _KnownName, _Span, expr_1_missing,
                     [quantity(expr_1_missing,unknown,number)]) :- !.
comparison_side_name(Tree, KnownName, Span, KnownName, Facts) :-
    compile_tree(Tree, KnownName, Span, Facts).

compile_missing_comparison_chain(Left, FirstRelation, Middle,
                                 SecondRelation, Right, Span, Program,
                                 expr_1_missing) :-
    comparison_side_name(Left, expr_1_comparison_left, Span,
                         LeftName, LeftFacts),
    comparison_side_name(Middle, expr_1_comparison_middle, Span,
                         MiddleName, MiddleFacts),
    comparison_side_name(Right, expr_1_comparison_right, Span,
                         RightName, RightFacts),
    append([LeftFacts, MiddleFacts, RightFacts,
            [relation(expr_1_missing,
                      comparison_chain_demand(
                          comparison(FirstRelation, LeftName, MiddleName),
                          comparison(SecondRelation, MiddleName, RightName)),
                      Span),
             asks(result,expr_1_missing)]], Program).

compile_missing_equation(hole, Expression, Span, Program, expr_1_missing) :-
    Expression \== hole,
    compile_tree(Expression, expr_1_missing, Span, Facts),
    ensure_unknown_quantity(expr_1_missing, Facts, WithUnknown),
    append(WithUnknown, [asks(result,expr_1_missing)], Program).
compile_missing_equation(Expression, hole, Span, Program, expr_1_missing) :-
    Expression \== hole,
    compile_tree(Expression, expr_1_missing, Span, Facts),
    ensure_unknown_quantity(expr_1_missing, Facts, WithUnknown),
    append(WithUnknown, [asks(result,expr_1_missing)], Program).
compile_missing_equation(Known, MissingExpression, Span, Program, Target) :-
    tree_hole(MissingExpression),
    \+ tree_hole(Known),
    compile_inverse(MissingExpression, Known, Span, Facts, Target),
    append(Facts, [asks(result,Target)], Program).
compile_missing_equation(MissingExpression, Known, Span, Program, Target) :-
    tree_hole(MissingExpression),
    \+ tree_hole(Known),
    compile_inverse(MissingExpression, Known, Span, Facts, Target),
    append(Facts, [asks(result,Target)], Program).

compile_inverse(add(hole, KnownPart), Total, Span, Facts, expr_1_missing) :-
    compile_binary_inverse(Total, KnownPart, difference,
                           expr_1_missing, Span, Facts).
compile_inverse(add(KnownPart, hole), Total, Span, Facts, expr_1_missing) :-
    compile_binary_inverse(Total, KnownPart, difference,
                           expr_1_missing, Span, Facts).
compile_inverse(subtract(hole, KnownPart), Difference, Span, Facts,
                expr_1_missing) :-
    compile_binary_inverse(Difference, KnownPart, sum,
                           expr_1_missing, Span, Facts).
compile_inverse(subtract(Minuend, hole), Difference, Span, Facts,
                expr_1_missing) :-
    compile_binary_inverse(Minuend, Difference, difference,
                           expr_1_missing, Span, Facts).
compile_inverse(multiply(hole, KnownFactor), Product, Span, Facts,
                expr_1_missing) :-
    compile_binary_inverse(Product, KnownFactor, quotient,
                           expr_1_missing, Span, Facts).
compile_inverse(multiply(KnownFactor, hole), Product, Span, Facts,
                expr_1_missing) :-
    compile_binary_inverse(Product, KnownFactor, quotient,
                           expr_1_missing, Span, Facts).
compile_inverse(divide(hole, Divisor), Quotient, Span, Facts,
                expr_1_missing) :-
    compile_binary_inverse(Quotient, Divisor, scale,
                           expr_1_missing, Span, Facts).
compile_inverse(divide(Dividend, hole), Quotient, Span, Facts,
                expr_1_missing) :-
    compile_binary_inverse(Dividend, Quotient, quotient,
                           expr_1_missing, Span, Facts).

compile_binary_inverse(Left, Right, RecipeKind, Target, Span, Facts) :-
    compile_tree(Left, expr_1_equation_value, Span, LeftFacts),
    compile_tree(Right, expr_1_known_part, Span, RightFacts),
    recipe(RecipeKind, expr_1_equation_value, expr_1_known_part, Recipe),
    append([LeftFacts, RightFacts,
            [quantity(Target,unknown,number),relation(Target,Recipe,Span)]], Facts).

compile_tree(literal(Value), Name, _Span, [quantity(Name,Value,number)]).
compile_tree(mixed(literal(Whole), literal(Fraction)), Name, Span, Facts) :-
    child_name(Name, whole, WholeName),
    child_name(Name, fraction, FractionName),
    Facts = [quantity(WholeName,Whole,number),
             quantity(FractionName,Fraction,number),
             quantity(Name,unknown,number),
             relation(Name,sum([WholeName,FractionName]),Span)].
compile_tree(add(Left, Right), Name, Span, Facts) :-
    compile_binary(Left, Right, sum, Name, Span, Facts).
compile_tree(subtract(Left, Right), Name, Span, Facts) :-
    compile_binary(Left, Right, difference, Name, Span, Facts).
compile_tree(multiply(Left, Right), Name, Span, Facts) :-
    compile_binary(Left, Right, scale, Name, Span, Facts).
compile_tree(divide(Left, Right), Name, Span, Facts) :-
    compile_binary(Left, Right, quotient, Name, Span, Facts).

compile_binary(Left, Right, RecipeKind, Name, Span, Facts) :-
    child_name(Name, left, LeftName),
    child_name(Name, right, RightName),
    compile_tree(Left, LeftName, Span, LeftFacts),
    compile_tree(Right, RightName, Span, RightFacts),
    recipe(RecipeKind, LeftName, RightName, Recipe),
    append([LeftFacts, RightFacts,
            [quantity(Name,unknown,number),relation(Name,Recipe,Span)]], Facts).

recipe(sum, Left, Right, sum([Left,Right])).
recipe(difference, Left, Right, difference(Left,Right)).
recipe(scale, Left, Right, scale(Left,Right)).
recipe(quotient, Left, Right, quotient(Left,Right)).

child_name(Parent, Role, Child) :-
    atomic_list_concat([Parent,Role], '_', Child).

ensure_unknown_quantity(Name, Facts, Facts) :-
    memberchk(quantity(Name,unknown,number), Facts), !.
ensure_unknown_quantity(Name, Facts, [quantity(Name,unknown,number)|Facts]).

provenance_term(Spans, source_segments(SegmentTerms)) :-
    maplist(source_segment_term, Spans, SegmentTerms).

source_segment_term(Span,
                    segment(Path,lines(LineStart,LineEnd),
                            bytes(ByteStart,ByteEnd),sha256(Sha))) :-
    get_dict(path, Span, Path),
    get_dict(line_start, Span, LineStart),
    get_dict(line_end, Span, LineEnd),
    get_dict(byte_start, Span, ByteStart),
    get_dict(byte_end, Span, ByteEnd),
    ( get_dict(sha256, Span, Sha) -> true ; Sha = "" ).

fact_provenance(Program, Spans, Rows) :-
    findall(fact_trace(Index,Fact,Spans),
            nth0(Index, Program, Fact), Rows).

refusal(Source, Reason,
        refused(Reason, receipt{source_statement:Source,program:[],
                                fact_provenance:[]})).

text_string(Text, Text) :- string(Text), !.
text_string(Text, String) :- atom(Text), !, atom_string(Text, String).
text_string(Text, String) :- string_codes(String, Text), !.
text_string(Text, String) :- string_chars(String, Text).

check_printed_expression_reader_pilot :-
    check_ast("142,571 + 2", add(literal(142571),literal(2))),
    check_ast("0.5 + 3.25", add(literal(0.5),literal(3.25))),
    check_ast("1 1/4 - 3/4", subtract(mixed(literal(1),literal(1r4)),
                                      literal(3r4))),
    check_ast("12 / 4", divide(literal(12),literal(4))),
    check_ast("2/5 + 4/9", add(literal(2r5),literal(4r9))),
    check_ast("1. 15 - 10 =", equation(subtract(literal(15),literal(10)),hole)),
    check_ast("2. = 13 - 3", equation(hole,subtract(literal(13),literal(3)))),
    check_ast("• 6 + 4 =", equation(add(literal(6),literal(4)),hole)),
    check_ast("2. 19 = 10 +", equation(literal(19),add(literal(10),hole))),
    Span = _{path:"guide.md",line_start:4,line_end:4,
             byte_start:20,byte_end:29,sha256:"abc"},
    RefValue = [_{antecedent:"Find the value of",kind:"expression"}],
    printed_expression_result("7 + 1", "Find the value of 7 + 1.",
                              RefValue, [Span],
                              parsed(find_value, ValueProgram, _)),
    memberchk(relation(expr_1_value,
                       sum([expr_1_value_left,expr_1_value_right]),_),
              ValueProgram),
    RefMissing = [_{antecedent:"Find the number that makes",kind:"equation"}],
    printed_expression_result("19 = 10 +", "Find the missing number.",
                              RefMissing, [Span],
                              parsed(find_missing_number, MissingProgram, _)),
    memberchk(relation(expr_1_missing,
                       difference(expr_1_equation_value,expr_1_known_part),_),
              MissingProgram),
    RefTruth = [_{antecedent:"Determine whether",kind:"equation"}],
    printed_expression_result("10 + 4 = 10 + 5", "Determine whether it is true.",
                              RefTruth, [Span],
                              parsed(decide_truth, [], _)),
    check_ast("(7 + 1)", add(literal(7),literal(1))),
    check_ast("(2 × 10) + (3 × 5)", add(multiply(literal(2),literal(10)),
                                        multiply(literal(3),literal(5)))),
    check_ast("54- 16 = ?", equation(subtract(literal(54),literal(16)),hole)),
    check_ast("10 = 9 + ___", equation(literal(10),add(literal(9),hole))),
    % Updated receipt: this syntax used to be refused because no checker was
    % registered.  It now parses as a truth claim and the incumbent grounded
    % comparison checker decides it.
    check_ast("100 > 99",
              comparison(literal(100),greater,literal(99))),
    check_math_claim(comparison(100, greater, 99), ComparisonVerdict),
    get_dict(verdict, ComparisonVerdict, "holds"),
    check_ast("5 > __", comparison(literal(5),greater,hole)),
    check_ast("a. 786.2 < ___ < 786.3",
              comparison_chain(literal(786.2),smaller,hole,smaller,
                               literal(786.3))),
    format('check_printed_expression_reader_pilot: ok examples=19 evaluation=checker_only~n').

check_ast(Text, Expected) :-
    printed_expression_ast(Text, Actual),
    Actual =@= Expected, !.
check_ast(Text, Expected) :-
    throw(error(unexpected_expression_ast(Text, Expected),
                check_printed_expression_reader_pilot/0)).
