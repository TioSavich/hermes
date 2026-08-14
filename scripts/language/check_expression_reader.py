#!/usr/bin/env python3
"""Build and verify the printed-expression reader census and routed sample."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from collections import Counter, defaultdict, deque
from fractions import Fraction
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "curriculum/im/generated/compiled_defragged_task_instances.pl"
TRUTH = ROOT / "curriculum/im/generated/wave5_row_machine_map.jsonl"
READER = ROOT / "knowledge/strategies/abstraction/printed_expression_reader_pilot.pl"
PUSU_RUNNER = ROOT / "scripts/language/pusu_harness_runner.pl"
ROUTER_RUNNER = ROOT / "scripts/language/standards_router_runner.pl"
SATURATOR = ROOT / "scripts/sidekick/diagnosis_saturate.pl"
OUTPUT = ROOT / "hermes/app/runtime/experiments/language/expression_reader.json"
SCHEMA = "printed_expression_reader_v1"
EXPECTED_ROWS = 2659
EXPECTED_EXPRESSION_ROWS = 1218
ROUTED_SAMPLE_SIZE = 160

EXPRESSION_SURFACE = re.compile(r"^[0-9+*/=.,()xX×÷\s-]+$")
GRADE = re.compile(r"^IM-G(K|[1-8])-")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    return parser.parse_args()


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def prolog_atom(path: Path) -> str:
    return "'" + str(path).replace("'", "''") + "'"


def load_rows() -> list[dict[str, Any]]:
    goal = (
        "use_module(library(http/json)),"
        f"load_files({prolog_atom(SOURCE)},[silent(true)]),"
        "findall(_{id:IdString,lesson:LessonString,status:StatusString,"
        "source_statement:Source,complete_statement:Complete,referents:Referents,"
        "source_statement_spans:SourceSpans},"
        "(compiled_defragged_task_instances:defragged_task_instance(Id,Lesson,_,Data),"
        "get_dict(status,Data,Status),get_dict(source_statement,Data,Source),"
        "get_dict(complete_statement,Data,Complete),get_dict(referents,Data,Referents),"
        "get_dict(source_statement_segments,Data,SourceIds),"
        "get_dict(source_segments,Data,Segments),atom_string(Id,IdString),"
        "atom_string(Lesson,LessonString),atom_string(Status,StatusString),"
        "findall(_{id:SourceIdString,path:Path,line_start:LineStart,"
        "line_end:LineEnd,byte_start:ByteStart,byte_end:ByteEnd,sha256:Sha},"
        "(member(SourceId,SourceIds),atom_string(SourceId,SourceIdString),"
        "member(Segment,Segments),get_dict(id,Segment,SourceIdString),"
        "get_dict(path,Segment,Path),get_dict(line_start,Segment,LineStart),"
        "get_dict(line_end,Segment,LineEnd),get_dict(byte_start,Segment,ByteStart),"
        "get_dict(byte_end,Segment,ByteEnd),get_dict(sha256,Segment,Sha)),"
        "SourceSpans)),Rows),json_write_dict(user_output,Rows,[width(0)])"
    )
    completed = subprocess.run(
        ["swipl", "-q", "-g", goal, "-t", "halt"],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=True,
    )
    rows: list[dict[str, Any]] = json.loads(completed.stdout)
    if len(rows) != EXPECTED_ROWS:
        raise ValueError(f"corpus drift: expected {EXPECTED_ROWS}, found {len(rows)}")
    return rows


class ExpressionRunner:
    def __init__(self) -> None:
        self.process = subprocess.Popen(
            ["swipl", "-q", "-f", str(PUSU_RUNNER)],
            cwd=ROOT,
            text=True,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            bufsize=1,
        )

    def run(self, row: dict[str, Any]) -> dict[str, Any]:
        if self.process.stdin is None or self.process.stdout is None:
            raise RuntimeError("expression runner has no pipes")
        request = {
            "sentences": [],
            "source_statement": row["source_statement"],
            "complete_statement": row["complete_statement"],
            "referents": row["referents"],
            "source_statement_spans": row["source_statement_spans"],
        }
        self.process.stdin.write(
            json.dumps(request, ensure_ascii=False, separators=(",", ":")) + "\n"
        )
        self.process.stdin.flush()
        line = self.process.stdout.readline()
        if not line:
            detail = self.process.stderr.read() if self.process.stderr else ""
            raise RuntimeError(f"expression runner stopped: {detail.strip()}")
        reply = json.loads(line)
        if not reply.get("ok"):
            raise RuntimeError(f"expression runner error: {reply.get('error')}")
        return {
            **row,
            "expression": reply["printed_expression"],
            "completion": reply["expression_completion"],
        }

    def close(self) -> None:
        if self.process.stdin and self.process.poll() is None:
            self.process.stdin.close()
        self.process.wait(timeout=30)
        if self.process.returncode:
            detail = self.process.stderr.read() if self.process.stderr else ""
            raise RuntimeError(f"expression runner failed: {detail.strip()}")


def read_expressions(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    runner = ExpressionRunner()
    try:
        return [runner.run(row) for row in rows]
    finally:
        runner.close()


def run_jsonl(command: list[str], requests: list[dict[str, Any]]) -> list[dict[str, Any]]:
    if not requests:
        return []
    payload = "".join(
        json.dumps(request, sort_keys=True, separators=(",", ":")) + "\n"
        for request in requests
    )
    completed = subprocess.run(
        command,
        cwd=ROOT,
        input=payload,
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError(completed.stderr or completed.stdout)
    responses = [
        json.loads(line) for line in completed.stdout.splitlines() if line.strip()
    ]
    if len(responses) != len(requests):
        raise RuntimeError(
            f"expected {len(requests)} responses, received {len(responses)}"
        )
    errors = [row for row in responses if row.get("status") == "error"]
    if errors:
        raise RuntimeError(f"request errors: {errors[:3]}")
    return responses


def route_rows(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    requests = [
        {
            "id": row["id"],
            "lesson": row["lesson"],
            "program": row["expression"]["program"],
        }
        for row in rows
        if row["expression"]["program"]
    ]
    return run_jsonl(
        [
            "swipl",
            "--on-error=status",
            "--on-warning=status",
            "-q",
            "-l",
            "paths.pl",
            "-s",
            str(ROUTER_RUNNER.relative_to(ROOT)),
            "-g",
            "main",
            "-t",
            "halt",
        ],
        requests,
    )


def base_class(row: dict[str, Any]) -> str:
    class_name = str(row["expression"].get("class") or "refused")
    if class_name.startswith("recovered_from_statement("):
        return "recovered_from_statement"
    return class_name


def recovered_as(row: dict[str, Any]) -> str | None:
    ask = row["expression"].get("ask") or {}
    value = ask.get("recovered_as")
    return str(value) if value is not None else None


def grade_of(lesson: str) -> str:
    match = GRADE.match(lesson)
    if not match:
        raise ValueError(f"unexpected lesson id: {lesson}")
    return match.group(1)


def expression_like(source: str) -> bool:
    return bool(re.search(r"[0-9]", source) and EXPRESSION_SURFACE.fullmatch(source))


def load_truth() -> dict[str, dict[str, Any]]:
    truth: dict[str, dict[str, Any]] = {}
    with TRUTH.open(encoding="utf-8") as handle:
        for line in handle:
            if line.strip():
                row = json.loads(line)
                truth[str(row["id"])] = row
    return truth


def stratified_sample(rows: list[dict[str, Any]], size: int) -> list[dict[str, Any]]:
    buckets: dict[tuple[str, str], deque[dict[str, Any]]] = defaultdict(deque)
    for row in rows:
        buckets[(grade_of(str(row["lesson"])), base_class(row))].append(row)
    keys = sorted(buckets, key=lambda key: (key[0] != "K", key[0], key[1]))
    selected: list[dict[str, Any]] = []
    while len(selected) < min(size, len(rows)):
        moved = False
        for key in keys:
            if buckets[key] and len(selected) < size:
                selected.append(buckets[key].popleft())
                moved = True
        if not moved:
            break
    return selected


def enact(routes: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    requests = [
        {
            "id": route["id"],
            "op": "strategy_trace",
            "strategy": route["kind"],
            "input": route["input"],
        }
        for route in routes
    ]
    responses = run_jsonl(
        ["swipl", "-q", "-l", "hermes_worker.pl", "-g", "worker_main"],
        requests,
    )
    return {str(response["id"]): response for response in responses}


def scalar(value: Any) -> Fraction | None:
    text = str(value).strip()
    long_division = re.fullmatch(r"long_division_result\((-?\d+),0\)", text)
    if long_division:
        return Fraction(int(long_division.group(1)))
    rational = re.fullmatch(r"(-?\d+)(?:r|/)(\d+)", text)
    if rational:
        return Fraction(int(rational.group(1)), int(rational.group(2)))
    if re.fullmatch(r"-?\d+(?:\.\d+)?", text):
        return Fraction(text)
    return None


def comparison_row(
    row: dict[str, Any], route: dict[str, Any], worker: dict[str, Any],
    truth: dict[str, dict[str, Any]],
) -> dict[str, Any]:
    trace = worker.get("result") or {}
    enacted_text = str(trace.get("result", ""))
    answers = row["completion"].get("answers") or []
    saturator_texts = [str(answer["value"]) for answer in answers]
    truth_row = truth.get(str(row["id"]))
    verified_text = (
        str((truth_row.get("execution") or {}).get("result_term", ""))
        if truth_row
        else ""
    )
    enacted_value = scalar(enacted_text)
    saturator_values = [scalar(value) for value in saturator_texts]
    verified_value = scalar(verified_text)
    comparable = bool(
        trace.get("ok") is True
        and enacted_value is not None
        and len(saturator_values) == 1
        and saturator_values[0] is not None
        and verified_value is not None
    )
    agrees = bool(
        comparable
        and enacted_value == saturator_values[0]
        and enacted_value == verified_value
    )
    return {
        "record_id": row["id"],
        "lesson": row["lesson"],
        "grade": grade_of(str(row["lesson"])),
        "class": base_class(row),
        "recovered_as": recovered_as(row),
        "source_statement": row["source_statement"],
        "route": route,
        "enacted_result": enacted_text,
        "saturator_answers": saturator_texts,
        "machine_verified_answer": verified_text,
        "comparable": comparable,
        "three_way_agreement": agrees,
    }


def truth_sample_row(row: dict[str, Any]) -> dict[str, Any]:
    return {
        "record_id": row["id"],
        "lesson": row["lesson"],
        "grade": grade_of(str(row["lesson"])),
        "class": base_class(row),
        "recovered_as": recovered_as(row),
        "source_statement": row["source_statement"],
        "truth": row["expression"].get("truth"),
        "comparable": False,
        "three_way_agreement": False,
        "comparison_reason": "truth_decision_has_no_saturator_value",
    }


def census(
    rows: list[dict[str, Any]], routes: list[dict[str, Any]]
) -> dict[str, Any]:
    expression_rows = [row for row in rows if expression_like(str(row["source_statement"]))]
    if len(expression_rows) != EXPECTED_EXPRESSION_ROWS:
        raise ValueError(
            "expression corpus drift: "
            f"expected {EXPECTED_EXPRESSION_ROWS}, found {len(expression_rows)}"
        )
    parsed = [row for row in rows if row["expression"]["status"] == "parsed"]
    refused = [row for row in rows if row["expression"]["status"] == "refused"]
    parsed_ids = {str(row["id"]) for row in parsed}
    expression_parsed = [
        row for row in expression_rows if str(row["id"]) in parsed_ids
    ]
    expression_refused = [
        row for row in expression_rows if str(row["id"]) not in parsed_ids
    ]
    programs = [row for row in expression_rows if row["expression"]["program"]]
    classes = Counter(base_class(row) for row in parsed)
    recovered = Counter(
        recovered_as(row) or "unspecified"
        for row in parsed
        if base_class(row) == "recovered_from_statement"
    )
    refusal_reasons = Counter(str(row["expression"]["refusal"]) for row in refused)
    expression_refusal_reasons = Counter(
        str(row["expression"]["refusal"]) for row in expression_refused
    )
    route_statuses = Counter(
        "routed" if route["status"] == "routed" else str(route["reason"])
        for route in routes
    )
    return {
        "all_rows": len(rows),
        "expression_surface_rows": len(expression_rows),
        "parsed_rows": len(parsed),
        "refused_rows": len(refused),
        "expression_surface_parsed": len(expression_parsed),
        "expression_surface_refused": len(expression_refused),
        "program_rows": len(programs),
        "program_yield_rate": len(programs) / len(expression_rows),
        "classes": dict(sorted(classes.items())),
        "recovered_as": dict(sorted(recovered.items())),
        "refusal_reasons_ranked": [
            {"reason": reason, "rows": count}
            for reason, count in refusal_reasons.most_common()
        ],
        "expression_refusal_reasons_ranked": [
            {"reason": reason, "rows": count}
            for reason, count in expression_refusal_reasons.most_common()
        ],
        "expression_rows_by_grade": dict(
            sorted(Counter(grade_of(str(row["lesson"])) for row in expression_rows).items())
        ),
        "parsed_rows_by_grade": dict(
            sorted(Counter(grade_of(str(row["lesson"])) for row in parsed).items())
        ),
        "router": {
            "program_rows": len(routes),
            "filled_contracts": route_statuses["routed"],
            "statuses": dict(sorted(route_statuses.items())),
            "filled_contracts_by_grade": dict(
                sorted(
                    Counter(
                        grade_of(str(row["lesson"]))
                        for row in rows
                        if route_by_id_status(routes, str(row["id"])) == "routed"
                    ).items()
                )
            ),
        },
    }


def route_by_id_status(routes: list[dict[str, Any]], record_id: str) -> str | None:
    for route in routes:
        if str(route["id"]) == record_id:
            return str(route["status"])
    return None


def validate_reader_boundary(rows: list[dict[str, Any]]) -> dict[str, Any]:
    allowed = {"quantity", "conversion", "relation", "asks", "discrete_kinds"}
    fact_count = 0
    for row in rows:
        program = row["expression"]["program"]
        provenance = row["expression"].get("fact_provenance") or []
        if len(program) != len(provenance):
            raise ValueError(f"fact provenance count mismatch for {row['id']}")
        for fact, trace in zip(program, provenance, strict=True):
            functor = str(fact).split("(", 1)[0]
            if functor not in allowed:
                raise ValueError(f"sixth fact form {functor!r} in {row['id']}")
            if not trace.get("spans"):
                raise ValueError(f"untraced fact in {row['id']}")
            fact_count += 1

    banned = re.compile(r"\bsucc_or_zero\b|=:=|=\\=|#=|\bis\s+[A-Za-z0-9_(]")
    violations = []
    for line_number, line in enumerate(READER.read_text(encoding="utf-8").splitlines(), 1):
        stripped = line.strip()
        if stripped.startswith(("%", "*", "/**", "*/")):
            continue
        code = re.sub(r'"(?:\\.|[^"])*"|\'(?:\'\'|[^\'])*\'', "", line)
        if banned.search(code):
            violations.append({"line": line_number, "text": stripped})
    if violations:
        raise ValueError(f"reader evaluation boundary violations: {violations}")
    return {
        "allowed_fact_forms": sorted(allowed),
        "facts_checked": fact_count,
        "facts_with_source_spans": fact_count,
        "evaluation_scan_violations": violations,
    }


def sources() -> dict[str, str]:
    paths = [
        Path(__file__),
        SOURCE,
        TRUTH,
        READER,
        PUSU_RUNNER,
        ROUTER_RUNNER,
        SATURATOR,
    ]
    return {str(path.relative_to(ROOT)): sha256(path) for path in paths}


def build_core() -> dict[str, Any]:
    rows = read_expressions(load_rows())
    routes = route_rows(rows)
    boundary_check = validate_reader_boundary(rows)
    route_by_id = {str(route["id"]): route for route in routes}
    routed_rows = [
        row
        for row in rows
        if route_by_id.get(str(row["id"]), {}).get("status") == "routed"
    ]
    routed_sample_rows = stratified_sample(routed_rows, ROUTED_SAMPLE_SIZE)
    routed_sample_routes = [route_by_id[str(row["id"])] for row in routed_sample_rows]
    worker_by_id = enact(routed_sample_routes)
    truth = load_truth()
    comparisons = [
        comparison_row(
            row,
            route_by_id[str(row["id"])],
            worker_by_id[str(row["id"])],
            truth,
        )
        for row in routed_sample_rows
    ]
    truth_rows = [
        row
        for row in rows
        if (
            base_class(row) == "decide_truth"
            or recovered_as(row) == "decide_truth"
        )
        and (row["expression"].get("truth") or {}).get("status") == "checked"
    ]
    truth_receipts = [truth_sample_row(row) for row in truth_rows]
    comparable = [row for row in comparisons if row["comparable"]]
    agreeing = [row for row in comparable if row["three_way_agreement"]]
    sample_grades = sorted(
        {row["grade"] for row in comparisons + truth_receipts},
        key=lambda grade: (grade != "K", grade),
    )
    return {
        "schema": SCHEMA,
        "sources": sources(),
        "reader_boundary": {
            "emits_only_five_form_program": True,
            "performs_evaluation": False,
            "verification": boundary_check,
            "truth_path": {
                "reader": "hermes/math_claim_language.pl:math_claims_in_text/2",
                "checker": "hermes/math_claim_checker.pl:check_math_claim/2",
                "worker_required": False,
            },
            "parenthesized_expression_rows": 0,
        },
        "census": census(rows, routes),
        "bounded_sample": {
            "requested_routed_rows": ROUTED_SAMPLE_SIZE,
            "routed_rows": len(comparisons),
            "truth_decision_rows": len(truth_receipts),
            "grades_present": sample_grades,
            "grades_absent": [grade for grade in ["K", "1", "2", "3", "4", "5", "6", "7", "8"] if grade not in sample_grades],
            "classes": dict(Counter(row["class"] for row in comparisons + truth_receipts)),
            "comparable_rows": len(comparable),
            "three_way_agreements": len(agreeing),
            "three_way_agreement_rate": (
                len(agreeing) / len(comparable) if comparable else None
            ),
            "rows": comparisons + truth_receipts,
        },
        "negative_receipt": {
            "ranked": census(rows, routes)["refusal_reasons_ranked"]
        },
    }


def canonical_bytes(value: Any) -> bytes:
    return (json.dumps(value, sort_keys=True, separators=(",", ":")) + "\n").encode()


def build_receipt() -> dict[str, Any]:
    first = build_core()
    second = build_core()
    first_bytes = canonical_bytes(first)
    second_bytes = canonical_bytes(second)
    if first_bytes != second_bytes:
        raise RuntimeError("expression-reader double build was not byte-identical")
    return {
        **first,
        "double_build": {
            "byte_identical": True,
            "first_sha256": hashlib.sha256(first_bytes).hexdigest(),
            "second_sha256": hashlib.sha256(second_bytes).hexdigest(),
        },
    }


def main() -> int:
    args = parse_args()
    receipt = build_receipt()
    rendered = json.dumps(receipt, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    if args.check:
        if not OUTPUT.exists():
            print(f"missing: {OUTPUT.relative_to(ROOT)}", file=sys.stderr)
            return 1
        if OUTPUT.read_text(encoding="utf-8") != rendered:
            print(f"stale: {OUTPUT.relative_to(ROOT)}", file=sys.stderr)
            return 1
        print(
            json.dumps(
                {
                    "fresh": True,
                    "program_rows": receipt["census"]["program_rows"],
                    "filled_contracts": receipt["census"]["router"]["filled_contracts"],
                    "sample": receipt["bounded_sample"]["routed_rows"],
                    "agreement_rate": receipt["bounded_sample"]["three_way_agreement_rate"],
                    "double_build": receipt["double_build"]["byte_identical"],
                },
                sort_keys=True,
            )
        )
        return 0
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(rendered, encoding="utf-8")
    print(f"wrote {OUTPUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
