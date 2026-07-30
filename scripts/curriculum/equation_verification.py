#!/usr/bin/env python3
"""The equation-verification task kind: a printed equation and the guide's own judgment.

The True-or-False instructional routine prints an equation and asks the student
to say whether it holds.  The doing is a verification, so the task this module
compiles is a verification: the claim term is the equation, the verdict and the
reason trace come from the registered claim checkers in
``hermes/math_claim_checker.pl``, and the witness is the judgment the guide
prints in its own Student Response block, cited by physical line.

Three things separate this lane from a plausible-looking reader.

*The witness is a truth value, and truth values are cheap.*  A printed "False"
next to any equation would satisfy a naive gate, so the gate here is the whole
sequence: the response block has to carry exactly as many printed judgments as
the span carries printed equations, and every computed verdict has to agree
with the judgment at its own index.  A misaligned reading fails on the first
equation whose truth value differs from its neighbour's, and the routine's
batteries mix true with false by construction.  A span whose printed judgments
are all the same value is recorded with that stated: the alignment is
unconstrained there, and it is also harmless, because every index carries the
same judgment either way.

*A disagreement is a finding, not a row to drop quietly.*  When a computed
verdict contradicts the printed judgment the whole span is refused and the
disagreement is recorded with both values.  Either the reader segmented the
guide wrongly or a checker is wrong; both are worth knowing and neither is
worth counting.

*Equations are consumed whole.*  A side of an equation yields a runnable task
only when that side is exactly one binary operation.  ``7 + 3 + 4`` yields
nothing, because ``add(7, 3)`` would be a slice of a longer printed
computation; ``10 + 4`` on the other side of the same equals sign yields
``add(10, 4)``, because that is the entire side.  The excerpt cited by every
emitted task is the complete equation.
"""

from __future__ import annotations

import json
import re
import subprocess
import tempfile
from dataclasses import dataclass, field, asdict
from pathlib import Path


# The routine's prompt, in the spellings the K-5 guides actually print.  The
# corpus survey behind this pattern found "Decide if each statement ..." on 66
# lessons and five further phrasings on one or two each; the pattern covers the
# stated forms rather than guessing at unstated ones.
ROUTINE_PROMPT_RE = re.compile(
    r"\b(?:decide|determine|tell)\s+(?:if|whether)\s+each\s+"
    r"(?:equation|statement|comparison|expression)\b",
    re.IGNORECASE,
)

# Whole numerals only.  A digit beside a solidus is a fraction component and a
# digit beside a period is a decimal; neither belongs to this lane, so both are
# refused at the numeral rather than filtered afterwards.
NUMERAL = r"(?<![\d.,/])(?:\d{1,3}(?:,\d{3})+|\d+)(?![\d,]|\.\d|/\d)"
OPERATOR = r"[+\-−×·÷]"
SIDE = rf"{NUMERAL}(?:\s*{OPERATOR}\s*{NUMERAL})*"
EQUATION_RE = re.compile(rf"(?P<lhs>{SIDE})\s*=\s*(?P<rhs>{SIDE})")
OPERAND_SPLIT_RE = re.compile(rf"(?P<operator>{OPERATOR})")

# A judgment is the first word of a response item, after whatever list marker
# the guide prints.  Requiring the token to open the item is what keeps a
# "true" buried in explanatory prose from being read as a verdict.
JUDGMENT_RE = re.compile(
    r"^(?:[•\-\*]\s*|\d+\.\s*|[a-z]\.\s*)*(?P<judgment>True|False)\b",
    re.IGNORECASE,
)
# The guides lay two columns into one text line.  A run of three or more spaces
# is the gutter; prose does not carry one.
COLUMN_GUTTER_RE = re.compile(r"\s{3,}")

