/** <module> Lakoff & Núñez grounding -> visual primitive routing
 *
 * The visualization primitives (P1..P10, docs/proposals/2026-06-22-k8-
 * visualization-coverage.md) are the image-schematic renderings of the L&N
 * grounding metaphors: Motion Along a Path is a number line with jumps (P1),
 * Object Collection is a set of discrete objects (P5), Object Construction and
 * the Container schema are a bounded whole made of parts (P2 bar, P3 area),
 * Measuring Stick is length on an axis or bar (P1/P2).
 *
 * This module makes that routing queryable. The metaphor a claim invokes is
 * already recorded: `mua_relations:grounding_metaphor/2` assigns each arithmetic
 * practice a grounding-metaphor label, and the geometry metaphor modules assign
 * geometry concepts an image-schema family. This module adds the missing edge --
 * which visual primitive renders which metaphor/schema -- so a content claim
 * routes to its visual through its grounding, not by ad-hoc topic match.
 *
 * The drawer.js DISPATCH table ships nine renderers today: fraction-bars,
 * number-line, area-model, base-ten-columns, place-value-chart, set-grouping,
 * balance-scale, hybridization-model, and notation. The facts here record a
 * grounding relation (which primitive renders which metaphor/schema); they are
 * not themselves a claim that a renderer exists for every mapped primitive.
 *
 * Sources:
 *   - formal/formalization/grounding_metaphors.pl (the four metaphors + repairs)
 *   - formal/pml/mua_relations.pl (grounding_metaphor/2: practice -> metaphor label)
 *   - geometry/metaphors/lakoff_nunez_inventory.pl, measuring_stick.pl
 *     (image-schema families: container_schema, source_path_goal,
 *      categories_are_containers; the Container vs Measuring-Stick distinction)
 */

:- module(grounding_to_primitive,
          [ primitive_renders_metaphor/3,      % ?Primitive, ?MetaphorLabel, ?Role
            primitive_for_practice/3,           % ?Practice, ?Primitive, ?Role
            primitive_for_practice_witness/4,   % ?Practice, ?Primitive, ?Role, -Witness
            metaphor_label_gloss/2,             % ?MetaphorLabel, ?Gloss
            metaphor_image_schema/2,            % ?MetaphorLabel, ?Schema
            image_schema_for_practice/2         % ?Practice, ?Schema
          ]).

:- use_module(pml(mua_relations)).

%!  primitive_renders_metaphor(?Primitive, ?MetaphorLabel, ?Role) is nondet.
%
%   The visual primitive that draws a claim grounded in MetaphorLabel. Role is
%   `primary` (the primitive is the canonical image-schematic rendering of the
%   metaphor) or `secondary` (the primitive can carry it for a sub-case, e.g.
%   Object Collection on an array for multiplication). MetaphorLabel uses the MUA
%   short labels for the four arithmetic metaphors, the full ids for the repair
%   metaphors, and the geometry image-schema family atoms.

% Motion Along a Path / Source-Path-Goal -> P1 number line with jumps.
primitive_renders_metaphor('P1', motion_along_path, primary).
primitive_renders_metaphor('P1', source_path_goal,  primary).
% Measuring Stick -> length on an axis (P1) or on a partitioned bar (P2).
primitive_renders_metaphor('P1', measuring_stick,   primary).
primitive_renders_metaphor('P2', measuring_stick,   secondary).
% The signed-number repair (rotation by 180) reads on the number line.
primitive_renders_metaphor('P1', multiplication_by_minus_one_is_rotation_by_180_degrees, secondary).

% Object Construction / Container (a bounded whole made of parts) -> P2 bar,
% P3 area (2-D part-of-part), P4 base-ten bundling.
primitive_renders_metaphor('P2', object_construction, primary).
primitive_renders_metaphor('P2', container_schema,    secondary).
primitive_renders_metaphor('P2', zero_object_metaphor, secondary).
primitive_renders_metaphor('P3', object_construction, secondary).
primitive_renders_metaphor('P4', object_construction, primary).

% Object Collection (discrete objects) -> P5 set-and-grouping; on an array (P3)
% when pooling subcollections grounds multiplication.
primitive_renders_metaphor('P5', object_collection,      primary).
primitive_renders_metaphor('P5', zero_collection_metaphor, secondary).
primitive_renders_metaphor('P3', object_collection,      secondary).

% Geometry image schemas.
primitive_renders_metaphor('P7', container_schema,        secondary). % polygon interior
primitive_renders_metaphor('P8', categories_are_containers, primary). % class inclusion
primitive_renders_metaphor('P8', container_schema,        primary).   % nested containment
primitive_renders_metaphor('P10', source_path_goal,       secondary). % the metaphor map itself

% Balance-preservation schema -> the two-pan balance ('PB'). This is the
% justify-side relational-equals primitive (balance_scale_scene.pl): "=" reads as
% the two sides naming the same quantity, and solving keeps the beam level by
% doing the same move to both pans. It is not one of the four L&N arithmetic
% grounding metaphors; the schema is sameness-preserved-under-the-same-operation.
% The p_relational_equals_balance_preservation practice carries this schema, so
% a relational-equals claim can now route to the PB primitive through grounding.
primitive_renders_metaphor('PB', balance_preservation_schema, primary).

