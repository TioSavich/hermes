#!/usr/bin/env python3
"""The mistake-location benchmark, three arms, exact-match scored.

MathTutorBench `mistake_location` asks for the number of the first step
carrying an error, or 0 if the solution is correct. The answer is one integer,
so nothing here depends on a reward model's opinion of good teaching.

Three arms, all against the same items and the same served checkpoint:

  config       the task's own shipped prompt. The baseline.
  abstain      a prompt that states the base rate and makes 0 a real answer.
               Measured on a 40-item sample: exact 0.300 against config's
               0.150, with 23 abstentions against 0.
  adjudicated  the model compiles the problem into referent facts and binds
               the student's numerals to them; SWI-Prolog saturates the
               problem-side facts and answers the first step whose bound
               referent derives a different value. The model never judges.

The bar all three answer to is `always answer 0`, which scores whatever
fraction of items carry no error. On a 40-item sample that was 0.475. An arm
below it has not earned its complexity.

Checkpointing is per item so a run resumes rather than restarts.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parents[2]
ENGINE = REPO / "scripts" / "sidekick" / "diagnosis_saturate.pl"

CONFIG_PROMPT = """\
You are an experienced math teacher. Your goal is to identify the step of the first mistake in the Student's Solution to a Problem.
Problem: {question}
Student Solution: {solution}
Q: Is the Student Solution incorrect? Write only the step number with the first error or 0 if no error is found.
A:"""

ABSTAIN_PROMPT = """\
You are a tutor reading a student's work. Many of these solutions are
completely correct. Your job is not to find an error; it is to decide
whether there is one.

Accusing a student who is actually right is the worst outcome here. It
squashes creative problem solving. Answering 0 is a real answer, not a
failure to answer, and it is the right answer whenever the work holds up.

Read every step. Check each one against the step before it. Only name a
step if you can state the specific thing that is wrong with that step and
you are 90% confident. Otherwise answer 0.

=== PROBLEM ===
{question}

=== STUDENT SOLUTION ===
{solution}

Answer with one line and nothing else:
STEP: n
where n is the number of the step that carries the error, or
STEP: 0
if the solution has no error, or you are not confident there is one.
"""

COMPILE_RULES = """\
Represent this mathematics problem as Prolog facts. Do not solve it. Do not
write any clause and do not write solve/1.

Use only these five forms:

quantity(Name, Value, Kind).
    Name is a referent handle naming a specific quantity in this problem,
    such as shop_crates. Value is a number, or the atom unknown for the
    quantity the question asks for. Kind is the countable species, such as
    crates or jars.

conversion(FromKind, ToKind, Factor, "the words that say so").
    World knowledge you supply, taken from the problem's own subject matter.
    A crate holds 6 boxes. A week has 7 days.

relation(Name, Recipe, "the words that say so").
    Recipe is convert(SourceName, TargetKind), or scale(ScalarName, SourceName),
    or sum([NameA, NameB]).

asks(result, Name).
    Which referent the question asks for.

discrete_kinds([Kinds]).
    Kinds that count whole objects.

Reply with the facts only, one per line, each ending in a period.
"""

# Frame A and frame A-prime. Temperature is 0, so an identical frame would
# return an identical program and the agreement guard would be vacuous. The
# exemplar is a problem chosen to sit outside the evaluated corpus.
EXEMPLAR = """\
Worked example.

PROBLEM: A crate holds 6 boxes. Each box holds 4 jars. A shop receives 3
crates and sells 20 jars. How many jars does the shop have left?

