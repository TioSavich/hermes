#!/usr/bin/env python3
"""Propose and source-gate the incompatibility triple for a dense error slice.

Three columns of `error_instances` were designed to carry a Brandomian
incompatibility triple and stand empty: `student_rule`, `valid_domain`,
`incompatible_with`. This script drafts them one row at a time through REALLMS
and refuses anything the row's own text does not carry.

Scope is deliberately dense rather than broad. Emergence needs the same atoms to
recur, so the slice is one topic with enough rows to repeat itself. The default
slice is fraction comparison; `--slice` names another.

Nothing here touches the database. Accepted proposals land in a gitignored
review directory and a human reads them before
`scripts/research/apply_incompatibility_triples.py` writes anything.

The standard each column must meet is stated in
docs/research/2026-07-27-no-saying-vocabularies-and-incompatibility.md §5.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import re
import sqlite3
import ssl
import sys
import time
from collections import Counter
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable

ROOT = Path(__file__).resolve().parents[2]
DB = ROOT / "data" / "research" / "research_shared.db"
LLM_PATH = ROOT / "hermes" / "app" / "llm.py"
DEFAULT_OUTPUT = ROOT / "scripts" / "research" / "incompatibility_triples_out"

# Bumped whenever SYSTEM_PROMPT or the slice-independent part of the gate changes,
# so a checkpoint written under an older standard is never silently mixed with a
# newer one. The per-slice gate data below is carried in the slice spec instead,
# because adding a slice must not restate the standard the earlier slices were
# coded under: fraction_comparison's checkpoints still answer to exactly the gate
# that accepted them.
PROMPT_VERSION = 2

STATUS_VALUES = {"stated", "inferred", "none_found"}

REQUIRED_FIELDS = {
    "student_rule",
    "rule_slug",
    "licensed_consequence",
    "consequence_slug",
    "valid_domain",
    "valid_domain_status",
    "divergence_context",
    "divergence_slug",
    "incompatible_with",
    "evidence",
}

# A rule is a total operation on a stated input class. These are the words a
# deficiency description uses and an operation does not, so their presence in
# `student_rule` is the mechanical form of the §5 test.
DEFICIENCY_WORDS = (
    "struggl", "fail", "lack", "difficult", "confus", "unable", "cannot",
    "misconcept", "incorrect", "erroneous", "mistaken", "wrong", "flaw",
    "deficien", "poor", "weak", "does not understand", "do not understand",
    "misunderstand", "inappropriat", "improper reasoning", "naive", "naïve",
)

# A rule states what the student does on every input of its class, so a
# frequency hedge means the coder recorded a tendency instead of an operation.
HEDGE_WORDS = ("sometimes", "often", "tend to", "may ", "might ", "usually", "some students")

SLUG_RE = re.compile(r"^[a-z][a-z0-9_]{2,63}$")
# A numeral pair written out is an instance where the standard asks for a class.
FRACTION_LITERAL_RE = re.compile(r"\d+\s*/\s*\d+")
DECIMAL_LITERAL_RE = re.compile(r"\d*\.\d+")

# A divergence class naming the whole input class says the rule fails
# everywhere, which contradicts having a valid domain. Refusing these keeps the
# two halves of the coding answerable to each other. The names are per slice
# because the whole input class is a different class in each.
FRACTION_UNRESTRICTED = frozenset(
    {
        "fractions", "pairs of fractions", "all pairs of fractions", "all fractions",
        "fraction comparison", "comparing fractions", "any pair of fractions",
        "fraction pairs", "all fraction pairs",
    }
)
# Only whole-domain names are listed. An operation-scoped name such as "decimal
# addition" is the whole input class for an addition rule and a proper subclass
# for a comparison rule, and the gate reads one row at a time without knowing
# which; those go to review rather than to a mechanical refusal.
DECIMAL_UNRESTRICTED = frozenset(
    {
        "decimals", "all decimals", "any decimal", "decimal numbers",
        "all decimal numbers", "decimal numerals", "all decimal numerals",
        "pairs of decimals", "all pairs of decimals", "any pair of decimals",
        "decimal pairs", "all decimal pairs", "decimal comparison",
        "comparing decimals", "decimal arithmetic", "decimal operations",
        "all decimal operations", "operations with decimals",
        "operations on decimals",
    }
)

SLICES: dict[str, dict[str, Any]] = {
    "fraction_comparison": {
        "domain": "fraction",
        "topics": ("fraction comparison", "comparing fractions"),
        "label": "fraction comparison",
        "unrestricted": FRACTION_UNRESTRICTED,
        "instance_patterns": (FRACTION_LITERAL_RE,),
    },
    # The decimal slice is the whole domain rather than a topic list. Topic
    # spelling in this corpus is unreliable — twenty decimal topics carry two
    # capitalisations of one name, and `mathematical_topic LIKE '%decimal%'`
    # reads 143 rows across six domains, which is a different set again. The
    # domain column carries one spelling and is the only stable handle.
    "decimal": {
        "domain": "decimal",
        "topics": None,
        "label": "decimal (whole domain)",
        "unrestricted": DECIMAL_UNRESTRICTED,
        "instance_patterns": (FRACTION_LITERAL_RE, DECIMAL_LITERAL_RE),
    },
    "whole_number_subtraction": {
        "domain": "whole_number",
        "topics": ("subtraction",),
        "label": "whole-number subtraction",
        "unrestricted": frozenset(
            {"whole numbers", "all whole numbers", "whole-number subtraction",
             "subtraction", "any subtraction", "all subtractions"}
        ),
        "instance_patterns": (),
    },
}


SYSTEM_PROMPT = """\
You code one research-corpus error record into a Brandomian incompatibility triple.

