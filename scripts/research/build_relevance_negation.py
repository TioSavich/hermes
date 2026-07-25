#!/usr/bin/env python3
"""Build evidence-backed exclusions over the corpus-window slices."""
from __future__ import annotations

import argparse
import json
import re
import subprocess
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "knowledge/index/relevance_negation.pl"
LESSON_MONITORING = ROOT / "curriculum/im/lesson_monitoring.pl"
FIELD_CACHE = ROOT / "curriculum/im/generated/field_context_cache.json"
WINDOW = ROOT / "knowledge/index/corpus_window.pl"
STANDARDS = ROOT / "knowledge/standards"
ACTION_GRAMMAR = ROOT / "knowledge/strategies/action_grammar.pl"
TRANSITION_TABLES = ROOT / "knowledge/strategies/transition_tables"

OPERATION_TOPIC_RE = re.compile(r"(?m)^operation_topic\((\w+), (\w+)\)\.")
# The keyword table is `topic_keyword(Keyword, Topic)` facts.  It was a wall of
# text_topic/2 clauses whose bodies disjoined sub_atom/5 calls until task 127
# flattened it; a reader that still parsed clause bodies would find no keywords
# and emit a negation layer with nothing to key on, which is why this check
# fails loudly on an empty table rather than writing an empty artifact.
TOPIC_KEYWORD_RE = re.compile(
    r"(?m)^topic_keyword\((\"[^\"]*\"|'[^']*'|\w+), (\w+)\)\."
)
WINDOW_ROW_RE = re.compile(r"(?m)^window_row\((\w+), (\w+),")
MACHINE_GRAMMAR_RE = re.compile(
    r"(?m)^machine_grammar\((\w+), (\w+), (\w+), arc\("
)
ATOM_RE = re.compile(r"^[a-z][a-zA-Z0-9_]*$")
STANDARD_CODE_RE = re.compile(r"^(K|\d+)\.")


@dataclass(frozen=True)
class StandardSlice:
    framework: str
    code: str
    grade: int

    @property
    def term(self) -> str:
        return f"standard({_pl_atom(self.framework)}, {_pl_atom(self.code)})"


@dataclass(frozen=True)
class BuildData:
    known_topics: tuple[str, ...]
    lessons: tuple[tuple[str, int, tuple[str, ...]], ...]
    cache_only_lessons: tuple[str, ...]
    machines: tuple[tuple[str, str], ...]
    machine_genres: tuple[tuple[str, str, str], ...]
    family_topics: tuple[tuple[str, tuple[str, ...]], ...]
    family_topic_sources: tuple[tuple[str, str, str], ...]
    standards: tuple[StandardSlice, ...]
    query_keywords: tuple[tuple[str, str], ...]
    exclusions: tuple[tuple[str, str, str, str], ...]
    floor_sources: tuple[tuple[str, int, str], ...]


def _pl_atom(value: str) -> str:
    if ATOM_RE.fullmatch(value):
        return value
    return "'" + value.replace("\\", "\\\\").replace("'", "\\'") + "'"


def _unquote(value: str) -> str:
    raw = value.strip()
    if len(raw) >= 2 and raw[0] == raw[-1] and raw[0] in {"'", '"'}:
        return raw[1:-1].replace("\\'", "'").replace('\\"', '"').replace("\\\\", "\\")
    return raw


def _split_top_level(text: str) -> list[str]:
    result: list[str] = []
    start = 0
    stack: list[str] = []
    quote: str | None = None
    escaped = False
    pairs = {"(": ")", "[": "]", "{": "}"}
    for index, char in enumerate(text):
        if quote:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
        elif char in {"'", '"'}:
            quote = char
        elif char in pairs:
            stack.append(pairs[char])
        elif stack and char == stack[-1]:
            stack.pop()
        elif not stack and char == ",":
            result.append(text[start:index].strip())
            start = index + 1
    result.append(text[start:].strip())
    return result


def _iter_facts(text: str, functor: str):
    pattern = re.compile(rf"(?m)^{re.escape(functor)}\s*\(")
    for match in pattern.finditer(text):
        depth = 1
        quote: str | None = None
        escaped = False
        index = match.end()
        while index < len(text) and depth:
            char = text[index]
            if quote:
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == quote:
                    quote = None
            elif char in {"'", '"'}:
                quote = char
            elif char == "(":
                depth += 1
            elif char == ")":
                depth -= 1
            index += 1
        if depth:
            raise ValueError(f"unterminated {functor} term")
        yield text[match.end() : index - 1]


