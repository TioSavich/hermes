/** <module> Conservative natural-language reader for mathematical claims
 *
 * Tokenize explicit arithmetic language and compose registered
 * math_claim_checker terms with a DCG.  This reader does not resolve pronouns,
 * supply omitted operands, or infer an operation from a sequence of numbers.
 * A parse therefore expands the syntactic surface accepted by Hermes without
 * weakening the checker's domain boundary.
 */
:- module(math_claim_language,
          [ math_readings_in_text/2,     % +Text, -Readings
            math_claims_in_text/2,       % +Text, -ClaimTerms
            math_claim_tokens/2         % +Tokens, -ClaimTerms
          ]).

:- use_module(library(error), [must_be/2]).
:- use_module(library(lists), [append/2, list_to_set/2]).
:- use_module(library(porter_stem), [tokenize_atom/2]).


%!  math_claims_in_text(+Text, -ClaimTerms) is det.
%
%   ClaimTerms are ordered by first occurrence and deduplicated.  Text may be
%   an atom, string, or character/code list accepted by tokenize_atom/2.
math_claims_in_text(Text, ClaimTerms) :-
    must_be(text, Text),
    tokenize_atom(Text, RawTokens),
    normalize_tokens(RawTokens, Tokens),
    math_claim_tokens(Tokens, ClaimTerms).


%!  math_readings_in_text(+Text, -Readings) is det.
%
%   Each reading keeps mathematical content separate from pragmatic force.
%   `commitment` is a syntactic classification, not a verdict about the
%   speaker's mental state or entitlement.
math_readings_in_text(Text, Readings) :-
    must_be(text, Text),
    tokenize_atom(Text, RawTokens),
    normalize_tokens(RawTokens, Tokens),
    readings_from_tokens(Tokens, Readings).


%!  math_claim_tokens(+Tokens, -ClaimTerms) is det.
%
%   Scan every token boundary so a claim can occur inside a longer student
%   sentence.  Each grammar rule itself must consume a complete explicit
%   relation; surrounding prose is never treated as an operand.
math_claim_tokens(Tokens, ClaimTerms) :-
    readings_from_tokens(Tokens, Readings),
    ordered_reading_terms(Readings, [], ClaimTerms).

ordered_reading_terms([], _, []).
ordered_reading_terms([Reading|Readings], Seen, Terms) :-
    Term = Reading.claim,
    ( get_dict(sequence, Reading, equation_chain)
    -> Terms = [Term|MoreTerms],
       ordered_reading_terms(Readings, Seen, MoreTerms)
    ; memberchk(Term, Seen)
    -> ordered_reading_terms(Readings, Seen, Terms)
    ; Terms = [Term|MoreTerms],
      ordered_reading_terms(Readings, [Term|Seen], MoreTerms)
    ).

readings_from_tokens(Tokens, Readings) :-
    findall(Candidate,
            claim_candidate(Tokens, Candidate),
            Candidates0),
    predsort(compare_candidates, Candidates0, Candidates),
    select_nonoverlapping(Candidates, 0, Selected),
    maplist(candidate_readings(Tokens), Selected, ReadingGroups),
    append(ReadingGroups, Readings).

claim_candidate(Tokens,
                candidate(Start, End, Rank, Payload, Polarity, SurfaceTokens)) :-
    append(Prefix, Suffix, Tokens),
    Suffix \== [],
    length(Prefix, Start),
    phrase(claim_payload(Payload, Polarity), Suffix, Rest),
    append(SurfaceTokens, Rest, Suffix),
    SurfaceTokens \== [],
    length(SurfaceTokens, Length),
    End is Start + Length,
    payload_rank(Payload, Rank).

claim_payload(equation_chain(Sides, Links), positive) -->
    equation_chain(Sides, Links).
claim_payload(Term, Polarity) -->
    math_clause(Term, Polarity).

term_rank(arithmetic_equation(_, _), 10) :- !.
term_rank(proportion_statement(_, _), 5) :- !.
term_rank(ratio_statement(_), 5) :- !.
term_rank(_, 0).

payload_rank(equation_chain(_, _), 20) :- !.
payload_rank(Term, Rank) :-
    term_rank(Term, Rank).

compare_candidates(Order,
                   candidate(S1,E1,R1,T1,P1,_),
                   candidate(S2,E2,R2,T2,P2,_)) :-
    compare(StartOrder, S1, S2),
    ( StartOrder \== (=)
    -> Order = StartOrder
    ; compare(EndOrder, E2, E1),
      ( EndOrder \== (=)
      -> Order = EndOrder
      ; compare(RankOrder, R1, R2),
        ( RankOrder \== (=)
        -> Order = RankOrder
        ; compare(Order, T1-P1, T2-P2)
        )
      )
    ).

