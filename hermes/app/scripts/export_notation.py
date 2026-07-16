#!/usr/bin/env python3
"""Export the notation (glyph-level) demos as SVG filmstrips.

Notation is the eighth representation language: a written equation as a row of
single inscribed characters, each at its own (x, y), each carrying an optional
per-glyph deformation transform (spec §3-§4,
docs/proposals/2026-06-25-notation-in-monitoring-charts.md). The Prolog layer
strategies/render/notation_scene.pl and
strategies/render/parametric_notation_deformation.pl decide WHAT each scene is
(which glyph reverses, which equals sign carries a chain tick, the literal glyph
row) and emit drawer-compatible frame documents. This script is the projection
step: it runs swipl through paths.pl to get the documents, then pipes each frame
through the frozen render contract in more-zeeman/render/drawer.js (the
'notation' format) via the same embedded node harness the parametric-partition
demo uses, writing per-frame SVGs and a small index.

It renders exactly the three bounded demos of spec §8:

  1. Productive baseline 2+3=5 on the real lesson IM-GK-U1-L12 (no marks, no
     flips) — proves the productive lane and glyph layout.
  2. operational_equals_chain 2+3=5+4=9 — one glyph row with chain-equals ticks.
  3. mirror_written_numeral hosted on IM-GK-U1-L12 — a reversed 3 in a small sum,
     the reversed digit chosen in Prolog, not in JS.

Each demo carries an honesty card stating where it is corpus-attested and where
it is literature-only (spec §2, §8). Output lands under
hermes/app/web/generated/notation_demos/.
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
DEFAULT_OUT = (
    REPO_ROOT / "hermes" / "app" / "web" / "generated" / "notation_demos"
)

# The real K lesson the demos host on. IM-GK-U1-L12 ("count all when count on
# available", addition) is verified at lessons/im/grade_k.pl:18. The IM K/G1
# corpus has no number-writing lesson, so the notation deformations attach to a
# counting/addition lesson as host (spec §1, §8).
HOST_LESSON = "IM-GK-U1-L12"


# --- The three demos, each (code, swipl goal, honesty card) ------------------
#
# Each goal binds D to a drawer-ready document dict and prints it as JSON.
# The honesty card is the literal label that travels onto the demo card in the
# index, stating corpus-attested vs literature-only per spec §2/§8.

DEMOS = [
    {
        "code": "NOTATION-productive-2plus3-IM-GK-U1-L12",
        "title": "Productive baseline 2+3=5 (IM-GK-U1-L12)",
        "goal": (
            "use_module(render(parametric_notation_deformation)),"
            "productive_notation_scene(write_equation(2,'+',3,5), D)"
        ),
        "card": (
            "Productive inscription on the real lesson IM-GK-U1-L12 "
            "(grade_k.pl:18). No marks, no flips: a child correctly writes "
            "2 + 3 = 5. Notation is a real productive language; only its "
            "deformations live in the misconception lane."
        ),
    },
    {
        "code": "NOTATION-operational-equals-chain-2plus3plus4",
        "title": "operational_equals_chain 2+3=5+4=9",
        "goal": (
            "use_module(render(notation_scene)),"
            "notation_render_json("
            "operational_equals_chain_full([2-(+)-3, 5-(+)-4], 9), D)"
        ),
        "card": (
            "Equals read as makes: the child chains the running total, writing "
            "2+3=5+4=9 with a chain-equals tick under each = whose two sides "
            "denote unequal quantities. Violation family corpus-attested (513 "
            "multi-= docling transcriptions); K/G1 instance literature-only."
        ),
    },
    {
        "code": "NOTATION-mirror-written-numeral-IM-GK-U1-L12",
        "title": "mirror_written_numeral (hosted on IM-GK-U1-L12)",
        "goal": (
            "use_module(render(parametric_notation_deformation)),"
            "deformed_notation_scene(write_equation(2,'+',3,5),"
            " notation_error(mirror_written_numeral), D)"
        ),
        "card": (
            "A reversed digit in a small sum; the reversed digit is chosen in "
            "Prolog from the lesson's number range, not in JS. Literature-only; "
            "no number-writing lesson exists in the IM K/G1 corpus, so it is "
            "hosted on an addition lesson; parametric over reversal-prone "
            "digits, not a corpus instance count."
        ),
    },
]


# --- swipl bridge: get a drawer-ready document for one demo goal --------------

SWIPL_TEMPLATE = (
    "use_module(library(http/json)),"
    "{goal},"
    "current_output(S),"
    "json_write_dict(S, D, [width(0)]),"
    "halt."
)


def swipl_doc(goal: str) -> dict:
    full_goal = SWIPL_TEMPLATE.format(goal=goal)
    proc = subprocess.run(
        ["swipl", "-q", "-l", "paths.pl", "-g", full_goal],
        cwd=REPO_ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if proc.returncode != 0:
        raise RuntimeError(f"swipl failed for goal:\n{goal}\n{proc.stderr}")
    out = proc.stdout.strip()
    # The goal may have written warnings before the JSON; take from the first {.
    brace = out.find("{")
    if brace < 0:
        raise RuntimeError(f"no JSON in swipl output:\n{out}\n{proc.stderr}")
    return json.loads(out[brace:])


# --- node harness: the SAME drawer.js render path the partition demo uses -----
#
# Copied verbatim from export_parametric_partition.py: a fake DOM whose Element
# supports arbitrary setAttribute/appendChild and nested outerHTML, so a
# <g transform=...> (the mirror flip) round-trips unchanged in static export.
# colorVars supplies --fig-deformation (#b95238) for red error ink.

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


# --- index.html (honesty cards, the fraction_cliff_demos pattern) ------------


def write_index(out_dir: Path, rendered: list[dict]) -> Path:
    parts = [
        "<!doctype html><meta charset=utf-8>"
        "<title>Notation in monitoring charts</title>",
        "<body style='font-family:system-ui;background:#f8f1df;padding:24px;"
        "max-width:900px'>",
        "<h1>Notation: the symbol-level companion to spatial representations</h1>",
        "<p>Glyph-level filmstrips from "
        "<code>strategies/render/notation_scene.pl</code> and "
        "<code>strategies/render/parametric_notation_deformation.pl</code> via "
        "<code>more-zeeman/render/drawer.js</code> (the <code>notation</code> "
        "format). Notation denotes the symbol string a child wrote, not the "
        "quantity it was meant to mean. Each deformation is born only as a "
        "labeled misconception (one flagged glyph or one appended mark). The "
        "diff between a correct inscription and its deformation is one field.</p>",
        f"<p>Demos 1 and 3 host on the real lesson <code>{HOST_LESSON}</code> "
        "(<code>grade_k.pl:18</code>). The IM K/Grade-1 corpus carries no "
        "number-writing lesson, so a numeral-reversal deformation attaches to a "
        "counting/addition lesson as host. The honesty card under each demo "
        "states where it is corpus-attested and where it is literature-only.</p>",
    ]
    for item in rendered:
        frames_html = "".join(
            f"<img src='{Path(f).name}' "
            "style='max-width:100%;background:#f8f1df;border:1px solid #cabf9f;"
            "margin:2px 0'>"
            for f in item["frames"]
        )
        parts.append(
            f"<section style='margin:28px 0;padding:16px;"
            "border:1px solid #cabf9f;background:#fdfaf0'>"
            f"<h2 style='margin-top:0'>{item['title']}</h2>"
            f"<p style='color:#5a513c;font-size:0.95em'><strong>Honesty card:"
            f"</strong> {item['card']}</p>"
            f"<p><small><code>{item['code']}</code></small></p>"
            f"{frames_html}"
            "</section>"
        )
    index = out_dir / "index.html"
    index.write_text("\n".join(parts) + "\n", encoding="utf-8")
    return index


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--out", type=Path, default=DEFAULT_OUT)
    return p.parse_args()


def main() -> int:
    args = parse_args()
    out_dir = args.out.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    written: list[Path] = []
    rendered: list[dict] = []
    manifest: dict = {"host_lesson": HOST_LESSON, "demos": []}

    for demo in DEMOS:
        code = demo["code"]
        doc = swipl_doc(demo["goal"])
        frame_files = export_frames(out_dir, code, doc)
        written.extend(frame_files)
        rendered.append(
            {
                "code": code,
                "title": demo["title"],
                "card": demo["card"],
                "frames": [str(p) for p in frame_files],
            }
        )
        manifest["demos"].append(
            {
                "code": code,
                "title": demo["title"],
                "card": demo["card"],
                "frame_count": len(doc.get("frames", [])),
                "frames": [p.name for p in frame_files],
            }
        )

    index = write_index(out_dir, rendered)
    written.append(index)
    (out_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2), encoding="utf-8"
    )

    print(f"Wrote {len(written)} files to {out_dir}")
    for path in written:
        print(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
