#!/usr/bin/env python3
"""Build the phase-0 pilot rows the gates are proven against.

Generation runs backward, as the design specifies: from an (op, args, result)
triple the worker actually produced to a user turn that would warrant it. The
tool half is correct because it executed, not because anything judged it.

What the pilot does NOT have is the framing half the full program calls for.
Phase 1 writes user turns with a teacher model; §6.4 of the design holds that
choice for Tio. Until then the framings here are authored patterns varied by
seed, which is enough to prove the gates and not enough to train on. The
distinction is recorded in each row's provenance as `framing: authored`.
"""
from __future__ import annotations

import argparse
import json
import random
import re
import sys
from pathlib import Path
from typing import Any, Callable, Iterator

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))
sys.path.insert(0, str(Path(__file__).resolve().parent))

from chat_format import GemmaChatFormat, conversation, sample_menu  # noqa: E402
from contamination import OverlapGate  # noqa: E402
from dataset import (  # noqa: E402
    RUNTIME,
    Call,
    Row,
    dataset_sha,
    execute,
    now,
    read as read_rows,
    run_gates,
    worker_sha,
    write,
)
from hermes.mcp.server import HermesMCPServer  # noqa: E402

MENU_SIZE = 8
DEFAULT_OUTPUT = RUNTIME / "datasets" / "pilot-200.jsonl"

CONTRACTS = "knowledge/strategies/automaton_input_contracts.pl"
REGISTRY = "hermes/capability_registry.pl"
GRAPH = "docs/research/assets/automata/full_graph.json"


def clean_name(name: str) -> str:
    return name.replace("_", " ")


# ------------------------------------------------------------ framing banks
# Authored patterns. Each takes the mathematics of an executed call and asks
# about it the way a teacher would, without naming a tool or quoting a result.

ASK_TRACE = (
    "A child worked {expression} this way in my class. Walk me through the steps that strategy takes.",
    "I want to model {expression} the way {gloss} goes. What does each step look like?",
    "One group solved {expression} by {gloss}. What is the run of that method, step by step?",
)
ASK_STRATEGY_NAMES = (
    "What {operation} methods does your library know about? I am planning a share-out.",
    "I need a short list of {operation} approaches to anticipate before tomorrow.",
    "Which {operation} strategies can you run for me?",
)
ASK_MISCONCEPTION_SEARCH = (
    "Is there anything recorded about {topic} errors that I could read before Monday?",
    "What does the research base hold on {topic} difficulties?",
    "Point me at what has been written up about {topic} mistakes.",
)
ASK_LOOKUP_DOMAIN = (
    "Show me a couple of recorded {domain} errors so I know what to watch for.",
    "What {domain} errors are on file? Two or three is plenty.",
)
ASK_CHART = (
    "I am teaching {code} tomorrow. What should I be listening for?",
    "Give me the planning inventory for {code}.",
    "What does {code} anticipate from students?",
)
ASK_ABDUCE = (
    "A student wrote {input_text} and answered {got_text}. What rule would produce that?",
    "One paper shows {input_text} coming out as {got_text}. What method gives that answer?",
    "I have {input_text} answered {got_text}. What would a child have to be doing?",
)
ASK_GRAPH = (
    "How does the {family} machine for {kind} move between its states?",
    "What are the states and steps of {kind} under {family}?",
)
ASK_INCOMPATIBILITY = (
    "What contents cannot hold together with {content}?",
    "Is {content} incompatible with anything on record?",
)
ASK_ENACTMENT = (
    "Which lessons can you actually run end to end?",
    "What is enactable right now, and what is named as out of reach?",
)

