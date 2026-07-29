#!/usr/bin/env python3
"""Measure the claim pipeline against a witness it did not produce.

Every reader in this repo can be checked against its own source, and that is
exactly what lets a bad reading survive: the reader and the check agree because
they are the same reading twice. `4 x 5 = 20` parses one way, `4 × 5 = 20`
parses to `arithmetic_equation(5, 20)` and is adjudicated `refuted` with a
confident trace, and nothing internal to the pipeline can tell that a true claim
was just called false.

The teacher guides supply a witness from outside, in two blocks that answer each
other. The Student Task Statement prints the statements to judge; the Student
Response prints the judgements, in the same order:

    Student Task Statement                     Launch
     Decide if each statement is true or false.  • Display one statement.
       • 10 = 10
       • 4 + 6 = 10
       • 2 + 7 = 10
    Student Response
      • True: A number equals a number.         • Repeat with each equation.
      • True: 4 + 6 is the same amount as 10.
      • False: 9 is the same amount as 2 + 7.

That block pair is the key, and it is the only defensible one. The ground beside
each verdict is *reasoning*, not a restatement: a False verdict is commonly
justified by stating what is true instead ("False: 20 + 20 = 40, and I know you
would need at least..."), so keying on the ground's quantities would score the
checker wrong precisely where it is right. And keying on the order of claims
read from the whole guide is worse still — an earlier form of this script did
that and paired three verdicts in
`grade2/unit6/lesson20.md` against arithmetic from a different activity a
hundred lines away, one of which then "agreed" by coincidence.

So items come from the task-statement span, read through the action-mapping
compiler's own extractor, which strips the teacher's right column and therefore
cannot bleed launch commentary into a statement. Where the markdown blanked the
expressions (the guides draw them as filled outlines), the recovered sidecar
supplies them, keyed by the same lesson and span position.

Those verdicts were authored by the curriculum. No reader here produced them, so
agreement between them and the grounded checker is evidence, and disagreement is
a quarantine signal rather than a puzzle to resolve by preferring one side.

This script measures the agreement rate. It is an instrument, not a gate: it
asserts nothing about which side is right when they differ, and it writes no
claim into any register.

    python3 scripts/research/measure_claim_agreement.py
    python3 scripts/research/measure_claim_agreement.py --report out.json
"""
from __future__ import annotations

import argparse
import json
import pathlib
import re
import subprocess
import sys
from collections import Counter

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "curriculum"))

import compile_action_mappings as compiler  # noqa: E402

TRUE_OR_FALSE = re.compile(r"true or false", re.I)

# "Student Response 1. True 2. False" and its bolded variants. The number is the
# item it answers.
NUMBERED_VERDICT = re.compile(r"(\d+)\s*[.):]\s*\**\s*(True|False)\b", re.I)
# The commoner shape by far: the guide answers in item order with the ground
# attached, "• True: 4 + 6 is the same amount as 10."
BULLET_VERDICT = re.compile(r"[•*]\s*\**\s*(True|False)\b\s*[:.]", re.I)

BULLET_ITEM = re.compile(r"^\s*[•*]\s*")
NUMBERED_ITEM = re.compile(r"^\s*(\d+)[.)]\s+")
# The sidecar delivers a span as one flow, so its item boundaries are the
# bullets and numbers inside the text rather than physical lines.
INLINE_ITEM_SPLIT = re.compile(r"\s*[•*]\s*|\s+(?=\d+\.\s)")
# An item is a bare statement to judge. Anything carrying words is the prompt,
# the "If you have time" tail, or an instruction, and ends the item list. The
# fraction words the guides use for unit-fraction comparisons are admitted by
# name rather than by loosening the rule.
FRACTION_WORD = (
    r"half|halves|third|thirds|fourth|fourths|quarter|quarters|fifth|fifths|"
    r"sixth|sixths|seventh|sevenths|eighth|eighths|ninth|ninths|tenth|tenths|"
    r"one|two|three|four|five|six|seven|eight|nine|ten"
)
ITEM_WORD = re.compile(rf"\b(?!(?:{FRACTION_WORD})\b)[A-Za-z]{{2,}}\b")
ITEM_RELATION = re.compile(r"[=<>]|\bis\b")
ITEM_NUMERAL = re.compile(r"\d")


def response_blocks(path: pathlib.Path) -> list[str]:
    """The Student Response text, with the teacher's right column removed.

    The column boundary is inherited from the nearest preceding Student Task
    Statement heading, which carries the "Launch" header the compiler uses for
    exactly this purpose. Without the boundary a response bullet keeps the
    launch commentary printed beside it, and "Activity Synthesis" arrives inside
    a verdict's ground.
    """
    raw_lines = path.read_text(encoding="utf-8", errors="replace").split("\n")
    blocks: list[str] = []
    right_column: int | None = None
    for index, raw_heading in enumerate(raw_lines):
        heading = raw_heading.lstrip("\f ")
        if heading.startswith("Student Task Statement"):
            launch_column = raw_heading.find("Launch")
            right_column = max(launch_column - 2, 0) if launch_column >= 0 else None
            continue
        if not heading.startswith("Student Response"):
            continue
        lines = []
        for next_index in range(index + 1, min(len(raw_lines), index + 121)):
            stripped = raw_lines[next_index].lstrip("\f ")
            if stripped.startswith("Student Response") or stripped.startswith(
                "Student Task Statement"
            ):
                break
            lines.append(compiler._student_column(raw_lines[next_index], right_column))
        blocks.append("\n".join(lines))
    return blocks


