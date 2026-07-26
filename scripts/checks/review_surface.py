#!/usr/bin/env python3
"""Check the aggregate review queues, evidence, diagnostics, and append log."""
from __future__ import annotations

import json
import re
import shutil
import sqlite3
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
LESSON_PROPOSALS = ROOT / "data/research/grade78_pairing_proposals.jsonl"
CORPUS_PROPOSALS = ROOT / "data/research/corpus_binding_proposals.json"
CORPUS_DIAGNOSTICS = ROOT / "data/research/corpus_binding_diagnostics.json"
FIELD_CONTEXT = ROOT / "curriculum/im/generated/field_context_cache.json"
CORPUS_WINDOW = ROOT / "knowledge/index/corpus_window.pl"
RESEARCH_DB = ROOT / "data/research/research_shared.db"
REVIEW_MODULE = ROOT / "hermes/review_queue.pl"
REVIEW_PAGE = ROOT / "hermes/web/review.html"

WINDOW_RE = re.compile(
    r"(?m)^window_row\(\s*([a-z][a-z0-9_]*)\s*,\s*"
    r"([a-z][a-z0-9_]*)\s*,"
)


def fail(message: str) -> None:
    raise AssertionError(message)


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    return [
        json.loads(line)
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]


def proposal_integrity() -> tuple[int, int]:
    lesson_rows = read_jsonl(LESSON_PROPOSALS)
    corpus_rows = json.loads(CORPUS_PROPOSALS.read_text(encoding="utf-8")).get(
        "proposals"
    )
    if not isinstance(corpus_rows, list):
        fail("corpus_binding_proposals.json has no proposals list")
    contexts = json.loads(FIELD_CONTEXT.read_text(encoding="utf-8")).get(
        "field_contexts", {}
    )
    machines = {
        f"{family}/{signature}"
        for family, signature in WINDOW_RE.findall(
            CORPUS_WINDOW.read_text(encoding="utf-8")
        )
    }

    units: set[str] = set()
    for row in lesson_rows:
        lesson = row.get("lesson")
        if lesson not in contexts:
            fail(f"lesson proposal does not resolve in field context: {lesson}")
        unit = "-".join(str(lesson).split("-")[:3])
        if len(unit.split("-")) != 3:
            fail(f"lesson proposal has no unit identity: {lesson}")
        units.add(unit)
        pairings = row.get("pairings")
        if not isinstance(pairings, list):
            fail(f"lesson proposal has no pairings list: {lesson}")
        for pairing in pairings:
            machine = pairing.get("machine")
            if machine not in machines:
                fail(f"lesson proposal machine does not resolve: {lesson} -> {machine}")

    connection = sqlite3.connect(f"file:{RESEARCH_DB}?mode=ro", uri=True)
    try:
        article_keys = {
            row[0]
            for row in connection.execute(
                "SELECT bibtex_key FROM articles WHERE bibtex_key IS NOT NULL"
            )
        }
    finally:
        connection.close()

    identities: set[str] = set()
    for proposal in corpus_rows:
        machine = f"{proposal.get('family')}/{proposal.get('signature')}"
        if machine not in machines:
            fail(
                "corpus proposal machine does not resolve: "
                f"row {proposal.get('row_id')} -> {machine}"
            )
        citation = proposal.get("bibtex_key")
        if citation != "unattributed" and citation not in article_keys:
            fail(f"corpus proposal citation does not resolve: {citation}")
        identity = (
            f"{proposal.get('row_type')}:{proposal.get('row_id')}:{machine}"
        )
        if identity in identities:
            fail(f"duplicate corpus proposal identity: {identity}")
        identities.add(identity)

    print(
        "proposal resolution: "
        f"{len(lesson_rows)} lessons in {len(units)} units; "
        f"{len(corpus_rows)} corpus proposals; all evidence keys resolve PASS"
    )
    return len(units), len(corpus_rows)


