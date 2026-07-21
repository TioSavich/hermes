#!/usr/bin/env python3
"""Render lesson-specific deformation monitoring charts as SVG.

The usefulness payoff: "given a grade-3 IM lesson on 1/N modeled with a circle or
a fraction strip, here are the student-work errors to watch for, rendered on 1/N."

The wire (the established render pattern, reusing the node drawer.js harness from
export_parametric_deformations.py verbatim):

  curriculum/im/lesson_deformation_chart.pl
      decides WHICH deformations to watch for, on WHICH fraction, for each real
      IM lesson -- every deformation gated through the grammar's misconception
      lane (representation_grammar:deformation_spec_evidence/4 and
      parametric_fraction_errors:error_evidence/4), so it is a labeled
      misconception, never an unlabeled productive diagram.
      -> a monitoring-chart dict (swipl -l paths.pl, json_write_dict) -> here
      -> hermes/web/render/drawer.js buildSvg -> SVG filmstrips.

Logic lives in Prolog; this script is projection plus layout. It does NOT edit
representation_grammar.pl or drawer.js. Output under
hermes/app/web/generated/lesson_deformation_charts/<lesson-code>/.

Run: python3 hermes/app/scripts/export_lesson_deformation_charts.py

Lean layout (``--lean``) is for remote, all-lesson generation. Each lesson
directory contains ``chart.json``, ``index.html``, one representative
productive filmstrip, and one representative filmstrip for each admitted
deformation kind. It deliberately does not emit one strip for every chart cell
or frame; the complete chart remains in ``chart.json``. The layout is bounded
at 12 files per lesson. Full mode remains the default for the hand galleries.
"""
from __future__ import annotations

import html
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO))
from hermes.app.scripts import export_engine

OUT = export_engine.gallery_output(REPO / "hermes" / "app" / "web" / "generated" / "lesson_deformation_charts")
MAX_LEAN_FILES_PER_LESSON = 12

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


# --- render one lesson's chart -----------------------------------------------

