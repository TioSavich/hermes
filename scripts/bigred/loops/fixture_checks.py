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
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from unittest.mock import Mock, patch

import run_loop_array as array_runner

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
                  "byte_identical_bridge", "trace_match"}


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


def main() -> int:
    print("Big Red loop substrate — offline fixture checks", flush=True)
    print(f"repo: {ROOT}", flush=True)
    for check in (check_schema_coverage, check_aa_run, check_same_archetype,
                  check_archetype_map_against_tree, check_r1_walk,
                  check_r5_reproduction, check_resume, check_watchdog,
                  check_compendium_reader, check_separation_audit,
                  check_r2_directed_walk, check_r2_pair_budget_partial,
                  check_r2_external_failure_rows,
                  check_r2_lenses, check_r2_resume):
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