OPERATION_BY_SYMBOL = {
    "+": ("addition", "add"),
    "-": ("subtraction", "subtract"),
    "−": ("subtraction", "subtract"),
    "×": ("multiplication", "multiply"),
    "·": ("multiplication", "multiply"),
    "÷": ("division", "divide"),
}
# Only these two operations have a registered whole-number claim checker that
# stays inside the grounded substrate.  Everything else is adjudicated by the
# arithmetic equality checker, which says so in its own checker name.
GROUNDED_CLAIM_BY_OPERATION = {
    "addition": "sum",
    "subtraction": "subtraction",
}
# The grounded checkers build one recollection per unit and take away one unit
# at a time, so their cost rises with the magnitude, not with the number of
# digits.  Measured on this tree: a grounded subtraction from 5,000 returns in
# 0.19s, from 20,000 in 0.62s, from 50,000 in 3.11s, and the grade-4 place-value
# item 423,450 - 42,345 = 105 does not return inside four minutes.  That is the
# counting model saying what it is; counting to four hundred thousand is not a
# doing.  Above the bound the equation still gets a verdict and a trace, from
# the arithmetic equality checker, and the row says which route adjudicated it.
GROUNDED_MAGNITUDE_BOUND = 10000
BOUNDARY_TOKENS = set("+-−×·÷=")

WITNESS_CLASS = "printed_judgment"
STATED_RESULT_RULE = "equation_verification_stated_result"
SIDE_RULE = "equation_verification_side"


@dataclass
class EquationTask:
    """One runnable doing a printed equation asks for, and where it is printed."""

    side: str
    task: str
    operation: str
    rule_id: str
    left: int
    right: int
    status: str = "reviewable"
    reason: str = ""


@dataclass
class EquationRow:
    """One printed equation, its claim, its witness, and its adjudication."""

    lesson: str
    position: str
    item: int
    equation: str
    equation_source: str
    span_source: str
    equation_line: int
    equation_end_line: int
    span_line: int
    span_end_line: int
    claim: str
    claim_family: str
    claim_route: str
    witness_source: str
    witness_line: int
    witness_judgment: str
    witness_fragment: str
    printed_reasoning: str
    printed_reasoning_lines: tuple[int, int]
    tasks: list[EquationTask] = field(default_factory=list)
    verdict: str = ""
    checker: str = ""
    status: str = ""
    reason_trace: list[str] = field(default_factory=list)
    viability: list[dict] = field(default_factory=list)
    accepted: bool = False
    refusal: str = ""


@dataclass
class SpanReading:
    """Every equation of one routine span, kept together because the gate is."""

    lesson: str
    position: str
    equation_source: str
    rows: list[EquationRow] = field(default_factory=list)
    refusal: str = ""
    witness_alignment: str = ""
    equation_count: int = 0
    judgment_count: int = 0


def _column_text(raw_line: str, right_column: int | None) -> str:
    """The left-column text of a guide line, without the facing teacher column."""
    clean = raw_line.replace("\f", " ", 1)
    if right_column is not None and len(clean) > right_column:
        clean = clean[:right_column]
    return clean.strip()


def _judgment_fragment(raw_line: str, right_column: int | None) -> str:
    """The printed judgment item as one verbatim slice of its own line."""
    text = _column_text(raw_line, right_column)
    gutter = COLUMN_GUTTER_RE.search(text)
    if gutter is not None:
        text = text[: gutter.start()]
    return text.strip()


def _numeral(token: str) -> int:
    return int(token.replace(",", ""))


def _side_operands(side_text: str) -> list[tuple[int, str, int]]:
    """The binary operations printed on one side, left to right."""
    parts = [part.strip() for part in re.split(rf"({OPERATOR})", side_text) if part.strip()]
    pairs = []
    for index in range(1, len(parts) - 1, 2):
        pairs.append((_numeral(parts[index - 1]), parts[index], _numeral(parts[index + 1])))
    return pairs


def _side_operator_count(side_text: str) -> int:
    return len(OPERAND_SPLIT_RE.findall(side_text))


def _prolog_expression(side_text: str) -> str:
    """The side as an SWI arithmetic expression, printed operators preserved."""
    out = []
    for token in re.split(rf"({OPERATOR})", side_text):
        token = token.strip()
        if not token:
            continue
        if OPERAND_SPLIT_RE.fullmatch(token):
            out.append({"+": "+", "-": "-", "−": "-",
                        "×": "*", "·": "*", "÷": "//"}[token])
        else:
            out.append(str(_numeral(token)))
    return " ".join(out)


