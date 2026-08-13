#!/usr/bin/env python3
"""Build the grade 8 solver-route map from the pool and the g8 pilot automata.

The published family-to-machine table routes grade 8 nowhere: every grade 8
row's operation term is `curriculum_task(section(...))`, which names a position
in a guide rather than an arithmetic doing. This builder produces the routes
grade 8 does have, in the same genre as `wave5_row_machine_map.jsonl`, from two
inputs and nothing else:

  1. the pool map, `curriculum/im/generated/wave5_row_machine_map.jsonl`, for
     each row's statement, status, referents, visuals, and evidence hash, and
  2. the thirteen quarantined pilots under
     `knowledge/strategies/abstraction/g8_*.pl`, run through
     `scripts/curriculum/g8_receipt_emitter.pl`.

Every emitted line is a machine that ran on a row's own numbers. Nothing here
computes an answer itself: the Prolog side computes and certifies, and this
side joins the certified outcome to the row it came from. A receipt whose
validity is not `correct` is written with the validity it actually returned,
and refusals are marked as refusals rather than folded into the solved count.

Two rows are additionally routed through an extant published machine
(`algebraic/balance_preserving_linear_solution`) by a mechanical read of the
statement's own LaTeX; those probes run through
`scripts/sidekick/wave5_trace_runner.pl`.

Usage:
    python3 scripts/curriculum/build_g8_row_machine_map.py
    python3 scripts/curriculum/build_g8_row_machine_map.py --check
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
POOL_MAP = ROOT / "curriculum/im/generated/wave5_row_machine_map.jsonl"
OUTPUT = ROOT / "curriculum/im/generated/wave5_g8_row_machine_map.jsonl"
EMITTER = ROOT / "scripts/curriculum/g8_receipt_emitter.pl"
TRACE_RUNNER = ROOT / "scripts/sidekick/wave5_trace_runner.pl"
PILOT_DIR = ROOT / "knowledge/strategies/abstraction"

# Menu carved from the grade 8 unit structure. A row's unit fixes its entry;
# the clustering that first produced these labels is recorded in the report
# and is not re-derived here.
CLUSTER_BY_UNIT = {
    1: "rigid_transformations",
    2: "dilations_and_similarity",
    3: "linear_relationships_and_slope",
    4: "one_variable_linear_equations",
    5: "functions",
    6: "scatter_plots_and_line_fit",
    7: "exponents_and_scientific_notation",
    8: "pythagorean_irrationals_and_volume",
    9: "putting_it_all_together",
}


def fail(message: str) -> None:
    raise SystemExit(f"build_g8_row_machine_map.py: {message}")


def grade8_rows() -> dict[str, dict]:
    if not POOL_MAP.is_file():
        fail(f"missing pool map: {POOL_MAP}")
    rows = {}
    for line in POOL_MAP.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        row = json.loads(line)
        if row.get("grade") == "8":
            rows[row["id"]] = row
    if not rows:
        fail("pool map carries no grade 8 rows")
    return rows


def unit_of(lesson: str) -> int:
    match = re.match(r"IM-G8-U(\d+)-L\d+", lesson)
    if not match:
        fail(f"lesson id outside the grade 8 shape: {lesson}")
    return int(match.group(1))


# ------------------------------------------------------------------ receipts

def run_emitter() -> list[dict]:
    """Run every pilot receipt through SWI-Prolog and read the outcomes."""
    if not EMITTER.is_file():
        fail(f"missing receipt emitter: {EMITTER}")
    result = subprocess.run(
        ["swipl", "-q", "-f", str(EMITTER)],
        cwd=ROOT, capture_output=True, text=True,
    )
    if result.returncode != 0:
        fail(f"receipt emitter failed: {result.stderr.strip()[:400]}")
    receipts = []
    for line in result.stdout.splitlines():
        if line.strip():
            receipts.append(json.loads(line))
    if not receipts:
        fail("receipt emitter produced no receipts")
    return receipts


# ------------------------------------- the one mechanical extant-machine read

LATEX = re.compile(r"\$\$(.+?)\$\$", re.S)
EQ_SPLIT = re.compile(r"(?<![<>!=])=(?!=)")


def flatten_latex(block: str) -> str:
    """Docling split every numeral and symbol; rejoin adjacent digit runs."""
    s = re.sub(r"\\begin\{[a-z]*\}|\\end\{[a-z]*\}", " ; ", block)
    s = s.replace("\\left", " ").replace("\\right", " ")
    s = s.replace("\\\\", " ; ").replace("&", " ")
    s = re.sub(r"\\[a-zA-Z]+", " ", s).replace("\\", " ")
    previous = None
    while previous != s:
        previous = s
        s = re.sub(r"(?<=\d) (?=\d)", "", s)
    return s


def one_sided_equations(statement: str) -> list[tuple[int, int, int]] | None:
    """`a*x + b = c` triples when EVERY equation in the row has that shape.

    Returns None when any equation carries the unknown on both sides, which
    is the pilot automaton's territory rather than the extant machine's.
    """
    lines = []
    for block in LATEX.findall(statement):
        for piece in re.split(r";|\n", flatten_latex(block)):
            if "=" in piece:
                lines.append(piece.strip())
    if not lines:
        return None
    triples = []
    for line in lines:
        parts = [p.strip() for p in EQ_SPLIT.split(line)]
        for left, right in zip(parts, parts[1:]):
            parsed = parse_one_sided(left, right)
            if parsed is None:
                return None
            triples.append(parsed)
    return triples or None


def parse_one_sided(left: str, right: str) -> tuple[int, int, int] | None:
    """Parse `a*x + b` = `c` with integer coefficients, or give up."""
    right = right.replace(" ", "")
    if not re.fullmatch(r"-?\d+", right):
        return None
    constant = int(right)
    text = left.replace(" ", "")
    match = re.fullmatch(r"(-?\d*)\(([a-zA-Z])([+-]\d+)\)", text)
    if match:
        outer = match.group(1)
        factor = -1 if outer == "-" else (1 if outer in {"", "+"} else int(outer))
        inner = int(match.group(3))
        return factor, factor * inner, constant
    match = re.fullmatch(r"(-?\d*)([a-zA-Z])([+-]\d+)?", text)
    if match:
        raw = match.group(1)
        coefficient = -1 if raw == "-" else (1 if raw in {"", "+"} else int(raw))
        offset = int(match.group(3)) if match.group(3) else 0
        return coefficient, offset, constant
    return None


class TraceRunner:
    """The shared headless strategy_trace seam, one process for the run."""

    def __init__(self) -> None:
        self.process = subprocess.Popen(
            ["swipl", "-q", "-f", str(TRACE_RUNNER)], cwd=ROOT, text=True,
            stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, bufsize=1,
        )

    def run(self, machine: str, payload: dict) -> dict:
        request = {"mode": "trace", "machine": machine, "input": payload}
        self.process.stdin.write(json.dumps(request, sort_keys=True) + "\n")
        self.process.stdin.flush()
        line = self.process.stdout.readline()
        if not line:
            fail(f"trace runner stopped: {self.process.stderr.read()[:300]}")
        return json.loads(line)

    def close(self) -> None:
        if self.process.stdin and self.process.poll() is None:
            self.process.stdin.write('{"mode":"stop"}\n')
            self.process.stdin.flush()
            self.process.stdin.close()
        self.process.wait(timeout=20)


# --------------------------------------------------------------------- build

def base_record(row: dict) -> dict:
    return {
        "id": row["id"],
        "lesson": row["lesson"],
        "grade": "8",
        "family": row.get("family", "curriculum_task"),
        "operation": row["operation"],
        "source_position": row["source_position"],
        "source_excerpt": row["source_excerpt"],
        "statement": row["statement"],
        "status": row["status"],
        "referents": row["referents"],
        "visuals": row["visuals"],
        "evidence_sha256": row["evidence_sha256"],
        "menu_cluster": CLUSTER_BY_UNIT[unit_of(row["lesson"])],
    }


def build() -> tuple[bytes, dict]:
    rows = grade8_rows()
    records: list[dict] = []
    unknown_rows: list[str] = []

    for index, receipt in enumerate(run_emitter(), start=1):
        row = rows.get(receipt["row_id"])
        if row is None:
            unknown_rows.append(receipt["row_id"])
            continue
        validity = receipt["validity"]
        if validity == "correct":
            route = "new_quarantined_automaton"
        elif validity == "refused":
            route = "new_quarantined_automaton_refusal"
        else:
            route = "new_quarantined_automaton_unvindicated"
        records.append({
            **base_record(row),
            "route": route,
            "cluster": receipt["cluster"],
            "module": f"knowledge/strategies/abstraction/{receipt['module']}.pl",
            "machine": receipt["doing"],
            "input": receipt["input"],
            "decoded_input": receipt["decoded_input"],
            "execution": {
                "ok": validity == "correct",
                "outcome": "correct" if validity == "correct" else validity,
                "validity": validity,
                "result_term": receipt["result_term"],
                "note": "",
            },
            "verification": {
                "method": receipt["verification"],
                "receipt": f"{receipt['module']}:g8 receipt {index}",
                "check": f"check_{receipt['module']}/0",
            },
        })

    if unknown_rows:
        fail("receipts name rows the pool does not carry: "
             + ", ".join(sorted(set(unknown_rows))[:5]))

    runner = TraceRunner()
    try:
        for row in rows.values():
            triples = one_sided_equations(row["statement"])
            if not triples:
                continue
            probes = [{"kind": "linear_equation", "a": a, "b": b, "c": c}
                      for a, b, c in triples]
            results = [runner.run("balance_preserving_linear_solution", p)
                       for p in probes]
            if not all(r.get("outcome") == "correct" for r in results):
                continue
            for probe, result in zip(probes, results):
                records.append({
                    **base_record(row),
                    "route": "extant_machine",
                    "cluster": "one_variable_linear_equations",
                    "module": "knowledge/strategies/math/algebraic_action_pairs.pl",
                    "machine": "balance_preserving_linear_solution",
                    "input": probe,
                    "decoded_input": "",
                    "execution": result,
                    "verification": {
                        "method": "headless strategy_trace on the row's own numbers",
                        "receipt": "scripts/sidekick/wave5_trace_runner.pl",
                        "check": "",
                    },
                })
    finally:
        runner.close()

    records.sort(key=lambda r: (r["lesson"], r["id"], r["machine"],
                                json.dumps(r["input"], sort_keys=True)))
    text = "\n".join(json.dumps(r, sort_keys=True) for r in records) + "\n"
    payload = text.encode("utf-8")

    routes = Counter(r["route"] for r in records)
    unvindicated = routes.get("new_quarantined_automaton_unvindicated", 0)
    if unvindicated:
        fail(f"{unvindicated} receipts came back unvindicated; a pilot check "
             "should have caught this before the map was built")

    summary = {
        "lines": len(records),
        "rows": len({r["id"] for r in records}),
        "lessons": len({r["lesson"] for r in records}),
        "grade8_rows_in_pool": len(rows),
        "routes": dict(routes),
        "clusters": dict(Counter(r["cluster"] for r in records)),
        "sha256": hashlib.sha256(payload).hexdigest(),
        "pool_map_sha256": hashlib.sha256(
            POOL_MAP.read_bytes()).hexdigest(),
        "pilot_modules": sorted(p.name for p in PILOT_DIR.glob("g8_*.pl")),
    }
    return payload, summary


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true",
                        help="rebuild and compare without writing")
    parser.add_argument("--output", type=Path, default=OUTPUT)
    args = parser.parse_args()

    payload, summary = build()

    if args.check:
        if not args.output.is_file():
            fail(f"missing map: {args.output}")
        current = args.output.read_bytes()
        if current != payload:
            fail(f"{args.output.name} is stale; rerun without --check "
                 f"(on disk {hashlib.sha256(current).hexdigest()[:16]}, "
                 f"rebuilt {summary['sha256'][:16]})")
        print(f"build_g8_row_machine_map.py --check: fresh "
              f"({summary['lines']} lines, {summary['rows']} rows, "
              f"{summary['lessons']} lessons, sha {summary['sha256'][:16]})")
        return 0

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(payload)
    print(json.dumps(summary, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
