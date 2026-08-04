#!/usr/bin/env python3
"""Check read-only MCP navigation of the shipped full graph artifact."""
from __future__ import annotations

import json
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from hermes.mcp.server import FULL_GRAPH_ARTIFACT, HermesMCPServer


def main() -> int:
    graph = json.loads((ROOT / FULL_GRAPH_ARTIFACT).read_text(encoding="utf-8"))
    counts = graph["meta"]["counts"]
    server = HermesMCPServer("core", ROOT)
    try:
        graph_tools = {
            row["name"]: row
            for row in server._public_tools
            if row["name"].startswith("graph_")
        }
        assert set(graph_tools) == {"graph_overview", "graph_machine", "graph_borrows"}
        assert all(row["annotations"] == {"readOnlyHint": True, "idempotentHint": True} for row in graph_tools.values())

        overview = server.call("graph_overview", {})
        assert overview["counts"] == {
            "machines": counts["machines"],
            "nodes": counts["nodes"],
            "edges": counts["edges"],
            "borrow_actions": counts["borrows"],
            "borrow_pairs": counts["borrow_pairs"],
            "cross_family_pairs": counts["cross_family_borrow_pairs"],
        }
        assert overview["meta"]["scope"] == graph["meta"]["scope"]
        assert overview["meta"]["level_ladder"] == graph["meta"]["level_ladder"]
        assert overview["meta"]["level_note"] == graph["meta"]["level_note"]

        machine = server.call(
            "graph_machine",
            {"family": "addition", "kind": "append_column_sum_without_carrying"},
        )
        assert len(machine["states"]) == 6
        assert len(machine["edges"]) == 5
        assert machine["borrow_summary"]["shared_canonical_action_count"] > 0
        assert all(
            {"local_action", "canonical_action", "stance", "provenance_kinds"} <= set(edge)
            for edge in machine["edges"]
        )

        cross_family_action = next(
            row["canonical_action"]
            for row in graph["borrows"]
            if any(pair["cross_family"] for pair in row["pairs"])
        )
        action_borrows = server.call(
            "graph_borrows",
            {"canonical_action": cross_family_action, "cross_family_only": True},
        )
        assert action_borrows["totals"]["cross_family_pairs"] > 0
        assert action_borrows["totals"]["carrier_machines"] >= 2
        assert action_borrows["pairs"] and all(pair["cross_family"] for pair in action_borrows["pairs"])

        machine_borrows = server.call(
            "graph_borrows",
            {
                "family": "addition",
                "kind": "append_column_sum_without_carrying",
                "limit": 1,
            },
        )
        assert machine_borrows["totals"]["matching_pairs"] > 1
        assert machine_borrows["page"]["returned"] == 1
        assert machine_borrows["page"]["truncated"] is True
        assert machine_borrows["page"]["next_offset"] == 1

        assert server.worker is None
        assert server._load_full_graph() is server._load_full_graph()
    finally:
        server.close()

    missing_server = HermesMCPServer("core", ROOT)
    try:
        with tempfile.TemporaryDirectory(prefix="hermes-mcp-missing-graph-") as temp_dir:
            missing_server.root = Path(temp_dir)
            response = missing_server.handle({
                "jsonrpc": "2.0",
                "id": 1,
                "method": "tools/call",
                "params": {"name": "graph_overview", "arguments": {}},
            })
        assert response is not None
        assert FULL_GRAPH_ARTIFACT in response["error"]["message"]
        assert missing_server.worker is None
    finally:
        missing_server.close()

    print(f"PASS graph_overview matches {counts['machines']} machines, {counts['nodes']} nodes, and {counts['edges']} edges")
    print("PASS graph_machine returns 6 states, 5 edges, and shared-action counts")
    print(f"PASS graph_borrows returns cross-family pairs for {cross_family_action}")
    print("PASS graph_borrows exposes pagination totals and truncation")
    print(f"PASS a missing graph names {FULL_GRAPH_ARTIFACT} without starting Prolog")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
