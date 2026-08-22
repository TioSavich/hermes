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
import re
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

# The guide lane's per-row anchors (D1/D2/D7) live under this gitignored
# docling tree. Nothing tracked may hard-require a gitignored input, and a
# rebuild without the tree would hold every guide row as source_missing --
# replacing the only good candidates.jsonl with a degraded one. When the
# tree is absent, main() prints one SKIP line and writes nothing.
GUIDE_DOCLING_ROOT = (
    ROOT / "hermes/app/runtime/experiments/gemma4_tutor/docling/full-output/TeacherLessonGuides"
)
DOCLING_SKIP_LINE = (
    "SKIP build_admission_candidates: docling guide anchors absent; "
    "existing outputs retained"
)

GRADE_TOKENS = ("k", "1", "2", "3", "4", "5", "6", "7", "8")
GRADE_MODULES = tuple(f"grade_{token}_extracted_guide_questions" for token in GRADE_TOKENS)

# A row's text is accepted as interrogative and clean under the same
# character set _middle_question_candidates already strips a guide
# question's trailing quote against (scripts/research/extract_lesson_context
# .py); reused here for both lanes, not reinvented per lane.
QUOTE_AND_SPACE_CHARS = " \t\r\n'\"‘’“”"

# The double-quote glyphs IM's guides print interchangeably: the straight
# quote and the two curly quotes. Measured against the live corpus
# (2026-08-22): the guides wrap one question in mixed pairs -- an opening
# curly closed by a straight quote, two openers closed by one closer, a
# closer used as an opener -- so these three glyphs form ONE wrapper class
# for balance purposes. Which glyph opens and which closes is typesetting,
# not meaning. Apostrophes and single quotes stay outside the class.
QUOTE_WRAPPER_GLYPHS = '"“”'

# When a question's quote never closes inside its extracted span, the
# source itself decides between two readings (2026-08-22 ruling): if the
# printed passage continues past the span and a wrapper glyph follows
# before any structural break, the span cut the quotation short
# (span_truncates_quote); if the source moves on to new content -- a
# bullet, a blank line, a new section -- without ever closing the quote,
# the lone opener is IM's own typography and the text is complete as
# stored. This many characters of source are consulted past the span end.
QUOTE_LOOKAHEAD_WINDOW = 300

# The lower length floor (in glyph-stripped characters) for a question:
# lowered from 8 to 4 on 2026-08-22 so a printed "Why?" admits. The upper
# bound is unchanged.
QUESTION_MIN_CHARS = 4
QUESTION_MAX_CHARS = 500

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


def strip_trailing_glosses(text: str) -> str:
    """Drop trailing parenthesized gloss(es) from a question's text.

    IM prints sample responses and asides in parentheses directly after a
    question -- "What parts did Diego break 4 into? (3 and 1)" -- and those
    ride along verbatim in the stored text. For deciding whether the text
    IS a question, each trailing "(...)" group and its surrounding
    whitespace comes off; interior parentheses stay. If the whole text is
    one parenthesized group, it is kept as it stands rather than emptied.
    """
    result = text.rstrip()
    while result.endswith(")"):
        depth = 0
        start = None
        for index in range(len(result) - 1, -1, -1):
            char = result[index]
            if char == ")":
                depth += 1
            elif char == "(":
                depth -= 1
                if depth == 0:
                    start = index
                    break
        if start is None:
            break
        candidate = result[:start].rstrip()
        if not candidate:
            break
        result = candidate
    return result


def has_sentence_terminal_question(text: str) -> bool:
    """True when the text carries at least one sentence-terminal `?`.

    A question mark is sentence-terminal when what follows it is the end
    of the text, a closing quote glyph, or whitespace and then a capital
    letter or an opening quote (the next printed sentence). A `?` followed
    by a lowercase word or a digit is not one: those are activity titles
    used mid-sentence ("the How Close? center") and counting continuations
    ("What comes next? 4, 5, 6"), and they do not admit a row on their own.
    """
    for index, char in enumerate(text):
        if char != "?":
            continue
        rest = text[index + 1:]
        if not rest:
            return True
        if rest[0] in "\"”’'":
            return True
        if rest[0].isspace():
            following = rest.lstrip()
            if not following:
                return True
            if following[0].isupper() or following[0] in "\"“‘'":
                return True
    return False


