#!/usr/bin/env python3
"""Exercise Task 94's bounded MCP contracts and print a reviewable transcript."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
SERVER = ROOT / "hermes" / "mcp" / "server.py"
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from hermes.app.root import resolve_hermes_root
from hermes.mcp.server import HermesMCPServer


def request(request_id: int, name: str, arguments: dict[str, Any]) -> dict[str, Any]:
    return {"jsonrpc": "2.0", "id": request_id, "method": "tools/call", "params": {"name": name, "arguments": arguments}}


def run(mode: str, messages: list[dict[str, Any]]) -> list[dict[str, Any]]:
    payload = "".join(json.dumps(message) + "\n" for message in messages)
    completed = subprocess.run([sys.executable, str(SERVER), "--mode", mode], input=payload, text=True, capture_output=True, cwd=ROOT, check=False)
    if completed.returncode:
        raise RuntimeError(completed.stderr or f"server exited {completed.returncode}")
    return [json.loads(line) for line in completed.stdout.splitlines()]


def tool_value(response: dict[str, Any]) -> Any:
    return json.loads(response["result"]["content"][0]["text"])


def compact(response: dict[str, Any]) -> dict[str, Any]:
    """Keep the transcript readable while proving renderer-oriented full access."""
    if "error" in response:
        return {"id": response.get("id"), "error": response["error"]}
    if "content" not in response.get("result", {}):
        payload = response.get("result", {})
        return {"id": response.get("id"), "result_keys": sorted(payload), "tool_count": len(payload.get("tools", []))}
    value = tool_value(response)
    if isinstance(value, dict):
        return {"id": response.get("id"), "result_keys": sorted(value), "counts": {key: len(item) for key, item in value.items() if isinstance(item, list)}}
    return {"id": response.get("id"), "result_type": type(value).__name__}


def exercise_monitoring_views() -> dict[str, Any]:
    """Exercise server-owned chart shaping without the worker's broad chart scan.

    The controller's live re-dogfood covers the complete monitoring export. The
    bounded transcript uses this representative worker-shaped payload so it can
    verify the MCP view layer inside a short local run.
    """
    chart = {
        "lesson_code": "IM-G3-U5-L1",
        "lesson": {"title": "Fraction partitioning"},
        "standards": ["3.NF.A.1"],
        "anticipated_strategies": [{"kind": "unit_fraction_partition"}],
        "registered_task_instances": [{"id": "task-1"}],
        "resonant_misconceptions": [{"name": "unequal_partition"}],
        "teacher_misconceptions": [{"name": "unequal_partition"}],
    }
    server = HermesMCPServer("core", resolve_hermes_root(ROOT))
    try:
        server._monitoring_full = lambda code: chart  # type: ignore[method-assign]
        summary = server.monitoring_chart({"code": "IM-G3-U5-L1"})
        detail = server.monitoring_chart_detail({"code": "IM-G3-U5-L1", "section": "anticipated_strategies"})
        full = server.monitoring_chart({"code": "IM-G3-U5-L1", "full": True})
        assert summary["sections"] and detail["data"] == chart["anticipated_strategies"] and full == chart
        return {"summary_sections": len(summary["sections"]), "detail_section": detail["section"], "full_keys": sorted(full)}
    finally:
        server.close()


def main() -> int:
    messages = [
        {"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2025-06-18", "capabilities": {}}},
        {"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {}},
        request(3, "lesson_deformation_chart", {"code": "IM-G3-U5-L1"}),
        request(4, "lesson_deformation_chart_detail", {"code": "IM-G3-U5-L1", "id": "$.cells[0].productive"}),
        request(5, "lesson_deformation_chart", {"code": "IM-G3-U5-L1", "full": True}),
        request(6, "strategy_trace", {"strategy": "count_on_from_largerr", "input": {"a": 47, "b": 28}}),
        request(7, "lesson_deformation_chart", {"code": "IM-G3-U5-L99"}),
        request(8, "misconception_search_rows", {"query": "arrangement", "k": 2}),
        request(9, "resonance_neighbors", {"name": "arrangement_as_combination_sum", "k": 2}),
        request(10, "incompatibility_entailments", {"replacement": "o(context(the_expansion_repeats_periodically))", "replaced": "o(context(the_expansion_does_not_terminate))"}),
        request(11, "incompatibility_profile", {"content": "o(context(the_expansion_repeats_periodically))"}),
        request(12, "misconception_lookup", {"domain": "fraction", "limit": 2, "offset": 1}),
        request(13, "resonance_neighbors", {"name": "arrangement_as_combination_sum", "unexpected": True}),
        {"jsonrpc": "2.0", "id": 14, "method": "initialize", "params": {"protocolVersion": "2099-01-01", "capabilities": {}}},
        request(15, "misconception_lookup", {"limit": "2"}),
        request(16, "strategy_recognize", {"content": "The student used count on from larger."}),
        request(17, "resonance_neighbors", {"name": "arrangement_as_combination_sum", "k": "5"}),
        request(18, "deontic_scorecard", {"agent": "student", "commitments": [1], "entitlements": []}),
        request(19, "incompatibility_profile", {}),
        request(20, "incompatibility_entailments", {"replacement": "o(context(the_expansion_repeats_periodically))"}),
        request(21, "misconception_lookup", {"limit": 5.5}),
        request(22, "misconception_lookup", {"domain": "whole_number", "source": "db_row(37492)", "limit": 1}),
        request(23, "resonance_neighbors", {"db_row": "db_row(37492)", "k": 5}),
    ]
    responses = run("core", messages)
    by_id = {response.get("id"): response for response in responses}
    listed = by_id[2]["result"]["tools"]
    assert by_id[1]["result"]["protocolVersion"] == "2025-06-18"
    assert by_id[14]["result"]["protocolVersion"] == "2025-03-26"
    assert all(tool["annotations"] == {"readOnlyHint": True, "idempotentHint": True} and tool["title"] for tool in listed)
    trace_schema = next(tool for tool in listed if tool["name"] == "strategy_trace")["inputSchema"]
    assert len(trace_schema["properties"]["strategy"]["oneOf"]) > 100
    assert next(tool for tool in listed if tool["name"] == "resonance_neighbors")["outputSchema"]
    assert next(tool for tool in listed if tool["name"] == "misconception_search_rows")["outputSchema"]
    assert next(tool for tool in listed if tool["name"] == "incompatibility_entailments")["outputSchema"]
    assert next(tool for tool in listed if tool["name"] == "incompatibility_profile")["outputSchema"]
    assert tool_value(by_id[3])["inventory"]
    assert tool_value(by_id[4])["id"] == "$.cells[0].productive"
    assert "cells" in tool_value(by_id[5])
    assert by_id[6]["error"]["data"]["kind"] == "not_covered"
    assert by_id[6]["error"]["data"]["suggestions"]
    assert by_id[7]["error"]["data"] == {"kind": "not_covered", "worker_type": "no_deformation_chart"}
    assert tool_value(by_id[8])["rows"][0]["name"] == "arrangement_as_combination_sum"
    assert tool_value(by_id[9])["neighbors"]
    assert tool_value(by_id[10])["status"] in {"entailed", "equivalent"}
    assert tool_value(by_id[10])["witnessing_contexts"]
    assert tool_value(by_id[11])["minimal_sets"]
    lookup = tool_value(by_id[12])
    assert lookup["total"] >= 3 and lookup["limit"] == 2 and lookup["offset"] == 1 and len(lookup["rows"]) == 2
    assert by_id[13]["error"]["code"] == -32602 and "unexpected" in by_id[13]["error"]["message"]
    assert tool_value(by_id[15])["limit"] == 2
    assert by_id[10]["result"]["structuredContent"] == tool_value(by_id[10])
    recognized = tool_value(by_id[16])
    assert isinstance(recognized, list) and recognized
    assert by_id[16]["result"]["structuredContent"] == {"items": recognized}
    assert len(tool_value(by_id[17])["neighbors"]) == 5
    assert by_id[18]["error"]["code"] == -32602 and "commitments" in by_id[18]["error"]["message"]
    assert by_id[19]["error"]["data"]["kind"] == "malformed_input" and "requires a content term string" in by_id[19]["error"]["message"]
    assert by_id[20]["error"]["data"]["kind"] == "malformed_input" and "requires replacement and replaced term strings" in by_id[20]["error"]["message"]
    assert by_id[21]["error"]["code"] == -32602 and "limit" in by_id[21]["error"]["message"]
    documented = tool_value(by_id[22])
    assert documented["rows"] and documented["rows"][0]["description"] == "too_vague"
    assert documented["rows"][0]["gloss"] and documented["rows"][0]["status"]
    assert by_id[22]["result"]["structuredContent"] == documented
    neighbors = tool_value(by_id[23])
    identities = [row["db_row"] for row in neighbors["neighbors"]]
    assert neighbors["query_db_row"] == "db_row(37492)"
    assert len(identities) == len(set(identities)) and "db_row(37492)" not in identities
    monitoring_views = exercise_monitoring_views()

    bundle_results: dict[str, list[str]] = {}
    for bundle in ("transcript-analysis", "curriculum-reading"):
        listed_bundle = run(f"bundle:{bundle}", [{"jsonrpc": "2.0", "id": 1, "method": "tools/list", "params": {}}])[0]
        bundle_results[bundle] = [tool["name"] for tool in listed_bundle["result"]["tools"]]
    assert bundle_results["transcript-analysis"] == [
        "deontic_scorecard", "deontic_consequences", "deontic_up_level", "commitment_match",
        "strategy_recognize", "strategy_trace", "misconception_lookup", "misconception_search_rows", "resonance_neighbors",
    ]
    assert bundle_results["curriculum-reading"] == [
        "monitoring_chart", "monitoring_chart_detail", "lesson_deformation_chart",
        "lesson_deformation_chart_detail", "strategy_trace", "misconception_lookup", "misconception_search_rows",
    ]

    for message in messages:
        print("REQUEST", json.dumps(message, ensure_ascii=False))
    for response in responses:
        print("RESPONSE", json.dumps(compact(response), ensure_ascii=False, sort_keys=True))
    print("FIXTURE_MONITORING_VIEWS", json.dumps(monitoring_views, sort_keys=True))
    for bundle, names in bundle_results.items():
        print("BUNDLE", bundle, json.dumps(names))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
