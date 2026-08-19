:- encoding(utf8).
/** <module> Reader for flattened Markdown tables
 *
 * Docling preserves the table pipes but flattens line boundaries to spaces.
 * This pilot recovers the rectangular rows those bytes state.  It emits
 * layout and cell observations only; it does not fill blanks, total cells, or
 * evaluate any relation licensed by a table.
 */
:- module(serialized_table_reader_pilot,
          [ serialized_table_reading/3,
            serialized_table_facts/3,
            serialized_table_refusal/2,
            check_serialized_table_reader/0
          ]).

:- use_module(library(pcre)).

%! serialized_table_reading(+Text, -Tables, -Remnants) is semidet.
%
%  Tables are decoded_table/6 terms in surface order.  Their cell terms retain
%  the character offsets needed by serialized_table_facts/3.  Remnant spans
%  name non-whitespace surface outside every recovered table.
serialized_table_reading(Text, Tables, Remnants) :-
    string(Text),
    pipe_tokens(Text, Tokens),
    separator_candidates(Tokens, Candidates),
    Candidates = [_|_],
    decode_candidates(Text, Tokens, Candidates, 1, Tables),
    table_spans(Tables, TableSpans),
    complement_remnants(Text, TableSpans, Remnants).

%! serialized_table_facts(+Tables, -Facts, -FactSpans) is det.
serialized_table_facts(Tables, Facts, FactSpans) :-
    table_facts(Tables, 0, Facts, FactSpans, _).

%! serialized_table_refusal(+Text, -Reason) is semidet.
serialized_table_refusal(Text, labels_without_cells) :-
    table_segment_surface(Text),
    pipe_tokens(Text, Tokens),
    separator_candidates(Tokens, Candidates),
    Candidates = [_|_],
    candidate_limits(Candidates, Tokens, Limits),
    member(candidate_limit(candidate(_, SepStart, Columns), Limit), Limits),
    SepEnd is SepStart + Columns,
    SepEnd >= Limit,
    !.
serialized_table_refusal(Text, cell_stream_not_rectangular) :-
    table_segment_surface(Text),
    \+ serialized_table_reading(Text, _, _).

% A strict structural surface guard: at least one pipe-bounded separator cell.
table_segment_surface(Text) :-
    pipe_tokens(Text, Tokens),
    member(Token, Tokens),
    dash_token(Token),
    !.

pipe_tokens(Text, Tokens) :-
    findall(Pos, sub_string(Text, Pos, 1, _, "|"), Pipes),
    adjacent_pipe_tokens(Text, Pipes, Tokens).

adjacent_pipe_tokens(_Text, [_], []).
adjacent_pipe_tokens(Text, [Left,Right|Pipes],
                     [Token|Tokens]) :-
    cell_token(Text, Left, Right, Token),
    adjacent_pipe_tokens(Text, [Right|Pipes], Tokens).
adjacent_pipe_tokens(_Text, [], []).

cell_token(Text, Left, Right,
           token(Left,Right,Start,End,Surface)) :-
    RawStart is Left + 1,
    RawLength is Right - RawStart,
    sub_string(Text, RawStart, RawLength, _, Raw),
    string_codes(Raw, Codes),
    leading_spaces(Codes, Leading),
    reverse(Codes, Reverse),
    leading_spaces(Reverse, Trailing),
    Start is RawStart + Leading,
    End is Right - Trailing,
    Length is max(0, End - Start),
    sub_string(Text, Start, Length, _, Surface).

leading_spaces([Code|Codes], Count) :-
    code_type(Code, space),
    !,
    leading_spaces(Codes, Rest),
    Count is Rest + 1.
leading_spaces(_, 0).

token_surface(token(_,_,_,_,Surface), Surface).
blank_token(Token) :- token_surface(Token, "").

dash_token(Token) :-
    token_surface(Token, Surface),
    re_match("^:?-{3,}:?$", Surface).

separator_candidates(Tokens, Candidates) :-
    findall(candidate(HeaderStart, SepStart, Columns),
            separator_candidate(Tokens, HeaderStart, SepStart, Columns),
            Candidates).

