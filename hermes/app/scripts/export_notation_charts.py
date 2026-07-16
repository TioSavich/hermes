#!/usr/bin/env python3
"""Render lesson-specific NOTATION monitoring charts as SVG filmstrips.

This is the notation cousin of export_lesson_deformation_charts.py. It copies
that script's filmstrip render harness verbatim (title + per-frame panels via
the node drawer.js bridge) but consumes
lessons/im/lesson_notation_chart.pl:notation_monitoring_chart/2 instead of the
fraction monitoring_chart/2. The two pipelines never collide: the fraction
chart is keyed on frac(M,N) and backs the live grade-3 fraction charts; this
chart is keyed on equation(A,Op,B,R) and emits equation/operands fields.

The usefulness payoff: "for this real Kindergarten / Grade-1 IM addition
lesson, here is the correct written inscription a child should produce, beside
the written-work errors to watch for -- a reversed numeral, an equals sign read
as 'makes', a transposed answer -- each rendered over a representative equation
from the lesson's operation."

The honesty boundary the chart must carry, not hide:

  - The IM K/G1 corpus has NO number-writing lessons (the K/G1 lessons are
    counting/addition lessons, not lessons whose object is the written numeral).
    A notation deformation is therefore HOSTED on an addition lesson and
    rendered over a REPRESENTATIVE equation from that lesson's operation. The
    chart is a PARAMETRIC render over that equation, NOT a count of corpus
    instances of the deformation in the lesson. Every lesson index says so.
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
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
OUT = REPO / "hermes" / "app" / "web" / "generated" / "notation_lesson_charts"

# The top-level honesty note, stated once on the top index and once per lesson.
HOST_NOTE = (
    "The IM Kindergarten / Grade-1 corpus has no number-writing lessons: the "
    "K/G1 lessons are counting and addition lessons, not lessons whose object "
    "is the written numeral. A notation deformation is therefore hosted on an "
    "addition lesson and rendered over a representative equation drawn from "
    "that lesson's operation. The chart is a parametric render over that "
    "equation, not a count of corpus instances of the deformation in the "
    "lesson."
)


# --- Enumerate the K and Grade-1 lessons that host a notation chart ----------
#
# A lesson hosts a chart when it carries an addition (or counting that resolves
# to addition) strategy AND the grammar admits at least one notation deformation
# for its representative equation. The Prolog decides both; this just collects.

def enumerate_lessons() -> dict:
    goal = (
        "use_module(lessons('im/lesson_notation_chart')), "
        "use_module(lessons('im/lesson_monitoring')), "
        "use_module(library(http/json)), "
        # hosting lessons (addition) with >=1 admitted notation deformation
        "findall(C, "
        "  ( lesson_notation_chart:notation_chart_lesson(C, _, _, _), "
        "    once(lesson_notation_chart:lesson_likely_notation_deformation("
        "         C, notation, _, _)) ), Hosted0), "
        "sort(Hosted0, Hosted), "
        # all K/G1 lessons carrying an addition or counting strategy (the pool)
        "findall(P, "
        "  ( lesson_monitoring:explicit_lesson_strategy(P, Op, _, _), "
        "    member(Op, [addition, counting]), "
        "    ( sub_atom(P,0,_,_,'IM-GK') ; sub_atom(P,0,_,_,'IM-G1') ) ), Pool0), "
        "sort(Pool0, Pool), "
        # the pool lessons that are NOT hosted (no admitted notation deformation)
        "findall(S, (member(S, Pool), \\+ member(S, Hosted)), Skipped), "
        "Doc = _{ hosted: Hosted, pool: Pool, skipped: Skipped }, "
        "json_write_dict(user_output, Doc, [width(0)]), nl, halt."
    )
    res = subprocess.run(
        ["swipl", "-q", "-l", "paths.pl", "-g", goal, "-t", "halt(1)"],
        cwd=REPO, capture_output=True, text=True,
    )
    lines = [l for l in res.stdout.splitlines() if l.startswith("{")]
    if not lines:
        sys.stderr.write(res.stdout + "\n" + res.stderr)
        raise SystemExit("swipl produced no lesson enumeration")
    return json.loads(lines[0])


# --- Ask swipl for one lesson's notation monitoring chart --------------------

def lesson_chart(code: str) -> dict:
    goal = (
        "use_module(lessons('im/lesson_notation_chart')), "
        "use_module(library(http/json)), "
        f"( lesson_notation_chart:notation_monitoring_chart('{code}', Doc) "
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


# --- The node drawer.js harness, reused verbatim from export_lesson_
# deformation_charts.py (filmstrip layout: title + per-frame panels). The
# 'notation' format is already wired in drawer.js, which dispatches purely on
# scene.format, so this harness renders notation scenes unchanged. ------------

NODE_HARNESS = r"""
const fs = require('fs'); const vm = require('vm'); const path = require('path');
const input = JSON.parse(fs.readFileSync(0, 'utf8'));
const repoRoot = input.repoRoot, frames = input.frames, outFile = input.outFile;
const labels = input.labels, captions = input.captions, title = input.title || '';
const panelW = input.panelW || 300, panelH = input.panelH || 220;
function escapeXml(s){return String(s).replace(/[<>&"]/g,c=>({'<':'&lt;','>':'&gt;','&':'&amp;','"':'&quot;'}[c]));}
class Element{constructor(n){this.name=n;this.attrs={};this.children=[];this._text='';}
  setAttribute(k,v){this.attrs[k]=v;} getAttribute(k){return this.attrs[k];}
  appendChild(c){this.children.push(c);return c;} set textContent(t){this._text=t;}
  get outerHTML(){const a=Object.entries(this.attrs).map(([k,v])=>` ${k}="${escapeXml(v)}"`).join('');
    const b=escapeXml(this._text)+this.children.map(c=>c.outerHTML||escapeXml(String(c))).join('');
    return `<${this.name}${a}>${b}</${this.name}>`;}}
const document={documentElement:{},createElementNS:(_n,n)=>new Element(n),createElement:n=>new Element(n),
  getElementById:()=>null,querySelectorAll:()=>[],addEventListener(){}};
const colorVars={'--fig-unit':'#3f7f89','--fig-iterated':'#d4a747','--fig-highlight':'#d4a747',
  '--fig-deformation':'#b95238','--fig-assembled':'#5d9c6d','--fig-comparison':'#7a6fb0',
  '--fig-neutral':'#cabf9f','--fig-whole':'#cabf9f','--fig-stroke':'#0d0c08','--paper-bg':'#f8f1df','--fig-label':'#1b1810'};
const window={}; const context={window,document,console,getComputedStyle:()=>({getPropertyValue:n=>colorVars[n]||''}),setTimeout,clearTimeout};
context.global=context; window.document=document; window.getComputedStyle=context.getComputedStyle;
vm.createContext(context);
vm.runInContext(fs.readFileSync(path.join(repoRoot,'more-zeeman/render/drawer.js'),'utf8'),context,{filename:'drawer.js'});
const drawer=context.window.HermesDrawer._internal;
const bounds=drawer.documentBounds(frames,input.canvas||{});
const gap=18,pad=22,headH=title?42:0;
const rootW=pad*2+frames.length*panelW+Math.max(0,frames.length-1)*gap, rootH=headH+panelH+88;
let body=`<rect x="0" y="0" width="${rootW}" height="${rootH}" fill="#f8f1df"/>`;
if(title){body+=`<text x="${rootW/2}" y="28" text-anchor="middle" font-family="Georgia, 'Times New Roman', serif" font-size="20" font-weight="700" fill="#1b1810">${escapeXml(title)}</text>`;}
for(let i=0;i<frames.length;i++){
  const x=pad+i*(panelW+gap);
  const svg=drawer.buildSvg(frames[i],bounds);
  const vb=String(svg.getAttribute('viewBox')||'0 0 1 1').split(/\s+/).map(Number);
  const scale=Math.min(panelW/vb[2],(panelH-8)/vb[3]);
  const tx=x+(panelW-vb[2]*scale)/2-vb[0]*scale, ty=headH+62+(panelH-vb[3]*scale)/2-vb[1]*scale;
  const children=svg.children.map(c=>c.outerHTML||'').join('');
  body+=`<text x="${x+panelW/2}" y="${headH+22}" text-anchor="middle" font-family="system-ui,sans-serif" font-size="15" font-weight="700" fill="#1b1810">${escapeXml(labels[i]||('Frame '+(i+1)))}</text>`;
  const capRaw=(captions&&captions[i]||frames[i].caption||'');
  const maxChars=Math.max(24,Math.floor(panelW/6.2));
  const cap=capRaw.length>maxChars?capRaw.slice(0,maxChars-1)+'…':capRaw;
  body+=`<text x="${x+panelW/2}" y="${headH+42}" text-anchor="middle" font-family="system-ui,sans-serif" font-size="11" fill="#5a5446">${escapeXml(cap)}</text>`;
  body+=`<g transform="translate(${tx} ${ty}) scale(${scale})">${children}</g>`;
}
const out=`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${rootW} ${rootH}" role="img" aria-label="${escapeXml(title||'lesson notation monitoring chart')}">${body}</svg>\n`;
fs.writeFileSync(outFile,out,'utf8'); process.stdout.write(outFile);
"""


def render(frames, out_file, labels, *, title="", captions=None,
           panel_w=270, panel_h=220, canvas=None):
    payload = {
        "repoRoot": str(REPO), "frames": frames, "outFile": str(out_file),
        "labels": labels, "title": title, "captions": captions,
        "panelW": panel_w, "panelH": panel_h, "canvas": canvas or {},
    }
    res = subprocess.run(["node", "-e", NODE_HARNESS], input=json.dumps(payload),
                         capture_output=True, text=True)
    if res.returncode != 0:
        sys.stderr.write(res.stderr)
        raise SystemExit(f"drawer failed for {out_file}")
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

def export_lesson(code: str) -> dict:
    chart = lesson_chart(code)
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
    rows.append("<title>Notation monitoring charts (Kindergarten + Grade 1)</title>")
    rows.append("<body style='font-family:system-ui;background:#f8f1df;color:#1b1810;"
                "max-width:1000px;margin:0 auto;padding:28px'>")
    rows.append("<h1 style=\"font-family:Georgia,'Times New Roman',serif\">"
                "Notation monitoring charts &mdash; Kindergarten and Grade 1</h1>")
    rows.append("<p style='max-width:840px;line-height:1.45'>For each real "
                "Kindergarten and Grade-1 Illustrative Mathematics addition "
                "lesson, the correct written inscription a child should produce "
                "beside the written-work deformations to watch for (reversed "
                "numeral, equals-as-makes chain, transposed answer), each "
                "rendered over a representative equation from the lesson's "
                "operation. The deformations are parametric over the equation's "
                "numbers and gated through the representation grammar's "
                "misconception lane. The companion fraction chart "
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
                "<code>literature_only</code> means the K/G1 instance is a "
                "literature-grounded named misconception rendered parametrically, "
                "with no instance counted in this corpus.</p></div>")

    # group records by grade band
    k_records = [r for r in records if r["code"].startswith("IM-GK")]
    g1_records = [r for r in records if r["code"].startswith("IM-G1")]
    rows.append(f"<p><strong>{len(records)} lessons charted</strong> "
                f"({len(k_records)} Kindergarten, {len(g1_records)} Grade 1).</p>")

    for band, band_records in (("Kindergarten", k_records), ("Grade 1", g1_records)):
        if not band_records:
            continue
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
        rows.append("<p style='max-width:840px;line-height:1.45'>These K/G1 "
                    "lessons in the addition/counting pool produced no admitted "
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

    enum = enumerate_lessons()
    hosted = enum["hosted"]
    skipped = enum["skipped"]
    if args.limit:
        hosted = hosted[: args.limit]

    k_codes = [c for c in hosted if c.startswith("IM-GK")]
    g1_codes = [c for c in hosted if c.startswith("IM-G1")]
    print(f"Enumerated {len(hosted)} hosting lessons "
          f"({len(k_codes)} K, {len(g1_codes)} G1); "
          f"{len(skipped)} addition/counting lessons skipped (no admitted "
          f"notation deformation).", flush=True)

    records = []
    for i, code in enumerate(hosted, 1):
        rec = export_lesson(code)
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
        "k_count": len(k_codes),
        "g1_count": len(g1_codes),
        "skipped": skipped,
        "lessons": [
            {
                "code": r["code"],
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

    total_files = sum(len(r["files"]) for r in records)
    print(f"Wrote {total_files} SVG/HTML files across {len(records)} lessons to {OUT}")
    print(f"  Kindergarten lessons charted: {len(k_codes)}")
    print(f"  Grade 1 lessons charted:      {len(g1_codes)}")
    print(f"  Skipped (no notation deformation): {len(skipped)}")
    print(OUT / "index.html")
    print(OUT / "manifest.json")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
