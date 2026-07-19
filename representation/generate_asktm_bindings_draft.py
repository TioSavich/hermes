#!/usr/bin/env python3
"""Generate the owner-review draft for ASKTM category-to-automaton bindings."""

import argparse
import json
import re
from collections import Counter, defaultdict
from pathlib import Path


REPO = Path(__file__).resolve().parent.parent
DEFAULT_OUT = REPO / "representation" / "asktm_bindings_draft.json"
DEFAULT_REPORT = REPO / "representation" / "asktm_bindings_review.md"
LEGEND_DIRS = {
    4: "Grade 4_Fine-Grained Coding_Second Pass",
    5: "Grade5 _Fine-Grained Coding_Second Pass",
}
HEADER = re.compile(
    r"^#\s*(?:\*\*)?(?:Category\s+)?([ABC]\d)\s*[–\-—]\s*(.*?)"
    r"(?:\*\*)?\s*$",
    re.I,
)

# The proposal is deliberately question-level. The source category headings
# distinguish response form, not the strategy within that response. The owner
# must compare each proposal with the tag-list detail before verifying a row.
QUESTION_BINDINGS = {
    (4, 1): ("smr_frac_nl_compare",
             "run_fraction_action(number_line_fraction_comparison)",
             "Fraction ordering can be enacted by locating each value and comparing its number-line position."),
    (4, 2): ("smr_decimal_fraction_compare",
             "run_decimal_action(decimal_fraction_place_value_comparison)",
             "The coded work compares decimals by fraction conversion or coordinated place-value units."),
    (4, 3): ("fraction_semantics", "apply_equivalence_rule",
             "The question asks students to construct equivalent fractions."),
    (4, 4): ("smr_frac_nl_compare",
             "run_fraction_action(number_line_fraction_comparison)",
             "Fraction-decimal ordering can use the same number-line comparison after expressing both values as fractions."),
    (4, 5): ("divaded_fractional_units", "add_fractions_by_co_measurement",
             "The dominant coded doing is fraction addition."),
    (4, 6): ("sar_sub_decomposition", "run_decomposition",
             "The dominant coded doing is subtraction across decimal and fraction forms."),
    (4, 7): ("area_model_part_of_part",
             "run_fraction_action(area_model_part_of_part)",
             "The dominant coded doing is fraction multiplication or repeated addition."),
    (4, 8): ("smr_mult_dr", "run_dr",
             "The dominant coded doing is decimal multiplication or repeated addition."),
    (5, 1): ("divaded_fractional_units", "add_fractions_by_co_measurement",
             "The dominant coded doing is fraction addition."),
    (5, 2): ("sar_sub_decomposition", "run_decomposition",
             "The dominant coded doing is subtraction with estimation."),
    (5, 3): ("smr_div_ucr", "run_ucr",
             "The dominant coded doing is measurement division of 36 by 8."),
    (5, 4): ("smr_div_ucr", "run_ucr",
             "The dominant coded doing is division of 8 by 10."),
    (5, 5): ("divaded_fractional_units", "subtract_fractions_by_co_measurement",
             "The dominant coded doing is fraction subtraction via equivalent fractions."),
    (5, 6): ("sar_sub_decomposition", "run_decomposition",
             "The dominant coded doing is decimal subtraction."),
    (5, 7): ("area_model_part_of_part",
             "run_fraction_action(area_model_part_of_part)",
             "The requested operation is fraction multiplication."),
    (5, 8): ("smr_div_ucr", "run_ucr",
             "The dominant coded doing is measurement division, often via repeated addition."),
}


def legend_files(metadata_root):
    for grade, dirname in LEGEND_DIRS.items():
        yield from ((grade, path) for path in sorted(
            (metadata_root / dirname / "converted").glob(f"G{grade}Q*.md")
        ))


def extract_rows(metadata_root):
    rows = []
    for grade, path in legend_files(metadata_root):
        question = int(re.search(r"Q(\d+)", path.stem, re.I).group(1))
        for line_no, line in enumerate(path.read_text(
                encoding="utf-8", errors="replace").splitlines(), 1):
            match = HEADER.match(line)
            if not match:
                continue
            code, legend = match.groups()
            code = code.upper()
            if code in {"A1", "B1", "C1", "C2", "C3"}:
                proposed, concept = "no_defensible_binding", None
                rationale = ("This response-form category does not expose an observable "
                             "strategy to bind.")
            else:
                proposed, concept, rationale = QUESTION_BINDINGS[(grade, question)]
            rows.append({
                "grade": grade,
                "question": question,
                "category_code": code,
                "legend_text": legend,
                "proposed_automaton": proposed,
                "proposed_prolog_concept": concept,
                "rationale": rationale,
                "verification_status": "draft_unverified",
                "source": {
                    "file": str(path.relative_to(metadata_root)),
                    "line": line_no,
                },
            })
    return rows


def accounting(rows):
    counts = Counter(row["proposed_automaton"] for row in rows)
    return {
        "codes_total": len(rows),
        "mapped": sum(count for name, count in counts.items()
                      if name not in {"awaiting_conversion", "no_defensible_binding"}),
        "awaiting_conversion": counts["awaiting_conversion"],
        "no_defensible_binding": counts["no_defensible_binding"],
        "verified": sum(row["verification_status"] == "verified" for row in rows),
    }


def write_report(path, rows, counts):
    groups = defaultdict(list)
    for row in rows:
        groups[row["proposed_automaton"]].append(row)
    lines = [
        "# ASKTM binding review draft",
        "",
        ("> DRAFT, OWNER NOT VERIFIED. Mapped rows may reach the gallery only "
         "with an unverified draft badge."),
        "",
        (f"Accounting: {counts['codes_total']} codes; {counts['mapped']} mapped; "
         f"{counts['awaiting_conversion']} awaiting_conversion; "
         f"{counts['no_defensible_binding']} no_defensible_binding; "
         f"{counts['verified']} verified."),
        "",
    ]
    for name in sorted(groups):
        group = sorted(groups[name], key=lambda r: (
            r["grade"], r["question"], r["category_code"]))
        lines.extend([f"## {name} ({len(group)})", ""])
        for row in group:
            key = f"G{row['grade']}Q{row['question']}:{row['category_code']}"
            lines.append(f"- `{key}` — {row['legend_text']}  ")
            lines.append(f"  {row['rationale']}")
        lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--metadata-root", required=True, type=Path)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUT)
    parser.add_argument("--report", type=Path, default=DEFAULT_REPORT)
    args = parser.parse_args()
    rows = extract_rows(args.metadata_root)
    counts = accounting(rows)
    payload = {
        "status": "DRAFT_OWNER_NOT_VERIFIED",
        "owner_verified": False,
        "downstream_policy": (
            "Mapped rows may join as draft; verification_status=verified joins "
            "at the verified tier."
        ),
        "source_kind": "ASKTM fine-grained Markdown category legends",
        "accounting": counts,
        "bindings": rows,
    }
    args.output.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8",
    )
    write_report(args.report, rows, counts)
    print(json.dumps(counts, sort_keys=True))


if __name__ == "__main__":
    main()
