#!/usr/bin/env python3
"""Pin numeric MCP description claims to the stores that supply them."""
from __future__ import annotations

import ast
import json
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SERVER = ROOT / "hermes/mcp/server.py"
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))


class CheckFailure(AssertionError):
    """A named MCP description-count failure."""


def fail(name: str, detail: str) -> None:
    raise CheckFailure(f"{name}: {detail}")


def descriptions() -> dict[str, str]:
    tree = ast.parse(SERVER.read_text(encoding="utf-8"), filename=str(SERVER))
    result: dict[str, str] = {}
    for node in tree.body:
        if not isinstance(node, ast.Assign):
            continue
        names = {target.id for target in node.targets if isinstance(target, ast.Name)}
        if not names.intersection({"CORE_TOOLS", "CORE_STANDALONE_TOOLS"}):
            continue
        for name, description, _parameters in ast.literal_eval(node.value):
            result[name] = description
    if not result:
        fail("description_parse", "CORE_TOOLS descriptions were not found")
    # guide_question_labels is the one store-counted description. MCP fills
    # its placeholders from the generated summary facts at registration time;
    # check the same registered text rather than the inert template literal.
    from hermes.mcp import server as mcp_server

    for name, description, _parameters in mcp_server.standalone_tool_rows(ROOT):
        if name == "guide_question_labels":
            result[name] = description
    return result


def match_claim(name: str, pattern: str, description: str) -> re.Match[str]:
    match = re.search(pattern, description, flags=re.DOTALL)
    if match is None:
        fail(name, "numeric claim is missing or no longer parseable")
    return match


def expect_equal(name: str, claimed: int | float, measured: int | float) -> None:
    if claimed != measured:
        fail(name, f"description claims {claimed}, source reports {measured}")


def check_deformation_chart(description: str) -> None:
    claim = match_claim(
        "lesson_deformation_chart",
        r"serves (?P<total>\d+) codes: (?P<hand_authored>\d+) hand-authored"
        r" fraction charts, (?P<evidence>\d+) evidence-joined fraction charts,"
        r" and (?P<division>\d+) compiled division chart.*?refuses"
        r" (?P<fraction_refusal>\d+) eligible codes with fraction_operands_unrecoverable"
        r" and (?P<host_refusal>\d+) with no_deformation_chart",
        description,
    )
    goal = (
        "use_module(library(http/json)),"
        "use_module(lessons('im/lesson_deformation_chart')),"
        "chart_provenance_census(Census),"
        "findall(Code,default_fill_lessons:default_fill_lesson(Code),Codes0),sort(Codes0,Codes),"
        "aggregate_all(count,(member(Code,Codes),chart_refusal(Code,fraction_operands_unrecoverable,_)),FractionRefusal),"
        "aggregate_all(count,(member(Code,Codes),chart_refusal(Code,no_deformation_chart,_)),HostRefusal),"
        "put_dict(_{fraction_refusal:FractionRefusal,host_refusal:HostRefusal},Census,Out),"
        "json_write_dict(current_output,Out),halt."
    )
    completed = subprocess.run(
        ["swipl", "-q", "-l", str(ROOT / "paths.pl"), "-g", goal],
        cwd=ROOT, text=True, capture_output=True, timeout=60, check=False,
    )
    if completed.returncode != 0:
        fail("lesson_deformation_chart.source", completed.stderr.strip())
    measured = json.loads(completed.stdout)
    for field in ("total", "hand_authored", "evidence", "division", "fraction_refusal", "host_refusal"):
        expect_equal(f"lesson_deformation_chart.{field}", int(claim[field]), int(measured[field]))


