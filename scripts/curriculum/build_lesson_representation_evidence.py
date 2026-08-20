#!/usr/bin/env python3
"""Build lesson-owned host and fraction evidence for deformation charts."""
from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
INVENTORY = ROOT / "curriculum/im/generated/default_fill_lessons.pl"
CONTEXT = ROOT / "curriculum/im/generated/compiled_lesson_context.pl"
DEFRAGGED_TASKS = ROOT / "curriculum/im/generated/compiled_defragged_task_instances.pl"
STRUCTURE_ROWS = ROOT / "curriculum/im/generated/structure_task_rows.jsonl"
VISION = ROOT / "curriculum/im/generated/vision_lesson_digest.pl"
VISION_FRACTION_RECOVERY = ROOT / "curriculum/im/generated/vision_fraction_recovery.pl"
DEFAULT_OUTPUT = ROOT / "curriculum/im/generated/lesson_representation_evidence.pl"

SHADOWED_HAND_AUTHORED = {"IM-G3-U5-L1", "IM-G3-U5-L2"}
CIRCLE_GUARD_FIXTURES = {"IM-G3-U5-L16", "IM-G4-U2-L12", "IM-G4-U2-L13"}
# IM-G5-U3-L19 ("Fraction Games") keeps zero representation evidence by
# design: its Student Task Statement boxes are blank digit-fill templates,
# so the lesson has no host representation of its own either (see the
# unconditional guard in main()). The other five lessons in this set lost
# every printed fraction glyph to the PDF-to-Markdown conversion pass; a
# 2026-08-20 vision recovery (scripts/curriculum/recover_vision_fractions.py)
# read the glyphs back off the source PDF pages, verified each against a
# surviving Markdown line, and populates their fractions below via
# add_vision_recovery_fractions -- so this set now names only the one
# lesson that is genuinely without a representation host.
FRACTIONLESS_FIXTURES = {
    "IM-G5-U3-L19",
}

DENOMINATOR_WORDS = {
    "halves": 2,
    "thirds": 3,
    "fourths": 4,
    "quarters": 4,
    "fifths": 5,
    "sixths": 6,
    "eighths": 8,
    "tenths": 10,
    "twelfths": 12,
    "hundredths": 100,
}
WORD_RE = re.compile(r"\b(" + "|".join(map(re.escape, DENOMINATOR_WORDS)) + r")\b", re.I)
SINGULAR_WORDS = {
    "half": 2, "third": 3, "fourth": 4, "quarter": 4, "fifth": 5,
    "sixth": 6, "eighth": 8, "tenth": 10, "twelfth": 12, "hundredth": 100,
}
SINGULAR_RE = re.compile(
    r"\b(?:a|an|one|1)\s*[- ]\s*(" + "|".join(SINGULAR_WORDS) + r")\b"
    r"|\b(" + "|".join(SINGULAR_WORDS) + r")\s+"
    r"(?:of|cup|foot|inch|pound|into|is|the)\b",
    re.I,
)
NUMERAL_RE = re.compile(r"(?<![\w.])(\d+)\s*/\s*(\d+)(?![\w.])")
CODE_RE = re.compile(r"IM-G(\d+)-U(\d+)-L(\d+)$")


@dataclass(frozen=True)
class Citation:
    path: str
    locator_kind: str
    locator: int | str
    excerpt: str


@dataclass(frozen=True)
class FractionEvidence:
    numerator: int
    denominator: int
    citation: Citation
    form: str


def inventory_codes() -> list[str]:
    text = INVENTORY.read_text(encoding="utf-8")
    codes = re.findall(r"^default_fill_lesson\('([^']+)'\)\.$", text, re.MULTILINE)
    return sorted(set(codes) - SHADOWED_HAND_AUTHORED)


def relative(path: Path) -> str:
    return path.resolve().relative_to(ROOT).as_posix()


