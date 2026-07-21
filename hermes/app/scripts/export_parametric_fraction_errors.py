#!/usr/bin/env python3
"""Render the parametric equipartition-failure family as SVG filmstrips.

The wire: knowledge/strategies/render/parametric_fraction_errors.pl (the logic) ->
B/M/E frames per (host, fraction, error type) (swipl) -> hermes/web/render/
drawer.js (buildSvg) -> SVG filmstrips. The point: one deformation reproduces
across the fraction family. The script renders the SAME error type for several
fractions side by side so the replication is legible.

A monitoring-chart use: name a lesson's target fractions, get the predicted
botches for each, in one strip per error type.

Run: python3 hermes/app/scripts/export_parametric_fraction_errors.py
"""
from __future__ import annotations

import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO))
from hermes.app.scripts import export_engine

MODULE = "knowledge/strategies/render/parametric_fraction_errors.pl"
OUT = export_engine.gallery_output(REPO / "hermes" / "app" / "web" / "generated" / "parametric_fraction_errors")


def scene_requests() -> list[export_engine.SwiplRequest]:
    requests = []
    for host in ("circle", "bar", "area"):
        for short, goal, _title in ERROR_CASES:
            for m, n in FAMILY[host]:
                key = f"{host}-{short}-{m}-{n}"
                requests.append(export_engine.SwiplRequest(
                    key,
                    "parametric_fraction_errors:deformed_fraction_error_scene("
                    f"{host}, frac({m},{n}), {goal}, Doc)",
                ))
    return requests


def render(doc: dict, out_file: Path, labels: list[str], title: str) -> Path:
    export_engine.render_svg(
        doc, "filmstrip", out_file, labels=labels, title=title,
        panelWidth=360, panelHeight=190, rootHeight=336, gap=22, pad=24,
        headHeight=36, titleLeft=True, fullPanelHeight=True, yOffset=74,
        labelOffset=24, labelSize=14, captionSize=10, wrapCaption=64,
        ariaLabel=title,
    )
    return out_file


# The replication grid: each (error_type, goal) rendered across a fraction family
# on one host. The B/M/E strip uses the named verbs from the frames.
ERROR_CASES = [
    ("unequal_partition", "unequal_partition",
     "Unequal partition (equipartition failure)"),
    ("miscount_partition", "miscount_partition",
     "Miscount partition (off-by-one)"),
    ("shade_wrong_count", "shade_wrong_count(2)",
     "Shade wrong count (shade 2, not the numerator)"),
    ("wrong_referent_whole", "wrong_referent_whole",
     "Wrong referent whole"),
]

# Fraction families per host. Keeps M < N where it matters for shading.
FAMILY = {
    "circle": [(1, 4), (1, 5), (1, 6)],
    "bar":    [(1, 4), (1, 5), (1, 6)],
    "area":   [(1, 4), (1, 5), (1, 6)],
}


def bme_labels(m: int, n: int) -> list[str]:
    return [
        f"B. establish_whole ({m}/{n})",
        f"M. apply_partition ({m}/{n})",
        f"E. shade_parts ({m}/{n})",
    ]


def main() -> int:
    args = export_engine.parse_args(__doc__, default_out=OUT)
    out_dir = args.out.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    documents = export_engine.run_swipl_batch(
        scene_requests(),
        prelude=(
            "use_module(knowledge/strategies/render/parametric_fraction_errors)",
        ),
    )
    manifest: dict = {"cases": []}
    index_lines = [
        "<!doctype html><meta charset=utf-8>",
        "<title>Parametric equipartition-failure family</title>",
        "<body style='font-family:system-ui;background:#f8f1df;color:#1b1810;padding:24px;max-width:1100px;margin:auto'>",
        "<h1>Equipartition-failure family, parametric over the fraction</h1>",
        "<p>One documented student-work error is a <b>rule</b>, not a single figure. "
        "Each strip below is the same deformation generated for several fractions, "
        "differing only by the fraction parameter. Logic: "
        "<code>knowledge/strategies/render/parametric_fraction_errors.pl</code>. Render: "
        "<code>hermes/web/render/drawer.js</code>. A deformation is drawn only as a "
        "labeled misconception, never as an unlabeled productive diagram.</p>",
    ]

    for host in ("circle", "bar", "area"):
        index_lines.append(f"<h2>Host: {host}</h2>")
        for short, goal, title in ERROR_CASES:
            for (m, n) in FAMILY[host]:
                doc = documents[f"{host}-{short}-{m}-{n}"]
                code = f"DEMO-eqfail-{host}-{short}-{m}-{n}"
                out_file = out_dir / f"{code}-filmstrip.svg"
                render(doc, out_file, bme_labels(m, n), f"{title}  |  {host}  {m}/{n}")
                manifest["cases"].append({
                    "code": code, "host": host, "error_type": short,
                    "m": m, "n": n,
                    "evidence": doc.get("evidence", {}),
                    "file": out_file.name,
                })
                index_lines.append(
                    f"<h3>{title} &mdash; {host} {m}/{n}</h3>"
                    f"<img src='{out_file.name}' style='max-width:100%;border:1px solid #cabf9f'>"
                )
                print(out_file)

    export_engine.write_json(out_dir / "manifest.json", manifest)
    index_lines.append("</body>")
    export_engine.write_index(out_dir, "\n".join(index_lines))
    print(out_dir / "index.html")
    print(out_dir / "manifest.json")
    return 0


if __name__ == "__main__":
    raise SystemExit(export_engine.exporter_main(main, OUT))
