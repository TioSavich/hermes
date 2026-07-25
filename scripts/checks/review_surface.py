#!/usr/bin/env python3
"""Check the proposal review queue, append log, routes, and shipped page."""
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
    corpus_data = json.loads(CORPUS_PROPOSALS.read_text(encoding="utf-8"))
    corpus_rows = corpus_data.get("proposals")
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
    connection = sqlite3.connect(f"file:{RESEARCH_DB}?mode=ro", uri=True)
    connection.row_factory = sqlite3.Row
    try:
        articles = {
            row["bibtex_key"]: dict(row)
            for row in connection.execute(
                """
                SELECT bibtex_key, authors, year, title, journal, doi
                  FROM articles
                 WHERE bibtex_key IS NOT NULL
                """
            )
        }
    finally:
        connection.close()

    pairing_count = 0
    gap_count = 0
    lesson_ids: set[str] = set()
    for row in lesson_rows:
        lesson = row.get("lesson")
        if lesson not in contexts:
            fail(f"lesson proposal does not resolve in field context: {lesson}")
        pairings = row.get("pairings")
        if not isinstance(pairings, list):
            fail(f"lesson proposal has no pairings list: {lesson}")
        if not pairings and row.get("gap"):
            gap_count += 1
        for pairing in pairings:
            machine = pairing.get("machine")
            if machine not in machines:
                fail(f"lesson proposal machine does not resolve: {lesson} -> {machine}")
            identity = f"{lesson}:{machine}"
            if identity in lesson_ids:
                fail(f"duplicate lesson pairing identity: {identity}")
            lesson_ids.add(identity)
            pairing_count += 1

    sentinel_count = 0
    resolved_count = 0
    unresolved_count = 0
    corpus_ids: set[str] = set()
    for proposal in corpus_rows:
        machine = f"{proposal.get('family')}/{proposal.get('signature')}"
        if machine not in machines:
            fail(
                "corpus proposal machine does not resolve: "
                f"row {proposal.get('row_id')} -> {machine}"
            )
        citation = proposal.get("bibtex_key")
        if citation == "unattributed":
            sentinel_count += 1
        elif citation in articles:
            resolved_count += 1
            article = articles[citation]
            if not article.get("authors") or not article.get("title"):
                fail(
                    "resolved corpus article lacks reviewer metadata: "
                    f"row {proposal.get('row_id')} -> {citation}"
                )
        else:
            unresolved_count += 1
        identity = f"{proposal.get('row_id')}:{machine}"
        if identity in corpus_ids:
            fail(f"duplicate corpus binding identity: {identity}")
        corpus_ids.add(identity)

    expected = {
        "lesson rows": (len(lesson_rows), 271),
        "lesson pairings": (pairing_count, 733),
        "stated gaps": (gap_count, 9),
        "corpus bindings": (len(corpus_rows), 268),
        "resolved database citations": (resolved_count, 262),
        "unattributed sentinels": (sentinel_count, 6),
        "unresolved citations": (unresolved_count, 0),
    }
    wrong = [
        f"{label}: {actual} != {wanted}"
        for label, (actual, wanted) in expected.items()
        if actual != wanted
    ]
    if wrong:
        fail("; ".join(wrong))
    print(
        "proposal resolution: "
        f"{len(lesson_rows)} lessons, {pairing_count} pairings, "
        f"{gap_count} stated gaps, {len(corpus_rows)} corpus bindings PASS"
    )
    print(
        "citation resolution: "
        f"resolved-in-database={resolved_count}, sentinel={sentinel_count}, "
        f"unresolved-anywhere={unresolved_count} PASS"
    )
    return pairing_count + gap_count, len(corpus_rows)


def copy_runtime_inputs(tree: Path) -> None:
    paths = (
        "hermes/review_queue.pl",
        "data/research/grade78_pairing_proposals.jsonl",
        "data/research/corpus_binding_proposals.json",
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
            f"{completed.stderr[-1200:]}"
        )
    try:
        return json.loads(completed.stdout)
    except json.JSONDecodeError as exc:
        fail(f"review queue Prolog returned non-JSON: {completed.stdout[-1200:]}")
        raise exc


