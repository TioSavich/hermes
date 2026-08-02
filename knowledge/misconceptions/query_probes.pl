/** <module> Keyword probes over the research-corpus misconception rows
 *
 * The prolog_query surface accepts caller-named predicates from knowledge/
 * only. These probes give a small model a single predicate it can call with
 * a keyword instead of the sixteen-argument row term: the row's description,
 * quote, topic, and subtopic are matched case-insensitively, and the answer
 * carries only the fields a diagnosis prompt can use. The corpus rows are
 * attested literature observations, so a mention is a citation to consider,
 * never a diagnosis.
 */
:- module(misconception_query_probes,
          [ misconception_mentions/2,
            misconception_mentions/3
          ]).

:- use_module(misconceptions(research_corpus_misconceptions),
              [ research_corpus_misconception_row/1 ]).

%!  misconception_mentions(+Keyword, -Mention) is nondet.
%
%   Mention = mention(Id, Domain, Topic, Description) for every corpus row
%   whose description, quote, topic, or subtopic contains Keyword,
%   case-insensitively. Keyword may be an atom or a string.
misconception_mentions(Keyword, mention(Id, Domain, Topic, Description)) :-
    keyword_lower(Keyword, Lower),
    research_corpus_misconception_row(
        row(Id, Description, Quote, Domain, Topic, Subtopic,
            _Actor, _Grade, _BibKey, _Authors, _Year, _Journal,
            _Stance, _Importance, _Pages, _Pdf)),
    (   field_contains(Description, Lower) -> true
    ;   field_contains(Quote, Lower) -> true
    ;   field_contains(Topic, Lower) -> true
    ;   field_contains(Subtopic, Lower)
    ).

%!  misconception_mentions(+Keyword, +Domain, -Mention) is nondet.
%
%   As misconception_mentions/2, narrowed to one mathematical domain
%   (for example whole_number, fraction, decimal, ratio).
misconception_mentions(Keyword, Domain, Mention) :-
    Mention = mention(_, Domain, _, _),
    misconception_mentions(Keyword, Mention).

keyword_lower(Keyword, Lower) :-
    (   string(Keyword)
    ->  atom_string(Atom, Keyword)
    ;   Atom = Keyword
    ),
    atom(Atom),
    Atom \== '',
    downcase_atom(Atom, Lower).

field_contains(Field, Lower) :-
    atom(Field),
    Field \== '',
    downcase_atom(Field, FieldLower),
    sub_atom(FieldLower, _, _, _, Lower).
