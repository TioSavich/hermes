/** <module> Candidate standards progression overlay queries
 *
 * Reads the tracked Learning Commons projection without promoting any row to
 * learner reachability.  A reviewed promotion with executable path evidence
 * is required before these annotations can enter learner-path traversal.
 */
:- module(standards_progression_overlay,
          [ standards_progression_candidates_dict/2
          ]).

:- use_module(library(apply), [include/3]).
:- use_module(library(http/json), [json_read_dict/3]).

:- dynamic overlay_json_path/1.

:- prolog_load_context(directory, IndexDirectory),
   directory_file_path(
       IndexDirectory,
       '../../data/learningcommons/derived/im_standards_progression_overlay.json',
       OverlayPath
   ),
   assertz(overlay_json_path(OverlayPath)).


%!  standards_progression_candidates_dict(+Code, -Dict) is semidet.
%
%   Return incoming and outgoing curriculum annotations for Code. Every row
%   and the response keep learner_reachability false.
standards_progression_candidates_dict(Code, Dict) :-
    atom(Code),
    progression_overlay(Root),
    get_dict(edges, Root, Edges),
    maplist(require_candidate_only, Edges),
    include(edge_from(Code), Edges, Outgoing),
    include(edge_to(Code), Edges, Incoming),
    (Outgoing \== [] ; Incoming \== []),
    length(Outgoing, OutgoingCount),
    length(Incoming, IncomingCount),
    Dict = standards_progression_candidates{
        code: Code,
        outgoing_count: OutgoingCount,
        incoming_count: IncomingCount,
        outgoing: Outgoing,
        incoming: Incoming,
        learner_reachability: false,
        promotion_requirement: "learner_reachability is false; reviewed promotion with executable learner-path evidence is required"
    }.


progression_overlay(Root) :-
    overlay_json_path(Path),
    setup_call_cleanup(
        open(Path, read, In, [encoding(utf8)]),
        json_read_dict(In, Root, [value_string_as(atom)]),
        close(In)
    ),
    get_dict(schema, Root, im_standards_progression_overlay_v1),
    get_dict(learner_reachability, Root, false).


require_candidate_only(Edge) :-
    get_dict(learner_reachability, Edge, false).

edge_from(Code, Edge) :-
    get_dict(from_code, Edge, Code).

edge_to(Code, Edge) :-
    get_dict(to_code, Edge, Code).
