/** <module> Unit Coordination and Fractalization Visualizer
 *
 * This module generates SVG visualizations demonstrating the mathematical
 * duality between:
 *   1. Coordinating Units (scaling up: units -> rods -> flats -> cubes in base B)
 *   2. Fractalizing Units (scaling down: whole -> parts -> subparts -> sub-subparts in denominator D)
 *
 * Generated SVGs are completely self-contained, requiring zero external
 * javascript, stylesheets, or CDNs.
 */

:- module(unit_coordination_viz,
          [ generate_coordination_svg/4,
            save_coordination_svg/4
          ]).

:- use_module(library(lists)).

%!  save_coordination_svg(+File, +Base, +ValUp, +ValDown) is det.
%
%   Generate the SVG visualization and save it directly to a file.
save_coordination_svg(File, Base, ValUp, ValDown) :-
    generate_coordination_svg(Base, ValUp, ValDown, SVGString),
    setup_call_cleanup(
        open(File, write, Out, [encoding(utf8)]),
        write(Out, SVGString),
        close(Out)
    ).

%!  generate_coordination_svg(+Base, +ValUp, +ValDown, -SVGString) is det.
%
%   Generates a self-contained, beautifully styled SVG demonstrating the
%   tenuous connection between coordinating units in Base and partitioning them.
%
%   @arg Base       The active base system (integer 2 to 15).
%   @arg ValUp      Value to scale up (integer count of units).
%   @arg ValDown    Value to scale down (either fraction(N, D) or integer N).
generate_coordination_svg(Base, ValUp, ValDown, SVGString) :-
    integer(Base), Base >= 2, Base =< 15,
    integer(ValUp), ValUp >= 0,
    parse_val_down(ValDown, Base, Num, Den),
    
    % Compute base components
    compute_base_digits(ValUp, Base, Cubes, Flats, Rods, Units),
    
    % Generate SVG elements
    svg_header(Header),
    svg_defs(Defs),
    svg_background(Bg),
    
    % Panels
    svg_left_panel(Base, ValUp, Cubes, Flats, Rods, Units, LeftPanel),
    svg_right_panel(Base, Num, Den, RightPanel),
    svg_divider(Divider),
    svg_footer(Base, Den, Footer),
    
    svg_close(Close),
    
    % Assemble everything
    atomic_list_concat([
        Header,
        Defs,
        Bg,
        LeftPanel,
        Divider,
        RightPanel,
        Footer,
        Close
    ], SVGString).

% Parse ValDown into Numerator and Denominator
parse_val_down(fraction(Num, Den), _Base, Num, Den) :-
    integer(Num), integer(Den), Den > 0, !.
parse_val_down(Num, Base, Num, Base) :-
    integer(Num), !.
parse_val_down(_, Base, 1, Base).

% Compute B^3, B^2, B^1, B^0 components
compute_base_digits(Val, Base, Cubes, Flats, Rods, Units) :-
    B2 is Base * Base,
    B3 is B2 * Base,
    Cubes is Val // B3,
    Rem3 is Val mod B3,
    Flats is Rem3 // B2,
    Rem2 is Rem3 mod B2,
    Rods is Rem2 // Base,
    Units is Rem2 mod Base.

% Base digits to letters mapping (digits 10-14 mapped to T, E, D, R, F)
digit_char(D, C) :- D >= 0, D =< 9, Code is 48 + D, char_code(C, Code), !.
digit_char(10, 'T') :- !.
digit_char(11, 'E') :- !.
digit_char(12, 'D') :- !.
digit_char(13, 'R') :- !.
digit_char(14, 'F') :- !.
digit_char(15, 'A') :- !.
digit_char(_, '?').

value_in_base(Val, Base, BaseStr) :-
    ( Val == 0 -> BaseStr = "0"
    ; value_in_base_rec(Val, Base, Acc),
      reverse(Acc, Rev),
      maplist(digit_char, Rev, Chars),
      atomic_list_concat(Chars, BaseStr)
    ).

value_in_base_rec(0, _, []) :- !.
value_in_base_rec(Val, Base, [Digit|Rest]) :-
    Digit is Val mod Base,
    Val1 is Val // Base,
    value_in_base_rec(Val1, Base, Rest).

% SVG Generators
svg_header(Header) :-
    Header = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 850 520" width="100%" height="100%" style="background-color: #0d0c15; font-family: system-ui, -apple-system, sans-serif; user-select: none;">\n'.

svg_close('</svg>\n').