A triple has three parts and a provenance note.

1. student_rule — a TOTAL OPERATION on a STATED INPUT CLASS, written from the
   student's side, independent of the task that elicited it. The test a reader
   applies: could they run it on an input the record never mentions?
     passes: "Order two fractions by the additive difference between
              denominator and numerator; the smaller difference is the smaller
              fraction."
     passes: "Add two fractions by adding numerators and adding denominators."
     fails:  "Struggles with improper fractions."  (a deficiency, not an operation)
     fails:  "Sometimes ignores the denominator."  (a tendency, not an operation)
   Never use evaluative words (incorrect, wrong, fails, misconception) inside
   the rule. The rule is what the student does, stated so it can be run.

2. valid_domain — the INPUT CLASS on which the rule agrees with the sanctioned
   one. Stated as a CLASS, never as an example: "pairs with equal numerators",
   not "1/3 and 1/4". Check the agreement: name a class only if you can see that
   running the rule on every input in it returns what the sanctioned comparison
   returns. Do not name a class you have not checked, and do not reach for
   "fractions between 0 and 1" or similar unless the operation really turns on
   that boundary.
   Many rules in this corpus are whole-number rules carried into fractions. Such
   a rule has a valid domain and it is the setting the rule came from: "more is
   larger" holds when counting collections of same-sized objects, "more digits
   is larger" holds for natural-number numerals. Name that setting; that is what
   the terms met-before and natural-number bias record.
   A rule that returns the sanctioned answer on some inputs and the wrong one on
   others HAS a valid domain: the class where the two agree. Work out that class
   from the operation and state it concretely. A rule ordering fractions by the
   difference between denominator and numerator agrees with the sanctioned order
   on every pair with equal numerators and on every pair with equal
   denominators, because on those the difference order and the fraction order
   coincide; that is the class, and its status is "inferred".
   Reserve "none_found" for a rule that agrees with the sanctioned one on no
   class you can name — a rule that inverts the sanctioned answer everywhere,
   for instance. Then valid_domain and divergence_context are both null. An
   empty domain of validity is a real result and is preferred to an invented
   one, but so is a domain you can check.
   valid_domain_status is "stated" when the record or the named mathematics
   supplies the class outright, "inferred" when you derived it from the rule.

3. divergence_context — the input CLASS where what the rule licenses fails.
   This is the third element of the triple and it must be a class, not a case.

Provenance: incompatible_with — the COMMITMENT the rule conflicts with, named as
somebody's commitment together with the context in which it is held. Write it in
the form "<holder>'s commitment, in <context>, that <content>". Example: "the
mathematical community's commitment, in rational-number comparison, that order
is fixed by the multiplicative relation of part to whole rather than by the
additive distance between the two numerals." Naming the holder is what makes
this a normative relation rather than a comparison against a bare fact.

Also supply licensed_consequence: what the rule yields on its valid domain,
stated as a claim (for gap thinking: "gap order is fraction order").

Slugs (rule_slug, consequence_slug, divergence_slug) are lower_snake_case names
for the three elements, 3-64 characters. Name the OPERATION, not the record, so
that two records following the same rule get the same slug. The consequence and
divergence slugs must name the QUANTITY the rule works with —
gap_order_is_fraction_order, denominator_order_is_fraction_order,
component_order_inverts_on_unit_fractions — never a generic
rule_agrees / rule_fails.

