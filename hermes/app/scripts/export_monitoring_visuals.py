#!/usr/bin/env python3
"""Export generated monitoring-chart visuals as static SVG files.

The Python side asks the existing Hermes worker/server generator for render
documents. The shared rendering adapter uses hermes/web/render/drawer.js to
serialize the final frame of each document as SVG.
"""
from __future__ import annotations

import html
import json
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO_ROOT))
from hermes.app.scripts import export_engine

DEFAULT_LESSONS = ["IM-G1-U3-L17", "IM-G2-U2-L7", "IM-G4-U4-L20"]
DEFAULT_OUT = export_engine.gallery_output(REPO_ROOT / "hermes" / "app" / "web" / "generated" / "monitoring_visuals")


def configure_cli(parser) -> None:
    parser.add_argument(
        "--lesson",
        action="append",
        dest="lessons",
        help="IM lesson code to export. Repeat for multiple lessons. Defaults to current regression examples.",
    )
    parser.add_argument(
        "--chart-json",
        type=Path,
        help=(
            "JSON object mapping lesson codes to monitoring-chart payloads. "
            "When provided, charts are read from this file instead of "
            "monitoring_chart_export."
        ),
    )


def svg_name(code: str, total: int, index: int, side: str) -> str:
    if total == 1:
        return f"{code}-{side}.svg"
    return f"{code}-{index + 1}-{side}.svg"


def filmstrip_svg_name(code: str, total: int, index: int, side: str) -> str:
    if total == 1:
        return f"{code}-{side}-filmstrip.svg"
    return f"{code}-{index + 1}-{side}-filmstrip.svg"


def proof_summary_html(visual: dict, side: str) -> str:
    proof = visual.get("proof") if isinstance(visual, dict) else {}
    proof = proof if isinstance(proof, dict) else {}
    side_proof = proof.get(side) if isinstance(proof.get(side), dict) else {}
    residue = proof.get("interpretive_residue") if isinstance(proof.get("interpretive_residue"), dict) else {}
    status = html.escape(str(side_proof.get("status") or "proof_unavailable"))
    frame_count = html.escape(str(side_proof.get("frame_count") or 0))
    temporal = "temporal" if side_proof.get("temporal") else "single-frame"
    residue_status = html.escape(str(residue.get("status") or "residue_unstated"))
    claim = html.escape(str(residue.get("claim") or ""))
    sequence = frame_sequence_html(side_proof)
    return f"""<dl class="proof">
  <dt>Proof</dt><dd>{status}</dd>
  <dt>Frames</dt><dd>{frame_count} ({temporal})</dd>
  <dt>Frame sequence</dt><dd>{sequence}</dd>
  <dt>Residue</dt><dd>{residue_status}</dd>
  <dt>Claim</dt><dd>{claim}</dd>
</dl>"""


def frame_sequence_html(side_proof: dict) -> str:
    sequence = side_proof.get("frame_sequence") if isinstance(side_proof, dict) else []
    if not isinstance(sequence, list) or not sequence:
        return "none"
    items: list[str] = []
    for frame in sequence:
        if not isinstance(frame, dict):
            continue
        step = html.escape(str(frame.get("step") or "?"))
        verb = html.escape(str(frame.get("verb") or "unnamed_step"))
        items.append(f"{step}. {verb}")
    return "<br>".join(items) if items else "none"


def build_gallery(out_dir: Path, docs: dict[str, dict]) -> None:
    cards: list[str] = []
    for code, payload in docs.items():
        visuals = payload.get("visuals") or []
        for index, visual in enumerate(visuals):
            expression = html.escape(str(visual.get("expression") or "generated visual"))
            family = html.escape(str(visual.get("family") or ""))
            for side in ("correct", "incorrect"):
                side_payload = visual.get(side) or {}
                desc = html.escape(str(side_payload.get("description") or side))
                doc = side_payload.get("doc") or {}
                frames = doc.get("frames") if isinstance(doc, dict) else []
                proof = visual.get("proof") if isinstance(visual.get("proof"), dict) else {}
                side_proof = proof.get(side) if isinstance(proof.get(side), dict) else {}
                is_temporal = bool(side_proof.get("temporal"))
                if frames:
                    name = (
                        filmstrip_svg_name(code, len(visuals), index, side)
                        if is_temporal
                        else svg_name(code, len(visuals), index, side)
                    )
                    media = f"""<img src="{html.escape(name)}" alt="{html.escape(code)} {html.escape(side)} {expression}">"""
                else:
                    note = html.escape(str(doc.get("error") or "No drawable frames returned."))
                    media = f"""<div class="note">{note}</div>"""
                cards.append(
                    f"""<figure>
  <figcaption><b>{html.escape(code)}</b> {html.escape(side)}<br><span>{expression} {family}</span></figcaption>
  {media}
  <p>{desc}</p>
  {proof_summary_html(visual, side)}
</figure>"""
                )
    body = "\n".join(cards) or "<p>No drawable monitoring visuals were generated.</p>"
    html_doc = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Generated Monitoring Visuals</title>
