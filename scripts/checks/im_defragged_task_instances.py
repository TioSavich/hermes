#!/usr/bin/env python3
"""Independent byte, census, fixture, and determinism gate for IM defrag rows."""

from __future__ import annotations

from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
from scripts.counts_baseline_lib import baseline_value  # noqa: E402

ARTIFACT = ROOT / "curriculum/im/generated/compiled_defragged_task_instances.pl"
COMPILED = ROOT / "curriculum/im/generated/compiled_task_instances.pl"
GRADE8_COMPILED = ROOT / "curriculum/im/generated/grade_8_extracted_task_instances.pl"
GENERATOR = ROOT / "scripts/curriculum/build_im_defragged_task_instances.py"
FIXTURES = ROOT / "scripts/checks/fixtures/im_defrag_source_spans.json"
EXPERIMENTS = ROOT / "hermes/app/runtime/experiments"
EXPECTED_STATUS = Counter(
    {
        "already_complete": 3417,
        "recovered": 1295,
        "recovered_with_referent": 3,
        "blocked_layout": 385,
    }
)
EXPECTED_BLOCKERS = Counter(
    {
        "required_visual_asset_unresolved": 23,
        "pdf_source_absent_no_unique_markdown_join": 242,
        "joined_source_span_not_complete": 60,
        "task_external_evidence_no_unique_productive_peer": 9,
        "known_cross_page_layout_refusal": 1,
        "expression_missing_from_markdown": 115,
        "expression_missing_without_visual": 70,
        "curriculum_text_absent_after_docling": 4,
        "task_section_contains_no_curriculum_text": 3,
    }
)
EXPECTED_REPAIR_CLASSES = Counter(
    {
        "complete_source": 4761,
        "source_fragmentary": 212,
        "span_ends_early": 198,
        "span_starts_mid_sentence": 71,
    }
)
SWI_GOAL = r"""use_module(library(http/json)),use_module(curriculum/im/generated/compiled_defragged_task_instances), forall(compiled_defragged_task_instances:defragged_task_instance(Id,L,T,D),(term_string(T,TS,[quoted(true)]),get_dict(source_evidence,D,E),term_string(E,ES,[quoted(true)]),del_dict(source_evidence,D,_,D1),del_dict(visuals,D1,Vs,D2),length(Vs,VC),put_dict(_{record_id:Id,lesson:L,task_term:TS,evidence_term:ES,visual_count:VC},D2,O),json_write_dict(current_output,O,[width(0)]),nl)),halt."""
VISUAL_GOAL = r"""use_module(curriculum/im/generated/compiled_defragged_task_instances),forall(compiled_defragged_task_instances:defragged_task_instance(_,_,_,D),(get_dict(status,D,Status),get_dict(visuals,D,Vs),(Status==blocked_missing_visual->Vs=[V],get_dict(status,V,VisualStatus),get_dict(asset,V,Asset),((VisualStatus==excluded_docling_asset,string(Asset),exists_directory(Asset));(memberchk(VisualStatus,[missing_from_guide_markdown,missing_from_absent_pdf]),Asset==none));Vs==[]))),halt."""
VISUAL_SCHEMA_GOAL = r"""use_module(curriculum/im/generated/compiled_defragged_task_instances),forall(compiled_defragged_task_instances:defragged_task_instance(_,_,_,D),(get_dict(status,D,Status),get_dict(visuals,D,Vs),(Status==blocked_missing_visual->Vs=[V],get_dict(status,V,VisualStatus),get_dict(asset,V,Asset),((VisualStatus==excluded_docling_asset,string(Asset));(memberchk(VisualStatus,[missing_from_guide_markdown,missing_from_absent_pdf]),Asset==none));Vs==[]))),halt."""


def fail(message: str) -> None:
    raise AssertionError(message)


