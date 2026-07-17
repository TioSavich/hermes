#!/usr/bin/env python3
"""Export the canonical hybridization misconception demo as SVG files."""
from __future__ import annotations

import argparse
import html
import json
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO_ROOT))

from hermes.app.scripts import export_monitoring_visuals
from hermes.app import rendering


DEFAULT_OUT = rendering.gallery_output(REPO_ROOT / "hermes" / "app" / "web" / "generated" / "misconception_demos")
HYBRIDIZATION_CASES = {
    "circle_partition_on_rectangle": {
        "code": "DEMO-hybridization-circle-partition-on-rectangle",
        "expression": "circle partition on rectangle",
        "incorrect_description": (
            "Hybridized model: the circle's radial partition rule is "
            "transplanted onto a rectangle host."
        ),
    },
    "vertical_partition_on_circle": {
        "code": "DEMO-hybridization-vertical-partition-on-circle",
        "expression": "vertical partition on circle",
        "incorrect_description": (
            "Hybridized model: the rectangle's vertical partition rule is "
            "transplanted onto a circular host."
        ),
    },
    "radial_partition_on_set": {
        "code": "DEMO-hybridization-radial-partition-on-set",
        "expression": "radial partition on set",
        "incorrect_description": (
            "Hybridized model: the circle's radial partition rule is "
            "transplanted onto elements of a fractional set host."
        ),
    },
    "parallel_partition_on_triangle": {
        "code": "DEMO-hybridization-parallel-partition-on-triangle",
        "expression": "parallel partition on triangle",
        "incorrect_description": (
            "Hybridized model: the rectangle's parallel partition rule is "
            "transplanted onto a triangular region host."
        ),
    },
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--out",
        type=Path,
        default=DEFAULT_OUT,
        help=f"Output directory. Default: {DEFAULT_OUT}",
    )
    return parser.parse_args()


def hybridization_doc(kind: str) -> dict:
    sys.path.insert(0, str(REPO_ROOT))
    from hermes.app import server

    try:
        doc = server.SERVICES.worker.request(
            "hybridization_render",
            kind=kind,
        )
    finally:
        server.SERVICES.worker.close()
    if not isinstance(doc, dict):
        raise RuntimeError(f"hybridization_render returned {type(doc).__name__}")
    return doc


def hybridization_docs() -> dict[str, dict]:
    return {kind: hybridization_doc(kind) for kind in HYBRIDIZATION_CASES}


def demo_docs(docs_by_kind: dict) -> dict:
    docs = {}
    for kind, doc in docs_by_kind.items():
        case = HYBRIDIZATION_CASES.get(kind, {})
        code = case.get("code", f"DEMO-hybridization-{kind.replace('_', '-')}")
        expression = case.get("expression", kind.replace("_", " "))
        incorrect_description = case.get(
            "incorrect_description",
            "Hybridized model: a foreign primitive is transplanted onto an illicit host.",
        )
        docs[code] = {
            "visuals": [
                {
                    "expression": expression,
                    "family": "transplant_deformation",
                    "correct": {
                        "description": "No productive hybrid is shown here; the point is the labeled transplant violation.",
                        "doc": {"frames": []},
                    },
                    "incorrect": {
                        "description": incorrect_description,
                        "doc": doc,
                    },
                }
            ]
        }
    return docs


def case_code(kind: str) -> str:
    return HYBRIDIZATION_CASES.get(kind, {}).get(
        "code",
        f"DEMO-hybridization-{kind.replace('_', '-')}",
    )


def ordered_case_items(docs_by_kind: dict) -> list[tuple[str, dict]]:
    ordered = [
        (kind, docs_by_kind[kind])
        for kind in HYBRIDIZATION_CASES
        if kind in docs_by_kind
    ]
    extras = [
        (kind, docs_by_kind[kind])
        for kind in sorted(docs_by_kind)
        if kind not in HYBRIDIZATION_CASES
    ]
    return ordered + extras


def _frame_cell(frames: list, index: int, code: str, expression: str) -> str:
    if index >= len(frames):
        return '<span class="missing">No frame</span>'
    frame = frames[index] or {}
    step = html.escape(str(frame.get("step", index + 1)))
    verb = html.escape(str(frame.get("verb", "")))
    caption = html.escape(str(frame.get("caption", "")))
    frame_svg = f"{code}-frame-{index + 1}.svg"
    alt = html.escape(f"{expression} frame {index + 1}", quote=True)
    return (
        f'<img class="frame-img" src="{html.escape(frame_svg, quote=True)}" alt="{alt}">'
        f'<div class="step">Step {step}</div>'
        f'<div class="verb">{verb}</div>'
        f'<p>{caption}</p>'
    )


