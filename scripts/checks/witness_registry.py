#!/usr/bin/env python3
"""Check that witness families are disjoint and backed by worker dispatch clauses."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from hermes.app.routes.logic import WITNESS_OPS  # noqa: E402

DISPATCH_RE = re.compile(
    r"(?m)^dispatch_request\(([a-z][A-Za-z0-9_]*),\s*Id,\s*_?Request,\s*Response\)\s*:-"
)


def main() -> int:
    owners: dict[str, str] = {}
    overlaps: list[str] = []
    for family, ops in sorted(WITNESS_OPS.items()):
        for op in sorted(ops):
            previous = owners.get(op)
            if previous is not None:
                overlaps.append(f"{op} ({previous}, {family})")
            owners[op] = family
    if overlaps:
        print("witness families overlap: " + ", ".join(overlaps), file=sys.stderr)
        return 1
    print(f"witness registry: {len(WITNESS_OPS)} pairwise-disjoint families: PASS")

    worker_text = (ROOT / "hermes_worker.pl").read_text(encoding="utf-8")
    dispatch_ops = set(DISPATCH_RE.findall(worker_text))
    missing = sorted(set(owners) - dispatch_ops)
    if missing:
        print("witness ops without dispatch_request clauses: " + ", ".join(missing), file=sys.stderr)
        return 1
    print(f"witness registry: {len(owners)} ops have dispatch_request clauses: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
