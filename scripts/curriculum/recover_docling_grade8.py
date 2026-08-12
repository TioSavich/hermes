#!/usr/bin/env python3
"""Recover blocked Grade 8 task statements from Docling JSON.

The pass is deliberately JSON first. It copies only items in the matched
Student Task Statement span, retains each raw JSON string, and stores a
separate deterministic rendering. Unsettled rows retain their original named
blocker. This module does not call a model.
"""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import copy
from difflib import SequenceMatcher
import hashlib
from itertools import combinations
import json
import os
from pathlib import Path
import re
import sys
import tempfile
import time
from typing import Any, Iterator


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.curriculum import compile_action_mappings as compiler  # noqa: E402
from scripts.curriculum import extract_docling_grade as extraction  # noqa: E402


BASE_CHECKPOINT_DIR = extraction.DEFAULT_CHECKPOINT_ROOT / "grade-8"
DEFAULT_RECOVERY_DIR = (
    ROOT / "hermes/app/runtime/experiments/docling_grade8_recovery"
)
DEFAULT_TASK_OUTPUT = extraction.GENERATED / "grade_8_extracted_task_instances.pl"
RUN_VERSION = "docling_grade8_json_recovery_v1"
NORMALIZATION_RULE = "docling_formula_spacing_v1"
TASK_HEADING_RE = re.compile(r"^Student Task Statement(?: \d+)?$")
BODY_START = "Activity Narrative"
BODY_CUTOFF_RE = re.compile(
    r"^(?:Lesson \d+ (?:Summary|Practice Problems)|Glossary)$"
)
ALLOWED_TEXT_LABELS = {"formula", "text", "list_item", "key_value_area"}
EXPRESSION_BLOCKERS = {
    "expression_missing_from_markdown",
    "expression_missing_without_visual",
}
SIBLING_SECTION_RE = re.compile(
    r"^(?:Student Response|Activity Synthesis|Lesson Synthesis|Launch|"
    r"Instructional Routines|Access for .+|Building on Student Thinking|"
    r"Responding to Student Thinking|Are You Ready for More\?)$"
)
INLINE_FURNITURE_RE = re.compile(r"^(?:\d+|\d+\.\d+|\d+\s+min)$", re.I)
UNDERSPECIFIED_STATEMENT_RE = re.compile(
    r"^(?:solve|graph|calculate|evaluate|find the value)\.?$", re.I
)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def atomic_write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temporary = Path(name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            handle.write(text)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    finally:
        if temporary.exists():
            temporary.unlink()


def atomic_write_json(path: Path, value: Any) -> None:
    atomic_write(path, json.dumps(value, indent=2, ensure_ascii=False) + "\n")


def _json_path(markdown_path: str) -> Path:
    path = ROOT / markdown_path
    return path.with_name("document.json")


def _resolve_ref(document: dict[str, Any], reference: str) -> dict[str, Any]:
    if not reference.startswith("#/"):
        raise ValueError(f"unsupported Docling reference: {reference}")
    value: Any = document
    for part in reference[2:].split("/"):
        part = part.replace("~1", "/").replace("~0", "~")
        value = value[int(part)] if isinstance(value, list) else value[part]
    if not isinstance(value, dict):
        raise ValueError(f"Docling reference is not an item: {reference}")
    return value


def _flatten_refs(document: dict[str, Any]) -> list[tuple[str, dict[str, Any]]]:
    ordered: list[tuple[str, dict[str, Any]]] = []
    active: set[str] = set()

    def visit(reference: str) -> None:
        if reference in active:
            raise ValueError(f"cycle in Docling body tree: {reference}")
        active.add(reference)
        item = _resolve_ref(document, reference)
        children = item.get("children", [])
        child_refs = [child.get("$ref") for child in children if child.get("$ref")]
        if child_refs:
            for child_ref in child_refs:
                visit(child_ref)
        else:
            ordered.append((reference, item))
        active.remove(reference)

    for child in document["body"].get("children", []):
        reference = child.get("$ref")
        if reference:
            visit(reference)
    return ordered


def _item_text(item: dict[str, Any]) -> str:
    value = item.get("text")
    return value if isinstance(value, str) else ""


def _task_spans(
    document: dict[str, Any],
) -> list[tuple[tuple[str, dict[str, Any]], list[tuple[str, dict[str, Any]]]]]:
    ordered = _flatten_refs(document)
    body_start = next(
        (index for index, (_ref, item) in enumerate(ordered) if _item_text(item) == BODY_START),
        None,
    )
    if body_start is None:
        raise ValueError("document.json has no Activity Narrative boundary")
    body_end = next(
        (
            index
            for index, (_ref, item) in enumerate(ordered[body_start + 1 :], body_start + 1)
            if BODY_CUTOFF_RE.fullmatch(_item_text(item))
        ),
        len(ordered),
    )
    headings = [
        index
        for index in range(body_start + 1, body_end)
        if TASK_HEADING_RE.fullmatch(_item_text(ordered[index][1]))
    ]
    spans = []
    for heading_index in headings:
        end = next(
            (
                index
                for index in range(heading_index + 1, body_end)
                if ordered[index][1].get("label") == "section_header"
                or TASK_HEADING_RE.fullmatch(_item_text(ordered[index][1]))
                or SIBLING_SECTION_RE.fullmatch(_item_text(ordered[index][1]))
            ),
            body_end,
        )
        spans.append((ordered[heading_index], ordered[heading_index + 1 : end]))
    return spans


def _align_spans(
    tasks: list[dict[str, Any]],
    candidates: list[
        tuple[
            tuple[str, dict[str, Any]],
            list[tuple[str, dict[str, Any]]],
            list[dict[str, Any]],
        ]
    ],
) -> list[
    tuple[
        tuple[str, dict[str, Any]],
        list[tuple[str, dict[str, Any]]],
        list[dict[str, Any]],
    ]
]:
    if len(candidates) < len(tasks):
        raise ValueError(
            f"JSON task-heading disagreement: expected at least {len(tasks)}, "
            f"found {len(candidates)}"
        )
    if len(candidates) == len(tasks):
        return candidates
    best_score = -1.0
    best: tuple[int, ...] | None = None
    for indices in combinations(range(len(candidates)), len(tasks)):
        score = 0.0
        for task, index in zip(tasks, indices):
            old = _collapse(task["excerpt"])
            new = _statement(candidates[index][2])
            if old == "Student Task Statement":
                continue
            score += SequenceMatcher(None, old, new, autojunk=False).ratio()
        if score > best_score:
            best_score = score
            best = indices
    assert best is not None
    return [candidates[index] for index in best]


def _encoded_value(value: str) -> list[bytes]:
    candidates = []
    for ensure_ascii in (False, True):
        encoded = json.dumps(value, ensure_ascii=ensure_ascii).encode("utf-8")
        if encoded not in candidates:
            candidates.append(encoded)
    return candidates


def _line_number(data: bytes, offset: int) -> int:
    return data.count(b"\n", 0, offset) + 1


def _locate_text_bytes(
    data: bytes, reference: str, raw: str
) -> tuple[int, int, int, str]:
    anchor = b'"self_ref": ' + json.dumps(reference).encode("utf-8")
    anchor_at = data.find(anchor)
    if anchor_at < 0:
        raise ValueError(f"self reference not found in JSON bytes: {reference}")
    next_ref = data.find(b'"self_ref"', anchor_at + len(anchor))
    limit = len(data) if next_ref < 0 else next_ref
    for encoded in _encoded_value(raw):
        needle = b'"text": ' + encoded
        found = data.find(needle, anchor_at, limit)
        if found >= 0:
            start = found + len(b'"text": ') + 1
            end = start + len(encoded) - 2
            decoder = "json_string_ascii" if b"\\u" in encoded else "json_string_utf8"
            return start, end, _line_number(data, start), decoder
    raise ValueError(f"text bytes not found for {reference}")


def _provenance(item: dict[str, Any]) -> tuple[int | None, dict[str, Any] | None]:
    rows = item.get("prov") or []
    if not rows:
        return None, None
    return rows[0].get("page_no"), rows[0].get("bbox")


def _collapse(value: str) -> str:
    return " ".join(value.split())


def normalize_formula(value: str) -> str:
    """Render Docling character-spaced formula text deterministically."""
    text = _collapse(value)
    previous = None
    while text != previous:
        previous = text
        text = re.sub(r"(?<=\d)\s+(?=\d)", "", text)
        text = re.sub(r"(?<=\d)\s*([.,])\s*(?=\d)", r"\1", text)
    text = re.sub(r"(?<=\d)\s+(?=[A-Za-z]\b)", "", text)
    text = re.sub(
        r"(^|(?<=[=({\[,;:]))\s*-\s+(?=[A-Za-z0-9\\])", "-", text
    )
    text = re.sub(r"\(\s+", "(", text)
    text = re.sub(r"\s+\)", ")", text)
    text = re.sub(r"\s+([,;:])", r"\1", text)
    return _collapse(text)


def normalize_item(kind: str, raw: str) -> str:
    return normalize_formula(raw) if kind == "formula" else _collapse(raw)


def _bbox_record(bbox: dict[str, Any] | None) -> dict[str, Any] | None:
    if bbox is None:
        return None
    return {key: bbox[key] for key in ("l", "t", "r", "b") if key in bbox}


def _text_record(
    json_path: Path,
    data: bytes,
    reference: str,
    item: dict[str, Any],
) -> dict[str, Any] | None:
    kind = item.get("label")
    raw = _item_text(item)
    if kind not in ALLOWED_TEXT_LABELS or not raw.strip():
        return None
    if kind == "text" and INLINE_FURNITURE_RE.fullmatch(raw.strip()):
        return None
    start, end, line, decoder = _locate_text_bytes(data, reference, raw)
    page, bbox = _provenance(item)
    index = int(reference.rsplit("/", 1)[1])
    return {
        "ref": reference,
        "index": index,
        "kind": kind,
        "raw": raw,
        "normalized": normalize_item(kind, raw),
        "page": page,
        "bbox": _bbox_record(bbox),
        "path": json_path.relative_to(ROOT).as_posix(),
        "byte_start": start,
        "byte_end": end,
        "line": line,
        "decoder": decoder,
    }


def _table_records(
    json_path: Path,
    data: bytes,
    reference: str,
    item: dict[str, Any],
) -> list[dict[str, Any]]:
    cells = item.get("data", {}).get("table_cells", [])
    page, table_bbox = _provenance(item)
    records = []
    cursor = data.find(b'"self_ref": ' + json.dumps(reference).encode("utf-8"))
    if cursor < 0:
        raise ValueError(f"table self reference not found: {reference}")
    for number, cell in enumerate(cells):
        raw = cell.get("text", "")
        if not isinstance(raw, str) or not raw.strip():
            continue
        hit = None
        encoded_hit = None
        for encoded in _encoded_value(raw):
            candidate = data.find(b'"text": ' + encoded, cursor)
            if candidate >= 0 and (hit is None or candidate < hit):
                hit, encoded_hit = candidate, encoded
        if hit is None or encoded_hit is None:
            raise ValueError(f"table cell text not found: {reference}/{number}")
        start = hit + len(b'"text": ') + 1
        end = start + len(encoded_hit) - 2
        cursor = end
        bbox = cell.get("bbox") or table_bbox
        records.append(
            {
                "ref": f"{reference}/data/table_cells/{number}",
                "index": number,
                "kind": "table",
                "raw": raw,
                "normalized": _collapse(raw),
                "page": page,
                "bbox": _bbox_record(bbox),
                "path": json_path.relative_to(ROOT).as_posix(),
                "byte_start": start,
                "byte_end": end,
                "line": _line_number(data, start),
                "decoder": "json_string_ascii" if b"\\u" in encoded_hit else "json_string_utf8",
                "row": cell.get("start_row_offset_idx"),
                "column": cell.get("start_col_offset_idx"),
            }
        )
    return records


def _harvest(
    json_path: Path,
    document: dict[str, Any],
    section: list[tuple[str, dict[str, Any]]],
) -> list[dict[str, Any]]:
    data = json_path.read_bytes()
    records = []
    for reference, item in section:
        if reference.startswith("#/texts/"):
            record = _text_record(json_path, data, reference, item)
            if record is not None:
                records.append(record)
        elif reference.startswith("#/tables/"):
            records.extend(_table_records(json_path, data, reference, item))
        elif reference.startswith("#/key_value_items/"):
            record = _text_record(json_path, data, reference, item)
            if record is not None:
                records.append(record)
    return records


def _statement(items: list[dict[str, Any]]) -> str:
    return " ".join(item["normalized"] for item in items if item["normalized"])


def _credible_formula(raw: str) -> bool:
    value = _collapse(raw)
    if len(value) < 3 or len(value) > 800:
        return False
    if value in {"-", "·", "."}:
        return False
    if re.search(r"\\cfrac\s*\{\s*\}|\[\s*some\s+stuff", value, re.I):
        return False
    if re.search(r"(?:\b[A-Za-z]\s+){8,}[A-Za-z]\b", value):
        return False
    if not re.search(r"\d", value):
        return False
    return value.count("{") == value.count("}")


def _still_has_plain_gap(statement: str) -> bool:
    return bool(
        re.search(
            r"\b(?:equation|expression|value|number|variable) is and\b|"
            r"\b(?:expression|equation) is\s*(?:[.,;:?]|$)",
            statement,
            re.I,
        )
    )


def _materially_new(task: dict[str, Any], items: list[dict[str, Any]], statement: str) -> bool:
    old = extraction._missing_expression(task["excerpt"])
    new = extraction._missing_expression(statement)
    if task["blocker"] in EXPRESSION_BLOCKERS:
        formulas = [item["raw"] for item in items if item["kind"] == "formula"]
        if not old or new or _still_has_plain_gap(statement):
            return False
        if _collapse(statement) == _collapse(task["excerpt"]):
            return False
        if formulas and all(_credible_formula(raw) for raw in formulas):
            overlap = SequenceMatcher(
                None,
                _collapse(task["excerpt"]),
                statement,
                autojunk=False,
            ).ratio()
            return overlap >= 0.65
        return len(statement) > len(_collapse(task["excerpt"]))
    if not statement or new:
        return False
    if UNDERSPECIFIED_STATEMENT_RE.fullmatch(statement):
        return False
    return _collapse(statement) not in {
        _collapse(task["excerpt"]),
        "Student Task Statement",
    }


def recover_payload(base: dict[str, Any]) -> dict[str, Any]:
    payload = copy.deepcopy(base)
    json_path = _json_path(base["source"])
    document = json.loads(json_path.read_text(encoding="utf-8"))
    spans = _task_spans(document)
    candidates = [
        (heading, section, _harvest(json_path, document, section))
        for heading, section in spans
    ]
    aligned = _align_spans(base["tasks"], candidates)
    recovered = 0
    for task, ((heading_ref, heading), _section, items) in zip(
        payload["tasks"], aligned
    ):
        if task["blocker"] == "none":
            continue
        statement = _statement(items)
        if not _materially_new(task, items, statement):
            continue
        task["excerpt"] = statement
        task["extraction_status"] = "recovered"
        task["blocker"] = "none"
        task["recovery"] = {
            "method": "docling_json",
            "source": json_path.relative_to(ROOT).as_posix(),
            "source_sha256": sha256_file(json_path),
            "heading_ref": heading_ref,
            "heading_index": int(heading_ref.rsplit("/", 1)[1]),
            "heading_raw": _item_text(heading),
            "items": items,
            "normalized_statement": statement,
            "normalization": NORMALIZATION_RULE,
        }
        recovered += 1
    payload["recovery_run_version"] = RUN_VERSION
    payload["json_source"] = json_path.relative_to(ROOT).as_posix()
    payload["json_source_sha256"] = sha256_file(json_path)
    payload["json_recoveries"] = recovered
    payload["model_calls"] = []
    return payload


def recovery_checkpoint_path(directory: Path, lesson: str) -> Path:
    return directory / "checkpoints" / f"{lesson}.json"


def compatible_recovery_checkpoint(
    path: Path, base: dict[str, Any]
) -> dict[str, Any] | None:
    if not path.is_file():
        return None
    payload = json.loads(path.read_text(encoding="utf-8"))
    json_path = _json_path(base["source"])
    if (
        payload.get("run_version") == base.get("run_version")
        and payload.get("source_sha256") == base.get("source_sha256")
        and payload.get("recovery_run_version") == RUN_VERSION
        and payload.get("json_source_sha256") == sha256_file(json_path)
    ):
        return payload
    return None


def load_base_payloads(lessons: list[str]) -> list[dict[str, Any]]:
    docs = extraction.discover_docs(8, compiler)
    if lessons:
        wanted = set(lessons)
        docs = [doc for doc in docs if doc.code in wanted]
        missing = sorted(wanted - {doc.code for doc in docs})
        if missing:
            raise ValueError("unknown requested lessons: " + ", ".join(missing))
    payloads = []
    for doc in docs:
        path = extraction.checkpoint_path(BASE_CHECKPOINT_DIR, doc.code)
        payload = extraction.compatible_checkpoint(path, doc)
        if payload is None:
            raise ValueError(f"missing or stale base checkpoint: {doc.code}")
        payloads.append(payload)
    return payloads


def build_summary(payloads: list[dict[str, Any]], resumed: int, wall: float) -> dict[str, Any]:
    before = Counter()
    after = Counter()
    recovered_from = Counter()
    recoveries = 0
    provider_calls = 0
    for payload in payloads:
        provider_calls += sum(
            max(1, int(call.get("attempts", 1)))
            for call in payload.get("model_calls", [])
        )
        base_path = extraction.checkpoint_path(BASE_CHECKPOINT_DIR, payload["lesson"])
        base = json.loads(base_path.read_text(encoding="utf-8"))
        for old, new in zip(base["tasks"], payload["tasks"]):
            before[old["extraction_status"]] += 1
            after[new["extraction_status"]] += 1
            if new["extraction_status"] == "recovered":
                recovered_from[old["blocker"]] += 1
                recoveries += 1
    remaining = Counter(
        task["blocker"]
        for payload in payloads
        for task in payload["tasks"]
        if task["blocker"] != "none"
    )
    return {
        "run_version": RUN_VERSION,
        "lessons": len(payloads),
        "tasks": sum(after.values()),
        "before_status_counts": dict(sorted(before.items())),
        "after_status_counts": dict(sorted(after.items())),
        "recovered": recoveries,
        "recovered_by_original_blocker": dict(sorted(recovered_from.items())),
        "remaining_blockers": dict(sorted(remaining.items())),
        "provider_calls": {"REALLMS_gemma_4_31B_it": provider_calls},
        "resumed_checkpoints": resumed,
        "wall_seconds": round(wall, 3),
    }


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lessons", help="comma-separated canonical lesson ids")
    parser.add_argument("--checkpoint-dir", type=Path, default=DEFAULT_RECOVERY_DIR)
    parser.add_argument("--task-output", type=Path, default=DEFAULT_TASK_OUTPUT)
    parser.add_argument("--summary-output", type=Path)
    parser.add_argument("--refresh", action="store_true")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args(argv)
    args.summary_output = args.summary_output or args.checkpoint_dir / "summary.json"
    args.lessons = [] if not args.lessons else [part.strip() for part in args.lessons.split(",")]
    if any(not part for part in args.lessons):
        parser.error("--lessons must contain nonblank comma-separated ids")
    return args


def run(args: argparse.Namespace) -> dict[str, Any]:
    started = time.monotonic()
    bases = load_base_payloads(args.lessons)
    payloads = []
    resumed = 0
    for base in bases:
        path = recovery_checkpoint_path(args.checkpoint_dir, base["lesson"])
        payload = None if args.refresh else compatible_recovery_checkpoint(path, base)
        if payload is None:
            payload = recover_payload(base)
            if not args.check:
                atomic_write_json(path, payload)
        else:
            resumed += 1
        payloads.append(payload)
    task_text = extraction.render_tasks(8, payloads)
    summary = build_summary(payloads, resumed, time.monotonic() - started)
    summary_text = json.dumps(summary, indent=2, sort_keys=True) + "\n"
    outputs = ((args.task_output, task_text), (args.summary_output, summary_text))
    if args.check:
        stale = []
        if (
            not args.task_output.is_file()
            or args.task_output.read_text(encoding="utf-8") != task_text
        ):
            stale.append(args.task_output)
        if args.summary_output.is_file():
            stored = json.loads(args.summary_output.read_text(encoding="utf-8"))
            stable_keys = set(summary) - {"resumed_checkpoints", "wall_seconds"}
            if any(stored.get(key) != summary.get(key) for key in stable_keys):
                stale.append(args.summary_output)
        else:
            stale.append(args.summary_output)
        if stale:
            raise SystemExit("stale recovery outputs: " + ", ".join(map(str, stale)))
    else:
        for path, text in outputs:
            atomic_write(path, text)
    print(json.dumps(summary, sort_keys=True))
    return summary


def iter_recovered_tasks(payloads: list[dict[str, Any]]) -> Iterator[dict[str, Any]]:
    for payload in payloads:
        for task in payload["tasks"]:
            if task["extraction_status"] == "recovered":
                yield task


def main(argv: list[str] | None = None) -> int:
    run(parse_args(argv))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
