#!/usr/bin/env python3
"""The generality suite: seven tools the model is never trained on.

This is the strongest single test in the program. A model that calls a tool
correctly from its declaration alone has learned a disposition; one that cannot
has learned twenty-one names. The seven are held out of every training row, and
they appear here in the declared menu with their real schemas, on tasks that
need them.

`prolog_query` joins the six the design named, because phase 0 showed it cannot
seed reproducible rows — a data limitation turned into a generality test rather
than left as a silent gap.

Scored on what the deployed path can check: the tool name, argument validity
against the server's own validator, and executability — whether the call comes
back with something rather than an abstention.
"""
from __future__ import annotations

import argparse
import json
import random
import sys
from pathlib import Path
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
for candidate in (str(REPO_ROOT), str(SCRIPT_DIR)):
    if candidate not in sys.path:
        sys.path.insert(0, candidate)

from chat_format import sample_menu  # noqa: E402
from dataset import RUNTIME, Call, Row, execute, now, worker_sha, write  # noqa: E402
from hermes.mcp.server import HermesMCPServer  # noqa: E402
from triples import HELD_OUT_TOOLS  # noqa: E402

DEFAULT_OUTPUT = RUNTIME / "probes" / "probe-heldout.jsonl"
MENU_SIZE = 8

ITEMS: tuple[tuple[str, str, dict[str, Any]], ...] = (
    ("Group the machines by family for me and show a few of the links between families.",
     "graph_quotient", {"view": "family", "limit": 3}),
    ("I want to see the methods bundled by the action they perform rather than by topic.",
     "graph_quotient", {"view": "action", "limit": 3}),
    ("Can you collapse the catalog down to its authored ladder and show me a few rungs?",
     "graph_quotient", {"view": "ladder", "limit": 3}),
    ("Show me the family bundles again, but start a little further down the list.",
     "graph_quotient", {"view": "family", "limit": 3, "offset": 3}),
    ("A student has committed to the claim that one half is bigger than one third. What should I ask her next?",
     "deontic_up_level", {"agent": "student", "commitments": ["one half is bigger than one third"]}),
    ("My student says the whole has to be the same size for the comparison to work. What is the next question up?",
     "deontic_up_level", {"agent": "student", "commitments": ["the whole must be the same size"]}),
    ("A child claims every fraction names a part of one. What unresolved question does that leave?",
     "deontic_up_level", {"agent": "student", "commitments": ["every fraction names a part of one"]}),
    ("What reviewed context nestings do you hold for transporting a claim from a narrow case to a broad one?",
     "incompatibility_contexts", {}),
    ("Show me only the reviewed nestings that touch the case where the written numeral order diverges from the decimal value order.",
     "incompatibility_contexts", {"context": "written_numeral_order_diverges_from_decimal_value_order"}),
    ("Which recorded errors sit closest to the one filed as choose notation as fraction?",
     "resonance_neighbors", {"name": "choose_notation_as_fraction", "k": 3}),
    ("Find the nearest recorded neighbours of the error about adding denominators on unit fractions.",
     "resonance_neighbors", {"name": "add_denominators_unit_fractions", "k": 3}),
    ("Give me a couple of errors that sit near the one about naming a fraction as parts of the total.",
     "resonance_neighbors", {"name": "add_denominators_unit_fractions", "k": 2}),
    ("Show me the first drawn scene from the deformation chart for IM-G3-U5-L1.",
     "lesson_deformation_chart_detail", {"code": "IM-G3-U5-L1", "id": "$.cells[0].deformations[0].scene"}),
    ("Pull the opening frame of that first scene in IM-G3-U5-L1's deformation chart.",
     "lesson_deformation_chart_detail", {"code": "IM-G3-U5-L1", "id": "$.cells[0].deformations[0].scene.frames[0]"}),
    ("Show me the second frame of the first deformation scene in IM-G3-U5-L1.",
     "lesson_deformation_chart_detail", {"code": "IM-G3-U5-L1", "id": "$.cells[0].deformations[0].scene.frames[1]"}),
    ("A child added one ninth and one ninth and wrote one eighteenth. What rule would build that answer?",
     "abduce_error", {"domain": "fraction", "input": "frac(1,9)-frac(1,9)", "got": "frac(1,18)"}),
    ("One student turned one quarter and one quarter into one eighth. Which rules reproduce that?",
     "abduce_error", {"domain": "fraction", "input": "frac(1,4)-frac(1,4)", "got": "frac(1,8)"}),
    ("Two fifths and one fifth came out as three tenths on this paper. What rule builds it?",
     "abduce_error", {"domain": "fraction", "input": "frac(2,5)-frac(1,5)", "got": "frac(3,10)"}),
    ("A student wrote one sixth and one sixth as one twelfth. Which rule produces that?",
     "abduce_error", {"domain": "fraction", "input": "frac(1,6)-frac(1,6)", "got": "frac(1,12)"}),
    ("List me the whole numbers from one to three straight out of the knowledge base.",
     "prolog_query", {"goal": "between(1,3,X)"}),
    ("Which loaded predicates have strategy in their name and take two arguments?",
     "prolog_query", {"name": "strategy", "arity": 2}),
    ("Show me what predicates the knowledge base loads out of the misconceptions files.",
     "prolog_query", {"file": "misconceptions", "name": "misconception"}),
)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--seed", type=int, default=31082026)
    arguments = parser.parse_args()

    rng = random.Random(arguments.seed)
    server = HermesMCPServer("core", REPO_ROOT)
    tools = list(server._public_tools)
    sha = worker_sha()
    rows: list[Row] = []
    faults: list[str] = []
    try:
        for index, (turn, name, argument_map) in enumerate(ITEMS):
            if name not in HELD_OUT_TOOLS:
                faults.append(f"{name} is not held out; it belongs in the training set")
            response, response_class = execute(
                server, Call(name=name, arguments=argument_map, response={}, response_class="result")
            )
            if response_class != "result":
                faults.append(f"item {index:02d} on {name} returned {response_class}, so it cannot test executability")
            rows.append(Row(
                id=f"heldout-{index:03d}",
                row_class="A",
                menu=[tool["name"] for tool in sample_menu(tools, [name], MENU_SIZE, rng)],
                user_turn=turn,
                calls=[Call(name, argument_map, response, response_class)],
                reply="",
                provenance={
                    "source": "authored generality item", "row": name, "cut": "heldout",
                    "kind": "held_out_tool", "executed_at": now(), "worker_sha": sha,
                    "framing": "authored",
                },
            ))
    finally:
        server.close()

    covered = sorted({row.calls[0].name for row in rows})
    missing = sorted(HELD_OUT_TOOLS - set(covered))
    if missing:
        faults.append(f"held-out tools with no item: {missing}")
    summary = {
        "path": str(arguments.output), "items": len(rows),
        "tools_covered": covered, "held_out": sorted(HELD_OUT_TOOLS), "faults": faults,
    }
    if faults:
        print(json.dumps(summary, indent=2))
        return 1
    write(rows, arguments.output)
    (arguments.output.parent / f"{arguments.output.stem}-summary.json").write_text(
        json.dumps(summary, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(summary, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
