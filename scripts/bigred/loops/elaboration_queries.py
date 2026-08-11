#!/usr/bin/env python3
"""Run Q1-Q3 over the tracked admitted edge and kernel overlay stores.

Reachability comes only from crisis_release/8 facts in admitted_edges.pl.
The store's registry wrapper supplies the machine universe for Q1; registry
membership and the kernel overlay remain non-reachability metadata.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from collections import Counter, defaultdict, deque
from pathlib import Path
from typing import Any, Iterable


ROOT = Path(__file__).resolve().parents[3]
PATHS = ROOT / "paths.pl"
STORE = ROOT / "scripts/bigred/loops/admitted_edges.pl"
KERNEL_STORE = ROOT / "scripts/bigred/loops/kernel_dependency_overlay.pl"
OUTPUT_JSON = (
    ROOT / "docs/research/internal/2026-08-11-elaboration-queries.json"
)
OUTPUT_MD = ROOT / "docs/research/internal/2026-08-11-elaboration-queries.md"
WAVE = "2026-08-09-wave1-with-2026-08-10-kernel-overlay"
SEAM_SOURCE = "docs/research/internal/2026-08-08-learner-path-graph-design.md"
SEAM_SCOUT = "docs/research/2026-08-06-learner-paths.md"

Machine = tuple[str, str]


class QueryError(RuntimeError):
    """The admitted store or a bounded query failed its contract."""


# The authoritative stage-1 design's "Where the graph disconnects today"
# table names exactly these eight seams.  Selectors retain the table's level of
# specificity: exact machines where the table/scout names them, family sets
# where the seam is stated across a representation or quantity family, and
# proposed markers for selectors absent from the action-automaton registry.
# Row notes distinguish missing code from runnable but unregistered code.
SEAMS: list[dict[str, Any]] = [
    {
        "id": "counting_one_by_one_to_recursive_place_value",
        "name": "Counting one by one to recursive place value",
        "note": (
            "counting/enumerate_collection_one_to_one anchors the existing "
            "near side; it is not the missing source-tension refusal machine, "
            "which remains unnamed"
        ),
        "sources": [
            {"machine": ["counting", "enumerate_collection_one_to_one"]}
        ],
        "targets": [
            {"machine": ["counting", "recursive_place_value_inscription"]}
        ],
    },
    {
        "id": "whole_number_sharing_to_unit_fractions",
        "name": "Whole-number sharing to unit fractions",
        "sources": [
            {"machine": ["proposed", "whole_number_non_integer_share_refusal"]}
        ],
        "targets": [
            {"machine": ["fraction", "unit_fraction_partition"]}
        ],
    },
    {
        "id": "fraction_units_to_decimal_place_units",
        "name": "Fraction units to decimal place units",
        "sources": [{"family": "fraction"}],
        "targets": [{"family": "decimal"}],
    },
    {
        "id": "fraction_or_decimal_quantity_to_ordered_ratio",
        "name": "Fraction or decimal quantity to ordered ratio",
        "sources": [{"family": "fraction"}, {"family": "decimal"}],
        "targets": [{"family": "ratio"}],
    },
    {
        "id": "proportional_equation_to_covariational_function",
        "name": "Proportional equation to covariational function",
        "sources": [
            {"machine": ["ratio", "inscribe_proportional_equation"]}
        ],
        "targets": [
            {"machine": ["proposed", "ordered_quantity_covariation"]}
        ],
    },
    {
        "id": "rational_co_measurement_to_real_number_measurement",
        "name": "Rational co-measurement to real-number measurement",
        "note": (
            "the incommensurability refusal runs in "
            "knowledge/strategies/abstraction/refusal_genesis_sketch.pl:157-170 "
            "but is not registered as an action automaton; the proposed marker "
            "stands for that registry absence, not absent code"
        ),
        "sources": [
            {"machine": ["proposed", "rational_co_measurement_refusal"]}
        ],
        "targets": [
            {"machine": ["proposed", "nested_interval_real_line"]}
        ],
    },
    {
        "id": "finite_relative_frequency_to_a_limit",
        "name": "Finite relative frequency to a limit",
        "sources": [
            {
                "machine": [
                    "statistics",
                    "finite_frequency_as_exact_probability",
                ]
            }
        ],
        "targets": [
            {
                "machine": [
                    "calculus",
                    "bounded_numerator_over_diverging_denominator",
                ]
            }
        ],
    },
    {
        "id": "algebraic_evaluation_to_function_limit",
        "name": "Algebraic evaluation to function limit",
        "sources": [
            {"machine": ["algebraic", "programming_expression_evaluation"]}
        ],
        "targets": [{"machine": ["calculus", "direct_substitution"]}],
    },
]


def machine_dict(machine: Machine) -> dict[str, str]:
    return {"family": machine[0], "kind": machine[1]}


def machine_name(machine: Machine) -> str:
    return f"{machine[0]}/{machine[1]}"


def read_store() -> tuple[
    list[dict[str, Any]], list[Machine], list[dict[str, Any]]
]:
    """Read reachability and annotation rows through their Prolog modules."""
    goal = (
        "use_module(library(http/json)),"
        "findall(D,admitted_edges:admitted_edge_dict(D),Edges),"
        "findall(_{family:F,kind:K},admitted_edges:registered_machine(F,K),Ms0),"
        "sort(Ms0,Machines),"
        "findall(KD,kernel_dependency_overlay:kernel_dependency_dict(KD),KDs),"
        "json_write_dict(current_output,_{edges:Edges,machines:Machines,"
        "kernel_dependencies:KDs},[width(0)]),nl"
    )
    completed = subprocess.run(
        [
            "swipl",
            "-q",
            "-l",
            str(PATHS),
            "-s",
            str(STORE),
            "-s",
            str(KERNEL_STORE),
            "-g",
            goal,
            "-t",
            "halt",
        ],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode:
        raise QueryError(
            "tracked overlay stores failed to load: "
            f"{completed.stderr.strip()[:1000]}"
        )
    line = next(
        (value for value in completed.stdout.splitlines() if value.startswith("{")),
        "",
    )
    if not line:
        raise QueryError("SWI-Prolog returned no admitted-store JSON")
    payload = json.loads(line)
    edges = payload["edges"]
    machines = sorted(
        (row["family"], row["kind"]) for row in payload["machines"]
    )
    kernel_dependencies = payload["kernel_dependencies"]
    if len(edges) != 34:
        raise QueryError(f"store exposes {len(edges)} admitted edges, expected 34")
    if len(kernel_dependencies) != 2:
        raise QueryError(
            "kernel overlay exposes "
            f"{len(kernel_dependencies)} rows, expected 2"
        )
    return edges, machines, kernel_dependencies


def edge_endpoints(edge: dict[str, Any]) -> tuple[Machine, Machine]:
    return (
        (edge["source"]["family"], edge["source"]["kind"]),
        (edge["target"]["family"], edge["target"]["kind"]),
    )


def adjacency(edges: Iterable[dict[str, Any]]) -> dict[Machine, list[dict[str, Any]]]:
    result: dict[Machine, list[dict[str, Any]]] = defaultdict(list)
    for edge in edges:
        source, _target = edge_endpoints(edge)
        result[source].append(edge)
    for outgoing in result.values():
        outgoing.sort(key=lambda edge: edge_endpoints(edge)[1])
    return result


def q1_radius(
    edges: list[dict[str, Any]], machines: list[Machine], k_max: int = 4
) -> dict[str, Any]:
    graph = adjacency(edges)
    rows: list[dict[str, Any]] = []
    flagged: list[dict[str, Any]] = []
    for start in machines:
        distances: dict[Machine, int] = {start: 0}
        queue: deque[Machine] = deque([start])
        while queue:
            current = queue.popleft()
            if distances[current] >= k_max:
                continue
            for edge in graph.get(current, []):
                _source, target = edge_endpoints(edge)
                if target not in distances:
                    distances[target] = distances[current] + 1
                    queue.append(target)
        by_k = []
        flagged_k = []
        for k in range(1, k_max + 1):
            reach_count = sum(1 for distance in distances.values() if 1 <= distance <= k)
            frontier_delta = sum(1 for distance in distances.values() if distance == k)
            by_k.append(
                {
                    "k": k,
                    "reach_count": reach_count,
                    "frontier_delta": frontier_delta,
                }
            )
            if frontier_delta >= 5:
                flagged_k.append(k)
        row = {
            "machine": machine_dict(start),
            "by_k": by_k,
            "delta_jump_at_least_5": bool(flagged_k),
            "flagged_k": flagged_k,
        }
        rows.append(row)
        if flagged_k:
            flagged.append({"machine": machine_dict(start), "k": flagged_k})
    return {
        "k_values": list(range(1, k_max + 1)),
        "delta_definition": "new machines first reached at exactly K",
        "flag_threshold": 5,
        "machine_count": len(rows),
        "flagged_machine_count": len(flagged),
        "flagged_machines": flagged,
        "rows": rows,
    }


def resolve_selectors(
    selectors: list[dict[str, Any]], machines: set[Machine]
) -> set[Machine]:
    resolved: set[Machine] = set()
    for selector in selectors:
        if "machine" in selector:
            family, kind = selector["machine"]
            machine = (family, kind)
            if machine in machines:
                resolved.add(machine)
        elif "family" in selector:
            resolved.update(
                machine for machine in machines if machine[0] == selector["family"]
            )
        else:
            raise QueryError(f"unknown seam selector: {selector}")
    return resolved


def shortest_path(
    graph: dict[Machine, list[dict[str, Any]]],
    starts: set[Machine],
    targets: set[Machine],
    k_max: int,
) -> tuple[list[Machine], list[dict[str, Any]]] | None:
    if not starts or not targets:
        return None
    queue: deque[Machine] = deque(sorted(starts))
    distance = {machine: 0 for machine in starts}
    previous: dict[Machine, tuple[Machine, dict[str, Any]]] = {}
    reached = next((machine for machine in sorted(starts) if machine in targets), None)
    while queue and reached is None:
        current = queue.popleft()
        if distance[current] >= k_max:
            continue
        for edge in graph.get(current, []):
            _source, target = edge_endpoints(edge)
            if target in distance:
                continue
            distance[target] = distance[current] + 1
            previous[target] = (current, edge)
            if target in targets:
                reached = target
                break
            queue.append(target)
    if reached is None:
        return None
    nodes = [reached]
    path_edges: list[dict[str, Any]] = []
    while reached not in starts:
        prior, edge = previous[reached]
        path_edges.append(edge)
        nodes.append(prior)
        reached = prior
    nodes.reverse()
    path_edges.reverse()
    return nodes, path_edges


def q2_seams(
    edges: list[dict[str, Any]], machines: list[Machine], k_max: int = 6
) -> dict[str, Any]:
    graph = adjacency(edges)
    machine_set = set(machines)
    rows = []
    for seam in SEAMS:
        starts = resolve_selectors(seam["sources"], machine_set)
        targets = resolve_selectors(seam["targets"], machine_set)
        path = shortest_path(graph, starts, targets, k_max)
        row = {
            "id": seam["id"],
            "name": seam["name"],
            "note": seam.get("note"),
            "provenance": [SEAM_SOURCE, SEAM_SCOUT],
            "source_selectors": seam["sources"],
            "target_selectors": seam["targets"],
            "registered_source_count": len(starts),
            "registered_target_count": len(targets),
        }
        if path is None:
            row.update(
                {
                    "status": "UNREACHED",
                    "minimum_admitted_path_length": None,
                    "path": [],
                }
            )
        else:
            nodes, path_edges = path
            row.update(
                {
                    "status": "REACHED",
                    "minimum_admitted_path_length": len(path_edges),
                    "path": [machine_dict(machine) for machine in nodes],
                }
            )
        rows.append(row)
    return {
        "k_max": k_max,
        "authoritative_seam_list": SEAM_SOURCE,
        "supporting_rung_scout": SEAM_SCOUT,
        "provenance": [SEAM_SOURCE, SEAM_SCOUT],
        "seam_count": len(rows),
        "reached_count": sum(row["status"] == "REACHED" for row in rows),
        "unreached_count": sum(row["status"] == "UNREACHED" for row in rows),
        "rows": rows,
    }


def q3_hybrid_walks(
    edges: list[dict[str, Any]], length_max: int = 4, path_cap: int = 100_000
) -> dict[str, Any]:
    graph = adjacency(edges)
    graph_nodes = sorted(
        {machine for edge in edges for machine in edge_endpoints(edge)}
    )
    examined = 0
    truncated = False
    candidates: list[dict[str, Any]] = []

    def visit(
        nodes: list[Machine], path_edges: list[dict[str, Any]]
    ) -> None:
        nonlocal examined, truncated
        if truncated or len(path_edges) >= length_max:
            return
        current = nodes[-1]
        for edge in graph.get(current, []):
            if examined >= path_cap:
                truncated = True
                return
            _source, target = edge_endpoints(edge)
            if target in nodes:
                continue
            next_nodes = nodes + [target]
            next_edges = path_edges + [edge]
            examined += 1
            families = sorted({machine[0] for machine in next_nodes})
            has_l2_l3 = any(item["lens"] in {"l2", "l3"} for item in next_edges)
            if len(families) >= 2 and has_l2_l3:
                candidates.append(
                    {
                        "path": [machine_dict(machine) for machine in next_nodes],
                        "length": len(next_edges),
                        "families": families,
                        "families_spanned": len(families),
                        "families_per_edge": len(families) / len(next_edges),
                        "lenses": [item["lens"] for item in next_edges],
                    }
                )
            visit(next_nodes, next_edges)
            if truncated:
                return

    for start in graph_nodes:
        visit([start], [])
        if truncated:
            break

    candidates.sort(
        key=lambda row: (
            -row["families_per_edge"],
            -row["families_spanned"],
            row["length"],
            [machine_name((node["family"], node["kind"])) for node in row["path"]],
        )
    )
    return {
        "length_max": length_max,
        "minimum_families": 2,
        "required_lenses": ["l2", "l3"],
        "simple_paths": True,
        "path_enumeration_cap": path_cap,
        "paths_examined": examined,
        "enumeration_truncated": truncated,
        "candidate_count": len(candidates),
        "ranking": "families_spanned per admitted edge spent",
        "top_20": candidates[:20],
    }


def build_result(
    edges: list[dict[str, Any]],
    machines: list[Machine],
    kernel_dependencies: list[dict[str, Any]],
) -> dict[str, Any]:
    pairs = [edge_endpoints(edge) for edge in edges]
    if len(pairs) != len(set(pairs)):
        raise QueryError("admitted store contains duplicate directed pairs")
    cross_family = sum(source[0] != target[0] for source, target in pairs)
    return {
        "schema": "hermes_elaboration_queries_v1",
        "generated_for": WAVE,
        "graph": {
            "source_store": "scripts/bigred/loops/admitted_edges.pl",
            "kernel_overlay_store": (
                "scripts/bigred/loops/kernel_dependency_overlay.pl"
            ),
            "reachability_edge_types": ["crisis_release"],
            "admitted_edge_count": len(edges),
            "registered_machine_count": len(machines),
            "cross_family_edge_count": cross_family,
            "lens_counts": dict(sorted(Counter(edge["lens"] for edge in edges).items())),
            "kernel_dependency_edge_count": len(kernel_dependencies),
            "kernel_dependencies": kernel_dependencies,
            "overlay_rule": "overlays annotate results and do not extend reachability",
        },
        "q1_elaboration_radius": q1_radius(edges, machines),
        "q2_seam_ledger": q2_seams(edges, machines),
        "q3_budgeted_hybrid_walks": q3_hybrid_walks(edges),
    }


def render_markdown(result: dict[str, Any]) -> str:
    graph = result["graph"]
    q1 = result["q1_elaboration_radius"]
    q2 = result["q2_seam_ledger"]
    q3 = result["q3_budgeted_hybrid_walks"]
    nonzero = [
        row for row in q1["rows"] if row["by_k"][-1]["reach_count"] > 0
    ]
    zero_count = q1["machine_count"] - len(nonzero)
    lines = [
        "# Bounded elaboration queries: wave 1 with kernel overlay",
        "",
        "## Scope",
        "",
        f"The run reads reachability edges only from `{graph['source_store']}`. "
        f"It contains {graph['admitted_edge_count']} admitted `crisis_release` "
        f"edges over a registry universe of {graph['registered_machine_count']} "
        f"machines. All {graph['admitted_edge_count']} edges carry the L2 lens, "
        f"and {graph['cross_family_edge_count']} cross a family. The tracked "
        f"`kernel_dependency` overlay at `{graph['kernel_overlay_store']}` has "
        f"{graph['kernel_dependency_edge_count']} rows. The queries read and "
        "report those annotations; they do not extend reachability.",
        "",
        "## Q1: elaboration radius",
        "",
        "`frontier delta` is the number of machines first reached at exactly K. "
        f"No machine has a delta of at least {q1['flag_threshold']}. "
        f"{zero_count} machines reach no admitted successor by K=4. The JSON "
        "artifact records all machines; the table below lists the machines with "
        "nonzero reach.",
        "",
        "| Machine | K=1 count/delta | K=2 count/delta | K=3 count/delta | K=4 count/delta |",
        "| --- | ---: | ---: | ---: | ---: |",
    ]
    for row in nonzero:
        cells = [
            f"{item['reach_count']}/{item['frontier_delta']}" for item in row["by_k"]
        ]
        machine = row["machine"]
        lines.append(
            f"| `{machine['family']}/{machine['kind']}` | "
            + " | ".join(cells)
            + " |"
        )

    lines.extend(
        [
            "",
            "## Q2: seam ledger",
            "",
            f"The authoritative list is the eight-row disconnection table in "
            f"`{q2['authoritative_seam_list']}`, supported by the rung table in "
            f"`{q2['supporting_rung_scout']}`. Minimum paths are bounded at "
            f"K={q2['k_max']}.",
            "",
            "| Seam | Minimum admitted path | Registered source/target endpoints | Note |",
            "| --- | ---: | ---: | --- |",
        ]
    )
    for row in q2["rows"]:
        length = (
            str(row["minimum_admitted_path_length"])
            if row["status"] == "REACHED"
            else "UNREACHED"
        )
        lines.append(
            f"| {row['name']} | {length} | "
            f"{row['registered_source_count']}/{row['registered_target_count']} | "
            f"{row['note'] or ''} |"
        )

    lines.extend(
        [
            "",
            "## Q3: budgeted hybrid walks",
            "",
            f"The bounded enumeration examined {q3['paths_examined']} simple "
            f"admitted paths of length at most {q3['length_max']} and did not "
            f"reach its {q3['path_enumeration_cap']:,}-path cap. It found "
            f"{q3['candidate_count']} paths spanning at least two families while "
            "using an L2- or L3-lensed edge. There is therefore no top-20 list "
            "in this wave.",
            "",
            "## First reading",
            "",
            "The admitted graph is shallow. Its edges release productive "
            "machines into same-question deformations inside addition, division, "
            "and fraction work. Two length-2 addition paths run through "
            "`append_column_sum_without_carrying`; no admitted edge crosses a "
            "family. All eight rung-map seams remain "
            "unreached, and the hybrid-walk query returns no candidates. This is "
            "the measured wave-1 boundary.",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help=(
            "compare present runtime artifacts with a fresh run and regenerate "
            "any that are absent"
        ),
    )
    args = parser.parse_args()
    edges, machines, kernel_dependencies = read_store()
    result = build_result(edges, machines, kernel_dependencies)
    json_text = json.dumps(result, indent=2, sort_keys=True) + "\n"
    markdown_text = render_markdown(result)

    outputs = [(OUTPUT_JSON, json_text), (OUTPUT_MD, markdown_text)]
    if args.check:
        stale = []
        for output, expected in outputs:
            if output.is_file():
                if output.read_text(encoding="utf-8") != expected:
                    stale.append(str(output.relative_to(ROOT)))
            else:
                output.parent.mkdir(parents=True, exist_ok=True)
                output.write_text(expected, encoding="utf-8")
                print(
                    "REGENERATED local runtime artifact: "
                    f"{output.relative_to(ROOT)}"
                )
        if stale:
            raise QueryError(
                "stale elaboration query artifact(s): " + ", ".join(stale)
            )
    else:
        for output, expected in outputs:
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_text(expected, encoding="utf-8")

    q1 = result["q1_elaboration_radius"]
    q2 = result["q2_seam_ledger"]
    q3 = result["q3_budgeted_hybrid_walks"]
    max_reach = max(
        row["by_k"][-1]["reach_count"] for row in q1["rows"]
    )
    print(
        "PASS elaboration queries: "
        f"machines={q1['machine_count']} max_reach_k4={max_reach} "
        f"delta_flags={q1['flagged_machine_count']} "
        f"seams_unreached={q2['unreached_count']}/{q2['seam_count']} "
        f"hybrid_candidates={q3['candidate_count']} "
        f"paths_examined={q3['paths_examined']} "
        f"kernel_dependencies={result['graph']['kernel_dependency_edge_count']}"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (QueryError, KeyError, ValueError, OSError) as error:
        print(f"FAIL elaboration_queries: {error}", file=sys.stderr)
        raise SystemExit(1)
