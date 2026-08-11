#!/usr/bin/env python3
"""Freeze the disposition probe, and execute the reference call behind each item.

The probe is adjudicated by hand: for every item somebody decided, before any
model ran, whether asking Hermes is warranted. Its turns are written fresh so
that no probe item shares its framing with a training row, and the same two
firewall gates run over it.

Probe-v1 carries two cuts and labels every item with its own. `explicit` asks
for an operation in all but name; `implicit` describes a classroom event and
asks a pedagogical question. They measure different competences, so they are
reported apart and pooling them is refused at the reporting end.

Execution adjudicates. An item filed as a limit whose reference call returns a
result is a mis-adjudication, and the builder refuses to write rather than
shipping the probe with it.
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
from contamination import SPLIT_GRAM, OverlapGate, index_manifest, split_overlap  # noqa: E402
from dataset import RUNTIME, Call, Row, execute, now, worker_sha, write  # noqa: E402
from hermes.mcp.server import HermesMCPServer  # noqa: E402
from probe_items import EXPLICIT_CALL, IMPLICIT_CALL, LIMIT, NO_CALL  # noqa: E402

DEFAULT_OUTPUT = RUNTIME / "probes" / "probe-v1.jsonl"
MENU_SIZE = 8


def build(server: HermesMCPServer, seed: int) -> tuple[list[Row], list[str]]:
    rng = random.Random(seed)
    tools = list(server._public_tools)
    sha = worker_sha()
    rows: list[Row] = []
    faults: list[str] = []

    def menu(required: list[str]) -> list[str]:
        return [tool["name"] for tool in sample_menu(tools, required, MENU_SIZE, rng)]

    def provenance(cut: str, kind: str, detail: str) -> dict[str, Any]:
        return {
            "source": "authored probe item",
            "row": detail,
            "cut": cut,
            "kind": kind,
            "executed_at": now(),
            "worker_sha": sha,
            "framing": "authored",
        }

    def call_items(items: Any, cut: str, prefix: str) -> None:
        for index, (turn, name, arguments) in enumerate(items):
            response, response_class = execute(
                server, Call(name=name, arguments=arguments, response={}, response_class="result")
            )
            if response_class != "result":
                faults.append(
                    f"{prefix}-{index:03d} is adjudicated as call-warranted but its reference "
                    f"{name} call returned {response_class}"
                )
            rows.append(Row(
                id=f"{prefix}-{index:03d}",
                row_class="A",
                menu=menu([name]),
                user_turn=turn,
                calls=[Call(name, arguments, response, response_class)],
                reply="",
                provenance=provenance(cut, "call_warranted", f"{name}:{response_class}"),
            ))

    call_items(EXPLICIT_CALL, "explicit", "probe-explicit")
    call_items(IMPLICIT_CALL, "implicit", "probe-implicit")

    for index, (turn, sub_kind) in enumerate(NO_CALL):
        rows.append(Row(
            id=f"probe-nocall-{index:03d}",
            row_class="C",
            menu=menu([]),
            user_turn=turn,
            calls=[],
            reply="",
            provenance=provenance("no_call", f"no_call_{sub_kind}", sub_kind),
        ))

    for index, (turn, name, arguments) in enumerate(LIMIT):
        response, response_class = execute(
            server, Call(name=name, arguments=arguments, response={}, response_class="result")
        )
        if response_class == "result":
            faults.append(
                f"probe-limit-{index:03d} is adjudicated as a limit but its reference "
                f"{name} call returned a result"
            )
        rows.append(Row(
            id=f"probe-limit-{index:03d}",
            row_class="D",
            menu=menu([name]),
            user_turn=turn,
            calls=[Call(name, arguments, response, response_class)],
            reply="",
            provenance=provenance("limit", "limit", f"{name}:{response_class}"),
        ))
    return rows, faults


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--seed", type=int, default=8102026)
    parser.add_argument("--training-rows", type=Path, default=RUNTIME / "datasets" / "sidekick-6000.jsonl")
    arguments = parser.parse_args()

    server = HermesMCPServer("core", REPO_ROOT)
    try:
        rows, faults = build(server, arguments.seed)
    finally:
        server.close()

    overlap = OverlapGate()
    for row in rows:
        hits = overlap.hits(row.user_turn)
        if hits:
            faults.append(f"{row.id} shares a 13-gram with the benchmark: {hits[0]!r}")

    # Recorded, not faulted: the probe is the frozen artifact, so a collision is
    # the training builder's to resolve by dropping its row. A silent record
    # would be the failure; a fault here would freeze the wrong side.
    if arguments.training_rows.is_file():
        from dataset import read as read_rows

        trained = {row.id: row.user_turn for row in read_rows(arguments.training_rows)}
        shared = split_overlap(trained, {row.id: row.user_turn for row in rows})
        overlap_record: dict[str, Any] = {
            "training_overlap_checked": True,
            "compared_with": arguments.training_rows.name,
            "compared_items": len(trained),
            "gram": SPLIT_GRAM,
            "shared_ngrams": len(shared),
            "examples": shared[:5],
        }
        if shared:
            print(
                f"{len(shared)} shared {SPLIT_GRAM}-grams touch "
                f"{len({hit['right'] for hit in shared})} probe items; the training builder "
                "drops the rows that reach them"
            )
    else:
        overlap_record = {
            "training_overlap_checked": False,
            "reason": f"{arguments.training_rows} is absent, so no training set exists to compare",
        }

    by_cut: dict[str, int] = {}
    for row in rows:
        by_cut[row.provenance["cut"]] = by_cut.get(row.provenance["cut"], 0) + 1
    summary = {
        "path": str(arguments.output),
        "items": len(rows),
        "cuts": by_cut,
        "pooling": "the explicit and implicit cuts are reported apart; a pooled number tracks the authoring mix",
        "reference_response_classes": {
            klass: sum(1 for row in rows for call in row.calls if call.response_class == klass)
            for klass in ("result", "refusal", "abstention")
        },
        "contamination_index": index_manifest(),
        "held_out_overlap": overlap_record,
        "faults": faults,
    }
    if faults:
        print(json.dumps(summary, indent=2))
        print(f"REFUSED: {len(faults)} items disagree with what the worker returned")
        return 1
    path = write(rows, arguments.output)
    (path.parent / f"{path.stem}-summary.json").write_text(
        json.dumps(summary, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(summary, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
