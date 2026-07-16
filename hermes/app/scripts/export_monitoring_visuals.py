#!/usr/bin/env python3
"""Export generated monitoring-chart visuals as static SVG files.

The Python side asks the existing Hermes worker/server generator for render
documents. The Node side uses the existing more-zeeman/render/drawer.js drawer
to serialize the final frame of each document as SVG.
"""
from __future__ import annotations

import argparse
import html
import json
import subprocess
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
DEFAULT_LESSONS = ["IM-G1-U3-L17", "IM-G2-U2-L7", "IM-G4-U4-L20"]
DEFAULT_OUT = REPO_ROOT / "hermes" / "app" / "web" / "generated" / "monitoring_visuals"

NODE_EXPORTER = r"""
const fs = require('fs');
const vm = require('vm');
const path = require('path');

const input = JSON.parse(fs.readFileSync(0, 'utf8'));
const repoRoot = input.repoRoot;
const outDir = input.outDir;
const docs = JSON.parse(fs.readFileSync(input.docsPath, 'utf8'));

function escapeXml(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

class Element {
  constructor(name) {
    this.name = name;
    this.attrs = {};
    this.children = [];
    this._text = '';
    this.style = {};
    this.classList = { add: (...names) => {
      const current = new Set(String(this.attrs.class || '').split(/\s+/).filter(Boolean));
      for (const name of names) current.add(name);
      if (current.size) this.attrs.class = Array.from(current).join(' ');
    }};
  }
  setAttribute(k, v) { this.attrs[k] = String(v); }
  getAttribute(k) { return this.attrs[k]; }
  appendChild(child) { this.children.push(child); return child; }
  addEventListener() {}
  querySelectorAll() { return []; }
  getScreenCTM() { return null; }
  createSVGPoint() { return { x: 0, y: 0, matrixTransform() { return this; } }; }
  set textContent(v) { this._text = String(v); }
  get textContent() { return this._text; }
  get outerHTML() {
    const attrs = Object.entries(this.attrs)
      .map(([k, v]) => ` ${k}="${escapeXml(v)}"`).join('');
    const body = escapeXml(this._text) + this.children.map(c => c.outerHTML || escapeXml(String(c))).join('');
    return `<${this.name}${attrs}>${body}</${this.name}>`;
  }
}

const document = {
  documentElement: {},
  createElementNS(_ns, name) { return new Element(name); },
  createElement(name) { return new Element(name); },
  getElementById() { return null; },
  querySelectorAll() { return []; },
  addEventListener() {}
};
const colorVars = {
  '--fig-unit': '#3f7f89',
  '--fig-iterated': '#d4a747',
  '--fig-highlight': '#d4a747',
  '--fig-deformation': '#b95238',
  '--fig-assembled': '#5d9c6d',
  '--fig-comparison': '#7a6fb0',
  '--fig-neutral': '#cabf9f',
  '--fig-stroke': '#0d0c08',
  '--paper-bg': '#f8f1df',
  '--fig-label': '#1b1810'
};
const window = {};
const context = {
  window,
  document,
  console,
  getComputedStyle() { return { getPropertyValue: name => colorVars[name] || '' }; },
  setTimeout,
  clearTimeout
};
context.global = context;
window.document = document;
window.getComputedStyle = context.getComputedStyle;
vm.createContext(context);
vm.runInContext(
  fs.readFileSync(path.join(repoRoot, 'more-zeeman/render/drawer.js'), 'utf8'),
  context,
  { filename: 'drawer.js' }
);
const drawer = context.window.HermesDrawer._internal;

function fileName(code, total, index, side) {
  return total === 1 ? `${code}-${side}.svg` : `${code}-${index + 1}-${side}.svg`;
}

function filmstripFileName(code, total, index, side) {
  return total === 1 ? `${code}-${side}-filmstrip.svg` : `${code}-${index + 1}-${side}-filmstrip.svg`;
}

function proofMetadata(code, index, side, visual, kind) {
  const proof = visual.proof || {};
  const sideProof = proof[side] || {};
  const payload = {
    kind,
    lesson_code: code,
    visual_index: index,
    side,
    expression: visual.expression || '',
    proof: {
      source: proof.source || '',
      status: sideProof.status || '',
      frame_count: Number.isInteger(sideProof.frame_count) ? sideProof.frame_count : null,
      temporal: sideProof.temporal === true,
      frame_sequence: Array.isArray(sideProof.frame_sequence) ? sideProof.frame_sequence : []
    },
    interpretive_residue: proof.interpretive_residue || {}
  };
  if (sideProof.grammar) payload.proof.grammar = sideProof.grammar;
  if (sideProof.refusal) payload.proof.refusal = sideProof.refusal;
  return payload;
}

function appendProofMetadata(svg, code, index, side, visual, kind) {
  const metadata = document.createElementNS('http://www.w3.org/2000/svg', 'metadata');
  metadata.setAttribute('data-hermes-kind', 'monitoring-visual-proof');
  metadata.textContent = JSON.stringify(proofMetadata(code, index, side, visual, kind));
  svg.appendChild(metadata);
}

function svgText(parent, x, y, text, attrs) {
  const node = document.createElementNS('http://www.w3.org/2000/svg', 'text');
  node.setAttribute('x', x);
  node.setAttribute('y', y);
  node.textContent = text;
  for (const [k, v] of Object.entries(attrs || {})) node.setAttribute(k, v);
  parent.appendChild(node);
  return node;
}

function buildFilmstripSvg(frames, bounds, code, index, side, visual) {
  const panelW = 320;
  const panelH = 260;
  const frameH = 176;
  const margin = 18;
  const gutter = 18;
  const width = margin * 2 + frames.length * panelW + Math.max(0, frames.length - 1) * gutter;
  const height = margin * 2 + panelH;
  const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  svg.setAttribute('xmlns', 'http://www.w3.org/2000/svg');
  svg.setAttribute('viewBox', `0 0 ${width} ${height}`);
  svg.setAttribute('preserveAspectRatio', 'xMidYMid meet');
  svg.setAttribute('role', 'img');
  svg.setAttribute('aria-label', `${code} ${side} filmstrip ${visual.expression || ''}`.trim());
  const bg = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
  bg.setAttribute('x', '0');
  bg.setAttribute('y', '0');
  bg.setAttribute('width', String(width));
  bg.setAttribute('height', String(height));
  bg.setAttribute('fill', '#f8f1df');
  svg.appendChild(bg);
  appendProofMetadata(svg, code, index, side, visual, 'hermes_monitoring_visual_filmstrip_proof');

  for (let i = 0; i < frames.length; i += 1) {
    const frame = frames[i] || {};
    const x = margin + i * (panelW + gutter);
    const y = margin;
    const group = document.createElementNS('http://www.w3.org/2000/svg', 'g');
    group.setAttribute('data-frame-index', String(i));
    group.setAttribute('transform', `translate(${x} ${y})`);
    const panel = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
    panel.setAttribute('x', '0');
    panel.setAttribute('y', '0');
    panel.setAttribute('width', String(panelW));
    panel.setAttribute('height', String(panelH));
    panel.setAttribute('rx', '6');
    panel.setAttribute('fill', '#fffaf0');
    panel.setAttribute('stroke', '#cabf9f');
    group.appendChild(panel);
    const frameSvg = drawer.buildSvg(frame, bounds);
    frameSvg.setAttribute('x', '10');
    frameSvg.setAttribute('y', '10');
    frameSvg.setAttribute('width', String(panelW - 20));
    frameSvg.setAttribute('height', String(frameH));
    group.appendChild(frameSvg);
    const step = frame.step == null ? i + 1 : frame.step;
    svgText(group, 14, frameH + 34, `Step ${step}: ${frame.verb || 'frame'}`, {
      'font-family': 'Georgia, Times New Roman, serif',
      'font-size': '14',
      'font-weight': '700',
      'fill': '#1b1810'
    });
    svgText(group, 14, frameH + 56, frame.caption || '', {
      'font-family': 'system-ui, sans-serif',
      'font-size': '12',
      'fill': '#4d4638'
    });
    svg.appendChild(group);
  }
  return svg;
}

const written = [];
for (const [code, payload] of Object.entries(docs)) {
  const visuals = payload.visuals || [];
  for (let i = 0; i < visuals.length; i += 1) {
    const visual = visuals[i];
    for (const side of ['correct', 'incorrect']) {
      const doc = visual[side] && visual[side].doc;
      const frames = doc && Array.isArray(doc.frames) ? doc.frames : [];
      if (!frames.length) continue;
      const bounds = drawer.documentBounds(frames, doc.canvas || {});
      const svg = drawer.buildSvg(frames[frames.length - 1], bounds);
      svg.setAttribute('role', 'img');
      svg.setAttribute('aria-label', `${code} ${side} ${visual.expression || ''}`.trim());
      appendProofMetadata(svg, code, i, side, visual, 'hermes_monitoring_visual_proof');
      let svgText = svg.outerHTML;
      svgText = svgText.replace(
        /font-family="Georgia, &quot;Times New Roman&quot;, serif"/g,
        'font-family="Georgia, Times New Roman, serif"'
      );
      const name = fileName(code, visuals.length, i, side);
      const file = path.join(outDir, name);
      fs.writeFileSync(file, svgText + '\n', 'utf8');
      written.push(file);
      if (frames.length > 1) {
        const filmstrip = buildFilmstripSvg(frames, bounds, code, i, side, visual);
        let filmstripText = filmstrip.outerHTML;
        filmstripText = filmstripText.replace(
          /font-family="Georgia, &quot;Times New Roman&quot;, serif"/g,
          'font-family="Georgia, Times New Roman, serif"'
        );
        const filmstripName = filmstripFileName(code, visuals.length, i, side);
        const filmstripFile = path.join(outDir, filmstripName);
        fs.writeFileSync(filmstripFile, filmstripText + '\n', 'utf8');
        written.push(filmstripFile);
      }
    }
  }
}
process.stdout.write(JSON.stringify(written, null, 2));
"""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--lesson",
        action="append",
        dest="lessons",
        help="IM lesson code to export. Repeat for multiple lessons. Defaults to current regression examples.",
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=DEFAULT_OUT,
        help=f"Output directory. Default: {DEFAULT_OUT}",
    )
    parser.add_argument(
        "--chart-json",
        type=Path,
        help=(
            "JSON object mapping lesson codes to monitoring-chart payloads. "
            "When provided, charts are read from this file instead of "
            "monitoring_chart_export."
        ),
    )
    return parser.parse_args()


