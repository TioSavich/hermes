#!/usr/bin/env python3
"""The question corpus as the mining unit: sentences inside compiled records.

Q0 fixed the unit. A compiled record can bundle several sentences carrying
different forces, so a move cites record plus sentence index, and every
sentence keeps its character span inside the record text. The prefilter drops
rows that are not questions to students, counted rather than dropped quietly.
"""
from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RUNTIME = ROOT / "hermes" / "app" / "runtime" / "experiments" / "questions"
RECORDS = RUNTIME / "question_records.jsonl"

# Activity locations that hold no question to a student. Q0 named the first
# two classes; the rest are the same extractor heuristic reaching into course
# mechanics. Every exclusion is counted by class.
PREFILTER_LOCATIONS = {
    "Teacher Reflection Questions": "teacher_reflection",
    "Suggested Centers": "center_choice",
    "Materials to Copy": "course_mechanics",
    "Standards": "course_mechanics",
    "Lesson Timeline": "course_mechanics",
}

SENTENCE_END = re.compile(r"(?<=[?!])\s+|(?<=\.)\s+(?=[A-Z(])")

# F-Q3, the class that needs a second student's work. The curriculum writes the
# missing name three ways: a plain blank, a markdown-escaped blank, and — where
# the extractor stripped it — an orphaned possessive with nothing in front of
# it. Each signal is named so the report can say which one fired.
PEER_WORK_SIGNALS = {
    "blank_plain": re.compile(r"_{2,}"),
    "blank_escaped": re.compile(r"(?:\\_){2,}"),
    "stripped_name_possessive": re.compile(r"(?:^|\s)'s\b"),
    "partner_work": re.compile(
        r"\b(?:you and your partner|your partner|both partners|with a partner|"
        r"your classmates?|their classmates?)\b", re.I),
    "another_students_work": re.compile(
        r"\b(?:their|his|her)\s+(?:work|strategy|strategies|reasoning|thinking|"
        r"method|methods|idea|ideas)\b", re.I),
    "agree_with_a_person": re.compile(
        r"\bagree (?:or disagree )?with (?:how )?(?:he|she|they|him|her|them)\b", re.I),
}

# Words that could carry a task pattern: an operation, a comparison, a
# representation of quantity, or a quantity noun. A sentence with none of
# these and no numeral cannot name a region of input space, whatever else it
# is worth in a classroom.
OPERATION_WORDS = {
    "add": "add", "adds": "add", "added": "add", "adding": "add", "addition": "add",
    "sum": "add", "sums": "add", "total": "add", "altogether": "add", "plus": "add",
    "combine": "add", "combined": "add", "join": "add", "more": "add",
    "subtract": "subtract", "subtracts": "subtract", "subtracted": "subtract",
    "subtracting": "subtract", "subtraction": "subtract", "difference": "subtract",
    "minus": "subtract", "fewer": "subtract", "less": "subtract", "left": "subtract",
    "take": "subtract", "took": "subtract", "away": "subtract", "remain": "subtract",
    "multiply": "multiply", "multiplies": "multiply", "multiplied": "multiply",
    "multiplying": "multiply", "multiplication": "multiply", "product": "multiply",
    "times": "multiply", "groups": "multiply", "each": "multiply", "array": "multiply",
    "divide": "divide", "divides": "divide", "divided": "divide", "dividing": "divide",
    "division": "divide", "quotient": "divide", "share": "divide", "shared": "divide",
    "split": "divide", "half": "divide", "quarter": "divide", "per": "divide",
    "fraction": "fraction", "fractions": "fraction", "numerator": "fraction",
    "denominator": "fraction", "unit": "fraction", "eighths": "fraction",
    "fourths": "fraction", "thirds": "fraction", "halves": "fraction",
    "decimal": "decimal", "decimals": "decimal", "tenths": "decimal",
    "hundredths": "decimal", "thousandths": "decimal",
    "compare": "compare", "compared": "compare", "greater": "compare",
    "larger": "compare", "smaller": "compare", "equal": "compare",
    "equivalent": "compare", "same": "compare",
    "area": "geometry", "perimeter": "geometry", "volume": "geometry",
    "rectangle": "geometry", "side": "geometry", "length": "geometry",
    "width": "geometry", "height": "geometry",
    "measure": "measurement", "measurement": "measurement", "convert": "measurement",
}

REPRESENTATION_WORDS = {
    "equation", "equations", "expression", "expressions", "number", "numbers",
    "numeral", "digit", "digits", "value", "values", "answer", "count", "counted",
    "counting", "strategy", "strategies", "represent", "representation",
    "diagram", "ten-frame", "place", "tens", "ones", "hundreds", "thousands",
}