FACTS:
quantity(crates_received, 3, crates).
quantity(jars_sold, 20, jars).
quantity(jars_left, unknown, jars).
conversion(crates, boxes, 6, "a crate holds 6 boxes").
conversion(boxes, jars, 4, "each box holds 4 jars").
relation(boxes_received, convert(crates_received, boxes), "3 crates").
relation(jars_received, convert(boxes_received, jars), "each box holds 4 jars").
asks(result, jars_left).
discrete_kinds([crates, boxes, jars]).
"""

FRAME_A = COMPILE_RULES + "\n" + EXEMPLAR + "\nPROBLEM: {q}\n\nFACTS:\n"
FRAME_B = ("Write the Prolog facts that represent this problem's quantities and "
           "the relations between them. Do not solve it.\n\n" + COMPILE_RULES +
           "\nPROBLEM: {q}\n\nFACTS:\n")

BIND_PROMPT = """\
Here is a mathematics problem, a list of referent names for the quantities in
it, and a student's numbered solution.

For each step that asserts a number, say which referent that number is meant
to be, choosing only from the list. If no referent in the list names it, write
unresolved. Do not judge whether the number is right.

Reply with one line per step and nothing else:
  b(StepNumber, referent_name, Value, "the exact words from that step").

=== PROBLEM ===
{question}

=== REFERENT NAMES ===
{lexicon}

=== STUDENT SOLUTION ===
{solution}
"""

FACT_LINE = re.compile(
    r'^\s*(quantity\([^\n]*\)|conversion\([^\n]*\)|relation\([^\n]*\)|'
    r'asks\([^\n]*\)|discrete_kinds\([^\n]*\))\s*\.\s*$')
# The tuned checkpoint emits its binding rows without the requested quotes or
# trailing period (b(1,name,4,the words) rather than b(1,name,4,"the words").),
# so the reader accepts both shapes. The span runs to the line's last paren.
BIND_LINE = re.compile(
    r'^\s*b\(\s*(\d+)\s*,\s*([a-z_][A-Za-z0-9_]*)\s*,\s*(-?[\d.]+)\s*,\s*'
    r'(?:"(.*)"|(.*?))\s*\)\s*\.?\s*$')
STEP_REPLY = re.compile(r"STEP\s*:\s*(\d+)")
BARE_INT = re.compile(r"-?\d+")
STEP_HEAD = re.compile(r"^\s*Step\s+(\d+)\s*[-:]", re.IGNORECASE | re.MULTILINE)


def chat(endpoint: str, model: str, prompt: str, max_tokens: int,
         timeout: float) -> tuple[str, str]:
    """Return (outcome, text). Only an `ok` outcome may be parsed."""
    body = json.dumps({"model": model,
                       "messages": [{"role": "user", "content": prompt}],
                       "temperature": 0, "max_tokens": max_tokens}).encode()
    request = urllib.request.Request(
        endpoint, data=body, headers={"Content-Type": "application/json"},
        method="POST")
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            payload = json.loads(response.read().decode())
    except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError,
            json.JSONDecodeError, OSError) as error:
        return f"transport_error:{type(error).__name__}", ""
    choice = payload["choices"][0]
    text = choice["message"].get("content") or ""
    if choice.get("finish_reason") == "length":
        return "truncated", text
    if not text.strip():
        return "empty_content", text
    return "ok", text


def program_of(text: str) -> list[str]:
    """Whitelist reader: any other functor or any clause makes it malformed."""
    kept: list[str] = []
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("%"):
            continue
        if ":-" in line:
            return []
        if FACT_LINE.match(line):
            kept.append(line)
    return kept


def lexicon_of(program: list[str]) -> list[str]:
    names: list[str] = []
    for line in program:
        found = re.match(r'^(?:quantity|relation)\(\s*([a-z_][A-Za-z0-9_]*)', line)
        if found and found.group(1) not in names:
            names.append(found.group(1))
    return names


def step_texts(solution: str) -> dict[int, str]:
    """Split the student's solution into its numbered steps."""
    # The dataset stores solutions with literal backslash-n character pairs,
    # not newlines, so the line-anchored scan saw a single line and every
    # binding past step 1 demoted as no_such_step.
    solution = (solution or "").replace("\\n", "\n")
    marks = list(STEP_HEAD.finditer(solution))
    out: dict[int, str] = {}
    for index, mark in enumerate(marks):
        end = marks[index + 1].start() if index + 1 < len(marks) else len(solution)
        out[int(mark.group(1))] = solution[mark.start():end]
    return out


