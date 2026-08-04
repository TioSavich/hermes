#!/usr/bin/env python3
"""Build the single-file automata compendium and print it with Chrome."""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
BUILDER = ROOT / "scripts/research/build_automata_compendium.py"
BUILD_DIR = ROOT / "build/automata-compendium"
PRINT_HTML = BUILD_DIR / "2026-08-03-automata-compendium-print.html"
PDF_OUTPUT = BUILD_DIR / "2026-08-03-automata-compendium.pdf"
CHROME = Path("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")

# Sixty seconds gives Chrome time to load all local SVGs and settle the complete
# 222-entry layout before it captures the print document.
VIRTUAL_TIME_BUDGET_MS = 60_000


def main() -> int:
    subprocess.run(
        [sys.executable, str(BUILDER), "--print"],
        cwd=ROOT,
        check=True,
    )
    if not CHROME.is_file():
        raise FileNotFoundError(f"Google Chrome not found at {CHROME}")

    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            str(CHROME),
            "--headless=new",
            "--allow-file-access-from-files",
            "--run-all-compositor-stages-before-draw",
            "--no-pdf-header-footer",
            f"--virtual-time-budget={VIRTUAL_TIME_BUDGET_MS}",
            f"--print-to-pdf={PDF_OUTPUT}",
            PRINT_HTML.resolve().as_uri(),
        ],
        cwd=ROOT,
        check=True,
    )
    if not PDF_OUTPUT.is_file() or PDF_OUTPUT.stat().st_size == 0:
        raise RuntimeError(f"Chrome did not produce a PDF at {PDF_OUTPUT}")
    print(f"automata compendium PDF: {PDF_OUTPUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
