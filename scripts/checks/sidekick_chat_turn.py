#!/usr/bin/env python3
"""Scripted end-to-end turns through the sidekick engine, no socket, no model.

The Completer seam exists exactly so this check can run in the sandbox: a
scripted fake stands in for llama-server (the sandbox forbids socket binding;
scripts/checks/route_behavior.py:1-6 records why), while the MCP server, the
argument validator, tool execution, and the three-way response classification
are all live. The first scenario boots a Prolog worker and can take ~11 s.
"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from hermes.app.sidekick_llm import ClientResult  # noqa: E402
from hermes.app.sidekick_turn import run_turn  # noqa: E402
from hermes.app.system_prompts import load_required_system_prompts  # noqa: E402
from hermes.mcp.server import HermesMCPServer  # noqa: E402


def reply(text: str) -> ClientResult:
    return ClientResult(outcome="ok", message={"content": text})


def tool_call(name: str, arguments: dict, content: str = "") -> ClientResult:
    return ClientResult(outcome="ok", message={
        "content": content,
        "tool_calls": [{"id": "call_0",
                        "function": {"name": name, "arguments": dict(arguments)}}],
    })


def tool_calls(*pairs: tuple[str, dict]) -> ClientResult:
    return ClientResult(outcome="ok", message={
        "content": "",
        "tool_calls": [
            {"id": f"call_{index}", "function": {"name": name, "arguments": dict(args)}}
            for index, (name, args) in enumerate(pairs)
        ],
    })


def offline() -> ClientResult:
    return ClientResult(outcome="transport_error", error="URLError: connection refused")


class FakeCompleter:
    def __init__(self, scripted: list[ClientResult]) -> None:
        self.scripted = list(scripted)
        self.calls: list[dict] = []

    def __call__(self, messages, tools, max_tokens) -> ClientResult:
        self.calls.append({"messages": messages, "tools": tools, "max_tokens": max_tokens})
        if not self.scripted:
            raise AssertionError("the scenario scripted too few completions")
        return self.scripted.pop(0)


def check(name: str, condition: bool, detail: str = "") -> bool:
    if not condition:
        print(f"FAIL {name}: {detail}", file=sys.stderr)
    else:
        print(f"pass {name}")
    return condition


def main() -> int:
    prompts = load_required_system_prompts()
    mcp = HermesMCPServer("core", ROOT)
    names = frozenset()
    passes = []

    # S1 routed hit: the router selects check_math_claim; the scripted call
    # is correct; the class is result; a final reply is composed.
    fake = FakeCompleter([
        tool_call("check_math_claim", {"term": "1/2 = 2/4"}),
        reply("The class wrote an equivalence the knowledge base also records."),
    ])
    turn = run_turn("Is it true that 1/2 = 2/4?", "routed", fake, mcp, prompts, names)
    row = turn.calls[0] if turn.calls else {}
    passes.append(check(
        "S1_routed_hit",
        turn.route == {"intent": "explicit_claim", "tool": "check_math_claim"}
        and row.get("tool") == "check_math_claim"
        and row.get("executed") is True
        and row.get("response_class") == "result"
        and row.get("arguments") == {"term": "1/2 = 2/4"}
        and turn.fallback is None
        and turn.reply.startswith("The class wrote"),
        f"route={turn.route} calls={turn.calls[:1]} fallback={turn.fallback} reply={turn.reply!r}",
    ))

    # S2 routed no-call: two scripted no-call turns, then the grounding-block
    # fallback; the grounding calls appear labeled chooser=route.
    fake = FakeCompleter([
        reply("I think the fractions look the same."),
        reply("They are the same."),
        reply("The knowledge base carries an entry for this comparison."),
    ])
    turn = run_turn("Is it true that 1/2 = 2/4?", "routed", fake, mcp, prompts, names)
    grounding = [row for row in turn.calls if row["chooser"] == "route" and row["executed"]]
    passes.append(check(
        "S2_routed_no_call",
        (turn.fallback or {}).get("kind") == "no_call"
        and {row["tool"] for row in grounding}
            == {"commitment_match", "misconception_search_rows"},
        f"fallback={turn.fallback} grounding={[r['tool'] for r in grounding]}",
    ))

    # S3 refusal + one stated-correction retry carrying the validator's
    # message; a second bad call ends in refusal_after_retry and the reply
    # names the refusal without asserting a verdict.
    fake = FakeCompleter([
        tool_call("check_math_claim", {"claim": "1/2 = 2/4"}),
        tool_call("check_math_claim", {"claim": "1/2 equals 2/4"}),
    ])
    turn = run_turn("Is it true that 1/2 = 2/4?", "routed", fake, mcp, prompts, names)
    correction_turn = fake.calls[1]["messages"][-1] if len(fake.calls) > 1 else {}
    refusals = [row for row in turn.calls if row.get("response_class") == "refusal"]
    passes.append(check(
        "S3_refusal_retry",
        (turn.fallback or {}).get("kind") == "refusal_after_retry"
        and len(refusals) == 2
        and "invalid argument key" in str(correction_turn.get("content", ""))
        and "did not accept" in turn.reply,
        f"fallback={turn.fallback} refusals={len(refusals)} "
        f"correction={str(correction_turn.get('content', ''))[:120]!r} reply={turn.reply!r}",
    ))

    # S4 abstention honesty: the tool abstains; a final reply that states no
    # limit is replaced by the deterministic abstention sentence.
    fake = FakeCompleter([
        tool_call("misconception_search_rows", {"query": "quixotic zebra nonesuch", "k": 5}),
        reply("Students mix this up in interesting ways all the time."),
    ])
    turn = run_turn(
        "What misconceptions show up with quixotic zebra nonesuch?",
        "routed", fake, mcp, prompts, names,
    )
    executed = [row for row in turn.calls if row["executed"]]
    passes.append(check(
        "S4_abstention_stated",
        executed and executed[0]["response_class"] == "abstention"
        and (turn.fallback or {}).get("kind") == "abstention_unstated"
        and turn.rejected_reply is not None
        and "returned nothing" in turn.reply,
        f"classes={[r['response_class'] for r in executed]} fallback={turn.fallback} "
        f"reply={turn.reply!r}",
    ))

    # S5 model-chooses round bound: three emitted calls; exactly two execute;
    # the third is recorded dropped.
    fake = FakeCompleter([
        tool_calls(
            ("list_strategies", {"limit": 5}),
            ("misconception_search_rows", {"query": "counting order", "k": 3}),
            ("check_math_claim", {"term": "1+1=2"}),
        ),
        reply("The knowledge base lists strategies and no misconception matched."),
    ])
    turn = run_turn("Show me around the knowledge base.", "model", fake, mcp, prompts, names)
    executed = [row for row in turn.calls if row["executed"]]
    dropped = [row for row in turn.calls if not row["executed"]]
    passes.append(check(
        "S5_round_bound",
        len(executed) == 2 and len(dropped) == 1
        and dropped[0]["dropped_reason"] == "round_bound"
        and dropped[0]["tool"] == "check_math_claim",
        f"executed={[r['tool'] for r in executed]} dropped={dropped}",
    ))

    # S6 model-chooses declines: no call in round 1; the reply stands and the
    # declination is flagged with an empty call list.
    fake = FakeCompleter([
        reply("Counting on from the larger addend saves steps."),
    ])
    turn = run_turn("Any thought on counting on?", "model", fake, mcp, prompts, names)
    passes.append(check(
        "S6_model_declined",
        "model_declined_consult" in turn.flags and turn.calls == []
        and turn.reply.startswith("Counting on"),
        f"flags={turn.flags} calls={turn.calls} reply={turn.reply!r}",
    ))

    # S7 unsafe reply: puffery in the final turn is replaced by a
    # deterministic substitute and the original is preserved.
    fake = FakeCompleter([
        tool_call("check_math_claim", {"term": "1/2 = 2/4"}),
        reply("Wonderful! Amazing work, the claim is fantastic and checks out perfectly!"),
    ])
    turn = run_turn("Is it true that 1/2 = 2/4?", "routed", fake, mcp, prompts, names)
    passes.append(check(
        "S7_reply_unsafe",
        (turn.fallback or {}).get("kind") == "reply_unsafe"
        and turn.rejected_reply is not None
        and "Wonderful" in turn.rejected_reply
        and "Wonderful" not in turn.reply,
        f"fallback={turn.fallback} reply={turn.reply!r} rejected={turn.rejected_reply!r}",
    ))

    # S8 offline: a transport failure on the first model call falls back to
    # the knowledge-base answer; no exception escapes.
    fake = FakeCompleter([offline()])
    turn = run_turn("Is it true that 1/2 = 2/4?", "routed", fake, mcp, prompts, names)
    passes.append(check(
        "S8_model_offline",
        (turn.fallback or {}).get("kind") == "model_offline"
        and "local model is not running" in turn.reply
        and turn.reply.strip() != "",
        f"fallback={turn.fallback} reply={turn.reply[:120]!r}",
    ))

    mcp.close()
    if all(passes):
        print(f"PASS sidekick chat turn: {len(passes)} scripted scenarios "
              "against a live MCP server")
        return 0
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