svg_defs(Defs) :-
    Defs = '  <defs>
    <!-- Dark glassmorphism card gradient -->
    <linearGradient id="cardGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#1e1b30" stop-opacity="0.75"/>
      <stop offset="100%" stop-color="#121020" stop-opacity="0.9"/>
    </linearGradient>
    <linearGradient id="dividerGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#2a2444" stop-opacity="0.1"/>
      <stop offset="50%" stop-color="#4c427c" stop-opacity="0.8"/>
      <stop offset="100%" stop-color="#2a2444" stop-opacity="0.1"/>
    </linearGradient>
    <!-- Level-based gradients -->
    <!-- Level 3: 3D Cubes (Crimson Red) -->
    <linearGradient id="cubeTop" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#f87171"/><stop offset="100%" stop-color="#ef4444"/>
    </linearGradient>
    <linearGradient id="cubeLeft" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#dc2626"/><stop offset="100%" stop-color="#991b1b"/>
    </linearGradient>
    <linearGradient id="cubeRight" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#b91c1c"/><stop offset="100%" stop-color="#7f1d1d"/>
    </linearGradient>
    <!-- Level 2: Flats (Amber Orange) -->
    <linearGradient id="flatGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#fbbf24"/><stop offset="100%" stop-color="#d97706"/>
    </linearGradient>
    <!-- Level 1: Rods (Emerald Green) -->
    <linearGradient id="rodGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#34d399"/><stop offset="100%" stop-color="#059669"/>
    </linearGradient>
    <!-- Level 0 / Base unit: Sleek Blue -->
    <linearGradient id="unitGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#60a5fa"/><stop offset="100%" stop-color="#2563eb"/>
    </linearGradient>
    <!-- Glow filter for Snap events / Highlights -->
    <filter id="glow" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur stdDeviation="6" result="blur" />
      <feComposite in="SourceGraphic" in2="blur" operator="over" />
    </filter>
  </defs>\n'.

svg_background(Bg) :-
    Bg = '  <!-- Title & Subtitle -->
  <text x="30" y="45" font-size="22" font-weight="700" fill="#f3f4f6" letter-spacing="0.05em">THE SPATIAL GRAMMAR OF UNITS</text>
  <text x="30" y="68" font-size="12" font-weight="500" fill="#7c769b" letter-spacing="0.03em">Composition (Base Systems) &amp; Decomposition (Fractional Parts) Duality</text>\n'.

svg_divider(Divider) :-
    Divider = '  <!-- Vertical Divider -->
  <line x1="425" y1="95" x2="425" y2="445" stroke="url(#dividerGrad)" stroke-width="2"/>\n'.

% LEFT PANEL: Composition Blocks
svg_left_panel(Base, Val, Cubes, Flats, Rods, Units, LeftPanel) :-
    value_in_base(Val, Base, BaseStr),
    
    % Panel header
    format(string(LHeader),
           '  <!-- Left Panel: Scaling Up -->
  <g transform="translate(30, 95)">
    <rect width="365" height="350" rx="10" fill="url(#cardGrad)" stroke="#221e3b" stroke-width="1.5"/>
    <text x="20" y="32" font-size="15" font-weight="600" fill="#f3f4f6" letter-spacing="0.05em">COORDINATING UNITS (Composition)</text>
    <text x="20" y="52" font-size="11" fill="#9ca3af">Base B = ~w  |  Count = ~w (Base 10)  |  Result = ~w (~w)</text>\n',
           [Base, Val, BaseStr, Base]),
           
    % Block components
    svg_cube_component(Cubes, Base, CubeSvg),
    svg_flat_component(Flats, Base, FlatSvg),
    svg_rod_component(Rods, Base, RodSvg),
    svg_unit_component(Units, UnitSvg),
    
    % Panel footer / summary
    LFooter = '  </g>\n',
    
    atomic_list_concat([LHeader, CubeSvg, FlatSvg, RodSvg, UnitSvg, LFooter], LeftPanel).

% Draw Cube components
svg_cube_component(Count, Base, Svg) :-
    B3 is Base * Base * Base,
    format(string(Label), '~w \u00d7 Cubes (~w\u00b3 = ~w)', [Count, Base, B3]),
    cube_3d_svg(60, 130, 30, 15, 25, CubeBlock),
    format(string(Svg),
           '    <!-- Level 3: Cubes -->
    <g transform="translate(20, 75)">
      ~w
      <text x="90" y="30" font-size="13" font-weight="600" fill="#f3f4f6">~w</text>
      <text x="90" y="46" font-size="10" fill="#9ca3af">Representing Level 3 (B\u00b3 units per block)</text>
    </g>\n',
           [CubeBlock, Label]).