def _grounded_side(side_text: str) -> tuple[str, int] | None:
    """Compile one printed side to a grounded left-to-right fold and its peak.

    The step representation is left-to-right by construction. A side that
    mixes multiplication with addition or subtraction therefore stays on the
    SWI arithmetic route, where standard precedence is preserved.

    The peak is the largest absolute intermediate value or printed operand.
    It applies ``GROUNDED_MAGNITUDE_BOUND`` per side before Prolog constructs
    any recollection. Division is outside this whole-number fold; its existing
    arithmetic route remains explicit.
    """
    parts = [
        part.strip()
        for part in re.split(rf"({OPERATOR})", side_text)
        if part.strip()
    ]
    symbols = parts[1::2]
    has_multiplication = any(symbol in {"×", "·"} for symbol in symbols)
    has_addition_or_subtraction = any(
        symbol in {"+", "-", "−"} for symbol in symbols
    )
    if has_multiplication and has_addition_or_subtraction:
        return None
    start = _numeral(parts[0])
    value = start
    peak = start
    steps = []
    for symbol, raw_operand in zip(parts[1::2], parts[2::2]):
        operand = _numeral(raw_operand)
        operation = {
            "+": "add",
            "-": "subtract",
            "−": "subtract",
            "×": "multiply",
            "·": "multiply",
        }.get(symbol)
        if operation is None:
            return None
        steps.append(f"{operation}({operand})")
        if operation == "add":
            value += operand
        elif operation == "subtract":
            value -= operand
        else:
            value *= operand
        peak = max(peak, operand, abs(value))
    return f"side({start}, [{', '.join(steps)}])", peak


def _equation_is_maximal(text: str, match: re.Match) -> bool:
    """Refuse an equation that is one link of a longer printed chain."""
    before = text[: match.start()].rstrip()
    after = text[match.end():].lstrip()
    if before and before[-1] in BOUNDARY_TOKENS:
        return False
    if after and after[0] in BOUNDARY_TOKENS:
        return False
    return True


def find_equations(span_lines: tuple[tuple[int, str], ...]) -> list[tuple[str, str, str, int]]:
    """Every complete, maximal printed equation in one prompt, in printed order.

    The line number travels with the equation because provenance is per
    equation, not per span: a guide prints its True-or-False items one to a
    line, and a sidecar pseudo-span carries line zero exactly as the recovered
    lane already does.
    """
    text = " ".join(line_text for _, line_text in span_lines).strip()
    starts: list[tuple[int, int]] = []
    offset = 0
    for index, (line_number, line_text) in enumerate(span_lines):
        starts.append((offset, line_number))
        offset += len(line_text)
        if index + 1 < len(span_lines):
            offset += 1
    found = []
    for match in EQUATION_RE.finditer(text):
        if not _equation_is_maximal(text, match):
            continue
        first = last = 0
        for start, candidate in starts:
            if start <= match.start():
                first = candidate
            if start < match.end():
                last = candidate
        found.append((match.group(0).strip(), match.group("lhs").strip(),
                      match.group("rhs").strip(), first, last))
    return found


