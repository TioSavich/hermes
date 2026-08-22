#!/usr/bin/env python3
"""Check authored fact-store lifecycle rows and consumption probes."""

from __future__ import annotations

import re
import subprocess
import sys
import tempfile
import time
from collections import Counter, defaultdict
from datetime import date
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
LIFECYCLE_PATH = Path(
    __import__("os").environ.get(
        "CONSUMPTION_GATE_LIFECYCLE",
        ROOT / "knowledge/index/consumption_lifecycle.pl",
    )
)
RUNNER_PATH = Path(
    __import__("os").environ.get(
        "CONSUMPTION_GATE_RUNNER",
        ROOT / "scripts/checks/consumption_gate_probes.pl",
    )
)
ATTESTED_PATH = ROOT / "knowledge/index/consumption_attested_run2.pl"
RUN_ALL_PATH = ROOT / "scripts/checks/run_all.sh"
CENSUS_PATH = ROOT / "scripts/bigred/total_audit/parse_census.pl"
# This is the run-2 model_reader.py --min-rows default.
STAGE_B_MIN_FACTS = 20
STORE_ROOTS = ("knowledge", "curriculum", "formal", "data", "hermes")
EXCLUDED_PREFIXES = (
    "scripts/",
    "third_party/",
    "hermes/web/prolog/",
    "formal/learner/",
    "hermes/app/runtime/",
)
LIFECYCLES = {
    "runtime_eager",
    "runtime_lazy",
    "runtime_python",
    "build_intermediate",
    "check_only",
    "separate_process",
    "quarantined",
    "third_party",
    "stalled_input",
}
RUNGS = {
    "consumer_goal",
    "check_goal",
    "python_check",
    "producer_consumer",
    "not_loaded",
    "eager",
    "consumer_ref",
}
ADMISSIBLE = {
    "runtime_eager": {"eager"},
    "runtime_lazy": {"consumer_goal", "consumer_ref"},
    "runtime_python": {"python_check"},
    "build_intermediate": {"producer_consumer"},
    "check_only": {"check_goal", "python_check"},
    "quarantined": {"not_loaded"},
    "stalled_input": set(),
    "separate_process": set(),
    "third_party": set(),
}
EXECUTABLE_RUNGS = {"consumer_goal", "check_goal", "not_loaded", "eager"}
STATIC_RUNGS = {"python_check", "producer_consumer", "consumer_ref"}
LIFECYCLE_LINE = re.compile(
    r"^store_lifecycle\('([^']+)',\s*([a-z_]+),\s*"
    r"(?:'([^']+)'|(none_named)),\s*'([^']+)',\s*\"(.*)\"\)\.$"
)
PROBE_LINE = re.compile(
    r"^consumption_probe\('([^']+)',\s*([a-z_]+),\s*(.*)\)\.$"
)
ATTESTED_LINE = re.compile(r"^store_consumption_attested\('([^']+)',")
VERDICT_LINE = re.compile(
    r"^PROBE\s+([a-z_]+)\s+(\S+)\s+(PASS|FAIL)(?:\s+(.*))?$"
)


def eligible_store(path: str) -> bool:
    """Mirror coverage_ledger.bucket_of for the store denominator."""
    return path.startswith(tuple(f"{root}/" for root in STORE_ROOTS)) and not path.startswith(
        EXCLUDED_PREFIXES
    )


def prolog_files() -> list[str]:
    # The task forbids invoking git. Including present files also lets the
    # new-store mutation exercise the lifecycle rule before a controller stages it.
    paths: list[str] = []
    for root_name in STORE_ROOTS:
        for path in (ROOT / root_name).rglob("*.pl"):
            relative = path.relative_to(ROOT).as_posix()
            if eligible_store(relative):
                paths.append(relative)
    return sorted(set(paths))


def parse_authored() -> tuple[list[dict[str, str]], list[dict[str, str]]]:
    lifecycles: list[dict[str, str]] = []
    probes: list[dict[str, str]] = []
    for line in LIFECYCLE_PATH.read_text(encoding="utf-8").splitlines():
        lifecycle_match = LIFECYCLE_LINE.match(line)
        if lifecycle_match:
            store, lifecycle, quoted_consumer, bare_consumer, since, note = (
                lifecycle_match.groups()
            )
            lifecycles.append(
                {
                    "store": store,
                    "lifecycle": lifecycle,
                    "consumer": quoted_consumer or bare_consumer,
                    "since": since,
                    "note": note,
                    "line": line,
                }
            )
            continue
        probe_match = PROBE_LINE.match(line)
        if probe_match:
            store, rung, spec = probe_match.groups()
            probes.append({"store": store, "rung": rung, "spec": spec, "line": line})
    return lifecycles, probes


