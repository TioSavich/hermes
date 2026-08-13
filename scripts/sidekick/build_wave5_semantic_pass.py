#!/usr/bin/env python3
"""Reconcile the human-reviewed Wave 5 semantic-pass ledger."""

from __future__ import annotations

import argparse
import hashlib
import json
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SOLUTION_SOURCE = (
    ROOT
    / "hermes/app/runtime/experiments/sidekick/datasets/wave5-solution-pairs.jsonl"
)
DEFAULT_DIAGNOSIS_SOURCE = (
    ROOT
    / "hermes/app/runtime/experiments/sidekick/datasets/wave5-diagnosis-pairs.jsonl"
)
DEFAULT_PIO_SOURCE = (
    ROOT / "hermes/app/runtime/experiments/questions/question-pio-pairs.jsonl"
)
DEFAULT_OUTPUT = (
    ROOT
    / "hermes/app/runtime/experiments/sidekick/datasets/wave5-semantic-pass.jsonl"
)
SOLUTION_SOURCE_SHA256 = (
    "1a09bdd52308929d05d125832b190257ca38304dee6d048d0355ccb986d0096a"
)
SOLUTION_SOURCE_ROWS = 1383
# The K-7 leg of the mint is unchanged by the grade-8 demand-fit rebuild: the
# same 1,373 ids in the same order occupy the first 1,373 lines. The line
# adjudications below therefore still hold for those lines. Grade 8 lost 53 of
# its 63 rows to the demand gates, so its verdicts are keyed by id instead.
K7_SOLUTION_LINES = 1373
DIAGNOSIS_SOURCE_SHA256 = (
    "1ce5230bae98e1b8e12e6781a1974d5e1f9a1da95689ffd020f0b987befffbfe"
)
DIAGNOSIS_SOURCE_ROWS = 1389
PIO_SOURCE_SHA256 = (
    "7a5e6286f853a5a410584fbada13e11248936483ffd45c681d4cf0a42a1934bf"
)
PIO_SOURCE_ROWS = 909
REASON_CLASSES = {
    "wrong_machine",
    "operand_mismatch",
    "referent_mismatch",
    "mangled_input",
    "answer_inconsistent",
    "other-with-note",
}


def numbers(text: str) -> set[int]:
    return {int(value) for value in text.split()}


NOTES = {
    "mangled_input": (
        "The input is truncated, duplicated, or combines several demands instead of one intact task."
    ),
    "operand_mismatch": (
        "The program operands do not match the quantities supplied by the task."
    ),
    "wrong_machine": (
        "The selected machine does not carry out the mathematical action the task requests."
    ),
    "answer_inconsistent": (
        "The expected answer is not a plausible answer in the form requested by the task."
    ),
    "other-with-note": (
        "The input includes a worked solution or answer, so it is not a clean student task."
    ),
    "referent_mismatch": (
        "The shared quantity referent does not name the quantity requested by the task."
    ),
}

