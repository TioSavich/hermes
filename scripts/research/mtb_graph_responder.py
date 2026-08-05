#!/usr/bin/env python3
"""mistake_location answered from the deformation graph alone.

The model reads one thing: `docs/research/assets/automata/full_graph.json`,
rendered as a catalog of the 222 computational machines — each machine's
ordered actions, with the deforming ones marked. No misconception corpus,
no Prolog adjudication, no arithmetic checking. The question the run asks
is narrow: when a student's written work is set beside a catalog of known
deformations, how often does a small checkpoint find a match it can pin to
the right numbered step?

Three constraints shape the reply, and each answers a measured failure:

* An accusation needs a named machine from the catalog. A step that merely
  looks wrong licenses nothing. This is the gate the 08-02 run lacked,
  where eight of nine accusations came from transcription damage.
* Silence is the default. On this benchmark the items divide evenly
  between erroneous and correct solutions, so accusing a correct solution
  is the only move that costs a point; accusing an erroneous one at the
  wrong step costs nothing. Caution is therefore free where it matters.
* A matched deformation still has to be located. A machine's internal
  action order is its own; it is not the student's step numbering, and the
  two are related only by what the student wrote.

The reply is parsed here rather than by the benchmark's first-integer
regex, because thinking is on and any stray numeral in a stray sentence
would otherwise become the answer.

This arm sees no worked examples. The unassisted arm receives the config's
few-shot samples and this one does not, so the two are not a controlled
pair; what is measured here is what the catalog alone supports.
"""
from __future__ import annotations

import collections
import hashlib
import json
import re
from pathlib import Path
from typing import Any

import mtb_responders

REPO_ROOT = Path(__file__).resolve().parents[2]
GRAPH_PATH = REPO_ROOT / "docs/research/assets/automata/full_graph.json"

LEGEND = """\
You are given the machine catalog below, and nothing else. It records 222
small machines. Each machine is one way of doing a piece of mathematics,
written as an ordered run of actions. A machine named after a loss
(for example append_column_sum_without_carrying) is a way the work goes
wrong; a machine named after a method (for example column_addition_with_
carrying) is a way it goes right.

An action written with a leading ! is a DEFORMING action: at that action
the machine loses something the work needed. An action written plainly
either conserves what the work needed or is neutral about it.

Machines are named family/kind. The families are ordered by level:
0 counting; 1 addition, subtraction; 2 multiplication, division;
3 measurement, geometry; 4 fraction, decimal, integer;
5 ratio, probability, statistics; 6 algebraic; 7 calculus.
"""

INSTRUCTION = """\
A student has written a numbered solution. Decide whether the student's
written work matches a deformation in the catalog above.

Answer with exactly two lines and nothing else:

MACHINE: family/kind
STEP: n

Rules.

1. Write MACHINE: NONE and STEP: 0 unless the student's work matches a
   machine in the catalog that has a ! action, and the student's work
   actually carries out that ! action. The machine must be one you can
   name from the catalog. A step that looks wrong, or that you cannot tie
   to a catalog machine, is not a match.

2. When you are unsure, answer NONE and 0. Staying quiet is the right
   answer far more often than accusing. Do not accuse to be helpful.

3. If and only if you have a match, decide which numbered step of the
   STUDENT's solution carries the ! action. The machine's own action
   order is not the student's step numbering: a machine may spend three
   actions on what the student wrote as one step, or the student may spend
   four steps before reaching the action that deforms. Re-read the
   student's numbered steps and choose the number beside the line where
   the deforming action is actually carried out. Do not report the
   position of the action inside the machine.

4. STEP must be a step number the student actually wrote.
"""

REPLY_MACHINE = re.compile(r"MACHINE\s*:\s*([A-Za-z0-9_/]+)")
REPLY_STEP = re.compile(r"STEP\s*:\s*(\d+)")
STEP_NUMBER = re.compile(r"^\s*Step\s+(\d+)\s*-", re.IGNORECASE)


def _ordered_edges(edges: list[dict], index: dict[str, int]) -> list[dict]:
    """Edges in the machine's own running order."""
    return sorted(edges, key=lambda edge: (index.get(edge["from"], 0),
                                           index.get(edge["to"], 0),
                                           edge["id"]))


def _machine_line(machine: str, edges: list[dict],
                  index: dict[str, int]) -> str:
    """One catalog entry.

    A machine whose states run in a single line is written as a chain,
    which is how 214 of the 222 read. The eight that branch are written
    edge by edge instead, because a chain would flatten a choice into a
    sequence and claim an order the transition table does not have.
    """
    ordered = _ordered_edges(edges, index)
    fan = collections.Counter(edge["from"] for edge in ordered)
    mark = lambda edge: ("!" if edge["stance"] == "deforming" else "")
    if any(count > 1 for count in fan.values()):
        body = "; ".join(
            f"{edge['from'].rsplit(':', 1)[1]}->{edge['to'].rsplit(':', 1)[1]} "
            f"{mark(edge)}{edge['local_action']}" for edge in ordered)
        return f"{machine} [branching]: {body}"
    body = " > ".join(f"{mark(edge)}{edge['local_action']}"
                      for edge in ordered)
    return f"{machine}: {body}"


