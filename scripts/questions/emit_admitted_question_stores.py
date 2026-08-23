#!/usr/bin/env python3
"""Stage 4 of the mechanical question-admission pipeline: the emitter.

Reads candidates.jsonl (stage 0's det verdicts and anchors), the tracked
verdict copy of the Big Red model pass (stage 2/3), and pass_void.json if a
lane's independent reading was disqualified before it ever ran. Applies the
agreement rule and the closed held taxonomy from
.superpowers/sdd/task-0820C-design.md sections 3 and 6, and writes two
attributed Prolog stores, byte-stably, never hand-edited:

  curriculum/im/generated/admitted_teacher_question_labels.pl
  curriculum/im/generated/admitted_guide_questions.pl

Each carries admitted/N and held/N rows, a summary fact, valid_testimony/1
(one clause per model/job/date that actually ran), and a self-contained
check_*/0 predicate that re-derives every claim a row makes -- the source
file's sha and the text at its span, the label from a Prolog copy of the
10-line heading rule, and every testimony against valid_testimony/1 --
rather than trusting this script once and never again.

Both stores' headers carry, verbatim, the one sentence that states what
admission licenses and what it does not (design section 5); no downstream
surface's copy may claim more than that sentence does.

--check rebuilds from the same tracked inputs and byte-compares against
what is on disk, exactly like scripts/questions/build_assessing_advancing_
labels.py's own check does for its store today.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from collections import Counter
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.research import extract_lesson_context as context  # noqa: E402

OUT_DIR = ROOT / "hermes/app/runtime/experiments/questions_admission"
DEFAULT_CANDIDATES = OUT_DIR / "candidates.jsonl"
DEFAULT_VERDICTS = ROOT / "curriculum/im/generated/questions_admission_verdicts.jsonl"
DEFAULT_PASS_VOID = OUT_DIR / "pass_void.json"
DEFAULT_OUT_LABELS = ROOT / "curriculum/im/generated/admitted_teacher_question_labels.pl"
DEFAULT_OUT_GUIDE = ROOT / "curriculum/im/generated/admitted_guide_questions.pl"

# Copied verbatim from scripts/bigred/questions_admission/judge.py so the
# emitter can hold the model pass to its own leakage-boundary receipt: every
# verdict row's prompt_sha must match the template that actually shipped.
# Duplicated rather than imported so this stage-4 script has no dependency
# on the stage-2 cluster script; a divergence between the two copies would
# mean the two scripts drifted, which this check would then catch.
LABELS_PROMPT_TEMPLATE = """You are labeling one teacher question from an elementary mathematics
curriculum.

Two labels exist:
- assessing: the question asks a student to explain or show what they did
  or what they currently think; it stays inside the student's existing work.
- advancing: the question presses beyond the student's current work toward
  the mathematical goal - to extend, connect, generalize, or take a next step.

Answer with ONLY a JSON object, no prose around it:
{"label": "assessing" | "advancing" | "cannot_tell"}

"cannot_tell" is an accepted answer when the text alone does not settle it.

QUESTION: {text}
"""

GUIDE_PROMPT_TEMPLATE = """You are reading one line extracted from a teacher lesson guide. Decide what
it is and, only if it is a question a teacher asks students, label its
function.

kind:
- teacher_question: a question the teacher poses to students during the lesson
- activity_title: the name of a game or activity (these may end in a
  question mark)
- student_task_text: text from the student-facing task, not a teacher's
  question
- not_a_question: not interrogative

label (only when kind is teacher_question):
- assessing: the question asks a student to explain or show what they did
  or what they currently think; it stays inside the student's existing work.
- advancing: the question presses beyond the student's current work toward
  the mathematical goal - to extend, connect, generalize, or take a next step.

Answer with ONLY a JSON object, no prose around it:
{"kind": "...", "label": "assessing" | "advancing" | "cannot_tell" | null}

