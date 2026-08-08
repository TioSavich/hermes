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

    print(f"      {'status':14s} {'grid':28s} {'pts':>5s} {'enum':>5s} "
          f"{'mach':>4s}", flush=True)
    for row in rows:
        print(f"      {row[0]:14s} {row[1][:28]:28s} {row[2]:>5s} {row[3]:>5s} "
              f"{row[4]:>4s}", flush=True)

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
            "resource_error", "uninstantiated"}
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


def main() -> int:
    print("Big Red loop substrate — offline fixture checks", flush=True)
    print(f"repo: {ROOT}", flush=True)
    for check in (check_schema_coverage, check_aa_run, check_same_archetype,
                  check_archetype_map_against_tree, check_r1_walk,
                  check_r5_reproduction, check_resume, check_watchdog,
                  check_compendium_reader, check_separation_audit):
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
