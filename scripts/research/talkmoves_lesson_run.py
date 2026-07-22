#!/usr/bin/env python3
"""Lesson-informed TalkMoves run: one transcript, one IM lesson, two arms.

The pilot-3 rerun (talkmoves_rerun.py) told the model nothing about the
lesson being taught. This driver hands the model a lesson monitoring
chart assembled from this repository's own facts: the lesson-mapped
strategy and its vocabulary, teacher-guide task instances, the unit
narrative from the scope and sequence, and literature-documented
misconceptions retrieved by resonance from the embedding index. The
TalkMoves gold labels never enter any prompt; they appear only in the
local alignment report.

Two arms over the same transcript keep the chart's effect measurable:

  baseline  the unmodified two-pass chain, windowed
  lesson    the same chain with the monitoring chart in both passes

Both passes run over utterance windows rather than one whole-transcript
call. The verified transcripts here are about three times as long as the
pilot trio, and the prior whole-transcript pass 2 yielded 6-20 readings
for hundreds of utterances; per-window reading is what makes the posture
record continuous. Pass-1 windows carry no margin (claims are
utterance-local); pass-2 windows carry margin lines marked context-only
so uptake stays readable across the seam.

Outputs land under the gitignored scripts/research/talkmoves_rerun_out/
lesson_run/. ``--dry-run`` builds every request and writes no network
calls.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path
from typing import Any, Callable

REPO_ROOT = Path(__file__).resolve().parents[2]
SIBLING_ROOT = Path("/Users/tio/Documents/GitHub/umedcta-formalization")
TALKMOVES_ROOT = SIBLING_ROOT / "data/external/talkmoves"
MANIFEST = TALKMOVES_ROOT / "manifests/talkmoves_blind_manifest.json"
ANSWER_KEY = TALKMOVES_ROOT / "keys/talkmoves_answer_key.jsonl"
DEFAULT_OUT = REPO_ROOT / "scripts/research/talkmoves_rerun_out/lesson_run"
PASS1_PROMPT = REPO_ROOT / "docs/research/2026-07-01-talkmoves-pass1-math-prompt.md"
PASS2_PROMPT = REPO_ROOT / "docs/research/2026-07-01-talkmoves-pass2-posture-prompt.md"
SCOPE_SEQUENCE = REPO_ROOT / "curriculum/scope_and_sequence/grade6.md"

# Transcript -> lesson rows verified against the live tree (2026-07-21):
# the spoken title or learning target in the blinded markdown matches the
# lesson title lesson_monitoring serves. Add a row only after that check.
VERIFIED_LESSONS: dict[str, dict[str, Any]] = {
    "tm_0007": {
        "lesson": "IM-G6-U4-L10",
        "verified_by": ('spoken target "I can divide a whole number by a '
                        'fraction"; the talk works 14 / (3/4) and 9 / (1/3), '
                        "the lesson's non-unit and unit cases"),
        "unit_heading": "## Unit 4: Dividing Fractions",
        "retrieval_queries": [
            "divide a whole number by a fraction: how many groups of a "
            "non-unit fraction fit in a whole number; measurement division "
            "by a fraction",
            "divide a whole number by a unit fraction using a tape diagram "
            "or number line: how many unit-fraction pieces are in the whole",
        ],
    },
    "tm_0071": {
        "lesson": "IM-G6-U4-L6",
        "verified_by": ('spoken title "Using Diagrams to Find the Number of '
                        'Groups" is the L6 title lesson_monitoring serves '
                        "(the Gemini survey had attributed this transcript "
                        "to L5, whose actual title is "
                        '"How Many Groups? (Part 2)")'),
        "unit_heading": "## Unit 4: Dividing Fractions",
        "retrieval_queries": [
            "use a tape diagram to represent equal-size groups and find "
            "the number of groups when dividing",
            "how many groups: measurement division represented with a "
            "diagram divided into equal pieces",
        ],
    },
}


def load_module(name: str, path: Path) -> Any:
    import importlib.util
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {name}: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


# ---------------------------------------------------------------------------
# Lesson facts (Prolog serves; this driver only formats)
# ---------------------------------------------------------------------------

_LESSON_FACTS_GOAL = """
use_module(library(http/json)),
Code = '{code}',
lesson_monitoring:monitoring_chart(Code, monitoring_chart(Code, lesson(_, Title, grade(G), unit(U), lesson(L)), Standards, Strategies, _, _, Resonant)),
findall(_{{operation:OpA, kind:KindA, vocabulary:VocabA, cluster:ClusterA}},
        ( member(strategy(Op, Kind, Info), Strategies),
          term_to_atom(Op, OpA), term_to_atom(Kind, KindA),
          ( member(vocabulary(Vs), Info) -> maplist(term_to_atom, Vs, VocabA) ; VocabA = [] ),
          ( member(cluster(Cl), Info) -> term_to_atom(Cl, ClusterA) ; ClusterA = none ) ),
        StratDicts),