separator_candidate(Tokens, HeaderStart, SepStart, Columns) :-
    nth0(SepStart, Tokens, Token),
    dash_token(Token),
    ( SepStart =:= 0
    ; Previous is SepStart - 1,
      nth0(Previous, Tokens, PreviousToken),
      \+ dash_token(PreviousToken)
    ),
    dash_run_length(Tokens, SepStart, Columns),
    Columns > 0,
    Boundary is SepStart - 1,
    Boundary >= 0,
    nth0(Boundary, Tokens, BoundaryToken),
    blank_token(BoundaryToken),
    HeaderStart is SepStart - Columns - 1,
    HeaderStart >= 0,
    slice(Tokens, HeaderStart, Columns, HeaderTokens),
    length(HeaderTokens, Columns).

dash_run_length(Tokens, Start, Length) :-
    dash_run_length(Tokens, Start, 0, Length).

dash_run_length(Tokens, Index, Count0, Count) :-
    ( nth0(Index, Tokens, Token), dash_token(Token)
    -> Next is Index + 1,
       Count1 is Count0 + 1,
       dash_run_length(Tokens, Next, Count1, Count)
    ;  Count = Count0
    ).

decode_candidates(Text, Tokens, Candidates, Number, Tables) :-
    candidate_limits(Candidates, Tokens, Limits),
    decode_candidate_limits(Text, Tokens, Limits, Number, Tables).

candidate_limits(Candidates, Tokens, Limits) :-
    length(Tokens, TokenCount),
    candidate_limits_(Candidates, TokenCount, Limits).

candidate_limits_([Candidate], TokenCount,
                  [candidate_limit(Candidate, TokenCount)]).
candidate_limits_([Candidate,Next|Candidates], TokenCount,
                  [candidate_limit(Candidate, NextHeader)|Limits]) :-
    Next = candidate(NextHeader, _, _),
    candidate_limits_([Next|Candidates], TokenCount, Limits).

decode_candidate_limits(_Text, _Tokens, [], _Number, []).
decode_candidate_limits(Text, Tokens,
                        [candidate_limit(Candidate,Limit)|Limits], Number,
                        [Table|Tables]) :-
    decode_candidate(Text, Tokens, Candidate, Limit, Number, Table),
    Next is Number + 1,
    decode_candidate_limits(Text, Tokens, Limits, Next, Tables).

decode_candidate(Text, Tokens,
                 candidate(HeaderStart, SepStart, Columns), Limit, Number,
                 decoded_table(TableId, Columns, HeaderCells, Rows,
                               table_span(TableStart,TableEnd),
                               header_span(HeaderSpanStart,HeaderSpanEnd,
                                           HeaderSurface))) :-
    slice(Tokens, HeaderStart, Columns, HeaderTokens),
    maplist(read_cell, HeaderTokens, HeaderCells),
    SepEnd is SepStart + Columns,
    SepEnd < Limit,
    nth0(SepEnd, Tokens, SeparatorBoundary),
    blank_token(SeparatorBoundary),
    DataStart is SepEnd + 1,
    DataStart =< Limit,
    decode_rows(Tokens, DataStart, Limit, Columns, Rows),
    Rows = [_|_],
    atom_concat(table_, Number, TableId),
    nth0(HeaderStart, Tokens, token(TableStart,_,_,_,_)),
    LastHeaderIndex is HeaderStart + Columns - 1,
    nth0(LastHeaderIndex, Tokens,
         token(_,HeaderRight,_,_,_)),
    HeaderSpanStart = TableStart,
    HeaderSpanEnd is HeaderRight + 1,
    HeaderLength is HeaderSpanEnd - HeaderSpanStart,
    sub_string(Text, HeaderSpanStart, HeaderLength, _, HeaderSurface),
    last(Rows, LastRow),
    last(LastRow, cell(_,_,_,_,LastRight)),
    TableEnd is LastRight + 1,
    sub_string(Text, TableStart, _, _, _).

decode_rows(_Tokens, Limit, Limit, _Columns, []) :- !.
decode_rows(Tokens, Start, Limit, Columns, [Row|Rows]) :-
    End is Start + Columns,
    End =< Limit,
    slice(Tokens, Start, Columns, RowTokens),
    maplist(read_cell, RowTokens, Row),
    ( End =:= Limit
    -> Rows = []
    ; nth0(End, Tokens, Boundary),
      blank_token(Boundary),
      Next is End + 1,
      Next =< Limit,
      decode_rows(Tokens, Next, Limit, Columns, Rows)
    ).

slice(List, Start, Length, Slice) :-
    length(Prefix, Start),
    append(Prefix, Rest, List),
    length(Slice, Length),
    append(Slice, _, Rest).