%!  primitive_for_practice(?Practice, ?Primitive, ?Role) is nondet.
%
%   Closes the loop practice -> grounding metaphor -> visual primitive for any
%   arithmetic practice that carries a `grounding_metaphor/2` assignment. A
%   practice with `no_metaphor_grounding` (a deformation) yields no primitive --
%   correct: an ungrounded deformation has no L&N-grounded figure of its own; it
%   is drawn only as the contrast against its grounded productive partner.
primitive_for_practice(Practice, Primitive, Role) :-
    mua_relations:grounding_metaphor(Practice, Label),
    primitive_renders_metaphor(Primitive, Label, Role).

%!  primitive_for_practice_witness(?Practice, ?Primitive, ?Role, -Witness) is nondet.
primitive_for_practice_witness(Practice, Primitive, Role,
        _{ kind: lakoff_nunez_grounded_primitive,
           practice: Practice,
           grounding_metaphor_label: Label,
           metaphor_gloss: Gloss,
           visual_primitive: Primitive,
           role: Role,
           source: lakoff_nunez_grounding }) :-
    mua_relations:grounding_metaphor(Practice, Label),
    primitive_renders_metaphor(Primitive, Label, Role),
    ( metaphor_label_gloss(Label, Gloss) -> true ; Gloss = Label ).

%!  metaphor_label_gloss(?MetaphorLabel, ?Gloss) is nondet.
metaphor_label_gloss(object_collection,   "Object Collection — numbers as collections of discrete objects").
metaphor_label_gloss(object_construction, "Object Construction — numbers as wholes built from parts").
metaphor_label_gloss(measuring_stick,     "Measuring Stick — numbers as physical segment lengths").
metaphor_label_gloss(motion_along_path,   "Motion Along a Path — numbers as point-locations reached by moving").
metaphor_label_gloss(container_schema,    "Container schema — interior / boundary / exterior of a bounded region").
metaphor_label_gloss(source_path_goal,    "Source-Path-Goal — a trajectory from origin toward a goal").
metaphor_label_gloss(categories_are_containers, "Categories Are Containers — class membership as being inside").
metaphor_label_gloss(balance_preservation_schema, "Balance preservation — equality maintained by applying the same operation to both sides").

%!  metaphor_image_schema(?MetaphorLabel, ?Schema) is nondet.
%
%   The underlying L&N image schema a grounding metaphor recruits. The four
%   arithmetic grounding metaphors (mua_relations:grounding_metaphor/2) and the
%   repair metaphors each draw on one of the image-schema families the geometry
%   inventory already names (geometry/metaphors/lakoff_nunez_inventory.pl:
%   source_path_goal, container_schema, categories_are_containers). This map is
%   the metaphor -> schema edge image_schema_for_practice/2 keys off.
%
%   Motion Along a Path and Measuring Stick both lay number against a directed
%   trajectory (a position reached, a length swept), so both recruit
%   Source-Path-Goal — the schema the number line / measuring bar draws. Object
%   Construction, the Container schema, and Object Collection all treat a number
%   as a bounded whole made of (or holding) parts, so they recruit the Container
%   schema — the schema the partitioned bar / bundling figure draws.
metaphor_image_schema(motion_along_path,   source_path_goal).
metaphor_image_schema(measuring_stick,     source_path_goal).
metaphor_image_schema(source_path_goal,    source_path_goal).
metaphor_image_schema(balance_preservation_schema, balance_preservation_schema).
metaphor_image_schema(object_construction, container_schema).
metaphor_image_schema(container_schema,    container_schema).
metaphor_image_schema(zero_object_metaphor, container_schema).
metaphor_image_schema(object_collection,   container_schema).
metaphor_image_schema(zero_collection_metaphor, container_schema).
metaphor_image_schema(categories_are_containers, categories_are_containers).

%!  image_schema_for_practice(?Practice, ?Schema) is det for a ground Practice.
%
%   The image schema a practice's visual renders, keyed off its
%   grounding_metaphor/2 assignment through metaphor_image_schema/2. A practice
%   may carry several grounding metaphors (e.g. p_count_on_from_larger carries
%   both motion_along_path and object_collection); the motion/measuring reading
%   takes priority so a counting-on claim routes to the Source-Path-Goal number
%   line rather than to a bounded-set figure. With no metaphor-of-motion present,
%   the construction/collection reading gives Container.
%
%   A practice with no_metaphor_grounding (an inferentially hollow deformation)
%   yields no schema -- correct: an ungrounded procedure has no image-schematic
%   figure of its own.
image_schema_for_practice(Practice, Schema) :-
    ( practice_motion_schema(Practice, S)
    -> Schema = S
    ;  practice_any_schema(Practice, Schema)
    ).

% A practice routes to Source-Path-Goal if any of its grounding metaphors is a
% motion / measuring metaphor.
practice_motion_schema(Practice, source_path_goal) :-
    once(( mua_relations:grounding_metaphor(Practice, Label),
           metaphor_image_schema(Label, source_path_goal) )).

% Otherwise the first non-motion grounding metaphor settles the schema.
practice_any_schema(Practice, Schema) :-
    once(( mua_relations:grounding_metaphor(Practice, Label),
           metaphor_image_schema(Label, Schema) )).
