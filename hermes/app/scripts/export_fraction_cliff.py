#!/usr/bin/env python3
"""Render the fraction unit-coordination machine's splitting cliff as filmstrips.

The wire: tools/carving/fraction_unit_machine.pl (the search) -> verdicts +
witness traces (swipl) -> fraction-bars frames (here) -> more-zeeman/render/
drawer.js (buildSvg) -> SVG filmstrips. Bounded on purpose: three demos.

  - 3/5  (proper)    : reachable intact at every stage, no crisis.
  - 7/5  at mc2      : reachable ONLY by collapsing the referent-whole chain
                       (the documented improper-fraction chain-loss deformation).
  - 7/5  at mc3      : reachable INTACT by freeing the unit fraction and
                       iterating beyond the whole (the reorganization).

Run: python3 hermes/app/scripts/export_fraction_cliff.py
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
MACHINE = "tools/carving/fraction_unit_machine.pl"
OUT = REPO / "hermes" / "app" / "web" / "generated" / "fraction_cliff_demos"

W, H = 300, 70          # whole-bar geometry
X0, Y0 = 30, 40


def verdict(stage: str, tc: int, tb: int) -> dict:
    """Ask the machine: intact cost/witness and collapsed cost at this stage."""
    goal = (
        f"consult('{MACHINE}'), M=fraction_unit_machine, "
        f"( M:uc_min_cost({stage}, frac({tc},{tb}), 12, 24, IC, IW) "
        f"  -> true ; IC = -1, IW = [] ), "
        f"( M:uc_min_cost_collapsed({stage}, frac({tc},{tb}), 12, 24, CC, _) "
        f"  -> true ; CC = -1 ), "
        f"format('~q~n', [v(IC, IW, CC)]), halt."
    )
    res = subprocess.run(["swipl", "-q", "-g", goal, "-t", "halt(1)"],
                         cwd=REPO, capture_output=True, text=True)
    line = [l for l in res.stdout.splitlines() if l.startswith("v(")]
    return {"raw": line[0] if line else "v(-1,[],-1)"}


def bar(x, y, parts, filled, label):
    cell = W / parts if parts else W
    splits = [{"x": i * cell, "y": 0, "w": cell, "h": H} for i in range(filled)]
    return {"x": x, "y": y, "w": W, "h": H, "label": label, "splits": splits}


def frame(step, caption, bars):
    return {"step": step, "caption": caption, "sceneChanged": True,
            "scene": {"format": "fraction-bars", "version": 1, "bars": bars}}


def frames_proper(tc, tb):
    return [
        frame(1, f"Partition the whole into {tb} equal parts.",
              [bar(X0, Y0, tb, 0, f"1 whole / {tb}")]),
        frame(2, f"Iterate the unit fraction {tc} times, within the whole.",
              [bar(X0, Y0, tb, tc, f"{tc}/{tb}")]),
        frame(3, "Chain intact: the referent whole is preserved.",
              [bar(X0, Y0, tb, tc, f"{tc}/{tb} ✓")]),
    ]


def frames_intact_beyond(tc, tb):
    return [
        frame(1, f"Partition the whole into {tb}; iterate to {tb}/{tb} = 1 whole.",
              [bar(X0, Y0, tb, tb, f"{tb}/{tb} = 1")]),
        frame(2, "Free the unit fraction so it can iterate past the whole.",
              [bar(X0, Y0, tb, tb, f"{tb}/{tb}"),
               bar(X0 + W + 40, Y0, tb, 0, "freed 1/%d" % tb)]),
        frame(3, f"Iterate {tc - tb} more {1}/{tb}-units beyond: {tc}/{tb}, chain intact.",
              [bar(X0, Y0, tb, tb, f"{tb}/{tb}"),
               bar(X0 + W + 40, Y0, tb, tc - tb, f"+{tc - tb}/{tb} → {tc}/{tb} ✓")]),
    ]


def frames_collapsed(tc, tb):
    return [
        frame(1, f"Partition the whole into {tb}; reach {tb}/{tb} = 1 whole.",
              [bar(X0, Y0, tb, tb, f"{tb}/{tb} = 1")]),
        frame(2, f"To say {tc}-something, re-partition the SAME whole into {tc}.",
              [bar(X0, Y0, tc, tc, f"{tc} parts?")]),
        frame(3, f"Whole now read as {tc}/{tc}: the original 1/{tb} chain is lost.",
              [bar(X0, Y0, tc, tc, f"{tc}/{tc} ✗ chain lost")]),
    ]


NODE_HARNESS = r"""
const fs = require('fs'); const vm = require('vm'); const path = require('path');
const input = JSON.parse(fs.readFileSync(0, 'utf8'));
const repoRoot = input.repoRoot, doc = input.doc, outFile = input.outFile, labels = input.labels;
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
const panelW=300,panelH=170,gap=18,pad=22;
const rootW=pad*2+frames.length*panelW+Math.max(0,frames.length-1)*gap, rootH=300;
let body=`<rect x="0" y="0" width="${rootW}" height="${rootH}" fill="#f8f1df"/>`;
for(let i=0;i<frames.length;i++){
  const x=pad+i*(panelW+gap);
  const svg=drawer.buildSvg(frames[i],bounds);
  const vb=String(svg.getAttribute('viewBox')||'0 0 1 1').split(/\s+/).map(Number);
  const scale=Math.min(panelW/vb[2],panelH/vb[3]);
  const tx=x+(panelW-vb[2]*scale)/2-vb[0]*scale, ty=64+(panelH-vb[3]*scale)/2-vb[1]*scale;
  const children=svg.children.map(c=>c.outerHTML||'').join('');
  body+=`<text x="${x+panelW/2}" y="24" text-anchor="middle" font-family="system-ui,sans-serif" font-size="15" font-weight="700" fill="#1b1810">${escapeXml(labels[i]||('Frame '+(i+1)))}</text>`;
  body+=`<text x="${x+panelW/2}" y="44" text-anchor="middle" font-family="system-ui,sans-serif" font-size="11" fill="#5a5446">${escapeXml((frames[i].caption||'').slice(0,60))}</text>`;
  body+=`<g transform="translate(${tx} ${ty}) scale(${scale})">${children}</g>`;
}
const out=`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${rootW} ${rootH}" role="img">${body}</svg>\n`;
fs.writeFileSync(outFile,out,'utf8'); process.stdout.write(outFile);
"""


def render(doc, out_file, labels):
    payload = {"repoRoot": str(REPO), "doc": doc, "outFile": str(out_file), "labels": labels}
    res = subprocess.run(["node", "-e", NODE_HARNESS], input=json.dumps(payload),
                         capture_output=True, text=True)
    if res.returncode != 0:
        sys.stderr.write(res.stderr)
        raise SystemExit(f"drawer failed for {out_file}")
    return out_file


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    cases = [
        ("DEMO-fraction-3-5-proper", frames_proper(3, 5),
         ["Partition", "Iterate 3/5", "Intact"], verdict("mc1", 3, 5)),
        ("DEMO-fraction-7-5-mc2-chain-loss", frames_collapsed(7, 5),
         ["1 whole", "Re-partition", "Chain lost (mc2)"], verdict("mc2", 7, 5)),
        ("DEMO-fraction-7-5-mc3-freed-intact", frames_intact_beyond(7, 5),
         ["5/5 = 1", "Free unit", "7/5 intact (mc3)"], verdict("mc3", 7, 5)),
    ]
    docs = {}
    for code, frames, labels, v in cases:
        doc = {"canvas": {"width": 760, "height": 150}, "frames": frames}
        out_file = OUT / f"{code}-filmstrip.svg"
        render(doc, out_file, labels)
        docs[code] = {"frames": frames, "machine_verdict": v["raw"]}
        print(out_file)
    (OUT / "docs.json").write_text(json.dumps(docs, indent=2))
    index = ["<!doctype html><meta charset=utf-8><title>Fraction splitting cliff</title>",
             "<body style='font-family:system-ui;background:#f8f1df;padding:24px'>",
             "<h1>The splitting cliff, computed</h1>",
             "<p>Filmstrips from <code>tools/carving/fraction_unit_machine.pl</code> "
             "via <code>drawer.js</code>. Each strip's verdict comes from the search.</p>"]
    for code, _f, _l, v in cases:
        index.append(f"<h2>{code}</h2><p><small>machine: {v['raw']}</small></p>"
                     f"<img src='{code}-filmstrip.svg' style='max-width:100%'>")
    (OUT / "index.html").write_text("\n".join(index))
    print(OUT / "index.html")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
