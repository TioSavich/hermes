#!/usr/bin/env python3
"""Check authored validity coverage for every deforming graph edge."""

from __future__ import annotations

import json
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
GRAPH = ROOT / "docs/research/assets/automata/full_graph.json"
LEDGER = ROOT / "knowledge/strategies/deformation_validity.pl"
TABLES = ROOT / "knowledge/strategies/transition_tables"

EXPECTED_ROWS = 232
ALLOWED_MODES = {
    "objective_invalid",
    "context_sensitive_or_inefficient",
}
ALLOWED_STATUSES = {"seeded_profile", "seeded_ledger", "proposed", "adjudicated"}
ALLOWED_BASIS_KINDS = {
    "addition_ledger_loss/3",
    "adjudicated/3",
    "coincidence_at/1",
    "coincidence_profile/4",
    "independent_truth_derivation/2",
    "proposed_from_code_reading/2",
    "conflict/3",
}
ADDITION_BASIS_RE = re.compile(
    r"^addition_ledger_loss\('knowledge/strategies/abstraction/addition_action_signatures\.pl',"
    r"([a-z][a-z0-9_]*),(answer_bearing|elaboration)\(([a-z][a-z0-9_]*)\)\)$"
)
PROFILE_BASIS_RE = re.compile(
    r"^coincidence_profile\('knowledge/strategies/deformation_coincidence\.pl',"
    r"([a-z][a-z0-9_]*)/([a-z][a-z0-9_]*),ran\(([0-9]+)\),coincide\(([0-9]+)\)\)$"
)
INDEPENDENT_TRUTH_RE = re.compile(
    r"^independent_truth_derivation\(action_pair_expected_result,'.+'\)$"
)
CODE_READING_RE = re.compile(r"^proposed_from_code_reading\(.+,'.+'\)$")
CONFLICT_RE = re.compile(
    r"^conflict\(machine_profile_projects_mixed,"
    r"addition_ledger_selects_objective_invalid,'.+'\)$"
)
ADJUDICATED_RE = re.compile(
    r"^adjudicated\(code_reading\('2026-08-05'\),'.+','.+'\)$"
)
COINCIDENCE_AT_RE = re.compile(r"^coincidence_at\('.+'\)$")

TRANSITION_RE = re.compile(
    r"^automaton_transition\(([^,]+), ([^,]+), ([^,]+), ([^,]+), ([^,]+),",
    re.MULTILINE,
)


def fail(message: str) -> None:
    print(f"FAIL deformation validity: {message}", file=sys.stderr)
    raise SystemExit(1)


def graph_key(edge: dict[str, object]) -> tuple[str, str, str, str, str]:
    machine = str(edge["machine"])
    family, kind = machine.split("/", 1)
    return (
        family,
        kind,
        str(edge["local_action"]),
        str(edge["from"]).rsplit(":", 1)[-1],
        str(edge["to"]).rsplit(":", 1)[-1],
    )


