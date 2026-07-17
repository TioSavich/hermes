% PURPOSE: Portable in-repo loader for the geometry KB, resolving the repository root through paths.pl search paths instead of a hardcoded absolute path.
%
% geometry_bridge.pl — standalone loader for the geometry knowledge base.
%
% This file supersedes an earlier untracked loader of the same name that
% lived outside this repository and pinned geometry_kb_root/1 to one
% machine's absolute path. A fresh clone carries only this file. The
% geometry/schema.pl owns the canonical load chain used here and by the
% Hermes worker. This bridge adds only standalone root discovery and a banner.
%
% Load through paths.pl so the search-path aliases exist:
%
%   swipl -l paths.pl -s geometry/geometry_bridge.pl
%
% Loading this file consults the KB (load_geometry_kb/0 runs as a final
% directive). If paths.pl has not been loaded yet, this file consults it
% from its own parent directory before resolving the root. After load,
% the KB predicates answer in `user`:
%
%   geom_concept/4, van_hiele_marker/4, metaphor_source/4,
%   geom_misconception/6, material_inference/4, bootstrap/6,
%   construction/5, standard_anchor/4, tier/4, triangulation/2,
%   pck_synthesis/5, developmental_marker/4
%
% along with the query layer (matching_concepts/3, ...) from query.pl and
% the validators validate_geom_kb/0 and coverage_report/1 from schema.pl.

% Make sure the paths.pl aliases exist. When this file is loaded without
% paths.pl (plain `swipl -s geometry/geometry_bridge.pl`), consult it from
% the parent directory of this file.
:- prolog_load_context(directory, GeomDir),
   (   user:file_search_path(geometry, _)
   ->  true
   ;   file_directory_name(GeomDir, RepoRoot),
       directory_file_path(RepoRoot, 'paths.pl', PathsFile),
       (   exists_file(PathsFile)
       ->  consult(PathsFile)
       ;   throw(error(existence_error(source_sink, PathsFile),
                       context(geometry_bridge, 'paths.pl not found beside geometry/')))
       )
   ).

% geometry_repo_root(-Root) — repository root, derived from the `geometry`
% search-path alias that paths.pl asserts.
geometry_repo_root(Root) :-
    user:file_search_path(geometry, GeomDir),
    file_directory_name(GeomDir, Root),
    !.

% load_geometry_kb/0 — delegate once to the canonical schema.pl load chain.
load_geometry_kb :-
    geometry_repo_root(Root),
    load_geometry_kb(Root).

load_geometry_kb(Root) :-
    directory_file_path(Root, 'geometry/schema.pl', Schema),
    consult(Schema),
    geometry_bridge_banner.

% One line to stderr so a standalone load reports what it holds.
geometry_bridge_banner :-
    aggregate_all(count, geom_concept(_, _, _, _), Concepts),
    aggregate_all(count, geom_misconception(_, _, _, _, _, _), Misconceptions),
    format(user_error,
           'geometry_bridge: KB loaded (~w concepts, ~w misconceptions).~n',
           [Concepts, Misconceptions]).

:- load_geometry_kb.