select_nonoverlapping([], _, []).
select_nonoverlapping([Candidate|Rest], Cursor, Selected) :-
    Candidate = candidate(Start, End, _, _, _, _),
    ( Start >= Cursor
    -> Selected = [Candidate|Tail],
       select_nonoverlapping(Rest, End, Tail)
    ;  select_nonoverlapping(Rest, Cursor, Selected)
    ).

candidate_readings(Tokens,
                   candidate(Start,_,_,equation_chain(Sides, Links),
                             Polarity,_),
                   Readings) :-
    !,
    length(Links, ChainLength),
    chain_readings(Tokens, Start, Sides, Links, Polarity,
                   1, ChainLength, Readings).
candidate_readings(Tokens, Candidate, [Reading]) :-
    candidate_reading(Tokens, Candidate, Reading).

candidate_reading(Tokens,
                  candidate(Start,End,_,Term,Polarity,SurfaceTokens),
                  Reading) :-
    classify_embedding(Tokens, Start, End, SurfaceTokens,
                       Mode, Embedding, Commitment),
    argument_metadata(Term, SurfaceTokens, Start,
                      ArgumentBindings, InferredArguments, Units),
    referent_metadata(SurfaceTokens, Start,
                      AntecedentCandidates, UnresolvedReferents),
    atomic_list_concat(SurfaceTokens, ' ', Surface),
    term_string(Term, ClaimText, [quoted(true), numbervars(true)]),
    Reading = _{ claim: Term,
                 claim_text: ClaimText,
                 normalized_surface: Surface,
                 token_start: Start,
                 token_end: End,
                 polarity: Polarity,
                 mode: Mode,
                 embedding: Embedding,
                 commitment: Commitment,
                 argument_bindings: ArgumentBindings,
                 inferred_arguments: InferredArguments,
                 units: Units,
                 antecedent_candidates: AntecedentCandidates,
                 unresolved_referents: UnresolvedReferents }.

chain_readings(_, _, [_], [], _, _, _, []).
chain_readings(Tokens, Start,
               [side(Left, LeftTokens),side(Right, RightTokens)|MoreSides],
               [LinkTokens|MoreLinks], Polarity,
               Index, ChainLength, [Reading|Readings]) :-
    length(LeftTokens, LeftLength),
    length(LinkTokens, LinkLength),
    length(RightTokens, RightLength),
    End is Start + LeftLength + LinkLength + RightLength,
    append([LeftTokens, LinkTokens, RightTokens], SurfaceTokens),
    Term = arithmetic_equation(Left, Right),
    candidate_reading(
        Tokens,
        candidate(Start, End, 10, Term, Polarity, SurfaceTokens),
        Reading0),
    Reading = Reading0.put(_{ sequence: equation_chain,
                             sequence_index: Index,
                             sequence_length: ChainLength }),
    NextStart is Start + LeftLength + LinkLength,
    NextIndex is Index + 1,
    chain_readings(Tokens, NextStart,
                   [side(Right, RightTokens)|MoreSides],
                   MoreLinks, Polarity,
                   NextIndex, ChainLength, Readings).

argument_metadata(Term, SurfaceTokens, Start,
                  ArgumentBindings, InferredArguments, Units) :-
    surface_values(SurfaceTokens, 0, SurfaceValues),
    length(SurfaceValues, Count),
    argument_roles(Term, Count, Roles),
    bindings_from_values(SurfaceValues, Roles, Start, ArgumentBindings),
    inferred_arguments(Term, SurfaceTokens, InferredArguments),
    findall(Unit,
            ( member(Binding, ArgumentBindings),
              Unit = Binding.unit,
              Unit \== none
            ),
            Units0),
    list_to_set(Units0, Units).

surface_values([], _, []).
surface_values(Tokens, Offset, [Value|Values]) :-
    best_surface_value(Tokens, Offset, Value, Length),
    !,
    length(Consumed, Length),
    append(Consumed, Rest, Tokens),
    NextOffset is Offset + Length,
    surface_values(Rest, NextOffset, Values).
surface_values([_|Rest], Offset, Values) :-
    NextOffset is Offset + 1,
    surface_values(Rest, NextOffset, Values).

best_surface_value(Tokens, Offset, Best, Length) :-
    findall(value_span(CapturedLength, Value, Captured, Unit),
            ( phrase(value(Value), Tokens, Rest),
              append(Captured, Rest, Tokens),
              Captured \== [],
              length(Captured, CapturedLength),
              following_unit(Rest, Unit)
            ),
            Candidates),
    Candidates \== [],
    predsort(compare_value_spans, Candidates,
             [value_span(Length, Value, Captured, Unit)|_]),
    End is Offset + Length,
    atomic_list_concat(Captured, ' ', SurfaceAtom),
    atom_string(SurfaceAtom, Surface),
    binding_value_text(Value, ValueText),
    Best = surface_value(ValueText, Surface, Offset, End, Unit).

