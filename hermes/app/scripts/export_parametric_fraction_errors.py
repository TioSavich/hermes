#!/usr/bin/env python3
"""Render the parametric equipartition-failure family as SVG filmstrips.

The wire: strategies/render/parametric_fraction_errors.pl (the logic) ->
B/M/E frames per (host, fraction, error type) (swipl) -> more-zeeman/render/
drawer.js (buildSvg) -> SVG filmstrips. The point: one deformation reproduces
across the fraction family. The script renders the SAME error type for several
fractions side by side so the replication is legible.

A monitoring-chart use: name a lesson's target fractions, get the predicted
botches for each, in one strip per error type.

Run: python3 hermes/app/scripts/export_parametric_fraction_errors.py
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
MODULE = "strategies/render/parametric_fraction_errors.pl"
OUT = REPO / "hermes" / "app" / "web" / "generated" / "parametric_fraction_errors"


def scene_doc(host: str, m: int, n: int, error_goal: str) -> dict:
    """Ask the Prolog module for the {frames:...} document, as JSON."""
    goal = (
        f"consult('paths.pl'), use_module(strategies/render/parametric_fraction_errors), "
        f"parametric_fraction_errors:deformed_fraction_error_scene("
        f"{host}, frac({m},{n}), {error_goal}, D), "
        f"use_module(library(http/json)), "
        f"json_write_dict(user_output, D, [width(0)]), nl, halt."
    )
    res = subprocess.run(
        ["swipl", "-q", "-g", goal, "-t", "halt(1)"],
        cwd=REPO, capture_output=True, text=True,
    )
    if res.returncode != 0:
        sys.stderr.write(res.stderr)
        raise SystemExit(f"prolog failed for {host} {m}/{n} {error_goal}")
    # take the last JSON line (consult may print warnings before it)
    line = res.stdout.strip().splitlines()[-1]
    return json.loads(line)


NODE_HARNESS = r"""
const fs = require('fs'); const vm = require('vm'); const path = require('path');
const input = JSON.parse(fs.readFileSync(0, 'utf8'));
const repoRoot = input.repoRoot, doc = input.doc, outFile = input.outFile, labels = input.labels, title = input.title;
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
const frames=doc.frames||[];
const bounds=drawer.documentBounds(frames,doc.canvas||{});
const panelW=360,panelH=190,gap=22,pad=24,titleH=36;
const rootW=pad*2+frames.length*panelW+Math.max(0,frames.length-1)*gap, rootH=titleH+300;
function wrapCaption(s,max){
  const words=String(s||'').split(/\s+/); const lines=[]; let cur='';
  for(const w of words){ if((cur+' '+w).trim().length>max){ if(cur) lines.push(cur); cur=w; } else { cur=(cur+' '+w).trim(); } }
  if(cur) lines.push(cur); return lines.slice(0,2);
}
let body=`<rect x="0" y="0" width="${rootW}" height="${rootH}" fill="#f8f1df"/>`;
body+=`<text x="${pad}" y="24" font-family="Georgia, Times New Roman, serif" font-size="18" font-weight="700" fill="#1b1810">${escapeXml(title)}</text>`;
for(let i=0;i<frames.length;i++){
  const x=pad+i*(panelW+gap);
  const svg=drawer.buildSvg(frames[i],bounds);
  const vb=String(svg.getAttribute('viewBox')||'0 0 1 1').split(/\s+/).map(Number);
  const scale=Math.min(panelW/vb[2],panelH/vb[3]);
  const tx=x+(panelW-vb[2]*scale)/2-vb[0]*scale, ty=titleH+74+(panelH-vb[3]*scale)/2-vb[1]*scale;
  const children=svg.children.map(c=>c.outerHTML||'').join('');
  body+=`<text x="${x+panelW/2}" y="${titleH+24}" text-anchor="middle" font-family="system-ui,sans-serif" font-size="14" font-weight="700" fill="#1b1810">${escapeXml(labels[i]||('Frame '+(i+1)))}</text>`;
  const capLines=wrapCaption(frames[i].caption||'',64);
  capLines.forEach((ln,k)=>{ body+=`<text x="${x+panelW/2}" y="${titleH+42+k*13}" text-anchor="middle" font-family="system-ui,sans-serif" font-size="10" fill="#5a5446">${escapeXml(ln)}</text>`; });
  body+=`<g transform="translate(${tx} ${ty}) scale(${scale})">${children}</g>`;
}
const out=`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${rootW} ${rootH}" role="img" aria-label="${escapeXml(title)}">${body}</svg>\n`;
fs.writeFileSync(outFile,out,'utf8'); process.stdout.write(outFile);
"""


def render(doc: dict, out_file: Path, labels: list[str], title: str) -> Path:
    payload = {
        "repoRoot": str(REPO), "doc": doc,
        "outFile": str(out_file), "labels": labels, "title": title,
    }
    res = subprocess.run(
        ["node", "-e", NODE_HARNESS], input=json.dumps(payload),
        capture_output=True, text=True,
    )
    if res.returncode != 0:
        sys.stderr.write(res.stderr)
        raise SystemExit(f"drawer failed for {out_file}")
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
    OUT.mkdir(parents=True, exist_ok=True)
    manifest: dict = {"cases": []}
    index_lines = [
        "<!doctype html><meta charset=utf-8>",
        "<title>Parametric equipartition-failure family</title>",
        "<body style='font-family:system-ui;background:#f8f1df;color:#1b1810;padding:24px;max-width:1100px;margin:auto'>",
        "<h1>Equipartition-failure family, parametric over the fraction</h1>",
        "<p>One documented student-work error is a <b>rule</b>, not a single figure. "
        "Each strip below is the same deformation generated for several fractions, "
        "differing only by the fraction parameter. Logic: "
        "<code>strategies/render/parametric_fraction_errors.pl</code>. Render: "
        "<code>more-zeeman/render/drawer.js</code>. A deformation is drawn only as a "
        "labeled misconception, never as an unlabeled productive diagram.</p>",
    ]

    for host in ("circle", "bar", "area"):
        index_lines.append(f"<h2>Host: {host}</h2>")
        for short, goal, title in ERROR_CASES:
            for (m, n) in FAMILY[host]:
                doc = scene_doc(host, m, n, goal)
                code = f"DEMO-eqfail-{host}-{short}-{m}-{n}"
                out_file = OUT / f"{code}-filmstrip.svg"
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

    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2))
    index_lines.append("</body>")
    (OUT / "index.html").write_text("\n".join(index_lines))
    print(OUT / "index.html")
    print(OUT / "manifest.json")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
