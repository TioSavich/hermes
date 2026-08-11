#!/usr/bin/env python3
"""Offline fixture checks for the Big Red loop substrate.

Zero cluster contact, zero network, zero model. Everything here runs against
this checkout and finishes in a couple of minutes.

Each check prints what it measured, not merely whether it liked the result. A
check that can only say PASS teaches nothing when it later fails.

  usage: python3 scripts/bigred/loops/fixture_checks.py
"""

from __future__ import annotations

import json
import io
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from contextlib import redirect_stdout
from unittest.mock import Mock, patch

import run_loop_array as array_runner
import step0_manifests as step0

ROOT = Path(__file__).resolve().parents[3]
DRIVER = ROOT / "scripts/bigred/loops/loop_driver.pl"
PATHS = ROOT / "paths.pl"
RUNNER = ROOT / "scripts/bigred/loops/run_loop_array.py"
STEP0 = ROOT / "scripts/bigred/loops/step0_manifests.py"
CW_EDGES = ROOT / "knowledge/crosswalk/families/cw_edges.pl"
CW_DRIVER = ROOT / "knowledge/crosswalk/families/cw_driver.pl"

RESULTS: list[tuple[str, bool, str]] = []


def record(name: str, ok: bool, detail: str) -> None:
    RESULTS.append((name, ok, detail))
    print(f"  {'PASS' if ok else 'FAIL'}  {name}: {detail}", flush=True)


def swipl(goal: str, timeout: int = 300) -> str:
    completed = subprocess.run(
        ["swipl", "-q", "-l", str(PATHS), "-l", str(DRIVER), "-g", goal,
         "-t", "halt"],
        cwd=str(ROOT), text=True, capture_output=True, timeout=timeout,
        check=False,
    )
    if completed.returncode:
        raise RuntimeError(
            f"goal failed ({completed.returncode}): "
            f"{completed.stderr.strip()[:600]}"
        )
    return completed.stdout


def run_item(item: dict, timeout: int = 300) -> dict:
    completed = subprocess.run(
        ["swipl", "-q", "-l", str(PATHS), "-l", str(DRIVER),
         "-g", "loop_driver:main_item", "-t", "halt"],
        cwd=str(ROOT), text=True, capture_output=True, timeout=timeout,
        input=json.dumps(item) + "\n", check=False,
    )
    line = next((ln for ln in completed.stdout.splitlines()
                 if ln.strip().startswith("{")), "")
    if not line:
        raise RuntimeError(f"driver wrote no row: {completed.stderr[:400]}")
    return json.loads(line)


# --------------------------------------------------------------------------
# 1. Schema coverage. A schema with no grid plan is RECORDED, never fatal.
# --------------------------------------------------------------------------

def check_schema_coverage() -> None:
    print("\n[1] schema coverage — every contract schema, and what it got",
          flush=True)
    goal = (
        "forall(loop_driver:contract_schema(S), "
        "( loop_driver:grid_status(S, Status), "
        "  aggregate_all(count, loop_driver:machine_schema(_, S), M), "
        "  ( Status = instantiated(bounds(N, P)) "
        "  -> aggregate_all(count, loop_driver:grid_input(S, _, _), Actual) "
        "  ;  N = none, P = 0, Actual = 0 ), "
        "  ( Status = instantiated(_) -> T = instantiated ; T = uninstantiated ), "
        "  format('~w\\t~w\\t~w\\t~w\\t~w\\t~q~n', [T, N, P, Actual, M, S]) ))"
    )
    rows = [line.split("\t", 5) for line in swipl(goal).splitlines()
            if line.strip()]
    instantiated = [r for r in rows if r[0] == "instantiated"]
    missing = [r for r in rows if r[0] != "instantiated"]
    drift = [r for r in instantiated if r[2] != r[3]]

    # The grid NAME is not the key and several names collide (three distinct
    # schema strings are all called a_b, three more decimal_pair). Reading the
    # name column as the key sums 69 + 10 + 6 into one 85-machine receiver set
    # that does not exist, so the schema string is printed beside it.
    print(f"      {'status':14s} {'grid':22s} {'pts':>5s} {'enum':>5s} "
          f"{'mach':>4s}  schema (the key)", flush=True)
    for row in rows:
        print(f"      {row[0]:14s} {row[1][:22]:22s} {row[2]:>5s} {row[3]:>5s} "
              f"{row[4]:>4s}  {row[5][:64]}", flush=True)

    names = [row[1] for row in instantiated]
    colliding = sorted({name for name in names if names.count(name) > 1})
    record("colliding grid names are shown beside their schema keys",
           True,
           f"{len(colliding)} name(s) cover more than one schema: "
           f"{', '.join(colliding) or 'none'}")

    covered = sum(int(r[4]) for r in instantiated)
    uncovered = sum(int(r[4]) for r in missing)
    print(f"\n      {len(instantiated)} schemas with a grid ({covered} machines); "
          f"{len(missing)} without ({uncovered} machines, recorded as "
          f"uninstantiated(schema))", flush=True)
    record("schema coverage table printed", True,
           f"{len(rows)} schemas, {covered}/{covered + uncovered} machines gridded")
    record("authored point counts match enumeration", not drift,
           "every plan enumerates the count it claims" if not drift
           else f"{len(drift)} plans disagree with their own count")


# --------------------------------------------------------------------------
# 2. aa_run on a productive machine, a refusal, and a deformation.
# --------------------------------------------------------------------------

def check_aa_run() -> None:
    print("\n[2] aa_run — a productive result, a refusal, a deformation",
          flush=True)
    cases = [
        ("addition", "base_ones_chunking", '{"a":47,"b":28}',
         "result", "productive machine computes 47 + 28"),
        ("subtraction", "take_away_base_ones", '{"a":3,"b":5}',
         "refused", "whole-number subtraction declines 3 - 5"),
        ("multiplication", "add_instead_of_multiply", '{"a":2,"b":3}',
         "result", "deformation computes, and computes wrongly"),
    ]
    # Each conjunct gets its own variables. Sharing D and O across conjuncts
    # makes the second one try to unify a fresh dict with the first one's, and
    # the whole goal fails for a reason that has nothing to do with aa_run.
    goal_parts = []
    for index, (family, kind, payload, _, _) in enumerate(cases):
        goal_parts.append(
            "( atom_json_dict('%s', D%d, [value_string_as(string)]), "
            "  loop_driver:aa_run(%s, %s, D%d, O%d), "
            "  format('~w\\t~w\\t~q~n', [%s, %s, O%d]) )"
            % (payload, index, family, kind, index, index, family, kind, index)
        )
    output = swipl("use_module(library(http/json)), " + ", ".join(goal_parts))
    seen = {}
    for line in output.splitlines():
        fields = line.split("\t", 2)
        if len(fields) == 3:
            seen[(fields[0], fields[1])] = fields[2]

    for family, kind, _, expected, gloss in cases:
        actual = seen.get((family, kind), "<no outcome>")
        ok = actual.startswith(expected)
        record(f"aa_run {family}/{kind}", ok, f"{gloss} -> {actual[:70]}")

    deformation = seen.get(("multiplication", "add_instead_of_multiply"), "")
    record("the deformation is labelled incorrect on a separating input",
           "incorrect" in deformation, deformation[:70] or "<none>")


# --------------------------------------------------------------------------
# 3. same_archetype on two known pairs and one known non-pair, plus the
#    severed pair the block is about.
# --------------------------------------------------------------------------

def check_same_archetype() -> None:
    print("\n[3] same_archetype — pairs, a non-pair, and the severed pair",
          flush=True)
    cases = [
        ("subtraction", "take_away_base_ones",
         "subtraction", "smaller_from_larger_in_column", True,
         "same schema, same family"),
        ("multiplication", "add_instead_of_multiply",
         "multiplication", "coordinate_groups_items", True,
         "same schema, same family"),
        ("addition", "base_ones_chunking",
         "fraction", "unit_fraction_iteration", False,
         "different schemas"),
        ("addition", "base_ones_chunking",
         "subtraction", "take_away_base_ones", False,
         "SHARED schema, severed by the archetype conjunct"),
    ]
    goal_parts = []
    for index, (fa, ka, fb, kb, _, _) in enumerate(cases):
        goal_parts.append(
            "( ( loop_driver:same_archetype(machine(%s,%s), machine(%s,%s)) "
            "  -> A%d = yes ; A%d = no ), "
            "  ( loop_driver:same_schema(machine(%s,%s), machine(%s,%s)) "
            "  -> S%d = yes ; S%d = no ), "
            "  format('~w/~w|~w/~w\\t~w\\t~w~n', [%s,%s,%s,%s, A%d, S%d]) )"
            % (fa, ka, fb, kb, index, index, fa, ka, fb, kb, index, index,
               fa, ka, fb, kb, index, index)
        )
    seen = {}
    for line in swipl(", ".join(goal_parts)).splitlines():
        fields = line.split("\t")
        if len(fields) == 3:
            seen[fields[0]] = (fields[1], fields[2])

    for fa, ka, fb, kb, expected, gloss in cases:
        key = f"{fa}/{ka}|{fb}/{kb}"
        archetype, schema = seen.get(key, ("?", "?"))
        ok = (archetype == "yes") == expected
        record(f"same_archetype {fa}/{ka} vs {fb}/{kb}", ok,
               f"{gloss}: archetype={archetype} schema={schema}")


# --------------------------------------------------------------------------
# 4. The authored archetype map against the file it was derived from.
# --------------------------------------------------------------------------

def check_archetype_map_against_tree() -> None:
    print("\n[4] family_probe_archetype — authored rows against cw_edges.pl",
          flush=True)
    family_module = {
        "addition": "action_automata_registry",
        "subtraction": "sar_sub_action_pairs",
        "multiplication": "smr_mult_action_pairs",
        "division": "smr_div_action_pairs",
        "fraction": "fraction_action_pairs",
        "decimal": "decimal_action_pairs",
        "integer": "integer_action_pairs",
        "ratio": "ratio_action_pairs",
        "diagnostic": "diagnostic_validation_action_pairs",
        "calculus": "calculus_limits_action_pairs",
        "algebraic": "algebraic_action_pairs",
        "probability": "probability_action_pairs",
    }
    edges_text = CW_EDGES.read_text(encoding="utf-8")
    tree = {}
    for line in edges_text.splitlines():
        if not line.startswith("edge(cw_misconception_hook,"):
            continue
        module = line.split(",", 2)[1].strip()
        archetype = line.rstrip().rstrip(").").rsplit(",", 1)[-1].strip()
        tree[module] = archetype

    enum = set(re.findall(r"^archetype\((\w+)\)\.",
                          CW_DRIVER.read_text(encoding="utf-8"), re.M))
    authored = {}
    for match in re.finditer(r"^family_probe_archetype\((\w+),\s*(\w+)\)\.",
                             DRIVER.read_text(encoding="utf-8"), re.M):
        authored[match.group(1)] = match.group(2)

    drift = []
    for family, archetype in sorted(authored.items()):
        module = family_module.get(family)
        expected = tree.get(module)
        if expected != archetype:
            drift.append(f"{family}: authored {archetype}, tree {expected}")
    record("every authored archetype row matches its cw_edges source",
           not drift, "; ".join(drift) or f"{len(authored)} rows agree")
    unknown = sorted(set(authored.values()) - enum)
    record("every authored archetype is in the blessed enum", not unknown,
           f"enum has {len(enum)} values; unknown: {unknown or 'none'}")

    families = set(re.findall(r"^automaton_input_contract\((\w+),",
                              (ROOT / "knowledge/strategies/"
                               "automaton_input_contracts.pl")
                              .read_text(encoding="utf-8"), re.M))
    holes = sorted(families - set(authored))
    record("families the tree gives no archetype are left unmapped", True,
           f"{len(holes)} unmapped: {', '.join(holes) or 'none'}")


# --------------------------------------------------------------------------
# 5. One R1 pair walked end to end on a small authored grid.
# --------------------------------------------------------------------------

ROW_FIELDS = {
    "run": str, "candidate_type": str, "source": dict, "target": dict,
    "input": dict, "evidence": dict, "outcome": str, "consumer": str,
}
OUTCOMES = {"certified_candidate", "no_candidate", "refused", "timeout",
            "resource_error", "uninstantiated", "not_walked"}
EVIDENCE_KINDS = {"separating_input", "coincidence_region", "failed_derivation",
                  "byte_identical_bridge", "trace_match",
                  "adapted_execution_bridge"}


def validate_row(row: dict) -> list[str]:
    problems = []
    for field, kind in ROW_FIELDS.items():
        if field not in row:
            problems.append(f"missing {field}")
        elif not isinstance(row[field], kind):
            problems.append(f"{field} is {type(row[field]).__name__}")
    if row.get("outcome") not in OUTCOMES:
        problems.append(f"outcome {row.get('outcome')!r} off the enum")
    if row.get("evidence", {}).get("kind") not in EVIDENCE_KINDS:
        problems.append(f"evidence.kind {row.get('evidence', {}).get('kind')!r} "
                        "off the enum")
    if not row.get("consumer"):
        problems.append("consumer is blank")
    return problems