compare_value_spans(Order,
                    value_span(Length1,Value1,_,_),
                    value_span(Length2,Value2,_,_)) :-
    compare(LengthOrder, Length2, Length1),
    ( LengthOrder == (=)
    -> compare(Order, Value1, Value2)
    ;  Order = LengthOrder
    ).

following_unit([Token|_], Unit) :-
    measurement_unit(Token, Unit),
    !.
following_unit(_, none).

binding_value_text(Value, Text) :-
    value_expression(Value, Expression),
    term_string(Expression, Text, [quoted(true), numbervars(true)]).

bindings_from_values([], [], _, []).
bindings_from_values(
    [surface_value(Value,Surface,LocalStart,LocalEnd,Unit)|Values],
    [Role|Roles], Start,
    [argument{ role: Role,
               value: Value,
               surface: Surface,
               token_start: TokenStart,
               token_end: TokenEnd,
               unit: Unit,
               support: explicit }|Bindings]) :-
    TokenStart is Start + LocalStart,
    TokenEnd is Start + LocalEnd,
    bindings_from_values(Values, Roles, Start, Bindings).

argument_roles(arithmetic_equation(_, Right), Count, Roles) :-
    !,
    arithmetic_right_arity(Right, Count, RightCount),
    LeftCount is Count - RightCount,
    numbered_roles(left_operand, LeftCount, LeftRoles),
    right_roles(RightCount, RightRoles),
    append(LeftRoles, RightRoles, Roles).
argument_roles(sum(_,_,_), 3, [addend_1,addend_2,total]) :- !.
argument_roles(subtraction(_,_,_), 3, [minuend,subtrahend,difference]) :- !.
argument_roles(equivalence(_,_), 2, [left_fraction,right_fraction]) :- !.
argument_roles(comparison(_,_,_), 2, [left_quantity,right_quantity]) :- !.
argument_roles(fraction_of(_,_,_), 3,
               [fractional_part,whole_quantity,result]) :- !.
argument_roles(fraction_sum(_,_,_), 3,
               [left_addend,right_addend,result]) :- !.
argument_roles(multiplication(_,_,_), 3,
               [left_factor,right_factor,product]) :- !.
argument_roles(difference(_,_,_), 3,
               [minuend,subtrahend,difference]) :- !.
argument_roles(ratio_statement(_), 2, [antecedent,consequent]) :- !.
argument_roles(proportion_statement(_,_), 4,
               [first_antecedent,first_consequent,
                second_antecedent,second_consequent]) :- !.
argument_roles(_, Count, Roles) :-
    numbered_roles(argument, Count, Roles).

arithmetic_right_arity(Right, Count, RightCount) :-
    surface_expression_arity(Right, Proposed),
    Maximum is max(1, Count - 1),
    RightCount is min(Proposed, Maximum).

surface_expression_arity(Expression, Count) :-
    compound(Expression),
    Expression =.. [Operator, Left, Right],
    memberchk(Operator, [+, -, *]),
    !,
    surface_expression_arity(Left, LeftCount),
    surface_expression_arity(Right, RightCount),
    Count is LeftCount + RightCount.
surface_expression_arity(_, 1).

numbered_roles(_, 0, []) :- !.
numbered_roles(Prefix, Count, Roles) :-
    findall(Role,
            ( between(1, Count, Index),
              atomic_list_concat([Prefix,Index], '_', Role)
            ),
            Roles).

right_roles(1, [right_side]) :- !.
right_roles(Count, Roles) :-
    numbered_roles(right_operand, Count, Roles).

inferred_arguments(arithmetic_equation(Percentage/100*_, _), SurfaceTokens,
                   [argument{ role: percent_denominator,
                              value: "100",
                              support: inferred,
                              source_span: none,
                              reason: "percent normalization" }]) :-
    memberchk(percent, SurfaceTokens),
    number(Percentage),
    !.
inferred_arguments(_, _, []).

referent_metadata(SurfaceTokens, Start,
                  AntecedentCandidates, UnresolvedReferents) :-
    findall(Referent,
            unresolved_referent(SurfaceTokens, Start, Referent),
            UnresolvedReferents),
    findall(Candidate,
            antecedent_candidate(SurfaceTokens, Start, Candidate),
            AntecedentCandidates).

unresolved_referent(Tokens, Start,
                    _{ token: Token,
                       token_start: TokenStart,
                       token_end: TokenEnd,
                       resolution: unresolved }) :-
    nth0(Index, Tokens, Token),
    anaphor_token(Token),
    TokenStart is Start + Index,
    TokenEnd is TokenStart + 1.