findall(_{{a:A, b:B, position:PosA, pages:PagesS, excerpt:Ex}},
        ( compiled_task_instances:compiled_lesson_task_instance(Code, _-divide(A,B), task_evidence(_, source(e343_pdf(_, pages(PagesS))), position(Pos), excerpt(Ex))), term_to_atom(Pos, PosA) ),
        Tasks),
findall(_{{code:SCA, statement:SS}},
        ( member(standard(ccss, SC, SS), Standards), term_to_atom(SC, SCA) ),
        CcssDicts),
findall(_{{name:RNA, domain:RDA, citation:RC, score:RS}},
        ( member(resonant_misconception(RN, RD, RC, RS), Resonant),
          term_to_atom(RN, RNA), term_to_atom(RD, RDA) ),
        ResonantDicts),
Lp is L - 1, Ln is L + 1,
format(string(PrevS), 'IM-G~w-U~w-L~w', [G,U,Lp]),
format(string(NextS), 'IM-G~w-U~w-L~w', [G,U,Ln]),
( member(standard(im_lesson, PrevS, PrevT), Standards) -> true ; PrevT = '' ),
( member(standard(im_lesson, NextS, NextT), Standards) -> true ; NextT = '' ),
json_write_dict(current_output, _{{code:Code, title:Title, grade:G, unit:U, lesson:L, strategies:StratDicts, tasks:Tasks, ccss:CcssDicts, resonant:ResonantDicts, prev_title:PrevT, next_title:NextT}}), nl, halt.
"""


def lesson_facts(code: str) -> dict[str, Any]:
    goal = _LESSON_FACTS_GOAL.format(code=code)
    proc = subprocess.run(
        [os.environ.get("HERMES_SWIPL", "swipl"), "-q", "-l", "paths.pl",
         "-s", "curriculum/im/lesson_monitoring.pl",
         "-s", "curriculum/im/generated/compiled_task_instances.pl",
         "-g", goal],
        cwd=REPO_ROOT, text=True, capture_output=True, check=False,
    )
    if proc.returncode != 0:
        raise RuntimeError(f"lesson_facts({code}) failed: {proc.stderr.strip()}")
    start = proc.stdout.find("{")
    if start < 0:
        raise RuntimeError(f"lesson_facts({code}) produced no JSON: "
                           f"{proc.stdout[:200]!r}")
    return json.loads(proc.stdout[start:])


def unit_narrative(unit_heading: str) -> str:
    """The unit's narrative paragraph from the scope and sequence, cut
    before the disciplinary-language progression (chart material ends
    where the terminology table begins)."""
    text = SCOPE_SEQUENCE.read_text(encoding="utf-8")
    start = text.find(unit_heading)
    if start < 0:
        raise ValueError(f"unit heading absent from scope and sequence: {unit_heading}")
    section = text[start:]
    next_unit = section.find("\n## ", 1)
    if next_unit > 0:
        section = section[:next_unit]
    body = re.split(r"Progression of Disciplinary Language", section)[0]
    lines = [line.strip() for line in body.splitlines()
             if line.strip() and not line.startswith("#")
             and not line.startswith("_Anchor")]
    return " ".join(lines)


# ---------------------------------------------------------------------------
# Misconception retrieval (resonance over the embedding index)
# ---------------------------------------------------------------------------

def resonant_misconceptions(queries: list[str], k: int) -> list[dict[str, Any]]:
    """Top-k registry rows by cosine resonance against lesson-derived
    queries. Queries come from the lesson, never from the transcript, so
    retrieval cannot smuggle transcript content back into the chart."""
    if str(REPO_ROOT) not in sys.path:
        sys.path.insert(0, str(REPO_ROOT))
    from hermes.app import llm
    from hermes.app.routes.misconception_search import cosine_matches, load_index
    emb = load_module("hermes_misconception_embedding",
                      REPO_ROOT / "scripts/research/misconception_embedding.py")
    index = load_index(REPO_ROOT)
    if index is None:
        raise RuntimeError("misconception embedding index is absent; build it first")
    client = llm.make_client(REPO_ROOT)
    vectors = emb.embed(queries, model=index.model, client=client)
    best: dict[str, dict[str, Any]] = {}
    for vector in vectors:
        for row in cosine_matches(index, vector, limit=max(32, k)):
            key = str(row.get("citation") or row.get("name"))
            if key not in best or row["score"] > best[key]["score"]:
                best[key] = dict(row)
    return sorted(best.values(), key=lambda row: -row["score"])[:k]


_DB_ROW_TAIL = re.compile(r"\s*\(db row \d+\)\s*$")


def misconception_line(row: dict[str, Any]) -> str:
    """One chart row: the documented error, then who documented it."""
    citation = _DB_ROW_TAIL.sub("", str(row.get("citation", "")).strip())
    match = re.match(r"^(.*?\(\d{4}\)):\s*(.+)$", citation)
    if match:
        authors, error = match.group(1), match.group(2)
        return f"- {error} — {authors}"
    return f"- {citation or row.get('description', row.get('name', '?'))}"


# ---------------------------------------------------------------------------
# The chart text (the only lesson knowledge either pass receives)
# ---------------------------------------------------------------------------

def monitoring_chart_text(facts: dict[str, Any], narrative: str,
                          misconceptions: list[dict[str, Any]]) -> str:
    code = facts["code"]
    lines = [
        f"----- LESSON MONITORING CHART: {code} -----",
        (f"The class is working Illustrative Mathematics Grade {facts['grade']}, "
         f"Unit {facts['unit']}, Lesson {facts['lesson']}, "
         f"\"{facts['title']}\" (Open Up Resources). This chart assembles what "
         "the lesson anticipates so that what speakers are attempting is "
         "recognizable. The chart anticipates; the transcript decides."),
        "",
    ]
    for standard in facts.get("ccss", []):
        lines.append(f"STANDARD: {str(standard.get('code', '')).strip(chr(39))}"
                     f" — {standard.get('statement')}")
    lines += [
        "",
        "UNIT STORY (published scope and sequence; fraction notation was "
        "lost in text extraction, so gaps in the quoted questions stand "
        "where fractions appeared):",
        narrative,
        "",
        "ANTICIPATED STRATEGY (this repository's lesson mapping):",
    ]
    for strategy in facts.get("strategies", []):
        vocab = ", ".join(str(v).replace("_", " ")
                          for v in strategy.get("vocabulary", []))
        kind = str(strategy.get("kind", "?")).replace("_", " ")
        lines.append(f"- {kind} (operation: {strategy.get('operation', '?')})."
                     + (f" Working vocabulary: {vocab}." if vocab else ""))
    tasks = facts.get("tasks", [])
    if tasks:
        lines.extend(["", "TEACHER-GUIDE TASKS REGISTERED FOR THIS LESSON:"])
        for task in tasks:
            lines.append(f"- {task.get('position', '?')}"
                         f" (teacher guide pp. {task.get('pages', '?')}):"
                         f" \"{task.get('excerpt', '')}\""
                         f" [{task.get('a')} / {task.get('b')}]")
    if misconceptions:
        lines.extend(["", "DOCUMENTED MISCONCEPTIONS NEAR THIS CONTENT",
                      "(retrieved by resonance from a literature-derived "
                      "registry; each row names the study that documented "
                      "the error):"])
        lines.extend(misconception_line(row) for row in misconceptions)
    prev_title, next_title = facts.get("prev_title"), facts.get("next_title")
    if prev_title or next_title:
        neighbor = []
        if prev_title:
            neighbor.append(f"the previous lesson was \"{prev_title}\"")
        if next_title:
            neighbor.append(f"the next lesson is \"{next_title}\"")
        lines.extend(["", "NEIGHBORING LESSONS: " + "; ".join(neighbor) + "."])
    lines.extend([
        "",
        "DISCIPLINE FOR USING THIS CHART:",
        "- Where the transcript departs from the chart, the transcript wins.",
        "- The chart never supplies content: every extracted surface must "
        "remain a verbatim substring of a transcript utterance. Never "
        "import the chart's numbers or phrasings into claims.",
        "- A speaker working near a documented misconception is a "
        "hypothesis to weigh against what is actually said, not a verdict.",
        f"----- END MONITORING CHART: {code} -----",
    ])
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Windows over the numbered transcript
# ---------------------------------------------------------------------------

_NUMBERED_LINE = re.compile(r"^U(\d{4})\s")


def utterance_lines(numbered: str) -> tuple[list[str], dict[int, int]]:
    """All lines plus a map from utterance number to line index."""
    lines = numbered.splitlines()
    index = {}
    for i, line in enumerate(lines):
        match = _NUMBERED_LINE.match(line)
        if match:
            index[int(match.group(1))] = i
    return lines, index


def window_spans(total: int, core: int) -> list[tuple[int, int]]:
    """Inclusive utterance-number spans; a short tail merges backward."""
    spans = []
    start = 1
    while start <= total:
        spans.append((start, min(total, start + core - 1)))
        start += core
    if len(spans) > 1 and spans[-1][1] - spans[-1][0] + 1 < core // 2:
        last = spans.pop()
        spans[-1] = (spans[-1][0], last[1])
    return spans


def window_text(lines: list[str], index: dict[int, int],
                span: tuple[int, int], margin: int, total: int) -> str:
    core_start, core_end = span
    lo = max(1, core_start - margin)
    hi = min(total, core_end + margin)
    parts: list[str] = []
    if lo < core_start:
        parts.append(f"[CONTEXT BEFORE U{core_start:04d} — for uptake and "
                     "continuity only; do not code these lines]")
        parts.extend(lines[index[lo]:index[core_start]])
    parts.append(f"[CODE THIS SPAN: U{core_start:04d}-U{core_end:04d}]")
    parts.extend(lines[index[core_start]:index[core_end] + 1])
    if hi > core_end:
        parts.append(f"[CONTEXT AFTER U{core_end:04d} — for uptake and "
                     "continuity only; do not code these lines]")
        parts.extend(lines[index[core_end] + 1:index[hi] + 1])
    return "\n".join(parts)


_LEDGER_UTTERANCE = re.compile(r"\(u(\d{4})\)")


def ledger_for_span(legend: list[str], span: tuple[int, int], margin: int,
                    total: int) -> list[str]:
    lo, hi = max(1, span[0] - margin), min(total, span[1] + margin)
    kept = []
    for line in legend:
        match = _LEDGER_UTTERANCE.search(line)
        if match and lo <= int(match.group(1)) <= hi:
            kept.append(line)
    return kept


def reading_in_span(reading: dict[str, Any], span: tuple[int, int]) -> bool:
    for utterance in reading.get("utterance_ids", []):
        match = re.search(r"(\d+)", str(utterance))
        if match and span[0] <= int(match.group(1)) <= span[1]:
            return True
    return False


# ---------------------------------------------------------------------------
# The run
# ---------------------------------------------------------------------------

def cached_text(path: Path, produce: Callable[[], str]) -> str:
    if path.is_file():
        return path.read_text(encoding="utf-8")
    value = produce()
    path.write_text(value, encoding="utf-8")
    return value


def run_arm(*, arm: str, transcript_id: str, numbered: str, chart: str,
            two_pass: Any, scorer: Any, rerun: Any, out_dir: Path,
            core: int, margin: int, dry_run: bool) -> dict[str, Any] | None:
    lines, index = utterance_lines(numbered)
    total = max(index) if index else 0
    if not total:
        raise ValueError(f"{transcript_id}: no numbered utterances")
    spans = window_spans(total, core)
    context = chart if arm == "lesson" else ""
    system1 = PASS1_PROMPT.read_text(encoding="utf-8")
    system2 = PASS2_PROMPT.read_text(encoding="utf-8")

    # Pass 1, windowed without margins: claims are utterance-local.
    claims: list[dict[str, Any]] = []
    actions: list[dict[str, Any]] = []
    pass1_errors: list[str] = []
    for k, span in enumerate(spans, start=1):
        note = (f"WINDOW: utterances U{span[0]:04d}-U{span[1]:04d} of a "
                f"{total}-utterance transcript. Extract claims and actions "
                "for these lines only.")
        block = note + ("\n\n" + context if context else "")
        text = "\n".join(lines[index[span[0]]:index[span[1]] + 1])
        request = two_pass.build_pass1_user_content(
            transcript_id, text, context_block=block)
        (out_dir / f"{transcript_id}_{arm}_pass1_w{k:02d}_request.txt"
         ).write_text(request, encoding="utf-8")
        if dry_run:
            continue
        reply = cached_text(
            out_dir / f"{transcript_id}_{arm}_pass1_w{k:02d}_reply.md",
            lambda: scorer.call_api(system1, request, retries=2, timeout=240))
        try:
            math = rerun.json_block(reply, "## MATH_JSON")
        except ValueError as exc:
            # The unparseable reply stays cached for audit; delete the
            # reply file to retry the window over the network.
            pass1_errors.append(f"w{k:02d}: {exc}")
            continue
        for claim in math.get("claims", []) or []:
            claim["id"] = f"w{k}{str(claim.get('id', 'c')).strip()}"
            claims.append(claim)
        for action in math.get("actions", []) or []:
            action["id"] = f"w{k}{str(action.get('id', 'a')).strip()}"
            action.setdefault("kind", "action")
            actions.append(action)
    if dry_run:
        return None

    extractions = two_pass.adjudicate_claims(claims) + actions
    (out_dir / f"{transcript_id}_{arm}_extractions.json").write_text(
        json.dumps(extractions, indent=2, sort_keys=True) + "\n",
        encoding="utf-8")
    mask = two_pass.mask_transcript(numbered, extractions)
    (out_dir / f"{transcript_id}_{arm}_mask.json").write_text(
        json.dumps(mask, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    # Pass 2 over masked windows with context-only margins.
    masked_lines, masked_index = utterance_lines(mask["masked"])
    readings: list[dict[str, Any]] = []
    passage_modes: list[dict[str, Any]] = []
    window_errors: list[str] = []
    for k, span in enumerate(spans, start=1):
        note = (f"WINDOW: this request covers utterances U{span[0]:04d}-"
                f"U{span[1]:04d} of a {total}-utterance transcript. Lines "
                "marked as context are present only so uptake and "
                "continuity stay readable; code postures for the marked "
                "span alone.")
        block = note + ("\n\n" + context if context else "")
        synthetic = {
            "masked": window_text(masked_lines, masked_index, span, margin,
                                  total),
            "legend": ledger_for_span(mask["legend"], span, margin, total),
        }
        request = two_pass.build_pass2_user_content(
            transcript_id, synthetic, variant="hard_mask",
            label=f"hard_mask_w{k:02d}", context_block=block)
        (out_dir / f"{transcript_id}_{arm}_pass2_w{k:02d}_request.txt"
         ).write_text(request, encoding="utf-8")
        reply = cached_text(
            out_dir / f"{transcript_id}_{arm}_pass2_w{k:02d}_reply.md",
            lambda: scorer.call_api(system2, request, retries=2, timeout=240))
        try:
            posture = rerun.json_block(reply, "## PML_JSON")
        except ValueError as exc:
            window_errors.append(f"w{k:02d}: {exc}")
            continue
        for mode in posture.get("passage_modes", []) or []:
            mode["window"] = k
            passage_modes.append(mode)
        for reading in posture.get("readings", []) or []:
            if not reading_in_span(reading, span):
                continue
            reading["id"] = f"w{k:02d}_{str(reading.get('id', 'r')).strip()}"
            reading["window"] = k
            readings.append(reading)

    (out_dir / f"{transcript_id}_{arm}_readings.json").write_text(
        json.dumps({"readings": readings, "passage_modes": passage_modes,
                    "window_errors": window_errors,
                    "pass1_errors": pass1_errors, "windows": spans},
                   indent=2, sort_keys=True) + "\n", encoding="utf-8")
    report = two_pass.teacher_report(transcript_id, extractions, readings,
                                     numbered, mask_result=mask)
    (out_dir / f"{transcript_id}_{arm}_report.json").write_text(
        json.dumps({"transcript_id": transcript_id, "arm": arm,
                    "report": report}, indent=2, sort_keys=True) + "\n",
        encoding="utf-8")
    (out_dir / f"{transcript_id}_{arm}_claims.md").write_text(
        rerun.render_claims(transcript_id, extractions, numbered),
        encoding="utf-8")
    return {"extractions": extractions, "readings": readings,
            "passage_modes": passage_modes, "mask": mask, "spans": spans,
            "window_errors": window_errors, "pass1_errors": pass1_errors,
            "total": total}


# ---------------------------------------------------------------------------
# Reader-facing documents
# ---------------------------------------------------------------------------

def strike_line(line: str, records: list[dict[str, Any]]) -> str:
    """The sous-rature substitution: the surface stays legible under the
    cross, followed by its checked token. Longest surfaces first, spans
    never overlap — the same verification the masker enforces."""
    taken: list[tuple[int, int]] = []
    pieces: list[tuple[int, int, str]] = []
    for record in sorted(records, key=lambda r: -len(r.get("trimmed_surface", ""))):
        trimmed = record.get("trimmed_surface", "")
        if not trimmed:
            continue
        body = r"\s+".join(re.escape(word) for word in trimmed.split())
        pattern = re.compile(r"(?<![A-Za-z0-9])" + body + r"(?![A-Za-z0-9])",
                             re.IGNORECASE)
        for match in pattern.finditer(line):
            if any(match.start() < e and match.end() > s for s, e in taken):
                continue
            taken.append(match.span())
            pieces.append((match.start(), match.end(),
                           f"~~{line[match.start():match.end()]}~~ "
                           f"{record['token']}"))
    pieces.sort()
    out, cursor = [], 0
    for start, end, replacement in pieces:
        out.append(line[cursor:start])
        out.append(replacement)
        cursor = end
    out.append(line[cursor:])
    return "".join(out)


def posture_note(reading: dict[str, Any]) -> str:
    pml = reading.get("pml", {})
    fields = "/".join(str(pml.get(f, "?")) for f in
                      ("force", "mode", "operator", "polarity"))
    content = str(pml.get("content", "")).strip()
    fate = (reading.get("uptake") or {}).get("fate")
    tail = f" [uptake: {fate}]" if fate else ""
    return (f"  - PML {reading.get('id')}: {fields}"
            + (f" — {content}" if content else "") + tail)


def write_sous_rature(transcript_id: str, arm: str, numbered: str,
                      result: dict[str, Any], two_pass: Any,
                      out_dir: Path) -> None:
    lines, index = utterance_lines(numbered)
    by_line: dict[int, list[dict[str, Any]]] = {}
    for record in result["mask"].get("applied", []):
        match = re.search(r"(\d+)", str(record.get("utterance_id", "")))
        if match and int(match.group(1)) in index:
            by_line.setdefault(index[int(match.group(1))], []).append(record)
    readings_by_utterance: dict[int, list[dict[str, Any]]] = {}
    for reading in result["readings"]:
        for utterance in reading.get("utterance_ids", []):
            match = re.search(r"(\d+)", str(utterance))
            if match:
                readings_by_utterance.setdefault(int(match.group(1)),
                                                 []).append(reading)
    body = [f"# {transcript_id}: the conversation under erasure ({arm} arm)",
            "",
            "Struck text is the mathematical layer: kept legible, crossed "
            "where it stands, each strike followed by the calculator's "
            "token for it (`[id shape: verdict]`). Erasure is not "
            "deletion — the claim is needed and cannot be taken on faith, "
            "so the calculator holds it. Indented lines carry the model's "
            "PML posture readings for that utterance; the readings are "
            "interpretive, the verdicts are computed.", "",
            two_pass.attribution_for(transcript_id), ""]
    for i, line in enumerate(lines):
        match = _NUMBERED_LINE.match(line)
        rendered = strike_line(line, by_line.get(i, [])) if i in by_line else line
        body.append(rendered)
        if match:
            for reading in readings_by_utterance.get(int(match.group(1)), []):
                body.append(posture_note(reading))
    (out_dir / f"{transcript_id}_sous_rature.md").write_text(
        "\n".join(body) + "\n", encoding="utf-8")


def write_pml_report(transcript_id: str, arm: str, result: dict[str, Any],
                     rerun: Any, out_dir: Path) -> None:
    readings = result["readings"]
    covered = set()
    for reading in readings:
        for utterance in reading.get("utterance_ids", []):
            match = re.search(r"(\d+)", str(utterance))
            if match:
                covered.add(int(match.group(1)))
    total = result["total"]
    body = [f"# {transcript_id}: PML posture record ({arm} arm)", "",
            f"{len(readings)} readings over {len(result['spans'])} windows; "
            f"{len(covered)}/{total} utterances carry at least one reading "
            f"({100 * len(covered) / total:.0f}% coverage).", ""]
    counts = rerun.posture_counts(readings)
    rows = [[field, value, str(count)]
            for field in ("force", "mode", "operator", "polarity")
            for value, count in sorted(counts[field].items())]
    body.extend(rerun.markdown_table(["Field", "Value", "Count"], rows))
    body.append("")
    if result["passage_modes"]:
        body.append("## Passage modes by window")
        body.append("")
        rows = [[str(mode.get("window", "?")), str(mode.get("id", "?")),
                 rerun.table_cell(mode.get("mode", "?")),
                 rerun.table_cell(mode.get("reading", ""))]
                for mode in result["passage_modes"]]
        body.extend(rerun.markdown_table(
            ["Window", "Id", "Mode", "Reading"], rows))
        body.append("")
    body.append("## Readings")
    body.append("")
    rows = []
    for reading in readings:
        pml = reading.get("pml", {})
        fate = (reading.get("uptake") or {}).get("fate", "")
        rows.append([
            rerun.table_cell(reading.get("id", "?")),
            rerun.table_cell(",".join(str(u) for u in
                                      reading.get("utterance_ids", []))),
            rerun.table_cell(pml.get("force", "?")),
            rerun.table_cell(pml.get("mode", "?")),
            rerun.table_cell(pml.get("operator", "?")),
            rerun.table_cell(pml.get("polarity", "?")),
            rerun.table_cell(pml.get("content", "")),
            rerun.table_cell(fate),
        ])
    body.extend(rerun.markdown_table(
        ["Id", "Utterances", "Force", "Mode", "Operator", "Polarity",
         "Content", "Uptake"], rows))
    if result["window_errors"]:
        body.extend(["", "## Windows that returned no parseable reading", ""])
        body.extend(f"- {error}" for error in result["window_errors"])
    (out_dir / f"{transcript_id}_pml_report.md").write_text(
        "\n".join(body) + "\n", encoding="utf-8")


def load_answer_key(transcript_id: str) -> list[dict[str, Any]]:
    rows = []
    with ANSWER_KEY.open(encoding="utf-8") as handle:
        for line in handle:
            row = json.loads(line)
            if row.get("transcript_id") == transcript_id:
                rows.append(row)
    rows.sort(key=lambda row: int(re.search(r"u(\d+)$",
                                            row["utterance_id"]).group(1)))
    return rows


def write_alignment(transcript_id: str, arm: str, result: dict[str, Any],
                    numbered: str, rerun: Any, out_dir: Path) -> None:
    """PML readings against the TalkMoves gold labels. Local only: the
    gold labels never entered any prompt in this run."""
    key_rows = load_answer_key(transcript_id)
    lines, index = utterance_lines(numbered)
    mismatch = 0
    for number, line_index in list(index.items())[:40]:
        spoken = lines[line_index].split(": ", 1)[-1].strip()
        gold = str(key_rows[number - 1]["sentence"]).strip() \
            if number - 1 < len(key_rows) else ""
        if spoken != gold:
            mismatch += 1
    body = [f"# {transcript_id}: PML postures beside TalkMoves labels "
            f"({arm} arm)", "",
            "The gold labels below never entered any model prompt; this "
            "alignment is computed locally after the run.", "",
            f"Alignment check: {len(key_rows)} answer-key rows for "
            f"{len(index)} numbered utterances; "
            f"{mismatch}/40 sampled sentences differ textually (in-text "
            "blinding accounts for small differences).", ""]
    if len(key_rows) != len(index):
        body.append("WARNING: row counts differ; the by-order join below "
                    "is suspect.")
    tags_by_number = {number: key_rows[number - 1]
                      for number in index if number - 1 < len(key_rows)}
    teacher_tab: Counter[tuple[str, str]] = Counter()
    student_tab: Counter[tuple[str, str]] = Counter()
    for reading in result["readings"]:
        operator = str(reading.get("pml", {}).get("operator", "?"))
        for utterance in reading.get("utterance_ids", []):
            match = re.search(r"(\d+)", str(utterance))
            if not match or int(match.group(1)) not in tags_by_number:
                continue
            row = tags_by_number[int(match.group(1))]
            teacher_tag = str(row.get("teacher_tag", "")).strip()
            student_tag = str(row.get("student_tag", "")).strip()
            if teacher_tag:
                teacher_tab[(teacher_tag, operator)] += 1
            if student_tag:
                student_tab[(student_tag, operator)] += 1
    for title, tab in (("Teacher talk moves × PML operator", teacher_tab),
                      ("Student talk moves × PML operator", student_tab)):
        body.extend([f"## {title}", ""])
        operators = ("comp_nec", "comp_poss", "exp_nec", "exp_poss")
        tags = sorted({tag for tag, _ in tab})
        rows = [[tag] + [str(tab.get((tag, op), 0)) for op in operators]
                for tag in tags]
        body.extend(rerun.markdown_table(["Talk move"] + list(operators),
                                         rows or [["-", "0", "0", "0", "0"]]))
        body.append("")
    distribution: Counter[str] = Counter()
    for row in key_rows:
        for field in ("teacher_tag", "student_tag"):
            tag = str(row.get(field, "")).strip()
            if tag:
                distribution[tag] += 1
    body.extend(["## Whole-transcript talk-move distribution (context)", ""])
    body.extend(rerun.markdown_table(
        ["Talk move", "Utterances"],
        [[tag, str(count)] for tag, count in distribution.most_common()]))
    (out_dir / f"{transcript_id}_talkmoves_alignment.md").write_text(
        "\n".join(body) + "\n", encoding="utf-8")


def write_arm_comparison(transcript_id: str, results: dict[str, dict[str, Any]],
                         rerun: Any, out_dir: Path) -> None:
    if set(results) != {"baseline", "lesson"}:
        return
    base, lesson = results["baseline"], results["lesson"]
    added, dropped, changed = rerun.compare_claims(
        base["extractions"], lesson["extractions"])
    body = [f"# {transcript_id}: lesson-informed arm versus baseline", "",
            "Same transcript, same chain, same windows; the only "
            "difference is the monitoring chart in the lesson arm's "
            "prompts. Claim identity is utterance id + typed shape + "
            "arguments.", "",
            f"- Claims only in the lesson arm: {len(added)}"
            + (" — " + "; ".join(added) if added else ""),
            f"- Claims only in the baseline arm: {len(dropped)}"
            + (" — " + "; ".join(dropped) if dropped else ""),
            f"- Verdicts changed: {len(changed)}"
            + (" — " + "; ".join(changed) if changed else ""), ""]
    for arm, result in results.items():
        applied = len(result["mask"].get("applied", []))
        skipped = len(result["mask"].get("skipped", []))
        covered = set()
        for reading in result["readings"]:
            for utterance in reading.get("utterance_ids", []):
                match = re.search(r"(\d+)", str(utterance))
                if match:
                    covered.add(int(match.group(1)))
        body.append(f"- {arm}: {applied} surfaces anchored verbatim, "
                    f"{skipped} refused by the masker; "
                    f"{len(result['readings'])} readings covering "
                    f"{len(covered)}/{result['total']} utterances.")
    body.append("")
    body.append("Posture distributions (chart effect on the reading, "
                "confounded with each arm's own mask — a rerun-to-rerun "
                "difference, not an accuracy claim):")
    base_counts = rerun.posture_counts(base["readings"])
    lesson_counts = rerun.posture_counts(lesson["readings"])
    rows = []
    for field in ("force", "mode", "operator", "polarity"):
        for value in sorted(set(base_counts[field]) | set(lesson_counts[field])):
            before = base_counts[field][value]
            after = lesson_counts[field][value]
            rows.append([field, value, str(before), str(after),
                         f"{after - before:+d}"])
    body.extend(rerun.markdown_table(
        ["Field", "Value", "Baseline", "Lesson", "Delta"], rows))
    (out_dir / f"{transcript_id}_arm_comparison.md").write_text(
        "\n".join(body) + "\n", encoding="utf-8")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--transcript", default="tm_0007",
                        choices=sorted(VERIFIED_LESSONS))
    parser.add_argument("--model", default="gemma-4-31B-it")
    parser.add_argument("--core", type=int, default=80,
                        help="utterances per window")
    parser.add_argument("--margin", type=int, default=12,
                        help="context-only utterances around a pass-2 window")
    parser.add_argument("--k", type=int, default=8,
                        help="misconception rows retrieved for the chart")
    parser.add_argument("--arms", default="both",
                        choices=("both", "lesson", "baseline"))
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT)
    parser.add_argument("--dry-run", action="store_true",
                        help="build requests; no network, no reports")
    args = parser.parse_args(argv)

    transcript_id = args.transcript
    lesson = VERIFIED_LESSONS[transcript_id]
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    row = {str(r.get("transcript_id")): r
           for r in manifest.get("transcripts", [])}.get(transcript_id)
    if row is None:
        raise SystemExit(f"{transcript_id} is absent from {MANIFEST}")
    markdown_path = TALKMOVES_ROOT / str(row["markdown_path"])

    two_pass = load_module("hermes_talkmoves_two_pass_lesson",
                           REPO_ROOT / "scripts/talkmoves_two_pass.py")
    rerun = load_module("hermes_talkmoves_rerun_helpers",
                        REPO_ROOT / "scripts/research/talkmoves_rerun.py")
    scorer = two_pass._load_scorer()
    scorer.load_dotenv(REPO_ROOT)
    previous_model = os.environ.get("REALLMS_MODEL")
    os.environ["REALLMS_MODEL"] = args.model

    out_dir = args.out
    out_dir.mkdir(parents=True, exist_ok=True)

    raw = markdown_path.read_text(encoding="utf-8")
    blinded, _aliases = two_pass.blind_transcript(raw)
    numbered, _ = scorer.number_transcript(blinded)

    facts = json.loads(cached_text(
        out_dir / f"{lesson['lesson']}_facts.json",
        lambda: json.dumps(lesson_facts(lesson["lesson"]), indent=2,
                           sort_keys=True) + "\n"))
    narrative = unit_narrative(lesson["unit_heading"])
    # The committed resonance facts are the same rows the app's chart
    # serves; live retrieval remains only as the fallback for lessons
    # whose facts have not been built.
    misconceptions: list[dict[str, Any]] = facts.get("resonant") or []
    if not misconceptions:
        misconception_path = out_dir / f"{lesson['lesson']}_misconceptions.json"
        if args.dry_run and not misconception_path.is_file():
            misconceptions = []
        else:
            misconceptions = json.loads(cached_text(
                misconception_path,
                lambda: json.dumps(resonant_misconceptions(
                    lesson["retrieval_queries"], args.k), indent=2,
                    sort_keys=True) + "\n"))
    chart = monitoring_chart_text(facts, narrative, misconceptions)
    (out_dir / f"{transcript_id}_lesson_context.md").write_text(
        chart + "\n", encoding="utf-8")

    arms = ("baseline", "lesson") if args.arms == "both" else (args.arms,)
    results: dict[str, dict[str, Any]] = {}
    try:
        for arm in arms:
            result = run_arm(arm=arm, transcript_id=transcript_id,
                             numbered=numbered, chart=chart,
                             two_pass=two_pass, scorer=scorer, rerun=rerun,
                             out_dir=out_dir, core=args.core,
                             margin=args.margin, dry_run=args.dry_run)
            if result is not None:
                results[arm] = result
    finally:
        if previous_model is None:
            os.environ.pop("REALLMS_MODEL", None)
        else:
            os.environ["REALLMS_MODEL"] = previous_model

    if args.dry_run:
        print(f"dry-run: requests under {out_dir}; no network calls made")
        return 0

    primary_arm = "lesson" if "lesson" in results else next(iter(results))
    primary = results[primary_arm]
    write_sous_rature(transcript_id, primary_arm, numbered, primary,
                      two_pass, out_dir)
    write_pml_report(transcript_id, primary_arm, primary, rerun, out_dir)
    write_alignment(transcript_id, primary_arm, primary, numbered, rerun,
                    out_dir)
    write_arm_comparison(transcript_id, results, rerun, out_dir)
    try:
        join = load_module("hermes_monitoring_join",
                           REPO_ROOT / "scripts/research/monitoring_join.py")
        join.main(["--run-dir", str(out_dir), "--transcript", transcript_id,
                   "--lesson", lesson["lesson"]])
        joined = True
    except Exception as exc:
        print(f"monitoring join did not run: {exc}")
        joined = False
    (out_dir / "run_manifest.json").write_text(json.dumps({
        "monitoring_join": joined,
        "transcript_id": transcript_id,
        "lesson": lesson["lesson"],
        "lesson_verified_by": lesson["verified_by"],
        "model": args.model,
        "arms": sorted(results),
        "core": args.core, "margin": args.margin,
        "windows": results[primary_arm]["spans"],
        "misconception_rows": len(misconceptions),
        "gold_labels_in_prompts": False,
    }, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"lesson run complete: {out_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