# These line adjudications are pinned to the current source hashes above. They
# update the prior ledger by id: repaired rows may become KEEP, newly admitted
# rows receive a first decision, and unchanged decisions carry forward.
SOLUTION_KEEP_LINES = numbers(
    "44 47 52 62 64 95 136 137 326 394 440 441 447 454 473 474 475 476 "
    "477 478 479 480 481 482 483 484 510 511 512 513 514 515 516 517 518 "
    "519 520 521 522 523 524 525 526 527 528 529 530 531 532 533 534 535 "
    "536 537 538 539 540 541 570 572 578 669 670 671 672 691 706 813 827 "
    "966 967 969 1002 1003 1005 1006 1331 1357"
)
SOLUTION_FLAG_LINES = {
    "referent_mismatch": numbers(
        "53 89 91 93 110 119 580 723 844 868"
    ),
    "mangled_input": numbers("94 96 132 811 812"),
    "operand_mismatch": numbers("145"),
    "wrong_machine": numbers(
        "588 604 714 833 893 894 961 962 963 1039 1040 1042 1069 1070 "
        "1098 1099 1161 1163 1164"
    ),
    "answer_inconsistent": numbers(""),
}
# Grade-8 verdicts from the 2026-08-13 read of the demand-fit rebuild. Every
# surviving grade-8 pair was read whole against its program, its answer, and
# its source statement.
G8_SOLUTION_VERDICTS: dict[str, str | None] = {
    # The equation the program solves is x - 5(x - 1) = x - (2x - 3); the input
    # lost the leading term and mixes two demands with a second equation.
    "im_defrag_f1a6b99462307dd233099f1f_1": "mangled_input",
    "im_defrag_1e44fea48a27e31352698b15_1": None,
    "im_defrag_5933c47e5e26b87ec5187d4e_1": None,
    # The task supplies 10,000 km per side. The program's left operand is 10^8,
    # which is already the product of two of those sides.
    "im_defrag_3b82ceedfb7a28535eff28d4_1": "operand_mismatch",
    # 70 is the low end of Mai's estimate, not the area of the square, and the
    # square itself is a figure the input does not carry.
    "im_defrag_f6d10b87eb7627fd903ff73c_1": "referent_mismatch",
    # The table lost its variable names and cell alignment, and the demand is to
    # complete every missing entry rather than the one the program returns.
    "im_defrag_9475b9f5d9008b9758f21f59_1": "mangled_input",
    "im_defrag_3f15cb205fefb9727c8d8a82_1": None,
    "im_defrag_030ad6d0a1d3e38a980e1eb8_1": None,
    "im_defrag_1dc1ee52e13e591e0ae61e17_1": None,
    "im_defrag_85edeb641252608948d2289d_1": None,
}
DIAGNOSIS_KEEP_LINES = numbers(
    "40 41 42 142 143 144 769 770 771 772 773 774 775 776 777 781 782 "
    "783 784 785 "
    "786 787 788 789 796 797 798 799 800 801 802 803 804 880 881 882 883 "
    "884 885 886 887 888 889 890 891 892 893 894 895 896 897 898 899 900 "
    "901 902 903 904 905 906 907 908 909 910 911 912 913 914 915 916 917 "
    "918 919 920 921 922 923 924 925 926 927 928 929 930 931 932 933 934 "
    "935 936 937 938 939 940 941 942 943 944 945 949 950 951 952 953 954 "
    "958 959 960 961 962 963 964 965 966 967 968 969 970 971 972 973 974 "
    "975 1123 1124 1125 1126 1127 1128 1129 1130 1131 1132 1133 1134 "
    "1300 1301 1302 1318 1319 1320 1369 1370 1371"
)
PIO_FLAG_LINES = {
    "mangled_input": numbers("1 69 96"),
    "referent_mismatch": numbers(
        "4 5 6 7 9 11 18 19 26 27 28 35 36 42 49 65 70 71 74 85 89 92 101"
    ),
    "wrong_machine": numbers("22 33 48 53 54 61 63 90 94 102"),
    "answer_inconsistent": numbers("25 95"),
}
PIO_NOTES = {
    "mangled_input": "The assembled teaching moment is incomplete or contains extraction debris.",
    "referent_mismatch": (
        "The question refers to a diagram, expression, object, or student work absent from the input."
    ),
    "wrong_machine": "The question does not make sense for the teaching moment supplied by the input.",
    "answer_inconsistent": (
        "The verbatim output lost required mathematical content and is not a usable question."
    ),
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def load_rows(path: Path) -> list[dict[str, object]]:
    with path.open(encoding="utf-8") as handle:
        return [json.loads(line) for line in handle if line.strip()]


def verify_source(
    path: Path,
    rows: list[dict[str, object]],
    *,
    expected_sha256: str,
    expected_rows: int,
    check_input_ambiguity: bool = True,
) -> None:
    observed_sha = sha256(path)
    if observed_sha != expected_sha256:
        raise RuntimeError(
            f"source SHA changed: expected {expected_sha256}, observed {observed_sha}"
        )
    if len(rows) != expected_rows:
        raise RuntimeError(
            f"source row count changed: expected {expected_rows}, observed {len(rows)}"
        )

    if not check_input_ambiguity:
        return

    differing = []
    by_input: dict[str, set[str]] = defaultdict(set)
    for row in rows:
        by_input[str(row["input"])].add(str(row["output"]))
    for input_text, outputs in by_input.items():
        if len(outputs) > 1:
            differing.append(input_text)
    if differing:
        raise RuntimeError(
            f"input ambiguity invariant failed for {len(differing)} input groups"
        )


def line_reasons(groups: dict[str, set[int]]) -> dict[int, str]:
    result: dict[int, str] = {}
    for reason, line_numbers in groups.items():
        if reason not in REASON_CLASSES:
            raise RuntimeError(f"unknown reason class: {reason}")
        for line_number in line_numbers:
            if line_number in result:
                raise RuntimeError(f"line {line_number} has two review reasons")
            result[line_number] = reason
    return result


def decision(
    pair_id: str,
    reason: str | None,
    *,
    notes: dict[str, str] = NOTES,
) -> dict[str, object]:
    row: dict[str, object] = {
        "id": pair_id,
        "reason_class": reason,
        "verdict": "flag" if reason else "keep",
    }
    if reason:
        row["note"] = notes[reason]
    return row


def load_baseline(path: Path) -> dict[str, dict[str, object]]:
    rows = load_rows(path)
    result: dict[str, dict[str, object]] = {}
    for row in rows:
        pair_id = str(row["id"])
        if pair_id in result:
            raise RuntimeError(f"baseline has duplicate id: {pair_id}")
        result[pair_id] = row
    return result


def build(
    solution_source: Path,
    diagnosis_source: Path,
    pio_source: Path,
    baseline_path: Path,
    output: Path,
) -> None:
    solution_rows = load_rows(solution_source)
    diagnosis_rows = load_rows(diagnosis_source)
    pio_rows = load_rows(pio_source)
    baseline = load_baseline(baseline_path)
    verify_source(
        solution_source,
        solution_rows,
        expected_sha256=SOLUTION_SOURCE_SHA256,
        expected_rows=SOLUTION_SOURCE_ROWS,
    )
    verify_source(
        diagnosis_source,
        diagnosis_rows,
        expected_sha256=DIAGNOSIS_SOURCE_SHA256,
        expected_rows=DIAGNOSIS_SOURCE_ROWS,
    )
    verify_source(
        pio_source,
        pio_rows,
        expected_sha256=PIO_SOURCE_SHA256,
        expected_rows=PIO_SOURCE_ROWS,
        check_input_ambiguity=False,
    )

    solution_overrides = line_reasons(SOLUTION_FLAG_LINES)
    pio_overrides = line_reasons(PIO_FLAG_LINES)
    if SOLUTION_KEEP_LINES & set(solution_overrides):
        raise RuntimeError("solution line has both KEEP and FLAG overrides")

    stale_lines = {
        line for line in SOLUTION_KEEP_LINES | set(solution_overrides)
        if line > K7_SOLUTION_LINES
    }
    if stale_lines:
        raise RuntimeError(
            f"solution line adjudications past the K-7 leg: {sorted(stale_lines)}"
        )

    results: list[dict[str, object]] = []
    read_g8: set[str] = set()
    for line_number, source_row in enumerate(solution_rows, 1):
        pair_id = str(source_row["id"])
        previous = baseline.get(pair_id)
        reason = (
            None
            if previous is None
            else previous.get("reason_class")
        )
        if line_number in SOLUTION_KEEP_LINES:
            reason = None
        if line_number in solution_overrides:
            reason = solution_overrides[line_number]
        if pair_id in G8_SOLUTION_VERDICTS:
            reason = G8_SOLUTION_VERDICTS[pair_id]
            read_g8.add(pair_id)
        elif str(source_row.get("grade")) == "8":
            raise RuntimeError(f"grade-8 pair {pair_id} carries no read verdict")
        results.append(decision(pair_id, None if reason is None else str(reason)))
    unread = set(G8_SOLUTION_VERDICTS) - read_g8
    if unread:
        raise RuntimeError(f"grade-8 verdicts name absent pairs: {sorted(unread)}")

    # The diagnosis set is below its ratified release floor. Carry forward only
    # decisions that existed before the rebuild, while correcting the repaired
    # statement subset. Newly admitted diagnosis ids remain unadjudicated.
    for line_number, source_row in enumerate(diagnosis_rows, 1):
        pair_id = str(source_row["id"])
        previous = baseline.get(pair_id)
        if previous is None:
            continue
        reason = previous.get("reason_class")
        if line_number in DIAGNOSIS_KEEP_LINES:
            reason = None
        results.append(decision(pair_id, None if reason is None else str(reason)))

    admitted_pio = [row for row in pio_rows if row["admitted_for_training"] is True]
    if len(admitted_pio) != 103:
        raise RuntimeError(f"expected 103 admitted PIO rows, observed {len(admitted_pio)}")
    for line_number, source_row in enumerate(admitted_pio, 1):
        reason = pio_overrides.get(line_number)
        results.append(
            decision(str(source_row["identity"]), reason, notes=PIO_NOTES)
        )

    ids = [str(row["id"]) for row in results]
    if len(ids) != len(set(ids)):
        raise RuntimeError("semantic pass would contain duplicate live ids")

    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", encoding="utf-8") as handle:
        for row in results:
            handle.write(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--solution-source", type=Path, default=DEFAULT_SOLUTION_SOURCE
    )
    parser.add_argument(
        "--diagnosis-source", type=Path, default=DEFAULT_DIAGNOSIS_SOURCE
    )
    parser.add_argument("--pio-source", type=Path, default=DEFAULT_PIO_SOURCE)
    parser.add_argument("--baseline", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    build(
        args.solution_source,
        args.diagnosis_source,
        args.pio_source,
        args.baseline,
        args.output,
    )


if __name__ == "__main__":
    main()
