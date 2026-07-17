"""Helpers for the monitoring/ folder.

The pack ships with N103 Smith & Stein 5-Practices monitoring charts under
`monitoring/`, plus a hand-editable `monitoring/INDEX.json` mapping each
`prompt_id` to a chart path (or `null` when no chart fits). The two
functions below provide:

1. `chart_path_for(prompt_id)` — resolve a chart path for a prompt.
2. `pck_section(chart_path)` — pull the teacher-misconceptions block out
   of a chart so we can attach just the PCK-relevant excerpt to a Gemma
   scoring call instead of the whole chart.
"""

from __future__ import annotations

import html as html_lib
import json
import re
from pathlib import Path
from typing import Any, Callable

WorkerRequest = Callable[..., Any]


FALLBACK_HINTS: dict[str, dict[str, object]] = {
    "05_4_disagreement_resolution": {
        "grade_band": "any",
        "tokens": [
            "disagreement", "definition", "counterexample", "quadrilateral",
            "trapezoid", "parallelogram", "inclusive", "exclusive",
        ],
    },
    "3_3_6_grade_1_geometry_lessons_async": {
        "grade_band": [1],
        "tokens": [
            "compose", "decompose", "shapes", "quadrilaterals", "sides",
            "corners", "attributes", "sorting",
        ],
    },
    "4_4_3_grade_2_geometry_lessons_async": {
        "grade_band": [2],
        "tokens": [
            "quadrilaterals", "right", "angles", "rectangles", "attributes",
            "sorting", "building",
        ],
    },
    "5_3_6_grade_3_geometry_lessons_async": {
        "grade_band": [3],
        "tokens": [
            "area", "unit", "decomposition", "rectangle", "rhombus",
            "quadrilateral", "attribute", "angle",
        ],
    },
    "6_1_6_grade_4_geometry_lessons_async": {
        "grade_band": [4],
        "tokens": [
            "polygon", "area", "decompose", "rectangle", "triangle",
            "line", "segment", "parallel", "perpendicular",
        ],
    },
    "7_3_6_grade_5_geometry_lessons_async": {
        "grade_band": [5],
        "tokens": [
            "volume", "unit", "cubes", "rectangular", "prism",
            "dimensions", "quadrilateral", "hierarchy", "attributes",
            "subset",
        ],
    },
    "8_1_2_transformations_first_try_async": {
        "grade_band": [8],
        "tokens": [
            "transformation", "translation", "rotation", "reflection",
            "dilation", "invariant", "command", "shape", "vector",
            "angle", "center", "line",
        ],
    },
}

TOKEN_STOPWORDS = {
    "and", "are", "but", "for", "from", "has", "have", "into", "not",
    "one", "that", "the", "their", "then", "this", "what", "when", "where",
    "which", "with", "would", "you", "your",
}


