#!/usr/bin/env python3
"""Keep task-span strategy widening attached only to stated student work."""
from __future__ import annotations

import json
import pathlib
import sys


ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "curriculum"))

import compile_action_mappings as compiler  # noqa: E402


REFUSAL_CODES = {
    "IM-GK-U1-L1": "Explore Connecting Cubes",
    "IM-GK-U1-L2": "Explore Pattern Blocks",
}
BITE_CODE = "IM-G2-U3-L9"
EXPECTED_HAND_TEMPLATED = {
    "IM-G2-U3-L14",
    "IM-G2-U3-L9",
    "IM-G3-U8-L7",
    "IM-G5-U2-L5",
    "IM-GK-U8-L8",
}
EXPECTED_DOCLING = {
    "IM-G7-U1-L2",
    "IM-G7-U1-L4",
    "IM-G7-U3-L1",
    "IM-G7-U7-L17",
    "IM-G7-U7-L3",
    "IM-G7-U7-L4",
    "IM-G7-U9-L10",
    "IM-G8-U1-L10",
    "IM-G8-U1-L4",
    "IM-G8-U1-L6",
    "IM-G8-U1-L7",
    "IM-G8-U7-L9",
    "IM-G8-U9-L2",
}
DOCLING_GUIDES = compiler.MIDDLE_GUIDE_ROOT


def task_span_rows() -> list[compiler.Mapping]:
    rules = json.loads(compiler.DEFAULT_RULES.read_text(encoding="utf-8"))
    docs = compiler.read_teacher_guides(ROOT)
    explicit = compiler.read_explicit_mappings(ROOT)
    spans = compiler.extract_student_task_spans(docs)
    parser_spans = spans + compiler.read_recovered_task_spans(ROOT, spans)
    legacy = compiler.compile_rule_mappings(docs, rules, explicit)
    baseline = sorted(
        set(legacy + compiler.compile_scope_batches(
            rules, explicit, compiler.read_scope_titles(ROOT)
        ))
    )
    attachments = {code: set(rows) for code, rows in explicit.items()}
    for mapping in baseline:
        attachments.setdefault(mapping.code, set()).add((mapping.operation, mapping.kind))
    candidates = compiler.extract_task_candidates(parser_spans, attachments)
    baseline = sorted(set(
        baseline + compiler.compile_task_derived_mappings(candidates, explicit, baseline)
    ))
    baseline_attached = set(explicit) | {mapping.code for mapping in baseline}
    return compiler.compile_task_span_rule_mappings(
        docs, rules, baseline_attached, spans
    )


def assert_unattached(rows: list[compiler.Mapping], code: str) -> None:
    if any(row.code == code for row in rows):
        raise SystemExit(f"task-span strategy attachment is forbidden for {code}")


def main() -> int:
    rows = task_span_rows()
    codes = {row.code for row in rows}
    docling_available = DOCLING_GUIDES.is_dir()
    expected = EXPECTED_HAND_TEMPLATED | (EXPECTED_DOCLING if docling_available else set())
    if codes != expected:
        raise SystemExit(f"unexpected task-span strategy lesson set: {sorted(codes)}")
    corpora = {
        row.code: compiler._source_corpus(row.source)
        for row in rows
    }
    if {
        code for code, corpus in corpora.items()
        if corpus == compiler.HAND_TEMPLATED_GUIDE_CORPUS
    } != EXPECTED_HAND_TEMPLATED:
        raise SystemExit("hand-templated task-span provenance changed")
    if docling_available and {
        code for code, corpus in corpora.items()
        if corpus == compiler.DOCLING_GUIDE_CORPUS
    } != EXPECTED_DOCLING:
        raise SystemExit("Docling task-span provenance changed")
    for code, title in REFUSAL_CODES.items():
        assert_unattached(rows, code)
        print(f"refusal: {code} ({title}) remains unattached")

    # BITE: applying the same refusal assertion to a known, operation-bearing
    # task-span row must fail. Catching the failure makes the control observable
    # without making this check fail.
    try:
        assert_unattached(rows, BITE_CODE)
    except SystemExit as error:
        print(f"bite: {error}")
    else:
        raise SystemExit(f"refusal control did not bite for {BITE_CODE}")

    if docling_available:
        rendered, _, _ = compiler.build(ROOT, compiler.DEFAULT_RULES)
    else:
        rendered = compiler.DEFAULT_OUTPUT.read_text(encoding="utf-8")
    for row in rows:
        if not row.excerpt or row.end_line < row.line:
            raise SystemExit(f"unquoted or invalid task-span provenance: {row}")
        required = (
            f"matched_field(task_span)",
            f"span_position('{row.span_position}')",
            f"lines({row.line}, {row.end_line})",
            json.dumps(row.excerpt, ensure_ascii=True),
        )
        if not all(fragment in rendered for fragment in required):
            raise SystemExit(f"task-span provenance did not render for {row.code}")
    if not docling_available:
        print(
            "SKIP Docling task-span refusal rows: "
            "hermes/app/runtime/experiments/gemma4_tutor/docling/full-output/"
            "TeacherLessonGuides absent locally (docling full-output); "
            f"the exact {len(rows)}-row hand-templated set, two refusals, bite control, "
            "and rendered provenance verified"
        )
    else:
        print(f"provenance: {len(rows)} task-span rows are quoted and line-addressable")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
