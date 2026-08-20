#!/usr/bin/env python3
"""Stage 0 of the mechanical question-admission pipeline: build candidates.

Directive (Tio, 2026-08-20): the two teacher-question stores
(curriculum/im/generated/structure_teacher_question_labels.pl, 9,246 rows,
and the nine curriculum/im/generated/grade_*_extracted_guide_questions.pl
stores, 2,616 rows) sit at review_status(pending_human_review) and will not
receive human review. This script is the first stage of a mechanical
replacement: a deterministic gate that re-derives every per-row claim a row
already makes, named D1-D7 per lane in
.superpowers/sdd/task-0820C-design.md section 2. A row that clears its
lane's gate is a CANDIDATE for one independent model reading (stage 2, on
Big Red); a row that fails is HELD here, with a named reason, and never
reaches the model -- a held-by-determinism row carries no testimony.

This script reads the two source stores directly (not the checkpoints that
built them, which are local-only): it loads each store's Prolog module and
asks SWI-Prolog itself to read back every fact, so the candidate rows are
never a hand-rolled parse of generated Prolog text. Deterministic and
idempotent: the same tracked stores produce byte-identical output twice in
a row; nothing here calls a model or reads the clock.

Two outputs:

  hermes/app/runtime/experiments/questions_admission/candidates.jsonl
      Every row from both source stores, its det verdict (pass/held), its
      held reason when held, and the anchor stage 4 will need to build an
      admitted or held row. char_span is the honest name for what the
      labels-lane source calls byte_start/byte_end (they are UTF-8
      character offsets -- see structure_teacher_question_labels.pl's own
      header); nothing here inherits the misnamed field.

  hermes/app/runtime/experiments/questions_admission/model_input.jsonl
      det=pass rows only, fields id/lane/text and nothing else -- no stored
      label, no region_type, no heading, no lesson code reaches this file.
      Sorted by id (sha order, which also breaks lesson/section adjacency).
      The five L17 human-adjudicated rows (four approved, one culled --
      scripts/research/extract_lesson_context.py REVIEWED_GUIDE_QUESTIONS)
      are excluded from candidacy entirely and never appear in
      candidates.jsonl; they ride this file as sentinels (flagged
      "sentinel": true) so the model pass can be checked against a known
      human reading, never as training signal and never as candidates.

A third output, hermes/app/runtime/experiments/questions_admission/
pilot_key.jsonl, carries id -> stored_label for the rows a downstream
pilot-decision function needs a ground-truth comparison for: the ~200-row
in-job pilot slice (both lanes) plus the five sentinels. It is written here
because the model_input file must never carry a stored label (the leakage
boundary); it is read only by judge.py's pilot-decision function, never by
its prompt builder -- see that script's module docstring for the same
boundary stated from the reading side.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
import tempfile
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.questions import build_assessing_advancing_labels as label_builder  # noqa: E402
from scripts.curriculum import structure_to_task_rows as anchoring  # noqa: E402
from scripts.research import extract_lesson_context as context  # noqa: E402

OUT_DIR = ROOT / "hermes/app/runtime/experiments/questions_admission"
CANDIDATES_PATH = OUT_DIR / "candidates.jsonl"
MODEL_INPUT_PATH = OUT_DIR / "model_input.jsonl"
PILOT_KEY_PATH = OUT_DIR / "pilot_key.jsonl"

GRADE_TOKENS = ("k", "1", "2", "3", "4", "5", "6", "7", "8")
GRADE_MODULES = tuple(f"grade_{token}_extracted_guide_questions" for token in GRADE_TOKENS)

# A row's text is accepted as interrogative and clean under the same
# character set _middle_question_candidates already strips a guide
# question's trailing quote against (scripts/research/extract_lesson_context
# .py); reused here for both lanes, not reinvented per lane.
QUOTE_AND_SPACE_CHARS = " \t\r\n'\"‘’“”"

PILOT_LABELS_TARGET = 150
PILOT_LABELS_MIN_ASSESSING = 40
PILOT_GUIDE_TARGET = 50


# ---------------------------------------------------------------------------
# Stage 0a: read the two tracked stores back through SWI-Prolog itself.
# ---------------------------------------------------------------------------

def _label_origin_json_term() -> str:
    return (
        "( LabelOrigin == machine_classification "
        "-> LabelOriginJson = machine_classification "
        "; LabelOrigin = author_heading(Title) "
        "-> LabelOriginJson = _{kind:author_heading, title:Title} "
        "; throw(error(unknown_label_origin(LabelOrigin), _)) )"
    )


def _dump_script() -> str:
    """A one-shot Prolog program that prints one tagged JSON line per row.

    Loads the labels store and all nine grade stores, none of them
    exporting a colliding name into user because every use_module imports
    nothing ([]) -- every call below is module-qualified. Printed lines are
    "LABEL <json>" or "GUIDE <grade-token> <json>"; the caller splits on the
    first space(s) rather than trusting JSON alone to start a line, so a
    text field that happens to start with a brace cannot be mistaken for
    the tag.
    """
    grade_use_modules = ",\n".join(
        f"    catch(use_module(curriculum/im/generated/{module}, []), _, true)"
        for module in GRADE_MODULES
    )
    grade_dumps = "\n".join(
        "    forall(\n"
        f"        {module}:extracted_lesson_guide_question(Lesson2,\n"
        "            guide_question(Purpose, Text2, source_guide(Source),\n"
        "                source_span(LineStart, LineEnd),\n"
        "                activity_location(Location), label_origin(LabelOrigin2),\n"
        "                review_status(ReviewStatus2), review_evidence(_))),\n"
        "        ( atom_string(LabelOrigin2, LabelOriginAtom2),\n"
        "          D2 = _{lesson:Lesson2, purpose:Purpose, text:Text2,\n"
        "                 source:Source, line_start:LineStart, line_end:LineEnd,\n"
        "                 activity_location:Location,\n"
        "                 label_origin:LabelOriginAtom2,\n"
        "                 review_status:ReviewStatus2},\n"
        f"          format(\"GUIDE {token} \"), json_write_dict(current_output, D2, [width(0)]), nl\n"
        "        )\n"
        "    ),"
        for token, module in zip(GRADE_TOKENS, GRADE_MODULES)
    )
    return f"""
