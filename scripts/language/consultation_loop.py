#!/usr/bin/env python3
"""Run the local, residue-triggered IM lesson-reading consultation loop.

SWI-Prolog tokenizes, resolves the stores, attempts the narrow reader, and
gates every proposed row.  The model answers only closed questions.  Its
answers remain attributed testimony in the admitted store and audit ledger.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
import urllib.error
import urllib.request
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable


REPO = Path(__file__).resolve().parents[2]
GUIDES = REPO / "curriculum" / "im_teacher_guides"
RUNTIME = REPO / "hermes" / "app" / "runtime" / "experiments" / "language"
LEDGER = RUNTIME / "consultation_ledger.json"
AUDIT = RUNTIME / "consultation_audit.jsonl"
STORE = REPO / "knowledge" / "strategies" / "abstraction" / "lexicon_loop_admitted_pilot.pl"
SUPPLEMENT = REPO / "knowledge" / "strategies" / "abstraction" / "lexicon_supplement_pilot.pl"
SCANNER = Path(__file__).with_name("consultation_scan.pl")
DEFAULT_ENDPOINT = "http://127.0.0.1:8099/v1/chat/completions"
DEFAULT_MODEL = "sidekick-wave5-Q4_K_M"
MODEL_ATOM = "sidekick_wave5_q4km"
CHOICE_REPLY = re.compile(r"^\s*choice\((\d+)\)\.\s*$")
CONFIRM_REPLY = re.compile(r"^\s*(yes|no\((\d+)\)|unclear)\.\s*$")
WORD_CLASS = re.compile(r"^% ([a-z_]+): (.+)$")
TERMINAL = re.compile(r"[^.!?]*(?:[.!?]+(?=\s|$)|$)")
REFUSAL_CLASSES = {"tokenizer_artifact", "contraction_fragment"}
NONE_MORPH_CLASSES = {
    "given_name", "family_name", "place_name", "named_entity",
    "tokenizer_artifact", "contraction_fragment",
}
NOUN_CLASSES = {"common_noun", "math_term", "pedagogy_term", "temporal_word"}
RECEIPT_CHECKS = [
    "no_class_conflict", "morphology_round_trip", "source_span_bound",
    "relevant_pilot_check",
]


def sha(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def health_url(endpoint: str) -> str:
    return endpoint.split("/v1/chat/completions", 1)[0] + "/health"


def health_check(endpoint: str, timeout: float) -> tuple[bool, str]:
    request = urllib.request.Request(health_url(endpoint), method="GET")
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            body = response.read().decode("utf-8", "replace")
            if 200 <= response.status < 300:
                return True, body
            return False, f"HTTP {response.status}"
    except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError, OSError) as error:
        return False, f"{type(error).__name__}: {error}"


def chat(endpoint: str, model: str, prompt: str, max_tokens: int,
         timeout: float) -> tuple[str, str]:
    """Return (outcome, text). Only an ok outcome is eligible for parsing."""
    body = json.dumps({
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0,
        "max_tokens": max_tokens,
    }).encode()
    request = urllib.request.Request(
        endpoint, data=body, headers={"Content-Type": "application/json"},
        method="POST")
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            payload = json.loads(response.read().decode())
    except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError,
            json.JSONDecodeError, OSError) as error:
        return f"transport_error:{type(error).__name__}", ""
    try:
        choice = payload["choices"][0]
        text = choice["message"].get("content") or ""
    except (KeyError, IndexError, TypeError, AttributeError):
        return "transport_error:response_shape", ""
    if choice.get("finish_reason") == "length":
        return "truncated", text
    if not text.strip():
        return "empty_content", text
    return "ok", text


def sentence_rows(grade: str, limit: int,
                  require_numeral: bool = False) -> list[dict[str, Any]]:
    grade_dir = GUIDES / grade
    if not grade_dir.is_dir():
        raise ValueError(f"grade directory is absent: {grade_dir.relative_to(REPO)}")
    rows: list[dict[str, Any]] = []
    seen: set[str] = set()
    for path in sorted(grade_dir.rglob("*.md"), key=lambda p: p.relative_to(REPO).as_posix()):
        relative = path.relative_to(REPO).as_posix()
        for line_number, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            line = raw_line.strip()
            if not line or line.startswith("```") or line.startswith("|"):
                continue
            for ordinal, match in enumerate(TERMINAL.finditer(line)):
                text = match.group(0).strip()
                if not text or text[-1:] not in ".!?":
                    continue
                lexical = re.findall(r"[^\W\d_]+", text, flags=re.UNICODE)
                if len(lexical) < 3:
                    continue
                # Guide files open with pages of narration; a digit filter
                # steers the budget toward sentences that carry quantities.
                if require_numeral and not re.search(r"\d", text):
                    continue
                digest = sha(text)
                if digest in seen:
                    continue
                seen.add(digest)
                sentence_id = f"{grade}:{relative}:{line_number}:{ordinal}:{digest[:12]}"
                rows.append({
                    "sentence_id": sentence_id,
                    "source": relative,
                    "line": line_number,
                    "sentence_index": len(rows),
                    "text": text,
                    "sha256": digest,
                })
                if len(rows) >= limit:
                    return rows
    return rows


def run_prolog(mode: str, payload: dict[str, Any]) -> dict[str, Any]:
    result = subprocess.run(
        ["swipl", "-q", "-l", str(SCANNER), "-g", "consultation_scan:main",
         "-t", "halt", "--", "--mode", mode],
        cwd=REPO, input=json.dumps(payload, ensure_ascii=False), text=True,
        capture_output=True)
    if result.returncode != 0:
        raise RuntimeError(f"SWI {mode} failed: {result.stderr.strip()}")
    try:
        output = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise RuntimeError(f"SWI {mode} returned non-JSON: {result.stdout[:500]!r}") from error
    if not output.get("ok"):
        raise RuntimeError(f"SWI {mode} error: {output.get('error', output)}")
    return output


def scan(sentences: Iterable[str]) -> dict[str, Any]:
    return run_prolog("scan", {"sentences": list(sentences)})


def class_definitions() -> dict[str, str]:
    definitions: dict[str, str] = {}
    for line in SUPPLEMENT.read_text(encoding="utf-8").splitlines():
        found = WORD_CLASS.match(line)
        if found:
            definitions[found.group(1)] = found.group(2)
    if not definitions:
        raise RuntimeError("could not read the supplement class vocabulary")
    return definitions


def token_spans(sentence: str, tokens: list[dict[str, Any]]) -> list[tuple[int, int]]:
    spans: list[tuple[int, int]] = []
    cursor = 0
    lower = sentence.lower()
    for token in tokens:
        surface = str(token["surface"])
        found = re.search(re.escape(surface), lower[cursor:])
        if not found:
            # tokenize_atom normalizes a few punctuation surfaces. A missing
            # lexical token makes the receipt unbindable; punctuation can use
            # a zero-width placeholder because residues are lexical.
            if token.get("lexical"):
                raise ValueError(f"token {surface!r} is not span-bound in {sentence!r}")
            spans.append((cursor, cursor))
            continue
        start = cursor + found.start()
        end = cursor + found.end()
        spans.append((start, end))
        cursor = end
    return spans


def residue_span(sentence: str, scan_row: dict[str, Any],
                 residue: dict[str, Any]) -> tuple[int, int, str]:
    spans = token_spans(sentence, scan_row["tokens"])
    start_index = int(residue["token_start"])
    end_index = int(residue["token_end"]) - 1
    start, end = spans[start_index][0], spans[end_index][1]
    return start, end, sentence[start:end]


def numbered(lines: list[str]) -> str:
    return "\n".join(f"{index}. {line}" for index, line in enumerate(lines, 1))


def prompt_for(sentence: str, residue: dict[str, Any],
               definitions: dict[str, str]) -> tuple[str, list[dict[str, Any]]]:
    residue_class = residue["class"]
    if residue_class == "r1_token_unknown":
        choices = [
            {"kind": "class", "value": name,
             "label": f"{name} — {definitions.get(name, 'supplement class')}"}
            for name in residue["choices"]
        ]
        run = " ".join(residue["known"]["unknown_run"])
        heading = (
            f'A sentence from a math lesson:\n  "{sentence}"\n'
            f'I do not know the words "{run}".\n'
            f'In this sentence, which one of these is "{run}"?')
    elif residue_class == "r6_unit_unknown_or_kind_gap":
        unit = " ".join(residue["known"]["unit_surface"])
        choices = [
            {"kind": "unit", "value": noun,
             "label": f"yes — it abbreviates the known noun {noun}"}
            for noun in residue.get("choices", [])
        ]
        choices.extend([
            {"kind": "count_noun", "value": "count_noun",
             "label": "it is a count noun, not a unit"},
            {"kind": "not_unit", "value": "not_unit",
             "label": "it is not a unit or a count noun here"},
        ])
        heading = (
            f'A sentence from a math lesson:\n  "{sentence}"\n'
            f'Is "{unit}" a unit here? The expansion must come from the '
            "known words in this sentence; do not supply a number or outside conversion.")
    elif residue_class == "r2_no_category_fits_slot":
        surface = residue["known"]["surface"]
        choices = [
            {"kind": "action", "value": row["base"],
             "label": f'{row["base"]} — the subject ends with {row["effect"]}'}
            for row in residue["choices"]
        ]
        heading = (
            f'A sentence from a math lesson:\n  "{sentence}"\n'
            f'The word "{surface}" is a known verb, but the reader only handles '
            "the actions below. Which action does it work like here?")
    elif residue_class == "r3_sentence_class_unparsed":
        descriptions = {
            "possession": 'possession — for example, "Mitchell has 30 pencils."',
            "change": 'change — for example, "Mitchell gives 6 pencils."',
            "conversion": 'conversion — for example, "Each basket holds 5 apples."',
            "remaining_question": 'remaining question — for example, "How many pencils does Mitchell have left?"',
        }
        choices = [
            {"kind": "sentence_class", "value": name,
             "label": descriptions.get(name, name)} for name in residue["choices"]
        ]
        heading = (
            f'A sentence from a math lesson:\n  "{sentence}"\n'
            "The deterministic reader could not read it. Which admitted sentence "
            "shape is nearest? Choosing a shape does not create facts; Prolog must reparse it.")
    else:
        raise ValueError(f"unsupported residue class: {residue_class}")
    choices.extend([
        {"kind": "refuse", "value": "none", "label": "none of these"},
        {"kind": "refuse", "value": "cannot_tell", "label": "cannot tell from the sentence"},
    ])
    prompt = f"{heading}\n{numbered([row['label'] for row in choices])}\nAnswer with one line: choice(N)."
    return prompt, choices


def morphology_for(word: str, class_name: str,
                   unit_full: str | None = None) -> dict[str, str] | None:
    if class_name in NONE_MORPH_CLASSES:
        return {"kind": "none"}
    if class_name == "unit_abbreviation":
        return {"kind": "expands_to", "full": unit_full} if unit_full else None
    if class_name == "corpus_verb":
        # A closed class choice does not supply the five independently
        # checkable forms, so the proposal remains rejected.
        return None
    if class_name in NOUN_CLASSES:
        if word.endswith("ies") and len(word) > 3:
            singular = word[:-3] + "y"
        elif word.endswith("s") and not word.endswith("ss") and len(word) > 2:
            singular = word[:-1]
        else:
            singular = word
        plural = word if word != singular else singular + "s"
        return {"kind": "noun", "singular": singular, "plural": plural}
    return {"kind": "invariant"}


def proposal_rows(sentence_meta: dict[str, Any], scan_row: dict[str, Any],
                  residue: dict[str, Any], choice: dict[str, Any],
                  consultation_id: str) -> tuple[list[dict[str, Any]], str | None]:
    start, end, surface = residue_span(sentence_meta["text"], scan_row, residue)
    residue_class = residue["class"]
    if choice["kind"] == "refuse":
        return [], "model_refused"
    if residue_class == "r3_sentence_class_unparsed":
        return [], "deterministic_reparse_failed"
    if residue_class == "r2_no_category_fits_slot":
        return [], "relationship_not_receipted_by_reader"
    if residue_class == "r1_token_unknown":
        class_name = choice["value"]
        if class_name in REFUSAL_CLASSES:
            return [], f"refusal_class:{class_name}"
        if class_name == "unit_abbreviation":
            return [], "unit_expansion_requires_r6_choice"
        token_start = int(residue["token_start"])
        token_end = int(residue["token_end"])
        unknown_tokens = [
            (index, scan_row["tokens"][index]["surface"])
            for index in range(token_start, token_end)
            if scan_row["tokens"][index].get("lexical")
            and not scan_row["tokens"][index].get("known")
        ]
        if len(unknown_tokens) > 3:
            return [], "proposal_cap_exceeded"
        candidates: list[dict[str, Any]] = []
        spans = token_spans(sentence_meta["text"], scan_row["tokens"])
        for token_index, word in unknown_tokens:
            morphology = morphology_for(word, class_name)
            if morphology is None:
                return [], f"morphology_not_receipted:{class_name}"
            word_start, word_end = spans[token_index]
            candidates.append(candidate_dict(
                sentence_meta, word, class_name, morphology, word_start, word_end,
                consultation_id,
                f'The model classified "{surface}" as {class_name} in the cited guide sentence.'))
        return candidates, None
    if residue_class == "r6_unit_unknown_or_kind_gap":
        word = residue["known"]["unit_surface"][0]
        if choice["kind"] == "unit":
            class_name, unit_full = "unit_abbreviation", choice["value"]
        elif choice["kind"] == "count_noun":
            class_name, unit_full = "common_noun", None
        else:
            return [], "model_refused"
        morphology = morphology_for(word, class_name, unit_full)
        return [candidate_dict(
            sentence_meta, word, class_name, morphology, start, end,
            consultation_id,
            f'The model classified "{surface}" as {class_name} in the cited guide sentence.')], None
    return [], "unsupported_residue"


def candidate_dict(meta: dict[str, Any], word: str, class_name: str,
                   morphology: dict[str, str], start: int, end: int,
                   consultation_id: str, rationale: str) -> dict[str, Any]:
    return {
        "word": word,
        "class": class_name,
        "morphology": morphology,
        "evidence": {
            "source": meta["source"],
            "sentence_index": meta["sentence_index"],
            "sentence": meta["text"],
            "start": start,
            "end": end,
        },
        "rationale": rationale,
        "consultation_id": consultation_id,
    }


def prolog_atom(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "''") + "'"


def prolog_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def morphology_term(morphology: dict[str, str]) -> str:
    kind = morphology["kind"]
    if kind == "none":
        return "none"
    if kind == "invariant":
        return "forms(invariant)"
    if kind == "noun":
        return f"forms(noun({prolog_atom(morphology['singular'])}, {prolog_atom(morphology['plural'])}))"
    if kind == "verb":
        fields = [prolog_atom(morphology[name]) for name in ("base", "third", "past", "ing", "participle")]
        return f"forms(verb({', '.join(fields)}))"
    if kind == "expands_to":
        return f"expands_to({prolog_atom(morphology['full'])})"
    raise ValueError(kind)


def candidate_fact(candidate: dict[str, Any], checks: list[str]) -> str:
    evidence = candidate["evidence"]
    checks_term = ", ".join(checks)
    return (
        f"loop_admitted_word({prolog_atom(candidate['word'])}, {candidate['class']}, "
        f"{morphology_term(candidate['morphology'])}, "
        f"evidence(guide_span({prolog_atom(evidence['source'])}, {evidence['sentence_index']}, "
        f"{prolog_string(evidence['sentence'])}, {evidence['start']}, {evidence['end']})), "
        f"{prolog_string(candidate['rationale'])}, "
        f"testimony(model({MODEL_ATOM}), consultation({prolog_atom(candidate['consultation_id'])})), "
        f"receipt(swipl_test([{checks_term}])))."
    )


def append_store(facts: list[str]) -> None:
    if not facts:
        return
    with STORE.open("a", encoding="utf-8") as stream:
        for fact in facts:
            stream.write(fact + "\n")


def append_audit(row: dict[str, Any]) -> None:
    RUNTIME.mkdir(parents=True, exist_ok=True)
    with AUDIT.open("a", encoding="utf-8") as stream:
        stream.write(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n")


def load_ledger(grade: str) -> dict[str, Any]:
    if LEDGER.exists():
        ledger = json.loads(LEDGER.read_text(encoding="utf-8"))
        if ledger.get("grade") != grade:
            raise ValueError(
                f"ledger is for {ledger.get('grade')}; move it before running {grade}")
        return ledger
    return {
        "version": 1,
        "grade": grade,
        "selection_rule": "sorted files; source-order terminal sentences; sha dedupe",
        "sentences": {},
        "runs": [],
        "created_at": utc_now(),
    }


def save_ledger(ledger: dict[str, Any]) -> None:
    RUNTIME.mkdir(parents=True, exist_ok=True)
    LEDGER.write_text(
        json.dumps(ledger, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8")


def choice_number(raw: str, count: int) -> tuple[int | None, str]:
    found = CHOICE_REPLY.fullmatch(raw)
    if not found:
        return None, "shape_reject"
    number = int(found.group(1))
    if not 1 <= number <= count:
        return None, "enum_reject"
    return number, "accepted_shape"


def confirmation(endpoint: str, model: str, timeout: float,
                 run_id: str, sentence_meta: dict[str, Any],
                 candidates: list[dict[str, Any]], main_id: str) -> tuple[bool, dict[str, Any]]:
    statements = [
        f'"{candidate["word"]}" is classified as {candidate["class"]} in this sentence.'
        for candidate in candidates
    ]
    prompt = (
        f'A sentence from a math lesson:\n  "{sentence_meta["text"]}"\n'
        "I read it as saying:\n" + numbered(statements) +
        "\nIs each numbered statement what the sentence says?\n"
        "Answer with one line: yes. or no(N). or unclear. "
        "N is the first statement that is not what the sentence says.")
    consultation_id = f"{main_id}-confirm"
    outcome, raw = chat(endpoint, model, prompt, 64, timeout)
    accepted = True
    shape = "not_parsed"
    disposition = f"skipped(transport({outcome}))"
    if outcome == "ok":
        found = CONFIRM_REPLY.fullmatch(raw)
        if not found:
            shape, disposition = "shape_reject", "answered_rejected(shape)"
        else:
            shape = "accepted_shape"
            answer = found.group(1)
            if answer.startswith("no("):
                number = int(found.group(2))
                if 1 <= number <= len(candidates):
                    accepted = False
                    disposition = f"answered_rejected(confirmation_dissent_{number})"
                else:
                    disposition = "answered_rejected(enum)"
            elif answer == "yes":
                disposition = "answered_accepted(testimony_only)"
            else:
                disposition = "skipped(model_unclear)"
    row = {
        "audit_id": consultation_id,
        "run_id": run_id,
        "residue_id": main_id,
        "sentence_id": sentence_meta["sentence_id"],
        "sentence": sentence_meta["text"],
        "source": sentence_meta["source"],
        "residue_class": "confirmation",
        "question": prompt,
        "question_sha256": sha(prompt),
        "raw_answer": raw,
        "transport_outcome": outcome,
        "shape_verdict": shape,
        "validation_verdict": disposition,
        "admitted_facts": [],
        "rejection_reason": None if accepted else disposition,
        "checkpoint_id": model,
        "max_tokens": 64,
        "timestamp": utc_now(),
    }
    append_audit(row)
    return accepted, row


def consult_residue(endpoint: str, model: str, timeout: float, run_id: str,
                    sentence_meta: dict[str, Any], scan_row: dict[str, Any],
                    residue: dict[str, Any], ordinal: int,
                    definitions: dict[str, str]) -> tuple[dict[str, Any], list[str], int]:
    consultation_id = f"c-{sha(sentence_meta['sentence_id'] + residue['class'] + str(ordinal))[:20]}"
    prompt, choices = prompt_for(sentence_meta["text"], residue, definitions)
    outcome, raw = chat(endpoint, model, prompt, 64, timeout)
    disposition = f"skipped(transport({outcome}))"
    shape_verdict = "not_parsed"
    enum_verdict = "not_parsed"
    validation: dict[str, Any] = {"verdict": "not_gated"}
    rejection_reason: str | None = None
    admitted_facts: list[str] = []
    proposal_count = 0
    extra_calls = 0
    if outcome == "ok":
        number, shape_verdict = choice_number(raw, len(choices))
        if number is None:
            rejection_reason = shape_verdict
            disposition = f"answered_rejected({shape_verdict})"
        else:
            enum_verdict = "in_enum"
            choice = choices[number - 1]
            candidates, proposal_error = proposal_rows(
                sentence_meta, scan_row, residue, choice, consultation_id)
            proposal_count = len(candidates)
            if proposal_error:
                rejection_reason = proposal_error
                if proposal_error == "model_refused":
                    disposition = "skipped(model_refused)"
                else:
                    disposition = f"answered_rejected({proposal_error})"
                validation = {"verdict": "rejected", "reason": proposal_error}
            else:
                passed: list[tuple[dict[str, Any], list[str]]] = []
                gates: list[dict[str, Any]] = []
                for candidate in candidates[:3]:
                    gate = run_prolog("gate", candidate)
                    gates.append(gate)
                    if gate["verdict"] == "passed":
                        passed.append((candidate, list(gate["checks"])))
                    else:
                        rejection_reason = str(gate["failed_check"])
                validation = {"verdict": "passed" if len(passed) == len(candidates) else "rejected",
                              "candidate_gates": gates}
                if passed and len(passed) == len(candidates):
                    keep, _confirmation_row = confirmation(
                        endpoint, model, timeout, run_id, sentence_meta,
                        [candidate for candidate, _ in passed], consultation_id)
                    extra_calls = 1
                    if keep:
                        admitted_facts = [candidate_fact(candidate, checks)
                                          for candidate, checks in passed]
                        append_store(admitted_facts)
                        disposition = "answered_accepted"
                    else:
                        rejection_reason = "confirmation_dissent"
                        disposition = "answered_rejected(confirmation_dissent)"
                        validation["verdict"] = "rejected"
                else:
                    disposition = f"answered_rejected({rejection_reason or 'candidate_gate'})"
    audit_row = {
        "audit_id": consultation_id,
        "run_id": run_id,
        "residue_id": consultation_id,
        "sentence_id": sentence_meta["sentence_id"],
        "sentence": sentence_meta["text"],
        "source": sentence_meta["source"],
        "residue_class": residue["class"],
        "residue": residue,
        "question": prompt,
        "question_sha256": sha(prompt),
        "raw_answer": raw,
        "transport_outcome": outcome,
        "shape_verdict": shape_verdict,
        "enum_verdict": enum_verdict,
        "validation_verdict": validation,
        "disposition": disposition,
        "proposal_count": proposal_count,
        "admitted_facts": admitted_facts,
        "rejection_reason": rejection_reason,
        "checkpoint_id": model,
        "max_tokens": 64,
        "timestamp": utc_now(),
    }
    append_audit(audit_row)
    return audit_row, admitted_facts, extra_calls


def process_sentence(endpoint: str, model: str, timeout: float, run_id: str,
                     meta: dict[str, Any], initial_scan: dict[str, Any],
                     definitions: dict[str, str]) -> dict[str, Any]:
    result: dict[str, Any] = {
        **meta,
        "status": "completed",
        "initial_parsed": bool(initial_scan["parsed"]),
        "initial_residue_classes": [r["class"] for r in initial_scan["residues"]],
        "consultation_ids": [],
        "admitted_facts": [],
        "dispositions": [],
    }
    if initial_scan["parsed"]:
        result["final_parsed"] = True
        return result
    calls = 0
    current_scan = initial_scan
    for round_classes in (
        {"r1_token_unknown", "r6_unit_unknown_or_kind_gap"},
        {"r2_no_category_fits_slot", "r3_sentence_class_unparsed",
         "r4_referent_unresolved", "r5_quantity_binds_ambiguously"},
    ):
        residues = [row for row in current_scan["residues"] if row["class"] in round_classes]
        for residue in residues:
            if calls >= 8:
                result["dispositions"].append({"class": residue["class"], "disposition": "skipped(budget)"})
                continue
            audit_row, facts, confirmation_calls = consult_residue(
                endpoint, model, timeout, run_id, meta, current_scan, residue,
                calls, definitions)
            calls += 1 + confirmation_calls
            result["consultation_ids"].append(audit_row["audit_id"])
            result["admitted_facts"].extend(facts)
            result["dispositions"].append({
                "class": residue["class"], "disposition": audit_row["disposition"]})
        # The one reparse between lexical and structural rounds is a fresh SWI
        # process, so newly appended loop rows participate in lexical lookup.
        current_scan = scan([meta["text"]])["rows"][0]
    result["final_parsed"] = bool(current_scan["parsed"])
    result["model_calls"] = calls
    return result


def audit_rows() -> list[dict[str, Any]]:
    if not AUDIT.exists():
        return []
    return [json.loads(line) for line in AUDIT.read_text(encoding="utf-8").splitlines() if line.strip()]


def summarize_run(run_id: str, processed: list[dict[str, Any]]) -> dict[str, Any]:
    rows = [row for row in audit_rows() if row.get("run_id") == run_id]
    residues = Counter()
    rejections = Counter()
    admissions = 0
    for sentence in processed:
        residues.update(sentence.get("initial_residue_classes", []))
        admissions += len(sentence.get("admitted_facts", []))
    for row in rows:
        if row.get("rejection_reason"):
            rejections[str(row["rejection_reason"])] += 1
    return {
        "run_id": run_id,
        "sentences_read": len(processed),
        "initial_residue_by_class": dict(sorted(residues.items())),
        "consultations": len(rows),
        "admissions": admissions,
        "rejections_by_reason": dict(sorted(rejections.items())),
        "audit_rows_equal_consultations": len(rows) == sum(int(row.get("model_calls", 0)) for row in processed),
        "completed_at": utc_now(),
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--grade", default="grade1")
    parser.add_argument("--limit", type=int, default=400)
    parser.add_argument("--endpoint", default=DEFAULT_ENDPOINT)
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument("--timeout", type=float, default=120.0)
    parser.add_argument("--health-only", action="store_true")
    parser.add_argument("--require-numeral", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.model != DEFAULT_MODEL:
        raise ValueError(
            f"this slice fixes testimony provenance to {DEFAULT_MODEL}; got {args.model}")
    healthy, health_detail = health_check(args.endpoint, min(args.timeout, 10.0))
    if not healthy:
        print(f"Consultation model server is unavailable at {health_url(args.endpoint)}: {health_detail}")
        return 2
    if args.health_only:
        print(f"Consultation model server is healthy at {health_url(args.endpoint)}")
        return 0
    if args.limit <= 0:
        raise ValueError("--limit must be positive")
    selection = sentence_rows(args.grade, args.limit,
                              require_numeral=args.require_numeral)
    ledger = load_ledger(args.grade)
    pending = [row for row in selection if row["sentence_id"] not in ledger["sentences"]]
    if not pending:
        print(json.dumps({"sentences_read": 0, "message": "frontier already complete"}, sort_keys=True))
        return 0
    initial = scan([row["text"] for row in pending])
    definitions = class_definitions()
    run_id = f"{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}-{sha(str(args.limit) + pending[0]['sentence_id'])[:10]}"
    processed: list[dict[str, Any]] = []
    for meta, scan_row in zip(pending, initial["rows"]):
        result = process_sentence(
            args.endpoint, args.model, args.timeout, run_id, meta, scan_row, definitions)
        ledger["sentences"][meta["sentence_id"]] = result
        processed.append(result)
        save_ledger(ledger)
    summary = summarize_run(run_id, processed)
    ledger["runs"].append(summary)
    ledger["selected_limit"] = max(args.limit, int(ledger.get("selected_limit", 0)))
    ledger["updated_at"] = utc_now()
    save_ledger(ledger)
    print(json.dumps(summary, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
