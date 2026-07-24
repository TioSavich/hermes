#!/usr/bin/env python3
"""Regression checks for MCP offline misconception row matching."""
from __future__ import annotations

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from hermes.mcp.server import HermesMCPServer, row_matches_query


def main() -> int:
    irrelevant = {
        "name": "arrangement_as_combination_sum",
        "domain": "combinatorial",
        "description": "arrangement_as_combination_sum",
        "citation": "structure pairings before counting",
    }
    substring_only = {
        "name": "configuration_error",
        "domain": "geometry",
        "description": "configuration error",
        "citation": "a global configuration conflicts with a local image",
    }
    ratio_row = {
        "name": "order_of_appearance_ratio",
        "domain": "fraction",
        "description": "order_of_appearance_ratio",
        "citation": "build the ratio from numbers in textual order",
    }
    assert not row_matches_query("vertical distance", irrelevant)
    assert not row_matches_query("ratio", substring_only)
    assert row_matches_query("ratio", ratio_row)
    assert row_matches_query("appearance ratio", ratio_row)
    assert not row_matches_query("---", ratio_row)

    server = HermesMCPServer("core", ROOT)
    try:
        absent = server.misconception_search_rows(
            {"query": "zzzz-no-such-misconception", "k": 3}
        )
        assert absent["count"] == 0 and absent["rows"] == []
        present = server.misconception_search_rows({"query": "ratio", "k": 3})
        assert present["count"] > 0 and present["rows"]
        assert all(row_matches_query("ratio", row) for row in present["rows"])
    finally:
        server.close()
    print("mcp search rows: empty-token and whole-word fixtures PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