read_cell(token(Left,Right,Start,End,Surface),
          cell(Reading,Start,End,Surface,Right)) :-
    cell_reading(Surface, Reading),
    Left < Right.

cell_reading("", blank) :- !.
cell_reading(Surface, share(Value,Surface)) :-
    sub_string(Surface, 0, Before, 1, NumberSurface),
    sub_string(Surface, Before, 1, 0, "%"),
    numeric_surface(NumberSurface, Value),
    !.
cell_reading(Surface, numeral(Value,Surface)) :-
    numeric_surface(Surface, Value),
    !.
cell_reading(Surface, words(Surface)).

numeric_surface(Surface, Value) :-
    ( re_match("^[+-]?(?:[0-9]+(?:\\.[0-9]+)?|\\.[0-9]+)$", Surface)
    -> NumberText = Surface
    ; re_match("^[+-]?[0-9]{1,3}(?:,[0-9]{3})+(?:\\.[0-9]+)?$", Surface),
      split_string(Surface, ",", "", Parts),
      atomics_to_string(Parts, NumberText)
    ),
    number_string(Value, NumberText).

table_facts([], Index, [], [], Index).
table_facts([decoded_table(TableId,Columns,HeaderCells,Rows,_,
                           header_span(HeaderStart,HeaderEnd,HeaderText))|Tables],
            Index0, Facts, FactSpans, Index) :-
    maplist(cell_reading_only, HeaderCells, Header),
    length(Rows, RowCount),
    Layout = table_layout(TableId, columns(Columns), rows(RowCount),
                          header(Header)),
    LayoutSpan = fact_span(Index0,HeaderStart,HeaderEnd,HeaderText),
    Index1 is Index0 + 1,
    row_facts(Rows, TableId, 1, Index1, CellFacts, CellSpans, Index2),
    table_facts(Tables, Index2, RestFacts, RestSpans, Index),
    Facts = [Layout|CellFactsAndRest],
    append(CellFacts, RestFacts, CellFactsAndRest),
    FactSpans = [LayoutSpan|CellSpansAndRest],
    append(CellSpans, RestSpans, CellSpansAndRest).

cell_reading_only(cell(Reading,_,_,_,_), Reading).

row_facts([], _TableId, _Row, Index, [], [], Index).
row_facts([Cells|Rows], TableId, Row, Index0, Facts, Spans, Index) :-
    cell_facts(Cells, TableId, Row, 1, Index0,
               RowFacts, RowSpans, Index1),
    NextRow is Row + 1,
    row_facts(Rows, TableId, NextRow, Index1,
              RestFacts, RestSpans, Index),
    append(RowFacts, RestFacts, Facts),
    append(RowSpans, RestSpans, Spans).

cell_facts([], _TableId, _Row, _Col, Index, [], [], Index).
cell_facts([cell(Reading,Start,End,Surface,_)|Cells], TableId, Row, Col,
           Index0,
           [table_cell(TableId,Row,Col,Reading)|Facts],
           [fact_span(Index0,Start,End,Surface)|Spans], Index) :-
    NextCol is Col + 1,
    Index1 is Index0 + 1,
    cell_facts(Cells, TableId, Row, NextCol, Index1,
               Facts, Spans, Index).

table_spans([], []).
table_spans([decoded_table(_,_,_,_,table_span(Start,End),_)|Tables],
            [span(Start,End)|Spans]) :-
    table_spans(Tables, Spans).

complement_remnants(Text, Spans, Remnants) :-
    string_length(Text, Length),
    complement_remnants(Text, Spans, 0, Length, Remnants).

complement_remnants(Text, [], Cursor, Length, Remnants) :-
    trimmed_remnant(Text, Cursor, Length, Remnants).
complement_remnants(Text, [span(Start,End)|Spans], Cursor, Length, Remnants) :-
    trimmed_remnant(Text, Cursor, Start, Here),
    complement_remnants(Text, Spans, End, Length, Rest),
    append(Here, Rest, Remnants).

trimmed_remnant(_Text, Start, End, []) :- Start >= End, !.
trimmed_remnant(Text, Start0, End0, Remnants) :-
    Length0 is End0 - Start0,
    sub_string(Text, Start0, Length0, _, Raw),
    string_codes(Raw, Codes),
    leading_spaces(Codes, Leading),
    reverse(Codes, Reverse),
    leading_spaces(Reverse, Trailing),
    Start is Start0 + Leading,
    End is End0 - Trailing,
    ( Start < End
    -> Length is End - Start,
       sub_string(Text, Start, Length, _, Surface),
       Remnants = [remnant(Start,End,Surface)]
    ;  Remnants = []
    ).

