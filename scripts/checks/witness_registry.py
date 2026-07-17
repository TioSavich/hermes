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

    # Every op-backed route must attribute at least one op in the generated
    # registry. The registry regenerates self-consistently, so --check alone
    # cannot notice when a refactor makes an op invisible to the extractor
    # (a _forward_op-style helper once hid six routes this way): an op-backed
    # route with zero capability_route facts is that failure, made loud.
    worker_routes_text = (ROOT / "hermes/app/routes/worker.py").read_text(encoding="utf-8")
    op_routes = set(re.findall(r'\(\s*"(/api/[^"]+)"\s*,\s*"[^"]+"\s*\)', worker_routes_text))
    op_routes |= {"/api/pair_candidate", "/api/unit_coordination.svg"}  # analysis.py op routes
    registry_text = (ROOT / "hermes/capability_registry.pl").read_text(encoding="utf-8")
    attributed = set(re.findall(r"capability_route\('[^']+', '[A-Z]+', '([^']+)'\)", registry_text))
    unattributed = sorted(op_routes - attributed)
    if unattributed:
        print(
            "op-backed routes with no capability_route attribution "
            "(extractor blind spot): " + ", ".join(unattributed),
            file=sys.stderr,
        )
        return 1
    print(f"witness registry: {len(op_routes)} op-backed routes all attributed: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
