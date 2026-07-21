#!/usr/bin/env python3
"""Render the three ReaLLMs-flagged real transplant figures as labeled
literature-exemplar transplant filmstrips.

These three figures were read by the ReaLLMs descriptor pass and carry
``is_hybridized_transplant: true`` with a ``hybrid_details`` tuple
(foreign_primitive, illicit_host) in
``data/research_assets/research/docling_classifications.json``:

  - ESM_Cadez_2018  p14_2  (rectangular_grid_partition on circle)
  - MERJ_Zhang_2015 p18_1  (radial_partition on rectangle)
  - ZDM_Garderen_2014 p9_1 (circle radial partition on submarine sandwich)

The figures are real student-work PNGs; this script does NOT redraw the
student work. It renders the *grammar* of each transplant as a temporal
proof object by reusing the registered hybridization scene whose geometry
matches the flagged (foreign_primitive -> illicit_host) move, then labels
the output with the literature source (author, year, page). The student PNG
remains the evidence; the generated SVG is the grammar model.

Output: B/M/E filmstrips + per-frame SVGs in
``hermes/app/web/generated/real_transplants/``.

The render path (worker hybridization_render -> drawer.js filmstrip/frame
exporters) is shared with export_hybridization_demo.py; this script only adds
the descriptor-to-scene mapping and the literature labels.
"""
from __future__ import annotations

import argparse
import html
import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO_ROOT))

from hermes.app.scripts import export_hybridization_demo as demo

DOCLING_CLASSIFICATIONS = (
    REPO_ROOT
    / "data"
    / "research_assets"
    / "research"
    / "docling_classifications.json"
)
DEFAULT_OUT = (
    REPO_ROOT / "hermes" / "app" / "web" / "generated" / "real_transplants"
)

# The three ReaLLMs-flagged real transplants. Each names the bibkey + page that
# locate the record in docling_classifications.json, the registered
# hybridization scene kind whose geometry matches the flagged transplant move,
# and the human-readable literature label. The scene kind is chosen by the
# (foreign_primitive -> illicit_host) geometry, NOT invented: a rectangle-style
# partition on a circle host reuses vertical_partition_on_circle; a circle
# radial partition on a rectangular host (the sandwich is a rectangular region)
# reuses circle_partition_on_rectangle.
REAL_TRANSPLANTS = [
    {
        "bibkey": "ESM_Cadez_2018",
        "page": "p14_2",
        "author": "Cadez & Kolar",
        "year": "2018",
        "page_label": "p.14",
        "scene_kind": "vertical_partition_on_circle",
        "code": "REAL-transplant-cadez-2018-p14",
    },
    {
        "bibkey": "MERJ_Zhang_2015",
        "page": "p18_1",
        "author": "Zhang, Clements & Ellerton",
        "year": "2015",
        "page_label": "p.18",
        "scene_kind": "circle_partition_on_rectangle",
        "code": "REAL-transplant-zhang-2015-p18",
    },
    {
        "bibkey": "ZDM_Garderen_2014",
        "page": "p9_1",
        "author": "van Garderen, Scheuermann & Jackson",
        "year": "2014",
        "page_label": "p.9",
        "scene_kind": "circle_partition_on_rectangle",
        "code": "REAL-transplant-garderen-2014-p9",
    },
]


def load_classifications() -> dict:
    return json.loads(DOCLING_CLASSIFICATIONS.read_text(encoding="utf-8"))


def find_record(classifications: dict, bibkey: str, page: str) -> tuple[str, dict]:
    """Return (image_path, record) for the flagged figure, matching by bibkey
    and page token in the docling key. The keys are absolute PNG paths."""
    for key, value in classifications.items():
        if bibkey in key and f"/{page}.png" in key:
            return key, value
    raise KeyError(f"no docling record for {bibkey} {page}")


