#!/usr/bin/env python3
"""Regression check for the E343 vocabulary-crosswalk substitution-license seed.

``knowledge/crosswalk/vocabulary_licenses.pl`` transcribes the 79-entry, six-
framework crosswalk the owner supplied
(``/Users/tio/Documents/GitHub/Math-Methods/vocabulary_crosswalk_expanded.json``)
into flat ``vocabulary_license/6`` facts.  This check re-derives what those
facts should say directly from the source JSON -- using the same conservative
classification rule documented below -- and compares that expectation against
what the Prolog module actually contains, so a hand edit that drops an entry,
mis-copies a note, or reclassifies a risk cannot pass silently.

It also performs a strict SWI-Prolog load of the module and computes (but
does not apply) a conservative exact/stem join between the license terms and
three read-only surfaces: the automata label census
(``scripts/research/strategy_label_census.py``), and the two lexicon files
(``scripts/research/mobius_band_lexicons.json``,
``scripts/research/brandomian_lexicons.json``).  The join is reported as
candidate counts only; nothing here writes to any of those surfaces.

Classification rule (documented, not just implemented): a framework cell in
the source JSON is treated as carrying no term (``not_addressed``) when its
text contains one of a fixed set of explicit disclaimer markers ("not
addressed", "not specified", "not named", "not distinguished", "not
referenced", "not described", "not directly", "not explicitly", "not used",
"not a curriculum component", "not systematically aligned", "implied via") or
matches one small set of oddball descriptive negatives that do not fit the
"not ..." pattern but still name no term of the framework's own
(``references ccss codes, not indiana codes``).  Every other cell is treated
as carrying a term -- including diffuse, descriptive cells such as "Part of
Connecting practice" or "Embedded in curriculum design (tends toward guided
invention)" that name no proper noun.  This is a mechanical, source-literal
rule, not a semantic judgment about whether a given phrase names a "real"
term; the report accompanying this check names that boundary explicitly.
"""
from __future__ import annotations

import importlib.util
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = ROOT / "knowledge/crosswalk/vocabulary_licenses.pl"
PATHS_PL = ROOT / "paths.pl"
CENSUS_SCRIPT = ROOT / "scripts/research/strategy_label_census.py"
MOBIUS_LEXICON = ROOT / "scripts/research/mobius_band_lexicons.json"
BRANDOMIAN_LEXICON = ROOT / "scripts/research/brandomian_lexicons.json"

# The source repository is read-only from Hermes; this absolute path follows
# the precedent already used for cross-repo, read-only sources (see
# scripts/research/other_curriculum_intake.py's SIBLING constant).
SOURCE_JSON = Path(
    "/Users/tio/Documents/GitHub/Math-Methods/vocabulary_crosswalk_expanded.json"
)

FRAMEWORKS = (
    "van_de_walle",
    "indiana",
    "ccss",
    "illustrative_math",
    "five_practices",
    "cdm",
)
RISK_MAP = {"HIGH": "high", "MEDIUM": "medium", "LOW": "low"}
KIND_SUBSTITUTABLE = "substitutable_in_context"
KIND_DISAMBIGUATION = "disambiguation_required"
KIND_NOT_ADDRESSED = "not_addressed"

NEGATION_MARKERS = (
    "not addressed",
    "not specified",
    "not named",
    "not distinguished",
    "not referenced",
    "not described",
    "not directly",
    "not explicitly",
    "not used",
    "not a curriculum component",
    "not systematically aligned",
    "implied via",
)
SPECIAL_NO_TERM_VALUES = {
    "references ccss codes, not indiana codes",
}


def has_no_term(value: str) -> bool:
    lowered = value.strip().lower()
    if lowered in SPECIAL_NO_TERM_VALUES:
        return True
    return any(marker in lowered for marker in NEGATION_MARKERS)


def expected_kind(risk_key: str, raw_value: str) -> str:
    if has_no_term(raw_value):
        return KIND_NOT_ADDRESSED
    return KIND_DISAMBIGUATION if risk_key == "HIGH" else KIND_SUBSTITUTABLE


def concept_id(index: int) -> str:
    return f"vl{index:03d}"