antecedent_candidate(Tokens, Start,
                     _{ referent: Token,
                        referent_token_start: ReferentStart,
                        token_start: CandidateStart,
                        token_end: CandidateEnd,
                        normalized_surface: Surface,
                        status: candidate }) :-
    nth0(Index, Tokens, Token),
    anaphor_token(Token),
    length(Prefix, Index),
    append(Prefix, _, Tokens),
    bounded_math_prefix(Prefix, CandidateTokens, LocalStart),
    CandidateTokens \== [],
    surface_values(CandidateTokens, 0, Values),
    Values \== [],
    ReferentStart is Start + Index,
    CandidateStart is Start + LocalStart,
    length(CandidateTokens, CandidateLength),
    CandidateEnd is CandidateStart + CandidateLength,
    atomic_list_concat(CandidateTokens, ' ', SurfaceAtom),
    atom_string(SurfaceAtom, Surface).

bounded_math_prefix(Prefix, CandidateTokens, Start) :-
    strip_trailing_reference_punctuation(Prefix, Clean),
    length(Clean, Length),
    Keep is min(12, Length),
    Start is Length - Keep,
    length(Dropped, Start),
    append(Dropped, CandidateTokens, Clean).

strip_trailing_reference_punctuation(Prefix, Clean) :-
    reverse(Prefix, Reversed),
    drop_reference_punctuation(Reversed, Trimmed),
    reverse(Trimmed, Clean).

drop_reference_punctuation([Token|Rest], Trimmed) :-
    reference_punctuation(Token),
    !,
    drop_reference_punctuation(Rest, Trimmed).
drop_reference_punctuation(Tokens, Tokens).

reference_punctuation(',').
reference_punctuation(';').
reference_punctuation(':').

anaphor_token(it).
anaphor_token(this).
anaphor_token(that).
anaphor_token(which).
anaphor_token(them).
anaphor_token(those).

classify_embedding(Tokens, Start, End, SurfaceTokens,
                   Mode, Embedding, Commitment) :-
    length(Before, Start), append(Before, _, Tokens),
    length(Through, End), append(Through, After, Tokens),
    sentence_tail(Before, Prefix),
    ( inline_report(SurfaceTokens)
    -> Mode = reported, Embedding = [indirect_report], Commitment = attributed
    ; quoted_prefix(Prefix)
    -> Mode = quoted, Embedding = [direct_quotation], Commitment = attributed
    ; reported_prefix(Prefix)
    -> Mode = reported, Embedding = [indirect_report], Commitment = attributed
    ; interrogative_context(Prefix, After)
    -> Mode = queried, Embedding = [interrogative], Commitment = queried
    ; tentative_prefix(Prefix)
    -> Mode = tentative, Embedding = [epistemic_modal], Commitment = proposed
    ; necessity_prefix(Prefix)
    -> Mode = asserted, Embedding = [necessity_modal], Commitment = undertaken
    ; tentative_surface(SurfaceTokens)
    -> Mode = tentative, Embedding = [epistemic_modal], Commitment = proposed
    ; Mode = asserted, Embedding = [], Commitment = undertaken
    ).

sentence_tail(Tokens, Tail) :-
    reverse(Tokens, Reversed),
    take_until_boundary(Reversed, RevTail),
    reverse(RevTail, Tail).

take_until_boundary([], []).
take_until_boundary([Token|_], []) :- sentence_boundary(Token), !.
take_until_boundary([Token|Rest], [Token|Tail]) :-
    take_until_boundary(Rest, Tail).

sentence_boundary('.').
sentence_boundary('!').
sentence_boundary('?').
sentence_boundary(';').

quoted_prefix(Prefix) :-
    include(quote_token, Prefix, Quotes),
    length(Quotes, Count),
    1 is Count mod 2.

quote_token('\'').
quote_token('"').

reported_prefix(Prefix) :-
    contains_sequence(Prefix, [said,that]);
    contains_sequence(Prefix, [says,that]);
    contains_sequence(Prefix, [told,me,that]);
    contains_sequence(Prefix, [i,figured,that]);
    contains_sequence(Prefix, [we,figured,that]);
    contains_sequence(Prefix, [i,worked,out,that]);
    contains_sequence(Prefix, [according,to]).

tentative_prefix(Prefix) :-
    memberchk(maybe, Prefix); memberchk(perhaps, Prefix);
    memberchk(probably, Prefix); memberchk(possibly, Prefix);
    contains_sequence(Prefix, [i,think]);
    contains_sequence(Prefix, [i,guess]);
    contains_sequence(Prefix, [i,believe]);
    contains_sequence(Prefix, [we,can,say]);
    contains_sequence(Prefix, [it,seems]).

necessity_prefix(Prefix) :-
    memberchk(must, Prefix);
    contains_sequence(Prefix, [has,to]);
    contains_sequence(Prefix, [have,to]).

interrogative_context(Prefix, After) :-
    memberchk('?', After), !;
    Prefix = [First|_], memberchk(First, [is,are,does,do,did,can,could,would,should]).

contains_sequence(List, Sequence) :- append(_, Tail, List), append(Sequence, _, Tail), !.

inline_report(Tokens) :-
    contains_sequence(Tokens, [i,said,that,it,was]);
    contains_sequence(Tokens, [i,said,it,was]);
    contains_sequence(Tokens, [i,thought,that,it,was]);
    contains_sequence(Tokens, [i,thought,it,was]).