def check_r1_walk() -> None:
    print("\n[5] one R1 pair, end to end on a small authored grid", flush=True)
    item = {
        "run": "r1",
        "source": {"family": "decimal",
                   "kind": "change_decimal_place_name_without_regrouping"},
        "target": {"family": "decimal", "kind": "decimal_place_unit_regrouping"},
        "pair_budget_s": 120, "input_timeout_s": 20, "max_witnesses": 0,
    }
    row = run_item(item)
    evidence = row["evidence"]
    print(f"      grid  : {row['input']['bounds']} "
          f"({row['input']['points']} points)", flush=True)
    print(f"      walk  : ran={evidence['ran']} coincide={evidence['coincide']} "
          f"separate={evidence['separate']} refused={evidence['refused']} "
          f"errored={evidence['errored']}", flush=True)
    print(f"      row   : outcome={row['outcome']} "
          f"type={row['candidate_type']}", flush=True)
    problems = validate_row(row)
    record("the row validates against the shared output schema", not problems,
           "; ".join(problems) or "every field present and on its enum")
    record("the walk ran the whole authored grid",
           evidence["ran"] + evidence["refused"] + evidence["errored"]
           == row["input"]["points"],
           f"{evidence['ran']} + {evidence['refused']} + {evidence['errored']} "
           f"of {row['input']['points']}")
    record("every separating input is retained as a witness",
           len(evidence["separating_inputs"]) == evidence["separate"],
           f"{len(evidence['separating_inputs'])} witnesses for "
           f"{evidence['separate']} separations")


# --------------------------------------------------------------------------
# 6. R5's mechanism, and the corpus that cannot feed it.
# --------------------------------------------------------------------------

def check_r5_reproduction() -> None:
    print("\n[6] R5 — the reproduction mechanism, and the corpus gap", flush=True)
    # A SYNTHETIC record. The 6-8 harvest supplies none: see the census below.
    # Operands 7 and 3 with a recorded answer of 10; add_instead_of_multiply
    # reproduces it by trace, coordinate_groups_items does not.
    goal = (
        "use_module(library(http/json)), "
        "atom_json_dict('{\"a\":7,\"b\":3}', D, [value_string_as(string)]), "
        "loop_driver:aa_run(multiplication, add_instead_of_multiply, D, O1), "
        "loop_driver:aa_run(multiplication, coordinate_groups_items, D, O2), "
        "format('~q\\n~q\\n', [O1, O2])"
    )
    lines = [ln for ln in swipl(goal).splitlines() if ln.strip()]
    recorded_answer = 10
    matched = [ln for ln in lines if f"result({recorded_answer}," in ln]
    missed = [ln for ln in lines if f"result({recorded_answer}," not in ln]
    record("one misconception machine reproduces the recorded answer",
           len(matched) == 1,
           f"answer {recorded_answer} reproduced by {len(matched)} of "
           f"{len(lines)}: {matched[0][:52] if matched else 'none'}")
    record("the other machine misses it", len(missed) == 1,
           f"{missed[0][:52] if missed else 'none'}")

    completed = subprocess.run(
        [sys.executable, str(STEP0), "--census"],
        cwd=str(ROOT), text=True, capture_output=True, timeout=600, check=False,
    )
    census = completed.stdout
    scorable = re.search(r"scorable for R5\s*:\s*(\d+)", census)
    records = re.search(r"task records\s*:\s*(\d+)", census)
    count = int(scorable.group(1)) if scorable else -1
    total = int(records.group(1)) if records else -1
    record("the harvest census is measured, not assumed", count >= 0,
           f"{total} task records, {count} carry a recorded answer")
    if count == 0:
        print("      R5 has no runnable corpus: the harvest records operands "
              "and no answers, so step0 writes no R5 manifest.", flush=True)


# --------------------------------------------------------------------------
# 7. Resume idempotence.
# --------------------------------------------------------------------------

def check_resume() -> None:
    print("\n[7] resume — a second run over the same shard adds no rows",
          flush=True)
    item = {
        "run": "r1",
        "key": "r1:geometry/angle_as_ray_length|geometry/angle_turn_measurement",
        "source": {"family": "geometry", "kind": "angle_as_ray_length"},
        "target": {"family": "geometry", "kind": "angle_turn_measurement"},
        "pair_budget_s": 60, "input_timeout_s": 20, "max_witnesses": 0,
    }
    with tempfile.TemporaryDirectory() as workspace:
        manifest = Path(workspace) / "shard.jsonl"
        output = Path(workspace) / "rows.jsonl"
        manifest.write_text(json.dumps(item) + "\n", encoding="utf-8")
        for _ in range(2):
            subprocess.run(
                [sys.executable, str(RUNNER), "--manifest", str(manifest),
                 "--output", str(output)],
                cwd=str(ROOT), text=True, capture_output=True, timeout=600,
                check=False,
            )
            if not output.is_file():
                record("resume idempotence", False, "first run wrote nothing")
                return
        rows = [ln for ln in output.read_text(encoding="utf-8").splitlines()
                if ln.strip()]
        record("resume idempotence", len(rows) == 1,
               f"{len(rows)} row(s) on disk after two runs of a one-item shard")


# --------------------------------------------------------------------------
# 8. The watchdog actually kills.
# --------------------------------------------------------------------------

def check_watchdog() -> None:
    print("\n[8] watchdog — a long item is killed and retained as a row",
          flush=True)
    # The multiplication pair over the 2,500-point integer grid needs minutes;
    # a six-second watchdog must cut it off and still write its row.
    item = {
        "run": "r1",
        "key": "watchdog-probe",
        "source": {"family": "multiplication", "kind": "add_instead_of_multiply"},
        "target": {"family": "multiplication", "kind": "coordinate_groups_items"},
        "pair_budget_s": 3600, "input_timeout_s": 3600, "max_witnesses": 0,
    }
    with tempfile.TemporaryDirectory() as workspace:
        manifest = Path(workspace) / "shard.jsonl"
        output = Path(workspace) / "rows.jsonl"
        manifest.write_text(json.dumps(item) + "\n", encoding="utf-8")
        subprocess.run(
            [sys.executable, str(RUNNER), "--manifest", str(manifest),
             "--output", str(output), "--watchdog-s", "6"],
            cwd=str(ROOT), text=True, capture_output=True, timeout=300,
            check=False,
        )
        if not output.is_file():
            record("the watchdog retains a row for the item it killed", False,
                   "no row written")
            return
        rows = [json.loads(ln) for ln in
                output.read_text(encoding="utf-8").splitlines() if ln.strip()]
        killed = rows and rows[0].get("outcome") == "timeout"
        record("the watchdog kills a long item", bool(killed),
               f"outcome={rows[0].get('outcome') if rows else 'none'} "
               f"after {rows[0].get('evidence', {}).get('elapsed_ms') if rows else 0} ms")
        record("the killed item is still a retained row",
               bool(rows) and not validate_row(rows[0]),
               "the timeout row carries the full schema"
               if rows and not validate_row(rows[0])
               else "; ".join(validate_row(rows[0])) if rows else "no row")


# --------------------------------------------------------------------------
# 9 and 10. The two named consumers, on a canned collection.
#
# The design's launch gate for wave 1 is that R1's consumers are confirmed
# reading before any shard runs. These checks are that confirmation: the
# readers exist, they parse the row schema the run emits, and they do it on
# rows written in the same shape the driver writes.
# --------------------------------------------------------------------------

def canned_collection(directory: Path) -> Path:
    """Two R1 rows in the shape loop_driver.pl emits them."""
    collection = directory / "2026-08-08-r1-canned"
    collection.mkdir(parents=True, exist_ok=True)
    consumer = ("scripts/research/build_automata_compendium.py:read_r1_atlas_rows"
                " + scripts/research/separation_coverage_audit.py")
    rows = [
        {
            "run": "r1", "candidate_type": "partial_coincidence",
            "source": {"family": "addition", "kind": "count_all_when_count_on_available"},
            "target": {"family": "addition", "kind": "round_without_adjusting"},
            "input": {"schema": '{"a":"integer","b":"integer"}',
                      "bounds": "bounds(a_b,2500)", "points": 2500},
            "evidence": {"kind": "coincidence_region",
                         "source_outcome": "result(75,75,correct)",
                         "target_outcome": "result(70,75,incorrect)",
                         "elapsed_ms": 4210, "ran": 2500, "coincide": 400,
                         "separate": 2100, "refused": 0, "errored": 0,
                         "full_agreement": False,
                         "separating_input_count": 2100,
                         "separating_inputs": [{"a": 47, "b": 28}, {"a": 9, "b": 2}],
                         "witnesses_truncated": False, "walk": "completed"},
            "outcome": "no_candidate", "consumer": consumer, "key": "canned-1",
        },
        {
            "run": "r1", "candidate_type": "behavioural_equivalence",
            "source": {"family": "addition", "kind": "count_all_when_count_on_available"},
            "target": {"family": "addition", "kind": "count_on_from_larger"},
            "input": {"schema": '{"a":"integer","b":"integer"}',
                      "bounds": "bounds(a_b,2500)", "points": 2500},
            "evidence": {"kind": "coincidence_region",
                         "source_outcome": "result(0,0,correct_but_inefficient)",
                         "target_outcome": "result(0,0,correct)",
                         "elapsed_ms": 3129, "ran": 2500, "coincide": 2500,
                         "separate": 0, "refused": 0, "errored": 0,
                         "full_agreement": True, "separating_input_count": 0,
                         "separating_inputs": [], "witnesses_truncated": False,
                         "walk": "completed"},
            "outcome": "certified_candidate", "consumer": consumer,
            "key": "canned-2",
        },
    ]
    (collection / "r1_rows_0000.jsonl").write_text(
        "\n".join(json.dumps(row, sort_keys=True) for row in rows) + "\n",
        encoding="utf-8",
    )
    return collection


def check_compendium_reader() -> None:
    print("\n[9] consumer — the compendium's R1 atlas reader", flush=True)
    with tempfile.TemporaryDirectory() as workspace:
        collection = canned_collection(Path(workspace))
        program = (
            "import sys, json; "
            f"sys.path.insert(0, {str(ROOT / 'scripts/research')!r}); "
            "from pathlib import Path; "
            "from build_automata_compendium import read_r1_atlas_rows as R; "
            f"rows = R(Path({str(collection)!r})); "
            "print(json.dumps([[r.source_kind, r.target_kind, r.coincide, "
            "r.separate, r.full_agreement, len(r.separating_inputs), "
            "r.outcome] for r in rows]))"
        )
        completed = subprocess.run(
            [sys.executable, "-c", program], cwd=str(ROOT), text=True,
            capture_output=True, timeout=300, check=False,
        )
        if completed.returncode:
            record("read_r1_atlas_rows reads a canned collection", False,
                   completed.stderr.strip()[:220])
            return
        parsed = json.loads(completed.stdout.strip().splitlines()[-1])
        record("read_r1_atlas_rows reads a canned collection", len(parsed) == 2,
               f"{len(parsed)} pair rows: {parsed}")
        equivalence = [row for row in parsed if row[4]]
        record("the full-agreement pair survives the read", len(equivalence) == 1,
               f"{len(equivalence)} row(s) flagged full agreement")
        witnesses = [row for row in parsed if row[5] == 2]
        record("separating witnesses survive the read", len(witnesses) == 1,
               f"{len(witnesses)} row(s) carry their 2 witnesses")


def check_separation_audit() -> None:
    print("\n[10] consumer — the separation-coverage audit", flush=True)
    audit = ROOT / "scripts/research/separation_coverage_audit.py"
    with tempfile.TemporaryDirectory() as workspace:
        collection = canned_collection(Path(workspace))
        completed = subprocess.run(
            [sys.executable, str(audit), "--collection", str(collection),
             "--print-only"],
            cwd=str(ROOT), text=True, capture_output=True, timeout=600,
            check=False,
        )
        if completed.returncode:
            record("the audit runs on a canned collection", False,
                   completed.stderr.strip()[:220])
            return
        report = completed.stdout
        rows_read = re.search(r"R1 pair rows read: (\d+)", report)
        joinable = re.search(r"joinable ones\): (\d+)", report)
        instances = re.search(r"task instances read: (\d+)", report)
        record("the audit runs on a canned collection", bool(rows_read),
               f"read {rows_read.group(1) if rows_read else '?'} rows, "
               f"{joinable.group(1) if joinable else '?'} joinable")
        record("the audit joins the curriculum task instances",
               bool(instances) and int(instances.group(1)) > 0,
               f"{instances.group(1) if instances else '0'} task instances joined")
        record("the audit names the collection it read",
               str(collection) in report,
               "the report carries its source path")


# --------------------------------------------------------------------------
# 11. R2 — the directed replay, per-side retention, and the lens thresholds.
# --------------------------------------------------------------------------

def run_item_rows(item: dict, timeout: int = 300) -> list[dict]:
    """Every row the driver writes for one item, not just the first."""
    completed = subprocess.run(
        ["swipl", "-q", "-l", str(PATHS), "-l", str(DRIVER),
         "-g", "loop_driver:main_item", "-t", "halt"],
        cwd=str(ROOT), text=True, capture_output=True, timeout=timeout,
        input=json.dumps(item) + "\n", check=False,
    )
    rows = [json.loads(ln) for ln in completed.stdout.splitlines()
            if ln.strip().startswith("{")]
    if not rows:
        raise RuntimeError(f"driver wrote no row: {completed.stderr[:400]}")
    return rows


