#!/usr/bin/env python3
"""Assemble the wave-2 training set: executed calls, narrative framings, gates.

The tool half comes from `triples.py` and is true by execution. The narrative
half comes from the 31 B teacher and is admitted only if it passes the framing
gate. The reply half depends on the class: for a class-D row it is bound to what
the worker actually said, and for every other class it is written by the teacher
and then checked for assertions the result does not support.

Every drop is attributed. A row that leaves this builder has passed six gates
and the held-out overlap check, and the report says how many did not and why.
"""
from __future__ import annotations

import argparse
import json
import math
import random
import sys
import threading
import time
from concurrent.futures import FIRST_COMPLETED, ThreadPoolExecutor, wait
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Sequence

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
for candidate in (str(REPO_ROOT), str(SCRIPT_DIR)):
    if candidate not in sys.path:
        sys.path.insert(0, candidate)

from chat_format import GemmaChatFormat, conversation, sample_menu  # noqa: E402
from contamination import OverlapGate  # noqa: E402
from dataset import (  # noqa: E402
    RUNTIME,
    WorkerHolder, Call, Row, dataset_sha, now, read as read_rows, run_gates, worker_sha, write,
)
from hermes.mcp.server import HermesMCPServer  # noqa: E402
from measure_floors import score_reply  # noqa: E402
from teacher import Teacher, admissible, framing_prompt, reply_prompt  # noqa: E402
from triples import HELD_OUT_TOOLS, NUMBER_WORDS, Triple, say_fraction, words  # noqa: E402
from wave2_pools import (  # noqa: E402
    BASE_OUT_OF_SCOPE_SCOPES,
    DEFINITION_PAIRS,
    NEW_OUT_OF_SCOPE_SCOPES,
    scope_faults,
)

MENU_SIZE = 8
PER_SUBJECT = 4
SUBJECTS_PER_CALL = 4
# The live wave-2 build admitted 380 of 544 C1 arithmetic framing slots
# (69.9%). Across class C, 244 of about 2,000 turns were too short. Use a
# conservative authored floor so raw teacher slots are not reported as rows.
CLASS_C_ADMISSION_RATE_FLOOR = 0.65
C1_ARITHMETIC_POOL_GROWTH = 16
DEFAULT_OUTPUT = RUNTIME / "datasets" / "sidekick-6000.jsonl"
DEFAULT_PROBE = RUNTIME / "probes" / "probe-v1.jsonl"


@dataclass
class CUnit:
    identity: str
    subject: str
    seed: dict[str, Any]
    framing_kind: str
    sub_kind: str
    reply: str = ""
    prior: list[dict[str, Any]] = field(default_factory=list)
    required_menu: list[str] = field(default_factory=list)
    c1_kind: str = ""


def class_targets(rows: int) -> dict[str, int]:
    """Wave-2 decision mix, with D held at its non-discretionary floor."""
    target = {
        "A": round(rows * 0.25),
        "B": round(rows * 0.15),
        "C": round(rows * 0.40),
        "D": round(rows * 0.20),
    }
    if sum(target.values()) != rows:
        target["A"] += rows - sum(target.values())
    return target


def class_c_targets(rows: int) -> dict[str, int]:
    """Controlled C trim; at C=2400 this is 960/400/200/480/360."""
    target = {
        "C3": round(rows * 0.40),
        "C1_arithmetic": round(rows / 6),
        "C1_definition": round(rows / 12),
        "C4": round(rows * 0.20),
    }
    target["C2"] = rows - sum(target.values())
    return target


def require_capacity(label: str, target: int, available: int) -> None:
    """Refuse a trim whose admitted pool cannot meet its exact target."""
    if available < target:
        raise RuntimeError(f"{label}: target {target}, available {available}")


def require_exact(label: str, target: int, available: int) -> None:
    """Refuse an output census that differs from its exact target."""
    if available != target:
        raise RuntimeError(f"{label}: target {target}, available {available}")


def discounted_capacity(raw_slots: int) -> int:
    """Return the conservative number of admitted rows planned from slots."""
    return math.floor(raw_slots * CLASS_C_ADMISSION_RATE_FLOOR)


def subjects_for_discounted_target(target: int) -> int:
    """Return subjects needed for `target` after the class-C admission floor."""
    return math.ceil(target / (PER_SUBJECT * CLASS_C_ADMISSION_RATE_FLOOR))


def planned_framing_slots(
    units: Sequence[tuple[str, Sequence[tuple[str, str, dict[str, Any]]], str, int]],
    cache: dict[str, Any],
) -> tuple[dict[str, int], dict[str, int]]:
    """Count actual cached turns and requested turns for uncached subjects."""
    by_identity: dict[str, int] = {}
    source_totals = {"cached": 0, "requested": 0}
    for _, group, kind, requested in units:
        key = f"framing:{kind}:" + "|".join(identity for identity, _, _ in group)
        stored = cache.get(key)
        if not isinstance(stored, dict):
            for identity, _, _ in group:
                by_identity[identity] = requested
                source_totals["requested"] += requested
            continue
        if len(group) == 1:
            identity = group[0][0]
            turns = stored.get("turns", [])
            count = sum(isinstance(turn, str) for turn in turns) if isinstance(turns, list) else 0
            by_identity[identity] = count
            source_totals["cached"] += count
            continue
        body = stored.get("subjects", {})
        for identity, _, _ in group:
            turns = body.get(identity, []) if isinstance(body, dict) else []
            count = sum(isinstance(turn, str) for turn in turns) if isinstance(turns, list) else 0
            by_identity[identity] = count
            source_totals["cached"] += count
    return by_identity, source_totals