def check_pedagogical_questions(description: str) -> None:
    claim = match_claim(
        "pedagogical_questions",
        r"The (?P<clusters>\d+) clusters.*?\((?P<assessing>\d+) assessing questions,"
        r" (?P<advancing>\d+) advancing questions total\)",
        description,
    )
    clusters: list[dict[str, object]] = []
    for path in sorted((ROOT / "data/research_assets/research").glob(
        "*monitoring-chart-clusters.json"
    )):
        payload = json.loads(path.read_text(encoding="utf-8"))
        clusters.extend(payload["clusters"])
    measured = {
        "clusters": len(clusters),
        "assessing": sum(len(row["assessing_questions"]) for row in clusters),
        "advancing": sum(len(row["advancing_questions"]) for row in clusters),
    }
    for field, count in measured.items():
        expect_equal(f"pedagogical_questions.{field}", int(claim[field]), count)


def check_guide_question_labels(description: str) -> None:
    claim = match_claim(
        "guide_question_labels",
        r"(?P<admitted>[\d,]+) of (?P<candidates>[\d,]+) candidate rows are mechanically admitted\."
        r" Warrant provenance: (?P<author>[\d,]+) im_author_heading rows.*?;"
        r" (?P<printed>[\d,]+) printed_region rows",
        description,
    )
    from hermes.mcp import server as mcp_server

    measured = mcp_server.question_admission_counts(ROOT)
    expect_equal(
        "guide_question_labels.total_admitted",
        int(claim["admitted"].replace(",", "")),
        measured["total_admitted"],
    )
    expect_equal(
        "guide_question_labels.candidate_count",
        int(claim["candidates"].replace(",", "")),
        measured["candidate_count"],
    )
    expect_equal(
        "guide_question_labels.author_heading_admitted",
        int(claim["author"].replace(",", "")),
        measured["author_heading_admitted"],
    )
    expect_equal(
        "guide_question_labels.printed_region_admitted",
        int(claim["printed"].replace(",", "")),
        measured["printed_region_admitted"],
    )
    for phrase in ("im_author_heading", "printed_region"):
        if phrase not in description:
            fail("guide_question_labels.warrant", f"missing phrase {phrase!r}")
    lowered = description.lower()
    for forbidden in ("void", "student or moment", "fits a particular"):
        if forbidden in lowered:
            fail("guide_question_labels.copy", f"forbidden surface phrase {forbidden!r}")


def swipl_integer(name: str, goal: str) -> int:
    completed = subprocess.run(
        ["swipl", "-q", "-l", str(ROOT / "paths.pl"), "-g", goal],
        cwd=ROOT,
        text=True,
        capture_output=True,
        timeout=30,
        check=False,
    )
    if completed.returncode != 0:
        fail(name, completed.stderr.strip() or f"swipl exited {completed.returncode}")
    try:
        return int(completed.stdout.strip())
    except ValueError:
        fail(name, f"expected one integer from swipl, got {completed.stdout!r}")


def check_strategy_recognize(description: str) -> None:
    claim = match_claim(
        "strategy_recognize",
        r"to (?P<count>\d+) execution-observed strategy traces",
        description,
    )
    measured = swipl_integer(
        "strategy_recognize.source",
        "use_module(hermes(strategy_recognizer),[]),"
        "findall(Operation-Kind,strategy_recognizer:observed_strategy(Operation,Kind,_),Rows),"
        "sort(Rows,Unique),length(Unique,Count),write(Count),halt.",
    )
    expect_equal("strategy_recognize.count", int(claim["count"]), measured)


def check_incompatibility_contexts(description: str) -> None:
    claim = match_claim(
        "incompatibility_contexts",
        r"inventory has (?P<count>\d+) rows and no pagination",
        description,
    )
    payload = json.loads((
        ROOT / "formal/incompatibility/a_fortiori_context_nestings.json"
    ).read_text(encoding="utf-8"))
    expect_equal(
        "incompatibility_contexts.count",
        int(claim["count"]),
        len(payload["nestings"]),
    )


