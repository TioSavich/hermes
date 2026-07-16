#!/usr/bin/env python3
"""Export the parametric partition-rule transplant deformations as SVG filmstrips.

The Prolog layer strategies/render/parametric_partition_deformation.pl decides
WHAT each deformation is (a foreign partition rule on an illicit host, parametric
over the fraction's denominator N) and emits drawer-compatible frame documents.
This script is the projection step: it runs swipl through paths.pl to get the
documents, then pipes each through the frozen render contract in
more-zeeman/render/drawer.js via an embedded node harness (the same harness the
hybridization demo uses), writing per-frame SVGs and a four-up filmstrip.

The replication panel renders the SAME deformation for several denominators so
the eye confirms what the skeleton-diff test asserts: only the cut count changes.

Output lands under hermes/app/web/generated/parametric_partition/.
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
DEFAULT_OUT = (
    REPO_ROOT / "hermes" / "app" / "web" / "generated" / "parametric_partition"
)

# The cases to render. Each is (host, transplant_rule, [denominators]).
# The headline case is vertical-strip-on-circle, the documented 1/4-on-circle
# error, replicated over 1/4, 1/5, 1/6, 1/8.
CASES = [
    ("circle", "vertical", [4, 5, 6, 8]),
    ("rectangle", "radial", [4, 6]),
    ("circle", "grid", [4, 6]),
    ("set", "radial", [3, 4]),
]
# The productive companion (the correct 1/N model in the host's own rule) for the
# headline host, so the chart can show licensed-vs-transplant side by side.
PRODUCTIVE = [("circle", [4, 6])]


def case_code(host: str, rule: str, n: int) -> str:
    return f"PARAM-transplant-{rule}-on-{host}-1over{n}"


def productive_code(host: str, n: int) -> str:
    return f"PARAM-productive-{host}-1over{n}"


# --- swipl bridge: get a drawer-ready document for one (host, rule, n) --------

SWIPL_DEFORMED = (
    "use_module(library(http/json)),"
    "use_module(render(parametric_partition_deformation)),"
    "deformed_partition_scene({host}, {n}, transplant({rule}), D),"
    "current_output(S),"
    "json_write_dict(S, D, [width(0)]),"
    "halt."
)
SWIPL_PRODUCTIVE = (
    "use_module(library(http/json)),"
    "use_module(render(parametric_partition_deformation)),"
    "productive_partition_scene({host}, {n}, D),"
    "current_output(S),"
    "json_write_dict(S, D, [width(0)]),"
    "halt."
)


def swipl_doc(goal: str) -> dict:
    proc = subprocess.run(
        ["swipl", "-q", "-l", "paths.pl", "-g", goal],
        cwd=REPO_ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if proc.returncode != 0:
        raise RuntimeError(f"swipl failed for goal:\n{goal}\n{proc.stderr}")
    out = proc.stdout.strip()
    # The goal may have written warnings before the JSON; take the last JSON line.
    brace = out.find("{")
    if brace < 0:
        raise RuntimeError(f"no JSON in swipl output:\n{out}\n{proc.stderr}")
    return json.loads(out[brace:])


def deformed_doc(host: str, rule: str, n: int) -> dict:
    return swipl_doc(SWIPL_DEFORMED.format(host=host, rule=rule, n=n))


def productive_doc(host: str, n: int) -> dict:
    return swipl_doc(SWIPL_PRODUCTIVE.format(host=host, n=n))


# --- node harness: the SAME drawer.js render path the hybridization demo uses -

NODE_HARNESS_HEAD = r"""
const fs = require('fs');
const vm = require('vm');
const path = require('path');

const input = JSON.parse(fs.readFileSync(0, 'utf8'));
const repoRoot = input.repoRoot;

function escapeXml(s) {
  return String(s)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;')
    .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}
