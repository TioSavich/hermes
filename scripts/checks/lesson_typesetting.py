#!/usr/bin/env python3
"""Focused contract for display-only lesson typesetting and training culling."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[2]
TYPESETTER = ROOT / "hermes/web/render/lesson-typesetting.js"
PAGE = ROOT / "hermes/web/monitoring_chart.html"
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "scripts/sidekick"))

from hermes.app.routes.monitoring import resolve_lesson_visual  # noqa: E402
from training_text import cull_display_math_markers  # noqa: E402


def run_node(source: str, value: str) -> str:
    completed = subprocess.run(
        ["node", "-e", source],
        cwd=ROOT,
        input=json.dumps(value),
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode:
        raise AssertionError(completed.stderr.strip() or completed.stdout.strip())
    return completed.stdout.rstrip("\n")


def lesson_prompt() -> str:
    goal = (
        "load_runtime,"
        "lesson_monitoring:lesson_guide_context_dict('IM-G1-U3-L17',D),"
        "get_dict(activity_prompt,D,Ps),nth1(2,Ps,P),get_dict(text,P,T),"
        "json_write_dict(current_output,_{text:T}),nl,halt"
    )
    completed = subprocess.run(
        ["swipl", "-q", "-l", "paths.pl", "-l", "hermes_worker.pl", "-g", goal],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
        timeout=30,
    )
    if completed.returncode:
        raise AssertionError(completed.stderr.strip() or completed.stdout.strip())
    return json.loads(completed.stdout)["text"]


def check_normalizer() -> str:
    raw = lesson_prompt()
    assert "• Pick a number card and add that many\ncounters." in raw
    program = """
const fs = require('fs');
const t = require('./hermes/web/render/lesson-typesetting.js');
const value = JSON.parse(fs.readFileSync(0, 'utf8'));
process.stdout.write(t.normalizedText(value));
"""
    rendered = run_node(program, raw)
    assert "• Pick a number card and add that many counters." in rendered
    assert "\n• Write an equation" in rendered
    assert "add that many\ncounters" not in rendered

    scar_fixture = "Find each value. • 7 + 1 • 9- 1\n◦ Explain your thinking."
    fixture = run_node(program, scar_fixture)
    assert fixture == (
        "Find each value.\n\n"
        "• $7 + 1$\n"
        "• $9 - 1$\n"
        "  ◦ Explain your thinking."
    )
    return rendered


def check_training_cull() -> None:
    value = {
        "messages": [
            {"content": "Compare $9 - 1$ with $7 + 1$."},
            {"content": "A ticket costs $5."},
        ]
    }
    culled = cull_display_math_markers(value)
    assert culled["messages"][0]["content"] == "Compare 9 - 1 with 7 + 1."
    assert culled["messages"][1]["content"] == "A ticket costs $5."


def check_page_contract() -> None:
    source = PAGE.read_text(encoding="utf-8")
    assert "https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-svg.js" in source
    assert 'src="render/lesson-typesetting.js"' in source
    assert "renderDisplayTaskInstances(displayTasks)" in source
    assert "blocked_missing_visual:" in source
    assert "/api/lesson_visual?asset=" in source
    assert "HermesLessonTypesetting.typeset(el('lesson-task'))" in source


def check_visual_containment() -> None:
    allowed = "curriculum/im_teacher_guides/grade8/unit1/lesson1/source.png"
    with mock.patch.object(Path, "is_file", return_value=True):
        resolved = resolve_lesson_visual(ROOT, allowed)
    assert resolved == (ROOT / allowed).resolve()
    assert resolve_lesson_visual(ROOT, "../../.env") is None
    assert resolve_lesson_visual(ROOT, "hermes/app/runtime/student-data/roster.png") is None
    assert resolve_lesson_visual(ROOT, "curriculum/im_teacher_guides/grade8/unit1/lesson1/source.pdf") is None


def main() -> int:
    rendered = check_normalizer()
    check_training_cull()
    check_page_contract()
    check_visual_containment()
    assert TYPESETTER.is_file()
    print(
        "PASS lesson typesetting: verbatim G1 prompt normalized at display time; "
        "bullets, welded subtraction, MathJax markers, visual containment, and "
        f"training cull verified ({len(rendered)} display characters)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
