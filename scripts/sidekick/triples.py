#!/usr/bin/env python3
"""Executed (op, args, result) triples: the half of a training row that is true.

Generation runs backward. A triple is correct because the worker produced it,
not because anything judged it, so the only remaining question for a row is
whether its narrative warrants the call — which is what the teacher model is
for and what the framing gate polices.

Three rules govern what may become a triple:

- **Held-out tools never appear.** Seven of the 28 core tools are reserved for
  the generality suite, so a triple naming one is not built at all.
- **Payloads are capped.** A result over the cap is retried with narrower
  arguments before the triple is abandoned. Asking narrowly is the skill being
  trained, so the cap improves the data rather than merely shrinking it.
- **Every triple carries its own provenance**, naming the Hermes store it came
  from, so the firewall has something to check.
"""
from __future__ import annotations

import json
import random
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable, Iterator

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
for candidate in (str(REPO_ROOT), str(SCRIPT_DIR)):
    if candidate not in sys.path:
        sys.path.insert(0, candidate)

from chat_format import GemmaChatFormat  # noqa: E402
from dataset import Call, execute, now, worker_sha  # noqa: E402
from hermes.mcp.server import HermesMCPServer  # noqa: E402

# Reserved for the generality suite (design §4.2 plus the amendment's
# prolog_query). A training row may not name one.
HELD_OUT_TOOLS = frozenset({
    "graph_quotient",
    "deontic_up_level",
    "incompatibility_contexts",
    "resonance_neighbors",
    "lesson_deformation_chart_detail",
    "abduce_error",
    "prolog_query",
})

PAYLOAD_CAP_TOKENS = 1200
CONTRACTS = "knowledge/strategies/automaton_input_contracts.pl"
GRAPH = "docs/research/assets/automata/full_graph.json"
RECOGNIZER = "hermes/strategy_recognizer.pl"


@dataclass
class Triple:
    """One executed call, with what it is for and where it came from."""

    id: str
    row_class: str
    sub_kind: str
    calls: list[Call]
    subject: str
    provenance: dict[str, Any]
    narrative_seed: dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "class": self.row_class,
            "sub_kind": self.sub_kind,
            "calls": [call.to_dict() for call in self.calls],
            "subject": self.subject,
            "provenance": self.provenance,
            "narrative_seed": self.narrative_seed,
        }

    @classmethod
    def from_dict(cls, body: dict[str, Any]) -> "Triple":
        return cls(
            id=body["id"],
            row_class=body["class"],
            sub_kind=body["sub_kind"],
            calls=[Call(**call) for call in body["calls"]],
            subject=body["subject"],
            provenance=body["provenance"],
            narrative_seed=body.get("narrative_seed", {}),
        )


def words(name: str) -> str:
    return name.replace("_", " ")


FRACTION_WORDS = {
    2: "half", 3: "third", 4: "quarter", 5: "fifth", 6: "sixth", 7: "seventh",
    8: "eighth", 9: "ninth", 10: "tenth", 12: "twelfth", 16: "sixteenth",
}
NUMBER_WORDS = {
    1: "one", 2: "two", 3: "three", 4: "four", 5: "five", 6: "six", 7: "seven",
    8: "eight", 9: "nine", 10: "ten", 11: "eleven", 12: "twelve",
}


def say_fraction(numerator: int, denominator: int) -> str:
    """Ordinary classroom words, never the tool's serialization."""
    unit = FRACTION_WORDS.get(denominator, f"{denominator}th")
    count = NUMBER_WORDS.get(numerator, str(numerator))
    if numerator == 1:
        return f"one {unit}"
    return f"{count} {unit}s"