def attested_stores() -> set[str]:
    stores: set[str] = set()
    for line in ATTESTED_PATH.read_text(encoding="utf-8").splitlines():
        match = ATTESTED_LINE.match(line)
        if match:
            stores.add(match.group(1))
    return stores


def run_census(paths: list[str]) -> tuple[dict[str, dict[str, object]], float]:
    started = time.monotonic()
    with tempfile.TemporaryDirectory(prefix="consumption-gate-") as temp_dir:
        temp = Path(temp_dir)
        filelist = temp / "files.txt"
        output = temp / "census.jsonl"
        filelist.write_text("\n".join(paths) + "\n", encoding="utf-8")
        child = subprocess.run(
            [
                "swipl",
                "-q",
                "-g",
                "main",
                str(CENSUS_PATH),
                "--",
                str(filelist),
                str(output),
            ],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        if child.returncode != 0:
            raise RuntimeError(
                "parse_census.pl failed: " + (child.stderr or child.stdout).strip()
            )
        import json

        rows = {
            row["path"]: row
            for line in output.read_text(encoding="utf-8").splitlines()
            if line.strip()
            for row in [json.loads(line)]
        }
    return rows, time.monotonic() - started


def path_reference(path: Path, store: str) -> bool:
    text = path.read_text(encoding="utf-8", errors="replace")
    name = Path(store).name
    grade_template = re.sub(r"^grade_(?:k|[0-8])_", "grade_{grade}_", name)
    return (
        store in text
        or name in text
        or Path(store).stem in text
        or (grade_template != name and grade_template in text)
    )


def run_all_entry_exists(entry: str, run_all: str) -> bool:
    return re.search(rf"^run\s+{re.escape(entry)}(?:\s|$)", run_all, re.MULTILINE) is not None


def static_validations(
    lifecycles: list[dict[str, str]], probes: list[dict[str, str]]
) -> tuple[list[str], list[tuple[str, str, str]]]:
    errors: list[str] = []
    static_verdicts: list[tuple[str, str, str]] = []
    life_by_store: dict[str, list[dict[str, str]]] = defaultdict(list)
    probes_by_store: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in lifecycles:
        life_by_store[row["store"]].append(row)
    for row in probes:
        probes_by_store[row["store"]].append(row)

    for store, rows in sorted(life_by_store.items()):
        if len(rows) != 1:
            errors.append(f"duplicate lifecycle rows for {store}: {len(rows)}")
            continue
        row = rows[0]
        lifecycle = row["lifecycle"]
        consumer = row["consumer"]
        if lifecycle not in LIFECYCLES:
            errors.append(f"unknown lifecycle for {store}: {lifecycle}")
        if not (ROOT / store).is_file():
            errors.append(f"store path is absent: {store}")
        if consumer != "none_named" and not (ROOT / consumer).is_file():
            errors.append(f"consumer path is absent for {store}: {consumer}")
        try:
            date.fromisoformat(row["since"])
        except ValueError:
            errors.append(f"invalid Since date for {store}: {row['since']}")
        store_probes = probes_by_store.get(store, [])
        admissible = ADMISSIBLE.get(lifecycle, set())
        if admissible:
            if len(store_probes) != 1:
                errors.append(
                    f"{store} lifecycle {lifecycle} requires exactly one probe; "
                    f"found {len(store_probes)}"
                )
            elif store_probes[0]["rung"] not in admissible:
                errors.append(
                    f"inadmissible rung for {store}: {store_probes[0]['rung']} "
                    f"with {lifecycle}"
                )
        elif store_probes:
            errors.append(f"{store} lifecycle {lifecycle} must not carry a probe")
        if lifecycle == "stalled_input":
            print(
                f"STALLED_INPUT {store} intended_consumer={consumer} "
                f"since={row['since']} note={row['note']}"
            )

    for probe in probes:
        store, rung, spec = probe["store"], probe["rung"], probe["spec"]
        if rung not in RUNGS:
            errors.append(f"unknown rung for {store}: {rung}")
            continue
        if store not in life_by_store:
            errors.append(f"probe has no lifecycle row: {store}")
            continue
        if rung == "consumer_goal" and not spec.startswith("probe("):
            errors.append(f"malformed consumer_goal spec for {store}")
        elif rung == "check_goal":
            match = re.match(r"check\('([^']+)',\s*.*\)$", spec)
            if not match:
                errors.append(f"malformed check_goal spec for {store}")
            elif not run_all_entry_exists(match.group(1), RUN_ALL_PATH.read_text()):
                errors.append(f"run_all entry absent for {store}: {match.group(1)}")
        elif rung == "python_check":
            match = re.match(r"check\('([^']+)'\)$", spec)
            consumer = life_by_store.get(store, [{}])[0].get("consumer", "")
            if not match:
                errors.append(f"malformed python_check spec for {store}")
            elif not run_all_entry_exists(match.group(1), RUN_ALL_PATH.read_text()):
                errors.append(f"run_all entry absent for {store}: {match.group(1)}")
            elif not path_reference(ROOT / consumer, store):
                errors.append(f"python check does not reference {store}: {consumer}")
            else:
                static_verdicts.append((store, rung, "PASS STATIC"))
        elif rung == "producer_consumer":
            match = re.match(r"scripts\('([^']+)',\s*'([^']+)'\)$", spec)
            if not match:
                errors.append(f"malformed producer_consumer spec for {store}")
            else:
                producer, consumer = (ROOT / match.group(1), ROOT / match.group(2))
                for role, path in (("producer", producer), ("consumer", consumer)):
                    if not path.is_file():
                        errors.append(f"{role} path absent for {store}: {path.relative_to(ROOT)}")
                    elif not path_reference(path, store):
                        errors.append(
                            f"{role} does not reference {store}: {path.relative_to(ROOT)}"
                        )
                if not any(error.endswith(str(producer)) or error.endswith(str(consumer)) for error in errors):
                    static_verdicts.append((store, rung, "PASS STATIC"))
        elif rung == "consumer_ref":
            match = re.match(r"ref\((no_callable_entry|include_active|python_reader)\)$", spec)
            consumer = life_by_store.get(store, [{}])[0].get("consumer", "")
            if not match:
                errors.append(f"malformed consumer_ref spec for {store}")
            elif not path_reference(ROOT / consumer, store):
                errors.append(f"consumer_ref does not reference {store}: {consumer}")
            else:
                static_verdicts.append((store, rung, "PASS STATIC"))
        elif rung in {"not_loaded", "eager"} and spec != "none":
            errors.append(f"{rung} spec must be none for {store}")
    return errors, static_verdicts


def shared_prefix(left: str, right: str) -> int:
    score = 0
    for left_part, right_part in zip(Path(left).parts, Path(right).parts):
        if left_part != right_part:
            break
        score += 1
    return score


def print_unattested(store: str, facts: int, lifecycles: list[dict[str, str]]) -> None:
    nearest = min(
        lifecycles,
        key=lambda row: (-shared_prefix(store, row["store"]), row["store"]),
    )
    print("CONSUMPTION GATE: FAIL (unattested store without lifecycle row)")
    print(f"  store: {store} ({facts} facts)")
    print("  nearest lifecycle row (same directory):")
    print(f"    {nearest['line']}")
    print("  add ONE row to knowledge/index/consumption_lifecycle.pl:")
    print(
        f"    store_lifecycle('{store}', LIFECYCLE, CONSUMER, "
        "'2026-08-22', \"...\")."
    )
    print("  If no consumer exists yet, declare stalled_input with the intended consumer")
    print("  named. Unconsumed data is stalled pipeline input, never vestige: this gate")
    print("  names absence; it does not license deletion.")


def parse_count(output: str, label: str) -> int | None:
    matches = re.findall(rf"^{label}\s+(\d+)$", output, flags=re.MULTILINE)
    if len(matches) != 1:
        return None
    return int(matches[0])


def print_probe_failure(store: str, rung: str, reason: str) -> None:
    lifecycles, _probes = parse_authored()
    row = next((item for item in lifecycles if item["store"] == store), None)
    if reason == "adapter_dead":
        print("CONSUMPTION GATE: FAIL (probe)")
        print(f"  store: {store}")
        if row is not None:
            print(
                f"  lifecycle: {row['lifecycle']}   consumer: {row['consumer']}"
            )
        print(
            f"  probe: {rung} - sentinel bound; consumer result did not "
            "satisfy the postcondition."
        )
        print(
            "  This is the adapter-dead signature: the consumer runs but no "
            "longer carries the store's rows."
        )
        print(
            "  Repair the read path or re-declare the lifecycle; do not "
            "delete the store."
        )
        return
    print("CONSUMPTION GATE: FAIL (probe)")
    print(f"  store: {store}")
    print(f"  probe: {rung} - {reason or 'failed'}")
    print("  Repair the declared path or re-declare the lifecycle; do not delete the store.")


def run_probe_process() -> int:
    lifecycles, probes = parse_authored()
    authored = [
        (probe["store"], probe["rung"])
        for probe in probes
        if probe["rung"] in EXECUTABLE_RUNGS
    ]
    child = subprocess.run(
        ["swipl", "-q", "-s", str(RUNNER_PATH)],
        cwd=ROOT,
        env={
            **__import__("os").environ,
            "CONSUMPTION_GATE_LIFECYCLE": str(LIFECYCLE_PATH),
        },
        text=True,
        capture_output=True,
        check=False,
    )
    output = child.stdout
    if child.stderr:
        print(child.stderr, file=sys.stderr, end="")

    expected = parse_count(output, "PROBES_EXPECTED")
    done = parse_count(output, "PROBES_DONE")
    verdicts = []
    for line in output.splitlines():
        match = VERDICT_LINE.match(line)
        if match:
            verdicts.append(match.groups())

    authored_count = len(authored)
    frame_ok = (
        child.returncode == 0
        and expected == authored_count
        and done == authored_count
        and len(verdicts) == authored_count
    )
    if not frame_ok:
        print("CONSUMPTION GATE: FAIL (probe framing)")
        print(f"  authored executable probes: {authored_count}")
        print(f"  PROBES_EXPECTED: {expected if expected is not None else 'missing'}")
        print(f"  PROBES_DONE: {done if done is not None else 'missing'}")
        print(f"  verdict lines: {len(verdicts)}")
        print(f"  swipl exit: {child.returncode}")
        return 1

    failed = False
    for rung, store, status, reason in sorted(verdicts, key=lambda row: row[1]):
        print(f"PROBE {rung} {store} {status}" + (f" {reason}" if reason else ""))
        if status == "FAIL":
            failed = True
            print_probe_failure(store, rung, reason or "")
    if failed:
        return 1
    print(f"CONSUMPTION GATE: PASS ({authored_count} executable probes)")
    return 0


def main() -> int:
    lifecycles, probes = parse_authored()
    errors, static_verdicts = static_validations(lifecycles, probes)
    paths = prolog_files()
    # Every authored store must stay inside the local denominator filter. This
    # assertion covers the 86 run-2 seeded paths without consulting local audit
    # artifacts during the per-commit check.
    rejected_seed_paths = [row["store"] for row in lifecycles if not eligible_store(row["store"])]
    if rejected_seed_paths:
        errors.append("local store filter rejected authored paths: " + ", ".join(rejected_seed_paths))
    try:
        census, duration = run_census(paths)
    except RuntimeError as error:
        print(f"CONSUMPTION GATE: FAIL (census)\n  {error}")
        return 1
    print(f"CENSUS_SECONDS {duration:.3f}")
    if duration > 90:
        print("CENSUS_NOTICE duration exceeded 90 seconds; full denominator retained")
    fatal = [path for path, row in census.items() if "fatal_error" in row]
    if fatal:
        errors.append("census fatal errors: " + ", ".join(sorted(fatal)))
    attested = attested_stores()
    lifecycle_counts = Counter(row["store"] for row in lifecycles)
    candidates = {
        path: int(row.get("facts", 0))
        for path, row in census.items()
        if int(row.get("facts", 0)) >= STAGE_B_MIN_FACTS
    }
    missing = [
        (path, facts)
        for path, facts in sorted(candidates.items())
        if path not in attested and lifecycle_counts[path] == 0
    ]
    if missing:
        for store, facts in missing:
            print_unattested(store, facts, lifecycles)
        errors.append(f"unattested stores without lifecycle rows: {len(missing)}")
    if errors:
        print("CONSUMPTION GATE: FAIL (static validation)")
        for error in sorted(set(errors)):
            print(f"  {error}")
        return 1
    for store, rung, status in sorted(static_verdicts):
        print(f"PROBE {rung} {store} {status}")
    result = run_probe_process()
    if result == 0:
        print(
            f"CONSUMPTION GATE SUMMARY candidates={len(candidates)} "
            f"lifecycle_rows={len(lifecycles)} static_probes={len(static_verdicts)}"
        )
    return result


if __name__ == "__main__":
    raise SystemExit(main())