def _squash(text: str) -> str:
    """Whitespace-free form for the verbatim check. The tuned checkpoint drops
    spaces after commas when it copies a step's words; spacing carries no
    content, and the check still requires the exact character sequence."""
    return re.sub(r"\s+", "", text)


def gate_bindings(text: str, lexicon: list[str], steps: dict[int, str],
                  derived: dict[str, float]) -> tuple[list[tuple[int, str, float]],
                                                      list[dict[str, Any]]]:
    """Apply the design's deterministic gates. A failure demotes, never repairs."""
    bindings: list[tuple[int, str, float]] = []
    audit: list[dict[str, Any]] = []
    for line in text.splitlines():
        found = BIND_LINE.match(line.strip())
        if not found:
            continue
        step = int(found.group(1))
        referent = found.group(2)
        value = float(found.group(3))
        span = found.group(4) if found.group(4) is not None else \
            (found.group(5) or "").strip()
        reason = None
        if referent not in lexicon and referent != "unresolved":
            reason = "referent_not_in_lexicon"
        elif step not in steps:
            reason = "no_such_step"
        elif span and _squash(span) not in _squash(steps[step]):
            reason = "span_not_verbatim"
        elif span and not any(
                abs(float(token) - value) < 1e-9
                for token in BARE_INT.findall(span.replace(",", ""))
                if token not in ("", "-")):
            reason = "value_not_at_token_boundary_in_span"
        else:
            # Value-collision demotion: the number equals a different lexicon
            # referent's derived value whose name-noun also occurs in the span.
            for other, other_value in derived.items():
                if other == referent:
                    continue
                if abs(other_value - value) < 1e-9:
                    noun = other.rsplit("_", 1)[-1]
                    if noun and noun in span.lower():
                        reason = f"value_collision_with_{other}"
                        break
        if reason:
            audit.append({"step": step, "proposed": referent, "value": value,
                          "demoted": reason})
            referent = "unresolved"
        bindings.append((step, referent, value))
    return bindings, audit


def adjudicate(program: list[str], bindings: list[tuple[int, str, float]],
               work: Path) -> tuple[int, str, dict[str, float]]:
    """Run the engine. Returns (answer, reason, derived)."""
    facts = "\n".join(f"p({line[:-1]})." for line in program)
    binds = "\n".join(f"q(b({s},{r},{v}))." for s, r, v in bindings)
    script = work / "_adjudicate.pl"
    script.write_text(
        f':- ensure_loaded("{ENGINE}").\n' + facts + "\n" + binds + "\n",
        encoding="utf-8")
    try:
        done = subprocess.run(
            ["swipl", "-q", "-g", f'consult("{script}"), catch(run,E,(print_message(error,E),true)), halt.',
             "-t", "halt"], capture_output=True, text=True, timeout=90)
    except subprocess.TimeoutExpired:
        return 0, "engine_timeout", {}
    answer, reason, derived = 0, "engine_no_answer", {}
    for line in done.stdout.splitlines():
        if line.startswith("ANSWER "):
            try:
                answer = int(line.split(None, 1)[1])
            except ValueError:
                answer = 0
        elif line.startswith("REASON "):
            reason = line.split(None, 1)[1]
        elif line.startswith("DERIVED "):
            name, _, value = line[8:].partition("=")
            try:
                derived[name.strip()] = float(value)
            except ValueError:
                pass
    return answer, reason, derived