def diagnostics_integrity(corpus_total: int) -> tuple[dict[str, int], int]:
    sys.path.insert(0, str(ROOT / "scripts/research"))
    import build_review_diagnostics as diagnostics  # noqa: PLC0415

    derived = diagnostics.derive()
    recorded = json.loads(CORPUS_DIAGNOSTICS.read_text(encoding="utf-8"))
    if recorded != derived:
        fail(
            "corpus_binding_diagnostics.json differs from the live proposal, "
            "database, or scoring sources"
        )
    counts = derived["counts"]
    if counts["proposals"] != corpus_total:
        fail(f"diagnostic proposal count is wrong: {counts}")
    if (
        counts["clean_proposals"] + counts["affected_union"]
        != counts["proposals"]
    ):
        fail(f"diagnostic union does not partition proposals: {counts}")
    defect_counts = {
        "score_tie": counts["score_ties"],
        "displacement": counts["displacements"],
        "fan_surplus": counts["fan_surplus"],
    }
    print(
        "binding defects recomputed: "
        f"score-ties={defect_counts['score_tie']}, "
        f"displacements={defect_counts['displacement']}, "
        f"fan-surplus={defect_counts['fan_surplus']}, "
        f"union={counts['affected_union']}, "
        f"clean={counts['clean_proposals']} PASS"
    )
    return defect_counts, counts["reviewable_signatures"]


def copy_runtime_inputs(tree: Path) -> None:
    paths = (
        "hermes/review_queue.pl",
        "data/research/grade78_pairing_proposals.jsonl",
        "data/research/corpus_binding_proposals.json",
        "data/research/corpus_binding_diagnostics.json",
        "curriculum/im/generated/field_context_cache.json",
        "knowledge/index/corpus_window.pl",
        "knowledge/index/index_query.pl",
        "knowledge/index/relevance_negation.pl",
    )
    for relative in paths:
        source = ROOT / relative
        target = tree / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)


def run_prolog(tree: Path, goal: str) -> dict[str, Any]:
    completed = subprocess.run(
        [
            "swipl",
            "--on-warning=status",
            "--on-error=status",
            "-q",
            "-g",
            goal,
            "-t",
            "halt",
        ],
        cwd=tree,
        capture_output=True,
        text=True,
        timeout=90,
    )
    if completed.returncode:
        fail(
            f"review queue Prolog failed ({completed.returncode}): "
            f"{completed.stderr[-1600:]}"
        )
    try:
        return json.loads(completed.stdout)
    except json.JSONDecodeError as exc:
        fail(f"review queue Prolog returned non-JSON: {completed.stdout[-1600:]}")
        raise exc


