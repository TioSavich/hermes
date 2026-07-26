#!/usr/bin/env python3
"""The whole loop on one laptop: select, open, prove, tutor.

This runs the neurosymbolic pipeline against real MathTutorBench dialogues using a
quantized Gemma 4 E2B served locally by Ollama and SWI-Prolog on the same machine.
Nothing here reaches a cluster or an API. That is the claim being built — a system
a teacher's laptop can run — so the laptop is the target and not a stand-in.

Four steps per item:

  1. SELECT   the model reads the 232-machine index and names one machine.
              Parsing accepts a valid family/signature with or without the OPEN
              keyword, because the cluster run discarded 89 correct selections of
              360 for missing that word alone, and scored them as refusals.
  2. OPEN     Prolog serves that machine's transition table. A name outside the
              offered set is rejected here rather than trusted.
  3. PROVE    hermes/math_claim_language.pl reads the student's arithmetic claims
              and the registered checkers decide truth. The model does not decide
              truth; it is told what Prolog found.
  4. TUTOR    the model writes one teacher turn, holding the opened machine and
              the proved or refuted claims.

No reference solution and no ground-truth teacher response enters any prompt.
They are present in the dataset and are read only for the audit line that reports
their absence from what the model saw.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WINDOW = ROOT / "knowledge/index/corpus_window.txt"
TABLES = ROOT / "knowledge/strategies/transition_tables"
DATASET = (ROOT / "hermes/app/runtime/experiments/gemma4_tutor"
           / "vendor/datasets/mathdial_bridge.json")
ENDPOINT = "http://localhost:11434/v1/chat/completions"

WINDOW_LINE = re.compile(r"^  ([a-z][a-z0-9_]*)/([a-z][a-z0-9_]*) arc=", re.MULTILINE)
NAME = re.compile(r"(?:OPEN\s+)?([a-z][a-z0-9_]*)\s*/\s*([a-z][a-z0-9_]*)")

SELECT_SYSTEM = """Choose one machine from the index that could frame the next
tutor move. The index is a menu, not evidence that any machine diagnoses this
student.

Reply with one machine name from the index and nothing else."""

TUTOR_SYSTEM = """You are an experienced math teacher responding to a student.
The student must do the mathematical work. Use the opened machine only where its
steps bear on what the student actually said. Do not name the machine or any
internal process. Do not state or confirm the final answer.

Reply with one short teacher turn."""


def chat(model: str, system: str, user: str, timeout: int, predict: int) -> str:
    payload = json.dumps({
        "model": model,
        "messages": [{"role": "system", "content": system},
                     {"role": "user", "content": user}],
        "stream": False,
        "options": {"num_predict": predict, "temperature": 0.0},
    }).encode("utf-8")
    request = urllib.request.Request(
        ENDPOINT, data=payload, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return json.load(response)["choices"][0]["message"]["content"]


def open_machine(family: str, signature: str) -> str:
    """Prolog serves the machine's ordered steps. Empty means no such machine."""
    goal = (
        "use_module(library(lists),[]),"
        f"forall(automaton_transition({family}, {signature}, F, A, T, _),"
        "format('~w -> ~w -> ~w~n', [F, A, T])),halt."
    )
    result = subprocess.run(
        ["swipl", "-q", "--on-warning=status", "--on-error=status",
         "-l", "paths.pl",
         "-g", f"['{TABLES / (family + '.pl')}']" if (TABLES / f"{family}.pl").exists()
         else "true",
         "-g", goal],
        cwd=ROOT, capture_output=True, text=True, timeout=90)
    return result.stdout.strip()


def prove_claims(text: str) -> tuple[list[dict], str]:
    """Prolog reads the student's claims AND adjudicates them.

    The verdict is the point, and the trace more so: `count on from 5 by 3
    reaches 8; claimed 9` says how the arithmetic disagrees in countable terms
    without stating the answer, which is a thing a teacher can hand back as a
    question. Parsing alone gave the model nothing to say, so it narrated answers.
    """
    escaped = text.replace("\\", "\\\\").replace('"', '\\"')[:1200]
    goal = (
        "use_module(hermes(math_claim_language), [math_claims_in_text/2]),"
        "use_module(hermes(math_claim_checker), [check_math_claim/2]),"
        f'( math_claims_in_text("{escaped}", Claims) -> true ; Claims = [] ),'
        "forall(member(C, Claims),"
        "  ( catch(check_math_claim(C, D), _, fail)"
        "  -> ( get_dict(trace, D, Tr) -> true ; Tr = [] ),"
        "     atomic_list_concat(Tr, ' | ', TraceText),"
        "     format('VERDICT ~w\t~q\t~w~n', [D.verdict, C, TraceText])"
        "  ;  format('VERDICT unchecked\t~q\t~n', [C]) )),halt."
    )
    result = subprocess.run(
        ["swipl", "-q", "--on-warning=status", "--on-error=status",
         "-l", "paths.pl", "-g", goal],
        cwd=ROOT, capture_output=True, text=True, timeout=120)
    claims = []
    for line in result.stdout.splitlines():
        if not line.startswith("VERDICT "):
            continue
        parts = line[8:].split("\t")
        if len(parts) >= 2:
            claims.append({"verdict": parts[0], "claim": parts[1],
                           "trace": parts[2] if len(parts) > 2 else ""})
    return claims, result.stderr.strip()[:200]


