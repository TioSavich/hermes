#!/usr/bin/env python3
"""Run the bounded seven-band transcript reading and adversarial seam loop.

The band rows are deterministic records.  They do not diagnose a speaker.
The optional LLM seam calls produce quarantined candidate facts only.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import os
import re
import subprocess
import sys
import tempfile
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any, Iterable


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

DEFAULT_REPORT = (
    ROOT / "scripts/research/talkmoves_rerun_out/lesson_run3/"
    "tm_0007_lesson_report.json"
)
DEFAULT_EXTRACTIONS = (
    ROOT / "scripts/research/talkmoves_rerun_out/lesson_run3/"
    "tm_0007_lesson_extractions.json"
)
DEFAULT_LESSON = (
    ROOT / "scripts/research/talkmoves_rerun_out/lesson_run3/"
    "IM-G6-U4-L10_facts.json"
)
DEFAULT_OUTPUT = ROOT / "scripts/research/talkmoves_rerun_out/mobius"
LEXICONS = ROOT / "scripts/research/mobius_band_lexicons.json"
BRANDOMIAN_TAGGER = ROOT / "scripts/research/brandomian_tagger.py"
PROBES = ("u0337", "u0394", "u0430")
BANDS = ("red", "orange", "yellow", "green", "blue", "indigo", "violet")
SEAMS = (
    ("red", "violet"),
    ("orange", "indigo"),
    ("yellow", "blue"),
    ("green", "green"),
)
LINE = re.compile(r"^U(?P<number>\d+)\s+(?P<speaker>[^:]+):\s?(?P<text>.*)$")
PERSON = {
    "first_person_singular": re.compile(r"\b(?:i|me|my|mine)\b", re.I),
    "first_person_plural": re.compile(r"\b(?:we|us|our|ours)\b", re.I),
    "second_person": re.compile(r"\b(?:you|your|yours)\b", re.I),
    "third_person": re.compile(
        r"\b(?:he|she|they|them|their|his|her|it|its)\b", re.I
    ),
}
FRACTION_DIVISION = re.compile(
    r"(?:\bdivid|\bfraction|\bquotient|\bdenominator|\bnumerator|\bgroup|/)",
    re.I,
)
CANDIDATE_FACT = re.compile(
    r"""band_claim\(\s*
        (?P<band>red|orange|yellow|green|blue|indigo|violet)\s*,\s*
        (?P<uid>u\d+)\s*,\s*
        (?P<claim>"(?:\\.|[^"\\])*")\s*,\s*
        (?P<why>"(?:\\.|[^"\\])*")\s*
        \)\s*\.""",
    re.X | re.S,
)


def load_module(name: str, path: Path) -> Any:
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def load_inputs(
    report_path: Path, extractions_path: Path, lesson_path: Path
) -> tuple[dict[str, Any], list[dict[str, Any]], dict[str, Any]]:
    report_payload = json.loads(report_path.read_text(encoding="utf-8"))
    report = report_payload.get("report", report_payload)
    if not isinstance(report, dict) or not isinstance(report.get("transcript"), str):
        raise ValueError("report must contain a numbered transcript")
    extractions = json.loads(extractions_path.read_text(encoding="utf-8"))
    lesson = json.loads(lesson_path.read_text(encoding="utf-8"))
    if not isinstance(extractions, list) or not isinstance(lesson, dict):
        raise ValueError("extractions must be a list and lesson facts an object")
    return report, extractions, lesson


def utterances(transcript: str) -> list[dict[str, str]]:
    rows = []
    for raw in transcript.splitlines():
        match = LINE.match(raw)
        if match:
            rows.append(
                {
                    "id": "u" + match.group("number"),
                    "speaker": match.group("speaker"),
                    "text": match.group("text"),
                }
            )
    if not rows:
        raise ValueError("numbered transcript has no utterances")
    return rows


def phrase_hits(text: str, phrases: Iterable[str]) -> list[dict[str, Any]]:
    hits: list[dict[str, Any]] = []
    for phrase in sorted(set(phrases), key=len, reverse=True):
        pattern = re.compile(r"(?<!\w)" + re.escape(phrase) + r"(?!\w)", re.I)
        for match in pattern.finditer(text):
            hits.append(
                {
                    "text": text[match.start() : match.end()],
                    "start": match.start(),
                    "end": match.end(),
                }
            )
    return sorted(hits, key=lambda row: (row["start"], row["end"], row["text"]))


def honest_call(server: Any, tool: str, arguments: dict[str, Any]) -> dict[str, Any]:
    try:
        return {"status": "read", "tool": tool, "result": server.call(tool, arguments)}
    except Exception as exc:  # each band records its actual abstention boundary
        return {
            "status": "silence",
            "tool": tool,
            "reason": type(exc).__name__,
            "message": str(exc),
        }


def posture_index(report: dict[str, Any]) -> dict[str, list[dict[str, Any]]]:
    indexed: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for posture in report.get("postures", []):
        if not isinstance(posture, dict):
            continue
        for uid in posture.get("utterances", []):
            if isinstance(uid, str):
                indexed[uid].append(posture)
    return indexed


def extraction_index(
    extractions: list[dict[str, Any]],
) -> dict[str, list[dict[str, Any]]]:
    indexed: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for claim in extractions:
        uid = claim.get("utterance_id")
        if isinstance(uid, str):
            indexed[uid].append(claim)
    return indexed


def red_reading(
    server: Any, uid: str, text: str, claims: list[dict[str, Any]]
) -> dict[str, Any]:
    probes = [str(claim.get("surface") or "") for claim in claims]
    probes = [probe for probe in probes if probe.strip()] or [text]
    checks = [honest_call(server, "check_math_claim", {"term": probe}) for probe in probes]
    read = [check for check in checks if check["status"] == "read"]
    return {
        "status": "read" if read else "silence",
        "reader": "mcp.check_math_claim",
        "checks": checks,
        "prior_extraction_count": len(claims),
        "prior_claims": [
            {
                "surface": claim.get("surface"),
                "term": claim.get("term"),
                "verdict": claim.get("verdict"),
            }
            for claim in claims
        ],
    }


def orange_reading(
    uid: str,
    text: str,
    tag: dict[str, Any],
    postures: list[dict[str, Any]],
) -> dict[str, Any]:
    relevant = {
        "alethic_modal",
        "normative_deontic",
        "interrogative",
        "negation",
    }
    spans = [span for span in tag["spans"] if span["type"] in relevant]
    positions = []
    for name, pattern in PERSON.items():
        matches = [
            {"text": match.group(0), "start": match.start(), "end": match.end()}
            for match in pattern.finditer(text)
        ]
        if matches:
            positions.append({"position": name, "spans": matches})
    readings = [
        {
            "move": posture.get("move"),
            "register": posture.get("register"),
            "response": posture.get("response"),
        }
        for posture in postures
    ]
    return {
        "status": "read" if spans or positions or readings else "silence",
        "surface_spans": spans,
        "person_positions_in_order": positions,
        "existing_pml_readings": readings,
        "claim": "surface and prior PML candidates, not a speaker diagnosis",
    }


def yellow_reading(text: str, lexicon: dict[str, Any]) -> dict[str, Any]:
    token_hits = phrase_hits(text, lexicon["yellow"]["disfluency"])
    pause_hits = phrase_hits(text, lexicon["yellow"]["pause"])
    punctuation = []
    for kind, pattern in (
        ("ellipsis", re.compile(r"\.{2,}|…")),
        ("trailing_off", re.compile(r"(?:--+|—)\s*$")),
        ("question", re.compile(r"\?")),
        ("repetition", re.compile(r"\b(\w+)(?:\s+\1){1,}\b", re.I)),
    ):
        punctuation.extend(
            {
                "type": kind,
                "text": match.group(0),
                "start": match.start(),
                "end": match.end(),
            }
            for match in pattern.finditer(text)
        )
    hits = [
        *({"type": "disfluency", **hit} for hit in token_hits),
        *({"type": "pause", **hit} for hit in pause_hits),
        *punctuation,
    ]
    hits.sort(key=lambda row: (row["start"], row["end"], row["type"]))
    return {
        "status": "read" if hits else "silence",
        "candidate_catastrophe_sites": hits,
        "claim": "surface tension markers only; no Zeeman coordinate inferred",
    }


def green_reading(
    tag: dict[str, Any], claims: list[dict[str, Any]]
) -> dict[str, Any]:
    refuted = [
        {
            "surface": claim.get("surface"),
            "term": claim.get("term"),
            "verdict": claim.get("verdict"),
            "ground": claim.get("adjudication"),
        }
        for claim in claims
        if claim.get("verdict") == "refuted"
    ]
    negations = [span for span in tag["spans"] if span["type"] == "negation"]
    return {
        "status": "read" if refuted or negations else "silence",
        "refuted_claims": refuted,
        "explicit_negation_spans": negations,
        "carving": (
            "checked refutation or explicit surface negation"
            if refuted or negations
            else "no utterance-linked carved predicate"
        ),
    }


def blue_reading(tag: dict[str, Any], text: str) -> dict[str, Any]:
    relevant = {
        "deictic",
        "anaphoric_unresolved",
        "anaphoric_candidate_window",
        "substitution_inference_candidate",
        "observational",
    }
    evaluative_frames = [
        match.span()
        for match in re.finditer(
            r"\b(?:which|that|it|this)\s+is\s+(?:awesome|good|great|okay|right)\b",
            text,
            re.I,
        )
    ]
    spans = []
    for span in tag["spans"]:
        if span["type"] not in relevant:
            continue
        if span["type"] == "substitution_inference_candidate" and any(
            span["start"] < end and span["end"] > start
            for start, end in evaluative_frames
        ):
            continue
        spans.append(span)
    return {
        "status": "read" if spans else "silence",
        "surface_spans": spans,
        "claim": "anaphora stays unresolved; candidate windows are not antecedents",
    }


def indigo_reading(server: Any, text: str, lesson: dict[str, Any]) -> dict[str, Any]:
    recognition = honest_call(server, "strategy_recognize", {"content": text})
    candidates = recognition.get("result") if recognition["status"] == "read" else []
    lesson_relevant = bool(FRACTION_DIVISION.search(text) or candidates)
    institution = (
        {
            "lesson_code": lesson.get("code"),
            "standard": lesson.get("ccss", []),
            "strategy_contracts": lesson.get("strategies", []),
            "relation": "lexical_or_trace_candidate",
        }
        if lesson_relevant
        else None
    )
    return {
        "status": (
            "read"
            if lesson_relevant or (recognition["status"] == "read" and candidates)
            else "silence"
        ),
        "recognizer": recognition,
        "lesson_relation": institution,
        "claim": "candidate curriculum relation, not learner placement",
    }


def violet_reading(text: str, lexicon: dict[str, Any]) -> dict[str, Any]:
    families = []
    for row in lexicon["violet"]:
        hits = phrase_hits(text, row["phrases"])
        if hits:
            families.append(
                {
                    "family": row["family"],
                    "spans": hits,
                    "citation": row["citation"],
                }
            )
    return {
        "status": "read" if families else "silence",
        "metaphor_family_candidates": families,
        "claim": "lexical candidates only; no material inference is assigned",
    }


def stage_a(
    report: dict[str, Any],
    extractions: list[dict[str, Any]],
    lesson: dict[str, Any],
    output: Path,
) -> tuple[list[dict[str, Any]], list[dict[str, str]]]:
    from hermes.app.root import resolve_hermes_root
    from hermes.mcp.server import HermesMCPServer

    tagger = load_module("mobius_brandomian_tagger", BRANDOMIAN_TAGGER)
    brandom_lexicon = tagger.load_lexicon(tagger.DEFAULT_LEXICON)
    band_lexicon = json.loads(LEXICONS.read_text(encoding="utf-8"))
    source = utterances(report["transcript"])
    claims = extraction_index(extractions)
    postures = posture_index(report)
    rows: list[dict[str, Any]] = []
    server = HermesMCPServer("core", resolve_hermes_root())
    try:
        for utterance in source:
            uid, text = utterance["id"], utterance["text"]
            tag = tagger.tag_utterance(uid, text, brandom_lexicon)
            readings = {
                "red": red_reading(server, uid, text, claims[uid]),
                "orange": orange_reading(uid, text, tag, postures[uid]),
                "yellow": yellow_reading(text, band_lexicon),
                "green": green_reading(tag, claims[uid]),
                "blue": blue_reading(tag, text),
                "indigo": indigo_reading(server, text, lesson),
                "violet": violet_reading(text, band_lexicon),
            }
            for band in BANDS:
                rows.append(
                    {
                        "transcript_id": report.get("transcript_id", "tm_0007"),
                        "utterance_id": uid,
                        "speaker": utterance["speaker"],
                        "utterance": text,
                        "band": band,
                        "reading": readings[band],
                    }
                )
    finally:
        server.close()
    output.mkdir(parents=True, exist_ok=True)
    write_jsonl(output / "band_readings.jsonl", rows)
    return rows, source


def probe_window(source: list[dict[str, str]], width: int) -> list[dict[str, str]]:
    if width < 1:
        return []
    by_id = {row["id"]: index for index, row in enumerate(source)}
    selected: list[int] = []
    per_probe = max(1, width // len(PROBES))
    offsets = [0]
    for distance in range(1, per_probe + 2):
        offsets.extend((-distance, distance))
    for probe in PROBES:
        if probe not in by_id:
            continue
        center = by_id[probe]
        added = 0
        for offset in offsets:
            index = center + offset
            if 0 <= index < len(source) and index not in selected:
                selected.append(index)
                added += 1
            if added >= per_probe:
                break
    if len(selected) < width:
        for probe in PROBES:
            if probe not in by_id:
                continue
            center = by_id[probe]
            for distance in range(per_probe + 1, len(source)):
                for index in (center - distance, center + distance):
                    if 0 <= index < len(source) and index not in selected:
                        selected.append(index)
                        break
                if len(selected) >= width:
                    break
            if len(selected) >= width:
                break
    return [source[index] for index in sorted(selected[:width])]


def seam_user_prompt(
    utterance: dict[str, str],
    left: str,
    right: str,
    readings: dict[tuple[str, str], dict[str, Any]],
) -> str:
    uid = utterance["id"]
    question = (
        f"What is wrong or missing in the {left} characterization that the "
        f"{right} characterization improves?"
        if left != right
        else "What does the green characterization itself exclude or leave uncarved?"
    )
    return f"""Utterance {uid} ({utterance['speaker']}):
{json.dumps(utterance['text'], ensure_ascii=False)}