tentative_surface(Tokens) :-
    contains_sequence(Tokens, [would,be]).


% Preserve the old DCG entry point for callers that want one positive claim.
math_claim(Term) --> math_clause(Term, positive).

math_clause(Term, negative) -->
    value(A), binary_operator(Op), value(B), [is,not], value(C),
    { compose_binary(Op, A, B, C, Term) }.
math_clause(Term, negative) -->
    value(A), [is,not,equal,to], value(B),
    { compose_equality(A, B, Term) }.
math_clause(Term, positive) --> inverted_question(Term).
math_clause(Term, positive) --> positive_math_claim(Term).

inverted_question(Term) -->
    [is], value(A), binary_operator(Op), value(B), [equal,to], value(C),
    { compose_binary(Op, A, B, C, Term) }.
inverted_question(Term) -->
    [is], value(A), [equal,to], value(B),
    { compose_equality(A, B, Term) }.

positive_math_claim(Term) --> active_addition(Term).
positive_math_claim(Term) --> active_subtraction(Term).
positive_math_claim(Term) --> active_multiplication(Term).
positive_math_claim(Term) --> active_division(Term).
positive_math_claim(Term) --> named_operation(Term).
positive_math_claim(Term) --> same_unit_total(Term).
positive_math_claim(Term) --> percentage_of_claim(Term).
positive_math_claim(Term) --> fraction_of_claim(Term).
positive_math_claim(Term) --> binary_claim(Term).
positive_math_claim(Term) --> comparison_claim(Term).
positive_math_claim(Term) --> proportion_claim(Term).
positive_math_claim(Term) --> ratio_claim(Term).
positive_math_claim(Term) --> equality_claim(Term).
positive_math_claim(Term) --> expression_equation(Term).


normalize_tokens([], []).
normalize_tokens([Word, '\'', s|Rest], [Contracted|Tokens]) :-
    atom(Word),
    !,
    downcase_atom(Word, Lower),
    atom_concat(Lower, s, Contracted),
    normalize_tokens(Rest, Tokens).
normalize_tokens([Token0|Rest], [Token|Tokens]) :-
    ( atom(Token0) -> downcase_atom(Token0, Token) ; Token = Token0 ),
    normalize_tokens(Rest, Tokens).


% ---------------------------------------------------------------------------
% Claim grammar and compositional term construction
% ---------------------------------------------------------------------------

active_addition(Term) -->
    [added], additive_whole_list(Values), action_result_link, integer_value(Result),
    { sum_expression(Values, Expression),
      Term = arithmetic_equation(Expression, Result) }.
active_addition(Term) -->
    [add], additive_whole_list(Values), action_result_link, integer_value(Result),
    { sum_expression(Values, Expression),
      Term = arithmetic_equation(Expression, Result) }.
active_addition(Term) -->
    [added], value(A), [and], value(B), action_result_link, value(C),
    { compose_binary(add, A, B, C, Term) }.
active_addition(Term) -->
    [add], value(A), [and], value(B), action_result_link, value(C),
    { compose_binary(add, A, B, C, Term) }.

active_subtraction(Term) -->
    [subtracted], value(B), [from], value(A), action_result_link, value(C),
    { compose_binary(subtract, A, B, C, Term) }.
active_subtraction(Term) -->
    [took], value(B), [away,from], value(A), action_result_link, value(C),
    { compose_binary(subtract, A, B, C, Term) }.

active_multiplication(Term) -->
    [multiplied], value(A), [by], value(B), action_result_link, value(C),
    { compose_binary(multiply, A, B, C, Term) }.

active_division(Term) -->
    [divided], value(A), [by], value(B), action_result_link, value(C),
    { compose_binary(divide, A, B, C, Term) }.

named_operation(Term) -->
    [the,sum,of], value(A), [and], value(B), result_link, value(C),
    { compose_binary(add, A, B, C, Term) }.
named_operation(Term) -->
    [the,difference,between], value(A), [and], value(B), result_link, value(C),
    { compose_binary(subtract, A, B, C, Term) }.
named_operation(Term) -->
    [the,product,of], value(A), [and], value(B), result_link, value(C),
    { compose_binary(multiply, A, B, C, Term) }.
named_operation(Term) -->
    [the,quotient,of], value(A), [and], value(B), result_link, value(C),
    { compose_binary(divide, A, B, C, Term) }.

same_unit_total(sum(A, B, C)) -->
    measured_whole(A, Unit), [and], measured_whole(B, Unit),
    total_link, measured_whole(C, Unit), optional_total.
same_unit_total(arithmetic_equation(Expression, Total)) -->
    measured_whole_list(Values, Unit),
    total_link, measured_whole(Total, Unit), optional_total,
    { sum_expression(Values, Expression) }.

