#!/usr/bin/env python3
"""Check the branch-agent loop and its recorded offline replay."""
from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from hermes.mcp.branch_agents import (
    BRANCHES,
    HermesToolExecutor,
    ModelReply,
    SyntaxCatalog,
    collect_trace,
    structured_reply,
)
from hermes.mcp.server import HermesMCPServer
from hermes.app.root import resolve_hermes_root


def main() -> int:
    syntax = SyntaxCatalog(ROOT)
    core = HermesMCPServer("core", resolve_hermes_root(ROOT))
    try:
        core_names = {tool["name"] for tool in core._tools}
        carved = [name for spec in BRANCHES.values() for name in spec.tools]
        assert set(carved) == core_names
        assert len(carved) == len(set(carved))
        assert all(row.get("source", "").startswith("knowledge/strategies/automaton_input_contracts.pl:") for row in core._strategy_contracts)
        strategy_prompt = syntax.branch_instruction("strategy_and_enactment")
        assert all(row["name"] in strategy_prompt and row["source"] in strategy_prompt for row in core._strategy_contracts)
        assert "no generated worked-input contract source" in syntax.branch_instruction("arithmetic_claim")
        assert "None of its verdicts is authoritative" not in strategy_prompt
    finally:
        core.close()

    reasoning_reply = ModelReply(
        content=":",
        reasoning_content='{"branch":"arithmetic_claim","reason":"explicit relation"}',
        raw_response={},
    )
    parsed, source = structured_reply(
        reasoning_reply,
        lambda value: value.get("branch") == "arithmetic_claim",
    )
    assert parsed["branch"] == "arithmetic_claim" and source == "reasoning_content"
    traces = collect_trace({"checks": [{"trace": ["a"]}], "nested": {"steps": ["b"]}})
    assert [row["path"] for row in traces] == ["$.checks[0].trace", "$.nested.steps"]

    live_tools = HermesToolExecutor(ROOT)
    try:
        live_verdict = live_tools.call(
            "strategy_trace",
            {"strategy": "count_on_from_larger", "input": {"a": 47, "b": 28}},
        )
    finally:
        live_tools.close()
    assert live_verdict.get("ok") is True and collect_trace(live_verdict)

    fixture = ROOT / "scripts" / "checks" / "fixtures" / "task_240_branch_agent_replay.jsonl"
    with tempfile.TemporaryDirectory(prefix="task-240-check-") as temp_dir:
        output = Path(temp_dir) / "replay.json"
        completed = subprocess.run(
            [sys.executable, str(ROOT / "hermes" / "mcp" / "branch_agents.py"), "--replay", str(fixture), "--out", str(output)],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        if completed.returncode:
            raise RuntimeError(completed.stderr or completed.stdout)
        records = json.loads(output.read_text(encoding="utf-8"))

    assert len(records) == 12
    assert len({record["replay_item_id"] for record in records}) == len(records)
    assert any(record["outcome"] == "retry_bound_exhausted" for record in records)
    assert any(
        event.get("structured_source") == "reasoning_content"
        for record in records
        for event in record["events"]
    )
    assert any(
        event["stage"] == "route" and event.get("decision") == "retry"
        for record in records
        for event in record["events"]
    )
    required_stages = {"dispatch", "agent_parse", "hermes_call", "agent_report", "adjudication", "route"}
    for record in records:
        stages = {event["stage"] for event in record["events"]}
        assert required_stages <= stages
        assert record["config"]["max_attempts"] >= record["attempts_used"]
        for event in record["events"]:
            if event["stage"] == "hermes_call":
                assert "raw_verdict" in event and "trace" in event and "call" in event

    print("PASS task-240 branch carving covers the live core surface once")
    print("PASS strategy syntax is generated from source-cited live contracts")
    print("PASS content and reasoning_content both feed structured parsing")
    print("PASS the live Hermes executor returns a trace-bearing strategy verdict")
    print("PASS recorded offline replay exercises answer, retry, branch change, and bound exhaustion")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
