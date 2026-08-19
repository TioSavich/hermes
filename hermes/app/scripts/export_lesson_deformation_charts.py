#!/usr/bin/env python3
"""Render supported lesson deformation charts and their shared SVG drawings.

"Given a lesson charted on 1/N modeled with a circle or a fraction strip, here
are the student-work errors to watch for, rendered on 1/N."

The wire (the established render pattern, reusing the node drawer.js harness from
export_parametric_deformations.py verbatim):

  curriculum/im/lesson_deformation_chart.pl
      decides WHICH deformations to watch for, on WHICH fraction, for each
      charted IM lesson -- every deformation gated through the grammar's
      misconception lane (representation_grammar:deformation_spec_evidence/4 and
      parametric_fraction_errors:error_evidence/4), so it is a labeled
      misconception, never an unlabeled productive diagram.
      -> a monitoring-chart dict (swipl -l paths.pl, json_write_dict) -> here
      -> hermes/web/render/drawer.js buildSvg -> SVG filmstrips.

WHICH fraction is where the honesty lives. Only 3 of the 77 enumerated charts
take their hosts and fractions from a teacher guide. The other 74 take one fixed
default set (chart_provenance/2 in the Prolog module records which), so this
exporter withdraws them rather than publishing lesson-named directories.

Logic lives in Prolog; this script is projection plus layout. It does NOT edit
representation_grammar.pl or drawer.js. The distinct drawings are written once
under hermes/app/web/generated/lesson_deformation_charts/_shared/. Only
hand_authored charts receive lesson directories, and their indexes reference
the shared drawings.

Run: python3 hermes/app/scripts/export_lesson_deformation_charts.py

"""
from __future__ import annotations

import html
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO))
from hermes.app.scripts import export_engine

OUT = export_engine.gallery_output(REPO / "hermes" / "app" / "web" / "generated" / "lesson_deformation_charts")

# --- Enumerate and build every chart in one SWI-Prolog process ----------------

def lesson_charts(limit: int = 0) -> dict:
    goal = (
        "findall(Code, lesson_deformation_chart:lesson_chart_lesson("
        "Code, _, _, _, _), Codes0), sort(Codes0, AllCodes), "
        f"Limit = {limit}, length(AllCodes, Total), "
        "( Limit > 0, Limit < Total "
        "  -> length(Codes, Limit), append(Codes, _, AllCodes) "
        "  ; Codes = AllCodes ), "
        "findall(Chart, (member(Code, Codes), "
        "lesson_deformation_chart:monitoring_chart(Code, Chart)), Charts), "
        "Doc = _{codes: Codes, all_codes: AllCodes, charts: Charts}"
    )
    return export_engine.run_swipl_batch(
        [export_engine.SwiplRequest("lesson-deformation-charts", goal)],
        prelude=("use_module(lessons('im/lesson_deformation_chart'))",),
    )["lesson-deformation-charts"]


# --- shared drawer adapter ---------------------------------------------------

def render(frames, out_file, labels, *, title="", captions=None,
           panel_w=270, panel_h=220, canvas=None):
    doc = {"frames": frames, "canvas": canvas or {}}
    export_engine.render_svg(
        doc, "filmstrip", out_file, labels=labels, title=title,
        captions=captions or [], panelWidth=panel_w, panelHeight=panel_h,
        captionEllipsis=True,
        ariaLabel=title or "lesson deformation monitoring chart",
    )
    return out_file


def _verb_label(frame: dict) -> str:
    verb = str(frame.get("verb", ""))
    head = verb.split("(", 1)[0] if verb else f"step {frame.get('step', '?')}"
    return head.replace("_", " ")


def _slug(s: str) -> str:
    return (
        str(s)
        .replace("/", "-")
        .replace("(", "-")
        .replace(")", "")
        .replace(" ", "")
    )


# --- render one supported lesson chart ---------------------------------------

