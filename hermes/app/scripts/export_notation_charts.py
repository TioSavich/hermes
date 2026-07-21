#!/usr/bin/env python3
"""Render lesson-specific NOTATION monitoring charts as SVG filmstrips.

This is the notation cousin of export_lesson_deformation_charts.py. It uses the
shared drawer adapter with title and per-frame panels, but consumes
lessons/im/lesson_notation_chart.pl:notation_monitoring_chart/2 instead of the
fraction monitoring_chart/2. The two pipelines never collide: the fraction
chart is keyed on frac(M,N) and backs the live grade-3 fraction charts; this
chart is keyed on equation(A,Op,B,R) and emits equation/operands fields.

Each IM lesson with an encoded addition, subtraction, or multiplication
attachment hosts one chart. The Prolog layer chooses the operation and admits
only deformations supported by cited evidence; this script projects those
charts without adding a grade heuristic.

The honesty boundary the chart must carry, not hide:

  - A notation deformation is hosted on an operation lesson and rendered over
    a representative equation from the chosen operation. The chart is a
    parametric render over that equation, not a count of corpus instances of
    the deformation in the lesson. Every lesson index says so.
  - Every deformation carries its provenance (corpus_attested | literature_only)
    read off the grammar's own Evidence dict via
    parametric_notation_deformation:notation_deformation_evidence/2. The index
    prints the provenance on each deformation's honesty card.

Logic lives in Prolog; this script is projection plus layout. It does NOT edit
representation_grammar.pl, drawer.js, the notation compiler, or the fraction
chart. Output under
hermes/app/web/generated/notation_lesson_charts/<lesson-code>/.

Run: python3 hermes/app/scripts/export_notation_charts.py
"""
from __future__ import annotations

import argparse
import html
import json
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO))
from hermes.app import rendering

OUT = rendering.gallery_output(REPO / "hermes" / "app" / "web" / "generated" / "notation_lesson_charts")

# The top-level honesty note, stated once on the top index and once per lesson.
HOST_NOTE = (
    "An IM lesson hosts one notation chart through its encoded addition, "
    "subtraction, or multiplication operation. The chart includes only "
    "deformations admitted by cited evidence and renders them over a "
    "representative equation; it does not count instances in the lesson."
)
GRADE_RE = re.compile(r"^IM-G(K|[1-8])-U\d+-L\d+$")
GRADE_ORDER = ["K", "1", "2", "3", "4", "5", "6", "7", "8"]


# --- Enumerate and build every hosted chart in one swipl process -------------
#
# A lesson hosts a chart when it carries one of the three hosted operations and
# the grammar admits at least one notation deformation for its representative
# equation. The Prolog decides both; this just collects.

def lesson_charts(limit: int = 0) -> dict:
    goal = (
        "use_module(lessons('im/lesson_notation_chart')), "
        "use_module(lessons('im/lesson_monitoring')), "
        "use_module(library(http/json)), "
        # hosting lessons with >=1 admitted notation deformation
        "findall(C, "
        "  ( lesson_notation_chart:notation_chart_lesson(C, _, _, _), "
        "    once(lesson_notation_chart:lesson_likely_notation_deformation("
        "         C, notation, _, _)) ), Hosted0), "
        "sort(Hosted0, HostedAll), "
        # all lessons carrying one of the hosted operations (the pool)
        "findall(P, "
        "  ( lesson_monitoring:im_lesson(P, _, _, _, _, _), "
        "    lesson_monitoring:specific_attachment_operation(P, Op), "
        "    member(Op, [addition, subtraction, multiplication]) ), Pool0), "
        "sort(Pool0, Pool), "
        # the pool lessons that are NOT hosted (no admitted notation deformation)
        "findall(S, (member(S, Pool), \\+ member(S, HostedAll)), Skipped), "
        f"Limit = {limit}, length(HostedAll, Total), "
        "( Limit > 0, Limit < Total "
        "  -> length(Hosted, Limit), append(Hosted, _, HostedAll) "
        "  ; Hosted = HostedAll ), "
        "findall(Chart, "
        "  ( member(Code, Hosted), "
        "    lesson_notation_chart:notation_monitoring_chart(Code, Chart) ), Charts), "
        "Doc = _{ hosted: Hosted, hosted_all: HostedAll, pool: Pool, "
        "         skipped: Skipped, charts: Charts }, "
        "json_write_dict(user_output, Doc, [width(0)]), nl, halt."
    )
    res = subprocess.run(
        ["swipl", "-q", "-l", "paths.pl", "-g", goal, "-t", "halt(1)"],
        cwd=REPO, capture_output=True, text=True,
    )
    lines = [l for l in res.stdout.splitlines() if l.startswith("{")]
    if not lines:
        sys.stderr.write(res.stdout + "\n" + res.stderr)
        raise SystemExit("swipl produced no batched lesson charts")
    return json.loads(lines[0])