def guide_path(code: str) -> Path:
    match = CODE_RE.fullmatch(code)
    if match is None:
        raise RuntimeError(f"malformed lesson code: {code}")
    grade, unit, lesson = map(int, match.groups())
    if grade <= 5:
        path = ROOT / f"curriculum/im_teacher_guides/grade{grade}/unit{unit}/lesson{lesson}.md"
        grade_source = (ROOT / f"curriculum/im/grade_{grade}.pl").read_text(encoding="utf-8")
        expected = f"im_teacher_guides/grade{grade}/unit{unit}/lesson{lesson}.md"
        if code not in grade_source or expected not in grade_source:
            raise RuntimeError(f"explicit_lesson_text_source is missing {code} -> {expected}")
        return path

    # Grade 6 uses the full docling guide recorded on compiled_lesson_context/4.
    source = CONTEXT.read_text(encoding="utf-8")
    start = source.find(f"compiled_lesson_context('{code}',")
    if start < 0:
        raise RuntimeError(f"compiled_lesson_context has no row for {code}")
    end = source.find("\ncompiled_lesson_context(", start + 1)
    block = source[start : len(source) if end < 0 else end]
    paths = re.findall(r"\bsource\('([^']+)'\)\)\.", block)
    if len(paths) != 1:
        raise RuntimeError(f"compiled_lesson_context has {len(paths)} source paths for {code}")
    return ROOT / paths[0]


def excerpt_at(lines: list[str], line_number: int, token: str) -> tuple[int, str] | None:
    for offset in (0, -1, 1, -2, 2):
        index = line_number - 1 + offset
        if 0 <= index < len(lines) and token.lower() in lines[index].lower():
            return index + 1, lines[index].strip()
    return None


def circle_is_noun(line: str) -> bool:
    low = line.lower()
    if re.match(r"^\s*(?:[-*•]\s*)?circle\b", low):
        return False
    if re.search(r"\b(?:a|an|the|paper|one|\d+)\s+circles?\b", low):
        return True
    return bool(re.search(
        r"\b(?:fold|cut|partition|split|shade)\w*\b[^.!?]{0,80}\bcircles?\b",
        low,
    ))


def fraction_cues(text: str) -> bool:
    return bool(WORD_RE.search(text) or SINGULAR_RE.search(text) or NUMERAL_RE.search(text))


def host_matches(lines: list[str], index: int) -> list[tuple[str, str]]:
    line = lines[index]
    low = line.lower()
    neighborhood = " ".join(lines[max(0, index - 2) : index + 3]).lower()
    matches: list[tuple[str, str]] = []

    def add(host: str, token: str) -> None:
        if not any(existing == host for existing, _ in matches):
            matches.append((host, token))

    for pattern, host in (
        (r"\bnumber lines?\b", "number_line"),
        (r"\bline plots?\b", "number_line"),
        (r"\bfraction[- ]strips?\b", "bar"),
        (r"\btape diagrams?\b", "bar"),
        (r"\bpaper strips?\b", "bar"),
        (r"\bbars?\b", "bar"),
        (r"\brectangles?\b", "rectangle"),
        (r"\bunit squares?\b", "rectangle"),
        (r"\bwhole squares?\b", "rectangle"),
        (r"\bpans?\b", "rectangle"),
        (r"\bpies?\b", "circle"),
        (r"\bplates?\b", "set"),
    ):
        found = re.search(pattern, low)
        if found:
            add(host, found.group(0))

    circle = re.search(r"\bcircles?\b", low)
    if circle and circle_is_noun(line):
        add("circle", circle.group(0))

    equal_groups = re.search(r"\bequal groups?\b", low)
    if equal_groups:
        add("set", equal_groups.group(0))
    groups_of = re.search(r"\bgroups of\b", low)
    logistical_group = bool(
        re.match(r"^\s*(?:[-*•]\s*)?groups of \d+", low)
        or (groups_of and "•" in low[max(0, groups_of.start() - 8) : groups_of.start()])
        or re.search(r"groups of \d+\s+(?:students?|people)", low)
    )
    if groups_of and not logistical_group and (
        fraction_cues(neighborhood) or re.search(r"\bgroups of \d+\b", low)
    ):
        add("set", groups_of.group(0))
    set_of = re.search(r"\bset of\b", low)
    if set_of and not re.search(r"\b(?:cards?|questions?|number lines?)\b", low[set_of.end() :]):
        add("set", set_of.group(0))
    return matches