def interrogative_form_ok(text: str) -> bool:
    """2026-08-22 widening: a row's text is interrogative when, after its
    trailing parenthesized glosses and outer quotes come off, it carries
    at least one complete printed question. Instructions IM prints after
    the question no longer disqualify the row; text with no sentence-
    terminal question mark at all still does.
    """
    stripped = strip_outer(strip_trailing_glosses(text))
    if not (QUESTION_MIN_CHARS <= len(stripped) <= QUESTION_MAX_CHARS):
        return False
    return has_sentence_terminal_question(stripped)


def quote_glyphs_balanced(text: str) -> bool:
    """Balance over the one wrapper class, honoring mixed typography.

    An even count of wrapper glyphs is balanced regardless of which glyphs
    pair with which. An odd count is still balanced when the text is
    enclosed -- it begins and ends with wrapper glyphs -- and the interior
    (after the enclosing runs) pairs off evenly: IM prints wrappers like
    "..." closed by a curly quote, and a doubled opener with a single
    closer, and neither is a defect. Everything else carries a genuinely
    unpaired quote.
    """
    stripped = text.strip()
    total = sum(1 for char in stripped if char in QUOTE_WRAPPER_GLYPHS)
    if total % 2 == 0:
        return True
    if (
        len(stripped) >= 2
        and stripped[0] in QUOTE_WRAPPER_GLYPHS
        and stripped[-1] in QUOTE_WRAPPER_GLYPHS
    ):
        lead = len(stripped) - len(stripped.lstrip(QUOTE_WRAPPER_GLYPHS))
        trail = len(stripped) - len(stripped.rstrip(QUOTE_WRAPPER_GLYPHS))
        return (total - lead - trail) % 2 == 0
    return False


def unpaired_leading_wrapper(text: str) -> bool:
    """The one imbalance class the source lookahead adjudicates: the text
    opens with a wrapper glyph, and the rest of its quotes pair off evenly
    -- a lone opener with no closer. Any other imbalance stays malformed.
    """
    stripped = text.strip()
    if not stripped or stripped[0] not in QUOTE_WRAPPER_GLYPHS:
        return False
    lead = len(stripped) - len(stripped.lstrip(QUOTE_WRAPPER_GLYPHS))
    rest = sum(1 for char in stripped[lead:] if char in QUOTE_WRAPPER_GLYPHS)
    return rest % 2 == 0


def source_closes_quote(source_text: str, span_end: int) -> bool:
    """Does the printed passage close the row's unclosed quote past its span?

    Consults QUOTE_LOOKAHEAD_WINDOW characters of source beyond the span
    end. A wrapper glyph found there closes the quote only when no
    structural break -- a bullet, a blank line -- stands between the span
    end and the glyph; a glyph past a break belongs to new content (the
    next bulleted question, the next section), which means the source
    itself never closes this quote.
    """
    window = source_text[span_end:span_end + QUOTE_LOOKAHEAD_WINDOW]
    for index, char in enumerate(window):
        if char in QUOTE_WRAPPER_GLYPHS:
            between = window[:index]
            if "•" in between or "◦" in between or "\n\n" in between:
                return False
            return True
    return False


def text_clean_ok(text: str) -> bool:
    if "|" in text:
        return False
    if not quote_glyphs_balanced(text):
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

