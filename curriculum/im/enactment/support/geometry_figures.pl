/** <module> Lattice figure algebra for the geometry enactment lane
 *
 * Every attribute a geometry lesson names is COMPUTED here from a polygon's
 * vertices: sides, parallel pairs, right angles, equal lengths, lines of
 * symmetry, area. Nothing in this file stores an attribute as a label.
 * `fig_attribute(Vertices, parallel_pairs(2))` succeeds because the cross
 * product of two side vectors is zero, not because a row said so.
 *
 * A figure is a list of integer X-Y vertices in boundary order, a simple closed
 * polygon on the integer lattice. Integer coordinates buy exact arithmetic:
 * parallel is cross = 0, perpendicular is dot = 0, equal length is equal
 * squared length, area is the shoelace half-sum. No float comparison appears
 * anywhere below. A checker that compared floats was a real defect in this
 * repository; the representation removes the temptation rather than guarding
 * against it.
 *
 * The lattice restricts what can be represented, and the restriction is a
 * result rather than a nuisance. No equilateral triangle has integer vertices:
 * its area is s^2*sqrt(3)/4, irrational for every rational s^2, while the
 * shoelace sum over integer vertices is always half an integer. Callers that
 * ask for one get `lattice_unrealizable/2` with the argument attached, not a
 * near miss dressed as an answer.
 *
 * Symmetry is exact too. A reflection that maps a polygon to itself fixes its
 * centroid and meets the boundary at either a vertex or an edge midpoint, so
 * the candidate axes are finite and enumerable. Coordinates are scaled by 2N
 * (N vertices) so centroid and midpoints stay integral, and the reflection is
 * compared after a further scaling by D.D, which clears its only division.
 */

:- module(geometry_figures,
          [ fig_sides/2,
            fig_edge_vectors/2,
            fig_side_lengths2/2,
            fig_area2/2,
            fig_area/2,
            fig_perimeter/2,
            fig_right_angle_count/2,
            fig_angle_classes/2,
            fig_parallel_pairs/2,
            fig_perpendicular_pairs/2,
            fig_symmetry_axis_count/2,
            fig_convex/1,
            fig_simple_closed/1,
            fig_name/2,
            fig_attribute/2,
            fig_attributes/2,
            fig_translate/3,
            fig_holds/2,
            lattice_unrealizable/2,
            canonical_figure/3,
            canonical_family/2,
            pattern_block/3,
            pattern_block_note/1,
            letterform/2,
            letterform_note/1,
            cube_net_foldable/1,
            hexomino/1,
            solid_prism/4,
            rectangles_with_area/2,
            boxes_with_volume/2
          ]).

:- use_module(library(lists)).
:- use_module(library(apply)).

% =============================================================================
% Edges and lengths
% =============================================================================

%!  fig_sides(+Vertices, -N) is det.
fig_sides(Vs, N) :- length(Vs, N).

%!  fig_edge_vectors(+Vertices, -Vectors) is det.
%
%   One DX-DY per side, in boundary order, closing back to the first vertex.
fig_edge_vectors([V | Vs], Vectors) :-
    edge_pairs([V | Vs], V, Pairs),
    maplist(pair_vector, Pairs, Vectors).

edge_pairs([A], First, [A-First]) :- !.
edge_pairs([A, B | Rest], First, [A-B | More]) :-
    edge_pairs([B | Rest], First, More).

pair_vector((X1-Y1)-(X2-Y2), DX-DY) :-
    DX is X2 - X1,
    DY is Y2 - Y1.

%!  fig_side_lengths2(+Vertices, -Squares) is det.
%
%   Squared side lengths in boundary order. Squared, so the comparison stays in
%   the integers: two sides are equal exactly when these agree.
fig_side_lengths2(Vs, Squares) :-
    fig_edge_vectors(Vs, Vectors),
    maplist([DX-DY, L]>>(L is DX*DX + DY*DY), Vectors, Squares).

