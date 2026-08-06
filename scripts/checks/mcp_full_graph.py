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

from hermes.mcp.server import FAMILY_GRAPH_ARTIFACT, FULL_GRAPH_ARTIFACT, HermesMCPServer


def main() -> int:
    graph = json.loads((ROOT / FULL_GRAPH_ARTIFACT).read_text(encoding="utf-8"))
    family_graph = json.loads((ROOT / FAMILY_GRAPH_ARTIFACT).read_text(encoding="utf-8"))
    counts = graph["meta"]["counts"]
    server = HermesMCPServer("core", ROOT)
    try:
        graph_tools = {
            row["name"]: row
            for row in server._public_tools
            if row["name"].startswith("graph_")
        }
        assert set(graph_tools) == {
            "graph_overview", "graph_machine", "graph_borrows", "graph_quotient"
        }
        assert all(row["annotations"] == {"readOnlyHint": True, "idempotentHint": True} for row in graph_tools.values())
        overview_count_schema = graph_tools["graph_overview"]["outputSchema"]["properties"]["counts"]
        assert {"validity_counts", "review_status_counts", "reviewed_unreviewed_counts"} <= set(
            overview_count_schema["required"]
        )
        machine_edge_schema = graph_tools["graph_machine"]["outputSchema"]["properties"]["edges"]["items"]
        assert {"validity_modes", "review_status"} <= set(machine_edge_schema["required"])
        carrier_schema = graph_tools["graph_borrows"]["outputSchema"]["properties"]["carriers"]["items"]
        assert "validity_modes" in carrier_schema["required"]
        quotient_schema = graph_tools["graph_quotient"]["outputSchema"]
        assert {"summary", "assertion", "nodes", "page", "edges"} <= set(
            quotient_schema["required"]
        )
        assert graph_tools["graph_quotient"]["inputSchema"]["required"] == ["view"]

        overview = server.call("graph_overview", {})
        assert overview["counts"] == {
            "machines": counts["machines"],
            "nodes": counts["nodes"],
            "edges": counts["edges"],
            "borrow_actions": counts["borrows"],
            "borrow_pairs": counts["borrow_pairs"],
            "cross_family_pairs": counts["cross_family_borrow_pairs"],
            "validity_counts": counts["deforming_edges_by_validity"],
            "review_status_counts": counts["deforming_edges_by_review_status"],
            "reviewed_unreviewed_counts": counts["deforming_edges_by_review_state"],
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
            {"local_action", "canonical_action", "stance", "validity_modes",
             "review_status", "provenance_kinds"} <= set(edge)
            for edge in machine["edges"]
        )
        assert all(
            (edge["validity_modes"] and edge["review_status"] is not None)
            if edge["stance"] == "deforming"
            else (edge["validity_modes"] == [] and edge["review_status"] is None)
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
        graph_edge_by_id = {edge["id"]: edge for edge in graph["edges"]}
        for carrier in action_borrows["carriers"]:
            expected_modes = [
                mode for mode in ("objective_invalid", "context_sensitive_or_inefficient")
                if any(mode in graph_edge_by_id[edge_id].get("validity_modes", [])
                       for edge_id in carrier["edge_ids"])
            ]
            assert carrier["validity_modes"] == expected_modes

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

        quotient = server.call(
            "graph_quotient", {"view": "family", "limit": 2, "offset": 1}
        )
        assert list(quotient)[:2] == ["summary", "assertion"]
        assert quotient["summary"]["view"] == "family"
        assert quotient["summary"]["counts"] == family_graph["meta"]["counts"]
        assert quotient["assertion"] == family_graph["meta"]["assertion"]
        assert "shared canonical action names only" in quotient["assertion"]
        assert quotient["nodes"] == family_graph["nodes"]
        assert quotient["edges"] == family_graph["edges"][1:3]
        assert quotient["page"] == {
            "limit": 2,
            "offset": 1,
            "returned_edges": 2,
            "returned_members": sum(
                len(edge["members"]) for edge in family_graph["edges"][1:3]
            ),
            "total_edges": len(family_graph["edges"]),
            "total_members": sum(len(edge["members"]) for edge in family_graph["edges"]),
            "truncated": True,
            "next_offset": 3,
        }
        assert all(
            {"canonical_action", "stance", "validity_modes",
             "carrier_machine_ids", "source_edge_ids"} <= set(member)
            for edge in quotient["edges"] for member in edge["members"]
        )

        assert server.worker is None
        assert server._load_full_graph() is server._load_full_graph()
        assert server._load_family_graph() is server._load_family_graph()
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

    missing_quotient_server = HermesMCPServer("core", ROOT)
    try:
        with tempfile.TemporaryDirectory(prefix="hermes-mcp-missing-quotient-") as temp_dir:
            missing_quotient_server.root = Path(temp_dir)
            response = missing_quotient_server.handle({
                "jsonrpc": "2.0",
                "id": 2,
                "method": "tools/call",
                "params": {
                    "name": "graph_quotient",
                    "arguments": {"view": "family"},
                },
            })
        assert response is not None
        assert FAMILY_GRAPH_ARTIFACT in response["error"]["message"]
        assert missing_quotient_server.worker is None
    finally:
        missing_quotient_server.close()

    print(f"PASS graph_overview matches {counts['machines']} machines, {counts['nodes']} nodes, and {counts['edges']} edges")
    print("PASS graph_machine returns 6 states, 5 edges, and shared-action counts")
    print(f"PASS graph_borrows returns cross-family pairs and carrier validity modes for {cross_family_action}")
    print("PASS graph_borrows exposes pagination totals and truncation")
    print("PASS graph_quotient returns a summary, visible page totals, and member evidence")
    print(f"PASS a missing graph names {FULL_GRAPH_ARTIFACT} without starting Prolog")
    print(f"PASS a missing quotient names {FAMILY_GRAPH_ARTIFACT} without starting Prolog")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