percentage_of_claim(arithmetic_equation(Percentage/100*Quantity, Result)) -->
    value(PercentageValue), [percent,of], value(QuantityValue),
    result_link, value(ResultValue),
    { value_expression(PercentageValue, Percentage),
      value_expression(QuantityValue, Quantity),
      value_expression(ResultValue, Result) }.

fraction_of_claim(fraction_of(N, fraction(A,B), Result)) -->
    fraction_value(fraction(A,B)), [of], integer_value(N),
    result_link, integer_value(Result).

binary_claim(Term) -->
    value(A), binary_operator(Op), value(B), result_link, value(C),
    { compose_binary(Op, A, B, C, Term) }.
binary_claim(Term) -->
    value(A), binary_operator(Op), value(B), inline_report_link, value(C),
    { compose_binary(Op, A, B, C, Term) }.

comparison_claim(comparison(A, Relation, B)) -->
    value(Left), comparison_link(Relation), value(Right),
    { comparison_operand(Left, A), comparison_operand(Right, B) }.

equality_claim(Term) -->
    value(A), equality_link, value(B),
    { compose_equality(A, B, Term) }.

expression_equation(arithmetic_equation(Left, Right)) -->
    arithmetic_expression(Left), expression_result_link, arithmetic_side(Right).

ratio_claim(ratio_statement(ratio(A, B))) -->
    [the,ratio,is], value(Left), [to], value(Right),
    { value_expression(Left, A),
      value_expression(Right, B) }.

proportion_claim(proportion_statement(ratio(A, B), ratio(C, D))) -->
    value(First), [is,to], value(Second), [as],
    value(Third), [is,to], value(Fourth),
    { value_expression(First, A),
      value_expression(Second, B),
      value_expression(Third, C),
      value_expression(Fourth, D) }.

equation_chain(
    [side(First,FirstTokens),side(Second,SecondTokens),
     side(Third,ThirdTokens)|MoreSides],
    [FirstLink,SecondLink|MoreLinks]) -->
    captured_arithmetic_expression(First, FirstTokens),
    captured_chain_link(FirstLink),
    captured_arithmetic_expression(Second, SecondTokens),
    captured_chain_link(SecondLink),
    captured_arithmetic_expression(Third, ThirdTokens),
    equation_chain_tail(MoreSides, MoreLinks).

equation_chain_tail([side(Expression,Tokens)|MoreSides],
                    [LinkTokens|MoreLinks]) -->
    captured_chain_link(LinkTokens),
    captured_arithmetic_expression(Expression, Tokens),
    equation_chain_tail(MoreSides, MoreLinks).
equation_chain_tail([], []) --> [].

captured_arithmetic_expression(Expression, Captured, Input, Rest) :-
    phrase(arithmetic_expression(Expression), Input, Rest),
    append(Captured, Rest, Input),
    Captured \== [].

captured_chain_link(Captured, Input, Rest) :-
    phrase(expression_result_link, Input, Rest),
    append(Captured, Rest, Input),
    Captured \== [].


binary_operator(add) --> [plus].
binary_operator(add) --> ['+'].
binary_operator(subtract) --> [minus].
binary_operator(subtract) --> ['-'].
binary_operator(multiply) --> [times].
binary_operator(multiply) --> [multiplied,by].
binary_operator(multiply) --> ['*'].
binary_operator(multiply) --> ['x'].
binary_operator(divide) --> [divided,by].
binary_operator(divide) --> ['divided','by'].
binary_operator(divide) --> ['/'].

result_link --> [is].
result_link --> [was].
result_link --> [equals].
result_link --> [equal,to].
result_link --> ['='].
result_link --> [makes].
result_link --> [gives].
result_link --> [results,in].
result_link --> [would,be].

equality_link --> [is,equal,to].
equality_link --> [is,the,same,as].
equality_link --> [equals].
equality_link --> ['='].

expression_result_link --> equality_link.
expression_result_link --> [is].

action_result_link --> [and,got].
action_result_link --> [and,get].
action_result_link --> [to,get].
action_result_link --> [which,gives].
action_result_link --> [which,is].
action_result_link --> result_link.

inline_report_link --> [',',i,said,that,it,was].
inline_report_link --> [',',i,said,it,was].
inline_report_link --> [',',i,thought,that,it,was].
inline_report_link --> [',',i,thought,it,was].
inline_report_link --> [',',which,would,be].
inline_report_link --> [',',which,is].
inline_report_link --> [',',which,means].
inline_report_link --> [or,just,',',which,is].

comparison_link(greater) --> [is,greater,than].
comparison_link(greater) --> [is,more,than].
comparison_link(greater) --> ['>'].
comparison_link(smaller) --> [is,less,than].
comparison_link(smaller) --> [is,smaller,than].
comparison_link(smaller) --> ['<'].

