#!/usr/bin/env python3
"""Byte, schema, count, and static-page gate for the full automata graph."""
from __future__ import annotations

import json
import re
import subprocess
import sys
import tempfile
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RESEARCH_SCRIPTS = ROOT / "scripts/research"
sys.path.insert(0, str(RESEARCH_SCRIPTS))

from build_full_graph_json import (  # noqa: E402
    LEVEL_BY_FAMILY,
    OUTPUT,
    REVIEW_STATUSES,
    UNREVIEWED_STATUSES,
    VALIDITY_MODES,
    generate_json,
)
from build_machine_typology import parse_transition_tables  # noqa: E402


PAGE = ROOT / "docs/research/automata-graph.html"
HUB = ROOT / "docs/research/2026-08-03-automata-compendium.html"
TOKENS = ROOT / "hermes/web/hermes-tokens.css"


def fail_if(condition: bool, message: str, failures: list[str]) -> None:
    if condition:
        failures.append(message)


def main() -> int:
    failures: list[str] = []
    expected = generate_json()
    fail_if(expected != generate_json(), "full-graph rebuild is not deterministic", failures)
    if not OUTPUT.exists():
        failures.append(f"missing generated artifact: {OUTPUT.relative_to(ROOT)}")
    elif OUTPUT.read_text(encoding="utf-8") != expected:
        failures.append(f"stale generated artifact: {OUTPUT.relative_to(ROOT)}")

    data = json.loads(expected)
    machines = parse_transition_tables()
    nodes = data.get("nodes", [])
    edges = data.get("edges", [])
    borrows = data.get("borrows", [])
    counts = data.get("meta", {}).get("counts", {})
    machine_ids = {f"{machine.family}/{machine.kind}" for machine in machines}
    node_ids = [node.get("id") for node in nodes]
    edge_ids = [edge.get("id") for edge in edges]
    edge_by_id = {edge.get("id"): edge for edge in edges}

    fail_if(data.get("schema") != 2, "full graph schema is not 2", failures)
    fail_if(len(machines) != 222, f"expected 222 machines, got {len(machines)}", failures)
    fail_if(len(nodes) != sum(len(machine.states) for machine in machines),
            "node count does not equal the per-machine state sum", failures)
    fail_if(len(edges) != sum(len(machine.unique_edges) for machine in machines),
            "edge count does not equal the per-machine unique-edge sum", failures)
    fail_if(len(node_ids) != len(set(node_ids)), "duplicate node ids", failures)
    fail_if(len(edge_ids) != len(set(edge_ids)), "duplicate edge ids", failures)
    fail_if(any(edge.get("from") not in set(node_ids) or edge.get("to") not in set(node_ids)
                for edge in edges), "edge references a missing node", failures)
    fail_if(any(edge.get("machine") not in machine_ids for edge in edges),
            "edge references a missing machine", failures)
    fail_if(any(node.get("level") != LEVEL_BY_FAMILY.get(node.get("family")) or
                node.get("position", {}).get("z") != node.get("level") for node in nodes),
            "node level or z position disagrees with the authored ladder", failures)
    fail_if(any(edge.get("stance") not in {"conserving", "deforming", "neutral"}
                for edge in edges), "edge has an invalid stance", failures)
    deforming_edges = [edge for edge in edges if edge.get("stance") == "deforming"]
    non_deforming_edges = [edge for edge in edges if edge.get("stance") != "deforming"]
    fail_if(any("validity_modes" not in edge or "review_status" not in edge
                for edge in deforming_edges),
            "deforming edge lacks validity_modes or review_status", failures)
    fail_if(any("validity_modes" in edge or "review_status" in edge
                for edge in non_deforming_edges),
            "non-deforming edge carries validity metadata", failures)
    for edge in deforming_edges:
        modes = edge.get("validity_modes")
        fail_if(
            not isinstance(modes, list)
            or not modes
            or len(modes) != len(set(modes))
            or any(mode not in VALIDITY_MODES for mode in modes)
            or (len(modes) == 2 and modes != list(VALIDITY_MODES)),
            f"edge {edge.get('id')} has invalid validity_modes {modes!r}",
            failures,
        )
        fail_if(edge.get("review_status") not in REVIEW_STATUSES,
                f"edge {edge.get('id')} has invalid review_status {edge.get('review_status')!r}",
                failures)

    borrow_actions = [borrow.get("canonical_action") for borrow in borrows]
    fail_if(len(borrow_actions) != len(set(borrow_actions)),
            "duplicate canonical action in borrow index", failures)
    pair_count = 0
    cross_family_count = 0
    for borrow in borrows:
        canonical = borrow.get("canonical_action")
        carried = borrow.get("edge_ids", [])
        carried_machines = {edge_by_id[edge_id]["machine"] for edge_id in carried
                            if edge_id in edge_by_id}
        if len(carried_machines) < 2:
            failures.append(f"borrow action {canonical} is not carried by two machines")
        if any(edge_id not in edge_by_id or edge_by_id[edge_id].get("canonical_action") != canonical
               for edge_id in carried):
            failures.append(f"borrow action {canonical} has an invalid edge index")
        for pair in borrow.get("pairs", []):
            pair_count += 1
            pair_machines = pair.get("machines", [])
            if len(pair_machines) != 2 or pair_machines[0] >= pair_machines[1]:
                failures.append(f"borrow action {canonical} has an invalid machine pair")
                continue
            expected_cross = pair_machines[0].split("/", 1)[0] != pair_machines[1].split("/", 1)[0]
            if pair.get("cross_family") != expected_cross:
                failures.append(f"borrow action {canonical} has a wrong cross_family flag")
            cross_family_count += expected_cross
            pair_edges = pair.get("edge_ids", [])
            if len(pair_edges) != 2 or any(
                edge_id not in carried or edge_by_id[edge_id].get("machine") != pair_machines[index]
                for index, ids in enumerate(pair_edges) for edge_id in ids
            ):
                failures.append(f"borrow action {canonical} has an invalid pair edge index")

    stance_counts = Counter(edge.get("stance") for edge in edges)
    unmapped_edges = [edge for edge in edges if edge.get("canonical_action") is None]
    stance_absent_edges = [
        edge for edge in edges
        if edge.get("canonical_action") is None
        or edge.get("canonical_action") not in data["meta"]["canonical_action_scope"]["computational"]
    ]
    expected_counts = {
        "machines": len(machines),
        "families": len({machine.family for machine in machines}),
        "nodes": len(nodes),
        "edges": len(edges),
        "borrows": len(borrows),
        "borrow_pairs": pair_count,
        "cross_family_borrow_pairs": cross_family_count,
        "unmapped_edges": len(unmapped_edges),
        "stance_absent_edges_defaulted_neutral": len(stance_absent_edges),
    }
    for label, observed in expected_counts.items():
        fail_if(counts.get(label) != observed,
                f"meta count {label}: expected {observed}, got {counts.get(label)}", failures)
    fail_if(counts.get("edges_by_stance") != {
        stance: stance_counts.get(stance, 0)
        for stance in ("conserving", "deforming", "neutral")
    }, "meta stance counts disagree with edges", failures)
    validity_counts = Counter()
    for edge in deforming_edges:
        modes = set(edge.get("validity_modes", []))
        if modes == {"objective_invalid"}:
            validity_counts["objective_invalid_only"] += 1
        elif modes == {"context_sensitive_or_inefficient"}:
            validity_counts["context_sensitive_or_inefficient_only"] += 1
        elif modes == set(VALIDITY_MODES):
            validity_counts["mixed"] += 1
    expected_validity_counts = {
        label: validity_counts.get(label, 0)
        for label in (
            "objective_invalid_only",
            "context_sensitive_or_inefficient_only",
            "mixed",
        )
    }
    fail_if(counts.get("deforming_edges_by_validity") != expected_validity_counts,
            "meta validity counts disagree with deforming edges", failures)
    expected_status_counts = {
        status: sum(edge.get("review_status") == status for edge in deforming_edges)
        for status in REVIEW_STATUSES
    }
    fail_if(counts.get("deforming_edges_by_review_status") != expected_status_counts,
            "meta review-status counts disagree with deforming edges", failures)
    expected_review_counts = {
        "reviewed": sum(edge.get("review_status") not in UNREVIEWED_STATUSES
                        for edge in deforming_edges),
        "unreviewed": sum(edge.get("review_status") in UNREVIEWED_STATUSES
                          for edge in deforming_edges),
    }
    fail_if(counts.get("deforming_edges_by_review_state") != expected_review_counts,
            "meta reviewed/unreviewed counts disagree with deforming edges", failures)
    fail_if(sum(expected_validity_counts.values()) != len(deforming_edges),
            "validity categories do not cover every deforming edge", failures)
    fail_if(sum(expected_status_counts.values()) != len(deforming_edges),
            "review statuses do not cover every deforming edge", failures)

    if not PAGE.exists():
        failures.append(f"missing graph page: {PAGE.relative_to(ROOT)}")
    else:
        page = PAGE.read_text(encoding="utf-8")
        required = (
            "assets/automata/full_graph.json",
            '<canvas id="graph"',
            '<option value="off"',
            '<option value="cross"',
            '<option value="all"',
            "Drag to orbit",
            "no state is literally shared",
            "vertical order is authored",
            "the claim is false on its own",
            "a correct doing the context makes insufficient",
            "blue base with a rust overlay",
            "reviewed",
            "unreviewed",
            "validity_modes",
            "review_status",
            "validityBlue",
            "drawValidityBlueBases",
            "drawValidityRustOverlays",
        )
        for fragment in required:
            fail_if(fragment not in page, f"graph page lacks required fragment: {fragment}", failures)
        blue_call = page.find("\n    drawValidityBlueBases(validityBlueEdges);")
        rust_call = page.find("\n    drawValidityRustOverlays(deformingEdges);")
        fail_if(blue_call < 0 or rust_call < 0 or blue_call > rust_call,
                "graph page does not draw blue validity bases before rust overlays", failures)
        fail_if(bool(re.search(r"https?://", page)), "graph page contains an external URL", failures)
        fail_if(bool(re.search(r"<script\b[^>]+\bsrc=", page, re.IGNORECASE)),
                "graph page loads an external script", failures)
        scripts = re.findall(r"<script>(.*?)</script>", page, re.DOTALL)
        fail_if(len(scripts) != 1, f"expected one inline graph script, got {len(scripts)}", failures)
        if len(scripts) == 1:
            with tempfile.TemporaryDirectory(prefix="hermes-full-graph-") as directory:
                script = Path(directory) / "graph.js"
                script.write_text(scripts[0], encoding="utf-8")
                check = subprocess.run(
                    ["node", "--check", str(script)], text=True, capture_output=True, check=False
                )
                if check.returncode:
                    failures.append(f"graph page JavaScript syntax: {check.stderr.strip()}")

    if not HUB.exists() or 'href="automata-graph.html"' not in HUB.read_text(encoding="utf-8"):
        failures.append("compendium hub lacks the full-graph link")

    token_text = TOKENS.read_text(encoding="utf-8") if TOKENS.exists() else ""
    blue = re.search(r"--validity-blue:\s*(#[0-9a-fA-F]{6})", token_text)
    norms = re.search(r"--acc-norms:\s*(#[0-9a-fA-F]{6})", token_text)
    fail_if(blue is None, "Hermes tokens lack --validity-blue", failures)
    fail_if(blue is not None and norms is not None and blue.group(1).lower() == norms.group(1).lower(),
            "--validity-blue reuses --acc-norms", failures)

    if failures:
        for failure in failures:
            print(failure, file=sys.stderr)
        return 1
    print(
        f"PASS full graph: {len(machines)} machines, {len(nodes)} nodes, {len(edges)} edges, "
        f"{len(borrows)} borrow actions and {pair_count} borrow pairs; deterministic JSON "
        "is byte-identical and the self-contained page passes static checks"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