def map_bounded(
    executor: ThreadPoolExecutor, function: Any, items: Sequence[Any], deadline_s: float, label: str
) -> list[Any]:
    """Run everything, but never let one hung call hold the build.

    A remote channel can accept a connection and then stall, and urllib's own
    timeout does not always fire on a trickling socket. The pass therefore
    carries its own deadline: whatever has finished is kept, the rest is
    abandoned and counted. An abandoned unit costs a few rows; a hung pass
    costs the run.
    """
    futures = {executor.submit(function, item): item for item in items}
    finished: list[Any] = []
    started = time.time()
    pending = set(futures)
    while pending and time.time() - started < deadline_s:
        done, pending = wait(pending, timeout=30, return_when=FIRST_COMPLETED)
        for future in done:
            try:
                finished.append(future.result())
            except Exception as exc:  # one unit's failure is not the pass's
                print(f"  {label}: a unit failed with {type(exc).__name__}", flush=True)
        if len(finished) % 50 == 0 and finished:
            print(f"  {label} {len(finished)}/{len(futures)}, {time.time() - started:.0f}s", flush=True)
    if pending:
        print(f"  {label}: abandoning {len(pending)} of {len(futures)} units at the "
              f"{deadline_s:.0f}s deadline", flush=True)
        for future in pending:
            future.cancel()
    return finished


def digest(call: Call, limit: int = 380) -> str:
    """A compact reading of one result, for the teacher to write against."""
    body = json.dumps(call.response, ensure_ascii=False, sort_keys=True)
    return body[:limit] + ("…" if len(body) > limit else "")


def relay(call: Call) -> str:
    """The class-D reply, bound to what the worker said. No teacher touches this.

    A teacher model writing relay prose can smuggle in the answer Hermes
    declined to give, which is the disqualifying failure being trained against.
    So the sentence is assembled from the worker's own refusal string or the
    abstention's own status, and asserts nothing else.
    """
    response = call.response
    if response.get("ok") is False:
        message = str(response.get("error", {}).get("message", "")).strip().rstrip(".")
        return f"Hermes will not answer that: {message}. I have nothing else on it."
    result = response.get("result")
    if result == [] or result == {}:
        return (
            "Hermes returns nothing for that, and an empty result is a declining to answer "
            "rather than a verdict that the work is right."
        )
    status = str(result.get("status", "")) if isinstance(result, dict) else ""
    if status:
        return (
            f"Hermes reports {words(status)} for that, so it holds nothing I can pass on. "
            "That is a limit of the record, not a judgement about the mathematics."
        )
    return "Hermes holds nothing for that, so there is nothing I can pass on."



def grounded_reply(triple: "Triple") -> str:
    """A reply built from the executed result, saying only what came back.

    The amendment binds the teacher to framings, where narrative is the point.
    A reply's job is narrower and harder to get right: it must assert nothing
    the result does not carry. Reading it off the result makes that true by
    construction, and the grounding gate still checks it afterwards.
    """
    last = triple.calls[-1]
    result = last.response.get("result")
    seed = triple.narrative_seed
    kind = triple.sub_kind
    if kind == "trace" and isinstance(result, dict):
        expected = result.get("expected")
        method = seed.get("method", "that method")
        if expected is not None:
            return f"Hermes runs {method} on that and reaches {expected}."
        return f"Hermes runs {method} on that and returns its recorded trace."
    if kind == "diagnose" and isinstance(result, list) and result:
        row = result[0]
        return (
            f"Hermes matches the recorded error {words(str(row.get('description', '')))}, "
            f"filed as {row.get('source', 'a stored row')}. That is a candidate with a citation, "
            "not a diagnosis of the child."
        )
    if kind == "chart" and isinstance(result, dict):
        names = ", ".join(seed.get("anticipated", [])[:4])
        sections = "the recorded"
        if names:
            return f"The inventory for {seed.get('lesson', 'that lesson')} anticipates {names}, across {sections} sections."
        return f"The inventory for {seed.get('lesson', 'that lesson')} carries {sections} sections and names no anticipated method."
    if kind == "machine" and isinstance(result, dict):
        return (
            f"That machine holds {len(result.get('states', []))} states and "
            f"{len(result.get('edges', []))} transitions. A shared action name records a borrow, "
            "not an equivalence between methods."
        )
    if kind == "claim" and isinstance(result, dict):
        checks = result.get("checks") or []
        verdict = json.dumps(checks[0].get("verdict", checks[0])) if checks else ""
        return f"Checked against the reader rather than from memory: {verdict}."
    if kind == "search" and isinstance(result, dict):
        found = ", ".join(seed.get("found", [])[:3])
        return f"The stored rows that match are {found}. Each carries its own citation."
    if kind == "lookup" and isinstance(result, dict):
        described = "; ".join(seed.get("described", [])[:2])
        return f"Recorded {seed.get('domain', '')} errors on file include {described}."
    if kind == "inventory" and isinstance(result, dict):
        if "strategies" in result:
            names = ", ".join(row["name"].replace("_", " ") for row in result["strategies"][:4])
            return f"Hermes registers {result.get('matched', 0)} of them; the first few are {names}."
        if "lessons" in result:
            return f"Hermes can run {len(result['lessons'])} lessons end to end."
        counts = result.get("counts", {})
        return f"The catalog reports {json.dumps(counts)[:120]}."
    if kind in {"recognize", "repair_after_abstention"} and isinstance(result, list):
        names = [
            words(str(row.get("kind", row.get("candidate_strategy", {}).get("kind", ""))))
            for row in result[:3] if isinstance(row, dict)
        ]
        names = [name for name in names if name]
        if names:
            return f"Hermes returns {', '.join(names)} as candidate alignments, not diagnoses of the student."
        return "Hermes returns candidate alignments for that explanation, not a diagnosis of the student."
    if kind == "discover_then_trace":
        first = triple.calls[0].response.get("result", {})
        expected = (result or {}).get("expected") if isinstance(result, dict) else None
        return (
            f"Hermes registers {first.get('matched', 0)} {seed.get('operation', '')} methods on this page. "
            f"Running {seed.get('method', 'the first of them')} on its worked input reaches {expected}."
        )
    if kind == "search_then_lookup":
        return (
            f"The first matching row is {seed.get('name', 'the one on file')}, and its record is what "
            "Hermes returned for it."
        )
    if kind == "chart_then_detail":
        return (
            f"{seed.get('lesson', 'That lesson')} carries the sections Hermes listed, and its "
            f"{seed.get('section', 'first')} section returns its recorded contents."
        )
    if kind == "machine_then_borrows":
        borrows = (result or {}).get("totals", {}) if isinstance(result, dict) else {}
        return (
            f"The {seed.get('kind', 'machine')} runs as Hermes described, and it shares canonical "
            f"actions with others: {json.dumps(borrows)[:100]}. A borrow is a shared action name, "
            "not an equivalence."
        )
    return "Hermes returned that, and I am passing on only what it gave."