TEXT: {text}
"""

LABELS_PROMPT_SHA = hashlib.sha256(LABELS_PROMPT_TEMPLATE.encode("utf-8")).hexdigest()
GUIDE_PROMPT_SHA = hashlib.sha256(GUIDE_PROMPT_TEMPLATE.encode("utf-8")).hexdigest()

# Positional-serving ruling (Tio, 2026-08-20, mid-session amendment to the
# section 13 amendment): a det=pass row is a VERIFIED FACT regardless of
# label_origin -- its text sits, byte-for-byte, at a sha-pinned location.
# Two distinct things can be licensed from that fact, and this store keeps
# them structurally apart so it can never assert one it has no warrant
# for:
#
#   warrant(im_author_heading)         -- the row's label (assessing or
#     advancing) is IM's own printed section title. Admitted with that
#     label as the row's function claim.
#   warrant(printed_region(Region))    -- the row's region_type
#     (labels lane) or activity_location (guide lane) is a verified
#     position, nothing more. Admitted with region(Region) in the label
#     argument's place -- NEVER an assessing/advancing atom, because nothing
#     here corroborates a function claim for it. Every det=pass
#     machine_classification row admits this way; none of them are held
#     for it any more (pass_void is retired).
#
# The receipt list differs by warrant: an author_heading row's list
# includes label_rule_rederived (its label is re-derived from the heading
# rule and must match) and author_heading_verbatim; a printed_region row's
# list swaps that pair for region_recorded (its region argument is
# re-derived from the anchor's own region field and must match) -- there
# is no label claim left to re-derive.
LABELS_RECEIPT_LIST_AUTHOR_HEADING = [
    "source_sha_verified", "span_reproduces_text", "label_rule_rederived",
    "anchor_unique", "author_heading_verbatim",
]
LABELS_RECEIPT_LIST_PRINTED_REGION = [
    "source_sha_verified", "span_reproduces_text", "region_recorded",
    "anchor_unique",
]
GUIDE_RECEIPT_LIST_AUTHOR_HEADING = [
    "doc_sha_pinned", "span_reproduces_text", "anchor_unique",
    "author_heading_verbatim",
]
GUIDE_RECEIPT_LIST_PRINTED_REGION = [
    "doc_sha_pinned", "span_reproduces_text", "region_recorded",
    "anchor_unique",
]

LABELS_BUILDER_SCRIPT = "scripts/questions/build_assessing_advancing_labels.py"
GUIDE_BUILDER_SCRIPT = "scripts/curriculum/extract_docling_grade.py"

VOID_AMENDMENT_CLAUSE = (
    " A second-reader corroboration was attempted for the assessing/"
    "advancing function claim and voided (kappa 0.02 labels / -0.03 "
    "guide, pilot n=326): a text-only reader does not recover that "
    "function from the text alone. That is why a machine_classification "
    "row is never admitted carrying a function claim here -- it admits "
    "only as printed_region, the verified position where IM prints it, "
    "which carries no function claim to corroborate."
)

LABELS_LICENSE_SENTENCE = (
    "Two admission classes license two different things. An author_heading "
    "row licenses transporting its label (assessing or advancing) as a "
    "fact about where IM prints the question -- a section whose heading "
    "the trusted rule maps to that label, with the text reproduced "
    "verbatim at its pinned span. A printed_region row licenses only the "
    "positional fact: this text sits verbatim at this sha-pinned span, "
    "recorded under this region_type -- it carries no assessing/advancing "
    "claim, and region(...) stands in the label argument's place so the "
    "store cannot assert one."
) + VOID_AMENDMENT_CLAUSE
GUIDE_LICENSE_SENTENCE = (
    "Two admission classes license two different things (see the labels "
    "store's header for the author_heading class; none of these rows "
    "currently carry it). A printed_region row -- every row currently "
    "admitted here -- licenses only the positional fact: this text sits "
    "verbatim at this sha-pinned line span, recorded under this "
    "activity_location. It carries no assessing/advancing claim, and "
    "region(...) stands in the label argument's place so the store cannot "
    "assert one."
) + VOID_AMENDMENT_CLAUSE
MECHANICAL_SENTENCE = (
    "Admission is mechanical: deterministic re-derivation only. An "
    "author_heading row's label is read off IM's own printed heading; a "
    "printed_region row asserts no label at all, only the verified "
    "position where IM prints the text. No person has reviewed these "
    "rows, and no model corroborated either class -- an independent model "
    "reading was attempted as a function-claim corroborator and voided; "
    "its attempt and its void are recorded below, not hidden."
)


# ---------------------------------------------------------------------------
# Prolog rendering helpers (same escaping convention as
# scripts/questions/build_assessing_advancing_labels.py)
# ---------------------------------------------------------------------------

def prolog_atom(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "\\'") + "'"


def prolog_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def model_atom(model_name: str) -> str:
    """gemma-4-26B-A4B-it_Q4_K_M -> gemma_4_26b_a4b_it_q4_k_m."""
    return model_name.lower().replace("-", "_")


def prolog_number_or_none(value: float | int | None) -> str:
    return "none" if value is None else repr(value)


# ---------------------------------------------------------------------------
# I/O
# ---------------------------------------------------------------------------

def load_jsonl(path: Path) -> list[dict[str, Any]]:
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line:
            rows.append(json.loads(line))
    return rows


def load_pass_void(path: Path) -> dict[str, dict[str, Any]]:
    if not path.is_file():
        return {}
    payload = json.loads(path.read_text(encoding="utf-8"))
    return {entry["lane"]: entry for entry in payload.get("lanes", [])}


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


# ---------------------------------------------------------------------------
# Testimony / kappa (kappa duplicated in miniature from judge.py -- the
# emitter's number is the FINAL agreement over every judged row, not the
# pilot-only provisional number judge.py itself printed)
# ---------------------------------------------------------------------------

def cohens_kappa(pairs: list[tuple[str, str]]) -> float | None:
    n = len(pairs)
    if n == 0:
        return None
    categories = sorted({value for pair in pairs for value in pair})
    if len(categories) < 2:
        return None
    observed = sum(1 for a, b in pairs if a == b) / n
    rater_a = Counter(a for a, _ in pairs)
    rater_b = Counter(b for _, b in pairs)
    expected = sum((rater_a[c] / n) * (rater_b[c] / n) for c in categories)
    if expected >= 1.0:
        return 1.0 if observed >= 1.0 else 0.0
    return (observed - expected) / (1 - expected)


# Retained for structural completeness only: valid_testimony/1 in the
# emitted Prolog check still recognizes this shape (model corroboration),
# per the section 13 amendment's own words ("beside the model form"). No
# code path constructs one any more -- verdicts.jsonl decides nothing
# about disposition under either amendment now, and the positional-serving
# ruling retires the one held class (pass_void) that used to attach it.
# render_testimony/check_testimony still accept it if a future ruling ever
# produces one again.

def render_testimony(testimony: dict[str, str]) -> str:
    if testimony["kind"] == "model":
        return (
            f"testimony(model({testimony['model']}), job({prolog_atom(testimony['job'])}), "
            f"date({prolog_atom(testimony['date'])}))"
        )
    if testimony["kind"] == "author_heading":
        return (
            f"testimony(im_author_heading({prolog_atom(testimony['title'])}), "
            f"extraction({prolog_atom(testimony['builder_script'])}), "
            f"date({prolog_atom(testimony['date'])}))"
        )
    if testimony["kind"] == "extraction":
        return (
            f"testimony(extraction({prolog_atom(testimony['builder_script'])}), "
            f"date({prolog_atom(testimony['date'])}))"
        )
    raise ValueError(f"unknown testimony kind: {testimony['kind']}")


def render_testimony_or_none(testimony: dict[str, str] | None) -> str:
    if testimony is None:
        return "testimony_or_none(none)"
    return f"testimony_or_none({render_testimony(testimony)})"


def render_held(reason: str, detail: Any) -> str:
    # Positional-serving ruling: pass_void is retired (every det=pass
    # machine_classification row now admits as printed_region, never
    # held); label_contradicts_heading is retired at stage 0 (it no
    # longer gates candidacy, so it can never reach the emitter); the
    # verdict-based classes (model_disagrees/model_abstains/
    # model_unparseable/not_teacher_question) were already retired by the
    # section 13 amendment, which stopped consulting verdicts for
    # disposition at all. The closed taxonomy going forward is purely
    # deterministic.
    #
    # 2026-08-22 admission pass, two new labels-lane reasons:
    # span_truncates_quote (the span cuts a quotation off before the
    # source closes it) and region_conflict_rederived (one printed span
    # recorded under two region types; the source page's nearest
    # preceding heading re-derived one winner, named in the argument, or
    # no argument when the page carries no heading to read). Keep this
    # set, the two stores' valid_held_reason/1 blocks, and stage 0's
    # reason names in step together.
    bare = {
        "source_missing", "source_sha_drift", "source_unreadable", "span_mismatch",
        "not_interrogative", "malformed_text", "label_rule_mismatch", "duplicate_span",
        "span_truncates_quote",
    }
    if reason in bare:
        return f"held({reason})"
    if reason == "region_conflict_rederived":
        if detail is None:
            return "held(region_conflict_rederived)"
        return f"held(region_conflict_rederived({prolog_atom(detail)}))"
    raise ValueError(f"held reason outside the closed taxonomy: {reason}")


# ---------------------------------------------------------------------------
# Disposition: apply the warrant rule + taxonomy to one lane's candidates
# ---------------------------------------------------------------------------

class Disposed:
    __slots__ = ("row", "kind", "reason", "detail", "testimony", "warrant")

    def __init__(self, row, kind, reason=None, detail=None, testimony=None, warrant=None):
        self.row = row
        self.kind = kind          # "admitted" or "held"
        self.reason = reason      # held reason name, or None for admitted
        self.detail = detail      # held reason argument (atom text), or None
        self.testimony = testimony  # dict or None
        self.warrant = warrant    # ("im_author_heading", None) or
                                   # ("printed_region", RegionOrLocation) or
                                   # ("none", None) for held rows


def disposition_for_row(
    row: dict[str, Any],
    is_guide_lane: bool,
    admission_date: str,
) -> Disposed:
    """Positional-serving ruling (Tio, 2026-08-20): a det=pass row is a
    verified fact -- text at a sha-pinned location -- regardless of
    label_origin. What that fact licenses depends on the warrant:

      - author_heading(...) -> ADMIT, warrant(im_author_heading), label
        argument carries the assessing/advancing atom (IM's own printed
        heading names the function).
      - machine_classification -> ADMIT, warrant(printed_region(Region)),
        label argument carries region(Region) -- NEVER an assessing/
        advancing atom, because nothing here corroborates a function
        claim for it. Region is the row's own region_type (labels lane)
        or activity_location (guide lane).

    Deterministic holds (det=held) are unchanged, except that
    label_contradicts_heading no longer exists as a held class -- it was
    retired at stage 0 (build_admission_candidates.py), which no longer
    gates guide-lane candidacy on activity_location's heading family since
    a printed_region row asserts no function claim for that family
    relationship to contradict.
    """
    if row["det"] == "held":
        detail = None
        if row["held_reason"] == "region_conflict_rederived":
            # The winning region the source page's own heading re-derived,
            # when one exists; a conflict the page could not settle carries
            # no argument.
            detail = row.get("held_detail", {}).get("winning_region")
        return Disposed(row, "held", row["held_reason"], detail, None, ("none", None))

    label_origin = row["anchor"]["label_origin"]
    builder_script = GUIDE_BUILDER_SCRIPT if is_guide_lane else LABELS_BUILDER_SCRIPT

    if label_origin == "machine_classification":
        region_value = (
            row["anchor"]["activity_location"] if is_guide_lane
            else row["anchor"]["region_type"]
        )
        testimony = {
            "kind": "extraction", "builder_script": builder_script, "date": admission_date,
        }
        return Disposed(row, "admitted", None, None, testimony, ("printed_region", region_value))

    title = label_origin["title"]
    testimony = {
        "kind": "author_heading", "title": title,
        "builder_script": builder_script, "date": admission_date,
    }
    return Disposed(row, "admitted", None, None, testimony, ("im_author_heading", None))


def dispose_lane(
    candidates: list[dict[str, Any]],
    is_guide_lane: bool,
    admission_date: str,
) -> list[Disposed]:
    return [disposition_for_row(row, is_guide_lane, admission_date) for row in candidates]


# ---------------------------------------------------------------------------
# Rendering: labels lane
# ---------------------------------------------------------------------------

def render_warrant_term(warrant: tuple[str, Any], region_render_fn) -> str:
    kind, value = warrant
    if kind == "im_author_heading":
        return "warrant(im_author_heading)"
    if kind == "printed_region":
        return f"warrant(printed_region({region_render_fn(value)}))"
    if kind == "none":
        return "warrant(none)"
    raise ValueError(f"unknown warrant kind: {kind}")


def render_labels_anchor(anchor: dict[str, Any], warrant: tuple[str, Any]) -> str:
    label_origin = anchor["label_origin"]
    if label_origin == "machine_classification":
        lo_term = "label_origin(machine_classification)"
    else:
        lo_term = f"label_origin(author_heading({prolog_atom(label_origin['title'])}))"
    return (
        f"anchor(source_path({prolog_atom(anchor['path'])}), "
        f"source_file_sha256({prolog_atom(anchor['sha256'])}), "
        f"char_span({anchor['char_span'][0]}, {anchor['char_span'][1]}), "
        f"region_type({prolog_atom(anchor['region_type'])}), "
        f"{lo_term}, "
        f"{render_warrant_term(warrant, prolog_atom)})"
    )


def render_labels_admitted_row(item: Disposed) -> str:
    row = item.row
    kind, value = item.warrant
    if kind == "im_author_heading":
        label_term = row["anchor"]["stored_label"]
        receipt = LABELS_RECEIPT_LIST_AUTHOR_HEADING
    else:
        label_term = f"region({prolog_atom(value)})"
        receipt = LABELS_RECEIPT_LIST_PRINTED_REGION
    receipt_str = "[" + ", ".join(receipt) + "]"
    return (
        f"admitted_question_label(\n"
        f"    {prolog_atom(row['lesson'])},\n"
        f"    {label_term},\n"
        f"    {prolog_string(row['text'])},\n"
        f"    {render_labels_anchor(row['anchor'], item.warrant)},\n"
        f"    {render_testimony(item.testimony)},\n"
        f"    receipt(swipl_test({receipt_str}))).\n"
    )


def render_labels_held_row(item: Disposed) -> str:
    row = item.row
    stored_label = row["anchor"]["stored_label"]
    return (
        f"held_question_label(\n"
        f"    {prolog_atom(row['lesson'])},\n"
        f"    {stored_label},\n"
        f"    {prolog_string(row['text'])},\n"
        f"    {render_labels_anchor(row['anchor'], item.warrant)},\n"
        f"    {render_testimony_or_none(item.testimony)},\n"
        f"    {render_held(item.reason, item.detail)}).\n"
    )


# ---------------------------------------------------------------------------
# Rendering: guide lane
# ---------------------------------------------------------------------------

def render_guide_anchor(anchor: dict[str, Any], warrant: tuple[str, Any]) -> str:
    label_origin = anchor["label_origin"]
    lo_term = (
        "label_origin(machine_classification)"
        if label_origin == "machine_classification"
        else f"label_origin(author_heading({prolog_atom(label_origin['title'])}))"
    )
    doc_sha = anchor["doc_sha256"]
    doc_sha_term = prolog_atom(doc_sha) if doc_sha is not None else "none"
    return (
        f"anchor(source_guide({prolog_atom(anchor['source'])}), "
        f"doc_sha256({doc_sha_term}), "
        f"line_span({anchor['line_span'][0]}, {anchor['line_span'][1]}), "
        f"activity_location({prolog_string(anchor['activity_location'])}), "
        f"{lo_term}, "
        f"{render_warrant_term(warrant, prolog_string)})"
    )


def render_guide_admitted_row(item: Disposed) -> str:
    row = item.row
    kind, value = item.warrant
    if kind == "im_author_heading":
        label_term = row["anchor"]["stored_label"]
        receipt = GUIDE_RECEIPT_LIST_AUTHOR_HEADING
    else:
        label_term = f"region({prolog_string(value)})"
        receipt = GUIDE_RECEIPT_LIST_PRINTED_REGION
    receipt_str = "[" + ", ".join(receipt) + "]"
    return (
        f"admitted_guide_question(\n"
        f"    {prolog_atom(row['lesson'])},\n"
        f"    {label_term},\n"
        f"    {prolog_string(row['text'])},\n"
        f"    {render_guide_anchor(row['anchor'], item.warrant)},\n"
        f"    {render_testimony(item.testimony)},\n"
        f"    receipt(swipl_test({receipt_str}))).\n"
    )


def render_guide_held_row(item: Disposed) -> str:
    row = item.row
    stored_label = row["anchor"]["stored_label"]
    return (
        f"held_guide_question(\n"
        f"    {prolog_atom(row['lesson'])},\n"
        f"    {stored_label},\n"
        f"    {prolog_string(row['text'])},\n"
        f"    {render_guide_anchor(row['anchor'], item.warrant)},\n"
        f"    {render_testimony_or_none(item.testimony)},\n"
        f"    {render_held(item.reason, item.detail)}).\n"
    )


# ---------------------------------------------------------------------------
# Static Prolog check code (no per-row interpolation; identical every run)
# ---------------------------------------------------------------------------

SHARED_HEADING_RULE_CODE = """
% The heading rule, carried a second time. Copied from
% scripts/questions/build_assessing_advancing_labels.py, itself copied
% from scripts/research/extract_lesson_context.py:668-681. A divergence
% between the two copies is exactly what this re-derivation is for.
assessing_heading_normalized('building_on_student_thinking').
assessing_heading_normalized('responding_to_student_thinking').
assessing_heading_normalized(launch).
assessing_heading_normalized(activity_narrative).
assessing_heading_normalized(math_community).
assessing_heading_normalized('consider_asking').
assessing_heading_normalized('discuss_with_students').
advancing_heading_normalized(activity_synthesis).
advancing_heading_normalized(lesson_synthesis).
advancing_heading_normalized('more_chances').

