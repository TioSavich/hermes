#!/usr/bin/env python3
"""Render the fraction unit-coordination machine's splitting cliff as filmstrips.

The wire: formal/tools/carving/fraction_unit_machine.pl (the search) -> verdicts +
witness traces (swipl) -> fraction-bars frames (here) -> hermes/web/render/
drawer.js (buildSvg) -> SVG filmstrips. Bounded on purpose: three demos.

  - 3/5  (proper)    : reachable intact at every stage, no crisis.
  - 7/5  at mc2      : reachable ONLY by collapsing the referent-whole chain
                       (the documented improper-fraction chain-loss deformation).
  - 7/5  at mc3      : reachable INTACT by freeing the unit fraction and
                       iterating beyond the whole (the reorganization).

Run: python3 hermes/app/scripts/export_fraction_cliff.py
"""
from __future__ import annotations

import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO))
from hermes.app.scripts import export_engine

MACHINE = "formal/tools/carving/fraction_unit_machine.pl"
OUT = export_engine.gallery_output(REPO / "hermes" / "app" / "web" / "generated" / "fraction_cliff_demos")

W, H = 300, 70          # whole-bar geometry
X0, Y0 = 30, 40


def verdict_requests() -> list[export_engine.SwiplRequest]:
    requests = []
    for stage, tc, tb in (("mc1", 3, 5), ("mc2", 7, 5), ("mc3", 7, 5)):
        requests.append(export_engine.SwiplRequest(
            f"{stage}-{tc}-{tb}",
            f"M=fraction_unit_machine, "
            "( current_predicate(fraction_unit_machine:uc_min_cost/7) "
            f"  -> ( M:uc_min_cost({stage}, frac({tc},{tb}), 12, 24, IC, IW) "
            f"       -> true ; IC = -1, IW = [] ), "
            f"     ( M:uc_min_cost_collapsed({stage}, frac({tc},{tb}), 12, 24, CC, _) "
            f"       -> true ; CC = -1 ) "
            "  ; IC = -1, IW = [], CC = -1 ), "
            "with_output_to(string(Raw), writeq(v(IC, IW, CC))), "
            "Doc = _{raw:Raw}",
        ))
    return requests


def bar(x, y, parts, filled, label):
    cell = W / parts if parts else W
    splits = [{"x": i * cell, "y": 0, "w": cell, "h": H} for i in range(filled)]
    return {"x": x, "y": y, "w": W, "h": H, "label": label, "splits": splits}


def frame(step, caption, bars):
    return {"step": step, "caption": caption, "sceneChanged": True,
            "scene": {"format": "fraction-bars", "version": 1, "bars": bars}}


def frames_proper(tc, tb):
    return [
        frame(1, f"Partition the whole into {tb} equal parts.",
              [bar(X0, Y0, tb, 0, f"1 whole / {tb}")]),
        frame(2, f"Iterate the unit fraction {tc} times, within the whole.",
              [bar(X0, Y0, tb, tc, f"{tc}/{tb}")]),
        frame(3, "Chain intact: the referent whole is preserved.",
              [bar(X0, Y0, tb, tc, f"{tc}/{tb} ✓")]),
    ]


def frames_intact_beyond(tc, tb):
    return [
        frame(1, f"Partition the whole into {tb}; iterate to {tb}/{tb} = 1 whole.",
              [bar(X0, Y0, tb, tb, f"{tb}/{tb} = 1")]),
        frame(2, "Free the unit fraction so it can iterate past the whole.",
              [bar(X0, Y0, tb, tb, f"{tb}/{tb}"),
               bar(X0 + W + 40, Y0, tb, 0, "freed 1/%d" % tb)]),
        frame(3, f"Iterate {tc - tb} more {1}/{tb}-units beyond: {tc}/{tb}, chain intact.",
              [bar(X0, Y0, tb, tb, f"{tb}/{tb}"),
               bar(X0 + W + 40, Y0, tb, tc - tb, f"+{tc - tb}/{tb} → {tc}/{tb} ✓")]),
    ]


def frames_collapsed(tc, tb):
    return [
        frame(1, f"Partition the whole into {tb}; reach {tb}/{tb} = 1 whole.",
              [bar(X0, Y0, tb, tb, f"{tb}/{tb} = 1")]),
        frame(2, f"To say {tc}-something, re-partition the SAME whole into {tc}.",
              [bar(X0, Y0, tc, tc, f"{tc} parts?")]),
        frame(3, f"Whole now read as {tc}/{tc}: the original 1/{tb} chain is lost.",
              [bar(X0, Y0, tc, tc, f"{tc}/{tc} ✗ chain lost")]),
    ]


def render(doc, out_file, labels):
    export_engine.render_svg(
        doc, "filmstrip", out_file, preset="fraction-cliff", labels=labels,
        captionChars=60, omitAria=True,
    )
    return out_file


def main() -> int:
    args = export_engine.parse_args(__doc__, default_out=OUT)
    out_dir = args.out.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    verdicts = export_engine.run_swipl_batch(
        verdict_requests(),
        prelude=(f"( exists_file('{MACHINE}') -> consult('{MACHINE}') ; true )",),
        load_paths=False,
    )
    cases = [
        ("DEMO-fraction-3-5-proper", frames_proper(3, 5),
         ["Partition", "Iterate 3/5", "Intact"], verdicts["mc1-3-5"]),
        ("DEMO-fraction-7-5-mc2-chain-loss", frames_collapsed(7, 5),
         ["1 whole", "Re-partition", "Chain lost (mc2)"], verdicts["mc2-7-5"]),
        ("DEMO-fraction-7-5-mc3-freed-intact", frames_intact_beyond(7, 5),
         ["5/5 = 1", "Free unit", "7/5 intact (mc3)"], verdicts["mc3-7-5"]),
    ]
    docs = {}
    for code, frames, labels, v in cases:
        doc = {"canvas": {"width": 760, "height": 150}, "frames": frames}
        out_file = out_dir / f"{code}-filmstrip.svg"
        render(doc, out_file, labels)
        docs[code] = {"frames": frames, "machine_verdict": v["raw"]}
        print(out_file)
    export_engine.write_json(out_dir / "docs.json", docs)
    index = ["<!doctype html><meta charset=utf-8><title>Fraction splitting cliff</title>",
             "<body style='font-family:system-ui;background:#f8f1df;padding:24px'>",
             "<h1>The splitting cliff, computed</h1>",
             "<p>Filmstrips from <code>formal/tools/carving/fraction_unit_machine.pl</code> "
             "via <code>drawer.js</code>. Each strip's verdict comes from the search.</p>"]
    for code, _f, _l, v in cases:
        index.append(f"<h2>{code}</h2><p><small>machine: {v['raw']}</small></p>"
                     f"<img src='{code}-filmstrip.svg' style='max-width:100%'>")
    export_engine.write_index(out_dir, "\n".join(index))
    print(out_dir / "index.html")
    return 0


if __name__ == "__main__":
    raise SystemExit(export_engine.exporter_main(main, OUT))