def labelled_doc(transplant: dict, record: dict) -> dict:
    """Fetch the registered scene doc and attach the literature label +
    the ReaLLMs-read hybrid_details so the render is grounded, not invented."""
    doc = demo.hybridization_doc(transplant["scene_kind"])
    details = record.get("hybrid_details") or {}
    source_label = (
        f"{transplant['author']} ({transplant['year']}), {transplant['page_label']}"
    )
    doc["literature_label"] = source_label
    doc["bibkey"] = transplant["bibkey"]
    doc["page"] = transplant["page"]
    # The ReaLLMs descriptor's own (foreign_primitive, illicit_host) read, kept
    # alongside the scene's registered tuple. They name the same transplant in
    # the corpus's vocabulary; the scene supplies the licensed geometry.
    doc["reallms_hybrid_details"] = {
        "foreign_primitive": details.get("foreign_primitive", ""),
        "illicit_host": details.get("illicit_host", ""),
    }
    doc["representation_language"] = record.get("representation_language", "")
    doc["student_strategy_description"] = record.get(
        "student_strategy_description", ""
    )
    return doc


def write_filmstrip(out_dir: Path, code: str, doc: dict) -> Path:
    """B/M/E filmstrip via the shared FILMSTRIP_EXPORTER. The four canonical
    frames (host, licensed home, transplant, hybrid result) are the
    beginning/middle/end of the transplant story."""
    return demo.export_filmstrip(out_dir, code, doc)


def write_frames(out_dir: Path, code: str, doc: dict) -> list[Path]:
    return demo.export_frame_svgs(out_dir, code, doc)


def repo_relative(path: str | Path) -> str:
    p = Path(path)
    try:
        return p.resolve().relative_to(REPO_ROOT).as_posix()
    except ValueError:
        return p.as_posix()


def build_index_html(out_dir: Path, exported: list[dict]) -> Path:
    cards = []
    for item in exported:
        code = item["code"]
        label = html.escape(item["literature_label"])
        foreign = html.escape(item["foreign_primitive"])
        host = html.escape(item["illicit_host"])
        scene = html.escape(item["scene_kind"])
        bibkey = html.escape(item["bibkey"])
        page = html.escape(item["page"])
        frame_imgs = "".join(
            f'<figure><img src="{html.escape(Path(p).name, quote=True)}" '
            f'alt="{html.escape(code, quote=True)} frame {i + 1}">'
            f"<figcaption>Frame {i + 1}</figcaption></figure>"
            for i, p in enumerate(item["frame_files"])
        )
        filmstrip_name = html.escape(Path(item["filmstrip_file"]).name, quote=True)
        cards.append(
            f'<section class="card" data-bibkey="{bibkey}" data-page="{page}">'
            f"<h2>{label}</h2>"
            f'<p class="source">Literature exemplar (real student-work figure). '
            f"ReaLLMs-read transplant: <code>{foreign}</code> on "
            f"<code>{host}</code>. Grammar model reuses scene "
            f"<code>{scene}</code>.</p>"
            f'<img class="filmstrip" src="{filmstrip_name}" '
            f'alt="{label} transplant filmstrip">'
            f'<div class="frames">{frame_imgs}</div>'
            "</section>"
        )
    cards_html = "\n".join(cards)
    return _write_index(out_dir, cards_html, exported)


