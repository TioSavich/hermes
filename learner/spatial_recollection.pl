/** <module> Spatial recollection evidence for learner reflection
 *
 * This adapter closes return paths from action to external representation and
 * back. Fraction bars reconstruct a unit plan from geometry; notation
 * reconstructs positional numerals and alternative action candidates from
 * glyph metadata. Each path retains its validation evidence for reflection.
 */

:- module(spatial_recollection,
          [ fraction_spatial_recollection/3,
            number_line_spatial_recollection/3,
            notation_recollection/2,
            notation_deformation_recollection/3,
            reflect_spatial_evidence/2
          ]).

:- use_module(render(fraction_bars_scene),
              [ fraction_render_json/4,
                fraction_scene_validation/5
              ]).
:- autoload(render(number_line_scene),
            [ number_line_plan_json/2,
              number_line_scene_plan/3
            ]).
:- use_module(render(notation_scene),
              [ notation_render_json/2,
                notation_scene_numeral/3,
                notation_scene_deformation/4
              ]).
:- use_module(math(recursive_unit_actions),
              [ numeral_equivalent/2,
                fraction_unit_plan/3,
                validate_fraction_candidate/4
              ]).


%!  fraction_spatial_recollection(+N, +D, -Evidence) is semidet.
fraction_spatial_recollection(N, D, Evidence) :-
    fraction_render_json(unit_fraction_iteration, N, D, Document),
    get_dict(frames, Document, Frames),
    last(Frames, FinalFrame),
    get_dict(scene, FinalFrame, Scene),
    fraction_scene_validation(N, D, Scene, ReconstructedPlan, Validation),
    Evidence = spatial_recollection{
        representation: fraction_bars,
        task: fraction(N, D),
        source: rendered_geometry,
        reconstructed_plan: ReconstructedPlan,
        validation: Validation
    }.


%!  number_line_spatial_recollection(+N, +D, -Evidence) is semidet.
number_line_spatial_recollection(N, D, Evidence) :-
    fraction_unit_plan(N, D, SourcePlan),
    number_line_plan_json(SourcePlan, Document),
    get_dict(frames, Document, Frames),
    last(Frames, FinalFrame),
    get_dict(scene, FinalFrame, Scene),
    number_line_scene_plan(Scene, ReconstructedPlan, Geometry),
    validate_fraction_candidate(N, D, ReconstructedPlan, Verdict),
    Evidence = spatial_recollection{
        representation: number_line,
        task: fraction(N, D),
        source: coordinate_geometry,
        reconstructed_plan: ReconstructedPlan,
        validation: scene_validation(Verdict, Geometry)
    }.


%!  notation_recollection(+Numeral, -Evidence) is semidet.
notation_recollection(Numeral, Evidence) :-
    notation_render_json(write_numeral(Numeral), Document),
    get_dict(frames, Document, Frames),
    last(Frames, FinalFrame),
    get_dict(scene, FinalFrame, Scene),
    notation_scene_numeral(Scene, Reconstructed, RecollectionEvidence),
    numeral_equivalent(Numeral, Reconstructed),
    get_dict(action_candidates, RecollectionEvidence, ActionCandidates),
    findall(Plan,
            member(action_candidate(Plan, _Trace), ActionCandidates),
            Plans),
    Evidence = spatial_recollection{
        representation: notation,
        task: numeral(Numeral),
        source: inscribed_glyph_metadata,
        reconstructed_plan: candidate_plans(Plans),
        validation: scene_validation(
                        licensed(equivalent_numeral),
                        RecollectionEvidence)
    }.


%!  notation_deformation_recollection(+Expected, +Kind, -Evidence) is semidet.
notation_deformation_recollection(Expected, Kind, Evidence) :-
    notation_render_json(write_deformed_numeral(Expected, Kind), Document),
    get_dict(frames, Document, Frames),
    last(Frames, FinalFrame),
    get_dict(scene, FinalFrame, Scene),
    notation_scene_deformation(Scene, Expected, Kind, Recollection),
    get_dict(produced_numeral, Recollection, Produced),
    get_dict(kernel_evidence, Recollection, KernelEvidence),
    get_dict(family, KernelEvidence, Family),
    Evidence = spatial_recollection{
        representation: notation,
        task: numeral(Expected),
        source: deformed_inscription,
        reconstructed_plan: candidate_numeral(Produced),
        validation: scene_validation(
                        deformation(Family, KernelEvidence),
                        Recollection)
    }.


%!  reflect_spatial_evidence(+Evidence, -Reflection) is det.
reflect_spatial_evidence(Evidence, Reflection) :-
    is_dict(Evidence, spatial_recollection),
    get_dict(representation, Evidence, Representation),
    get_dict(task, Evidence, Task),
    get_dict(reconstructed_plan, Evidence, Plan),
    get_dict(validation, Evidence, scene_validation(Verdict, Geometry)),
    spatial_verdict(Verdict, Status, Trigger),
    Reflection = spatial_reflection{
        status: Status,
        representation: Representation,
        task: Task,
        reconstructed_plan: Plan,
        trigger: Trigger,
        geometry_evidence: Geometry
    },
    !.
reflect_spatial_evidence(Evidence,
                         spatial_reflection{
                             status: unsupported,
                             trigger: malformed_spatial_evidence(Evidence)
                         }).

spatial_verdict(licensed(Kind), licensed, licensed_plan(Kind)).
spatial_verdict(deformation(Family, Detail), deformation,
                representation_deformation(Family, Detail)).
spatial_verdict(unsupported(Reason), unsupported,
                unsupported_recollection(Reason)).