% Draw Flat components
svg_flat_component(Count, Base, Svg) :-
    B2 is Base * Base,
    format(string(Label), '~w \u00d7 Flats (~w\u00b2 = ~w)', [Count, Base, B2]),
    flat_svg(60, 205, 50, Base, FlatBlock),
    format(string(Svg),
           '    <!-- Level 2: Flats -->
    <g transform="translate(20, 155)">
      ~w
      <text x="90" y="30" font-size="13" font-weight="600" fill="#f3f4f6">~w</text>
      <text x="90" y="46" font-size="10" fill="#9ca3af">Representing Level 2 (B\u00b2 units per flat)</text>
    </g>\n',
           [FlatBlock, Label]).

% Draw Rod components
svg_rod_component(Count, Base, Svg) :-
    format(string(Label), '~w \u00d7 Rods (B = ~w)', [Count, Base]),
    rod_svg(60, 260, 50, Base, RodBlock),
    format(string(Svg),
           '    <!-- Level 1: Rods -->
    <g transform="translate(20, 235)">
      ~w
      <text x="90" y="25" font-size="13" font-weight="600" fill="#f3f4f6">~w</text>
      <text x="90" y="41" font-size="10" fill="#9ca3af">Representing Level 1 (B units per rod)</text>
    </g>\n',
           [RodBlock, Label]).

% Draw Unit components
svg_unit_component(Count, Svg) :-
    format(string(Label), '~w \u00d7 Units', [Count]),
    unit_svg(60, 310, 15, UnitBlock),
    format(string(Svg),
           '    <!-- Level 0: Units -->
    <g transform="translate(20, 305)">
      ~w
      <text x="90" y="20" font-size="13" font-weight="600" fill="#f3f4f6">~w</text>
      <text x="90" y="36" font-size="10" fill="#9ca3af">Representing Level 0 (1 unit)</text>
    </g>\n',
           [UnitBlock, Label]).

% Helper for drawing isometric 3D cube
cube_3d_svg(CX, CY, DX, DY, H, Svg) :-
    % Left face
    LX1 is CX, LY1 is CY,
    LX2 is CX - DX, LY2 is CY - DY,
    LX3 is CX - DX, LY3 is CY - DY + H,
    LX4 is CX, LY4 is CY + H,
    % Right face
    RX1 is CX, RY1 is CY,
    RX2 is CX + DX, RY2 is CY - DY,
    RX3 is CX + DX, RY3 is CY - DY + H,
    RX4 is CX, RY4 is CY + H,
    % Top face
    TX1 is CX, TY1 is CY,
    TX2 is CX + DX, TY2 is CY - DY,
    TX3 is CX, TY3 is CY - DY - DY,
    TX4 is CX - DX, TY4 is CY - DY,
    format(string(Svg),
           '<g>
        <path d="M ~w,~w L ~w,~w L ~w,~w L ~w,~w Z" fill="url(#cubeTop)" stroke="#ef4444" stroke-width="0.5"/>
        <path d="M ~w,~w L ~w,~w L ~w,~w L ~w,~w Z" fill="url(#cubeLeft)" stroke="#b91c1c" stroke-width="0.5"/>
        <path d="M ~w,~w L ~w,~w L ~w,~w L ~w,~w Z" fill="url(#cubeRight)" stroke="#7f1d1d" stroke-width="0.5"/>
      </g>',
           [TX1, TY1, TX2, TY2, TX3, TY3, TX4, TY4,
            LX1, LX2, LX3, LX4, LY1, LY2, LY3, LY4,
            RX1, RX2, RX3, RX4, RY1, RY2, RY3, RY4]).

% Helper for flat
flat_svg(CX, CY, Size, Base, Svg) :-
    X is CX - Size / 2,
    Y is CY - Size / 2,
    grid_lines_svg(X, Y, Size, Base, GridLines),
    format(string(Svg),
           '<g>
        <rect x="~w" y="~w" width="~w" height="~w" fill="url(#flatGrad)" rx="3" stroke="#d97706" stroke-width="1"/>
        ~w
      </g>',
           [X, Y, Size, Size, GridLines]).

% Helper for rod
rod_svg(CX, CY, Width, Base, Svg) :-
    X is CX - Width / 2,
    Y is CY - 7,
    Height = 14,
    grid_lines_vertical(X, Y, Width, Height, 1, Base, GridLines),
    format(string(Svg),
           '<g>
        <rect x="~w" y="~w" width="~w" height="~w" fill="url(#rodGrad)" rx="2" stroke="#059669" stroke-width="1"/>
        ~w
      </g>',
           [X, Y, Width, Height, GridLines]).