def check_r2_directed_walk() -> None:
    print("\n[11] R2 — one walk, two directed censuses, per-side retention",
          flush=True)
    # subtraction/take_away_base_ones refuses wherever the minuend is smaller;
    # smaller_from_larger_in_column computes there. R1 recorded 2,050 refusals
    # for this pair as ONE joint number. R2 has to split it.
    item = {
        "run": "r2",
        "source": {"family": "subtraction", "kind": "take_away_base_ones"},
        "target": {"family": "subtraction", "kind": "smaller_from_larger_in_column"},
        "pair_budget_s": 300, "input_timeout_s": 20, "max_witnesses": 200,
    }
    rows = run_item_rows(item, timeout=600)
    record("one walk emits both directed censuses", len(rows) == 2,
           f"{len(rows)} row(s)")
    if len(rows) != 2:
        return
    forward, backward = rows
    for row in rows:
        problems = validate_row(row)
        if problems:
            record("R2 rows validate against the shared schema", False,
                   "; ".join(problems))
            return
    record("R2 rows validate against the shared schema", True,
           "both directions carry every field, on their enums")
    record("both directions come from the SAME walk",
           forward["evidence"]["walked_points"]
           == backward["evidence"]["walked_points"],
           f"{forward['evidence']['walked_points']} points walked once")

    forward_released = forward["evidence"]["released_count"]
    backward_released = backward["evidence"]["released_count"]
    print(f"      {forward['source']['kind']} refuses -> "
          f"{forward['target']['kind']} receives: {forward_released} released",
          flush=True)
    print(f"      {backward['source']['kind']} refuses -> "
          f"{backward['target']['kind']} receives: {backward_released} released",
          flush=True)
    record("per-side retention recovers the asymmetry R1 could not",
           forward_released != backward_released,
           f"{forward_released} one way, {backward_released} the other — "
           "a joint refusal count cannot express this")

    released = backward if backward_released > forward_released else forward
    evidence = released["evidence"]
    record("the productive receiver's release is a candidate at lens l1",
           released["outcome"] == "certified_candidate"
           and released["candidate_lens"] == "l1",
           f"outcome={released['outcome']} lens={released['candidate_lens']} "
           f"validities={evidence['released_validity_counts']}")
    record("the witness list is capped at 200 with the count kept exact",
           len(evidence["released_witnesses"]) <= 200
           and evidence["released_count"] == backward_released
           if released is backward else True,
           f"{len(evidence['released_witnesses'])} witnesses kept of "
           f"{evidence['released_count']} released, "
           f"truncated={evidence['witnesses_truncated']}")
    witnesses = evidence["released_witnesses"]
    record("the region endpoints are retained so the region reconstructs",
           len(witnesses) >= 2,
           f"first={witnesses[0]['input'] if witnesses else None} "
           f"last={witnesses[-1]['input'] if witnesses else None}")
    record("every row names a consumer", bool(released["consumer"]),
           released["consumer"][:60])


def check_r2_pair_budget_partial() -> None:
    print("\n[12] R2: a pair-budget timeout retains both partial censuses",
          flush=True)
    item = {
        "run": "r2",
        "source": {"family": "addition", "kind": "base_ones_chunking"},
        "target": {"family": "division",
                   "kind": "missing_factor_repeated_addition"},
        "pair_budget_s": 0.02,
        "input_timeout_s": 1,
        "max_witnesses": 200,
    }
    rows = run_item_rows(item, timeout=60)
    record("the pair-budget stop emits both directed rows",
           len(rows) == 2, f"{len(rows)} row(s)")
    if len(rows) != 2:
        return
    timeout_row, sibling_row = rows
    problems = [problem for row in rows for problem in validate_row(row)]
    record("the timeout pair keeps the shared row schema", not problems,
           "; ".join(problems) or "both rows validate")
    record("both directions record the pair-budget timeout",
           all(row.get("outcome") == "timeout"
               and row.get("candidate_type") == "pair_budget_timeout"
               and row.get("evidence", {}).get("walk") == "pair_budget"
               for row in rows),
           "; ".join(
               f"{row.get('outcome')}/{row.get('candidate_type')}"
               for row in rows
           ))
    walked = [row.get("evidence", {}).get("walked_points") for row in rows]
    record("both directions retain the same nonzero partial walk",
           walked[0] == walked[1]
           and isinstance(walked[0], int)
           and 0 < walked[0] < timeout_row.get("input", {}).get("points", 0),
           f"walked_points={walked}")
    item["key"] = (
        "r2:addition/base_ones_chunking|"
        "division/missing_factor_repeated_addition"
    )
    with tempfile.TemporaryDirectory() as workspace:
        manifest = Path(workspace) / "shard.jsonl"
        output = Path(workspace) / "rows.jsonl"
        manifest.write_text(json.dumps(item) + "\n", encoding="utf-8")
        completed = subprocess.run(
            [sys.executable, str(RUNNER), "--manifest", str(manifest),
             "--output", str(output), "--watchdog-s", "30"],
            cwd=str(ROOT), text=True, capture_output=True, timeout=60,
            check=False,
        )
        retained = [json.loads(line) for line in
                    output.read_text(encoding="utf-8").splitlines()
                    if line.strip()] if output.is_file() else []
        record("the runner retains keys on both timeout-path rows",
               completed.returncode == 0 and len(retained) == 2
               and all(row.get("item_key") == item["key"]
                       and row.get("key") for row in retained),
               f"returncode={completed.returncode}; {len(retained)} row(s)")


def check_r2_external_failure_rows() -> None:
    print("\n[13] R2: external failures retain two convention-shaped rows",
          flush=True)
    item = {
        "run": "r2",
        "source": {"family": "addition", "kind": "base_ones_chunking"},
        "target": {"family": "division",
                   "kind": "missing_factor_repeated_addition"},
        "schema": '{"a":"integer","b":"integer"}',
    }

    no_row_process = Mock()
    no_row_process.communicate.return_value = (
        "", "fixture process exited before writing a row"
    )
    with patch.object(array_runner.subprocess, "Popen",
                      return_value=no_row_process):
        no_row_rows, disposition = array_runner.run_item(item, watchdog_s=30)
    no_row_sibling = no_row_rows[1] if len(no_row_rows) == 2 else {}
    record("a no-row R2 process yields its failed row and reverse sibling",
           disposition == "no_row" and len(no_row_rows) == 2
           and no_row_rows[0].get("candidate_type") == "no_row"
           and no_row_sibling.get("outcome") == "not_walked"
           and no_row_sibling.get("evidence", {}).get("reason")
               == "sibling_no_row",
           f"disposition={disposition}; {len(no_row_rows)} row(s); "
           f"reason={no_row_sibling.get('evidence', {}).get('reason')}")

    timeout_process = Mock()
    timeout_process.communicate.side_effect = [
        subprocess.TimeoutExpired(cmd="swipl", timeout=1),
        ("", ""),
    ]
    with patch.object(array_runner.subprocess, "Popen",
                      return_value=timeout_process):
        timeout_rows, disposition = array_runner.run_item(item, watchdog_s=1)
    shapes = [set((row.get("evidence") or {}).keys()) for row in timeout_rows]
    record("watchdog rows use one R2 evidence kind and field set",
           disposition == "timeout" and len(timeout_rows) == 2
           and all(row.get("evidence", {}).get("kind") == "failed_derivation"
                   for row in timeout_rows)
           and shapes[0] == shapes[1],
           f"disposition={disposition}; field_counts="
           f"{[len(shape) for shape in shapes]}")
    timeout_sibling = timeout_rows[1] if len(timeout_rows) == 2 else {}
    record("the watchdog sibling names the external failure class",
           timeout_sibling.get("outcome") == "not_walked"
           and timeout_sibling.get("evidence", {}).get("reason")
               == "sibling_watchdog_timeout",
           f"reason={timeout_sibling.get('evidence', {}).get('reason')}")


def lens_probe(refuser: str, receiver: str, validities: list[str],
               out_region: int) -> tuple[str, dict]:
    """Call release_quality/2 and r2_lens/8 on a constructed released region."""
    released = ", ".join(
        f"released(point({index}), {validity}, result(0,0,{validity}))"
        for index, validity in enumerate(validities)
    )
    refuser_family, refuser_kind = refuser.split("/")
    receiver_family, receiver_kind = receiver.split("/")
    goal = (
        f"Released = [{released}], "
        "loop_driver:release_quality(Released, Quality), "
        f"loop_driver:r2_lens(machine({refuser_family},{refuser_kind}), "
        f"machine({receiver_family},{receiver_kind}), Released, {out_region}, "
        "Quality, Lens, Flags, _), "
        # get_dict/3 rather than Flags.l1: functional dict notation needs goal
        # expansion, which a -g goal does not get.
        "get_dict(l1, Flags, L1), get_dict(l2, Flags, L2), "
        "get_dict(l3, Flags, L3), "
        "format('LENS ~w~n', [Lens]), "
        "format('FLAGS ~w ~w ~w ~w~n', [Quality, L1, L2, L3])"
    )
    lens, detail = "?", {}
    for line in swipl(goal).splitlines():
        if line.startswith("LENS "):
            lens = line.split(None, 1)[1].strip()
        elif line.startswith("FLAGS "):
            quality, l1, l2, l3 = line.split()[1:5]
            detail = {"quality": quality, "l1": l1, "l2": l2, "l3": l3}
    return lens, detail


def check_r2_lenses() -> None:
    print("\n[14] R2 — the L2 thresholds and the accidentally_correct exclusion",
          flush=True)
    deformation = "multiplication/add_instead_of_multiply"   # registered
    productive = "subtraction/take_away_base_ones"           # not registered

    lens, flags = lens_probe("multiplication/repeat_equal_groups", deformation,
                             ["correct"] * 12, 1)
    record("a registered deformation, strong on 12 released points, "
           "incorrect elsewhere, is l2", lens == "l2",
           f"lens={lens} flags={flags}")

    lens, flags = lens_probe("multiplication/repeat_equal_groups", deformation,
                             ["correct"] * 9, 1)
    record("nine strong points is below the L2 threshold", lens != "l2",
           f"lens={lens} (the ruling says >=10)")

    lens, flags = lens_probe("multiplication/repeat_equal_groups", deformation,
                             ["correct"] * 12, 0)
    record("no out-of-region incorrect point is not l2", lens != "l2",
           f"lens={lens} — without it the viability is not shown to be regional")

    lens, flags = lens_probe("multiplication/repeat_equal_groups", deformation,
                             ["accidentally_correct"] * 20, 5)
    record("an accidentally_correct-only release is EXCLUDED",
           lens == "unlensed" and flags["quality"] == "unlicensed",
           f"lens={lens} quality={flags['quality']} — isolated-point "
           "coincidence keeps rust")

    lens, flags = lens_probe("subtraction/smaller_from_larger_in_column",
                             productive, ["correct", "correct_but_inefficient"], 0)
    record("a non-deformation receiver on clean validity is l1", lens == "l1",
           f"lens={lens} — inefficiency is not error")

    lens, flags = lens_probe("multiplication/repeat_equal_groups", deformation,
                             ["contextually_correct"] * 11, 2)
    record("contextually_correct counts toward the L2 threshold", lens == "l2",
           f"lens={lens} flags={flags}")


def check_r2_resume() -> None:
    print("\n[15] R2 — resume idempotence across a two-row item", flush=True)
    item = {
        "run": "r2",
        "key": "r2:geometry/angle_as_ray_length|geometry/angle_turn_measurement",
        "source": {"family": "geometry", "kind": "angle_as_ray_length"},
        "target": {"family": "geometry", "kind": "angle_turn_measurement"},
        "pair_budget_s": 60, "input_timeout_s": 20, "max_witnesses": 200,
    }
    singleton = {
        "run": "r2",
        "key": "r2:probability/terminal_tree_endpoint_probability_sum|no_receiver",
        "source": {"family": "probability",
                   "kind": "terminal_tree_endpoint_probability_sum"},
        "no_receiver": True,
    }
    with tempfile.TemporaryDirectory() as workspace:
        manifest = Path(workspace) / "shard.jsonl"
        output = Path(workspace) / "rows.jsonl"
        manifest.write_text(
            json.dumps(item) + "\n" + json.dumps(singleton) + "\n",
            encoding="utf-8")
        counts = []
        for _ in range(2):
            subprocess.run(
                [sys.executable, str(RUNNER), "--manifest", str(manifest),
                 "--output", str(output)],
                cwd=str(ROOT), text=True, capture_output=True, timeout=600,
                check=False,
            )
            if not output.is_file():
                record("R2 resume idempotence", False, "first run wrote nothing")
                return
            counts.append(len([ln for ln in
                               output.read_text(encoding="utf-8").splitlines()
                               if ln.strip()]))
        record("a two-row item plus a no-receiver item writes three rows",
               counts[0] == 3, f"{counts[0]} row(s) after the first run")
        record("R2 resume idempotence", counts[0] == counts[1],
               f"{counts[0]} then {counts[1]} — the second run adds "
               f"{counts[1] - counts[0]}")
        rows = [json.loads(ln) for ln in
                output.read_text(encoding="utf-8").splitlines() if ln.strip()]
        no_receiver = [row for row in rows
                       if row.get("candidate_type") == "no_receiver"]
        record("a schema singleton records uninstantiated(no_receiver)",
               len(no_receiver) == 1
               and no_receiver[0]["outcome"] == "uninstantiated",
               f"{len(no_receiver)} no-receiver row, "
               f"outcome={no_receiver[0]['outcome'] if no_receiver else 'none'}")


