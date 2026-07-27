#!/usr/bin/env python3
"""Generate the checked IM lesson-identity relation.

The published K-8 spine supplies the finite denominator.  K-5 identity rows
are checked against the existing standard_anchor/4 facts that contain both
spellings.  Grades 6-8 retain a typed absence for the atom spelling.  Their
concept-keyed im_lesson anchors are checked separately and are not treated as
lesson-identity aliases.
"""
from __future__ import annotations

import argparse
import difflib
import json
import re
import subprocess
import sys
import tempfile
from collections import Counter, defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "knowledge" / "index" / "im_lesson_identity.pl"
SPINE = ROOT / "data" / "learningcommons" / "derived" / "im_k8_spine.json"

DASH_ID_RE = re.compile(r"^IM-G(K|[1-8])-U([1-9][0-9]*)-L([1-9][0-9]*)$")
ATOM_ID_RE = re.compile(
    r"^im_(?:kindergarten|grade([1-8]))_u([1-9][0-9]*)_l([1-9][0-9]*)$"
)


def prolog_atom(value: str) -> str:
    if re.fullmatch(r"[a-z][A-Za-z0-9_]*", value):
        return value
    return "'" + value.replace("'", "''") + "'"


def prolog_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def atom_id(grade: str, unit: int, lesson: int) -> str:
    prefix = "im_kindergarten" if grade == "K" else f"im_grade{grade}"
    return f"{prefix}_u{unit}_l{lesson}"


def dash_parts(value: str) -> tuple[str, int, int]:
    match = DASH_ID_RE.fullmatch(value)
    if match is None:
        raise ValueError(f"unconvertible published lesson id: {value}")
    return match.group(1), int(match.group(2)), int(match.group(3))


def expected_title_prefix(row: dict) -> str:
    grade_name = "Kindergarten" if row["grade"] == "K" else f"Grade{row['grade']}"
    return (
        f"IM {grade_name} Unit {row['unit']} Lesson {row['lesson']}: "
        f"{row['name']}"
    )


