#!/usr/bin/env python3
"""Check the local Hermes MCP path before connecting it to a client."""
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import sys
from typing import Any, Callable

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

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
    Check(
        label="incompatibility_entailments for a reviewed a-fortiori replacement",
        tool="incompatibility_entailments",
        arguments={
            "replacement": "o(context(the_expansion_repeats_periodically))",
            "replaced": "o(context(the_expansion_does_not_terminate))",
        },
        accepts=lambda value: isinstance(value, dict) and value.get("status") in {"entailed", "equivalent"} and bool(value.get("witnessing_contexts")),
        fix="Use a replacement/replaced pair that the finite live profile relation can witness; this surface is not an unrestricted consequence relation.",
    ),
    Check(
        label="incompatibility_profile for a reviewed closure context",
        tool="incompatibility_profile",
        arguments={"content": "o(context(the_expansion_repeats_periodically))"},
        accepts=lambda value: isinstance(value, dict) and bool(value.get("minimal_sets")),
        fix="Pass the exact content-term text recorded in a size-3-or-more hyperedge; binary declared seed pairs are not in this inventory.",
    ),
    Check(
        label="incompatibility_contexts returns the reviewed nesting inventory",
        tool="incompatibility_contexts",
        arguments={"context": "fraction_part_numeral_order_diverges_within_equal_integer_parts"},
        accepts=lambda value: isinstance(value, dict)
        and value.get("context_filter") == "fraction_part_numeral_order_diverges_within_equal_integer_parts"
        and value.get("count") == len(value.get("nestings", []))
        and bool(value.get("nestings")),
        fix="Use no context for the bounded full inventory or an atom named by a reviewed nesting endpoint.",
    ),
    Check(
        label="misconception_lookup retains the documented-only row gloss and status",
        tool="misconception_lookup",
        arguments={"domain": "whole_number", "source": "db_row(37492)", "limit": 1},
        accepts=lambda value: isinstance(value, dict)
        and bool(value.get("rows"))
        and bool(value["rows"][0].get("gloss"))
        and bool(value["rows"][0].get("status")),
        fix="Confirm that the worker loaded the encyclopedia citation join and that db_row(37492) remains in the registry.",
    ),
    Check(
        label="resonance_neighbors keeps distinct db_row identities",
        tool="resonance_neighbors",
        arguments={"db_row": "db_row(37492)", "k": 5},
        accepts=lambda value: isinstance(value, dict)
        and value.get("query_db_row") == "db_row(37492)"
        and len({row.get("db_row") for row in value.get("neighbors", [])}) == len(value.get("neighbors", []))
        and all(row.get("db_row") != "db_row(37492)" for row in value.get("neighbors", [])),
        fix="Use the db_row identity returned by misconception_search_rows; row names are not unique.",
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
