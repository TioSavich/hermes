#!/usr/bin/env python3
"""Build source-sliced IM task records without changing the compiled inputs."""

from __future__ import annotations

import argparse
from bisect import bisect_right
from collections import Counter, defaultdict
from dataclasses import dataclass
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
from typing import NoReturn


ROOT = Path(__file__).resolve().parents[2]
COMPILED = ROOT / "curriculum/im/generated/compiled_task_instances.pl"
GRADE8_COMPILED = (
    ROOT / "curriculum/im/generated/grade_8_extracted_task_instances.pl"
)
RECOVERED = ROOT / "curriculum/im/generated/recovered_task_spans.json"
JSON_RECOVERY_DIR = (
    ROOT / "hermes/app/runtime/experiments/docling_grade8_recovery/checkpoints"
)
OUTPUT = ROOT / "curriculum/im/generated/compiled_defragged_task_instances.pl"

sys.path.insert(0, str(ROOT / "scripts/curriculum"))
import compile_action_mappings as compiler  # noqa: E402
import vision_statement_contract  # noqa: E402


EXPECTED_OUTCOMES = Counter(
    {
        "already_standalone": 547,
        "complete_task_recovered": 1261,
        "recoverable_with_referent_context": 3,
        "blocked_by_missing_image": 23,
        "blocked_by_layout": 312,
    }
)
STATUS = {
    "already_standalone": "already_complete",
    "complete_task_recovered": "recovered",
    "recoverable_with_referent_context": "recovered_with_referent",
    "blocked_by_missing_image": "blocked_missing_visual",
    "blocked_by_layout": "blocked_layout",
    "json_task_recovered": "recovered",
    "vision_task_recovered": "recovered",
}

SWI_GOAL = r"""use_module(library(http/json)),use_module(curriculum/im/generated/compiled_task_instances,[]),use_module(curriculum/im/generated/grade_8_extracted_task_instances,[]), forall(((compiled_task_instances:compiled_lesson_task_instance(L,T,Evd);grade_8_extracted_task_instances:extracted_lesson_task_instance(L,T,Evd)),Evd=..[task_evidence,rule(R),S,position(P),excerpt(E)|Extra]), (term_string(T,TS,[quoted(true)]),term_string(R,RS,[quoted(true)]),term_string(P,PS,[quoted(true)]),term_string(Evd,ES,[quoted(true)]),(memberchk(extraction_status(US),Extra)->true;US=legacy),(memberchk(blocker(UB),Extra)->true;UB=none),(S=source(Path,lines(A,B))->K=markdown,Src=Path,Start=A,End=B;S=source(e343_pdf(Path,pages(Pg)))->K=pdf,Src=Path,Start=Pg,End=Pg;S=source(recovered_task_spans(Path,lesson(_),position(RP)))->K=recovered,Src=Path,Start=RP,End=RP),json_write_dict(current_output,_{lesson:L,task:TS,rule:RS,source_kind:K,source:Src,start:Start,end:End,position:PS,excerpt:E,evidence_term:ES,upstream_status:US,upstream_blocker:UB},[width(0)]),nl)), halt."""

IMPERATIVE = re.compile(
    r"^(?:\d+[a-z]?\.\s*)?(?:for each[^,.?]*,\s*)?"
    r"(?:find|write|explain|show|solve|determine|calculate|complete|compare|decide|"
    r"select|choose|draw|use|create|represent|measure|estimate|label|order|match|"
    r"plot|circle|shade|partition|decompose|fill|state|describe|name|record|make|"
    r"identify|evaluate|give|tell|read|place|put|count|sort|build|construct|"
    r"graph|mark|locate|list|convert|round|rewrite|express|check|verify|predict)\b",
    re.I,
)
DEICTIC = re.compile(
    r"\b(?:these|those) (?:\w+\s+){0,2}(?:expressions?|equations?|relationships?|objects?|"
    r"figures?|images?|pictures?|diagrams?|rooms?|values?|strategies?|numbers?|"
    r"shapes?|graphs?|tables?)\b|\bthe following\b|"
    r"\beach (?:expression|equation|image|picture|diagram|figure|graph|table)\b|"
    r"\bthis (?:expression|equation|image|picture|diagram|figure|graph|table|"
    r"number line|relationship|pattern|shape|problem|situation|flag|recipe|"
    r"package|crew|speed|rate|difference)\b|"
    r"\bthe (?:image|picture|diagram|figure|graph|number line)\b|"
    r"\b(?:in|from|using|complete) the table\b|"
    r"\bthe table (?:above|below|shown|represents|with)\b",
    re.I,
)
VISUAL_INPUT = re.compile(
    r"\b(?:shown|pictured|displayed) (?:above|below|here|in|on)\b|"
    r"\b(?:in|from|by|using|use|look at|shown in|shown on) (?:the|this|these|each|a|an)?\s*"
    r"(?:image|picture|diagram|figure|graph|table|number line|plot)\b|"
    r"\bhere (?:is|are) (?:a|an|the|some)?\s*(?:image|picture|diagram|figure|graph|table|number line|plot)\b|"
    r"\b(?:image|picture|diagram|figure|graph|table|number line|plot) (?:above|below|shown|provided)\b",
    re.I,
)
VISUAL_SURFACE = re.compile(
    r"\b(?:each|this|the|these|following|a|an)?\s*"
    r"(?:image|images|picture|pictures|photo|photograph|diagram|graph|plot|"
    r"number line|coordinate plane|figure|geometric objects|objects)\b",
    re.I,
)
TOKEN = re.compile(r"\S+")