def queue_and_append_behavior(unit_total: int, signature_total: int) -> None:
    with tempfile.TemporaryDirectory(prefix="hermes-review-check-") as raw:
        tree = Path(raw)
        copy_runtime_inputs(tree)
        common = (
            "use_module(library(http/json)),"
            "asserta(user:file_search_path(index,'knowledge/index')),"
            "use_module('hermes/review_queue.pl'),"
        )
        first = run_prolog(
            tree,
            common
            + "review_queue:review_source_items(unit_recognition_set,UItems),"
            + "maplist([I,T]>>get_dict(item_type,I,T),UItems,UTypes),"
            + "review_queue:review_source_items(signature_anchor,SItems),"
            + "maplist([I,T]>>get_dict(item_type,I,T),SItems,STypes),"
            + "review_queue:review_queue_dict(unit_recognition_set,0,Q0),"
            + "get_dict(item,Q0,I0),get_dict(identity,I0,Id0),"
            + "put_dict(decision_detail,I0,"
            + '_{drop_machines:["ratio/example"],add_machines:[],'
            + 'lesson_exceptions:"IM-G7-U1-L1: retain as an exception"},Shown),'
            + "review_queue:review_decide_dict(unit_recognition_set,Id0,amend,"
            + '"structured exception check",Shown,D1),'
            + "review_queue:review_queue_dict(signature_anchor,0,SQ0),"
            + "get_dict(item,SQ0,SI0),get_dict(identity,SI0,SId0),"
            + "review_queue:review_decide_dict(signature_anchor,SId0,none,"
            + '"none check",SI0,SD1),'
            + "json_write_dict(current_output,"
            + "_{units:UItems,unit_types:UTypes,signatures:SItems,"
            + "signature_types:STypes,unit_queue:Q0,unit_decision:D1,"
            + "signature_queue:SQ0,signature_decision:SD1},[width(0)])",
        )

        units = first["units"]
        signatures = first["signatures"]
        if len(units) != unit_total:
            fail(f"unit queue total {len(units)} != live unit count {unit_total}")
        if len(signatures) != signature_total:
            fail(
                f"signature queue total {len(signatures)} "
                f"!= recomputed clean-signature count {signature_total}"
            )
        if set(first["unit_types"]) != {"unit_recognition_set"}:
            fail("unit queue contains a per-pairing or other item")
        if set(first["signature_types"]) != {"signature_anchor"}:
            fail("signature queue contains a per-row or other item")
        for item in units:
            if not item["proposed_machines"] or not item["lessons"]:
                fail(f"unit decision lacks its set evidence: {item['identity']}")
            for proposed in item["proposed_machines"]:
                if not proposed.get("machine_steps") or not proposed.get(
                    "motivated_by"
                ):
                    fail(f"unit machine lacks steps or motivations: {proposed}")
        for item in signatures:
            if not item.get("none_is_first_class"):
                fail(f"none is not first-class on {item['identity']}")
            if not item.get("machine_steps") or not item.get("candidates"):
                fail(f"signature decision lacks machine or candidates: {item}")
            if not any(c["mechanically_clear"] for c in item["candidates"]):
                fail(f"signature has no clear candidate after triage: {item}")

        if first["unit_decision"]["verdict"] != "amend":
            fail("unit amendment verdict was not recorded")
        if first["signature_decision"]["verdict"] != "none":
            fail("signature none verdict was not recorded")

        decision_lines = (
            tree / "data/research/review_decisions.jsonl"
        ).read_text(encoding="utf-8").splitlines()
        records = [json.loads(line) for line in decision_lines]
        if len(records) != 2:
            fail(f"append log has {len(records)} records instead of two")
        detail = records[0]["reviewer_text"].get("decision_detail", {})
        if not detail.get("lesson_exceptions"):
            fail("unit decision did not preserve its lesson exception")
        print(
            "queue behavior: aggregate unit and signature items only; "
            f"totals={len(units)}+{len(signatures)}; "
            "unit amendment and signature none append PASS"
        )


def full_text_and_route_metadata() -> None:
    common = (
        "use_module(library(http/json)),"
        "asserta(user:file_search_path(index,'knowledge/index')),"
        "use_module('hermes/review_queue.pl'),"
        "review_queue:review_source_items(signature_anchor,Items),"
        "member(Item,Items),"
        'get_dict(machine,Item,"addition/drop_carry_to_next_column"),!,'
        "json_write_dict(current_output,_{has_item:true,item:Item},[width(0)])"
    )
    result = run_prolog(ROOT, common)

    sys.path.insert(0, str(ROOT))
    from hermes.app.routes.logic import _enrich_review_citation  # noqa: PLC0415

    enriched = _enrich_review_citation(ROOT, result)
    candidates = enriched["item"]["candidates"]
    if not candidates:
        fail("known signature anchor has no candidates")
    for candidate in candidates:
        if not candidate.get("full_text"):
            fail(f"candidate has no full database row: {candidate}")
        if candidate["citation"] != "unattributed":
            article = candidate.get("citation_metadata") or {}
            if not article.get("authors") or not article.get("title"):
                fail(f"candidate lacks database citation metadata: {candidate}")
    known = next(
        (
            candidate
            for candidate in candidates
            if candidate["row_type"] == "misconception"
            and candidate["row_id"] == 46701
        ),
        None,
    )
    if known is None:
        fail("known truncated row 46701 is absent from its signature decision")
    if len(known["full_text"]) <= len(known["excerpt"]):
        fail(
            "served row 46701 is not longer than its proposal excerpt: "
            f"{len(known['full_text'])} <= {len(known['excerpt'])}"
        )
    print(
        "display evidence: full database row exceeds the 240-character proposal "
        "field; article metadata resolves for every candidate in the known item PASS"
    )