:- use_module(library(http/json)).
:- use_module(curriculum/im/generated/structure_teacher_question_labels, []).
:- ( {grade_use_modules}
   ).
:- initialization(main).

main :-
    set_stream(user_output, encoding(utf8)),
    forall(
        structure_teacher_question_labels:teacher_question_label(Lesson,
            labeled_question(Label, Text, region_type(RegionType),
                source_path(SourcePath), source_file_sha256(Sha),
                source_byte_span(Start, End), label_origin(LabelOrigin),
                review_status(ReviewStatus))),
        ( {_label_origin_json_term()},
          D = _{{lesson:Lesson, label:Label, text:Text,
                region_type:RegionType, source_path:SourcePath,
                source_file_sha256:Sha, byte_start:Start, byte_end:End,
                label_origin:LabelOriginJson, review_status:ReviewStatus}},
          format("LABEL "), json_write_dict(current_output, D, [width(0)]), nl
        )
    ),
{grade_dumps}
    halt.
"""


def dump_prolog_stores() -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    """Read back every row of both source stores via a live SWI-Prolog load.

    This is the store as SWI-Prolog itself parses it -- not a hand-rolled
    regex over generated text -- so a stale or hand-edited .pl file shows up
    as a real row here, which is exactly what D6/D5's re-derivation checks
    need to be meaningful rather than tautological.
    """
    with tempfile.NamedTemporaryFile(
        "w", suffix=".pl", delete=False, encoding="utf-8"
    ) as handle:
        handle.write(_dump_script())
        script_path = Path(handle.name)
    try:
        result = subprocess.run(
            ["swipl", "-q", "-l", "paths.pl", "-l", str(script_path)],
            cwd=ROOT,
            text=True,
            encoding="utf-8",
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
    finally:
        script_path.unlink(missing_ok=True)
    if result.returncode != 0:
        raise RuntimeError(
            "reading back the source stores through SWI-Prolog failed: "
            + (result.stderr or result.stdout)
        )
    label_rows: list[dict[str, Any]] = []
    guide_rows: list[dict[str, Any]] = []
    for line in result.stdout.splitlines():
        if line.startswith("LABEL "):
            label_rows.append(json.loads(line[len("LABEL "):]))
        elif line.startswith("GUIDE "):
            _token, _sp, rest = line[len("GUIDE "):].partition(" ")
            guide_rows.append(json.loads(rest))
        elif line.strip():
            raise RuntimeError(f"unrecognized dump line: {line[:120]!r}")
    if not label_rows or not guide_rows:
        raise RuntimeError(
            f"the store dump came back too small: {len(label_rows)} label rows, "
            f"{len(guide_rows)} guide rows"
        )
    return label_rows, guide_rows


# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

def strip_outer(text: str) -> str:
    return text.strip(QUOTE_AND_SPACE_CHARS)


def interrogative_form_ok(text: str) -> bool:
    stripped = strip_outer(text)
    return stripped.endswith("?") and 8 <= len(stripped) <= 500


def text_clean_ok(text: str) -> bool:
    if "|" in text:
        return False
    if text.count('"') % 2 != 0:
        return False
    if text.count("“") != text.count("”"):
        return False
    if text.startswith("#") or text.startswith("- "):
        return False
    return True


def make_id(prefix: str, parts: list[Any]) -> str:
    joined = "|".join(str(part) for part in parts)
    digest = hashlib.sha256(joined.encode("utf-8")).hexdigest()
    return f"{prefix}-{digest[:12]}"


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


# ---------------------------------------------------------------------------
# Labels lane (store 1): D1-D7
# ---------------------------------------------------------------------------

def rederive_label(region_type: str) -> tuple[str | None, dict[str, Any] | None]:
    """Re-run the 10-line heading rule (reused, not reimplemented).

    Returns (label, label_origin_json) or (None, None) if the region_type
    would be excluded -- which should not happen for a row already in the
    store, since the store only carries labeled rows; a None result here
    is itself the label_rule_mismatch signal.
    """
    if region_type in label_builder.AUTHOR_HEADING_OVERRIDES:
        label, title = label_builder.AUTHOR_HEADING_OVERRIDES[region_type]
        return label, {"kind": "author_heading", "title": title}
    normalized = label_builder.normalize_heading(region_type)
    if normalized in label_builder.ASSESSING_REGION_TYPES:
        return "assessing", "machine_classification"
    if normalized in label_builder.ADVANCING_REGION_TYPES:
        return "advancing", "machine_classification"
    return None, None


def build_labels_candidates(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    # IDs first (needed for the anchor-collision check independent of any
    # row's own D1-D6 outcome), then the collision map across ALL rows.
    #
    # The id hash carries region_type alongside path/span/text -- a finding
    # from running this against the live store: 124 rows share an exact
    # (path, char_span, text) with another row (the source JSONL genuinely
    # repeats itself at those spans), and in 14 of those groups the two
    # copies carry DIFFERENT region_type (sometimes different label_origin
    # too) that both happen to rederive the same label. Hashing on
    # path|start|end|text alone (the design's literal formula) would fold
    # those 14 genuinely-distinct rows onto one id and silently drop one
    # provenance; region_type is the field that actually distinguishes
    # them, so it rides the hash. The remaining ~110 groups are true,
    # content-identical duplicates and are collapsed by id in build_all().
    for row in rows:
        row["_id"] = make_id(
            "tql",
            [row["source_path"], row["byte_start"], row["byte_end"],
             row["region_type"], row["text"]],
        )
    anchor_groups: dict[tuple[str, int, int], list[dict[str, Any]]] = defaultdict(list)
    for row in rows:
        anchor_groups[(row["source_path"], row["byte_start"], row["byte_end"])].append(row)
    colliding_ids: dict[str, list[str]] = {}
    for group in anchor_groups.values():
        if len(group) < 2:
            continue
        labels_seen = {member["label"] for member in group}
        if len(labels_seen) > 1:
            for member in group:
                partners = [other["_id"] for other in group if other is not member]
                colliding_ids[member["_id"]] = partners

    candidates = []
    for row in rows:
        det, held_reason, extra = check_labels_row(row, colliding_ids)
        candidates.append(render_labels_candidate(row, det, held_reason, extra))
    return candidates


def check_labels_row(
    row: dict[str, Any], colliding_ids: dict[str, list[str]]
) -> tuple[str, str | None, dict[str, Any]]:
    source_path = ROOT / row["source_path"]

    # D1 source_present
    if not source_path.is_file():
        return "held", "source_missing", {}

    # D2 source_sha_match
    actual_sha = sha256_file(source_path)
    if actual_sha != row["source_file_sha256"]:
        return "held", "source_sha_drift", {}

    # D3 span_integrity (reused anchoring.find_verbatim)
    text = source_path.read_text(encoding="utf-8", errors="replace")
    span = anchoring.find_verbatim(text, row["text"])
    if span != (row["byte_start"], row["byte_end"]):
        return "held", "span_mismatch", {}

    # D4 interrogative_form
    if not interrogative_form_ok(row["text"]):
        return "held", "not_interrogative", {}

    # D5 text_clean
    if not text_clean_ok(row["text"]):
        return "held", "malformed_text", {}

    # D6 label_rule_rederived
    rederived_label, rederived_origin = rederive_label(row["region_type"])
    stored_origin = row["label_origin"]
    if rederived_label != row["label"] or rederived_origin != stored_origin:
        return "held", "label_rule_mismatch", {
            "rederived_label": rederived_label,
            "rederived_label_origin": rederived_origin,
        }

    # D7 anchor_unique
    if row["_id"] in colliding_ids:
        return "held", "duplicate_span", {"partners": colliding_ids[row["_id"]]}

    return "pass", None, {}


def render_labels_candidate(
    row: dict[str, Any], det: str, held_reason: str | None, extra: dict[str, Any]
) -> dict[str, Any]:
    anchor = {
        "path": row["source_path"],
        "sha256": row["source_file_sha256"],
        "char_span": [row["byte_start"], row["byte_end"]],
        "region_type": row["region_type"],
        "label_origin": row["label_origin"],
        "stored_label": row["label"],
        # The labels lane's family match is definitional: a row only ever
        # enters this store because its region_type already matched a
        # heading family (or an AUTHOR_HEADING_OVERRIDES entry). There is
        # no fallback path here -- that concept belongs to the guide lane
        # (D5), where activity_location is read independently of the label.
        "heading_warrant": "heading_licensed",
    }
    candidate = {
        "id": row["_id"],
        "lane": "labels",
        "lesson": row["lesson"],
        "text": row["text"],
        "det": det,
        "anchor": anchor,
    }
    if held_reason is not None:
        candidate["held_reason"] = held_reason
    if extra:
        candidate["held_detail"] = extra
    return candidate


# ---------------------------------------------------------------------------
# Guide lane (store 2): D1-D7
# ---------------------------------------------------------------------------

def classify_heading_family(activity_location: str) -> str | None:
    normalized = label_builder.normalize_heading(activity_location)
    if normalized in label_builder.ASSESSING_REGION_TYPES:
        return "assessing"
    if normalized in label_builder.ADVANCING_REGION_TYPES:
        return "advancing"
    return None


def build_guide_candidates(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    for row in rows:
        row["_id"] = make_id(
            "gq",
            [row["source"], row["line_start"], row["purpose"], row["text"]],
        )
    key_groups: dict[tuple[str, int, str, str], list[dict[str, Any]]] = defaultdict(list)
    for row in rows:
        key_groups[(row["source"], row["line_start"], row["purpose"], row["text"])].append(row)
    duplicate_ids: dict[str, list[str]] = {}
    for group in key_groups.values():
        if len(group) < 2:
            continue
        for member in group:
            duplicate_ids[member["_id"]] = [
                other["_id"] for other in group if other is not member
            ]

    candidates = []
    for row in rows:
        det, held_reason, extra, doc_sha = check_guide_row(row, duplicate_ids)
        candidates.append(render_guide_candidate(row, det, held_reason, extra, doc_sha))
    return candidates


def check_guide_row(
    row: dict[str, Any], duplicate_ids: dict[str, list[str]]
) -> tuple[str, str | None, dict[str, Any], str | None]:
    source_path = ROOT / row["source"]

    # D1 source_present
    if not source_path.is_file():
        return "held", "source_missing", {}, None

    # D2 span_integrity (reused context.cited_span_contains; \n-split line
    # addressing matches validate_guide_question's own convention)
    try:
        source_lines = source_path.read_text(encoding="utf-8").split("\n")
    except UnicodeError:
        return "held", "source_unreadable", {}, None
    line_start, line_end = row["line_start"], row["line_end"]
    if not (1 <= line_start <= line_end <= len(source_lines)):
        return "held", "span_mismatch", {}, None
    cited_lines = source_lines[line_start - 1: line_end]
    if not context.cited_span_contains(row["text"], cited_lines):
        return "held", "span_mismatch", {}, None

    # D3 interrogative_form
    if not interrogative_form_ok(row["text"]):
        return "held", "not_interrogative", {}, None

    # D4 text_clean
    if not text_clean_ok(row["text"]):
        return "held", "malformed_text", {}, None

    # D5 label_heading_position -- INFORMATIONAL ONLY as of the 2026-08-20
    # positional-serving ruling. This step used to hold a row whose
    # activity_location sat in the family opposite its stored purpose
    # (label_contradicts_heading), because that mismatch would have
    # undercut a served assessing/advancing claim. It no longer gates:
    # under positional serving, a det=pass machine_classification row
    # never asserts that function claim in the first place (it admits as
    # printed_region, carrying the region identity, not the label), so the
    # family mismatch has nothing left to contradict. heading_warrant is
    # still computed and carried for legibility; the emitter reads it as
    # descriptive metadata only.
    family = classify_heading_family(row["activity_location"])
    if family is None:
        heading_warrant = "heading_fallback"
    elif family == row["purpose"]:
        heading_warrant = "heading_licensed"
    else:
        heading_warrant = "heading_contradicts"

    # D6 anchor_unique
    if row["_id"] in duplicate_ids:
        return "held", "duplicate_span", {"partners": duplicate_ids[row["_id"]]}, None

    # D7 doc_sha_pinned
    try:
        doc_sha = sha256_file(source_path)
    except OSError:
        return "held", "source_unreadable", {}, None

    return "pass", None, {"heading_warrant": heading_warrant}, doc_sha


def render_guide_candidate(
    row: dict[str, Any],
    det: str,
    held_reason: str | None,
    extra: dict[str, Any],
    doc_sha: str | None,
) -> dict[str, Any]:
    heading_warrant = extra.pop("heading_warrant", None)
    if heading_warrant is None:
        # A row held before D5 ran (D1-D4) never computed heading_warrant;
        # fill it in the same way D5 itself would, purely for legibility --
        # it no longer gates anything (2026-08-20 positional-serving
        # ruling), so a held row's heading_warrant here is descriptive,
        # never a claim about why the row is held.
        family = classify_heading_family(row["activity_location"])
        if family is None:
            heading_warrant = "heading_fallback"
        elif family == row["purpose"]:
            heading_warrant = "heading_licensed"
        else:
            heading_warrant = "heading_contradicts"
    anchor = {
        "source": row["source"],
        "doc_sha256": doc_sha,
        "line_span": [row["line_start"], row["line_end"]],
        "activity_location": row["activity_location"],
        "label_origin": row["label_origin"],
        "stored_label": row["purpose"],
        "heading_warrant": heading_warrant,
    }
    candidate = {
        "id": row["_id"],
        "lane": "guide",
        "lesson": row["lesson"],
        "text": row["text"],
        "det": det,
        "anchor": anchor,
    }
    if held_reason is not None:
        candidate["held_reason"] = held_reason
    if extra:
        candidate["held_detail"] = extra
    return candidate


# ---------------------------------------------------------------------------
# Sentinels: the five L17 human-adjudicated rows, excluded from candidacy.
# ---------------------------------------------------------------------------

def build_sentinels() -> list[dict[str, Any]]:
    sentinels = []
    for question in context.REVIEWED_GUIDE_QUESTIONS:
        sentinel_id = make_id(
            "tql-sentinel",
            [question.source, question.line_start, question.purpose, question.text],
        )
        sentinels.append({
            "id": sentinel_id,
            "lane": "labels",
            "text": question.text,
            "stored_label": question.purpose,
            "lesson": question.code,
            "review_status": question.review_status,
        })
    return sentinels


# ---------------------------------------------------------------------------
# Pilot stratification (computed here; carried as a flag on model_input.jsonl
# rows because the model_input rows themselves must never carry a label).
# ---------------------------------------------------------------------------

def choose_labels_pilot(sorted_pass_rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    n = min(PILOT_LABELS_TARGET, len(sorted_pass_rows))
    while n < len(sorted_pass_rows):
        chosen = sorted_pass_rows[:n]
        assessing = sum(1 for row in chosen if row["anchor"]["stored_label"] == "assessing")
        if assessing >= PILOT_LABELS_MIN_ASSESSING:
            break
        n += 1
    return sorted_pass_rows[:n]


def choose_guide_pilot(sorted_pass_rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return sorted_pass_rows[: min(PILOT_GUIDE_TARGET, len(sorted_pass_rows))]


def dedupe_by_id(rendered_rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Collapse rows that share an id to one candidate row.

    An id collision here means the source store recorded the exact same
    (path/source, span, [region_type,] text) more than once -- a genuine
    upstream repeat, not two independently meaningful observations (unlike
    the "same text at a different span" case, which is legitimate and
    never touched). Every field a check or the emitter reads is a pure
    function of the id's own hash inputs plus the source row, so true
    duplicates render byte-identical candidates; this asserts that rather
    than assuming it, and raises loudly if it is ever wrong.
    """
    seen: dict[str, dict[str, Any]] = {}
    deduped: list[dict[str, Any]] = []
    for row in rendered_rows:
        prior = seen.get(row["id"])
        if prior is None:
            seen[row["id"]] = row
            deduped.append(row)
        elif json.dumps(row, sort_keys=True) != json.dumps(prior, sort_keys=True):
            raise ValueError(
                f"id collision with differing content, id scheme needs a wider "
                f"key: {row['id']}"
            )
    return deduped


