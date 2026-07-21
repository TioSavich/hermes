#!/usr/bin/env python3
"""Draft and execute-gate runnable arithmetic misconception candidates.

The model is a drafting aid.  A candidate is written to ``churn_out/admitted``
only after SWI-Prolog loads it without diagnostics, its registration executes,
its outcome differs from the registered correct answer, and its rule name (and,
when available, its output) matches the documented error pattern.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import math
import os
import re
import subprocess
import sys
import tempfile
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Iterable


ROOT = Path(__file__).resolve().parents[2]
MISCONCEPTIONS = ROOT / "knowledge" / "misconceptions"
OUTPUT_ROOT = Path(__file__).resolve().parent / "churn_out"
LITERATURE = MISCONCEPTIONS / "literature_incompatibility_facts.pl"
LLM_PATH = ROOT / "hermes" / "app" / "llm.py"
DEFAULT_MODEL = "qwen3coder-next"
ORIGINAL_DOMAINS = ("whole_number", "fraction", "decimal", "measurement", "geometry")
ARITH_DOMAINS = ORIGINAL_DOMAINS[:-1]
STOP_WORDS = {
    "about", "after", "again", "against", "answer", "because", "before",
    "correct", "does", "error", "from", "into", "number", "numbers", "only",
    "student", "than", "that", "their", "them", "then", "they", "this",
    "treat", "treats", "using", "when", "where", "which", "with", "wrong",
}


@dataclass(frozen=True)
class LiteratureMeta:
    row_id: str
    domain: str
    target_operation: str
    error_action: str
    source_key: str
    citation: str
    error_description: str


@dataclass(frozen=True)
class Entry:
    row_id: str
    domain: str
    registered_name: str
    candidate_name: str
    target_operation: str
    citation: str
    error_action: str
    error_description: str
    provenance_comments: str
    worked_example: str | None
    source_file: str


@dataclass
class GateResult:
    admitted: bool
    reason: str
    transcript: str
    rule_name: str | None = None
    got: str | None = None
    expected: str | None = None


def split_prolog_args(text: str) -> list[str]:
    """Split the argument text of a Prolog term without interpreting it."""
    args: list[str] = []
    start = 0
    depth = 0
    quote: str | None = None
    escaped = False
    for index, char in enumerate(text):
        if quote:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
            continue
        if char in ("'", '"'):
            quote = char
        elif char in "([{" :
            depth += 1
        elif char in ")]}":
            depth -= 1
        elif char == "," and depth == 0:
            args.append(text[start:index].strip())
            start = index + 1
    args.append(text[start:].strip())
    return args


def unquote_prolog_atom(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] == "'":
        return value[1:-1].replace("\\'", "'").replace("\\\\", "\\")
    return value


def iter_terms(text: str, functor: str) -> Iterable[tuple[int, int, list[str]]]:
    """Yield balanced calls to *functor* as (start, end, args)."""
    marker = functor + "("
    cursor = 0
    while True:
        start = text.find(marker, cursor)
        if start < 0:
            return
        line_start = text.rfind("\n", 0, start) + 1
        if text[line_start:start].strip():
            # Ignore schema examples and prose mentions in comments. Authored
            # facts in these tables begin a logical line with the functor.
            cursor = start + len(marker)
            continue
        pos = start + len(marker)
        depth = 1
        quote: str | None = None
        escaped = False
        while pos < len(text) and depth:
            char = text[pos]
            if quote:
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == quote:
                    quote = None
            elif char in ("'", '"'):
                quote = char
            elif char == "(":
                depth += 1
            elif char == ")":
                depth -= 1
            pos += 1
        if depth:
            raise ValueError(f"unterminated {functor} term at byte {start}")
        end = pos
        if text[end:end + 1] == ".":
            end += 1
        yield start, end, split_prolog_args(text[start + len(marker):pos - 1])
        cursor = end


def load_literature() -> dict[str, LiteratureMeta]:
    text = LITERATURE.read_text(encoding="utf-8")
    derived: dict[str, tuple[str, str, str]] = {}
    for _start, _end, args in iter_terms(text, "lit_derived"):
        if len(args) >= 4:
            row = unquote_prolog_atom(args[0])
            derived[row] = tuple(unquote_prolog_atom(value) for value in args[1:4])
    prose: dict[str, tuple[str, str, str]] = {}
    for _start, _end, args in iter_terms(text, "lit_derived_meta"):
        if len(args) == 4:
            row = unquote_prolog_atom(args[0])
            prose[row] = tuple(unquote_prolog_atom(value) for value in args[1:4])
    result: dict[str, LiteratureMeta] = {}
    for row, (domain, operation, error_action) in derived.items():
        source_key, citation, description = prose.get(row, ("", "", error_action))
        result[row] = LiteratureMeta(
            row, domain, operation, error_action, source_key, citation, description
        )
    return result


def preceding_comment_block(text: str, start: int) -> str:
    lines = text[:start].splitlines()
    block: list[str] = []
    saw_comment = False
    for line in reversed(lines):
        stripped = line.strip()
        if stripped.startswith("%"):
            block.append(stripped[1:].strip())
            saw_comment = True
        elif not stripped and not saw_comment:
            continue
        elif not stripped and saw_comment:
            block.append("")
        else:
            break
    return "\n".join(reversed(block)).strip()


def find_worked_example(comments: str) -> str | None:
    selected = []
    for line in comments.splitlines():
        if re.match(r"(?i)^(task|input|example|error|wrong|correct)\s*:", line.strip()):
            selected.append(line.strip())
    return "\n".join(selected) if selected else None


def slug(value: str) -> str:
    cleaned = re.sub(r"[^a-z0-9]+", "_", value.lower()).strip("_")
    return cleaned[:72] or "unnamed"


def enumerate_entries() -> tuple[list[Entry], dict[str, int]]:
    literature = load_literature()
    entries: list[Entry] = []
    census = {domain: 0 for domain in ORIGINAL_DOMAINS}
    for domain in ARITH_DOMAINS:
        path = MISCONCEPTIONS / f"misconceptions_{domain}.pl"
        text = path.read_text(encoding="utf-8")
        for start, _end, args in iter_terms(text, "test_harness:arith_misconception"):
            if len(args) != 6 or args[3].strip() != "skip":
                continue
            row_match = re.fullmatch(r"db_row\(([^)]+)\)", args[0].strip())
            if not row_match:
                continue
            row_id = unquote_prolog_atom(row_match.group(1))
            meta = literature.get(row_id)
            comments = preceding_comment_block(text, start)
            registered_name = unquote_prolog_atom(args[2])
            error_action = meta.error_action if meta else registered_name
            candidate_name = f"churn_{row_id}_{slug(error_action)}"
            entries.append(Entry(
                row_id=row_id,
                domain=domain,
                registered_name=registered_name,
                candidate_name=candidate_name,
                target_operation=meta.target_operation if meta else "unknown",
                citation=meta.citation if meta else "citation unavailable",
                error_action=error_action,
                error_description=(meta.error_description if meta else comments),
                provenance_comments=comments,
                worked_example=find_worked_example(comments),
                source_file=str(path.relative_to(ROOT)),
            ))
            census[domain] += 1
    # Geometry uses entail_misconception/5 and has no arithmetic rule slot.
    census["geometry"] = 0
    return entries, census


def runnable_examples(domain: str, count: int = 2) -> list[str]:
    """Return compact, existing clauses plus registrations from one domain."""
    path = MISCONCEPTIONS / f"misconceptions_{domain}.pl"
    text = path.read_text(encoding="utf-8")
    terms = list(iter_terms(text, "test_harness:arith_misconception"))
    examples: list[str] = []
    previous_end = 0
    for start, end, args in terms:
        if len(args) != 6 or args[3].strip() == "skip":
            previous_end = end
            continue
        rule = args[3].strip()
        match = re.fullmatch(r"([a-zA-Z0-9_]+):([a-zA-Z0-9_]+)", rule)
        if not match:
            previous_end = end
            continue
        module, predicate = match.groups()
        segment = text[previous_end:start]
        clause_at = segment.find(f"{module}:(" + predicate + "(")
        if clause_at < 0:
            previous_end = end
            continue
        clause = segment[clause_at:].strip()
        registration = text[start:end].strip()
        # Exemplars must wear the form the gate expects: the candidate
        # module, not the historical batch module they were archived under.
        clause = clause.replace(f"{module}:", "churn_candidate:")
        registration = registration.replace(f"{module}:{predicate}", f"churn_candidate:{predicate}")
        if len(clause) <= 1800:
            examples.append(clause + "\n\n" + registration)
        previous_end = end
        if len(examples) == count:
            break
    if len(examples) < count:
        raise RuntimeError(f"could not find two compact runnable exemplars for {domain}")
    return examples


def system_prompt(entry: Entry, exemplars: list[str]) -> str:
    return f"""You draft candidate SWI-Prolog rules for a research misconception registry.

