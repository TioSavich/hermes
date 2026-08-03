#!/usr/bin/env python3
"""Gemma against the Hermes MCP, with a judgment gate the harness enforces.

The local model (Ollama, gemma4:e2b) never decides anything alone. The
protocol runs fixed stages: the model transcribes the problem and the
student's steps into a small fact vocabulary with units; SWI-Prolog derives
what those facts license and names every disagreement; the Hermes MCP server
— the same stdio process the interactive tools use — answers corpus queries
about the named disagreement. A judgment is reported only when one of two
gates opens:

  (a) the misconception corpus returns at least one row for the disagreement
      (rows are cited verbatim; the model may restate them, never replace
      them), or
  (b) the engine validates the student's algorithm: every claim agrees with
      a licensed value and the units are consistent through to the asked
      quantity.

If neither gate opens — including when the output-token budget runs out —
the default passes: no judgement. The closed-world pretense is deliberate:
the corpus is treated as if it were exhaustive, so silence is an answer.

Two operating rules carried from measured failure: every Ollama request
pins "think": false (thinking spends the token budget invisibly and there
is no server-side setting for it in this Ollama), and every model call asks
one small question (compound instructions collapse).
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import tempfile
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OLLAMA = "http://localhost:11434/api/generate"

NAME = r"[a-z][a-z0-9_]*"
NUM = r"-?\d+(?:/\d+)?"
FORMS = {
    "given": re.compile(rf"^given\({NAME},\s*{NUM},\s*{NAME}\)\.$"),
    "ratio": re.compile(rf"^ratio\({NAME},\s*{NUM},\s*{NAME},\s*{NUM}\)\.$"),
    "sum": re.compile(rf"^sum\({NAME},\s*\[{NAME}(?:,\s*{NAME})*\]\)\.$"),
    "unit": re.compile(rf"^unit\({NAME},\s*{NAME}\)\.$"),
    "asks": re.compile(rf"^asks\({NAME}\)\.$"),
    "student": re.compile(rf"^student\(\d+,\s*{NAME},\s*{NUM}\)\.$"),
}

GIVENS_PROMPT = """Problem: {problem}

List every quantity this problem states as a plain number. One line per
quantity, exact form:
given(name, Value, unit).
- name is a short lowercase snake_case noun for WHAT is measured (the
  substance or object, e.g. peanut_butter, oil, red_marbles)
- Value is an integer or a fraction like 3/4; no $ signs
- unit is the measure word (ounces, dollars, cups); write count when
  the quantity is a plain count
- skip numbers that belong to a "for every"/"per"/"times as many" phrase
Example line: given(red_marbles, 10, count).
Write only given lines, nothing else."""

RATIOS_PROMPT = """Problem: {problem}

List every ratio this problem states. Phrases like "for every", "per",
"each", and "times as many" state ratios. Exact form:
ratio(a, Va, b, Vb).
It means: for every Va of a there are Vb of b. Names are short lowercase
snake_case nouns for what is measured.
Example line: ratio(nuts, 3, raisins, 1).
If the problem states no ratio, write NONE. Write only ratio lines or NONE."""

UNITS_PROMPT = """Problem: {problem}

Quantity names: {names}.
For each name, its unit — the measure word the problem uses for it
(ounces, dollars, cups), or count for a plain count. One line per name:
unit(name, unit).
Write only unit lines, nothing else."""

ASKS_PROMPT = """Problem: {problem}

Known quantity names: {names}.
What quantity does the question ask for? Write exactly one line:
asks(name).
Use a known name when the question asks for one of them. Write nothing
else."""

STEP_PROMPT = """Known quantity names: {names}.
A student solving a math problem wrote this step:
"{step}"

Which quantities does this step state a numeric value for? One line per
stated value, exact form:
student({k}, name, Value).
- use a known name when the step refers to that quantity; if the student
  writes a letter like x for a known quantity, use the known name
- a genuinely new quantity gets a new short snake_case name
- name WHAT is measured, never the measure word: ounces, dollars, and
  cups are units, not quantity names
- Value is an integer or a fraction like 3/4; no $ signs
If the step states no numeric value, write NONE. Write nothing else."""

KEYWORDS_PROMPT = """A student made this error in a math problem:
{summary}

Write three short search phrases, one per line, that a catalogue of
documented student misconceptions might use for this error. Plain
lowercase words, no punctuation. Write the three lines and nothing else."""

RESTATE_PROMPT = """A diagnosis engine matched a student's error to these
documented misconceptions:
{rows}

The mechanical finding was:
{summary}