def dialog_text(row: dict) -> str:
    turns = row.get("dialog_history") or []
    return "\n".join(f"{t.get('user','?')}: {t.get('text','')}" for t in turns)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model", default="gemma4:e2b")
    parser.add_argument("--items", type=int, default=6)
    parser.add_argument("--timeout", type=int, default=600)
    parser.add_argument("--show", action="store_true", help="print each tutor turn")
    parser.add_argument("--output", type=Path, default=None)
    args = parser.parse_args()

    full_window = WINDOW.read_text(encoding="utf-8")
    offered = {f"{f}/{s}" for f, s in WINDOW_LINE.findall(full_window)}
    # The legend lists 122 ACTIONS beside the 232 machines, and the model chose
    # actions from it: compute_product, retrieve_known_fact. Machines only takes
    # local selection from 50% to 100% and drops ~1,968 tokens per prompt.
    window_lines = full_window.splitlines()
    machines_at = next((i for i, line in enumerate(window_lines)
                        if line.startswith("MACHINES")), 0)
    window = "\n".join(window_lines[machines_at:])
    rows = json.loads(DATASET.read_text(encoding="utf-8"))
    if isinstance(rows, dict):
        rows = rows.get("data") or list(rows.values())[0]
    print(f"model {args.model} (local Ollama) · {len(offered)} machines offered · "
          f"{len(rows)} dialogues available")
    print()

    records = []
    selected = with_keyword = evidence_served = proved_any = tutored = 0
    leak_free = 0
    started = time.monotonic()

    for index, row in enumerate(rows[:args.items], start=1):
        dialog = dialog_text(row)
        case = f"PROBLEM\n{row.get('problem','')}\n\nCONVERSATION\n{dialog}"

        raw = chat(args.model, SELECT_SYSTEM,
                   f"MACHINE INDEX\n\n{window}\n\n{case}", args.timeout, 24).strip()
        hit = NAME.search(raw)
        machine = f"{hit.group(1)}/{hit.group(2)}" if hit else None
        valid = machine in offered
        if valid:
            selected += 1
            if raw.upper().startswith("OPEN"):
                with_keyword += 1

        table = open_machine(*machine.split("/")) if valid else ""
        if table:
            evidence_served += 1
        claims, _ = prove_claims(dialog)
        if claims:
            proved_any += 1

        evidence = (f"OPENED MACHINE {machine}\n{table}\n\n" if table else "")
        proved = ""
        if claims:
            rows = []
            for c in claims:
                line = f"  {c['claim']} -- {c['verdict'].upper()}"
                if c["trace"]:
                    line += f"\n      because: {c['trace']}"
                rows.append(line)
            proved = ("PROLOG CHECKED THE STUDENT'S ARITHMETIC\n"
                      + "\n".join(rows)
                      + "\n\nUse a REFUTED line to ask the student to re-examine "
                        "that step. Never give the corrected value.\n\n")
        turn = chat(args.model, TUTOR_SYSTEM,
                    f"{case}\n\n{evidence}{proved}Write the next teacher turn.",
                    args.timeout, 160).strip()
        if turn:
            tutored += 1

        prompt_seen = case + evidence + proved
        reference = str(row.get("reference_solution", ""))[:60]
        truth = str(row.get("ground_truth_response", ""))[:60]
        if (not reference or reference not in prompt_seen) and \
           (not truth or truth not in prompt_seen):
            leak_free += 1

        records.append({"index": index, "selection_raw": raw, "machine": machine,
                        "valid": valid, "table_steps": len(table.splitlines()),
                        "claims": claims, "tutor_turn": turn})
        flag = "S" if valid else "."
        print(f"[{index}] {flag} {machine or raw[:34]!r:46} "
              f"steps={len(table.splitlines()):2} claims={len(claims)}", flush=True)
        if args.show and turn:
            print(f"      teacher: {turn[:150]}")

    elapsed = time.monotonic() - started
    n = len(records)
    print()
    print(f"items                            : {n}")
    print(f"named a machine in the index     : {selected}/{n} = {selected/n:.0%}")
    print(f"  of those, wrote the OPEN word  : {with_keyword}")
    print(f"Prolog served the machine's steps: {evidence_served}/{n}")
    print(f"Prolog read claims in the dialog : {proved_any}/{n}")
    print(f"produced a teacher turn          : {tutored}/{n}")
    print(f"no reference or gold in prompts  : {leak_free}/{n}")
    print(f"wall clock                       : {elapsed:.0f}s = {elapsed/n:.1f}s/item")
    if args.output:
        args.output.write_text(json.dumps(records, indent=2) + "\n", encoding="utf-8")
        print(f"wrote {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
