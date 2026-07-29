#!/usr/bin/env python3
"""Check the authored lesson-task readings and a known manufactured control."""
from __future__ import annotations

import json
import pathlib
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
CURRICULUM = ROOT / "scripts" / "curriculum"
FIXTURES = sorted(
    (ROOT / "scripts" / "checks" / "fixtures").glob("lesson_task_readings_*.json")
)
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(CURRICULUM))

import compile_action_mappings as compiler  # noqa: E402
from scripts.curriculum import build_lesson_evidence as evidence_ledger  # noqa: E402


def coverage() -> tuple[list[compiler.LessonDoc], set[str], dict[str, set[tuple[str, str]]]]:
    rules = json.loads(compiler.DEFAULT_RULES.read_text(encoding="utf-8"))
    docs = compiler.read_teacher_guides(ROOT)
    explicit = compiler.read_explicit_mappings(ROOT)
    mappings = compiler.compile_rule_mappings(docs, rules, explicit)
    mappings += compiler.compile_scope_batches(rules, explicit, compiler.read_scope_titles(ROOT))
    mappings = sorted(set(mappings))
    covered = {mapping.code for mapping in mappings} | set(explicit)
    attachments = {code: set(rows) for code, rows in explicit.items()}
    for mapping in mappings:
        attachments.setdefault(mapping.code, set()).add((mapping.operation, mapping.kind))
    return docs, covered, attachments


def declared_absent_ledger_control(
    fixture_path: pathlib.Path,
    docs: list[compiler.LessonDoc],
    covered: set[str],
    attachments: dict[str, set[tuple[str, str]]],
) -> str:
    """A visible declared-absent fact cannot license executable_task by itself."""
    rows = compiler.validate_lesson_task_readings(ROOT, docs, covered, attachments, fixture_path)
    if len(rows) != 1 or rows[0]["witness_class"] != "declared_absent":
        raise SystemExit("declared-absent fixture did not retain its witness class")
    row = rows[0]
    content = compiler.render_task_prolog([
        compiler.TaskInstance(
            row["lesson"], row["task"], "productive", row["id"], row["source"],
            row["line"], row["end_line"], row["position"], row["excerpt"],
            witness_class=row["witness_class"],
        )
    ])
    if "witness_class(declared_absent)" not in content:
        raise SystemExit("declared-absent witness class was not rendered")
    with tempfile.NamedTemporaryFile(
        "w", encoding="utf-8", suffix=".pl", dir=ROOT
    ) as temporary:
        temporary.write(content)
        temporary.flush()
        previous = evidence_ledger.COMPILED_TASKS
        try:
            evidence_ledger.COMPILED_TASKS = pathlib.Path(temporary.name)
            spine = json.loads(evidence_ledger.SPINE.read_text(encoding="utf-8"))
            catalog = json.loads(evidence_ledger.CATALOG.read_text(encoding="utf-8"))
            pairs = json.loads(evidence_ledger.PAIR_CATALOG.read_text(encoding="utf-8"))
            payload = evidence_ledger.build(spine, catalog, pairs)
        finally:
            evidence_ledger.COMPILED_TASKS = previous
    lesson = next(item for item in payload["lessons"] if item["lesson"] == row["lesson"])
    if lesson["evidence"]["executable_task"]:
        raise SystemExit("declared-absent task incorrectly granted executable_task")
    return row["lesson"]


def recovered_span_declared_absent_control(
    fixture_path: pathlib.Path,
    docs: list[compiler.LessonDoc],
    covered: set[str],
    attachments: dict[str, set[tuple[str, str]]],
) -> str:
    """A sidecar-only complete expression remains citable but non-counting."""
    rows = compiler.validate_lesson_task_readings(ROOT, docs, covered, attachments, fixture_path)
    if len(rows) != 1 or rows[0]["witness_class"] != "declared_absent":
        raise SystemExit("recovered-span fixture did not compile as declared-absent")
    if rows[0]["source"] != str(compiler.RECOVERED_TASK_SPANS.relative_to(ROOT)):
        raise SystemExit("recovered-span fixture did not retain sidecar provenance")
    return f"{rows[0]['lesson']}/{rows[0]['task']}"


def wrapped_span_control(fixture: dict, docs: list[compiler.LessonDoc]) -> str:
    """Column-aware span text accepts a true wrapped left-column sentence."""
    spans = {
        (span.code, span.position): span
        for span in compiler.extract_student_task_spans(docs)
    }
    span = spans[(fixture["lesson"], fixture["position"])]
    citation = fixture["citation"]
    if compiler._span_bound_markdown_provenance(citation, span) is None:
        raise SystemExit("wrapped span citation did not pass column-aware binding")
    try:
        compiler._reviewed_provenance(
            citation, citation["excerpt"], "", "wrapped span raw-line control"
        )
    except SystemExit:
        return f"{fixture['lesson']}/{fixture['position']}"
    raise SystemExit("wrapped span raw-line control unexpectedly passed")