def check_arithmetic_demonstration(description: str) -> None:
    claim = match_claim(
        "lesson_arithmetic_demonstration",
        r"List the (?P<count>\w+) compiled IM-G1-U3-L17 addition tasks",
        description,
    )
    number_words = {"one": 1, "two": 2, "three": 3, "four": 4}
    count_text = claim["count"].lower()
    try:
        claimed = int(count_text)
    except ValueError:
        if count_text not in number_words:
            fail("lesson_arithmetic_demonstration", f"unsupported number word {count_text!r}")
        claimed = number_words[count_text]
    source = (
        ROOT / "curriculum/im/generated/compiled_task_instances.pl"
    ).read_text(encoding="utf-8")
    tasks = set(re.findall(
        r"compiled_lesson_task_instance\('IM-G1-U3-L17',\s*productive-add\((\d+),\s*(\d+)\)",
        source,
    ))
    expect_equal("lesson_arithmetic_demonstration.count", claimed, len(tasks))


def check_model_analysis_lookup(description: str) -> None:
    claim = match_claim(
        "model_analysis_lookup",
        r"the (?P<rows>\d+) stored model-authored analyses.*?source ledger holds"
        r" (?P<held>\d+) additional oracle_mismatched_held rows",
        description,
    )
    goal = (
        "use_module(library(http/json)),"
        "use_module(strategies('abstraction/model_analysis_pilot'),[]),"
        "model_analysis_pilot:model_analysis_summary("
        "summary(row_count(Rows),held_excluded(Held),by_tier(_),by_grade(_))),"
        "json_write_dict(current_output,_{rows:Rows,held:Held}),halt."
    )
    completed = subprocess.run(
        ["swipl", "-q", "-l", str(ROOT / "paths.pl"), "-g", goal],
        cwd=ROOT,
        text=True,
        capture_output=True,
        timeout=30,
        check=False,
    )
    if completed.returncode != 0:
        fail("model_analysis_lookup.source", completed.stderr.strip())
    measured = json.loads(completed.stdout)
    expect_equal("model_analysis_lookup.rows", int(claim["rows"]), int(measured["rows"]))
    expect_equal("model_analysis_lookup.held", int(claim["held"]), int(measured["held"]))


def check_prolog_query(description: str) -> None:
    claim = match_claim(
        "prolog_query",
        r"capped at (?P<solutions>\d+) solutions, and limited to (?P<seconds>\d+) seconds",
        description,
    )
    source = (ROOT / "hermes/prolog_query.pl").read_text(encoding="utf-8")
    solution = match_claim(
        "prolog_query.solution_source",
        r"HERMES_PROLOG_QUERY_SOLUTION_CAP',\s*integer,\s*(?P<value>\d+)",
        source,
    )
    timeout = match_claim(
        "prolog_query.timeout_source",
        r"HERMES_PROLOG_QUERY_TIMEOUT_SECONDS',\s*number,\s*(?P<value>\d+(?:\.\d+)?)",
        source,
    )
    expect_equal("prolog_query.solutions", int(claim["solutions"]), int(solution["value"]))
    expect_equal("prolog_query.seconds", int(claim["seconds"]), float(timeout["value"]))


def main() -> int:
    try:
        rows = descriptions()
        check_deformation_chart(rows["lesson_deformation_chart"])
        check_pedagogical_questions(rows["pedagogical_questions"])
        check_guide_question_labels(rows["guide_question_labels"])
        check_strategy_recognize(rows["strategy_recognize"])
        check_incompatibility_contexts(rows["incompatibility_contexts"])
        check_arithmetic_demonstration(rows["lesson_arithmetic_demonstration"])
        check_model_analysis_lookup(rows["model_analysis_lookup"])
        check_prolog_query(rows["prolog_query"])
    except (CheckFailure, KeyError, OSError, json.JSONDecodeError, subprocess.TimeoutExpired) as exc:
        print(f"FAIL mcp_description_counts: {exc}", file=sys.stderr)
        return 1
    print("PASS MCP description counts match their live stores and limits")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