# --- shared drawer adapter ---------------------------------------------------

def render(frames, out_file, labels, *, title="", captions=None,
           panel_w=270, panel_h=220, canvas=None):
    rendering.render_svg(
        {"frames": frames, "canvas": canvas or {}}, "filmstrip", out_file,
        labels=labels, title=title, captions=captions or [],
        panelWidth=panel_w, panelHeight=panel_h,
        captionEllipsis=True,
        ariaLabel=title or "notation monitoring chart",
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
        .replace("+", "plus")
        .replace("=", "eq")
        .replace("(", "-")
        .replace(")", "")
        .replace(" ", "")
    )


# --- render one lesson's notation chart --------------------------------------

def export_lesson(chart: dict) -> dict:
    code = chart["lesson_code"]
    lesson_dir = OUT / code
    lesson_dir.mkdir(parents=True, exist_ok=True)

    (lesson_dir / "chart.json").write_text(
        json.dumps(chart, indent=2), encoding="utf-8"
    )

    equation = chart["representative_equation"]
    eq_slug = _slug(equation)

    written = []
    cell_records = []
    for cell in chart["cells"]:
        host = cell["host"]
        eq = cell["equation"]
        cell_eq_slug = _slug(eq)

        # productive scene (the correct inscription)
        prod = cell["productive"]
        prod_frames = prod["frames"]
        prod_file = lesson_dir / f"{host}-{cell_eq_slug}-PRODUCTIVE.svg"
        render(
            prod_frames, prod_file,
            [_verb_label(f) for f in prod_frames],
            title=f"{host}: correct inscription {eq}",
            panel_w=300, panel_h=180,
        )
        written.append(prod_file)

        # deformation scenes (labeled notation misconceptions only)
        deform_records = []
        for d in cell["deformations"]:
            name = d["deformation"]
            provenance = d["provenance"]
            scene = d["scene"]
            frames = scene["frames"]
            d_slug = _slug(name)
            d_file = lesson_dir / f"{host}-{cell_eq_slug}-{d_slug}.svg"
            render(
                frames, d_file,
                [_verb_label(f) for f in frames],
                title=f"WATCH FOR: {name} on {eq} ({provenance})",
                panel_w=320, panel_h=180,
            )
            written.append(d_file)
            deform_records.append({
                "deformation": name,
                "family": d.get("family", "notation_error"),
                "provenance": provenance,
                "host_note": d.get("host_note", ""),
                "file": d_file.name,
                "frame_count": len(frames),
            })

        cell_records.append({
            "host": host,
            "equation": eq,
            "operands": cell.get("operands", {}),
            "productive_file": prod_file.name,
            "deformations": deform_records,
        })

    index = build_lesson_index(chart, cell_records)
    (lesson_dir / "index.html").write_text(index, encoding="utf-8")
    written.append(lesson_dir / "index.html")

    return {
        "code": code,
        "title": chart["title"],
        "standards": chart.get("standards", []),
        "hosts": chart.get("hosts", []),
        "operation": chart["operation"],
        "representative_equation": equation,
        "cell_count": len(cell_records),
        "cells": cell_records,
        "files": [str(w) for w in written],
        "dir": str(lesson_dir),
    }


# --- the per-lesson index page (honesty cards) -------------------------------

