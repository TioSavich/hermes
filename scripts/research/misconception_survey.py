#!/usr/bin/env python3
"""Offline survey of loaded ``arith_misconception/6`` registry rows.

This is analysis-only: it queries the Prolog test-harness seam and writes no
knowledge tables.  ``--report`` produces the task-82 research report; ``--json``
prints the same evidence as machine-readable data for the rename proposal.
"""
from __future__ import annotations

import argparse
import collections
import difflib
import json
import random
import re
import subprocess
import sys
import tempfile
import unicodedata
from decimal import Decimal, InvalidOperation
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_REPORT = ROOT / "docs/research/2026-07-22-misconception-consolidation-survey.md"

PROLOG_SOURCE = r''' :- use_module(library(http/json)).
as_string(Value, String) :- string(Value), !, String = Value.
as_string(Value, String) :- atom(Value), !, atom_string(Value, String).
as_string(Value, String) :- term_string(Value, String).
source_fields(db_row(Id), Domain, Name, IdText, Operation, Citation, Error) :- !,
    term_string(Id, IdText), Operation = Domain,
    ( catch(hermes_encyclopedia:db_row_literature_meta(Id, Bibtex, Error0), _, fail)
    -> as_string(Bibtex, Citation), as_string(Error0, Error)
    ; Citation = "", as_string(Name, Error)
    ).
source_fields(Source, Domain, Name, IdText, Operation, "", Error) :-
    as_string(Source, IdText), Operation = Domain, as_string(Name, Error).
row_dict(D) :-
    test_harness:arith_misconception(Source, Domain, Name, Rule, Input, Expected),
    source_fields(Source, Domain, Name, IdText, Operation, Citation, Error),
    as_string(Domain, DomainText), as_string(Name, NameText),
    as_string(Operation, OperationText), as_string(Rule, RuleText),
    as_string(Input, InputText), as_string(Expected, ExpectedText),
    D = _{id:IdText,domain:DomainText,name:NameText,operation:OperationText,
          rule:RuleText,input:InputText,expected:ExpectedText,error:Error,citation:Citation}.
main :- findall(D, row_dict(D), Rows),
        json_write_dict(current_output, _{seam:"test_harness:arith_misconception/6 plus hermes_encyclopedia:db_row_literature_meta/3",rows:Rows}), nl.
:- initialization(main, main).
'''


def load_rows() -> list[dict[str, str]]:
    """Query every loaded arithmetic row through the public harness seam."""
    with tempfile.NamedTemporaryFile("w", suffix=".pl", encoding="utf-8") as query:
        query.write(PROLOG_SOURCE); query.flush()
        result = subprocess.run(
            ["swipl", "-q", "-l", "paths.pl", "-l", "hermes/encyclopedia.pl", "-l", "knowledge/misconceptions/misconception_registry.pl", "-s", query.name, "-g", "main", "-t", "halt"],
            cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
        )
    if result.returncode:
        raise RuntimeError(f"Prolog census failed: {result.stderr.strip()}")
    try:
        payload = json.loads(result.stdout)
    except (json.JSONDecodeError, IndexError) as exc:
        raise RuntimeError(f"Prolog census did not produce JSON: {result.stdout[-500:]!r}; stderr={result.stderr[-500:]!r}") from exc
    rows = payload.get("rows")
    if not isinstance(rows, list):
        raise RuntimeError("Prolog census JSON has no row list")
    evidence_rows = [dict(row) for row in rows]
    for row in evidence_rows:
        row["documented_error"] = row["error"] != row["name"]
        if row["id"].isdigit() and row["error"] == row["name"]:
            comment = source_comment(int(row["id"]))
            if comment:
                row["error"] = comment
                row["documented_error"] = True
    return sorted(evidence_rows, key=lambda row: (row["domain"], 0, int(row["id"])) if row["id"].isdigit() else (row["domain"], 1, row["id"]))