def single_expression_control(
    fixture_path: pathlib.Path,
    docs: list[compiler.LessonDoc],
    covered: set[str],
    attachments: dict[str, set[tuple[str, str]]],
) -> str:
    """A marker-less grid still permits one exact compiler-shaped expression."""
    rows = compiler.validate_lesson_task_readings(ROOT, docs, covered, attachments, fixture_path)
    if len(rows) != 1 or rows[0]["witness_class"] != "declared_absent":
        raise SystemExit("single-expression fixture did not compile as declared-absent")
    if not compiler._operands_content_scope_matches("multiply", 647, 9, "647 × 9"):
        raise SystemExit("single-expression content scope rejected IM-G5-U4-L6 647 × 9")
    return f"{rows[0]['lesson']}/{rows[0]['task']}"


def complete_expression_control(
    fixture_path: pathlib.Path,
    docs: list[compiler.LessonDoc],
    covered: set[str],
    attachments: dict[str, set[tuple[str, str]]],
) -> str:
    """Prose framing and sentence punctuation do not truncate a complete pair."""
    rows = compiler.validate_lesson_task_readings(ROOT, docs, covered, attachments, fixture_path)
    if len(rows) != 1 or rows[0]["witness_class"] != "declared_absent":
        raise SystemExit("complete-expression fixture did not compile as declared-absent")
    return f"{rows[0]['lesson']}/{rows[0]['task']}"


def hyphen_range_control(fixture: dict) -> str:
    """Document the known range-token boundary without adding a new heuristic."""
    operator, left, right = compiler._task_reading_task(fixture["task"], "hyphen-range")
    excerpt = fixture["excerpt"]
    span = compiler.StudentTaskSpan(
        "FIXTURE", "fixture", 1, 1, "student_task_statement(1)", ((1, excerpt),)
    )
    if not compiler._operands_content_scope_matches(operator, left, right, excerpt):
        raise SystemExit("hyphen-range unit control no longer reaches content scope")
    if not compiler._operands_expression_is_maximal(span, excerpt):
        raise SystemExit("hyphen-range unit control now refuses at maximality")
    return fixture["excerpt"]


def maximality_form_controls() -> str:
    """Keep containment and non-regex adjacency refusals independently live."""
    for text in ("104 + 2 × 10 = n", "104 + 2 = n"):
        span = compiler.StudentTaskSpan(
            "FIXTURE", "fixture", 1, 1, "student_task_statement(1)", ((1, text),)
        )
        if compiler._operands_expression_is_maximal(span, "104 + 2", 1, 1):
            raise SystemExit(f"maximality unit control accepted truncated {text!r}")
    return "containment and adjacency refused"


def markerless_grid_audit(
    docs: list[compiler.LessonDoc],
    covered: set[str],
    attachments: dict[str, set[tuple[str, str]]],
) -> tuple[int, int]:
    """Exercise one exact expression from every marker-less multi-pair K--5 span."""
    operation_by_symbol = {
        "+": ("add", "addition"),
        "-": ("subtract", "subtraction"),
        "−": ("subtract", "subtraction"),
        "×": ("multiply", "multiplication"),
        "·": ("multiply", "multiplication"),
        "÷": ("divide", "division"),
    }
    markerless = []
    citable = 0
    for span in compiler.extract_student_task_spans(docs):
        grade = compiler.CODE_RE.fullmatch(span.code).group(1)
        expressions = list(compiler.ARITHMETIC_EXPRESSION_RE.finditer(span.text))
        if grade not in {"K", "1", "2", "3", "4", "5"} or len(expressions) < 2:
            continue
        if compiler.ITEM_MARKER_RE.search(span.text):
            continue
        markerless.append(span)
        candidate = None
        for line, text in span.lines:
            for match in compiler.ARITHMETIC_EXPRESSION_RE.finditer(text):
                pair = operation_by_symbol.get(match.group("symbol"))
                if pair is None:
                    continue
                operator, operation = pair
                if not any(item[0] == operation for item in attachments.get(span.code, set())):
                    continue
                left = compiler._arithmetic_number(match.group("left"))
                right = compiler._arithmetic_number(match.group("right"))
                expression = text[match.start("left"):match.end("right")]
                candidate = (line, text, operator, operation, left, right, expression)
                break
            if candidate is not None:
                break
        if candidate is None:
            continue
        line, text, operator, operation, left, right, expression = candidate
        payload = {
            "schema": "lesson_task_readings_v1",
            "register": "Checker-only marker-less grid scope audit.",
            "readings": [{
                "lesson": span.code,
                "id": f"markerless_scope_{span.code}_{span.position}",
                "position": span.position,
                "task": f"{operator}({left}, {right})",
                "operation": operation,
                "prompt": {
                    "source": span.source,
                    "line": span.lines[0][0],
                    "excerpt": span.lines[0][1],
                },
                "operands": {
                    "source": span.source,
                    "line": line,
                    "excerpt": expression,
                },
                "printed_answer": {
                    "absent": True,
                    "reason": "Checker-only scope audit; this does not claim a missing guide answer.",
                },
                "read_by": "fixture",
            }],
        }
        with tempfile.NamedTemporaryFile(
            "w", encoding="utf-8", suffix=".json", dir=ROOT
        ) as temporary:
            json.dump(payload, temporary)
            temporary.flush()
            try:
                compiler.validate_lesson_task_readings(
                    ROOT, docs, covered, attachments, pathlib.Path(temporary.name)
                )
            except SystemExit as error:
                if "maximality failed" not in str(error):
                    raise
                continue
        citable += 1
    if len(markerless) != 14:
        raise SystemExit(
            f"marker-less grid audit expected 14 K--5 spans, found {len(markerless)}"
        )
    return len(markerless), citable