Task register:
- Encode the DOCUMENTED student error exactly. Do not repair it and do not invent mathematics.
- If the documentation does not determine a runnable rule and a defensible probe, output exactly `ABSTAIN: <reason>`.
- The model proposes; an execution gate decides admission.

Schema contract:
`test_harness:arith_misconception(Source, Domain, Description, Rule, Input, ExpectedCorrect).`
`Rule` names a predicate of arity 2. Calling `Rule(Input, Got)` must produce the documented wrong answer. `ExpectedCorrect` is the correct outcome and therefore must not unify with `Got`.

Output contract:
- Output either one Prolog clause block or ABSTAIN. No Markdown fences or discussion.
- The clause block contains the rule predicate and exactly one arith_misconception/6 registration.
- Name the predicate exactly `{entry.candidate_name}` and qualify it in the registration as `churn_candidate:{entry.candidate_name}`.
- Use `db_row({entry.row_id})`, domain `{entry.domain}`, and description `{entry.candidate_name}` exactly.
- Supply a concrete, schema-appropriate Input and correct ExpectedCorrect. Keep the rule general when the documented procedure supports generality.
- Use only SWI-Prolog built-ins; no directives, imports, side effects, cuts, meta-calls, file access, network access, or dynamic database changes.
- Qualify the rule clause head and the registration rule slot with `churn_candidate:` exactly as the exemplars do; no other module qualification.

