#!/usr/bin/env python3
"""Check generated monitoring and gallery entrances on the public pages."""
from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
GENERATED = ROOT / "hermes" / "app" / "web" / "generated"


def main() -> int:
    regen = subprocess.run(
        ["bash", str(ROOT / "scripts/regen_all.sh"), "--dry-run"],
        cwd=ROOT, capture_output=True, text=True, check=True,
    ).stdout.splitlines()
    required_exporters = [
        "python3 hermes/app/scripts/export_fraction_cliff.py",
        "python3 hermes/app/scripts/export_parametric_deformations.py",
        "python3 hermes/app/scripts/export_parametric_fraction_errors.py",
        "python3 hermes/app/scripts/export_lesson_deformation_charts.py",
    ]
    index_command = "python3 scripts/generate_visual_surface_indexes.py"
    if index_command not in regen:
        raise AssertionError("regen_all omits visual surface index generation")
    index_position = regen.index(index_command)
    for command in required_exporters:
        if command not in regen or regen.index(command) >= index_position:
            raise AssertionError(f"regen_all does not settle {command} before visual indexes")

    subprocess.run(
        ["python3", str(ROOT / "scripts" / "generate_visual_surface_indexes.py"), "--check"],
        cwd=ROOT,
        check=True,
    )
    monitoring = (ROOT / "hermes" / "web" / "monitoring_chart.html").read_text(encoding="utf-8")
    if "id='monitoring-visual-index'" in monitoring or 'id="monitoring-visual-index"' in monitoring:
        raise AssertionError("monitoring page still embeds a hand-written visual index")
    if "fetch('/generated/monitoring_visual_index.json')" not in monitoring:
        raise AssertionError("monitoring page does not read the generated index")
    if "var STATIC_LESSON = 'IM-G2-U2-L7'" not in monitoring:
        raise AssertionError("monitoring page default has no committed filmstrip pair")
    if "The committed visual index could not be loaded" not in monitoring:
        raise AssertionError("monitoring page silently discards visual-index failures")
    if "vision_lesson_digest.pl" in monitoring:
        raise AssertionError("monitoring page exposes an internal source filename")

    index = json.loads((GENERATED / "monitoring_visual_index.json").read_text(encoding="utf-8"))
    if not index.get("lessons"):
        raise AssertionError("generated monitoring index has no lessons")
    for pairs in index["lessons"].values():
        for pair in pairs:
            for side in ("correct", "incorrect"):
                asset = pair.get(side)
                if asset and not (ROOT / "hermes" / "app" / "web" / asset.lstrip("/")).is_file():
                    raise AssertionError(f"indexed asset is missing: {asset}")

    public_links = {
        "misconception_demos": "hermes/web/visualizations.html",
        "parametric_fraction_errors": "hermes/web/visualizations.html",
        "parametric_deformations": "hermes/web/visualizations.html",
        "fraction_cliff_demos": "hermes/web/visualizations.html",
        "best_IM_scenes": "hermes/web/visualizations.html",
        "real_transplants": "hermes/web/research.html",
        "fractal_loops": "hermes/web/research.html",
    }
    for gallery, page_name in public_links.items():
        page = (ROOT / page_name).read_text(encoding="utf-8")
        if f"../generated/{gallery}/index.html" not in page:
            raise AssertionError(f"{gallery} has no public card on {page_name}")
        if not (GENERATED / gallery / "index.html").is_file():
            raise AssertionError(f"{gallery} has no index page")

    teacher_generators = [
        ROOT / "hermes/app/scripts/export_fraction_cliff.py",
        ROOT / "hermes/app/scripts/export_parametric_deformations.py",
        ROOT / "hermes/app/scripts/export_parametric_fraction_errors.py",
    ]
    for generator in teacher_generators:
        source = generator.read_text(encoding="utf-8")
        if re.search(r"<code>[^<]*\.(?:pl|js)</code>", source):
            raise AssertionError(f"{generator.name} puts source filenames on its gallery page")
    cliff_source = teacher_generators[0].read_text(encoding="utf-8")
    if "Each strip's verdict comes from the search" in cliff_source or "machine:" in cliff_source:
        raise AssertionError("fraction cliff generator publishes an unsupported machine verdict")

    best_count = len(list((GENERATED / "best_IM_scenes").glob("*.svg")))
    best_index = (GENERATED / "best_IM_scenes" / "index.html").read_text(encoding="utf-8")
    if best_index.count("<figure>") != best_count:
        raise AssertionError("best_IM_scenes index does not contain every generated SVG")
    print(
        f"PASS visual surface indexes: {len(index['lessons'])} monitoring entries, "
        f"{len(public_links)} gallery cards, {best_count} lesson scenes"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