# The printed heading vocabulary the pipeline already trusts: the heading
# rule's two lists plus the author-heading override titles (all from
# build_assessing_advancing_labels.py, itself carrying
# extract_lesson_context.py:668-681 verbatim). Used by the duplicate-span
# re-derivation below to read the region straight off the source page.
NORMALIZED_REGION_HEADINGS = frozenset(
    label_builder.normalize_heading(heading)
    for heading in (
        label_builder.ASSESSING_HEADINGS
        + label_builder.ADVANCING_HEADINGS
        + tuple(title for _label, title in label_builder.AUTHOR_HEADING_OVERRIDES.values())
    )
)

_COLUMN_GAP = re.compile(r"\s{2,}")


def _line_region_heading(line: str) -> str | None:
    """The region heading this source line prints, if it prints one.

    The K-5 guides are fixed-width, two-column pages: a region heading
    appears either as a line of its own ("Activity Synthesis", possibly
    after a form feed) or as the right-column segment of a shared line
    ("Student Task Statement          Launch"). Segments are split on runs
    of two or more spaces -- the column gap -- and each candidate is
    matched by normalized identity against the trusted heading vocabulary,
    never by resemblance.
    """
    raw = line.lstrip("\x0c").strip()
    if not raw:
        return None
    candidates = [raw]
    parts = _COLUMN_GAP.split(raw)
    if len(parts) > 1:
        candidates.append(parts[0])
        candidates.append(parts[-1])
    for candidate in candidates:
        normalized = label_builder.normalize_heading(candidate)
        if normalized in NORMALIZED_REGION_HEADINGS:
            return normalized
    return None


def nearest_region_heading(source_text: str, char_start: int) -> str | None:
    """The nearest trusted region heading preceding char_start, or None.

    Walks the source line by line and keeps the last heading found on a
    line that starts before char_start. Offsets are UTF-8 character
    offsets, the same convention the spans themselves use.
    """
    found = None
    position = 0
    for line in source_text.split("\n"):
        if position >= char_start:
            break
        heading = _line_region_heading(line)
        if heading is not None:
            found = heading
        position += len(line) + 1
    return found


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

    # A span recorded under two conflicting labels is not left as a mutual
    # duplicate_span hold any more (2026-08-22 ruling): the source page
    # itself decides. The nearest trusted region heading preceding the span
    # re-derives the region; the member whose recorded region matches it
    # clears D7, every other member holds under region_conflict_rederived
    # naming the winner. When no preceding heading exists (the span sits in
    # narrative text before any region structure), every member holds and
    # no winner is named.
    conflict_decisions: dict[str, tuple[str, str | None, list[str]]] = {}
    for (source_path, char_start, _end), group in anchor_groups.items():
        if len(group) < 2:
            continue
        labels_seen = {member["label"] for member in group}
        if len(labels_seen) < 2:
            continue
        full_path = ROOT / source_path
        winner = None
        if full_path.is_file():
            source_text = full_path.read_text(encoding="utf-8", errors="replace")
            winner = nearest_region_heading(source_text, char_start)
        for member in group:
            partners = [other["_id"] for other in group if other is not member]
            matches = (
                winner is not None
                and label_builder.normalize_heading(member["region_type"]) == winner
            )
            verdict = "pass" if matches else "held"
            conflict_decisions[member["_id"]] = (verdict, winner, partners)

    candidates = []
    for row in rows:
        det, held_reason, extra = check_labels_row(row, conflict_decisions)
        candidates.append(render_labels_candidate(row, det, held_reason, extra))
    return candidates


