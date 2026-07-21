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
      -> more-zeeman/render/drawer.js buildSvg -> SVG filmstrips.

Logic lives in Prolog; this script is projection plus layout. It does NOT edit
representation_grammar.pl or drawer.js. Output under
hermes/app/web/generated/lesson_deformation_charts/<lesson-code>/.

Run: python3 hermes/app/scripts/export_lesson_deformation_charts.py
"""
from __future__ import annotations

import html
import json
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO))
from hermes.app import rendering

OUT = rendering.gallery_output(REPO / "hermes" / "app" / "web" / "generated" / "lesson_deformation_charts")

LESSONS = ["IM-G3-U5-L1", "IM-G3-U5-L2", "IM-G3-U5-L15"]


# --- Ask swipl for one lesson's monitoring chart -----------------------------

def lesson_chart(code: str) -> dict:
    goal = (
        "use_module(lessons('im/lesson_deformation_chart')), "
        "use_module(library(http/json)), "
        f"( lesson_deformation_chart:monitoring_chart('{code}', Doc) "
        "  -> json_write_dict(user_output, Doc, [width(0)]), nl "
        "  ; (write(user_error, 'no chart'), nl(user_error)) ), halt."
    )
    res = subprocess.run(
        ["swipl", "-q", "-l", "paths.pl", "-g", goal, "-t", "halt(1)"],
        cwd=REPO, capture_output=True, text=True,
    )
    lines = [l for l in res.stdout.splitlines() if l.startswith("{")]
    if not lines:
        sys.stderr.write(res.stdout + "\n" + res.stderr)
        raise SystemExit(f"swipl produced no chart for {code}")
    return json.loads(lines[0])


# --- shared drawer adapter ---------------------------------------------------

def render(frames, out_file, labels, *, title="", captions=None,
           panel_w=270, panel_h=220, canvas=None):
    doc = {"frames": frames, "canvas": canvas or {}}
    rendering.render_svg(
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

def export_lesson(code: str) -> dict:
    chart = lesson_chart(code)
    lesson_dir = OUT / code
    lesson_dir.mkdir(parents=True, exist_ok=True)

    (lesson_dir / "chart.json").write_text(
        json.dumps(chart, indent=2), encoding="utf-8"
    )

    written = []
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
    (lesson_dir / "index.html").write_text(index, encoding="utf-8")
    written.append(lesson_dir / "index.html")

    return {
        "code": code,
        "title": chart["title"],
        "standards": chart["standards"],
        "hosts": chart["hosts"],
        "fractions": chart["fractions"],
        "cell_count": len(cell_records),
        "cells": cell_records,
        "files": [str(w) for w in written],
        "dir": str(lesson_dir),
    }


# --- the per-lesson index page -----------------------------------------------

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
                f"<strong>Fractions:</strong> {html.escape(fractions)}</p>")
    rows.append("<p style='max-width:820px;line-height:1.45'>This is the monitoring "
                "chart for the lesson: the <em>productive</em> model for each of the "
                "lesson's fractions, beside the <em>likely student-work deformations</em> "
                "to watch for on each representation, drawn on the lesson's own "
                "fraction. The deformations are parametric: the same error rule "
                "regenerates for every fraction the lesson names. Each deformation is "
                "a labeled misconception, gated through the representation grammar's "
                "misconception lane &mdash; never an unlabeled productive diagram. "
                "Logic in <code>curriculum/im/lesson_deformation_chart.pl</code>; render "
                "projected through <code>more-zeeman/render/drawer.js</code>.</p>")

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


# --- the top-level index across the three lessons ----------------------------

def build_top_index(records: list) -> str:
    rows = []
    rows.append("<!doctype html><meta charset=utf-8>")
    rows.append("<title>Lesson deformation monitoring charts</title>")
    rows.append("<body style='font-family:system-ui;background:#f8f1df;color:#1b1810;"
                "max-width:900px;margin:0 auto;padding:28px'>")
    rows.append("<h1 style=\"font-family:Georgia,'Times New Roman',serif\">"
                "Lesson deformation monitoring charts</h1>")
    rows.append("<p style='max-width:760px;line-height:1.45'>For three real grade-3 "
                "Illustrative Mathematics fraction lessons, the productive model for "
                "the lesson's fractions beside the student-work deformations to watch "
                "for, rendered on the lesson's own fractions. The deformations are "
                "parametric over the fraction and grounded in the corpus-attested "
                "transplant and equipartition-failure families.</p>")
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
    OUT.mkdir(parents=True, exist_ok=True)
    records = [export_lesson(code) for code in LESSONS]

    (OUT / "index.html").write_text(build_top_index(records), encoding="utf-8")

    manifest = {
        "kind": "lesson_deformation_charts",
        "lessons": [
            {
                "code": r["code"],
                "title": r["title"],
                "standards": r["standards"],
                "hosts": r["hosts"],
                "fractions": r["fractions"],
                "cell_count": r["cell_count"],
                "deformations_per_cell": sorted({
                    d["deformation"]
                    for c in r["cells"] for d in c["deformations"]
                }),
            }
            for r in records
        ],
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2),
                                       encoding="utf-8")

    total_files = sum(len(r["files"]) for r in records)
    print(f"Wrote {total_files} SVG/HTML files across {len(records)} lessons to {OUT}")
    for r in records:
        defs = sorted({d["deformation"] for c in r["cells"] for d in c["deformations"]})
        print(f"  {r['code']} ({r['title']}): {r['cell_count']} cells; "
              f"fractions {', '.join(r['fractions'])}; "
              f"deformations {', '.join(defs)}")
    print(OUT / "index.html")
    print(OUT / "manifest.json")
    return 0


if __name__ == "__main__":
    if "--check" in sys.argv:
        raise SystemExit(rendering.check_exporter(Path(__file__), OUT))
    raise SystemExit(main())