# ---------------------------------------------------------------------------
# Assembly
# ---------------------------------------------------------------------------

def build_all() -> dict[str, Any]:
    label_rows, guide_rows = dump_prolog_stores()
    labels_candidates = dedupe_by_id(
        sorted(build_labels_candidates(label_rows), key=lambda row: row["id"])
    )
    guide_candidates = dedupe_by_id(
        sorted(build_guide_candidates(guide_rows), key=lambda row: row["id"])
    )
    sentinels = sorted(build_sentinels(), key=lambda row: row["id"])

    candidates = labels_candidates + guide_candidates

    labels_pass = [row for row in labels_candidates if row["det"] == "pass"]
    guide_pass = [row for row in guide_candidates if row["det"] == "pass"]
    labels_pilot_ids = {row["id"] for row in choose_labels_pilot(labels_pass)}
    guide_pilot_ids = {row["id"] for row in choose_guide_pilot(guide_pass)}

    model_input = []
    for row in labels_pass:
        entry = {"id": row["id"], "lane": "labels", "text": row["text"]}
        if row["id"] in labels_pilot_ids:
            entry["pilot"] = True
        model_input.append(entry)
    for row in guide_pass:
        entry = {"id": row["id"], "lane": "guide", "text": row["text"]}
        if row["id"] in guide_pilot_ids:
            entry["pilot"] = True
        model_input.append(entry)
    model_input.sort(key=lambda row: row["id"])
    for sentinel in sentinels:
        model_input.append({
            "id": sentinel["id"],
            "lane": sentinel["lane"],
            "text": sentinel["text"],
            "sentinel": True,
        })

    # pilot_key.jsonl: id -> stored_label for every row a downstream
    # pilot-decision function needs a ground-truth comparison for -- the
    # chosen pilot rows in BOTH lanes (kappa is computed per lane) plus the
    # five sentinels (reported, never counted in kappa). Read only by that
    # function, never by judge.py's prompt builder; see this script's
    # module docstring and judge.py's for the same boundary from both sides.
    pilot_key = []
    for row in labels_candidates:
        if row["id"] in labels_pilot_ids:
            pilot_key.append({
                "id": row["id"], "lane": "labels",
                "stored_label": row["anchor"]["stored_label"],
                "pilot": True, "sentinel": False,
            })
    for row in guide_candidates:
        if row["id"] in guide_pilot_ids:
            pilot_key.append({
                "id": row["id"], "lane": "guide",
                "stored_label": row["anchor"]["stored_label"],
                "pilot": True, "sentinel": False,
            })
    for sentinel in sentinels:
        pilot_key.append({
            "id": sentinel["id"], "lane": sentinel["lane"],
            "stored_label": sentinel["stored_label"],
            "pilot": False, "sentinel": True,
        })
    pilot_key.sort(key=lambda row: row["id"])

    return {
        "candidates": candidates,
        "model_input": model_input,
        "pilot_key": pilot_key,
        "labels_candidates": labels_candidates,
        "guide_candidates": guide_candidates,
        "sentinels": sentinels,
        "labels_pilot_count": len(labels_pilot_ids),
        "guide_pilot_count": len(guide_pilot_ids),
    }