Two admitted-style schema exemplars from the same domain follow. They are shape examples only; do not copy their mathematics.

EXEMPLAR 1
{exemplars[0]}

EXEMPLAR 2
{exemplars[1]}
"""


def user_prompt(entry: Entry, prior_failure: str | None = None) -> str:
    fields = [
        f"Source table: {entry.source_file}",
        f"Source row: db_row({entry.row_id})",
        f"Registered name: {entry.registered_name}",
        f"Required candidate name: {entry.candidate_name}",
        f"Domain: {entry.domain}",
        f"Target operation: {entry.target_operation}",
        f"Citation: {entry.citation}",
        f"Documented error action: {entry.error_action}",
        f"Documented error description: {entry.error_description}",
        "Provenance comments (verbatim):\n" + (entry.provenance_comments or "(none)"),
        "Worked example (verbatim):\n" + (entry.worked_example or "(none present)"),
    ]
    if prior_failure:
        fields.append(
            "The first draft was rejected by the execution gate. Correct only the stated failure; "
            "ABSTAIN if it cannot be corrected without invention.\nGate failure: " + prior_failure
        )
    return "\n\n".join(fields)


def clean_response(response: str) -> str:
    text = (response or "").strip()
    fence = re.fullmatch(r"```(?:prolog)?\s*(.*?)\s*```", text, flags=re.DOTALL | re.IGNORECASE)
    text = fence.group(1).strip() if fence else text
    # Normalize historical registry qualifiers to the candidate module so
    # the stored draft and the judged draft are the same text.
    return re.sub(r"\b(?:misconceptions_[a-z0-9_]+|churn_(?!candidate\b)[a-z0-9_]+)\s*:", "churn_candidate:", text)


def existing_rule_names() -> set[str]:
    names: set[str] = set()
    for path in sorted(MISCONCEPTIONS.glob("misconceptions_*.pl")):
        text = path.read_text(encoding="utf-8")
        for _start, _end, args in iter_terms(text, "test_harness:arith_misconception"):
            if len(args) != 6:
                continue
            rule = args[3].strip()
            match = re.fullmatch(r"(?:[a-zA-Z0-9_]+:)?([a-zA-Z0-9_]+)", rule)
            if match and match.group(1) != "skip":
                names.add(match.group(1))
    return names


def meaningful_tokens(value: str) -> set[str]:
    return {
        token for token in re.findall(r"[a-z][a-z0-9]+", value.lower())
        if len(token) >= 4 and token not in STOP_WORDS
    }


def explicit_claims(description: str) -> list[str]:
    """Extract only claims introduced by strong result language.

    This deliberately does not treat every number in a citation or task as a
    claimed wrong output.
    """
    patterns = (
        r"(?i)(?:equal(?:s| to)?|yields?|gets?|returns?|answer(?:s| is)?|result(?:s| is)?|says?)\s+(-?\d+(?:\.\d+)?|[a-z][a-z0-9_]*)",
        r"(?i)(?:->|=)\s*(-?\d+(?:\.\d+)?|[a-z][a-z0-9_]*)",
    )
    claims: list[str] = []
    for pattern in patterns:
        claims.extend(match.group(1).lower() for match in re.finditer(pattern, description))
    return claims


def output_matches_documentation(entry: Entry, rule_name: str, got: str) -> tuple[bool, str]:
    """Apply the declared no-example description-pattern match.

    The rule name must share a meaningful token with the structured literature
    error action. If the prose states an explicit claimed result after strong
    result language, the canonical Prolog output must also contain that result.
    """
    action_tokens = meaningful_tokens(entry.error_action)
    name_tokens = meaningful_tokens(rule_name)
    overlap = sorted(action_tokens & name_tokens)
    if not overlap:
        return False, "predicate name does not match the documented error-action pattern"
    wrong_example_lines = "\n".join(
        line for line in (entry.worked_example or "").splitlines()
        if re.match(r"(?i)^(error|wrong)\s*:", line.strip())
    )
    claims = explicit_claims("\n".join(filter(None, [entry.error_description, wrong_example_lines])))
    if claims:
        got_tokens = set(re.findall(r"-?\d+(?:\.\d+)?|[a-z][a-z0-9_]*", got.lower()))
        if not any(claim in got_tokens for claim in claims):
            return False, f"output {got} does not match explicit documented claim(s) {claims}"
    return True, "matched error-action tokens: " + ", ".join(overlap)


def parse_candidate_registration(draft: str) -> tuple[list[str] | None, str | None]:
    terms = list(iter_terms(draft, "test_harness:arith_misconception"))
    if len(terms) != 1:
        return None, f"expected exactly one arith_misconception/6 registration; found {len(terms)}"
    args = terms[0][2]
    if len(args) != 6:
        return None, f"registration has {len(args)} arguments, expected 6"
    return args, None


def gate_draft(entry: Entry, draft: str, collisions: set[str]) -> GateResult:
    draft = clean_response(draft)
    if re.search(r"(?m)^\s*:-", draft):
        return GateResult(False, "directives are not allowed", "static gate: directive found")
    forbidden = re.search(
        r"\b(?:abolish|asserta|assertz|call|consult|delete_file|halt|load_files|"
        r"nb_setval|open|process_create|retract|retractall|rename_file|see|seen|"
        r"set_prolog_flag|shell|tell|told|use_module|write_term_to_file)\s*\(",
        draft,
    )
    if forbidden:
        return GateResult(
            False,
            f"unsafe or meta predicate is not allowed: {forbidden.group(0).rstrip('(').strip()}",
            "static gate: forbidden predicate",
        )
    # Models sometimes copy a registry module's historical qualifier;
    # normalize those to the candidate module before judging.
    draft = re.sub(r"\b(?:misconceptions_[a-z0-9_]+|churn_(?!candidate\b)[a-z0-9_]+)\s*:", "churn_candidate:", draft)
    external_module = re.search(r"\b(?!test_harness\b|churn_candidate\b)[a-z][a-zA-Z0-9_]*\s*:", draft)
    if external_module:
        return GateResult(
            False,
            f"external module qualification is not allowed: {external_module.group(0).strip()}",
            "static gate: external module",
        )
    args, error = parse_candidate_registration(draft)
    if error or args is None:
        return GateResult(False, error or "registration parse failed", "static gate: " + (error or "failed"))
    required = [f"db_row({entry.row_id})", entry.domain, entry.candidate_name]
    if [value.strip() for value in args[:3]] != required:
        return GateResult(False, "registration source/domain/description does not match the entry", repr(args[:3]))
    rule_match = re.fullmatch(r"churn_candidate:([a-z][a-zA-Z0-9_]*)", args[3].strip())
    if not rule_match:
        return GateResult(False, "Rule must be churn_candidate:<predicate>", args[3])
    rule_name = rule_match.group(1)
    if rule_name != entry.candidate_name:
        return GateResult(False, f"predicate must be named {entry.candidate_name}", rule_name=rule_name, transcript="static gate")
    if rule_name in collisions:
        return GateResult(False, f"predicate-name collision: {rule_name}/2 already exists", rule_name=rule_name, transcript="static gate")
    if args[4].strip() == "none" or args[5].strip() == "none":
        return GateResult(False, "candidate registration must supply a probe Input and ExpectedCorrect", rule_name=rule_name, transcript="static gate")

    module_name = "churn_candidate"
    query = (
        f"test_harness:arith_misconception(db_row({entry.row_id}),{entry.domain},{entry.candidate_name},Rule,Input,Expected),"
        "catch(call_with_inference_limit(call(Rule,Input,Got),10000,Status),Error,(write_canonical(error(Error)),nl,halt(22))),"
        "(Status==inference_limit_exceeded->writeln('STATUS=inference_limit'),halt(23);true),"
        "write('GOT='),write_canonical(Got),nl,write('EXPECTED='),write_canonical(Expected),nl,"
        "(Got =@= Expected->writeln('CLASS=well_formed'),halt(24);writeln('CLASS=incorrect'))"
    )
    source = (
        f":- module({module_name}, []).\n"
        ":- multifile test_harness:arith_misconception/6.\n"
        ":- dynamic test_harness:arith_misconception/6.\n"
        ":- discontiguous test_harness:arith_misconception/6.\n\n"
        + draft + "\n"
    )
    with tempfile.TemporaryDirectory(prefix="hermes-churn-") as temp_dir:
        scratch = Path(temp_dir) / "candidate.pl"
        scratch.write_text(source, encoding="utf-8")
        proc = subprocess.run(
            ["swipl", "-q", "--on-warning=status", "--on-error=status", "-s", str(scratch), "-g", query, "-t", "halt"],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=30,
            check=False,
        )
    transcript = (
        f"command: swipl -q --on-warning=status --on-error=status -s <scratch>/candidate.pl -g <gate> -t halt\n"
        f"exit: {proc.returncode}\nstdout:\n{proc.stdout}stderr:\n{proc.stderr}"
    )
    if proc.returncode != 0:
        return GateResult(False, f"SWI-Prolog gate exited {proc.returncode}", transcript, rule_name)
    if proc.stderr.strip():
        return GateResult(False, "SWI-Prolog emitted diagnostics", transcript, rule_name)
    got_match = re.search(r"(?m)^GOT=(.*)$", proc.stdout)
    expected_match = re.search(r"(?m)^EXPECTED=(.*)$", proc.stdout)
    if not got_match or not expected_match or "CLASS=incorrect" not in proc.stdout:
        return GateResult(False, "candidate did not produce a documented incorrect outcome", transcript, rule_name)
    got = got_match.group(1).strip()
    expected = expected_match.group(1).strip()
    matched, match_reason = output_matches_documentation(entry, rule_name, got)
    transcript += f"\ndescription-match: {match_reason}\n"
    if not matched:
        return GateResult(False, match_reason, transcript, rule_name, got, expected)
    return GateResult(True, "loaded, executed, returned an incorrect documented-pattern outcome", transcript, rule_name, got, expected)


def load_llm_module() -> Any:
    spec = importlib.util.spec_from_file_location("hermes_reallms", LLM_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import {LLM_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def call_reallms(
    llm: Any,
    system: str,
    user: str,
    *,
    api_key: str,
    api_url: str,
    model: str,
    ssl_ctx: Any,
    timeout: int,
) -> str:
    """Use Hermes's transport while keeping failures catchable by the batch."""
    return llm.call_api_messages(
        [{"role": "system", "content": system}, {"role": "user", "content": user}],
        api_key=api_key,
        api_url=api_url,
        model=model,
        ssl_ctx=ssl_ctx,
        retries=3,
        timeout=timeout,
        fail_on_error=False,
    )


