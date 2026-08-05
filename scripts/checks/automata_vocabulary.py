#!/usr/bin/env python3
"""Check the public vocabulary shared by the automata research pages."""
from __future__ import annotations

import re
import sys
from html.parser import HTMLParser
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DOCS = ROOT / "docs"
GLOSSARY = DOCS / "research/automata-vocabulary.html"
HUB = DOCS / "research/2026-08-03-automata-compendium.html"
GRAPH = DOCS / "research/automata-graph.html"
FAMILY_DIR = DOCS / "research/automata-compendium"
COMPOSITE_DIR = DOCS / "research/assets/automata"

REQUIRED_TERMS = {
    "automaton",
    "state",
    "formal state name",
    "code name",
    "plain-language state label",
    "start state",
    "accepting state",
    "transition",
    "local action",
    "canonical action",
    "borrow",
    "conserving",
    "deforming",
    "neutral",
    "runtime trace",
    "action sequence",
    "algorithm",
    "family",
    "kind",
    "domain scene",
    "family path composite",
    "path point",
    "recorded transition graph",
    "branching",
    "loop",
}


class DefinitionTerms(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.in_terms = False
        self.in_term = False
        self.current: list[str] = []
        self.terms: set[str] = set()

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag == "dl" and "terms" in dict(attrs).get("class", "").split():
            self.in_terms = True
        elif tag == "dt" and self.in_terms:
            self.in_term = True
            self.current = []

    def handle_data(self, data: str) -> None:
        if self.in_term:
            self.current.append(data)

    def handle_endtag(self, tag: str) -> None:
        if tag == "dt" and self.in_term:
            term = " ".join("".join(self.current).split()).lower()
            if term:
                self.terms.add(term)
            self.in_term = False
        elif tag == "dl" and self.in_terms:
            self.in_terms = False


def fail_if(condition: bool, message: str, failures: list[str]) -> None:
    if condition:
        failures.append(message)


def main() -> int:
    failures: list[str] = []
    if not GLOSSARY.exists():
        failures.append(f"missing glossary: {GLOSSARY.relative_to(ROOT)}")
        glossary = ""
        terms: set[str] = set()
    else:
        glossary = GLOSSARY.read_text(encoding="utf-8")
        parser = DefinitionTerms()
        parser.feed(glossary)
        terms = parser.terms
    for term in sorted(REQUIRED_TERMS - terms):
        failures.append(f"glossary lacks a definition for: {term}")
    for fragment in (
        "Machine</em> is an informal synonym",
        "asserts no equivalence between automata and no prerequisite order",
        "An automaton is an algorithm only when",
        "Most branching sites come from that provenance union",
        "Path points are not states of any single automaton",
    ):
        fail_if(fragment not in glossary, f"glossary lacks required ruling: {fragment}", failures)
    fail_if("MathJax" in glossary, "glossary loads or names MathJax", failures)
    fail_if(bool(re.search(r"https?://", glossary)), "glossary contains an external URL", failures)

    composites = sorted(COMPOSITE_DIR.glob("*/_composite.svg"))
    fail_if(len(composites) != 15, f"expected 15 composite SVGs, got {len(composites)}", failures)
    for path in composites:
        svg = path.read_text(encoding="utf-8")
        fail_if(bool(re.search(r">s\d+(?:<|\s)", svg)),
                f"composite has an s-numbered node label: {path.relative_to(ROOT)}", failures)
        fail_if(not bool(re.search(r">p\d+</text>", svg)),
                f"composite lacks p-numbered path points: {path.relative_to(ROOT)}", failures)
        for fragment in (
            "family path composite",
            "Path points are not states of any single automaton",
            "Loops are not unfolded",
        ):
            fail_if(fragment not in svg,
                    f"composite lacks accessible text {fragment!r}: {path.relative_to(ROOT)}",
                    failures)

    if not HUB.exists():
        failures.append(f"missing hub: {HUB.relative_to(ROOT)}")
    else:
        fail_if('href="automata-vocabulary.html"' not in HUB.read_text(encoding="utf-8"),
                "compendium hub lacks the glossary link", failures)
    family_pages = sorted(FAMILY_DIR.glob("*.html"))
    fail_if(len(family_pages) != 15, f"expected 15 family pages, got {len(family_pages)}", failures)
    for path in family_pages:
        fail_if('href="../automata-vocabulary.html"' not in path.read_text(encoding="utf-8"),
                f"family page lacks the glossary link: {path.relative_to(ROOT)}", failures)
    if not GRAPH.exists():
        failures.append(f"missing graph page: {GRAPH.relative_to(ROOT)}")
    else:
        graph = GRAPH.read_text(encoding="utf-8")
        fail_if('href="automata-vocabulary.html"' not in graph,
                "automata graph lacks the glossary link", failures)
        fail_if('href="automata-vocabulary.html#borrow"' not in graph,
                "automata graph lacks the borrow-definition pointer", failures)

    forbidden = b"branched-schedule"
    for path in sorted(item for item in DOCS.rglob("*") if item.is_file()):
        if forbidden in path.read_bytes():
            failures.append(f"forbidden string branched-schedule: {path.relative_to(ROOT)}")

    if failures:
        for failure in failures:
            print(failure, file=sys.stderr)
        return 1
    print(
        f"PASS automata vocabulary: {len(terms)} definitions, {len(composites)} composites, "
        f"the hub and {len(family_pages)} family pages link the glossary, and docs contains "
        "no branched-schedule string"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