def _read_topics() -> tuple[
    dict[str, set[str]],
    tuple[tuple[str, str], ...],
    set[str],
]:
    text = LESSON_MONITORING.read_text(encoding="utf-8")
    operation_topics: dict[str, set[str]] = defaultdict(set)
    for operation, topic in OPERATION_TOPIC_RE.findall(text):
        operation_topics[operation].add(topic)

    query_keywords: set[tuple[str, str]] = set()
    text_topics: set[str] = set()
    for raw_keyword, topic in TOPIC_KEYWORD_RE.findall(text):
        text_topics.add(topic)
        query_keywords.add((topic, _unquote(raw_keyword)))
    if not query_keywords:
        raise RuntimeError(
            "no topic_keyword/2 facts found in "
            f"{LESSON_MONITORING.relative_to(ROOT)}; the negation layer would "
            "have nothing to key a query on"
        )
    known_topics = set().union(*operation_topics.values()) | text_topics
    return operation_topics, tuple(sorted(query_keywords)), known_topics


def _read_live_lessons() -> tuple[tuple[str, int, tuple[str, ...]], ...]:
    goal = (
        "use_module(im_lessons(lesson_monitoring),[]),"
        "findall(C-G,lesson_monitoring:encoded_im_lesson(C,_,_,grade(G),_,_),Pairs0),"
        "sort(Pairs0,Pairs),"
        "forall(member(C-G,Pairs),"
        "(lesson_monitoring:lesson_topics(C,T),"
        "format('~w\\t~d\\t~q~n',[C,G,T]))),halt."
    )
    result = subprocess.run(
        [
            "swipl",
            "-q",
            "--on-warning=status",
            "--on-error=status",
            "-l",
            "paths.pl",
            "-g",
            goal,
        ],
        cwd=ROOT,
        capture_output=True,
        text=True,
        timeout=180,
        check=False,
    )
    if result.returncode:
        raise RuntimeError(
            f"lesson predicate query failed with exit {result.returncode}: "
            f"{result.stdout.strip()} {result.stderr.strip()}"
        )
    lessons: list[tuple[str, int, tuple[str, ...]]] = []
    for line in result.stdout.splitlines():
        code, grade_raw, topics_raw = line.split("\t", 2)
        if not topics_raw.startswith("[") or not topics_raw.endswith("]"):
            raise ValueError(f"unexpected lesson topic list for {code}: {topics_raw}")
        topics = tuple(
            part.strip()
            for part in topics_raw[1:-1].split(",")
            if part.strip()
        )
        lessons.append((code, int(grade_raw), topics))
    return tuple(sorted(lessons))


def _read_standards() -> tuple[
    tuple[StandardSlice, ...],
    tuple[str, int, str],
]:
    by_key: dict[tuple[str, str], int] = {}
    thirds_sources: list[tuple[int, str]] = []
    for path in sorted(STANDARDS.rglob("*.pl")):
        text = path.read_text(encoding="utf-8")
        for raw_fact in _iter_facts(text, "standard_anchor"):
            args = _split_top_level(raw_fact)
            if len(args) != 4:
                continue
            concept_raw, framework_raw, code_raw, statement_raw = args
            concept = _unquote(concept_raw)
            framework = _unquote(framework_raw)
            code = _unquote(code_raw)
            statement = _unquote(statement_raw)
            if not ATOM_RE.fullmatch(concept) or not ATOM_RE.fullmatch(framework):
                continue
            if framework == "im_lesson":
                continue
            grade_match = STANDARD_CODE_RE.match(code)
            if not grade_match:
                continue
            grade = 0 if grade_match.group(1) == "K" else int(grade_match.group(1))
            key = (framework, code)
            if key in by_key and by_key[key] != grade:
                raise ValueError(f"standard {framework}/{code} has two grades")
            by_key[key] = grade
            if "thirds" in concept or re.search(r"\bthirds\b", statement.lower()):
                source = (
                    f"standard_anchor_evidence({_pl_atom(concept)}, {_pl_atom(framework)}, "
                    f"{_pl_atom(code)})"
                )
                thirds_sources.append((grade, source))

    if not thirds_sources:
        raise ValueError("no standard anchor grounds a thirds grade floor")
    floor, source = sorted(thirds_sources)[0]
    standards = tuple(
        StandardSlice(framework, code, grade)
        for (framework, code), grade in sorted(by_key.items())
    )
    return standards, ("fraction/thirds", floor, source)