# --------------------------------------------------------------------------
# 16-18. R3 — the depth-1 kernel re-derivation sweep.
#
# One machine that re-derives, one that does not, and one budget that stops the
# walk. The three together are what keeps a resister row readable: a miss and a
# stop must never wear the same candidate_type, or absence starts reading as a
# measured result.
# --------------------------------------------------------------------------

R3_DRIVER = ROOT / "scripts/bigred/loops/r3_driver.pl"


def run_r3_item(item: dict, timeout: int = 600) -> dict:
    completed = subprocess.run(
        ["swipl", "-q", "-l", str(PATHS), "-l", str(R3_DRIVER),
         "-g", "r3_driver:main_item", "-t", "halt"],
        cwd=str(ROOT), text=True, capture_output=True, timeout=timeout,
        input=json.dumps(item) + "\n", check=False,
    )
    line = next((ln for ln in completed.stdout.splitlines()
                 if ln.strip().startswith("{")), "")
    if not line:
        raise RuntimeError(f"r3_driver wrote no row: {completed.stderr[:400]}")
    return json.loads(line)


def r3_swipl(goal: str, timeout: int = 300) -> str:
    completed = subprocess.run(
        ["swipl", "-q", "-l", str(PATHS), "-l", str(R3_DRIVER), "-g", goal,
         "-t", "halt"],
        cwd=str(ROOT), text=True, capture_output=True, timeout=timeout,
        check=False,
    )
    if completed.returncode:
        raise RuntimeError(
            f"goal failed ({completed.returncode}): "
            f"{completed.stderr.strip()[:600]}"
        )
    return completed.stdout


def check_r3_known_dependency() -> None:
    print("\n[16] R3 — a known kernel dependency re-derives at depth 1",
          flush=True)
    # counting/recursive_place_value_inscription calls K6 and returns the
    # kernel's numeral unchanged (counting_action_pairs.pl:343-357). It is the
    # ground truth for a hit: if the sweep cannot find this one, it can find
    # nothing.
    item = {
        "run": "r3",
        "source": {"family": "counting",
                   "kind": "recursive_place_value_inscription"},
        "machine_budget_s": 120, "composition_timeout_s": 10,
    }
    row = run_r3_item(item)
    evidence = row["evidence"]
    print(f"      space : {evidence['compositions_enumerated']} depth-1 "
          f"compositions, {evidence['compositions_applicable']} applicable "
          f"at the first screen point", flush=True)
    print(f"      walk  : probed {evidence['grid_points_probed']} of "
          f"{evidence['grid_points_available']} grid points, "
          f"{evidence['machine_computed']} computed, "
          f"{evidence['machine_refused']} refused", flush=True)
    print(f"      row   : {row['outcome']} / {row['candidate_type']} in "
          f"{evidence['elapsed_ms']} ms", flush=True)

    problems = validate_row(row)
    record("the R3 row validates against the shared output schema",
           not problems,
           "; ".join(problems) or "every field present and on its enum")
    record("the known dependency is certified at depth 1",
           row["outcome"] == "certified_candidate"
           and row["candidate_type"] == "kernel_dependency",
           f"outcome={row['outcome']} type={row['candidate_type']}")
    record("the bridge proof is byte-identical, not numeric",
           evidence["kind"] == "byte_identical_bridge"
           and evidence["source_outcome"] == evidence["target_outcome"],
           f"machine and composition both answered "
           f"{evidence['source_outcome'][:56]}")
    tested = len(evidence["screen_inputs"]) + len(evidence["verification_inputs"])
    record("the row carries all 110 inputs the candidacy rests on",
           tested == 110 and evidence["evidence_strength"] == "design",
           f"{len(evidence['screen_inputs'])} screened + "
           f"{len(evidence['verification_inputs'])} verified = {tested}")
    record("the winning kernel is named on the row",
           row["target"]["kind"] == "recollect_base_cycles",
           f"target={row['target']}")

    # Receipt executability: the row's composition is a term, not a caption.
    # Read the printed string back and run it against the row's own first
    # screen input; an unbindable receipt licenses nothing.
    composition = evidence["candidate_compositions"][0]
    first_input = json.dumps(evidence["screen_inputs"][0])
    goal = (
        "use_module(library(http/json)), "
        f"term_string(Composition, {json.dumps(composition)}), "
        f"atom_json_dict({json.dumps(first_input)}, Input, "
        "[value_string_as(string)]), "
        "r3_driver:apply_composition(Composition, Input, Result), "
        "format('REPLAY ~q~n', [Result])"
    )
    replayed = ""
    for line in r3_swipl(goal).splitlines():
        if line.startswith("REPLAY "):
            replayed = line.split(None, 1)[1].strip()
    record("the recorded composition re-runs from its printed string",
           replayed == evidence["source_outcome"],
           f"replay gave {replayed[:56]!r}")


def check_r3_measured_resister() -> None:
    print("\n[17] R3 — a machine with no depth-1 composition is a MEASURED "
          "resister", flush=True)
    item = {
        "run": "r3",
        "source": {"family": "addition", "kind": "base_ones_chunking"},
        "machine_budget_s": 120, "composition_timeout_s": 10,
    }
    row = run_r3_item(item)
    evidence = row["evidence"]
    print(f"      machine answers {evidence['source_outcome'][:64]}", flush=True)
    print(f"      searched {evidence['compositions_enumerated']} compositions, "
          f"{evidence['compositions_applicable']} ran, "
          f"{evidence['compositions_screen_passed']} passed the screen",
          flush=True)

    problems = validate_row(row)
    record("the resister row validates against the shared output schema",
           not problems,
           "; ".join(problems) or "every field present and on its enum")
    record("an exhausted search is a measured resister, not a silence",
           row["outcome"] == "no_candidate"
           and row["candidate_type"] == "measured_resister"
           and evidence["walk"] == "completed",
           f"type={row['candidate_type']} walk={evidence['walk']}")
    record("the resister row says how much was searched",
           evidence["compositions_enumerated"] > 0
           and evidence["compositions_applicable"] > 0
           and evidence["compositions_truncated"] is False,
           f"{evidence['compositions_applicable']} of "
           f"{evidence['compositions_enumerated']} compositions ran; "
           f"truncated={evidence['compositions_truncated']}")
    record("the two kernels depth 1 cannot bind are named on the row",
           sorted(evidence["kernels_unbindable"])
           == ["compare_place_sequences_by_significance",
               "refine_bracket_by_order"],
           ", ".join(evidence["kernels_unbindable"]))
    record("every R3 row names a consumer", bool(row["consumer"]),
           row["consumer"][:60])


def check_r3_budget_guard() -> None:
    print("\n[18] R3 — a spent machine budget yields an explicit row",
          flush=True)
    item = {
        "run": "r3",
        "source": {"family": "addition", "kind": "base_ones_chunking"},
        "machine_budget_s": 0.02, "composition_timeout_s": 1,
    }
    row = run_r3_item(item, timeout=120)
    evidence = row["evidence"]
    print(f"      row   : {row['outcome']} / {row['candidate_type']}, "
          f"walk={evidence['walk']}", flush=True)

    problems = validate_row(row)
    record("the budget-stop row keeps the shared output schema", not problems,
           "; ".join(problems) or "every field present and on its enum")
    record("a spent budget is a timeout and never a resister",
           row["outcome"] == "timeout"
           and row["candidate_type"] == "machine_budget_exhausted"
           and evidence["walk"] == "machine_budget",
           f"outcome={row['outcome']} type={row['candidate_type']} "
           f"walk={evidence['walk']}")

    # The verdict itself, called directly: a budget stop outranks an exhausted
    # search even when the search found nothing and enumerated everything, and
    # it outranks an unconfirmed screen-passer too.
    goal = (
        "r3_driver:r3_verdict([], [], machine_budget, false, \"design\", "
        "OutcomeA, TypeA, _), format('V1 ~w ~w~n', [OutcomeA, TypeA]), "
        "r3_driver:r3_verdict([], [], completed, false, \"design\", "
        "OutcomeB, TypeB, _), format('V2 ~w ~w~n', [OutcomeB, TypeB]), "
        "r3_driver:r3_verdict([], [comp(1,k,g,[])], machine_budget, false, "
        "\"design\", OutcomeC, TypeC, _), format('V3 ~w ~w~n', [OutcomeC, TypeC])"
    )
    verdicts = {}
    for line in r3_swipl(goal).splitlines():
        for tag in ("V1", "V2", "V3"):
            if line.startswith(tag + " "):
                verdicts[tag] = line.split(None, 1)[1].strip()
    record("the verdict separates a stop from an exhausted search",
           verdicts.get("V1") == "timeout machine_budget_exhausted"
           and verdicts.get("V2") == "no_candidate measured_resister",
           f"stopped -> {verdicts.get('V1')!r}; "
           f"exhausted -> {verdicts.get('V2')!r}")
    record("a stop outranks an unconfirmed screen-passer",
           verdicts.get("V3") == "timeout machine_budget_exhausted",
           f"budget + unverified -> {verdicts.get('V3')!r}")

    # The cumulative budget is checked INSIDE a confirmation run, so a budget
    # that dies partway through 100 held-out inputs stops gracefully instead of
    # waiting for the external watchdog.
    goal = (
        "get_time(T), "
        "r3_driver:agrees_on([], c, 10, T, 0, Empty), "
        "format('EMPTY ~w~n', [Empty]), "
        "r3_driver:agrees_on([point(point(1), 1)], c, 10, T, 0, Dead), "
        "format('DEAD ~w~n', [Dead]), "
        "r3_driver:screened(budget, c, [x], T, 0, 10, 50, "
        "  st(tally(1,0,0,0), [], [], none, completed), State), "
        "format('SCREENED ~w~n', [State]), "
        "Input = _{n:3}, "
        "Composition = comp(2, "
        "  comp(1,complete_to_unit,whole_number(const(10)),[part(in(n))]), "
        "  comp(1,partition_regroup,integer_line, "
        "       [unit(prior),plan(partition(in(n)))])), "
        "r3_driver:apply_composition(Composition, Input, Result), "
        "get_time(D2Now), D2Started is D2Now - 1, "
        "r3_driver:step_composition(Composition, [point(Input,Result)], "
        "  [point(Input,Result)], D2Started, 0.5, limits(10,5), "
        "  st(tally(0,0,0,0),[],[],none,completed), D2State), "
        "D2State = st(D2Tally,D2Candidates,D2Unverified,D2Nearest,D2Stopped), "
        "r3_driver:candidate_row(2, machine(fixture,depth_2), "
        "  _{schema:fixture,bounds:\"fixture\",points:2}, D2Started, "
        "  probe(2,2,2,0,0), sizes(1,1,1,0,false,1,1,false), "
        "  [leaf(n,3)], [point(Input,Result)], [point(Input,Result)], "
        "  D2Tally, D2Candidates, D2Unverified, D2Nearest, D2Stopped, "
        "  D2Row), "
        "get_dict(outcome, D2Row, D2Outcome), "
        "get_dict(candidate_type, D2Row, D2Type), "
        "get_dict(evidence, D2Row, D2Evidence), "
        "get_dict(walk, D2Evidence, D2Walk), "
        "get_dict(candidate_compositions, D2Evidence, D2CandidateStrings), "
        "get_dict(unverified_compositions, D2Evidence, D2UnverifiedStrings), "
        "length(D2UnverifiedStrings, D2UnverifiedCount), "
        "format('D2BUDGET ~w ~w ~w ~q ~w~n', "
        "       [D2Outcome,D2Type,D2Walk,D2CandidateStrings,D2UnverifiedCount])"
    )
    signals = {}
    for line in r3_swipl(goal).splitlines():
        for tag in ("EMPTY", "DEAD", "SCREENED", "D2BUDGET"):
            if line.startswith(tag + " "):
                signals[tag] = line.split(None, 1)[1].strip()
    record("a budget that dies inside a confirmation stops gracefully",
           signals.get("DEAD") == "budget"
           and signals.get("EMPTY") == "agreed"
           and "machine_budget" in signals.get("SCREENED", ""),
           f"empty={signals.get('EMPTY')} dead_budget={signals.get('DEAD')} "
           f"screened={signals.get('SCREENED')}")
    record("a depth-2 verification budget death writes a graceful non-candidate row",
           signals.get("D2BUDGET")
           == "timeout machine_budget_exhausted machine_budget [] 1",
           f"row={signals.get('D2BUDGET')}")