def scan_guide(code: str, path: Path) -> tuple[dict[str, Citation], dict[tuple[int, int], FractionEvidence]]:
    if not path.is_file():
        raise RuntimeError(f"guide source does not exist for {code}: {path}")
    lines = path.read_text(encoding="utf-8").splitlines()
    path_text = relative(path)
    hosts: dict[str, Citation] = {}
    fractions: dict[tuple[int, int], FractionEvidence] = {}
    for index, line in enumerate(lines):
        for host, token in host_matches(lines, index):
            hosts.setdefault(host, Citation(path_text, "line", index + 1, line.strip()))
        for match in WORD_RE.finditer(line):
            denominator = DENOMINATOR_WORDS[match.group(1).lower()]
            key = (1, denominator)
            fractions.setdefault(key, FractionEvidence(
                1, denominator, Citation(path_text, "line", index + 1, line.strip()),
                "denominator_word",
            ))
        for match in SINGULAR_RE.finditer(line):
            word = (match.group(1) or match.group(2)).lower()
            denominator = SINGULAR_WORDS[word]
            key = (1, denominator)
            fractions.setdefault(key, FractionEvidence(
                1, denominator, Citation(path_text, "line", index + 1, line.strip()),
                "denominator_word",
            ))
        for match in NUMERAL_RE.finditer(line):
            numerator, denominator = map(int, match.groups())
            if denominator <= 0:
                continue
            key = (numerator, denominator)
            fractions.setdefault(key, FractionEvidence(
                numerator, denominator, Citation(path_text, "line", index + 1, line.strip()),
                "numeral",
            ))
    return hosts, fractions


def add_structure_rows(codes: set[str], fractions: dict[str, dict[tuple[int, int], FractionEvidence]]) -> None:
    for raw in STRUCTURE_ROWS.read_text(encoding="utf-8").splitlines():
        row = json.loads(raw)
        code = str(row.get("lesson", ""))
        if code not in codes:
            continue
        path = ROOT / str(row.get("path", ""))
        lines = path.read_text(encoding="utf-8").splitlines()
        for expression in row.get("printed_expressions", []):
            text = str(expression.get("text", ""))
            for match in NUMERAL_RE.finditer(text):
                numerator, denominator = map(int, match.groups())
                located = excerpt_at(lines, int(expression["line"]), match.group(0))
                if denominator <= 0 or located is None:
                    continue
                line_number, excerpt = located
                key = (numerator, denominator)
                fractions[code].setdefault(key, FractionEvidence(
                    numerator, denominator,
                    Citation(relative(path), "line", line_number, excerpt), "numeral",
                ))


def add_defragged_tasks(codes: set[str], fractions: dict[str, dict[tuple[int, int], FractionEvidence]]) -> None:
    """Use complete statements and their source segments as the DFG fallback."""
    fallback_codes = {
        code for code in codes if not fractions[code] and code not in FRACTIONLESS_FIXTURES
    }
    if not fallback_codes:
        return

    source = DEFRAGGED_TASKS.read_text(encoding="utf-8")
    starts = [match.start() for match in re.finditer(r"^defragged_task_instance\(", source, re.MULTILINE)]
    starts.append(len(source))
    for start, end in zip(starts, starts[1:]):
        block = source[start:end]
        code_match = re.search(r"^defragged_task_instance\([^,]+,\s*\n\s*'([^']+)'", block)
        statement_match = re.search(r"\bcomplete_statement:(\"(?:\\.|[^\"\\])*\")", block)
        if code_match is None or statement_match is None:
            continue
        code = code_match.group(1)
        if code not in fallback_codes:
            continue
        statement = json.loads(statement_match.group(1))
        segments = [
            (path, int(line))
            for path, line in re.findall(
                r'\bpath:"([^"]+)", line_start:(\d+)', block
            )
        ]
        for match in NUMERAL_RE.finditer(statement):
            numerator, denominator = map(int, match.groups())
            if denominator <= 0:
                continue
            located_source = None
            for path_text, line_number in segments:
                path = ROOT / path_text
                if not path.is_file():
                    continue
                located = excerpt_at(
                    path.read_text(encoding="utf-8").splitlines(),
                    line_number,
                    match.group(0),
                )
                if located is not None:
                    actual_line, _ = located
                    located_source = Citation(
                        relative(path), "line", actual_line, match.group(0)
                    )
                    break
            if located_source is None:
                continue
            key = (numerator, denominator)
            fractions[code].setdefault(key, FractionEvidence(
                numerator, denominator, located_source, "numeral",
            ))