class Element {
  constructor(name) {
    this.name = name; this.attrs = {}; this.children = []; this._text = '';
    this.style = {};
    this.classList = { add: (...names) => {
      const cur = new Set(String(this.attrs.class || '').split(/\s+/).filter(Boolean));
      for (const n of names) cur.add(n);
      if (cur.size) this.attrs.class = Array.from(cur).join(' ');
    }};
  }
  setAttribute(k, v) { this.attrs[k] = String(v); }
  getAttribute(k) { return this.attrs[k]; }
  appendChild(child) { this.children.push(child); return child; }
  addEventListener() {} querySelectorAll() { return []; }
  getScreenCTM() { return null; }
  createSVGPoint() { return { x: 0, y: 0, matrixTransform() { return this; } }; }
  set textContent(v) { this._text = String(v); }
  get textContent() { return this._text; }
  get outerHTML() {
    const attrs = Object.entries(this.attrs)
      .map(([k, v]) => ` ${k}="${escapeXml(v)}"`).join('');
    const body = escapeXml(this._text) +
      this.children.map(c => c.outerHTML || escapeXml(String(c))).join('');
    return `<${this.name}${attrs}>${body}</${this.name}>`;
  }
}
const document = {
  documentElement: {},
  createElementNS(_ns, name) { return new Element(name); },
  createElement(name) { return new Element(name); },
  getElementById() { return null; }, querySelectorAll() { return []; },
  addEventListener() {}
};
const colorVars = {
  '--fig-unit': '#3f7f89', '--fig-iterated': '#d4a747', '--fig-highlight': '#d4a747',
  '--fig-deformation': '#b95238', '--fig-assembled': '#5d9c6d',
  '--fig-comparison': '#7a6fb0', '--fig-neutral': '#cabf9f', '--fig-whole': '#cabf9f',
  '--fig-stroke': '#0d0c08', '--paper-bg': '#f8f1df', '--fig-label': '#1b1810'
};
const window = {};
const context = {
  window, document, console,
  getComputedStyle() { return { getPropertyValue: name => colorVars[name] || '' }; },
  setTimeout, clearTimeout
};
context.global = context;
window.document = document;
window.getComputedStyle = context.getComputedStyle;
vm.createContext(context);
vm.runInContext(
  fs.readFileSync(path.join(repoRoot, 'more-zeeman/render/drawer.js'), 'utf8'),
  context, { filename: 'drawer.js' });
const drawer = context.window.HermesDrawer._internal;
"""

# Per-frame exporter: writes one SVG per frame for one document.
NODE_FRAMES = NODE_HARNESS_HEAD + r"""
const doc = JSON.parse(fs.readFileSync(input.docPath, 'utf8'));
const outDir = input.outDir;
const code = input.code;
const frames = Array.isArray(doc.frames) ? doc.frames : [];
const bounds = drawer.documentBounds(frames, doc.canvas || {});
const written = [];
for (let i = 0; i < frames.length; i += 1) {
  const frame = frames[i] || {};
  const svg = drawer.buildSvg(frame, bounds);
  svg.setAttribute('xmlns', 'http://www.w3.org/2000/svg');
  svg.setAttribute('role', 'img');
  svg.setAttribute('aria-label', `${code} frame ${i + 1} ${frame.verb || ''}`.trim());
  const out = svg.outerHTML.replace(
    /font-family="Georgia, &quot;Times New Roman&quot;, serif"/g,
    'font-family="Georgia, Times New Roman, serif"');
  const outFile = path.join(outDir, `${code}-frame-${i + 1}.svg`);
  fs.writeFileSync(outFile, out + '\n', 'utf8');
  written.push(outFile);
}
process.stdout.write(JSON.stringify(written));
"""

# Replication-strip exporter: one panel per denominator, drawing the FINAL
# (hybrid-result) frame of each document, so the strip shows the same
# deformation at 1/4, 1/5, 1/6, 1/8 — only the cut count changes.
NODE_REPLICATION = NODE_HARNESS_HEAD + r"""
const docs = input.docs.map(d => ({ n: d.n, doc: JSON.parse(fs.readFileSync(d.docPath, 'utf8')) }));
const outFile = input.outFile;
const title = input.title;
const panelW = 230, panelH = 220, gap = 16, pad = 22, headH = 84;
const rootW = pad * 2 + docs.length * panelW + Math.max(0, docs.length - 1) * gap;
const rootH = headH + panelH + 56;
let body = `<rect x="0" y="0" width="${rootW}" height="${rootH}" fill="#f8f1df"/>`;
body += `<text x="${rootW / 2}" y="30" text-anchor="middle" font-family="system-ui, sans-serif" font-size="18" font-weight="700" fill="#1b1810">${escapeXml(title)}</text>`;
for (let i = 0; i < docs.length; i += 1) {
  const { n, doc } = docs[i];
  const frames = Array.isArray(doc.frames) ? doc.frames : [];
  const bounds = drawer.documentBounds(frames, doc.canvas || {});
  const last = frames[frames.length - 1];
  const svg = drawer.buildSvg(last, bounds);
  const vb = String(svg.getAttribute('viewBox') || '0 0 1 1').split(/\s+/).map(Number);
  const scale = Math.min(panelW / vb[2], panelH / vb[3]);
  const x = pad + i * (panelW + gap);
  const tx = x + (panelW - vb[2] * scale) / 2 - vb[0] * scale;
  const ty = headH + (panelH - vb[3] * scale) / 2 - vb[1] * scale;
  const children = svg.children.map(c => c.outerHTML || '').join('');
  body += `<text x="${x + panelW / 2}" y="${headH - 18}" text-anchor="middle" font-family="Georgia, serif" font-size="20" font-weight="700" fill="#1b1810">1/${n}</text>`;
  body += `<g transform="translate(${tx} ${ty}) scale(${scale})">${children}</g>`;
}
const out = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${rootW} ${rootH}" role="img" aria-label="${escapeXml(title)}">${body}</svg>\n`
  .replace(/font-family="Georgia, &quot;Times New Roman&quot;, serif"/g,
           'font-family="Georgia, Times New Roman, serif"');