def check_r3_unverified_and_strength() -> None:
    print("\n[19] R3 — an absent confirmation set never certifies, and a small "
          "item never certifies itself", flush=True)
    # Six screen points and no held-out points: the composition that answered
    # every screen point is real, and nothing confirms it. Certifying here
    # would make `byte_identical_bridge` mean "agreed with the inputs that
    # chose it".
    item = {
        "run": "r3",
        "source": {"family": "counting",
                   "kind": "recursive_place_value_inscription"},
        "machine_budget_s": 120, "composition_timeout_s": 10,
        "sample_count": 6, "verify_count": 0,
    }
    row = run_r3_item(item)
    evidence = row["evidence"]
    print(f"      screen {evidence['screen_size']}, verification "
          f"{evidence['verification_size']}, "
          f"{evidence['compositions_screen_passed']} passed the screen",
          flush=True)
    problems = validate_row(row)
    record("the unverified row validates against the shared output schema",
           not problems,
           "; ".join(problems) or "every field present and on its enum")
    record("a screen-passer with no held-out set is NOT certified",
           row["outcome"] == "no_candidate"
           and row["candidate_type"] == "kernel_dependency_unverified"
           and evidence["kind"] == "failed_derivation"
           and evidence["candidate_compositions"] == []
           and row["target"]["kind"] is None,
           f"outcome={row['outcome']} type={row['candidate_type']} "
           f"kind={evidence['kind']}")
    record("the unconfirmed composition stays on the row, out of the "
           "candidate list",
           len(evidence["unverified_compositions"]) == 1
           and "recollect_base_cycles" in evidence["unverified_compositions"][0],
           f"{len(evidence['unverified_compositions'])} unverified: "
           f"{evidence['unverified_compositions'][0][:60] if evidence['unverified_compositions'] else None}")

    # evidence_strength reads the DRIVER's defaults, not the item's, so an item
    # that lowers the counts cannot stamp its own row as a full run.
    small = {
        "run": "r3",
        "source": {"family": "counting",
                   "kind": "recursive_place_value_inscription"},
        "machine_budget_s": 120, "composition_timeout_s": 10,
        "sample_count": 2, "verify_count": 3,
    }
    small_row = run_r3_item(small)
    small_evidence = small_row["evidence"]
    record("a five-input item reads grid_limited, never design",
           small_evidence["evidence_strength"] == "grid_limited"
           and small_row["candidate_type"] == "kernel_dependency_thin_evidence"
           and small_evidence["screen_size_required"] == 110,
           f"strength={small_evidence['evidence_strength']} "
           f"type={small_row['candidate_type']} "
           f"required={small_evidence['screen_size_required']} against "
           f"{small_evidence['screen_size'] + small_evidence['verification_size']} tested")

    # The external failure path: R3 walks one machine, so it retains one row,
    # and that row must not read as a search that finished.
    failed_process = Mock()
    failed_process.communicate.return_value = (
        "", "fixture process exited before writing a row"
    )
    with patch.object(array_runner.subprocess, "Popen",
                      return_value=failed_process):
        rows, disposition = array_runner.run_item(
            item, watchdog_s=30, driver=R3_DRIVER)
    record("an R3 process that writes no row still leaves one behind",
           disposition == "no_row" and len(rows) == 1
           and rows[0]["run"] == "r3"
           and rows[0]["candidate_type"] == "no_row"
           and rows[0]["evidence"]["walk"] == "no_row",
           f"disposition={disposition}; {len(rows)} row(s); "
           f"type={rows[0]['candidate_type'] if rows else None}")


# --------------------------------------------------------------------------
# 20-22. R3 depth 2 — executable chaining, a miss, and eligibility accounting.
# --------------------------------------------------------------------------

def check_r3_depth2_composition() -> None:
    print("\n[20] R3 depth 2 — one result feeds a second kernel application",
          flush=True)
    goal = (
        "Input = _{n:3}, "
        "Composition = comp(2, "
        "  comp(1,complete_to_unit,whole_number(const(10)),[part(in(n))]), "
        "  comp(1,partition_regroup,integer_line,"
        "       [unit(prior),plan(partition(in(n)))])), "
        "r3_driver:apply_composition(Composition, Input, Result), "
        "get_time(T), "
        "r3_driver:search([Composition], [point(Input,Result)], "
        "  [point(Input,Result)], T, 60, limits(10,5), "
        "  st(tally(0,0,0,0),[],[],none,completed), State), "
        "format('D2HIT ~q ~q~n', [Result,State]), "
        "r3_driver:candidate_row(2, machine(fixture,depth_2), "
        "  _{schema:fixture,bounds:\"fixture\",points:2}, T, "
        "  probe(2,2,2,0,0), sizes(1,1,1,0,false,1,1,false), "
        "  [leaf(n,3)], [point(Input,Result)], [point(Input,Result)], "
        "  tally(1,1,1,1), [Composition], [], none, completed, Row), "
        "get_dict(evidence, Row, Evidence), "
        "get_dict(candidate_kernels, Evidence, CandidateKernels), "
        "format('D2ROW ~q~n', [CandidateKernels]), "
        "r3_driver:composition_count(2,[leaf(a,1),leaf(b,2)],Count), "
        "format('D2COUNT ~w~n', [Count])"
    )
    signals = {}
    for line in r3_swipl(goal).splitlines():
        if line.startswith("D2HIT "):
            signals["hit"] = line.split(None, 1)[1]
        if line.startswith("D2COUNT "):
            signals["count"] = int(line.split()[1])
        if line.startswith("D2ROW "):
            signals["kernels"] = line.split(None, 1)[1]
    hit = signals.get("hit", "")
    record("the fixture-authored depth-2 receipt runs both kernels",
           hit.startswith("made(3,part_unit(3,complement(7))) "), hit[:120])
    record("the depth-2 receipt clears strict identity on screen and verify",
           "tally(1,1,1,1)" in hit and "comp(2," in hit, hit[-180:])
    record("a depth-2 candidate row lists both kernels in execution order",
           signals.get("kernels")
           == "[complete_to_unit,partition_regroup]",
           f"candidate_kernels={signals.get('kernels')}")
    record("the two-leaf authored depth-2 space is measured near the design bar",
           signals.get("count") == 27324,
           f"{signals.get('count')} compositions")


def check_r3_depth2_miss() -> None:
    print("\n[21] R3 depth 2 — a disagreement stays a miss and a real row says "
          "depth 2", flush=True)
    goal = (
        "Input = _{n:3}, "
        "Composition = comp(2, "
        "  comp(1,complete_to_unit,whole_number(const(10)),[part(in(n))]), "
        "  comp(1,partition_regroup,integer_line,"
        "       [unit(prior),plan(partition(in(n)))])), "
        "get_time(T), "
        "r3_driver:search([Composition], "
        "  [point(Input,made(2,part_unit(2,complement(7))))], [], "
        "  T, 60, limits(10,5), "
        "  st(tally(0,0,0,0),[],[],none,completed), State), "
        "format('D2MISS ~q~n', [State])"
    )
    miss = next((line.split(None, 1)[1] for line in r3_swipl(goal).splitlines()
                 if line.startswith("D2MISS ")), "")
    record("a depth-2 disagreement does not enter either candidate list",
           miss.startswith("st(tally(1,0,0,0),[],[],"), miss)

    item = {
        "run": "r3", "depth": 2,
        "source": {"family": "addition", "kind": "base_ones_chunking"},
        "machine_budget_s": 120, "composition_timeout_s": 10,
        "sample_count": 2, "verify_count": 3, "max_compositions": 40,
    }
    row = run_r3_item(item)
    evidence = row["evidence"]
    problems = validate_row(row)
    record("the depth-2 miss row keeps the shared output schema", not problems,
           "; ".join(problems) or "every field present and on its enum")
    record("every field carrying search depth reads 2",
           evidence["depth"] == 2 and row["candidate_type"] == "search_truncated",
           f"depth={evidence['depth']} type={row['candidate_type']}")
    record("the row distinguishes total space from the attempted prefix",
           evidence["compositions_enumerated"] > 40
           and evidence["compositions_attempted"] == 40,
           f"{evidence['compositions_attempted']} attempted of "
           f"{evidence['compositions_enumerated']}")
    record("depth 2 names only the still-unbindable rational-bracket kernel",
           evidence["kernels_unbindable"] == ["refine_bracket_by_order"],
           repr(evidence["kernels_unbindable"]))

    failed_process = Mock()
    failed_process.communicate.return_value = (
        "", "depth-2 fixture process exited before writing a row"
    )
    with patch.object(array_runner.subprocess, "Popen",
                      return_value=failed_process):
        rows, disposition = array_runner.run_item(
            item, watchdog_s=30, driver=R3_DRIVER)
    record("an external depth-2 failure row also carries depth 2",
           disposition == "no_row" and len(rows) == 1
           and rows[0]["evidence"]["depth"] == 2
           and rows[0]["evidence"]["compositions_attempted"] == 0,
           f"disposition={disposition}; depth="
           f"{rows[0]['evidence']['depth'] if rows else None}")


def check_r3_depth2_eligibility() -> None:
    print("\n[22] R3 depth 2 — the collected depth-1 census governs eligibility",
          flush=True)
    census = step0.r3_depth2_collection_census(step0.R3_DEPTH1_COLLECTION)
    counts = census["counts"]
    record("the collection accounts for all 246 depth-1 machines",
           len(census["rows"]) == 246
           and len(census["eligible"]) == 209
           and len(census["excluded"]) == 37,
           f"{len(census['eligible'])} eligible + "
           f"{len(census['excluded'])} excluded = {len(census['rows'])}")
    record("the eligible population is 206 resisters plus 3 insufficient rows",
           counts["measured_resister"]
           + counts["measured_resister_thin_grid"] == 206
           and counts["insufficient_computed_samples"] == 3,
           f"resisters={counts['measured_resister'] + counts['measured_resister_thin_grid']} "
           f"insufficient={counts['insufficient_computed_samples']}")
    hits = {"counting/recursive_place_value_inscription",
            "counting/inscribe_cardinality"}
    record("both depth-1 hits are absent from the eligible set",
           hits.isdisjoint(census["eligible"])
           and all(census["excluded"].get(key) == "certified at depth 1"
                   for key in hits),
           ", ".join(sorted(hits)))

    output = io.StringIO()
    with redirect_stdout(output):
        step0.print_r3_depth2_collection_census(census)
    printed = output.getvalue()
    record("the exclusion census prints all three reasons and accounting",
           "excluded depth-1 hits       : 2 -> certified at depth 1" in printed
           and "excluded never-computed     : 30 -> unsearchable" in printed
           and "excluded uninstantiated     : 5 -> unsearchable" in printed
           and "accounted                   : 246/246" in printed,
           "hits=2, never-computed=30, uninstantiated=5, accounted=246/246")

    machines = [
        {"family": "counting", "kind": "recursive_place_value_inscription"},
        {"family": "addition", "kind": "base_ones_chunking"},
    ]
    small_census = {"eligible": {"addition/base_ones_chunking"}}
    eligible = step0.filter_r3_depth2_machines(machines, small_census)
    with tempfile.TemporaryDirectory() as directory:
        shards = step0.write_r3_shards(
            eligible, Path(directory), 4, {},
            {"depth": 2, "machine_budget_s": 2700,
             "composition_timeout_s": 120, "sample_count": 10,
             "verify_count": 100, "max_compositions": 0},
        )
        manifest_rows = [json.loads(line) for line in
                         shards[0].read_text(encoding="utf-8").splitlines()]
    record("a depth-1 hit cannot appear in a depth-2 manifest",
           len(manifest_rows) == 1
           and manifest_rows[0]["source"]["kind"] == "base_ones_chunking"
           and manifest_rows[0]["depth"] == 2,
           repr(manifest_rows))


# --------------------------------------------------------------------------
# 23-27. R4 — the contract-bridge adapter search.
#
# A pair the authored library genuinely bridges, a pair whose unit relabel has
# no witness and therefore certifies nothing, two kinds of miss that must not
# wear one name, a spent budget, and the library itself. The warrant refusal is
# the one these five exist for: an adapter that fits mechanically and drops a
# unit is the type-level pun the design's ceremony refuses by rule, and a run
# that could not tell it from a bridge would hand the ceremony the pun.
# --------------------------------------------------------------------------

R4_DRIVER = ROOT / "scripts/bigred/loops/r4_driver.pl"
R4_ADAPTERS = ROOT / "scripts/bigred/loops/r4_adapters.pl"
R4_DOCKET = ROOT / "scripts/bigred/loops/r4_admission_docket.py"


def run_r4_item(item: dict, timeout: int = 600) -> dict:
    completed = subprocess.run(
        ["swipl", "-q", "-l", str(PATHS), "-l", str(R4_DRIVER),
         "-g", "r4_driver:main_item", "-t", "halt"],
        cwd=str(ROOT), text=True, capture_output=True, timeout=timeout,
        input=json.dumps(item) + "\n", check=False,
    )
    line = next((ln for ln in completed.stdout.splitlines()
                 if ln.strip().startswith("{")), "")
    if not line:
        raise RuntimeError(f"r4_driver wrote no row: {completed.stderr[:400]}")
    return json.loads(line)


def r4_swipl(goal: str, timeout: int = 300) -> str:
    completed = subprocess.run(
        ["swipl", "-q", "-l", str(PATHS), "-l", str(R4_DRIVER), "-g", goal,
         "-t", "halt"],
        cwd=str(ROOT), text=True, capture_output=True, timeout=timeout,
        check=False,
    )
    if completed.returncode:
        raise RuntimeError(
            f"goal failed ({completed.returncode}): "
            f"{completed.stderr.strip()[:600]}"
        )
    return completed.stdout