def _proof_metadata(docs_by_kind: dict) -> dict:
    cases = []
    for kind, doc in ordered_case_items(docs_by_kind):
        cases.append(
            {
                "kind": kind,
                "code": case_code(kind),
                "family": doc.get("family", ""),
                "foreign_primitive": doc.get("foreignPrimitive", ""),
                "licensed_home": doc.get("licensedHome", ""),
                "illicit_host": doc.get("illicitHost", ""),
                "violation": doc.get("violation", ""),
                "frame_count": len(doc.get("frames", [])),
            }
        )
    return {
        "kind": "hermes_hybridized_model_chart_proof",
        "source": "hybridization_scene_case_registry",
        "cases": cases,
        "interpretive_residue": {
            "status": "human_endorsement_required",
            "claim": "Hermes checks the transplant grammar and render contract; it does not certify a student-work reading.",
        },
    }


def build_hybridized_model_chart_html(docs_by_kind: dict) -> str:
    metadata = _proof_metadata(docs_by_kind)
    rows = []
    for kind, doc in ordered_case_items(docs_by_kind):
        code = case_code(kind)
        frames = list(doc.get("frames", []))
        family = str(doc.get("family", ""))
        foreign = str(doc.get("foreignPrimitive", ""))
        licensed = str(doc.get("licensedHome", ""))
        illicit = str(doc.get("illicitHost", ""))
        violation = str(doc.get("violation", ""))
        final_svg = f"{code}-incorrect.svg"
        filmstrip = f"{code}-filmstrip.svg"
        expression = HYBRIDIZATION_CASES.get(kind, {}).get("expression", kind.replace("_", " "))
        rows.append(
            '<tr '
            f'data-hybridization-case="{html.escape(kind, quote=True)}" '
            f'data-family="{html.escape(family, quote=True)}" '
            f'data-foreign-primitive="{html.escape(foreign, quote=True)}" '
            f'data-licensed-home="{html.escape(licensed, quote=True)}" '
            f'data-illicit-host="{html.escape(illicit, quote=True)}" '
            f'data-proof-status="{html.escape(violation, quote=True)}">'
            f'<th scope="row"><span class="case-title">{html.escape(expression)}</span>'
            f'<code>{html.escape(kind)}</code></th>'
            f'<td>{_frame_cell(frames, 0, code, expression)}</td>'
            f'<td>{_frame_cell(frames, 1, code, expression)}</td>'
            f'<td>{_frame_cell(frames, 2, code, expression)}</td>'
            f'<td><img src="{html.escape(final_svg, quote=True)}" alt="{html.escape(expression, quote=True)} hybrid result">'
            f'<a href="{html.escape(filmstrip, quote=True)}">Temporal filmstrip</a></td>'
            f'<td><code>{html.escape(foreign)}</code><br>'
            f'<span>licensed in</span> <code>{html.escape(licensed)}</code><br>'
            f'<span>placed on</span> <code>{html.escape(illicit)}</code><br>'
            f'<strong>{html.escape(violation)}</strong></td>'
            '</tr>'
        )
    rows_html = "\n".join(rows)
    metadata_json = html.escape(json.dumps(metadata, indent=2), quote=False)
    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Chart of Hybridized Models</title>
  <style>
    body {{ margin: 0; background: #f8f1df; color: #1b1810; font-family: system-ui, sans-serif; }}
    main {{ max-width: 1280px; margin: 0 auto; padding: 28px; }}
    h1 {{ font-family: Georgia, "Times New Roman", serif; font-size: 32px; margin: 0 0 8px; }}
    .residue {{ margin: 0 0 22px; max-width: 820px; color: #4d4638; }}
    table {{ width: 100%; border-collapse: collapse; background: #fffaf0; border: 1px solid #cabf9f; }}
    th, td {{ border: 1px solid #cabf9f; padding: 12px; vertical-align: top; }}
    thead th {{ background: #efe3c8; font-size: 14px; text-align: left; }}
    tbody th {{ width: 190px; text-align: left; }}
    code {{ display: inline-block; margin-top: 6px; font-size: 12px; color: #4d4638; }}
    img {{ display: block; width: 220px; max-width: 100%; background: #f8f1df; border: 1px solid #cabf9f; }}
    .frame-img {{ margin-bottom: 8px; }}
    a {{ display: inline-block; margin-top: 8px; color: #365f6b; }}
    .step {{ font-size: 12px; font-weight: 700; color: #6d5b31; }}
    .verb {{ margin-top: 4px; font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 12px; }}
    p {{ margin: 6px 0 0; line-height: 1.35; }}
    .case-title {{ display: block; font-weight: 700; }}
    .missing {{ color: #8b1e16; }}
  </style>
</head>
<body>
<main>
  <h1>Chart of Hybridized Models</h1>
  <p class="residue"><strong>human_endorsement_required:</strong> Hermes checks the transplant grammar and render contract; it does not certify a student-work reading.</p>
  <table>
    <thead>
      <tr>
        <th>Case</th>
        <th>One unit</th>
        <th>Licensed home</th>
        <th>Transplant</th>
        <th>Hybrid model</th>
        <th>Grammar proof</th>
      </tr>
    </thead>
    <tbody>
{rows_html}
    </tbody>
  </table>
  <script type="application/json" id="hybridized-model-chart-proof">
{metadata_json}
  </script>
</main>
</body>
</html>
"""


def write_hybridized_model_chart(out_dir: Path, docs_by_kind: dict) -> Path:
    path = out_dir / "hybridized_model_chart.html"
    path.write_text(build_hybridized_model_chart_html(docs_by_kind), encoding="utf-8")
    return path


def merge_existing_docs(out_dir: Path, new_docs: dict) -> dict:
    docs_path = out_dir / "docs.json"
    if docs_path.exists():
        docs = json.loads(docs_path.read_text(encoding="utf-8"))
    else:
        docs = {}
    docs.update(new_docs)
    return docs


def export_final_svgs(out_dir: Path, docs: dict) -> None:
    docs_path = out_dir / "docs.json"
    docs_path.write_text(json.dumps(docs, indent=2), encoding="utf-8")
    rendering.render_monitoring_docs(docs, out_dir)
    export_monitoring_visuals.build_gallery(out_dir, docs)


def export_filmstrip(out_dir: Path, code: str, doc: dict) -> Path:
    kind = str(doc.get("kind", code)).replace("-", "_")
    doc_path = out_dir / f"hybridization_{kind}_doc.json"
    doc_path.write_text(json.dumps(doc, indent=2), encoding="utf-8")
    out_file = out_dir / f"{code}-filmstrip.svg"
    rendering.render_svg(
        doc, "filmstrip", out_file,
        labels=["Host", "Licensed home", "Transplant", "Hybrid result"],
        panelWidth=258, panelHeight=220, gap=16, rootHeight=328,
        fullPanelHeight=True, yOffset=74, labelOffset=26, labelSize=17,
        labelFont="system-ui, sans-serif", omitCaptions=True, cleanFonts=True,
        ariaLabel="Canonical hybridization temporal filmstrip",
    )
    return out_file


def export_frame_svgs(out_dir: Path, code: str, doc: dict) -> list[Path]:
    kind = str(doc.get("kind", code)).replace("-", "_")
    doc_path = out_dir / f"hybridization_{kind}_doc.json"
    doc_path.write_text(json.dumps(doc, indent=2), encoding="utf-8")
    return rendering.render_frames(
        doc, out_dir, code, metadata_kind="hybridization-frame-proof",
        metadata_payload_kind="hermes_hybridization_frame_proof",
    )


def main() -> int:
    args = parse_args()
    out_dir = args.out.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    docs_by_kind = hybridization_docs()
    new_docs = demo_docs(docs_by_kind)
    (out_dir / "hybridization_docs.json").write_text(
        json.dumps(new_docs, indent=2),
        encoding="utf-8",
    )
    docs = merge_existing_docs(out_dir, new_docs)
    export_final_svgs(out_dir, docs)
    filmstrips = [
        export_filmstrip(
            out_dir,
            HYBRIDIZATION_CASES.get(kind, {}).get("code", f"DEMO-hybridization-{kind.replace('_', '-')}"),
            doc,
        )
        for kind, doc in docs_by_kind.items()
    ]
    frame_svgs = [
        frame_svg
        for kind, doc in docs_by_kind.items()
        for frame_svg in export_frame_svgs(
            out_dir,
            HYBRIDIZATION_CASES.get(kind, {}).get("code", f"DEMO-hybridization-{kind.replace('_', '-')}"),
            doc,
        )
    ]
    chart = write_hybridized_model_chart(out_dir, docs_by_kind)

    print(f"Wrote hybridization demo to {out_dir}")
    for kind in docs_by_kind:
        code = HYBRIDIZATION_CASES.get(kind, {}).get("code", f"DEMO-hybridization-{kind.replace('_', '-')}")
        print(out_dir / f"{code}-incorrect.svg")
    for filmstrip in filmstrips:
        print(filmstrip)
    for frame_svg in frame_svgs:
        print(frame_svg)
    print(chart)
    print(out_dir / "index.html")
    print(html.escape(", ".join(sorted(new_docs))))
    return 0


if __name__ == "__main__":
    if "--check" in sys.argv:
        raise SystemExit(
            rendering.check_exporter(Path(__file__), DEFAULT_OUT, seed_tracked=True)
        )
    raise SystemExit(main())