class Assembler:
    def __init__(self, server: HermesMCPServer, chat: GemmaChatFormat, teacher: Teacher, seed: int) -> None:
        self.server = server
        self.chat = chat
        self.teacher = teacher
        self.rng = random.Random(seed)
        self.tools = [tool for tool in server._public_tools if tool["name"] not in HELD_OUT_TOOLS]
        self.sha = worker_sha()
        self.counter = 0
        self.rejections: dict[str, int] = {}
        self.lock = threading.Lock()

    def reject(self, reason: str) -> None:
        with self.lock:
            self.rejections[reason] = self.rejections.get(reason, 0) + 1

    def identity(self, row_class: str) -> str:
        with self.lock:
            self.counter += 1
            return f"r-{row_class}-{self.counter:05d}"

    def menu(self, required: Sequence[str]) -> list[str]:
        with self.lock:
            chosen = sample_menu(self.tools, list(dict.fromkeys(required)), MENU_SIZE, self.rng)
        return [tool["name"] for tool in chosen]

    # ---- the teacher passes, batched and cached

    def framings_for(self, group: Sequence[tuple[str, str, dict[str, Any]]], kind: str, count: int) -> dict[str, list[str]]:
        """One call covers several subjects; the cache key names them all."""
        key = f"framing:{kind}:" + "|".join(identity for identity, _, _ in group)
        if len(group) == 1:
            identity, subject, seed = group[0]
            parsed = self.teacher.ask(key, framing_prompt(kind, subject, seed, count))
            turns = (parsed or {}).get("turns", []) if isinstance(parsed, dict) else []
            return {identity: [turn for turn in turns if isinstance(turn, str)]}
        blocks = "\n\n".join(
            f"SUBJECT {index + 1} (id {identity}): {subject}\n"
            f"Details: {json.dumps({k: v for k, v in seed.items() if v not in (None, '', [])}, ensure_ascii=False)}"
            for index, (identity, subject, seed) in enumerate(group)
        )
        single = framing_prompt(kind, "see the subjects below", {}, count)
        instruction = single.split("Write ")[0].split("Details: {}\n\n", 1)[-1]
        prompt = (
            f"{blocks}\n\n{instruction}\n\n"
            f"Write {count} different turns for EACH subject above. Reply exactly as "
            '{"subjects": {"<id>": ["turn", "turn"], "<id>": ["turn", "turn"]}}'
        )
        parsed = self.teacher.ask(key, prompt)
        found: dict[str, list[str]] = {}
        body = (parsed or {}).get("subjects", {}) if isinstance(parsed, dict) else {}
        for identity, _, _ in group:
            turns = body.get(identity, []) if isinstance(body, dict) else []
            found[identity] = [turn for turn in turns if isinstance(turn, str)]
        return found

    def replies_for(self, identity: str, subject: str, call: Call, count: int) -> list[str]:
        key = f"reply:{identity}"
        parsed = self.teacher.ask(key, reply_prompt(subject, digest(call), count), max_tokens=4000)
        replies = (parsed or {}).get("replies", []) if isinstance(parsed, dict) else []
        return [reply for reply in replies if isinstance(reply, str)]

    # ---- row assembly

    def rows_from(
        self,
        triple: Triple,
        turns: Sequence[str],
        replies: Sequence[str],
        framing_kind: str,
    ) -> list[Row]:
        rows: list[Row] = []
        answer_terms = self.answer_terms(triple)
        support = " ".join(
            [json.dumps(call.response, ensure_ascii=False, sort_keys=True) for call in triple.calls]
        )
        for index, turn in enumerate(turns):
            ok, why = admissible(turn, answer_terms)
            if not ok:
                self.reject(f"framing: {why}")
                continue
            if triple.sub_kind in {"recognize", "repair_after_abstention"}:
                content = str(triple.narrative_seed.get("student_said", "")).casefold()
                if content and content in turn.casefold():
                    self.reject("recognition framing copied the executed action wording")
                    continue
            if triple.row_class == "D":
                reply = relay(triple.calls[-1])
            else:
                reply = grounded_reply(triple)
                unsupported, _ = score_reply(reply, turn + " " + support, triple.row_class)
                if unsupported:
                    self.reject(f"reply asserts what the result does not carry: {unsupported[0]}")
                    continue
            rows.append(Row(
                id=self.identity(triple.row_class),
                row_class=triple.row_class,
                menu=self.menu([call.name for call in triple.calls]),
                user_turn=turn.strip(),
                calls=list(triple.calls),
                reply=reply.strip(),
                provenance={
                    **triple.provenance,
                    "framing": "teacher_31b",
                    "teacher_model": self.teacher.model,
                    "reply_source": "template_bound" if triple.row_class == "D" else "grounded_template",
                    "sub_kind": triple.sub_kind,
                    "triple": triple.id,
                    "framing_kind": framing_kind,
                },
            ))
        return rows

    @staticmethod
    def answer_terms(triple: Triple) -> list[str]:
        """What the turn must not already say, drawn from the executed result."""
        terms: list[str] = []
        for call in triple.calls:
            result = call.response.get("result")
            if isinstance(result, dict):
                expected = result.get("expected")
                if isinstance(expected, (str, int)):
                    terms.append(str(expected))
            if isinstance(result, list):
                for row in result[:3]:
                    if isinstance(row, dict) and isinstance(row.get("description"), str):
                        terms.append(words(row["description"]))
        return [term for term in terms if len(term) > 3]