def build_catalog(graph_path: Path = GRAPH_PATH,
                  scope: str = "all") -> tuple[str, set[str], set[str]]:
    """Render the graph as the catalog the model reads.

    `scope` chooses how much of it is rendered. `all` writes every machine,
    which gives the model a contrast class: work matching a machine with no
    deforming action is work done a known correct way. `deforming` writes
    only the 98 machines that carry a deforming action, which is what the
    accusation rule actually consults and costs less than half the tokens.
    Which one a small checkpoint can hold is measured, not assumed.

    Returns the catalog text, every machine name in it, and the subset that
    carries at least one deforming action. The second set is the gate: an
    accusation naming a machine outside it is not licensed by the graph.
    """
    graph = json.loads(graph_path.read_text(encoding="utf-8"))
    index = {node["id"]: node.get("formal_index", 0) for node in graph["nodes"]}
    by_machine: dict[str, list[dict]] = collections.defaultdict(list)
    for edge in graph["edges"]:
        by_machine[edge["machine"]].append(edge)

    deforming = {machine for machine, edges in by_machine.items()
                 if any(edge["stance"] == "deforming" for edge in edges)}
    if scope == "deforming":
        written = sorted(deforming)
    elif scope == "all":
        written = sorted(by_machine)
    else:
        raise SystemExit(f"unknown catalog scope {scope!r}; have: all, deforming")

    lines = [_machine_line(machine, by_machine[machine], index)
             for machine in written]
    return "\n".join(lines), set(written), deforming & set(written)


def _student_steps(solution: str) -> list[str]:
    return [part for part in solution.split("\\n") if part.strip()]


def solution_key(solution: str) -> str:
    """A label for the solution text, not an identifier for the item.

    The item set repeats: 2004 items carry 1224 distinct solutions, and 111
    of the repeats are annotated with different erroneous steps. The key
    marks those collisions so they can be counted; it cannot separate them,
    which is why the working record travels on the item's own row rather
    than in a file that would have to be joined back.
    """
    return hashlib.sha1(solution.encode("utf-8")).hexdigest()[:16]


def _written_numbers(steps: list[str]) -> set[int]:
    """The step numbers the student actually wrote."""
    numbers = set()
    for position, step in enumerate(steps, start=1):
        found = STEP_NUMBER.match(step)
        numbers.add(int(found.group(1)) if found else position)
    return numbers


def _graph_only(model: str, **options: str) -> mtb_responders.Responder:
    backend = options.get("backend", "ollama")
    endpoint = options.get("endpoint")
    # Probe 7890077: reasoning alone runs 1,000 to 2,100 tokens over this
    # catalog. At 1,600 the two lines were never reached on three items in
    # four and the reply came back empty, which reads as silence and is not.
    num_predict = int(options.get("num_predict", 4000))
    graph_path = Path(options.get("graph", str(GRAPH_PATH)))
    scope = options.get("scope", "all")

    catalog, names, deforming = build_catalog(graph_path, scope)
    preamble = f"{LEGEND}\n=== MACHINE CATALOG ===\n{catalog}\n=== END CATALOG ===\n"

    def respond(*, prompt: str, stop: list[str] | None,
                example: dict[str, Any], task_name: str) -> str:
        problem = example.get("question", "")
        solution = example.get("student_solution", "")
        steps = _student_steps(solution)
        allowed = _written_numbers(steps)
        record: dict[str, Any] = {
            "solution_key": solution_key(solution),
            "question_head": problem[:80], "steps": len(steps),
            "machine": None, "answer": "0", "gate": "none"}
        try:
            # The catalog leads every request byte for byte, so the server
            # reuses one cached prefix across items and pays for the
            # rendering once per slot.
            body = (f"{preamble}\n{INSTRUCTION}\n"
                    f"=== PROBLEM ===\n{problem}\n"
                    f"=== STUDENT SOLUTION ===\n" + "\n".join(steps) + "\n")
            reply = mtb_responders.complete(
                body, model=model, backend=backend, endpoint=endpoint,
                stop=None, num_predict=num_predict, stop_mode="post")
            record["reply"] = reply[-600:]

            named = REPLY_MACHINE.search(reply)
            stepped = REPLY_STEP.search(reply)
            machine = named.group(1).strip() if named else None
            record["machine"] = machine
            if machine is None:
                # No MACHINE line at all. A reply that never reached the
                # answer — a thinking budget spent before the two lines were
                # written — must not be read as a decision to stay quiet.
                record["gate"] = "unparsed" if reply.strip() else "empty"
            elif machine == "NONE" or not stepped:
                record["gate"] = "declined"
            elif machine not in names:
                # A machine name that is not in the catalog is invented, and
                # an invented match licenses nothing.
                record["gate"] = "machine_not_in_catalog"
            elif machine not in deforming:
                record["gate"] = "machine_carries_no_deformation"
            elif int(stepped.group(1)) not in allowed:
                # Reporting a step the student never wrote is the machine's
                # own numbering leaking through, which rule 3 forbids.
                record["gate"] = "step_not_written"
                record["claimed_step"] = int(stepped.group(1))
            else:
                record["gate"] = "accused"
                record["answer"] = str(int(stepped.group(1)))
        except Exception as error:  # a broken item must not sink the run
            record["responder_error"] = f"{type(error).__name__}: {error}"
        mtb_responders.emit(record)
        return record["answer"]

    return respond


mtb_responders.register("graph_only", _graph_only)