def printed_verdicts(block: str) -> tuple[list[str], str]:
    """The guide's own answers for one response block, in item order."""
    numbered: dict[int, str] = {}
    for number, verdict in NUMBERED_VERDICT.findall(block):
        index = int(number)
        token = verdict.lower()
        if index in numbered and numbered[index] != token:
            # The same item answered twice, differently. Refuse the block
            # rather than pick one.
            return [], "conflicting"
        numbered[index] = token
    if numbered:
        # The numbers must run 1..N. A gap would otherwise close silently and
        # shift every verdict after it onto the wrong statement, which is the
        # defect this whole instrument was re-keyed to remove.
        if sorted(numbered) != list(range(1, len(numbered) + 1)):
            return [], "gapped"
        return [numbered[key] for key in sorted(numbered)], "numbered"
    bulleted = [v.lower() for v in BULLET_VERDICT.findall(block)]
    if bulleted:
        return bulleted, "bulleted"
    return [], "absent"


def statement_item(fragment: str) -> bool:
    """Whether a fragment is a statement to judge rather than prose."""
    text = fragment.strip()
    if not text or not ITEM_NUMERAL.search(text) or not ITEM_RELATION.search(text):
        return False
    return not ITEM_WORD.search(text)


def span_items(span) -> list[str]:
    """The statements a task-statement span asks students to judge.

    The list ends at the first fragment that is not a bare statement, which is
    how the "If you have time" tail and the closing instructions stay out of it.
    """
    if span.recovered:
        fragments = INLINE_ITEM_SPLIT.split(span.text)
        fragments = [NUMBERED_ITEM.sub("", part) for part in fragments]
    else:
        fragments = []
        current: str | None = None
        for _line, text in span.lines:
            if BULLET_ITEM.match(text) or NUMBERED_ITEM.match(text):
                if current is not None:
                    fragments.append(current)
                current = NUMBERED_ITEM.sub("", BULLET_ITEM.sub("", text)).strip()
            elif current is not None:
                current += " " + text.strip()
        if current is not None:
            fragments.append(current)
    items = []
    for fragment in fragments:
        if statement_item(fragment):
            items.append(fragment.strip())
        elif items:
            break
    return items


def checker_verdicts(probes: list[tuple[str, str]]) -> dict[str, list[dict]]:
    """Run the repo's own reader and checker over each item, via swipl.

    Shelling out keeps the one loader rule: this measures the same predicates
    the worker serves, not a Python re-implementation of them.
    """
    # The item texts go into the probe file as facts, never onto the command
    # line: the corpus overflows the argv limit.
    def pl_string(value: str) -> str:
        return '"' + value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'

    facts = "\n".join(
        f"probe_span({pl_string(key)}, {pl_string(text)})." for key, text in probes)
    script = (
        ':- use_module(hermes(math_claim_language), [math_claims_in_text/2]).\n'
        ':- use_module(hermes(math_claim_checker), [check_math_claim/2]).\n'
        ':- dynamic probe_span/2.\n'
        + facts + "\n"
        + "probe_all :- forall(probe_span(K, T),\n"
          "    ( ( math_claim_language:math_claims_in_text(T, Cs) -> true ; Cs = [] ),\n"
          "      forall(member(C, Cs),\n"
          "        ( catch(math_claim_checker:check_math_claim(C, V), _, V = error),\n"
          "          ( is_dict(V) -> get_dict(verdict, V, Vd) ; Vd = error ),\n"
          '          format("ROW\\t~w\\t~q\\t~w~n", [K, C, Vd]) )) )).\n'
    )
    goal = "probe_all, halt."
    tmp = ROOT / "scripts" / "research" / "_claim_agreement_probe.pl"
    tmp.write_text(script, encoding="utf-8")
    try:
        done = subprocess.run(
            ["swipl", "-q", "-l", "paths.pl", "-s", str(tmp), "-g", goal],
            cwd=ROOT, capture_output=True, text=True, timeout=900)
    finally:
        tmp.unlink(missing_ok=True)
    rows: dict[str, list[dict]] = {}
    for line in done.stdout.splitlines():
        if not line.startswith("ROW\t"):
            continue
        _, key, claim, verdict = line.split("\t", 3)
        rows.setdefault(key, []).append({"claim": claim, "verdict": verdict})
    return rows