<style>
body {{ margin: 24px; font: 16px system-ui, sans-serif; background: #f8f1df; color: #1b1810; }}
main {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 16px; }}
figure {{ margin: 0; padding: 12px; border: 1px solid #cabf9f; background: #fffaf0; }}
figcaption {{ font-size: 0.9rem; margin-bottom: 8px; }}
figcaption span, p {{ color: #665f4f; }}
img {{ width: 100%; height: 220px; object-fit: contain; background: #f8f1df; border: 1px solid #cabf9f; }}
.note {{ min-height: 220px; display: grid; place-items: center; padding: 12px; background: #fff4e8; border: 1px solid #cabf9f; color: #665f4f; text-align: center; }}
p {{ margin: 8px 0 0; font-size: 0.9rem; }}
.proof {{ margin: 10px 0 0; display: grid; grid-template-columns: max-content 1fr; gap: 4px 10px; font-size: 0.78rem; color: #4d4638; }}
.proof dt {{ font-weight: 700; }}
.proof dd {{ margin: 0; overflow-wrap: anywhere; }}
</style>
</head>
<body>
<h1>Generated Monitoring Visuals</h1>
<main>
{body}
</main>
</body>
</html>
"""
    export_engine.write_index(out_dir, html_doc)


def load_chart_json(path: Path) -> dict[str, dict]:
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except OSError as exc:
        raise RuntimeError(f"{path}: {exc}") from exc
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"{path}: invalid JSON: {exc}") from exc
    if not isinstance(raw, dict):
        raise RuntimeError(f"{path}: chart JSON root must be an object")
    charts: dict[str, dict] = {}
    for code, chart in raw.items():
        lesson_code = str(code)
        if not isinstance(chart, dict):
            raise RuntimeError(f"{path}: chart for {lesson_code} must be an object")
        charts[lesson_code] = chart
    return charts


def main() -> int:
    args = export_engine.parse_args(
        __doc__, default_out=DEFAULT_OUT, configure=configure_cli
    )
    out_dir = args.out.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    from hermes.app.monitoring.visuals import monitoring_visuals_for_chart

    try:
        chart_overrides = load_chart_json(args.chart_json) if args.chart_json else None
    except RuntimeError as exc:
        sys.stderr.write(f"{exc}\n")
        return 2
    lessons = args.lessons or (list(chart_overrides.keys()) if chart_overrides else DEFAULT_LESSONS)

    docs: dict[str, dict] = {}
    try:
        with export_engine.worker_requester() as request:
            for code in lessons:
                if chart_overrides is not None:
                    if code not in chart_overrides:
                        raise RuntimeError(f"{code}: no chart in {args.chart_json}")
                    chart = chart_overrides[code]
                else:
                    chart = request("monitoring_chart_export", lesson_code=code)
                if not isinstance(chart, dict):
                    raise RuntimeError(f"{code}: monitoring_chart_export returned {type(chart).__name__}")
                docs[code] = monitoring_visuals_for_chart(
                    code, chart, request, repo_root=REPO_ROOT
                )
    except RuntimeError as exc:
        sys.stderr.write(f"{exc}\n")
        return 2

    docs_path = out_dir / "docs.json"
    export_engine.write_json(docs_path, docs)

    from hermes.app.scripts import verify_monitoring_visuals

    issues = verify_monitoring_visuals.verify_docs(docs)
    if issues:
        for issue in issues:
            sys.stderr.write(f"{issue}\n")
        return 1

    try:
        written_paths = export_engine.render_monitoring_docs(docs, out_dir)
    except export_engine.RenderAdapterError as exc:
        sys.stderr.write(f"{exc}\n")
        return 1

    svg_issues = verify_monitoring_visuals.verify_svg_files(docs, out_dir)
    if svg_issues:
        for issue in svg_issues:
            sys.stderr.write(f"{issue}\n")
        return 1

    build_gallery(out_dir, docs)
    written = [str(path) for path in written_paths]
    print(f"Wrote {len(written)} SVG files to {out_dir}")
    for file in written:
        print(file)
    print(out_dir / "index.html")
    return 0


if __name__ == "__main__":
    raise SystemExit(export_engine.exporter_main(main, DEFAULT_OUT))