% Controller ruling 2026-08-18 (see the builder's docstring): the one
% region_type whose string is itself a published IM section title naming
% a questioning function directly, not a resemblance to another name.
author_heading_override_region(advancing_student_thinking, advancing,
                               'Advancing Student Thinking').

normalize_heading_text(Value0, Normalized) :-
    ( atom(Value0) -> atom_string(Value0, S0) ; S0 = Value0 ),
    split_string(S0, "", " \\t\\r\\n", [S1]),
    ( string_concat(S2, ":", S1) -> true ; S2 = S1 ),
    split_string(S2, "", " \\t\\r\\n", [S3]),
    string_lower(S3, S4),
    string_chars(S4, Chars0),
    maplist(space_or_hyphen_to_underscore, Chars0, Chars1),
    string_chars(S5, Chars1),
    atom_string(Normalized, S5).

space_or_hyphen_to_underscore(' ', '_') :- !.
space_or_hyphen_to_underscore('-', '_') :- !.
space_or_hyphen_to_underscore(C, C).

rederive_label_from_region_type(RegionType, Label, LabelOriginTerm) :-
    ( author_heading_override_region(RegionType, Label0, Title)
    -> Label = Label0,
       LabelOriginTerm = label_origin(author_heading(Title))
    ;  normalize_heading_text(RegionType, Normalized),
       ( assessing_heading_normalized(Normalized) -> Label = assessing
       ; advancing_heading_normalized(Normalized) -> Label = advancing
       ),
       LabelOriginTerm = label_origin(machine_classification)
    ).

%  Collapses whitespace runs to one space -- the guide lane's tolerance
%  (scripts/research/extract_lesson_context.py normalized_source_text:
%  " ".join(value.split())), used to reproduce cited_span_contains.
normalize_whitespace_runs(Value, Normalized) :-
    ( atom(Value) -> atom_string(Value, S) ; S = Value ),
    split_string(S, " \\t\\r\\n", "", Parts0),
    exclude(==(""), Parts0, Parts1),
    ( Parts1 == [] -> Normalized = '' ; atomic_list_concat(Parts1, ' ', Normalized) ).

%  Strips whitespace entirely -- the labels lane's tolerance
%  (scripts/curriculum/structure_to_task_rows.py find_verbatim's fallback
%  joins needle words with a \\s* regex, which tolerates ANY amount of
%  source whitespace between them, including none). A finding while
%  writing this check: 'IM-G5-U6-L7' has a row whose text says "264 1/2"
%  and whose source column-extract says "2641/2" with no separating space
%  at all -- normalize_whitespace_runs (single-space collapse) calls that
%  a mismatch; only whitespace removed entirely reproduces find_verbatim's
%  own, more tolerant, rule.
normalize_strip_whitespace(Value, Normalized) :-
    ( atom(Value) -> atom_string(Value, S) ; S = Value ),
    split_string(S, " \\t\\r\\n", "", Parts0),
    exclude(==(""), Parts0, Parts1),
    atomic_list_concat(Parts1, '', Normalized).

file_sha256_hex(Path, HexAtom) :-
    read_file_to_string(Path, Content, [encoding(utf8)]),
    sha_hash(Content, Hash, [algorithm(sha256), encoding(utf8)]),
    hash_atom(Hash, HexAtom).

%  Section 13 amendment: two honest testimony shapes now exist --
%  model-corroboration (kept alive for held rows a pilot judged before its
%  lane voided) and author-heading (the only shape an admitted row may
%  carry). Checked and validated against valid_testimony/1 generically, so
%  neither the admitted-row check nor the held-row check has to special-
%  case which shape it is looking at beyond this one call.
check_testimony(ErrorTag, Testimony) :-
    ( Testimony = testimony(model(Model), job(Job), date(Date))
    -> atom(Model), atom(Job), atom(Date)
    ;  Testimony = testimony(im_author_heading(Title), extraction(Script), date(Date))
    -> atom(Title), atom(Script), atom(Date)
    ;  Testimony = testimony(extraction(Script2), date(Date2))
    -> atom(Script2), atom(Date2)
    ;  MalformedTerm =.. [ErrorTag, malformed_testimony(Testimony)],
       throw(error(MalformedTerm, _))
    ),
    ( valid_testimony(Testimony)
    -> true
    ;  BadTerm =.. [ErrorTag, bad_testimony(Testimony)],
       throw(error(BadTerm, _))
    ).
"""

LABELS_CHECK_CODE_TEMPLATE = """
:- use_module(library(sha)).
:- use_module(library(pairs)).
""" + SHARED_HEADING_RULE_CODE + """
%! check_admitted_question_labels is det.
%
%  Re-derives every claim this store makes: source sha, span-reproduces-
%  text (whitespace-run normalized), the warrant-appropriate claim (an
%  author_heading row's label re-derived from the heading rule; a
%  printed_region row's region argument re-derived from its own anchor
%  field), testimony against valid_testimony/1, receipts against the
%  warrant's fixed list, held reasons against the closed taxonomy, anchor
%  consistency among author_heading rows (no two admitted author_heading
%  rows at one anchor may disagree; a span recorded under two conflicting
%  region types admits at most its re-derived winner, the rest holding
%  region_conflict_rederived -- printed_region rows assert no label to
%  conflict over, so they are not checked here),
%  and the summary counts against the rows themselves. Throws a named
%  error on the first claim that fails to reproduce.
check_admitted_question_labels :-
    findall(Row, admitted_question_label(_, _, _, _, _, _), AdmittedRows),
    findall(Row, held_question_label(_, _, _, _, _, _), HeldRows),
    forall(admitted_question_label(L, La, T, A, Te, R),
           check_admitted_labels_row(L, La, T, A, Te, R)),
    forall(held_question_label(L, La, T, A, To, H),
           check_held_labels_row(L, La, T, A, To, H)),
    check_labels_anchor_consistency,
    check_labels_summary,
    length(AdmittedRows, AdmittedCount),
    length(HeldRows, HeldCount),
    format('check_admitted_question_labels: ~d admitted, ~d held, all receipts passed~n',
           [AdmittedCount, HeldCount]).

check_admitted_labels_row(Lesson, LabelArg, Text,
        anchor(source_path(SourcePath), source_file_sha256(Sha256),
               char_span(Start, End), region_type(RegionType), LabelOriginTerm,
               warrant(Warrant)),
        Testimony,
        receipt(swipl_test(ReceiptList))) :-
    % The warrant decides everything else about this row's shape: which
    % receipt list, what the label argument may hold, what testimony shape
    % is legal, and what the anchor's label_origin must say.
    ( Warrant == im_author_heading
    -> ExpectedReceipt = [source_sha_verified, span_reproduces_text,
                          label_rule_rederived, anchor_unique, author_heading_verbatim],
       ( memberchk(LabelArg, [assessing, advancing])
       -> true
       ;  throw(error(admitted_teacher_question_labels(
                       author_heading_label_not_function(Lesson, LabelArg)), _))
       ),
       ( Testimony = testimony(im_author_heading(HeadingTitle), extraction(BuilderScript), date(_))
       -> true
       ;  throw(error(admitted_teacher_question_labels(
                       admitted_row_not_author_heading(Lesson, Testimony)), _))
       ),
       atom(HeadingTitle), atom(BuilderScript),
       ( LabelOriginTerm == label_origin(author_heading(HeadingTitle))
       -> true
       ;  throw(error(admitted_teacher_question_labels(
                       heading_title_mismatch(Lesson, LabelOriginTerm, HeadingTitle)), _))
       ),
       rederive_label_from_region_type(RegionType, RederivedLabel, RederivedOrigin),
       ( RederivedLabel == LabelArg
       -> true
       ;  throw(error(admitted_teacher_question_labels(
                       label_rule_mismatch(Lesson, RederivedLabel, LabelArg)), _))
       ),
       ( RederivedOrigin == LabelOriginTerm
       -> true
       ;  throw(error(admitted_teacher_question_labels(
                       label_origin_mismatch(Lesson, RederivedOrigin, LabelOriginTerm)), _))
       )
    ;  Warrant = printed_region(RegionArg)
    -> ExpectedReceipt = [source_sha_verified, span_reproduces_text,
                          region_recorded, anchor_unique],
       % The label argument NEVER carries assessing/advancing for a
       % printed_region row -- structurally it cannot, since this is the
       % one place that would happen and it is required to be region(_).
       ( LabelArg == region(RegionArg)
       -> true
       ;  throw(error(admitted_teacher_question_labels(
                       printed_region_label_not_region(Lesson, LabelArg)), _))
       ),
       ( LabelOriginTerm == label_origin(machine_classification)
       -> true
       ;  throw(error(admitted_teacher_question_labels(
                       printed_region_not_machine_classification(Lesson, LabelOriginTerm)), _))
       ),
       ( RegionArg == RegionType
       -> true
       ;  throw(error(admitted_teacher_question_labels(
                       region_recorded_mismatch(Lesson, RegionArg, RegionType)), _))
       ),
       ( Testimony = testimony(extraction(BuilderScript2), date(_))
       -> atom(BuilderScript2)
       ;  throw(error(admitted_teacher_question_labels(
                       printed_region_bad_testimony_shape(Lesson, Testimony)), _))
       )
    ;  throw(error(admitted_teacher_question_labels(bad_warrant(Lesson, Warrant)), _))
    ),
    ( ReceiptList == ExpectedReceipt
    -> true
    ;  throw(error(admitted_teacher_question_labels(bad_receipt(Lesson, ReceiptList)), _))
    ),
    check_testimony(admitted_teacher_question_labels, Testimony),
    ( exists_file(SourcePath)
    -> true
    ;  throw(error(admitted_teacher_question_labels(source_missing(Lesson, SourcePath)), _))
    ),
    file_sha256_hex(SourcePath, ActualSha),
    ( ActualSha == Sha256
    -> true
    ;  throw(error(admitted_teacher_question_labels(sha_drift(Lesson, SourcePath)), _))
    ),
    read_file_to_string(SourcePath, Content, [encoding(utf8)]),
    Length is End - Start,
    ( Start >= 0, Length >= 0, string_length(Content, ContentLen), End =< ContentLen
    -> true
    ;  throw(error(admitted_teacher_question_labels(span_out_of_range(Lesson, Start, End)), _))
    ),
    sub_string(Content, Start, Length, _, Sub),
    normalize_strip_whitespace(Sub, NormSub),
    normalize_strip_whitespace(Text, NormText),
    ( NormSub == NormText
    -> true
    ;  throw(error(admitted_teacher_question_labels(span_mismatch(Lesson, Start, End)), _))
    ).

check_held_labels_row(Lesson, _StoredLabel, _Text, _Anchor,
        testimony_or_none(TestimonyOrNone), held(Reason)) :-
    % Every held row's testimony_or_none is none under the current
    % (purely deterministic) closed taxonomy; the model shape stays
    % supported here for the same structural-completeness reason
    % render_testimony/check_testimony keep it.
    ( TestimonyOrNone == none
    -> true
    ;  check_testimony(admitted_teacher_question_labels, TestimonyOrNone)
    ),
    ( valid_held_reason(Reason)
    -> true
    ;  throw(error(admitted_teacher_question_labels(bad_held_reason(Lesson, Reason)), _))
    ).

% duplicate_span is extinct in this lane as of the 2026-08-22 admission
% pass: a span recorded under two conflicting region types is settled by
% the source page's own nearest preceding heading -- the matching row
% admits, the rest hold under region_conflict_rederived, which names the
% winning region when the page carries a heading to read and no argument
% when it does not. span_truncates_quote holds a row whose span cuts a
% quotation off before the source closes it.
valid_held_reason(source_missing).
valid_held_reason(source_sha_drift).
valid_held_reason(span_mismatch).
valid_held_reason(not_interrogative).
valid_held_reason(malformed_text).
valid_held_reason(label_rule_mismatch).
valid_held_reason(span_truncates_quote).
valid_held_reason(region_conflict_rederived).
valid_held_reason(region_conflict_rederived(Region)) :- atom(Region).

%  No two admitted author_heading rows at the same anchor may disagree
%  (a span recorded under two conflicting region types admits at most the
%  member the source page's own heading re-derived; the rest hold
%  region_conflict_rederived). Scoped to warrant(im_author_heading) rows only:
%  printed_region rows assert no label (their argument is region(_), not
%  assessing/advancing), so two of them differing in region at a shared
%  span is not a contradiction the way a differing function claim would
%  be, and is not checked here.
check_labels_anchor_consistency :-
    findall((SourcePath, Start, End)-Label,
            admitted_question_label(_, Label, _,
                anchor(source_path(SourcePath), _, char_span(Start, End), _, _,
                       warrant(im_author_heading)), _, _),
            AdmittedEntries),
    keysort(AdmittedEntries, Sorted),
    group_pairs_by_key(Sorted, Groups),
    forall(member(_-Labels, Groups), check_labels_anchor_group(Labels)).

check_labels_anchor_group(Labels) :-
    sort(Labels, Distinct),
    ( Distinct = [_]
    -> true
    ;  throw(error(admitted_teacher_question_labels(
                    conflicting_admitted_labels_at_anchor(Labels)), _))
    ).

check_summary_field(ErrorTag, Dict, Key, Expected) :-
    get_dict(Key, Dict, Actual),
    ( Actual == Expected
    -> true
    ;  ErrorTerm =.. [ErrorTag, summary_field_mismatch(Key, Expected, Actual)],
       throw(error(ErrorTerm, _))
    ).

check_labels_summary :-
    admitted_question_labels_summary(Summary),
    aggregate_all(count, admitted_question_label(_, _, _, _, _, _), AdmittedCount),
    aggregate_all(count, held_question_label(_, _, _, _, _, _), HeldCount),
    check_summary_field(admitted_teacher_question_labels, Summary, admitted, AdmittedCount),
    check_summary_field(admitted_teacher_question_labels, Summary, held, HeldCount),
    aggregate_all(count,
                   admitted_question_label(_, _, _,
                       anchor(_, _, _, _, _, warrant(im_author_heading)), _, _),
                   AuthorHeadingCount),
    aggregate_all(count,
                   admitted_question_label(_, _, _,
                       anchor(_, _, _, _, _, warrant(printed_region(_))), _, _),
                   PrintedRegionCount),
    check_summary_field(admitted_teacher_question_labels, Summary,
                         admitted_im_author_heading, AuthorHeadingCount),
    check_summary_field(admitted_teacher_question_labels, Summary,
                         admitted_printed_region, PrintedRegionCount),
    AuthorHeadingCount + PrintedRegionCount =:= AdmittedCount,
    aggregate_all(count,
                   admitted_question_label(_, assessing, _,
                       anchor(_, _, _, _, _, warrant(im_author_heading)), _, _),
                   AssessingCount),
    aggregate_all(count,
                   admitted_question_label(_, advancing, _,
                       anchor(_, _, _, _, _, warrant(im_author_heading)), _, _),
                   AdvancingCount),
    check_summary_field(admitted_teacher_question_labels, Summary,
                         admitted_im_author_heading_assessing, AssessingCount),
    check_summary_field(admitted_teacher_question_labels, Summary,
                         admitted_im_author_heading_advancing, AdvancingCount),
    get_dict(held_by_class, Summary, HeldByClass),
    dict_pairs(HeldByClass, _, ClassCountPairs),
    forall(member(Class-ExpectedCount, ClassCountPairs),
           ( aggregate_all(count,
                            ( held_question_label(_, _, _, _, _, held(Reason)),
                              held_class_matches(Class, Reason) ),
                            ActualCount),
             ( ActualCount == ExpectedCount
             -> true
             ;  throw(error(admitted_teacher_question_labels(
                             summary_mismatch(Class, ExpectedCount, ActualCount)), _))
             )
           )),
    findall(V, member(_-V, ClassCountPairs), ClassCounts),
    sum_list(ClassCounts, SumOfClasses),
    ( SumOfClasses == HeldCount
    -> true
    ;  throw(error(admitted_teacher_question_labels(
                    held_by_class_sum_mismatch(SumOfClasses, HeldCount)), _))
    ).

held_class_matches(Class, Reason) :- atom(Reason), !, Class == Reason.
held_class_matches(Class, Reason) :- compound(Reason), !,
    functor(Reason, Class, _).
"""

GUIDE_CHECK_CODE_TEMPLATE = """
:- use_module(library(sha)).
:- use_module(library(pairs)).
""" + SHARED_HEADING_RULE_CODE + """
%! check_admitted_guide_questions is det.
%
%  Structural checks and span/sha re-derivation run against the tracked
%  teacher-guide corpus on every checkout.
check_admitted_guide_questions :-
    findall(Row, admitted_guide_question(_, _, _, _, _, _), AdmittedRows),
    findall(Row, held_guide_question(_, _, _, _, _, _), HeldRows),
    forall(admitted_guide_question(L, La, T, A, Te, R),
           check_admitted_guide_row(L, La, T, A, Te, R)),
    forall(held_guide_question(L, La, T, A, To, H),
           check_held_guide_row(L, La, T, A, To, H)),
    check_guide_anchor_consistency,
    check_guide_summary,
    length(AdmittedRows, AdmittedCount),
    length(HeldRows, HeldCount),
    format('check_admitted_guide_questions: ~d admitted, ~d held, all receipts passed~n',
           [AdmittedCount, HeldCount]).

check_admitted_guide_row(Lesson, LabelArg, Text,
        anchor(source_guide(Source), doc_sha256(DocSha), line_span(Start, End),
               activity_location(ActivityLocation), LabelOriginTerm,
               warrant(Warrant)),
        Testimony,
        receipt(swipl_test(ReceiptList))) :-
    ( Warrant == im_author_heading
    -> ExpectedReceipt = [doc_sha_pinned, span_reproduces_text,
                          anchor_unique, author_heading_verbatim],
       ( memberchk(LabelArg, [assessing, advancing])
       -> true
       ;  throw(error(admitted_guide_questions(
                       author_heading_label_not_function(Lesson, LabelArg)), _))
       ),
       ( Testimony = testimony(im_author_heading(HeadingTitle), extraction(BuilderScript), date(_))
       -> true
       ;  throw(error(admitted_guide_questions(
                       admitted_row_not_author_heading(Lesson, Testimony)), _))
       ),
       atom(HeadingTitle), atom(BuilderScript),
       ( LabelOriginTerm == label_origin(author_heading(HeadingTitle))
       -> true
       ;  throw(error(admitted_guide_questions(
                       heading_title_mismatch(Lesson, LabelOriginTerm, HeadingTitle)), _))
       )
    ;  Warrant = printed_region(RegionArg)
    -> ExpectedReceipt = [doc_sha_pinned, span_reproduces_text,
                          region_recorded, anchor_unique],
       % The label argument NEVER carries assessing/advancing for a
       % printed_region row.
       ( LabelArg == region(RegionArg)
       -> true
       ;  throw(error(admitted_guide_questions(
                       printed_region_label_not_region(Lesson, LabelArg)), _))
       ),
       ( LabelOriginTerm == label_origin(machine_classification)
       -> true
       ;  throw(error(admitted_guide_questions(
                       printed_region_not_machine_classification(Lesson, LabelOriginTerm)), _))
       ),
       ( RegionArg == ActivityLocation
       -> true
       ;  throw(error(admitted_guide_questions(
                       region_recorded_mismatch(Lesson, RegionArg, ActivityLocation)), _))
       ),
       ( Testimony = testimony(extraction(BuilderScript2), date(_))
       -> atom(BuilderScript2)
       ;  throw(error(admitted_guide_questions(
                       printed_region_bad_testimony_shape(Lesson, Testimony)), _))
       )
    ;  throw(error(admitted_guide_questions(bad_warrant(Lesson, Warrant)), _))
    ),
    ( ReceiptList == ExpectedReceipt
    -> true
    ;  throw(error(admitted_guide_questions(bad_receipt(Lesson, ReceiptList)), _))
    ),
    check_testimony(admitted_guide_questions, Testimony),
    ( exists_file(Source)
       -> true
       ;  throw(error(admitted_guide_questions(source_missing(Lesson, Source)), _))
       ),
       ( DocSha == none
       -> throw(error(admitted_guide_questions(missing_doc_sha(Lesson)), _))
       ;  file_sha256_hex(Source, ActualSha),
          ( ActualSha == DocSha
          -> true
          ;  throw(error(admitted_guide_questions(sha_drift(Lesson, Source)), _))
          )
       ),
       read_file_to_string(Source, Content, [encoding(utf8)]),
       split_string(Content, "\\n", "", SourceLines),
       length(SourceLines, NumLines),
       ( Start >= 1, Start =< End, End =< NumLines
       -> true
       ;  throw(error(admitted_guide_questions(span_out_of_range(Lesson, Start, End)), _))
       ),
       StartIndex is Start - 1,
       LineCount is End - Start + 1,
       length(CitedLines, LineCount),
       ( nth0(StartIndex, SourceLines, _)
       -> true
       ;  throw(error(admitted_guide_questions(span_out_of_range(Lesson, Start, End)), _))
       ),
       findall(Line, ( between(1, LineCount, Offset),
                        Index is StartIndex + Offset - 1,
                        nth0(Index, SourceLines, Line) ),
               CitedLines),
       atomic_list_concat(CitedLines, '\\n', CitedJoined),
       normalize_whitespace_runs(CitedJoined, NormCited),
       normalize_whitespace_runs(Text, NormText),
       ( sub_atom(NormCited, _, _, _, NormText)
       -> true
       ;  throw(error(admitted_guide_questions(span_mismatch(Lesson, Start, End)), _))
       ).

check_held_guide_row(Lesson, _StoredLabel, _Text,
        anchor(source_guide(Source), doc_sha256(DocSha), _, _, _, _),
        testimony_or_none(TestimonyOrNone), held(Reason)) :-
    ( TestimonyOrNone == none
    -> true
    ;  check_testimony(admitted_guide_questions, TestimonyOrNone)
    ),
    ( valid_held_reason(Reason)
    -> true
    ;  throw(error(admitted_guide_questions(bad_held_reason(Lesson, Reason)), _))
    ),
    ( exists_file(Source)
    -> true
    ;  throw(error(admitted_guide_questions(source_missing(Lesson, Source)), _))
    ),
    ( DocSha == none
    -> throw(error(admitted_guide_questions(missing_doc_sha(Lesson)), _))
    ;  file_sha256_hex(Source, ActualSha),
       ( ActualSha == DocSha
       -> true
       ;  throw(error(admitted_guide_questions(sha_drift(Lesson, Source)), _))
       )
    ).

% Positional-serving ruling: label_contradicts_heading is retired at
% stage 0 (it no longer gates guide-lane candidacy); pass_void is retired
% (every det=pass machine_classification row now admits as
% printed_region); the verdict-based classes were already retired by the
% section 13 amendment.
valid_held_reason(source_missing).
valid_held_reason(source_unreadable).
valid_held_reason(span_mismatch).
valid_held_reason(not_interrogative).
valid_held_reason(malformed_text).
valid_held_reason(duplicate_span).

%  Scoped to warrant(im_author_heading) rows only -- see the labels
%  store's check_labels_anchor_consistency for why printed_region rows
%  are not checked here.
check_guide_anchor_consistency :-
    findall((Source, Start, End)-Label,
            admitted_guide_question(_, Label, _,
                anchor(source_guide(Source), _, line_span(Start, End), _, _,
                       warrant(im_author_heading)), _, _),
            AdmittedEntries),
    keysort(AdmittedEntries, Sorted),
    group_pairs_by_key(Sorted, Groups),
    forall(member(_-Labels, Groups), check_guide_anchor_group(Labels)).

check_guide_anchor_group(Labels) :-
    sort(Labels, Distinct),
    ( Distinct = [_]
    -> true
    ;  throw(error(admitted_guide_questions(
                    conflicting_admitted_labels_at_anchor(Labels)), _))
    ).

check_summary_field(ErrorTag, Dict, Key, Expected) :-
    get_dict(Key, Dict, Actual),
    ( Actual == Expected
    -> true
    ;  ErrorTerm =.. [ErrorTag, summary_field_mismatch(Key, Expected, Actual)],
       throw(error(ErrorTerm, _))
    ).

check_guide_summary :-
    admitted_guide_questions_summary(Summary),
    aggregate_all(count, admitted_guide_question(_, _, _, _, _, _), AdmittedCount),
    aggregate_all(count, held_guide_question(_, _, _, _, _, _), HeldCount),
    check_summary_field(admitted_guide_questions, Summary, admitted, AdmittedCount),
    check_summary_field(admitted_guide_questions, Summary, held, HeldCount),
    aggregate_all(count,
                   admitted_guide_question(_, _, _,
                       anchor(_, _, _, _, _, warrant(im_author_heading)), _, _),
                   AuthorHeadingCount),
    aggregate_all(count,
                   admitted_guide_question(_, _, _,
                       anchor(_, _, _, _, _, warrant(printed_region(_))), _, _),
                   PrintedRegionCount),
    check_summary_field(admitted_guide_questions, Summary,
                         admitted_im_author_heading, AuthorHeadingCount),
    check_summary_field(admitted_guide_questions, Summary,
                         admitted_printed_region, PrintedRegionCount),
    AuthorHeadingCount + PrintedRegionCount =:= AdmittedCount,
    aggregate_all(count,
                   admitted_guide_question(_, assessing, _,
                       anchor(_, _, _, _, _, warrant(im_author_heading)), _, _),
                   AssessingCount),
    aggregate_all(count,
                   admitted_guide_question(_, advancing, _,
                       anchor(_, _, _, _, _, warrant(im_author_heading)), _, _),
                   AdvancingCount),
    check_summary_field(admitted_guide_questions, Summary,
                         admitted_im_author_heading_assessing, AssessingCount),
    check_summary_field(admitted_guide_questions, Summary,
                         admitted_im_author_heading_advancing, AdvancingCount),
    get_dict(held_by_class, Summary, HeldByClass),
    dict_pairs(HeldByClass, _, ClassCountPairs),
    forall(member(Class-ExpectedCount, ClassCountPairs),
           ( aggregate_all(count,
                            ( held_guide_question(_, _, _, _, _, held(Reason)),
                              held_class_matches(Class, Reason) ),
                            ActualCount),
             ( ActualCount == ExpectedCount
             -> true
             ;  throw(error(admitted_guide_questions(
                             summary_mismatch(Class, ExpectedCount, ActualCount)), _))
             )
           )),
    findall(V, member(_-V, ClassCountPairs), ClassCounts),
    sum_list(ClassCounts, SumOfClasses),
    ( SumOfClasses == HeldCount
    -> true
    ;  throw(error(admitted_guide_questions(
                    held_by_class_sum_mismatch(SumOfClasses, HeldCount)), _))
    ).

held_class_matches(Class, Reason) :- atom(Reason), !, Class == Reason.
held_class_matches(Class, Reason) :- compound(Reason), !,
    functor(Reason, Class, _).
"""


# ---------------------------------------------------------------------------
# Store assembly
# ---------------------------------------------------------------------------

def testimony_sort_key(testimony: dict[str, str]) -> tuple[str, ...]:
    if testimony["kind"] == "model":
        return ("model", testimony["model"], testimony["job"], testimony["date"])
    if testimony["kind"] == "author_heading":
        return ("author_heading", testimony["title"], testimony["builder_script"], testimony["date"])
    return ("extraction", testimony["builder_script"], testimony["date"])


def collect_testimonies(items: list[Disposed]) -> list[dict[str, str]]:
    """One clause per distinct testimony that actually appears on a row --
    of any of the three shapes (model, author_heading, extraction), same
    "enumerate what actually ran" convention the model form used alone
    before the section 13 amendment.
    """
    seen: dict[tuple[str, ...], dict[str, str]] = {}
    for item in items:
        if item.testimony is not None:
            seen[testimony_sort_key(item.testimony)] = item.testimony
    return [seen[key] for key in sorted(seen)]


def lane_agreement_stats(
    candidates: list[dict[str, Any]], verdicts_by_id: dict[str, dict[str, Any]],
    is_guide_lane: bool,
) -> dict[str, Any]:
    pairs: list[tuple[str, str]] = []
    for row in candidates:
        if row["det"] != "pass":
            continue
        verdict_row = verdicts_by_id.get(row["id"])
        if verdict_row is None or verdict_row["verdict"] not in ("assessing", "advancing", "cannot_tell"):
            continue
        if is_guide_lane and verdict_row.get("kind") != "teacher_question":
            continue
        pairs.append((row["anchor"]["stored_label"], verdict_row["verdict"]))
    n = len(pairs)
    agree = sum(1 for a, b in pairs if a == b)
    return {
        "n_judged": n,
        "agreement_rate": round(agree / n, 4) if n else None,
        "kappa": (lambda k: round(k, 4) if k is not None else None)(cohens_kappa(pairs)),
    }


def sentinel_outcomes(verdicts_by_id: dict[str, dict[str, Any]]) -> list[dict[str, Any]]:
    outcomes = []
    for question in context.REVIEWED_GUIDE_QUESTIONS:
        digest = hashlib.sha256(
            "|".join([question.source, str(question.line_start), question.purpose, question.text])
            .encode("utf-8")
        ).hexdigest()
        sentinel_id = f"tql-sentinel-{digest[:12]}"
        verdict_row = verdicts_by_id.get(sentinel_id)
        outcomes.append({
            "id": sentinel_id,
            "lesson": question.code,
            "stored_label": question.purpose,
            "review_status": question.review_status,
            "verdict": verdict_row["verdict"] if verdict_row else None,
            "agrees": (verdict_row is not None and verdict_row["verdict"] == question.purpose),
        })
    return outcomes


def render_store(
    module: str,
    exports: list[str],
    row_predicate_indicators: list[str],
    header_lines: list[str],
    summary_lines: list[str],
    testimony_lines: list[str],
    row_blocks: list[str],
    check_code: str,
) -> str:
    lines = ["/** <module> " + header_lines[0]]
    for line in header_lines[1:]:
        lines.append(" * " + line if line else " *")
    lines.append(" */")
    lines.append(f":- module({module},")
    lines.append("          [ " + ",\n            ".join(exports) + "\n          ]).")
    lines.append("")
    # A lane can legitimately admit or hold zero rows (a fully void lane
    # admits nothing at all); an exported predicate with no clauses at all
    # is otherwise an existence error the first time it is queried.
    lines.append(":- dynamic " + ", ".join(row_predicate_indicators) + ".")
    lines.append("")
    lines.extend(summary_lines)
    lines.append("")
    lines.extend(testimony_lines)
    lines.append("")
    lines.extend(row_blocks)
    lines.append(check_code.strip("\n"))
    lines.append("")
    return "\n".join(lines).rstrip("\n") + "\n"


def build_labels_store(
    candidates_labels: list[dict[str, Any]],
    verdicts_by_id: dict[str, dict[str, Any]],
    input_shas: dict[str, str],
    admission_date: str,
) -> tuple[str, dict[str, Any]]:
    disposed = dispose_lane(candidates_labels, False, admission_date)
    admitted = [item for item in disposed if item.kind == "admitted"]
    held = [item for item in disposed if item.kind == "held"]
    admitted.sort(key=lambda item: item.row["id"])
    held.sort(key=lambda item: item.row["id"])

    testimonies = collect_testimonies(admitted + held)
    held_by_class: Counter[str] = Counter(item.reason for item in held)
    admitted_author_heading = [item for item in admitted if item.warrant[0] == "im_author_heading"]
    admitted_printed_region = [item for item in admitted if item.warrant[0] == "printed_region"]
    admitted_assessing = sum(
        1 for item in admitted_author_heading if item.row["anchor"]["stored_label"] == "assessing"
    )
    admitted_advancing = sum(
        1 for item in admitted_author_heading if item.row["anchor"]["stored_label"] == "advancing"
    )
    stats = lane_agreement_stats(candidates_labels, verdicts_by_id, False)

    header = [
        "Generated mechanically admitted teacher-question rows",
        "",
        "Directive (Tio, 2026-08-20; amended mid-session, positional serving):",
        "work blocked on human review does not receive human review. Every row",
        "below cleared a deterministic re-derivation gate (source present, sha",
        "match, span reproduces the text, interrogative form, clean text). ",
        MECHANICAL_SENTENCE,
        "",
        LABELS_LICENSE_SENTENCE,
        "",
        "char_span/2 carries the source store's byte_start/byte_end verbatim.",
        "Despite the name, those fields are UTF-8 CHARACTER offsets from Python",
        "str.find, not raw byte offsets -- see structure_teacher_question_labels.pl's",
        "own header and scripts/curriculum/structure_to_task_rows.py find_verbatim.",
        "char_span is this store's honest name for the same field; nothing here",
        "inherits the misnamed one.",
        "",
        "Admission rule (positional-serving ruling, replacing the section 13",
        "amendment's admit/hold split): every deterministic pass admits. Its",
        "label_origin decides which of the two admitted shapes it takes --",
        "author_heading(Title) admits with the assessing/advancing label as a",
        "function claim (IM's own printed section title names it);",
        "machine_classification admits with region(RegionType) in the label",
        "argument's place, asserting only the verified position, never a",
        "function claim. Held rows stay in this store, forever queryable,",
        "never deleted.",
        "",
        "What counts as a question (2026-08-22 admission pass): a row admits",
        "when its printed text carries at least one complete question -- a",
        "question mark closing a sentence. Glosses, sample responses, and",
        "follow-on instructions IM prints with the question ride along",
        "verbatim rather than disqualifying the row, and IM's own mixed",
        "quotation typography -- a curly opener closed by a straight quote, a",
        "quote the source never closes -- is typography, not a defect. Rows",
        "whose text carries no question at all stay held (not_interrogative).",
        "The same pass named two further holds: span_truncates_quote, a span",
        "that cuts a quotation off before the source closes it, and",
        "region_conflict_rederived, one printed span recorded under two",
        "region types, where the region the page's own nearest preceding",
        "heading re-derives admits and the others hold with the winner named",
        "(or with none named, when the page carries no heading to read).",
        "",
        f"Inputs: candidates.jsonl sha256 {input_shas['candidates']}, "
        f"verdicts file sha256 {input_shas['verdicts']}, "
        f"labels prompt template sha256 {LABELS_PROMPT_SHA}.",
        "",
        "Generated by scripts/questions/emit_admitted_question_stores.py.",
        "Do not edit by hand.",
    ]

    summary_dict_lines = [
        "admitted_question_labels_summary(",
        "    summary{",
        f"      admitted: {len(admitted)},",
        f"      admitted_im_author_heading: {len(admitted_author_heading)},",
        f"      admitted_im_author_heading_assessing: {admitted_assessing},",
        f"      admitted_im_author_heading_advancing: {admitted_advancing},",
        f"      admitted_printed_region: {len(admitted_printed_region)},",
        f"      held: {len(held)},",
        "      held_by_class: dict{"
        + ", ".join(f"{cls}: {held_by_class[cls]}" for cls in sorted(held_by_class))
        + "},",
        f"      pilot_or_full_agreement: dict{{n_judged: {stats['n_judged']}, "
        f"agreement_rate: {prolog_number_or_none(stats['agreement_rate'])}, "
        f"kappa: {prolog_number_or_none(stats['kappa'])}}}",
        "    }).",
    ]

    testimony_lines = [f"valid_testimony({render_testimony(t)})." for t in testimonies]

    row_blocks = [render_labels_admitted_row(item) + "\n" for item in admitted]
    row_blocks += [render_labels_held_row(item) + "\n" for item in held]

    text = render_store(
        "admitted_teacher_question_labels",
        ["admitted_question_label/6", "held_question_label/6",
         "admitted_question_labels_summary/1", "check_admitted_question_labels/0"],
        ["admitted_question_label/6", "held_question_label/6"],
        header, summary_dict_lines, testimony_lines, row_blocks, LABELS_CHECK_CODE_TEMPLATE,
    )
    report = {
        "admitted": len(admitted),
        "admitted_im_author_heading": len(admitted_author_heading),
        "admitted_printed_region": len(admitted_printed_region),
        "held": len(held), "held_by_class": dict(held_by_class),
        "agreement": stats,
    }
    return text, report


def build_guide_store(
    candidates_guide: list[dict[str, Any]],
    verdicts_by_id: dict[str, dict[str, Any]],
    input_shas: dict[str, str],
    admission_date: str,
) -> tuple[str, dict[str, Any]]:
    disposed = dispose_lane(candidates_guide, True, admission_date)
    admitted = [item for item in disposed if item.kind == "admitted"]
    held = [item for item in disposed if item.kind == "held"]
    admitted.sort(key=lambda item: item.row["id"])
    held.sort(key=lambda item: item.row["id"])

    testimonies = collect_testimonies(admitted + held)
    held_by_class: Counter[str] = Counter(item.reason for item in held)
    admitted_author_heading = [item for item in admitted if item.warrant[0] == "im_author_heading"]
    admitted_printed_region = [item for item in admitted if item.warrant[0] == "printed_region"]
    admitted_assessing = sum(
        1 for item in admitted_author_heading if item.row["anchor"]["stored_label"] == "assessing"
    )
    admitted_advancing = sum(
        1 for item in admitted_author_heading if item.row["anchor"]["stored_label"] == "advancing"
    )
    stats = lane_agreement_stats(candidates_guide, verdicts_by_id, True)

    header = [
        "Generated mechanically admitted K-8 extracted guide questions",
        "",
        "Directive (Tio, 2026-08-20; amended mid-session, positional serving):",
        "work blocked on human review does not receive human review. Every row",
        "below cleared a deterministic re-derivation gate (source present, span",
        "reproduces the text, interrogative form, clean text). " + MECHANICAL_SENTENCE,
        "",
        GUIDE_LICENSE_SENTENCE,
        "",
        "Sources are tracked paths under curriculum/im_teacher_guides_docling/.",
        "The manifest there pins each file to its local Docling source. These",
        "rows are served only on research",
        "surfaces that say so; the teacher-facing dict never resolves them.",
        "",
        "Admission rule (positional-serving ruling, replacing the section 13",
        "amendment's admit/hold split): every deterministic pass admits. Its",
        "label_origin decides which of the two admitted shapes it takes --",
        "author_heading(Title) would admit with the assessing/advancing label",
        "as a function claim (no row currently carries it: the nine grade",
        "extraction stores record machine_classification only, so this rule",
        "is stated for when one does); machine_classification admits with",
        "region(ActivityLocation) in the label argument's place, asserting",
        "only the verified position, never a function claim. This includes",
        "every row whose activity_location previously sat in the family",
        "opposite its extracted purpose (label_contradicts_heading, formerly",
        "a stage-0 hold): under positional serving there is no function claim",
        "left for that family relationship to contradict. Held rows stay in",
        "this store, forever queryable, never deleted.",
        "",
        f"Inputs: candidates.jsonl sha256 {input_shas['candidates']}, "
        f"verdicts file sha256 {input_shas['verdicts']}, "
        f"guide prompt template sha256 {GUIDE_PROMPT_SHA}.",
        "",
        "Generated by scripts/questions/emit_admitted_question_stores.py.",
        "Do not edit by hand.",
    ]

    summary_dict_lines = [
        "admitted_guide_questions_summary(",
        "    summary{",
        f"      admitted: {len(admitted)},",
        f"      admitted_im_author_heading: {len(admitted_author_heading)},",
        f"      admitted_im_author_heading_assessing: {admitted_assessing},",
        f"      admitted_im_author_heading_advancing: {admitted_advancing},",
        f"      admitted_printed_region: {len(admitted_printed_region)},",
        f"      held: {len(held)},",
        "      held_by_class: dict{"
        + ", ".join(f"{cls}: {held_by_class[cls]}" for cls in sorted(held_by_class))
        + "},",
        f"      pilot_or_full_agreement: dict{{n_judged: {stats['n_judged']}, "
        f"agreement_rate: {prolog_number_or_none(stats['agreement_rate'])}, "
        f"kappa: {prolog_number_or_none(stats['kappa'])}}}",
        "    }).",
    ]

    testimony_lines = [f"valid_testimony({render_testimony(t)})." for t in testimonies]

    row_blocks = [render_guide_admitted_row(item) + "\n" for item in admitted]
    row_blocks += [render_guide_held_row(item) + "\n" for item in held]

    text = render_store(
        "admitted_guide_questions",
        ["admitted_guide_question/6", "held_guide_question/6",
         "admitted_guide_questions_summary/1", "check_admitted_guide_questions/0"],
        ["admitted_guide_question/6", "held_guide_question/6"],
        header, summary_dict_lines, testimony_lines, row_blocks, GUIDE_CHECK_CODE_TEMPLATE,
    )
    report = {
        "admitted": len(admitted),
        "admitted_im_author_heading": len(admitted_author_heading),
        "admitted_printed_region": len(admitted_printed_region),
        "held": len(held), "held_by_class": dict(held_by_class),
        "agreement": stats,
    }
    return text, report


# ---------------------------------------------------------------------------
# Orchestration
# ---------------------------------------------------------------------------

def run(
    args: argparse.Namespace,
) -> tuple[str, str, dict[str, Any], dict[str, Any], dict[str, dict[str, Any]]]:
    candidates_bytes = args.candidates.read_bytes()
    candidates = load_jsonl(args.candidates)
    verdicts_bytes = args.verdicts.read_bytes() if args.verdicts.is_file() else b""
    verdicts_by_id = {row["id"]: row for row in load_jsonl(args.verdicts)} if verdicts_bytes else {}
    # Section 13: pass_void.json no longer gates admission (label_origin
    # alone does) -- it is read here only to report the recorded void
    # evidence (kappa/modal/n) the header's amendment clause quotes.
    void_by_lane = load_pass_void(args.pass_void)

    input_shas = {
        "candidates": sha256_bytes(candidates_bytes),
        "verdicts": sha256_bytes(verdicts_bytes) if verdicts_bytes else "no_verdicts_file",
    }

    for verdict_row in verdicts_by_id.values():
        expected_sha = LABELS_PROMPT_SHA if verdict_row["lane"] == "labels" else GUIDE_PROMPT_SHA
        if verdict_row.get("prompt_sha") != expected_sha:
            raise SystemExit(
                f"verdict row {verdict_row['id']} carries prompt_sha "
                f"{verdict_row.get('prompt_sha')!r}, expected {expected_sha!r} for lane "
                f"{verdict_row['lane']} -- the model pass did not use the committed "
                "prompt template; refusing to trust it"
            )

    candidates_labels = [row for row in candidates if row["lane"] == "labels"]
    candidates_guide = [row for row in candidates if row["lane"] == "guide"]

    labels_text, labels_report = build_labels_store(
        candidates_labels, verdicts_by_id, input_shas, args.admission_date,
    )
    guide_text, guide_report = build_guide_store(
        candidates_guide, verdicts_by_id, input_shas, args.admission_date,
    )

    return labels_text, guide_text, labels_report, guide_report, void_by_lane


def print_report(lane: str, report: dict[str, Any]) -> None:
    print(f"== {lane} ==")
    print(
        f"  admitted: {report['admitted']} "
        f"(im_author_heading {report['admitted_im_author_heading']}, "
        f"printed_region {report['admitted_printed_region']})"
    )
    print(f"  held: {report['held']}")
    for cls in sorted(report["held_by_class"]):
        print(f"    held {cls:24s} {report['held_by_class'][cls]}")
    agreement = report["agreement"]
    print(
        f"  judged rows: {agreement['n_judged']}  "
        f"agreement_rate: {agreement['agreement_rate']}  kappa: {agreement['kappa']}"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--candidates", type=Path, default=DEFAULT_CANDIDATES)
    parser.add_argument("--verdicts", type=Path, default=DEFAULT_VERDICTS)
    parser.add_argument("--pass-void", type=Path, default=DEFAULT_PASS_VOID)
    parser.add_argument("--out-labels", type=Path, default=DEFAULT_OUT_LABELS)
    parser.add_argument("--out-guide", type=Path, default=DEFAULT_OUT_GUIDE)
    parser.add_argument(
        "--admission-date", default="2026-08-20",
        help="date recorded in author_heading testimony rows (fixed, not "
             "today's date, so --check stays byte-stable on a later day)",
    )
    parser.add_argument("--check", action="store_true",
                         help="rebuild from the same inputs and byte-compare against disk")
    args = parser.parse_args()

    if not args.candidates.is_file():
        completed = subprocess.run(
            [
                sys.executable,
                "scripts/questions/build_admission_candidates.py",
                "--candidates",
                str(args.candidates),
                "--model-input",
                str(args.candidates.with_name("model_input.jsonl")),
                "--pilot-key",
                str(args.candidates.with_name("pilot_key.jsonl")),
            ],
            cwd=ROOT,
            text=True,
            check=False,
        )
        if completed.returncode or not args.candidates.is_file():
            raise SystemExit(
                "could not rebuild the derived admission candidates from the "
                "tracked guide corpus"
            )

    labels_text, guide_text, labels_report, guide_report, void_by_lane = run(args)

    if args.check:
        stale = []
        for path, text in ((args.out_labels, labels_text), (args.out_guide, guide_text)):
            if not path.is_file() or path.read_text(encoding="utf-8") != text:
                stale.append(str(path))
        if stale:
            raise SystemExit("stale admitted question stores: " + ", ".join(stale))
        print("--check: both admitted stores match a fresh rebuild byte-for-byte")
    else:
        args.out_labels.parent.mkdir(parents=True, exist_ok=True)
        args.out_labels.write_text(labels_text, encoding="utf-8")
        args.out_guide.write_text(guide_text, encoding="utf-8")
        print(f"written: {args.out_labels}")
        print(f"written: {args.out_guide}")

    print_report("labels lane", labels_report)
    print_report("guide lane", guide_report)

    print("== recorded void evidence (pass_void.json; informational under section 13) ==")
    if not void_by_lane:
        print("  none present -- no lane recorded a pilot void")
    for lane in sorted(void_by_lane):
        entry = void_by_lane[lane]
        print(
            f"  {lane:8s} reason={entry.get('reason')}  n={entry.get('n')}  "
            f"modal_share={entry.get('modal_share')}  modal_answer={entry.get('modal_answer')}  "
            f"kappa={entry.get('kappa')}"
        )

    verdicts_by_id = {row["id"]: row for row in load_jsonl(args.verdicts)} if args.verdicts.is_file() else {}
    print("== sentinel outcomes (L17 human rows; not admitted, reported only) ==")
    for outcome in sentinel_outcomes(verdicts_by_id):
        print(
            f"  {outcome['lesson']:16s} stored={outcome['stored_label']:10s} "
            f"review_status={outcome['review_status']:18s} "
            f"model_verdict={outcome['verdict']}  agrees={outcome['agrees']}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