def fail(message: str) -> NoReturn:
    raise SystemExit(f"build_im_defragged_task_instances.py: {message}")


def norm(text: str) -> str:
    return " ".join(text.split())


def records() -> list[dict]:
    result = subprocess.run(
        ["swipl", "-q", "-g", SWI_GOAL],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode:
        fail(f"SWI input reader failed: {result.stderr.strip()}")
    return [json.loads(line) for line in result.stdout.splitlines()]


def question_missing_referent(text: str) -> bool:
    value = norm(text)
    if "?" not in value or not DEICTIC.search(value):
        return False
    low = value.lower()
    if "this difference" in low and re.search(
        r"\b(?:largest|smallest) difference\b", low.split("this difference")[0]
    ):
        return False
    inline_entity = re.search(
        r"\bthis (?:home|package|coupon|elevator|speed|situation|problem)\b", low
    )
    if inline_entity:
        before = low[: inline_entity.start()]
        if len(before.split()) >= 7 and re.search(
            r"\d|\b(?:is|are|costs?|travels?|earns?|paid)\b", before
        ):
            return False
    if "this expression" in low:
        before = low[: low.find("this expression")]
        if re.search(r"\d\s*[+\-−×÷/]", before):
            return False
    if "these two figures" in low and len(re.findall(r"\d+", low)) >= 4:
        return False
    if "this rate" in low:
        before = low[: low.find("this rate")]
        if len(re.findall(r"\d+(?:[,.]\d+)?", before)) >= 2 or (
            " per " in before and re.search(r"\d", before)
        ):
            return False
    if re.search(r"\bthis diagram\b", low) and re.search(r"\[[^\]]{6,}\]", low):
        return False
    each_expression = re.search(r"\beach (?:expression|equation)\b", low)
    if each_expression:
        after = low[each_expression.end() :]
        if re.search(r"\d\s*[=+\-−×÷/]|[a-z]\s*[=·]", after):
            return False
    return True


def missing_visual(text: str, full: str = "") -> bool:
    value = norm(text)
    low = value.lower()
    combined = full or value
    if re.search(
        r"\b(?:each|this|the|these|following) (?:image|images|picture|pictures|photo|photograph)\b|"
        r"\b(?:image|images|picture|pictures) (?:above|below|shown|provided|of)\b|"
        r"\bin image [a-z0-9]\b|\bhere (?:is|are) (?:an? |some )?(?:image|images|picture|pictures)\b",
        low,
    ):
        return True
    if re.search(
        r"\b(?:this|the) (?:diagram|graph|plot|number line|coordinate plane|figure)\b",
        low,
    ) and not re.search(r"\[[^\]]{6,}\]|\$\$|\\begin\{", combined):
        return True
    if re.search(
        r"\b(?:which of the geometric objects|pick two of the objects)\b", low
    ):
        return True
    if not VISUAL_INPUT.search(value):
        return False
    if "table" in low and "|" in combined:
        return False
    if re.search(r"\[[^\]]{6,}\]|\$\$|\\begin\{", combined):
        return False
    return bool(
        re.search(
            r"\b(?:diagram|graph|plot|number line|coordinate plane|figure)\b", low
        )
    )


def standalone_complete(text: str) -> bool:
    value = norm(text).strip('“”" ')
    return bool(value and ("?" in value or IMPERATIVE.search(value)))


def root_position(position: str) -> str | None:
    match = re.search(r"student_task_statement\(\d+\)", position)
    return match.group(0) if match else None


def task_core(task: str) -> str:
    value = re.sub(r"^productive-", "", task)
    return re.sub(r"^deformation\([^)]*\)-", "", value)


def failed_task_ranges() -> dict[str, list[tuple[int, int]]]:
    sys.path.insert(0, str(ROOT / "scripts/research"))
    import extract_lesson_context as context  # noqa: E402

    out: dict[str, list[tuple[int, int]]] = defaultdict(list)
    for path in sorted(
        (ROOT / "curriculum/im_teacher_guides").glob("*/unit*/lesson[0-9]*.md")
    ):
        if not re.fullmatch(r"lesson\d+", path.stem):
            continue
        text = path.read_text(encoding="utf-8")
        anchor = context.ANCHOR_RE.search(text)
        raw = context.raw_extract(text)
        if not anchor or raw is None:
            continue
        code = anchor.group(1)
        lines, offset = raw
        current = "Lesson"
        index = 0
        while index < len(lines):
            major = context.section_heading(lines[index])
            if major:
                current = major
            if "Student Task Statement" in lines[index]:
                item, nxt = context.task_statement(lines, index, current)
                if item is None:
                    out[code].append((index + 1 + offset, max(nxt, index + 1) + offset))
                index = nxt
                continue
            index += 1
    return out


def choose_span(
    record: dict, spans_by_key: dict, recovered_by_key: dict, by_lesson: dict
):
    position = root_position(record["position"])
    if position:
        source = (
            recovered_by_key if record["source_kind"] == "recovered" else spans_by_key
        )
        span = source.get((record["lesson"], position))
        if span:
            return span
    excerpt = norm(record["excerpt"])
    hits = [
        span
        for span in by_lesson.get(record["lesson"], [])
        if excerpt and excerpt in norm(span.text)
    ]
    return hits[0] if len(hits) == 1 else None


def span_text_for_record(record: dict, span) -> tuple[str, int, int]:
    item = re.search(r"/item\((\d+)\)", record["position"])
    if item:
        chunks = compiler._task_chunks(span)
        number = int(item.group(1))
        if 1 <= number <= len(chunks):
            start, end, _position, text = chunks[number - 1]
            return text, start, end
    if record["source_kind"] == "pdf" and not question_missing_referent(
        record["excerpt"]
    ):
        excerpt = norm(record["excerpt"])
        hits = [
            (start, end, text)
            for start, end, _position, text in compiler._task_chunks(span)
            if excerpt and excerpt in norm(text)
        ]
        if len(hits) == 1:
            start, end, text = hits[0]
            return text, start, end
    if span.lines:
        return span.text, span.lines[0][0], span.lines[-1][0]
    return span.text, span.heading_line, span.end_line


def classify(rows: list[dict]) -> list[dict]:
    docs = compiler.read_teacher_guides(ROOT)
    spans = compiler.extract_student_task_spans(docs)
    spans_by_key = {(span.code, span.position): span for span in spans}
    recovered_spans = compiler.read_recovered_task_spans(ROOT, spans)
    recovered_by_key = {(span.code, span.position): span for span in recovered_spans}
    by_lesson: dict[str, list] = defaultdict(list)
    for span in spans:
        by_lesson[span.code].append(span)
    failed = failed_task_ranges()

    direct = []
    peer_candidates: dict[tuple[str, str], list] = defaultdict(list)
    for row in rows:
        span = choose_span(row, spans_by_key, recovered_by_key, by_lesson)
        direct.append(span)
        if span is not None:
            key = (row["lesson"], task_core(row["task"]))
            if all(existing != span for existing in peer_candidates[key]):
                peer_candidates[key].append(span)

    results = []
    for index, row in enumerate(rows):
        row = dict(row)
        excerpt = row["excerpt"]
        row["missing_referent"] = question_missing_referent(excerpt)
        row["visual"] = missing_visual(excerpt)
        row["fragment"] = (
            not standalone_complete(excerpt) or row["missing_referent"] or row["visual"]
        )
        span = direct[index]
        if span is None and row["task"].startswith("deformation("):
            peers = peer_candidates.get((row["lesson"], task_core(row["task"])), [])
            if len(peers) == 1:
                span = peers[0]
        row["span"] = span
        if span:
            full, start, end = span_text_for_record(row, span)
            row.update(full=full, full_start=start, full_end=end)
            row["full_visual"] = missing_visual(full, full)
            row["full_complete"] = standalone_complete(full)
            row["referent_recovered"] = (
                row["missing_referent"]
                and norm(full) != norm(excerpt)
                and not row["full_visual"]
                and len(norm(full).split()) >= len(norm(excerpt).split()) + 5
            )
        else:
            row.update(
                full="",
                full_start=0,
                full_end=0,
                full_visual=False,
                full_complete=False,
                referent_recovered=False,
            )
        row["failed_layout"] = False
        if row["source_kind"] == "markdown":
            for start, end in failed.get(row["lesson"], []):
                if not (row["end"] < start or row["start"] > end):
                    row["failed_layout"] = True
        upstream_status = row.get("upstream_status", "legacy")
        if upstream_status == "complete":
            outcome = "already_standalone"
        elif upstream_status == "recovered":
            outcome = (
                "vision_task_recovered"
                if "recovery(vision(" in row["evidence_term"]
                else "json_task_recovered"
            )
        elif upstream_status == "blocked_missing_visual":
            outcome = "blocked_by_missing_image"
        elif upstream_status == "blocked_layout":
            outcome = "blocked_by_layout"
        elif upstream_status != "legacy":
            fail(f"unknown upstream extraction status: {upstream_status}")
        elif not row["fragment"]:
            outcome = "already_standalone"
        elif row["visual"] or (span and row["full_visual"]):
            outcome = "blocked_by_missing_image"
        elif row["failed_layout"]:
            outcome = "blocked_by_layout"
        elif row["missing_referent"] and row["referent_recovered"]:
            outcome = "recoverable_with_referent_context"
        elif span and row["full_complete"]:
            outcome = "complete_task_recovered"
        else:
            outcome = "blocked_by_layout"
        row["outcome"] = outcome
        if upstream_status != "legacy" and outcome.startswith("blocked_by_"):
            row["blocker"] = row.get("upstream_blocker", "upstream_blocker_missing")
        elif outcome == "blocked_by_layout":
            if row["failed_layout"]:
                row["blocker"] = "known_cross_page_layout_refusal"
            elif row["source_kind"] == "pdf" and span is None:
                row["blocker"] = "pdf_source_absent_no_unique_markdown_join"
            elif row["source_kind"] == "markdown" and span is None:
                row["blocker"] = "task_external_evidence_no_unique_productive_peer"
            else:
                row["blocker"] = "joined_source_span_not_complete"
        elif outcome == "blocked_by_missing_image":
            row["blocker"] = "required_visual_asset_unresolved"
        else:
            row["blocker"] = "none"
        results.append(row)
    legacy = results[:2146]
    legacy_outcomes = Counter(row["outcome"] for row in legacy)
    if len(legacy) != 2146 or legacy_outcomes != EXPECTED_OUTCOMES:
        fail(
            f"legacy scout census drift: rows={len(legacy)}, "
            f"outcomes={legacy_outcomes}"
        )
    return results


@dataclass(frozen=True)
class MappedToken:
    text: str
    path: str
    byte_start: int
    byte_end: int
    line: int
    decoder: str


@dataclass
class StatementMap:
    statement: str
    tokens: list[MappedToken]
    target_ranges: list[tuple[int, int]]

    def token_slice(self, start: int, end: int) -> list[MappedToken]:
        selected = []
        for token, (token_start, token_end) in zip(self.tokens, self.target_ranges):
            overlap_start = max(start, token_start)
            overlap_end = min(end, token_end)
            if overlap_start >= overlap_end:
                continue
            left = overlap_start - token_start
            right = overlap_end - token_start
            if token.decoder == "utf8":
                prefix = token.text[:left].encode("utf-8")
                body = token.text[left:right].encode("utf-8")
                byte_start = token.byte_start + len(prefix)
                byte_end = byte_start + len(body)
            else:
                ensure_ascii = token.decoder == "json_string_ascii"
                raw = json.dumps(token.text, ensure_ascii=ensure_ascii)[1:-1]
                prefix = json.dumps(token.text[:left], ensure_ascii=ensure_ascii)[1:-1]
                body = json.dumps(token.text[left:right], ensure_ascii=ensure_ascii)[
                    1:-1
                ]
                suffix = json.dumps(token.text[right:], ensure_ascii=ensure_ascii)[1:-1]
                if raw != prefix + body + suffix:
                    fail("cannot slice an encoded provenance token")
                byte_start = token.byte_start + len(prefix.encode("utf-8"))
                byte_end = byte_start + len(body.encode("utf-8"))
            selected.append(
                MappedToken(
                    token.text[left:right],
                    token.path,
                    byte_start,
                    byte_end,
                    token.line,
                    token.decoder,
                )
            )
        return selected


class SourceFiles:
    def __init__(self) -> None:
        self.data: dict[str, bytes] = {}
        self.newlines: dict[str, list[int]] = {}

    def read(self, path: str) -> bytes:
        if path not in self.data:
            data = (ROOT / path).read_bytes()
            self.data[path] = data
            self.newlines[path] = [i for i, value in enumerate(data) if value == 10]
        return self.data[path]

    def line(self, path: str, offset: int) -> int:
        self.read(path)
        return bisect_right(self.newlines[path], offset) + 1


SOURCES = SourceFiles()


def _target_ranges(statement: str) -> list[tuple[int, int]]:
    return [(match.start(), match.end()) for match in TOKEN.finditer(statement)]


def map_guide_statement(target: str, span, start: int, end: int) -> StatementMap:
    statement = norm(target)
    target_values = TOKEN.findall(statement)
    path = span.source
    data = SOURCES.read(path)
    physical = data.splitlines(keepends=True)
    offsets = []
    cursor = 0
    for raw in physical:
        offsets.append(cursor)
        cursor += len(raw)
    source_tokens: list[MappedToken] = []
    for line_number, cleaned in span.lines:
        if not start <= line_number <= end:
            continue
        raw = physical[line_number - 1].rstrip(b"\r\n")
        decoded = raw.decode("utf-8")
        column = decoded.find(cleaned)
        if column < 0:
            fail(f"cannot locate extracted text at {path}:{line_number}: {cleaned!r}")
        base = offsets[line_number - 1] + len(decoded[:column].encode("utf-8"))
        for match in TOKEN.finditer(cleaned):
            byte_start = base + len(cleaned[: match.start()].encode("utf-8"))
            byte_end = base + len(cleaned[: match.end()].encode("utf-8"))
            source_tokens.append(
                MappedToken(
                    match.group(0), path, byte_start, byte_end, line_number, "utf8"
                )
            )
    values = [token.text for token in source_tokens]
    hit = next(
        (
            index
            for index in range(len(values) - len(target_values) + 1)
            if values[index : index + len(target_values)] == target_values
        ),
        None,
    )
    if hit is None:
        fail(
            f"statement does not map to ordered source tokens in {path}:{start}-{end}: {statement!r}"
        )
    mapped = source_tokens[hit : hit + len(target_values)]
    return StatementMap(statement, mapped, _target_ranges(statement))


def _encoded_char(value: str, *, ensure_ascii: bool) -> str:
    return json.dumps(value, ensure_ascii=ensure_ascii)[1:-1]


def map_encoded_statement(
    target: str,
    decoded_source: str,
    path: str,
    content_start: int,
    raw_content: bytes,
) -> StatementMap:
    statement = norm(target)
    source_matches = list(TOKEN.finditer(decoded_source))
    target_values = TOKEN.findall(statement)
    values = [match.group(0) for match in source_matches]
    hit = next(
        (
            index
            for index in range(len(values) - len(target_values) + 1)
            if values[index : index + len(target_values)] == target_values
        ),
        None,
    )
    if hit is None:
        fail(f"statement does not map to encoded source text in {path}: {statement!r}")
    ensure_ascii = True
    encoded_source = "".join(
        _encoded_char(char, ensure_ascii=ensure_ascii) for char in decoded_source
    ).encode("utf-8")
    if encoded_source != raw_content:
        ensure_ascii = False
        encoded_source = "".join(
            _encoded_char(char, ensure_ascii=ensure_ascii) for char in decoded_source
        ).encode("utf-8")
    if encoded_source != raw_content:
        fail(f"encoded source bytes do not decode exactly in {path}")
    char_offsets = [0]
    for char in decoded_source:
        encoded_char = _encoded_char(char, ensure_ascii=ensure_ascii).encode("utf-8")
        char_offsets.append(char_offsets[-1] + len(encoded_char))
    mapped = []
    for match in source_matches[hit : hit + len(target_values)]:
        byte_start = content_start + char_offsets[match.start()]
        byte_end = content_start + char_offsets[match.end()]
        mapped.append(
            MappedToken(
                match.group(0),
                path,
                byte_start,
                byte_end,
                SOURCES.line(path, byte_start),
                "json_string_ascii" if ensure_ascii else "json_string_utf8",
            )
        )
    return StatementMap(statement, mapped, _target_ranges(statement))


def map_text_file_statement(target: str, path: str) -> StatementMap:
    statement = norm(target)
    data = SOURCES.read(path)
    decoded = data.decode("utf-8")
    # Shared contract: the whitespace-normalized statement must be an exact,
    # contiguous character sequence in the description; surrounding text or
    # punctuation is not part of the statement.
    span = vision_statement_contract.normalized_contiguous_span(statement, decoded)
    if span is None:
        fail(f"vision statement does not map to its description file: {path}")
    matches = list(TOKEN.finditer(decoded, *span))
    mapped = []
    for match in matches:
        start = len(decoded[: match.start()].encode("utf-8"))
        end = len(decoded[: match.end()].encode("utf-8"))
        mapped.append(
            MappedToken(
                match.group(0), path, start, end, SOURCES.line(path, start), "utf8"
            )
        )
    return StatementMap(statement, mapped, _target_ranges(statement))


def scan_compiled_file(path: Path, prefix: str, *, expected: int | None) -> list[dict]:
    data = path.read_bytes()
    if not data.isascii():
        fail("compiled task artifact unexpectedly contains non-ASCII bytes")
    text = data.decode("ascii")
    facts = []
    cursor = 0
    while True:
        start = text.find(prefix, cursor)
        if start < 0:
            break
        depth = 0
        in_string = False
        escaped = False
        end = None
        for index in range(start, len(text)):
            char = text[index]
            if in_string:
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == '"':
                    in_string = False
                continue
            if char == '"':
                in_string = True
            elif char == "(":
                depth += 1
            elif char == ")":
                depth -= 1
                if depth == 0 and text[index + 1 : index + 2] == ".":
                    end = index + 2
                    break
        if end is None:
            fail(f"unterminated compiled fact at byte {start}")
        facts.append(
            {"start": start, "end": end, "text": text[start:end], "path": path}
        )
        cursor = end
    if expected is not None and len(facts) != expected:
        fail(f"expected {expected} compiled facts in {path.name}, found {len(facts)}")
    return facts


def scan_compiled_facts() -> list[dict]:
    return [
        *scan_compiled_file(
            COMPILED, "compiled_lesson_task_instance(", expected=2146
        ),
        *scan_compiled_file(
            GRADE8_COMPILED, "extracted_lesson_task_instance(", expected=None
        ),
    ]


def compiled_excerpt_map(row: dict, fact: dict) -> StatementMap:
    encoded = json.dumps(row["excerpt"], ensure_ascii=True)
    needle = f"excerpt({encoded})"
    local = fact["text"].find(needle)
    if local < 0:
        fail(f"compiled excerpt bytes not found for {row['lesson']}/{row['task']}")
    content_start = fact["start"] + local + len("excerpt(") + 1
    raw = encoded[1:-1].encode("ascii")
    return map_encoded_statement(
        row["excerpt"],
        row["excerpt"],
        str(fact["path"].relative_to(ROOT)),
        content_start,
        raw,
    )


def recovered_string_locations() -> dict[tuple[str, str], tuple[int, bytes, str]]:
    data = RECOVERED.read_bytes()
    payload = json.loads(data)
    rows = payload["spans"]
    pattern = re.compile(rb'"recovered_text"\s*:\s*"')
    matches = list(pattern.finditer(data))
    if len(matches) != len(rows):
        fail("recovered sidecar string count drift")
    locations = {}
    for row, match in zip(rows, matches):
        start = match.end()
        cursor = start
        escaped = False
        while cursor < len(data):
            value = data[cursor]
            if escaped:
                escaped = False
            elif value == 92:
                escaped = True
            elif value == 34:
                break
            cursor += 1
        raw = data[start:cursor]
        decoded = json.loads(b'"' + raw + b'"')
        if decoded != row["recovered_text"]:
            fail(f"recovered sidecar decode drift: {row['lesson']}/{row['position']}")
        locations[(row["lesson"], row["position"])] = (start, raw, decoded)
    return locations


def json_recovery_records() -> dict[tuple[str, str], dict]:
    records = {}
    if not JSON_RECOVERY_DIR.is_dir():
        return records
    for path in sorted(JSON_RECOVERY_DIR.glob("IM-G8-*.json")):
        payload = json.loads(path.read_text(encoding="utf-8"))
        for task in payload.get("tasks", []):
            recovery = task.get("recovery")
            if task.get("extraction_status") != "recovered" or not isinstance(
                recovery, dict
            ):
                continue
            key = (payload["lesson"], task["position"])
            if key in records:
                fail(f"duplicate JSON recovery checkpoint: {key}")
            records[key] = recovery
    return records


def map_json_recovery_statement(target: str, recovery: dict) -> StatementMap:
    from scripts.curriculum import recover_docling_grade8 as json_recovery

    statement = norm(target)
    if statement != recovery.get("normalized_statement"):
        fail("JSON recovery statement differs from its checkpoint rendering")
    tokens = []
    ranges = []
    cursor = 0
    for item in recovery.get("items", []):
        normalized = item["normalized"]
        if not normalized:
            continue
        path = item["path"]
        start = item["byte_start"]
        end = item["byte_end"]
        raw_content = SOURCES.read(path)[start:end]
        try:
            decoded = json.loads(b'"' + raw_content + b'"')
        except json.JSONDecodeError as exc:
            fail(f"cannot decode JSON recovery bytes in {path}: {exc}")
        if decoded != item["raw"]:
            fail(f"JSON recovery raw value drift at {path}:{item['ref']}")
        if json_recovery.normalize_item(item["kind"], decoded) != normalized:
            fail(f"JSON recovery normalization drift at {path}:{item['ref']}")
        if tokens:
            cursor += 1
        ranges.append((cursor, cursor + len(normalized)))
        cursor += len(normalized)
        decoder = (
            json_recovery.NORMALIZATION_RULE
            if item["kind"] == "formula"
            else "docling_json_text_v1"
        )
        tokens.append(
            MappedToken(
                normalized,
                path,
                start,
                end,
                item["line"],
                decoder,
            )
        )
    if " ".join(token.text for token in tokens) != statement:
        fail("JSON recovery items do not reconstruct the normalized statement")
    return StatementMap(statement, tokens, ranges)


class SegmentStore:
    def __init__(self) -> None:
        self.rows: dict[str, dict] = {}

    def add_tokens(self, tokens: list[MappedToken]) -> list[str]:
        merged: list[MappedToken] = []
        for token in tokens:
            if merged:
                previous = merged[-1]
                gap = SOURCES.read(token.path)[previous.byte_end : token.byte_start]
                if (
                    previous.path == token.path
                    and previous.decoder == token.decoder
                    and previous.line == token.line
                    and gap == b" "
                ):
                    merged[-1] = MappedToken(
                        previous.text + " " + token.text,
                        previous.path,
                        previous.byte_start,
                        token.byte_end,
                        previous.line,
                        previous.decoder,
                    )
                    continue
            merged.append(token)
        ids = []
        for token in merged:
            raw = SOURCES.read(token.path)[token.byte_start : token.byte_end]
            key = f"{token.path}\0{token.byte_start}\0{token.byte_end}\0{token.decoder}"
            segment_id = "seg_" + hashlib.sha256(key.encode()).hexdigest()[:20]
            row = {
                "id": segment_id,
                "path": token.path,
                "line_start": token.line,
                "line_end": SOURCES.line(
                    token.path, max(token.byte_end - 1, token.byte_start)
                ),
                "byte_start": token.byte_start,
                "byte_end": token.byte_end,
                "decoder": token.decoder,
                "sha256": hashlib.sha256(raw).hexdigest(),
            }
            if segment_id in self.rows and self.rows[segment_id] != row:
                fail(f"segment ID collision: {segment_id}")
            self.rows[segment_id] = row
            ids.append(segment_id)
        return ids


def type_specimen_referents(statement: str) -> list[str]:
    """Return copied equation sides answering a 'these two expressions' prompt."""
    marker = re.search(r"these two expressions", statement, re.I)
    if not marker:
        return []
    parenthetical = re.search(r"\(([^()]*=[^()]*)\)", statement[marker.end() :])
    if not parenthetical:
        return []
    equation = parenthetical.group(1)
    sides = [norm(side) for side in equation.split("=", 1)]
    return sides if len(sides) == 2 and all(sides) else []


def referents_for(row: dict, mapping: StatementMap, store: SegmentStore) -> list[dict]:
    refs = []
    deictic = DEICTIC.search(mapping.statement)
    if deictic:
        surface = deictic.group(0)
        surface_ids = store.add_tokens(
            mapping.token_slice(deictic.start(), deictic.end())
        )
        recovered = row["referent_recovered"]
        carried = not row["missing_referent"]
        antecedent_end = deictic.start()
        antecedent = (
            mapping.statement[:antecedent_end].strip() if (recovered or carried) else ""
        )
        antecedent_ids = (
            store.add_tokens(mapping.token_slice(0, antecedent_end))
            if antecedent
            else []
        )
        terminal = re.findall(r"[A-Za-z]+", surface.lower())
        refs.append(
            {
                "surface": surface,
                "kind": terminal[-1].rstrip("s") if terminal else "deictic",
                "status": "recovered"
                if recovered
                else "carried_inline"
                if carried
                else "missing",
                "segments": surface_ids,
                "antecedent": antecedent,
                "antecedent_segments": antecedent_ids,
                "absence_reason": "none"
                if antecedent
                else "antecedent_not_in_available_source",
            }
        )
    for surface in type_specimen_referents(mapping.statement):
        start = mapping.statement.find(surface)
        refs.append(
            {
                "surface": surface,
                "kind": "expression",
                "status": "recovered",
                "segments": store.add_tokens(
                    mapping.token_slice(start, start + len(surface))
                ),
                "antecedent": "",
                "antecedent_segments": [],
                "absence_reason": "none",
            }
        )
    return refs


def visuals_for(row: dict, mapping: StatementMap, store: SegmentStore) -> list[dict]:
    if row["outcome"] != "blocked_by_missing_image":
        return []
    match = VISUAL_SURFACE.search(mapping.statement)
    if not match and row.get("upstream_status") == "legacy":
        fail(f"visual-blocked row has no visual surface: {row['lesson']}/{row['task']}")
    path = mapping.tokens[0].path
    if path.startswith("curriculum/im_teacher_guides/"):
        status = "missing_from_guide_markdown"
        asset = "none"
    elif "/docling/full-output/TeacherLessonGuides/" in path:
        status = "excluded_docling_asset"
        asset = str((Path(path).parent / "document_artifacts").as_posix())
    else:
        status = "missing_from_absent_pdf"
        asset = "none"
    surface = match.group(0) if match else "source visual"
    return [
        {
            "surface": surface,
            "status": status,
            "asset": asset,
            "source_segments": (
                store.add_tokens(mapping.token_slice(match.start(), match.end()))
                if match
                else []
            ),
        }
    ]


def _prolog(value) -> str:
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=True)
    if isinstance(value, int):
        return str(value)
    if isinstance(value, list):
        return "[" + ", ".join(_prolog(item) for item in value) + "]"
    fail(f"unsupported Prolog scalar: {value!r}")