def queue_and_append_behavior(lesson_total: int, corpus_total: int) -> None:
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
            + "review_queue:review_source_items(lesson_pairings,LItems),"
            + "findall(LT,(member(LI,LItems),get_dict(ranking_tier,LI,LT)),LTiers),"
            + "msort(LTiers,LTiers),"
            + "review_queue:review_source_items(corpus_bindings,CItems),"
            + "findall(CT,(member(CI,CItems),get_dict(ranking_tier,CI,CT)),CTiers),"
            + "msort(CTiers,CTiers),"
            + "review_queue:review_queue_dict(lesson_pairings,0,Q0),"
            + "get_dict(item,Q0,I0),get_dict(identity,I0,Id0),"
            + "review_queue:review_decide_dict(lesson_pairings,Id0,unsure,"
            + '"first append check",I0,D1),'
            + "json_write_dict(current_output,_{queue:Q0,decision:D1},[width(0)])",
        )
        queue0 = first["queue"]
        decision1 = first["decision"]
        if queue0["progress"] != {
            "decided": 0,
            "remaining": lesson_total,
            "total": lesson_total,
        }:
            fail(f"unexpected initial lesson progress: {queue0['progress']}")
        if (
            queue0["item"]["item_type"] != "authoring_gap"
            or queue0["item"]["ranking_tier"] != 0
        ):
            fail("lesson queue does not start with a ranked authoring gap")
        if decision1["progress"]["decided"] != 1:
            fail("first decision did not move decided count to one")

        decisions_path = tree / "data/research/review_decisions.jsonl"
        after_first = decisions_path.read_text(encoding="utf-8").splitlines()
        if len(after_first) != 1:
            fail(f"first append produced {len(after_first)} decision lines")
        first_line = after_first[0]

        second = run_prolog(
            tree,
            common
            + "review_queue:review_queue_dict(lesson_pairings,0,Q1),"
            + "get_dict(item,Q1,I1),get_dict(identity,I1,Id1),"
            + "review_queue:review_decide_dict(lesson_pairings,Id1,accept,"
            + '"second append check",I1,D2),'
            + "review_queue:review_queue_dict(lesson_pairings,0,Q2),"
            + "review_queue:review_queue_dict(corpus_bindings,0,CQ),"
            + "json_write_dict(current_output,"
            + "_{before:Q1,decision:D2,after:Q2,corpus:CQ},[width(0)])",
        )
        before = second["before"]
        after = second["after"]
        if before["progress"]["decided"] != 1:
            fail("decided item remained in the lesson queue")
        if before["item"]["identity"] == queue0["item"]["identity"]:
            fail("the decided lesson item was returned again")
        if second["decision"]["progress"]["decided"] != 2:
            fail("second decision did not move decided count by exactly one")
        if after["progress"]["decided"] != 2:
            fail("queue progress did not retain both decisions")
        if second["corpus"]["progress"]["total"] != corpus_total:
            fail(f"unexpected corpus queue total: {second['corpus']['progress']}")
        if second["corpus"]["item"]["citation_status"] != "no_recorded_source":
            fail("corpus queue does not prioritize an unattributed proposal")

        final_lines = decisions_path.read_text(encoding="utf-8").splitlines()
        if len(final_lines) != 2:
            fail(f"second append produced {len(final_lines)} decision lines")
        if final_lines[0] != first_line:
            fail("the second append changed the first decision line")
        records = [json.loads(line) for line in final_lines]
        if records[0]["reviewer_text"] != queue0["item"]:
            fail("decision log did not preserve the reviewer-facing item")
        print(
            "queue behavior: ranked lesson and corpus queues; "
            "deciding removes one item and moves progress by one PASS"
        )
        print(
            "append behavior: two JSONL decisions; first line survived verbatim PASS"
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
        "write confinement: data/research/review_decisions.jsonl is the sole "
        "write target; knowledge/ and curriculum/ are held read-only PASS"
    )


def page_and_smoke() -> None:
    page = REVIEW_PAGE.read_text(encoding="utf-8")
    required = (
        'data-active="review"',
        "/api/review_queue",
        "/api/review_decide",
        'data-verdict="accept"',
        'data-verdict="reject"',
        'data-verdict="unsure"',
        "No recorded source",
        "citation_metadata",
        "article.authors",
        "article.year",
        "article.title",
        "changes no knowledge or",
        "MathJax",
    )
    missing = [marker for marker in required if marker not in page]
    if missing:
        fail("review page is missing: " + ", ".join(missing))

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
        "review page: shell, three equal verdict controls, API routes, "
        "database author/year/title fields, MathJax, and smoke-bundle assertion PASS"
    )


def route_citation_metadata() -> None:
    sys.path.insert(0, str(ROOT))
    from hermes.app.routes.logic import _enrich_review_citation  # noqa: PLC0415

    resolved = _enrich_review_citation(
        ROOT,
        {
            "has_item": True,
            "item": {
                "item_type": "corpus_binding",
                "citation": "ISI:000355686800006",
            },
        },
    )
    item = resolved["item"]
    if item["citation_status"] != "resolved_in_database":
        fail("API route did not mark a database citation resolved")
    article = item.get("citation_metadata") or {}
    if (
        article.get("authors") != "Tunc-Pekkan, Zelha"
        or article.get("year") != 2015
        or not str(article.get("title") or "").startswith("An analysis of")
    ):
        fail(f"API route returned the wrong database citation fields: {article}")

    sentinel = _enrich_review_citation(
        ROOT,
        {
            "has_item": True,
            "item": {
                "item_type": "corpus_binding",
                "citation": "unattributed",
            },
        },
    )
    if (
        sentinel["item"]["citation_status"] != "no_recorded_source"
        or sentinel["item"]["citation_metadata"] is not None
    ):
        fail("API route did not preserve the unattributed sentinel")

    try:
        _enrich_review_citation(
            ROOT,
            {
                "has_item": True,
                "item": {
                    "item_type": "corpus_binding",
                    "citation": "missing-review-citation",
                },
            },
        )
    except LookupError:
        pass
    else:
        fail("API route accepted a citation absent from articles")
    print(
        "route citation metadata: database author, year, and title attached; "
        "sentinel preserved; unresolved key refused PASS"
    )


def main() -> int:
    try:
        lesson_total, corpus_total = proposal_integrity()
        queue_and_append_behavior(lesson_total, corpus_total)
        write_confinement()
        route_citation_metadata()
        page_and_smoke()
    except (AssertionError, OSError, subprocess.SubprocessError) as exc:
        print(f"review surface: FAIL: {exc}", file=sys.stderr)
        return 1
    print("review surface: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