def check_r4_bridge_hit() -> None:
    print("\n[23] R4 — a pair the authored library genuinely bridges",
          flush=True)
    # The source's answer becomes the target's first operand and the target's
    # second operand is threaded from the source's own input: on the grid point
    # {a:12, b:24} that is 12 + 24 = 36, then 36 - 24. A two-step task, and the
    # smallest honest one.
    item = {
        "run": "r4",
        "source": {"family": "addition", "kind": "base_ones_chunking"},
        "target": {"family": "subtraction", "kind": "count_up_missing_addend"},
        "adapter": "identity",
        "sample_count": 6, "pair_budget_s": 120, "input_timeout_s": 10,
    }
    row = run_r4_item(item)
    evidence = row["evidence"]
    print(f"      adapter : {evidence['adapter']} "
          f"{evidence['adapter_signature']}", flush=True)
    print(f"      landing : {evidence['placement_path']} "
          f"(placement {evidence['placement_index']} of "
          f"{evidence['placements_available']}, "
          f"{evidence['placements_run']} run)", flush=True)
    print(f"      samples : {evidence['samples_bridged']} bridged of "
          f"{evidence['samples_available']} the source computed on, "
          f"{evidence['grid_points_probed']} grid points probed", flush=True)
    print(f"      row     : {row['outcome']} / {row['candidate_type']} in "
          f"{evidence['elapsed_ms']} ms", flush=True)

    problems = validate_row(row)
    record("the bridge row validates against the shared output schema",
           not problems,
           "; ".join(problems) or "every field present and on its enum")
    record("a pair bridged on every computed sample is a candidate",
           row["outcome"] == "certified_candidate"
           and row["candidate_type"].startswith("contract_bridge")
           and evidence["kind"] == "adapted_execution_bridge",
           f"type={row['candidate_type']} kind={evidence['kind']} "
           f"{evidence['samples_bridged']}/{evidence['samples_available']}")
    record("the landing slot is on the row, so the bridge is executable",
           evidence["placement_path"] == ".a"
           and evidence["placement_index"] == 1,
           f"placement {evidence['placement_index']} at "
           f"{evidence['placement_path']}")

    records = evidence["sample_records"]
    record("every sample carries all three warrant records",
           bool(records) and all(
               sample["units"] and sample["roles"] and sample["boundary"]
               for sample in records),
           f"{len(records)} sample record(s), each with units, roles and "
           f"boundary")
    record("the roles record names where each slot's value came from",
           bool(records)
           and "threaded from the source input" in records[0]["roles"]
           and ".a" in records[0]["roles"],
           records[0]["roles"] if records else "no records")

    # Receipt executability: the adapted input on the row is re-run through the
    # target machine here, and must reproduce the row's own target result. A
    # receipt nobody can bind licenses nothing.
    replay = next((sample for sample in records
                   if sample["adapted_input"] and sample["target_result"]), None)
    if replay is None:
        record("the recorded adapted input re-runs", False,
               "no sample carried both an adapted input and a target result")
    else:
        goal = (
            "use_module(library(http/json)), "
            "atom_json_dict('%s', Input, [value_string_as(string)]), "
            "loop_driver:aa_run(subtraction, count_up_missing_addend, Input, "
            "Outcome), term_string(Outcome, S), format('REPLAY ~w~n', [S])"
            % json.dumps(replay["adapted_input"]).replace("'", "\\'")
        )
        replayed = ""
        for line in r4_swipl(goal).splitlines():
            if line.startswith("REPLAY "):
                replayed = line.split(None, 1)[1].strip()
        record("the recorded adapted input re-runs to the recorded result",
               replayed == replay["target_result"],
               f"{replay['adapted_input']} -> {replayed!r} against the row's "
               f"{replay['target_result']!r}")

    # A ROW WHOSE CARRIED VALUE IS A RATIONAL, because JSON has none.
    # statistics/mean_as_fair_share answers rational(27,5); row 12 carries it as
    # 27 rdiv 5 into a positive_number slot; json_write_dict writes 5.4. The
    # float is NOT what the target machine received, so the receipt binds only
    # through carried_value_exact.
    rational_row = run_r4_item({
        "run": "r4",
        "source": {"family": "statistics", "kind": "mean_as_fair_share"},
        "target": {"family": "geometry",
                   "kind": "polygon_perimeter_boundary_accumulation"},
        "adapter": "project_rational_magnitude",
        "sample_count": 8, "pair_budget_s": 120, "input_timeout_s": 10,
    })
    rational_evidence = rational_row["evidence"]
    exact_sample = next(
        (sample for sample in rational_evidence["sample_records"]
         if sample["status"] == "bridged"
         and "r" in str(sample["carried_value_exact"])), None)
    if exact_sample is None:
        record("a rational carried value is recorded exactly", False,
               "no bridged sample carried a rational")
    else:
        floated = exact_sample["adapted_input"]["sides"][0]
        print(f"      rational: carried {exact_sample['carried_value_exact']}, "
              f"written to JSON as {floated}", flush=True)
        record("a rational carried value is recorded exactly beside its float",
               isinstance(floated, float)
               and str(exact_sample["carried_value_exact"]) != str(floated),
               f"carried_value_exact={exact_sample['carried_value_exact']!r} "
               f"against adapted_input {floated!r}")

        # Rebuild the adapted input by putting the exact value back at the
        # placement path, and re-run. The float must NOT reproduce the row.
        goal = (
            "use_module(library(http/json)), "
            "term_string(Exact, \"%s\"), "
            "Rebuilt = _{kind: \"polygon_sides_with_unit\", sides: [Exact], "
            "            unit: \"%s\"}, "
            "loop_driver:aa_run(geometry, polygon_perimeter_boundary_accumulation, "
            "                   Rebuilt, ExactOutcome), "
            "term_string(ExactOutcome, ExactString), "
            "format('EXACT ~w~n', [ExactString]), "
            "Floated = _{kind: \"polygon_sides_with_unit\", sides: [%r], "
            "            unit: \"%s\"}, "
            "loop_driver:aa_run(geometry, polygon_perimeter_boundary_accumulation, "
            "                   Floated, FloatOutcome), "
            "term_string(FloatOutcome, FloatString), "
            "format('FLOAT ~w~n', [FloatString])"
            % (exact_sample["carried_value_exact"],
               exact_sample["adapted_input"]["unit"],
               floated,
               exact_sample["adapted_input"]["unit"])
        )
        replays = {}
        for line in r4_swipl(goal).splitlines():
            for tag in ("EXACT", "FLOAT"):
                if line.startswith(tag + " "):
                    replays[tag] = line.split(None, 1)[1].strip()
        record("the exact value rebinds the receipt and the float does not",
               replays.get("EXACT") == exact_sample["target_result"]
               and replays.get("FLOAT") != exact_sample["target_result"],
               f"exact -> {replays.get('EXACT')!r}; "
               f"float -> {replays.get('FLOAT')!r}; "
               f"row -> {exact_sample['target_result']!r}")


def check_r4_warrant_refusal() -> None:
    print("\n[24] R4 — a unit relabel computes nothing without a witness, and "
          "the inverse of a declared witness is one", flush=True)
    # RULING R1 (2026-08-10): a declared factor licenses its own inverse,
    # because one yard being three feet is one fact and not two.
    # measurement/unit_conversion_by_iteration answers quantity(Count x Factor,
    # foot); the target contract's from_unit is the unit OF its count and
    # threads from the source's own input to yard. The sample declares
    # scaling(yard, foot, Factor), so the relabel reads its inverse and the
    # magnitude returns to the count it started from — eleven feet back to one
    # yard, which is a bridge and lands on an integer slot exactly.
    inverse = run_r4_item({
        "run": "r4",
        "source": {"family": "measurement", "kind": "unit_conversion_by_iteration"},
        "target": {"family": "measurement",
                   "kind": "change_unit_label_without_scaling"},
        "adapter": "unit_relabel_with_scaling_witness",
        "sample_count": 8, "pair_budget_s": 120, "input_timeout_s": 10,
    })
    inverse_evidence = inverse["evidence"]
    inverse_sample = next((sample for sample in
                           inverse_evidence["sample_records"]
                           if sample["status"] == "bridged"), None)
    print(f"      inverse : {inverse['candidate_type']}, "
          f"{inverse_evidence['samples_bridged']} bridged on "
          f"{inverse_evidence['distinct_adapted_inputs']} distinct inputs",
          flush=True)
    if inverse_sample:
        print(f"        {inverse_sample['units']}", flush=True)
    problems = validate_row(inverse)
    record("the inverse-witness row validates against the shared schema",
           not problems,
           "; ".join(problems) or "every field present and on its enum")
    record("the inverse of a declared witness licenses the relabel",
           inverse["outcome"] == "certified_candidate"
           and inverse_sample is not None
           and "inverted(scaling(" in inverse_sample["units"],
           f"type={inverse['candidate_type']}; units="
           f"{inverse_sample['units'] if inverse_sample else None!r}")
    record("the row says which direction it read the witness in",
           inverse_sample is not None
           and "the inverse of the declared witness"
           in inverse_sample["transform"],
           inverse_sample["transform"] if inverse_sample else "no sample")

    # AND THE REFUSAL MOVES TO BOUNDARY, which is where it belongs.
    # measurement/change_unit_label_without_scaling is the misconception: it
    # relabels yards as feet without scaling, so it answers quantity(Count,
    # foot) and the honest inverse gives Count/Factor yards — one eleventh of a
    # yard, which an integer count slot cannot hold. The bridge is dimensionally
    # sound and the target contract cannot take it.
    row = run_r4_item({
        "run": "r4",
        "source": {"family": "measurement",
                   "kind": "change_unit_label_without_scaling"},
        "target": {"family": "measurement",
                   "kind": "unit_conversion_by_iteration"},
        "adapter": "unit_relabel_with_scaling_witness",
        "sample_count": 8, "pair_budget_s": 120, "input_timeout_s": 10,
    })
    evidence = row["evidence"]
    refusals = evidence["warrant_refusals"]
    print(f"      source answers {evidence['source_outcome']}", flush=True)
    print(f"      refusals : {refusals}", flush=True)

    problems = validate_row(row)
    record("the warrant-refusal row validates against the shared schema",
           not problems,
           "; ".join(problems) or "every field present and on its enum")
    record("an unscaled relabel is a refusal, not a bridge",
           row["outcome"] == "no_candidate"
           and row["candidate_type"] == "warrant_refused"
           and evidence["samples_bridged"] == 0
           and evidence["kind"] == "failed_derivation",
           f"type={row['candidate_type']} bridged="
           f"{evidence['samples_bridged']} kind={evidence['kind']}")
    record("under ruling R1 the refusal reads boundary, and names the value",
           bool(refusals)
           and all(entry["obligation"] == "boundary" for entry in refusals)
           and any("outside integer" in entry["reason"]
                   for entry in refusals),
           "; ".join(f"{entry['obligation']}: {entry['reason']}"
                     for entry in refusals) or "no refusal recorded")

    # Row 5 must not quietly do row 6's work: offered the same relabel with no
    # mode to license it, carry_measured_magnitude still refuses at units.
    preserved = run_r4_item({
        "run": "r4",
        "source": {"family": "measurement", "kind": "unit_conversion_by_iteration"},
        "target": {"family": "measurement",
                   "kind": "change_unit_label_without_scaling"},
        "adapter": "carry_measured_magnitude",
        "sample_count": 6, "pair_budget_s": 120, "input_timeout_s": 10,
    })
    preserved_refusals = preserved["evidence"]["warrant_refusals"]
    record("the preserving row still refuses a relabel it is not licensed for",
           preserved["candidate_type"] == "warrant_refused"
           and any("relabelled_without_witness" in entry["reason"]
                   for entry in preserved_refusals),
           "; ".join(entry["reason"] for entry in preserved_refusals)
           or "no refusal recorded")

    # A dimension change is refused too, and for a different reason: the only
    # witness shape the library admits relates two NAMED units by a factor, and
    # square(centimeter) is not a named unit. Carrying an area into a linear
    # unit slot is geometry/linear_unit_for_area_or_volume, a modelled
    # misconception rather than a bridge.
    area_item = {
        "run": "r4",
        "source": {"family": "geometry", "kind": "area_unit_covering"},
        "target": {"family": "geometry", "kind": "count_overlapping_area_tiles"},
        "adapter": "carry_measured_magnitude",
        "sample_count": 4, "pair_budget_s": 120, "input_timeout_s": 10,
    }
    area_row = run_r4_item(area_item)
    area_refusals = area_row["evidence"]["warrant_refusals"]
    record("a dimension change has no witness and is refused as one",
           area_row["candidate_type"] == "warrant_refused"
           and any("unit_not_nameable" in entry["reason"]
                   for entry in area_refusals),
           "; ".join(entry["reason"] for entry in area_refusals)
           or "no refusal recorded")

    # The rule itself, called directly, so the fixture tests the library's
    # semantics and not only one pair's luck.
    goal = (
        "r4_adapters:unit_disposition(unit(foot), unit(yard), [], relabel, A), "
        "format('NOWITNESS ~w~n', [A]), "
        "r4_adapters:unit_disposition(unit(foot), unit(yard), "
        "  [scaling(foot, yard, 3)], relabel, B), format('WITNESS ~w~n', [B]), "
        "r4_adapters:unit_disposition(unit(centimeter), none, [], preserve, C), "
        "format('DROPPED ~w~n', [C]), "
        "r4_adapters:unit_disposition(unit(inch), unit(inch), [], preserve, D), "
        "format('PRESERVED ~w~n', [D]), "
        "r4_adapters:unit_disposition(unit(foot), unit(yard), "
        "  [scaling(yard, foot, 3)], relabel, E), format('INVERSE ~w~n', [E]), "
        "r4_adapters:unit_disposition(unit(foot), unit(yard), "
        "  [scaling(yard, foot, 0)], relabel, F), format('ZERO ~w~n', [F])"
    )
    dispositions = {}
    for line in r4_swipl(goal).splitlines():
        for tag in ("NOWITNESS", "WITNESS", "DROPPED", "PRESERVED", "INVERSE",
                    "ZERO"):
            if line.startswith(tag + " "):
                dispositions[tag] = line.split(None, 1)[1].strip()
    record("the units rule refuses a witnessless relabel and admits a witnessed one",
           dispositions.get("NOWITNESS") == "relabelled_without_witness(foot,yard)"
           and dispositions.get("WITNESS") == "rescaled(foot,yard,3)",
           f"without -> {dispositions.get('NOWITNESS')!r}; "
           f"with -> {dispositions.get('WITNESS')!r}")
    record("a declared witness licenses its inverse, and a zero factor does not",
           dispositions.get("INVERSE")
           == "rescaled(foot,yard,1r3,inverted(scaling(yard,foot,3)))"
           and dispositions.get("ZERO")
           == "relabelled_without_witness(foot,yard)",
           f"inverse -> {dispositions.get('INVERSE')!r}; "
           f"zero factor -> {dispositions.get('ZERO')!r}")
    record("a target with no unit slot drops the unit, and that is a refusal",
           dispositions.get("DROPPED") == "dropped(centimeter)"
           and dispositions.get("PRESERVED") == "preserved(inch)",
           f"no slot -> {dispositions.get('DROPPED')!r}; "
           f"same unit -> {dispositions.get('PRESERVED')!r}")