def load_ledger() -> list[dict[str, object]]:
    query = (
        "use_module(library(http/json)),"
        f"use_module('{LEDGER.as_posix()}'),"
        "forall(deformation_validity(Family,Kind,Action,From,To,Modes,Basis,Status),"
        "(Basis=basis(Evidence),Evidence=[_|_],"
        "term_string(Basis,BasisText,[quoted(true)]),"
        "findall(Label,(member(Item,Evidence),functor(Item,Name,Arity),"
        "format(string(Label),'~w/~w',[Name,Arity])),BasisKinds),"
        "findall(ItemText,(member(Item,Evidence),"
        "term_string(Item,ItemText,[quoted(true)])),BasisItems),"
        "json_write_dict(current_output,_{family:Family,kind:Kind,local_action:Action,"
        "from:From,to:To,modes:Modes,basis:BasisText,basis_kinds:BasisKinds,basis_items:BasisItems,"
        "review_status:Status},[width(0)]),nl))"
    )
    completed = subprocess.run(
        ["swipl", "-q", "-g", query, "-t", "halt"],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        detail = completed.stderr.strip() or completed.stdout.strip()
        fail(f"ledger did not load cleanly: {detail}")
    try:
        return [json.loads(line) for line in completed.stdout.splitlines() if line]
    except json.JSONDecodeError as exc:
        fail(f"ledger serialization was not JSON: {exc}")


def load_transition_keys() -> set[tuple[str, str, str, str, str]]:
    keys: set[tuple[str, str, str, str, str]] = set()
    for path in sorted(TABLES.glob("*.pl")):
        for family, kind, before, action, after in TRANSITION_RE.findall(
            path.read_text(encoding="utf-8")
        ):
            keys.add((family, kind, action, before, after))
    if not keys:
        fail("no automaton_transition/6 rows were found")
    return keys


def main() -> None:
    graph = json.loads(GRAPH.read_text(encoding="utf-8"))
    deforming_edges = [edge for edge in graph["edges"] if edge.get("stance") == "deforming"]
    graph_keys = [graph_key(edge) for edge in deforming_edges]

    if len(graph_keys) != EXPECTED_ROWS:
        fail(f"full_graph.json has {len(graph_keys)} deforming edges, expected {EXPECTED_ROWS}")
    if len(set(graph_keys)) != len(graph_keys):
        duplicates = [key for key, count in Counter(graph_keys).items() if count > 1]
        fail(f"full_graph.json has duplicate deforming keys: {duplicates[:3]}")

    rows = load_ledger()
    if len(rows) != EXPECTED_ROWS:
        fail(f"ledger has {len(rows)} rows, expected {EXPECTED_ROWS}")

    ledger_keys: list[tuple[str, str, str, str, str]] = []
    mode_census: Counter[str] = Counter()
    status_census: Counter[str] = Counter()

    for row_number, row in enumerate(rows, 1):
        key = (
            str(row["family"]),
            str(row["kind"]),
            str(row["local_action"]),
            str(row["from"]),
            str(row["to"]),
        )
        ledger_keys.append(key)

        modes = row.get("modes")
        if not isinstance(modes, list) or not modes:
            fail(f"row {row_number} {key} has no modes")
        if len(modes) != len(set(modes)):
            fail(f"row {row_number} {key} repeats a mode")
        if not set(modes) <= ALLOWED_MODES:
            fail(f"row {row_number} {key} has invalid modes {modes}")
        if len(modes) == 2 and modes != [
            "objective_invalid",
            "context_sensitive_or_inefficient",
        ]:
            fail(f"row {row_number} {key} has noncanonical mixed-mode order")

        status = str(row.get("review_status"))
        if status not in ALLOWED_STATUSES:
            fail(f"row {row_number} {key} has invalid review_status {status}")
        status_census[status] += 1

        basis_kinds = row.get("basis_kinds")
        if not isinstance(basis_kinds, list) or not basis_kinds:
            fail(f"row {row_number} {key} has no structured basis")
        if not set(basis_kinds) <= ALLOWED_BASIS_KINDS:
            fail(f"row {row_number} {key} has invalid basis values {basis_kinds}")
        basis_items = row.get("basis_items")
        if not isinstance(basis_items, list) or len(basis_items) != len(basis_kinds):
            fail(f"row {row_number} {key} has malformed structured basis items")
        addition_seed = None
        profile_seed = None
        adjudication_count = 0
        for basis_kind, basis_item in zip(basis_kinds, basis_items):
            basis_item = str(basis_item)
            if basis_kind == "addition_ledger_loss/3":
                match = ADDITION_BASIS_RE.fullmatch(basis_item)
                if not match or match.group(1) != key[2]:
                    fail(f"row {row_number} {key} has invalid addition-ledger basis {basis_item}")
                addition_seed = (match.group(2), match.group(3))
            elif basis_kind == "coincidence_profile/4":
                match = PROFILE_BASIS_RE.fullmatch(basis_item)
                if not match or (match.group(1), match.group(2)) != key[:2]:
                    fail(f"row {row_number} {key} has invalid profile basis {basis_item}")
                ran, coincide = int(match.group(3)), int(match.group(4))
                if ran <= 0 or not 0 <= coincide <= ran:
                    fail(f"row {row_number} {key} has invalid profile counts {basis_item}")
                profile_seed = (ran, coincide)
            elif basis_kind == "independent_truth_derivation/2":
                if not INDEPENDENT_TRUTH_RE.fullmatch(basis_item):
                    fail(f"row {row_number} {key} has invalid truth basis {basis_item}")
            elif basis_kind == "proposed_from_code_reading/2":
                if not CODE_READING_RE.fullmatch(basis_item):
                    fail(f"row {row_number} {key} has invalid code-reading basis {basis_item}")
            elif basis_kind == "conflict/3":
                if not CONFLICT_RE.fullmatch(basis_item):
                    fail(f"row {row_number} {key} has invalid conflict basis {basis_item}")
            elif basis_kind == "adjudicated/3":
                if not ADJUDICATED_RE.fullmatch(basis_item):
                    fail(f"row {row_number} {key} has invalid adjudication basis {basis_item}")
                adjudication_count += 1
            elif basis_kind == "coincidence_at/1":
                if not COINCIDENCE_AT_RE.fullmatch(basis_item):
                    fail(f"row {row_number} {key} has invalid coincidence basis {basis_item}")
        if "proposed_from_code_reading/2" not in basis_kinds:
            fail(f"row {row_number} {key} does not name its code-reading basis")
        if status == "seeded_ledger" and "addition_ledger_loss/3" not in basis_kinds:
            fail(f"row {row_number} {key} is seeded_ledger without a loss row")
        if status == "seeded_profile" and "coincidence_profile/4" not in basis_kinds:
            fail(f"row {row_number} {key} is seeded_profile without a profile citation")
        if status == "proposed" and set(basis_kinds) & {
            "addition_ledger_loss/3",
            "coincidence_profile/4",
        }:
            fail(f"row {row_number} {key} is proposed but cites a seed source")
        if status == "adjudicated" and adjudication_count != 1:
            fail(f"row {row_number} {key} must name exactly one adjudication basis")
        if status != "adjudicated" and adjudication_count:
            fail(f"row {row_number} {key} has an adjudication basis before review")

        if status == "seeded_ledger":
            expected_modes = (
                ["objective_invalid"]
                if addition_seed and addition_seed[0] == "answer_bearing"
                else ["context_sensitive_or_inefficient"]
            )
            if modes != expected_modes:
                fail(f"row {row_number} {key} disagrees with its addition loss basis")
        if status == "seeded_profile":
            if profile_seed is None:
                fail(f"row {row_number} {key} has no readable profile seed")
            ran, coincide = profile_seed
            expected_modes = (
                ["context_sensitive_or_inefficient"]
                if coincide == ran
                else ["objective_invalid"]
                if coincide == 0
                else ["objective_invalid", "context_sensitive_or_inefficient"]
            )
            if modes != expected_modes:
                fail(f"row {row_number} {key} disagrees with its profile basis")

        basis_text = str(row.get("basis", ""))
        if modes == ["objective_invalid"] and not (
            "independent_truth_derivation(" in basis_text
            or (
                "addition_ledger_loss(" in basis_text
                and "answer_bearing(" in basis_text
            )
        ):
            fail(f"row {row_number} {key} publishes sole objective_invalid without an authored truth basis")
        if "conflict/3" in basis_kinds and not {
            "addition_ledger_loss/3",
            "coincidence_profile/4",
        } <= set(basis_kinds):
            fail(f"row {row_number} {key} records a conflict without both sources")

        mode_set = set(modes)
        if mode_set == {"objective_invalid"}:
            mode_census["rust-only"] += 1
        elif mode_set == {"context_sensitive_or_inefficient"}:
            mode_census["blue-only"] += 1
        elif mode_set == ALLOWED_MODES:
            mode_census["mixed"] += 1
        else:
            fail(f"row {row_number} {key} has an unsupported mode combination")

    duplicate_ledger = [key for key, count in Counter(ledger_keys).items() if count > 1]
    if duplicate_ledger:
        fail(f"ledger has duplicate keys: {duplicate_ledger[:3]}")

    graph_key_set = set(graph_keys)
    ledger_key_set = set(ledger_keys)
    missing = graph_key_set - ledger_key_set
    orphans = ledger_key_set - graph_key_set
    if missing:
        fail(f"ledger is missing {len(missing)} deforming edges; first: {sorted(missing)[0]}")
    if orphans:
        fail(f"ledger has {len(orphans)} orphan rows; first: {sorted(orphans)[0]}")

    transition_keys = load_transition_keys()
    unresolved_ledger = ledger_key_set - transition_keys
    unresolved_graph = graph_key_set - transition_keys
    if unresolved_ledger:
        fail(f"ledger key does not resolve in transition tables: {sorted(unresolved_ledger)[0]}")
    if unresolved_graph:
        fail(f"graph key does not resolve in transition tables: {sorted(unresolved_graph)[0]}")

    print("deformation validity census")
    for label in ("rust-only", "blue-only", "mixed"):
        print(f"  {label}: {mode_census[label]}")
    print("  by review_status:")
    for status in ("seeded_ledger", "seeded_profile", "proposed", "adjudicated"):
        print(f"    {status}: {status_census[status]}")
    print(
        f"PASS deformation validity: {len(rows)} ledger rows join "
        f"{len(graph_keys)} deforming graph edges and the transition tables"
    )


if __name__ == "__main__":
    main()
