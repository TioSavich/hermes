#!/usr/bin/env python3
"""Regression checks for MCP misconception lookup and offline row matching."""
from __future__ import annotations

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from hermes.mcp.server import HermesMCPServer, ToolCallError, row_matches_query


def assert_filter_refused(
    server: HermesMCPServer, argument: str, received: str
) -> None:
    """Pin the worker refusal for a supplied non-ground filter term."""
    try:
        server.misconception_lookup({argument: received, "limit": 100})
    except ToolCallError as exc:
        assert exc.kind == "malformed_input"
        assert exc.worker_type == "invalid_misconception_filter"
        assert argument in str(exc)
        assert received in str(exc)
        assert "misconception_search_rows" in str(exc)
    else:
        raise AssertionError(
            f"misconception_lookup accepted non-ground {argument}={received!r}"
        )


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
        assert_filter_refused(server, "domain", "Fraction")
        assert_filter_refused(server, "source", "Baruk")
        lowercase_exact = server.misconception_lookup(
            {"source": "baruk", "limit": 100}
        )
        assert lowercase_exact["total"] == 0 and lowercase_exact["rows"] == []
        assert_filter_refused(server, "description", "Whatever")
        db_row_exact = server.misconception_lookup(
            {"source": "db_row(37434)", "limit": 100}
        )
        assert db_row_exact["total"] == 1 and len(db_row_exact["rows"]) == 1

        absent = server.misconception_search_rows(
            {"query": "zzzz-no-such-misconception", "k": 3}
        )
        assert absent["count"] == 0 and absent["rows"] == []
        present = server.misconception_search_rows({"query": "ratio", "k": 3})
        assert present["count"] > 0 and present["rows"]
        assert all(row_matches_query("ratio", row) for row in present["rows"])
        documented = server.misconception_search_rows({"query": "zero exempt", "k": 3})
        assert documented["rows"]
        assert all(row["gloss"] and row["status"] and row["db_row"] for row in documented["rows"])
        assert documented["rows"][0]["name"] == "too_vague"
    finally:
        server.close()
    print(
        "mcp misconception filters and search rows: refusal, exact-match, "
        "empty-token, and whole-word fixtures PASS"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