%!  fig_perimeter(+Vertices, -Perimeter) is semidet.
%
%   Succeeds only when every side has integer length. A lattice polygon's
%   perimeter is usually irrational, and printing a rounded decimal as "the
%   perimeter" would be the float comparison this module refuses, one step
%   later.
fig_perimeter(Vs, Perimeter) :-
    fig_side_lengths2(Vs, Squares),
    maplist(exact_root, Squares, Lengths),
    sum_list(Lengths, Perimeter).

exact_root(Square, Root) :-
    Root is round(sqrt(Square)),
    Root * Root =:= Square.

% =============================================================================
% Area
% =============================================================================

%!  fig_area2(+Vertices, -TwiceArea) is det.
%
%   The shoelace sum: twice the area, always an integer for lattice vertices.
fig_area2(Vs, TwiceArea) :-
    Vs = [First | _],
    shoelace(Vs, First, Sum),
    TwiceArea is abs(Sum).

shoelace([X-Y], FX-FY, Term) :- !,
    Term is X*FY - FX*Y.
shoelace([X1-Y1, X2-Y2 | Rest], First, Sum) :-
    shoelace([X2-Y2 | Rest], First, More),
    Sum is X1*Y2 - X2*Y1 + More.

%!  fig_area(+Vertices, -Area) is det.
%
%   An integer where the doubled sum is even, otherwise the term Odd/2. Half a
%   square unit is a real lattice area (a triangle over one cell), so it keeps
%   its exact form instead of being rounded away.
fig_area(Vs, Area) :-
    fig_area2(Vs, Twice),
    ( 0 is Twice mod 2 -> Area is Twice // 2 ; Area = Twice/2 ).

% =============================================================================
% Angles, parallels, convexity
% =============================================================================

cross(DX1-DY1, DX2-DY2, C) :- C is DX1*DY2 - DY1*DX2.
dot(DX1-DY1, DX2-DY2, D)   :- D is DX1*DX2 + DY1*DY2.

%!  fig_parallel_pairs(+Vertices, -Count) is det.
%
%   Unordered pairs of sides whose cross product vanishes.
fig_parallel_pairs(Vs, Count) :-
    fig_edge_vectors(Vs, Vectors),
    findall(I-J,
            ( nth0(I, Vectors, A), nth0(J, Vectors, B), I < J,
              cross(A, B, 0) ),
            Pairs),
    length(Pairs, Count).

%!  fig_perpendicular_pairs(+Vertices, -Count) is det.
fig_perpendicular_pairs(Vs, Count) :-
    fig_edge_vectors(Vs, Vectors),
    findall(I-J,
            ( nth0(I, Vectors, A), nth0(J, Vectors, B), I < J,
              dot(A, B, 0) ),
            Pairs),
    length(Pairs, Count).

%!  fig_angle_classes(+Vertices, -Classes) is det.
%
%   One of right, acute, obtuse or reflex per vertex, in boundary order. The
%   incoming side reversed and the outgoing side span the interior angle; the
%   sign of their dot product separates acute from obtuse, and the polygon's
%   own orientation separates a reflex vertex from a convex one.
fig_angle_classes(Vs, Classes) :-
    fig_edge_vectors(Vs, Vectors),
    polygon_orientation(Vs, Orient),
    length(Vectors, N),
    findall(Class,
            ( between(1, N, K),
              Prev is ((K - 2) mod N),
              Cur is K - 1,
              nth0(Prev, Vectors, In),
              nth0(Cur, Vectors, Out),
              vertex_angle_class(In, Out, Orient, Class) ),
            Classes).

vertex_angle_class(DX1-DY1, Out, Orient, Class) :-
    BX is -DX1, BY is -DY1,
    dot(BX-BY, Out, D),
    cross(DX1-DY1, Out, C),
    Turn is C * Orient,
    (   Turn < 0 -> Class = reflex
    ;   D =:= 0  -> Class = right
    ;   D > 0    -> Class = acute
    ;   Class = obtuse
    ).

polygon_orientation(Vs, Orient) :-
    Vs = [First | _],
    shoelace(Vs, First, Sum),
    ( Sum >= 0 -> Orient = 1 ; Orient = -1 ).

%!  fig_right_angle_count(+Vertices, -Count) is det.
fig_right_angle_count(Vs, Count) :-
    fig_angle_classes(Vs, Classes),
    include(==(right), Classes, Rights),
    length(Rights, Count).

%!  fig_convex(+Vertices) is semidet.
fig_convex(Vs) :-
    fig_angle_classes(Vs, Classes),
    \+ memberchk(reflex, Classes).

%!  fig_simple_closed(+Vertices) is semidet.
%
%   Three or more distinct integer vertices, no zero-length side, and no two
%   consecutive sides collinear, which would put a false vertex in the middle
%   of a straight edge. The geoboard compiler admits a polygon on the same
%   terms.
fig_simple_closed(Vs) :-
    is_list(Vs),
    length(Vs, N), N >= 3,
    maplist([X-Y]>>(integer(X), integer(Y)), Vs),
    sort(Vs, Sorted), length(Sorted, N),
    fig_edge_vectors(Vs, Vectors),
    \+ memberchk(0-0, Vectors),
    \+ ( consecutive_wrap(Vectors, A, B), cross(A, B, 0) ).

consecutive_wrap(Vectors, A, B) :-
    length(Vectors, N),
    between(1, N, K),
    Cur is K - 1,
    Next is K mod N,
    nth0(Cur, Vectors, A),
    nth0(Next, Vectors, B).

% =============================================================================
% Symmetry
% =============================================================================

%!  fig_symmetry_axis_count(+Vertices, -Count) is det.
%
%   Reflections that carry the vertex set to itself. Coordinates are scaled by
%   2N so the centroid and every edge midpoint land on integers; the reflection
%   formula is then multiplied through by D.D, which clears its only division.
%   Nothing here rounds.
fig_symmetry_axis_count(Vs, Count) :-
    length(Vs, N),
    Scale is 2 * N,
    maplist(scale_vertex(Scale), Vs, Scaled),
    centroid_scaled(Vs, Centroid),
    candidate_axes(Scaled, Centroid, Axes),
    include(axis_fixes_figure(Scaled, Centroid), Axes, Good),
    length(Good, Count).

%!  scale_vertex(+Scale, +Vertex, -Scaled) is det.
%
%   Named rather than written as a lambda. A `>>` lambda whose free variable is
%   not declared with `/` is compiled into an auxiliary predicate that does not
%   carry the variable, so `Scale` arrives unbound and `is/2` raises. It read as
%   working for as long as the lambda was interpreted rather than expanded, and
%   the expansion depended on what else the process had loaded, which is the
%   worst shape a defect can take.
scale_vertex(Scale, X-Y, SX-SY) :-
    SX is Scale * X,
    SY is Scale * Y.

%   Scale is 2N and the centroid divides by N, so the scaled centroid is 2*Sum.
centroid_scaled(Vs, CX-CY) :-
    foldl([X-_, A0, A]>>(A is A0 + X), Vs, 0, SumX),
    foldl([_-Y, A0, A]>>(A is A0 + Y), Vs, 0, SumY),
    CX is 2 * SumX,
    CY is 2 * SumY.

candidate_axes(Scaled, CX-CY, Axes) :-
    findall(D,
            ( member(VX-VY, Scaled),
              DX is VX - CX, DY is VY - CY,
              normalize_direction(DX-DY, D) ),
            FromVertices),
    findall(D,
            ( edge_midpoint(Scaled, MX-MY),
              DX is MX - CX, DY is MY - CY,
              normalize_direction(DX-DY, D) ),
            FromMidpoints),
    append(FromVertices, FromMidpoints, All),
    sort(All, Axes).

edge_midpoint([First | Rest], MX-MY) :-
    edge_pairs([First | Rest], First, Pairs),
    member((X1-Y1)-(X2-Y2), Pairs),
    MX is (X1 + X2) // 2,
    MY is (Y1 + Y2) // 2.

%!  normalize_direction(+Vector, -Canonical) is semidet.
%
%   Divide out the common factor and fix the sign, so a direction and its
%   negation collapse to one axis. Fails on the zero vector.
normalize_direction(0-0, _) :- !, fail.
normalize_direction(DX-DY, NX-NY) :-
    G is gcd(abs(DX), abs(DY)),
    G > 0,
    RX is DX // G, RY is DY // G,
    (   RX < 0
    ->  NX is -RX, NY is -RY
    ;   RX =:= 0, RY < 0
    ->  NX = 0, NY is -RY
    ;   NX = RX, NY = RY
    ).

axis_fixes_figure(Scaled, Centroid, Direction) :-
    dot(Direction, Direction, DD),
    DD > 0,
    maplist(reflect_scaled(Centroid, Direction, DD), Scaled, Images),
    maplist(scale_point(DD), Scaled, Originals),
    msort(Originals, SortedOriginals),
    msort(Images, SortedImages),
    SortedOriginals == SortedImages.

scale_point(K, X-Y, SX-SY) :- SX is K*X, SY is K*Y.

%   Reflection of Q across the line through P with direction D, multiplied
%   through by D.D so the result stays integral:
%       (Q' - P) * (D.D) = 2*((Q-P).D)*D - (D.D)*(Q-P)
reflect_scaled(PX-PY, DX-DY, DD, QX-QY, RX-RY) :-
    WX is QX - PX, WY is QY - PY,
    dot(DX-DY, WX-WY, WD),
    K is 2 * WD,
    RX is DD*PX + K*DX - DD*WX,
    RY is DD*PY + K*DY - DD*WY.

% =============================================================================
% Names read off the computed attributes
% =============================================================================

%!  fig_name(+Vertices, -Name) is det.
%
%   The classification a K-5 lesson would use, derived from side count, side
%   lengths, angle classes and parallel pairs. A square is named a square
%   because four equal sides carry four right angles here, not because a stored
%   row called it one.
fig_name(Vs, Name) :-
    fig_sides(Vs, N),
    (   N =:= 3 -> triangle_name(Vs, Name)
    ;   N =:= 4 -> quadrilateral_name(Vs, Name)
    ;   N =:= 5 -> Name = pentagon
    ;   N =:= 6 -> Name = hexagon
    ;   Name = polygon(N)
    ).

triangle_name(Vs, triangle(Angle, Side)) :-
    fig_side_lengths2(Vs, Squares),
    sort(Squares, Distinct),
    length(Distinct, Kinds),
    fig_angle_classes(Vs, Classes),
    (   memberchk(right, Classes)  -> Angle = right
    ;   memberchk(obtuse, Classes) -> Angle = obtuse
    ;   Angle = acute
    ),
    (   Kinds =:= 1 -> Side = equilateral
    ;   Kinds =:= 2 -> Side = isosceles
    ;   Side = scalene
    ).

quadrilateral_name(Vs, Name) :-
    fig_side_lengths2(Vs, Squares),
    sort(Squares, Distinct),
    fig_right_angle_count(Vs, Rights),
    fig_parallel_pairs(Vs, Parallels),
    (   Parallels >= 2, Rights =:= 4, Distinct = [_] -> Name = square
    ;   Parallels >= 2, Rights =:= 4                 -> Name = rectangle
    ;   Parallels >= 2, Distinct = [_]               -> Name = rhombus
    ;   Parallels >= 2                               -> Name = parallelogram
    ;   Parallels =:= 1                              -> Name = trapezoid
    ;   adjacent_equal_pairs(Squares)                -> Name = kite
    ;   Name = quadrilateral
    ).

adjacent_equal_pairs([A, A, B, B]) :- A \== B, !.
adjacent_equal_pairs([A, B, B, A]) :- A \== B.

% =============================================================================
% The attribute surface every form reads
% =============================================================================

%!  fig_attribute(+Vertices, ?Attribute) is nondet.
%
%   Enumerates the computed attributes of a figure. Every clause runs a
%   calculation; none looks a value up.
fig_attribute(Vs, sides(N))              :- fig_sides(Vs, N).
fig_attribute(Vs, name(Name))            :- fig_name(Vs, Name).
fig_attribute(Vs, right_angles(K))       :- fig_right_angle_count(Vs, K).
fig_attribute(Vs, acute_angles(K))       :-
    fig_angle_classes(Vs, Cs), include(==(acute), Cs, L), length(L, K).
fig_attribute(Vs, obtuse_angles(K))      :-
    fig_angle_classes(Vs, Cs), include(==(obtuse), Cs, L), length(L, K).
fig_attribute(Vs, parallel_pairs(K))     :- fig_parallel_pairs(Vs, K).
fig_attribute(Vs, perpendicular_pairs(K)):- fig_perpendicular_pairs(Vs, K).
fig_attribute(Vs, lines_of_symmetry(K))  :- fig_symmetry_axis_count(Vs, K).
fig_attribute(Vs, area(A))               :- fig_area(Vs, A).
fig_attribute(Vs, all_sides_equal)       :-
    fig_side_lengths2(Vs, Squares), sort(Squares, [_]).
fig_attribute(Vs, all_angles_equal)      :-
    fig_angle_classes(Vs, Classes), sort(Classes, [Class]),
    fig_sides(Vs, N),
    (   N =:= 4
    ->  Class == right
    ;   fig_side_lengths2(Vs, Squares), sort(Squares, [_])
    ).
fig_attribute(Vs, equal_side_pairs(K))   :-
    fig_side_lengths2(Vs, Squares),
    findall(I-J, ( nth0(I, Squares, L), nth0(J, Squares, L), I < J ), Pairs),
    length(Pairs, K).
fig_attribute(Vs, convex)                :- fig_convex(Vs).
fig_attribute(Vs, concave)               :- \+ fig_convex(Vs).
fig_attribute(Vs, perimeter(P))          :- fig_perimeter(Vs, P).

%!  fig_attributes(+Vertices, -Attributes) is det.
fig_attributes(Vs, Attributes) :-
    findall(A, fig_attribute(Vs, A), Raw),
    sort(Raw, Attributes).

%!  fig_holds(+Vertices, +Condition) is semidet.
%
%   Condition vocabulary for the constraint lists lessons print. Each condition
%   reduces to a computed attribute, and a comparison is a comparison, never a
%   lookup.
fig_holds(Vs, at_least(Attr, N))  :- fig_attribute(Vs, A), A =.. [F, V], Attr =.. [F], V >= N.
fig_holds(Vs, at_most(Attr, N))   :- fig_attribute(Vs, A), A =.. [F, V], Attr =.. [F], V =< N.
fig_holds(Vs, exactly(Attr, N))   :- fig_attribute(Vs, A), A =.. [F, V], Attr =.. [F], V =:= N.
fig_holds(Vs, Attr)               :- fig_attribute(Vs, Attr).
fig_holds(Vs, not(Cond))          :- \+ fig_holds(Vs, Cond).
fig_holds(Vs, sides_fewer_than(N)):- fig_sides(Vs, S), S < N.
fig_holds(Vs, sides_more_than(N)) :- fig_sides(Vs, S), S > N.
fig_holds(Vs, side_length_count(L, K)) :-
    fig_side_lengths2(Vs, Squares),
    L2 is L*L,
    include(==(L2), Squares, Matching),
    length(Matching, K).

%!  fig_translate(+Vertices, +Offset, -Moved) is det.
fig_translate(Vs, DX-DY, Moved) :-
    maplist(translate_vertex(DX, DY), Vs, Moved).

translate_vertex(DX, DY, X-Y, MX-MY) :-
    MX is X + DX,
    MY is Y + DY.

% =============================================================================
% What the lattice cannot hold
% =============================================================================

%!  lattice_unrealizable(?Shape, -Argument) is nondet.
%
%   Shapes with no integer-vertex realization, each with the argument that
%   rules it out. These are limits of the representation, stated rather than
%   worked around: a construction search reports them instead of returning a
%   near miss.
lattice_unrealizable(equilateral_triangle,
    'Integer vertices give an area that is half an integer by the shoelace sum, while an equilateral triangle of side s has area s^2*sqrt(3)/4, irrational for every rational s^2. No integer-vertex triangle is equilateral.').
lattice_unrealizable(regular_pentagon,
    'A regular pentagon on the lattice yields a strictly smaller one by rotating each vertex about its neighbour, and that descent has no least element among the positive integers.').
lattice_unrealizable(regular_hexagon,
    'A regular hexagon carries an equilateral triangle on three of its vertices, so the equilateral argument rules it out too.').

% =============================================================================
% The canonical inventory
% =============================================================================

%!  canonical_figure(?Id, ?Family, ?Vertices) is nondet.
%
%   A figure set standing in for the shape cards a guide names but does not
%   print. Each entry carries only a vertex list; the family atom is a filing
%   aid, and every claim a form makes about the figure is recomputed from the
%   vertices. Reading the family atom as evidence would be the
%   label-instead-of-calculation error this module exists to avoid.
canonical_figure(sq_4,           quadrilateral, [0-0, 4-0, 4-4, 0-4]).
canonical_figure(sq_2,           quadrilateral, [0-0, 2-0, 2-2, 0-2]).
canonical_figure(rect_6x3,       quadrilateral, [0-0, 6-0, 6-3, 0-3]).
canonical_figure(rect_5x2,       quadrilateral, [0-0, 5-0, 5-2, 0-2]).
canonical_figure(rhombus_5,      quadrilateral, [0-0, 3-4, 8-4, 5-0]).
canonical_figure(parallelo_1,    quadrilateral, [0-0, 5-0, 7-3, 2-3]).
canonical_figure(trapezoid_1,    quadrilateral, [0-0, 6-0, 4-3, 1-3]).
canonical_figure(trapezoid_iso,  quadrilateral, [0-0, 6-0, 5-3, 1-3]).
canonical_figure(trapezoid_right, quadrilateral, [0-0, 6-0, 3-3, 0-3]).
canonical_figure(kite_1,         quadrilateral, [0-0, 2-3, 0-8, -2-3]).
canonical_figure(quad_general,   quadrilateral, [0-0, 5-0, 6-4, 2-2]).
canonical_figure(quad_dart,      quadrilateral, [0-0, 3-2, 0-1, -3-2]).

canonical_figure(tri_right_iso,   triangle, [0-0, 4-0, 0-4]).
canonical_figure(tri_right_scal,  triangle, [0-0, 4-0, 0-3]).
canonical_figure(tri_acute_scal,  triangle, [0-0, 6-0, 2-3]).
canonical_figure(tri_acute_iso,   triangle, [0-0, 6-0, 3-5]).
canonical_figure(tri_obtuse_scal, triangle, [0-0, 7-0, 1-2]).
canonical_figure(tri_obtuse_iso,  triangle, [0-0, 8-0, 4-1]).

canonical_figure(pent_1, polygon, [0-0, 4-0, 5-3, 2-5, -1-3]).
canonical_figure(hex_1,  polygon, [0-0, 3-0, 5-2, 4-5, 1-5, -1-2]).

%!  canonical_family(?Family, -Ids) is nondet.
canonical_family(Family, Ids) :-
    setof(F, I^V^canonical_figure(I, F, V), Families),
    member(Family, Families),
    findall(Id, canonical_figure(Id, Family, _), Ids).

% =============================================================================
% Pattern blocks, letterforms, solids
% =============================================================================

%!  pattern_block(?Name, ?TriangleUnits, ?Sides) is nondet.
%
%   The four commensurable pattern blocks, measured in green triangles. Areas
%   drive every composition count downstream.
pattern_block(green_triangle, 1, 3).
pattern_block(blue_rhombus,   2, 4).
pattern_block(red_trapezoid,  3, 4).
pattern_block(yellow_hexagon, 6, 6).

%!  pattern_block_note(-Note) is det.
pattern_block_note(
    'The orange square and the tan rhombus are left out: neither area is a whole number of green triangles, so no count of triangles measures them and they cannot enter a composition tally.').

%!  letterform(?Letter, -Segments) is nondet.
%
%   Block capitals as straight-stroke skeletons, each segment a pair of
%   endpoints. Lessons asking which letters carry parallel or intersecting
%   segments are answered by computing over these strokes.
letterform('W', [(0-4)-(1-0), (1-0)-(2-4), (2-4)-(3-0), (3-0)-(4-4)]).
letterform('H', [(0-0)-(0-4), (2-0)-(2-4), (0-2)-(2-2)]).
letterform('A', [(0-0)-(2-4), (2-4)-(4-0), (1-2)-(3-2)]).
letterform('L', [(0-4)-(0-0), (0-0)-(2-0)]).
letterform('E', [(0-0)-(0-4), (0-4)-(2-4), (0-2)-(2-2), (0-0)-(2-0)]).
letterform('J', [(2-4)-(2-1), (2-1)-(0-1)]).
letterform('O', [(0-1)-(0-3), (0-3)-(2-3), (2-3)-(2-1), (2-1)-(0-1)]).
letterform('Y', [(0-4)-(1-2), (2-4)-(1-2), (1-2)-(1-0)]).
letterform('F', [(0-0)-(0-4), (0-4)-(2-4), (0-2)-(2-2)]).
letterform('U', [(0-4)-(0-1), (0-1)-(2-1), (2-1)-(2-4)]).
letterform('N', [(0-0)-(0-4), (0-4)-(2-0), (2-0)-(2-4)]).
letterform('K', [(0-0)-(0-4), (2-4)-(0-2), (0-2)-(2-0)]).
letterform('I', [(1-0)-(1-4)]).
letterform('T', [(0-4)-(2-4), (1-4)-(1-0)]).
letterform('S', [(2-4)-(0-4), (0-4)-(0-2), (0-2)-(2-2), (2-2)-(2-0), (2-0)-(0-0)]).

%!  letterform_note(-Note) is det.
letterform_note(
    'These are block capitals with straight strokes. O, S, U and J are round in most typefaces, so a letter answer holds for this drawing of the letter and not for every drawing of it.').

%!  solid_prism(?Name, ?L, ?W, ?H) is nondet.
solid_prism(cube_1,      1, 1, 1).
solid_prism(prism_2x3x2, 2, 3, 2).
solid_prism(prism_1x2x6, 1, 2, 6).
solid_prism(prism_3x4x5, 3, 4, 5).

%!  rectangles_with_area(+Area, -Pairs) is det.
%
%   Every whole-number Width-Height with Width =< Height whose product is Area.
rectangles_with_area(Area, Pairs) :-
    findall(W-H,
            ( between(1, Area, W),
              0 is Area mod W,
              H is Area // W,
              W =< H ),
            Pairs).

%!  boxes_with_volume(+Volume, -Triples) is det.
%
%   Every whole-number L-W-H with L =< W =< H whose product is Volume.
boxes_with_volume(Volume, Triples) :-
    findall(L-W-H,
            ( between(1, Volume, L),
              0 is Volume mod L,
              Rest is Volume // L,
              between(L, Rest, W),
              0 is Rest mod W,
              H is Rest // W,
              W =< H ),
            Triples).

% =============================================================================
% Hexominoes and the cube-net decision
% =============================================================================

%!  hexomino(-Cells) is nondet.
%
%   Every six-cell edge-connected polyomino, produced by growth from a single
%   cell and reduced to one representative per shape under the eight lattice
%   symmetries. Nothing is tabulated; the set is generated.
hexomino(Cells) :-
    findall(C, hexomino_canonical(C), Raw),
    sort(Raw, All),
    member(Cells, All).

hexomino_canonical(Canon) :-
    grow([0-0], 5, Cells),
    canonical_polyomino(Cells, Canon).

grow(Cells, 0, Sorted) :- !, msort(Cells, Sorted).
grow(Cells, N, Out) :-
    N > 0,
    member(X-Y, Cells),
    neighbour(X-Y, NX-NY),
    \+ memberchk(NX-NY, Cells),
    N1 is N - 1,
    grow([NX-NY | Cells], N1, Out).

neighbour(X-Y, NX-Y) :- NX is X + 1.
neighbour(X-Y, NX-Y) :- NX is X - 1.
neighbour(X-Y, X-NY) :- NY is Y + 1.
neighbour(X-Y, X-NY) :- NY is Y - 1.

canonical_polyomino(Cells, Canon) :-
    findall(Norm,
            ( symmetry_image(Cells, Image), normalize_cells(Image, Norm) ),
            Images),
    msort(Images, [Canon | _]).

symmetry_image(Cells, Image) :-
    member(T, [id, r90, r180, r270, fx, fy, fd, fa]),
    maplist(apply_symmetry(T), Cells, Image).

apply_symmetry(id,   X-Y, X-Y).
apply_symmetry(r90,  X-Y, NY-X)  :- NY is -Y.
apply_symmetry(r180, X-Y, NX-NY) :- NX is -X, NY is -Y.
apply_symmetry(r270, X-Y, Y-NX)  :- NX is -X.
apply_symmetry(fx,   X-Y, X-NY)  :- NY is -Y.
apply_symmetry(fy,   X-Y, NX-Y)  :- NX is -X.
apply_symmetry(fd,   X-Y, Y-X).
apply_symmetry(fa,   X-Y, NY-NX) :- NY is -Y, NX is -X.

normalize_cells(Cells, Norm) :-
    findall(X, member(X-_, Cells), Xs),
    findall(Y, member(_-Y, Cells), Ys),
    min_list(Xs, MinX), min_list(Ys, MinY),
    findall(NX-NY,
            ( member(X-Y, Cells), NX is X - MinX, NY is Y - MinY ),
            Shifted),
    msort(Shifted, Norm).

%!  cube_net_foldable(+Cells) is semidet.
%
%   Roll a cube over the arrangement and check that six different faces land.
%   Each step to a neighbouring cell tips the cube over that edge, so the face
%   touching the paper changes in a fixed way, and the arrangement folds to a
%   cube exactly when a different face lands on every cell. Faces are 1..6 and
%   opposite faces sum to 7. Rolling around a closed loop returns the same face
%   to the paper, so the face on a cell does not depend on the route taken to
%   reach it.
cube_net_foldable(Cells) :-
    length(Cells, 6),
    Cells = [Start | _],
    fold_walk([Start-cube(1, 2, 3)], Cells, [], Assigned),
    length(Assigned, 6),
    findall(F, member(_-F, Assigned), Faces),
    sort(Faces, Sorted),
    length(Sorted, 6).

fold_walk([], _, Acc, Acc).
fold_walk([Cell-State | Queue], Cells, Acc, Out) :-
    (   memberchk(Cell-_, Acc)
    ->  fold_walk(Queue, Cells, Acc, Out)
    ;   State = cube(Down, _, _),
        findall(Next-NextState,
                ( step_direction(Cell, Cells, Acc, Next, Dir),
                  roll(Dir, State, NextState) ),
                Successors),
        append(Queue, Successors, Queue1),
        fold_walk(Queue1, Cells, [Cell-Down | Acc], Out)
    ).

step_direction(X-Y, Cells, Acc, NX-NY, Dir) :-
    member(Dir-DX-DY, [east-1-0, west-(-1)-0, north-0-1, south-0-(-1)]),
    NX is X + DX, NY is Y + DY,
    memberchk(NX-NY, Cells),
    \+ memberchk((NX-NY)-_, Acc).

roll(east,  cube(D, N, E), cube(D1, N, D))  :- D1 is 7 - E.
roll(west,  cube(D, N, E), cube(E, N, E1))  :- E1 is 7 - D.
roll(north, cube(D, N, E), cube(N, N1, E))  :- N1 is 7 - D.
roll(south, cube(D, N, E), cube(D1, D, E))  :- D1 is 7 - N.