def pl_escape(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


def pl_unescape(value: str) -> str:
    return value.replace('\\"', '"').replace("\\\\", "\\")


def pl_string(value: str) -> str:
    return f'"{pl_escape(value)}"'


# ---------------------------------------------------------------------------
# Source loading
# ---------------------------------------------------------------------------


def load_source() -> dict:
    if not SOURCE_JSON.exists():
        raise FileNotFoundError(
            f"read-only source not found: {SOURCE_JSON} "
            "(Math-Methods checkout required for this check)"
        )
    data = json.loads(SOURCE_JSON.read_text(encoding="utf-8"))
    entries = data["entries"]
    if len(entries) != data["total_entries"]:
        raise ValueError(
            f"source declares total_entries={data['total_entries']} but has "
            f"{len(entries)} entries"
        )
    return data


# ---------------------------------------------------------------------------
# Prolog module parsing
# ---------------------------------------------------------------------------

STRING = r'"((?:[^"\\]|\\.)*)"'
ATOM = r"([a-z][a-zA-Z0-9_]*)"

SOURCE_FACT_RE = re.compile(
    r"^vocabulary_license_source\('([^']*)',\s*" + STRING + r",\s*" + STRING + r"\)\.$"
)
CONCEPT_FACT_RE = re.compile(
    r"^vocabulary_license_concept\(" + ATOM + r",\s*(\d+),\s*" + STRING + r"\)\.$"
)
NOTE_FACT_RE = re.compile(
    r"^vocabulary_license_note\(" + ATOM + r",\s*" + STRING + r"\)\.$"
)
LICENSE_FACT_RE = re.compile(
    r"^vocabulary_license\("
    + ATOM
    + r",\s*"
    + ATOM
    + r",\s*"
    + STRING
    + r",\s*"
    + ATOM
    + r",\s*"
    + ATOM
    + r",\s*provenance\((\d+),\s*'([^']*)',\s*"
    + STRING
    + r"\)\)\.$"
)


class ParseError(Exception):
    pass


MODULE_DOC_RE = re.compile(r"/\*\*.*?\*/", re.DOTALL)
MODULE_DIRECTIVE_RE = re.compile(r":-\s*module\(.*?\)\.", re.DOTALL)


def strip_preamble(text: str) -> str:
    """Remove the module doc comment and the (multi-line) module/2 directive.

    Both are structural boilerplate, not facts; stripping them as whole
    blocks (rather than trying to track "inside a directive" line by line)
    keeps the per-line fact parser below simple and exact.
    """
    text = MODULE_DOC_RE.sub("", text, count=1)
    text = MODULE_DIRECTIVE_RE.sub("", text, count=1)
    return text


def parse_module(text: str) -> dict:
    source_facts = []
    concepts: dict[str, tuple[int, str]] = {}
    notes: dict[str, str] = {}
    licenses: list[tuple[str, str, str, str, str, int, str, str]] = []
    unparsed: list[str] = []

    for raw_line in strip_preamble(text).splitlines():
        line = raw_line.strip()
        if not line or line.startswith("%") or line.startswith("/*") or line.startswith("*"):
            continue
        match = SOURCE_FACT_RE.match(line)
        if match:
            source_facts.append(
                (match.group(1), pl_unescape(match.group(2)), pl_unescape(match.group(3)))
            )
            continue
        match = CONCEPT_FACT_RE.match(line)
        if match:
            cid, index, text_ = match.groups()
            if cid in concepts:
                raise ParseError(f"duplicate concept fact for {cid}")
            concepts[cid] = (int(index), pl_unescape(text_))
            continue
        match = NOTE_FACT_RE.match(line)
        if match:
            cid, text_ = match.groups()
            if cid in notes:
                raise ParseError(f"duplicate note fact for {cid}")
            notes[cid] = pl_unescape(text_)
            continue
        match = LICENSE_FACT_RE.match(line)
        if match:
            cid, framework, term, risk, kind, prov_index, prov_file, prov_version = (
                match.groups()
            )
            licenses.append(
                (
                    cid,
                    framework,
                    pl_unescape(term),
                    risk,
                    kind,
                    int(prov_index),
                    prov_file,
                    pl_unescape(prov_version),
                )
            )
            continue
        unparsed.append(raw_line)

    if unparsed:
        raise ParseError(
            f"{len(unparsed)} line(s) did not match any known fact shape, e.g. "
            f"{unparsed[0]!r}"
        )

    return {
        "source_facts": source_facts,
        "concepts": concepts,
        "notes": notes,
        "licenses": licenses,
    }


# ---------------------------------------------------------------------------
# Structural validation against the source
# ---------------------------------------------------------------------------


def validate_structure(source_data: dict, parsed: dict) -> list[str]:
    errors: list[str] = []
    entries = source_data["entries"]
    n = len(entries)

    if len(parsed["source_facts"]) != 1:
        errors.append(
            f"expected exactly one vocabulary_license_source/3 fact, found "
            f"{len(parsed['source_facts'])}"
        )
    else:
        file_, version, date = parsed["source_facts"][0]
        if file_ != SOURCE_JSON.name:
            errors.append(f"source fact file mismatch: {file_!r} != {SOURCE_JSON.name!r}")
        if version != source_data["version"]:
            errors.append(f"source fact version mismatch: {version!r} != {source_data['version']!r}")
        if date != source_data["date"]:
            errors.append(f"source fact date mismatch: {date!r} != {source_data['date']!r}")

    expected_ids = {concept_id(i) for i in range(1, n + 1)}
    actual_concept_ids = set(parsed["concepts"])
    if actual_concept_ids != expected_ids:
        missing = expected_ids - actual_concept_ids
        extra = actual_concept_ids - expected_ids
        errors.append(f"concept id set mismatch: missing={sorted(missing)} extra={sorted(extra)}")

    actual_note_ids = set(parsed["notes"])
    if actual_note_ids != expected_ids:
        missing = expected_ids - actual_note_ids
        extra = actual_note_ids - expected_ids
        errors.append(f"note id set mismatch: missing={sorted(missing)} extra={sorted(extra)}")

    for index, entry in enumerate(entries, start=1):
        cid = concept_id(index)
        if cid in parsed["concepts"]:
            got_index, got_text = parsed["concepts"][cid]
            if got_index != index:
                errors.append(f"{cid}: concept index {got_index} != source index {index}")
            if got_text != entry["concept"]:
                errors.append(f"{cid}: concept text does not match source verbatim")
        if cid in parsed["notes"]:
            if parsed["notes"][cid] != entry["note"]:
                errors.append(f"{cid}: note text does not match source verbatim")

    license_by_key: dict[tuple[str, str], tuple] = {}
    for row in parsed["licenses"]:
        cid, framework, term, risk, kind, prov_index, prov_file, prov_version = row
        key = (cid, framework)
        if key in license_by_key:
            errors.append(f"duplicate vocabulary_license fact for {key}")
        license_by_key[key] = row

    expected_pairs = {(concept_id(i), fw) for i in range(1, n + 1) for fw in FRAMEWORKS}
    actual_pairs = set(license_by_key)
    if actual_pairs != expected_pairs:
        missing = expected_pairs - actual_pairs
        extra = actual_pairs - expected_pairs
        errors.append(
            f"license (concept,framework) pair mismatch: "
            f"missing={sorted(missing)[:5]}({len(missing)} total) "
            f"extra={sorted(extra)[:5]}({len(extra)} total)"
        )

    total_expected = n * len(FRAMEWORKS)
    if len(parsed["licenses"]) != total_expected:
        errors.append(
            f"expected {total_expected} vocabulary_license facts, found {len(parsed['licenses'])}"
        )

    allowed_risks = set(RISK_MAP.values())
    allowed_kinds = {KIND_SUBSTITUTABLE, KIND_DISAMBIGUATION, KIND_NOT_ADDRESSED}

    for index, entry in enumerate(entries, start=1):
        cid = concept_id(index)
        risk_key = entry["confusion_risk"]
        expected_risk = RISK_MAP[risk_key]
        for framework in FRAMEWORKS:
            key = (cid, framework)
            row = license_by_key.get(key)
            if row is None:
                continue
            _, _, term, risk, kind, prov_index, prov_file, prov_version = row
            if risk not in allowed_risks:
                errors.append(f"{key}: risk atom {risk!r} not in {sorted(allowed_risks)}")
            if kind not in allowed_kinds:
                errors.append(f"{key}: kind atom {kind!r} not in {sorted(allowed_kinds)}")
            if risk != expected_risk:
                errors.append(
                    f"{key}: risk {risk!r} != expected {expected_risk!r} "
                    f"(source confusion_risk={risk_key!r})"
                )
            raw_value = entry[framework]
            if term != raw_value:
                errors.append(f"{key}: term does not match source verbatim")
            expected = expected_kind(risk_key, raw_value)
            if kind != expected:
                errors.append(f"{key}: kind {kind!r} != expected {expected!r}")
            if prov_index != index:
                errors.append(f"{key}: provenance index {prov_index} != {index}")
            if prov_file != SOURCE_JSON.name:
                errors.append(f"{key}: provenance file {prov_file!r} != {SOURCE_JSON.name!r}")
            if prov_version != source_data["version"]:
                errors.append(
                    f"{key}: provenance version {prov_version!r} != {source_data['version']!r}"
                )

    return errors


# ---------------------------------------------------------------------------
# Strict SWI-Prolog load
# ---------------------------------------------------------------------------


def run_strict_load() -> None:
    goal = "user:ensure_loaded(crosswalk(vocabulary_licenses)), halt."
    result = subprocess.run(
        [
            "swipl",
            "-q",
            "--on-warning=status",
            "--on-error=status",
            "-l",
            str(PATHS_PL),
            "-g",
            goal,
        ],
        cwd=ROOT,
        capture_output=True,
        text=True,
        timeout=120,
    )
    if result.returncode != 0:
        raise RuntimeError(
            "strict SWI load of crosswalk(vocabulary_licenses) failed "
            f"(exit {result.returncode}):\n{result.stdout}\n{result.stderr}"
        )
    combined = result.stdout + result.stderr
    if "ERROR:" in combined or "Warning:" in combined:
        raise RuntimeError(f"strict SWI load emitted diagnostics:\n{combined}")


# ---------------------------------------------------------------------------
# Census + lexicon join (candidates only, never applied)
# ---------------------------------------------------------------------------


def _load_census_module():
    spec = importlib.util.spec_from_file_location(
        "vocabulary_licenses_census_probe", CENSUS_SCRIPT
    )
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


STOPWORDS = frozenset(
    {
        "not", "the", "and", "for", "with", "that", "this", "from", "into",
        "student", "students", "teacher", "teachers", "practice", "practices",
        "standard", "standards", "framework", "frameworks", "addressed",
        "context", "using", "used", "based", "understand", "understanding",
        "concept", "concepts", "grade", "grades", "number", "numbers",
        "problem", "problems", "class", "classroom", "specific",
        "specifically", "named", "name", "phase", "phases", "step", "steps",
        "talk", "moves", "move", "question", "questions", "task", "tasks",
        "activity", "activities", "lesson", "guidance", "section",
        "sections", "component", "components", "which", "when", "where",
        "about", "each", "other", "than", "these", "those", "such", "also",
        "implied", "directly", "explicitly", "referenced", "distinguished",
        "described", "specified", "curriculum", "course", "ppts", "final",
        "exam", "content", "embedded", "during", "after", "before",
        "document", "documents", "progression", "progressions", "domain",
        "domains", "strand", "performance", "related", "assessment",
        "assessments", "observation", "observations", "interview",
        "interviews",
    }
)
WORD_RE = re.compile(r"[a-z]+")


def _content_tokens(text: str, stem) -> frozenset[str]:
    words = WORD_RE.findall(text.lower())
    return frozenset(
        stem(word) for word in words if len(word) >= 4 and word not in STOPWORDS
    )


def _label_tokens(label: str, stem) -> frozenset[str]:
    parts = [p for p in label.split("_") if p]
    return frozenset(
        stem(p) for p in parts if len(p) >= 4 and p not in STOPWORDS
    )


def _load_anchors() -> dict[str, str]:
    mobius = json.loads(MOBIUS_LEXICON.read_text(encoding="utf-8"))
    brandom = json.loads(BRANDOMIAN_LEXICON.read_text(encoding="utf-8"))
    anchors: dict[str, str] = {}
    for kind, phrases in mobius.get("yellow", {}).items():
        for phrase in phrases:
            anchors[phrase] = f"mobius.yellow.{kind}"
    for family_entry in mobius.get("violet", []):
        for phrase in family_entry["phrases"]:
            anchors[phrase] = f"mobius.violet.{family_entry['family']}"
    for kind, phrases in brandom.items():
        for phrase in phrases:
            anchors.setdefault(phrase, f"brandomian.{kind}")
    return anchors


def compute_join(source_data: dict) -> dict:
    census_mod = _load_census_module()
    stem = census_mod.stem_token
    census = census_mod.build_census(census_mod.DEFAULT_REGISTRY, census_mod.DEFAULT_TABLES)
    action_labels = sorted(census["action_labels"]["arities"].keys())
    state_labels = sorted(census["state_labels"]["arities"].keys())
    action_tokens = {label: _label_tokens(label, stem) for label in action_labels}
    state_tokens = {label: _label_tokens(label, stem) for label in state_labels}

    anchors = _load_anchors()
    anchor_tokens = {phrase: _content_tokens(phrase, stem) for phrase in anchors}

    touched_actions: set[str] = set()
    touched_states: set[str] = set()
    touched_anchors: set[str] = set()
    seen_terms: dict[str, tuple[list[str], list[str], list[str]]] = {}
    concepts_with_touch: set[int] = set()

    for index, entry in enumerate(source_data["entries"], start=1):
        for framework in FRAMEWORKS:
            term = entry[framework]
            if term in seen_terms:
                matched_actions, matched_states, matched_anch = seen_terms[term]
            else:
                term_tokens = _content_tokens(term, stem)
                matched_actions = sorted(
                    label
                    for label, toks in action_tokens.items()
                    if toks and toks <= term_tokens
                )
                matched_states = sorted(
                    label
                    for label, toks in state_tokens.items()
                    if toks and toks <= term_tokens
                )
                matched_anch = sorted(
                    phrase
                    for phrase, toks in anchor_tokens.items()
                    if toks and toks <= term_tokens
                )
                seen_terms[term] = (matched_actions, matched_states, matched_anch)
            if matched_actions or matched_states or matched_anch:
                concepts_with_touch.add(index)
            touched_actions.update(matched_actions)
            touched_states.update(matched_states)
            touched_anchors.update(matched_anch)

    return {
        "action_label_total": len(action_labels),
        "state_label_total": len(state_labels),
        "anchor_total": len(anchors),
        "touched_actions": sorted(touched_actions),
        "touched_states": sorted(touched_states),
        "touched_anchors": sorted(touched_anchors),
        "unique_terms_considered": len(seen_terms),
        "terms_with_any_touch": sum(
            1 for v in seen_terms.values() if v[0] or v[1] or v[2]
        ),
        "concepts_with_any_touch": len(concepts_with_touch),
        "concept_total": len(source_data["entries"]),
    }


def run_census_cli_regression() -> None:
    """Confirm the two documented, read-only census invocations still run clean."""
    for args in (["--format", "json"], ["--format", "proposal-csv"]):
        result = subprocess.run(
            [sys.executable, str(CENSUS_SCRIPT), *args],
            cwd=ROOT,
            capture_output=True,
            text=True,
            timeout=120,
        )
        if result.returncode != 0:
            raise RuntimeError(
                f"strategy_label_census.py {' '.join(args)} failed:\n{result.stderr}"
            )


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------


def main() -> int:
    source_data = load_source()
    if not MODULE_PATH.exists():
        print(f"FAIL: {MODULE_PATH} does not exist", file=sys.stderr)
        return 1

    text = MODULE_PATH.read_text(encoding="utf-8")
    try:
        parsed = parse_module(text)
    except ParseError as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1

    errors = validate_structure(source_data, parsed)
    if errors:
        print(f"FAIL: {len(errors)} structural mismatch(es):", file=sys.stderr)
        for error in errors[:25]:
            print(f"  - {error}", file=sys.stderr)
        return 1
    print(
        f"PASS structural round-trip: {len(parsed['concepts'])} concepts, "
        f"{len(parsed['licenses'])} license facts, all provenance-backed"
    )

    run_strict_load()
    print("PASS strict SWI load of crosswalk(vocabulary_licenses)")

    run_census_cli_regression()
    print("PASS census CLI (json + proposal-csv) still runs read-only")

    join_a = compute_join(source_data)
    join_b = compute_join(source_data)
    if json.dumps(join_a, sort_keys=True) != json.dumps(join_b, sort_keys=True):
        print("FAIL: census/lexicon join is not deterministic across two runs", file=sys.stderr)
        return 1
    print("PASS two-run determinism of the census/lexicon join")

    kind_counts = {KIND_SUBSTITUTABLE: 0, KIND_DISAMBIGUATION: 0, KIND_NOT_ADDRESSED: 0}
    for row in parsed["licenses"]:
        kind_counts[row[4]] += 1

    print()
    print("License-kind distribution:")
    for kind in (KIND_SUBSTITUTABLE, KIND_DISAMBIGUATION, KIND_NOT_ADDRESSED):
        print(f"  {kind}: {kind_counts[kind]}")
    print()
    print("Census/lexicon join (candidates only, never auto-applied):")
    print(
        f"  action labels touched: {len(join_a['touched_actions'])}/"
        f"{join_a['action_label_total']}"
    )
    print(
        f"  state labels touched: {len(join_a['touched_states'])}/"
        f"{join_a['state_label_total']}"
    )
    print(
        f"  lexicon anchors touched: {len(join_a['touched_anchors'])}/"
        f"{join_a['anchor_total']}"
    )
    print(
        f"  concept entries with >=1 touch: {join_a['concepts_with_any_touch']}/"
        f"{join_a['concept_total']}"
    )
    print()
    print("PASS vocabulary_licenses check")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