def export_lesson(out_dir: Path, shared_dir: Path, code: str, chart: dict,
                  rendered: set[str]) -> dict:
    lesson_dir = out_dir / code
    lesson_dir.mkdir(parents=True, exist_ok=True)

    export_engine.write_json(lesson_dir / "chart.json", chart)

    written = [lesson_dir / "chart.json"]
    cell_records = []
    for cell in chart["cells"]:
        host = cell["host"]
        frac = cell["fraction"]
        n = cell["denominator"]
        frac_slug = _slug(frac)

        # productive scene (B/M/E)
        prod = cell["productive"]
        prod_frames = prod["frames"]
        prod_name = f"{host}-{frac_slug}-PRODUCTIVE.svg"
        if prod_name not in rendered:
            render(
                prod_frames, shared_dir / prod_name,
                [_verb_label(f) for f in prod_frames],
                title=f"{host}: correct {frac} (establish - partition - shade)",
                panel_w=250, panel_h=210,
            )
            rendered.add(prod_name)

        # deformation scenes (labeled misconceptions only)
        deform_records = []
        for d in cell["deformations"]:
            name = d["deformation"]
            scene = d["scene"]
            frames = scene["frames"]
            d_slug = _slug(name)
            drawing_name = f"{host}-{frac_slug}-{d_slug}.svg"
            if drawing_name not in rendered:
                render(
                    frames, shared_dir / drawing_name,
                    [_verb_label(f) for f in frames],
                    title=f"WATCH FOR: {name} of {frac} on a {host}",
                    panel_w=300, panel_h=210,
                )
                rendered.add(drawing_name)
            deform_records.append({
                "deformation": name,
                "family": d["family"],
                "file": f"../_shared/{drawing_name}",
                "frame_count": len(frames),
            })

        cell_records.append({
            "host": host,
            "fraction": frac,
            "denominator": n,
            "productive_file": f"../_shared/{prod_name}",
            "deformations": deform_records,
        })

    index = build_lesson_index(chart, cell_records)
    export_engine.write_index(lesson_dir, index)
    written.append(lesson_dir / "index.html")

    return {
        "code": code,
        "title": chart["title"],
        "standards": chart["standards"],
        "hosts": chart["hosts"],
        "fractions": chart["fractions"],
        "provenance": chart["provenance"],
        "cell_count": len(cell_records),
        "cells": cell_records,
        "files": [str(w) for w in written],
        "dir": str(lesson_dir),
    }


# --- the per-lesson index page -----------------------------------------------

PROVENANCE_LABEL = {
    "hand_authored": "read from the teacher guide",
    "default_fill": "fixed default set, not read from this lesson",
}

# Default fill covers most of the gallery, so the banner carries the warmer
# colour and the body copy changes with the provenance rather than describing
# quantities the chart does not have.
PROVENANCE_BANNER_STYLE = {
    "hand_authored": "border-left:4px solid #365f6b;background:#eef3f4",
    "default_fill": "border-left:4px solid #8b1e16;background:#f7ece9",
}


def provenance_banner(chart: dict) -> str:
    """A block that states the chart's provenance in the module's own words."""
    provenance = chart.get("provenance", "default_fill")
    note = chart.get("provenance_note", "")
    label = PROVENANCE_LABEL.get(provenance, provenance.replace("_", " "))
    style = PROVENANCE_BANNER_STYLE.get(provenance, PROVENANCE_BANNER_STYLE["default_fill"])
    return (
        f"<div style='{style};max-width:820px;padding:12px 16px;margin:18px 0;"
        "line-height:1.45'>"
        f"<strong>Quantities: {html.escape(label)}</strong> "
        f"(<code>provenance: {html.escape(provenance)}</code>)"
        f"<br>{html.escape(note)}</div>"
    )