def add_vision_computations(codes: set[str], guides: dict[str, Path],
                            fractions: dict[str, dict[tuple[int, int], FractionEvidence]]) -> None:
    pattern = re.compile(
        r"^vision_lesson_computation\('([^']+)', \"([^\"]+)\", \"([^\"]+)\", "
        r"[^,]+, \"([^\"]+)\", (?:text|figure)\)\.$"
    )
    for line in VISION.read_text(encoding="utf-8").splitlines():
        match = pattern.match(line)
        if match is None:
            continue
        code, expression, answer, page_range = match.groups()
        if code not in codes:
            continue
        excerpt = f"{expression} = {answer}"
        for fraction in NUMERAL_RE.finditer(f"{expression} {answer}"):
            numerator, denominator = map(int, fraction.groups())
            if denominator <= 0:
                continue
            key = (numerator, denominator)
            fractions[code].setdefault(key, FractionEvidence(
                numerator, denominator,
                Citation(relative(guides[code]), "page", page_range, excerpt), "computation",
            ))


VISION_RECOVERY_ROW_RE = re.compile(
    r"^recovered_fraction\('([^']+)', frac\((\d+),(\d+)\), "
    r"anchor\(source\('([^']+)', line\((\d+)\)\), page\(\d+\), "
    r'fragment\("(?:[^"\\]|\\.)*"\), '
    r'markdown_excerpt\("((?:[^"\\]|\\.)*)"\), '
    r"lesson_owned\((true|false)\)\)",
    re.MULTILINE,
)


def add_vision_recovery_fractions(
    codes: set[str], fractions: dict[str, dict[tuple[int, int], FractionEvidence]]
) -> None:
    """Consume the 2026-08-20 vision recovery's lesson-owned rows.

    Six lessons' teacher-guide Markdown lost every printed fraction glyph in
    the PDF-to-text conversion pass (Tio, 2026-08-20: "if it is easy to get
    it out of markdown or pdf, do so"). scripts/curriculum/
    recover_vision_fractions.py read the glyphs back off the source PDF
    pages with a REALLMS vision call and kept only a reading whose
    surrounding words -- with the fraction's own placeholder removed --
    reproduce a line of the lesson's own Markdown. lesson_owned(false) marks
    a reading recovered from teacher-facing commentary rather than the
    lesson's own student-facing text (IM-G5-U3-L19's Student Task Statement
    is a blank digit-fill template with no fraction of its own); those rows
    are read but never joined here, so the deformation chart's existing
    no-host refusal for that lesson is unaffected by this recovery.
    """
    if not VISION_FRACTION_RECOVERY.is_file():
        raise RuntimeError(f"vision fraction recovery store is missing: {VISION_FRACTION_RECOVERY}")
    text = VISION_FRACTION_RECOVERY.read_text(encoding="utf-8")
    for match in VISION_RECOVERY_ROW_RE.finditer(text):
        code, numerator_text, denominator_text, path_text, line_text, excerpt_json, lesson_owned = (
            match.groups()
        )
        if code not in codes or lesson_owned != "true":
            continue
        numerator, denominator = int(numerator_text), int(denominator_text)
        excerpt = json.loads(f'"{excerpt_json}"')
        key = (numerator, denominator)
        fractions[code].setdefault(key, FractionEvidence(
            numerator, denominator,
            Citation(path_text, "line", int(line_text), excerpt), "vision_recovery",
        ))


def quote_atom(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "\\'") + "'"


def quote_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def citation_term(citation: Citation) -> str:
    locator = str(citation.locator) if citation.locator_kind == "line" else quote_string(str(citation.locator))
    return f"source({quote_atom(citation.path)}, {citation.locator_kind}({locator}))"


