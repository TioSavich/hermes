#!/usr/bin/env python3
"""Check the local Hermes MCP path before connecting it to a client."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Callable

from hermes.app.root import resolve_hermes_root
from hermes.mcp.server import HermesMCPServer, ToolCallError


@dataclass(frozen=True)
class Check:
    """One colleague-facing MCP call and the evidence that it succeeded."""

    label: str
    tool: str
    arguments: dict[str, Any]
    accepts: Callable[[Any], bool]
    fix: str


CHECKS = (
    Check(
        label="monitoring_chart on IM-G3-U5-L1",
        tool="monitoring_chart",
        arguments={"code": "IM-G3-U5-L1"},
        accepts=lambda value: isinstance(value, dict) and bool(value.get("sections")),
        fix="Confirm that this checkout includes the lesson corpus, then run the command again from the repository root.",
    ),
    Check(
        label="check_math_claim for ordinary-language addition",
        tool="check_math_claim",
        arguments={"term": "I added 4 and 2 and got 6"},
        accepts=lambda value: isinstance(value, dict) and bool(value.get("checks")),
        fix="Supply a complete explicit relation with its operands and claimed result; the reader abstains on implied operations.",
    ),
    Check(
        label="strategy_trace for count_on_from_larger",
        tool="strategy_trace",
        arguments={"strategy": "count_on_from_larger", "input": {"a": 47, "b": 28}},
        accepts=lambda value: isinstance(value, dict) and value.get("ok") is not False,
        fix="Use a strategy name and worked input from the strategy_trace tool schema; its contracts are specific to each strategy.",
    ),
)


def failure_detail(exc: Exception) -> str:
    """Keep failures actionable without exposing an implementation traceback."""
    if isinstance(exc, ToolCallError):
        detail = f"{exc.kind}: {exc}"
        if exc.worker_type:
            detail += f" ({exc.worker_type})"
        return detail
    return str(exc) or exc.__class__.__name__


def main() -> int:
    server = HermesMCPServer("core", resolve_hermes_root())
    failures = 0
    try:
        for check in CHECKS:
            try:
                value = server.call(check.tool, check.arguments)
                if not check.accepts(value):
                    raise RuntimeError("the call returned no usable result")
            except Exception as exc:
                failures += 1
                print(f"FAIL {check.label}: {failure_detail(exc)}")
                print(f"  Fix: {check.fix}")
            else:
                print(f"PASS {check.label}")
    finally:
        server.close()
    if failures:
        print(f"SELF-CHECK FAILED ({failures}/{len(CHECKS)} calls)")
        return 1
    print(f"SELF-CHECK PASSED ({len(CHECKS)}/{len(CHECKS)} calls)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