# Class C. Hard negatives: no Hermes operation answers these.
C1_KNOWN_FACT = (
    ("What is 7 times 8?", "Fifty-six."),
    ("Quick check: what is 144 divided by 12?", "Twelve."),
    ("What is a prime number, in one sentence?", "A whole number greater than one whose only whole-number factors are one and itself."),
    ("What does the word numerator mean?", "The numerator is the count of parts the fraction names, written above the line."),
    ("Is 0 an even number?", "Yes. Zero is divisible by two with no remainder."),
    ("What is one half plus one half?", "One whole."),
    ("How many sides does a hexagon have?", "Six."),
    ("What is 25 percent of 80?", "Twenty."),
)
C2_OUT_OF_SCOPE = (
    ("How should I seat a group of four so the quiet student is not squeezed out?", "Put the quiet student where two others must turn toward them to be heard, and give that seat the recording job so the group has to come back to it."),
    ("A student cried during the quiz. What do I say tomorrow?", "Meet them before class, name only what you saw, and offer one concrete next step they choose between. Say nothing about the score until they raise it."),
    ("How long should a number talk run in second grade?", "Ten minutes is usually the ceiling; stop while children still want the next turn."),
    ("My co-teacher and I keep interrupting each other in front of the class. Ideas?", "Agree beforehand on who holds the floor for each segment, and use a silent hand-off signal rather than a spoken correction."),
    ("Do you have advice for a parent who wants nightly worksheets?", "Offer one shared task a week that the child explains at home, and say plainly what nightly drill does and does not buy."),
    ("What time should I schedule my intervention block?", "Put it where attention is best in your room, and protect it from being the block that gets cut."),
    ("Can you help me word an email asking for more planning time?", "State the hours you need, what you will produce with them, and one thing you will stop doing to make room."),
    ("How do I keep a fast finisher busy without more worksheets?", "Hand them the job of writing the question the class should argue about next."),
)
C4_ALREADY_ANSWERED = (
    "Remind me what that came out to?",
    "Sorry, what was that result again?",
    "Can you restate that last answer plainly?",
)


def surface_match_ask(mathematics: str) -> str:
    """A class-C3 turn: every lexical cue is there and no operation answers it."""
    return mathematics


C3_SURFACE_MATCHED = (
    ("A parent asked why we teach {gloss} at all instead of the standard algorithm. What do I say?",
     "Say that the method makes the place-value reasoning audible, and that the algorithm arrives faster once children can say why the steps work."),
    ("My class already knows {gloss}. How do I make tomorrow's lesson worth their time?",
     "Give them a case where the method gets clumsy and let them argue for a better one; the comparison is the lesson."),
    ("Two students disagree about whether {gloss} is allowed on the test. How should I settle it?",
     "Tell them any method they can justify is allowed, then have each write the justification and trade."),
    ("Should I put {gloss} on the anchor chart before or after the students invent it?",
     "After. The chart records what they produced; posting it first turns invention into copying."),
    ("How do I grade a student who used {gloss} correctly but never wrote a number sentence?",
     "Give credit for the reasoning and ask for the sentence as the revision, so the notation is a next step rather than a penalty."),
    ("A student wants to know if {gloss} always works. How should I handle that?",
     "Tell them to hunt for a case where it breaks, and give them the rest of the period to find one."),
)


def gloss_for(name: str) -> str:
    return clean_name(name)


# -------------------------------------------------------------- the sources


def contract_rows(server: HermesMCPServer) -> list[dict[str, Any]]:
    return list(server._strategy_contracts)


def lesson_codes(server: HermesMCPServer, limit: int = 40) -> list[str]:
    """Lesson codes the monitoring chart actually serves."""
    listing = server.call("lesson_enactment_list", {})
    codes: list[str] = []
    for entry in listing.get("lessons", []) if isinstance(listing, dict) else []:
        code = entry.get("lesson") if isinstance(entry, dict) else None
        if isinstance(code, str):
            codes.append(code)
    return codes[:limit]


def graph_machines(limit: int = 40) -> list[tuple[str, str]]:
    graph = json.loads((REPO_ROOT / GRAPH).read_text(encoding="utf-8"))
    seen: list[tuple[str, str]] = []
    for node in graph.get("nodes", []):
        pair = (node.get("family"), node.get("kind"))
        if all(isinstance(part, str) for part in pair) and pair not in seen:
            seen.append(pair)  # type: ignore[arg-type]
        if len(seen) >= limit:
            break
    return seen