% Helper for single unit
unit_svg(CX, CY, Size, Svg) :-
    X is CX - Size / 2,
    Y is CY - Size / 2,
    format(string(Svg),
           '<rect x="~w" y="~w" width="~w" height="~w" fill="url(#unitGrad)" rx="1" stroke="#2563eb" stroke-width="1"/>',
           [X, Y, Size, Size]).

% Generate vertical + horizontal grid lines inside a box
grid_lines_svg(X, Y, Size, Base, GridLines) :-
    Step is Size / Base,
    grid_lines_v_loop(X, Y, Size, Step, 1, Base, VLines),
    grid_lines_h_loop(X, Y, Size, Step, 1, Base, HLines),
    atomic_list_concat([VLines, HLines], GridLines).

grid_lines_v_loop(_, _, _, _, I, Base, '') :- I >= Base, !.
grid_lines_v_loop(X, Y, Size, Step, I, Base, Svg) :-
    LX is X + I * Step,
    LY2 is Y + Size,
    format(string(Line), '<line x1="~w" y1="~w" x2="~w" y2="~w" stroke="#78350f" stroke-width="0.5" opacity="0.6"/>\n', [LX, Y, LX, LY2]),
    I1 is I + 1,
    grid_lines_v_loop(X, Y, Size, Step, I1, Base, Rest),
    atom_concat(Line, Rest, Svg).

grid_lines_h_loop(_, _, _, _, I, Base, '') :- I >= Base, !.
grid_lines_h_loop(X, Y, Size, Step, I, Base, Svg) :-
    LY is Y + I * Step,
    LX2 is X + Size,
    format(string(Line), '<line x1="~w" y1="~w" x2="~w" y2="~w" stroke="#78350f" stroke-width="0.5" opacity="0.6"/>\n', [X, LY, LX2, LY]),
    I1 is I + 1,
    grid_lines_h_loop(X, Y, Size, Step, I1, Base, Rest),
    atom_concat(Line, Rest, Svg).

grid_lines_vertical(_, _, _, _, I, Base, '') :- I >= Base, !.
grid_lines_vertical(X, Y, Width, Height, I, Base, Svg) :-
    Step is Width / Base,
    LX is X + Step,
    LY2 is Y + Height,
    format(string(Line), '<line x1="~w" y1="~w" x2="~w" y2="~w" stroke="#047857" stroke-width="0.5" opacity="0.6"/>\n', [LX, Y, LX, LY2]),
    X1 is X + Step,
    I1 is I + 1,
    grid_lines_vertical(X1, Y, Width, Height, I1, Base, Rest),
    atom_concat(Line, Rest, Svg).


% RIGHT PANEL: Fractalizing Units (Fractions)
svg_right_panel(Base, Num, Den, RightPanel) :-
    % Compute fraction properties
    Value is Num / Den,
    format(string(FractionLabel), '~w/~w', [Num, Den]),
    
    % Panel header
    format(string(RHeader),
           '  <!-- Right Panel: Scaling Down -->
  <g transform="translate(455, 95)">
    <rect width="365" height="350" rx="10" fill="url(#cardGrad)" stroke="#221e3b" stroke-width="1.5"/>
    <text x="20" y="32" font-size="15" font-weight="600" fill="#f3f4f6" letter-spacing="0.05em">FRACTALIZING UNITS (Decomposition)</text>
    <text x="20" y="52" font-size="11" fill="#9ca3af">Denominator D = ~w  |  Fraction = ~w  |  Decimal Value \u2248 ~2f</text>\n',
           [Den, FractionLabel, Value]),
           
    % Bars
    % Whole bar (Level 0)
    svg_whole_bar_svg(WholeBar),
    
    % Partitioned bar (Level -1, partition into D parts, highlight N)
    svg_partitioned_bar_svg(Num, Den, PartBar),
    
    % Subpartitioned bar (Level -2, partition each segment into B parts, total D*B parts)
    svg_subpartitioned_bar_svg(Base, Num, Den, SubBar),
    
    RFooter = '  </g>\n',
    
    atomic_list_concat([RHeader, WholeBar, PartBar, SubBar, RFooter], RightPanel).

svg_whole_bar_svg(Svg) :-
    Svg = '    <!-- Level 0: The Whole -->
    <g transform="translate(20, 75)">
      <rect x="0" y="10" width="325" height="24" fill="url(#unitGrad)" rx="4" stroke="#1d4ed8" stroke-width="1"/>
      <text x="0" y="0" font-size="11" font-weight="600" fill="#f3f4f6">Level 0: The Whole (1 Unit)</text>
      <text x="162.5" y="26" font-size="10" fill="#ffffff" text-anchor="middle" font-weight="600" opacity="0.9">1</text>
    </g>\n'.

