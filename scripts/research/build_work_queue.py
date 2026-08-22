#!/usr/bin/env python3
"""Build the tracked work queue from repository and run-2 evidence."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import tempfile
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any, Iterable


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_AUDIT_DIR = ROOT / ".bigred-collected/2026-08-19-total-audit"
DEFAULT_JSON_OUTPUT = ROOT / "data/research/work_queue.json"
DEFAULT_MD_OUTPUT = ROOT / "data/research/work_queue.md"
ADDENDA_PATH = ROOT / "data/research/work_queue_addenda.json"
RESOLUTIONS_PATH = ROOT / "data/research/work_queue_resolutions.json"
LIFECYCLE_PATH = ROOT / "knowledge/index/consumption_lifecycle.pl"
ATTESTED_PATH = ROOT / "knowledge/index/consumption_attested_run2.pl"
CENSUS_PATH = ROOT / "data/research/self_description_census.json"
TEACHER_LABELS_PATH = ROOT / "curriculum/im/generated/admitted_teacher_question_labels.pl"
GUIDE_QUESTIONS_PATH = ROOT / "curriculum/im/generated/admitted_guide_questions.pl"
REVIEW_PROPOSALS_PATH = ROOT / "knowledge/index/admitted_review_proposals.pl"
RENDER_LINK_PATH = ROOT / "knowledge/strategies/render/misconception_render_link.pl"

AUDIT_LEDGER_NAME = "audit_ledger.json"
SWEEP_RESULTS_NAME = "sweep_results.jsonl"
TIER_ORDER = {name: index for index, name in enumerate(
    ("structural", "store", "held", "defect", "authoring")
)}

LIFECYCLE_LINE = re.compile(
    r"^store_lifecycle\('([^']+)',\s*([a-z_]+),\s*"
    r"(?:'([^']+)'|(none_named)),\s*'([^']+)',\s*\"(.*)\"\)\.$"
)
ATTESTED_LINE = re.compile(r"^store_consumption_attested\('([^']+)',")


class WorkQueueError(RuntimeError):
    """Raised when a required input contradicts the queue contract."""


def read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def parse_lifecycles() -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for line in LIFECYCLE_PATH.read_text(encoding="utf-8").splitlines():
        match = LIFECYCLE_LINE.match(line)
        if not match:
            continue
        store, lifecycle, quoted_consumer, bare_consumer, since, note = match.groups()
        rows.append(
            {
                "store": store,
                "lifecycle": lifecycle,
                "consumer": quoted_consumer or bare_consumer,
                "since": since,
                "note": note,
            }
        )
    if not rows:
        raise WorkQueueError(f"no lifecycle rows parsed from {LIFECYCLE_PATH}")
    stores = [row["store"] for row in rows]
    duplicates = sorted(name for name, count in Counter(stores).items() if count > 1)
    if duplicates:
        raise WorkQueueError(f"duplicate lifecycle stores: {duplicates}")
    return rows


def parse_attested_stores() -> set[str]:
    stores: set[str] = set()
    for line in ATTESTED_PATH.read_text(encoding="utf-8").splitlines():
        match = ATTESTED_LINE.match(line)
        if match:
            stores.add(match.group(1))
    if not stores:
        raise WorkQueueError(f"no attested rows parsed from {ATTESTED_PATH}")
    return stores


def first_terminal_rows(rows: Iterable[dict[str, Any]]) -> list[dict[str, Any]]:
    """Keep the first non-circuit outcome, or the first circuit-only record."""
    terminal: dict[str, dict[str, Any]] = {}
    circuit_only: dict[str, dict[str, Any]] = {}
    order: list[str] = []
    for row in rows:
        identifier = row.get("id")
        if not isinstance(identifier, str) or not identifier:
            raise WorkQueueError("sweep row has no string id")
        if identifier not in terminal and identifier not in circuit_only:
            order.append(identifier)
        if identifier in terminal:
            continue
        if row.get("outcome") == "op_circuit_open":
            circuit_only.setdefault(identifier, row)
        else:
            terminal[identifier] = row
    return [
        terminal[identifier] if identifier in terminal else circuit_only[identifier]
        for identifier in order
    ]


def load_sweep(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError as exc:
            raise WorkQueueError(f"invalid sweep JSON at line {line_number}: {exc}") from exc
        if not isinstance(row.get("op"), str) or not isinstance(row.get("outcome"), str):
            raise WorkQueueError(f"incomplete sweep row at line {line_number}")
        rows.append(row)
    if not rows:
        raise WorkQueueError(f"no sweep rows parsed from {path}")
    return rows


def predicate_count(path: Path, predicate: str) -> int:
    pattern = re.compile(rf"^{re.escape(predicate)}\(")
    return sum(
        1
        for line in path.read_text(encoding="utf-8").splitlines()
        if pattern.match(line)
    )


def store_entries(audit: dict[str, Any]) -> list[dict[str, Any]]:
    files = audit.get("files")
    if not isinstance(files, list):
        raise WorkQueueError("audit ledger has no files list")
    by_path = {row.get("path"): row for row in files if isinstance(row, dict)}
    lifecycles = parse_lifecycles()
    attested = parse_attested_stores()
    overlap = sorted(row["store"] for row in lifecycles if row["store"] in attested)
    if overlap:
        raise WorkQueueError(
            "stores occur in both lifecycle and run-2 attestation stores: "
            + ", ".join(overlap)
        )

    entries: list[dict[str, Any]] = []
    for row in lifecycles:
        if row["lifecycle"] not in {"stalled_input", "quarantined"}:
            continue
        audit_row = by_path.get(row["store"])
        if audit_row is None:
            raise WorkQueueError(
                f"lifecycle store is absent from the run-2 ledger: {row['store']}"
            )
        facts = audit_row.get("facts")
        if not isinstance(facts, int) or isinstance(facts, bool) or facts < 0:
            raise WorkQueueError(f"invalid fact count for {row['store']}: {facts!r}")
        # Preserve the run-2 Stage-B size boundary while accepting 0822B's
        # lifecycle verdict as the authority on whether the store is stalled.
        if facts < 20:
            continue
        lifecycle = row["lifecycle"]
        action = "Provide a consumer for" if lifecycle == "stalled_input" else "Review quarantine for"
        entries.append(
            {
                "id": f"store:{row['store']}",
                "title": f"{action} {row['store']}",
                "rows_blocked": facts,
                "tier": "store",
                "source": (
                    "knowledge/index/consumption_lifecycle.pl; "
                    "knowledge/index/consumption_attested_run2.pl; "
                    ".bigred-collected/2026-08-19-total-audit/audit_ledger.json"
                ),
                "evidence": {
                    "authoritative_status": lifecycle,
                    "consumer": row["consumer"],
                    "since": row["since"],
                    "note": row["note"],
                    "run2_facts": facts,
                    "run2_jobs": [8028943, 8028944],
                    "collected": "2026-08-22",
                },
            }
        )
    return entries


def refusal_entries(sweep_rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    deduped = first_terminal_rows(sweep_rows)
    by_op: dict[str, Counter[str]] = defaultdict(Counter)
    for row in deduped:
        by_op[row["op"]][row["outcome"]] += 1

    entries: list[dict[str, Any]] = []
    for op, outcomes in sorted(by_op.items()):
        refused = outcomes["refused"]
        if refused == 0:
            continue
        total = sum(outcomes.values())
        full_refusal = total >= 3 and refused == total
        entries.append(
            {
                "id": f"op-refusal:{op}",
                "title": (
                    f"Resolve 100% refusal surface for {op}"
                    if full_refusal
                    else f"Review refusal surface for {op}"
                ),
                "rows_blocked": refused,
                "tier": "structural",
                "source": (
                    ".bigred-collected/2026-08-19-total-audit/"
                    "sweep_results.jsonl"
                ),
                "evidence": {
                    "dedup": "first_terminal",
                    "total": total,
                    "ok": outcomes["ok"],
                    "refused": refused,
                    "timeout": outcomes["timeout"],
                    "op_circuit_open": outcomes["op_circuit_open"],
                    "refusal_rate": round(refused / total, 6),
                    "full_refusal_n_ge_3": full_refusal,
                    "run2_jobs": [8028943, 8028944],
                    "collected": "2026-08-22",
                },
            }
        )
    return entries


def held_entries() -> list[dict[str, Any]]:
    teacher = predicate_count(TEACHER_LABELS_PATH, "held_question_label")
    guide = predicate_count(GUIDE_QUESTIONS_PATH, "held_guide_question")
    proposals = predicate_count(REVIEW_PROPOSALS_PATH, "held_signature_anchor")
    proposals += predicate_count(REVIEW_PROPOSALS_PATH, "held_unit_recognition_proposal")
    unlinked = predicate_count(RENDER_LINK_PATH, "misconception_render_unlinked")
    rows = [
        (
            "held:teacher-question-labels",
            "Run an admission pass on held teacher-question labels",
            teacher,
            TEACHER_LABELS_PATH,
            "held_question_label/6 rows",
        ),
        (
            "held:guide-questions",
            "Run an admission pass on held guide questions",
            guide,
            GUIDE_QUESTIONS_PATH,
            "held_guide_question/6 rows",
        ),
        (
            "held:review-proposals",
            "Run an admission pass on held review proposals",
            proposals,
            REVIEW_PROPOSALS_PATH,
            "held_signature_anchor/9 and held_unit_recognition_proposal/6 rows",
        ),
        (
            "held:misconception-render-links",
            "Author warranted links for unlinked render deformations",
            unlinked,
            RENDER_LINK_PATH,
            "misconception_render_unlinked/2 rows",
        ),
    ]
    return [
        {
            "id": identifier,
            "title": title,
            "rows_blocked": count,
            "tier": "held",
            "source": path.relative_to(ROOT).as_posix(),
            "evidence": {"derived_from": derivation, "count": count},
        }
        for identifier, title, count, path, derivation in rows
    ]


def census_entries() -> list[dict[str, Any]]:
    census = read_json(CENSUS_PATH)
    undetermined = [
        row for row in census.get("orphan_modules", [])
        if row.get("verdict") == "undetermined"
    ]
    unrouted = census.get("unrouted", [])
    if not isinstance(unrouted, list):
        raise WorkQueueError("self-description census unrouted field is not a list")
    return [
        {
            "id": "census:orphan-modules-undetermined",
            "title": "Adjudicate census orphan modules with undetermined status",
            "rows_blocked": len(undetermined),
            "tier": "store",
            "source": "data/research/self_description_census.json",
            "evidence": {
                "verdict": "undetermined",
                "paths": sorted(row["path"] for row in undetermined),
            },
        },
        {
            "id": "census:unrouted",
            "title": "Review unrouted capability rows",
            "rows_blocked": len(unrouted),
            "tier": "structural",
            "source": "data/research/self_description_census.json",
            "evidence": {"names": sorted(row["name"] for row in unrouted)},
        },
    ]


def addenda_entries() -> list[dict[str, Any]]:
    data = read_json(ADDENDA_PATH)
    if not isinstance(data, list):
        raise WorkQueueError(f"{ADDENDA_PATH.relative_to(ROOT)} must contain a JSON list")
    return data


RESOLUTION_KEYS = {"id", "resolution", "date", "finding", "evidence"}


def parse_resolutions() -> list[dict[str, str]]:
    """Read the authored resolutions that retire queue entries.

    A resolution names a queue id whose blocking condition no longer holds
    (the op was verified serving, retired, or repaired) while the collected
    audit evidence still reproduces the entry. Resolved entries leave the
    ranked tables and appear in their own section, so the queue stops
    re-issuing settled work between audit runs.
    """
    if not RESOLUTIONS_PATH.is_file():
        return []
    data = read_json(RESOLUTIONS_PATH)
    if not isinstance(data, list):
        raise WorkQueueError(
            f"{RESOLUTIONS_PATH.relative_to(ROOT)} must contain a JSON list"
        )
    rows: list[dict[str, str]] = []
    for index, row in enumerate(data):
        if not isinstance(row, dict) or set(row) != RESOLUTION_KEYS:
            raise WorkQueueError(
                f"resolution entry {index} must carry exactly {sorted(RESOLUTION_KEYS)}"
            )
        for key in RESOLUTION_KEYS:
            if not isinstance(row[key], str) or not row[key].strip():
                raise WorkQueueError(f"resolution entry {index} has an empty {key}")
        rows.append(row)
    identifiers = Counter(row["id"] for row in rows)
    duplicates = sorted(name for name, count in identifiers.items() if count > 1)
    if duplicates:
        raise WorkQueueError(f"duplicate resolution ids: {duplicates}")
    return rows


def sort_entries(entries: Iterable[dict[str, Any]]) -> list[dict[str, Any]]:
    return sorted(
        entries,
        key=lambda row: (
            -row["rows_blocked"],
            TIER_ORDER.get(row["tier"], len(TIER_ORDER)),
            row["id"],
        ),
    )


def build_full(
    audit_dir: Path = DEFAULT_AUDIT_DIR,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]], list[dict[str, str]]]:
    """Return (active entries, resolved entries, prunable resolutions)."""
    audit = read_json(audit_dir / AUDIT_LEDGER_NAME)
    sweep = load_sweep(audit_dir / SWEEP_RESULTS_NAME)
    entries = [
        *store_entries(audit),
        *refusal_entries(sweep),
        *held_entries(),
        *census_entries(),
        *addenda_entries(),
    ]
    resolutions = {row["id"]: row for row in parse_resolutions()}
    active = [row for row in entries if row["id"] not in resolutions]
    resolved = [
        {**row, "resolution": resolutions[row["id"]]}
        for row in entries
        if row["id"] in resolutions
    ]
    produced = {row["id"] for row in entries}
    prunable = [row for name, row in sorted(resolutions.items()) if name not in produced]
    return sort_entries(active), sort_entries(resolved), prunable


def build(audit_dir: Path = DEFAULT_AUDIT_DIR) -> list[dict[str, Any]]:
    active, _resolved, _prunable = build_full(audit_dir)
    return active


def render_json(entries: list[dict[str, Any]]) -> str:
    return json.dumps(entries, indent=2, sort_keys=True, ensure_ascii=False) + "\n"


def compact_evidence(evidence: Any) -> str:
    if not isinstance(evidence, dict):
        return str(evidence)
    preferred = (
        "authoritative_status",
        "consumer",
        "derived_from",
        "refused",
        "total",
        "ok",
        "timeout",
        "op_circuit_open",
        "full_refusal_n_ge_3",
        "count",
        "finding",
    )
    parts = []
    for key in preferred:
        if key in evidence:
            parts.append(f"{key}={evidence[key]}")
    if not parts:
        for key, value in evidence.items():
            if isinstance(value, list):
                parts.append(f"{key}={len(value)} rows")
            else:
                parts.append(f"{key}={value}")
    return "; ".join(parts)


def table_escape(value: Any) -> str:
    return str(value).replace("|", "\\|").replace("\n", " ")


def render_table(entries: list[dict[str, Any]]) -> list[str]:
    lines = [
        "| rank | work item | rows blocked | source | evidence |",
        "|---:|---|---:|---|---|",
    ]
    for rank, row in enumerate(entries, 1):
        lines.append(
            "| "
            + " | ".join(
                (
                    str(rank),
                    f"`{table_escape(row['id'])}`<br>{table_escape(row['title'])}",
                    f"{row['rows_blocked']:,}",
                    f"`{table_escape(row['source'])}`",
                    table_escape(compact_evidence(row["evidence"])),
                )
            )
            + " |"
        )
    return lines


def render_resolved_table(
    resolved: list[dict[str, Any]], prunable: list[dict[str, str]]
) -> list[str]:
    lines = [
        "| work item | rows in evidence | resolution | date | finding |",
        "|---|---:|---|---|---|",
    ]
    for row in resolved:
        resolution = row["resolution"]
        lines.append(
            "| "
            + " | ".join(
                (
                    f"`{table_escape(row['id'])}`",
                    f"{row['rows_blocked']:,}",
                    table_escape(resolution["resolution"]),
                    table_escape(resolution["date"]),
                    table_escape(resolution["finding"]),
                )
            )
            + " |"
        )
    if prunable:
        names = ", ".join(f"`{table_escape(row['id'])}`" for row in prunable)
        lines.extend(
            [
                "",
                "Resolutions with no matching entry in the current evidence "
                f"(prunable from `data/research/work_queue_resolutions.json`): {names}.",
            ]
        )
    return lines


def render_markdown(
    entries: list[dict[str, Any]],
    resolved: list[dict[str, Any]] | None = None,
    prunable: list[dict[str, str]] | None = None,
) -> str:
    resolved = resolved or []
    prunable = prunable or []
    lines = [
        "# Generated work queue",
        "",
        "This queue ranks stalled inputs, refusal surfaces, held rows, census absences, and authored findings. It names work that blocks rows. It does not license deleting unconsumed stores.",
        "",
        "Store status comes from `knowledge/index/consumption_lifecycle.pl` and `knowledge/index/consumption_attested_run2.pl`. Run-2 row counts and refusal outcomes come from jobs 8028943 and 8028944, collected 2026-08-22. Entries retired by `data/research/work_queue_resolutions.json` appear under Resolved instead of the ranked tables.",
        "",
    ]
    for tier in TIER_ORDER:
        tier_rows = [row for row in entries if row["tier"] == tier]
        lines.extend([f"## {tier.capitalize()}", ""])
        if tier == "structural":
            full = [
                row for row in tier_rows
                if isinstance(row.get("evidence"), dict)
                and row["evidence"].get("full_refusal_n_ge_3") is True
            ]
            other = [row for row in tier_rows if row not in full]
            lines.extend(["### 100% refusal operations with at least 3 requests", ""])
            lines.extend(render_table(full) if full else ["No entries."])
            lines.extend(["", "### Other structural surfaces", ""])
            lines.extend(render_table(other) if other else ["No entries."])
        else:
            lines.extend(render_table(tier_rows) if tier_rows else ["No entries."])
        lines.append("")
    if resolved or prunable:
        lines.extend(["## Resolved", ""])
        lines.extend(render_resolved_table(resolved, prunable))
        lines.append("")
    return "\n".join(lines)


def write_atomic(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temporary = Path(name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    finally:
        if temporary.exists():
            temporary.unlink()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--audit-dir", type=Path, default=DEFAULT_AUDIT_DIR)
    parser.add_argument("--json-output", type=Path, default=DEFAULT_JSON_OUTPUT)
    parser.add_argument("--md-output", type=Path, default=DEFAULT_MD_OUTPUT)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    ledger = args.audit_dir / AUDIT_LEDGER_NAME
    sweep = args.audit_dir / SWEEP_RESULTS_NAME
    if not ledger.is_file() or not sweep.is_file():
        if args.json_output.is_file() and args.md_output.is_file():
            print(
                "carried forward work queue unchanged: audit collection is absent at "
                f"{args.audit_dir}"
            )
            return 0
        print(
            "cannot carry forward work queue because an output is absent: "
            f"{args.json_output}, {args.md_output}",
            file=sys.stderr,
        )
        return 1
    try:
        entries, resolved, prunable = build_full(args.audit_dir)
        write_atomic(args.json_output, render_json(entries))
        write_atomic(args.md_output, render_markdown(entries, resolved, prunable))
    except (OSError, ValueError, WorkQueueError) as exc:
        print(f"build_work_queue.py: {exc}", file=sys.stderr)
        return 1
    print(
        f"wrote {args.json_output}: {len(entries)} entries "
        f"({len(resolved)} resolved, {len(prunable)} prunable resolutions); "
        f"wrote {args.md_output}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