%! check_serialized_table_reader is det.
check_serialized_table_reader :-
    fixture_f1(F1),
    serialized_table_reading(F1, Tables1, []),
    serialized_table_facts(Tables1, Facts1, Spans1),
    Facts1 == [
        table_layout(table_1,columns(2),rows(2),
                     header([words("salt (grams)"),words("honey (grams)")])),
        table_cell(table_1,1,1,numeral(10,"10")),
        table_cell(table_1,1,2,numeral(14,"14")),
        table_cell(table_1,2,1,numeral(25,"25")),
        table_cell(table_1,2,2,numeral(35,"35"))
    ],
    length(Spans1, 5),
    fixture_f2(F2),
    serialized_table_reading(F2, [Table2], [remnant(_,_,"1.")]),
    Table2 = decoded_table(table_1,3,Header2,Rows2,_,_),
    maplist(cell_reading_only, Header2,
            [blank,words("right hand length (cm)"),
             words("right foot length (cm)")]),
    length(Rows2, 5),
    fixture_f3(F3),
    serialized_table_reading(F3, Tables3, []),
    serialized_table_facts(Tables3, Facts3, _),
    memberchk(table_layout(table_1,columns(4),rows(3),_), Facts3),
    aggregate_all(count,
                  member(table_cell(table_1,_,_,blank), Facts3),
                  5),
    fixture_f4(F4),
    serialized_table_reading(F4, Tables4, []),
    length(Tables4, 3),
    maplist(table_shape(2,3), Tables4),
    fixture_f5(F5),
    serialized_table_refusal(F5, labels_without_cells),
    \+ serialized_table_reading(F5, _, _),
    fixture_merged(F6),
    serialized_table_reading(F6, [Table6],
                             [remnant(0,_,"Using the entries from the actual frequency table, complete this table so that it shows relative frequencies"),
                              remnant(_,_,"based on the rows.")]),
    Table6 = decoded_table(table_1,4,_,Rows6,_,_),
    length(Rows6, 3),
    fixture_transposed(F7),
    serialized_table_reading(F7, [Table7], []),
    table_shape(9,1,Table7),
    cell_reading("1,549", numeral(1549,"1,549")),
    cell_reading("93.50", numeral(93.5,"93.50")),
    cell_reading("89%", share(89,"89%")),
    \+ table_segment_surface("A prose sentence with one | typo."),
    format('check_serialized_table_reader: ok tables=8 refusals=2 spans=anchored remnants=2~n').

table_shape(Columns, Rows,
            decoded_table(_,Columns,_,CellRows,_,_)) :-
    length(CellRows, Rows).

fixture_f1("| salt (grams) | honey (grams) | |----------------|-----------------| | 10 | 14 | | 25 | 35 |").
fixture_f2("| | right hand length (cm) | right foot length (cm) | |----------|--------------------------|--------------------------| | person A | 19 | 27 | | person B | 21 | 30 | | person C | 17 | 23 | | person D | 18 | 24 | | person E | 19 | 26 | 1.").
fixture_f3("| | plays instrument | does not play instrument | total | |---------------------|--------------------|----------------------------|---------| | plays sport | 5 | | 16 | | does not play sport | | | | | total | | 15 | 25 |").
fixture_f4("| input | output | |---------|----------| | | 7 | | 2.35 | | | 42 | | | input | output | |---------|----------| | | 7 | | 2.35 | | | 42 | | | input | output | |---------|----------| | | 7 | | 2.35 | | | 42 | |").
fixture_f5("| Equation A | Equation B | Equation C | Equation D | |--------------|--------------|--------------|--------------|").
fixture_merged("Using the entries from the actual frequency table, complete this table so that it shows relative frequencies | | plays an instrument | does not play an instrument | total | |-----------------------|-----------------------|-------------------------------|---------| | plays a sport | | 16 | | | does not play a sport | 5 | | | | total | | | 25 | based on the rows.").
fixture_transposed("| side length, | 0.5 | | 1.5 | | 2.5 | | 3.5 | | |----------------|-------|----|-------|----|-------|----|-------|----| | area, | | 1 | | 4 | | 9 | | 16 |").