def run_item(item: dict[str, Any], arm: str, endpoint: str, model: str,
             work: Path, timeout: float) -> dict[str, Any]:
    question, solution = item["question"], item["solution"]
    if arm == "config":
        outcome, raw = chat(endpoint, model,
                            CONFIG_PROMPT.format(question=question, solution=solution),
                            32, timeout)
        found = BARE_INT.search(raw) if outcome == "ok" else None
        return {"answer": int(found.group()) if found else 0,
                "outcome": outcome, "raw": raw}
    if arm == "abstain":
        outcome, raw = chat(endpoint, model,
                            ABSTAIN_PROMPT.format(question=question, solution=solution),
                            64, timeout)
        found = STEP_REPLY.search(raw) if outcome == "ok" else None
        return {"answer": int(found.group(1)) if found else 0,
                "outcome": outcome, "raw": raw}

    # adjudicated
    outcome_a, text_a = chat(endpoint, model, FRAME_A.format(q=question), 500, timeout)
    program = program_of(text_a) if outcome_a == "ok" else []
    if not program:
        return {"answer": 0, "outcome": outcome_a, "reason": "compile_malformed",
                "raw_compile": text_a}
    _, _, derived_a = adjudicate(program, [], work)

    outcome_b, text_b = chat(endpoint, model, FRAME_B.format(q=question), 500, timeout)
    program_b = program_of(text_b) if outcome_b == "ok" else []
    _, _, derived_b = adjudicate(program_b, [], work) if program_b else (0, "", {})

    lexicon = lexicon_of(program)
    outcome_c, text_c = chat(
        endpoint, model,
        BIND_PROMPT.format(question=question, solution=solution,
                           lexicon="\n".join(lexicon)), 500, timeout)
    steps = step_texts(solution)
    bindings, audit = gate_bindings(text_c if outcome_c == "ok" else "",
                                    lexicon, steps, derived_a)
    answer, reason, _ = adjudicate(program, bindings, work)

    # The agreement guard: an accusation stands only if the independent second
    # compile derives the same value for that referent.
    if answer != 0:
        target = None
        for step, referent, _value in bindings:
            if step == answer and referent != "unresolved":
                target = referent
                break
        if target is None or target not in derived_b or \
                abs(derived_b[target] - derived_a.get(target, float("nan"))) > 1e-6:
            answer, reason = 0, f"withheld_no_agreement({reason})"
    return {"answer": answer, "outcome": outcome_a, "reason": reason,
            "facts": len(program), "derived": len(derived_a),
            "bindings": len(bindings), "demotions": audit,
            "raw_compile": text_a, "raw_bind": text_c}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--items", type=Path, required=True)
    parser.add_argument("--arm", required=True,
                        choices=["config", "abstain", "adjudicated"])
    parser.add_argument("--endpoint", required=True)
    parser.add_argument("--model", default="sidekick")
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--timeout", type=float, default=900.0)
    parser.add_argument("--limit", type=int)
    args = parser.parse_args()

    items = json.loads(args.items.read_text())
    if args.limit:
        items = items[: args.limit]
    work = args.out / args.arm
    work.mkdir(parents=True, exist_ok=True)

    for index, item in enumerate(items):
        stamp = work / f"item-{index:04d}.json"
        if stamp.exists():
            continue
        record = run_item(item, args.arm, args.endpoint, args.model, work,
                          args.timeout)
        record["index"] = index
        record["target"] = str(item["target"])
        stamp.write_text(json.dumps(record), encoding="utf-8")
        if (index + 1) % 25 == 0:
            print(f"{args.arm}: {index + 1}/{len(items)}", flush=True)

    records = [json.loads(p.read_text()) for p in sorted(work.glob("item-*.json"))]
    hits = sum(str(r["answer"]) == r["target"] for r in records)
    zeros = sum(str(r["target"]) == "0" for r in records)
    said0 = sum(r["answer"] == 0 for r in records)
    located = sum(str(r["answer"]) == r["target"] for r in records
                  if r["target"] != "0")
    false_acc = sum(r["answer"] != 0 for r in records if r["target"] == "0")
    summary = {"arm": args.arm, "n": len(records), "exact": hits / len(records),
               "hits": hits, "always_zero_baseline": zeros / len(records),
               "abstentions": said0, "located_when_error_exists": located,
               "errors_present": len(records) - zeros,
               "false_accusations": false_acc}
    (args.out / f"summary-{args.arm}.json").write_text(
        json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps(summary, indent=2), flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