total_link --> [',',so,thats].
total_link --> [so,thats].
total_link --> [',',so,that,is].
total_link --> [so,that,is].
total_link --> [',',so,the,total,is].
total_link --> [so,the,total,is].
total_link --> [',',for,a,total,of].
total_link --> [for,a,total,of].

optional_total --> [total].
optional_total --> [].

additive_whole_list([A,B,C|Rest]) -->
    integer_value(A), additive_separator,
    integer_value(B), additive_separator,
    integer_value(C), additive_whole_rest(Rest).

additive_whole_rest([N|Rest]) -->
    additive_separator, integer_value(N), additive_whole_rest(Rest).
additive_whole_rest([]) --> [].

additive_separator --> [',',and].
additive_separator --> [','].
additive_separator --> [and].

measured_whole_list([A,B,C|Rest], Unit) -->
    measured_whole(A, Unit), additive_separator,
    measured_whole(B, Unit), additive_separator,
    measured_whole(C, Unit), measured_whole_rest(Rest, Unit).

measured_whole_rest([N|Rest], Unit) -->
    additive_separator, measured_whole(N, Unit),
    measured_whole_rest(Rest, Unit).
measured_whole_rest([], _Unit) --> [].


% ---------------------------------------------------------------------------
% Numeric phrases
% ---------------------------------------------------------------------------

value(mixed(W,N,D)) -->
    integer_value(W), [and], fraction_value(fraction(N,D)).
value(frac(N,D)) --> fraction_value(fraction(N,D)).
value(whole(N)) --> integer_value(N).
value(scalar(N)) -->
    [N],
    { number(N),
      ( float(N) ; N < 0 ) }.

fraction_value(fraction(N,D)) -->
    integer_value(N), ['/'], integer_value(D), { D > 0 }.
fraction_value(fraction(N,D)) -->
    integer_value(N), [DenominatorWord],
    { denominator_word(DenominatorWord, D) }.
fraction_value(fraction(1,D)) -->
    [a, DenominatorWord],
    { denominator_word(DenominatorWord, D) }.

integer_value(N) --> [N], { integer(N), N >= 0 }.
integer_value(N) --> [Word], { small_number_word(Word, N) }.
integer_value(N) --> [TensWord, UnitWord],
    { tens_word(TensWord, Tens), unit_word(UnitWord, Unit), N is Tens + Unit }.
integer_value(N) --> [HundredWord, hundred],
    { unit_word(HundredWord, H), N is H * 100 }.
integer_value(N) --> [HundredWord, hundred, RemainderWord],
    { unit_word(HundredWord, H), small_number_word(RemainderWord, R),
      R > 0, N is H * 100 + R }.
integer_value(N) --> [HundredWord, hundred, and, RemainderWord],
    { unit_word(HundredWord, H), small_number_word(RemainderWord, R),
      R > 0, N is H * 100 + R }.

small_number_word(zero, 0).
small_number_word(one, 1).
small_number_word(two, 2).
small_number_word(three, 3).
small_number_word(four, 4).
small_number_word(five, 5).
small_number_word(six, 6).
small_number_word(seven, 7).
small_number_word(eight, 8).
small_number_word(nine, 9).
small_number_word(ten, 10).
small_number_word(eleven, 11).
small_number_word(twelve, 12).
small_number_word(thirteen, 13).
small_number_word(fourteen, 14).
small_number_word(fifteen, 15).
small_number_word(sixteen, 16).
small_number_word(seventeen, 17).
small_number_word(eighteen, 18).
small_number_word(nineteen, 19).
small_number_word(twenty, 20).
small_number_word(thirty, 30).
small_number_word(forty, 40).
small_number_word(fifty, 50).
small_number_word(sixty, 60).
small_number_word(seventy, 70).
small_number_word(eighty, 80).
small_number_word(ninety, 90).

unit_word(one, 1).
unit_word(two, 2).
unit_word(three, 3).
unit_word(four, 4).
unit_word(five, 5).
unit_word(six, 6).
unit_word(seven, 7).
unit_word(eight, 8).
unit_word(nine, 9).

tens_word(twenty, 20).
tens_word(thirty, 30).
tens_word(forty, 40).
tens_word(fifty, 50).
tens_word(sixty, 60).
tens_word(seventy, 70).
tens_word(eighty, 80).
tens_word(ninety, 90).

denominator_word(half, 2).
denominator_word(halves, 2).
denominator_word(third, 3).
denominator_word(thirds, 3).
denominator_word(fourth, 4).
denominator_word(fourths, 4).
denominator_word(quarter, 4).
denominator_word(quarters, 4).
denominator_word(fifth, 5).
denominator_word(fifths, 5).
denominator_word(sixth, 6).
denominator_word(sixths, 6).
denominator_word(seventh, 7).
denominator_word(sevenths, 7).
denominator_word(eighth, 8).
denominator_word(eighths, 8).
denominator_word(ninth, 9).
denominator_word(ninths, 9).
denominator_word(tenth, 10).
denominator_word(tenths, 10).

