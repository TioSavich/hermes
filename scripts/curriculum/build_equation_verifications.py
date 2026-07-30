#!/usr/bin/env python3
"""Generate the equation-verification ledger from the guides and the checkers.

The extraction and the gates live in ``equation_verification.py``; this script
supplies the corpus, runs the one SWI-Prolog batch that adjudicates every claim
and every automaton pair, and writes the result.  ``--check`` compares without
writing, which is what says a committed ledger still matches the corpus and the
checkers it was read from.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "curriculum"))

import compile_action_mappings as compiler  # noqa: E402
import equation_verification as eqv  # noqa: E402

OUTPUT = ROOT / "scripts" / "curriculum" / "lesson_equation_verifications.json"


def registry_pairs(root: pathlib.Path) -> dict[tuple[str, str], list[dict]]:
    """Read the finite productive/deformation pair registry, keyed by productive."""
    goal = (
        "use_module(strategies('math/action_automata_registry')),"
        "forall(action_automata_registry:action_automaton_pair(Op,P,D,F),"
        "format('PAIR\\t~w\\t~w\\t~w\\t~w~n',[Op,P,D,F])),halt"
    )
    result = subprocess.run(
        ["swipl", "-q", "-l", "paths.pl", "-g", goal],
        cwd=root,
        text=True,
        capture_output=True,
        check=True,
    )
    index: dict[tuple[str, str], list[dict]] = {}
    for line in result.stdout.splitlines():
        if not line.startswith("PAIR\t"):
            continue
        operation, productive, deformation, family = line.split("\t")[1:]
        index.setdefault((operation, productive), []).append({
            "productive": productive,
            "deformation": deformation,
            "family": family,
        })
    if not index:
        raise SystemExit("action automaton pair registry returned no rows")
    return index


def corpus(root: pathlib.Path):
    """The spans, the sidecar join, and the accepted lesson attachments."""
    rules = json.loads(compiler.DEFAULT_RULES.read_text(encoding="utf-8"))
    docs = compiler.read_teacher_guides(root)
    explicit = compiler.read_explicit_mappings(root)
    mappings = compiler.compile_rule_mappings(docs, rules, explicit)
    mappings += compiler.compile_scope_batches(
        rules, explicit, compiler.read_scope_titles(root)
    )
    mappings = sorted(set(mappings))
    attachments = {code: set(rows) for code, rows in explicit.items()}
    for mapping in mappings:
        attachments.setdefault(mapping.code, set()).add(
            (mapping.operation, mapping.kind)
        )
    spans = compiler.extract_student_task_spans(docs)
    recovered = {
        (span.code, span.position): span
        for span in compiler.read_recovered_task_spans(root, spans)
    }
    return docs, spans, recovered, attachments


def build(root: pathlib.Path) -> dict:
    docs, spans, recovered, attachments = corpus(root)
    readings = eqv.read_span_readings(
        root,
        spans,
        recovered,
        {doc.code: doc for doc in docs},
        attachments,
        compiler._next_response_range,
    )
    eqv.adjudicate(root, readings, attachments, registry_pairs(root))
    return eqv.render_ledger(readings)


def render(payload: dict) -> str:
    return json.dumps(payload, indent=1, ensure_ascii=False, sort_keys=True) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--output", type=pathlib.Path, default=OUTPUT)
    args = parser.parse_args()

    payload = build(ROOT)
    rendered = render(payload)
    if args.check:
        current = (
            args.output.read_text(encoding="utf-8") if args.output.exists() else ""
        )
        if current != rendered:
            print(
                "stale equation-verification ledger: run "
                "scripts/curriculum/build_equation_verifications.py",
                file=sys.stderr,
            )
            return 1
    else:
        args.output.write_text(rendered, encoding="utf-8")
    summary = payload["summary"]
    print(
        "equation_verifications "
        + " ".join(f"{key}={value}" for key, value in sorted(summary.items()))
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