def _claim_term(lhs: str, rhs: str) -> tuple[str, str, str]:
    """The registered claim term for one printed equation.

    A stated-result equation within the counting bound reaches the grounded
    whole-number checkers, whose trace names the counting acts.  Everything
    else reaches the arithmetic equality checker, whose name records that it is
    the red pen and not the grounded route.  The third value says which of
    those happened and why.
    """
    left_ops = _side_operator_count(lhs)
    right_ops = _side_operator_count(rhs)
    stated: tuple[str, tuple[int, str, int], int] | None = None
    if left_ops == 1 and right_ops == 0:
        stated = ("lhs", _side_operands(lhs)[0], _numeral(rhs))
    elif left_ops == 0 and right_ops == 1:
        stated = ("rhs", _side_operands(rhs)[0], _numeral(lhs))
    if stated is not None:
        _, (left, symbol, right), result = stated
        operation = OPERATION_BY_SYMBOL.get(symbol)
        family = GROUNDED_CLAIM_BY_OPERATION.get(operation[0]) if operation else None
        if family and max(left, right, result) > GROUNDED_MAGNITUDE_BOUND:
            return (
                f"arithmetic_equation({_prolog_expression(lhs)}, "
                f"{_prolog_expression(rhs)})",
                "arithmetic_equality",
                "magnitude_above_grounded_counting_bound",
            )
        if family:
            return (
                f"{family}({left}, {right}, {result})",
                "grounded",
                "stated_result_within_grounded_counting_bound",
            )
    left_side = _grounded_side(lhs)
    right_side = _grounded_side(rhs)
    if left_side is not None and right_side is not None:
        left_term, left_peak = left_side
        right_term, right_peak = right_side
        if max(left_peak, right_peak) > GROUNDED_MAGNITUDE_BOUND:
            return (
                f"arithmetic_equation({_prolog_expression(lhs)}, "
                f"{_prolog_expression(rhs)})",
                "arithmetic_equality",
                "magnitude_above_grounded_counting_bound",
            )
        return (
            "equation_sides("
            f"grounded_counting_bound({GROUNDED_MAGNITUDE_BOUND}), "
            f"{left_term}, {right_term})",
            "grounded",
            "two_sided_within_grounded_counting_bound",
        )
    return (
        f"arithmetic_equation({_prolog_expression(lhs)}, {_prolog_expression(rhs)})",
        "arithmetic_equality",
        "equation_states_no_single_binary_result",
    )


def _side_tasks(lhs: str, rhs: str, attachments: set[tuple[str, str]]) -> list[EquationTask]:
    """One runnable doing per side that is exactly one binary operation."""
    tasks = []
    stated_result = (
        _side_operator_count(lhs) + _side_operator_count(rhs) == 1
    )
    for side_name, side_text in (("left", lhs), ("right", rhs)):
        if _side_operator_count(side_text) != 1:
            continue
        left, symbol, right = _side_operands(side_text)[0]
        mapped = OPERATION_BY_SYMBOL.get(symbol)
        if mapped is None:
            continue
        operation, task_name = mapped
        if operation == "subtraction" and left < right:
            # The registered subtraction machines take away from what is
            # present; a negative difference would compile a fact no automaton
            # can run.
            continue
        if operation == "division" and right == 0:
            continue
        has_route = any(attached == operation for attached, _ in attachments)
        tasks.append(
            EquationTask(
                side=side_name,
                task=f"{task_name}({left}, {right})",
                operation=operation,
                rule_id=STATED_RESULT_RULE if stated_result else SIDE_RULE,
                left=left,
                right=right,
                status="reviewable" if has_route else "rejected",
                reason=(
                    "printed_equation_side_is_one_binary_operation_with_route"
                    if has_route
                    else f"lesson_has_no_{operation}_attachment"
                ),
            )
        )
    return tasks


def _response_judgments(
    raw_lines: list[str], response_range: tuple[int, int], right_column: int | None
) -> list[tuple[int, str, str, tuple[int, int]]]:
    """The printed judgments of one response block, with their reasoning ranges."""
    found: list[tuple[int, str, str, tuple[int, int]]] = []
    starts: list[int] = []
    for index in range(response_range[0], response_range[1]):
        text = _column_text(raw_lines[index], right_column)
        match = JUDGMENT_RE.match(text)
        if match is None:
            continue
        starts.append(index)
        found.append(
            (
                index + 1,
                match.group("judgment").lower(),
                _judgment_fragment(raw_lines[index], right_column),
                (index + 1, index + 1),
            )
        )
    rows = []
    for order, (line, judgment, fragment, _) in enumerate(found):
        end = starts[order + 1] if order + 1 < len(starts) else response_range[1]
        reasoning = " ".join(
            part
            for part in (
                _judgment_fragment(raw_lines[index], right_column)
                for index in range(starts[order], end)
            )
            if part
        )
        rows.append((line, judgment, fragment, (line, end), reasoning))
    return rows


