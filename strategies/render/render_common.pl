/** <module> Shared plumbing for render-scene compilers
 *
 * Scene modules own their geometry, captions, verbs, requests, results, and
 * render-document shapes.  This module contains only the byte-identical
 * generate-or-defer control flow, term formatting, and JSON file writer that
 * those compilers previously repeated.
 */

:- module(render_common,
          [ render_frames/4,       % +Spec, :Generate, :Deferred, -Frames
            term_to_string/2,      % +Term, -String
            write_render_json/2    % +Path, +Dict
          ]).

:- use_module(library(http/json), [json_write_dict/3]).

:- meta_predicate render_frames(+, 2, 2, -).

%!  render_frames(+Spec, :Generate, :Deferred, -Frames) is det.
%
%   Use the compiler's scene generator when it succeeds.  Otherwise retain
%   that compiler's annotation-only deferred frame.
render_frames(Spec, Generate, Deferred, Frames) :-
    ( call(Generate, Spec, Frames0)
    -> Frames = Frames0
    ;  call(Deferred, Spec, Frame),
       Frames = [Frame]
    ).

%!  term_to_string(+Term, -String) is det.
term_to_string(Term, String) :-
    ( string(Term)
    -> String = Term
    ;  format(string(String), '~w', [Term])
    ).

%!  write_render_json(+Path, +Dict) is det.
write_render_json(Path, Dict) :-
    setup_call_cleanup(
        open(Path, write, Stream),
        json_write_dict(Stream, Dict, [width(80)]),
        close(Stream)).