def check_r4_misses() -> None:
    print("\n[25] R4 — the two kinds of miss do not wear one name", flush=True)
    # The target machine declines the adapted input. The adapter did its work;
    # the machine's own domain refused the result. Calling that an
    # incompatibility of the library would put the blame in the wrong place.
    declined = run_r4_item({
        "run": "r4",
        "source": {"family": "addition", "kind": "base_ones_chunking"},
        "target": {"family": "addition", "kind": "make_ten_split_leftover"},
        "adapter": "identity",
        "sample_count": 5, "pair_budget_s": 120, "input_timeout_s": 10,
    })
    declined_evidence = declined["evidence"]
    print(f"      declined: {declined['candidate_type']}, "
          f"{declined_evidence['samples_target_refused']} sample(s) the target "
          f"machine would not take", flush=True)
    problems = validate_row(declined)
    record("the target-refusal row validates against the shared schema",
           not problems,
           "; ".join(problems) or "every field present and on its enum")
    record("a target machine that declines is not a measured incompatibility",
           declined["candidate_type"] == "target_refused"
           and declined_evidence["samples_target_refused"] > 0
           and declined_evidence["walk"] == "completed",
           f"type={declined['candidate_type']} declined="
           f"{declined_evidence['samples_target_refused']}")

    # A target contract with a slot neither the adapter nor the source's own
    # input reaches. Nothing is invented to fill it; the row names the path.
    unreachable = run_r4_item({
        "run": "r4",
        "source": {"family": "geometry",
                   "kind": "rectangle_perimeter_boundary_traversal"},
        "target": {"family": "geometry", "kind": "parallelogram_area_base_height"},
        "adapter": "carry_measured_magnitude",
        "sample_count": 4, "pair_budget_s": 120, "input_timeout_s": 10,
    })
    unreachable_evidence = unreachable["evidence"]
    unfilled = [sample["unfilled_path"]
                for sample in unreachable_evidence["sample_records"]
                if sample["unfilled_path"]]
    print(f"      unreachable: {unreachable['candidate_type']}, "
          f"unfilled {unfilled}", flush=True)
    record("an unfillable slot is a measured incompatibility naming the path",
           unreachable["candidate_type"] == "measured_incompatible"
           and bool(unfilled),
           f"type={unreachable['candidate_type']} unfilled={unfilled}")
    record("nothing was invented to fill it",
           unreachable_evidence["samples_bridged"] == 0
           and all(sample["adapted_input"] is None
                   for sample in unreachable_evidence["sample_records"]),
           f"{unreachable_evidence['samples_bridged']} bridged; no adapted "
           f"input was built")

    # TWENTY BRIDGED SAMPLES ARE NOT TWENTY PIECES OF EVIDENCE. The carried
    # value overwrites the slot it lands in, so two grid inputs can produce one
    # adapted input. division/divide_larger_by_smaller carried into the single
    # typed slot of a signed-number list is the case: every sample bridges and
    # the quotients repeat.
    correlated = run_r4_item({
        "run": "r4",
        "source": {"family": "division", "kind": "divide_larger_by_smaller"},
        "target": {"family": "integer",
                   "kind": "signed_number_location_and_order"},
        "adapter": "project_quotient",
        "sample_count": 20, "pair_budget_s": 120, "input_timeout_s": 10,
    })
    correlated_evidence = correlated["evidence"]
    print(f"      correlated: {correlated_evidence['samples_bridged']} bridged "
          f"on {correlated_evidence['distinct_adapted_inputs']} distinct "
          f"adapted inputs -> {correlated['candidate_type']}", flush=True)
    record("a bridged sample count is not a distinct-input count",
           correlated_evidence["samples_bridged"]
           > correlated_evidence["distinct_adapted_inputs"]
           and correlated_evidence["distinct_adapted_inputs"] > 0,
           f"{correlated_evidence['samples_bridged']} bridged from "
           f"{correlated_evidence['distinct_adapted_inputs']} distinct inputs")
    record("evidence strength keys on the distinct count, not the sample count",
           correlated["candidate_type"] == "contract_bridge_thin_evidence"
           and correlated_evidence["evidence_strength"] == "grid_limited",
           f"type={correlated['candidate_type']} "
           f"strength={correlated_evidence['evidence_strength']} on "
           f"{correlated_evidence['distinct_adapted_inputs']} of "
           f"{correlated_evidence['samples_required']} required")

    # The counter itself, called directly: two structurally identical adapted
    # inputs are ONE, even though each dict carries its own fresh tag variable
    # and ==/2 therefore separates them.
    goal = (
        "dict_pairs(A, _, [a-1, b-2]), dict_pairs(B, _, [a-1, b-2]), "
        "dict_pairs(C, _, [a-9, b-2]), "
        "r4_driver:distinct_adapted_inputs("
        "  [ _{status: \"bridged\", adapted_input: A}, "
        "    _{status: \"bridged\", adapted_input: B}, "
        "    _{status: \"bridged\", adapted_input: C}, "
        "    _{status: \"target_refused\", adapted_input: C} ], N), "
        "format('DISTINCT ~w~n', [N]), "
        "( A == B -> Same = yes ; Same = no ), format('IDENTICAL ~w~n', [Same])"
    )
    counted = {}
    for line in r4_swipl(goal).splitlines():
        for tag in ("DISTINCT", "IDENTICAL"):
            if line.startswith(tag + " "):
                counted[tag] = line.split(None, 1)[1].strip()
    record("identical adapted inputs count once, despite distinct dict tags",
           counted.get("DISTINCT") == "2" and counted.get("IDENTICAL") == "no",
           f"three bridged records, two shapes -> {counted.get('DISTINCT')} "
           f"distinct; raw ==/2 says identical={counted.get('IDENTICAL')}")

    # The verdict itself, called directly, on the priority the ceremony reads.
    goal = (
        "r4_driver:r4_verdict(0, 5, 0, 2, completed, \"design\", "
        "  [_{obligation: \"units\", reason: \"r\", samples: 1}], 0, OA, TA), "
        "format('V1 ~w ~w~n', [OA, TA]), "
        "r4_driver:r4_verdict(0, 5, 0, 2, completed, \"design\", [], 5, OB, TB), "
        "format('V2 ~w ~w~n', [OB, TB]), "
        "r4_driver:r4_verdict(0, 5, 0, 2, pair_budget, \"design\", [], 5, OC, TC), "
        "format('V3 ~w ~w~n', [OC, TC]), "
        "r4_driver:r4_verdict(5, 5, 5, 2, completed, \"design\", [], 0, OD, TD), "
        "format('V4 ~w ~w~n', [OD, TD]), "
        "r4_driver:r4_verdict(5, 5, 5, 2, completed, \"grid_limited\", [], 0, OE, TE), "
        "format('V5 ~w ~w~n', [OE, TE]), "
        "r4_driver:r4_verdict(20, 20, 1, 2, completed, \"design\", [], 0, OF, TF), "
        "format('V6 ~w ~w~n', [OF, TF])"
    )
    verdicts = {}
    for line in r4_swipl(goal).splitlines():
        for tag in ("V1", "V2", "V3", "V4", "V5", "V6"):
            if line.startswith(tag + " "):
                verdicts[tag] = line.split(None, 1)[1].strip()
    record("the verdict keeps a warrant refusal apart from a target refusal",
           verdicts.get("V1") == "no_candidate warrant_refused"
           and verdicts.get("V2") == "no_candidate target_refused",
           f"warrant -> {verdicts.get('V1')!r}; "
           f"target -> {verdicts.get('V2')!r}")
    record("a spent budget outranks every miss",
           verdicts.get("V3") == "timeout pair_budget_exhausted",
           f"budget + declines -> {verdicts.get('V3')!r}")
    record("a thin grid certifies under its own name, never the design's",
           verdicts.get("V4") == "certified_candidate contract_bridge"
           and verdicts.get("V5")
           == "certified_candidate contract_bridge_thin_evidence",
           f"design -> {verdicts.get('V4')!r}; "
           f"grid_limited -> {verdicts.get('V5')!r}")
    record("twenty bridges on one distinct input certify nothing",
           verdicts.get("V6") == "no_candidate insufficient_distinct_inputs",
           f"20 bridged, 1 distinct -> {verdicts.get('V6')!r}")


def check_r4_budget_guard() -> None:
    print("\n[26] R4 — a spent (pair, adapter) budget yields an explicit row",
          flush=True)
    item = {
        "run": "r4",
        "source": {"family": "addition", "kind": "base_ones_chunking"},
        "target": {"family": "subtraction", "kind": "count_up_missing_addend"},
        "adapter": "identity",
        "sample_count": 6, "pair_budget_s": 0.001, "input_timeout_s": 1,
    }
    row = run_r4_item(item, timeout=120)
    evidence = row["evidence"]
    print(f"      row : {row['outcome']} / {row['candidate_type']}, "
          f"walk={evidence['walk']}", flush=True)
    problems = validate_row(row)
    record("the budget-stop row keeps the shared output schema", not problems,
           "; ".join(problems) or "every field present and on its enum")
    record("a spent budget is a timeout and never an incompatibility",
           row["outcome"] == "timeout"
           and row["candidate_type"] == "pair_budget_exhausted"
           and evidence["walk"] == "pair_budget",
           f"outcome={row['outcome']} type={row['candidate_type']} "
           f"walk={evidence['walk']}")

    # The external failure path: R4 walks one (pair, adapter) per item, so it
    # retains one row, and that row must not read as a search that finished.
    failed_process = Mock()
    failed_process.communicate.return_value = (
        "", "fixture process exited before writing a row"
    )
    with patch.object(array_runner.subprocess, "Popen",
                      return_value=failed_process):
        rows, disposition = array_runner.run_item(
            item, watchdog_s=30, driver=R4_DRIVER)
    record("an R4 process that writes no row still leaves one behind",
           disposition == "no_row" and len(rows) == 1
           and rows[0]["run"] == "r4"
           and rows[0]["candidate_type"] == "no_row"
           and rows[0]["evidence"]["walk"] == "no_row"
           and rows[0]["evidence"]["adapter"] == "identity",
           f"disposition={disposition}; {len(rows)} row(s); "
           f"type={rows[0]['candidate_type'] if rows else None}")


