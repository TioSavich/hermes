/** <module> Cross-representation deformation comparison dispatcher */

:- module(deformation_comparison_scene,
          [ deformation_compare_json/3
          ]).

:- use_module(render(coordinate_plane_scene), []).
:- use_module(render(rigid_motion_scene), []).
:- use_module(render(polyform_tiling_scene), []).
:- use_module(render(angle_circular_scene), []).
:- use_module(render(data_display_scene), []).
:- use_module(render(solid_net_scene), []).
:- use_module(render(geoboard_scene), []).


deformation_compare_json(quadrant_sign_error, Spec, Dict) :-
    coordinate_plane_scene:coordinate_plane_compare_json(Spec, Dict).
deformation_compare_json(reflection_by_rotation, Spec, Dict) :-
    rigid_motion_scene:rigid_motion_compare_json(Spec, Dict).
deformation_compare_json(flip_needed, Spec, Dict) :-
    polyform_tiling_scene:polyform_tiling_compare_json(Spec, Dict).
deformation_compare_json(unfillable_by_parity, Spec, Dict) :-
    polyform_tiling_scene:polyform_tiling_compare_json(Spec, Dict).
deformation_compare_json(angle_confused_with_ray_length, Spec, Dict) :-
    angle_circular_scene:angle_circular_compare_json(Spec, Dict).
deformation_compare_json(bar_histogram_conflation, Spec, Dict) :-
    data_display_scene:data_display_compare_json(Spec, Dict).
deformation_compare_json(net_fold_failure, Spec, Dict) :-
    solid_net_scene:solid_net_compare_json(Spec, Dict).
deformation_compare_json(boundary_peg_as_interior, Spec, Dict) :-
    geoboard_scene:geoboard_compare_json(Spec, Dict).