def generated_source(hosts: dict[str, dict[str, Citation]],
                     fractions: dict[str, dict[tuple[int, int], FractionEvidence]]) -> str:
    host_rows = sum(len(rows) for rows in hosts.values())
    fraction_rows = sum(len(rows) for rows in fractions.values())
    both = sum(bool(hosts[code]) and bool(fractions[code]) for code in hosts)
    hosts_only = sum(bool(hosts[code]) and not fractions[code] for code in hosts)
    fractions_only = sum(not hosts[code] and bool(fractions[code]) for code in hosts)
    neither = len(hosts) - both - hosts_only - fractions_only
    lines = [
        "/** <module> Generated lesson representation evidence",
        " *",
        " * Host rows come from guarded representation vocabulary in each lesson's cited text; circle is admitted only in noun or partition-object position.",
        " * Fraction rows come from denominator words, numeric fraction tokens, and page-cited vision computations, with guide text taking precedence.",
        " */",
        ":- module(lesson_representation_evidence,",
        "          [ lesson_host_evidence/4, lesson_fraction_evidence/5,",
        "            lesson_representation_evidence_summary/1 ]).",
        ":- discontiguous lesson_host_evidence/4.",
        ":- discontiguous lesson_fraction_evidence/5.",
        "",
        f"lesson_representation_evidence_summary(_{{lessons:{len(hosts)}, host_rows:{host_rows}, fraction_rows:{fraction_rows}, both:{both}, hosts_only:{hosts_only}, fractions_only:{fractions_only}, neither:{neither}}}).",
        "",
    ]
    for code in sorted(hosts):
        for host in sorted(hosts[code]):
            citation = hosts[code][host]
            lines.append(
                f"lesson_host_evidence({quote_atom(code)}, {host}, {citation_term(citation)}, excerpt({quote_string(citation.excerpt)}))."
            )
        for key in sorted(fractions[code], key=lambda item: (item[1], item[0])):
            row = fractions[code][key]
            lines.append(
                f"lesson_fraction_evidence({quote_atom(code)}, frac({row.numerator},{row.denominator}), "
                f"{citation_term(row.citation)}, excerpt({quote_string(row.citation.excerpt)}), form({row.form}))."
            )
        if hosts[code] or fractions[code]:
            lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()

    codes = inventory_codes()
    code_set = set(codes)
    guides = {code: guide_path(code) for code in codes}
    hosts: dict[str, dict[str, Citation]] = {}
    fractions: dict[str, dict[tuple[int, int], FractionEvidence]] = {}
    for code in codes:
        hosts[code], fractions[code] = scan_guide(code, guides[code])

    add_vision_recovery_fractions(code_set, fractions)
    add_defragged_tasks(code_set, fractions)
    add_structure_rows(code_set, fractions)
    add_vision_computations(code_set, guides, fractions)

    # The docling descriptions for the two Grade 6 guides include incidental
    # shape words from image narration. Their compiled contexts attest bars,
    # with rectangle additionally attested for L6; no circle or set host is used.
    for code in ("IM-G6-U4-L6", "IM-G6-U4-L7"):
        hosts[code].pop("circle", None)
        hosts[code].pop("set", None)
    hosts["IM-G6-U4-L7"].pop("rectangle", None)

    for code in CIRCLE_GUARD_FIXTURES:
        if "circle" in hosts[code]:
            raise RuntimeError(f"circle guard admitted imperative use for {code}")
    if hosts["IM-G5-U3-L19"] or fractions["IM-G5-U3-L19"]:
        raise RuntimeError("IM-G5-U3-L19 must remain without representation evidence")

    output = generated_source(hosts, fractions)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(output, encoding="utf-8")
    summary = {
        "output": relative(args.output),
        "lessons": len(codes),
        "host_lessons": sum(bool(rows) for rows in hosts.values()),
        "fraction_lessons": sum(bool(rows) for rows in fractions.values()),
        "both": sum(bool(hosts[code]) and bool(fractions[code]) for code in codes),
        "written_host_rows": sum(map(len, hosts.values())),
        "written_fraction_rows": sum(map(len, fractions.values())),
    }
    print(json.dumps(summary, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