def run_prolog_inventory() -> dict:
    """Read the live Prolog relations through the supported lesson loader."""
    goal = r"""
use_module(library(http/json)),
use_module(lessons('im/lesson_monitoring')),
findall(_{atom:Atom,dash:Dash,title:Title},
        ( lesson_monitoring:loaded_standard_anchor(Atom, im_lesson, DashString, Title),
          atom(Atom),
          atom_string(Dash, DashString)
        ),
        IdentityRows0),
sort(IdentityRows0, IdentityRows),
findall(_{atom:Atom,framework:Framework},
        ( lesson_monitoring:loaded_standard_anchor(Atom, Framework, _Code, _Statement),
          atom(Atom),
          Framework \== im_lesson
        ),
        AtomStandardRows0),
sort(AtomStandardRows0, AtomStandardRows),
findall(Dash,
        lesson_monitoring:explicit_lesson_standard(Dash, _Framework, _Code, _Statement),
        DashStandardRows0),
sort(DashStandardRows0, DashStandardRows),
json_write_dict(current_output,
                _{identity_rows:IdentityRows,
                  atom_standard_rows:AtomStandardRows,
                  dash_standard_lessons:DashStandardRows}),
nl,
halt
"""
    completed = subprocess.run(
        ["swipl", "-q", "-l", str(ROOT / "paths.pl"), "-g", goal],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    if completed.returncode:
        raise RuntimeError(
            completed.stderr.strip() or "SWI-Prolog lesson inventory failed"
        )
    if completed.stderr.strip():
        raise RuntimeError(completed.stderr.strip())
    return json.loads(completed.stdout)


def source_inventory() -> dict:
    spine = json.loads(SPINE.read_text(encoding="utf-8"))
    if not isinstance(spine, list) or not spine:
        raise RuntimeError("published IM K-8 spine is empty or malformed")

    by_dash: dict[str, dict] = {}
    for row in spine:
        dash = row["repo_id"]
        grade, unit, lesson = dash_parts(dash)
        if (
            str(row["grade"]) != grade
            or int(row["unit"]) != unit
            or int(row["lesson"]) != lesson
        ):
            raise RuntimeError(f"spine coordinates disagree with {dash}")
        if dash in by_dash:
            raise RuntimeError(f"duplicate published spine lesson: {dash}")
        by_dash[dash] = row

    inventory = run_prolog_inventory()
    identity_by_dash: dict[str, tuple[str, str]] = {}
    concept_routes: list[tuple[str, str, str]] = []
    unconverted_identity_rows: list[dict] = []
    for row in inventory["identity_rows"]:
        atom = row["atom"]
        dash = row["dash"]
        atom_match = ATOM_ID_RE.fullmatch(atom)
        dash_match = DASH_ID_RE.fullmatch(dash)
        if atom_match is not None and dash_match is not None:
            if dash in identity_by_dash:
                raise RuntimeError(f"duplicate lesson identity source row: {dash}")
            identity_by_dash[dash] = (atom, row["title"])
        elif dash_match is not None and dash_match.group(1) in {"6", "7", "8"}:
            concept_routes.append((atom, dash, row["title"]))
        elif "_u" in atom and "_l" in atom:
            unconverted_identity_rows.append(row)

    if unconverted_identity_rows:
        sample = ", ".join(
            f"{row['atom']}:{row['dash']}" for row in unconverted_identity_rows[:5]
        )
        raise RuntimeError(f"unconverted lesson identity source rows: {sample}")

    for dash, (atom, title) in identity_by_dash.items():
        spine_row = by_dash.get(dash)
        if spine_row is None:
            raise RuntimeError(f"identity row is absent from the published spine: {dash}")
        grade, unit, lesson = dash_parts(dash)
        expected_atom = atom_id(grade, unit, lesson)
        if atom != expected_atom:
            raise RuntimeError(
                f"identity source disagrees with mechanical rule: "
                f"{atom} != {expected_atom} for {dash}"
            )
        title_prefix = expected_title_prefix(spine_row)
        if not title.startswith(title_prefix):
            raise RuntimeError(
                f"identity title disagrees with published spine for {dash}: "
                f"{title!r} does not begin {title_prefix!r}"
            )

    k5_dash = {
        dash for dash, row in by_dash.items() if str(row["grade"]) in {"K", "1", "2", "3", "4", "5"}
    }
    missing_k5_identity = k5_dash - identity_by_dash.keys()
    extra_identity = identity_by_dash.keys() - k5_dash
    if missing_k5_identity or extra_identity:
        raise RuntimeError(
            "K-5 identity source coverage disagrees with the published spine: "
            f"missing={sorted(missing_k5_identity)[:5]}, "
            f"extra={sorted(extra_identity)[:5]}"
        )

    concept_by_dash: dict[str, tuple[str, str]] = {}
    concept_id_routes: dict[str, set[str]] = defaultdict(set)
    concept_title_disagreements: list[tuple[str, str, str]] = []
    for concept, dash, title in concept_routes:
        if dash in concept_by_dash:
            raise RuntimeError(f"duplicate concept-keyed lesson route: {dash}")
        spine_row = by_dash.get(dash)
        if spine_row is None:
            raise RuntimeError(f"concept-keyed route is outside the spine: {dash}")
        if title != spine_row["name"]:
            concept_title_disagreements.append(
                (dash, title, spine_row["name"])
            )
        concept_by_dash[dash] = (concept, title)
        concept_id_routes[concept].add(dash)

    middle_dash = {
        dash for dash, row in by_dash.items() if str(row["grade"]) in {"6", "7", "8"}
    }
    missing_concept_routes = middle_dash - concept_by_dash.keys()
    extra_concept_routes = concept_by_dash.keys() - middle_dash
    if missing_concept_routes or extra_concept_routes:
        raise RuntimeError(
            "grade 6-8 concept routes disagree with the published spine: "
            f"missing={sorted(missing_concept_routes)[:5]}, "
            f"extra={sorted(extra_concept_routes)[:5]}"
        )

    atom_standard_ids = {
        row["atom"]
        for row in inventory["atom_standard_rows"]
        if ATOM_ID_RE.fullmatch(row["atom"])
    }
    dash_standard_ids = {
        dash
        for dash in inventory["dash_standard_lessons"]
        if DASH_ID_RE.fullmatch(dash)
    }
    unknown_atom_standards = atom_standard_ids - {
        atom_id(*dash_parts(dash)) for dash in by_dash
    }
    unknown_dash_standards = dash_standard_ids - by_dash.keys()
    invalid_unknown_dash = {
        dash for dash in unknown_dash_standards if DASH_ID_RE.fullmatch(dash) is None
    }
    invalid_unknown_atom = {
        atom for atom in unknown_atom_standards if ATOM_ID_RE.fullmatch(atom) is None
    }
    if invalid_unknown_atom or invalid_unknown_dash:
        raise RuntimeError(
            "unconvertible lesson standards are outside the published spine: "
            f"atom={sorted(invalid_unknown_atom)[:5]}, "
            f"dash={sorted(invalid_unknown_dash)[:5]}"
        )

    return {
        "spine": spine,
        "by_dash": by_dash,
        "identity_by_dash": identity_by_dash,
        "concept_by_dash": concept_by_dash,
        "concept_id_routes": concept_id_routes,
        "concept_title_disagreements": concept_title_disagreements,
        "atom_standard_ids": atom_standard_ids,
        "dash_standard_ids": dash_standard_ids,
        "unknown_atom_standards": unknown_atom_standards,
        "unknown_dash_standards": unknown_dash_standards,
    }


def render_module() -> tuple[str, Counter[str], Counter[str], dict]:
    inventory = source_inventory()
    spine = sorted(inventory["spine"], key=lambda row: row["repo_id"])
    identity_by_dash = inventory["identity_by_dash"]
    atom_standard_ids = inventory["atom_standard_ids"]
    dash_standard_ids = inventory["dash_standard_ids"]
    identity_counts: Counter[str] = Counter()
    standard_counts: Counter[str] = Counter()

    lines = [
        "/** <module> Checked Illustrative Mathematics lesson identity",
        " *",
        " * The published K-8 spine is the finite denominator for this relation.",
        " * derived_lesson_id_pair/2 states the mechanical spelling rule;",
        " * im_lesson_identity/4 records the checked result for each published",
        " * lesson. K-5 rows cite the existing standard_anchor/4 fact containing",
        " * both spellings. Grades 6-8 retain a typed atom-spelling absence.",
        " *",
        " * Concept-keyed grade 6-8 anchors are checked by the generator but are",
        " * not identity aliases. lesson_standard_through_identity/5 reaches only",
        " * academic standard facts, preserving that boundary.",
        " *",
        " * Generated by scripts/extract_im_lesson_identity.py.",
        " * Regenerate: python3 scripts/extract_im_lesson_identity.py",
        " */",
        "",
        ":- module(im_lesson_identity,",
        "          [ derived_lesson_id_pair/2,",
        "            im_lesson_identity/4,",
        "            lesson_identity_denominator/1,",
        "            lesson_identity_status_count/2,",
        "            lesson_standard_reachability/3,",
        "            lesson_standard_through_identity/5",
        "          ]).",
        "",
        ":- use_module(lessons('im/lesson_monitoring'), []).",
        "",
        "%!  derived_lesson_id_pair(?AtomId, ?DashId) is nondet.",
        "%",
        "%   Mechanical conversion between the two lesson-id spellings. With both",
        "%   arguments unbound, enumerate only pairs checked into the finite table.",
        "derived_lesson_id_pair(AtomId, DashId) :-",
        "    ( nonvar(AtomId)",
        "    -> atom_lesson_parts(AtomId, Grade, Unit, Lesson),",
        "       dash_lesson_id(Grade, Unit, Lesson, DashId)",
        "    ; nonvar(DashId)",
        "    -> dash_lesson_parts(DashId, Grade, Unit, Lesson),",
        "       atom_lesson_id(Grade, Unit, Lesson, AtomId)",
        "    ; im_lesson_identity(AtomId, DashId, _, _)",
        "    ).",
        "",
        "atom_lesson_parts(AtomId, Grade, Unit, Lesson) :-",
        "    atom(AtomId),",
        "    ( atom_concat(im_kindergarten_u, Rest, AtomId)",
        "    -> Grade = 'K'",
        "    ; atom_concat(im_grade, GradeRest, AtomId),",
        "      atomic_list_concat([GradeAtom, UnitRest], '_u', GradeRest),",
        "      atom_number(GradeAtom, GradeNumber),",
        "      between(1, 8, GradeNumber),",
        "      atom_number(Grade, GradeNumber),",
        "      Rest = UnitRest",
        "    ),",
        "    atomic_list_concat([UnitAtom, LessonAtom], '_l', Rest),",
        "    atom_number(UnitAtom, Unit),",
        "    atom_number(LessonAtom, Lesson),",
        "    Unit > 0, Lesson > 0.",
        "",
        "dash_lesson_parts(DashId, Grade, Unit, Lesson) :-",
        "    atom(DashId),",
        "    atomic_list_concat(['IM', GradePart, UnitPart, LessonPart], '-', DashId),",
        "    atom_concat('G', Grade, GradePart),",
        "    ( Grade == 'K'",
        "    -> true",
        "    ; atom_number(Grade, GradeNumber), between(1, 8, GradeNumber)",
        "    ),",
        "    atom_concat('U', UnitAtom, UnitPart),",
        "    atom_concat('L', LessonAtom, LessonPart),",
        "    atom_number(UnitAtom, Unit),",
        "    atom_number(LessonAtom, Lesson),",
        "    Unit > 0, Lesson > 0.",
        "",
        "atom_lesson_id('K', Unit, Lesson, AtomId) :-",
        "    format(atom(AtomId), 'im_kindergarten_u~d_l~d', [Unit, Lesson]).",
        "atom_lesson_id(Grade, Unit, Lesson, AtomId) :-",
        "    Grade \\== 'K',",
        "    format(atom(AtomId), 'im_grade~w_u~d_l~d', [Grade, Unit, Lesson]).",
        "",
        "dash_lesson_id(Grade, Unit, Lesson, DashId) :-",
        "    format(atom(DashId), 'IM-G~w-U~d-L~d', [Grade, Unit, Lesson]).",
        "",
    ]

    native_source_lines: list[str] = []
    for row in spine:
        dash = row["repo_id"]
        grade, unit, lesson = dash_parts(dash)
        atom = atom_id(grade, unit, lesson)
        name = row["name"]
        spine_evidence = (
            "source_record('data/learningcommons/derived/im_k8_spine.json', "
            f"{prolog_atom(dash)}, spine_coordinates({prolog_atom(grade)}, "
            f"{unit}, {lesson}), {prolog_string(name)})"
        )
        if dash in identity_by_dash:
            status = "present(source_join)"
            identity_counts["present(source_join)"] += 1
            source_evidence = (
                "source_fact('knowledge/standards/im/lesson_anchors.pl', "
                f"standard_anchor/4, identity_keys({prolog_atom(atom)}, "
                f"{prolog_atom(dash)}))"
            )
            evidence = f"[{source_evidence}, {spine_evidence}]"
        else:
            status = "coverage_gap(atom_spelling_absent)"
            identity_counts["coverage_gap(atom_spelling_absent)"] += 1
            evidence = (
                f"[{spine_evidence}, derived_by(derived_lesson_id_pair/2), "
                "source_absence(atom_spelling)]"
            )
        lines.append(
            f"im_lesson_identity({prolog_atom(atom)}, {prolog_atom(dash)}, "
            f"{status}, {evidence})."
        )

        sources: list[str] = []
        if atom in atom_standard_ids:
            sources.append("atom_spelling")
            native_source_lines.append(
                f"lesson_standard_native_source({prolog_atom(dash)}, atom_spelling, "
                "source_fact(standard_anchor/4, "
                f"{prolog_atom(atom)}))."
            )
        if dash in dash_standard_ids:
            sources.append("dash_spelling")
            native_source_lines.append(
                f"lesson_standard_native_source({prolog_atom(dash)}, dash_spelling, "
                "source_fact(lesson_monitoring:explicit_lesson_standard/4, "
                f"{prolog_atom(dash)}))."
            )
        if sources == ["atom_spelling", "dash_spelling"]:
            standard_counts["both_spellings"] += 1
        elif sources:
            standard_counts[sources[0]] += 1
        else:
            standard_counts["no_standard_anchor"] += 1

    for dash in sorted(inventory["unknown_dash_standards"]):
        grade, unit, lesson = dash_parts(dash)
        atom = atom_id(grade, unit, lesson)
        identity_counts["unknown(published_spine_absent)"] += 1
        lines.append(
            f"im_lesson_identity({prolog_atom(atom)}, {prolog_atom(dash)}, "
            "unknown(published_spine_absent), "
            "[source_fact('curriculum/im/generated/lesson_standard_anchors.pl', "
            f"lesson_monitoring:explicit_lesson_standard/4, {prolog_atom(dash)}), "
            "derived_by(derived_lesson_id_pair/2), "
            "source_absence(published_spine)])."
        )
        native_source_lines.append(
            f"lesson_standard_native_source({prolog_atom(dash)}, dash_spelling, "
            "source_fact(lesson_monitoring:explicit_lesson_standard/4, "
            f"{prolog_atom(dash)}))."
        )
    for atom in sorted(inventory["unknown_atom_standards"]):
        match = ATOM_ID_RE.fullmatch(atom)
        if match is None:
            continue
        grade = match.group(1) or "K"
        unit = int(match.group(2))
        lesson = int(match.group(3))
        dash = f"IM-G{grade}-U{unit}-L{lesson}"
        identity_counts["unknown(published_spine_absent)"] += 1
        lines.append(
            f"im_lesson_identity({prolog_atom(atom)}, {prolog_atom(dash)}, "
            "unknown(published_spine_absent), "
            "[source_fact(standard_anchor/4, "
            f"{prolog_atom(atom)}), derived_by(derived_lesson_id_pair/2), "
            "source_absence(published_spine)])."
        )
        native_source_lines.append(
            f"lesson_standard_native_source({prolog_atom(dash)}, atom_spelling, "
            f"source_fact(standard_anchor/4, {prolog_atom(atom)}))."
        )

    lines.extend([
        "",
        f"lesson_identity_denominator({len(spine)}).",
        f"lesson_identity_status_count(present(source_join), {identity_counts['present(source_join)']}).",
        "lesson_identity_status_count(coverage_gap(atom_spelling_absent), "
        f"{identity_counts['coverage_gap(atom_spelling_absent)']}).",
        "lesson_identity_status_count(unknown(published_spine_absent), "
        f"{identity_counts['unknown(published_spine_absent)']}).",
        "",
    ])
    for dash, concept_title, spine_title in inventory["concept_title_disagreements"]:
        lines.append(
            "% concept_route_title_disagreement("
            f"{prolog_atom(dash)}, {prolog_string(concept_title)}, "
            f"{prolog_string(spine_title)})."
        )
    if inventory["concept_title_disagreements"]:
        lines.append("")
    lines.extend(native_source_lines)
    lines.extend([
        "",
        "%!  lesson_standard_reachability(+DashId, -Status, -Evidence) is det.",
        "%",
        "%   Classify the native academic-standard route for one published lesson.",
        "lesson_standard_reachability(DashId, Status, Evidence) :-",
        "    im_lesson_identity(_AtomId, DashId, IdentityStatus, _IdentityEvidence),",
        "    IdentityStatus \\= unknown(_),",
        "    findall(Source-EvidenceItem,",
        "            lesson_standard_native_source(DashId, Source, EvidenceItem),",
        "            SourceRows0),",
        "    sort(SourceRows0, SourceRows),",
        "    standard_source_status(SourceRows, Status, Evidence).",
        "",
        "standard_source_status([], coverage_gap(no_standard_anchor),",
        "                       [machinery(standard_anchor),",
        "                        machinery(lesson_monitoring:explicit_lesson_standard/4)]).",
        "standard_source_status([atom_spelling-Evidence], present(atom_spelling),",
        "                       [Evidence]).",
        "standard_source_status([dash_spelling-Evidence], present(dash_spelling),",
        "                       [Evidence]).",
        "standard_source_status([atom_spelling-AtomEvidence,",
        "                        dash_spelling-DashEvidence],",
        "                       present(both_spellings),",
        "                       [AtomEvidence, DashEvidence]).",
        "",
        "%!  lesson_standard_through_identity(",
        "%!      +LessonId, ?Framework, ?Code, ?Statement, -NativeSpelling) is nondet.",
        "%",
        "%   Reach an academic standard from either checked lesson-id spelling.",
        "lesson_standard_through_identity(LessonId, Framework, Code, Statement,",
        "                                 atom_spelling(AtomId)) :-",
        "    identity_member(LessonId, AtomId, _DashId),",
        "    lesson_monitoring:loaded_standard_anchor(",
        "        AtomId, Framework, Code, Statement),",
        "    Framework \\== im_lesson.",
        "lesson_standard_through_identity(LessonId, Framework, Code, Statement,",
        "                                 dash_spelling(DashId)) :-",
        "    identity_member(LessonId, _AtomId, DashId),",
        "    lesson_monitoring:explicit_lesson_standard(",
        "        DashId, Framework, Code, Statement).",
        "",
        "identity_member(LessonId, AtomId, DashId) :-",
        "    im_lesson_identity(AtomId, DashId, _Status, _Evidence),",
        "    ( LessonId == AtomId ; LessonId == DashId ).",
        "",
    ])
    return "\n".join(lines), identity_counts, standard_counts, inventory


def check_output(expected: str, output: Path) -> int:
    actual = output.read_text(encoding="utf-8") if output.is_file() else ""
    if actual == expected:
        return 0
    with tempfile.NamedTemporaryFile(
        "w", encoding="utf-8", suffix=".pl", delete=False
    ) as temporary:
        temporary.write(expected)
        temporary_path = Path(temporary.name)
    diff = list(
        difflib.unified_diff(
            actual.splitlines(),
            expected.splitlines(),
            fromfile=str(output),
            tofile=str(temporary_path),
            lineterm="",
        )
    )
    print(
        "IM lesson identity is stale; run python3 "
        "scripts/extract_im_lesson_identity.py",
        file=sys.stderr,
    )
    for line in diff[:12]:
        print(line, file=sys.stderr)
    temporary_path.unlink(missing_ok=True)
    return 1


def summary(
    output: Path,
    identity_counts: Counter[str],
    standard_counts: Counter[str],
    inventory: dict,
    current: bool,
) -> str:
    concept_fact_count = len(inventory["concept_by_dash"])
    concept_id_count = len(inventory["concept_id_routes"])
    disagreements = inventory["concept_title_disagreements"]
    disagreement_text = (
        "none"
        if not disagreements
        else ", ".join(
            f"{dash}:{concept_title!r}!={spine_title!r}"
            for dash, concept_title, spine_title in disagreements
        )
    )
    state = "current" if current else "wrote"
    return (
        f"IM lesson identity {state}: "
        f"{output.relative_to(ROOT) if output.is_relative_to(ROOT) else output}; "
        f"rows={sum(identity_counts.values())}; "
        f"published_denominator={len(inventory['spine'])}; "
        f"present(source_join)={identity_counts['present(source_join)']}; "
        "coverage_gap(atom_spelling_absent)="
        f"{identity_counts['coverage_gap(atom_spelling_absent)']}; "
        "unknown(published_spine_absent)="
        f"{identity_counts['unknown(published_spine_absent)']}; "
        f"standard_anchor(atom_spelling)={standard_counts['atom_spelling']}; "
        f"standard_anchor(dash_spelling)={standard_counts['dash_spelling']}; "
        f"standard_anchor(both_spellings)={standard_counts['both_spellings']}; "
        f"standard_anchor(no_standard_anchor)={standard_counts['no_standard_anchor']}; "
        f"concept_routes={concept_fact_count}/{concept_fact_count} facts, "
        f"{concept_id_count}/{concept_id_count} concept ids; "
        f"concept_title_disagreements={disagreement_text}"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--output", type=Path, default=OUTPUT, help=argparse.SUPPRESS)
    args = parser.parse_args()
    output = args.output if args.output.is_absolute() else ROOT / args.output
    rendered, identity_counts, standard_counts, inventory = render_module()
    if args.check:
        result = check_output(rendered, output)
        if result == 0:
            print(summary(output, identity_counts, standard_counts, inventory, True))
        return result
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(rendered, encoding="utf-8")
    print(summary(output, identity_counts, standard_counts, inventory, False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
