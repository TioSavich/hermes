#!/usr/bin/env python3
"""Check class-C1 arithmetic against the symbolic core, in its own process.

The rider on ruling 3 says the core validates its own training data: a
known-fact reply is admitted only if `check_math_claim` agrees with it. That is
cheap and it closes the obvious hole of a teacher model writing wrong
arithmetic.

It runs here rather than inline because the worker client can block inside
`readline` past its own deadline when an operation stalls mid-line. A stall
should cost one claim, not a six-thousand-row build, so the caller runs this
with a wall-clock timeout and reads whatever was written before it fired.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from hermes.mcp.server import HermesMCPServer  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--terms", type=Path, required=True, help="JSON list of claim terms")
    parser.add_argument("--out", type=Path, required=True, help="JSONL of {term, holds}")
    arguments = parser.parse_args()

    terms = json.loads(arguments.terms.read_text(encoding="utf-8"))
    server = HermesMCPServer("core", REPO_ROOT)
    arguments.out.parent.mkdir(parents=True, exist_ok=True)
    with arguments.out.open("w", encoding="utf-8") as handle:
        for term in terms:
            try:
                checked = server.call("check_math_claim", {"term": term})
                holds = bool(checked and checked.get("checks"))
            except Exception as exc:
                holds = False
                handle.write(json.dumps({"term": term, "holds": False, "refused": type(exc).__name__}) + "\n")
                handle.flush()
                continue
            handle.write(json.dumps({"term": term, "holds": holds}) + "\n")
            handle.flush()
    server.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