def _atom(value: str) -> str:
    if re.fullmatch(r"[a-z][a-zA-Z0-9_]*", value):
        return value
    return "'" + value.replace("'", "''") + "'"


def _dict(tag: str, value: dict, *, atoms: set[str] = frozenset()) -> str:
    fields = []
    for key, item in value.items():
        if key in atoms:
            rendered = _atom(item)
        elif isinstance(item, list) and item and isinstance(item[0], dict):
            child_tag = {
                "source_segments": "segment",
                "referents": "referent",
                "visuals": "visual",
            }[key]
            child_atoms = {
                "source_segments": {"decoder"},
                "referents": {"kind", "status", "absence_reason"},
                "visuals": {"status", "asset"}
                if all(v.get("asset") == "none" for v in item)
                else {"status"},
            }[key]
            rendered = (
                "["
                + ", ".join(_dict(child_tag, row, atoms=child_atoms) for row in item)
                + "]"
            )
        elif isinstance(item, list):
            rendered = "[" + ", ".join(_atom(part) for part in item) + "]"
        else:
            rendered = _prolog(item)
        fields.append(f"{key}:{rendered}")
    return f"{tag}{{" + ", ".join(fields) + "}"


def render(results: list[dict], facts: list[dict]) -> str:
    recovered_locations = recovered_string_locations()
    json_recoveries = json_recovery_records()
    occurrence: Counter[str] = Counter()
    status_counts = Counter(STATUS[row["outcome"]] for row in results)
    lines = [
        "/** <module> Generated source-sliced IM task instances",
        " *",
        " * Generated by scripts/curriculum/build_im_defragged_task_instances.py.",
        " * Do not edit by hand. Blocked rows are retained with named blockers.",
        " */",
        ":- module(compiled_defragged_task_instances,",
        "          [ defragged_task_instance/4,",
        "            defragged_task_instance_summary/2",
        "          ]).",
        "",
        f"defragged_task_instance_summary({len(results)},",
        "    counts{" + ", ".join(
            f"{status}:{count}"
            for status, count in sorted(status_counts.items())
        ) + "}).",
        "",
    ]
    for row, fact in zip(results, facts):
        fact_bytes = fact["text"].encode("ascii")
        evidence_sha = hashlib.sha256(fact_bytes).hexdigest()
        stable_key = "\0".join(
            [row["lesson"], row["task"], row["evidence_term"], evidence_sha]
        )
        digest = hashlib.sha256(stable_key.encode()).hexdigest()[:24]
        occurrence[digest] += 1
        record_id = f"im_defrag_{digest}_{occurrence[digest]}"
        outcome = row["outcome"]
        if outcome in {
            "already_standalone",
            "json_task_recovered",
            "vision_task_recovered",
        }:
            statement = row["excerpt"]
        elif outcome in {
            "complete_task_recovered",
            "recoverable_with_referent_context",
        }:
            statement = row["full"]
        elif outcome == "blocked_by_missing_image":
            statement = row["full"] or row["excerpt"]
        else:
            statement = ""

        store = SegmentStore()
        mapping = None
        if statement:
            span = row["span"]
            if outcome == "json_task_recovered":
                key = (row["lesson"], root_position(row["position"]))
                recovery = json_recoveries.get(key)
                if recovery is None:
                    fail(f"missing JSON recovery checkpoint: {key}")
                mapping = map_json_recovery_statement(statement, recovery)
            elif outcome == "vision_task_recovered":
                match = re.search(r"description_file\('([^']+)'\)", row["evidence_term"])
                if match is None:
                    fail("vision recovery lacks a description file")
                mapping = map_text_file_statement(statement, match.group(1))
            elif row["source_kind"] == "recovered" and span is not None:
                key = (row["lesson"], root_position(row["position"]))
                content_start, raw, decoded = recovered_locations[key]
                mapping = map_encoded_statement(
                    statement,
                    decoded,
                    str(RECOVERED.relative_to(ROOT)),
                    content_start,
                    raw,
                )
            elif span is not None:
                if outcome == "already_standalone":
                    start, end = span.lines[0][0], span.lines[-1][0]
                else:
                    start, end = row["full_start"], row["full_end"]
                try:
                    mapping = map_guide_statement(statement, span, start, end)
                except SystemExit:
                    if outcome != "already_standalone":
                        raise
            if mapping is None:
                mapping = compiled_excerpt_map(row, fact)
            statement = mapping.statement
            statement_segments = store.add_tokens(mapping.tokens)
            referents = (
                []
                if outcome in {"json_task_recovered", "vision_task_recovered"}
                else referents_for(row, mapping, store)
            )
            visuals = visuals_for(row, mapping, store)
        else:
            statement_segments = []
            fragment_mapping = compiled_excerpt_map(row, fact)
            referents = referents_for(row, fragment_mapping, store)
            visuals = []

        data = {
            "evidence_sha256": evidence_sha,
            "status": STATUS[outcome],
            "blocker": row["blocker"],
            "complete_statement": statement,
            "statement_joiner": " ",
            "statement_segments": statement_segments,
            "referents": referents,
            "visuals": visuals,
            "source_segments": list(store.rows.values()),
        }
        if not statement:
            data["available_fragment"] = fragment_mapping.statement
            data["fragment_joiner"] = " "
            data["fragment_segments"] = store.add_tokens(fragment_mapping.tokens)
            data["source_segments"] = list(store.rows.values())
        rendered = _dict(
            "defragged_task",
            data,
            atoms={"status", "blocker"},
        )
        # source_evidence remains a Prolog term, not a lossy serialization.
        rendered = rendered[:-1] + f", source_evidence:{row['evidence_term']}}}"
        lines.extend(
            [
                f"defragged_task_instance({record_id},",
                f"    {_atom(row['lesson'])},",
                f"    {row['task']},",
                f"    {rendered}).",
                "",
            ]
        )
    return "\n".join(lines)


def build() -> str:
    rows = records()
    facts = scan_compiled_facts()
    if len(rows) != len(facts):
        fail("Prolog input rows do not align with compiled fact blocks")
    return render(classify(rows), facts)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--output", type=Path, default=OUTPUT)
    args = parser.parse_args()
    rendered = build()
    if args.check:
        if (
            not args.output.exists()
            or args.output.read_text(encoding="utf-8") != rendered
        ):
            fail(f"generated artifact is stale: {args.output.relative_to(ROOT)}")
        print("PASS im defrag generator: artifact is byte-current")
        return
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        "w", encoding="utf-8", dir=args.output.parent, delete=False
    ) as handle:
        handle.write(rendered)
        temporary = Path(handle.name)
    temporary.replace(args.output)
    try:
        display = args.output.relative_to(ROOT)
    except ValueError:
        display = args.output
    print(f"wrote {display} ({len(rendered.encode('utf-8'))} bytes)")


if __name__ == "__main__":
    main()