Write ONE sentence for a teacher naming what the student did, staying
inside what the rows above document. Do not add causes the rows do not
state. Write the sentence and nothing else."""

CHECKER = r"""
:- set_prolog_flag(prefer_rationals, true).
:- use_module(library(lists)).
:- dynamic given/3.
:- dynamic ratio/4.
:- dynamic sum/2.
:- dynamic unit/2.
:- dynamic asks/1.
:- dynamic student/3.
:- discontiguous licensed/2.
:- table licensed/2.

licensed(N, V) :- given(N, V0, _), V is V0.
licensed(B, V) :- ratio(A, Va, B, Vb), licensed(A, X), V is (X * Vb) rdiv Va.
licensed(A, V) :- ratio(A, Va, B, Vb), licensed(B, X), V is (X * Va) rdiv Vb.
licensed(W, V) :- sum(W, Parts), maplist(licensed, Parts, Vs), sum_list(Vs, V).
licensed(P, V) :-
    sum(W, Parts), select(P, Parts, Rest),
    licensed(W, X), maplist(licensed, Rest, Vs), sum_list(Vs, Y), V is X - Y.
part_ratio(A, Va, B, Vb) :- ratio(A, Va, B, Vb).
part_ratio(A, Va, B, Vb) :- ratio(B, Vb, A, Va).
licensed(A, V) :-
    sum(W, [A, B]), part_ratio(A, Va, B, Vb),
    licensed(W, X), V is (X * Va) rdiv (Va + Vb).
licensed(B, V) :-
    sum(W, [A, B]), part_ratio(A, Va, B, Vb),
    licensed(W, X), V is (X * Vb) rdiv (Va + Vb).

quantity_unit(N, U) :- unit(N, U).
quantity_unit(N, U) :- given(N, _, U).

verdict(S, N, Said, Lic, Status) :-
    student(S, N, Said0),
    catch(Said is Said0, _, fail),
    (   licensed(N, Lic)
    ->  ( Said =:= Lic -> Status = agrees ; Status = contradicts )
    ;   Lic = none, Status = unlicensed
    ).

% an unlicensed value that equals a different quantity's given value is a
% substitution: the student used one quantity's number as another's
substitution(S, N, V, M, U) :-
    verdict(S, N, V, none, unlicensed),
    given(M, V0, U), M \== N, catch(V =:= V0, _, fail).

unit_gap(N) :-
    (   given(N, _, _) ; asks(N)
    ;   ratio(N, _, _, _) ; ratio(_, _, N, _)
    ),
    \+ quantity_unit(N, _).

sum_unit_clash(W, P) :-
    sum(W, Parts), quantity_unit(W, WU),
    member(P, Parts), quantity_unit(P, PU), PU \== WU.

main :-
    forall(verdict(S, N, Said, Lic, Status),
           format("verdict ~w ~w ~w ~w ~w~n", [Status, S, N, Said, Lic])),
    forall(substitution(S, N, V, M, U),
           format("substitution ~w ~w ~w ~w ~w~n", [S, N, V, M, U])),
    forall((setof(N0, unit_gap(N0), Gaps), member(N, Gaps)),
           format("unit_gap ~w~n", [N])),
    forall(sum_unit_clash(W, P),
           format("sum_unit_clash ~w ~w~n", [W, P])),
    (   asks(Goal), licensed(Goal, Answer), quantity_unit(Goal, Unit)
    ->  format("licensed_answer ~w ~w ~w~n", [Goal, Answer, Unit])
    ;   asks(Goal), licensed(Goal, Answer)
    ->  format("licensed_answer ~w ~w unknown_unit~n", [Goal, Answer])
    ;   true
    ).