class TripleBank:
    def __init__(self, server: HermesMCPServer, chat: GemmaChatFormat, seed: int) -> None:
        self.server = server
        self.chat = chat
        self.rng = random.Random(seed)
        self.sha = worker_sha()
        self.counter = 0
        self.dropped: dict[str, int] = {}
        self.capped = 0

    def drop(self, reason: str) -> None:
        self.dropped[reason] = self.dropped.get(reason, 0) + 1

    def identity(self, row_class: str) -> str:
        self.counter += 1
        return f"t-{row_class}-{self.counter:05d}"

    def provenance(self, source: str, row: str, **extra: Any) -> dict[str, Any]:
        return {"source": source, "row": row, "executed_at": now(), "worker_sha": self.sha, **extra}

    def run(self, name: str, arguments: dict[str, Any]) -> Call | None:
        """Execute one call, capping its payload or giving the triple up."""
        if name in HELD_OUT_TOOLS:
            self.drop(f"{name} is held out")
            return None
        response, response_class = execute(
            self.server, Call(name=name, arguments=dict(arguments), response={}, response_class="result")
        )
        call = Call(name, dict(arguments), response, response_class)
        size = self.chat.count(json.dumps(response, ensure_ascii=False, sort_keys=True))
        if size <= PAYLOAD_CAP_TOKENS:
            return call
        narrowed = self.narrow(name, arguments)
        if narrowed is None:
            self.drop(f"{name} payload over cap and cannot be narrowed")
            return None
        response, response_class = execute(
            self.server, Call(name=name, arguments=dict(narrowed), response={}, response_class="result")
        )
        size = self.chat.count(json.dumps(response, ensure_ascii=False, sort_keys=True))
        if size > PAYLOAD_CAP_TOKENS:
            self.drop(f"{name} payload over cap after narrowing")
            return None
        self.capped += 1
        return Call(name, dict(narrowed), response, response_class)

    @staticmethod
    def narrow(name: str, arguments: dict[str, Any]) -> dict[str, Any] | None:
        """Ask the same question in a smaller way, where the tool allows it."""
        tightened = dict(arguments)
        if name in {"misconception_lookup", "list_strategies"}:
            tightened["limit"] = 3
            return tightened
        if name == "misconception_search_rows":
            tightened["k"] = 2
            return tightened
        if name == "graph_borrows":
            tightened["limit"] = 3
            return tightened
        return None

    # ------------------------------------------------------------- class A

    def strategy_traces(self, wanted: int) -> Iterator[Triple]:
        contracts = [row for row in self.server._strategy_contracts if row["example"]]
        self.rng.shuffle(contracts)
        made = 0
        for contract in contracts:
            if made >= wanted:
                return
            call = self.run("strategy_trace", {"strategy": contract["name"], "input": contract["example"]})
            if call is None or call.response_class != "result":
                continue
            example = contract["example"]
            operands = (
                f"{example['a']} and {example['b']}" if {"a", "b"} <= set(example) else ""
            )
            yield Triple(
                id=self.identity("A"),
                row_class="A",
                sub_kind="trace",
                calls=[call],
                subject=f"running the {words(contract['name'])} method on {operands or 'its worked input'}",
                provenance=self.provenance(CONTRACTS, contract["source"], strategy=contract["name"]),
                narrative_seed={"method": words(contract["name"]), "operands": operands,
                                "operation": contract["operation"]},
            )
            made += 1

    def diagnoses(self, wanted: int) -> Iterator[Triple]:
        """Exemplar-bound rows: the registry's own recorded input and wrong answer."""
        rows = self.registry_exemplars()
        self.rng.shuffle(rows)
        made = 0
        for domain, text, wrong, spoken in rows:
            if made >= wanted:
                return
            call = self.run("diagnose_error", {"domain": domain, "input": text, "got": wrong})
            if call is None or call.response_class != "result":
                continue
            yield Triple(
                id=self.identity("A"),
                row_class="A",
                sub_kind="diagnose",
                calls=[call],
                subject=f"a student writing {spoken}",
                provenance=self.provenance("misconception registry exemplars", f"{domain}:{text}"),
                narrative_seed={"student_wrote": spoken, "domain": domain},
            )
            made += 1

    def registry_exemplars(self) -> list[tuple[str, str, str, str]]:
        """Read (domain, input, wrong answer) straight from the knowledge store."""
        import re

        pattern = re.compile(
            r"^test_harness:arith_misconception\(([^,]+), ([a-z_]+), ([a-z0-9_]+),\s*$"
        )
        found: list[tuple[str, str, str, str]] = []
        for path in sorted((REPO_ROOT / "knowledge" / "misconceptions").glob("misconceptions_*.pl")):
            lines = path.read_text(encoding="utf-8").splitlines()
            for index, line in enumerate(lines):
                match = pattern.match(line)
                if not match or index + 3 >= len(lines):
                    continue
                domain = match.group(2)
                term = lines[index + 2].strip().rstrip(",")
                wrong = self.rule_output(domain, term)
                if wrong is None:
                    continue
                found.append((domain, term, wrong, self.speak(term, wrong)))
        return found

    def rule_output(self, domain: str, term: str) -> str | None:
        """Find the answer the recorded rule builds, by asking the checker."""
        import re

        match = re.match(r"^frac\((\d+),(\d+)\)-frac\((\d+),(\d+)\)$", term)
        if not match:
            return None
        a, b, c, d = (int(part) for part in match.groups())
        for candidate in (
            f"frac({a},{b + d})", f"frac({a + c},{b + d})", f"frac({a * c},{b * d})",
            f"frac({a + c},{b})", f"frac({a * d + c * b},{b * d})",
        ):
            probe = self.server.call("diagnose_error", {"domain": domain, "input": term, "got": candidate})
            if probe:
                return candidate
        return None

    @staticmethod
    def speak(term: str, wrong: str) -> str:
        import re

        left = re.match(r"^frac\((\d+),(\d+)\)-frac\((\d+),(\d+)\)$", term)
        right = re.match(r"^frac\((\d+),(\d+)\)$", wrong)
        if not left or not right:
            return f"{term} as {wrong}"
        a, b, c, d = (int(part) for part in left.groups())
        e, f = (int(part) for part in right.groups())
        return (
            f"{say_fraction(a, b)} and {say_fraction(c, d)} as {say_fraction(e, f)}"
        )

    def charts(self, wanted: int) -> Iterator[Triple]:
        codes = self.lesson_codes()
        self.rng.shuffle(codes)
        made = 0
        for code in codes:
            if made >= wanted:
                return
            call = self.run("monitoring_chart", {"code": code})
            if call is None or call.response_class != "result":
                continue
            names = [words(name) for name in call.response["result"].get("strategy_names", [])]
            yield Triple(
                id=self.identity("A"),
                row_class="A",
                sub_kind="chart",
                calls=[call],
                subject=f"planning lesson {code}",
                provenance=self.provenance("lesson corpus", code),
                narrative_seed={"lesson": code, "anticipated": names[:4]},
            )
            made += 1

    def searches(self, wanted: int) -> Iterator[Triple]:
        topics = [
            "fraction", "decimal", "measurement", "place value", "subtraction",
            "multiplication", "division", "percent", "integer", "ratio",
            "fraction comparison", "unit fraction", "equal share", "area",
            "perimeter", "rounding", "estimation", "counting", "number line",
            "equivalence", "remainder", "regrouping", "borrowing", "carrying",
        ]
        made = 0
        for topic in topics:
            if made >= wanted:
                return
            call = self.run("misconception_search_rows", {"query": topic, "k": 3})
            if call is None or call.response_class != "result":
                continue
            found = [words(row["name"]) for row in call.response["result"]["rows"]]
            yield Triple(
                id=self.identity("A"),
                row_class="A",
                sub_kind="search",
                calls=[call],
                subject=f"what is recorded about {topic} errors",
                provenance=self.provenance("misconception row store", f"query:{topic}"),
                narrative_seed={"topic": topic, "found": found},
            )
            made += 1

    def lookups(self, wanted: int) -> Iterator[Triple]:
        domains = ["fraction", "decimal", "measurement", "integer", "percent",
                   "combinatorial", "discrete", "probability"]
        made = 0
        for domain in domains:
            for offset in (0, 3, 6, 9):
                if made >= wanted:
                    return
                call = self.run("misconception_lookup", {"domain": domain, "limit": 2, "offset": offset})
                if call is None or call.response_class != "result":
                    continue
                described = [words(row["description"]) for row in call.response["result"]["rows"]]
                if not described:
                    continue
                yield Triple(
                    id=self.identity("A"),
                    row_class="A",
                    sub_kind="lookup",
                    calls=[call],
                    subject=f"recorded {domain} errors",
                    provenance=self.provenance("misconception registry", f"{domain}:{offset}"),
                    narrative_seed={"domain": domain, "described": described},
                )
                made += 1

    def machines(self, wanted: int) -> Iterator[Triple]:
        pairs = self.graph_machines()
        self.rng.shuffle(pairs)
        made = 0
        for family, kind in pairs:
            if made >= wanted:
                return
            call = self.run("graph_machine", {"family": family, "kind": kind})
            if call is None or call.response_class != "result":
                continue
            result = call.response["result"]
            yield Triple(
                id=self.identity("A"),
                row_class="A",
                sub_kind="machine",
                calls=[call],
                subject=f"the {words(kind)} machine in the {family} family",
                provenance=self.provenance(GRAPH, f"{family}/{kind}"),
                narrative_seed={"family": family, "kind": words(kind),
                                "states": len(result.get("states", [])),
                                "edges": len(result.get("edges", []))},
            )
            made += 1

    def claims(self, wanted: int) -> Iterator[Triple]:
        made = 0
        seen: set[str] = set()
        while made < wanted:
            a, b = self.rng.randint(2, 12), self.rng.randint(2, 12)
            style = self.rng.choice(["sum", "product", "compare"])
            if style == "sum":
                stated = a + b + self.rng.choice([0, 0, 1, -1, 10])
                term = f"{a}+{b}={stated}"
                spoken = f"{NUMBER_WORDS.get(a, a)} plus {NUMBER_WORDS.get(b, b)} makes {stated}"
            elif style == "product":
                stated = a * b + self.rng.choice([0, 0, 1, -2])
                term = f"{a}*{b}={stated}"
                spoken = f"{NUMBER_WORDS.get(a, a)} times {NUMBER_WORDS.get(b, b)} is {stated}"
            else:
                c, d = self.rng.randint(1, 6), self.rng.randint(2, 9)
                term = f"{c}/{d} > {d - c}/{d}"
                spoken = f"{say_fraction(c, d)} is more than {say_fraction(max(d - c, 1), d)}"
            if term in seen:
                continue
            seen.add(term)
            call = self.run("check_math_claim", {"term": term})
            if call is None or call.response_class != "result":
                continue
            yield Triple(
                id=self.identity("A"),
                row_class="A",
                sub_kind="claim",
                calls=[call],
                subject=f"whether {spoken}",
                provenance=self.provenance("generated claim over the reader's registered forms", term),
                narrative_seed={"claim_spoken": spoken},
            )
            made += 1

    def singletons(self, wanted: int) -> Iterator[Triple]:
        """The zero-argument surfaces, and the operations menu."""
        made = 0
        options: list[tuple[str, dict[str, Any], str]] = [
            ("lesson_enactment_list", {}, "which lessons can run end to end"),
            ("graph_overview", {}, "how much the machine catalog holds"),
        ]
        for operation in ("addition", "subtraction", "multiplication", "division",
                          "fraction", "measurement", "counting", "decimal", "integer",
                          "ratio", "statistics", "geometry", "probability", "algebraic"):
            options.append(("list_strategies", {"operation": operation, "limit": 8},
                            f"which {operation} methods exist"))
        for name, arguments, subject in options:
            if made >= wanted:
                return
            call = self.run(name, arguments)
            if call is None or call.response_class != "result":
                continue
            yield Triple(
                id=self.identity("A"),
                row_class="A",
                sub_kind="inventory",
                calls=[call],
                subject=subject,
                provenance=self.provenance("worker inventory", f"{name}:{json.dumps(arguments, sort_keys=True)}"),
                narrative_seed={"subject": subject},
            )
            made += 1

    def recognition_candidates(self) -> list[tuple[dict[str, Any], str, str]]:
        """Build controlled candidates, leaving admission to live execution.

        `generate_strategy_variant/4` in the recognizer obtains its canonical
        variant from these same execution-observed action labels. Rebuilding
        that bounded form from the returned trace avoids a private Prolog call:
        the only admitted training call is still the public core operation.
        """
        candidates: list[tuple[dict[str, Any], str, str]] = []
        contracts = [row for row in self.server._strategy_contracts if row["example"]]
        for contract in contracts:
            trace = self.run(
                "strategy_trace", {"strategy": contract["name"], "input": contract["example"]}
            )
            if trace is None or trace.response_class != "result":
                continue
            local_actions: list[str] = []
            for step in trace.response.get("result", {}).get("steps", []):
                label = str(step.get("label", ""))
                local = label.split("(", 1)[0]
                if local:
                    local_actions.append(local)
            if len(local_actions) < 2:
                continue
            rendered = [words(action) for action in local_actions]
            variants = (
                ". ".join(rendered) + ".",
                "First I " + ". Then I ".join(rendered) + ".",
                "The student said, I " + "; then I ".join(rendered) + ".",
            )
            for content in variants:
                candidates.append((contract, content, contract["source"]))
        self.rng.shuffle(candidates)
        return candidates

    def recognitions(self, wanted: int) -> Iterator[Triple]:
        """A-recognize: keep only candidate phrasings the live worker reaches."""
        made = 0
        for contract, content, source in self.recognition_candidates():
            if made >= wanted:
                return
            call = self.run("strategy_recognize", {"content": content})
            if call is None or call.response_class != "result":
                continue
            yield Triple(
                id=self.identity("A"), row_class="A", sub_kind="recognize",
                calls=[call], subject=f"a student explaining {content!r}",
                provenance=self.provenance(
                    RECOGNIZER, source, harvest="worker_result_required",
                    source_strategy=contract["name"],
                ),
                narrative_seed={"student_said": content},
            )
            made += 1

    # ------------------------------------------------------------- class B

    def discovery_chains(self, wanted: int) -> Iterator[Triple]:
        contracts = {row["name"]: row for row in self.server._strategy_contracts}
        operations = ["fraction", "subtraction", "addition", "division", "multiplication",
                      "measurement", "counting", "decimal", "integer", "ratio",
                      "statistics", "geometry", "probability", "algebraic"]
        made = 0
        for operation in operations:
            first = self.run("list_strategies", {"operation": operation, "limit": 8})
            if first is None or first.response_class != "result":
                continue
            names = [row["name"] for row in first.response["result"]["strategies"]]
            self.rng.shuffle(names)
            for chosen in names:
                if made >= wanted:
                    return
                contract = contracts.get(chosen)
                if not contract or not contract["example"]:
                    continue
                second = self.run("strategy_trace", {"strategy": chosen, "input": contract["example"]})
                if second is None or second.response_class != "result":
                    continue
                yield Triple(
                    id=self.identity("B"),
                    row_class="B",
                    sub_kind="discover_then_trace",
                    calls=[first, second],
                    subject=f"which {operation} methods exist, then running {words(chosen)}",
                    provenance=self.provenance(CONTRACTS, chosen, chain="list_strategies then strategy_trace"),
                    narrative_seed={"operation": operation, "method": words(chosen)},
                )
                made += 1

    def lookup_chains(self, wanted: int) -> Iterator[Triple]:
        topics = ["fraction", "decimal", "measurement", "place value", "ratio",
                  "percent", "integer", "subtraction", "division", "area"]
        made = 0
        for topic in topics:
            first = self.run("misconception_search_rows", {"query": topic, "k": 3})
            if first is None or first.response_class != "result":
                continue
            for row in first.response["result"]["rows"]:
                if made >= wanted:
                    return
                second = self.run("misconception_lookup", {"source": row["db_row"], "limit": 1})
                if second is None or second.response_class != "result":
                    continue
                yield Triple(
                    id=self.identity("B"),
                    row_class="B",
                    sub_kind="search_then_lookup",
                    calls=[first, second],
                    subject=f"the recorded {topic} error and what its record says",
                    provenance=self.provenance("misconception row store", row["db_row"],
                                               chain="search then lookup"),
                    narrative_seed={"topic": topic, "name": words(row["name"])},
                )
                made += 1

    def chart_chains(self, wanted: int) -> Iterator[Triple]:
        codes = self.lesson_codes()
        self.rng.shuffle(codes)
        made = 0
        for code in codes:
            first = self.run("monitoring_chart", {"code": code})
            if first is None or first.response_class != "result":
                continue
            sections = first.response["result"].get("sections", [])
            for section in sections[:2]:
                if made >= wanted:
                    return
                label = section.get("name") if isinstance(section, dict) else section
                second = self.run("monitoring_chart_detail", {"code": code, "section": label})
                if second is None or second.response_class != "result":
                    continue
                yield Triple(
                    id=self.identity("B"),
                    row_class="B",
                    sub_kind="chart_then_detail",
                    calls=[first, second],
                    subject=f"lesson {code} and its {words(str(label))} section",
                    provenance=self.provenance("lesson corpus", code, chain="chart then detail"),
                    narrative_seed={"lesson": code, "section": words(str(label))},
                )
                made += 1

    def machine_chains(self, wanted: int) -> Iterator[Triple]:
        pairs = self.graph_machines()
        self.rng.shuffle(pairs)
        made = 0
        for family, kind in pairs:
            if made >= wanted:
                return
            first = self.run("graph_machine", {"family": family, "kind": kind})
            if first is None or first.response_class != "result":
                continue
            second = self.run("graph_borrows", {"family": family, "kind": kind, "limit": 3})
            if second is None or second.response_class != "result":
                continue
            yield Triple(
                id=self.identity("B"),
                row_class="B",
                sub_kind="machine_then_borrows",
                calls=[first, second],
                subject=f"the {words(kind)} machine and what it shares with others",
                provenance=self.provenance(GRAPH, f"{family}/{kind}", chain="machine then borrows"),
                narrative_seed={"family": family, "kind": words(kind)},
            )
            made += 1

    def repair_chains(self, wanted: int) -> Iterator[Triple]:
        """B-repair: a broad abstention followed by a result-bearing reformulation."""
        made = 0
        for contract, content, source in self.recognition_candidates():
            if made >= wanted:
                return
            first = self.run("strategy_recognize", {"content": "I worked with the numbers."})
            if first is None or first.response_class == "result":
                continue
            second = self.run("strategy_recognize", {"content": content})
            if second is None or second.response_class != "result":
                continue
            yield Triple(
                id=self.identity("B"), row_class="B", sub_kind="repair_after_abstention",
                calls=[first, second],
                subject=f"a student's fuller explanation after a broad description returned nothing",
                provenance=self.provenance(
                    RECOGNIZER, source,
                    chain="broad strategy recognition then evidence-bearing reformulation",
                    source_strategy=contract["name"],
                ),
                narrative_seed={"student_said": content, "first_attempt": "I worked with the numbers."},
            )
            made += 1

    # ------------------------------------------------------------- class D

    def limits(self, wanted: int) -> Iterator[Triple]:
        """Refusals and abstentions, generated rather than listed.

        The relay reply is template-bound to what the worker said, so the
        teacher model never writes it; a teacher writing relay prose can smuggle
        in the answer Hermes declined to give.
        """
        made = 0
        for maker in (self._unknown_lessons, self._unknown_strategies, self._unknown_machines,
                      self._exemplar_misses, self._unmatched_prose, self._empty_searches,
                      self._absent_profiles, self._unresolved_entailments, self._bad_sections):
            for triple in maker():
                if made >= wanted:
                    return
                yield triple
                made += 1

    def _unknown_lessons(self) -> Iterator[Triple]:
        for grade in (9, 10, 11, 12):
            for unit in range(1, 7):
                for lesson in (7, 14, 21):
                    code = f"IM-G{grade}-U{unit}-L{lesson}"
                    for name in ("monitoring_chart", "lesson_enactment_run", "lesson_deformation_chart"):
                        key = "lesson" if name == "lesson_enactment_run" else "code"
                        call = self.run(name, {key: code})
                        if call is None or call.response_class == "result":
                            continue
                        yield Triple(
                            id=self.identity("D"), row_class="D", sub_kind=f"{name}_uncovered",
                            calls=[call], subject=f"lesson {code}",
                            provenance=self.provenance("worker refusal vocabulary", f"{name}:{code}",
                                                       response_class=call.response_class),
                            narrative_seed={"lesson": code},
                        )

    def _unknown_strategies(self) -> Iterator[Triple]:
        invented = [
            "borrow_across_zero_shortcut", "guess_and_check_fractions", "lattice_multiplication",
            "russian_peasant_multiplication", "chunking_division", "finger_multiplication_nines",
            "cross_multiply_shortcut", "butterfly_method_fractions", "keep_change_flip",
            "foil_expansion", "long_division_bring_down", "napiers_bones",
            "vedic_vertically_crosswise", "trachtenberg_doubling", "casting_out_nines",
            "japanese_line_multiplication", "box_method_multiplication", "ladder_method_gcf",
        ]
        for name in invented:
            call = self.run("strategy_trace", {"strategy": name, "input": {"a": 47, "b": 28}})
            if call is None or call.response_class == "result":
                continue
            yield Triple(
                id=self.identity("D"), row_class="D", sub_kind="strategy_unregistered",
                calls=[call], subject=f"the {words(name)} method",
                provenance=self.provenance("worker refusal vocabulary", f"strategy_trace:{name}",
                                           response_class=call.response_class),
                narrative_seed={"method": words(name)},
            )

    def _unknown_machines(self) -> Iterator[Triple]:
        for family, kind in (
            ("estimation", "front_end_rounding"), ("arithmetic", "mental_math"),
            ("estimation", "compatible_numbers"), ("trigonometry", "unit_circle"),
            ("calculus", "limit_evaluation"), ("algebra", "quadratic_formula"),
            ("statistics", "regression_line"), ("geometry", "compass_construction"),
        ):
            call = self.run("graph_machine", {"family": family, "kind": kind})
            if call is None or call.response_class == "result":
                continue
            yield Triple(
                id=self.identity("D"), row_class="D", sub_kind="machine_uncovered",
                calls=[call], subject=f"the {words(kind)} machine in the {family} family",
                provenance=self.provenance("worker refusal vocabulary", f"graph_machine:{family}/{kind}",
                                           response_class=call.response_class),
                narrative_seed={"family": family, "kind": words(kind)},
            )

    def _exemplar_misses(self) -> Iterator[Triple]:
        for a, b, c, d in ((1, 9, 1, 9), (2, 5, 1, 5), (3, 4, 1, 2), (7, 8, 3, 8),
                           (1, 6, 1, 6), (5, 6, 1, 3), (2, 3, 1, 4), (3, 5, 2, 5),
                           (1, 3, 1, 12), (4, 5, 1, 10), (1, 2, 3, 8), (5, 8, 1, 4)):
            wrong = f"frac({a + c},{b + d})"
            call = self.run("diagnose_error", {"domain": "fraction",
                                               "input": f"frac({a},{b})-frac({c},{d})", "got": wrong})
            if call is None or call.response_class == "result":
                continue
            yield Triple(
                id=self.identity("D"), row_class="D", sub_kind="diagnose_abstains",
                calls=[call],
                subject=f"a student writing {say_fraction(a, b)} and {say_fraction(c, d)} as {say_fraction(a + c, b + d)}",
                provenance=self.provenance("worker abstention shapes", f"diagnose_error:{a}/{b}+{c}/{d}",
                                           response_class=call.response_class),
                narrative_seed={"student_wrote": f"{say_fraction(a, b)} and {say_fraction(c, d)} as {say_fraction(a + c, b + d)}"},
            )

    def _unmatched_prose(self) -> Iterator[Triple]:
        for prose in (
            "we did the thing with the boxes again", "my mum showed me a trick at home",
            "it was easy", "I did it in my head", "I lined them up and added each column",
            "I counted on by tens and then by ones", "I just looked at it and knew",
            "we always do it this way in my old school", "I used the poster on the wall",
            "my sister taught me", "I guessed and it was right", "I used my fingers",
        ):
            call = self.run("strategy_recognize", {"content": prose})
            if call is None or call.response_class == "result":
                continue
            yield Triple(
                id=self.identity("D"), row_class="D", sub_kind="recognize_abstains",
                calls=[call], subject=f"a student saying {prose!r}",
                provenance=self.provenance("worker abstention shapes", f"strategy_recognize:{prose[:24]}",
                                           response_class=call.response_class),
                narrative_seed={"student_said": prose},
            )

    def _empty_searches(self) -> Iterator[Triple]:
        for topic in ("trigonometric identity", "calculus limit", "matrix determinant",
                      "logarithm", "complex number", "vector cross product",
                      "differential equation", "eigenvalue", "modular arithmetic",
                      "polar coordinate"):
            call = self.run("misconception_search_rows", {"query": topic, "k": 3})
            if call is None or call.response_class == "result":
                continue
            yield Triple(
                id=self.identity("D"), row_class="D", sub_kind="search_abstains",
                calls=[call], subject=f"recorded {topic} errors",
                provenance=self.provenance("worker abstention shapes", f"search:{topic}",
                                           response_class=call.response_class),
                narrative_seed={"topic": topic},
            )

    def _absent_profiles(self) -> Iterator[Triple]:
        for content in ("unit_fraction", "area_model", "repeated_addition", "equal_share",
                        "number_line", "skip_counting", "place_value", "array_model",
                        "partitioning", "iteration"):
            call = self.run("incompatibility_profile", {"content": content})
            if call is None or call.response_class == "result":
                continue
            yield Triple(
                id=self.identity("D"), row_class="D", sub_kind="profile_absent",
                calls=[call], subject=f"what rules out {words(content)}",
                provenance=self.provenance("worker abstention shapes", f"profile:{content}",
                                           response_class=call.response_class),
                narrative_seed={"content": words(content)},
            )

    def _unresolved_entailments(self) -> Iterator[Triple]:
        for left, right in (("column_stacking", "counting_on"), ("area_model", "array_model"),
                            ("skip_counting", "repeated_addition"), ("number_line", "tape_diagram"),
                            ("partitioning", "iteration"), ("equal_share", "fair_share")):
            call = self.run("incompatibility_entailments", {"replacement": left, "replaced": right})
            if call is None or call.response_class == "result":
                continue
            yield Triple(
                id=self.identity("D"), row_class="D", sub_kind="entailment_unresolved",
                calls=[call], subject=f"whether {words(left)} entails {words(right)}",
                provenance=self.provenance("worker abstention shapes", f"entail:{left}/{right}",
                                           response_class=call.response_class),
                narrative_seed={"left": words(left), "right": words(right)},
            )

    def _bad_sections(self) -> Iterator[Triple]:
        codes = self.lesson_codes()[:6]
        for code in codes:
            for section in ("closing_summary", "homework", "assessment_rubric", "exit_ticket"):
                call = self.run("monitoring_chart_detail", {"code": code, "section": section})
                if call is None or call.response_class == "result":
                    continue
                yield Triple(
                    id=self.identity("D"), row_class="D", sub_kind="section_absent",
                    calls=[call], subject=f"the {words(section)} part of lesson {code}",
                    provenance=self.provenance("worker refusal vocabulary", f"detail:{code}/{section}",
                                               response_class=call.response_class),
                    narrative_seed={"lesson": code, "section": words(section)},
                )

    def multi_call_limits(self, wanted: int) -> Iterator[Triple]:
        """D multi-call relay: two honest limits, with the last one relayed."""
        made = 0
        for grade in (9, 10, 11, 12):
            for unit in range(1, 7):
                for lesson in (8, 15, 22):
                    if made >= wanted:
                        return
                    code = f"IM-G{grade}-U{unit}-L{lesson}"
                    first = self.run("monitoring_chart", {"code": code})
                    second = self.run("lesson_deformation_chart", {"code": code})
                    if first is None or second is None:
                        continue
                    if first.response_class == "result" or second.response_class == "result":
                        continue
                    yield Triple(
                        id=self.identity("D"), row_class="D", sub_kind="multi_call_relay",
                        calls=[first, second], subject=f"planning unavailable lesson {code}",
                        provenance=self.provenance(
                            "worker refusal vocabulary", f"multi-limit:{code}",
                            chain="monitoring chart then deformation chart",
                        ),
                        narrative_seed={"lesson": code},
                    )
                    made += 1

        invented = (
            "spiral_addition_wheel", "rainbow_subtraction_arc", "staircase_product_method",
            "mirror_division_path", "triangle_sum_ladder", "bead_exchange_shortcut",
            "clock_face_fraction_fold", "diagonal_decimal_shift", "zigzag_ratio_table",
            "corner_counting_rule", "balance_beam_percent", "nested_grouping_route",
            "arrow_chain_addition", "folded_number_line", "paired_column_sweep",
            "circle_partition_jump", "reverse_array_walk", "tally_bundle_switch",
        )
        for name in invented:
            if made >= wanted:
                return
            first = self.run("strategy_trace", {"strategy": name, "input": {"a": 63, "b": 29}})
            second = self.run("strategy_trace", {"strategy": name, "input": {"a": 18, "b": 7}})
            if first is None or second is None:
                continue
            if first.response_class == "result" or second.response_class == "result":
                continue
            yield Triple(
                id=self.identity("D"), row_class="D", sub_kind="multi_call_relay",
                calls=[first, second], subject=f"the unregistered {words(name)} method",
                provenance=self.provenance(
                    "worker refusal vocabulary", f"multi-limit:{name}",
                    chain="strategy trace retried with a simpler input",
                ),
                narrative_seed={"method": words(name)},
            )
            made += 1

    # ------------------------------------------------------------- helpers

    _codes: list[str] | None = None

    def lesson_codes(self) -> list[str]:
        if TripleBank._codes is None:
            listing = self.server.call("lesson_enactment_list", {})
            codes = [
                entry.get("lesson") for entry in listing.get("lessons", [])
                if isinstance(entry, dict) and isinstance(entry.get("lesson"), str)
            ]
            TripleBank._codes = codes
        return list(TripleBank._codes)

    _machines: list[tuple[str, str]] | None = None

    def graph_machines(self) -> list[tuple[str, str]]:
        if TripleBank._machines is None:
            graph = json.loads((REPO_ROOT / GRAPH).read_text(encoding="utf-8"))
            found: list[tuple[str, str]] = []
            for node in graph.get("nodes", []):
                pair = (node.get("family"), node.get("kind"))
                if all(isinstance(part, str) for part in pair) and pair not in found:
                    found.append(pair)  # type: ignore[arg-type]
            TripleBank._machines = found
        return list(TripleBank._machines)