def _write_index(out_dir: Path, cards_html: str, exported: list[dict]) -> Path:
    metadata = {
        "kind": "hermes_real_transplant_exemplars",
        "source": "reallms_docling_classifications",
        "claim": (
            "These are real student-work figures the ReaLLMs pass flagged as "
            "hybridized transplants. The SVG filmstrips model the transplant "
            "grammar; they do not redraw the student work, and the PNG is the "
            "evidence. Human endorsement is required for the student-work reading."
        ),
        "exemplars": [
            {
                "code": e["code"],
                "bibkey": e["bibkey"],
                "page": e["page"],
                "literature_label": e["literature_label"],
                "scene_kind": e["scene_kind"],
                "reallms_foreign_primitive": e["foreign_primitive"],
                "reallms_illicit_host": e["illicit_host"],
            }
            for e in exported
        ],
    }
    metadata_json = html.escape(json.dumps(metadata, indent=2), quote=False)
    html_doc = f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Real transplant exemplars (ReaLLMs-flagged)</title>
  <style>
    body {{ margin: 0; background: #f8f1df; color: #1b1810; font-family: system-ui, sans-serif; }}
    main {{ max-width: 1080px; margin: 0 auto; padding: 28px; }}
    h1 {{ font-family: Georgia, "Times New Roman", serif; font-size: 30px; margin: 0 0 8px; }}
    .residue {{ max-width: 760px; color: #4d4638; margin: 0 0 24px; }}
    .card {{ background: #fffaf0; border: 1px solid #cabf9f; padding: 18px; margin-bottom: 22px; }}
    .card h2 {{ font-family: Georgia, "Times New Roman", serif; margin: 0 0 6px; }}
    .source {{ color: #4d4638; margin: 0 0 12px; }}
    code {{ font-size: 12px; color: #4d4638; }}
    img.filmstrip {{ display: block; width: 100%; max-width: 100%; background: #f8f1df; border: 1px solid #cabf9f; }}
    .frames {{ display: flex; flex-wrap: wrap; gap: 10px; margin-top: 12px; }}
    .frames figure {{ margin: 0; width: 180px; }}
    .frames img {{ width: 180px; background: #f8f1df; border: 1px solid #cabf9f; }}
    figcaption {{ font-size: 12px; color: #6d5b31; margin-top: 4px; }}
  </style>
</head>
<body>
<main>
  <h1>Real transplant exemplars (ReaLLMs-flagged)</h1>
  <p class="residue">Three real student-work figures the ReaLLMs descriptor pass
  flagged as hybridized transplants. Each filmstrip models the transplant
  grammar (host, licensed home, transplant, hybrid result) and is labeled with
  the literature source. The figures themselves remain the evidence; the SVG is
  the model, not a redraw of the student page.</p>
{cards_html}
  <script type="application/json" id="real-transplant-exemplars">
{metadata_json}
  </script>
</main>
</body>
</html>
"""
    path = out_dir / "index.html"
    path.write_text(html_doc, encoding="utf-8")
    return path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--out",
        type=Path,
        default=DEFAULT_OUT,
        help=f"Output directory. Default: {DEFAULT_OUT}",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    out_dir = args.out.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    classifications = load_classifications()
    exported: list[dict] = []
    written: list[Path] = []

    for transplant in REAL_TRANSPLANTS:
        image_path, record = find_record(
            classifications, transplant["bibkey"], transplant["page"]
        )
        if not record.get("is_hybridized_transplant"):
            raise RuntimeError(
                f"{transplant['bibkey']} {transplant['page']} is not flagged "
                "is_hybridized_transplant; refusing to render it as one."
            )
        doc = labelled_doc(transplant, record)
        code = transplant["code"]
        # Persist the labeled doc so the artifact is auditable.
        doc_path = out_dir / f"{code}-doc.json"
        doc_path.write_text(json.dumps(doc, indent=2), encoding="utf-8")
        filmstrip = write_filmstrip(out_dir, code, doc)
        frames = write_frames(out_dir, code, doc)
        details = record.get("hybrid_details") or {}
        exported.append(
            {
                "code": code,
                "bibkey": transplant["bibkey"],
                "page": transplant["page"],
                "literature_label": doc["literature_label"],
                "scene_kind": transplant["scene_kind"],
                "foreign_primitive": details.get("foreign_primitive", ""),
                "illicit_host": details.get("illicit_host", ""),
                "image_path": repo_relative(image_path),
                "filmstrip_file": repo_relative(filmstrip),
                "frame_files": [repo_relative(p) for p in frames],
            }
        )
        written.append(doc_path)
        written.append(filmstrip)
        written.extend(frames)

    index = build_index_html(out_dir, exported)
    written.append(index)

    manifest = out_dir / "real_transplants_manifest.json"
    manifest.write_text(json.dumps(exported, indent=2), encoding="utf-8")
    written.append(manifest)

    print(f"Wrote real transplant exemplars to {out_dir}")
    for path in written:
        print(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
