#!/usr/bin/env python3
"""Ask a model to route a description to a machine, twice: once from the index,
once from a same-budget slice of the raw tables.

The index (`knowledge/index/corpus_window.pl` and its `.txt`) was built on a
measured claim: 232 machines and their legend fit in about 12,900 tokens, where
the material behind them runs to roughly 727,000.  That ratio is arithmetic
until somebody asks a question with it, which is what this driver does.

The comparison is between two prompts of the same size:

  window   the whole index, all 232 machines, plus the legend that reads it
  shards   the raw transition-table text for whichever machines a keyword
           overlap ranks highest, truncated to the window's byte budget

Neither condition contains the phrase being asked about.  The question set is
drawn from `automaton_instance_bindings.evidence` — phrases the literature uses
for a strategy, cited and bound to a signature — and every item is filtered to
share no content word with any action label of its own machine.  That filter is
the point: a phrase that shares wording with an action label can be matched
lexically, which would measure the retrieval baseline rather than either prompt.

Scoring is exact on family and signature, with the family recorded separately so
a near miss inside the right family is visible as one.
"""
from __future__ import annotations

import argparse
import collections
import json
import os
import re
import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from hermes.app import llm  # noqa: E402

WINDOW_TXT = ROOT / "knowledge/index/corpus_window.txt"
TABLES = ROOT / "knowledge/strategies/transition_tables"
DISCOURSE = ROOT / "knowledge/discourse/commitment_automata.pl"
DB = ROOT / "data/research/research_shared.db"

TRANS_RE = re.compile(r"(?m)^automaton_transition\((\w+), (\w+), (\w+), (\w+), (\w+),")
REF_RE = re.compile(r"^action_automata_registry:(\w+):(\w+)$")

STOPWORDS = frozenset(
    "the a an of to in as by and or for with on at from into is it that this then "
    "their its one two be was were all not no so if when what which how each any "
    "other more most some such only own same than too very can will just".split()
)


def content_words(text: str) -> set[str]:
    return {w for w in re.findall(r"[a-z]+", text.lower())
            if w not in STOPWORDS and len(w) > 2}


def machine_actions() -> dict[tuple[str, str], list[str]]:
    actions: dict[tuple[str, str], list[str]] = collections.defaultdict(list)
    for path in sorted(TABLES.glob("*.pl")) + [DISCOURSE]:
        if not path.exists():
            continue
        for family, signature, _, action, _ in TRANS_RE.findall(
                path.read_text(encoding="utf-8")):
            actions[(family, signature)].append(action)
    return actions


def machine_shards() -> dict[tuple[str, str], str]:
    """Raw transition-table lines, grouped per machine.  This is the shard text."""
    shards: dict[tuple[str, str], list[str]] = collections.defaultdict(list)
    for path in sorted(TABLES.glob("*.pl")) + [DISCOURSE]:
        if not path.exists():
            continue
        for line in path.read_text(encoding="utf-8").splitlines():
            match = TRANS_RE.match(line)
            if match:
                shards[(match.group(1), match.group(2))].append(line)
    return {key: "\n".join(lines) for key, lines in shards.items()}


def question_set(actions: dict[tuple[str, str], list[str]],
                 limit: int) -> list[dict]:
    """Cited phrases that share no content word with their machine's labels.

    The no-overlap filter removes the lexical shortcut.  Without it this would
    measure keyword retrieval, which is the baseline and not the question.
    """
    connection = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
    try:
        rows = connection.execute(
            "select automaton_ref, evidence from automaton_instance_bindings "
            "where evidence is not null and evidence != '' order by id"
        ).fetchall()
    finally:
        connection.close()

    items: list[dict] = []
    seen_phrases: set[str] = set()
    per_machine: collections.Counter = collections.Counter()
    for ref, evidence in rows:
        match = REF_RE.match(ref or "")
        if not match:
            continue
        key = (match.group(1), match.group(2))
        if key not in actions:
            continue
        label_words: set[str] = set()
        for action in actions[key]:
            label_words |= content_words(action.replace("_", " "))
        for phrase in (p.strip() for p in evidence.split(";")):
            if len(phrase) < 14 or phrase.lower() in seen_phrases:
                continue
            words = content_words(phrase)
            if not words or (words & label_words):
                continue          # lexically reachable: excluded by design
            # also exclude phrases naming the family, another free shortcut
            if key[0] in {w for w in words}:
                continue
            if per_machine[key] >= 2:
                continue          # cap so no machine dominates the score
            seen_phrases.add(phrase.lower())
            per_machine[key] += 1
            items.append({"phrase": phrase, "family": key[0], "signature": key[1]})
    items.sort(key=lambda item: (item["family"], item["signature"], item["phrase"]))
    if limit and len(items) > limit:
        step = len(items) / limit          # even spread, deterministic
        items = [items[int(i * step)] for i in range(limit)]
    return items


def shard_prompt(phrase: str, shards: dict[tuple[str, str], str],
                 budget: int) -> tuple[str, int]:
    """Keyword-overlap retrieval over shard text, truncated to `budget` bytes."""
    words = content_words(phrase)
    scored = []
    for key, text in shards.items():
        overlap = len(words & content_words(text.replace("_", " ")))
        scored.append((overlap, key))
    scored.sort(key=lambda pair: (-pair[0], pair[1]))
    chosen: list[str] = []
    used = 0
    count = 0
    for _, key in scored:
        block = f"% {key[0]}/{key[1]}\n{shards[key]}\n"
        if used + len(block) > budget:
            break
        chosen.append(block)
        used += len(block)
        count += 1
    return "".join(chosen), count