def svg_name(code: str, total: int, index: int, side: str) -> str:
    if total == 1:
        return f"{code}-{side}.svg"
    return f"{code}-{index + 1}-{side}.svg"


def filmstrip_svg_name(code: str, total: int, index: int, side: str) -> str:
    if total == 1:
        return f"{code}-{side}-filmstrip.svg"
    return f"{code}-{index + 1}-{side}-filmstrip.svg"


def proof_summary_html(visual: dict, side: str) -> str:
    proof = visual.get("proof") if isinstance(visual, dict) else {}
    proof = proof if isinstance(proof, dict) else {}
    side_proof = proof.get(side) if isinstance(proof.get(side), dict) else {}
    residue = proof.get("interpretive_residue") if isinstance(proof.get("interpretive_residue"), dict) else {}
    status = html.escape(str(side_proof.get("status") or "proof_unavailable"))
    frame_count = html.escape(str(side_proof.get("frame_count") or 0))
    temporal = "temporal" if side_proof.get("temporal") else "single-frame"
    residue_status = html.escape(str(residue.get("status") or "residue_unstated"))
    claim = html.escape(str(residue.get("claim") or ""))
    sequence = frame_sequence_html(side_proof)
    return f"""<dl class="proof">
  <dt>Proof</dt><dd>{status}</dd>
  <dt>Frames</dt><dd>{frame_count} ({temporal})</dd>
  <dt>Frame sequence</dt><dd>{sequence}</dd>
  <dt>Residue</dt><dd>{residue_status}</dd>
  <dt>Claim</dt><dd>{claim}</dd>
</dl>"""