def load_index(pack_root: Path) -> dict[str, str | None]:
    idx_path = pack_root / "monitoring" / "INDEX.json"
    if not idx_path.exists():
        return {}
    try:
        data = json.loads(idx_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {}
    return {k: v for k, v in data.items() if not k.startswith("_")}


def load_im_codes(pack_root: Path) -> dict[str, str]:
    mapping_path = pack_root / "monitoring" / "im_codes.json"
    if not mapping_path.exists():
        return {}
    try:
        data = json.loads(mapping_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {}
    return {
        k: v
        for k, v in data.items()
        if not k.startswith("_") and isinstance(v, str) and v.startswith("IM-")
    }


def im_code_for(pack_root: Path, prompt_id: str) -> str | None:
    return load_im_codes(pack_root).get(prompt_id)


def chart_path_for(pack_root: Path, prompt_id: str) -> Path | None:
    idx = load_index(pack_root)
    rel = idx.get(prompt_id)
    if not rel:
        return None
    p = pack_root / rel
    return p if p.exists() else None


def prompt_text_for(pack_root: Path, prompt_id: str) -> str:
    prompt_path = pack_root / "prompts" / f"{prompt_id}.html"
    if not prompt_path.exists():
        return prompt_id.replace("_", " ")
    raw = prompt_path.read_text(encoding="utf-8", errors="replace")
    text = re.sub(r"(?s)<script.*?</script>|<style.*?</style>", " ", raw)
    text = re.sub(r"<[^>]+>", " ", text)
    return html_lib.unescape(text)


def fallback_tokens_for(pack_root: Path, prompt_id: str) -> tuple[list[str], object]:
    hint = FALLBACK_HINTS.get(prompt_id, {})
    seed_tokens = [str(t) for t in hint.get("tokens", [])]
    text_tokens = [
        token
        for token in re.findall(r"[a-z0-9]+", prompt_text_for(pack_root, prompt_id).lower())
        if len(token) >= 3 and token not in TOKEN_STOPWORDS
    ]
    seen: set[str] = set()
    tokens = []
    for token in [*seed_tokens, *text_tokens]:
        safe = re.sub(r"[^a-z0-9_]", "", token.lower())
        if safe and safe not in seen:
            seen.add(safe)
            tokens.append(safe)
    return tokens[:80], hint.get("grade_band", "any")


def _geometry_concept_matches(
    worker_request: WorkerRequest,
    tokens: list[str],
    grade_band: object,
) -> dict | None:
    if not tokens:
        return None
    try:
        result = worker_request(
            "geometry",
            predicate="workflow_monitoring_matches",
            args=[tokens, grade_band],
        )
    except Exception:
        return None
    return result if isinstance(result, dict) else None


def _append_term_lines(lines: list[str], label: str, values: list[str]) -> None:
    if not values:
        return
    lines.append(f"  {label}:")
    for value in values:
        lines.append(f"    - {value}")


def format_geometry_fallback(prompt_id: str, data: dict, tokens: list[str]) -> str:
    concepts = data.get("concepts")
    if not isinstance(concepts, list) or not concepts:
        return ""
    lines = [
        "----- PCK CONTEXT (from Prolog geometry concept fallback; use for PCK grounding only) -----",
        f"Prompt: {prompt_id}",
        "Source: geometry/query.pl concept_monitoring_bundle/2 matched from prompt tokens.",
        f"Matched tokens: {', '.join(tokens[:16])}",
        "",
        "## Matched geometry concepts",
    ]
    for concept in concepts:
        if not isinstance(concept, dict):
            continue
        lines.append(
            f"- {concept.get('id')}: {concept.get('name')} "
            f"(topic: {concept.get('topic')}; score: {concept.get('score')})"
        )
        pck = str(concept.get("pck") or "").strip()
        if pck and pck != "none":
            lines.append(f"  PCK synthesis: {pck}")
        _append_term_lines(lines, "standards", concept.get("standards") or [])
        _append_term_lines(lines, "misconceptions", concept.get("misconceptions") or [])
        _append_term_lines(lines, "metaphors", concept.get("metaphors") or [])
        _append_term_lines(lines, "Van Hiele/developmental markers", concept.get("markers") or [])
        _append_term_lines(lines, "developmental arcs", concept.get("arcs") or [])
        lines.append("")
    lines.append("----- END PCK CONTEXT -----")
    lines.append("")
    return "\n".join(lines)


def prolog_fallback_pck(
    pack_root: Path,
    prompt_id: str,
    *,
    worker_request: WorkerRequest,
    timeout: int = 45,
) -> str:
    tokens, grade_band = fallback_tokens_for(pack_root, prompt_id)
    data = _geometry_concept_matches(worker_request, tokens, grade_band)
    if not data:
        return ""
    return format_geometry_fallback(prompt_id, data, tokens)


def monitoring_chart_export(
    pack_root: Path,
    lesson_code: str,
    *,
    worker_request: WorkerRequest,
    timeout: int = 45,
) -> dict | None:
    try:
        result = worker_request("monitoring_chart_export", lesson_code=lesson_code)
    except Exception:
        return None
    return result if isinstance(result, dict) else None


def _fmt_field(label: str, value: object) -> str:
    if value in (None, "", []):
        return ""
    if isinstance(value, list):
        value = ", ".join(str(item) for item in value)
    return f"  {label}: {value}"


def format_prolog_chart(result: dict) -> str:
    lines: list[str] = []

    core = result.get("productive_core")
    if core:
        lines.extend([
            "## Productive core (what to want)",
            str(core),
            "",
        ])

    expressive = result.get("expressive_power")
    if isinstance(expressive, dict):
        lines.append("## Expressive power this lesson puts in play")
        for label, key in (
            ("proof-paths (strategic routes through the action space)", "proof_paths"),
            ("strategy incompatibilities", "strategy_incompatibilities"),
            ("misconception incompatibilities", "misconception_incompatibilities"),
        ):
            field = _fmt_field(label, expressive.get(key))
            if field:
                lines.append(field)
        lines.append("")

    strategies = result.get("anticipated_strategies") or []
    if strategies:
        lines.append("## Anticipated student strategies (elementary children)")
        for strategy in strategies:
            if not isinstance(strategy, dict):
                continue
            name = strategy.get("name") or strategy.get("kind") or "unnamed_strategy"
            lines.append(f"- {name}")
            for label, key in (
                ("operation", "operation"),
                ("source", "source"),
                ("productive", "productive"),
                ("where_to_spot", "where_to_spot"),
            ):
                field = _fmt_field(label, strategy.get(key))
                if field:
                    lines.append(field)
        lines.append("")

    misconceptions = result.get("teacher_misconceptions") or []
    if misconceptions:
        lines.append("## Anticipated preservice/inservice teacher misconceptions")
        # The worker exports both the raw deontic term (commitment_made, ...)
        # and a teacher-language gloss (commitment_made_gloss, ...). This chart
        # feeds prose surfaces, so the gloss wins where the worker supplied
        # one; the raw term remains the fallback for entries without a gloss.
        glossed_keys = {"commitment_made", "entitlement_lacked", "incompatibility"}
        for misconception in misconceptions:
            if not isinstance(misconception, dict):
                continue
            name = misconception.get("name") or "unnamed_misconception"
            lines.append(f"- {name}")
            for label, key in (
                ("operation", "operation"),
                ("commitment_made", "commitment_made"),
                ("entitlement_lacked", "entitlement_lacked"),
                ("incompatibility", "incompatibility"),
                ("citation", "citation"),
                ("re_anchoring_move", "re_anchoring_move"),
            ):
                value = misconception.get(key)
                if key in glossed_keys:
                    gloss = misconception.get(f"{key}_gloss")
                    if gloss not in (None, "", []):
                        value = gloss
                field = _fmt_field(label, value)
                if field:
                    lines.append(field)
        lines.append("")

    pml_facts = result.get("pml_facts") or []
    if pml_facts:
        lines.append("## PML facts")
        seen_facts: set[tuple] = set()
        for fact in pml_facts:
            if not isinstance(fact, dict):
                continue
            fact_id = fact.get("id") or "unnamed_fact"
            # The text interpreter can emit an explicit fact and a generic
            # fallback that coincide; collapse exact duplicates so Gemma's PCK
            # context is not padded with repeats.
            dedup_key = (fact_id, str(fact.get("conclusion")), str(fact.get("polarity")))
            if dedup_key in seen_facts:
                continue
            seen_facts.add(dedup_key)
            lines.append(f"- {fact_id}")
            for label, key in (
                ("polarity", "polarity"),
                ("premises", "premises"),
                ("conclusion", "conclusion"),
            ):
                field = _fmt_field(label, fact.get(key))
                if field:
                    lines.append(field)

    return "\n".join(lines).strip()


def prolog_pck_block(
    pack_root: Path,
    prompt_id: str,
    *,
    worker_request: WorkerRequest,
) -> str:
    lesson_code = im_code_for(pack_root, prompt_id)
    if not lesson_code:
        return ""
    result = monitoring_chart_export(
        pack_root, lesson_code, worker_request=worker_request
    )
    if not result:
        return ""
    excerpt = format_prolog_chart(result)
    if not excerpt:
        return ""
    return (
        "----- PCK CONTEXT (from Prolog monitoring chart; use for PCK Grounding scoring only) -----\n"
        f"Lesson: {lesson_code}\n\n"
        f"{excerpt}\n"
        "----- END PCK CONTEXT -----\n\n"
    )


# Section headers we are willing to extract for PCK context.
SECTION_HEADERS = (
    "Anticipated preservice/inservice teacher misconceptions",
    "Productive core (what to want)",
    "Anticipated student strategies (elementary children",
)


def pck_section(chart_path: Path) -> str:
    """Pull just the teacher-misconceptions block (plus the productive-core
    framing) from a monitoring chart. Returns "" if the chart is missing
    or has no recognized sections."""
    if not chart_path or not chart_path.exists():
        return ""
    text = chart_path.read_text(encoding="utf-8")
    sections: list[str] = []
    for header in SECTION_HEADERS:
        pattern = re.compile(
            rf"(?ms)^(##\s+{re.escape(header)}.*?)(?=^##\s+|\Z)"
        )
        m = pattern.search(text)
        if m:
            sections.append(m.group(1).strip())
    return "\n\n".join(sections).strip()