ASK = (
    "A researcher describes a student's mathematical method with this phrase:\n\n"
    "    \"{phrase}\"\n\n"
    "Name the one machine from the material above whose steps that phrase "
    "describes.\n"
    "Answer with exactly one line and nothing else, in the form:\n"
    "    family/signature\n"
    "If the material does not contain a machine for it, answer:\n"
    "    none"
)

WINDOW_FRAME = (
    "Below is an index of every finite-state machine in a mathematics-education "
    "knowledge base. Each line gives a machine's family and signature, the "
    "normative arc its steps spell, and its steps grouped as shell (preparing or "
    "transforming the problem), core (the iterative or operative work), closure "
    "(what it records), and other.\n\n{material}\n\n"
)

SHARD_FRAME = (
    "Below are raw transition rows from a mathematics-education knowledge base, "
    "for the machines most lexically similar to the question. Each row is "
    "automaton_transition(Family, Signature, FromState, Action, ToState, ...).\n\n"
    "{material}\n\n"
)

ANSWER_RE = re.compile(r"([a-z_]+)\s*/\s*([a-z_0-9]+)")


def parse_answer(reply: str) -> tuple[str, str] | None:
    for line in reply.strip().splitlines():
        cleaned = line.strip().strip("`*_ .")
        if cleaned.lower() in ("none", "none."):
            return None
        match = ANSWER_RE.search(cleaned)
        if match:
            return match.group(1), match.group(2)
    return None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--items", type=int, default=30)
    parser.add_argument("--output", type=Path,
                        default=ROOT / "data/research/window_vs_shards.json")
    parser.add_argument("--dry-run", action="store_true",
                        help="build both prompts and report sizes; call nothing")
    args = parser.parse_args()

    actions = machine_actions()
    shards = machine_shards()
    window = WINDOW_TXT.read_text(encoding="utf-8")
    budget = len(window)

    items = question_set(actions, args.items)
    if not items:
        print("FAIL: no lexically-independent question items found", file=sys.stderr)
        return 1
    print(f"question items: {len(items)} over "
          f"{len({(i['family'], i['signature']) for i in items})} machines")
    print(f"window budget: {budget} bytes (~{budget // 4} tokens)")

    if args.dry_run:
        material, count = shard_prompt(items[0]["phrase"], shards, budget)
        print(f"shard slice at that budget holds {count} of {len(shards)} machines")
        print(f"window holds {window.count(chr(10))} lines, all {len(shards)} machines")
        for item in items[:8]:
            print(f"  {item['family']}/{item['signature']}: \"{item['phrase']}\"")
        return 0

    client = llm.make_client(ROOT)
    print(f"model: {client['model']}")
    results = []
    for index, item in enumerate(items, 1):
        record = {**item, "conditions": {}}
        for condition in ("window", "shards"):
            if condition == "window":
                material, held = window, len(shards)
            else:
                material, held = shard_prompt(item["phrase"], shards, budget)
            frame = WINDOW_FRAME if condition == "window" else SHARD_FRAME
            prompt = frame.format(material=material) + ASK.format(phrase=item["phrase"])
            try:
                reply = llm.call_api_messages(
                    [{"role": "user", "content": prompt}],
                    retries=2, timeout=300, fail_on_error=False, **client)
            except Exception as exc:                      # noqa: BLE001
                reply = f"<error: {exc}>"
            answer = parse_answer(reply or "")
            record["conditions"][condition] = {
                "machines_held": held,
                "prompt_bytes": len(prompt),
                "reply": (reply or "").strip()[:400],
                "answer": list(answer) if answer else None,
                "exact": bool(answer and answer == (item["family"], item["signature"])),
                "family_right": bool(answer and answer[0] == item["family"]),
            }
        results.append(record)
        marks = "".join("W" if results[-1]["conditions"][c]["exact"] else
                        ("f" if results[-1]["conditions"][c]["family_right"] else ".")
                        for c in ("window", "shards"))
        print(f"  [{index}/{len(items)}] {marks}  {item['family']}/{item['signature']}",
              flush=True)

    summary = {}
    for condition in ("window", "shards"):
        exact = sum(1 for r in results if r["conditions"][condition]["exact"])
        family = sum(1 for r in results if r["conditions"][condition]["family_right"])
        abstain = sum(1 for r in results if r["conditions"][condition]["answer"] is None)
        summary[condition] = {"exact": exact, "family_right": family,
                              "abstained": abstain, "n": len(results)}

    payload = {"model": client["model"], "window_budget_bytes": budget,
               "total_machines": len(shards), "summary": summary, "items": results}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n",
                           encoding="utf-8")
    print()
    for condition, counts in summary.items():
        print(f"{condition:7} exact {counts['exact']}/{counts['n']}  "
              f"family {counts['family_right']}/{counts['n']}  "
              f"abstained {counts['abstained']}")
    print(f"wrote {args.output.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
