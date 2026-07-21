/** <module> Literature-exemplar figures for monitoring-chart misconceptions
 *
 * Phase 0 of the student-work-images thread
 * (docs/proposals/2026-06-18-student-work-images-todo.md).
 *
 * Joins a lesson's misconception rows to docling-extracted figures through the
 * shared bibtex key: a misconception carries citation(BibKey, _) in the
 * registry, and docling_figure/5 keys each figure by the same BibKey. The join
 * is therefore *bibkey-level*. A figure attached here documents the cited
 * misconception in real student work *from the literature*, NOT a child's
 * response to the IM lesson's exact numerals. Callers must label rendered
 * artifacts as literature exemplars (Author, Year, p.N).
 */
:- module(lesson_monitoring_figures,
          [ misconception_bibkey/2,        % +Name, -BibKey
            misconception_figure/2,         % +Name, -figure(...)
            misconception_figures/2,        % +Name, -Figures
            lesson_misconception_figures/2, % +Code, -Rows
            lesson_figure_count/2           % +Code, -Count
          ]).

:- use_module(lessons(im/lesson_monitoring),
              [ lesson_misconception/4 ]).
:- use_module(misconceptions(misconception_registry),
              [ misconception_registry_entry/5 ]).
:- use_module(lessons(im/docling_figures),
              [ docling_figure/5 ]).
:- use_module(library(lists), [ member/2 ]).
:- use_module(library(apply), [ maplist/3 ]).

%!  misconception_bibkey(+Name, -BibKey) is nondet.
%
%   The bibtex key(s) cited by a misconception in the registry. A misconception
%   may carry more than one citation across registry routes; all are yielded.
misconception_bibkey(Name, BibKey) :-
    misconception_registry_entry(Name, _Operation, citation(BibKey, _Note), _, _).

%!  misconception_figure(+Name, -Figure) is nondet.
%
%   Figure = figure(BibKey, RelPath, PageNo, OnCandidatePage, Caption).
%   One solution per docling figure whose bibkey the misconception cites.
misconception_figure(Name, figure(BibKey, RelPath, PageNo, OnCandidatePage, Caption)) :-
    misconception_bibkey(Name, BibKey),
    docling_figure(BibKey, RelPath, PageNo, OnCandidatePage, Caption).

%!  misconception_figures(+Name, -Figures) is det.
%
%   The sorted, de-duplicated list of figures for a misconception.
misconception_figures(Name, Figures) :-
    findall(F, misconception_figure(Name, F), Fs0),
    sort(Fs0, Figures).

%!  lesson_misconception_figures(+Code, -Rows) is det.
%
%   For a lesson, the list of misc_figures(Operation, Name, Figures) rows whose
%   misconception has at least one literature-exemplar figure. Misconceptions
%   with no figure are omitted (the chart still lists them via the plain
%   monitoring export; this predicate is the figure overlay).
lesson_misconception_figures(Code, Rows) :-
    findall(misc_figures(Operation, Name, Figures),
            ( lesson_monitoring:lesson_misconception(Code, Operation, Name, _Info),
              misconception_figures(Name, Figures),
              Figures \== []
            ),
            Rows0),
    sort(Rows0, Rows).

%!  lesson_figure_count(+Code, -Count) is det.
%
%   Total literature-exemplar figures available across a lesson's
%   misconceptions (counting a figure once per (misconception, figure) pair).
lesson_figure_count(Code, Count) :-
    lesson_misconception_figures(Code, Rows),
    maplist(row_figure_count, Rows, Counts),
    sum_list(Counts, Count).

row_figure_count(misc_figures(_, _, Figures), N) :-
    length(Figures, N).