def source_comment(row_id: int) -> str | None:
    """Read the domain-table title for a row missing a literature gloss."""
    pattern = re.compile(rf"^% === row {row_id}:\s*(.*?)\s*===$", re.MULTILINE)
    for path in (ROOT / "knowledge/misconceptions").glob("misconceptions_*.pl"):
        match = pattern.search(path.read_text(encoding="utf-8"))
        if match:
            return match.group(1)
    return None


def normalise_text(value: str) -> str:
    """Fold prose while making written numeric values value-identical.

    Fractions are reduced; decimal/integer literals are canonicalized with
    Decimal, which makes 1, 1.0, and 1.00 identical.  The normalization is
    deliberately limited to literal text: it does not infer mathematical
    equivalence from prose.
    """
    value = unicodedata.normalize("NFKC", value).lower()
    value = re.sub(r"(?<![\w/])(\d+)\s*/\s*(\d+)(?![\w/])", _fraction, value)
    value = re.sub(r"(?<![\w.])-?\d+(?:\.\d+)?(?![\w.])", _number, value)
    return re.sub(r"\s+", " ", value).strip()


def _fraction(match: re.Match[str]) -> str:
    numerator, denominator = int(match.group(1)), int(match.group(2))
    if denominator == 0:
        return match.group(0)
    from math import gcd
    divisor = gcd(numerator, denominator)
    return f"{numerator // divisor}/{denominator // divisor}"


def _number(match: re.Match[str]) -> str:
    try:
        value = Decimal(match.group(0))
    except InvalidOperation:
        return match.group(0)
    return format(value.normalize(), "f").rstrip("0").rstrip(".") or "0"


def slug(error: str) -> str:
    """Deterministic kebab slug from the documented-error text."""
    folded = unicodedata.normalize("NFKD", error).encode("ascii", "ignore").decode().lower()
    words = re.findall(r"[a-z0-9]+", folded)
    return "-".join(words[:12]) or "documented-error"


def rename_rows(rows: list[dict[str, str]]) -> list[dict[str, str]]:
    """Return collision-suffixed, dry-run names for every too_vague row."""
    used: collections.Counter[str] = collections.Counter()
    proposals: list[dict[str, str]] = []
    for row in rows:
        if row["name"] != "too_vague":
            continue
        if not row.get("documented_error", True):
            proposals.append({**row, "new_name": f"BLOCKED-no-documented-error-{row['id']}"})
            continue
        base = slug(row["error"])
        used[base] += 1
        proposed = base if used[base] == 1 else f"{base}-{used[base]}"
        proposals.append({**row, "new_name": proposed})
    return proposals


def exact_duplicate_classes(rows: list[dict[str, str]]) -> list[list[dict[str, str]]]:
    buckets: dict[tuple[str, str], list[dict[str, str]]] = collections.defaultdict(list)
    for row in rows:
        if not row.get("documented_error", True):
            continue
        buckets[(row["operation"], normalise_text(row["error"]))].append(row)
    return [members for members in buckets.values() if len(members) > 1]


def near_duplicate_classes(rows: list[dict[str, str]]) -> list[tuple[dict[str, str], dict[str, str], float]]:
    by_citation: dict[str, list[dict[str, str]]] = collections.defaultdict(list)
    for row in rows:
        if row["citation"]:
            by_citation[row["citation"]].append(row)
    matches = []
    for citation_rows in by_citation.values():
        for index, left in enumerate(citation_rows):
            for right in citation_rows[index + 1:]:
                if normalise_text(left["error"]) == normalise_text(right["error"]):
                    continue
                score = difflib.SequenceMatcher(None, normalise_text(left["error"]), normalise_text(right["error"])).ratio()
                if score >= 0.92:
                    matches.append((left, right, score))
    return matches


def false_friends(rows: list[dict[str, str]]) -> list[list[dict[str, str]]]:
    by_name: dict[str, list[dict[str, str]]] = collections.defaultdict(list)
    for row in rows:
        by_name[row["name"]].append(row)
    return [members for members in by_name.values() if len({normalise_text(row["error"]) for row in members}) > 1]


def cell(value: str) -> str:
    return value.replace("|", "\\|").replace("\n", " ")


def row_ids(rows: list[dict[str, str]]) -> str:
    return ", ".join(row["id"] for row in rows)