measured_whole(N, Unit) -->
    integer_value(N), [SurfaceUnit],
    { measurement_unit(SurfaceUnit, Unit) },
    optional_activity.

optional_activity --> [Activity], { activity_word(Activity) }.
optional_activity --> [].

measurement_unit(hour, hour).
measurement_unit(hours, hour).
measurement_unit(minute, minute).
measurement_unit(minutes, minute).
measurement_unit(day, day).
measurement_unit(days, day).
measurement_unit(dollar, dollar).
measurement_unit(dollars, dollar).
measurement_unit(cent, cent).
measurement_unit(cents, cent).
measurement_unit(mile, mile).
measurement_unit(miles, mile).
measurement_unit(meter, meter).
measurement_unit(meters, meter).
measurement_unit(foot, foot).
measurement_unit(feet, foot).
measurement_unit(inch, inch).
measurement_unit(inches, inch).
measurement_unit(item, item).
measurement_unit(items, item).

activity_word(cleaning).
activity_word(cooking).
activity_word(crafting).
activity_word(tailoring).
activity_word(working).
activity_word(walking).
activity_word(driving).
activity_word(reading).
activity_word(sleeping).
activity_word(spent).


% ---------------------------------------------------------------------------
% Logical-form composition
% ---------------------------------------------------------------------------

compose_binary(add, whole(A), whole(B), whole(C), sum(A,B,C)).
compose_binary(add, frac(A,B), frac(C,D), whole(N),
               fraction_sum(fraction(A,B), fraction(C,D), whole(N))).
compose_binary(add, frac(A,B), frac(C,D), frac(P,Q),
               fraction_sum(fraction(A,B), fraction(C,D), fraction(P,Q))).
compose_binary(subtract, whole(A), whole(B), whole(C), subtraction(A,B,C)).
compose_binary(subtract, frac(A,B), frac(C,D), frac(P,Q),
               difference(fraction(A,B), fraction(C,D), fraction(P,Q))).
compose_binary(multiply, frac(A,B), frac(C,D), frac(P,Q),
               multiplication(fraction(A,B), fraction(C,D), fraction(P,Q))).
compose_binary(multiply, whole(A), frac(C,D), Result,
               multiplication(A, fraction(C,D), Product)) :-
    fraction_product(Result, Product).
compose_binary(Op, A, B, C, arithmetic_equation(Left, Right)) :-
    memberchk(Op, [add,subtract,multiply,divide]),
    value_expression(A, EA), value_expression(B, EB), value_expression(C, Right),
    operation_expression(Op, EA, EB, Left).

compose_equality(frac(A,B), frac(C,D),
                 equivalence(fraction(A,B), fraction(C,D))).
compose_equality(A, B, arithmetic_equation(Left, Right)) :-
    value_expression(A, Left), value_expression(B, Right).

comparison_operand(whole(N), N).
comparison_operand(frac(N,D), fraction(N,D)).

fraction_product(frac(P,Q), fraction(P,Q)).
fraction_product(whole(N), fraction(N,1)).

value_expression(whole(N), N).
value_expression(scalar(N), N).
value_expression(frac(N,D), N/D).
value_expression(mixed(W,N,D), W + N/D).

operation_expression(add, A, B, A+B).
operation_expression(subtract, A, B, A-B).
operation_expression(multiply, A, B, A*B).
operation_expression(divide, A, B, A/B).

sum_expression([First|Rest], Expression) :-
    foldl(add_expression, Rest, First, Expression).

add_expression(Next, Acc, Acc+Next).

arithmetic_expression(Expression) -->
    multiplicative_expression(First),
    additive_tail(First, Expression).

additive_tail(Acc, Expression) -->
    additive_operator(Op), multiplicative_expression(Next),
    { operation_expression(Op, Acc, Next, Acc1) },
    additive_tail(Acc1, Expression).
additive_tail(Expression, Expression) --> [].

multiplicative_expression(Expression) -->
    arithmetic_side(First),
    multiplicative_tail(First, Expression).

multiplicative_tail(Acc, Expression) -->
    multiplicative_operator(Op), arithmetic_side(Next),
    { operation_expression(Op, Acc, Next, Acc1) },
    multiplicative_tail(Acc1, Expression).
multiplicative_tail(Expression, Expression) --> [].

arithmetic_side(Expression) -->
    ['('], arithmetic_expression(Expression), [')'].
arithmetic_side(Expression) --> value(Value), { value_expression(Value, Expression) }.

additive_operator(add) --> [plus].
additive_operator(add) --> ['+'].
additive_operator(subtract) --> [minus].
additive_operator(subtract) --> ['-'].

multiplicative_operator(multiply) --> [times].
multiplicative_operator(multiply) --> ['*'].
multiplicative_operator(multiply) --> ['x'].
multiplicative_operator(divide) --> [divided,by].
multiplicative_operator(divide) --> ['/'].
