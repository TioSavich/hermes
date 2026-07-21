/** <module> Ace-of-Base to Fraction Bars unit echo
 *
 * Produces a paired, witness-fed render document.  The primary frames are the
 * Fraction Bars iteration, while `aceOfBase` retains the companion place-value
 * regrouping document.  The shared relation comes from recursive_unit_actions;
 * neither renderer infers it independently.
 *
 * The scene round trip reads split counts and widths from the final fraction-bar
 * scene, reconstructs a unit plan, and validates that plan against N/Base.
 */

:- module(unit_echo_scene,
          [ unit_echo_render_json/3,
            fraction_scene_plan/3,
            fraction_scene_validation/5
          ]).

:- use_module(math(recursive_unit_actions), []).
:- use_module(render(base_ten_scene), []).
:- use_module(render(fraction_bars_scene), []).
:- use_module(library(lists)).


%!  unit_echo_render_json(+Base, +Iterations, -Dict) is semidet.
unit_echo_render_json(Base, Iterations, Dict) :-
    integer(Base), Base >= 2,
    integer(Iterations), Iterations > 0,
    A is Base - 1,
    base_ten_scene:base_ten_render_json(add_with_carry(A, 1, Base), AceDoc),
    fraction_bars_scene:fraction_render_json(unit_fraction_iteration,
                                             Iterations, Base, FractionDoc),
    recursive_unit_actions:unit_echo_witness(Base, Iterations, EchoWitness),
    echo_dict(EchoWitness, EchoDict),
    final_scene(FractionDoc, FinalScene),
    fraction_scene_validation(Iterations, Base, FinalScene,
                              RecollectedPlan, Validation),
    recursive_unit_actions:plan_dict(RecollectedPlan, RecollectedPlanDict),
    validation_dict(Validation, ValidationDict),
    get_dict(result, FractionDoc, Result),
    get_dict(canvas, FractionDoc, Canvas),
    get_dict(frames, FractionDoc, Frames),
    Dict = _{ kind: "unit_reorganization_echo",
              request: _{ base: Base, iterations: Iterations },
              result: Result,
              canvas: Canvas,
              frames: Frames,
              aceOfBase: AceDoc,
              fractionBars: FractionDoc,
              echo: EchoDict,
              spatialRoundTrip: _{
                  source: "fraction_bar_geometry",
                  reconstructedPlan: RecollectedPlanDict,
                  validation: ValidationDict
              } },
    !.


%!  fraction_scene_plan(+Scene, -Plan, -Evidence) is semidet.
%
%   Reconstruct N/D from geometry, not from the displayed fraction label.
fraction_scene_plan(Scene, Plan, Evidence) :-
    fraction_bars_scene:fraction_scene_plan(Scene, Plan, Evidence).


%!  fraction_scene_validation(+ExpectedN, +ExpectedD, +Scene,
%                             -Plan, -Validation) is det.
fraction_scene_validation(ExpectedN, ExpectedD, Scene, Plan, Validation) :-
    fraction_bars_scene:fraction_scene_validation(
        ExpectedN, ExpectedD, Scene, Plan, Validation).


final_scene(Doc, Scene) :-
    get_dict(frames, Doc, Frames),
    last(Frames, FinalFrame),
    get_dict(scene, FinalFrame, Scene).

echo_dict(unit_echo_witness(base(Base),
                            outward_cycle(count(CountPlan, _, _),
                                           regroup(RegroupPlan, _, _),
                                           OutInvariant),
                            inward_cycle(fraction(FractionPlan, Quantity, _),
                                         InInvariant,
                                         validation(Verdict)),
                            relation(Relation)),
          Dict) :-
    recursive_unit_actions:plan_dict(CountPlan, CountDict),
    recursive_unit_actions:plan_dict(RegroupPlan, RegroupDict),
    recursive_unit_actions:plan_dict(FractionPlan, FractionDict),
    term_string(OutInvariant, OutInvariantString),
    term_string(InInvariant, InInvariantString),
    term_string(Relation, RelationString),
    term_string(Quantity, QuantityString),
    validation_dict(Verdict, VerdictDict),
    Dict = _{ base: Base,
              relation: RelationString,
              outward: _{ countPlan: CountDict,
                           regroupPlan: RegroupDict,
                           invariant: OutInvariantString },
              inward: _{ fractionPlan: FractionDict,
                          quantity: QuantityString,
                          invariant: InInvariantString,
                          validation: VerdictDict } }.

validation_dict(licensed(Kind),
                _{ status: "licensed", kind: KindString }) :-
    !,
    term_string(Kind, KindString).
validation_dict(deformation(Family, Evidence),
                _{ status: "deformation",
                   family: FamilyString,
                   evidence: EvidenceString }) :-
    !,
    term_string(Family, FamilyString),
    term_string(Evidence, EvidenceString).
validation_dict(unsupported(Reason),
                _{ status: "unsupported", reason: ReasonString }) :-
    term_string(Reason, ReasonString).
validation_dict(scene_validation(Verdict, Evidence), Dict) :-
    validation_dict(Verdict, VerdictDict),
    term_string(Evidence, EvidenceString),
    Dict = VerdictDict.put(evidence, EvidenceString).
