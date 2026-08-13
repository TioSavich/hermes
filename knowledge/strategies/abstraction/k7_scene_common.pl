:- encoding(utf8).
/** <module> K-7 scene emission, shared: the grapher's genre and its render receipt
 *
 * WHAT THIS IS. The parts the four K-7 scene-emission pilots share: building a
 * specification in the coordinate-plane grapher's own JSON genre
 * (`hermes/web/coordinate-plane`, schema version 1), writing it out, and
 * handing it to that renderer under Node so a specification the renderer
 * rejects fails a check rather than passing as a claim.
 *
 * WHY A RENDER RECEIPT. A scene that no renderer has accepted is a dict that
 * looks like a drawing. The receipt here is the drawing: `grapher.js`
 * validates the specification and returns SVG, and a non-zero exit or a reply
 * that does not open with `<svg` is thrown, not warned about.
 *
 * WHAT IT DOES NOT DO. It computes no mathematics. Coordinates arrive already
 * exact from the pilot that built them; the float conversion happens here at
 * the last step only because the renderer's schema takes numbers. No pilot
 * decides anything from a float.
 *
 * QUARANTINE. Nothing outside `knowledge/strategies/abstraction/` imports this
 * module. It renames nothing and modifies no existing machine.
 */

:- module(k7_scene_common,
          [ k7_scene_json/2,            % +Scene, -JSON
            k7_render_scenes/1,         % +ListOfJSONStrings
            k7_render_scene/1,          % +JSONString
            k7_rational_text/2,         % +Rational, -Text
            k7_point/4,                 % +X, +Y, +Colour, -Point
            k7_labelled_point/5,        % +X, +Y, +Label, +Colour, -Point
            k7_segment/6,               % +X1,+Y1,+X2,+Y2,+Colour,-Segment
            k7_labelled_segment/7,      % +X1,+Y1,+X2,+Y2,+Label,+Colour,-Segment
            k7_colour/2                 % +Role, -Hex
          ]).

:- use_module(library(http/json), [json_write_dict/3]).
:- use_module(library(process), [process_create/3, process_wait/2]).

% ==========================================================================
% COLOUR ROLES
%
% Two readings are drawn side by side throughout this lane: the run the
% machine certifies, and the run a deformation produces. Colour separates
% them so a teacher can put one beside the other. These are the grapher's own
% palette values, not new ones.
% ==========================================================================

k7_colour(productive, "#2f7d6e").
k7_colour(student, "#b5563f").
k7_colour(structure, "#3f7f89").
k7_colour(landmark, "#a97c24").

% ==========================================================================
% SCENE PARTS
% ==========================================================================

%!  k7_point(+X, +Y, +Colour, -Point) is det.
%
%   A point of the grapher's genre. X and Y arrive exact and become floats
%   here because the schema takes numbers.
k7_point(X, Y, Colour, point{x: FX, y: FY, color: Colour}) :-
    FX is float(X), FY is float(Y).

k7_labelled_point(X, Y, Label, Colour,
                  point{x: FX, y: FY, label: Label, color: Colour}) :-
    FX is float(X), FY is float(Y).

k7_segment(X1, Y1, X2, Y2, Colour,
           line{type: "segment",
                from: point{x: FX1, y: FY1},
                to: point{x: FX2, y: FY2},
                color: Colour}) :-
    FX1 is float(X1), FY1 is float(Y1),
    FX2 is float(X2), FY2 is float(Y2).

k7_labelled_segment(X1, Y1, X2, Y2, Label, Colour,
                    line{type: "segment",
                         from: point{x: FX1, y: FY1},
                         to: point{x: FX2, y: FY2},
                         label: Label, color: Colour}) :-
    FX1 is float(X1), FY1 is float(Y1),
    FX2 is float(X2), FY2 is float(Y2).

% ==========================================================================
% EXACT RENDERING OF A RATIONAL
% ==========================================================================

%!  k7_rational_text(+Q, -Text) is det.
%
%   An exact rational written the way it would be read aloud: an integer as
%   itself, anything else as a quotient of integers. No decimal approximation
%   is produced here, because nothing downstream is allowed to decide from one.
k7_rational_text(Q, Text) :-
    integer(Q),
    !,
    format(string(Text), "~w", [Q]).
k7_rational_text(Q, Text) :-
    rational(Q),
    !,
    N is numerator(Q), D is denominator(Q),
    format(string(Text), "~w/~w", [N, D]).
k7_rational_text(Q, Text) :-
    format(string(Text), "~w", [Q]).

% ==========================================================================
% THE RENDER RECEIPT
% ==========================================================================

%!  k7_scene_json(+Scene, -JSON) is det.
%
%   The scene as a single-line JSON string, which is what the renderer takes.
k7_scene_json(Scene, JSON) :-
    with_output_to(string(JSON),
                   json_write_dict(current_output, Scene, [width(0)])).

%!  k7_render_scene(+JSON) is det.
%
%   Hand one specification to the coordinate-plane grapher. Throws if the
%   renderer rejects it.
k7_render_scene(JSON) :-
    k7_render_scenes([JSON]).

%!  k7_render_scenes(+JSONs) is det.
%
%   Hand every specification to `hermes/web/coordinate-plane/grapher.js` under
%   Node. The renderer validates each specification and returns SVG; anything
%   else throws `grapher_rejected_scene/2` and fails the caller's check.
k7_render_scenes(JSONs) :-
    absolute_file_name(hermes('web/coordinate-plane/grapher.js'), Grapher,
                       [access(read)]),
    setup_call_cleanup(
        tmp_file_stream(text, File, Stream),
        ( forall(member(S, JSONs), ( write(Stream, S), nl(Stream) )),
          close(Stream),
          run_grapher(Grapher, File)
        ),
        catch(delete_file(File), _, true)).

run_grapher(Grapher, File) :-
    Script = 'const fs=require("fs");const g=require(process.argv[1]);\c
let n=0;for(const line of fs.readFileSync(process.argv[2],"utf8").split("\\n")){\c
if(!line.trim())continue;const spec=JSON.parse(line);g.validateSpec(spec);\c
const svg=g.renderSpec(spec);if(!svg||svg.indexOf("<svg")!==0)throw new Error("no svg");n++;}\c
console.log("rendered "+n);',
    process_create(path(node), ['-e', Script, Grapher, File],
                   [stdout(pipe(Out)), stderr(pipe(Err)), process(PID)]),
    read_string(Out, _, Stdout),
    read_string(Err, _, Stderr),
    process_wait(PID, Status),
    (   Status == exit(0)
    ->  true
    ;   throw(error(grapher_rejected_scene(Stdout, Stderr), _))
    ).