def write_jsonl(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = [json.dumps(row, ensure_ascii=False, sort_keys=True) for row in rows]
    path.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")


def print_census(built: dict[str, Any]) -> None:
    for lane, rows in (("labels", built["labels_candidates"]), ("guide", built["guide_candidates"])):
        total = len(rows)
        passed = sum(1 for row in rows if row["det"] == "pass")
        held = Counter(row["held_reason"] for row in rows if row["det"] == "held")
        print(f"== {lane} lane: {total} rows, {passed} det=pass, {total - passed} det=held ==")
        for reason in sorted(held):
            print(f"  held {reason:28s} {held[reason]}")
    print(f"sentinels (excluded from candidacy): {len(built['sentinels'])}")
    print(f"model_input rows: {len(built['model_input'])} "
          f"(labels pilot {built['labels_pilot_count']}, "
          f"guide pilot {built['guide_pilot_count']}, "
          f"sentinels {len(built['sentinels'])})")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--candidates", type=Path, default=CANDIDATES_PATH)
    parser.add_argument("--model-input", type=Path, default=MODEL_INPUT_PATH)
    parser.add_argument("--pilot-key", type=Path, default=PILOT_KEY_PATH)
    args = parser.parse_args()

    built = build_all()
    write_jsonl(args.candidates, built["candidates"])
    write_jsonl(args.model_input, built["model_input"])
    write_jsonl(args.pilot_key, built["pilot_key"])

    print_census(built)
    print(f"written: {args.candidates}")
    print(f"written: {args.model_input}")
    print(f"written: {args.pilot_key}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