def write_confinement() -> None:
    code = REVIEW_MODULE.read_text(encoding="utf-8")
    if "repo_file('data/research/review_decisions.jsonl', DecisionsPath)" not in code:
        fail("review decision target is not the declared data/research path")
    append_calls = re.findall(
        r"open\(([^,\n]+),\s*(append|write|update)\s*,", code
    )
    if append_calls != [("DecisionsPath", "append")]:
        fail(f"unexpected write-mode open calls: {append_calls}")
    mutation_lines = [
        line
        for line in code.splitlines()
        if re.search(
            r"\b(open\([^,]+,\s*(?:append|write|update)|"
            r"delete_file|rename_file|make_directory|write_file)\b",
            line,
        )
    ]
    forbidden = [
        line
        for line in mutation_lines
        if "knowledge/" in line or "curriculum/" in line
    ]
    if forbidden:
        fail("write path reaches a held tree: " + " | ".join(forbidden))
    print(
        "write confinement: review decisions are the sole runtime write; "
        "knowledge/ and curriculum/ remain held PASS"
    )


def page_and_smoke() -> None:
    page = REVIEW_PAGE.read_text(encoding="utf-8")
    required = (
        'data-active="review"',
        "/api/review_queue",
        "/api/review_decide",
        'data-source="unit_recognition_set"',
        'data-source="signature_anchor"',
        '"accept-set"',
        '"reject-set"',
        '"amend"',
        '"none"',
        "None of these rows",
        "Full corpus row",
        "explicit_lesson_strategy/4",
        "score tie",
        "already-bound signature",
        "several signatures",
        "MathJax",
    )
    missing = [marker for marker in required if marker not in page]
    if missing:
        fail("review page is missing: " + ", ".join(missing))
    forbidden = (
        'data-source="lesson_pairings"',
        'data-source="corpus_bindings"',
        'data-verdict="accept"',
        'data-verdict="reject"',
        'data-verdict="unsure"',
    )
    present = [marker for marker in forbidden if marker in page]
    if present:
        fail("review page retains per-item controls: " + ", ".join(present))

    smoke = (ROOT / "scripts/bundle/smoke_bundle.py").read_text(encoding="utf-8")
    if smoke.count('"hermes/web/review.html"') < 2:
        fail("smoke bundle does not require and assert review.html")

    sys.path.insert(0, str(ROOT / "scripts/bundle"))
    from smoke_bundle import api_routes, page_url_for  # noqa: PLC0415

    routes = api_routes(ROOT)
    missing_routes = {
        "/api/review_queue",
        "/api/review_decide",
    } - routes
    if missing_routes:
        fail("review page API routes are absent: " + ", ".join(sorted(missing_routes)))
    if page_url_for("hermes/web/review.html") != "/more-zeeman/review.html":
        fail("smoke bundle does not map review.html to its public page URL")
    print(
        "review page: aggregate modes, mode-specific verdicts, full-row copy, "
        "score calibration, API routes, MathJax, and smoke assertion PASS"
    )


def main() -> int:
    try:
        unit_total, corpus_total = proposal_integrity()
        _defect_counts, signature_total = diagnostics_integrity(corpus_total)
        queue_and_append_behavior(unit_total, signature_total)
        full_text_and_route_metadata()
        write_confinement()
        page_and_smoke()
    except (AssertionError, OSError, subprocess.SubprocessError, sqlite3.Error) as exc:
        print(f"review surface: FAIL: {exc}", file=sys.stderr)
        return 1
    print("review surface: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