def build(server: HermesMCPServer, chat: GemmaChatFormat, targets: dict[str, int], seed: int) -> tuple[list[Triple], TripleBank]:
    bank = TripleBank(server, chat, seed)
    plan: list[tuple[str, Callable[[int], Iterator[Triple]], int]] = [
        ("A trace", bank.strategy_traces, targets["A"] * 30 // 100),
        ("A diagnose", bank.diagnoses, targets["A"] * 20 // 100),
        ("A chart", bank.charts, targets["A"] * 12 // 100),
        ("A machine", bank.machines, targets["A"] * 12 // 100),
        ("A claim", bank.claims, targets["A"] * 12 // 100),
        ("A search", bank.searches, targets["A"] * 6 // 100),
        ("A lookup", bank.lookups, targets["A"] * 6 // 100),
        ("A inventory", bank.singletons, targets["A"] * 4 // 100),
        ("B discover", bank.discovery_chains, targets["B"] * 45 // 100),
        ("B machine", bank.machine_chains, targets["B"] * 25 // 100),
        ("B chart", bank.chart_chains, targets["B"] * 20 // 100),
        ("B lookup", bank.lookup_chains, targets["B"] * 10 // 100),
        ("D limits", bank.limits, targets["D"]),
        # Wave 2 pools append after every phase-1 pool. Existing triple ids and
        # teacher cache groupings therefore retain their order-dependent keys.
        ("A recognize", bank.recognitions, 60),
        ("B repair", bank.repair_chains, 60),
        ("D multi relay", bank.multi_call_limits, 90),
    ]
    triples: list[Triple] = []
    for label, maker, wanted in plan:
        if label == "A recognize":
            # The appended wave has its own seed stream, so rebuilding the old
            # pools or using --base produces the same appended candidates.
            bank.rng = random.Random(seed ^ 0x52D2)
        produced = list(maker(wanted))
        print(f"  {label:14s} {len(produced):5d} of {wanted:5d} wanted", flush=True)
        triples.extend(produced)
    return triples, bank


def append_wave2(
    server: HermesMCPServer, chat: GemmaChatFormat, base: list[Triple], seed: int
) -> tuple[list[Triple], TripleBank]:
    """Append only the wave-2 pools to an already executed phase-1 bank."""
    bank = TripleBank(server, chat, seed)
    bank.rng = random.Random(seed ^ 0x52D2)
    numeric_ids = [
        int(triple.id.rsplit("-", 1)[-1]) for triple in base
        if triple.id.rsplit("-", 1)[-1].isdigit()
    ]
    bank.counter = max(numeric_ids, default=0)
    additions: list[Triple] = []
    for label, maker, wanted in (
        ("A recognize", bank.recognitions, 60),
        ("B repair", bank.repair_chains, 60),
        ("D multi relay", bank.multi_call_limits, 90),
    ):
        produced = list(maker(wanted))
        print(f"  {label:14s} {len(produced):5d} of {wanted:5d} wanted", flush=True)
        additions.extend(produced)
    return [*base, *additions], bank


def main() -> int:
    import argparse

    from dataset import RUNTIME

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=RUNTIME / "datasets" / "triples.jsonl")
    parser.add_argument("--a", type=int, default=700)
    parser.add_argument("--b", type=int, default=400)
    parser.add_argument("--d", type=int, default=500)
    parser.add_argument("--seed", type=int, default=20260810)
    parser.add_argument(
        "--base", type=Path,
        help="append wave-2 pools to this executed phase-1 triple file instead of rebuilding it",
    )
    arguments = parser.parse_args()

    chat = GemmaChatFormat()
    server = HermesMCPServer("core", REPO_ROOT)
    try:
        if arguments.base:
            base = [
                Triple.from_dict(json.loads(line))
                for line in arguments.base.read_text(encoding="utf-8").splitlines()
                if line.strip()
            ]
            triples, bank = append_wave2(server, chat, base, arguments.seed)
        else:
            triples, bank = build(
                server, chat, {"A": arguments.a, "B": arguments.b, "D": arguments.d}, arguments.seed
            )
    finally:
        server.close()
    arguments.output.parent.mkdir(parents=True, exist_ok=True)
    with arguments.output.open("w", encoding="utf-8") as handle:
        for triple in triples:
            handle.write(json.dumps(triple.to_dict(), ensure_ascii=False, sort_keys=True) + "\n")
    counts: dict[str, int] = {}
    for triple in triples:
        counts[triple.row_class] = counts.get(triple.row_class, 0) + 1
    print(json.dumps({
        "path": str(arguments.output),
        "triples": len(triples),
        "by_class": counts,
        "payloads_narrowed": bank.capped,
        "dropped": bank.dropped,
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
