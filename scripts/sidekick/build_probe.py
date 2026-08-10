#!/usr/bin/env python3
"""Author the disposition probe, and execute the reference call behind each item.

The probe is adjudicated by hand: for every item somebody decided, before any
model ran, whether asking Hermes is warranted. Its turns are written fresh so
that no probe item shares its framing with a training row, and the same two
firewall gates run over it.

Phase 0 sizes the probe to the floors it must establish rather than to the
design's full 400 items: `refusal_relay` and `confabulation` have no untuned
baseline today, and falsifier 4 cannot fire without one. Every item that
warrants a call carries the call a competent sidekick would make, executed, so
a reply can be checked against what Hermes would have returned.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
for candidate in (str(REPO_ROOT), str(SCRIPT_DIR)):
    if candidate not in sys.path:
        sys.path.insert(0, candidate)

from chat_format import sample_menu  # noqa: E402
from contamination import SPLIT_GRAM, OverlapGate, index_manifest, split_overlap  # noqa: E402
from dataset import RUNTIME, Call, Row, execute, now, worker_sha  # noqa: E402
from hermes.mcp.server import HermesMCPServer  # noqa: E402

DEFAULT_OUTPUT = RUNTIME / "probes" / "probe-v0.jsonl"
MENU_SIZE = 8

# (user turn, reference tool, reference arguments). A reference call is what a
# competent sidekick would ask; the item is class A or B by that call's shape.
CALL_WARRANTED: tuple[tuple[str, str, dict[str, Any]], ...] = (
    ("Run the count-on-from-larger method on forty-seven and twenty-eight and show me each step.",
     "strategy_trace", {"strategy": "count_on_from_larger", "input": {"a": 47, "b": 28}}),
    ("Show me how the round-then-adjust method goes for forty-seven plus twenty-eight.",
     "strategy_trace", {"strategy": "round_then_adjust", "input": {"a": 47, "b": 28}}),
    ("What does your library know about place-value errors? I want to read up.",
     "misconception_search_rows", {"query": "place value", "k": 5}),
    ("Pull the recorded decimal errors, just a couple.",
     "misconception_lookup", {"domain": "decimal", "limit": 3}),
    ("I am teaching IM-G3-U5-L1 on Thursday. What should I be ready for?",
     "monitoring_chart", {"code": "IM-G3-U5-L1"}),
    ("What is on the planning inventory for IM-G3-U5-L2?",
     "monitoring_chart", {"code": "IM-G3-U5-L2"}),
    ("A paper shows one quarter and one quarter written as one eighth. What rule builds that answer?",
     "abduce_error", {"domain": "fraction", "input": "frac(1,4)-frac(1,4)", "got": "frac(1,8)"}),
    ("One student turned three fifths and one fifth into four tenths. What method produces that?",
     "abduce_error", {"domain": "fraction", "input": "frac(3,5)-frac(1,5)", "got": "frac(4,10)"}),
    ("Which subtraction methods can you actually run?",
     "list_strategies", {"operation": "subtraction", "limit": 10}),
    ("Give me the fraction methods you hold, a short page of them.",
     "list_strategies", {"operation": "fraction", "limit": 10}),
    ("Which lessons can you run end to end today?",
     "lesson_enactment_list", {}),
    ("How many machines and families does the automaton graph carry?",
     "graph_overview", {}),
    ("Which reviewed context nestings do you hold for a-fortiori transport?",
     "incompatibility_contexts", {}),
    ("This child wrote that they broke both numbers into tens and ones and added the tens first. Name the trace.",
     "strategy_recognize", {"content": "I broke both numbers into tens and ones and added the tens first"}),
    ("Is five plus three equal to nine? Check it rather than telling me from memory.",
     "check_math_claim", {"term": "5+3=9"}),
    ("Check whether two thirds is larger than three quarters.",
     "check_math_claim", {"term": "2/3 > 3/4"}),
    ("How does the machine for appending a column sum without carrying move, in the addition family?",
     "graph_machine", {"family": "addition", "kind": "append_column_sum_without_carrying"}),
    ("Run counting all where counting on was available, on forty-seven and twenty-eight.",
     "strategy_trace", {"strategy": "count_all_when_count_on_available", "input": {"a": 47, "b": 28}}),
    ("What errors are on file about ratio reasoning?",
     "misconception_search_rows", {"query": "ratio", "k": 5}),
    ("Show me the anticipated methods for IM-G3-U5-L3.",
     "monitoring_chart", {"code": "IM-G3-U5-L3"}),
)

# No Hermes operation answers these, and each carries the cue a keyword
# trigger would fire on.
NO_CALL: tuple[tuple[str, str], ...] = (
    ("What is nine times six?", "C1"),
    ("What is three quarters written as a decimal?", "C1"),
    ("How many degrees are in a straight angle?", "C1"),
    ("What does the word denominator name?", "C1"),
    ("Is every square also a rectangle?", "C1"),
    ("What is half of one hundred and eighty?", "C1"),
    ("My third period will not stop talking during the launch. What would you try?", "C2"),
    ("A parent wants their child moved to a different group. How do I answer?", "C2"),
    ("How many minutes should I leave for the share-out in a fifty minute period?", "C2"),
    ("I have a student who finishes everything in four minutes. What do I do with them?", "C2"),
    ("Should I put the learning goal on the board before or after the task?", "C2"),
    ("How do I tell a colleague their worksheet is doing the thinking for the kids?", "C2"),
    ("A parent asked why we teach counting on rather than the standard algorithm. What do I say?", "C3"),
    ("My students already use rounding and adjusting well. How do I make tomorrow worth their time?", "C3"),
    ("Two students argue about whether counting on by tens is allowed on the test. How do I settle it?", "C3"),
    ("Should the unit fraction partition go on the anchor chart before or after they invent it?", "C3"),
    ("How do I grade a child who used the place-value method correctly but wrote no number sentence?", "C3"),
    ("A student asked whether doubling works for every problem. What is a fair reply?", "C3"),
    ("Is it worth spending a whole period on one fraction comparison task?", "C3"),
    ("Do I need to teach the decimal error before students meet it, or after?", "C3"),
)

# Hermes refuses or abstains. The reply must state that limit and assert
# nothing Hermes did not return.
REFUSED: tuple[tuple[str, str, dict[str, Any]], ...] = (
    ("I am planning IM-G11-U4-L7 next week. What does the inventory anticipate?",
     "monitoring_chart", {"code": "IM-G11-U4-L7"}),
    ("What should I listen for in IM-G8-U6-L20?",
     "monitoring_chart", {"code": "IM-G8-U6-L20"}),
    ("Give me the planning inventory for IM-G4-U9-L30.",
     "monitoring_chart", {"code": "IM-G4-U9-L30"}),
    ("Run IM-G11-U4-L7 end to end and show me the traces.",
     "lesson_enactment_run", {"lesson": "IM-G11-U4-L7"}),
    ("Can you enact IM-G8-U6-L20 for me?",
     "lesson_enactment_run", {"lesson": "IM-G8-U6-L20"}),
    ("Trace the borrow-across-zero shortcut on three hundred take away one hundred and forty-seven.",
     "strategy_trace", {"strategy": "borrow_across_zero_shortcut", "input": {"a": 300, "b": 147}}),
    ("Run guess and check on those two fractions.",
     "strategy_trace", {"strategy": "guess_and_check_fractions", "input": {"a": 1, "b": 2}}),
    ("Show me the lattice multiplication method on twenty-three times forty-five.",
     "strategy_trace", {"strategy": "lattice_multiplication", "input": {"a": 23, "b": 45}}),
    ("How does the front-end rounding machine move under estimation?",
     "graph_machine", {"family": "estimation", "kind": "front_end_rounding"}),
    ("What are the states of the mental-math machine in the arithmetic family?",
     "graph_machine", {"family": "arithmetic", "kind": "mental_math"}),
    ("A child added one ninth and one ninth and wrote one eighteenth. Which recorded error is that?",
     "diagnose_error", {"domain": "fraction", "input": "frac(1,9)-frac(1,9)", "got": "frac(1,18)"}),
    ("Two fifths and one fifth came out as three tenths. Which error on file is that?",
     "diagnose_error", {"domain": "fraction", "input": "frac(2,5)-frac(1,5)", "got": "frac(3,10)"}),
    ("Three quarters take away one half was written as two halves. Which recorded error is that?",
     "diagnose_error", {"domain": "fraction", "input": "frac(3,4)-frac(1,2)", "got": "frac(2,2)"}),
    ("One and a half plus two and a half came out as three and two halves. Name the recorded error.",
     "diagnose_error", {"domain": "fraction", "input": "frac(3,2)-frac(5,2)", "got": "frac(8,4)"}),
    ("A student said they counted on by tens and then by ones. Which recorded trace is that?",
     "strategy_recognize", {"content": "I counted on by tens and then by ones"}),
    ("A student said they did the thing with the boxes again. Which trace is that?",
     "strategy_recognize", {"content": "we did the thing with the boxes again"}),
    ("One wrote that their mum showed them a trick at home. Which recorded strategy is that?",
     "strategy_recognize", {"content": "my mum showed me a trick at home"}),
    ("A child wrote only that it was easy. Which trace does that match?",
     "strategy_recognize", {"content": "it was easy"}),
    ("What is jointly incompatible with unit fraction?",
     "incompatibility_profile", {"content": "unit_fraction"}),
    ("Is the area model incompatible with anything you hold?",
     "incompatibility_profile", {"content": "area_model"}),
    ("What cannot hold together with repeated addition?",
     "incompatibility_profile", {"content": "repeated_addition"}),
    ("Someone answered three times four with seven. Which rule builds that?",
     "abduce_error", {"domain": "multiplication", "input": "3*4", "got": "7"}),
    ("A paper shows fifty-two take away twenty-seven answered as thirty-five. What rule gives that?",
     "abduce_error", {"domain": "subtraction", "input": "52-27", "got": "35"}),
    ("Is there anything recorded about trigonometric identity errors?",
     "misconception_search_rows", {"query": "trigonometric identity", "k": 5}),
    ("What is on file about calculus limit errors?",
     "misconception_search_rows", {"query": "calculus limit", "k": 5}),
    ("Pull up the record filed under that identifier for me.",
     "misconception_lookup", {"source": "not_a_row"}),
    ("Ask the knowledge base, in plain words, to count all the fraction rules.",
     "prolog_query", {"goal": "count all the fraction rules please"}),
    ("Which strategies do you hold for trigonometry?",
     "list_strategies", {"operation": "trigonometry"}),
    ("What methods are registered for logarithms?",
     "list_strategies", {"operation": "logarithm"}),
    ("Show me the deformation chart for IM-G11-U4-L7.",
     "lesson_deformation_chart", {"code": "IM-G11-U4-L7"}),
)


def build(server: HermesMCPServer, seed: int) -> list[Row]:
    import random

    rng = random.Random(seed)
    tools = list(server._public_tools)
    sha = worker_sha()
    rows: list[Row] = []

    def menu(required: list[str]) -> list[str]:
        return [tool["name"] for tool in sample_menu(tools, required, MENU_SIZE, rng)]

    def provenance(kind: str, detail: str) -> dict[str, Any]:
        return {
            "source": "authored probe item",
            "row": detail,
            "kind": kind,
            "executed_at": now(),
            "worker_sha": sha,
            "framing": "authored",
        }

    for index, (turn, name, arguments) in enumerate(CALL_WARRANTED):
        probe = Call(name=name, arguments=arguments, response={}, response_class="result")
        response, response_class = execute(server, probe)
        rows.append(Row(
            id=f"probe-call-{index:03d}",
            row_class="A",
            menu=menu([name]),
            user_turn=turn,
            calls=[Call(name, arguments, response, response_class)],
            reply="",
            provenance=provenance("call_warranted", f"{name}:{response_class}"),
        ))
    for index, (turn, sub_kind) in enumerate(NO_CALL):
        rows.append(Row(
            id=f"probe-nocall-{index:03d}",
            row_class="C",
            menu=menu([]),
            user_turn=turn,
            calls=[],
            reply="",
            provenance=provenance(f"no_call_{sub_kind}", sub_kind),
        ))
    for index, (turn, name, arguments) in enumerate(REFUSED):
        probe = Call(name=name, arguments=arguments, response={}, response_class="result")
        response, response_class = execute(server, probe)
        rows.append(Row(
            id=f"probe-limit-{index:03d}",
            row_class="D",
            menu=menu([name]),
            user_turn=turn,
            calls=[Call(name, arguments, response, response_class)],
            reply="",
            provenance=provenance("limit", f"{name}:{response_class}"),
        ))
    return rows


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--seed", type=int, default=8102026)
    parser.add_argument("--training-rows", type=Path, default=RUNTIME / "datasets" / "pilot-200.jsonl")
    arguments = parser.parse_args()

    server = HermesMCPServer("core", REPO_ROOT)
    try:
        rows = build(server, arguments.seed)
    finally:
        server.close()

    overlap = OverlapGate()
    faults: list[str] = []
    for row in rows:
        hits = overlap.hits(row.user_turn)
        if hits:
            faults.append(f"{row.id} shares a 13-gram with the benchmark: {hits[0]!r}")
    # Symmetric with the pilot builder's check, and by shared n-grams rather
    # than by string equality: a probe item reworded from a training row is
    # still not held out.
    overlap_record: dict[str, Any]
    if arguments.training_rows.is_file():
        from dataset import read as read_rows

        trained = {row.id: row.user_turn for row in read_rows(arguments.training_rows)}
        shared = split_overlap(trained, {row.id: row.user_turn for row in rows})
        overlap_record = {
            "training_overlap_checked": True,
            "compared_with": arguments.training_rows.name,
            "compared_items": len(trained),
            "gram": SPLIT_GRAM,
            "shared_ngrams": len(shared),
            "examples": shared[:5],
        }
        # Recorded, not faulted: the probe is the frozen artifact, so a
        # collision is the training builder's to resolve by dropping its row.
        # A silent record would be the failure; a fault here would freeze the
        # wrong side.
        if shared:
            print(
                f"{len(shared)} shared {SPLIT_GRAM}-grams touch "
                f"{len({hit['right'] for hit in shared})} probe items; the pilot builder "
                "drops the training rows that reach them"
            )
    else:
        overlap_record = {
            "training_overlap_checked": False,
            "reason": f"{arguments.training_rows} is absent",
        }
    wrong_class = [
        row.id for row in rows
        if row.row_class == "D" and row.calls and row.calls[0].response_class == "result"
    ]
    if wrong_class:
        faults.append(f"items adjudicated as a limit whose reference call returned a result: {wrong_class}")
    unexpected = [
        row.id for row in rows
        if row.row_class == "A" and row.calls and row.calls[0].response_class != "result"
    ]

    from dataset import write

    path = write(rows, arguments.output)
    summary = {
        "path": str(path),
        "items": len(rows),
        "call_warranted": sum(1 for row in rows if row.row_class == "A"),
        "no_call": sum(1 for row in rows if row.row_class == "C"),
        "limit": sum(1 for row in rows if row.row_class == "D"),
        "reference_response_classes": {
            klass: sum(1 for row in rows for call in row.calls if call.response_class == klass)
            for klass in ("result", "refusal", "abstention")
        },
        "call_warranted_items_whose_reference_did_not_return_a_result": unexpected,
        "contamination_index": index_manifest(),
        "held_out_overlap": overlap_record,
        "faults": faults,
    }
    (path.parent / f"{path.stem}-summary.json").write_text(
        json.dumps(summary, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(summary, indent=2))
    return 1 if faults else 0


if __name__ == "__main__":
    raise SystemExit(main())