def _read_machine_genres(
    machines: tuple[tuple[str, str], ...],
) -> tuple[tuple[str, str, str], ...]:
    genres: dict[tuple[str, str], str] = {}
    text = ACTION_GRAMMAR.read_text(encoding="utf-8")
    for genre, family, signature in MACHINE_GRAMMAR_RE.findall(text):
        key = (family, signature)
        if key in genres and genres[key] != genre:
            raise ValueError(f"machine {family}/{signature} has two genres")
        genres[key] = genre
    missing = sorted(set(machines) - set(genres))
    if missing:
        raise ValueError(f"machines have no machine_grammar/6 genre: {missing}")
    return tuple(
        (family, signature, genres[(family, signature)])
        for family, signature in machines
    )


def _read_family_topic_sources(
    known_topics: set[str],
    machines: tuple[tuple[str, str], ...],
) -> tuple[tuple[str, str, str], ...]:
    """Read narrow family-topic links whose evidence is explicit in a table."""
    if "data" not in known_topics:
        return ()

    statistics = (TRANSITION_TABLES / "statistics.pl").read_text(encoding="utf-8")
    candidates: list[str] = []
    for raw_fact in _iter_facts(statistics, "automaton_tuple"):
        args = _split_top_level(raw_fact)
        if len(args) != 6:
            continue
        family = _unquote(args[0])
        signature = _unquote(args[1])
        if (
            family == "statistics"
            and (family, signature) in machines
            and re.search(r"\bpreserve_data_set\b", args[3])
        ):
            candidates.append(signature)
    if not candidates:
        raise ValueError(
            "statistics has no automaton_tuple action that grounds the data topic"
        )
    signature = sorted(candidates)[0]
    source = (
        "automaton_action_evidence("
        f"statistics, {signature}, preserve_data_set)"
    )
    return (("statistics", "data", source),)


def _lesson_floor_sources(
    topics: set[str],
    lessons: tuple[tuple[str, int, tuple[str, ...]], ...],
) -> tuple[tuple[str, int, str], ...]:
    sources: list[tuple[str, int, str]] = []
    for topic in sorted(topics):
        witnesses = sorted(
            (grade, code)
            for code, grade, lesson_topics in lessons
            if topic in lesson_topics
        )
        if not witnesses:
            continue
        floor, code = witnesses[0]
        source = (
            f"lesson_topic_grade_evidence({_pl_atom(code)}, {topic}, {floor})"
        )
        sources.append((topic, floor, source))
    return tuple(sources)