"""


class Budget:
    """Output-budget units spent across model calls; the gate reads it."""

    def __init__(self, cap: int) -> None:
        self.cap = cap
        self.spent = 0

    def exhausted(self) -> bool:
        return self.spent >= self.cap

    def remaining(self) -> int:
        return max(0, self.cap - self.spent)


def complete(prompt: str, budget: Budget, num_predict: int = 512,
             model: str = "gemma4:e2b") -> str:
    if budget.exhausted():
        return ""
    num_predict = min(num_predict, budget.remaining())
    body = json.dumps({
        "model": model, "prompt": prompt, "stream": False, "think": False,
        "options": {"temperature": 0, "num_predict": num_predict}}).encode()
    request = urllib.request.Request(
        OLLAMA, data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(request, timeout=300) as reply:
        payload = json.loads(reply.read())
    budget.spent += int(payload.get("eval_count", 0))
    return payload.get("response", "")


class MCPClient:
    """The same stdio server the interactive Hermes tools speak to."""

    def __init__(self) -> None:
        import os
        environment = dict(os.environ)
        environment["UMEDCTA_ROOT"] = str(ROOT)
        self.process = subprocess.Popen(
            [sys.executable, str(ROOT / "hermes/mcp/server.py"),
             "--mode", "core"],
            cwd=ROOT, text=True, encoding="utf-8", env=environment,
            stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL)
        self.next_id = 0
        self.request("initialize", {
            "protocolVersion": "2025-03-26", "capabilities": {},
            "clientInfo": {"name": "gemma_hermes_protocol", "version": "0"}})
        self.notify("notifications/initialized")

    def request(self, method: str, params: dict) -> dict:
        self.next_id += 1
        message = {"jsonrpc": "2.0", "id": self.next_id,
                   "method": method, "params": params}
        assert self.process.stdin and self.process.stdout
        self.process.stdin.write(json.dumps(message) + "\n")
        self.process.stdin.flush()
        while True:
            line = self.process.stdout.readline()
            if not line:
                raise RuntimeError("hermes mcp server closed its pipe")
            reply = json.loads(line)
            if reply.get("id") == self.next_id:
                return reply

    def notify(self, method: str) -> None:
        assert self.process.stdin
        self.process.stdin.write(
            json.dumps({"jsonrpc": "2.0", "method": method}) + "\n")
        self.process.stdin.flush()

    def call_tool(self, name: str, arguments: dict) -> str:
        reply = self.request("tools/call",
                             {"name": name, "arguments": arguments})
        parts = reply.get("result", {}).get("content", [])
        return "\n".join(p.get("text", "") for p in parts
                         if p.get("type") == "text")

    def close(self) -> None:
        self.process.kill()
        self.process.wait()


def keep(raw: str, form: str) -> list[str]:
    kept = []
    for line in raw.splitlines():
        line = line.strip().strip("`")
        if line and not line.endswith("."):
            line += "."
        if FORMS[form].match(line):
            kept.append(line)
    return kept


def names_of(facts: list[str]) -> list[str]:
    found: list[str] = []
    for fact in facts:
        inner = fact[fact.index("(") + 1:fact.rindex(")")]
        for token in inner.replace("[", "").replace("]", "").split(","):
            token = token.strip()
            if re.fullmatch(NAME, token) and token not in found:
                found.append(token)
    return found


def reconcile(facts: list[str]) -> list[str]:
    """Ratio restatements are the ratio: drop givens and student claims
    that duplicate a ratio pair, and drop degenerate ratios."""
    pairs = set()
    kept = []
    for fact in facts:
        matched = re.match(
            rf"^ratio\(({NAME}),\s*({NUM}),\s*({NAME}),\s*({NUM})\)\.$", fact)
        if matched:
            if matched.group(1) == matched.group(3):
                continue
            pairs.add((matched.group(1), matched.group(2)))
            pairs.add((matched.group(3), matched.group(4)))
        kept.append(fact)
    final = []
    for fact in kept:
        matched = (re.match(rf"^given\(({NAME}),\s*({NUM}),\s*{NAME}\)\.$", fact)
                   or re.match(rf"^student\(\d+,\s*({NAME}),\s*({NUM})\)\.$",
                               fact))
        if matched and (matched.group(1), matched.group(2)) in pairs:
            continue
        final.append(fact)
    return final


def extract(problem: str, steps: list[str], budget: Budget,
            transcript: list[str], complete_fn=None,
            max_steps: int = 12) -> list[str]:
    call = complete_fn or complete
    facts = keep(call(GIVENS_PROMPT.format(problem=problem), budget),
                 "given")
    facts += keep(call(RATIOS_PROMPT.format(problem=problem), budget),
                  "ratio")
    facts = reconcile(facts)
    names = names_of([f for f in facts if not f.startswith("student(")])
    unitless = [n for n in names
                if not any(f.startswith(f"unit({n},") for f in facts)]
    if unitless:
        facts += keep(call(UNITS_PROMPT.format(
            problem=problem, names=", ".join(unitless)), budget), "unit")
    facts += keep(call(ASKS_PROMPT.format(
        problem=problem, names=", ".join(names)), budget), "asks")
    unit_words = {re.match(rf"^unit\({NAME},\s*({NAME})\)\.$", f).group(1)
                  for f in facts if f.startswith("unit(")}
    unit_words |= {"ounces", "ounce", "dollars", "cups", "count"}
    for k, step in enumerate(steps[:max_steps], start=1):
        if not step.strip() or not re.search(r"\d", step):
            continue
        prompt = STEP_PROMPT.format(
            names=", ".join(names), step=step.strip(), k=k)
        lines = keep(call(prompt, budget), "student")
        named_by_unit = [
            line for line in lines
            if re.match(rf"^student\(\d+,\s*({NAME}),", line).group(1)
            in unit_words]
        if named_by_unit and not budget.exhausted():
            corrective = (prompt + "\nNote: " +
                          ", ".join(sorted(unit_words & {
                              m.group(1) for line in named_by_unit
                              for m in [re.match(
                                  rf"^student\(\d+,\s*({NAME}),", line)]})) +
                          " are units, not quantity names. Use the known "
                          "quantity names.")
            lines = keep(call(corrective, budget), "student")
        facts += [line for line in lines
                  if re.match(rf"^student\(\d+,\s*({NAME}),", line).group(1)
                  not in unit_words]
    facts = reconcile(facts)
    deduped = []
    for fact in facts:
        if fact not in deduped:
            deduped.append(fact)
    transcript.append("facts:\n" + "\n".join(deduped))
    return deduped


def run_checker(facts: list[str]) -> list[str]:
    with tempfile.TemporaryDirectory() as scratch:
        checker = Path(scratch) / "checker.pl"
        checker.write_text(CHECKER)
        facts_file = Path(scratch) / "facts.pl"
        facts_file.write_text("\n".join(facts) + "\n")
        result = subprocess.run(
            ["swipl", "-q", "-g", "main", "-t", "halt",
             str(checker), str(facts_file)],
            capture_output=True, text=True, timeout=60)
    return [line for line in result.stdout.splitlines() if line.strip()]


def violation_summary(report: list[str]) -> tuple[str, str, int] | None:
    for line in report:
        parts = line.split()
        if parts[0] == "substitution":
            _, step, name, value, other, unit = parts
            return "substitution", (
                f"In step {step} the student uses {value} as the value "
                f"of {name}, but {value} {unit} is given as the "
                f"{other} quantity; no stated fact licenses "
                f"{name} = {value}."), int(step)
    contradictions = []
    for line in report:
        parts = line.split()
        if parts[0] == "verdict" and parts[1] == "contradicts":
            contradictions.append(parts)
    if contradictions:
        parts = min(contradictions, key=lambda p: int(p[2]))
        _, _, step, name, said, licensed = parts
        return "contradicts", (
            f"In step {step} the student states {name} = {said}, "
            f"but the problem's facts license {name} = {licensed}."), int(step)
    return None


def corpus_gate(problem: str, kind: str, summary: str, budget: Budget,
                transcript: list[str], client: MCPClient,
                complete_fn=None) -> list[dict]:
    """Gate (a) in one place: model-proposed keywords widen the fixed
    probes, retrieval and ranking stay mechanical, and the rows returned
    are the license for any judgment."""
    call = complete_fn or complete
    raw = call(KEYWORDS_PROMPT.format(summary=summary), budget,
               num_predict=64)
    keywords = ["whole part total", "referent proportion"] if (
        kind == "substitution") else []
    keywords += [line.strip() for line in raw.splitlines()
                 if line.strip()][:3]
    return corpus_rows(client, keywords, f"{summary} {problem}",
                       kind, transcript)


STOPWORDS = {
    "the", "a", "an", "of", "in", "as", "for", "and", "or", "to", "is",
    "student", "students", "when", "with", "that", "this", "which", "one",
    "uses", "used", "using", "problem", "quantity", "value", "stated",
    "given", "no", "not", "but", "her", "his", "their", "she", "he"}


def stem(word: str) -> str:
    for suffix in ("es", "s"):
        if word.endswith(suffix) and len(word) > len(suffix) + 3:
            return word[:-len(suffix)]
    return word


def content_words(text: str) -> set[str]:
    words = re.findall(r"[a-z]+", text.lower())
    return {stem(w) for w in words if len(w) > 3 and w not in STOPWORDS}


# the vocabulary a whole-for-part substitution shares with corpus prose,
# regardless of the problem's own surface words
SUBSTITUTION_VOCABULARY = ("whole part total referent mixture constituent "
                           "amount combine merged proportion")
SUBSTITUTION_PROBES = ["mixture", "referent", "whole amount", "total as",
                       "constituent", "proportion", "intensive"]


def corpus_rows(client: MCPClient, keywords: list[str], context: str,
                kind: str, transcript: list[str]) -> list[dict]:
    """Short word probes against the offline all-words search, ranked
    mechanically. A substitution has structure (one quantity's value used
    as another's), so its type vocabulary joins the scoring context and
    its probes fire; a bare contradiction has no such structure and must
    earn rows from its own words at a higher bar — a type vocabulary
    applied to every violation would open the gate on the same stock rows
    for any wrong value, which is a fabricated judgment. A probe whose
    match count exceeds what one call returns is discarded: the server
    truncates alphabetically, so a flooded probe is uninformative, not
    evidence. The engine ranks; no model judgment enters retrieval."""
    substitution = kind == "substitution"
    probes = list(SUBSTITUTION_PROBES) if substitution else []
    threshold = 2 if substitution else 3
    for keyword in keywords:
        for word in sorted(content_words(keyword)):
            if word not in probes:
                probes.append(word)
    candidates: dict[str, dict] = {}
    for probe in probes[:12]:
        text = client.call_tool("misconception_search_rows",
                                {"query": probe, "k": 32})
        try:
            reply = json.loads(text)
        except json.JSONDecodeError:
            transcript.append(f"mcp search({probe!r}): unparseable reply")
            continue
        count = reply.get("count", 0)
        if count > 32:
            transcript.append(f"mcp search({probe!r}): {count} rows — "
                              f"flooded, discarded")
            continue
        transcript.append(f"mcp search({probe!r}): {count} rows")
        for row in reply.get("rows", []):
            if row.get("description") == "too_vague":
                continue
            candidates.setdefault(str(row.get("db_row")), row)
    context_tokens = content_words(context)
    if substitution:
        context_tokens |= content_words(SUBSTITUTION_VOCABULARY)
    scored = []
    for row in candidates.values():
        row_tokens = content_words(
            f"{row.get('description', '')} {row.get('citation', '')}")
        score = len(row_tokens & context_tokens)
        if score >= threshold:
            scored.append((score, row))
    scored.sort(key=lambda pair: (-pair[0], str(pair[1].get("db_row"))))
    transcript.append("row scores: " + "; ".join(
        f"{row.get('db_row')}={score}" for score, row in scored[:6]))
    top = [row for _, row in scored[:3]]
    if top:
        neighbors = client.call_tool(
            "resonance_neighbors",
            {"db_row": str(top[0].get("db_row")), "k": 3})
        transcript.append(f"mcp resonance_neighbors(top row): "
                          f"{neighbors[:400]}")
    return top


def validated(report: list[str]) -> bool:
    verdicts = [line.split()[1] for line in report
                if line.startswith("verdict ")]
    clean = verdicts and all(v == "agrees" for v in verdicts)
    gaps = any(line.startswith(("unit_gap", "sum_unit_clash"))
               for line in report)
    answered = any(line.startswith("licensed_answer") for line in report)
    return clean and answered and not gaps


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--stepverify-index", type=int, default=83)
    parser.add_argument("--budget", type=int, default=2500,
                        help="total output tokens across every model call")
    parser.add_argument("--out", type=Path, default=None)
    args = parser.parse_args()

    from datasets import load_dataset  # deferred: heavy import
    item = load_dataset("eth-nlped/stepverify", split="train")[
        args.stepverify_index]
    problem = item["problem"]
    steps = item["student_incorrect_solution"]
    if isinstance(steps, str):
        steps = [s for s in steps.split("\n") if s.strip()]

    budget = Budget(args.budget)
    transcript: list[str] = [f"problem: {problem}"]
    facts = extract(problem, steps, budget, transcript)
    report = run_checker(facts)
    transcript.append("checker:\n" + "\n".join(report))

    judgment = None
    violation = violation_summary(report)
    if violation and not budget.exhausted():
        kind, summary, _step = violation
        transcript.append(f"violation ({kind}): {summary}")
        client = MCPClient()
        try:
            rows = corpus_gate(problem, kind, summary, budget,
                               transcript, client)
        finally:
            client.close()
        if rows:
            cited = "\n".join(
                f"{row.get('db_row')}: {row.get('description')} — "
                f"{row.get('citation')}" for row in rows)
            sentence = complete(RESTATE_PROMPT.format(
                rows=cited, summary=summary), budget,
                num_predict=128).strip()
            judgment = (f"JUDGMENT (gate a, corpus rows matched):\n"
                        f"{summary}\nrows:\n{cited}\n"
                        f"teacher sentence: {sentence}")
    if judgment is None and validated(report):
        answer = next(line for line in report
                      if line.startswith("licensed_answer"))
        judgment = (f"JUDGMENT (gate b, algorithm validated with units): "
                    f"every student claim agrees with a licensed value; "
                    f"{answer}")
    if judgment is None:
        judgment = "no judgement (default: neither gate opened)"

    transcript.append(f"tokens spent: {budget.spent}/{budget.cap}")
    transcript.append(judgment)
    print("\n\n".join(transcript))
    if args.out:
        args.out.write_text("\n\n".join(transcript) + "\n")


if __name__ == "__main__":
    main()