def chart_body_copy(chart: dict) -> str:
    """What the chart reports, worded to the provenance it actually has."""
    if chart.get("provenance") == "hand_authored":
        opening = (
            "This is the monitoring chart for the lesson: the <em>productive</em> "
            "model for each fraction the teacher guide names, beside the "
            "<em>likely student-work deformations</em> to watch for on each "
            "representation, drawn on that same fraction."
        )
    else:
        opening = (
            "The hosts and fractions below are the chart's fixed default set, "
            "handed to every lesson that was not read. Each pair is the "
            "<em>productive</em> model for a default fraction beside the "
            "<em>likely student-work deformations</em> on that representation. "
            "The pairs report the deformation families; they do not report what "
            "this lesson asks children to model."
        )
    return (
        "<p style='max-width:820px;line-height:1.45'>" + opening +
        " The deformations are parametric: the same error rule regenerates for "
        "any fraction handed to it. Each deformation is a labeled misconception, "
        "gated through the representation grammar's misconception lane &mdash; "
        "never an unlabeled productive diagram. Logic in "
        "<code>curriculum/im/lesson_deformation_chart.pl</code>; render "
        "projected through <code>hermes/web/render/drawer.js</code>.</p>"
    )


def build_lesson_index(chart: dict, cells: list) -> str:
    code = chart["lesson_code"]
    title = chart["title"]
    standards = ", ".join(chart["standards"])
    fractions = ", ".join(chart["fractions"])
    rows = []
    rows.append("<!doctype html><meta charset=utf-8>")
    rows.append(f"<title>{html.escape(code)} - deformations to watch for</title>")
    rows.append("<body style='font-family:system-ui;background:#f8f1df;color:#1b1810;"
                "max-width:1180px;margin:0 auto;padding:28px'>")
    rows.append(f"<h1 style=\"font-family:Georgia,'Times New Roman',serif\">"
                f"{html.escape(code)}: {html.escape(title)}</h1>")
    rows.append(f"<p><strong>Standards:</strong> {html.escape(standards)} &nbsp; "
                f"<strong>Fractions charted:</strong> {html.escape(fractions)}</p>")
    rows.append(provenance_banner(chart))
    rows.append(chart_body_copy(chart))

    # group cells by host, then fraction
    by_host: dict[str, list] = {}
    for c in cells:
        by_host.setdefault(c["host"], []).append(c)

    for host, host_cells in by_host.items():
        rows.append(f"<h2>Host: {html.escape(host)}</h2>")
        for c in host_cells:
            rows.append(f"<h3>{html.escape(c['fraction'])} on a {html.escape(host)}</h3>")
            rows.append("<div style='display:flex;flex-wrap:wrap;gap:14px;align-items:flex-start'>")
            rows.append("<figure style='margin:0'>"
                        "<figcaption style='font-size:13px;font-weight:700;color:#365f6b'>"
                        "Productive (the lesson's correct model)</figcaption>"
                        f"<img src='{html.escape(c['productive_file'], quote=True)}' "
                        "style='max-width:420px;border:1px solid #cabf9f;background:#f8f1df'></figure>")
            for d in c["deformations"]:
                rows.append("<figure style='margin:0'>"
                            "<figcaption style='font-size:13px;font-weight:700;color:#8b1e16'>"
                            f"Watch for: {html.escape(d['deformation'])}</figcaption>"
                            f"<img src='{html.escape(d['file'], quote=True)}' "
                            "style='max-width:420px;border:1px solid #cabf9f;background:#f8f1df'></figure>")
            rows.append("</div>")

    rows.append("</body>")
    return "\n".join(rows)


# --- the top-level index across all charted lessons ---------------------------

