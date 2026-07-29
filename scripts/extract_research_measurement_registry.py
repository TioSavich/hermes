#!/usr/bin/env python3
"""Generate a bounded provenance registry for quantitative research claims.

The denominator is every explicit quantitative-result statement in the 65
top-level Markdown reports in docs/research/: a non-code prose line carrying a
percentage or cohort ratio, or a Markdown table data row under a header that
names a quantitative field.  A table row is one measurement vector; its metric
columns are kept together rather than split into invented claims.
"""
from __future__ import annotations

import argparse
import difflib
import re
import sys
import tempfile
from collections import Counter
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REPORTS = ROOT / "docs" / "research"
OUTPUT = ROOT / "knowledge" / "index" / "research_measurement_registry.pl"
OUTPUT_PRODUCERS = {
    # This report cites the generated coverage ledger, not its builder. The
    # assignment is checked against the live producer below so it cannot turn a
    # reader of the ledger into its alleged producer.
    "curriculum/im/coverage/im_coverage.json": "scripts/research/build_im_coverage.py",
}
METHOD_INPUTS = {
    "scripts/research/build_self_description_census.py": ("hermes/capability_registry.pl",),
    "scripts/research/score_recognition_benchmark.py": ("data/research/recognition_benchmark.json",),
}
SCRIPT_SUFFIXES = {".py", ".sh", ".pl"}
DATA_SUFFIXES = {".bib", ".csv", ".db", ".json", ".jsonl", ".md", ".npz", ".pl", ".sqlite", ".txt"}
PATH_RE = re.compile(
    r"(?<![A-Za-z0-9_./-])((?:\.?/?)(?:scripts|data|knowledge|curriculum|formal|hermes)/[A-Za-z0-9_./-]+)"
)
FOREIGN_PATH_RE = re.compile(
    r"(\.\./[A-Za-z0-9_-]+/[A-Za-z0-9_./-]+\.(?:bib|csv|db|json|jsonl|md|npz|pl|sqlite|tex|txt))"
)
PERCENT_RE = re.compile(r"\b\d+(?:\.\d+)?%")
COHORT_RE = re.compile(r"\b\d[\d,]*\s+(?:of|out of)\s+\d[\d,]*\b", re.I)
RATIO_RE = re.compile(
    r"\b\d[\d,]*\s*/\s*\d[\d,]*\s+(?:items?|rows?|machines?|lessons?|"
    r"observed|passed|pass|coverage|accepted|acceptance|agreement|correct|exact)\b",
    re.I,
)
METRIC_HEADER_RE = re.compile(
    r"\b(?:count|total|items?|lessons|machines|rate|percent|percentage|"
    r"coverage|recall|accuracy|agreement|acceptance|score|failures?|entries|passed|"
    r"converted|bindings|candidates|abstention|resolution)\b|%|@",
    re.I,
)


@dataclass(frozen=True)
class Measurement:
    report: str
    location: str
    claim: str
    method_context: tuple[str, ...]
    data_context: tuple[str, ...]


def atom(value: str) -> str:
    if re.fullmatch(r"[a-z][A-Za-z0-9_]*", value):
        return value
    return "'" + value.replace("'", "''") + "'"