Evidence: quote VERBATIM. evidence.description_span must be an exact substring
of the record's description. evidence.example_span must be an exact substring of
the record's example, or null when the record has no example. Do not paraphrase
inside these spans; the gate checks them character by character.

Answer with a single JSON object and nothing else:

{"student_rule": "...", "rule_slug": "...", "licensed_consequence": "...",
 "consequence_slug": "...", "valid_domain": "..." or null,
 "valid_domain_status": "stated" | "inferred" | "none_found",
 "divergence_context": "..." or null, "divergence_slug": "..." or null,
 "incompatible_with": "...",
 "evidence": {"description_span": "...", "example_span": "..." or null}}

If the record does not state an operation you could run — if it reports only
that something was hard, or reports a teacher's judgement rather than a rule —
answer with the single line:

ABSTAIN: <one sentence saying what the record withholds>
"""


@dataclass(frozen=True)
class Row:
    row_id: int
    description: str
    example: str
    topic: str
    subtopic: str
    vocabulary: str
    task_context: str
    population: str
    orientation: str
    locus: str
    article: str
    authors: str
    year: str


Transport = Callable[[Row, list[dict[str, str]], int], str]


def load_llm_module() -> Any:
    spec = importlib.util.spec_from_file_location("hermes_reallms", LLM_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import {LLM_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def slice_sql(spec: dict[str, Any]) -> tuple[str, tuple[Any, ...]]:
    """Return the WHERE clause and parameters that define a slice.

    Topic matching is case-insensitive and trimmed. The fraction pilot lost a
    fourth spelling of one topic to a case-sensitive comparison, so the
    comparison is folded here rather than at each call site.
    """
    clause = "lower(trim(e.mathematical_domain)) = ?"
    parameters: list[Any] = [spec["domain"]]
    if spec["topics"] is not None:
        placeholders = ", ".join("?" for _ in spec["topics"])
        clause += f" AND lower(trim(e.mathematical_topic)) IN ({placeholders})"
        parameters.extend(spec["topics"])
    return clause, tuple(parameters)


def fetch_rows(slice_name: str) -> list[Row]:
    spec = SLICES[slice_name]
    clause, parameters = slice_sql(spec)
    connection = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
    connection.row_factory = sqlite3.Row
    try:
        cursor = connection.execute(
            f"""
            SELECT e.id, e.error_description, e.example, e.mathematical_topic,
                   e.mathematical_subtopic, e.vocabulary_used_raw, e.task_context,
                   e.population, e.orientation, e.locus_of_attribution,
                   a.title, a.authors, a.year
              FROM error_instances e
              JOIN articles a ON a.id = e.article_id
             WHERE {clause}
             ORDER BY e.id
            """,
            parameters,
        )
        return [
            Row(
                row_id=record["id"],
                description=(record["error_description"] or "").strip(),
                example=(record["example"] or "").strip(),
                topic=(record["mathematical_topic"] or "").strip(),
                subtopic=(record["mathematical_subtopic"] or "").strip(),
                vocabulary=(record["vocabulary_used_raw"] or "").strip(),
                task_context=(record["task_context"] or "").strip(),
                population=(record["population"] or "").strip(),
                orientation=(record["orientation"] or "").strip(),
                locus=(record["locus_of_attribution"] or "").strip(),
                article=(record["title"] or "").strip(),
                authors=(record["authors"] or "").strip(),
                year=str(record["year"] or "").strip(),
            )
            for record in cursor
        ]
    finally:
        connection.close()


def build_messages(row: Row) -> list[dict[str, str]]:
    lines = [
        f"RECORD {row.row_id}",
        f"source: {row.authors} ({row.year}), {row.article}",
        f"topic: {row.topic} / {row.subtopic or 'no subtopic recorded'}",
        f"population: {row.population or 'not recorded'}",
        "",
        "description:",
        row.description,
        "",
        "example:",
        row.example if row.example else "(the record carries no example)",
        "",
        f"vocabulary the article used: {row.vocabulary or 'not recorded'}",
        f"task context: {row.task_context or 'not recorded'}",
        "",
        "Code this record. Quote the description and example verbatim in evidence.",
    ]
    return [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": "\n".join(lines)},
    ]


def normalize(text: str) -> str:
    replacements = {
        "‘": "'", "’": "'", "“": '"', "”": '"',
        "–": "-", "—": "-", "…": "...", " ": " ",
    }
    for source, target in replacements.items():
        text = text.replace(source, target)
    return re.sub(r"\s+", " ", text).strip().lower()


def clean_response(response: str) -> str:
    """Strip fences and any deployment banner the endpoint prepends.

    Some REALLMS deployments emit a capability line ("Context length: 256K; ...")
    before the answer. That is transport noise, not a coding, so the first
    balanced JSON object in the reply is what gets read.
    """
    text = response.strip()
    if text.upper().startswith("ABSTAIN"):
        return text
    fenced = re.search(r"```[a-zA-Z]*\s*(.*?)\s*```", text, flags=re.DOTALL)
    if fenced:
        text = fenced.group(1).strip()
    if text.startswith("{"):
        return text
    start = text.find("{")
    if start == -1:
        return text
    depth = 0
    in_string = False
    escaped = False
    for index in range(start, len(text)):
        character = text[index]
        if in_string:
            if escaped:
                escaped = False
            elif character == "\\":
                escaped = True
            elif character == '"':
                in_string = False
            continue
        if character == '"':
            in_string = True
        elif character == "{":
            depth += 1
        elif character == "}":
            depth -= 1
            if depth == 0:
                return text[start : index + 1]
    return text


def parse_proposal(response: str) -> tuple[dict[str, Any] | None, str | None]:
    cleaned = clean_response(response)
    if not cleaned:
        return None, "empty response"
    abstention = next(
        (line for line in cleaned.splitlines() if line.strip().upper().startswith("ABSTAIN")),
        None,
    )
    if abstention is not None and not cleaned.startswith("{"):
        _, _, reason = abstention.partition(":")
        return None, "abstained" + (f": {reason.strip()}" if reason.strip() else "")
    try:
        payload = json.loads(cleaned)
    except json.JSONDecodeError as exc:
        return None, f"response is not JSON: {exc.msg} at line {exc.lineno} column {exc.colno}"
    if not isinstance(payload, dict):
        return None, "proposal top level is not an object"
    return payload, None


def _text_field(payload: dict[str, Any], name: str) -> str | None:
    value = payload.get(name)
    if value is None:
        return None
    if not isinstance(value, str):
        return None
    stripped = value.strip()
    return stripped or None


def gate(row: Row, payload: dict[str, Any], spec: dict[str, Any]) -> tuple[bool, str]:
    """Refuse anything the row's own text does not carry. Reasons are named.

    `spec` supplies the two checks whose content is a fact about the slice's
    input class rather than about the standard: which names denote the whole
    class, and what an instance looks like written out.
    """
    missing = sorted(REQUIRED_FIELDS - payload.keys())
    if missing:
        return False, f"missing_field: {', '.join(missing)}"

    rule = _text_field(payload, "student_rule")
    if rule is None:
        return False, "empty_student_rule"
    lowered_rule = rule.lower()
    hit = next((word for word in DEFICIENCY_WORDS if word in lowered_rule), None)
    if hit:
        return False, f"rule_states_a_deficiency: {hit!r} appears in student_rule"
    hedge = next((word for word in HEDGE_WORDS if word in lowered_rule), None)
    if hedge:
        return False, f"rule_is_a_tendency: {hedge!r} appears in student_rule"

    status = payload.get("valid_domain_status")
    if status not in STATUS_VALUES:
        return False, f"bad_status: {status!r} is not one of {sorted(STATUS_VALUES)}"
    domain = _text_field(payload, "valid_domain")
    if status == "none_found" and domain is not None:
        return False, "status_domain_mismatch: none_found carries a valid_domain"
    if status != "none_found" and domain is None:
        return False, f"status_domain_mismatch: {status} carries no valid_domain"
    if domain is not None and any(pattern.search(domain) for pattern in spec["instance_patterns"]):
        return False, "valid_domain_names_an_instance: a numeral appears where a class belongs"

    divergence = _text_field(payload, "divergence_context")
    divergence_slug = _text_field(payload, "divergence_slug")
    if status != "none_found" and (divergence is None or divergence_slug is None):
        return False, "divergence_missing: a valid domain needs a context where it diverges"
    if status == "none_found":
        # A rule valid nowhere has nothing for its licensed result to diverge
        # from, so a divergence here is surplus rather than a fabrication.
        # Dropping it keeps the triple's arity honest without discarding a
        # coding over a field the coder should have left empty.
        payload["divergence_context"] = None
        payload["divergence_slug"] = None

    commitment = _text_field(payload, "incompatible_with")
    if commitment is None:
        return False, "empty_incompatible_with"
    lowered_commitment = commitment.lower()
    if "'s commitment" not in lowered_commitment and "s' commitment" not in lowered_commitment:
        return False, "incompatible_with_names_no_holder: no possessive commitment holder"
    if ", in " not in lowered_commitment:
        return False, "incompatible_with_names_no_context: the holding context is unstated"

    for name in ("rule_slug", "consequence_slug"):
        slug = _text_field(payload, name)
        if slug is None or not SLUG_RE.match(slug):
            return False, f"slug_malformed: {name}={payload.get(name)!r}"
    if divergence_slug is not None and not SLUG_RE.match(divergence_slug):
        return False, f"slug_malformed: divergence_slug={divergence_slug!r}"

    if _text_field(payload, "licensed_consequence") is None:
        return False, "empty_licensed_consequence"
    consequence_slug = _text_field(payload, "consequence_slug")
    if divergence_slug is not None and divergence_slug == consequence_slug:
        # The set the relation holds has three elements. When what the rule
        # licenses and the class where it diverges carry one name, sorting
        # collapses them and the triple is a pair.
        return False, "degenerate_triple: consequence and divergence carry one name"
    if divergence is not None and normalize(divergence) in spec["unrestricted"]:
        return False, f"divergence_is_the_whole_input_class: {divergence!r}"

    evidence = payload.get("evidence")
    if not isinstance(evidence, dict):
        return False, "evidence_not_an_object"
    description_span = _text_field(evidence, "description_span")
    if description_span is None:
        return False, "evidence_missing_description_span"
    if normalize(description_span) not in normalize(row.description):
        return False, "description_span_not_verbatim"
    example_span = _text_field(evidence, "example_span")
    if row.example:
        if example_span is None:
            return False, "evidence_missing_example_span"
        if normalize(example_span) not in normalize(row.example):
            return False, "example_span_not_verbatim"
    elif example_span is not None:
        return False, "example_span_supplied_for_a_record_with_no_example"

    return True, "accepted by the source gate"


def atomic_write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    temporary.replace(path)


def checkpoint_path(output_dir: Path, row_id: int) -> Path:
    return output_dir / "checkpoints" / f"{row_id}.json"


def reallms_transport(llm: Any, client: dict[str, Any], timeout: int) -> Transport:
    def transport(_row: Row, messages: list[dict[str, str]], _index: int) -> str:
        return llm.call_api_messages(
            messages,
            api_key=client["api_key"],
            api_url=client["api_url"],
            model=client["model"],
            ssl_ctx=client["ssl_ctx"],
            retries=3,
            timeout=timeout,
            fail_on_error=False,
        )

    return transport


def run(arguments: argparse.Namespace) -> int:
    spec = SLICES[arguments.slice]
    rows = fetch_rows(arguments.slice)
    if arguments.limit:
        rows = rows[: arguments.limit]
    # Sharding exists because one row is one API round trip and the endpoint's
    # latency varies by an order of magnitude. Shards write disjoint checkpoints,
    # so the run report is written by whichever shard finishes last and reflects
    # every checkpoint on disk.
    if arguments.shards > 1:
        rows = [row for index, row in enumerate(rows) if index % arguments.shards == arguments.shard]
    output_dir = Path(arguments.output)
    print(f"slice {arguments.slice}: {len(rows)} rows")

    transport: Transport
    model_name = "none"
    if arguments.dry_run:
        transport = lambda row, messages, index: "ABSTAIN: dry run"  # noqa: E731
    else:
        llm = load_llm_module()
        client = llm.make_client(ROOT)
        model_name = client["model"]
        transport = reallms_transport(llm, client, arguments.timeout)

    results: list[dict[str, Any]] = []
    faults: Counter[str] = Counter()
    calls = 0
    for index, row in enumerate(rows, 1):
        path = checkpoint_path(output_dir, row.row_id)
        if path.is_file() and not arguments.refresh:
            record = json.loads(path.read_text(encoding="utf-8"))
            if record.get("prompt_version") != PROMPT_VERSION:
                print(f"[{index}/{len(rows)}] {row.row_id} checkpoint predates prompt v{PROMPT_VERSION}; recoding")
                path.unlink()
            else:
                if arguments.regate and record["proposal"] is not None:
                    # The gate can gain a check after a batch has run. Re-running
                    # it over the stored proposal costs nothing and keeps the
                    # reported pass rate a rate under the gate as it now stands.
                    accepted, verdict = gate(row, record["proposal"], spec)
                    if (accepted, verdict) != (record["accepted"], record["verdict"]):
                        record["accepted"] = accepted
                        record["verdict"] = verdict
                        record["fault_kind"] = "accepted" if accepted else verdict.split(":", 1)[0]
                        record["regated"] = True
                        atomic_write_json(path, record)
                results.append(record)
                if not record["accepted"]:
                    faults[record["fault_kind"]] += 1
                print(f"[{index}/{len(rows)}] {row.row_id} checkpointed ({record['verdict']})")
                continue
        messages = build_messages(row)
        started = time.perf_counter()
        try:
            response = transport(row, messages, index)
        except Exception as exc:  # noqa: BLE001 — one row's transport failure must not end the batch
            response = ""
            transport_error = str(exc)
        else:
            transport_error = ""
        calls += 1
        elapsed = time.perf_counter() - started
        if transport_error or not response.strip():
            accepted, verdict = False, f"transport_failed: {transport_error or 'empty response'}"
            payload = None
        else:
            payload, parse_fault = parse_proposal(response)
            if payload is None:
                accepted, verdict = False, parse_fault or "unparsed"
            else:
                accepted, verdict = gate(row, payload, spec)
        record = {
            "row_id": row.row_id,
            "slice": arguments.slice,
            "model": model_name,
            "prompt_version": PROMPT_VERSION,
            "accepted": accepted,
            "verdict": verdict,
            "fault_kind": "accepted" if accepted else verdict.split(":", 1)[0],
            "seconds": round(elapsed, 2),
            "row": {
                "description": row.description,
                "example": row.example,
                "subtopic": row.subtopic,
                "vocabulary_used_raw": row.vocabulary,
                "source": f"{row.authors} ({row.year}) {row.article}",
            },
            "proposal": payload,
            "raw_response": response if not accepted else None,
        }
        atomic_write_json(path, record)
        results.append(record)
        if not accepted:
            faults[record["fault_kind"]] += 1
        print(f"[{index}/{len(rows)}] {row.row_id} {'ACCEPT' if accepted else 'REFUSE'} {verdict} ({elapsed:.1f}s)")

    every = []
    for path in sorted((output_dir / "checkpoints").glob("*.json")):
        record = json.loads(path.read_text(encoding="utf-8"))
        if record.get("prompt_version") == PROMPT_VERSION and record["slice"] == arguments.slice:
            every.append(record)
    results = every
    faults = Counter(record["fault_kind"] for record in results if not record["accepted"])
    accepted_records = [record for record in results if record["accepted"]]
    report = {
        "slice": arguments.slice,
        "model": model_name,
        "prompt_version": PROMPT_VERSION,
        "rows": len(rows),
        "calls_made_this_run": calls,
        "accepted": len(accepted_records),
        "refused": len(results) - len(accepted_records),
        "gate_pass_rate": round(len(accepted_records) / len(results), 3) if results else 0.0,
        "fault_kinds": dict(faults.most_common()),
        "valid_domain_status": dict(
            Counter(record["proposal"]["valid_domain_status"] for record in accepted_records)
        ),
        "rule_slugs": dict(
            Counter(record["proposal"]["rule_slug"] for record in accepted_records).most_common()
        ),
    }
    atomic_write_json(output_dir / f"{arguments.slice}_proposals.json", accepted_records)
    atomic_write_json(output_dir / f"{arguments.slice}_report.json", report)
    print(json.dumps({key: report[key] for key in
                      ("rows", "accepted", "refused", "gate_pass_rate", "fault_kinds", "valid_domain_status")},
                     indent=2))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--slice", choices=sorted(SLICES), default="fraction_comparison")
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--limit", type=int, default=0, help="code only the first N rows")
    parser.add_argument("--refresh", action="store_true", help="ignore existing checkpoints")
    parser.add_argument("--dry-run", action="store_true", help="build prompts without calling REALLMS")
    parser.add_argument("--timeout", type=int, default=300)
    parser.add_argument("--shards", type=int, default=1, help="split the slice across this many processes")
    parser.add_argument("--shard", type=int, default=0, help="which shard this process codes")
    parser.add_argument("--regate", action="store_true", help="re-apply the gate to stored proposals without calling REALLMS")
    return run(parser.parse_args())


if __name__ == "__main__":
    raise SystemExit(main())