def build_lesson_index(chart: dict, cells: list) -> str:
    code = chart["lesson_code"]
    title = chart["title"]
    standards = ", ".join(chart.get("standards", [])) or "(none encoded)"
    equation = chart["representative_equation"]
    chart_host_note = chart.get("host_note", HOST_NOTE)
    rows = []
    rows.append("<!doctype html><meta charset=utf-8>")
    rows.append(f"<title>{html.escape(code)} - notation deformations to watch for</title>")
    rows.append("<body style='font-family:system-ui;background:#f8f1df;color:#1b1810;"
                "max-width:1180px;margin:0 auto;padding:28px'>")
    rows.append(f"<h1 style=\"font-family:Georgia,'Times New Roman',serif\">"
                f"{html.escape(code)}: notation monitoring chart</h1>")
    rows.append(f"<p><strong>Standards:</strong> {html.escape(standards)} &nbsp; "
                f"<strong>Representative equation:</strong> "
                f"<code>{html.escape(equation)}</code></p>")
    rows.append("<p style='max-width:860px;line-height:1.45'>This is the notation "
                "monitoring chart for the lesson: the <em>productive</em> written "
                "inscription a child should produce, beside the <em>likely "
                "written-work deformations</em> to watch for &mdash; a reversed "
                "numeral, an equals sign read as &ldquo;makes&rdquo;, a transposed "
                "answer &mdash; each drawn over the lesson's representative "
                "equation. Each deformation is a labeled misconception, gated "
                "through the representation grammar's misconception lane "
                "(<code>deformation_spec_evidence(notation, ...)</code> with "
                "<code>mode: misconception</code>) &mdash; never an unflagged "
                "inscription. The diff between the correct inscription and a "
                "deformation is one field (one flipped glyph, or one appended "
                "mark). Logic in "
                "<code>lessons/im/lesson_notation_chart.pl</code>; render "
                "projected through <code>more-zeeman/render/drawer.js</code> (the "
                "<code>notation</code> format).</p>")
    # The load-bearing honesty card, on every lesson page.
    rows.append("<div style='max-width:860px;margin:18px 0;padding:14px 16px;"
                "border:1px solid #b95238;border-left-width:5px;background:#fdf0ec'>"
                "<strong style='color:#8b1e16'>Honesty card &mdash; this chart is "
                "a parametric render, not a corpus instance count.</strong>"
                f"<p style='margin:6px 0 0;line-height:1.4'>{html.escape(chart_host_note)}</p>"
                "</div>")

    for c in cells:
        rows.append(f"<h2>{html.escape(c['equation'])} on <em>{html.escape(c['host'])}</em></h2>")
        rows.append("<div style='display:flex;flex-wrap:wrap;gap:14px;align-items:flex-start'>")
        rows.append("<figure style='margin:0'>"
                    "<figcaption style='font-size:13px;font-weight:700;color:#365f6b'>"
                    "Productive (the correct inscription)</figcaption>"
                    f"<img src='{html.escape(c['productive_file'], quote=True)}' "
                    "style='max-width:420px;border:1px solid #cabf9f;background:#f8f1df'></figure>")
        for d in c["deformations"]:
            prov = d["provenance"]
            prov_color = "#2f6f3a" if prov == "corpus_attested" else "#8a6d1a"
            rows.append("<figure style='margin:0;max-width:440px'>"
                        "<figcaption style='font-size:13px;font-weight:700;color:#8b1e16'>"
                        f"Watch for: {html.escape(d['deformation'])} "
                        f"<span style='color:{prov_color};font-weight:600'>"
                        f"[{html.escape(prov)}]</span></figcaption>"
                        f"<img src='{html.escape(d['file'], quote=True)}' "
                        "style='max-width:440px;border:1px solid #cabf9f;background:#f8f1df'>"
                        f"<figcaption style='font-size:11px;color:#5a513c;"
                        f"line-height:1.35;margin-top:4px'>{html.escape(d.get('host_note',''))}"
                        "</figcaption></figure>")
        rows.append("</div>")

    rows.append("</body>")
    return "\n".join(rows)


# --- the top-level index across all charted lessons --------------------------

