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
        r"of the (?P<total>\d+) lesson codes.*?, (?P<guide>\d+) take their hosts"
        r".*?\(all (?P<hand_authored>\d+) report provenance hand_authored\);"
        r" the other (?P<default_fill>\d+) take one fixed default set",
        description,
    )
    chart_source = (
        ROOT / "curriculum/im/lesson_deformation_chart.pl"
    ).read_text(encoding="utf-8")
    default_source = (
        ROOT / "curriculum/im/generated/default_fill_lessons.pl"
    ).read_text(encoding="utf-8")
    guide_codes = set(re.findall(
        r"^hand_authored_chart_lesson\('([^']+)'",
        chart_source,
        flags=re.MULTILINE,
    ))
    division_codes = set(re.findall(
        r"^division_chart_lesson\('([^']+)'\)\.",
        chart_source,
        flags=re.MULTILINE,
    ))
    generated_codes = set(re.findall(
        r"^default_fill_lesson\('([^']+)'\)\.",
        default_source,
        flags=re.MULTILINE,
    ))
    default_codes = generated_codes - guide_codes
    hand_authored_codes = guide_codes | division_codes
    all_codes = hand_authored_codes | default_codes
    expect_equal("lesson_deformation_chart.total", int(claim["total"]), len(all_codes))
    expect_equal("lesson_deformation_chart.guide", int(claim["guide"]), len(guide_codes))
    expect_equal(
        "lesson_deformation_chart.hand_authored",
        int(claim["hand_authored"]),
        len(hand_authored_codes),
    )
    expect_equal(
        "lesson_deformation_chart.default_fill",
        int(claim["default_fill"]),
        len(default_codes),
    )


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
        check_strategy_recognize(rows["strategy_recognize"])
        check_incompatibility_contexts(rows["incompatibility_contexts"])
        check_arithmetic_demonstration(rows["lesson_arithmetic_demonstration"])
        check_prolog_query(rows["prolog_query"])
    except (CheckFailure, KeyError, OSError, json.JSONDecodeError, subprocess.TimeoutExpired) as exc:
        print(f"FAIL mcp_description_counts: {exc}", file=sys.stderr)
        return 1
    print("PASS MCP description counts match their live stores and limits")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