def main() -> int:
    docs, covered, attachments = coverage()
    rows = compiler.validate_lesson_task_readings(ROOT, docs, covered, attachments)
    boundary_path = ROOT / "curriculum/im_teacher_guides/kindergarten/unit5/lesson6.md"
    if compiler._next_response_range(boundary_path, 158) is not None:
        print("adjacent task statements were incorrectly paired to a later response", file=sys.stderr)
        return 1
    if compiler._next_response_range(boundary_path, 248) != (256, 329):
        print("second adjacent task statement lost its own response range", file=sys.stderr)
        return 1
    refusals = []
    declared_absent_lesson = ""
    recovered_span_lesson = ""
    wrapped_control = ""
    single_expression = ""
    complete_expression = ""
    hyphen_range = ""
    maximality_forms = ""
    for fixture_path in FIXTURES:
        fixture = json.loads(fixture_path.read_text(encoding="utf-8"))
        if fixture.get("expected_result") == "declared_absent_compiles":
            declared_absent_lesson = declared_absent_ledger_control(
                fixture_path, docs, covered, attachments
            )
            continue
        if fixture.get("expected_result") == "recovered_span_declared_absent_compiles":
            recovered_span_lesson = recovered_span_declared_absent_control(
                fixture_path, docs, covered, attachments
            )
            continue
        if fixture.get("expected_result") == "span_bound_markdown_passes":
            wrapped_control = wrapped_span_control(fixture, docs)
            continue
        if fixture.get("expected_result") == "single_expression_compiles":
            single_expression = single_expression_control(
                fixture_path, docs, covered, attachments
            )
            continue
        if fixture.get("expected_result") == "complete_expression_compiles":
            complete_expression = complete_expression_control(
                fixture_path, docs, covered, attachments
            )
            continue
        if fixture.get("expected_result") == "known_hyphen_range_passes":
            hyphen_range = hyphen_range_control(fixture)
            continue
        try:
            compiler.validate_lesson_task_readings(
                ROOT, docs, covered, attachments, fixture_path
            )
        except SystemExit as error:
            message = str(error)
            expected = fixture["expected_error"]
            if expected not in message:
                print(
                    f"{fixture_path.name} failed at the wrong gate: {message}",
                    file=sys.stderr,
                )
                return 1
            refusals.append((fixture_path.name, message))
        else:
            print(
                f"{fixture_path.name} unexpectedly passed",
                file=sys.stderr,
            )
            return 1
    printed = sum(row["witness_class"] == "printed_answer" for row in rows)
    absent = sum(row["witness_class"] == "declared_absent" for row in rows)
    print(
        f"lesson task readings current: rows={len(rows)} "
        f"printed_answer={printed} declared_absent={absent}"
    )
    print("adjacent-task response-boundary control passed")
    print(
        f"declared-absent control compiled for {declared_absent_lesson}; "
        "ledger executable_task=false"
    )
    print(
        f"recovered-span declared-absent control compiled for {recovered_span_lesson}; "
        "ledger executable_task=false"
    )
    print(f"wrapped-span column-aware control passed: {wrapped_control}")
    print(f"marker-less single-expression control passed: {single_expression}")
    print(f"complete-expression maximality control passed: {complete_expression}")
    print(f"known latent hyphen-range unit behavior: passes ({hyphen_range})")
    maximality_forms = maximality_form_controls()
    print(f"maximality unit controls passed: {maximality_forms}")
    markerless_spans, citable_spans = markerless_grid_audit(docs, covered, attachments)
    print(
        "marker-less grid audit: "
        f"spans={markerless_spans} single_expression_citable={citable_spans}"
    )
    for name, message in refusals:
        print(f"manufactured control refused ({name}): {message}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