def read_span_readings(
    root: Path,
    spans: list,
    recovered_by_key: dict,
    doc_by_code: dict,
    attachments: dict[str, set[tuple[str, str]]],
    next_response_range,
) -> list[SpanReading]:
    """Read every True-or-False routine span into gated equation rows.

    ``spans`` are the tracked student-task spans; the sidecar pseudo-span for
    the same key supplies the equations when the markdown extraction dropped
    them.  The witness always comes from the tracked markdown, because only the
    markdown is line-addressable.
    """
    readings: list[SpanReading] = []
    for span in spans:
        if not ROUTINE_PROMPT_RE.search(span.text):
            continue
        doc = doc_by_code.get(span.code)
        if doc is None:
            continue
        markdown_equations = find_equations(span.lines)
        recovered = recovered_by_key.get((span.code, span.position))
        equations = markdown_equations
        equation_source = "markdown"
        equation_text = span.text
        if recovered is not None:
            recovered_equations = find_equations(recovered.lines)
            if len(recovered_equations) > len(markdown_equations):
                equations = recovered_equations
                equation_source = "recovered_task_spans"
                equation_text = recovered.text
        reading = SpanReading(span.code, span.position, equation_source)
        reading.equation_count = len(equations)
        if not equations:
            reading.refusal = "routine_span_prints_no_complete_equation"
            readings.append(reading)
            continue
        response_range = next_response_range(doc.path, span.heading_line)
        if response_range is None:
            reading.refusal = "routine_span_has_no_following_student_response_block"
            readings.append(reading)
            continue
        raw_lines = doc.path.read_text(encoding="utf-8", errors="replace").split("\n")
        heading = raw_lines[span.heading_line - 1]
        launch_column = heading.find("Launch")
        right_column = max(launch_column - 2, 0) if launch_column >= 0 else None
        judgments = _response_judgments(raw_lines, response_range, right_column)
        reading.judgment_count = len(judgments)
        if len(judgments) != len(equations):
            reading.refusal = (
                f"witness_count_mismatch: {len(equations)} printed equations, "
                f"{len(judgments)} printed judgments"
            )
            readings.append(reading)
            continue
        distinct = {row[1] for row in judgments}
        reading.witness_alignment = (
            "constant_judgment_sequence_alignment_unconstrained"
            if len(distinct) == 1
            else "mixed_judgment_sequence_alignment_constrained"
        )
        lesson_attachments = attachments.get(span.code, set())
        for item, ((equation, lhs, rhs, equation_line, equation_end_line), witness) in enumerate(
            zip(equations, judgments), 1
        ):
            line, judgment, fragment, reasoning_range, reasoning = witness
            claim, claim_family, claim_route = _claim_term(lhs, rhs)
            reading.rows.append(
                EquationRow(
                    lesson=span.code,
                    position=f"{span.position}/equation({item})",
                    item=item,
                    equation=equation,
                    equation_source=equation_source,
                    span_source=(
                        recovered.source
                        if equation_source == "recovered_task_spans"
                        else span.source
                    ),
                    equation_line=equation_line,
                    equation_end_line=equation_end_line,
                    span_line=span.heading_line,
                    span_end_line=span.end_line,
                    claim=claim,
                    claim_family=claim_family,
                    claim_route=claim_route,
                    witness_source=str(doc.path.relative_to(root)),
                    witness_line=line,
                    witness_judgment=judgment,
                    witness_fragment=fragment,
                    printed_reasoning=reasoning,
                    printed_reasoning_lines=reasoning_range,
                    tasks=_side_tasks(lhs, rhs, lesson_attachments),
                )
            )
        stray = [row.equation for row in reading.rows if row.equation not in equation_text]
        if stray:
            # The segmenter reads the span it names, so this cannot happen from
            # corpus data. It would mean the reader and the text disagreed
            # about what was printed, which is not something to carry forward.
            raise SystemExit(
                f"equation verification segmenter left {span.code}/{span.position} "
                f"with equations absent from the span: {stray}"
            )
        readings.append(reading)
    return readings


# ---------------------------------------------------------------------------
# Adjudication: the verdicts and the reason traces come from Prolog.
# ---------------------------------------------------------------------------

