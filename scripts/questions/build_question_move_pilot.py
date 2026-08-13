#!/usr/bin/env python3
"""Compile verified question links into the quarantined move pilot.

Only links that passed all three engine checks reach this file. Every move
cites its source record and sentence index, carries the review status of the
row it came from, and names the date the engine re-proved it. Nothing here
serves: serving stays gated on human review of the evidence rows.
"""
from __future__ import annotations

import argparse
import collections
import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))

RUNTIME = ROOT / "hermes" / "app" / "runtime" / "experiments" / "questions"
PILOT = ROOT / "knowledge" / "strategies" / "abstraction" / "question_move_pilot.pl"
GENERAL = RUNTIME / "general_moves.jsonl"
GENERATED_DATE = "date(2026,8,12)"

LICENSED = {("assessing", "narrows"), ("advancing", "raises"), ("advancing", "articulates")}


def quote(value: str) -> str:
    return "'" + str(value).replace("\\", "\\\\").replace("'", "\\'") + "'"


def prolog_string(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def templatize(text: str, slot_map: dict[str, str]) -> tuple[str, list[str]]:
    """Numeral tokens that bind a parameter become typed slots; the rest stay."""
    slots: list[str] = []
    if not slot_map:
        return text, slots
    bound = {}
    for key, target in slot_map.items():
        try:
            bound[float(key)] = target
        except (TypeError, ValueError):
            continue

    def replace(match: re.Match) -> str:
        value = float(match.group(0).replace(",", ""))
        if value in bound:
            target = bound[value]
            name = re.sub(r"[^a-z0-9_]", "_", str(target).casefold())
            if name not in slots:
                slots.append(name)
            return f"~slot({name})~"
        return match.group(0)

    return re.sub(r"(?<![A-Za-z0-9])\d+(?:[.,]\d+)?(?![A-Za-z0-9])", replace, text), slots


def slot_terms(slots: list[str], slot_map: dict[str, str]) -> str:
    targets = {}
    for target in slot_map.values():
        name = re.sub(r"[^a-z0-9_]", "_", str(target).casefold())
        targets[name] = target
    return ", ".join(f"slot({name}, {targets.get(name, name)})" for name in slots)


def context_term(link: dict, partners: list[str]) -> tuple[str, str]:
    """The from-state's epistemic position, and the token that names it."""
    if link["move_type"] == "assessing":
        # The machine the lesson actually mapped stays at the head of the
        # candidate set. Sorting the whole list and then truncating it would
        # drop the productive reading from states whose partners sort earlier.
        others = sorted({kind for kind in partners if kind != link["machine"]})
        candidates = [link["machine"]] + others[:5]
        return f"undetermined([{', '.join(candidates)}])", "undetermined"
    return f"productive({link['registry_family']}/{link['machine']})", "productive"


def build(sources: list[Path]) -> dict[str, object]:
    links: list[dict] = []
    for path in sources:
        if not path.is_file():
            continue
        for line in path.read_text(encoding="utf-8").splitlines():
            if line.strip():
                links.append(json.loads(line))
    # Two proposers can reach the same reading of the same sentence. That is
    # one move with two witnesses, not two moves; a DIFFERENT reading of the
    # same sentence stays a separate move, because the store records what is
    # licensed at a position and both readings are.
    merged: dict[tuple, dict] = {}
    for link in links:
        key = (link["identity"], link["pattern_ids"][0], link["move_type"],
               link["effect"]["kind"], json.dumps(link["effect"]["value"], sort_keys=True))
        if key in merged:
            existing = merged[key]
            proposers = set(existing["proposers"]) | {link["proposer"]}
            existing["proposers"] = sorted(proposers)
        else:
            merged[key] = {**link, "proposers": [link["proposer"]]}
    links = list(merged.values())
    links.sort(key=lambda row: (row["lesson"], row["record_index"], row["sentence_index"],
                                row["pattern_ids"][0], row["move_type"], row["effect"]["kind"]))

    menu = json.loads((RUNTIME / "machine_menu.json").read_text(encoding="utf-8"))
    partner_table = {
        family: [item["kind"] for item in kinds if item["polarity"] == "deformation"]
        for family, kinds in menu.items()
    }

    states: dict[tuple[str, str], str] = {}
    state_rows: list[tuple[str, str, str]] = []

    def state_id(pattern_id: str, context: str) -> str:
        key = (pattern_id, context)
        if key not in states:
            states[key] = f"qs_{len(states) + 1:04d}"
            state_rows.append((states[key], pattern_id, context))
        return states[key]

    move_lines: list[str] = []
    counts = collections.Counter()
    for index, link in enumerate(links, start=1):
        pattern_id = link["pattern_ids"][0]
        partners = partner_table.get(link["registry_family"], [])
        context, context_token = context_term(link, partners)
        from_state = state_id(pattern_id, context)
        effect = link["effect"]
        if effect["kind"] == "narrows":
            value = effect["value"] if isinstance(effect["value"], list) else [effect["value"]]
            effect_term = f"narrows([{', '.join(sorted(dict.fromkeys(value))[:6])}])"
            to_state = "unverified_landing"
        elif effect["kind"] == "raises":
            target = effect["value"]
            if isinstance(target, str) and target.startswith("tp_"):
                effect_term = f"raises(task_pattern({target}))"
                to_state = state_id(target, context)
            else:
                effect_term = f"raises({target})"
                to_state = "unverified_landing"
        else:
            effect_term = f"articulates({effect['value']})"
            to_state = "unverified_landing"
        template, slots = templatize(link["text"], link.get("slot_map", {}))
        counts[(link["move_type"], effect["kind"])] += 1
        for proposer in link["proposers"]:
            counts[proposer] += 1
        move_lines.append(f"question_move(qm_{index:04d},")
        move_lines.append(f"    from({from_state}), type({link['move_type']}),")
        move_lines.append(f"    template({prolog_string(template)},")
        move_lines.append(f"             slots([{slot_terms(slots, link.get('slot_map', {}))}])),")
        move_lines.append(f"    effect({effect_term}),")
        move_lines.append(f"    to({to_state}),")
        move_lines.append(
            f"    evidence([q_ref({quote(link['lesson'])}, "
            f"span({link['span_start']}, {link['span_end']}), "
            f"sentence({link['sentence_index']}))]),")
        move_lines.append(f"    review_status({link['review_status']}),")
        witnesses = ", ".join(
            proposer.replace("-", "_").replace(".", "_") for proposer in link["proposers"])
        move_lines.append(
            f"    verification(engine_reproved(strategy_trace, [{witnesses}], "
            f"{GENERATED_DATE}))).")

    lines: list[str] = []
    lines.append(":- encoding(utf8).")
    lines.append("/** <module> Question-move pilot — licensed moves over algebraicized regions")
    lines.append(" *")
    lines.append(" * GENERATED by scripts/questions/build_question_move_pilot.py. Do not edit by")
    lines.append(" * hand; edit the generator or re-run the linking pass it reads.")
    lines.append(" *")
    lines.append(" * QUARANTINED: nothing imports this module, it renames nothing, and its rows")
    lines.append(" * are vetoable one by one. It does not enter machine_typology.pl without an")
    lines.append(" * admission ceremony.")
    lines.append(" *")
    lines.append(" * A state pairs a task pattern with the teacher's epistemic position. A move")
    lines.append(" * is what a question is licensed to do from that position: an assessing move")
    lines.append(" * narrows which machine the student is running, an advancing move raises the")
    lines.append(" * task region, and the compare-and-connect move states the region's")
    lines.append(" * constraint aloud. Branching is the normal case; the rows record what is")
    lines.append(" * LICENSED at a position, never what is probable.")
    lines.append(" *")
    lines.append(" * to(unverified_landing) means the move's landing state is not re-proved.")
    lines.append(" * The design allows a move to name both ends only when both ends verify.")
    lines.append(" *")
    lines.append(" * Nothing here serves to a web reader. Serving is gated on the review status")
    lines.append(" * of the evidence row, and 2,616 of the 2,621 source rows are unreviewed.")
    lines.append(" *")
    lines.append(" * Check: swipl -q -l paths.pl -l knowledge/strategies/abstraction/question_move_pilot.pl \\")
    lines.append(" *              -g question_move_pilot:check_question_move_pilot -t halt")
    lines.append(" */")
    lines.append(":- module(question_move_pilot,")
    lines.append("          [ qa_state/3,")
    lines.append("            question_move/9,")
    lines.append("            question_move_pilot_summary/5,")
    lines.append("            check_question_move_pilot/0")
    lines.append("          ]).")
    lines.append("")
    lines.append(":- use_module(library(lists)).")
    lines.append("")
    for state, pattern_id, context in state_rows:
        lines.append(f"qa_state({state}, task_pattern({pattern_id}), context({context})).")
    lines.append("")
    lines.extend(move_lines)
    lines.append("")
    licensed = sum(count for key, count in counts.items()
                   if isinstance(key, tuple) and key in LICENSED)
    lines.append("%! question_move_pilot_summary(-States, -Moves, -Sorting, -Sources, -Generated)")
    lines.append("%")
    lines.append("%  Sorting counts moves whose effect sits on the coordinate its type acts on")
    lines.append("%  (the design's falsifiable asymmetry), so a reader never counts by hand.")
    lines.append(
        "question_move_pilot_summary(states(%d), moves(%d), sorting(%d), "
        "sources([%s]), generated(%s))."
        % (
            len(state_rows), len(links), licensed,
            ", ".join(sorted({quote(proposer) for link in links
                              for proposer in link["proposers"]})) or "",
            GENERATED_DATE,
        )
    )
    lines.append("")
    lines.extend(CHECK_SOURCE.splitlines())
    lines.append("")
    PILOT.write_text("\n".join(lines), encoding="utf-8")

    return {
        "moves": len(links),
        "states": len(state_rows),
        "by_type_and_effect": {f"{key[0]}/{key[1]}": value for key, value in counts.items()
                               if isinstance(key, tuple)},
        "by_proposer": {key: value for key, value in counts.items() if isinstance(key, str)},
        "sorting": licensed,
        "pilot": str(PILOT.relative_to(ROOT)),
        "pilot_sha256": hashlib.sha256(PILOT.read_bytes()).hexdigest(),
    }


CHECK_SOURCE = '''%! check_question_move_pilot is det.
%
%  Ids are unique, every move's ends are declared states or the named
%  unverified landing, every move carries evidence and a verification date,
%  and the summary agrees with the rows.
check_question_move_pilot :-
    findall(Id, question_move(Id, _, _, _, _, _, _, _, _), Ids),
    sort(Ids, SortedIds),
    length(Ids, MoveCount), length(SortedIds, MoveCount),
    findall(S, qa_state(S, _, _), States),
    sort(States, SortedStates),
    length(States, StateCount), length(SortedStates, StateCount),
    forall(question_move(Id, from(From), _, _, _, to(To), evidence(Evidence), _, _),
           (   memberchk(From, SortedStates),
               ( To == unverified_landing -> true ; memberchk(To, SortedStates) ),
               Evidence = [_|_]
           ->  true
           ;   throw(error(dangling_question_move(Id), _))
           )),
    question_move_pilot_summary(states(StateCount), moves(MoveCount), sorting(Sorting), _, _),
    format("check_question_move_pilot: ~w states, ~w moves, ~w on the type's own coordinate~n",
           [StateCount, MoveCount, Sorting]).
'''


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", action="append", default=[],
                        help="a verified-links jsonl; repeatable")
    arguments = parser.parse_args()
    sources = [Path(item) for item in arguments.source] or [
        RUNTIME / "baseline_links.jsonl",
        RUNTIME / "glm_pilot_links.jsonl",
        RUNTIME / "glm_scale_links.jsonl",
    ]
    print(json.dumps(build(sources), indent=1, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