def read_rows() -> list[dict]:
    result = subprocess.run(
        ["swipl", "-q", "-g", SWI_GOAL],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode:
        fail(f"artifact load failed: {result.stderr.strip()}")
    try:
        return [json.loads(line) for line in result.stdout.splitlines()]
    except json.JSONDecodeError as exc:
        fail(f"artifact JSON projection failed: {exc}")


def scan_file_facts(path: Path, prefix: str) -> list[bytes]:
    data = path.read_bytes()
    if not data.isascii():
        fail("compiled task artifact is no longer ASCII-rendered")
    text = data.decode("ascii")
    facts = []
    cursor = 0
    while True:
        start = text.find(prefix, cursor)
        if start < 0:
            break
        depth = 0
        in_string = False
        escaped = False
        end = None
        for index in range(start, len(text)):
            char = text[index]
            if in_string:
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == '"':
                    in_string = False
                continue
            if char == '"':
                in_string = True
            elif char == "(":
                depth += 1
            elif char == ")":
                depth -= 1
                if depth == 0 and text[index + 1 : index + 2] == ".":
                    end = index + 2
                    break
        if end is None:
            fail(f"unterminated compiled fact at byte {start}")
        facts.append(data[start:end])
        cursor = end
    return facts


def scan_compiled_facts() -> list[bytes]:
    return [
        *scan_file_facts(COMPILED, "compiled_lesson_task_instance("),
        *scan_file_facts(GRADE8_COMPILED, "extracted_lesson_task_instance("),
    ]


def decode_segment(segment: dict, cache: dict[str, bytes]) -> str:
    path = segment["path"]
    candidate = (ROOT / path).resolve()
    if not candidate.is_relative_to(ROOT.resolve()):
        fail(f"segment escapes repository root: {path}")
    data = cache.setdefault(path, candidate.read_bytes())
    start = segment["byte_start"]
    end = segment["byte_end"]
    if not (0 <= start < end <= len(data)):
        fail(f"invalid byte range for {segment['id']}: {start}:{end}")
    raw = data[start:end]
    if hashlib.sha256(raw).hexdigest() != segment["sha256"]:
        fail(f"byte hash mismatch for {segment['id']}")
    line_start = data.count(b"\n", 0, start) + 1
    line_end = data.count(b"\n", 0, end - 1) + 1
    if (line_start, line_end) != (segment["line_start"], segment["line_end"]):
        fail(f"line provenance mismatch for {segment['id']}")
    decoder = segment["decoder"]
    if decoder == "utf8":
        return raw.decode("utf-8")
    if decoder in {"json_string_ascii", "json_string_utf8"}:
        return json.loads(b'"' + raw + b'"')
    if decoder == "docling_json_text_v1":
        return " ".join(json.loads(b'"' + raw + b'"').split())
    if decoder == "docling_formula_spacing_v1":
        from scripts.curriculum import recover_docling_grade8 as recovery

        return recovery.normalize_formula(json.loads(b'"' + raw + b'"'))
    fail(f"unknown decoder for {segment['id']}: {decoder}")


def joined(ids: list[str], joiner: str, decoded: dict[str, str]) -> str:
    try:
        return joiner.join(decoded[segment_id] for segment_id in ids)
    except KeyError as exc:
        fail(f"unknown source segment reference: {exc.args[0]}")


def check_provenance(rows: list[dict]) -> dict[str, int]:
    cache: dict[str, bytes] = {}
    verified_segments = 0
    unavailable_segments = 0
    allowed_decoders = {
        "utf8",
        "json_string_ascii",
        "json_string_utf8",
        "docling_json_text_v1",
        "docling_formula_spacing_v1",
    }
    for row in rows:
        segments = row["source_segments"]
        by_id = {segment["id"]: segment for segment in segments}
        if len(by_id) != len(segments):
            fail(f"duplicate segment ID inside {row['record_id']}")
        referenced = [
            *row["statement_segments"],
            *row["source_statement_segments"],
            *row.get("fragment_segments", []),
            *(
                segment_id
                for referent in row["referents"]
                for segment_id in [
                    *referent["segments"],
                    *referent["antecedent_segments"],
                ]
            ),
        ]
        unknown = sorted(set(referenced) - set(by_id))
        if unknown:
            fail(f"unknown source segment references in {row['record_id']}: {unknown}")
        decoded: dict[str, str] = {}
        for segment_id, segment in by_id.items():
            path = segment.get("path")
            if not isinstance(path, str):
                fail(f"segment path is malformed for {segment_id}")
            candidate = (ROOT / path).resolve()
            if not candidate.is_relative_to(ROOT.resolve()):
                fail(f"segment escapes repository root: {path}")
            if segment.get("decoder") not in allowed_decoders:
                fail(f"unknown decoder for {segment_id}: {segment.get('decoder')}")
            if not isinstance(segment.get("sha256"), str) or not re.fullmatch(
                r"[0-9a-f]{64}", segment["sha256"]
            ):
                fail(f"segment hash is malformed for {segment_id}")
            if candidate.is_file():
                decoded[segment_id] = decode_segment(segment, cache)
                verified_segments += 1
            elif not EXPERIMENTS.is_dir() and candidate.is_relative_to(EXPERIMENTS.resolve()):
                unavailable_segments += 1
            else:
                fail(f"segment source is absent: {path}")

        def verify_join(ids: list[str], joiner: str, expected: str, label: str) -> None:
            if all(segment_id in decoded for segment_id in ids):
                actual = joined(ids, joiner, decoded)
                if actual != expected:
                    fail(f"{label} is not byte-backed: {row['record_id']}")

        verify_join(
            row["statement_segments"], row["statement_joiner"],
            row["complete_statement"], "statement text",
        )
        if row["source_statement_segments"]:
            verify_join(
                row["source_statement_segments"],
                row["source_statement_joiner"],
                row["source_statement"],
                "source statement",
            )
        if row["status"] == "blocked_layout":
            if row["complete_statement"] or row["statement_segments"]:
                fail(
                    f"layout-blocked row claims a complete statement: {row['record_id']}"
                )
            if not row["available_fragment"] or not row["fragment_segments"]:
                fail(f"layout-blocked row has no available fragment: {row['record_id']}")
            verify_join(
                row["fragment_segments"], row["fragment_joiner"],
                row["available_fragment"], "layout-blocked fragment",
            )
        elif not row["complete_statement"] or not row["statement_segments"]:
            fail(
                f"usable or visual-blocked row has no task statement: {row['record_id']}"
            )
        for referent in row["referents"]:
            verify_join(
                referent["segments"], " ", referent["surface"], "referent surface"
            )
            verify_join(
                referent["antecedent_segments"], " ", referent["antecedent"],
                "referent antecedent",
            )
            if referent["status"] == "missing" and (
                referent["antecedent"] or referent["absence_reason"] == "none"
            ):
                fail(
                    f"missing referent lacks an honest absence marker: {row['record_id']}"
                )
    return {
        "verified_segments": verified_segments,
        "unavailable_segments": unavailable_segments,
    }


def check_identity(rows: list[dict]) -> None:
    facts = scan_compiled_facts()
    expected_facts = baseline_value("defrag.compiled_facts")
    expected_rows = baseline_value("defrag.rows")
    if len(facts) != expected_facts or len(rows) != expected_rows:
        fail(f"row count drift: compiled={len(facts)}, defrag={len(rows)}")
    ids = [row["record_id"] for row in rows]
    if len(ids) != len(set(ids)):
        fail("defrag record IDs are not unique")
    occurrences: Counter[str] = Counter()
    for row, fact in zip(rows[: len(facts)], facts):
        evidence_sha = hashlib.sha256(fact).hexdigest()
        if evidence_sha != row["evidence_sha256"]:
            fail(f"compiled evidence hash mismatch for {row['record_id']}")
        stable_key = "\0".join(
            [row["lesson"], row["task_term"], row["evidence_term"], evidence_sha]
        )
        digest = hashlib.sha256(stable_key.encode()).hexdigest()[:24]
        occurrences[digest] += 1
        expected = f"im_defrag_{digest}_{occurrences[digest]}"
        if row["record_id"] != expected:
            fail(f"unstable record ID: expected {expected}, got {row['record_id']}")
    admitted = rows[len(facts) :]
    expected_admitted = baseline_value("defrag.admitted_rows")
    if len(admitted) != expected_admitted:
        fail(f"admission row count drift: {len(admitted)}")
    if any(
        row["task_term"] != "rule_absent-absent(operation)"
        or "rule(absent)" not in row["evidence_term"]
        or "admission(unclaimed_student_task_statement)" not in row["evidence_term"]
        for row in admitted
    ):
        fail("an admission row does not record absent rule and operation")


def load_span_fixtures() -> list[dict]:
    return json.loads(FIXTURES.read_text(encoding="utf-8"))


def check_census(rows: list[dict]) -> None:
    status = Counter(row["status"] for row in rows)
    blockers = Counter(row["blocker"] for row in rows)
    expected_status = EXPECTED_STATUS.copy()
    expected_status["blocked_missing_visual"] = baseline_value(
        "defrag.visual_markers"
    )
    if status != expected_status:
        fail(f"status census drift: {status}")
    expected_blockers = EXPECTED_BLOCKERS.copy()
    expected_blockers["none"] = baseline_value("defrag.eligible_rows")
    if blockers != expected_blockers:
        fail(f"blocker census drift: {blockers}")
    expected_visuals = baseline_value("defrag.visual_markers")
    if sum(row["visual_count"] for row in rows) != expected_visuals:
        fail(f"visual absence-marker count is not {expected_visuals}")
    repair_classes = Counter(row["statement_repair_class"] for row in rows)
    if repair_classes != EXPECTED_REPAIR_CLASSES:
        fail(f"statement-repair census drift: {repair_classes}")
    if (
        sum(
            row["status"]
            in {"already_complete", "recovered", "recovered_with_referent"}
            for row in rows
        )
        != baseline_value("defrag.eligible_rows")
    ):
        fail("eligible record count disagrees with the baseline")
    widened = [
        row
        for row in rows
        if "provenance_class(widened_checkpoint_receipt_v1)" in row["evidence_term"]
    ]
    expected_widened = baseline_value("defrag.widened_receipts")
    if len(widened) != expected_widened:
        fail(f"widened receipt census is not {expected_widened}: {len(widened)}")
    if not all(
        "raw_response_checkpoint(" in row["evidence_term"]
        and "structured_reading_sha256(" in row["evidence_term"]
        and "acceptance_path(" in row["evidence_term"]
        for row in widened
    ):
        fail("widened source evidence lacks its checkpoint acceptance receipt")


def check_visual_markers() -> None:
    goal = VISUAL_GOAL if EXPERIMENTS.is_dir() else VISUAL_SCHEMA_GOAL
    result = subprocess.run(
        ["swipl", "-q", "-g", goal],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode:
        fail(f"visual absence-marker gate failed: {result.stderr.strip()}")


def check_span_fixtures(rows: list[dict]) -> None:
    fixtures = load_span_fixtures()
    expected_fixtures = baseline_value("defrag.span_fixtures")
    if len(fixtures) != expected_fixtures:
        fail(
            f"expected {expected_fixtures} source-span fixtures, "
            f"found {len(fixtures)}"
        )
    by_lesson: dict[str, list[dict]] = defaultdict(list)
    for row in rows:
        by_lesson[row["lesson"]].append(row)
    for fixture in fixtures:
        matches = [
            row
            for row in by_lesson[fixture["lesson"]]
            if row["complete_statement"] == fixture["statement"]
            and fixture["fragment"] in row["evidence_term"]
        ]
        if not matches:
            fail(
                f"source-span fixture did not join artifact: "
                f"{fixture['lesson']} / {fixture['fragment']}"
            )
        for row in matches:
            relevant = [
                segment
                for segment in row["source_segments"]
                if segment["id"] in row["statement_segments"]
                and segment["path"] == fixture["path"]
            ]
            if not relevant:
                fail(f"fixture uses the wrong source path: {fixture['lesson']}")
            if (
                min(segment["line_start"] for segment in relevant)
                < fixture["line_start"]
            ):
                fail(f"fixture starts before its cited span: {fixture['lesson']}")
            if max(segment["line_end"] for segment in relevant) > fixture["line_end"]:
                fail(f"fixture ends after its cited span: {fixture['lesson']}")


def check_l17_type_specimen() -> None:
    sys.path.insert(0, str(ROOT / "scripts/curriculum"))
    from build_im_defragged_task_instances import type_specimen_referents

    path = ROOT / "curriculum/im_teacher_guides/grade1/unit3/lesson17.md"
    lines = path.read_text(encoding="utf-8").split("\n")
    statement = " ".join(line.strip() for line in lines[318:323] if line.strip())
    expected = ["9 + 7", "10 + 6"]
    if type_specimen_referents(statement) != expected:
        fail("L17 adjacent parenthetical expressions are not first-class referents")
    for expression in expected:
        if expression.encode() not in path.read_bytes():
            fail(f"L17 referent is not copied from source bytes: {expression}")


def check_sentence_boundary_repair(rows: list[dict]) -> None:
    by_id = {row["record_id"]: row for row in rows}
    books = by_id["im_defrag_996f6ccc412f7f3e566aa8b4_1"]
    expected_books = (
        "Mai has 5 books about space. She checks out 4 more. "
        "How many books about space does Mai have? "
        "Show your thinking using drawings, numbers, or words."
    )
    if books["complete_statement"] != expected_books:
        fail("G1 books statement was not widened to its authored sentence boundary")
    if books["statement_repair_class"] != "span_starts_mid_sentence":
        fail("G1 books statement lacks its start-boundary repair class")

    train_error = by_id["im_defrag_e09043be9da9e9e18c44f2bd_1"]
    if train_error["source_statement"] != (
        "Students find the sum of the cubes rather than the difference."
    ):
        fail("G2 response excerpt was not widened through its wrapped source line")
    if train_error["statement_repair_class"] != "span_ends_early":
        fail("G2 response excerpt lacks its end-boundary repair class")

    sys.path.insert(0, str(ROOT / "scripts/curriculum"))
    import compile_action_mappings as compiler

    atomic = compiler.sentence_boundary_span("Find the value. 7 + 4", "7 + 4")
    if atomic.text != "7 + 4" or atomic.starts_mid_sentence or atomic.ends_early:
        fail("atomic mathematical spans must remain representation units")


def check_double_generation() -> None:
    with tempfile.TemporaryDirectory(prefix="hermes-im-defrag-") as directory:
        first = Path(directory) / "first.pl"
        second = Path(directory) / "second.pl"
        for output in (first, second):
            result = subprocess.run(
                [sys.executable, str(GENERATOR), "--output", str(output)],
                cwd=ROOT,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
            )
            if result.returncode:
                fail(f"regeneration failed: {result.stderr.strip()}")
        first_bytes = first.read_bytes()
        if first_bytes != second.read_bytes() or first_bytes != ARTIFACT.read_bytes():
            fail("double generation is not byte-identical to the tracked artifact")


def main() -> None:
    local_runtime_available = EXPERIMENTS.is_dir()
    rows = read_rows()
    check_identity(rows)
    check_census(rows)
    check_visual_markers()
    provenance = check_provenance(rows)
    check_span_fixtures(rows)
    check_l17_type_specimen()
    check_sentence_boundary_repair(rows)
    if local_runtime_available:
        check_double_generation()
        print(
            f"PASS im defrag: {baseline_value('defrag.rows'):,} rows; "
            f"{baseline_value('defrag.eligible_rows'):,} usable; "
            f"{baseline_value('defrag.admitted_rows'):,} unclaimed admissions; "
            f"{baseline_value('defrag.widened_receipts')} widened receipts; "
            f"385 layout blocks; {baseline_value('defrag.visual_markers')} visual blocks; "
            f"{baseline_value('defrag.span_fixtures')} spans; byte provenance and "
            "double generation"
        )
    else:
        print(
            "SKIP IM defrag local-source re-derivation: "
            "hermes/app/runtime/experiments absent locally (gitignored research state); "
            f"tracked Prolog load, {baseline_value('defrag.rows'):,}-row census, "
            f"visual marker schema, {provenance['verified_segments']} tracked byte spans, "
            "local span schemas, fixtures, and repair controls verified"
        )


if __name__ == "__main__":
    main()
