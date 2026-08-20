#!/usr/bin/env python3
"""Check evidence-backed deformation-chart coverage, families, and refusals."""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def main() -> int:
    goal = r'''use_module(lessons('im/lesson_deformation_chart')),
chart_provenance_census(_{hand_authored:3,evidence:73,division:1,total:77}),
forall(charted_lesson_code(Code),(chart_provenance(Code,P),memberchk(P,[hand_authored,evidence,division]))),
findall(Code,(default_fill_lessons:default_fill_lesson(Code),chart_refusal(Code,fraction_operands_unrecoverable,_)),Fraction0),sort(Fraction0,FractionCodes),length(FractionCodes,0),
findall(Code,(default_fill_lessons:default_fill_lesson(Code),chart_refusal(Code,no_deformation_chart,_)),Host0),sort(Host0,HostCodes),HostCodes=['IM-G5-U3-L19'],
monitoring_chart('IM-G3-U5-L1',Hand),get_dict(provenance,Hand,hand_authored),
monitoring_chart('IM-G3-U5-L5',NumberLine),get_dict(cells,NumberLine,NumberCells),member(NumberCell,NumberCells),get_dict(host,NumberCell,"number_line"),get_dict(deformations,NumberCell,[NumberDef]),get_dict(deformation,NumberDef,"number_line_count_marks_not_intervals"),
monitoring_chart('IM-G4-U3-L3',Set),get_dict(cells,Set,SetCells),member(SetCell,SetCells),get_dict(host,SetCell,"set"),get_dict(deformations,SetCell,[SetDef]),get_dict(deformation,SetDef,"set_model_subset_size_focus"),
monitoring_chart('IM-G5-U2-L2',Rectangle),get_dict(cells,Rectangle,RectangleCells),member(RectCell,RectangleCells),get_dict(host,RectCell,"rectangle"),
monitoring_chart('IM-G6-U4-L6',NonUnit),get_dict(fractions,NonUnit,NonUnitFractions),member("5/2",NonUnitFractions),get_dict(cells,NonUnit,NonUnitCells),\+ (member(AreaCell,NonUnitCells),get_dict(host,AreaCell,AreaHost),memberchk(AreaHost,["circle","rectangle","bar"]),get_dict(numerator,AreaCell,M),M=\=1),
monitoring_chart('IM-G4-U2-L14',Recovered),get_dict(provenance,Recovered,evidence),get_dict(fractions,Recovered,RecoveredFractions),member("3/4",RecoveredFractions),member("7/12",RecoveredFractions),
chart_refusal('IM-G5-U3-L19',no_deformation_chart,_),halt.'''
    completed = subprocess.run(
        ["swipl", "-q", "-l", "paths.pl", "-g", goal],
        cwd=ROOT, text=True, capture_output=True, check=False, timeout=60,
    )
    if completed.returncode:
        print(
            "FAIL lesson deformation chart evidence: "
            + (completed.stderr.strip() or f"SWI-Prolog exited {completed.returncode}"),
            file=sys.stderr,
        )
        return 1
    print("PASS lesson deformation chart: 77 served; evidence families, non-unit guard, and 1 refusal checked")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