svg_partitioned_bar_svg(Num, Den, Svg) :-
    % Generate ticks and segments
    % Total width is 325. Each segment is 325/Den
    SegWidth is 325 / Den,
    generate_segments_svg(0, SegWidth, Num, Den, 24, Segments),
    format(string(Svg),
           '    <!-- Level -1: Partitioned Parts -->
    <g transform="translate(20, 165)">
      <text x="0" y="0" font-size="11" font-weight="600" fill="#f3f4f6">Level -1: Unit Fraction (Partition into D = ~w equal parts)</text>
      <!-- Base bar background -->
      <rect x="0" y="10" width="325" height="24" fill="#1f1b2c" rx="4" stroke="#4b5563" stroke-width="1"/>
      ~w
    </g>\n',
           [Den, Segments]).

generate_segments_svg(Index, _Width, _Num, Den, _Height, Svg) :-
    Index >= Den, !, Svg = ''.
generate_segments_svg(Index, Width, Num, Den, Height, Svg) :-
    X is Index * Width,
    ( Index < Num -> Fill = 'url(#rodGrad)', Stroke = '#059669'
    ; Fill = 'none', Stroke = '#4b5563'
    ),
    format(string(Seg),
           '<rect x="~w" y="10" width="~w" height="~w" fill="~w" stroke="~w" stroke-dasharray="0" stroke-width="1"/>
           <text x="~w" y="26" font-size="8" fill="#9ca3af" text-anchor="middle">1/~w</text>\n',
           [X, Width, Height, Fill, Stroke,
            X + Width/2, Den]),
    I1 is Index + 1,
    generate_segments_svg(I1, Width, Num, Den, Height, Rest),
    atom_concat(Seg, Rest, Svg).

svg_subpartitioned_bar_svg(Base, Num, Den, Svg) :-
    % Total partition parts = Den * Base. Total width = 325.
    TotalParts is Den * Base,
    SegWidth is 325 / TotalParts,
    % Highlight up to Num * Base parts
    HighlightUpTo is Num * Base,
    generate_subsegments_svg(0, SegWidth, HighlightUpTo, TotalParts, 24, Segments),
    format(string(Svg),
           '    <!-- Level -2: Subpartitioned Parts -->
    <g transform="translate(20, 255)">
      <text x="0" y="0" font-size="11" font-weight="600" fill="#f3f4f6">Level -2: Fractal Partition (Each segment split into B = ~w parts)</text>
      <text x="0" y="13" font-size="8" fill="#9ca3af">Total parts = ~w  |  Subunit size = 1/~w</text>
      <!-- Base bar background -->
      <rect x="0" y="20" width="325" height="24" fill="#1f1b2c" rx="4" stroke="#4b5563" stroke-width="1"/>
      ~w
    </g>\n',
           [Base, TotalParts, TotalParts, Segments]).

generate_subsegments_svg(Index, _Width, _Num, Den, _Height, Svg) :-
    Index >= Den, !, Svg = ''.
generate_subsegments_svg(Index, Width, Num, Den, Height, Svg) :-
    X is Index * Width,
    ( Index < Num -> Fill = 'url(#flatGrad)', Stroke = '#d97706'
    ; Fill = 'none', Stroke = '#374151'
    ),
    format(string(Seg),
           '<rect x="~w" y="20" width="~w" height="~w" fill="~w" stroke="~w" stroke-width="0.5"/>\n',
           [X, Width, Height, Fill, Stroke]),
    I1 is Index + 1,
    generate_subsegments_svg(I1, Width, Num, Den, Height, Rest),
    atom_concat(Seg, Rest, Svg).


svg_footer(Base, Den, Footer) :-
    ( Base == Den ->
        ConnectionText = 'SYNERGY DETECTED: The fraction partition denominator aligns with the arithmetic base. Scaling down matches the exact inverse of base coordination. Fractions are the decimals of this system.'
    ;
        ConnectionText = 'TENUOUS CONNECTION: Operating base B and fraction denominator D differ. Base coordination groups by B; fraction partitioning divides by D. Synergy occurs when D matches B.'
    ),
    format(string(Footer),
           '  <!-- Duality Connection Card -->
  <g transform="translate(30, 460)">
    <rect width="790" height="42" rx="6" fill="#161427" stroke="#2c2847" stroke-width="1"/>
    <text x="15" y="24" font-size="11" font-weight="600" fill="#fbbf24" letter-spacing="0.02em">SPATIAL SYNAPSE:</text>
    <text x="135" y="24" font-size="10.5" fill="#d1d5db">~w</text>
  </g>\n',
           [ConnectionText]).