def collect_blocks() -> list[dict]:
    """Pair each true/false task-statement span with the response that answers it."""
    docs = compiler.read_teacher_guides(ROOT)
    spans = compiler.extract_student_task_spans(docs)
    recovered = {
        (span.code, span.position): span
        for span in compiler.read_recovered_task_spans(ROOT, spans)
    }
    guide_path = {doc.code: doc.path for doc in docs}
    responses: dict[str, list[str]] = {}
    paired = []
    for span in spans:
        if not TRUE_OR_FALSE.search(span.text):
            continue
        items = span_items(span)
        source = "markdown"
        if not items and (span.code, span.position) in recovered:
            items = span_items(recovered[(span.code, span.position)])
            source = "recovered"
        path = guide_path[span.code]
        if span.code not in responses:
            responses[span.code] = response_blocks(path)
        # Span position N is answered by response block N.
        index = int(span.position[len("student_task_statement("):-1]) - 1
        blocks = responses[span.code]
        block = blocks[index] if index < len(blocks) else ""
        verdicts, shape = printed_verdicts(block)
        paired.append({
            "guide": str(path.relative_to(ROOT)),
            "lesson": span.code,
            "position": span.position,
            "items": items,
            "item_source": source,
            "verdicts": verdicts,
            "shape": shape,
        })
    return paired


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=pathlib.Path)
    parser.add_argument("--limit", type=int)
    arguments = parser.parse_args()

    blocks = collect_blocks()
    if arguments.limit:
        blocks = blocks[: arguments.limit]

    probes = []
    for index, block in enumerate(blocks):
        for position, item in enumerate(block["items"], start=1):
            probes.append((f"{index}:{position}", item))
    produced = checker_verdicts(probes)

    status = Counter()
    detail = []
    for index, block in enumerate(blocks):
        status["spans"] += 1
        status[f"shape_{block['shape']}"] += 1
        status["printed_verdicts"] += len(block["verdicts"])
        status["items"] += len(block["items"])
        if block["item_source"] == "recovered":
            status["spans_items_from_sidecar"] += 1
        outcome = None
        if not block["items"]:
            outcome = "no_items"
        elif not block["verdicts"]:
            outcome = "no_verdicts"
        elif len(block["items"]) != len(block["verdicts"]):
            outcome = "count_mismatch"
        if outcome:
            status[f"spans_{outcome}"] += 1
            detail.append({**{k: block[k] for k in ("guide", "position", "shape")},
                           "outcome": outcome,
                           "items": len(block["items"]),
                           "printed": len(block["verdicts"])})
            continue
        rows = []
        unread = 0
        for position, item in enumerate(block["items"], start=1):
            claims = produced.get(f"{index}:{position}", [])
            status["claims_read"] += len(claims)
            if len(claims) != 1:
                unread += 1
                rows.append({"item": item, "printed": block["verdicts"][position - 1],
                             "checker": "unread", "claims": len(claims),
                             "agree": False})
                continue
            printed = block["verdicts"][position - 1]
            read = claims[0]["verdict"]
            mapped = {"holds": "true", "refuted": "false"}.get(read, read)
            rows.append({"item": item, "printed": printed, "checker": read,
                         "claim": claims[0]["claim"], "agree": mapped == printed})
        # A span whose statements the reader cannot read is not a disagreement.
        # It is reported as the reader's silence and left out of the rate.
        if unread == len(rows):
            status["spans_reader_silent"] += 1
            detail.append({**{k: block[k] for k in ("guide", "position", "shape")},
                           "outcome": "reader_silent", "items": len(rows)})
            continue
        judged = [row for row in rows if row["checker"] != "unread"]
        agree = sum(1 for row in judged if row["agree"])
        status["spans_aligned"] += 1
        status["aligned_items"] += len(judged)
        status["items_unread"] += unread
        status["agreements"] += agree
        status["disagreements"] += len(judged) - agree
        detail.append({**{k: block[k] for k in ("guide", "position", "shape")},
                       "outcome": "aligned", "item_source": block["item_source"],
                       "agree": agree, "of": len(judged), "rows": rows})

    print("claim agreement against the guides' printed verdicts")
    for key in ("spans", "shape_numbered", "shape_bulleted", "shape_absent",
                "shape_gapped", "shape_conflicting",
                "items", "spans_items_from_sidecar", "printed_verdicts",
                "spans_no_items", "spans_no_verdicts", "spans_count_mismatch",
                "spans_reader_silent", "spans_aligned",
                "claims_read", "items_unread",
                "aligned_items", "agreements", "disagreements"):
        print(f"  {key}={status.get(key, 0)}")
    aligned = status.get("aligned_items", 0)
    if aligned:
        rate = status.get("agreements", 0) / aligned
        print(f"  agreement_rate={rate:.3f} over {aligned} aligned items")
    else:
        print("  agreement_rate=unmeasurable; no span aligned")
    print("  NOTE: alignment needs the same number of statements as verdicts, so"
          " the rate is measured on the subset whose two blocks agree in count.")

    if arguments.report:
        arguments.report.write_text(
            json.dumps({"counts": dict(status), "spans": detail}, indent=2) + "\n",
            encoding="utf-8")
        print(f"wrote {arguments.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
