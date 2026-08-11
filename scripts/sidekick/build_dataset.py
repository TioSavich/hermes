#!/usr/bin/env python3
"""Assemble the phase-1 training set: executed calls, narrative framings, gates.

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
import random
import sys
import threading
import time
from concurrent.futures import FIRST_COMPLETED, ThreadPoolExecutor, wait
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

MENU_SIZE = 8
PER_SUBJECT = 4
SUBJECTS_PER_CALL = 4
DEFAULT_OUTPUT = RUNTIME / "datasets" / "sidekick-6000.jsonl"
DEFAULT_PROBE = RUNTIME / "probes" / "probe-v1.jsonl"



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
        sections = len(result.get("sections", []))
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

    def rows_from(self, triple: Triple, turns: Sequence[str], replies: Sequence[str]) -> list[Row]:
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
                    "reply_source": "template_bound" if triple.row_class == "D" else "teacher_31b",
                    "sub_kind": triple.sub_kind,
                    "triple": triple.id,
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
            term, truth, spoken = f"{a}-{b}={a - b}", str(a - b), f"{a} take away {b}"
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
    arguments = parser.parse_args()

    rng = random.Random(arguments.seed)
    triples = [Triple.from_dict(json.loads(line))
               for line in arguments.triples.read_text(encoding="utf-8").splitlines() if line.strip()]
    if arguments.limit_triples:
        triples = triples[: arguments.limit_triples]
    by_class: dict[str, list[Triple]] = {}
    for triple in triples:
        by_class.setdefault(triple.row_class, []).append(triple)
    print({key: len(value) for key, value in by_class.items()}, flush=True)

    target = {
        "A": round(arguments.rows * 0.35),
        "B": round(arguments.rows * 0.20),
        "C": round(arguments.rows * 0.20),
        "D": round(arguments.rows * 0.25),
    }
    chat = GemmaChatFormat()
    server = HermesMCPServer("core", REPO_ROOT)
    teacher = Teacher(arguments.cache, dry_run=arguments.offline)
    assembler = Assembler(server, chat, teacher, arguments.seed)
    started = time.time()

    # ---- class C: no triple, but the same teacher and the same gates.
    known = known_fact_items(target["C"] // 6 + 4, rng)
    c_units: list[tuple[str, str, dict[str, Any], str]] = []
    for index, item in enumerate(known):
        c_units.append((f"c1-{index:04d}", f"the value of {item['spoken']}", item, "known_fact"))
    scopes = [
        "a group that will not settle after the launch", "a parent who wants nightly worksheets",
        "a colleague whose worksheets do the thinking", "a child who finishes in four minutes",
        "an observation by the principal next week", "running out of time before the share-out",
        "a student who cried during the quiz", "seating a group of four",
        "a co-teacher who talks over you", "asking for more planning time",
        "a family asking for extra practice", "a student who will not work with a partner",
    ]
    for index, scope in enumerate(scopes):
        c_units.append((f"c2-{index:04d}", scope, {"situation": scope}, "out_of_scope"))
    surface_sources = [t for t in by_class.get("A", []) if t.narrative_seed][: target["C"] // 2]
    for triple in surface_sources:
        c_units.append((f"c3-{triple.id}", triple.subject, triple.narrative_seed, "surface"))

    # ---- the core validates its own class-C1 data, out of process
    terms = [item["term"] for _, _, item, kind in c_units if kind == "known_fact" and item.get("term")]
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
        narrative_share = 0.75 if row_class == "A" else (0.6 if row_class == "B" else 0.5)
        for start in range(0, len(pool), SUBJECTS_PER_CALL):
            group = pool[start : start + SUBJECTS_PER_CALL]
            kind = "narrative" if rng.random() < narrative_share else (
                "limit" if row_class == "D" else "direct"
            )
            units.append((
                f"{row_class}:{start}",
                [(t.id, t.subject, t.narrative_seed) for t in group],
                kind,
                per_triple[row_class],
            ))
    for start in range(0, len(c_units), SUBJECTS_PER_CALL):
        group = c_units[start : start + SUBJECTS_PER_CALL]
        kinds = {unit[3] for unit in group}
        if len(kinds) > 1:
            for unit in group:
                units.append((f"C:{unit[0]}", [(unit[0], unit[1], unit[2])], unit[3], 4))
            continue
        units.append((
            f"C:{start}",
            [(unit[0], unit[1], unit[2]) for unit in group],
            group[0][3],
            4,
        ))

    print(f"{len(units)} teacher batches; {len(teacher.cache)} already cached", flush=True)
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
        rows.extend(assembler.rows_from(triple, turns, replies.get(triple.id, [])))

    # class C rows, with C1 validated by the symbolic core
    c_rows: list[Row] = []
    for identity, subject, seed, kind in c_units:
        turns = framings.get(identity, [])
        for turn in turns:
            ok, why = admissible(turn)
            if not ok:
                assembler.reject(f"framing: {why}")
                continue
            if kind == "known_fact":
                # The core checked these in a child process before assembly; a
                # claim it could not read, or never reached, is not admitted.
                if not validated.get(seed.get("term", ""), False):
                    assembler.reject("C1 claim did not check out against the core")
                    continue
                reply = f"{seed['spoken'].capitalize()} is {seed['truth']}."
                sub = "C1"
            elif kind == "out_of_scope":
                reply = ""
                sub = "C2"
            else:
                reply = ""
                sub = "C3"
            c_rows.append(Row(
                id=assembler.identity("C"),
                row_class="C",
                menu=assembler.menu([]),
                user_turn=turn.strip(),
                calls=[],
                reply=reply,
                provenance={
                    "source": f"authored class {sub} subject with a teacher framing",
                    "row": identity, "executed_at": now(), "worker_sha": assembler.sha,
                    "framing": "teacher_31b", "teacher_model": teacher.model,
                    "reply_source": "template_bound" if sub == "C1" else "teacher_31b",
                    "sub_kind": sub,
                    "checked_by": "check_math_claim" if sub == "C1" else "",
                },
            ))

    # C2 and C3 replies come from the teacher, one batch per row group
    pending = [row for row in c_rows if not row.reply]
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
    c_rows = [row for row in c_rows if row.reply.strip()]
    rows.extend(c_rows)

    # ---- trim to the mix, then gate
    trimmed: list[Row] = []
    for row_class, wanted in target.items():
        pool = [row for row in rows if row.row_class == row_class]
        rng.shuffle(pool)
        if len(pool) < wanted:
            assembler.reject(f"class {row_class} short by {wanted - len(pool)} rows")
        trimmed.extend(pool[:wanted])
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

    path = write(kept, arguments.output)
    summary = report.summary()
    summary.update({
        "written": len(kept),
        "dropped_by_gate": len(failed),
        "dropped_over_4096": len(over_length),
        "teacher": {
            "model": teacher.model, "calls": teacher.calls, "usage": teacher.usage,
            "cache": str(arguments.cache), "channel_failures": len(teacher.failures),
            "first_failures": teacher.failures[:5],
        },
        "rejections": assembler.rejections,
        "worker_stalls_during_reexecution": holder.stalls,
        "class_counts_written": {
            row_class: sum(1 for row in kept if row.row_class == row_class)
            for row_class in ("A", "B", "C", "D")
        },
        "narrative_share_class_a": round(sum(
            1 for row in kept if row.row_class == "A" and "narrative" in str(row.provenance.get("kind", "narrative"))
        ) / max(1, sum(1 for row in kept if row.row_class == "A")), 3),
        "path": str(path), "dataset_sha": dataset_sha(path), "worker_sha": worker_sha(),
        "elapsed_s": round(time.time() - started, 1),
    })
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
