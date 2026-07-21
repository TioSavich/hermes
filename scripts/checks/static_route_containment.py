#!/usr/bin/env python3
"""Prove web-root and whitelisted-mount traversal remains contained."""
from __future__ import annotations

import sys
from pathlib import Path
from types import SimpleNamespace

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from hermes.app.routes.static import resolve_static_file  # noqa: E402
from hermes.app.server import STATIC_MOUNTS  # noqa: E402


def main() -> int:
    app = ROOT / "hermes/app"
    mounts = {
        "more-zeeman": ROOT / "more-zeeman",
        "learner": ROOT / "formal" / "learner",
        "representation": ROOT / "representation",
        "ASKTM_Data": ROOT / "data" / "asktm",
        "docs": ROOT / "docs",
        "docs/research_assets": ROOT / "data" / "research_assets",
    }
    if mounts != dict(STATIC_MOUNTS):
        print("containment mount table differs from server STATIC_MOUNTS",
              file=sys.stderr)
        return 1
    ctx = SimpleNamespace(web_root=app / "web", static_mounts=mounts)
    probes = ["/../server.py", "/%2e%2e/server.py"]
    for mount in mounts:
        probes.extend((f"/{mount}/../hermes_worker.pl", f"/{mount}/%2e%2e/hermes_worker.pl"))
    escaped = [(probe, resolve_static_file(ctx, probe)) for probe in probes]
    escaped = [(probe, path) for probe, path in escaped if path is not None]
    if escaped:
        for probe, path in escaped:
            print(f"traversal resolved: {probe} -> {path}", file=sys.stderr)
        return 1
    if resolve_static_file(ctx, "/console.html") != app / "web/console.html":
        print("web-root control file did not resolve", file=sys.stderr)
        return 1
    print(f"static containment: {len(probes)} traversal probes rejected across web root and six mounts")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