fs.writeFileSync(outFile, out, 'utf8');
process.stdout.write(outFile);
"""


def run_node(script: str, payload: dict) -> str:
    proc = subprocess.run(
        ["node", "-e", script],
        input=json.dumps(payload),
        cwd=REPO_ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr)
    return proc.stdout


def export_frames(out_dir: Path, code: str, doc: dict) -> list[Path]:
    doc_path = out_dir / f"{code}-doc.json"
    doc_path.write_text(json.dumps(doc, indent=2), encoding="utf-8")
    out = run_node(
        NODE_FRAMES,
        {
            "repoRoot": str(REPO_ROOT),
            "docPath": str(doc_path),
            "outDir": str(out_dir),
            "code": code,
        },
    )
    return [Path(p) for p in json.loads(out or "[]")]


def export_replication_strip(
    out_dir: Path, host: str, rule: str, ns: list[int], docs: dict[int, dict]
) -> Path:
    out_file = out_dir / f"PARAM-replication-{rule}-on-{host}.svg"
    items = []
    for n in ns:
        doc_path = out_dir / f"{case_code(host, rule, n)}-doc.json"
        doc_path.write_text(json.dumps(docs[n], indent=2), encoding="utf-8")
        items.append({"n": n, "docPath": str(doc_path)})
    title = (
        f"Same {rule}-rule transplant on a {host}, parametric over the fraction "
        f"(only the cut count changes)"
    )
    run_node(
        NODE_REPLICATION,
        {
            "repoRoot": str(REPO_ROOT),
            "docs": items,
            "outFile": str(out_file),
            "title": title,
        },
    )
    return out_file


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--out", type=Path, default=DEFAULT_OUT)
    return p.parse_args()


def main() -> int:
    args = parse_args()
    out_dir = args.out.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    written: list[Path] = []
    manifest: dict = {"deformations": [], "productive": [], "replication_strips": []}

    for host, rule, ns in CASES:
        docs = {n: deformed_doc(host, rule, n) for n in ns}
        for n in ns:
            code = case_code(host, rule, n)
            frame_files = export_frames(out_dir, code, docs[n])
            written.extend(frame_files)
            manifest["deformations"].append(
                {
                    "host": host,
                    "rule": rule,
                    "n": n,
                    "code": code,
                    "frame_count": len(docs[n].get("frames", [])),
                    "foreign_primitive": docs[n].get("foreignPrimitive", ""),
                    "illicit_host": docs[n].get("illicitHost", ""),
                    "violation": docs[n].get("violation", ""),
                    "frames": [p.name for p in frame_files],
                }
            )
        strip = export_replication_strip(out_dir, host, rule, ns, docs)
        written.append(strip)
        manifest["replication_strips"].append(
            {"host": host, "rule": rule, "denominators": ns, "file": strip.name}
        )

    for host, ns in PRODUCTIVE:
        for n in ns:
            doc = productive_doc(host, n)
            code = productive_code(host, n)
            frame_files = export_frames(out_dir, code, doc)
            written.extend(frame_files)
            manifest["productive"].append(
                {
                    "host": host,
                    "n": n,
                    "code": code,
                    "frame_count": len(doc.get("frames", [])),
                    "frames": [p.name for p in frame_files],
                }
            )

    (out_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2), encoding="utf-8"
    )

    print(f"Wrote {len(written)} SVGs to {out_dir}")
    for path in written:
        print(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
