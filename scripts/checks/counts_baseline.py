#!/usr/bin/env python3
"""Compare the tracked count baseline with live repository derivations."""

from __future__ import annotations

import difflib
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.counts_baseline_lib import BASELINE_PATH, BaselineError, load_baseline  # noqa: E402
from scripts.research.build_counts_baseline import derive_baseline, render  # noqa: E402


def main() -> int:
    try:
        current = load_baseline()
        derived = derive_baseline(current, preserve_carried=True)
    except (BaselineError, OSError, RuntimeError, ValueError) as exc:
        experiments = ROOT / "hermes/app/runtime/experiments"
        if not experiments.is_dir():
            # A clone carries no runtime tree at all; a maintainer's tree
            # with a single missing checkpoint dir still fails below.
            print(
                "SKIP counts baseline re-derivation: "
                "hermes/app/runtime/experiments absent locally "
                "(gitignored research state); tracked baseline not compared"
            )
            return 0
        print(f"counts_baseline.py: {exc}", file=sys.stderr)
        return 1
    old = render(current)
    new = render(derived)
    if old != new:
        diff = difflib.unified_diff(
            old.splitlines(keepends=True),
            new.splitlines(keepends=True),
            fromfile=str(BASELINE_PATH.relative_to(ROOT)),
            tofile="re-derived counts baseline",
        )
        sys.stderr.writelines(diff)
        return 1
    carried = sum(entry["carried"] for entry in current.values())
    print(f"PASS counts baseline: {len(current)} entries, {carried} carried")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