def frame_sequence_html(side_proof: dict) -> str:
    sequence = side_proof.get("frame_sequence") if isinstance(side_proof, dict) else []
    if not isinstance(sequence, list) or not sequence:
        return "none"
    items: list[str] = []
    for frame in sequence:
        if not isinstance(frame, dict):
            continue
        step = html.escape(str(frame.get("step") or "?"))
        verb = html.escape(str(frame.get("verb") or "unnamed_step"))
        items.append(f"{step}. {verb}")
    return "<br>".join(items) if items else "none"


def build_gallery(out_dir: Path, docs: dict[str, dict]) -> None:
    cards: list[str] = []
    for code, payload in docs.items():
        visuals = payload.get("visuals") or []
        for index, visual in enumerate(visuals):
            expression = html.escape(str(visual.get("expression") or "generated visual"))
            family = html.escape(str(visual.get("family") or ""))
            for side in ("correct", "incorrect"):
                side_payload = visual.get(side) or {}
                desc = html.escape(str(side_payload.get("description") or side))
                doc = side_payload.get("doc") or {}
                frames = doc.get("frames") if isinstance(doc, dict) else []
                proof = visual.get("proof") if isinstance(visual.get("proof"), dict) else {}
                side_proof = proof.get(side) if isinstance(proof.get(side), dict) else {}
                is_temporal = bool(side_proof.get("temporal"))
                if frames:
                    name = (
                        filmstrip_svg_name(code, len(visuals), index, side)
                        if is_temporal
                        else svg_name(code, len(visuals), index, side)
                    )
                    media = f"""<img src="{html.escape(name)}" alt="{html.escape(code)} {html.escape(side)} {expression}">"""
                else:
                    note = html.escape(str(doc.get("error") or "No drawable frames returned."))
                    media = f"""<div class="note">{note}</div>"""
                cards.append(
                    f"""<figure>
  <figcaption><b>{html.escape(code)}</b> {html.escape(side)}<br><span>{expression} {family}</span></figcaption>
  {media}
  <p>{desc}</p>
  {proof_summary_html(visual, side)}
</figure>"""
                )
    body = "\n".join(cards) or "<p>No drawable monitoring visuals were generated.</p>"
    html_doc = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Generated Monitoring Visuals</title>
