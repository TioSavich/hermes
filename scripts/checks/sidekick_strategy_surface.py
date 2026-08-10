#!/usr/bin/env python3
"""The two strategy-name surfaces must name the same strategies.

`strategy_trace` declares its accepted names as a `oneOf` of consts read from
`automaton_input_contracts.pl`. `list_strategies` serves names read from the
worker's own catalog. Today those sets are identical, and nothing in the tree
makes them so: they come from different readers over different stores. A
caller told to discover names through `list_strategies` and run them through
`strategy_trace` depends on that identity, so it is asserted here rather than
assumed, and drift fails loudly instead of returning a not-covered refusal to
a name the discovery step had just offered.

The paging contract is checked in the same pass, because a discovery step that
silently truncates is a discovery step that hides names.
"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from hermes.mcp.server import HermesMCPServer, ToolCallError  # noqa: E402


def main() -> int:
    server = HermesMCPServer("core", ROOT)
    try:
        declared = {
            entry["const"]
            for tool in server._public_tools
            if tool["name"] == "strategy_trace"
            for entry in tool["inputSchema"]["properties"]["strategy"]["oneOf"]
        }
        served: set[str] = set()
        offset, pages = 0, 0
        while True:
            page = server.call("list_strategies", {"limit": 100, "offset": offset})
            served.update(row["name"] for row in page["strategies"])
            pages += 1
            if not page["has_more"]:
                break
            offset += len(page["strategies"])
            assert pages < 20, "list_strategies paging did not terminate"

        only_declared = sorted(declared - served)
        only_served = sorted(served - declared)
        assert not only_declared, (
            f"{len(only_declared)} names are declared by strategy_trace and never served by "
            f"list_strategies, so discovery cannot reach them: {only_declared[:5]}"
        )
        assert not only_served, (
            f"{len(only_served)} names are served by list_strategies and rejected by "
            f"strategy_trace, so discovery would hand out unusable names: {only_served[:5]}"
        )
        assert served, "list_strategies served no name at all"

        first = server.call("list_strategies", {"limit": 5})
        assert first["has_more"] is True, "a five-name page of 246 reports no more"
        assert len(first["strategies"]) == 5, "limit was not honoured"
        last = server.call("list_strategies", {"limit": 100, "offset": len(served) - 1})
        assert last["has_more"] is False, "the final page reports more"

        for arguments, why in (
            ({"operation": "trigonometry"}, "an operation with no strategy"),
            ({"contains": "zzzznotaname"}, "a substring matching no name"),
        ):
            try:
                server.call("list_strategies", arguments)
            except ToolCallError as refusal:
                assert refusal.kind == "not_covered", f"{why} refused as {refusal.kind}"
            else:
                raise AssertionError(f"{why} returned a page instead of a limit")

        for arguments in ({"limit": "many"}, {"limit": 0}, {"limit": 500}, {"offset": -1}):
            try:
                server.call("list_strategies", dict(arguments))
            except ToolCallError as refusal:
                assert refusal.kind == "malformed_input", f"{arguments} refused as {refusal.kind}"
            else:
                raise AssertionError(f"{arguments} was accepted as paging")
    finally:
        server.close()

    print(
        f"PASS sidekick strategy surface: list_strategies and strategy_trace name the same "
        f"{len(served)} strategies; paging reports has_more, and both filters refuse a miss "
        "as not_covered"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