def build_data() -> BuildData:
    operation_topics, query_keywords, known_topics = _read_topics()
    lessons = _read_live_lessons()
    live_codes = {code for code, _grade, _topics in lessons}
    cache = json.loads(FIELD_CACHE.read_text(encoding="utf-8"))
    cache_codes = set(cache["field_contexts"])
    cache_only = tuple(sorted(cache_codes - live_codes))

    machines = tuple(
        sorted(
            {
                (family, signature)
                for family, signature in WINDOW_ROW_RE.findall(
                    WINDOW.read_text(encoding="ascii")
                )
                if ATOM_RE.fullmatch(family) and ATOM_RE.fullmatch(signature)
            }
        )
    )
    machine_genres = _read_machine_genres(machines)
    genre_by_machine = {
        (family, signature): genre
        for family, signature, genre in machine_genres
    }
    family_topic_sources = _read_family_topic_sources(known_topics, machines)
    families = sorted({family for family, _signature in machines})
    family_topic_rows: list[tuple[str, tuple[str, ...]]] = []
    for family in families:
        topics = set(operation_topics.get(family, set()))
        if family in known_topics:
            topics.add(family)
        topics.update(
            topic
            for source_family, topic, _source in family_topic_sources
            if source_family == family
        )
        family_topic_rows.append((family, tuple(sorted(topics))))

    standards, special_floor_source = _read_standards()
    special_query, special_floor, special_source = special_floor_source
    subtraction_topics = set(known_topics)
    floor_sources = (
        _lesson_floor_sources(subtraction_topics, lessons)
        + (special_floor_source,)
    )
    family_topics = dict(family_topic_rows)
    exclusions: set[tuple[str, str, str, str]] = set()

    for topic in sorted(subtraction_topics):
        for family, signature in machines:
            topics = family_topics[family]
            if topics and topic not in topics:
                key = f"machine({family}, {signature})"
                reason = (
                    f"family_mismatch({topic}, {family}, "
                    f"[{', '.join(topics)}])"
                )
                exclusions.add((topic, "family", key, reason))
            elif not topics and genre_by_machine[(family, signature)] == "discursive":
                key = f"machine({family}, {signature})"
                reason = f"nonmathematical_genre({topic}, {family}, discursive)"
                exclusions.add((topic, "family", key, reason))
        for code, _grade, topics in lessons:
            if topics and topic not in topics:
                reason = f"lesson_topic_mismatch({topic}, [{', '.join(topics)}])"
                exclusions.add((topic, "lesson", _pl_atom(code), reason))

    for grade in sorted({grade for _code, grade, _topics in lessons}):
        if grade < special_floor:
            reason = f"grade_band_below({special_floor}, {special_source})"
            exclusions.add((special_query, "grade_band", str(grade), reason))
    for code, grade, _topics in lessons:
        if grade < special_floor:
            reason = (
                f"lesson_grade_below({special_floor}, {grade}, {special_source})"
            )
            exclusions.add((special_query, "lesson", _pl_atom(code), reason))
    for topic, floor, source in floor_sources:
        for standard in standards:
            if standard.grade < floor:
                reason = f"standard_grade_below({floor}, {standard.grade}, {source})"
                exclusions.add((topic, "standard", standard.term, reason))

    return BuildData(
        known_topics=tuple(sorted(known_topics | {special_query})),
        lessons=lessons,
        cache_only_lessons=cache_only,
        machines=machines,
        machine_genres=machine_genres,
        family_topics=tuple(family_topic_rows),
        family_topic_sources=family_topic_sources,
        standards=standards,
        query_keywords=query_keywords,
        exclusions=tuple(sorted(exclusions)),
        floor_sources=floor_sources,
    )


def _atom_list(items: tuple[str, ...]) -> str:
    return "[" + ", ".join(_pl_atom(item) for item in items) + "]"


