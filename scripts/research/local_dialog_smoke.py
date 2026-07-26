#!/usr/bin/env python3
"""Run the machine-selection protocol locally, in minutes, before spending a cluster.

Cycle 1 spent twelve GPU chunks and three hours to learn that 45% of replies named
an openable machine. That number was visible in the first ten items, and the run
that measured it cannot tell two very different causes apart:

  the model did not choose a machine
  the model chose one and the parser did not accept the reply

`MACHINE_LINE` anchors with `\\Z`, so a reply ending in anything after the name —
a period, a clause of explanation — yields no match and is counted with the
refusals. This driver prints every unparsed reply verbatim, which is the only way
to separate the two.

It runs against a local Ollama endpoint, which is not a testing shortcut: the
claim being built is a system a teacher's laptop can run, so the laptop is the
deployment target and exercising it is the point. The cluster is for the 360-item
score, not for finding protocol bugs.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WINDOW = ROOT / "knowledge/index/corpus_window.txt"
ENDPOINT = "http://localhost:11434/v1/chat/completions"

MACHINE_LINE = re.compile(r"OPEN ([a-z][a-z0-9_]*)/([a-z][a-z0-9_]*)\Z")
LENIENT_LINE = re.compile(r"OPEN\s+([a-z][a-z0-9_]*)\s*/\s*([a-z][a-z0-9_]*)")
WINDOW_LINE = re.compile(r"^  ([a-z][a-z0-9_]*)/([a-z][a-z0-9_]*) arc=", re.MULTILINE)

SELECT_SYSTEM = """Choose one Hermes machine that could help frame the next
tutor move. The index is a menu, not evidence that any machine diagnoses this
student. Return exactly one line in this form:
OPEN family/signature

Use only a name present in the supplied index. Do not explain the choice."""

# Stand-in student turns. These are not benchmark items and no score is computed
# here; the question is whether the protocol survives contact with a small model.
CASES = [
    "Student: I think three fifths is bigger than two thirds because five is bigger than three.",
    "Student: I did 47 plus 28 by making it 50 plus 25.",
    "Student: For 7 divided by 1/2 I got 3 and a half.",
    "Student: I added the tops and the bottoms so 1/2 plus 1/3 is 2/5.",
    "Student: There are 24 cookies and 6 kids so each one gets 4.",
    "Student: I lined up the decimal points and then added.",
    "Student: 0.5 is smaller than 0.25 because 5 is smaller than 25.",
    "Student: I counted on from 8 to get to 13, so it's 5.",
    "Student: The scale factor is 3 so the area is 3 times bigger.",
    "Student: I split the 12 into 10 and 2 to multiply by 6.",
    "Student: Two thirds of 9 is 6 because I did 9 divided by 3 times 2.",
    "Student: I borrowed from the 0 so I took from the next one over.",
]


def chat(model: str, system: str, user: str, timeout: int) -> str:
    payload = json.dumps({
        "model": model,
        "messages": [{"role": "system", "content": system},
                     {"role": "user", "content": user}],
        "stream": False,
        "options": {"num_predict": 32, "temperature": 0.0},
    }).encode("utf-8")
    request = urllib.request.Request(
        ENDPOINT, data=payload, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(request, timeout=timeout) as response:
        body = json.load(response)
    return body["choices"][0]["message"]["content"]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model", default="gemma:2b")
    parser.add_argument("--items", type=int, default=12)
    parser.add_argument("--timeout", type=int, default=180)
    parser.add_argument("--window-machines", type=int, default=0,
                        help="0 = the whole 232-machine window; a positive number "
                             "offers only that many, to test whether menu size is "
                             "the binding constraint")
    args = parser.parse_args()

    window = WINDOW.read_text(encoding="utf-8")
    known = {f"{f}/{s}" for f, s in WINDOW_LINE.findall(window)}
    if args.window_machines:
        keep = sorted(known)[:args.window_machines]
        lines = [ln for ln in window.splitlines()
                 if not ln.startswith("  ") or
                 any(ln.strip().startswith(k + " ") for k in keep)]
        window = "\n".join(lines)
        offered = set(keep)
    else:
        offered = known
    print(f"model {args.model}; window offers {len(offered)} of {len(known)} machines; "
          f"{len(window)} chars (~{len(window)//4} tokens)")

    strict = lenient = named_unknown = errors = 0
    unparsed: list[str] = []
    for index, case in enumerate(CASES[:args.items], start=1):
        user = f"MACHINE INDEX\n\n{window}\n\n{case}"
        try:
            reply = chat(args.model, SELECT_SYSTEM, user, args.timeout).strip()
        except (urllib.error.URLError, TimeoutError, KeyError) as exc:
            errors += 1
            print(f"  [{index}] ERROR {type(exc).__name__}")
            continue
        strict_hit = MACHINE_LINE.search(reply)
        lenient_hit = LENIENT_LINE.search(reply)
        if strict_hit:
            strict += 1
        if lenient_hit:
            lenient += 1
            name = f"{lenient_hit.group(1)}/{lenient_hit.group(2)}"
            if name not in offered:
                named_unknown += 1
        if not strict_hit:
            unparsed.append(reply)
        mark = "S" if strict_hit else ("L" if lenient_hit else ".")
        print(f"  [{index}] {mark} {reply[:70]!r}", flush=True)

    n = min(args.items, len(CASES)) - errors
    if n <= 0:
        print("FAIL: no successful calls", file=sys.stderr)
        return 1
    print()
    print(f"items                      : {n}")
    print(f"strict parse (\\Z anchored) : {strict}/{n} = {strict/n:.0%}")
    print(f"lenient parse (name found) : {lenient}/{n} = {lenient/n:.0%}")
    print(f"named a machine not offered: {named_unknown}")
    if lenient > strict:
        print()
        print(f"*** {lenient - strict} replies named a machine the strict regex rejected.")
        print("    A run reporting only the strict rate would attribute those to the")
        print("    model declining to choose. They are parser losses, not refusals.")
    if unparsed:
        print()
        print("replies the strict parser rejected, verbatim:")
        for reply in unparsed[:6]:
            print(f"  {reply[:160]!r}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