def balanced_selection(entries: list[Entry], domains: list[str], limit: int) -> list[Entry]:
    if limit < 1:
        return []
    unknown = sorted(set(domains) - set(ARITH_DOMAINS))
    if unknown:
        raise ValueError(f"non-arithmetic or unknown pilot domain(s): {', '.join(unknown)}")
    buckets = {domain: [entry for entry in entries if entry.domain == domain] for domain in domains}
    # Round-robin so small domains empty gracefully and the surplus goes
    # to the domains that still have rows.
    selected: list[Entry] = []
    cursors = {domain: 0 for domain in domains}
    while len(selected) < limit:
        advanced = False
        for domain in domains:
            if len(selected) >= limit:
                break
            i = cursors[domain]
            if i < len(buckets[domain]):
                selected.append(buckets[domain][i])
                cursors[domain] = i + 1
                advanced = True
        if not advanced:
            break
    return selected


def write_outcome(entry: Entry, status: str, body: str, gate: GateResult | None = None) -> Path:
    directory = OUTPUT_ROOT / status / entry.domain
    directory.mkdir(parents=True, exist_ok=True)
    suffix = ".pl" if status == "admitted" else ".txt"
    path = directory / f"{entry.candidate_name}{suffix}"
    if status == "admitted" and gate:
        comments = [
            "% Misconception churn candidate; not integrated into a domain table.",
            f"% Source: {entry.source_file}, db_row({entry.row_id})",
            f"% Citation: {entry.citation}",
            f"% Documented error: {entry.error_description}",
            f"% Gate: {gate.reason}",
            f"% Gate outcome: Got={gate.got}; ExpectedCorrect={gate.expected}",
            "",
        ]
        wrapper = (
            ":- module(churn_candidate, []).\n"
            ":- multifile test_harness:arith_misconception/6.\n"
            ":- dynamic test_harness:arith_misconception/6.\n"
            ":- discontiguous test_harness:arith_misconception/6.\n\n"
        )
        path.write_text("\n".join(comments) + wrapper + body.rstrip() + "\n", encoding="utf-8")
        transcript_dir = OUTPUT_ROOT / "transcripts" / entry.domain
        transcript_dir.mkdir(parents=True, exist_ok=True)
        (transcript_dir / f"{entry.candidate_name}.txt").write_text(gate.transcript, encoding="utf-8")
    else:
        path.write_text(body.rstrip() + "\n", encoding="utf-8")
    return path


