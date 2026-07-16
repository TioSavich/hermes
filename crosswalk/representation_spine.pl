/** <module> Representation spine crosswalk

Read-only Prolog surface for the visual representation spine. `renders_on/3`
records current concept-to-surface routing. `asset_for/3` exposes the generated
representation asset manifest without turning generated JSON into hand-authored
facts.
*/
:- module(representation_spine,
          [ renders_on/3,   % ?Concept, ?Surface, ?DataShape
            asset_for/3     % ?Concept, ?Asset, ?Provenance
          ]).

:- use_module(library(http/json)).
:- use_module(library(lists), [member/2]).

:- dynamic asset_manifest_cache/1.
:- dynamic asset_manifest_path/1.

:- prolog_load_context(directory, CrosswalkDir),
   directory_file_path(CrosswalkDir, '../representation/asset_manifest.json', ManifestPath),
   asserta(asset_manifest_path(ManifestPath)).

renders_on(unit_fraction_partition, fraction_bars, fraction_bar_scene).
renders_on(unit_fraction_iteration, fraction_bars, fraction_bar_scene).
renders_on(fraction_number_line_measure, number_line, number_line_scene).
renders_on(set_grouping, set_model, set_grouping_scene).
renders_on(base_ten_place_value, base_ten_blocks, base_ten_scene).
renders_on(balance_preservation_schema, balance_scale, balance_scene).
renders_on(quadrilateral_hierarchy, geometry_gallery, docling_figure_scene).
renders_on(coordinate_plane_plotting, coordinate_plane, coordinate_plane_scene).
renders_on(rigid_motion_transformation, rigid_motion, rigid_motion_scene).
renders_on(polyform_tiling_composition, polyform_tiling, polyform_tiling_scene).
renders_on(angle_measure_turning, angle_circular, angle_circular_scene).
renders_on(data_display_distribution, data_display, data_display_scene).
renders_on(solid_net_folding, solid_net, solid_net_scene).
renders_on(geoboard_polygon_area, geoboard, geoboard_scene).


asset_for(Concept, Asset, asset_manifest(Source, Id)) :-
    asset_manifest_entry(Entry),
    asset_entry_concept(Entry, Concept),
    dict_atom(Entry, source, Source),
    dict_atom(Entry, id, Id),
    format(atom(Asset), 'representation/asset_manifest.json#~w', [Id]).

asset_manifest_entry(Entry) :-
    asset_manifest(Manifest),
    get_dict(assets, Manifest, Assets),
    member(Entry, Assets).

asset_manifest(Manifest) :-
    asset_manifest_cache(Manifest),
    !.
asset_manifest(Manifest) :-
    asset_manifest_path(Path),
    setup_call_cleanup(
        open(Path, read, In, [encoding(utf8)]),
        json_read_dict(In, Manifest),
        close(In)
    ),
    asserta(asset_manifest_cache(Manifest)).

asset_entry_concept(Entry, Concept) :-
    get_dict(prolog_concepts, Entry, Concepts),
    member(ConceptText, Concepts),
    prolog_concept_atom(ConceptText, Concept).
asset_entry_concept(Entry, Concept) :-
    get_dict(domains, Entry, Domains),
    member(DomainText, Domains),
    value_atom(DomainText, Concept).
asset_entry_concept(Entry, Concept) :-
    dict_atom(Entry, representation_language, Concept).

prolog_concept_atom(Text, unit_fraction_partition) :-
    sub_text(Text, 'unit_fraction_partition'),
    !.
prolog_concept_atom(Text, unit_fraction_iteration) :-
    sub_text(Text, 'unit_fraction_iteration'),
    !.
prolog_concept_atom(Text, area_model_part_of_part) :-
    sub_text(Text, 'area_model_part_of_part'),
    !.
prolog_concept_atom(Text, cross_multiplication_rule_from_pattern) :-
    sub_text(Text, 'cross_multiplication_rule_from_pattern'),
    !.
prolog_concept_atom(Text, quadrilateral_hierarchy) :-
    sub_text(Text, 'quadrilateral_hierarchy'),
    !.
prolog_concept_atom(Text, area_as_interior_coverage) :-
    sub_text(Text, 'area_as_interior_coverage'),
    !.
prolog_concept_atom(Text, length_measurement_as_unit_iteration) :-
    sub_text(Text, 'length_measurement_as_unit_iteration'),
    !.
prolog_concept_atom(Text, object_construction) :-
    sub_text(Text, 'object_construction'),
    !.
prolog_concept_atom(Text, motion_along_path) :-
    sub_text(Text, 'motion_along_path'),
    !.
prolog_concept_atom(Text, object_collection) :-
    sub_text(Text, 'object_collection'),
    !.
prolog_concept_atom(Text, balance_preservation_schema) :-
    sub_text(Text, 'balance_preservation_schema'),
    !.

sub_text(Text, Needle) :-
    string(Text),
    sub_string(Text, _, _, _, Needle).
sub_text(Text, Needle) :-
    atom(Text),
    sub_atom(Text, _, _, _, Needle).

dict_atom(Dict, Key, Atom) :-
    get_dict(Key, Dict, Value),
    value_atom(Value, Atom).

value_atom(Value, Atom) :-
    atom(Value),
    !,
    Atom = Value.
value_atom(Value, Atom) :-
    string(Value),
    !,
    atom_string(Atom, Value).
