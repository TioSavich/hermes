#!/usr/bin/env python3
"""One agent per item: survey the graph for a hypothesis, then test it.

Measured on the 2004-item set, the graph pass and a following re-reading
have opposite strengths. When they look at wrong work they name the exact
step 61.7% of the time, and they accuse correct work only 1.4% of the time.
What holds the score down is reach: the graph pass examined 15.3% of the
wrong solutions and passed silently over the rest. At the same quality,
full reach would score about 0.80.

So the two turns here are tuned in opposite directions, and the harness —
not the model — enforces which turn owns which decision.

**Turn one is for reach.** The model sees the 98 machines that carry an
error-producing action, and is asked which one could describe what this
student did. It is told to prefer naming one, because a later turn discards
wrong guesses and a guess never made cannot be recovered. Turn one cannot
accuse; its output is a hypothesis.

**Turn two is for restraint.** The model no longer sees the catalog. It
sees the item and, when turn one produced one, a single named claim to
test — with the instruction that the claim is often wrong and refusing it
is a normal answer. Turn two owns the accusation.

Every item reaches turn two, including those turn one had no hypothesis
for. That makes the arm a strict extension of the no-graph reading, and the
difference between them is what the graph contributed.

The earlier failure this avoids: an arm that showed the model all 222
machines and let it accuse directly scored below the naked model, because a
menu of named errors invites a match. Here the menu produces a claim the
next turn is asked to refuse.
"""
from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

import mtb_responders
from mtb_graph_responder import (GRAPH_PATH, build_catalog, _student_steps,
                                 _written_numbers)

SURVEY = """\
Below is a catalogue of {count} ways school mathematics goes wrong. Each
entry names a way of working and lists the actions in it that lose
something the work needed.

{catalog}

=== PROBLEM ===
{question}

=== STUDENT SOLUTION ===
{solution}

Which entry, if any, could describe what this student did?

Prefer to name one. A later check will test your answer and throw it out if
it is wrong, so a wrong guess costs little. A guess you never make cannot
be recovered. Name an entry whenever the student's work could plausibly be
an instance of it, even if you are unsure.

Answer with exactly two lines and nothing else:

MACHINE: family/kind
STEP: n

where n is the step you would look at first, or write MACHINE: NONE and
STEP: 0 only if no entry could apply at all.
"""

TEST_WITH_CLAIM = """\
There might be an error in this student's work. Identify the step.

Another reader looked at this work and thought the student may have done
this specific thing:

  {machine}
  which means: {shape}

Treat that as a claim to test, not as an answer. The reader is often wrong.
If the student did not do that thing, answer 0, even though the reader
thought otherwise.

Only name the step if you are 90% confident that there is an error. One of
the worst things a tutor can do is accuse a kid of being wrong when they
are actually right. It squashes creative problem solving.

=== PROBLEM ===
{question}

=== STUDENT SOLUTION ===
{solution}

Answer with one line and nothing else:
STEP: n
where n is the number of the step that carries the error, or
STEP: 0
if you are not confident there is one.
"""

TEST_ALONE = """\
There might be an error in this student's work. Identify the step.

Only name the step if you are 90% confident that there is one. One of the
worst things a tutor can do is accuse a kid of being wrong when they are
actually right. It squashes creative problem solving.

=== PROBLEM ===
{question}

=== STUDENT SOLUTION ===
{solution}

Answer with one line and nothing else:
STEP: n
where n is the number of the step that carries the error, or
STEP: 0
if you are not confident there is one.
"""

REPLY_MACHINE = re.compile(r"MACHINE\s*:\s*([A-Za-z0-9_/]+)")
REPLY_STEP = re.compile(r"STEP\s*:\s*(\d+)")


def deforming_shapes(graph_path: Path = GRAPH_PATH) -> dict[str, str]:
    """Each machine's error-producing actions, in the machine's own words."""
    catalog, _, _ = build_catalog(graph_path, "deforming")
    shapes = {}
    for line in catalog.splitlines():
        name, body = line.split(":", 1)
        marked = [part.strip().lstrip("!").replace("_", " ")
                  for part in re.split(r"[>;]", body)
                  if part.strip().startswith("!")]
        shapes[name.strip()] = ", then ".join(marked)
    return shapes


def _graph_agent(model: str, **options: str) -> mtb_responders.Responder:
    backend = options.get("backend", "ollama")
    endpoint = options.get("endpoint")
    survey_budget = int(options.get("survey_budget", 4000))
    test_budget = int(options.get("test_budget", 6000))
    graph_path = Path(options.get("graph", str(GRAPH_PATH)))

    catalog, names, _ = build_catalog(graph_path, "deforming")
    shapes = deforming_shapes(graph_path)

    def call(body: str, budget: int) -> str:
        return mtb_responders.complete(
            body, model=model, backend=backend, endpoint=endpoint,
            stop=None, num_predict=budget, stop_mode="post")

    def respond(*, prompt: str, stop: list[str] | None,
                example: dict[str, Any], task_name: str) -> str:
        question = example.get("question", "")
        steps = _student_steps(example.get("student_solution", ""))
        allowed = _written_numbers(steps)
        written = "\n".join(steps)
        record: dict[str, Any] = {"machine": None, "survey_step": None,
                                  "answer": "0", "gate": "none"}
        try:
            survey = call(SURVEY.format(count=len(names), catalog=catalog,
                                        question=question, solution=written),
                          survey_budget)
            named = REPLY_MACHINE.search(survey)
            stepped = REPLY_STEP.search(survey)
            machine = named.group(1).strip() if named else None
            if machine and machine in shapes:
                record["machine"] = machine
                record["survey_step"] = (int(stepped.group(1))
                                         if stepped else None)
                body = TEST_WITH_CLAIM.format(
                    machine=machine, shape=shapes[machine],
                    question=question, solution=written)
            else:
                # No usable hypothesis. The item still reaches turn two, so
                # this arm never answers on less evidence than the reading
                # that has no graph at all.
                record["machine"] = machine  # kept even when off-catalogue
                record["gate"] = ("named_off_catalogue" if machine
                                  else "no_hypothesis")
                body = TEST_ALONE.format(question=question, solution=written)

            verdict = call(body, test_budget)
            record["reply"] = verdict[-300:]
            found = REPLY_STEP.search(verdict)
            if not found:
                record["gate"] = "unparsed" if verdict.strip() else "empty"
            else:
                claimed = int(found.group(1))
                if claimed == 0:
                    record["gate"] = "declined"
                elif claimed not in allowed:
                    record["gate"] = "step_not_written"
                else:
                    record["gate"] = ("accused_on_hypothesis"
                                      if record["machine"] in shapes
                                      else "accused_without_hypothesis")
                    record["answer"] = str(claimed)
        except Exception as error:  # a broken item must not sink the run
            record["responder_error"] = f"{type(error).__name__}: {error}"
        mtb_responders.emit(record)
        return record["answer"]

    return respond


mtb_responders.register("graph_agent", _graph_agent)