def check_r4_library() -> None:
    print("\n[27] R4 — the adapter library is complete and self-consistent",
          flush=True)
    goal = (
        "r4_adapters:adapter_count(N), format('COUNT ~w~n', [N]), "
        "forall(r4_adapters:adapter(Id, signature(A, R, P), Obligations), "
        "  format('ROW ~w|~w|~w|~w|~w~n', [Id, A, R, P, Obligations])), "
        "aggregate_all(count, r4_adapters:uncarried(_, _), U), "
        "format('UNCARRIED ~w~n', [U])"
    )
    rows = []
    count = 0
    uncarried = 0
    for line in r4_swipl(goal).splitlines():
        if line.startswith("COUNT "):
            count = int(line.split()[1])
        elif line.startswith("UNCARRIED "):
            uncarried = int(line.split()[1])
        elif line.startswith("ROW "):
            rows.append(line[4:].split("|"))
    for identifier, accepts, route, produces, obligations in rows:
        print(f"      {identifier:36s} {accepts} via {route} -> {produces}  "
              f"{obligations}", flush=True)

    record("the library carries the design's twelve rows",
           count == 12 and len(rows) == 12,
           f"{count} adapter/3 rows")
    record("every row declares units, roles and boundary",
           all("units" in obligations and "roles" in obligations
               and "boundary" in obligations
               for *_, obligations in rows),
           "; ".join(f"{identifier}={obligations}"
                     for identifier, *_, obligations in rows[:2]) + " ...")
    record("the shapes the library will not carry are named, not silent",
           uncarried >= 5,
           f"{uncarried} uncarried shape class(es) recorded")

    # Every row must have a transform clause, or the manifest would offer items
    # nothing can run. adapt/6 is called with a carrier of the kind the row
    # declares it reads, and must either produce or refuse — never fail.
    goal = (
        "forall(( r4_adapters:adapter_id(Id), "
        "         fixture_carrier(Kind, Carrier, Route), "
        "         r4_adapters:adapter_reads(Id, Kind, Route) ), "
        "( ( r4_adapters:adapt(Id, Carrier, Route, "
        "      context(unit(yard), [scaling(foot, yard, 3)]), Produced, _) "
        "  -> functor(Produced, F, _) ; F = no_clause ), "
        "  format('ADAPT ~w ~w~n', [Id, F]) ))"
    )
    helper = (
        "fixture_carrier(magnitude_dimensionless, magnitude(6, dimensionless), "
        "  direct). "
        "fixture_carrier(magnitude_dimensionless, magnitude(6, dimensionless), "
        "  unwrapped(1)). "
        "fixture_carrier(magnitude_with_unit, magnitude(6, unit(foot)), "
        "  field(quantity/2)). "
        "fixture_carrier(fraction, fraction(3, 4), field(fraction/2)). "
        "fixture_carrier(decimal, decimal(28, 10), field(decimal/3)). "
        "fixture_carrier(quotient_remainder, quotient_remainder(6, 2), "
        "  field(quotient_remainder/2))."
    )
    with tempfile.NamedTemporaryFile("w", suffix=".pl", delete=False) as handle:
        handle.write(helper + "\n")
        helper_path = Path(handle.name)
    try:
        completed = subprocess.run(
            ["swipl", "-q", "-l", str(PATHS), "-l", str(R4_DRIVER),
             "-l", str(helper_path), "-g", goal, "-t", "halt"],
            cwd=str(ROOT), text=True, capture_output=True, timeout=300,
            check=False,
        )
        reached = {}
        for line in completed.stdout.splitlines():
            if line.startswith("ADAPT "):
                _, identifier, functor = line.split()
                reached.setdefault(identifier, set()).add(functor)
    finally:
        helper_path.unlink(missing_ok=True)

    # A row whose Route is `direct` only sees the direct carrier, and one whose
    # Route is `unwrapped` only sees the unwrapped one; the goal above offers
    # both, so every row should have been exercised at least once.
    missing = [identifier for identifier, *_ in rows
               if identifier not in reached]
    no_clause = sorted(identifier for identifier, functors in reached.items()
                       if functors == {"no_clause"})
    record("every row in the library has a transform clause that runs",
           not missing and not no_clause,
           f"unexercised={missing or 'none'}; without a clause="
           f"{no_clause or 'none'}")

    # The relabel row, offered a carrier whose unit already matches, must not
    # quietly do the other row's work.
    goal = (
        "r4_adapters:adapt(unit_relabel_with_scaling_witness, "
        "  magnitude(6, unit(yard)), field('quantity/2'), "
        "  context(unit(yard), []), Produced, _), "
        "term_string(Produced, S), format('SAMEUNIT ~w~n', [S])"
    )
    same_unit = ""
    for line in r4_swipl(goal).splitlines():
        if line.startswith("SAMEUNIT "):
            same_unit = line.split(None, 1)[1].strip()
    record("the relabel row declines a sample that needs no relabel",
           same_unit == "refused(no_relabel_required(yard))",
           f"same unit -> {same_unit!r}")

    # An item naming an adapter outside the library gets a row saying so. A
    # manifest typo that failed the item instead would surface as a dead
    # process, which reads as the cluster's fault rather than the manifest's.
    unknown = run_r4_item({
        "run": "r4",
        "source": {"family": "addition", "kind": "base_ones_chunking"},
        "target": {"family": "addition", "kind": "count_on_from_larger"},
        "adapter": "an_adapter_the_library_does_not_carry",
    })
    problems = validate_row(unknown)
    record("an item naming an adapter outside the library gets a row saying so",
           not problems
           and unknown["candidate_type"] == "no_adapter_row"
           and unknown["outcome"] == "uninstantiated"
           and len(unknown["evidence"]["adapter_obligations"]) == 12,
           f"type={unknown['candidate_type']}; "
           f"{'; '.join(problems) or 'row valid'}; "
           f"{len(unknown['evidence']['adapter_obligations'])} known rows "
           f"listed on it")


# --------------------------------------------------------------------------
# 28. R4 admission docket — anchored collection, census, bands, and blanks.
# --------------------------------------------------------------------------

def check_r4_docket_fixture() -> None:
    print("\n[28] R4 docket — anchored rows, census, bands, and blank verdicts",
          flush=True)

    def row(key: str, source_family: str, source_kind: str,
            target_family: str, target_kind: str, candidate_type: str,
            outcome: str, adapter: str, distinct: int = 0,
            bridged: int = 0) -> dict:
        return {
            "run": "r4",
            "key": key,
            "item_key": f"fixture-{key}",
            "source": {"family": source_family, "kind": source_kind},
            "target": {"family": target_family, "kind": target_kind},
            "candidate_type": candidate_type,
            "outcome": outcome,
            "evidence": {
                "adapter": adapter,
                "distinct_adapted_inputs": distinct,
                "samples_bridged": bridged,
                "sample_records": [],
            },
        }

    rows = [
        row("typed-rank-first", "addition", "fixture_source",
            "multiplication", "fixture_target", "contract_bridge",
            "certified_candidate", "project_quotient", 9, 9),
        row("typed-seam-weight", "fraction", "fixture_source",
            "division", "fixture_target", "contract_bridge",
            "certified_candidate", "integer_over_one_to_fraction_object",
            8, 20),
        row("identity-same", "addition", "fixture_source_a",
            "addition", "fixture_target_a", "contract_bridge",
            "certified_candidate", "identity", 6, 6),
        row("identity-cross", "addition", "fixture_source_b",
            "subtraction", "fixture_target_b",
            "contract_bridge_thin_evidence", "certified_candidate",
            "identity", 3, 5),
        row("identity-same-thin", "geometry", "fixture_source_a",
            "geometry", "fixture_target_a",
            "contract_bridge_thin_evidence", "certified_candidate",
            "identity", 2, 4),
        row("warrant", "measurement", "fixture_source",
            "geometry", "fixture_target", "warrant_refused",
            "no_candidate", "carry_measured_magnitude"),
        row("incompatible", "ratio", "fixture_source",
            "algebraic", "fixture_target", "measured_incompatible",
            "no_candidate", "identity"),
        row("target", "counting", "fixture_source",
            "integer", "fixture_target", "target_refused",
            "no_candidate", "identity"),
        row("source", "statistics", "fixture_source",
            "calculus", "fixture_target", "source_never_computed",
            "no_candidate", "identity"),
        {
            "run": "r4",
            "key": "malformed-target",
            "item_key": "fixture-malformed-target",
            "source": {"family": "addition", "kind": "fixture_malformed"},
            "target": {"family": "subtraction"},
            "candidate_type": "fixture_malformed",
            "outcome": "no_candidate",
            "evidence": {"adapter": "identity", "sample_records": []},
        },
    ]

    with tempfile.TemporaryDirectory() as workspace:
        root = Path(workspace)
        collection = root / "rows"
        output = root / "docket"
        collection.mkdir()
        shard_text = "\n".join(
            json.dumps(item, sort_keys=True) for item in rows
        ) + "\n"
        (collection / "r4_rows_0003.jsonl").write_text(
            shard_text, encoding="utf-8"
        )
        (collection / "r4_rows_0003 2.jsonl").write_text(
            shard_text, encoding="utf-8"
        )
        (collection / "r4_rows_0004.jsonl").write_text(
            "\n\n", encoding="utf-8"
        )
        completed = subprocess.run(
            [sys.executable, str(R4_DOCKET), "--rows", str(collection),
             "--output-dir", str(output), "--witnesses", "1"],
            cwd=str(ROOT), text=True, capture_output=True, timeout=60,
            check=False,
        )
        if completed.returncode:
            raise RuntimeError(
                f"docket exited {completed.returncode}: "
                f"{completed.stderr.strip()[:400]}"
            )
        docket_path = output / "2026-08-10-r4-admission-docket.json"
        payload = json.loads(docket_path.read_text(encoding="utf-8"))

    print(f"      files   : {payload['row_files_read']} counted, "
          f"{len(payload['row_files_skipped'])} skipped; "
          f"{payload['recomputed_counts']['rows_total']} rows",
          flush=True)
    record("the docket counts anchored shards, including an empty one, once",
           payload["row_files_read"] == 2
           and payload["recomputed_counts"]["row_files"] == 2
           and payload["recomputed_counts"]["rows_total"] == 10
           and payload["row_files_skipped"] == ["r4_rows_0003 2.jsonl"],
           f"counted={payload['row_files_read']}; "
           f"skipped={payload['row_files_skipped']}; "
           f"rows={payload['recomputed_counts']['rows_total']}")

    record("the docket excludes malformed machines from its ordered-pair count",
           payload["rows_lacking_a_machine"] == 1
           and payload["recomputed_counts"]["ordered_pairs"] == 9,
           f"malformed={payload['rows_lacking_a_machine']}; "
           f"ordered_pairs={payload['recomputed_counts']['ordered_pairs']}")

    expected_counts = {
        "certified_candidates": 5,
        "contract_bridge": 3,
        "contract_bridge_thin_evidence": 2,
        "warrant_refused": 1,
        "measured_incompatible": 1,
        "target_refused": 1,
        "source_never_computed": 1,
    }
    measured_counts = {
        key: payload["recomputed_counts"][key] for key in expected_counts
    }
    print(f"      census  : {measured_counts}", flush=True)
    record("the docket recomputes the constructed outcome census exactly",
           measured_counts == expected_counts,
           f"measured={measured_counts}; expected={expected_counts}")

    typed = payload["band_one_typed_converters"]
    identity = payload["band_two_identity_bridges"]
    typed_keys = [item["source_row"]["key"] for item in typed]
    same_keys = [item["source_row"]["key"]
                 for item in identity["same_family"]]
    cross_keys = [item["source_row"]["key"]
                  for item in identity["cross_family"]]
    seam_row = next(
        item for item in typed
        if item["source_row"]["key"] == "typed-seam-weight"
    )
    print(f"      bands   : typed={typed_keys}; same={same_keys}; "
          f"cross={cross_keys}; seam={seam_row['seam_relevant']}",
          flush=True)
    record("the docket applies the ruled bands and mechanical identity split",
           typed_keys == ["typed-rank-first", "typed-seam-weight"]
           and same_keys == ["identity-same", "identity-same-thin"]
           and cross_keys == ["identity-cross"]
           and seam_row["band"] == "typed_converters"
           and seam_row["seam_relevant"] == [1],
           f"typed={typed_keys}; same={same_keys}; cross={cross_keys}; "
           f"seam={seam_row['seam_relevant']}")

    print(f"      weight  : {seam_row['distinct_adapted_inputs']} distinct from "
          f"{seam_row['samples_bridged']} bridged samples; rank "
          f"{seam_row['rank']}", flush=True)
    record("the docket reads distinct adapted inputs as evidence weight",
           seam_row["distinct_adapted_inputs"] == 8
           and seam_row["samples_bridged"] == 20
           and seam_row["rank"] == 2,
           f"weight={seam_row['distinct_adapted_inputs']}; "
           f"samples={seam_row['samples_bridged']}; rank={seam_row['rank']}")

    emitted = typed + identity["same_family"] + identity["cross_family"]
    blanks = sum(item.get("question_preservation") == "" for item in emitted)
    print(f"      verdict : {blanks}/{len(emitted)} question-preservation "
          "fields blank", flush=True)
    record("the docket leaves question preservation blank on every row",
           blanks == len(emitted),
           f"{blanks}/{len(emitted)} emitted rows carry an empty field")


def main() -> int:
    print("Big Red loop substrate — offline fixture checks", flush=True)
    print(f"repo: {ROOT}", flush=True)
    for check in (check_schema_coverage, check_aa_run, check_same_archetype,
                  check_archetype_map_against_tree, check_r1_walk,
                  check_r5_reproduction, check_resume, check_watchdog,
                  check_compendium_reader, check_separation_audit,
                  check_r2_directed_walk, check_r2_pair_budget_partial,
                  check_r2_external_failure_rows,
                  check_r2_lenses, check_r2_resume,
                  check_r3_known_dependency, check_r3_measured_resister,
                  check_r3_budget_guard, check_r3_unverified_and_strength,
                  check_r3_depth2_composition, check_r3_depth2_miss,
                  check_r3_depth2_eligibility,
                  check_r4_bridge_hit, check_r4_warrant_refusal,
                  check_r4_misses, check_r4_budget_guard, check_r4_library,
                  check_r4_docket_fixture):
        try:
            check()
        except Exception as error:  # a broken check is a failure, not a skip
            record(check.__name__, False, f"raised {type(error).__name__}: {error}")

    failures = [name for name, ok, _ in RESULTS if not ok]
    print(f"\n{len(RESULTS) - len(failures)}/{len(RESULTS)} checks pass",
          flush=True)
    for name in failures:
        print(f"  FAILED: {name}", flush=True)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