def run(args: argparse.Namespace) -> int:
    entries, census = enumerate_entries()
    print("Skip census (arith_misconception rule slot):")
    for domain in ORIGINAL_DOMAINS:
        note = " (entailment schema; no rule slot)" if domain == "geometry" else ""
        print(f"  {domain}: {census[domain]}{note}")
    print(f"  total: {sum(census.values())}")
    if args.census_only:
        return 0

    selected = balanced_selection(entries, args.domains, args.limit)
    if len(selected) < args.limit:
        print(f"note: {args.limit} requested; the chosen domains hold {len(selected)} skip rows — running all of them", flush=True)
    already = [e for e in selected if any(
        (OUTPUT_ROOT / status / e.domain / f"{e.candidate_name}{'.pl' if status == 'admitted' else '.txt'}").exists()
        for status in ("admitted", "abstained", "rejected"))]
    if already:
        print(f"resume: {len(already)} rows already carry an outcome record and are skipped", flush=True)
        skip_names = {e.candidate_name for e in already}
        selected = [e for e in selected if e.candidate_name not in skip_names]
    llm = load_llm_module()
    llm.load_dotenv(ROOT)
    api_key = llm.require_api_key()
    api_url = llm.resolve_api_url()
    ssl_ctx = llm.build_ssl_context()
    collisions = existing_rule_names()
    counts = {"admitted": 0, "abstained": 0, "rejected": 0}
    records: list[dict[str, Any]] = []
    infrastructure_errors: list[dict[str, str]] = []

    for index, entry in enumerate(selected, 1):
        print(f"[{index}/{len(selected)}] {entry.domain} db_row({entry.row_id}) {entry.error_action}", flush=True)
        exemplars = runnable_examples(entry.domain)
        system = system_prompt(entry, exemplars)
        attempts: list[dict[str, str]] = []
        final_gate: GateResult | None = None
        final_response = ""
        status = "rejected"
        for attempt in range(2):
            failure = final_gate.reason if final_gate else None
            try:
                response = call_reallms(
                    llm,
                    system,
                    user_prompt(entry, failure),
                    api_key=api_key,
                    api_url=api_url,
                    model=args.model,
                    ssl_ctx=ssl_ctx,
                    timeout=args.timeout,
                )
            except RuntimeError as exc:
                infrastructure_errors.append({
                    "row_id": entry.row_id,
                    "domain": entry.domain,
                    "error": str(exc),
                })
                print(f"  infrastructure error: {exc}", file=sys.stderr, flush=True)
                break
            final_response = clean_response(response)
            # The predicate name is our convention, not the model's choice:
            # rewrite any churn_* name it coined to the canonical one.
            for coined in set(re.findall(r"churn_candidate:\(?([a-z][a-zA-Z0-9_]*)", final_response)):
                if coined.startswith("churn_") and coined != entry.candidate_name:
                    final_response = re.sub(r"\b" + re.escape(coined) + r"\b",
                                            entry.candidate_name, final_response)
            if final_response.upper().startswith("ABSTAIN"):
                status = "abstained"
                attempts.append({"response": final_response, "result": "abstained"})
                final_gate = None
                break
            final_gate = gate_draft(entry, final_response, collisions)
            attempts.append({"response": final_response, "result": final_gate.reason})
            if final_gate.admitted:
                status = "admitted"
                collisions.add(final_gate.rule_name or entry.candidate_name)
                break
            print(f"  retry after rejection: {final_gate.reason}", flush=True)

        if infrastructure_errors:
            break
        counts[status] += 1
        if status == "admitted" and final_gate:
            output_path = write_outcome(entry, status, final_response, final_gate)
        else:
            reason = final_response if status == "abstained" else (final_gate.reason if final_gate else "no gate result")
            artifact = {
                "status": status,
                "entry": asdict(entry),
                "reason": reason,
                "attempts": attempts,
            }
            output_path = write_outcome(entry, status, json.dumps(artifact, indent=2, ensure_ascii=False))
        records.append({
            "entry": asdict(entry),
            "status": status,
            "output": str(output_path.relative_to(ROOT)),
            "attempts": attempts,
            "gate": asdict(final_gate) if final_gate else None,
        })
        print(f"  {status}", flush=True)

    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    summary = {
        "model": args.model,
        "limit": args.limit,
        "domains": args.domains,
        "census": census,
        "counts": counts,
        "completed": len(records),
        "infrastructure_errors": infrastructure_errors,
        "description_match_rule": (
            "For entries without an independently structured worked example, the predicate name must share "
            "a meaningful token with lit_derived's documented error action; when the prose states an explicit "
            "claimed result after strong result language, the canonical Prolog Got must contain that claim. "
            "In every case Got must differ from ExpectedCorrect."
        ),
        "records": records,
    }
    (OUTPUT_ROOT / "pilot_summary.json").write_text(
        json.dumps(summary, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print("Pilot counts: " + ", ".join(f"{key}={value}" for key, value in counts.items()))
    return 1 if infrastructure_errors else 0


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--census-only", action="store_true", help="enumerate skip rows without calling REALLMS")
    parser.add_argument("--limit", type=int, default=30, help="maximum number of misconceptions to draft")
    parser.add_argument(
        "--domains", nargs="+", choices=ARITH_DOMAINS,
        default=["whole_number", "fraction", "measurement"],
        help="balanced pilot domains (default: 10 each for the 30-entry pilot)",
    )
    parser.add_argument("--model", default=DEFAULT_MODEL, help=f"REALLMS model id (default: {DEFAULT_MODEL})")
    parser.add_argument("--timeout", type=int, default=600, help="per-call timeout in seconds")
    return parser.parse_args(argv)


if __name__ == "__main__":
    try:
        raise SystemExit(run(parse_args(sys.argv[1:])))
    except (RuntimeError, ValueError, subprocess.TimeoutExpired) as exc:
        sys.stderr.write(f"error: {exc}\n")
        raise SystemExit(1)
