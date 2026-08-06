#!/usr/bin/env python3
"""Check metaphor-machine registration, grounding, and seam kinds."""

from __future__ import annotations

import json
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
REGISTRY = ROOT / "knowledge/strategies/abstraction/metaphor_seam_registry.pl"
HEADER_KIND_RE = re.compile(r"^\s*\*\s+-\s+`([^`]+)`:", re.MULTILINE)
YEAR_RE = re.compile(r"\b(?:19|20)\d{2}\b")


def fail(message: str) -> None:
    print(f"FAIL metaphor seam registry: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_rows() -> list[dict[str, object]]:
    query = (
        "use_module(library(http/json)),"
        "load_files('paths.pl',[silent(true)]),"
        "use_module(math(action_automata_registry)),"
        "use_module(formalization(grounding_metaphors)),"
        "use_module(knowledge/strategies/abstraction/metaphor_seam_registry),"
        "forall(metaphor_seam_registry:metaphor_operating(Family/Kind,Metaphor,Evidence),"
        "(term_string(Evidence,EvidenceText,[quoted(true)]),"
        "(action_automata_registry:action_automaton_signature(Family,Kind,_,_)->MachineRegistered=true;MachineRegistered=false),"
        "(grounding_metaphors:grounding_metaphor_definition(Metaphor,_,_,_)->MetaphorGrounded=true;MetaphorGrounded=false),"
        "(once((sub_term(Citation,Evidence),compound(Citation),functor(Citation,citation,_)))->HasCitation=true;HasCitation=false),"
        "json_write_dict(current_output,_{record:operating,family:Family,kind:Kind,metaphor:Metaphor,"
        "machine_registered:MachineRegistered,metaphor_grounded:MetaphorGrounded,"
        "has_citation:HasCitation,evidence:EvidenceText},[width(0)]),nl)),"
        "forall(metaphor_seam_registry:metaphor_seam(Context,Retiring,Succeeding,SeamKind,Evidence),"
        "(term_string(Context,ContextText,[quoted(true)]),"
        "term_string(Retiring,RetiringText,[quoted(true)]),"
        "term_string(Succeeding,SucceedingText,[quoted(true)]),"
        "term_string(SeamKind,SeamKindText,[quoted(true)]),"
        "term_string(Evidence,EvidenceText,[quoted(true)]),"
        "functor(SeamKind,KindName,KindArity),"
        "(SeamKind=seam_kind(KindValue)->format(string(KindSignature),'seam_kind(~w)',[KindValue]),"
        "SuccessorRequired=true;format(string(KindSignature),'~w/~w',[KindName,KindArity]),SuccessorRequired=false),"
        "(grounding_metaphors:grounding_metaphor_definition(Retiring,_,_,_)->RetiringGrounded=true;RetiringGrounded=false),"
        "(SuccessorRequired==true->"
        "(grounding_metaphors:grounding_metaphor_definition(Succeeding,_,_,_)->SucceedingGrounded=true;SucceedingGrounded=false);"
        "SucceedingGrounded=true),"
        "(once((sub_term(Citation,Evidence),compound(Citation),functor(Citation,citation,_)))->HasCitation=true;HasCitation=false),"
        "json_write_dict(current_output,_{record:seam,context:ContextText,retiring:RetiringText,"
        "succeeding:SucceedingText,seam_kind:SeamKindText,seam_kind_signature:KindSignature,"
        "retiring_grounded:RetiringGrounded,successor_required:SuccessorRequired,"
        "succeeding_grounded:SucceedingGrounded,has_citation:HasCitation,evidence:EvidenceText},[width(0)]),nl))"
    )
    completed = subprocess.run(
        ["swipl", "-q", "-g", query, "-t", "halt"],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        detail = completed.stderr.strip() or completed.stdout.strip()
        fail(f"registries did not load cleanly: {detail}")
    if completed.stderr.strip():
        fail(f"registries emitted load warnings: {completed.stderr.strip()}")
    try:
        return [json.loads(line) for line in completed.stdout.splitlines() if line]
    except json.JSONDecodeError as exc:
        fail(f"registry serialization was not JSON: {exc}")


def cited(row: dict[str, object]) -> bool:
    return bool(row.get("has_citation")) or bool(YEAR_RE.search(str(row.get("evidence", ""))))


def repeated(values: list[tuple[str, ...]]) -> list[tuple[str, ...]]:
    return [value for value, count in Counter(values).items() if count > 1]


def main() -> int:
    source = REGISTRY.read_text(encoding="utf-8")
    declared_kinds = set(HEADER_KIND_RE.findall(source))
    if not declared_kinds:
        fail("the registry header declares no seam kinds")

    rows = load_rows()
    operating = [row for row in rows if row.get("record") == "operating"]
    seams = [row for row in rows if row.get("record") == "seam"]
    if not operating:
        fail("the registry has no metaphor_operating/3 rows")
    if not seams:
        fail("the registry has no metaphor_seam/5 rows")

    operating_keys = [
        (str(row["family"]), str(row["kind"]), str(row["metaphor"]))
        for row in operating
    ]
    duplicates = repeated(operating_keys)
    if duplicates:
        fail(f"duplicate metaphor_operating keys: {duplicates[:3]}")

    seam_keys = [
        (
            str(row["context"]),
            str(row["retiring"]),
            str(row["succeeding"]),
            str(row["seam_kind"]),
        )
        for row in seams
    ]
    duplicates = repeated(seam_keys)
    if duplicates:
        fail(f"duplicate metaphor_seam keys: {duplicates[:3]}")

    for row in operating:
        machine = f"{row['family']}/{row['kind']}"
        if not row.get("machine_registered"):
            fail(f"metaphor_operating machine is not registered: {machine}")
        if not row.get("metaphor_grounded") and not cited(row):
            fail(
                f"metaphor {row['metaphor']} for {machine} is neither grounded "
                "nor supported by a literature citation"
            )

    used_kinds = {str(row["seam_kind_signature"]) for row in seams}
    undeclared = used_kinds - declared_kinds
    if undeclared:
        fail(f"seam kinds are not defined in the registry header: {sorted(undeclared)}")

    for row in seams:
        if not row.get("retiring_grounded") and not cited(row):
            fail(
                f"retiring metaphor {row['retiring']} at {row['context']} is "
                "neither grounded nor supported by a literature citation"
            )
        if (
            row.get("successor_required")
            and not row.get("succeeding_grounded")
            and not cited(row)
        ):
            fail(
                f"succeeding metaphor {row['succeeding']} at {row['context']} is "
                "neither grounded nor supported by a literature citation"
            )

    print(
        f"PASS metaphor seam registry: {len(operating)} operating rows resolve "
        f"to registered machines; {len(seams)} seams use "
        f"{', '.join(sorted(used_kinds))}; metaphor atoms are grounded or cited"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