def build_top_index(records: list, skipped: list) -> str:
    rows = []
    rows.append("<!doctype html><meta charset=utf-8>")
    rows.append("<title>Notation monitoring charts (Grades K-8)</title>")
    rows.append("<body style='font-family:system-ui;background:#f8f1df;color:#1b1810;"
                "max-width:1000px;margin:0 auto;padding:28px'>")
    rows.append("<h1 style=\"font-family:Georgia,'Times New Roman',serif\">"
                "Notation monitoring charts &mdash; Grades K&ndash;8</h1>")
    rows.append("<p style='max-width:840px;line-height:1.45'>Each Illustrative "
                "Mathematics lesson with an encoded addition, subtraction, or "
                "multiplication attachment hosts one chart. When a lesson has "
                "several such operations, addition precedes subtraction, which "
                "precedes multiplication. The deformations are admitted by cited "
                "evidence through the representation grammar's misconception "
                "lane and rendered over a representative equation. The companion fraction chart "
                "(<code>lesson_deformation_chart.pl</code>) is a separate "
                "pipeline and is untouched.</p>")
    # The top-level honesty card.
    rows.append("<div style='max-width:840px;margin:18px 0;padding:14px 16px;"
                "border:1px solid #b95238;border-left-width:5px;background:#fdf0ec'>"
                "<strong style='color:#8b1e16'>Honesty card.</strong>"
                f"<p style='margin:6px 0 0;line-height:1.4'>{html.escape(HOST_NOTE)} "
                "Provenance travels with every deformation: "
                "<code>corpus_attested</code> means the violation reason or "
                "inscription form is attested somewhere in this corpus; "
                "<code>literature_only</code> means the rendered instance is a "
                "literature-grounded named misconception rendered parametrically, "
                "with no instance counted in this corpus.</p></div>")

    # group records by the grade atom in the lesson code
    grade_records = {grade: [] for grade in GRADE_ORDER}
    for record in records:
        match = GRADE_RE.fullmatch(record["code"])
        if not match:
            raise ValueError(f"invalid lesson code: {record['code']}")
        grade_records[match.group(1)].append(record)
    count_text = ", ".join(
        f"{len(grade_records[g])} G{g}" for g in GRADE_ORDER
        if grade_records[g]
    )
    rows.append(f"<p><strong>{len(records)} lessons charted</strong> "
                f"({html.escape(count_text)}).</p>")

    for grade in GRADE_ORDER:
        band_records = grade_records[grade]
        if not band_records:
            continue
        band = "Kindergarten" if grade == "K" else f"Grade {grade}"
        rows.append(f"<h2>{band} ({len(band_records)} lessons)</h2>")
        rows.append("<ul style='columns:2;-webkit-columns:2;line-height:1.5'>")
        for r in band_records:
            defs = sorted({
                f"{d['deformation']} [{d['provenance']}]"
                for c in r["cells"] for d in c["deformations"]
            })
            rows.append(
                f"<li><a href='{html.escape(r['code'])}/index.html'>"
                f"{html.escape(r['code'])}</a> "
                f"&mdash; <code>{html.escape(r['representative_equation'])}</code>; "
                f"{html.escape('; '.join(defs))}</li>"
            )
        rows.append("</ul>")

    if skipped:
        rows.append("<h2>Lessons with no notation chart</h2>")
        rows.append("<p style='max-width:840px;line-height:1.45'>These lessons "
                    "in the hosted-operation pool produced no admitted "
                    "notation deformation for their representative equation, so no "
                    "chart was rendered.</p>")
        rows.append("<ul>")
        for s in skipped:
            rows.append(f"<li><code>{html.escape(s)}</code></li>")
        rows.append("</ul>")

    rows.append("</body>")
    return "\n".join(rows)


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--limit", type=int, default=0,
                   help="render at most N lessons (0 = all); for quick checks")
    return p.parse_args()


def main() -> int:
    args = parse_args()
    OUT.mkdir(parents=True, exist_ok=True)

    enum = lesson_charts(args.limit)
    hosted = enum["hosted"]
    skipped = enum["skipped"]
    charts = enum["charts"]
    operation_counts = {
        operation: sum(c["operation"] == operation for c in charts)
        for operation in ("addition", "subtraction", "multiplication")
    }
    grade_counts = {
        grade: sum(c["lesson_code"].startswith(f"IM-G{grade}-") for c in charts)
        for grade in GRADE_ORDER
    }
    print(f"Enumerated {len(hosted)} hosting lessons in one swipl process "
          f"({operation_counts['addition']} addition, "
          f"{operation_counts['subtraction']} subtraction, "
          f"{operation_counts['multiplication']} multiplication); "
          f"{len(skipped)} hosted-operation lessons skipped (no admitted "
          f"notation deformation).", flush=True)

    records = []
    for i, chart in enumerate(charts, 1):
        code = chart["lesson_code"]
        rec = export_lesson(chart)
        records.append(rec)
        if i % 20 == 0 or i == len(hosted):
            print(f"  [{i}/{len(hosted)}] {code}: {rec['cell_count']} cell(s)",
                  flush=True)

    (OUT / "index.html").write_text(
        build_top_index(records, skipped), encoding="utf-8")

    manifest = {
        "kind": "notation_lesson_charts",
        "host_note": HOST_NOTE,
        "lesson_count": len(records),
        "grade_counts": grade_counts,
        "operation_counts": operation_counts,
        "skipped": skipped,
        "lessons": [
            {
                "code": r["code"],
                "operation": r["operation"],
                "standards": r["standards"],
                "representative_equation": r["representative_equation"],
                "cell_count": r["cell_count"],
                "deformations": sorted({
                    f"{d['deformation']}|{d['provenance']}"
                    for c in r["cells"] for d in c["deformations"]
                }),
            }
            for r in records
        ],
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2),
                                       encoding="utf-8")

    svg_count = sum(
        Path(path).suffix == ".svg" for record in records for path in record["files"]
    )
    print(f"Wrote {svg_count} SVGs across {len(records)} lessons to {OUT}")
    for grade in GRADE_ORDER:
        print(f"  Grade {grade} lessons charted: {grade_counts[grade]}")
    for operation, count in operation_counts.items():
        print(f"  {operation.capitalize()} lessons charted: {count}")
    print(f"  Skipped (no notation deformation): {len(skipped)}")
    print(OUT / "index.html")
    print(OUT / "manifest.json")
    return 0


if __name__ == "__main__":
    if "--check" in sys.argv:
        raise SystemExit(rendering.check_exporter(Path(__file__), OUT))
    raise SystemExit(main())
