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
SHELL_PATH = ROOT / "hermes" / "web" / "render" / "hermes-shell.js"
NAV_BLOCK_RE = re.compile(r"\bvar NAV = \[(.*?)\n  \];", re.DOTALL)
NAV_SECTION_RE = re.compile(
    r'\{ title: "([^"]+)", kind: "([^"]+)", base: "([^"]+)", items: \[(.*?)\]\s*\}',
    re.DOTALL,
)
NAV_ITEM_RE = re.compile(r'\["([^"]+)",\s*"([^"]+)",\s*([^\]]+?)\],')
EXPECTED_NAV = (
    ("explore", "Lessons", 'app("console.html#explore")'),
    ("lesson", "Lesson dossier", 'app("lesson")'),
    ("surfaces", "All pages", 'app("surfaces.html")'),
    ("discussions", "Discussions", 'app("discussions.html")'),
    ("sidekick", "Sidekick", 'app("sidekick.html")'),
    ("visualizations", "Math tools", 'mz("visualizations.html")'),
    ("landing", "Journey", 'mz("landing.html")'),
    ("research", "Research", 'mz("research.html")'),
)


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


def report_nav() -> int:
    source = SHELL_PATH.read_text(encoding="utf-8")
    block_match = NAV_BLOCK_RE.search(source)
    if not block_match:
        print("Hermes shell NAV block is missing")
        return 1
    sections = NAV_SECTION_RE.findall(block_match.group(1))
    if len(sections) != 1:
        print(f"Hermes shell NAV has {len(sections)} sections; expected one")
        return 1
    title, kind, base, item_source = sections[0]
    if (title, kind, base) != ("Hermes", "practice", "light"):
        print(
            "Hermes shell NAV section differs: "
            f"{(title, kind, base)!r}"
        )
        return 1
    items = tuple(
        (page_id, label, href.strip())
        for page_id, label, href in NAV_ITEM_RE.findall(item_source)
    )
    if items != EXPECTED_NAV:
        print("Hermes shell NAV entries differ")
        print("expected:", *EXPECTED_NAV, sep="\n")
        print("actual:", *items, sep="\n")
        return 1
    if 'brand.href = app("");' not in source:
        print("Hermes shell brand does not link to the app root")
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
    failed |= report_nav()
    if failed:
        return 1
    print(
        "PASS Hermes shell PAGE_CONTEXT: "
        f"{len(template_ids)} tagged template ids and {len(PAGE_CONTEXT)} context ids"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