def check_labels_row(
    row: dict[str, Any],
    conflict_decisions: dict[str, tuple[str, str | None, list[str]]],
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

    # D5 text_clean. A lone opening quote with no closer is the one
    # imbalance the source adjudicates (2026-08-22 ruling): when the
    # printed passage closes the quote just past the span, the stored text
    # truncates the quotation and fails its verbatim-completeness claim;
    # when the source itself never closes it, the glyph is IM's own
    # typography and the row continues through the remaining gates.
    if not text_clean_ok(row["text"]):
        if unpaired_leading_wrapper(row["text"]):
            if source_closes_quote(text, row["byte_end"]):
                return "held", "span_truncates_quote", {}
        else:
            return "held", "malformed_text", {}

    # D6 label_rule_rederived
    rederived_label, rederived_origin = rederive_label(row["region_type"])
    stored_origin = row["label_origin"]
    if rederived_label != row["label"] or rederived_origin != stored_origin:
        return "held", "label_rule_mismatch", {
            "rederived_label": rederived_label,
            "rederived_label_origin": rederived_origin,
        }

    # D7 anchor_unique, settled by re-derivation for conflicting groups
    # (see build_labels_candidates): the member matching the source page's
    # own nearest preceding heading passes; the rest hold with the winner
    # named, or with none named when the page carries no heading to read.
    if row["_id"] in conflict_decisions:
        verdict, winner, partners = conflict_decisions[row["_id"]]
        if verdict == "held":
            extra: dict[str, Any] = {"partners": partners}
            if winner is not None:
                extra["winning_region"] = winner
            return "held", "region_conflict_rederived", extra

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


def render_jsonl(rows: list[dict[str, Any]]) -> str:
    lines = [json.dumps(row, ensure_ascii=False, sort_keys=True) for row in rows]
    return "\n".join(lines) + ("\n" if lines else "")


def write_jsonl(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(render_jsonl(rows), encoding="utf-8")


def check_outputs(outputs: list[tuple[str, Path, list[dict[str, Any]]]]) -> int:
    """Compare a fresh in-memory re-derivation against the files on disk.

    Byte comparison is sound here because the build path and this check
    render through the same render_jsonl and the build is deterministic
    (no clock, no model). Re-reading the files alone would certify a stale
    artifact; only a re-derivation catches one.
    """
    failures = []
    for name, path, rows in outputs:
        expected = render_jsonl(rows)
        if not path.is_file():
            print(f"MISSING {name}: {path} does not exist while its sources are "
                  "present -- the builder never ran here; run scripts/regen_all.sh")
            failures.append(f"{name} missing")
            continue
        actual = path.read_text(encoding="utf-8")
        if actual == expected:
            print(f"ok {name}: {len(rows)} rows match a fresh re-derivation ({path})")
            continue
        expected_lines = expected.splitlines()
        actual_lines = actual.splitlines()
        differing = sum(1 for a, b in zip(actual_lines, expected_lines) if a != b)
        differing += abs(len(actual_lines) - len(expected_lines))
        print(f"MISMATCH {name}: {len(actual_lines)} rows on disk, "
              f"{len(expected_lines)} re-derived, {differing} line(s) differ ({path})")
        failures.append(f"{name} mismatch")
    if failures:
        print(
            "FAIL build_admission_candidates --check: " + "; ".join(failures)
            + " -- the sources are present, so scripts/regen_all.sh can settle "
            "the outputs",
            file=sys.stderr,
        )
        return 1
    print("PASS build_admission_candidates --check: all three outputs match a "
          "fresh re-derivation")
    return 0


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
    parser.add_argument(
        "--check", action="store_true",
        help="re-derive all three outputs in memory and compare against the "
             "files on disk; exits nonzero on any missing or differing output",
    )
    args = parser.parse_args()

    # Both the build and the check need the gitignored guide anchors; without
    # them a build would degrade candidates.jsonl and a check would report a
    # mismatch that is really an absent input.
    if not GUIDE_DOCLING_ROOT.is_dir():
        print(DOCLING_SKIP_LINE)
        return 0

    built = build_all()
    outputs = [
        ("candidates", args.candidates, built["candidates"]),
        ("model_input", args.model_input, built["model_input"]),
        ("pilot_key", args.pilot_key, built["pilot_key"]),
    ]

    if args.check:
        return check_outputs(outputs)

    for _name, path, rows in outputs:
        write_jsonl(path, rows)

    print_census(built)
    for _name, path, _rows in outputs:
        print(f"written: {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
