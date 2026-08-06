#!/usr/bin/env python3
"""Keep shell page ids and /api/help grounding in exact agreement.

The shell tag is the page's declared identity for both navigation and the
live-help request.  A tag without PAGE_CONTEXT makes the help control fail at
runtime; a context without a tag is grounding for no shipped shell page.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from hermes.app.help_grounding import PAGE_CONTEXT, assemble_help_context


TEMPLATE_ROOTS = (
    ROOT / "hermes" / "app" / "web",
    ROOT / "hermes" / "web",
    ROOT / "formal" / "learner",
)
ACTIVE_RE = re.compile(r"\bdata-active\s*=\s*([\"'])([^\"']+)\1")


def template_active_ids() -> dict[str, list[Path]]:
    found: dict[str, list[Path]] = {}
    for template_root in TEMPLATE_ROOTS:
        for path in template_root.rglob("*.html"):
            for _quote, page_id in ACTIVE_RE.findall(path.read_text(encoding="utf-8")):
                found.setdefault(page_id, []).append(path.relative_to(ROOT))
    return found


def report_orphans(template_ids: set[str], context_ids: set[str]) -> int:
    missing_context = sorted(template_ids - context_ids)
    missing_template = sorted(context_ids - template_ids)
    if missing_context:
        print("shell ids without PAGE_CONTEXT: " + ", ".join(missing_context))
    if missing_template:
        print("PAGE_CONTEXT ids without a shell template: " + ", ".join(missing_template))
    return int(bool(missing_context or missing_template))


def report_strategy_machine_backing() -> int:
    context = assemble_help_context(ROOT, "strategy-machine")
    required = (
        "PAGE-SPECIFIC BACKING",
        "MACHINE PAGE",
        "selects one automaton by family and kind",
        "GLOSSARY EXCERPT (docs/research/automata-vocabulary.html)",
        "- automaton: One registered state-and-transition structure for one family and kind.",
        "- state: One node in one automaton.",
        "- transition: One directed move from a source state to a target state, labeled by a local action.",
        "- local action: The action name authored on one transition.",
        "- canonical action: A normalized action name used to compare local actions across automata.",
        "- kind: The registered subtype within a family.",
        "- runtime trace: The ordered steps returned by one runner invocation.",
    )
    missing = [text for text in required if text not in context]
    if missing:
        print("strategy-machine context missing backing: " + ", ".join(missing))
        return 1
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--synthetic-orphan",
        action="store_true",
        help="add an ungrounded template id to demonstrate that the check fails",
    )
    args = parser.parse_args()
    active = template_active_ids()
    template_ids = set(active)
    if args.synthetic_orphan:
        template_ids.add("synthetic-orphan")
    failed = report_orphans(template_ids, set(PAGE_CONTEXT))
    failed |= report_strategy_machine_backing()
    if failed:
        return 1
    print(
        "PASS Hermes shell PAGE_CONTEXT: "
        f"{len(template_ids)} tagged template ids and {len(PAGE_CONTEXT)} context ids"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