def render(data: BuildData) -> str:
    grades = sorted({grade for _code, grade, _topics in data.lessons})
    lines = [
        "% Generated by build_relevance_negation.py. Hand edits will not survive the check.",
        "% Exclusions are data. Each reason resolves against evidence facts below.",
        "",
    ]
    for topic in data.known_topics:
        lines.append(f"known_topic({_pl_atom(topic)}).")
    lines.append("")
    for topic, keyword in data.query_keywords:
        lines.append(f"query_keyword({topic}, {_pl_atom(keyword)}).")
    lines.append("")
    for grade in grades:
        lines.append(f"slice(grade_band, {grade}).")
    for code, _grade, _topics in data.lessons:
        lines.append(f"slice(lesson, {_pl_atom(code)}).")
    for family, signature in data.machines:
        lines.append(f"slice(family, machine({family}, {signature})).")
    for standard in data.standards:
        lines.append(f"slice(standard, {standard.term}).")
    lines.append("")
    for code, grade, _topics_for_lesson in data.lessons:
        lines.append(f"lesson_grade({_pl_atom(code)}, {grade}).")
    lines.append("")
    for code, _grade, topics_for_lesson in data.lessons:
        lines.append(
            f"lesson_topics({_pl_atom(code)}, {_atom_list(topics_for_lesson)})."
        )
    lines.append("")
    for family, topics_for_family in data.family_topics:
        lines.append(f"family_topics({family}, {_atom_list(topics_for_family)}).")
    lines.append("")
    for family, signature, genre in data.machine_genres:
        lines.append(f"machine_genre({family}, {signature}, {genre}).")
    lines.append("")
    for family, topic, source in data.family_topic_sources:
        lines.append(f"{source}.")
        lines.append(f"family_topic_source({family}, {topic}, {source}).")
    lines.append("")
    for standard in data.standards:
        lines.append(f"standard_grade({standard.term}, {standard.grade}).")
    lines.append("")
    for _topic, _floor, source in data.floor_sources:
        lines.append(f"{source}.")
    for topic, floor, source in data.floor_sources:
        lines.append(f"topic_grade_floor({_pl_atom(topic)}, {floor}, {source}).")
    for code in data.cache_only_lessons:
        lines.append(f"source_gap(cache_only_lesson, {_pl_atom(code)}).")
    lines.append("")
    for topic, kind, key, reason in data.exclusions:
        lines.append(f"excludes({_pl_atom(topic)}, {kind}, {key}, {reason}).")
    lines.extend(
        [
            "",
            "normalized_query(Query, Query) :-",
            "    known_topic(Query),",
            "    Query \\== 'fraction/thirds',",
            "    !.",
            "normalized_query(Query, Topic) :-",
            "    atom(Query),",
            "    downcase_atom(Query, Lower),",
            "    query_keyword(Topic, Keyword),",
            "    sub_atom(Lower, _, _, _, Keyword),",
            "    !.",
            "",
            "applicable_exclusion_topic(Query, Query) :-",
            "    known_topic(Query).",
            "applicable_exclusion_topic(Query, Topic) :-",
            "    normalized_query(Query, Topic),",
            "    Topic \\== Query.",
            "",
            "applicable_exclusion(Query, Kind, Key, Reason) :-",
            "    excludes(Query, Kind, Key, Reason).",
            "applicable_exclusion(Query, Kind, Key, Reason) :-",
            "    normalized_query(Query, Topic),",
            "    Topic \\== Query,",
            "    excludes(Topic, Kind, Key, Reason),",
            "    \\+ ( Kind == standard,",
            "         Reason = standard_grade_below(_, _, _) ).",
            "",
            "surviving_slices(Topic, Survivors, Excluded) :-",
            "    findall(excluded(Kind, Key, Reason),",
            "            applicable_exclusion(Topic, Kind, Key, Reason),",
            "            Excluded0),",
            "    sort(Excluded0, Excluded),",
            "    findall(slice(Kind, Key),",
            "            ( slice(Kind, Key),",
            "              \\+ memberchk(excluded(Kind, Key, _), Excluded) ),",
            "            Survivors0),",
            "    sort(Survivors0, Survivors).",
            "",
            "exclusion_reason_resolves(Topic, family, machine(Family, Signature),",
            "                          family_mismatch(Topic, Family, Topics)) :-",
            "    slice(family, machine(Family, Signature)),",
            "    family_topics(Family, Topics),",
            "    \\+ memberchk(Topic, Topics).",
            "exclusion_reason_resolves(Topic, family, machine(Family, Signature),",
            "                          nonmathematical_genre(Topic, Family, Genre)) :-",
            "    known_topic(Topic),",
            "    machine_genre(Family, Signature, Genre),",
            "    Genre == discursive.",
            "exclusion_reason_resolves(Topic, lesson, Code,",
            "                          lesson_topic_mismatch(Topic, Topics)) :-",
            "    lesson_topics(Code, Topics),",
            "    \\+ memberchk(Topic, Topics).",
            "exclusion_reason_resolves(Topic, grade_band, Grade,",
            "                          grade_band_below(Floor, Source)) :-",
            "    topic_grade_floor(Topic, Floor, Source),",
            "    call(Source),",
            "    integer(Grade),",
            "    Grade < Floor.",
            "exclusion_reason_resolves(Topic, lesson, Code,",
            "                          lesson_grade_below(Floor, Grade, Source)) :-",
            "    topic_grade_floor(Topic, Floor, Source),",
            "    call(Source),",
            "    lesson_grade(Code, Grade),",
            "    Grade < Floor.",
            "exclusion_reason_resolves(Topic, standard, Standard,",
            "                          standard_grade_below(Floor, Grade, Source)) :-",
            "    topic_grade_floor(Topic, Floor, Source),",
            "    call(Source),",
            "    standard_grade(Standard, Grade),",
            "    Grade < Floor.",
            "",
        ]
    )
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=OUTPUT)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    data = build_data()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(render(data), encoding="utf-8", newline="\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