DRIVER = r"""
:- use_module(hermes(math_claim_checker), [ check_math_claim/2 ]).
:- use_module(strategies('math/action_automata_registry')).
:- use_module(library(http/json)).
:- use_module(library(lists)).
:- use_module(library(time)).

:- dynamic eqv_claim/2.
:- dynamic eqv_run/5.

main :-
    forall(eqv_claim(Id, Claim), emit_claim(Id, Claim)),
    forall(eqv_run(Id, Operation, Kind, A, B), emit_run(Id, Operation, Kind, A, B)),
    halt.

emit_claim(Id, Claim) :-
    check_math_claim(Claim, Dict),
    ( get_dict(verdict, Dict, V0) -> V = V0 ; V = "not_checked" ),
    ( get_dict(checker, Dict, C0) -> C = C0 ; C = "none" ),
    ( get_dict(status, Dict, S0) -> S = S0 ; S = "unknown" ),
    ( get_dict(trace, Dict, T0) -> T = T0 ; T = [] ),
    maplist(text_of, T, Trace),
    Out = _{ kind: "claim", id: Id, verdict: V, checker: C, status: S, trace: Trace },
    json_write_dict(current_output, Out, [width(0)]), nl.

emit_run(Id, Operation, Kind, A, B) :-
    (   catch(call_with_time_limit(5,
              run_action_automaton(Operation, Kind, A, B, Outcome, _)), _, fail)
    ->  Outcome = action_outcome(_, Fields),
        ( memberchk(result(R), Fields), integer(R) -> Result = R ; Result = null ),
        ( memberchk(validity(Validity), Fields) -> text_of(Validity, Val) ; Val = "unknown" ),
        Out = _{ kind: "run", id: Id, operation: Operation, automaton: Kind,
                 result: Result, validity: Val, ran: true }
    ;   Out = _{ kind: "run", id: Id, operation: Operation, automaton: Kind,
                 result: null, validity: "did_not_run", ran: false }
    ),
    json_write_dict(current_output, Out, [width(0)]), nl.

text_of(Value, Text) :-
    ( string(Value) -> Text = Value
    ; atom(Value)   -> atom_string(Value, Text)
    ; format(string(Text), "~w", [Value]) ).
"""


def _run_driver(root: Path, claims: list[tuple[str, str]],
                runs: list[tuple[str, str, str, int, int]]) -> list[dict]:
    """One SWI-Prolog batch for every claim and every automaton run."""
    if not claims and not runs:
        return []
    with tempfile.TemporaryDirectory() as workspace:
        driver = Path(workspace) / "eqv_driver.pl"
        body = [DRIVER]
        for identifier, claim in claims:
            body.append(f"eqv_claim({json.dumps(identifier)}, {claim}).")
        for identifier, operation, kind, left, right in runs:
            body.append(
                f"eqv_run({json.dumps(identifier)}, {operation}, {kind}, {left}, {right})."
            )
        driver.write_text("\n".join(body) + "\n", encoding="utf-8")
        result = subprocess.run(
            ["swipl", "-q", "-l", "paths.pl", "-s", str(driver), "-g", "main", "-t", "halt"],
            cwd=root,
            text=True,
            capture_output=True,
        )
    if result.returncode != 0:
        raise SystemExit(
            "equation-verification adjudication failed:\n"
            + result.stderr.strip()[-4000:]
        )
    rows = []
    for line in result.stdout.splitlines():
        line = line.strip()
        if not line.startswith("{"):
            continue
        rows.append(json.loads(line))
    return rows


def _lesson_pairs(
    lesson: str,
    operation: str,
    attachments: dict[str, set[tuple[str, str]]],
    pairs_by_productive: dict[tuple[str, str], list[dict]],
) -> list[dict]:
    """The registered pairs a lesson's own attached productive kinds carry."""
    found = []
    for attached_operation, kind in sorted(attachments.get(lesson, set())):
        if attached_operation != operation:
            continue
        found.extend(pairs_by_productive.get((operation, kind), []))
    return found