<style>
body {{ margin: 24px; font: 16px system-ui, sans-serif; background: #f8f1df; color: #1b1810; }}
main {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 16px; }}
figure {{ margin: 0; padding: 12px; border: 1px solid #cabf9f; background: #fffaf0; }}
figcaption {{ font-size: 0.9rem; margin-bottom: 8px; }}
figcaption span, p {{ color: #665f4f; }}
img {{ width: 100%; height: 220px; object-fit: contain; background: #f8f1df; border: 1px solid #cabf9f; }}
.note {{ min-height: 220px; display: grid; place-items: center; padding: 12px; background: #fff4e8; border: 1px solid #cabf9f; color: #665f4f; text-align: center; }}
p {{ margin: 8px 0 0; font-size: 0.9rem; }}
.proof {{ margin: 10px 0 0; display: grid; grid-template-columns: max-content 1fr; gap: 4px 10px; font-size: 0.78rem; color: #4d4638; }}
.proof dt {{ font-weight: 700; }}
.proof dd {{ margin: 0; overflow-wrap: anywhere; }}
</style>
</head>
<body>
<h1>Generated Monitoring Visuals</h1>
<main>
{body}
</main>
</body>
</html>
"""
    (out_dir / "index.html").write_text(html_doc, encoding="utf-8")


def load_chart_json(path: Path) -> dict[str, dict]:
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except OSError as exc:
        raise RuntimeError(f"{path}: {exc}") from exc
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"{path}: invalid JSON: {exc}") from exc
    if not isinstance(raw, dict):
        raise RuntimeError(f"{path}: chart JSON root must be an object")
    charts: dict[str, dict] = {}
    for code, chart in raw.items():
        lesson_code = str(code)
        if not isinstance(chart, dict):
            raise RuntimeError(f"{path}: chart for {lesson_code} must be an object")
        charts[lesson_code] = chart
    return charts


def main() -> int:
    args = parse_args()
    out_dir = args.out.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    sys.path.insert(0, str(REPO_ROOT))
    from hermes.app import server

    try:
        chart_overrides = load_chart_json(args.chart_json) if args.chart_json else None
    except RuntimeError as exc:
        sys.stderr.write(f"{exc}\n")
        return 2
    lessons = args.lessons or (list(chart_overrides.keys()) if chart_overrides else DEFAULT_LESSONS)

    docs: dict[str, dict] = {}
    try:
        for code in lessons:
            if chart_overrides is not None:
                if code not in chart_overrides:
                    raise RuntimeError(f"{code}: no chart in {args.chart_json}")
                chart = chart_overrides[code]
            else:
                chart = server.worker_request("monitoring_chart_export", lesson_code=code)
            if not isinstance(chart, dict):
                raise RuntimeError(f"{code}: monitoring_chart_export returned {type(chart).__name__}")
            docs[code] = server._monitoring_visuals_for_chart(code, chart)
    except RuntimeError as exc:
        sys.stderr.write(f"{exc}\n")
        return 2
    finally:
        worker = getattr(server, "_WORKER", None)
        if worker is not None:
            worker.close()

    docs_path = out_dir / "docs.json"
    docs_path.write_text(json.dumps(docs, indent=2), encoding="utf-8")

    from hermes.app.scripts import verify_monitoring_visuals

    issues = verify_monitoring_visuals.verify_docs(docs)
    if issues:
        for issue in issues:
            sys.stderr.write(f"{issue}\n")
        return 1

    proc = subprocess.run(
        ["node", "-e", NODE_EXPORTER],
        input=json.dumps({
            "repoRoot": str(REPO_ROOT),
            "outDir": str(out_dir),
            "docsPath": str(docs_path),
        }),
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        cwd=REPO_ROOT,
        check=False,
    )
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr)
        return proc.returncode

    svg_issues = verify_monitoring_visuals.verify_svg_files(docs, out_dir)
    if svg_issues:
        for issue in svg_issues:
            sys.stderr.write(f"{issue}\n")
        return 1

    build_gallery(out_dir, docs)
    written = json.loads(proc.stdout or "[]")
    print(f"Wrote {len(written)} SVG files to {out_dir}")
    for file in written:
        print(file)
    print(out_dir / "index.html")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