{left.upper()} READING:
{json.dumps(readings[(uid, left)], indent=2, ensure_ascii=False, sort_keys=True)}

{right.upper()} READING:
{json.dumps(readings[(uid, right)], indent=2, ensure_ascii=False, sort_keys=True)}

{question}

Return exactly two lines:
REASON: one sentence grounded only in the quoted utterance and readings
band_claim({right}, {uid}, "one bounded candidate claim", "the same one-sentence reason").

Use double-quoted Prolog strings. Do not diagnose the speaker, infer emotion,
resolve anaphora without evidence, or introduce a mathematical answer."""


def system_prompt() -> str:
    return """You are an adversarial seam reader for a classroom transcript.
The deterministic band readings are partial records, not diagnoses. Identify
one bounded omission only when the second reading supplies textual evidence.
If it does not, say that the seam supplies no warranted improvement and encode
that limitation as the candidate claim. Every returned fact is quarantined."""


def call_seams(
    prompts: list[dict[str, Any]], model: str, checkpoint: Path
) -> list[dict[str, Any]]:
    llm = load_module("mobius_reallms", ROOT / "hermes/app/llm.py")
    llm.load_dotenv(ROOT)
    key = llm.load_key(ROOT)
    if not key:
        raise RuntimeError("REALLMS_API_KEY is not configured")
    api_url = llm.resolve_api_url()
    ssl_ctx = llm.build_ssl_context()
    results = []
    for payload in prompts:
        try:
            reply = llm.call_api(
                payload["system"],
                payload["user"],
                api_key=key,
                api_url=api_url,
                model=model,
                ssl_ctx=ssl_ctx,
                retries=2,
                timeout=240,
            )
            results.append({**payload["metadata"], "status": "returned", "reply": reply})
        except Exception as exc:
            results.append(
                {
                    **payload["metadata"],
                    "status": "call_failed",
                    "error": type(exc).__name__,
                    "message": str(exc),
                }
            )
        atomic_write_jsonl(checkpoint, results)
    return results


def stage_b(
    rows: list[dict[str, Any]],
    source: list[dict[str, str]],
    output: Path,
    width: int,
    live: bool,
    model: str,
) -> list[dict[str, Any]]:
    indexed = {
        (row["utterance_id"], row["band"]): row["reading"] for row in rows
    }
    prompts = []
    prompt_dir = output / "seam_prompts"
    prompt_dir.mkdir(parents=True, exist_ok=True)
    for utterance in probe_window(source, width):
        for left, right in SEAMS:
            metadata = {
                "utterance_id": utterance["id"],
                "left_band": left,
                "right_band": right,
                "model": model,
            }
            payload = {
                "metadata": metadata,
                "system": system_prompt(),
                "user": seam_user_prompt(utterance, left, right, indexed),
            }
            prompts.append(payload)
            name = f"{utterance['id']}_{left}_{right}.json"
            (prompt_dir / name).write_text(
                json.dumps(payload, indent=2, ensure_ascii=False, sort_keys=True) + "\n",
                encoding="utf-8",
            )
    if live:
        results = call_seams(prompts, model, output / "seam_results.partial.jsonl")
    else:
        results = [
            {
                **payload["metadata"],
                "status": "prompt_only",
                "command": (
                    "python3 scripts/research/mobius_adversarial_loop.py "
                    f"--live --model {model}"
                ),
            }
            for payload in prompts
        ]
    write_jsonl(output / "seam_results.jsonl", results)
    return results


def decode_fact(result: dict[str, Any]) -> tuple[dict[str, str] | None, str]:
    reply = result.get("reply")
    if not isinstance(reply, str):
        return None, "no returned reply"
    matches = list(CANDIDATE_FACT.finditer(reply))
    if len(matches) != 1:
        return None, f"expected one band_claim/4 fact, found {len(matches)}"
    match = matches[0]
    try:
        claim = json.loads(match.group("claim"))
        why = json.loads(match.group("why"))
    except json.JSONDecodeError as exc:
        return None, f"invalid quoted string: {exc}"
    fact = {
        "band": match.group("band"),
        "utterance_id": match.group("uid"),
        "claim": claim,
        "why": why,
    }
    if not claim.strip() or not why.strip():
        return None, "claim and reason must be non-empty"
    return fact, ""


def prolog_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def fact_clause(fact: dict[str, str]) -> str:
    return (
        f"band_claim({fact['band']}, {fact['utterance_id']}, "
        f"{prolog_string(fact['claim'])}, {prolog_string(fact['why'])})."
    )


def prolog_loads(source: str) -> tuple[bool, str]:
    with tempfile.TemporaryDirectory(prefix="hermes-mobius-") as directory:
        path = Path(directory) / "candidate.pl"
        path.write_text(source, encoding="utf-8")
        proc = subprocess.run(
            [
                "swipl",
                "-q",
                "--on-warning=status",
                "--on-error=status",
                "-s",
                str(path),
                "-g",
                "halt",
            ],
            cwd=ROOT,
            text=True,
            capture_output=True,
            timeout=20,
            check=False,
        )
        transcript = f"exit={proc.returncode}\nstdout={proc.stdout}\nstderr={proc.stderr}"
        return proc.returncode == 0, transcript


def stage_c(
    results: list[dict[str, Any]], rows: list[dict[str, Any]], output: Path
) -> tuple[list[dict[str, Any]], list[dict[str, Any]], list[dict[str, Any]]]:
    readings = {
        (row["utterance_id"], row["band"]): row["reading"] for row in rows
    }
    accepted: list[dict[str, Any]] = []
    rejected: list[dict[str, Any]] = []
    abstained: list[dict[str, Any]] = []
    for result in results:
        fact, reason = decode_fact(result)
        if fact is None:
            if result.get("status") == "returned":
                rejected.append({**result, "failing_goal": "parse_band_claim/4", "reason": reason})
            continue
        expected_band = result["right_band"]
        expected_uid = result["utterance_id"]
        if fact["band"] != expected_band or fact["utterance_id"] != expected_uid:
            rejected.append(
                {
                    **result,
                    "candidate": fact,
                    "failing_goal": "seam_identity",
                    "reason": "candidate band or utterance differs from the seam",
                }
            )
            continue
        if "no warranted improvement" in fact["claim"].lower():
            abstained.append(
                {
                    **result,
                    "candidate": fact,
                    "reason": "seam returned an explicit evidence-limited abstention",
                }
            )
            continue
        source = (
            ":- module(mobius_candidate_probe, [band_claim/4]).\n"
            + fact_clause(fact)
            + "\n"
        )
        loaded, transcript = prolog_loads(source)
        if not loaded:
            rejected.append(
                {
                    **result,
                    "candidate": fact,
                    "failing_goal": "strict_load",
                    "reason": transcript,
                }
            )
            continue
        green = readings.get((expected_uid, "green"), {})
        refuted = green.get("refuted_claims", [])
        material_conflicts = []
        if refuted and re.search(r"\b(?:holds|correct|true)\b", fact["claim"], re.I):
            material_conflicts.append("candidate affirms where the red ledger has a checked refutation")
        accepted.append(
            {
                **result,
                "candidate": fact,
                "load_check": "passed",
                "foreground_band_query": readings.get((expected_uid, expected_band), {}),
                "material_incompatibilities": material_conflicts,
                "hierarchically_related_predicates": ["band_claim/4"],
                "carving_status": (
                    "utterance-linked checked refutation compared"
                    if refuted
                    else "no utterance-linked registry carving matched the prose candidate"
                ),
            }
        )

    candidate_lines = [
        ":- module(mobius_candidate_facts, [band_claim/4]).",
        "",
        "% QUARANTINE: generated seam candidates; no production module loads this file.",
        "band_claim(_, _, _, _) :- fail.",
    ]
    candidate_lines.extend(fact_clause(row["candidate"]) for row in accepted)
    (output / "candidate_facts.pl").write_text(
        "\n".join(candidate_lines) + "\n", encoding="utf-8"
    )

    negation_lines = [
        ":- module(mobius_determinate_negations, [determinate_negation/5]).",
        "",
        "% QUARANTINE: failed seam deposits and their failing goals.",
        "determinate_negation(_, _, _, _, _) :- fail.",
    ]
    for row in rejected:
        negation_lines.append(
            "determinate_negation("
            f"{row.get('right_band', 'green')}, "
            f"{row.get('utterance_id', 'u0000')}, "
            f"{prolog_string(str(row.get('failing_goal', 'unknown')))}, "
            f"{prolog_string(str(row.get('reason', 'unknown failure')))}, "
            f"{prolog_string(str(row.get('reply', '')))}"
            ")."
        )
    (output / "determinate_negations.pl").write_text(
        "\n".join(negation_lines) + "\n", encoding="utf-8"
    )
    write_jsonl(output / "candidate_deposits.jsonl", accepted)
    write_jsonl(output / "determinate_negations.jsonl", rejected)
    write_jsonl(output / "seam_abstentions.jsonl", abstained)
    return accepted, rejected, abstained


def write_jsonl(path: Path, rows: Iterable[dict[str, Any]]) -> None:
    path.write_text(
        "".join(
            json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n" for row in rows
        ),
        encoding="utf-8",
    )


def atomic_write_jsonl(path: Path, rows: Iterable[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        mode="w", encoding="utf-8", dir=path.parent, delete=False
    ) as handle:
        temporary = Path(handle.name)
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n")
    os.replace(temporary, path)


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    return [
        json.loads(line)
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]


def verify_outputs(output: Path) -> None:
    for name in ("candidate_facts.pl", "determinate_negations.pl"):
        proc = subprocess.run(
            [
                "swipl",
                "-q",
                "--on-warning=status",
                "--on-error=status",
                "-s",
                str(output / name),
                "-g",
                "halt",
            ],
            cwd=ROOT,
            text=True,
            capture_output=True,
            timeout=30,
            check=False,
        )
        if proc.returncode:
            raise RuntimeError(f"{name} failed strict load:\n{proc.stderr}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, default=DEFAULT_REPORT)
    parser.add_argument("--extractions", type=Path, default=DEFAULT_EXTRACTIONS)
    parser.add_argument("--lesson", type=Path, default=DEFAULT_LESSON)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--window", type=int, default=12)
    parser.add_argument("--live", action="store_true")
    parser.add_argument(
        "--stage-a-only",
        action="store_true",
        help="refresh the deterministic band ledger without touching seam artifacts",
    )
    parser.add_argument(
        "--reuse-band-readings",
        action="store_true",
        help="reuse output/band_readings.jsonl instead of repeating MCP calls",
    )
    parser.add_argument("--model", default=os.environ.get("REALLMS_MODEL", "gemma-4-31B-it"))
    args = parser.parse_args()

    report, extractions, lesson = load_inputs(
        args.report, args.extractions, args.lesson
    )
    source = utterances(report["transcript"])
    if args.reuse_band_readings:
        rows = read_jsonl(args.output / "band_readings.jsonl")
        expected = len(source) * len(BANDS)
        if len(rows) != expected:
            raise ValueError(
                f"reused band ledger has {len(rows)} rows, expected {expected}"
            )
    else:
        rows, source = stage_a(report, extractions, lesson, args.output)
    if args.stage_a_only:
        band_status = {
            band: dict(
                sorted(
                    Counter(
                        row["reading"]["status"]
                        for row in rows
                        if row["band"] == band
                    ).items()
                )
            )
            for band in BANDS
        }
        summary = {
            "transcript_id": report.get("transcript_id", "tm_0007"),
            "utterances": len(source),
            "band_rows": len(rows),
            "band_status": band_status,
            "stage": "A",
        }
        (args.output / "stage_a_summary.json").write_text(
            json.dumps(summary, indent=2, ensure_ascii=False, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        print(json.dumps(summary, indent=2, ensure_ascii=False, sort_keys=True))
        return 0
    results = stage_b(
        rows, source, args.output, args.window, args.live, args.model
    )
    accepted, rejected, abstained = stage_c(results, rows, args.output)
    verify_outputs(args.output)
    band_status: dict[str, dict[str, int]] = {}
    for band in BANDS:
        band_status[band] = dict(
            sorted(
                Counter(
                    row["reading"]["status"] for row in rows if row["band"] == band
                ).items()
            )
        )
    summary = {
        "transcript_id": report.get("transcript_id", "tm_0007"),
        "utterances": len(source),
        "band_rows": len(rows),
        "band_status": band_status,
        "seam_prompts": len(results),
        "seam_status": dict(sorted(Counter(row["status"] for row in results).items())),
        "candidate_facts": len(accepted),
        "determinate_negations": len(rejected),
        "seam_abstentions": len(abstained),
        "model": args.model,
        "live": args.live,
    }
    (args.output / "summary.json").write_text(
        json.dumps(summary, indent=2, ensure_ascii=False, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(summary, indent=2, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