def known_fact_items(count: int, rng: random.Random) -> list[dict[str, Any]]:
    """Arithmetic whose truth we hold before anyone writes a sentence about it."""
    items: list[dict[str, Any]] = []
    seen: set[str] = set()
    while len(items) < count:
        style = rng.choice(["sum", "product", "difference", "fraction_sum"])
        if style == "sum":
            a, b = rng.randint(11, 89), rng.randint(11, 89)
            term, truth, spoken = f"{a}+{b}={a + b}", str(a + b), f"{a} plus {b}"
        elif style == "product":
            a, b = rng.randint(2, 12), rng.randint(2, 12)
            term, truth, spoken = f"{a}*{b}={a * b}", str(a * b), f"{a} times {b}"
        elif style == "difference":
            a, b = rng.randint(30, 99), rng.randint(2, 29)
            term, truth, spoken = f"{a} - {b} = {a - b}", str(a - b), f"{a} take away {b}"
        else:
            d = rng.choice([3, 4, 5, 6, 8])
            term = f"1/{d} + 1/{d} = 2/{d}"
            truth, spoken = say_fraction(2, d), f"{say_fraction(1, d)} and {say_fraction(1, d)}"
        if term in seen:
            continue
        seen.add(term)
        items.append({"term": term, "truth": truth, "spoken": spoken})
    return items


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--triples", type=Path, default=RUNTIME / "datasets" / "triples.jsonl")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--probe", type=Path, default=DEFAULT_PROBE)
    parser.add_argument("--cache", type=Path, default=RUNTIME / "teacher" / "phase1.jsonl")
    parser.add_argument("--rows", type=int, default=6000)
    parser.add_argument("--workers", type=int, default=12)
    parser.add_argument("--seed", type=int, default=20260810)
    parser.add_argument("--limit-triples", type=int, default=0)
    parser.add_argument("--framing-deadline", type=int, default=5400)
    parser.add_argument("--reply-deadline", type=int, default=3600)
    parser.add_argument("--reexecute-sample", type=int, default=250)
    parser.add_argument("--offline", action="store_true", help="assemble from the teacher cache without opening the channel")
    parser.add_argument(
        "--plan-only", action="store_true",
        help="with --offline, verify pool arithmetic and report missing teacher units without assembling",
    )
    arguments = parser.parse_args()
    if arguments.plan_only and not arguments.offline:
        parser.error("--plan-only requires --offline")

    rng = random.Random(arguments.seed)
    triples = [Triple.from_dict(json.loads(line))
               for line in arguments.triples.read_text(encoding="utf-8").splitlines() if line.strip()]
    if arguments.limit_triples:
        triples = triples[: arguments.limit_triples]
    by_class: dict[str, list[Triple]] = {}
    for triple in triples:
        by_class.setdefault(triple.row_class, []).append(triple)
    print({key: len(value) for key, value in by_class.items()}, flush=True)

    target = class_targets(arguments.rows)
    c_target = class_c_targets(target["C"])
    chat = GemmaChatFormat()
    server = HermesMCPServer("core", REPO_ROOT)
    teacher = Teacher(arguments.cache, dry_run=arguments.offline)
    assembler = Assembler(server, chat, teacher, arguments.seed)
    started = time.time()

    # ---- class C: no triple, but the same teacher and the same gates.
    c_rng = random.Random(arguments.seed ^ 0xC240)
    # Preserve the seed-stable 204-subject pool and append new identities. The
    # checker-readable subtraction spelling above recovers its sound claims.
    arithmetic_subjects = (
        -(-c_target["C1_arithmetic"] // PER_SUBJECT) * 2
        + 4
        + C1_ARITHMETIC_POOL_GROWTH
    )
    known = known_fact_items(arithmetic_subjects, c_rng)
    c_units: list[CUnit] = []
    for index, item in enumerate(known):
        c_units.append(CUnit(
            identity=f"c1-{index:04d}", subject=f"the value of {item['spoken']}",
            seed=item, framing_kind="known_fact", sub_kind="C1",
            reply=f"{item['spoken'].capitalize()} is {item['truth']}.", c1_kind="arithmetic",
        ))
    for index, (term, definition) in enumerate(DEFINITION_PAIRS):
        c_units.append(CUnit(
            identity=f"c1d-{index:04d}", subject=f"the mathematical term {term}",
            seed={"term": term}, framing_kind="known_definition", sub_kind="C1",
            reply=definition, c1_kind="definition",
        ))
    scopes = list(BASE_OUT_OF_SCOPE_SCOPES + NEW_OUT_OF_SCOPE_SCOPES)
    faults = scope_faults(scopes)
    if faults:
        raise SystemExit(f"class-C2 scope names a core operation: {faults[0]}")
    for index, scope in enumerate(scopes):
        c_units.append(CUnit(
            identity=f"c2-{index:04d}", subject=scope, seed={"situation": scope},
            framing_kind="out_of_scope", sub_kind="C2",
        ))
    surface_pool = [
        t for t in by_class.get("A", [])
        if t.narrative_seed and t.sub_kind != "recognize"
        and "doubl" not in (t.subject + " " + json.dumps(t.narrative_seed)).casefold()
    ]
    surface_subjects = min(len(surface_pool), subjects_for_discounted_target(c_target["C3"]))
    surface_sources = c_rng.sample(surface_pool, surface_subjects)
    for triple in surface_sources:
        c_units.append(CUnit(
            identity=f"c3-{triple.id}", subject=triple.subject, seed=triple.narrative_seed,
            framing_kind="surface", sub_kind="C3",
        ))

    c4_pool = [
        t for t in by_class.get("A", [])
        if t.sub_kind == "trace" and t.calls
        and isinstance(t.calls[-1].response.get("result"), dict)
        and t.calls[-1].response["result"].get("expected") is not None
    ]
    c4_subjects = min(len(c4_pool), subjects_for_discounted_target(c_target["C4"]))
    for triple in c_rng.sample(c4_pool, c4_subjects):
        call = triple.calls[-1]
        expected = str(call.response["result"]["expected"])
        strategy = str(call.arguments.get("strategy", "that strategy"))
        prior = conversation(
            f"Run {words(strategy)} for me on its worked input.",
            [call.to_dict()],
            f"Hermes reports {expected}.",
        )
        c_units.append(CUnit(
            identity=f"c4-{triple.id}", subject="the result already supplied in the preceding turn",
            seed={"answer": expected}, framing_kind="already_answered", sub_kind="C4",
            reply=f"It came out to {expected}.", prior=prior, required_menu=["strategy_trace"],
        ))

    capacity = {
        "C1_arithmetic": sum(u.c1_kind == "arithmetic" for u in c_units) * PER_SUBJECT,
        "C1_definition": sum(u.c1_kind == "definition" for u in c_units) * PER_SUBJECT,
        "C2": sum(u.sub_kind == "C2" for u in c_units) * PER_SUBJECT,
        "C3": sum(u.sub_kind == "C3" for u in c_units) * PER_SUBJECT,
        "C4": sum(u.sub_kind == "C4" for u in c_units) * PER_SUBJECT,
    }
    print(json.dumps({"wave2_targets": target, "class_c_targets": c_target,
                      "class_c_authored_slot_ceiling": capacity}, sort_keys=True), flush=True)

    # ---- the core validates its own class-C1 data, out of process
    terms = [
        unit.seed["term"] for unit in c_units
        if unit.c1_kind == "arithmetic" and unit.seed.get("term")
    ]
    validated: dict[str, bool] = {}
    if terms:
        import subprocess

        terms_path = arguments.cache.parent / "c1-terms.json"
        holds_path = arguments.cache.parent / "c1-validated.jsonl"
        terms_path.parent.mkdir(parents=True, exist_ok=True)
        terms_path.write_text(json.dumps(terms), encoding="utf-8")
        try:
            subprocess.run(
                [sys.executable, str(SCRIPT_DIR / "validate_claims.py"),
                 "--terms", str(terms_path), "--out", str(holds_path)],
                timeout=300, check=False,
            )
        except subprocess.TimeoutExpired:
            print("  C1 validation hit its wall clock; keeping what it wrote", flush=True)
        if holds_path.is_file():
            for line in holds_path.read_text(encoding="utf-8").splitlines():
                if line.strip():
                    row = json.loads(line)
                    validated[row["term"]] = bool(row["holds"])
        print(f"  C1 claims: {sum(validated.values())} of {len(terms)} check out against the core",
              flush=True)

    # ---- batch every teacher unit, then run them through the pool.
    units: list[tuple[str, Sequence[tuple[str, str, dict[str, Any]]], str, int]] = []
    framing_kind_by_id: dict[str, str] = {}
    plan = [
        ("A", by_class.get("A", []), target["A"]),
        ("B", by_class.get("B", []), target["B"]),
        ("D", by_class.get("D", []), target["D"]),
    ]
    per_triple: dict[str, int] = {}
    for row_class, pool, wanted in plan:
        if not pool:
            continue
        per_triple[row_class] = max(2, min(6, -(-wanted // max(1, len(pool))) + 1))
    for row_class, pool, wanted in plan:
        if not pool:
            continue
        recognition = [
            triple for triple in pool
            if triple.sub_kind in {"recognize", "repair_after_abstention"}
        ]
        multi_relay = [triple for triple in pool if triple.sub_kind == "multi_call_relay"]
        ordinary = [
            triple for triple in pool
            if triple not in recognition and triple not in multi_relay
        ]
        for segment_name, segment in (
            ("base", ordinary), ("recognize", recognition), ("multi_relay", multi_relay)
        ):
            for start in range(0, len(segment), SUBJECTS_PER_CALL):
                group = segment[start : start + SUBJECTS_PER_CALL]
                identities = "|".join(t.id for t in group)
                if segment_name == "recognize":
                    kind = "recognize"
                elif segment_name == "multi_relay":
                    kind = "limit"
                else:
                    allowed = (("narrative", "direct") if row_class != "D"
                               else ("limit", "narrative"))
                    cached_kind = next(
                        (candidate for candidate in allowed
                         if f"framing:{candidate}:{identities}" in teacher.cache), None
                    )
                    if cached_kind:
                        kind = cached_kind
                    elif row_class == "A":
                        kind = "narrative"
                    elif row_class == "D":
                        kind = "limit"
                    else:
                        kind = "narrative" if (start // SUBJECTS_PER_CALL) % 5 < 3 else "direct"
                recorded_kind = "narrative" if kind == "recognize" else kind
                for triple in group:
                    framing_kind_by_id[triple.id] = recorded_kind
                units.append((
                    f"{row_class}:{segment_name}:{start}",
                    [(t.id, t.subject, t.narrative_seed) for t in group],
                    kind,
                    5 if any(
                        triple.sub_kind in {"repair_after_abstention", "multi_call_relay"}
                        for triple in group
                    ) else per_triple[row_class],
                ))
    for kind in ("known_fact", "known_definition", "out_of_scope", "surface", "already_answered"):
        kind_units = [unit for unit in c_units if unit.framing_kind == kind]
        for start in range(0, len(kind_units), SUBJECTS_PER_CALL):
            group = kind_units[start : start + SUBJECTS_PER_CALL]
            for unit in group:
                framing_kind_by_id[unit.identity] = kind
            units.append((
                f"C:{kind}:{start}",
                [(unit.identity, unit.subject, unit.seed) for unit in group],
                kind,
                PER_SUBJECT,
            ))

    missing_framing_units = [
        {"kind": kind, "subjects": [identity for identity, _, _ in group]}
        for _, group, kind, _ in units
        if f"framing:{kind}:" + "|".join(identity for identity, _, _ in group) not in teacher.cache
    ]
    print(f"{len(units)} teacher framing batches; {len(teacher.cache)} entries already cached; "
          f"{len(missing_framing_units)} framing calls await the teacher", flush=True)
    if arguments.plan_only:
        c_framing_units = [unit for unit in units if unit[0].startswith("C:")]
        framing_slots, framing_slot_sources = planned_framing_slots(c_framing_units, teacher.cache)
        raw_capacity = {
            "C1_arithmetic": sum(
                framing_slots.get(unit.identity, 0)
                for unit in c_units
                if unit.c1_kind == "arithmetic" and validated.get(unit.seed.get("term", ""), False)
            ),
            "C1_definition": sum(
                framing_slots.get(unit.identity, 0)
                for unit in c_units if unit.c1_kind == "definition"
            ),
            "C2": sum(framing_slots.get(unit.identity, 0) for unit in c_units if unit.sub_kind == "C2"),
            "C3": sum(framing_slots.get(unit.identity, 0) for unit in c_units if unit.sub_kind == "C3"),
            "C4": sum(framing_slots.get(unit.identity, 0) for unit in c_units if unit.sub_kind == "C4"),
        }
        margin_discounted_capacity = {
            key: discounted_capacity(slots) for key, slots in raw_capacity.items()
        }
        short = {
            key: c_target[key] - margin_discounted_capacity[key]
            for key in c_target if margin_discounted_capacity[key] < c_target[key]
        }
        planned_reply_rows = sum(
            framing_slots.get(unit.identity, 0)
            for unit in c_units if unit.sub_kind in {"C2", "C3"}
        )
        planned_reply_calls = -(-planned_reply_rows // 6)
        plan_summary = {
            "mode": "offline_plan",
            "class_census": target,
            "within_class_census": {
                "A_recognize": 180,
                "B_repair_after_abstention": 225,
                "D_multi_call_relay": 360,
            },
            "class_c_subkind_census": c_target,
            "class_c_admission_rate_floor": CLASS_C_ADMISSION_RATE_FLOOR,
            "raw_slot_capacity": raw_capacity,
            "margin_discounted_capacity": margin_discounted_capacity,
            "framing_slot_sources": framing_slot_sources,
            "authored_pools": {
                "definition_pairs": len(DEFINITION_PAIRS),
                "base_out_of_scope_scopes": len(BASE_OUT_OF_SCOPE_SCOPES),
                "new_out_of_scope_scopes": len(NEW_OUT_OF_SCOPE_SCOPES),
            },
            "teacher": {
                "framing_batches_total": len(units),
                "framing_calls_awaiting": len(missing_framing_units),
                "c2_c3_reply_rows_planned": planned_reply_rows,
                "c2_c3_reply_calls_awaiting": planned_reply_calls,
                "total_calls_awaiting": len(missing_framing_units) + planned_reply_calls,
            },
            "short": short,
        }
        print("OFFLINE PLAN " + json.dumps(plan_summary, sort_keys=True), flush=True)
        teacher.close()
        server.close()
        return 1 if short else 0
    framings: dict[str, list[str]] = {}
    done = 0

    def work(unit: tuple[str, Sequence[tuple[str, str, dict[str, Any]]], str, int]) -> dict[str, list[str]]:
        _, group, kind, count = unit
        return assembler.framings_for(group, kind, count)

    pool_executor = ThreadPoolExecutor(max_workers=arguments.workers)
    for found in map_bounded(pool_executor, work, units, float(arguments.framing_deadline), "framings"):
        framings.update(found)
        done += 1
    pool_executor.shutdown(wait=False, cancel_futures=True)

    replies: dict[str, list[str]] = {}

    # ---- assemble
    rows: list[Row] = []
    for triple in triples:
        turns = framings.get(triple.id, [])
        if not turns:
            assembler.reject("no admissible framing was returned")
            continue
        rows.extend(assembler.rows_from(
            triple, turns, replies.get(triple.id, []), framing_kind_by_id.get(triple.id, "")
        ))

    # class C rows, with C1 validated by the symbolic core
    c_rows: list[Row] = []
    for unit in c_units:
        turns = framings.get(unit.identity, [])
        for turn in turns:
            forbidden = [str(unit.seed.get("answer", ""))] if unit.sub_kind == "C4" else []
            ok, why = admissible(turn, forbidden)
            if not ok:
                assembler.reject(f"framing: {why}")
                continue
            if unit.c1_kind == "arithmetic":
                # The core checked these in a child process before assembly; a
                # claim it could not read, or never reached, is not admitted.
                if not validated.get(unit.seed.get("term", ""), False):
                    assembler.reject("C1 claim did not check out against the core")
                    continue
            reply = unit.reply
            c_rows.append(Row(
                id=assembler.identity("C"),
                row_class="C",
                menu=assembler.menu(unit.required_menu),
                user_turn=turn.strip(),
                calls=[],
                reply=reply,
                prior=list(unit.prior),
                provenance={
                    "source": f"authored class {unit.sub_kind} subject with a teacher framing",
                    "row": unit.identity, "executed_at": now(), "worker_sha": assembler.sha,
                    "framing": "teacher_31b", "teacher_model": teacher.model,
                    "reply_source": "authored" if unit.sub_kind in {"C1", "C4"} else "teacher_31b",
                    "sub_kind": unit.sub_kind,
                    "c1_kind": unit.c1_kind,
                    "framing_kind": framing_kind_by_id.get(unit.identity, ""),
                    "checked_by": "check_math_claim" if unit.c1_kind == "arithmetic" else "",
                },
            ))

    # C2 and C3 replies come from the teacher, one batch per row group
    pending = [row for row in c_rows if not row.reply]
    planned_c_reply_rows = sum(
        PER_SUBJECT for unit in c_units if unit.sub_kind in {"C2", "C3"}
    )
    planned_c_reply_calls = -(-planned_c_reply_rows // 6)
    print(f"class-C2/C3 reply plan: up to {planned_c_reply_rows} rows in "
          f"{planned_c_reply_calls} teacher calls after framing admission", flush=True)
    done = 0

    def c_reply_batch(group: Sequence[Row]) -> list[tuple[str, str]]:
        key = "creply:" + "|".join(row.id for row in group)
        listing = "\n".join(f"{index + 1}. {row.user_turn}" for index, row in enumerate(group))
        parsed = teacher.ask(key, (
            f"A teacher wrote each of these:\n{listing}\n\n"
            "Write one short, practical reply to each, in order. Two sentences at most each. "
            "Do not look anything up, do not mention tools, and do not invent numbers or records.\n"
            '{"replies": ["reply to 1", "reply to 2"]}'
        ), max_tokens=3000)
        found = (parsed or {}).get("replies", []) if isinstance(parsed, dict) else []
        return [
            (row.id, str(found[index]) if index < len(found) and isinstance(found[index], str) else "")
            for index, row in enumerate(group)
        ]

    groups = [pending[start:start + 6] for start in range(0, len(pending), 6)]
    missing_reply_groups = sum(
        1 for group in groups
        if "creply:" + "|".join(row.id for row in group) not in teacher.cache
    )
    print(f"class-C2/C3 reply batches: {len(groups)} total; "
          f"{missing_reply_groups} calls await the teacher", flush=True)
    by_id: dict[str, str] = {}
    pool_executor = ThreadPoolExecutor(max_workers=arguments.workers)
    for found in map_bounded(pool_executor, c_reply_batch, groups, float(arguments.reply_deadline), "class C replies"):
        for identity, text in found:
            by_id[identity] = text
        done += 1
    pool_executor.shutdown(wait=False, cancel_futures=True)
    for row in c_rows:
        if not row.reply:
            row.reply = by_id.get(row.id, "").strip()
    checked_c_rows: list[Row] = []
    for row in c_rows:
        if not row.reply.strip():
            continue
        if row.provenance.get("sub_kind") in {"C2", "C3"}:
            unsupported, _ = score_reply(row.reply, row.user_turn, row.row_class)
            if unsupported:
                assembler.reject(f"class-C reply asserts outside the turn: {unsupported[0]}")
                continue
        checked_c_rows.append(row)
    c_rows = checked_c_rows
    rows.extend(c_rows)

    # ---- trim to the mix, then gate
    trimmed: list[Row] = []
    special_targets = {
        "A": ("recognize", 180),
        "B": ("repair_after_abstention", 225),
        "D": ("multi_call_relay", 360),
    }
    for row_class in ("A", "B", "D"):
        wanted = target[row_class]
        pool = [row for row in rows if row.row_class == row_class]
        special_kind, special_wanted = special_targets[row_class]
        special = [row for row in pool if row.provenance.get("sub_kind") == special_kind]
        ordinary = [row for row in pool if row.provenance.get("sub_kind") != special_kind]
        rng.shuffle(special)
        rng.shuffle(ordinary)
        require_capacity(
            f"class {row_class} sub-kind {special_kind}", special_wanted, len(special)
        )
        ordinary_wanted = wanted - special_wanted
        require_capacity(f"class {row_class} base", ordinary_wanted, len(ordinary))
        trimmed.extend(special[:special_wanted])
        trimmed.extend(ordinary[:ordinary_wanted])
    c_buckets: dict[str, list[Row]] = {key: [] for key in c_target}
    for row in (row for row in rows if row.row_class == "C"):
        sub_kind = str(row.provenance.get("sub_kind", ""))
        if sub_kind == "C1":
            key = f"C1_{row.provenance.get('c1_kind', '')}"
        else:
            key = sub_kind
        if key in c_buckets:
            c_buckets[key].append(row)
        else:
            assembler.reject(f"unknown class-C trim bucket {key or '<empty>'}")
    for key, wanted in c_target.items():
        pool = c_buckets[key]
        rng.shuffle(pool)
        require_capacity(f"class C sub-kind {key}", wanted, len(pool))
        trimmed.extend(pool[:wanted])
    candidate_census = {
        "classes": {key: sum(row.row_class == key for row in trimmed) for key in ("A", "B", "C", "D")},
        "within_class": {
            sub_kind: sum(row.provenance.get("sub_kind") == sub_kind for row in trimmed)
            for sub_kind, _ in special_targets.values()
        },
        "class_c": {
            key: min(len(c_buckets[key]), wanted) for key, wanted in c_target.items()
        },
    }
    print("trimmed candidate census " + json.dumps(candidate_census, sort_keys=True), flush=True)
    rng.shuffle(trimmed)

    held_out = None
    if arguments.probe.is_file():
        held_out = {row.id: row.user_turn for row in read_rows(arguments.probe)}
    holder = WorkerHolder(lambda: HermesMCPServer("core", REPO_ROOT))
    report = run_gates(trimmed, server=server, chat=chat, overlap=OverlapGate(), tools={
        tool["name"]: tool for tool in server._public_tools
    }, held_out=held_out, held_out_label=arguments.probe.name, holder=holder,
       reexecute_sample=arguments.reexecute_sample)
    for row in trimmed:
        row.gates = report.per_row.get(row.id, {})
    failed = {failure["id"] for failure in report.failures}
    kept = [row for row in trimmed if row.id not in failed]

    over_length = []
    for row in list(kept):
        rendered = chat.render(row.messages(), [
            tool for tool in server._public_tools if tool["name"] in row.menu
        ])
        if len(rendered.ids) > 4096:
            over_length.append(row.id)
    if over_length:
        kept = [row for row in kept if row.id not in set(over_length)]

    # Gates and the length ceiling can only remove rows. Recheck the exact
    # decision mix before writing so a successful process cannot leave an
    # off-mix artifact.
    for row_class, (sub_kind, wanted) in special_targets.items():
        require_exact(
            f"class {row_class} sub-kind {sub_kind} after gates",
            wanted,
            sum(
                row.row_class == row_class and row.provenance.get("sub_kind") == sub_kind
                for row in kept
            ),
        )
    for key, wanted in c_target.items():
        require_exact(
            f"class C sub-kind {key} after gates",
            wanted,
            sum(
                row.row_class == "C" and (
                    (row.provenance.get("sub_kind") == "C1"
                     and key == f"C1_{row.provenance.get('c1_kind', '')}")
                    or row.provenance.get("sub_kind") == key
                )
                for row in kept
            ),
        )
    for row_class, wanted in target.items():
        require_exact(
            f"class {row_class} after gates",
            wanted,
            sum(row.row_class == row_class for row in kept),
        )

    path = write(kept, arguments.output)
    summary = report.summary()
    framing_kinds_complete = all(
        row.provenance.get("framing_kind") in {"narrative", "direct"}
        for row in kept if row.row_class == "A"
    )
    summary.update({
        "written": len(kept),
        "dropped_by_gate": len(failed),
        "dropped_over_4096": len(over_length),
        "teacher": {
            "model": teacher.model, "calls": teacher.calls, "usage": teacher.usage,
            "cache": str(arguments.cache), "channel_failures": len(teacher.failures),
            "first_failures": teacher.failures[:5],
        },
        "teacher_generation_plan": {
            "framing_batches_total": len(units),
            "framing_calls_awaiting": len(missing_framing_units),
            "c2_c3_reply_rows_planned": planned_c_reply_rows,
            "c2_c3_reply_calls_planned": planned_c_reply_calls,
            "c2_c3_reply_calls_awaiting_after_framings": missing_reply_groups,
        },
        "class_c_subject_capacity": capacity,
        "rejections": assembler.rejections,
        "worker_stalls_during_reexecution": holder.stalls,
        "class_counts_written": {
            row_class: sum(1 for row in kept if row.row_class == row_class)
            for row_class in ("A", "B", "C", "D")
        },
        "wave2_subkind_counts_written": {
            sub_kind: sum(row.provenance.get("sub_kind") == sub_kind for row in kept)
            for sub_kind in ("recognize", "repair_after_abstention", "multi_call_relay")
        },
        "class_c_counts_written": {
            key: sum(
                1 for row in kept if row.row_class == "C" and (
                    (row.provenance.get("sub_kind") == "C1"
                     and key == f"C1_{row.provenance.get('c1_kind', '')}")
                    or (row.provenance.get("sub_kind") == key)
                )
            ) for key in c_target
        },
        "framing_kind_recorded_class_a": framing_kinds_complete,
        "path": str(path), "dataset_sha": dataset_sha(path), "worker_sha": worker_sha(),
        "elapsed_s": round(time.time() - started, 1),
    })
    if framing_kinds_complete:
        summary["narrative_share_class_a"] = round(sum(
            1 for row in kept
            if row.row_class == "A" and row.provenance.get("framing_kind") == "narrative"
        ) / max(1, sum(1 for row in kept if row.row_class == "A")), 3)
    (path.parent / f"{path.stem}-gates.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary, indent=2), flush=True)
    teacher.close()
    server.close()
    sys.stdout.flush()
    sys.stderr.flush()
    # Every artifact is written. A worker thread still blocked on a stalled
    # socket must not hold the exit.
    import os

    os._exit(0 if kept else 1)


if __name__ == "__main__":
    raise SystemExit(main())