def build_top_index(records: list, shared_drawings: list[str]) -> str:
    rows = []
    rows.append("<!doctype html><meta charset=utf-8>")
    rows.append("<title>Lesson deformation charts</title>")
    rows.append("<body style='font-family:system-ui;background:#f8f1df;color:#1b1810;"
                "max-width:900px;margin:0 auto;padding:28px'>")
    rows.append("<h1 style=\"font-family:Georgia,'Times New Roman',serif\">"
                "Lesson deformation charts</h1>")
    rows.append("<p style='max-width:760px;line-height:1.45'>The productive model "
                "for a unit fraction, beside the deformations to watch for on it.</p>")
    rows.append("<h2 style=\"font-family:Georgia,serif;font-size:1.05rem\">Charted lessons</h2>")
    lesson_items = []
    for r in records:
        lesson_items.append(
            "<li style='margin:.45rem 0'>"
            f"<a href='{html.escape(r['code'], quote=True)}/index.html'>"
            f"{html.escape(r['code'])}</a> &middot; {html.escape(r['title'])}<br>"
            "<span style='color:#6b6252;font-size:.88rem'>hosts "
            f"{html.escape(', '.join(r['hosts']))} &middot; unit fractions "
            f"{html.escape(', '.join(r['fractions']))}</span></li>"
        )
    rows.append("<ul>" + "".join(lesson_items) + "</ul>")
    rows.append("<h2 style=\"font-family:Georgia,serif;font-size:1.05rem\">The drawings</h2>")
    rows.append("<p style='max-width:760px;line-height:1.45'>Drawn from the host "
                "and the unit fraction, not from student work.</p>")
    rows.append("<ul style='columns:2;font-size:.9rem'>" + "".join(
        "<li style='margin:.2rem 0'>"
        f"<a href='_shared/{html.escape(name, quote=True)}'>{html.escape(name)}</a></li>"
        for name in shared_drawings
    ) + "</ul>")
    rows.append("</body>")
    return "\n".join(rows)


def main() -> int:
    def configure(parser):
        parser.add_argument("--limit", type=int, default=0,
                            help="Export the first N charted lessons (default: all).")

    args = export_engine.parse_args(__doc__, default_out=OUT, configure=configure)
    out_dir = args.out.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    enumerated = lesson_charts(args.limit)
    charts = {chart["lesson_code"]: chart for chart in enumerated["charts"]}
    codes = [
        code for code in enumerated["codes"]
        if charts[code].get("provenance") == "hand_authored"
    ]
    withdrawn = sum(
        chart.get("provenance") != "hand_authored"
        for chart in enumerated["charts"]
    )
    shared_dir = out_dir / "_shared"
    shared_dir.mkdir(parents=True, exist_ok=True)
    rendered: set[str] = set()
    records = [
        export_lesson(out_dir, shared_dir, code, charts[code], rendered)
        for code in codes
    ]
    shared_drawings = sorted(rendered)

    export_engine.write_index(out_dir, build_top_index(records, shared_drawings))

    manifest = {
        "kind": "lesson_deformation_charts",
        "lean": False,
        "provenance_census": {
            "hand_authored": len(records),
            "default_fill": 0,
            "total": len(records),
            "note": "Charted lessons are those whose hosts and unit fractions are "
                    "read off the lesson's own teacher guide. The "
                    f"{withdrawn} default_fill lessons were withdrawn on 2026-08-19: "
                    "they carried the chart's fixed default hosts and fractions, so "
                    "they said nothing about the lesson they were named for. The "
                    "drawings they used are kept once each in _shared/. No coverage "
                    "number may cite this manifest.",
        },
        "lessons": [
            {
                "code": r["code"],
                "title": r["title"],
                "standards": r["standards"],
                "hosts": r["hosts"],
                "fractions": r["fractions"],
                "provenance": r["provenance"],
                "cell_count": r["cell_count"],
                "deformations_per_cell": r.get("deformation_kinds") or sorted({
                    d["deformation"]
                    for c in r.get("cells", []) for d in c["deformations"]
                }),
            }
            for r in records
        ],
        "shared_drawings": shared_drawings,
    }
    export_engine.write_json(out_dir / "manifest.json", manifest)

    total_files = len(shared_drawings) + sum(len(r["files"]) for r in records)
    print(f"Wrote {total_files} lesson/shared files across "
          f"{len(records)} hand-authored lessons to {out_dir}")
    print(f"Enumerated {len(enumerated['all_codes'])} chart definitions; "
          f"withdrew {withdrawn} default-fill lesson directories")
    for r in records:
        defs = r.get("deformation_kinds") or sorted({
            d["deformation"]
            for c in r.get("cells", []) for d in c["deformations"]
        })
        print(f"  {r['code']} ({r['title']}): {r['cell_count']} cells; "
              f"fractions {', '.join(r['fractions'])}; "
              f"deformations {', '.join(defs)}")
    print(out_dir / "index.html")
    print(out_dir / "manifest.json")
    return 0


if __name__ == "__main__":
    raise SystemExit(export_engine.exporter_main(main, OUT))
