#!/usr/bin/env python3
"""Run every tracked render exporter in non-mutating drift-check mode."""
from __future__ import annotations

import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
EXPORTERS = (
    "export_fraction_cliff.py",
    "export_hybridization_demo.py",
    "export_lesson_deformation_charts.py",
    "export_monitoring_visuals.py",
    "export_notation.py",
    "export_notation_charts.py",
    "export_parametric_deformations.py",
    "export_parametric_fraction_errors.py",
    "export_parametric_partition.py",
)


def main() -> int:
    def run(name: str) -> tuple[str, int, str]:
        path = REPO / "hermes" / "app" / "scripts" / name
        proc = subprocess.run(
            [sys.executable, str(path), "--check"], cwd=REPO,
            text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=False,
        )
        return name, proc.returncode, proc.stdout

    failed = []
    with ThreadPoolExecutor(max_workers=3) as executor:
        results = list(executor.map(run, EXPORTERS))
    for name, returncode, output in results:
        print(f"[{name}]")
        print(output, end="" if output.endswith("\n") else "\n")
        if returncode:
            failed.append(name)
    if failed:
        print("test_prebaked_gallery_drift: FAILED: " + ", ".join(failed))
        return 1
    print(f"test_prebaked_gallery_drift: ok ({len(EXPORTERS)} exporters)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