def export_lesson(out_dir: Path, code: str, chart: dict, *, lean: bool = False) -> dict:
    lesson_dir = out_dir / code
    lesson_dir.mkdir(parents=True, exist_ok=True)

    export_engine.write_json(lesson_dir / "chart.json", chart)

    written = [lesson_dir / "chart.json"]
    if lean:
        return export_lesson_lean(lesson_dir, code, chart, written)

    cell_records = []
    for cell in chart["cells"]:
        host = cell["host"]
        frac = cell["fraction"]
        n = cell["denominator"]
        frac_slug = _slug(frac)

        # productive scene (B/M/E)
        prod = cell["productive"]
        prod_frames = prod["frames"]
        prod_file = lesson_dir / f"{host}-{frac_slug}-PRODUCTIVE.svg"
        render(
            prod_frames, prod_file,
            [_verb_label(f) for f in prod_frames],
            title=f"{host}: correct {frac} (establish - partition - shade)",
            panel_w=250, panel_h=210,
        )
        written.append(prod_file)

        # deformation scenes (labeled misconceptions only)
        deform_records = []
        for d in cell["deformations"]:
            name = d["deformation"]
            scene = d["scene"]
            frames = scene["frames"]
            d_slug = _slug(name)
            d_file = lesson_dir / f"{host}-{frac_slug}-{d_slug}.svg"
            render(
                frames, d_file,
                [_verb_label(f) for f in frames],
                title=f"WATCH FOR: {name} of {frac} on a {host}",
                panel_w=300, panel_h=210,
            )
            written.append(d_file)
            deform_records.append({
                "deformation": name,
                "family": d["family"],
                "file": d_file.name,
                "frame_count": len(frames),
            })

        cell_records.append({
            "host": host,
            "fraction": frac,
            "denominator": n,
            "productive_file": prod_file.name,
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


def export_lesson_lean(lesson_dir: Path, code: str, chart: dict, written: list[Path]) -> dict:
    """Render one deterministic representative filmstrip for each chart kind."""
    cells = chart["cells"]
    if not cells:
        raise ValueError(f"{code} has no deformation chart cells")

    productive_cell = cells[0]
    productive = productive_cell["productive"]
    productive_file = lesson_dir / "LEAN-PRODUCTIVE.svg"
    render(
        productive["frames"], productive_file,
        [_verb_label(frame) for frame in productive["frames"]],
        title=(f"Representative productive model: {productive_cell['fraction']} "
               f"on a {productive_cell['host']}"),
        panel_w=250, panel_h=210,
    )
    written.append(productive_file)

    selected = []
    seen_kinds = set()
    for cell in cells:
        for deformation in cell["deformations"]:
            name = deformation["deformation"]
            if name in seen_kinds:
                continue
            seen_kinds.add(name)
            scene = deformation["scene"]
            deformation_file = lesson_dir / f"LEAN-{_slug(name)}.svg"
            render(
                scene["frames"], deformation_file,
                [_verb_label(frame) for frame in scene["frames"]],
                title=(f"WATCH FOR: {name} of {cell['fraction']} "
                       f"on a {cell['host']}"),
                panel_w=300, panel_h=210,
            )
            written.append(deformation_file)
            selected.append({
                "deformation": name,
                "family": deformation["family"],
                "file": deformation_file.name,
                "frame_count": len(scene["frames"]),
                "source_host": cell["host"],
                "source_fraction": cell["fraction"],
            })

    export_engine.write_index(
        lesson_dir,
        build_lean_lesson_index(chart, productive_cell, productive_file.name, selected),
    )
    written.append(lesson_dir / "index.html")
    if len(written) > MAX_LEAN_FILES_PER_LESSON:
        raise ValueError(
            f"{code} lean export produced {len(written)} files; "
            f"limit is {MAX_LEAN_FILES_PER_LESSON}"
        )
    return {
        "code": code,
        "title": chart["title"],
        "standards": chart["standards"],
        "hosts": chart["hosts"],
        "fractions": chart["fractions"],
        "provenance": chart["provenance"],
        "cell_count": len(cells),
        "deformation_kinds": [item["deformation"] for item in selected],
        "files": [str(path) for path in written],
        "dir": str(lesson_dir),
    }


# --- the per-lesson index page -----------------------------------------------

def build_lesson_index(chart: dict, cells: list) -> str:
    code = chart["lesson_code"]
    title = chart["title"]
    standards = ", ".join(chart["standards"])
    fractions = ", ".join(chart["fractions"])
    provenance = chart["provenance"].replace("_", " ")
    rows = []
    rows.append("<!doctype html><meta charset=utf-8>")
    rows.append(f"<title>{html.escape(code)} - deformations to watch for</title>")
    rows.append("<body style='font-family:system-ui;background:#f8f1df;color:#1b1810;"
                "max-width:1180px;margin:0 auto;padding:28px'>")
    rows.append(f"<h1 style=\"font-family:Georgia,'Times New Roman',serif\">"
                f"{html.escape(code)}: {html.escape(title)}</h1>")
    rows.append(f"<p><strong>Standards:</strong> {html.escape(standards)} &nbsp; "
                f"<strong>Fractions:</strong> {html.escape(fractions)} &nbsp; "
                f"<strong>Chart source:</strong> {html.escape(provenance)}</p>")
    rows.append("<p style='max-width:820px;line-height:1.45'>This is the monitoring "
                "chart for the lesson: the <em>productive</em> model for each of the "
                "lesson's fractions, beside the <em>likely student-work deformations</em> "
                "to watch for on each representation, drawn on the lesson's own "
                "fraction. The deformations are parametric: the same error rule "
                "regenerates for every fraction the lesson names. Each deformation is "
                "a labeled misconception, gated through the representation grammar's "
                "misconception lane &mdash; never an unlabeled productive diagram. "
                "Logic in <code>curriculum/im/lesson_deformation_chart.pl</code>; render "
                "projected through <code>hermes/web/render/drawer.js</code>.</p>")

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


def build_lean_lesson_index(chart: dict, productive_cell: dict, productive_file: str,
                            deformations: list[dict]) -> str:
    """Build a compact, explicit index for the remote lean layout."""
    code = chart["lesson_code"]
    rows = [
        "<!doctype html><meta charset=utf-8>",
        f"<title>{html.escape(code)} - lean deformation chart</title>",
        "<body style='font-family:system-ui;background:#f8f1df;color:#1b1810;"
        "max-width:1180px;margin:0 auto;padding:28px'>",
        f"<h1 style=\"font-family:Georgia,'Times New Roman',serif\">"
        f"{html.escape(code)}: lean deformation chart</h1>",
        "<p style='max-width:820px;line-height:1.45'>This compact remote-export "
        "layout retains the complete chart in <code>chart.json</code>, one "
        "representative productive filmstrip, and one representative filmstrip "
        "for each admitted deformation kind. It is not a cell-by-cell gallery.</p>",
        "<h2>Representative productive model</h2>",
        f"<p>{html.escape(productive_cell['fraction'])} on a "
        f"{html.escape(productive_cell['host'])}</p>",
        f"<img src='{html.escape(productive_file, quote=True)}' "
        "style='max-width:420px;border:1px solid #cabf9f;background:#f8f1df'>",
        "<h2>Admitted deformation kinds</h2>",
        "<div style='display:flex;flex-wrap:wrap;gap:14px;align-items:flex-start'>",
    ]
    for deformation in deformations:
        rows.append(
            "<figure style='margin:0'><figcaption style='font-size:13px;"
            "font-weight:700;color:#8b1e16'>"
            f"Watch for: {html.escape(deformation['deformation'])} "
            f"({html.escape(deformation['source_fraction'])} on "
            f"{html.escape(deformation['source_host'])})</figcaption>"
            f"<img src='{html.escape(deformation['file'], quote=True)}' "
            "style='max-width:420px;border:1px solid #cabf9f;background:#f8f1df'></figure>"
        )
    rows.extend(["</div>", "</body>"])
    return "\n".join(rows)


# --- the top-level index across all charted lessons ---------------------------

def build_top_index(records: list, *, lean: bool = False) -> str:
    rows = []
    rows.append("<!doctype html><meta charset=utf-8>")
    rows.append("<title>Lesson deformation monitoring charts</title>")
    rows.append("<body style='font-family:system-ui;background:#f8f1df;color:#1b1810;"
                "max-width:900px;margin:0 auto;padding:28px'>")
    rows.append("<h1 style=\"font-family:Georgia,'Times New Roman',serif\">"
                "Lesson deformation monitoring charts</h1>")
    rows.append("<p style='max-width:760px;line-height:1.45'>For each charted "
                "Illustrative Mathematics fraction lesson, the productive model for "
                "the lesson's fractions beside the student-work deformations to watch "
                "for, rendered on the lesson's own fractions. The deformations are "
                "parametric over the fraction and grounded in the corpus-attested "
                "transplant and equipartition-failure families.</p>")
    if lean:
        rows.append("<p><strong>Lean export:</strong> each lesson has one productive "
                    "filmstrip and one filmstrip for each admitted deformation kind; "
                    "the complete cell data remains in its chart.json.</p>")
    rows.append("<ul>")
    for r in records:
        rows.append(
            f"<li><a href='{html.escape(r['code'])}/index.html'>"
            f"{html.escape(r['code'])}: {html.escape(r['title'])}</a> "
            f"&mdash; {html.escape(', '.join(r['standards']))}; "
            f"fractions {html.escape(', '.join(r['fractions']))}; "
            f"{r['cell_count']} cells</li>"
        )
    rows.append("</ul>")
    rows.append("</body>")
    return "\n".join(rows)


def main() -> int:
    def configure(parser):
        parser.add_argument("--limit", type=int, default=0,
                            help="Export the first N charted lessons (default: all).")
        parser.add_argument("--lean", action="store_true",
                            help="Emit a compact representative gallery for each lesson.")

    args = export_engine.parse_args(__doc__, default_out=OUT, configure=configure)
    started = time.monotonic()
    out_dir = args.out.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    enumerated = lesson_charts(args.limit)
    charts = {chart["lesson_code"]: chart for chart in enumerated["charts"]}
    codes = enumerated["codes"]
    records = [export_lesson(out_dir, code, charts[code], lean=args.lean) for code in codes]

    export_engine.write_index(out_dir, build_top_index(records, lean=args.lean))

    manifest = {
        "kind": "lesson_deformation_charts",
        "lean": args.lean,
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
    }
    export_engine.write_json(out_dir / "manifest.json", manifest)

    total_files = sum(len(r["files"]) for r in records)
    elapsed = time.monotonic() - started
    print(f"Wrote {total_files} files across {len(records)} lessons to {out_dir}")
    print(f"Enumerated {len(enumerated['all_codes'])} charted lessons; wall time {elapsed:.2f}s")
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