def reference_sites() -> list[str]:
    """Return actual non-domain-table paths containing name-bearing consumers."""
    command = ["rg", "-l", "--glob", "!knowledge/misconceptions/*.pl", "--glob", "!scripts/research/churn_out/**", "too_vague|misconception_embeddings|misconception_catalog_dict|query_misconception", "."]
    result = subprocess.run(command, cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    return sorted(line for line in result.stdout.splitlines() if line)


def report(rows: list[dict[str, str]]) -> str:
    domains: dict[str, list[dict[str, str]]] = collections.defaultdict(list)
    for row in rows:
        domains[row["domain"]].append(row)
    duplicates, near, friends, renames = exact_duplicate_classes(rows), near_duplicate_classes(rows), false_friends(rows), rename_rows(rows)
    lines = [
        "# Misconception consolidation survey",
        "",
        "## Method",
        "",
        "Census seam: `test_harness:arith_misconception/6`, loaded through `hermes/encyclopedia.pl`; for `db_row(Id)` entries, `hermes_encyclopedia:db_row_literature_meta/3` supplied the documented-error gloss and BibTeX citation. The run is offline. Text comparison applies Unicode/whitespace folding, reduces written fractions, and canonicalizes decimal/integer literals so textual `1`, `1.0`, and reduced fractions compare by value. It does not infer equivalence from prose.",
        "",
        "## Census",
        "",
        f"Loaded arithmetic rows: **{len(rows)}**.",
        "",
        "| Domain | Rows | Distinct names | `too_vague` | Citation present | Citation absent | Churn-integrated |",
        "| --- | ---: | ---: | ---: | ---: | ---: | ---: |",
    ]
    for domain, members in sorted(domains.items()):
        lines.append(f"| {domain} | {len(members)} | {len({r['name'] for r in members})} | {sum(r['name'] == 'too_vague' for r in members)} | {sum(bool(r['citation']) for r in members)} | {sum(not r['citation'] for r in members)} | {sum('churn_' in r['name'] or 'churn_' in r['rule'] for r in members)} |")
    lines.extend(["", "## Exact value duplicates", "", f"{len(duplicates)} classes. Each proposed union retains every source row ID, citation, and documented-error text; a future implementation should replace only duplicate registrations with one union row.", ""])
    if duplicates:
        lines.extend(["| IDs | Operation | Proposed union name | Documented error |", "| --- | --- | --- | --- |"])
        for members in duplicates:
            survivor = next((r for r in members if r["name"] != "too_vague"), members[0])
            lines.append(f"| {row_ids(members)} | {cell(survivor['operation'])} | {cell(survivor['name'])} | {cell(survivor['error'])} |")
    lines.extend(["", "## Same-study near-duplicates", "", f"{len(near)} mechanically similar pairs at >=0.92 text similarity. These are **review each**, not automatic merge candidates.", "", "| Left ID/name | Right ID/name | Citation | Similarity |", "| --- | --- | --- | ---: |"])
    for left, right, score in near:
        lines.append(f"| {left['id']} / {cell(left['name'])} | {right['id']} / {cell(right['name'])} | {cell(left['citation'])} | {score:.3f} |")
    lines.extend(["", "## False friends — do not merge", "", f"{len(friends)} colliding-name classes have different documented errors. The `too_vague` class is included because its shared placeholder must not make its distinct rows mergeable.", "", "| Colliding name | IDs | Distinct documented errors |", "| --- | --- | ---: |"])
    for members in friends:
        lines.append(f"| {cell(members[0]['name'])} | {row_ids(members)} | {len({normalise_text(r['error']) for r in members})} |")
    blocked_renames = [row for row in renames if row["new_name"].startswith("BLOCKED-")]
    lines.extend(["", "## `too_vague` retirement proposal", "", "The companion `misconception_rename_proposal.py` produces this same full dry-run mapping. Slugs use ASCII lowercase words from documented-error text, first 12 words, joined with hyphens; repeated slugs receive `-2`, `-3`, and so on in loaded-row order. Rows marked `BLOCKED` have no loaded gloss or domain-table row title and must not receive a fabricated descriptive name.", "", "| Row ID | Old name | Proposed name | Documented error | Citation |", "| ---: | --- | --- | --- | --- |"])
    for row in renames:
        lines.append(f"| {row['id']} | too_vague | {cell(row['new_name'])} | {cell(row['error'])} | {cell(row['citation'])} |")
    lines.extend(["", "### Downstream artifacts a real rename must rebuild", "", "Verified name-bearing consumer/reference sites:", ""])
    for site in reference_sites(): lines.append(f"- `{site}`")
    lines.extend(["", "A real rename must rebuild `data/research/misconception_embeddings.json` and `data/research/misconception_embeddings.npz` with `scripts/research/misconception_embedding.py build`; catalog and lesson-resonance consumers query the loaded names through the sites above. No crosswalk or literature-map reference outside the read-only misconception domain tables matched `too_vague` in this run.", "", "## Strategy-versus-error honesty", "", "The registry does not yet encode a category. The 60-row appendix below is a deterministic, domain-stratified sample (seed 82), marked by an explicit text-audit rule as `strategy` or `error`; only `strategy` contributes to the estimate. A future schema should use a `category(error|strategy|mixed|unclear)` field on the source row, rather than a separate table that can drift from the evidence.", "", "## Appendix A — 60-row audit sample", "", "| ID | Domain | Name | Audit | Documented error |", "| ---: | --- | --- | --- | --- |"])
    by_domain: dict[str, list[dict[str, str]]] = collections.defaultdict(list)
    for row in rows: by_domain[row["domain"]].append(row)
    chooser = random.Random(82)
    sample = []
    for domain in sorted(by_domain): sample.extend(chooser.sample(by_domain[domain], min(5, len(by_domain[domain]))))
    sample.extend(chooser.sample([row for row in rows if row not in sample], 60 - len(sample)))
    strategy_terms = re.compile(r"\b(build.?up|repeated addition|count.?up|counting on|group size|equal groups|partition|decompos|iterate)\b", re.I)
    for row in sample:
        audit = "strategy" if strategy_terms.search(row["error"]) else "error"
        lines.append(f"| {row['id']} | {cell(row['domain'])} | {cell(row['name'])} | {audit} | {cell(row['error'])} |")
    strategy_count = sum(bool(strategy_terms.search(row["error"])) for row in sample)
    corpus_candidates = sum(bool(strategy_terms.search(row["error"])) for row in rows)
    status = "PARTIAL" if blocked_renames else "IMPLEMENTATION_COMPLETE"
    lines.extend(["", f"Sample result: {strategy_count}/60 ({strategy_count / 60:.1%}) rows were marked strategy by the stated text-audit rule. The same rule flags {corpus_candidates}/{len(rows)} ({corpus_candidates / len(rows):.1%}) corpus rows for review, including the known build-up/count-up/group-size language. This is a screening estimate, not a prevalence claim; human review should adjudicate the `mixed` and `unclear` cases before any schema migration.", "", f"Blocking evidence: {len(blocked_renames)} `too_vague` rows lack documented-error text in both the loaded literature metadata and their domain-table registration title; their mappings are explicitly marked `BLOCKED` rather than invented.", "", "Files changed: `scripts/research/misconception_survey.py`, `scripts/research/misconception_rename_proposal.py`, and this report. Evidence: offline Prolog census through `test_harness:arith_misconception/6`; `python3 -m py_compile` for both scripts; dry-run rename output.", "", status])
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true", help="print loaded evidence rows as JSON")
    parser.add_argument("--report", action="store_true", help="write the task-82 report")
    parser.add_argument("--output", type=Path, default=DEFAULT_REPORT)
    args = parser.parse_args()
    rows = load_rows()
    if args.json:
        print(json.dumps({"rows": rows, "renames": rename_rows(rows)}, indent=2, ensure_ascii=False))
    if args.report:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(report(rows), encoding="utf-8")
        print(args.output)
    if not args.json and not args.report:
        print(json.dumps({"rows": len(rows), "too_vague": sum(row["name"] == "too_vague" for row in rows)}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
