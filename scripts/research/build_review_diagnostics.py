#!/usr/bin/env python3
"""Derive review defects in corpus-binding proposals from the live inputs.

The proposal generator scored only signatures without an existing binding.
Review needs the omitted comparison as well as two structural checks that can
be made directly from the proposal file.  This script writes those derivations
for the Prolog queue; it does not change the proposal file or the research
database.
"""
from __future__ import annotations

import argparse
import collections
import json
import sqlite3
from pathlib import Path
from typing import Any

import map_corpus_to_automata as mapper

ROOT = Path(__file__).resolve().parents[2]
PROPOSALS = ROOT / "data/research/corpus_binding_proposals.json"
DEFAULT_OUTPUT = ROOT / "data/research/corpus_binding_diagnostics.json"


def candidate_identity(proposal: dict[str, Any]) -> str:
    machine = f"{proposal['family']}/{proposal['signature']}"
    return (
        f"corpus_candidate:{proposal['row_type']}:{proposal['row_id']}:{machine}"
    )


def _fan_surplus(proposals: list[dict[str, Any]]) -> set[int]:
    by_row: dict[tuple[str, int], list[tuple[int, dict[str, Any]]]] = (
        collections.defaultdict(list)
    )
    for index, proposal in enumerate(proposals):
        by_row[(proposal["row_type"], proposal["row_id"])].append(
            (index, proposal)
        )

    surplus: set[int] = set()
    for candidates in by_row.values():
        ranked = sorted(
            candidates,
            key=lambda item: (-float(item[1]["score"]), item[0]),
        )
        surplus.update(index for index, _proposal in ranked[1:])
    return surplus


def derive(root: Path = ROOT) -> dict[str, Any]:
    proposal_path = root / PROPOSALS.relative_to(ROOT)
    data = json.loads(proposal_path.read_text(encoding="utf-8"))
    proposals = data["proposals"]

    database = root / mapper.DB.relative_to(mapper.ROOT)
    connection = sqlite3.connect(f"file:{database}?mode=ro", uri=True)
    try:
        rows = {
            (row["row_type"], row["row_id"]): row
            for row in mapper.corpus_rows(connection)
        }
        bound = {
            (operation, kind)
            for operation, kind in connection.execute(
                """
                SELECT DISTINCT operation, kind
                  FROM automaton_instance_bindings
                """
            )
        }
    finally:
        connection.close()

    vocabulary = mapper.signature_vocabulary()
    ties = {
        index
        for index, proposal in enumerate(proposals)
        if float(proposal["score"]) == float(proposal["runner_up_score"])
    }
    fan_surplus = _fan_surplus(proposals)
    displacements: dict[int, list[dict[str, Any]]] = {}

    for index, proposal in enumerate(proposals):
        row = rows[(proposal["row_type"], proposal["row_id"])]
        better: list[dict[str, Any]] = []
        for family, signature in sorted(bound):
            terms = vocabulary.get((family, signature))
            if terms is None or not mapper.domain_agrees(row["domain"], family):
                continue
            score, evidence = mapper.score(row["text"], terms[0], terms[1])
            if score > float(proposal["score"]):
                better.append(
                    {
                        "machine": f"{family}/{signature}",
                        "score": round(score, 2),
                        "evidence": evidence[:12],
                    }
                )
        if better:
            displacements[index] = sorted(
                better, key=lambda item: (-item["score"], item["machine"])
            )

    displaced = set(displacements)
    affected = ties | displaced | fan_surplus
    clean_signatures = {
        (proposal["family"], proposal["signature"])
        for index, proposal in enumerate(proposals)
        if index not in affected
    }

    diagnostics: list[dict[str, Any]] = []
    for index, proposal in enumerate(proposals):
        defects: list[dict[str, Any]] = []
        if index in ties:
            defects.append(
                {
                    "kind": "score_tie",
                    "reason": (
                        "The proposal tied the runner-up score, so the scoring "
                        "evidence did not prefer this signature."
                    ),
                }
            )
        if index in displaced:
            better = displacements[index]
            defects.append(
                {
                    "kind": "displacement",
                    "reason": (
                        "An already-bound signature scores higher for this row. "
                        "The proposal generator did not compare against it."
                    ),
                    "better_bound_candidates": better,
                }
            )
        if index in fan_surplus:
            defects.append(
                {
                    "kind": "fan_surplus",
                    "reason": (
                        "This corpus row was proposed for several signatures; "
                        "a higher-ranked proposal already uses the same row."
                    ),
                }
            )
        signature = (proposal["family"], proposal["signature"])
        diagnostics.append(
            {
                "identity": candidate_identity(proposal),
                "reviewable": index not in affected,
                "signature_has_clean_candidate": signature in clean_signatures,
                "defects": defects,
            }
        )

    return {
        "schema_version": 1,
        "source": str(PROPOSALS.relative_to(ROOT)),
        "method": (
            "score ties from proposal scores; displacement by rescoring each row "
            "against every domain-compatible already-bound signature; fan surplus "
            "by retaining the highest-scoring proposal for each corpus row"
        ),
        "counts": {
            "proposals": len(proposals),
            "score_ties": len(ties),
            "displacements": len(displaced),
            "fan_surplus": len(fan_surplus),
            "affected_union": len(affected),
            "clean_proposals": len(proposals) - len(affected),
            "reviewable_signatures": len(clean_signatures),
        },
        "diagnostics": diagnostics,
    }


def render(payload: dict[str, Any]) -> str:
    return json.dumps(payload, indent=1, sort_keys=True) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    payload = derive()
    output = args.output
    rendered = render(payload)
    if args.check:
        if not output.exists() or output.read_text(encoding="utf-8") != rendered:
            raise SystemExit(f"{output} is stale; regenerate it with this script")
    else:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(rendered, encoding="utf-8")

    counts = payload["counts"]
    print(
        "review diagnostics: "
        f"ties={counts['score_ties']}, "
        f"displacements={counts['displacements']}, "
        f"fan-surplus={counts['fan_surplus']}, "
        f"union={counts['affected_union']}, "
        f"clean={counts['clean_proposals']}, "
        f"signatures={counts['reviewable_signatures']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