def misconception_topics() -> list[str]:
    return [
        "fraction", "decimal", "measurement", "place value", "subtraction",
        "multiplication", "division", "percent", "integer", "ratio",
    ]


# ------------------------------------------------------------- row builders


class Builder:
    def __init__(self, server: HermesMCPServer, seed: int) -> None:
        self.server = server
        self.rng = random.Random(seed)
        self.tools = list(server._public_tools)
        self.tool_names = [tool["name"] for tool in self.tools]
        self.sha = worker_sha()
        self.counter = 0

    def identity(self, row_class: str) -> str:
        self.counter += 1
        return f"pilot-{row_class}-{self.counter:04d}"

    def menu(self, required: list[str]) -> list[str]:
        chosen = sample_menu(self.tools, required, MENU_SIZE, self.rng)
        return [tool["name"] for tool in chosen]

    def call(self, name: str, arguments: dict[str, Any]) -> Call:
        probe = Call(name=name, arguments=arguments, response={}, response_class="result")
        response, response_class = execute(self.server, probe)
        return Call(name=name, arguments=arguments, response=response, response_class=response_class)

    def provenance(self, source: str, row: str, **extra: Any) -> dict[str, Any]:
        return {
            "source": source,
            "row": row,
            "executed_at": now(),
            "worker_sha": self.sha,
            "framing": "authored",
            **extra,
        }

    # ---- class A: one call, grounded reply

    def strategy_trace_rows(self, count: int) -> Iterator[Row]:
        contracts = [row for row in contract_rows(self.server) if row["example"]]
        self.rng.shuffle(contracts)
        made = 0
        for contract in contracts:
            if made >= count:
                return
            call = self.call(
                "strategy_trace",
                {"strategy": contract["name"], "input": contract["example"]},
            )
            if call.response_class != "result":
                continue
            example = contract["example"]
            expression = (
                f"{example['a']} and {example['b']}"
                if {"a", "b"} <= set(example)
                else json.dumps(example, sort_keys=True)
            )
            gloss = gloss_for(contract["name"])
            user_turn = self.rng.choice(ASK_TRACE).format(expression=expression, gloss=gloss)
            result = call.response.get("result", {})
            expected = result.get("expected") if isinstance(result, dict) else None
            reply = (
                f"Hermes runs {gloss} on that input and reports {expected}."
                if expected is not None
                else f"Hermes runs {gloss} on that input and returns its recorded trace."
            )
            yield Row(
                id=self.identity("A"),
                row_class="A",
                menu=self.menu(["strategy_trace"]),
                user_turn=user_turn,
                calls=[call],
                reply=reply,
                provenance=self.provenance(CONTRACTS, contract["source"], strategy=contract["name"]),
            )
            made += 1

    def search_rows(self, count: int) -> Iterator[Row]:
        topics = misconception_topics()
        for index in range(count):
            topic = topics[index % len(topics)]
            call = self.call("misconception_search_rows", {"query": topic, "k": 3})
            if call.response_class != "result":
                continue
            rows = call.response["result"]["rows"]
            names = ", ".join(clean_name(row["name"]) for row in rows[:3])
            yield Row(
                id=self.identity("A"),
                row_class="A",
                menu=self.menu(["misconception_search_rows"]),
                user_turn=self.rng.choice(ASK_MISCONCEPTION_SEARCH).format(topic=topic),
                calls=[call],
                reply=f"The stored rows that match are {names}. Each carries its own citation.",
                provenance=self.provenance("misconception row store", f"query:{topic}"),
            )

    def lookup_rows(self, count: int) -> Iterator[Row]:
        domains = ["fraction", "decimal", "measurement", "integer", "percent"]
        for index in range(count):
            domain = domains[index % len(domains)]
            call = self.call("misconception_lookup", {"domain": domain, "limit": 2})
            if call.response_class != "result":
                continue
            rows = call.response["result"]["rows"]
            described = "; ".join(clean_name(row["description"]) for row in rows)
            yield Row(
                id=self.identity("A"),
                row_class="A",
                menu=self.menu(["misconception_lookup"]),
                user_turn=self.rng.choice(ASK_LOOKUP_DOMAIN).format(domain=domain),
                calls=[call],
                reply=f"Two recorded {domain} errors: {described}.",
                provenance=self.provenance("misconception registry", f"domain:{domain}"),
            )

    def chart_rows(self, codes: list[str], count: int) -> Iterator[Row]:
        made = 0
        for code in codes:
            if made >= count:
                return
            call = self.call("monitoring_chart", {"code": code})
            if call.response_class != "result":
                continue
            result = call.response["result"]
            names = ", ".join(clean_name(name) for name in result.get("strategy_names", [])[:4])
            sections = len(result.get("sections", []))
            reply = (
                f"The chart for {code} anticipates {names} and carries {sections} sections."
                if names
                else f"The chart for {code} carries {sections} sections and names no anticipated strategy."
            )
            yield Row(
                id=self.identity("A"),
                row_class="A",
                menu=self.menu(["monitoring_chart"]),
                user_turn=self.rng.choice(ASK_CHART).format(code=code),
                calls=[call],
                reply=reply,
                provenance=self.provenance("lesson corpus", code),
            )
            made += 1

    def abduce_rows(self, count: int) -> Iterator[Row]:
        candidates = [
            ("fraction", "frac(1,9)-frac(1,9)", "frac(1,18)", "one ninth and one ninth", "one eighteenth"),
            ("fraction", "frac(1,2)-frac(1,3)", "frac(1,5)", "one half and one third", "one fifth"),
            ("fraction", "frac(1,4)-frac(1,4)", "frac(1,8)", "one quarter and one quarter", "one eighth"),
            ("fraction", "frac(2,3)-frac(1,3)", "frac(3,6)", "two thirds and one third", "three sixths"),
            ("fraction", "frac(1,5)-frac(1,5)", "frac(1,10)", "one fifth and one fifth", "one tenth"),
            ("fraction", "frac(3,4)-frac(1,2)", "frac(4,6)", "three quarters and one half", "four sixths"),
        ]
        made = 0
        while made < count:
            domain, text, got, input_text, got_text = candidates[made % len(candidates)]
            call = self.call("abduce_error", {"domain": domain, "input": text, "got": got})
            if call.response_class != "result":
                return
            rules = call.response["result"]
            named = ", ".join(clean_name(row["citations"][0]["description"]) for row in rules[:2] if row.get("citations"))
            yield Row(
                id=self.identity("A"),
                row_class="A",
                menu=self.menu(["abduce_error"]),
                user_turn=self.rng.choice(ASK_ABDUCE).format(input_text=input_text, got_text=got_text),
                calls=[call],
                reply=(
                    f"Hermes reproduces that answer with {named}. These are candidates with citations, "
                    "not a diagnosis of the child."
                ),
                provenance=self.provenance("misconception rule registry", f"{domain}:{text}"),
            )
            made += 1

    def graph_rows(self, machines: list[tuple[str, str]], count: int) -> Iterator[Row]:
        made = 0
        for family, kind in machines:
            if made >= count:
                return
            call = self.call("graph_machine", {"family": family, "kind": kind})
            if call.response_class != "result":
                continue
            result = call.response["result"]
            yield Row(
                id=self.identity("A"),
                row_class="A",
                menu=self.menu(["graph_machine"]),
                user_turn=self.rng.choice(ASK_GRAPH).format(family=family, kind=clean_name(kind)),
                calls=[call],
                reply=(
                    f"That machine holds {len(result.get('states', []))} states and "
                    f"{len(result.get('edges', []))} transitions. Shared action names record a borrow, "
                    "not an equivalence."
                ),
                provenance=self.provenance(GRAPH, f"{family}/{kind}"),
            )
            made += 1

    # ---- class B: the result of the first call chooses the second

    def discovery_chains(self, count: int) -> Iterator[Row]:
        operations = ["fraction", "subtraction", "addition", "division", "multiplication", "measurement"]
        made = 0
        for index in range(count * 3):
            if made >= count:
                return
            operation = operations[index % len(operations)]
            first = self.call("list_strategies", {"operation": operation, "limit": 8})
            if first.response_class != "result":
                continue
            names = [row["name"] for row in first.response["result"]["strategies"]]
            contracts = {row["name"]: row for row in contract_rows(self.server)}
            chosen = next((name for name in names if contracts.get(name, {}).get("example")), None)
            if chosen is None:
                continue
            second = self.call(
                "strategy_trace", {"strategy": chosen, "input": contracts[chosen]["example"]}
            )
            if second.response_class != "result":
                continue
            expected = second.response["result"].get("expected")
            yield Row(
                id=self.identity("B"),
                row_class="B",
                menu=self.menu(["list_strategies", "strategy_trace"]),
                user_turn=self.rng.choice(ASK_STRATEGY_NAMES).format(operation=operation),
                calls=[first, second],
                reply=(
                    f"Hermes registers {len(names)} {operation} methods on this page. "
                    f"Running {gloss_for(chosen)} on its worked input reaches {expected}."
                ),
                provenance=self.provenance(CONTRACTS, chosen, chain="list_strategies then strategy_trace"),
            )
            made += 1

    def lookup_chains(self, count: int) -> Iterator[Row]:
        topics = misconception_topics()
        made = 0
        for index in range(count * 2):
            if made >= count:
                return
            topic = topics[index % len(topics)]
            first = self.call("misconception_search_rows", {"query": topic, "k": 3})
            if first.response_class != "result" or not first.response["result"]["rows"]:
                continue
            row = first.response["result"]["rows"][0]
            second = self.call("misconception_lookup", {"source": row["db_row"], "limit": 1})
            if second.response_class != "result":
                continue
            found = second.response["result"]["rows"]
            gloss = found[0].get("gloss", "") if found else ""
            yield Row(
                id=self.identity("B"),
                row_class="B",
                menu=self.menu(["misconception_search_rows", "misconception_lookup"]),
                user_turn=f"Find me the recorded {topic} error that has a citation, then tell me what it says.",
                calls=[first, second],
                reply=f"The first matching row is {clean_name(row['name'])}. Its record reads: {gloss}",
                provenance=self.provenance("misconception row store", row["db_row"], chain="search then lookup"),
            )
            made += 1

    def chart_chains(self, codes: list[str], count: int) -> Iterator[Row]:
        made = 0
        for code in codes:
            if made >= count:
                return
            first = self.call("monitoring_chart", {"code": code})
            if first.response_class != "result":
                continue
            sections = first.response["result"].get("sections", [])
            if not sections:
                continue
            section = sections[0].get("name") if isinstance(sections[0], dict) else sections[0]
            second = self.call("monitoring_chart_detail", {"code": code, "section": section})
            if second.response_class != "result":
                continue
            yield Row(
                id=self.identity("B"),
                row_class="B",
                menu=self.menu(["monitoring_chart", "monitoring_chart_detail"]),
                user_turn=f"For {code}, what sections does the planning inventory hold, and what is in the first one?",
                calls=[first, second],
                reply=(
                    f"{code} carries {len(sections)} sections. The first, {clean_name(str(section))}, "
                    "returns its recorded contents."
                ),
                provenance=self.provenance("lesson corpus", code, chain="chart then detail"),
            )
            made += 1

    # ---- class C: no call is warranted, and the row's label is the empty list

    def known_fact_rows(self, count: int) -> Iterator[Row]:
        for index in range(count):
            question, answer = C1_KNOWN_FACT[index % len(C1_KNOWN_FACT)]
            yield Row(
                id=self.identity("C"),
                row_class="C",
                menu=self.menu([]),
                user_turn=question,
                calls=[],
                reply=answer,
                provenance=self.provenance("authored class C1", f"known-fact:{index}", sub_kind="C1"),
            )

    def out_of_scope_rows(self, count: int) -> Iterator[Row]:
        for index in range(count):
            question, answer = C2_OUT_OF_SCOPE[index % len(C2_OUT_OF_SCOPE)]
            yield Row(
                id=self.identity("C"),
                row_class="C",
                menu=self.menu([]),
                user_turn=question,
                calls=[],
                reply=answer,
                provenance=self.provenance("authored class C2", f"out-of-scope:{index}", sub_kind="C2"),
            )

    def surface_matched_rows(self, count: int) -> Iterator[Row]:
        """C3: keep the mathematics of a class-A item and rewrite the ask."""
        contracts = [row for row in contract_rows(self.server) if row["example"]]
        self.rng.shuffle(contracts)
        for index in range(count):
            contract = contracts[index % len(contracts)]
            pattern, answer = C3_SURFACE_MATCHED[index % len(C3_SURFACE_MATCHED)]
            gloss = gloss_for(contract["name"])
            yield Row(
                id=self.identity("C"),
                row_class="C",
                menu=self.menu(["strategy_trace"]),
                user_turn=pattern.format(gloss=gloss),
                calls=[],
                reply=answer,
                provenance=self.provenance(
                    CONTRACTS, contract["source"], sub_kind="C3", surface_of=contract["name"]
                ),
            )

    def already_answered_rows(self, count: int) -> Iterator[Row]:
        """C4: the result is already in the context, so a second call is waste."""
        contracts = [row for row in contract_rows(self.server) if row["example"]]
        self.rng.shuffle(contracts)
        made = 0
        for contract in contracts:
            if made >= count:
                return
            call = self.call(
                "strategy_trace", {"strategy": contract["name"], "input": contract["example"]}
            )
            if call.response_class != "result":
                continue
            expected = call.response["result"].get("expected")
            if expected is None:
                continue
            gloss = gloss_for(contract["name"])
            prior = conversation(
                f"Run {gloss} for me on its worked input.",
                [call.to_dict()],
                f"Hermes reports {expected}.",
            )
            yield Row(
                id=self.identity("C"),
                row_class="C",
                menu=self.menu(["strategy_trace"]),
                user_turn=self.rng.choice(C4_ALREADY_ANSWERED),
                calls=[],
                reply=f"It came out to {expected}.",
                prior=prior,
                provenance=self.provenance(
                    CONTRACTS, contract["source"], sub_kind="C4", already_answered=contract["name"]
                ),
            )
            made += 1

    # ---- class D: Hermes refuses or abstains, and the reply relays the limit

    def refusal_rows(self, count: int) -> Iterator[Row]:
        seeds: list[tuple[str, dict[str, Any], str, str]] = [
            ("monitoring_chart", {"code": "IM-G9-U9-L9"},
             "I am planning IM-G9-U9-L9 for next week. What does the inventory anticipate?",
             "Hermes serves no chart for that lesson code, so there is nothing here to plan from."),
            ("monitoring_chart", {"code": "IM-G7-U2-L14"},
             "What should I listen for in IM-G7-U2-L14?",
             "Hermes serves no chart for that lesson code. I have nothing recorded to offer."),
            ("lesson_enactment_run", {"lesson": "IM-G9-U9-L9"},
             "Walk IM-G9-U9-L9 for me start to finish.",
             "No enactment is declared for that lesson, so Hermes has nothing to run."),
            ("strategy_trace", {"strategy": "borrow_across_zero_the_easy_way", "input": {"a": 300, "b": 147}},
             "Run the easy way of borrowing across zero on 300 take away 147.",
             "Hermes has no registered strategy under that name, so it will not run one."),
            ("strategy_trace", {"strategy": "guess_and_check_fractions", "input": {"a": 1, "b": 2}},
             "Trace guess and check on those fractions for me.",
             "That name is not in the registry, so Hermes declines to run it."),
            ("graph_machine", {"family": "estimation", "kind": "front_end_rounding"},
             "Take me through the estimation family's front-end machine.",
             "The graph holds no machine under that family and kind."),
            # prolog_query seeds no row here. Its sandbox rejection carries
            # fresh SWI variable numbers on every run, so the row cannot
            # re-execute identically, and its parse refusal quotes the caller's
            # own words back, which the framing gate reads as a turn written
            # from the result. Both limits are real; neither is trainable data.
            ("lesson_deformation_chart", {"code": "IM-G11-U4-L7"},
             "Show me the deformation scenes for IM-G11-U4-L7.",
             "Hermes charts no deformation for that lesson, so there are no scenes to show."),
            ("misconception_lookup", {"source": "not_a_row"},
             "Open whatever is stored against that reference number.",
             "That filter does not parse as a row identity, so the lookup was refused."),
        ]
        for index in range(count):
            name, arguments, user_turn, reply = seeds[index % len(seeds)]
            call = self.call(name, dict(arguments))
            if call.response_class == "result":
                continue
            yield Row(
                id=self.identity("D"),
                row_class="D",
                menu=self.menu([name]),
                user_turn=user_turn,
                calls=[call],
                reply=reply,
                provenance=self.provenance(
                    "worker refusal vocabulary", f"{name}:{json.dumps(arguments, sort_keys=True)}",
                    response_class=call.response_class,
                ),
            )

    def abstention_rows(self, count: int) -> Iterator[Row]:
        seeds: list[tuple[str, dict[str, Any], str, str]] = [
            ("diagnose_error", {"domain": "fraction", "input": "frac(1,9)-frac(1,9)", "got": "frac(1,18)"},
             "A child combined two ninths worth of pie and landed on a single eighteenth. What is on file?",
             "Hermes matches no recorded exemplar for that input, and an empty result is an abstention rather than a verdict that the work is right."),
            ("diagnose_error", {"domain": "fraction", "input": "frac(2,5)-frac(1,5)", "got": "frac(3,10)"},
             "This paper turns a pair of fifths into tenths. Which stored row covers it?",
             "No recorded exemplar matches that input. Hermes declines to name an error, which is not a claim that the answer is correct."),
            ("strategy_recognize", {"content": "I just knew it, it felt right"},
             "A student explained their work by saying they just knew it and it felt right. What strategy is that?",
             "Hermes aligns that sentence to no execution-observed trace, so it names no strategy. The empty result is an abstention."),
            ("strategy_recognize", {"content": "we did the thing with the boxes again"},
             "A student described their work only as the usual square-drawing routine. Name the method?",
             "That sentence matches no recorded trace, so Hermes names nothing. It is declining, not disagreeing."),
            ("incompatibility_profile", {"content": "unit_fraction"},
             "What contents cannot hold together with unit fraction?",
             "Hermes holds no incompatibility profile for that content, so there is no set to report."),
            ("incompatibility_profile", {"content": "area_model"},
             "Is area model incompatible with anything on record?",
             "There is no recorded profile for that content, so Hermes reports none."),
            ("abduce_error", {"domain": "multiplication", "input": "3*4", "got": "7"},
             "Someone answered three times four with seven. What rule builds that?",
             "No registered rule reproduces that answer, so Hermes offers no candidate."),
            ("misconception_search_rows", {"query": "trigonometric identity", "k": 3},
             "Is anything recorded about trigonometric identity errors?",
             "The offline row search finds no matching row, so nothing is on file to read."),
        ]
        for index in range(count):
            name, arguments, user_turn, reply = seeds[index % len(seeds)]
            call = self.call(name, dict(arguments))
            if call.response_class == "result":
                continue
            yield Row(
                id=self.identity("D"),
                row_class="D",
                menu=self.menu([name]),
                user_turn=user_turn,
                calls=[call],
                reply=reply,
                provenance=self.provenance(
                    "worker abstention shapes", f"{name}:{json.dumps(arguments, sort_keys=True)}",
                    response_class=call.response_class,
                ),
            )


