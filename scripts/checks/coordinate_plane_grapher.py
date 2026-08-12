#!/usr/bin/env python3
"""Focused offline checks for the standalone coordinate-plane grapher."""

from __future__ import annotations

import hashlib
import json
import subprocess
import sys
import xml.etree.ElementTree as ET
from html.parser import HTMLParser
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
WEB = ROOT / "hermes" / "web"
GRAPher = WEB / "coordinate-plane" / "grapher.js"
DEMO = WEB / "coordinate-plane" / "index.html"
SAMPLES = WEB / "coordinate-plane" / "samples"
README = WEB / "coordinate-plane" / "README.md"
ATLAS = WEB / "atlas.html"
VISUALIZATIONS = WEB / "visualizations.html"
BUNDLE_BUILDER = ROOT / "scripts" / "bundle" / "app_manifest.py"
BUNDLE_MANIFEST = ROOT / "scripts" / "bundle" / "app_manifest.txt"
SVG_NS = "{http://www.w3.org/2000/svg}"


class EmbeddedSpecs(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.specs: dict[str, tuple[str, str]] = {}
        self._active: str | None = None
        self._sample = ""
        self._parts: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = dict(attrs)
        if tag == "script" and values.get("data-demo-spec"):
            self._active = values["data-demo-spec"]
            self._sample = values.get("data-sample") or ""
            self._parts = []

    def handle_data(self, data: str) -> None:
        if self._active is not None:
            self._parts.append(data)

    def handle_endtag(self, tag: str) -> None:
        if tag == "script" and self._active is not None:
            self.specs[self._active] = (self._sample, "".join(self._parts))
            self._active = None
            self._sample = ""
            self._parts = []


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def finite_number(value: object) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def validate_point(point: object, path: str) -> None:
    require(isinstance(point, dict), f"{path} must be an object")
    require(finite_number(point.get("x")), f"{path}.x must be numeric")
    require(finite_number(point.get("y")), f"{path}.y must be numeric")


def validate_sample(spec: object, filename: str) -> None:
    require(isinstance(spec, dict), f"{filename}: root must be an object")
    require(spec.get("version") == 1, f"{filename}: version must be 1")
    require(isinstance(spec.get("id"), str) and spec["id"], f"{filename}: id required")
    require(isinstance(spec.get("title"), str) and spec["title"], f"{filename}: title required")
    kind = spec.get("kind")
    require(kind in {"coordinate-plane", "bar-chart", "dot-plot"}, f"{filename}: invalid kind")
    canvas = spec.get("canvas", {})
    require(isinstance(canvas, dict), f"{filename}: canvas must be an object")
    require(320 <= canvas.get("width", 640) <= 1600, f"{filename}: canvas width out of range")
    require(240 <= canvas.get("height", 420) <= 1200, f"{filename}: canvas height out of range")
    if kind == "coordinate-plane":
        points = spec.get("points", [])
        lines = spec.get("lines", [])
        require(isinstance(points, list) and isinstance(lines, list), f"{filename}: arrays required")
        require(bool(points or lines), f"{filename}: a coordinate mark is required")
        for index, point in enumerate(points):
            validate_point(point, f"{filename}.points[{index}]")
        for index, line in enumerate(lines):
            require(isinstance(line, dict), f"{filename}.lines[{index}] must be an object")
            line_type = line.get("type")
            require(line_type in {"slope-intercept", "through-points", "segment"},
                    f"{filename}.lines[{index}]: invalid type")
            if line_type == "slope-intercept":
                require(finite_number(line.get("slope")) and finite_number(line.get("intercept")),
                        f"{filename}.lines[{index}]: slope and intercept required")
            elif line_type == "through-points":
                require(isinstance(line.get("points"), list) and len(line["points"]) == 2,
                        f"{filename}.lines[{index}]: two points required")
                validate_point(line["points"][0], f"{filename}.lines[{index}].points[0]")
                validate_point(line["points"][1], f"{filename}.lines[{index}].points[1]")
            else:
                validate_point(line.get("from"), f"{filename}.lines[{index}].from")
                validate_point(line.get("to"), f"{filename}.lines[{index}].to")
    elif kind == "bar-chart":
        categories = spec.get("categories")
        require(isinstance(categories, list) and categories, f"{filename}: categories required")
        for index, category in enumerate(categories):
            require(isinstance(category, dict), f"{filename}.categories[{index}] must be an object")
            require(isinstance(category.get("label"), str) and category["label"],
                    f"{filename}.categories[{index}]: label required")
            require(finite_number(category.get("value")) and category["value"] >= 0,
                    f"{filename}.categories[{index}]: nonnegative value required")
    else:
        values = spec.get("values")
        require(isinstance(values, list) and values, f"{filename}: values required")
        require(all(finite_number(value) for value in values), f"{filename}: values must be numeric")


def class_count(root: ET.Element, token: str) -> int:
    return sum(
        token in (element.get("class") or "").split()
        for element in root.iter()
    )


def render_with_node(samples: list[Path]) -> list[dict[str, str]]:
    program = r"""
const fs = require('fs');
const crypto = require('crypto');
const grapher = require(process.argv[1]);
const files = process.argv.slice(2);
const rows = files.map((file) => {
  const spec = JSON.parse(fs.readFileSync(file, 'utf8'));
  grapher.validateSpec(spec);
  const first = grapher.renderSpec(spec);
  const second = grapher.renderSpec(spec);
  if (first !== second) throw new Error(file + ': nondeterministic SVG');
  return {
    file,
    id: spec.id,
    kind: spec.kind,
    svg: first,
    sha256: crypto.createHash('sha256').update(first, 'utf8').digest('hex')
  };
});
const vertical = {
  version: 1, id: 'vertical-control', kind: 'coordinate-plane', title: 'Vertical control',
  lines: [{type: 'through-points', points: [{x: 2, y: -1}, {x: 2, y: 3}]}]
};
if (!grapher.renderSpec(vertical).includes('data-line-type="through-points"')) {
  throw new Error('vertical through-points line was not rendered');
}
const invalid = {version: 1, id: 'invalid', kind: 'coordinate-plane', title: 'Invalid', lines: []};
let rejected = false;
try { grapher.renderSpec(invalid); } catch (error) { rejected = /point or line/.test(error.message); }
if (!rejected) throw new Error('empty coordinate spec was accepted');
process.stdout.write(JSON.stringify(rows));
"""
    command = ["node", "-e", program, str(GRAPher), *(str(path) for path in samples)]
    completed = subprocess.run(command, cwd=ROOT, check=True, capture_output=True, text=True)
    return json.loads(completed.stdout)


def check_svg(row: dict[str, str], spec: dict[str, object]) -> str:
    svg = row["svg"]
    require(hashlib.sha256(svg.encode()).hexdigest() == row["sha256"],
            f"{row['id']}: Node/Python hash mismatch")
    root = ET.fromstring(svg)
    require(root.tag == SVG_NS + "svg", f"{row['id']}: root is not SVG")
    require(root.get("data-hermes-renderer") == "grapher-v1", f"{row['id']}: renderer marker missing")
    require(root.get("data-hermes-kind") == spec["kind"], f"{row['id']}: kind marker mismatch")
    require(root.get("data-spec-id") == spec["id"], f"{row['id']}: spec id marker mismatch")
    require(root.find(SVG_NS + "title") is not None, f"{row['id']}: title missing")
    require(root.find(SVG_NS + "desc") is not None, f"{row['id']}: description missing")
    if spec["kind"] == "coordinate-plane":
        require(class_count(root, "axis-x") == 1 and class_count(root, "axis-y") == 1,
                f"{row['id']}: coordinate axes missing")
        require(class_count(root, "data-point") == len(spec.get("points", [])),
                f"{row['id']}: point count mismatch")
        require(class_count(root, "data-line") == len(spec.get("lines", [])),
                f"{row['id']}: line count mismatch")
        tick_values = {
            float(element.get("data-value"))
            for element in root.iter()
            if "gridline" in (element.get("class") or "").split()
        }
        require(any(value < 0 for value in tick_values) and any(value > 0 for value in tick_values),
                f"{row['id']}: quadrant ticks do not cross zero")
    elif spec["kind"] == "bar-chart":
        require(class_count(root, "data-bar") == len(spec["categories"]),
                f"{row['id']}: bar count mismatch")
    else:
        require(class_count(root, "data-dot") == len(spec["values"]),
                f"{row['id']}: dot count mismatch")
    return f"{row['id']}: bytes={len(svg.encode())} sha256={row['sha256']}"


def main() -> int:
    sample_paths = sorted(SAMPLES.glob("*.json"))
    require([path.name for path in sample_paths] == [
        "bar-chart.json", "dot-plot.json", "linear-function.json", "two-point-line.json"
    ], "the four required sample files are not exact")
    specs: dict[str, dict[str, object]] = {}
    for path in sample_paths:
        spec = json.loads(path.read_text(encoding="utf-8"))
        validate_sample(spec, path.name)
        require(spec["id"] not in specs, f"duplicate spec id {spec['id']}")
        specs[spec["id"]] = spec

    parser = EmbeddedSpecs()
    parser.feed(DEMO.read_text(encoding="utf-8"))
    require(set(parser.specs) == set(specs), "demo ids differ from sample ids")

    # Match each embedded demo to the file named by its data-sample attribute.
    for spec_id, (relative_path, source) in parser.specs.items():
        sample_path = DEMO.parent / relative_path
        require(sample_path.is_file(), f"{spec_id}: embedded sample path is absent")
        embedded = json.loads(source)
        require(embedded == json.loads(sample_path.read_text(encoding="utf-8")),
                f"{spec_id}: embedded JSON differs from {relative_path}")

    subprocess.run(["node", "--check", str(GRAPher)], cwd=ROOT, check=True)
    rendered = render_with_node(sample_paths)
    evidence = [check_svg(row, specs[row["id"]]) for row in rendered]

    all_line_types = {
        line["type"]
        for spec in specs.values()
        for line in spec.get("lines", [])
    }
    require(all_line_types == {"slope-intercept", "through-points", "segment"},
            "demo specs do not cover all line forms")

    readme = README.read_text(encoding="utf-8")
    for token in ["coordinate-plane", "bar-chart", "dot-plot", "slope-intercept",
                  "through-points", "segment", "renderSpec", "version"]:
        require(token in readme, f"README omits {token}")
    require("coordinate-plane/index.html" in ATLAS.read_text(encoding="utf-8"),
            "atlas does not link the grapher")
    require('href="coordinate-plane/index.html"' in VISUALIZATIONS.read_text(encoding="utf-8"),
            "visualizer picker does not link the grapher")
    require('"hermes/web/coordinate-plane/README.md"' in BUNDLE_BUILDER.read_text(encoding="utf-8"),
            "bundle builder does not retain the grapher README")
    manifest_text = BUNDLE_MANIFEST.read_text(encoding="utf-8")
    for relative in [
        "hermes/web/coordinate-plane/README.md",
        "hermes/web/coordinate-plane/grapher.js",
        "hermes/web/coordinate-plane/index.html",
        *(f"hermes/web/coordinate-plane/samples/{path.name}" for path in sample_paths),
    ]:
        require(relative in manifest_text, f"runtime manifest omits {relative}")

    print("PASS coordinate-plane demo schemas: 4/4")
    print("PASS line forms: slope-intercept, through-points, segment")
    print("PASS deterministic SVG and DOM contracts:")
    for line in evidence:
        print(f"  {line}")
    print("PASS atlas, visualizer picker, README, and runtime manifest registration")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, json.JSONDecodeError, ET.ParseError, subprocess.CalledProcessError) as error:
        print(f"FAIL coordinate_plane_grapher: {error}", file=sys.stderr)
        raise SystemExit(1)