def adjudicate(
    root: Path,
    readings: list[SpanReading],
    attachments: dict[str, set[tuple[str, str]]],
    pairs_by_productive: dict[tuple[str, str], list[dict]],
) -> None:
    """Fill verdict, checker and reason trace, then apply the agreement gate."""
    claims = []
    runs = []
    index: dict[str, EquationRow] = {}
    for reading in readings:
        for row in reading.rows:
            identifier = f"{row.lesson}|{row.position}"
            index[identifier] = row
            claims.append((identifier, row.claim))
    # Automaton runs answer one question: does the deformation partner answer
    # this printed item the same way the productive machine does?  That question
    # only has an answer where the equation states a single result value to
    # compare against, so the runs are requested only there.  Identical (kind,
    # operands) triples across rows are run once; the run identity is the
    # triple, not the row.
    requested: dict[tuple[str, str, int, int], str] = {}
    for reading in readings:
        for row in reading.rows:
            if _stated_value(row.claim) is None:
                continue
            for task in row.tasks:
                if task.status != "reviewable":
                    continue
                for pair in _lesson_pairs(
                    row.lesson, task.operation, attachments, pairs_by_productive
                ):
                    for kind in (pair["productive"], pair["deformation"]):
                        key = (task.operation, kind, task.left, task.right)
                        if key in requested:
                            continue
                        identifier = f"{task.operation}|{kind}|{task.left}|{task.right}"
                        requested[key] = identifier
                        runs.append(
                            (identifier, task.operation, kind, task.left, task.right)
                        )
    results = _run_driver(root, claims, runs)
    run_results: dict[str, dict] = {}
    for record in results:
        if record["kind"] == "claim":
            row = index[record["id"]]
            row.verdict = record["verdict"]
            row.checker = record["checker"]
            row.status = record["status"]
            row.reason_trace = record["trace"]
        else:
            run_results[record["id"]] = record
    _apply_agreement_gate(readings)
    _record_viability(readings, attachments, pairs_by_productive, run_results)


def _apply_agreement_gate(readings: list[SpanReading]) -> None:
    """Refuse a span whose printed judgments disagree with the computed verdicts."""
    for reading in readings:
        if reading.refusal or not reading.rows:
            continue
        disagreements = []
        unchecked = []
        for row in reading.rows:
            expected = {"holds": "true", "refuted": "false"}.get(row.verdict)
            if expected is None:
                unchecked.append(f"{row.position}={row.claim} status={row.status}")
                continue
            if expected != row.witness_judgment:
                disagreements.append(
                    f"{row.position}: printed {row.witness_judgment}, "
                    f"{row.checker} computed {row.verdict} for {row.claim}"
                )
        if unchecked:
            reading.refusal = (
                "claim_not_adjudicated_by_a_registered_checker: " + "; ".join(unchecked)
            )
        elif disagreements:
            reading.refusal = (
                "witness_disagrees_with_computed_verdict: " + "; ".join(disagreements)
            )
        else:
            for row in reading.rows:
                row.accepted = True
        if reading.refusal:
            for row in reading.rows:
                row.accepted = False
                row.refusal = reading.refusal