def build(server: HermesMCPServer, total: int, seed: int) -> list[Row]:
    builder = Builder(server, seed)
    codes = lesson_codes(server)
    machines = graph_machines()
    share = {
        "A": round(total * 0.33),
        "B": round(total * 0.10),
        "C": round(total * 0.40),
        "D": total - round(total * 0.33) - round(total * 0.10) - round(total * 0.40),
    }
    plan: list[tuple[str, Callable[[], Iterator[Row]], int]] = [
        ("A strategy_trace", lambda: builder.strategy_trace_rows(share["A"] // 6 + 1), 0),
        ("A search", lambda: builder.search_rows(share["A"] // 6), 0),
        ("A lookup", lambda: builder.lookup_rows(share["A"] // 6), 0),
        ("A chart", lambda: builder.chart_rows(codes, share["A"] // 6), 0),
        ("A abduce", lambda: builder.abduce_rows(share["A"] // 6), 0),
        ("A graph", lambda: builder.graph_rows(machines, share["A"] // 6), 0),
        ("B discovery", lambda: builder.discovery_chains(share["B"] // 3 + 1), 0),
        ("B lookup", lambda: builder.lookup_chains(share["B"] // 3), 0),
        ("B chart", lambda: builder.chart_chains(codes, share["B"] // 3), 0),
        ("C1", lambda: builder.known_fact_rows(share["C"] // 4), 0),
        ("C2", lambda: builder.out_of_scope_rows(share["C"] // 4), 0),
        ("C3", lambda: builder.surface_matched_rows(share["C"] // 4), 0),
        ("C4", lambda: builder.already_answered_rows(share["C"] - 3 * (share["C"] // 4)), 0),
        ("D refusal", lambda: builder.refusal_rows(share["D"] // 2), 0),
        ("D abstention", lambda: builder.abstention_rows(share["D"] - share["D"] // 2), 0),
    ]
    rows: list[Row] = []
    for label, factory, _ in plan:
        produced = list(factory())
        print(f"  {label:16s} {len(produced):3d} rows", flush=True)
        rows.extend(produced)
    # Integer shares leave a remainder. Top it up class by class so the mix
    # stays the design's mix rather than whatever the division happened to
    # leave behind.
    top_ups: dict[str, Callable[[int], Iterator[Row]]] = {
        "A": builder.strategy_trace_rows,
        "B": lambda count: builder.discovery_chains(count),
        "C": builder.known_fact_rows,
        "D": builder.abstention_rows,
    }
    for row_class, wanted in share.items():
        have = sum(1 for row in rows if row.row_class == row_class)
        if have < wanted:
            extra = list(top_ups[row_class](wanted - have))
            print(f"  {row_class} top-up      {len(extra):3d} rows", flush=True)
            rows.extend(extra)
    return rows


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rows", type=int, default=200)
    parser.add_argument("--seed", type=int, default=20260810)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--probe", type=Path, default=RUNTIME / "probes" / "probe-v0.jsonl")
    arguments = parser.parse_args()

    server = HermesMCPServer("core", REPO_ROOT)
    try:
        print(f"building {arguments.rows} pilot rows against the live worker", flush=True)
        rows = build(server, arguments.rows, arguments.seed)
        chat = GemmaChatFormat()
        overlap = OverlapGate()
        tools = {tool["name"]: tool for tool in server._public_tools}
        held_out = None
        if arguments.probe.is_file():
            held_out = {row.id: row.user_turn for row in read_rows(arguments.probe)}
        report = run_gates(
            rows,
            server=server,
            chat=chat,
            overlap=overlap,
            tools=tools,
            held_out=held_out,
            held_out_label=arguments.probe.name,
        )
        # A row states what the gates found about it, not what the builder
        # hoped. Writing constants here would put a green field on a row the
        # report had already faulted.
        for row in rows:
            row.gates = report.per_row.get(row.id, {})
        failed = {failure["id"] for failure in report.failures}
        kept = [row for row in rows if row.id not in failed]
        path = write(kept, arguments.output)
        summary = report.summary()
        summary["written"] = len(kept)
        summary["dropped"] = len(rows) - len(kept)
        summary["path"] = str(path)
        summary["dataset_sha"] = dataset_sha(path)
        summary["worker_sha"] = worker_sha()
        print(json.dumps(summary, indent=2))
        (path.parent / f"{path.stem}-gates.json").write_text(
            json.dumps(summary, indent=2) + "\n", encoding="utf-8"
        )
    finally:
        server.close()
    return 0 if summary["written"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