def q(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def clean_path(value: str) -> str:
    value = value.rstrip(".,;:)]}>")
    while value.startswith("./"):
        value = value[2:]
    return value


def referenced_paths(lines: list[str]) -> tuple[str, ...]:
    paths = {
        clean_path(match.group(1))
        for line in lines
        for pattern in (PATH_RE, FOREIGN_PATH_RE)
        for match in pattern.finditer(line)
    }
    return tuple(sorted(path for path in paths if path and Path(path).suffix in DATA_SUFFIXES))


def method_path(path: str) -> bool:
    return path.startswith("scripts/") or "/scripts/" in path


def live_path(path: str) -> bool:
    return not path.startswith("../") and (ROOT / path).is_file()


def prose_measurement(line: str) -> bool:
    return bool(PERCENT_RE.search(line) or COHORT_RE.search(line) or RATIO_RE.search(line))


def table_cells(line: str) -> tuple[str, ...]:
    return tuple(cell.strip() for cell in line.strip().strip("|").split("|"))


def separator_row(line: str) -> bool:
    cells = table_cells(line)
    return bool(cells) and all(re.fullmatch(r":?-{3,}:?", cell.replace(" ", "")) for cell in cells)


def claim_text(line: str) -> str:
    return " ".join(line.strip().split())


def table_has_metric_header(header: str) -> bool:
    cells = table_cells(header)
    return any(
        METRIC_HEADER_RE.search(cell)
        and not re.fullmatch(r"(?:row\s+)?id", cell, re.I)
        for cell in cells
    )


def collect_measurements(path: Path) -> list[Measurement]:
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    report = str(path.relative_to(ROOT))
    measurements: list[Measurement] = []
    in_fence = False
    index = 0
    while index < len(lines):
        line = lines[index]
        if line.strip().startswith("```"):
            in_fence = not in_fence
            index += 1
            continue
        if in_fence:
            index += 1
            continue
        if (
            line.lstrip().startswith("|")
            and index + 1 < len(lines)
            and separator_row(lines[index + 1])
        ):
            header = claim_text(line)
            header_is_metric = table_has_metric_header(header)
            row_index = index + 2
            while row_index < len(lines) and lines[row_index].lstrip().startswith("|"):
                row = lines[row_index]
                if header_is_metric and re.search(r"\d", row):
                    measurements.append(
                        Measurement(
                            report,
                            f"table_lines({index + 1},{row_index + 1})",
                            f"table header: {header}; row: {claim_text(row)}",
                            tuple(lines[max(0, row_index - 120): min(len(lines), row_index + 121)]),
                            tuple(lines[max(0, row_index - 30): min(len(lines), row_index + 3)]),
                        )
                    )
                row_index += 1
            index = row_index
            continue
        stripped = line.strip()
        if stripped and not stripped.startswith(">") and not stripped.startswith("#") and prose_measurement(stripped):
            measurements.append(
                Measurement(
                    report,
                    f"line({index + 1})",
                    claim_text(line),
                    tuple(lines[max(0, index - 120): min(len(lines), index + 121)]),
                    tuple(lines[max(0, index - 30): min(len(lines), index + 3)]),
                )
            )
        index += 1
    return measurements


def producer_scripts(data_paths: tuple[str, ...]) -> dict[str, set[str]]:
    """Join cited generated artifacts to their verified live producers.

    This stays deliberately narrow. A repository-wide text search turns every
    reader of a shared data file into a false producer, which is exactly the
    provenance collapse this registry is intended to prevent.
    """
    producers = {data: set() for data in data_paths}
    for data, script in OUTPUT_PRODUCERS.items():
        if data not in producers:
            continue
        if not (ROOT / script).is_file():
            raise RuntimeError(f"verified producer is absent: {script}")
        producers[data].add(script)
    return producers


def classify(
    measurement: Measurement, producers: dict[str, set[str]]
) -> tuple[str, tuple[str, ...], tuple[str, ...]]:
    method_paths = referenced_paths(list(measurement.method_context))
    named_scripts = tuple(
        path for path in method_paths
        if method_path(path) and Path(path).suffix in SCRIPT_SUFFIXES
    )
    live_scripts = tuple(path for path in named_scripts if live_path(path))
    absent_scripts = tuple(path for path in named_scripts if not live_path(path))
    data_paths = tuple(
        path for path in referenced_paths(list(measurement.data_context))
        if not (method_path(path) and Path(path).suffix in SCRIPT_SUFFIXES)
    )
    absent_data = tuple(path for path in data_paths if not live_path(path))
    present_data = tuple(path for path in data_paths if live_path(path))
    produced_by = tuple(
        sorted({script for data in present_data for script in producers.get(data, set())})
    )
    command_scripts = tuple(sorted({
        clean_path(match.group(1))
        for line in measurement.method_context
        for match in re.finditer(r"(?:python(?:3)?|bash)\s+((?:\.?/?scripts)/[^\s`]+)", line)
        if (ROOT / clean_path(match.group(1))).is_file()
    }))
    generated_scripts = tuple(sorted({
        clean_path(match.group(1))
        for line in measurement.method_context
        for match in re.finditer(r"Generated by `((?:\.?/?scripts)/[^`]+)`", line)
        if (ROOT / clean_path(match.group(1))).is_file()
    }))
    methods = generated_scripts or command_scripts or live_scripts or produced_by

    if len(methods) == 1:
        inputs = METHOD_INPUTS.get(methods[0], ())
        if absent_data:
            return "resolved_method_data_missing", methods, absent_data
        return "resolved_live_method", methods, tuple(sorted(set(present_data) | set(inputs)))
    if len(methods) > 1:
        return "method_ambiguous", methods, present_data
    if absent_scripts and absent_data:
        return "method_path_and_cited_data_missing", absent_scripts, absent_data
    if absent_data:
        return "cited_data_missing", absent_scripts, absent_data
    if absent_scripts:
        return "method_path_missing", absent_scripts, present_data
    if present_data:
        return "data_method_unrecorded", (), present_data
    return "method_not_recorded", (), ()


def method_term(status: str, methods: tuple[str, ...]) -> str:
    if status in {"resolved_live_method", "resolved_method_data_missing"}:
        return f"live_script({q(methods[0])})"
    if status == "method_ambiguous":
        return "ambiguous_scripts([" + ", ".join(q(method) for method in methods) + "])"
    if status in {"method_path_missing", "method_path_and_cited_data_missing"}:
        return "missing_script([" + ", ".join(q(method) for method in methods) + "])"
    return "none_recorded"


def data_term(data: tuple[str, ...]) -> str:
    if not data:
        return "none_recorded"
    return "[" + ", ".join(q(path) for path in data) + "]"


def control_rows() -> list[tuple[str, str, str]]:
    controls = (
        ("coverage_absence_registry", "scripts/extract_coverage_absence_registry.py", "scripts/extract_coverage_absence_registry.py", "knowledge/index/coverage_absence_registry.pl"),
        ("self_description_census", "scripts/research/build_self_description_census.py", "scripts/checks/self_description_census.py", "data/research/self_description_census.json"),
        ("recognition_benchmark", "scripts/research/build_recognition_benchmark.py", "scripts/checks/recognition_benchmark.py", "data/research/recognition_benchmark.json"),
    )
    rows = []
    for name, script, check, artifact in controls:
        script_path, check_path, artifact_path = ROOT / script, ROOT / check, ROOT / artifact
        resolved = script_path.is_file() and check_path.is_file() and artifact_path.is_file()
        status = "resolved_live_method" if resolved else "control_failed"
        rows.append((name, script, status))
    if any(status != "resolved_live_method" for _name, _script, status in rows):
        detail = ", ".join(name for name, _script, status in rows if status != "resolved_live_method")
        raise RuntimeError(f"positive control did not resolve: {detail}")
    return rows


def render_registry() -> str:
    reports = sorted(REPORTS.glob("*.md"))
    # The count is asserted rather than inferred so that a report entering or
    # leaving the corpus is a decision someone makes, not a silent change in a
    # denominator. Raise it when a report is added, in the same commit.
    # 56 until 2026-07-27; that day added the no-saying vocabularies report, the
    # singleton-tail analysis, and the non-emergent-sets analysis, and vendored
    # the 2026-07-02 emergent-hyperedge search record three modules cite, and the
    # account of why incompatibility entailment does not move, and the PML status
    # report.
    # 62 until 2026-07-28 evening, which added the incompatibility / LX /
    # diagonalization / vanishing-points report.
    # 63 until 2026-07-28 evening, which added the account of what refusals are
    # for: the carving of refused spans into kinds that differ in what should
    # happen to them.
    if len(reports) != 67:
        raise RuntimeError(f"expected 67 top-level research reports, found {len(reports)}")
    measurements = sorted(
        (measurement for report in reports for measurement in collect_measurements(report)),
        key=lambda item: (item.report, item.location, item.claim),
    )
    if not measurements:
        raise RuntimeError("the bounded research-measurement denominator is empty")
    controls = control_rows()
    all_data_paths = tuple(sorted({
        path
        for measurement in measurements
        for path in referenced_paths(list(measurement.data_context))
        if not method_path(path) and live_path(path)
    }))
    producers = producer_scripts(all_data_paths)
    counts: Counter[str] = Counter()
    rows: list[str] = []
    for number, measurement in enumerate(measurements, start=1):
        status, methods, data = classify(measurement, producers)
        counts[status] += 1
        rows.append(
            "measurement_receipt("
            f"measurement({number}), {q(measurement.report)}, {atom(measurement.location)}, "
            f"{q(measurement.claim)}, {method_term(status, methods)}, {data_term(data)}, {atom(status)})."
        )

    lines = [
        "/** <module> Generated research-measurement provenance registry",
        " *",
        " * The denominator is every explicit quantitative-result statement in the 65",
        " * top-level Markdown reports in docs/research/: a non-code prose line with",
        " * a percentage or cohort ratio, or a Markdown table data row under a header",
        " * that names a quantitative field. A table row is one measurement vector;",
        " * its metric columns remain together rather than becoming invented claims.",
        " *",
        " * Each receipt retains its report location, claim text, a recorded method when",
        " * one can be joined to a live script, and cited repository data paths.",
        " * The remainder is typed from this checkout. Its statuses retain",
        " * method-path and cited-data absences rather than repairing reports.",
        " *",
        " * Generated by scripts/extract_research_measurement_registry.py.",
        " * Regenerate: python3 scripts/extract_research_measurement_registry.py",
        " */",
        "",
        ":- module(research_measurement_registry,",
        "          [ measurement_receipt/7,",
        "            measurement_denominator/2,",
        "            measurement_resolution_count/2,",
        "            measurement_without_live_method/3,",
        "            measurement_control/3",
        "          ]).",
        "",
    ]
    lines.extend(rows)
    lines.extend(["", f"measurement_denominator(explicit_quantitative_result_statement, {len(measurements)})."])
    for status in (
        "resolved_live_method",
        "resolved_method_data_missing",
        "method_ambiguous",
        "method_path_and_cited_data_missing",
        "method_path_missing",
        "cited_data_missing",
        "data_method_unrecorded",
        "method_not_recorded",
    ):
        if counts[status]:
            lines.append(f"measurement_resolution_count({status}, {counts[status]}).")
    lines.append("")
    for name, script, status in controls:
        lines.append(f"measurement_control({atom(name)}, {q(script)}, {atom(status)}).")
    lines.extend([
        "",
        "measurement_without_live_method(Id, Claim, Status) :-",
        "    measurement_receipt(Id, _, _, Claim, _, _, Status),",
        "    Status \\= resolved_live_method.",
        "",
    ])
    return "\n".join(lines)


def check_output(expected: str, output: Path) -> int:
    actual = output.read_text(encoding="utf-8") if output.is_file() else ""
    if actual == expected:
        print(f"research measurement registry is current: {output.relative_to(ROOT)}")
        return 0
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", suffix=".pl", delete=False) as temporary:
        temporary.write(expected)
        temporary_path = Path(temporary.name)
    diff = list(difflib.unified_diff(actual.splitlines(), expected.splitlines(), fromfile=str(output), tofile=str(temporary_path), lineterm=""))
    print("research measurement registry is stale; run python3 scripts/extract_research_measurement_registry.py", file=sys.stderr)
    for line in diff[:12]:
        print(line, file=sys.stderr)
    temporary_path.unlink(missing_ok=True)
    return 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail if the generated registry is stale")
    parser.add_argument("--output", type=Path, default=OUTPUT, help=argparse.SUPPRESS)
    args = parser.parse_args()
    output = args.output if args.output.is_absolute() else ROOT / args.output
    rendered = render_registry()
    if args.check:
        return check_output(rendered, output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(rendered, encoding="utf-8")
    print(f"wrote {output.relative_to(ROOT)}: {len(rendered.splitlines())} lines")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
