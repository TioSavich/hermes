#!/usr/bin/env python3
"""Score blinded TalkMoves transcripts with the PML discourse instrument.

Default behavior is dry-run only: assemble one request per transcript and write
the exact prompts that would be sent to Gemma/Reallms. Pass `--live` to make API
calls. The unit of scoring is a markdown transcript, never an Excel row.

For each scored transcript, the script extracts `reader_axiom/4` and
`passage_mode/3` clauses from the model reply and routes them through this repo's
SWI-Prolog `hermes_encyclopedia:pml_score_dict/2` validator.
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import hashlib
import importlib.util
import json
import os
import re
import shutil
import ssl
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any


DEFAULT_ROOT = Path("data/external/talkmoves")
REPO_ROOT = Path(__file__).resolve().parents[1]
# Legacy pml-discourse-instrument checkouts can still be passed explicitly for
# dotenv lookup, but the scoring prompt defaults to this repo's tracked
# TalkMoves-specific JSON reader so a clean clone can assemble requests.
DEFAULT_INSTRUMENT_RUN = Path(
    os.environ.get("PML_INSTRUMENT_RUN")
    or REPO_ROOT
)
DEFAULT_SYSTEM_PROMPT = REPO_ROOT / "docs" / "research" / "2026-06-15-pml-json-score-system-prompt.md"
DEFAULT_OUTPUT_DIR = DEFAULT_ROOT / "scored"
DEFAULT_API_URL = "https://reallms.rescloud.iu.edu/direct/v1/chat/completions"
DEFAULT_MODEL = "gemma-4-31B-it"
MATH_ACTION_CATALOG_DOMAINS = {"fraction", "addition", "subtraction", "multiplication", "division", "ratio", "algebraic"}
MATH_ACTION_CATALOG_REQUIRED = [
    ("fraction", "unit_fraction_iteration"),
    ("fraction", "splitting"),
    ("fraction", "improper_fraction_iteration"),
    ("fraction", "whole_number_grab"),
    ("algebraic", "linear_pattern_contextual_rule"),
]
_MATH_ACTION_CATALOG_CACHE: str | None = None
BIGRED_TALKMOVES_BRIDGE_CANDIDATES = [
    REPO_ROOT / "iteration10_work_bigred" / "work" / "talkmoves" / "talkmoves_bridge_prompt.md",
    REPO_ROOT / "scripts" / "bigred" / "iteration10" / "work" / "talkmoves" / "talkmoves_bridge_prompt.md",
]
MODAL_OP_POLARITY = {
    "comp_nec": "compressive",
    "comp_poss": "compressive",
    "exp_nec": "expansive",
    "exp_poss": "expansive",
}
PML_MODE_FUNCTORS = {
    "subjective": "s",
    "s": "s",
    "objective": "o",
    "o": "o",
    "normative": "n",
    "n": "n",
}
PML_POSITIONS = {
    "pos_1s",
    "pos_2s",
    "pos_2_indef",
    "pos_1p_incl",
    "pos_1p_excl",
    "pos_3s_specific",
    "pos_3_generic",
    "pos_3_performative",
}
PML_PERSON_POSITION_DEFAULTS = {
    "I": "pos_1s",
    "i": "pos_1s",
    "you": "pos_2s",
    "generic_you": "pos_2_indef",
    "we_inclusive": "pos_1p_incl",
    "we_exclusive": "pos_1p_excl",
    "it": "pos_3_generic",
    "they": "pos_3s_specific",
}
PML_FORCES = {"assert", "avow", "acknowledge", "attribute", "demand", "permit", "question"}


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def slugify(value: str) -> str:
    text = re.sub(r"[^A-Za-z0-9]+", "-", value).strip("-").lower()
    return text[:90] or "run"


def load_dotenv(start: Path) -> None:
    candidates = [Path.cwd() / ".env", start / ".env"]
    candidates.extend(parent / ".env" for parent in start.parents)
    for candidate in candidates:
        if not candidate.exists():
            continue
        for raw in candidate.read_text(encoding="utf-8").splitlines():
            line = raw.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, value = line.partition("=")
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            if key and key not in os.environ:
                os.environ[key] = value
        return


def require_api_key() -> str:
    api_key = os.environ.get("REALLMS_API_KEY", "").strip()
    if not api_key or api_key.startswith("sk-PASTE") or api_key == "YOUR_KEY_HERE":
        raise SystemExit("REALLMS_API_KEY is not configured; omit --live for dry-run.")
    return api_key


def resolve_api_url() -> str:
    api_url = os.environ.get("REALLMS_BASE_URL", DEFAULT_API_URL).strip().rstrip("/")
    if not api_url.endswith("/chat/completions"):
        api_url += "/chat/completions" if api_url.endswith("/v1") else "/v1/chat/completions"
    return api_url


def resolve_model() -> str:
    return os.environ.get("REALLMS_MODEL", DEFAULT_MODEL).strip()


def build_ssl_context() -> ssl.SSLContext:
    if os.environ.get("REALLMS_INSECURE", "").strip().lower() in {"1", "true", "yes"}:
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        return ctx
    return ssl.create_default_context()


def call_api(system_prompt: str, user_content: str, *, retries: int, timeout: int) -> str:
    api_key = require_api_key()
    api_url = resolve_api_url()
    model = resolve_model()
    ssl_ctx = build_ssl_context()
    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_content},
        ],
    }
    body = json.dumps(payload).encode("utf-8")
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
    last_err = ""
    for attempt in range(1, retries + 1):
        req = urllib.request.Request(api_url, data=body, headers=headers, method="POST")
        try:
            with urllib.request.urlopen(req, timeout=timeout, context=ssl_ctx) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                return data["choices"][0]["message"]["content"]
        except urllib.error.HTTPError as exc:
            last_err = f"HTTP {exc.code}: {exc.read().decode('utf-8', errors='replace')[:500]}"
            if exc.code in {429, 500, 502, 503, 504} and attempt < retries:
                time.sleep(5 * attempt)
                continue
            break
        except (urllib.error.URLError, TimeoutError) as exc:
            last_err = f"network: {exc}"
            if attempt < retries:
                time.sleep(5 * attempt)
                continue
            break
    raise RuntimeError(f"API call failed after {retries} attempt(s): {last_err}")


def load_manifest(root: Path) -> dict[str, Any]:
    path = root / "manifests" / "talkmoves_blind_manifest.json"
    if not path.exists():
        raise SystemExit(f"Manifest not found: {path}. Run talkmoves_prepare_blind_corpus.py first.")
    return json.loads(path.read_text(encoding="utf-8"))


def select_transcripts(manifest: dict[str, Any], *, split: str, only: str | None, limit: int | None) -> list[dict[str, Any]]:
    rows = manifest.get("transcripts", [])
    if split != "all":
        rows = [row for row in rows if row.get("split") == split]
    if only:
        wanted = {item.strip() for item in only.split(",") if item.strip()}
        rows = [row for row in rows if row.get("transcript_id") in wanted]
    rows = sorted(rows, key=lambda row: row.get("transcript_id", ""))
    if limit is not None:
        rows = rows[:limit]
    return rows


def number_transcript(markdown: str) -> tuple[str, list[str]]:
    numbered: list[str] = []
    aliases: list[str] = []
    utterance_index = 0
    for line in markdown.splitlines():
        if re.match(r"^S\d\d: ", line):
            utterance_index += 1
            alias = line.split(":", 1)[0]
            if alias not in aliases:
                aliases.append(alias)
            numbered.append(f"U{utterance_index:04d} {line}")
        else:
            numbered.append(line)
    return "\n".join(numbered).strip() + "\n", aliases


def build_user_content(transcript: dict[str, Any], markdown: str,
                       *, slice_bridge: bool = False) -> tuple[str, list[str]]:
    numbered, aliases = number_transcript(markdown)
    transcript_id = transcript["transcript_id"]
    math_catalog = math_action_catalog_prompt(markdown, slice_bridge=slice_bridge)
    return (
        f"UNIT: thread 1\n"
        f"PROMPT_ID: talkmoves::{transcript_id}\n"
        f"TRANSCRIPT_ID: {transcript_id}\n\n"
        "Score this single blinded classroom transcript in transcript-full mode.\n"
        "Corpus discipline:\n"
        "- This is one model call for the whole transcript, not one call per utterance.\n"
        "- Speaker aliases S01, S02, ... are stable within this transcript.\n"
        "- Treat the aliases as authors. Do not infer real names, teacher identity, or TalkMoves labels.\n"
        "- Use U#### utterance ids as evidence anchors in substrate facts, premises, or prose when useful.\n"
        "- Produce 6-20 diagnostic PML readings for the most diagnostic modal moments; do not emit one reading per utterance.\n"
        "- Do not map isolated lexical cues directly to operators. Use local discourse context and say when evidence is thin.\n"
        "- Your primary output must be a single JSON object under a `PML_JSON` heading. Do not write final Prolog yourself unless JSON is impossible.\n"
        "- The `readings` array is required. A final score JSON with only authors/scores/passage_modes is incomplete.\n"
        "- Do not use the old `reader_axiom(... force(pos, mode, operator, content) ...)` tuple style; the local compiler writes Prolog from JSON.\n"
        "- Preserve PML texture before normalizing content: grammatical person, PML position, force, mode, operator, polarity, decorative wrapper status, and a short subject-position read.\n"
        "- `grammatical_person` should preserve the surface address: I, you, generic_you, we_inclusive, we_exclusive, it, they, unknown.\n"
        "- `position` should use PML position vocabulary such as pos_1s, pos_2s, pos_2_indef, pos_1p_incl, pos_1p_excl, pos_3s_specific, pos_3_generic, pos_3_performative.\n"
        "- `force` should be assert, avow, acknowledge, attribute, demand, permit, or question. Use avow when an I-think wrapper decorates an objective claim rather than changing the claim's content.\n"
        "- `mode` must be subjective, objective, or normative. `operator` must be comp_nec, comp_poss, exp_nec, or exp_poss. `polarity` must be compressive or expansive.\n"
        "- `decorative_wrapper` means the utterance has a surface mood/person wrapper, such as I think or maybe, that should not swallow the mathematical content.\n"
        "- Add math candidate actions only when transcript evidence clearly matches the catalog; Prolog will compile and validate them.\n"
        "- Include passage modes as JSON objects with id, mode, and reading.\n\n"
        "PML_JSON schema example:\n"
        "{\n"
        "  \"unit\": \"thread 1\",\n"
        "  \"authors\": [\"S01\", \"S02\"],\n"
        "  \"openness\": 8,\n"
        "  \"discussion_affordance\": 11,\n"
        "  \"async_protocol\": 3,\n"
        "  \"passage_modes\": [{\"id\": \"span_u0001_u0007\", \"mode\": \"successful_rhythm\", \"reading\": \"short reading\"}],\n"
        "  \"readings\": [{\n"
        "    \"id\": \"a1\",\n"
        "    \"utterance_ids\": [\"u0007\"],\n"
        "    \"raw_text\": \"short original utterance excerpt\",\n"
        "    \"normalized_text\": \"clean mathematical/discourse content\",\n"
        "    \"pml\": {\n"
        "      \"grammatical_person\": \"I\",\n"
        "      \"position\": \"pos_1s\",\n"
        "      \"force\": \"avow\",\n"
        "      \"mode\": \"objective\",\n"
        "      \"operator\": \"comp_nec\",\n"
        "      \"polarity\": \"compressive\",\n"
        "      \"content\": \"twelve twelfths equals one whole\",\n"
        "      \"decorative_wrapper\": true,\n"
        "      \"subject_position_read\": \"speaker avows an objective fraction-unit relation\"\n"
        "    },\n"
        "    \"math\": {\"domain\": \"fraction\", \"candidate_actions\": [{\"kind\": \"splitting\", \"arguments\": {\"count\": 1, \"base\": 12}, \"confidence\": \"high\"}]}\n"
        "  }]\n"
        "}\n\n"
        f"{math_catalog}\n\n"
        "----- BLINDED TRANSCRIPT -----\n"
        f"{numbered}"
    ), aliases


def math_action_catalog_prompt(transcript_markdown: str | None = None,
                               *, slice_bridge: bool = False) -> str:
    """Compose the math-action catalog plus the optional Big Red bridge.

    The catalog base (a swipl-derived strategy list) is cached. The bridge is
    candidate-generation context only; with ``slice_bridge`` it is narrowed to
    the math domains the transcript actually shows, addressing the FLM draft's
    one open engineering item ("retrieve or slice a small domain-relevant subset
    before calling Gemma"). Default behaviour is unchanged: the whole bridge is
    appended, so tracked-run prompts are byte-for-byte identical."""
    global _MATH_ACTION_CATALOG_CACHE
    if _MATH_ACTION_CATALOG_CACHE is None:
        _MATH_ACTION_CATALOG_CACHE = build_math_action_catalog_prompt(load_math_action_catalog())
    base = _MATH_ACTION_CATALOG_CACHE
    bridge = load_bigred_talkmoves_bridge_prompt()
    if not bridge:
        return base
    if slice_bridge:
        domains = detect_bridge_domains(transcript_markdown or "")
        bridge, kept, total = slice_bridge_prompt(bridge, domains)
        if domains and kept < total:
            print(
                f"[slice-bridge] domains={sorted(domains)} kept {kept}/{total} bridge anchors",
                file=sys.stderr,
            )
    return base + "\n\n----- BIG RED TALKMOVES BRIDGE -----\n" + bridge


def load_bigred_talkmoves_bridge_prompt() -> str:
    """Load the optional Big Red bridge prompt generated by iteration10.

    The bridge is candidate-generation context only. It is deliberately appended
    to the prompt rather than compiled as a truth checker.
    """
    env_path = os.environ.get("BIGRED_TALKMOVES_BRIDGE_PROMPT", "").strip()
    candidates = [Path(env_path)] if env_path else []
    candidates.extend(BIGRED_TALKMOVES_BRIDGE_CANDIDATES)
    for path in candidates:
        if not path.exists() or not path.is_file():
            continue
        text = path.read_text(encoding="utf-8", errors="replace").strip()
        if text:
            return text
    return ""


# Signals that a transcript touches a bridge math domain. Keyed by the
# operation tag the bridge uses (operation=<name>). The detector errs toward
# inclusion: an over-broad match only weakens the slicing benefit, while a
# missed signal could drop a relevant candidate anchor, so the safe failure
# mode is to keep more, not less.
BRIDGE_DOMAIN_SIGNALS: dict[str, list[str]] = {
    "fraction": [
        r"\bfraction", r"\bnumerator", r"\bdenominator", r"\bunit fraction",
        r"\bequivalen", r"\bhalf\b", r"\bhalves\b", r"\bthirds?\b",
        r"\bfourths?\b", r"\bquarters?\b", r"\bfifths?\b", r"\bsixths?\b",
        r"\beighths?\b", r"\btwelfths?\b", r"\d+\s*/\s*\d+",
    ],
    "decimal": [
        r"\bdecimal", r"\btenths?\b", r"\bhundredths?\b", r"\d+\.\d+",
    ],
    "division": [
        r"\bdivid", r"\bdivision\b", r"\bquotient", r"\bshare", r"\bsplit",
        r"\bgroups of\b", r"\beach group", r"÷",
    ],
    "multiplication": [
        r"\bmultipl", r"\btimes\b", r"\bproduct\b", r"\barray\b", r"\bfactor",
        r"\brepeated addition", r"\bgroups of\b",
    ],
    "addition": [
        r"\badd\b", r"\badding\b", r"\baddition\b", r"\bplus\b", r"\bsum\b",
        r"\baltogether", r"\btotal\b", r"\bcombine", r"\bcount on", r"\bcount up",
        r"\bcarry", r"\bregroup",
    ],
    "algebraic": [
        r"\bpattern", r"\bvariable", r"\bequation", r"\bexpression",
        r"\bsequence", r"\bfunction\b", r"\brow number", r"\bnth\b",
    ],
    "calculus": [
        r"\blimit", r"\bderivative", r"\binfinit", r"\bapproach",
        r"\brate of change", r"\bcontinuous", r"\basymptote",
    ],
    "integer": [
        r"\bnegative\b", r"\bintegers?\b", r"\bbelow zero", r"\bopposite\b",
        r"\bsigned number",
    ],
    "diagnostic": [
        r"\bjustif", r"\bprove\b", r"\bproof\b", r"\bestimate", r"\bverify",
        r"\bcompare\b", r"\bwrong\b", r"\bmistake", r"\berror\b", r"\bdisagree",
        r"\bconvince",
    ],
}


def detect_bridge_domains(markdown: str) -> set[str]:
    """The set of bridge math domains the transcript shows evidence for.

    Empty when nothing matches, which tells the slicer to keep the full bridge
    rather than guess."""
    text = markdown.lower()
    found: set[str] = set()
    for domain, signals in BRIDGE_DOMAIN_SIGNALS.items():
        if any(re.search(signal, text) for signal in signals):
            found.add(domain)
    return found


def slice_bridge_prompt(bridge_text: str, domains: set[str]) -> tuple[str, int, int]:
    """Keep prose/structure lines and only the candidate-anchor lines whose
    operation is in ``domains``.

    A candidate-anchor line is tagged ``operation=<name>``. With an empty
    ``domains`` set the bridge is returned unchanged (no silent narrowing of
    coverage). Returns (sliced_text, kept_anchor_count, total_anchor_count)."""
    lines = bridge_text.splitlines()
    total = sum(1 for line in lines if "operation=" in line)
    if not domains:
        return bridge_text, total, total
    kept = 0
    kept_lines: list[str] = []
    for line in lines:
        match = re.search(r"operation=([a-z_]+)", line)
        if match is None:
            kept_lines.append(line)
            continue
        if match.group(1) in domains:
            kept_lines.append(line)
            kept += 1
    sliced = "\n".join(kept_lines)
    if bridge_text.endswith("\n"):
        sliced += "\n"
    return sliced, kept, total


def load_math_action_catalog() -> list[dict[str, Any]]:
    goal = (
        "use_module(library(http/json)), "
        "use_module(hermes(encyclopedia)), "
        "strategy_catalog_dict(D), "
        "json_write_dict(current_output,D,[]), halt"
    )
    try:
        proc = subprocess.run(
            ["swipl", "-q", "-l", "paths.pl", "-g", goal],
            cwd=REPO_ROOT,
            check=True,
            text=True,
            capture_output=True,
            timeout=20,
        )
    except (OSError, subprocess.SubprocessError):
        return fallback_math_action_catalog()
    output = proc.stdout
    start = output.find("{")
    if start < 0:
        return fallback_math_action_catalog()
    try:
        data = json.loads(output[start:])
    except json.JSONDecodeError:
        return fallback_math_action_catalog()
    rows = data.get("strategies", []) if isinstance(data, dict) else []
    filtered = [
        row
        for row in rows
        if isinstance(row, dict) and row.get("operation") in MATH_ACTION_CATALOG_DOMAINS
    ]
    return filtered or fallback_math_action_catalog()


def fallback_math_action_catalog() -> list[dict[str, Any]]:
    return [
        {
            "operation": "fraction",
            "kind": "unit_fraction_iteration",
            "cluster": "fraction_unit_referent_operations",
            "source": "vocabulary: referent_whole, unit_fraction, iteration_count, denominator, completion_marker, beyond_whole",
        },
        {
            "operation": "fraction",
            "kind": "splitting",
            "cluster": "fraction_reversibility_splitting",
            "source": "vocabulary: referent_whole, equal_partition, unit_fraction, iterate, mutual_inverse, whole_recovered",
        },
        {
            "operation": "algebraic",
            "kind": "linear_pattern_contextual_rule",
            "cluster": "algebraic_linear_pattern_generalization",
            "source": "vocabulary: linear_pattern, first_value, row_number, constant_rate_of_change, accumulated_change",
        },
    ]


def build_math_action_catalog_prompt(rows: list[dict[str, Any]], *, limit: int = 24) -> str:
    selected: list[dict[str, Any]] = []
    seen: set[tuple[str, str]] = set()
    by_key = {(str(row.get("operation", "")), str(row.get("kind", ""))): row for row in rows}
    for key in MATH_ACTION_CATALOG_REQUIRED:
        row = by_key.get(key)
        if row and key not in seen:
            selected.append(row)
            seen.add(key)
    for row in rows:
        key = (str(row.get("operation", "")), str(row.get("kind", "")))
        if key in seen:
            continue
        selected.append(row)
        seen.add(key)
        if len(selected) >= limit:
            break

    lines = [
        "----- PML MATH ACTION CATALOG -----",
        "Use these operation:kind names for optional math_action/5 facts when the transcript clearly instantiates the action.",
        "Examples:",
        "- math_action(a1, fraction, unit_fraction_iteration, 7, 5).",
        "- math_action(a2, fraction, splitting, 1, 4).",
        "- math_action(a3, algebraic, linear_pattern_contextual_rule, linear_pattern(first(3), change(-1), row(5)), transcript_claim(row_structure)).",
        "Available action kinds:",
    ]
    for row in selected[:limit]:
        operation = str(row.get("operation", "") or "")
        kind = str(row.get("kind", "") or "")
        cluster = str(row.get("cluster", "") or "")
        source = str(row.get("source", "") or "")
        vocabulary = source.replace("vocabulary: ", "")
        lines.append(f"- {operation}:{kind} [{cluster}] vocabulary: {vocabulary}")
    return "\n".join(lines)


def extract_final_json(reply: str) -> dict[str, Any] | None:
    for raw in reversed(reply.splitlines()):
        line = raw.strip()
        if not line.startswith("{"):
            continue
        try:
            value = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(value, dict):
            return value
    return None


def extract_pml_json(reply: str) -> dict[str, Any] | None:
    """Return the first JSON object after a PML_JSON marker, if present."""
    start = reply.lower().find("pml_json")
    scan = start if start >= 0 else 0
    while True:
        open_pos = reply.find("{", scan)
        if open_pos < 0:
            return None
        end_pos = matching_json_object_end(reply, open_pos)
        if end_pos is None:
            return None
        candidate = reply[open_pos:end_pos]
        try:
            value = json.loads(candidate)
        except json.JSONDecodeError:
            scan = open_pos + 1
            continue
        if isinstance(value, dict) and ("readings" in value or "passage_modes" in value):
            return value
        scan = end_pos


def matching_json_object_end(text: str, open_pos: int) -> int | None:
    depth = 0
    in_string = False
    escape = False
    for index in range(open_pos, len(text)):
        ch = text[index]
        if in_string:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_string = False
            continue
        if ch == '"':
            in_string = True
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return index + 1
    return None


def prolog_atom(value: Any, *, default: str, lowercase: bool = True) -> str:
    text = str(value if value is not None else "").strip()
    if lowercase:
        text = text.lower()
    text = re.sub(r"[^A-Za-z0-9_]+", "_", text).strip("_")
    if not text:
        text = default
    if not text:
        return ""
    if text[0].isdigit():
        text = f"{default}_{text}"
    return text


def prolog_string(value: Any) -> str:
    return json.dumps(str(value if value is not None else ""), ensure_ascii=False)


def prolog_number_or_atom(value: Any, *, default: str = "value") -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float) and value.is_integer():
        return str(int(value))
    if isinstance(value, float):
        return repr(value)
    text = str(value if value is not None else "").strip()
    if re.fullmatch(r"-?\d+", text):
        return text
    if re.fullmatch(r"-?\d+\.\d+", text):
        return text
    return prolog_atom(text, default=default)


def normalize_pml_position(position: Any, grammatical_person: Any) -> str:
    candidate = prolog_atom(position, default="", lowercase=True) if position else ""
    if candidate in PML_POSITIONS:
        return candidate
    person = str(grammatical_person if grammatical_person is not None else "").strip()
    return PML_PERSON_POSITION_DEFAULTS.get(person, "pos_3_generic")


def normalize_pml_force(value: Any) -> str:
    force = prolog_atom(value, default="assert", lowercase=True)
    return force if force in PML_FORCES else "assert"


def normalize_pml_mode(value: Any) -> str | None:
    mode = prolog_atom(value, default="", lowercase=True)
    return PML_MODE_FUNCTORS.get(mode)


def normalize_pml_operator(value: Any) -> str | None:
    operator = prolog_atom(value, default="", lowercase=True)
    return operator if operator in MODAL_OP_POLARITY else None


def normalize_pml_polarity(value: Any, operator: str) -> str:
    polarity = prolog_atom(value, default="", lowercase=True)
    return polarity if polarity in {"compressive", "expansive"} else MODAL_OP_POLARITY[operator]


def reading_utterance_ids(reading: dict[str, Any]) -> list[str]:
    values = reading.get("utterance_ids") or reading.get("premises") or []
    if isinstance(values, str):
        values = [values]
    if not isinstance(values, list):
        return []
    ids: list[str] = []
    for value in values:
        short = short_utterance_id(str(value))
        atom = prolog_atom(short, default="u0000", lowercase=True)
        if atom not in ids:
            ids.append(atom)
    return ids


def compile_pml_json_to_clauses(payload: dict[str, Any] | None) -> tuple[list[str], dict[str, Any]]:
    if not isinstance(payload, dict):
        return [], {"source": "pml_json", "readings_by_id": {}, "skipped": ["payload is not an object"]}

    clauses: list[str] = []
    metadata: dict[str, Any] = {
        "source": "pml_json",
        "authors": payload.get("authors") or [],
        "readings_by_id": {},
        "skipped": [],
    }
    readings = payload.get("readings") or []
    if not isinstance(readings, list):
        readings = []

    for index, reading0 in enumerate(readings, start=1):
        if not isinstance(reading0, dict):
            metadata["skipped"].append({"index": index, "reason": "reading is not an object"})
            continue
        reading = dict(reading0)
        pml = reading.get("pml") if isinstance(reading.get("pml"), dict) else {}
        axiom_id = prolog_atom(reading.get("id") or f"a{index}", default=f"a{index}", lowercase=True)
        operator = normalize_pml_operator(pml.get("operator"))
        mode_functor = normalize_pml_mode(pml.get("mode"))
        if operator is None or mode_functor is None:
            metadata["skipped"].append(
                {"id": axiom_id, "reason": "missing legal mode/operator", "pml": pml}
            )
            continue
        polarity = normalize_pml_polarity(pml.get("polarity"), operator)
        position = normalize_pml_position(pml.get("position"), pml.get("grammatical_person"))
        force = normalize_pml_force(pml.get("force"))
        content = pml.get("content") or reading.get("normalized_text") or reading.get("raw_text") or axiom_id
        premises = reading_utterance_ids(reading)
        premise_list = "[" + ", ".join(premises) + "]"
        conclusion = f"force({force}({position}({mode_functor}({operator}({prolog_string(content)})))))"
        axiom_clause = f"reader_axiom({axiom_id}, {premise_list}, {conclusion}, {polarity})."
        clauses.append(axiom_clause)

        compiled_clauses = [axiom_clause]
        for math_clause in compile_math_action_clauses(axiom_id, reading):
            clauses.append(math_clause)
            compiled_clauses.append(math_clause)
        for claim_clause in compile_math_claim_clauses(axiom_id, reading):
            clauses.append(claim_clause)
            compiled_clauses.append(claim_clause)

        reading["compiled_axiom_id"] = axiom_id
        reading["compiled_clauses"] = compiled_clauses
        metadata["readings_by_id"][axiom_id] = reading

    for clause in compile_passage_mode_clauses(payload.get("passage_modes") or []):
        clauses.append(clause)

    metadata["compiled_clause_count"] = len(clauses)
    return clauses, metadata


def compile_passage_mode_clauses(passage_modes: Any) -> list[str]:
    if not isinstance(passage_modes, list):
        return []
    clauses: list[str] = []
    for index, passage in enumerate(passage_modes, start=1):
        if not isinstance(passage, dict):
            continue
        passage_id = prolog_atom(passage.get("id") or f"span_{index}", default=f"span_{index}", lowercase=True)
        mode = prolog_atom(passage.get("mode") or "flat", default="flat", lowercase=True)
        reading = passage.get("reading") or passage.get("description") or ""
        clauses.append(f"passage_mode({passage_id}, {mode}, {prolog_string(reading)}).")
    return clauses


# --- deterministic math-claim extraction from normalized text -----------------
# Turn the cleaned mathematical content of a PML reading into ground, typed
# claim terms that hermes/math_claim_checker.pl can adjudicate (holds/refuted).
# This is the domain-anchor layer: we do NOT rely on the model to invent perfect
# Prolog; we recognise a small set of stable fraction patterns and route them to
# the existing grounded checkers.

_FRAC = r"(\d+)\s*/\s*(\d+)"
_NUM = r"(\d+(?:\.\d+)?|\.\d+)"
_WORD_TIMES = {"once": 1, "twice": 2, "thrice": 3, "two": 2, "three": 3, "four": 4}
_WORD_NUMBERS = {
    "one": 1,
    "two": 2,
    "three": 3,
    "four": 4,
    "five": 5,
    "six": 6,
    "seven": 7,
    "eight": 8,
    "nine": 9,
    "ten": 10,
    "eleven": 11,
    "twelve": 12,
}
_WORD_DENOMINATORS = {
    "half": 2,
    "halves": 2,
    "third": 3,
    "thirds": 3,
    "fourth": 4,
    "fourths": 4,
    "fifth": 5,
    "fifths": 5,
    "sixth": 6,
    "sixths": 6,
    "twelfth": 12,
    "twelfths": 12,
}


def _times_value(token: str) -> int | None:
    token = token.strip().lower()
    if token.isdigit():
        return int(token)
    return _WORD_TIMES.get(token)


def _prolog_number(token: str) -> str:
    token = token.strip()
    if token.startswith("."):
        return "0" + token
    return token


def _number_word_or_token(token: str) -> str | None:
    token = token.strip().lower()
    if re.fullmatch(_NUM, token):
        return _prolog_number(token)
    value = _WORD_NUMBERS.get(token)
    return str(value) if value is not None else None


def _fraction_pair(value: Any) -> tuple[int, int] | None:
    if isinstance(value, str):
        match = re.fullmatch(r"\s*(\d+)\s*/\s*(\d+)\s*", value)
        if match:
            return int(match.group(1)), int(match.group(2))
    return None


def _word_fraction_pattern() -> str:
    nums = "|".join(sorted(_WORD_NUMBERS, key=len, reverse=True))
    dens = "|".join(sorted(_WORD_DENOMINATORS, key=len, reverse=True))
    return rf"\b({nums})[-\s]+({dens})\b"


def extract_math_claims(text: str | None) -> list[str]:
    """Extract ground Prolog claim terms from a normalized-text string.

    Returns a de-duplicated list of claim-term strings (no trailing period),
    e.g. "equivalence(fraction(2,4), fraction(1,2))". Conservative: prose with
    no recognised fraction pattern yields [].
    """
    if not text or not isinstance(text, str):
        return []
    t = text.strip()
    low = t.lower()
    claims: list[str] = []

    def add(c: str) -> None:
        if c not in claims:
            claims.append(c)

    has_mult = bool(re.search(r"[*x×]", t))
    has_plus = "+" in t
    has_minus = bool(re.search(r"[-−]", t))

    # SWI arithmetic red-pen: plain whole-number/decimal equations.
    # Fractional "/" claims stay on the fraction-specific path below.
    if "/" not in t:
        for a, b, c in re.findall(rf"\b{_NUM}\s*\+\s*{_NUM}\s*=\s*{_NUM}\b", t):
            add(
                "arithmetic_equation("
                f"{_prolog_number(a)} + {_prolog_number(b)}, {_prolog_number(c)})"
            )
        for a, b, c in re.findall(rf"\b{_NUM}\s*[*x×]\s*{_NUM}\s*=\s*{_NUM}\b", t):
            add(
                "arithmetic_equation("
                f"{_prolog_number(a)} * {_prolog_number(b)}, {_prolog_number(c)})"
            )
        num_or_word = rf"(?:\d+(?:\.\d+)?|\.\d+|{'|'.join(_WORD_NUMBERS)})"
        for a, b, c in re.findall(
            rf"\b({num_or_word})\s+(?:times|multiplied\s+by)\s+({num_or_word})\s+(?:is|equals)\s+({num_or_word})\b",
            low,
        ):
            a0 = _number_word_or_token(a)
            b0 = _number_word_or_token(b)
            c0 = _number_word_or_token(c)
            if a0 is not None and b0 is not None and c0 is not None:
                add(f"arithmetic_equation({a0} * {b0}, {c0})")

    # fraction-of arithmetic: "2/3 of 13 = (13 * 2) / 3".
    for a, b, whole, expr in re.findall(
        rf"{_FRAC}\s+of\s+(\d+)\s*=\s*\(?\s*(\d+\s*[*x×]\s*\d+\s*)\)?\s*/\s*\d+",
        t,
        flags=re.IGNORECASE,
    ):
        expr_norm = re.sub(r"\s+", " ", expr.replace("x", "*").replace("×", "*")).strip()
        if f"{whole} * {a}" == expr_norm or f"{a} * {whole}" == expr_norm:
            add(f"arithmetic_equation(({whole} * {a}) / {b}, ({whole} * {a}) / {b})")

    if "equal numerator and denominator equals one" in low or "same number on top" in low or re.search(r"\bn\s*/\s*n\s*=\s*1\b", low):
        add("n_over_n_schema")
    div_unit = re.search(
        rf"dividing\s+by\s+({'|'.join(_WORD_NUMBERS)})\s+.*(?:one|1)\s+({'|'.join(_WORD_DENOMINATORS)})",
        low,
    )
    if div_unit:
        divisor = _WORD_NUMBERS[div_unit.group(1)]
        denominator = _WORD_DENOMINATORS[div_unit.group(2)]
        if divisor == denominator:
            add(f"division_by_n_is_unit_fraction({divisor})")

    # multiplication: a/b * c/d = p/q
    if has_mult:
        for a, b, c, d, p, q in re.findall(
            rf"{_FRAC}\s*[*x×]\s*{_FRAC}\s*=\s*{_FRAC}", t
        ):
            add(f"multiplication(fraction({a},{b}), fraction({c},{d}), fraction({p},{q}))")
        for a, b, c, d, p, q in re.findall(
            rf"{_FRAC}\s*[*x×]\s*{_FRAC}.*?=\s*{_FRAC}", t
        ):
            add(f"multiplication(fraction({a},{b}), fraction({c},{d}), fraction({p},{q}))")
        for p, q, a, b, c, d in re.findall(
            rf"{_FRAC}\s*=\s*{_FRAC}\s*[*x×]\s*{_FRAC}", t
        ):
            add(f"multiplication(fraction({a},{b}), fraction({c},{d}), fraction({p},{q}))")
    for a, b, c, d, p, q in re.findall(
        rf"product\s+of\s+{_FRAC}\s+and\s+{_FRAC}\s+(?:is|equals)\s+{_FRAC}",
        t,
        flags=re.IGNORECASE,
    ):
        add(f"multiplication(fraction({a},{b}), fraction({c},{d}), fraction({p},{q}))")

    # difference: a/b - c/d = p/q
    if has_minus:
        for a, b, c, d, p, q in re.findall(
            rf"{_FRAC}\s*[-−]\s*{_FRAC}\s*=\s*{_FRAC}", t
        ):
            add(f"difference(fraction({a},{b}), fraction({c},{d}), fraction({p},{q}))")

    # sum-to-one and n/n = 1 (only when an addition is present)
    if has_plus:
        for a, b, c, d in re.findall(rf"{_FRAC}\s*\+\s*{_FRAC}\b.*?=\s*1\b", t):
            if (a, b) == (c, d):
                add(f"iterate_to_whole(fraction({a},{b}), times(2))")
        for n, dd in re.findall(rf"{_FRAC}\s*=\s*1\b", t):
            if n == dd:
                add(f"n_over_n_is_one(fraction({n},{dd}))")
    elif not has_mult and not has_minus:
        # plain equivalence: a/b = c/d  (skip when an addition could confuse it)
        for a, b, c, d in re.findall(rf"{_FRAC}\s*=\s*{_FRAC}", t):
            add(f"equivalence(fraction({a},{b}), fraction({c},{d}))")
        for n, dd in re.findall(rf"{_FRAC}\s*=\s*1\b", t):
            if n == dd:
                add(f"n_over_n_is_one(fraction({n},{dd}))")
        for n, dd in re.findall(_FRAC, t):
            if n == dd and "total length" in low:
                add(f"n_over_n_is_one(fraction({n},{dd}))")

    # iterate a part N times to make the whole: "2/4 iterated twice ... whole"
    for a, b, k in re.findall(
        rf"{_FRAC}\s+iterated\s+(\w+)[^.]*?\bwhole\b", low
    ):
        kv = _times_value(k)
        if kv is not None:
            add(f"iterate_to_whole(fraction({a},{b}), times({kv}))")

    # number-line position. "midpoint" is more specific and wins.
    if "midpoint" in low:
        mfrac = re.search(_FRAC, t)
        if mfrac:
            add(f"midpoint(fraction({mfrac.group(1)},{mfrac.group(2)}))")
        else:
            wfrac = re.search(_word_fraction_pattern(), low)
            if wfrac:
                add(
                    "midpoint("
                    f"fraction({_WORD_NUMBERS[wfrac.group(1)]},{_WORD_DENOMINATORS[wfrac.group(2)]}))"
                )
    elif re.search(r"\b(?:as|is|was|were|treating)\s+(?:the\s+)?half\b(?!\s+of)", low):
        mfrac = re.search(_FRAC, t)
        if mfrac:
            add(f"midpoint(fraction({mfrac.group(1)},{mfrac.group(2)}))")
        else:
            wfrac = re.search(_word_fraction_pattern(), low)
            if wfrac:
                add(
                    "midpoint("
                    f"fraction({_WORD_NUMBERS[wfrac.group(1)]},{_WORD_DENOMINATORS[wfrac.group(2)]}))"
                )
    elif ("between 0 and 1" in low) or ("number line" in low):
        mfrac = re.search(_FRAC, t)
        if mfrac:
            add(
                f"number_line_position(fraction({mfrac.group(1)},{mfrac.group(2)}), between(0,1))"
            )

    # improper fraction, only when the word is present (avoids over-claiming)
    if "improper" in low:
        mfrac = re.search(_FRAC, t)
        if mfrac:
            add(f"improper(fraction({mfrac.group(1)},{mfrac.group(2)}))")
    if "exist" in low or "exists" in low:
        wfrac = re.search(_word_fraction_pattern(), low)
        if wfrac:
            n = _WORD_NUMBERS[wfrac.group(1)]
            d = _WORD_DENOMINATORS[wfrac.group(2)]
            if n > d:
                add(f"improper(fraction({n},{d}))")

    for total, shaded, half_n, half_d in re.findall(
        rf"divided\s+into\s+(\d+)\s+equal\s+parts\s+with\s+(\d+)\s+shaded\s+equals\s+{_FRAC}",
        low,
    ):
        add(f"equivalence(fraction({shaded},{total}), fraction({half_n},{half_d}))")

    return claims


def compile_math_claim_clauses(axiom_id: str, reading: dict[str, Any]) -> list[str]:
    """Emit math_claim/2 Prolog clauses for a reading from its normalized text.

    Falls back to the PML content atom only if normalized_text yields nothing.
    """
    text = reading.get("normalized_text")
    claims = extract_math_claims(text)
    if not claims:
        pml = reading.get("pml") if isinstance(reading.get("pml"), dict) else {}
        claims = extract_math_claims(pml.get("content"))
    return [f"math_claim({axiom_id}, {claim})." for claim in claims]


def compile_math_action_clauses(axiom_id: str, reading: dict[str, Any]) -> list[str]:
    math = reading.get("math") if isinstance(reading.get("math"), dict) else {}
    candidates = math.get("candidate_actions") or math.get("actions") or []
    if isinstance(candidates, dict):
        candidates = [candidates]
    if not isinstance(candidates, list):
        return []

    clauses: list[str] = []
    for candidate in candidates:
        if not isinstance(candidate, dict):
            continue
        operation = prolog_atom(
            candidate.get("operation") or candidate.get("domain") or math.get("domain") or math.get("operation"),
            default="operation",
            lowercase=True,
        )
        kind = prolog_atom(candidate.get("kind") or candidate.get("action_kind"), default="kind", lowercase=True)
        args = candidate.get("arguments") if isinstance(candidate.get("arguments"), dict) else {}
        left, right = compile_math_action_args(operation, kind, args, candidate)
        if left is None or right is None:
            continue
        if operation == "fraction" and kind == "improper_fraction_iteration":
            left_n = numeric_value(left)
            right_n = numeric_value(right)
            if left_n is not None and right_n is not None and left_n <= right_n:
                kind = "unit_fraction_iteration"
        clauses.append(f"math_action({axiom_id}, {operation}, {kind}, {left}, {right}).")
    return clauses


def compile_math_action_args(
    operation: str,
    kind: str,
    args: dict[str, Any],
    candidate: dict[str, Any],
) -> tuple[str | None, str | None]:
    if "left" in args and "right" in args:
        return prolog_math_term(args["left"]), prolog_math_term(args["right"])
    if "left" in candidate and "right" in candidate:
        return prolog_math_term(candidate["left"]), prolog_math_term(candidate["right"])
    if "count" in args and "base" in args:
        return prolog_math_term(args["count"]), prolog_math_term(args["base"])
    if operation == "multiplication" and isinstance(args.get("factor_pair"), list):
        factors = args["factor_pair"]
        if len(factors) >= 2:
            return prolog_math_term(factors[0]), prolog_math_term(factors[1])
    if operation == "division" and kind == "fair_share_equal_groups":
        total = args.get("total")
        group_count = args.get("number_of_groups") or args.get("group_count") or args.get("groups")
        if total is not None and group_count is not None:
            return prolog_math_term(total), prolog_math_term(group_count)
    if operation == "fraction" and kind == "unit_fraction_partition" and "denominator" in args:
        return "1", prolog_math_term(args["denominator"])
    unit_fraction = _fraction_pair(args.get("unit_fraction"))
    if operation == "fraction" and unit_fraction is not None:
        unit_count, unit_base = unit_fraction
        if kind == "splitting":
            base = args.get("equal_partition") or args.get("base") or unit_base
            return prolog_math_term(unit_count), prolog_math_term(base)
        if kind == "unit_fraction_iteration":
            count = args.get("iteration_count") or args.get("iterations") or args.get("iterate") or unit_count
            return prolog_math_term(count), prolog_math_term(unit_base)
        if kind == "improper_fraction_iteration":
            target = None
            for key in ("iterate_past_whole", "target_fraction", "improper_fraction"):
                target = _fraction_pair(args.get(key))
                if target is not None:
                    break
            if target is not None:
                return prolog_math_term(target[0]), prolog_math_term(target[1])
            count = args.get("iteration_count") or args.get("iterations") or args.get("iterate")
            if count is not None:
                return prolog_math_term(count), prolog_math_term(unit_base)
    if operation == "fraction" and kind == "splitting" and "equal_partition" in args:
        return "1", prolog_math_term(args["equal_partition"])
    if "iterations" in args and "denominator" in args:
        return prolog_math_term(args["iterations"]), prolog_math_term(args["denominator"])
    if "iteration_count" in args and "denominator" in args:
        return prolog_math_term(args["iteration_count"]), prolog_math_term(args["denominator"])
    if "numerator" in args and "denominator" in args:
        return prolog_math_term(args["numerator"]), prolog_math_term(args["denominator"])
    if operation == "algebraic" and kind == "linear_pattern_contextual_rule":
        pattern = args.get("pattern") if isinstance(args.get("pattern"), dict) else args
        first = pattern.get("first") or pattern.get("first_value")
        change = pattern.get("change") or pattern.get("rate") or pattern.get("constant_rate_of_change")
        row = linear_pattern_row(pattern, change)
        if first is not None and change is not None and row is not None:
            left = (
                "linear_pattern("
                f"first({prolog_number_or_atom(first)}), "
                f"change({prolog_number_or_atom(change)}), "
                f"row({prolog_number_or_atom(row)})"
                ")"
            )
            claim = args.get("claim") or candidate.get("claim") or "row_structure"
            return left, f"transcript_claim({prolog_atom(claim, default='claim')})"
    return None, None


def numeric_value(value: Any) -> float | None:
    if isinstance(value, bool) or value is None:
        return None
    if isinstance(value, (int, float)):
        return float(value)
    text = str(value).strip()
    try:
        return float(text)
    except ValueError:
        return None


def linear_pattern_row(pattern: dict[str, Any], change: Any) -> Any:
    accumulated = numeric_value(pattern.get("accumulated_change"))
    change_value = numeric_value(change)
    if accumulated is not None and change_value not in {None, 0}:
        relative_steps = accumulated / change_value
        if relative_steps >= 0 and abs(relative_steps - round(relative_steps)) < 1e-9:
            return int(round(relative_steps)) + 1

    target_row = numeric_value(pattern.get("target_row") or pattern.get("target_row_number"))
    baseline_row = numeric_value(pattern.get("baseline_row") or pattern.get("source_row"))
    if target_row is not None and baseline_row is not None:
        relative_row = target_row - baseline_row + 1
        if relative_row >= 1 and abs(relative_row - round(relative_row)) < 1e-9:
            return int(round(relative_row))

    return pattern.get("row") or pattern.get("row_number")


def prolog_math_term(value: Any) -> str:
    if isinstance(value, dict):
        if set(value) >= {"first", "change", "row"}:
            return (
                "linear_pattern("
                f"first({prolog_number_or_atom(value.get('first'))}), "
                f"change({prolog_number_or_atom(value.get('change'))}), "
                f"row({prolog_number_or_atom(value.get('row'))})"
                ")"
            )
        return prolog_atom("_".join(str(part) for part in value.values()), default="term")
    return prolog_number_or_atom(value)


def summary_passage_modes(value: Any) -> str:
    if not isinstance(value, list):
        return ""
    items: list[str] = []
    for item in value:
        if isinstance(item, dict):
            mode = str(item.get("mode") or item.get("id") or "").strip()
            if mode:
                items.append(mode)
        elif item is not None:
            items.append(str(item))
    return "|".join(items)


def extract_pml_clauses(text: str) -> list[str]:
    clauses: list[str] = []
    for keyword in ("reader_axiom", "math_action", "passage_mode"):
        needle = keyword + "("
        start = 0
        while True:
            pos = text.find(needle, start)
            if pos < 0:
                break
            depth = 0
            i = pos + len(keyword)
            in_string = False
            escape = False
            while i < len(text):
                ch = text[i]
                if in_string:
                    if escape:
                        escape = False
                    elif ch == "\\":
                        escape = True
                    elif ch == '"':
                        in_string = False
                else:
                    if ch == '"':
                        in_string = True
                    elif ch == "(":
                        depth += 1
                    elif ch == ")":
                        depth -= 1
                        if depth == 0:
                            end = i + 1
                            if end < len(text) and text[end] == ".":
                                end += 1
                            clauses.append(text[pos:end].strip())
                            start = end
                            break
                i += 1
            else:
                start = pos + len(needle)
    return clauses


def matching_term_end(text: str, open_pos: int) -> int | None:
    pairs = {"(": ")", "[": "]", "{": "}"}
    open_char = text[open_pos]
    close_char = pairs.get(open_char)
    if close_char is None:
        return None
    stack = [close_char]
    in_string = False
    escape = False
    for index in range(open_pos + 1, len(text)):
        ch = text[index]
        if in_string:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_string = False
            continue
        if ch == '"':
            in_string = True
        elif ch in pairs:
            stack.append(pairs[ch])
        elif stack and ch == stack[-1]:
            stack.pop()
            if not stack:
                return index + 1
    return None


def split_top_level_args(text: str) -> list[str]:
    args: list[str] = []
    start = 0
    depth = 0
    in_string = False
    escape = False
    for index, ch in enumerate(text):
        if in_string:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_string = False
            continue
        if ch == '"':
            in_string = True
        elif ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        elif ch == "," and depth == 0:
            args.append(text[start:index].strip())
            start = index + 1
    tail = text[start:].strip()
    if tail:
        args.append(tail)
    return args


def term_args(text: str, functor: str) -> list[str] | None:
    stripped = text.strip()
    if stripped.endswith("."):
        stripped = stripped[:-1].strip()
    prefix = functor + "("
    if not stripped.startswith(prefix):
        return None
    open_pos = stripped.find("(")
    close_pos = matching_term_end(stripped, open_pos)
    if close_pos != len(stripped):
        return None
    return split_top_level_args(stripped[open_pos + 1 : close_pos - 1])


def normalize_legacy_premises(text: str) -> str:
    ids = re.findall(r"\b[Uu](\d{4})\b", text)
    if ids:
        return "[" + ", ".join(f"u{digits}" for digits in ids) + "]"
    return text


def legacy_content_term(text: str) -> str:
    value = text.strip()
    if value.startswith('"') and value.endswith('"'):
        return value
    if value.startswith("'") and value.endswith("'"):
        value = value[1:-1]
    return prolog_string(value)


def repair_legacy_reader_axiom_clause(clause: str) -> str | None:
    args = term_args(clause, "reader_axiom")
    if not args or len(args) != 4:
        return None
    axiom_id0, premises0, conclusion0, polarity0 = args
    force_args = term_args(conclusion0, "force")
    if not force_args or len(force_args) not in {4, 5}:
        return None
    if len(force_args) == 4:
        position0, mode0, operator0, content0 = force_args
        force0 = "assert"
    else:
        position0, force0, mode0, operator0, content0 = force_args
    mode_functor = normalize_pml_mode(mode0)
    operator = normalize_pml_operator(operator0)
    if mode_functor is None or operator is None:
        return None
    axiom_id = prolog_atom(axiom_id0.strip("'\""), default="a", lowercase=True)
    premises = normalize_legacy_premises(premises0)
    position = normalize_pml_position(position0, "")
    force = normalize_pml_force(force0)
    polarity = normalize_pml_polarity(polarity0, operator)
    content = legacy_content_term(content0)
    conclusion = f"force({force}({position}({mode_functor}({operator}({content})))))"
    return f"reader_axiom({axiom_id}, {premises}, {conclusion}, {polarity})."


def short_utterance_id(value: str) -> str:
    match = re.search(r"u(\d{4})", str(value or ""), flags=re.IGNORECASE)
    return f"u{match.group(1)}" if match else str(value or "")


def clause_axiom_id(clause: str) -> str | None:
    match = re.match(r"\s*reader_axiom\(\s*([^,\s]+)", clause)
    if not match:
        return None
    return str(match.group(1)).strip("'\"")


def index_transcript_utterances(markdown: str, key_rows: list[dict[str, Any]] | None = None) -> list[dict[str, Any]]:
    key_by_short = {
        short_utterance_id(row.get("utterance_id", "")): row
        for row in (key_rows or [])
        if short_utterance_id(row.get("utterance_id", ""))
    }
    utterances: list[dict[str, Any]] = []
    index = 0
    for line in markdown.splitlines():
        if not re.match(r"^S\d\d: ", line):
            continue
        index += 1
        utterance_id = f"u{index:04d}"
        alias, _, sentence = line.partition(": ")
        key = key_by_short.get(utterance_id, {})
        utterances.append(
            {
                "utterance_id": utterance_id,
                "alias": alias,
                "line": line,
                "sentence": sentence,
                "speaker": key.get("speaker", ""),
                "teacher_tag": key.get("teacher_tag", ""),
                "student_tag": key.get("student_tag", ""),
                "extra_labels": key.get("extra_labels", {}) or {},
                "source_path": key.get("source_path", ""),
                "sheet": key.get("sheet", ""),
                "source_row": key.get("source_row", ""),
                "turn": key.get("turn", ""),
            }
        )
    return utterances


def load_answer_key_rows(root: Path, transcript_ids: set[str]) -> dict[str, list[dict[str, Any]]]:
    key_path = root / "keys" / "talkmoves_answer_key.jsonl"
    rows: dict[str, list[dict[str, Any]]] = {tid: [] for tid in transcript_ids}
    if not key_path.exists():
        return rows
    with key_path.open(encoding="utf-8") as handle:
        for line in handle:
            row = json.loads(line)
            transcript_id = row.get("transcript_id")
            if transcript_id in rows:
                rows[transcript_id].append(row)
    return rows


def evidence_for_premise(
    premise: str,
    utterances: list[dict[str, Any]],
    by_short_id: dict[str, dict[str, Any]],
    *,
    window_size: int = 1,
) -> dict[str, Any] | None:
    short_id = short_utterance_id(premise)
    utterance = by_short_id.get(short_id)
    if utterance is None:
        return None
    idx = utterances.index(utterance)
    start = max(0, idx - window_size)
    end = min(len(utterances), idx + window_size + 1)
    evidence = dict(utterance)
    evidence["window"] = utterances[start:end]
    return evidence


def build_audit_packet(
    *,
    transcript: dict[str, Any],
    markdown: str,
    raw_clauses: list[str],
    repaired_clauses: list[str],
    validation: dict[str, Any],
    key_rows: list[dict[str, Any]],
    response_path: Path,
    prolog_path: Path,
) -> dict[str, Any]:
    utterances = index_transcript_utterances(markdown, key_rows)
    by_short_id = {row["utterance_id"]: row for row in utterances}
    raw_by_id = {axiom_id: clause for clause in raw_clauses if (axiom_id := clause_axiom_id(clause))}
    repaired_by_id = {axiom_id: clause for clause in repaired_clauses if (axiom_id := clause_axiom_id(clause))}
    compiled_pml = validation.get("compiled_pml_json", {}) if isinstance(validation, dict) else {}
    pml_readings_by_id = compiled_pml.get("readings_by_id", {}) if isinstance(compiled_pml, dict) else {}

    audit_axioms: list[dict[str, Any]] = []
    for axiom in validation.get("axioms", []) or []:
        axiom_id = axiom.get("id", "")
        premises = axiom.get("premises", []) or []
        evidence = [
            item
            for premise in premises
            if (item := evidence_for_premise(premise, utterances, by_short_id)) is not None
        ]
        polarity_match = bool(axiom.get("polarity_match", axiom.get("coherent", True)))
        audit_axioms.append(
            {
                "id": axiom_id,
                "raw_clause": raw_by_id.get(axiom_id, ""),
                "repaired_clause": repaired_by_id.get(axiom_id, ""),
                "pml_reading": pml_readings_by_id.get(axiom_id, {}),
                "prolog": axiom,
                "evidence": evidence,
                "validator_trace": {
                    "parsed_mode": axiom.get("mode", ""),
                    "parsed_operator": axiom.get("operator", ""),
                    "operator_polarity": axiom.get("polarity", ""),
                    "stated_polarity": axiom.get("stated_polarity", ""),
                    "polarity_status": "matched" if polarity_match else "mismatched",
                    "note": "polarity mismatch is notation-level agreement, not a mathematical contradiction",
                },
            }
        )

    return {
        "transcript_id": transcript.get("transcript_id", ""),
        "markdown_path": transcript.get("markdown_path", ""),
        "response_path": str(response_path),
        "prolog_path": str(prolog_path),
        "utterance_count": len(utterances),
        "profile": validation.get("profile", {}),
        "incompatibilities": validation.get("incompatibilities", []) or [],
        "polarity_mismatches": validation.get("polarity_mismatches", []) or [],
        "passage_modes": validation.get("passage_modes", []) or [],
        "rejected": validation.get("rejected", []) or [],
        "schema_repairs": validation.get("schema_repairs", []) or [],
        "axioms": audit_axioms,
    }


# Order and human-facing labels for the suggestive context registers. The
# truth-checked verdict is rendered SEPARATELY (above this block, from
# math_validation) and is deliberately NOT one of these registers — context is
# suggestive only and never proves a claim (Hard Rule 4).
CONTEXT_REGISTERS: list[tuple[str, str]] = [
    ("literature", "Related literature"),
    ("metaphor", "Metaphor frame"),
    ("standard", "Standard anchor"),
    ("strategy", "Strategy"),
    ("misconception", "Possible misconception"),
    ("grounded", "Grounded context"),
    ("analytic_generated", "Analytic-generated"),
]


def _candidate_summary(provenance: str, candidate: dict[str, Any]) -> str:
    """One-line, register-specific summary of a context candidate."""
    detail = candidate.get("detail", {}) or {}
    concept = candidate.get("concept", "")
    if provenance == "literature":
        body = detail.get("gloss") or detail.get("commitment") or concept
    elif provenance == "metaphor":
        body = f"{detail.get('inference', concept)} via {detail.get('mechanism', '')}".strip(" via")
    elif provenance == "standard":
        body = f"{detail.get('framework', '')} {detail.get('code', '')}: {detail.get('statement', '')}".strip()
    elif provenance == "strategy":
        body = f"{detail.get('kind', concept)} (cluster {detail.get('cluster', '')})"
    elif provenance == "misconception":
        body = f"{detail.get('productive', concept)} -> {detail.get('deformation', '')}"
    elif provenance == "grounded":
        body = detail.get("predicate") or detail.get("mechanism") or concept
    else:
        body = concept
    note = candidate.get("note", "")
    line = f"  * `{concept}` — {body}"
    if note:
        line += f" ({note})"
    return line


def render_context_block(math_context: dict[str, Any]) -> list[str]:
    """Render the suggestive context with the registers SEPARATED.

    The registers are kept distinct from each other and from the truth-checked
    verdict so a reader never mistakes related context for proof of the claim.
    """
    if not math_context:
        return []
    ctx = math_context.get("context", {}) or {}
    lines: list[str] = [
        "",
        "Related context (suggestive only — does not prove the claim):",
    ]
    coverage = math_context.get("coverage_note", "")
    if coverage:
        lines.append(f"- _{coverage}_")
    any_candidate = False
    for key, label in CONTEXT_REGISTERS:
        cands = ctx.get(key, []) or []
        if not cands:
            continue
        any_candidate = True
        lines.append(f"- {label}:")
        for cand in cands:
            lines.append(_candidate_summary(key, cand))
    if not any_candidate:
        lines.append("- (no related context candidates resolved)")
    return lines


def write_audit_markdown(packet: dict[str, Any], path: Path) -> None:
    lines = [
        f"# {packet['transcript_id']} PML Audit",
        "",
        f"- Utterances: {packet['utterance_count']}",
        f"- Polarity mismatches: {packet.get('profile', {}).get('polarity_mismatches', 0)}",
        f"- Incompatibilities: {packet.get('profile', {}).get('incompatibility_count', 0)}",
        "",
        "## Axioms",
    ]
    for axiom in packet.get("axioms", []):
        prolog = axiom.get("prolog", {})
        trace = axiom.get("validator_trace", {})
        lines.extend(
            [
                "",
                f"### {axiom.get('id', '')}: {prolog.get('content', '')}",
                "",
                f"- Raw: `{axiom.get('raw_clause', '')}`",
                f"- Parsed: `{prolog.get('formal', '')}`",
                f"- Mode/operator: `{trace.get('parsed_mode', '')}` / `{trace.get('parsed_operator', '')}`",
                f"- Polarity: operator `{trace.get('operator_polarity', '')}`, stated `{trace.get('stated_polarity', '')}` ({trace.get('polarity_status', '')})",
            "",
            ]
        )
        math_validation = prolog.get("math_validation", {}) or {}
        pml_reading = axiom.get("pml_reading", {}) or {}
        pml = pml_reading.get("pml", {}) if isinstance(pml_reading, dict) else {}
        if pml_reading:
            lines.extend(
                [
                    f"- Normalized text: {pml_reading.get('normalized_text', '')}",
                    f"- PML texture: person `{pml.get('grammatical_person', '')}`, position `{pml.get('position', '')}`, force `{pml.get('force', '')}`, decorative `{pml.get('decorative_wrapper', '')}`",
                    f"- Subject-position read: {pml.get('subject_position_read', '')}",
                ]
            )
        if math_validation:
            lines.append(
                f"- Math validation: `{math_validation.get('status', '')}` / `{math_validation.get('verdict', '')}`"
            )
            if math_validation.get("adjudication"):
                adjudication = f"`{math_validation.get('adjudication', '')}`"
                if math_validation.get("deformation"):
                    adjudication += f" (`{math_validation.get('deformation', '')}`)"
                lines.append(f"- Math adjudication: {adjudication}")
            lines.append(f"- Math checker: `{math_validation.get('checker', math_validation.get('reason', ''))}`")
            trace_lines = math_validation.get("trace", []) or []
            if trace_lines:
                lines.append("- Math trace:")
                for step in trace_lines[:6]:
                    lines.append(f"  * `{step}`")
        # Suggestive related context, rendered with registers SEPARATED and
        # kept distinct from the truth-checked verdict above (Hard Rule 4).
        math_context = prolog.get("math_context", {}) or {}
        lines.extend(render_context_block(math_context))
        lines.extend(
            [
                "",
                "Evidence:",
            ]
        )
        for ev in axiom.get("evidence", []):
            label_parts = [part for part in (ev.get("teacher_tag"), ev.get("student_tag")) if part]
            labels = "; ".join(label_parts) if label_parts else "no TalkMoves label"
            lines.append(f"- `{ev['utterance_id']}` {ev['line']} [{labels}]")
            if ev.get("source_path") or ev.get("sheet") or ev.get("source_row"):
                lines.append(
                    f"  Source: `{ev.get('source_path', '')}` / `{ev.get('sheet', '')}` row `{ev.get('source_row', '')}`"
                )
            dialogact = (ev.get("extra_labels", {}) or {}).get("dialogact", "")
            if dialogact:
                lines.append(f"  Dialog act: `{dialogact}`")
            for win in ev.get("window", []):
                prefix = "  *"
                lines.append(f"{prefix} `{win['utterance_id']}` {win['line']}")
    lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8")


def repair_pml_clause_schema(clauses: list[str]) -> tuple[list[str], list[dict[str, Any]]]:
    repaired: list[str] = []
    repairs: list[dict[str, Any]] = []
    passage_range = re.compile(
        r"^passage_mode\(\s*U(\d{4})\s*-\s*U(\d{4})\s*,\s*([a-z][A-Za-z0-9_]*)\s*,\s*(.*?)\s*\)\.?\s*$"
    )

    for index, clause in enumerate(clauses):
        current = clause
        legacy = repair_legacy_reader_axiom_clause(current)
        if legacy:
            repairs.append(
                {
                    "index": index,
                    "kind": "reader_axiom_legacy_force_tuple",
                    "from": current,
                    "to": legacy,
                }
            )
            current = legacy

        for op, polarity in MODAL_OP_POLARITY.items():
            pattern = rf",\s*{op}\s*(\)\.?\s*)$"
            if re.search(pattern, current):
                current = re.sub(pattern, rf", {polarity}\1", current)
                repairs.append(
                    {
                        "index": index,
                        "kind": "reader_axiom_polarity",
                        "from": op,
                        "to": polarity,
                    }
                )
                break

        match = passage_range.match(current)
        if match:
            start, end, mode, reading = match.groups()
            quoted_reading = reading.strip()
            if not (quoted_reading.startswith('"') and quoted_reading.endswith('"')):
                quoted_reading = json.dumps(quoted_reading, ensure_ascii=False)
            replacement = f"passage_mode(span_u{start}_u{end}, {mode}, {quoted_reading})."
            repairs.append(
                {
                    "index": index,
                    "kind": "passage_mode_span_reading",
                    "from": current,
                    "to": replacement,
                }
            )
            current = replacement

        repaired.append(current)

    return repaired, repairs


def pml_clauses_from_reply(
    reply: str,
) -> tuple[dict[str, Any] | None, list[str], list[str], list[dict[str, Any]], dict[str, Any], str]:
    pml_json = extract_pml_json(reply)
    if pml_json:
        compiled_clauses, compiled_pml_json = compile_pml_json_to_clauses(pml_json)
        if compiled_pml_json.get("readings_by_id"):
            return pml_json, compiled_clauses, compiled_clauses, [], compiled_pml_json, "pml_json"

        legacy_clauses = extract_pml_clauses(reply)
        if legacy_clauses:
            clauses, repairs = repair_pml_clause_schema(legacy_clauses)
            compiled_pml_json["fallback_reason"] = "pml_json_without_readings"
            return pml_json, legacy_clauses, clauses, repairs, compiled_pml_json, "legacy_prolog_clauses"

        return pml_json, compiled_clauses, compiled_clauses, [], compiled_pml_json, "pml_json"

    raw_clauses = extract_pml_clauses(reply)
    clauses, repairs = repair_pml_clause_schema(raw_clauses)
    return extract_final_json(reply), raw_clauses, clauses, repairs, {}, "prolog_clauses"


def prolog_validate_clauses(clauses: list[str]) -> dict[str, Any]:
    if not clauses:
        return {
            "clause_count": 0,
            "valid_count": 0,
            "axioms": [],
            "passage_modes": [],
            "rejected": [],
            "profile": {
                "mode": {"subjective": 0, "objective": 0, "normative": 0},
                "modality": {"necessity": 0, "possibility": 0},
                "polarity": {"compressive": 0, "expansive": 0},
                "dominant_mode": "none",
                "dominant_polarity": "none",
                "polarity_mismatches": 0,
                "incompatibility_count": 0,
                "incoherent_axioms": 0,
            },
            "incompatibilities": [],
        }
    # pml_score_dict/2 lives in the hermes_encyclopedia module; -s loads that
    # module but does not import its exports into `user`, so the call must be
    # module-qualified or it raises existence_error and we lose valid_count.
    goal = (
        "use_module(library(http/json)), "
        f"hermes_encyclopedia:pml_score_dict({json.dumps(clauses)}, D), "
        "json_write_dict(current_output, D, [width(0)]), nl, halt"
    )
    proc = subprocess.run(
        ["swipl", "-q", "-l", "paths.pl", "-s", "hermes/encyclopedia.pl", "-g", goal],
        cwd=Path(__file__).resolve().parents[1],
        text=True,
        capture_output=True,
        check=False,
    )
    if proc.returncode != 0:
        return {
            "error": "swipl_failed",
            "returncode": proc.returncode,
            "stdout": proc.stdout,
            "stderr": proc.stderr,
        }
    output = proc.stdout.strip().splitlines()[-1] if proc.stdout.strip() else "{}"
    return json.loads(output)


def append_jsonl(path: Path, row: dict[str, Any]) -> None:
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n")


def write_summary_csv(path: Path, rows: list[dict[str, Any]]) -> None:
    fields = [
        "transcript_id",
        "split",
        "status",
        "planned_api_calls",
        "actual_api_calls",
        "char_count",
        "authors",
        "openness",
        "discussion_affordance",
        "async_protocol",
        "passage_modes",
        "valid_axioms",
        "rejected_clauses",
        "schema_repairs",
        "polarity_mismatches",
        "incompatibilities",
        "dominant_mode",
        "dominant_polarity",
        "incoherent_axioms",
    ]
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fields})


def read_summary_by_transcript(path: Path) -> dict[str, dict[str, str]]:
    if not path.exists():
        return {}
    with path.open(encoding="utf-8", newline="") as handle:
        return {
            row.get("transcript_id", ""): row
            for row in csv.DictReader(handle)
            if row.get("transcript_id")
        }


def _load_source_anchoring_module() -> Any:
    path = REPO_ROOT / "scripts" / "talkmoves_source_anchoring.py"
    spec = importlib.util.spec_from_file_location("talkmoves_source_anchoring", path)
    module = importlib.util.module_from_spec(spec)
    assert spec and spec.loader
    spec.loader.exec_module(module)
    return module


def write_source_anchoring_outputs(run_dir: Path, blind_root: Path) -> dict[str, Any]:
    anchoring = _load_source_anchoring_module()
    rows = anchoring.build_rows(run_dir, blind_root)
    summary = anchoring.summarize(rows)
    anchor_dir = run_dir / "anchoring"
    anchor_dir.mkdir(parents=True, exist_ok=True)
    rows_path = anchor_dir / "anchoring_rows.csv"
    summary_path = anchor_dir / "anchoring_summary.json"
    with rows_path.open("w", newline="", encoding="utf-8") as handle:
        fieldnames = [
            "transcript_id", "reading_id", "anchor_verdict", "anchor_ratio",
            "valid_axiom", "math_status", "math_adjudication", "raw_text", "normalized_text",
        ]
        writer = csv.DictWriter(handle, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        for row in rows:
            writer.writerow(row)
    summary_path.write_text(json.dumps(summary, indent=2, ensure_ascii=False, sort_keys=True) + "\n", encoding="utf-8")
    return {
        "summary_path": summary_path.relative_to(run_dir).as_posix(),
        "rows_path": rows_path.relative_to(run_dir).as_posix(),
        "total_readings": summary.get("total_readings", 0),
        "anchor_verdicts": summary.get("anchor_verdicts", {}),
    }


def scoreboard_from_rows(rows: list[dict[str, Any]]) -> dict[str, Any]:
    totals = {
        "transcript_count": len(rows),
        "actual_api_calls": sum(int(row.get("actual_api_calls") or 0) for row in rows),
        "valid_axioms": sum(int(row.get("valid_axioms") or 0) for row in rows),
        "rejected_clauses": sum(int(row.get("rejected_clauses") or 0) for row in rows),
        "schema_repairs": sum(int(row.get("schema_repairs") or 0) for row in rows),
        "polarity_mismatches": sum(int(row.get("polarity_mismatches") or 0) for row in rows),
        "incompatibilities": sum(int(row.get("incompatibilities") or 0) for row in rows),
        "incoherent_axioms": sum(int(row.get("incoherent_axioms") or 0) for row in rows),
        "dominant_modes": {},
        "dominant_polarities": {},
        "statuses": {},
    }
    for row in rows:
        for key, bucket in (
            ("dominant_mode", "dominant_modes"),
            ("dominant_polarity", "dominant_polarities"),
            ("status", "statuses"),
        ):
            value = row.get(key) or "unknown"
            totals[bucket][value] = totals[bucket].get(value, 0) + 1
    return totals


def run(args: argparse.Namespace) -> dict[str, Any]:
    root = args.root
    manifest = load_manifest(root)
    selected = select_transcripts(manifest, split=args.split, only=args.only, limit=args.limit)
    if not selected:
        raise SystemExit("No transcripts selected.")

    system_prompt_path = args.system_prompt
    system_prompt = system_prompt_path.read_text(encoding="utf-8")
    run_id = args.run_id or dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    run_dir = args.output_dir / slugify(run_id)
    if args.force and run_dir.exists():
        shutil.rmtree(run_dir)
    previous_summary_by_id = read_summary_by_transcript(run_dir / "summary.csv") if args.reuse_responses else {}
    request_dir = run_dir / "requests"
    response_dir = run_dir / "responses"
    prolog_dir = run_dir / "prolog"
    audit_dir = run_dir / "audit"
    for path in (request_dir, response_dir, prolog_dir, audit_dir):
        path.mkdir(parents=True, exist_ok=True)

    load_dotenv(args.instrument_run)
    key_rows_by_transcript = load_answer_key_rows(
        root,
        {str(row.get("transcript_id", "")) for row in selected},
    )
    summary_rows: list[dict[str, Any]] = []
    summary_jsonl = run_dir / "summary.jsonl"
    if (args.force or args.reuse_responses) and summary_jsonl.exists():
        summary_jsonl.unlink()

    for transcript in selected:
        transcript_id = transcript["transcript_id"]
        md_path = root / transcript["markdown_path"]
        markdown = md_path.read_text(encoding="utf-8")
        user_content, aliases = build_user_content(transcript, markdown, slice_bridge=args.slice_bridge)
        request_path = request_dir / f"{transcript_id}.prompt.md"
        response_path = response_dir / f"{transcript_id}.md"
        prolog_path = prolog_dir / f"{transcript_id}.json"
        if not (args.reuse_responses and request_path.exists()):
            request_path.write_text(user_content, encoding="utf-8")

        planned_calls = 1
        actual_calls = 0
        status = "dry_run"
        reply = ""
        final_json: dict[str, Any] | None = None
        validation: dict[str, Any] = {}
        previous_actual_calls = int(previous_summary_by_id.get(transcript_id, {}).get("actual_api_calls") or 0)

        if args.live or args.reuse_responses:
            if args.reuse_responses:
                if not response_path.exists():
                    raise RuntimeError(f"--reuse-responses requested but response is missing: {response_path}")
                status = "revalidated"
                reply = response_path.read_text(encoding="utf-8")
                actual_calls = previous_actual_calls
            elif response_path.exists() and prolog_path.exists() and not args.force:
                status = "cached"
                reply = response_path.read_text(encoding="utf-8")
            else:
                print(f"scoring {transcript_id} as one transcript-level call", flush=True)
                reply = call_api(system_prompt, user_content, retries=args.retries, timeout=args.timeout)
                response_path.write_text(reply, encoding="utf-8")
                actual_calls = 1
                status = "scored"
            final_json, raw_clauses, clauses, schema_repairs, compiled_pml_json, source_format = pml_clauses_from_reply(reply)
            validation = prolog_validate_clauses(clauses)
            validation["raw_clause_count"] = len(raw_clauses)
            validation["schema_repairs"] = schema_repairs
            if compiled_pml_json:
                validation["compiled_pml_json"] = compiled_pml_json
            validation["source_format"] = source_format
            prolog_path.write_text(json.dumps(validation, indent=2, ensure_ascii=False, sort_keys=True) + "\n", encoding="utf-8")
            audit_packet = build_audit_packet(
                transcript=transcript,
                markdown=markdown,
                raw_clauses=raw_clauses,
                repaired_clauses=clauses,
                validation=validation,
                key_rows=key_rows_by_transcript.get(transcript_id, []),
                response_path=response_path,
                prolog_path=prolog_path,
            )
            (audit_dir / f"{transcript_id}.json").write_text(
                json.dumps(audit_packet, indent=2, ensure_ascii=False, sort_keys=True) + "\n",
                encoding="utf-8",
            )
            write_audit_markdown(audit_packet, audit_dir / f"{transcript_id}.md")

        profile = validation.get("profile", {}) if isinstance(validation, dict) else {}
        score_json = final_json or {}
        row = {
            "transcript_id": transcript_id,
            "split": transcript.get("split", ""),
            "status": status,
            "planned_api_calls": planned_calls,
            "actual_api_calls": actual_calls,
            "char_count": len(user_content),
            "authors": "|".join(score_json.get("authors") or aliases),
            "openness": score_json.get("openness", ""),
            "discussion_affordance": score_json.get("discussion_affordance", ""),
            "async_protocol": score_json.get("async_protocol", ""),
            "passage_modes": summary_passage_modes(score_json.get("passage_modes") or []),
            "valid_axioms": validation.get("valid_count", ""),
            "rejected_clauses": len(validation.get("rejected", []) or []) if isinstance(validation, dict) else "",
            "schema_repairs": len(validation.get("schema_repairs", []) or []) if isinstance(validation, dict) else "",
            "polarity_mismatches": profile.get("polarity_mismatches", ""),
            "incompatibilities": profile.get("incompatibility_count", ""),
            "dominant_mode": profile.get("dominant_mode", ""),
            "dominant_polarity": profile.get("dominant_polarity", ""),
            "incoherent_axioms": profile.get("incoherent_axioms", ""),
            "request_sha256": sha256_text(user_content),
            "system_prompt": str(system_prompt_path),
            "markdown_path": transcript.get("markdown_path", ""),
            "response_path": str(response_path.relative_to(run_dir)) if response_path.exists() else "",
            "prolog_path": str(prolog_path.relative_to(run_dir)) if prolog_path.exists() else "",
        }
        summary_rows.append(row)
        append_jsonl(summary_jsonl, row)

    write_summary_csv(run_dir / "summary.csv", summary_rows)
    scoreboard = scoreboard_from_rows(summary_rows)
    (run_dir / "scoreboard.json").write_text(
        json.dumps(scoreboard, indent=2, ensure_ascii=False, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    run_manifest = {
        "run_id": run_id,
        "live": args.live,
        "root": str(root),
        "split": args.split,
        "selected_count": len(selected),
        "planned_api_calls": len(selected),
        "actual_api_calls": scoreboard["actual_api_calls"],
        "instrument_run": str(args.instrument_run),
        "system_prompt": str(system_prompt_path),
        "output_dir": str(run_dir),
    }
    if args.anchor:
        # The gate must not lose an already-scored run: API calls are spent by
        # this point, so an anchoring failure is recorded in the manifest for
        # the audit trail rather than raised.
        try:
            run_manifest["anchoring"] = write_source_anchoring_outputs(run_dir, root / "blind")
        except Exception as exc:
            run_manifest["anchoring"] = {"error": str(exc)}
    (run_dir / "run_manifest.json").write_text(
        json.dumps(run_manifest, indent=2, ensure_ascii=False, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return run_manifest


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=DEFAULT_ROOT, help="TalkMoves corpus cache root.")
    parser.add_argument("--instrument-run", type=Path, default=DEFAULT_INSTRUMENT_RUN, help="pml-discourse-instrument run directory.")
    parser.add_argument("--system-prompt", type=Path, default=DEFAULT_SYSTEM_PROMPT, help="PML scoring system prompt.")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR, help="Ignored score output root.")
    parser.add_argument("--run-id", help="Stable output run id. Defaults to timestamp.")
    parser.add_argument("--split", choices=["calibration", "validation", "reserve", "all"], default="validation")
    parser.add_argument("--only", help="Comma-separated transcript ids to score.")
    parser.add_argument("--limit", type=int, help="Maximum transcripts to process.")
    parser.add_argument("--live", action="store_true", help="Actually call Reallms/Gemma. Default is dry-run.")
    parser.add_argument("--reuse-responses", action="store_true", help="Recompute Prolog/audit outputs from existing response files without API calls.")
    parser.add_argument(
        "--anchor",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Write source-anchoring summary and rows for the scored run. "
        "On by default: the admission gate is the per-run discipline, not a "
        "manual add-on. --no-anchor declines it.",
    )
    parser.add_argument("--slice-bridge", action="store_true",
                        help="Slice the Big Red bridge to the transcript's detected math domains "
                             "instead of sending the whole bridge to every prompt (default off).")
    parser.add_argument("--force", action="store_true", help="Overwrite/recompute existing outputs in this run.")
    parser.add_argument("--retries", type=int, default=3)
    parser.add_argument("--timeout", type=int, default=600)
    return parser.parse_args()


def main() -> int:
    result = run(parse_args())
    print(json.dumps(result, indent=2, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