NUMERAL = re.compile(r"(?<![A-Za-z0-9])\d+(?:[.,]\d+)?(?![A-Za-z0-9])")
NUMBER_WORDS = {
    "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6,
    "seven": 7, "eight": 8, "nine": 9, "ten": 10, "eleven": 11, "twelve": 12,
    "twenty": 20, "thirty": 30, "forty": 40, "fifty": 50, "hundred": 100,
}


@dataclass
class Sentence:
    record_index: int
    sentence_index: int
    lesson: str
    grade: str
    text: str
    char_start: int
    char_end: int
    record_type: str
    label_origin: str
    review_status: str
    activity_location: str
    source_guide: str
    span_start: int
    span_end: int
    numerals: list[float] = field(default_factory=list)
    number_words: list[str] = field(default_factory=list)
    operation_hints: list[str] = field(default_factory=list)
    representation_hints: list[str] = field(default_factory=list)
    peer_work: bool = False
    peer_work_signals: list[str] = field(default_factory=list)
    is_question: bool = True

    @property
    def identity(self) -> str:
        return f"{self.lesson}#{self.record_index}.{self.sentence_index}"

    def to_dict(self) -> dict:
        data = dict(self.__dict__)
        data["identity"] = self.identity
        return data


def grade_of(lesson: str) -> str:
    match = re.match(r"IM-G(\w+)-", lesson)
    return match.group(1) if match else "?"


def split_sentences(text: str) -> list[tuple[int, int, str]]:
    """Sentences with their character spans inside the record text."""
    spans: list[tuple[int, int, str]] = []
    start = 0
    for match in SENTENCE_END.finditer(text):
        end = match.start()
        piece = text[start:end].strip()
        if piece:
            offset = text.index(piece, start)
            spans.append((offset, offset + len(piece), piece))
        start = match.end()
    tail = text[start:].strip()
    if tail:
        offset = text.index(tail, start)
        spans.append((offset, offset + len(tail), tail))
    return spans


def numerals_in(text: str) -> list[float]:
    """Numeral TOKENS only. A number word carries quantity but binds no slot."""
    return [float(match.group(0).replace(",", "")) for match in NUMERAL.finditer(text)]


def number_words_in(text: str) -> list[str]:
    return sorted({word for word in NUMBER_WORDS if re.search(rf"\b{word}\b", text, re.I)})


def load_records() -> list[dict]:
    return [json.loads(line) for line in RECORDS.read_text(encoding="utf-8").splitlines() if line.strip()]


def prefilter(record: dict) -> tuple[bool, str]:
    location = record["activity_location"].strip()
    for prefix, reason in PREFILTER_LOCATIONS.items():
        if location == prefix or location.endswith(prefix):
            return False, reason
    return True, "kept"


def build_sentences(records: list[dict]) -> tuple[list[Sentence], dict[str, int]]:
    excluded: dict[str, int] = {}
    sentences: list[Sentence] = []
    for record in records:
        keep, reason = prefilter(record)
        if not keep:
            excluded[reason] = excluded.get(reason, 0) + 1
            continue
        for index, (start, end, piece) in enumerate(split_sentences(record["text"])):
            operations = sorted({
                OPERATION_WORDS[word]
                for word in re.findall(r"[A-Za-z][A-Za-z'-]*", piece.casefold())
                if word in OPERATION_WORDS
            })
            representations = sorted({
                word for word in re.findall(r"[A-Za-z][A-Za-z'-]*", piece.casefold())
                if word in REPRESENTATION_WORDS
            })
            signals = sorted(
                name for name, pattern in PEER_WORK_SIGNALS.items() if pattern.search(piece)
            )
            sentences.append(Sentence(
                record_index=record["record_index"],
                sentence_index=index,
                lesson=record["lesson"],
                grade=grade_of(record["lesson"]),
                text=piece,
                char_start=start,
                char_end=end,
                record_type=record["type"],
                label_origin=record["label_origin"],
                review_status=record["review_status"],
                activity_location=record["activity_location"],
                source_guide=record["source_guide"],
                span_start=record["span_start"],
                span_end=record["span_end"],
                numerals=numerals_in(piece),
                number_words=number_words_in(piece),
                operation_hints=operations,
                representation_hints=representations,
                peer_work=bool(signals),
                peer_work_signals=signals,
                is_question=piece.rstrip().endswith("?"),
            ))
    return sentences, excluded


def mineable(sentence: Sentence) -> bool:
    """Could this sentence name a region of input space at all?"""
    return bool(
        sentence.numerals or sentence.number_words
        or sentence.operation_hints or sentence.representation_hints
    )