def _record_viability(readings: list[SpanReading],
                      attachments: dict[str, set[tuple[str, str]]],
                      pairs_by_productive: dict[tuple[str, str], list[dict]],
                      run_results: dict[str, dict]) -> None:
    """Say, per registered pair, whether the deformation answers the equation differently.

    A True-or-False item is answered by comparing a computed value with the
    printed one.  Where the productive machine and its deformation partner both
    miss the printed value, both answer the same way and the item does not
    separate them; that agreement region is the honest reading, not a failure.
    Where the printed value equals the deformation's own output, the item
    separates them, and the deformation answers "true" where the productive
    answers "false".
    """
    for reading in readings:
        for row in reading.rows:
            stated = _stated_value(row.claim)
            if stated is None:
                continue
            for task in row.tasks:
                if task.status != "reviewable":
                    continue
                for pair in _lesson_pairs(
                    row.lesson, task.operation, attachments, pairs_by_productive
                ):
                    base = f"{task.operation}"
                    productive = run_results.get(
                        f"{base}|{pair['productive']}|{task.left}|{task.right}"
                    )
                    deformation = run_results.get(
                        f"{base}|{pair['deformation']}|{task.left}|{task.right}"
                    )
                    if productive is None or deformation is None:
                        continue
                    entry = {
                        "side": task.side,
                        "task": task.task,
                        "productive": pair["productive"],
                        "deformation": pair["deformation"],
                        "family": pair["family"],
                        "productive_result": productive.get("result"),
                        "deformation_result": deformation.get("result"),
                        "productive_ran": productive.get("ran", False),
                        "deformation_ran": deformation.get("ran", False),
                    }
                    if not entry["productive_ran"] or not entry["deformation_ran"]:
                        entry["context"] = "pair_did_not_run_on_this_input"
                    elif stated is None:
                        entry["context"] = "equation_states_no_single_result_value"
                    else:
                        productive_says = entry["productive_result"] == stated
                        deformation_says = entry["deformation_result"] == stated
                        entry["productive_answers"] = "true" if productive_says else "false"
                        entry["deformation_answers"] = "true" if deformation_says else "false"
                        entry["context"] = (
                            "separating_at_this_input"
                            if productive_says != deformation_says
                            else "agrees_at_input"
                        )
                    row.viability.append(entry)


_STATED_RE = re.compile(r"^(?:sum|subtraction)\(\s*-?\d+\s*,\s*-?\d+\s*,\s*(-?\d+)\s*\)$")


def _stated_value(claim: str) -> int | None:
    match = _STATED_RE.match(claim)
    return int(match.group(1)) if match else None


# ---------------------------------------------------------------------------
# The ledger
# ---------------------------------------------------------------------------

LEDGER_SCHEMA = "lesson_equation_verifications_v1"
LEDGER_REGISTER = (
    "Each row is one equation the True-or-False routine prints, the claim term it "
    "compiles to, the verdict and reason trace a registered checker returned, and "
    "the judgment the guide prints for it. A span is accepted only when its printed "
    "judgments and the computed verdicts agree at every index; a disagreement is "
    "recorded with both values and counts for nothing."
)


def render_ledger(readings: list[SpanReading]) -> dict:
    spans = []
    for reading in sorted(readings, key=lambda item: (item.lesson, item.position)):
        spans.append({
            "lesson": reading.lesson,
            "position": reading.position,
            "equation_source": reading.equation_source,
            "equation_count": reading.equation_count,
            "judgment_count": reading.judgment_count,
            "witness_alignment": reading.witness_alignment,
            "refusal": reading.refusal,
            "rows": [
                {
                    key: (list(value) if isinstance(value, tuple) else value)
                    for key, value in asdict(row).items()
                }
                for row in reading.rows
            ],
        })
    accepted = [row for reading in readings for row in reading.rows if row.accepted]
    accepted_tasks = [
        task
        for reading in readings
        for row in reading.rows
        if row.accepted
        for task in row.tasks
        if task.status == "reviewable"
    ]
    return {
        "schema": LEDGER_SCHEMA,
        "register": LEDGER_REGISTER,
        "summary": {
            "routine_spans": len(readings),
            "accepted_spans": sum(
                1 for reading in readings if reading.rows and not reading.refusal
            ),
            "refused_spans": sum(1 for reading in readings if reading.refusal),
            "accepted_equations": len(accepted),
            "accepted_tasks": len(accepted_tasks),
            "grounded_claims": sum(
                1 for row in accepted if row.claim_family == "grounded"
            ),
            "arithmetic_equality_claims": sum(
                1 for row in accepted if row.claim_family == "arithmetic_equality"
            ),
            "lessons_with_accepted_task": len({
                reading.lesson
                for reading in readings
                for row in reading.rows
                if row.accepted and any(t.status == "reviewable" for t in row.tasks)
            }),
            "agrees_at_input": sum(
                1
                for row in accepted
                for entry in row.viability
                if entry.get("context") == "agrees_at_input"
            ),
            "separating_at_this_input": sum(
                1
                for row in accepted
                for entry in row.viability
                if entry.get("context") == "separating_at_this_input"
            ),
        },
        "spans": spans,
    }
