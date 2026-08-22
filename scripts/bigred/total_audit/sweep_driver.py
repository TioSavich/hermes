#!/usr/bin/env python3
"""sweep_driver.py — drive every worker op across enumerable input domains,
under clause coverage.

The driver spawns the Hermes JSONL worker wrapped in cov_worker.pl, asks it
for its own op list (the health reply carries one), harvests input domains
from the worker's list-shaped replies plus the typed parameter declarations
in hermes/dispatch_spec.pl, then executes the resulting work list with an
external per-item watchdog. Coverage data lands in per-segment files that
coverage_ledger.py joins against the static census.

Honesty rules built in:
  - every op gets at least a shape probe; a refusal is a recorded outcome,
    never an error to hide;
  - per-op enumeration caps are LOGGED as truncations, never silent;
  - a watchdog kill requeues the killed segment's completed items once, so
    their coverage is re-collected in a fresh segment.

Run-2 widening (2026-08-20, task 0820D). Run 1 reached 199 of 218 ops with
only the empty-args shape probe: a pool-or-nothing rule skipped
fixture-resolvable-but-unpooled ops, several real params (lesson_code,
content, concept, claim_id, ...) never matched a POOL_KEYS name, and
cross-product ops (input_contract, the geometry standard/metaphor witnesses)
enumerated only their first param, holding the rest at one sample. This pass
adds: fixture items for resolvable-but-unpooled ops (TYPE_FIXTURES extended);
a harvested `phrase` pool driving strategy_recognize/commitment_match; a
PARAM_POOL_ALIAS table so differently-named params reach the pool their
values actually are; a TUPLE_DOMAINS mechanism so cross-product ops enumerate
real correlated pairs/triples instead of a first-param sweep; regex-harvested
pools (topic, state, canonical, pack, claim_id, concept,
bootstrap_id, inference_id) read straight from the fact files rather than
the Prolog prolog_query op; and an IRREGULAR_SPECS table so bespoke (non
dispatch_spec) ops get typed params too. See
.superpowers/sdd/task-0820D-widening-spec.md for the item-by-item contract
this implements.

Run-3 widening (2026-08-22). The 08-19 audit left a block of ops refusing
every keyed item; two verified domain reports (the 35 crosswalk-family
witnesses and 40 further ops, every one probed serving) showed the refusals
were wrong-key-domain artifacts: claim-id pools that never held an op's real
ids, classroom phrases fed to term-typed params, fixtures missing required
dict keys. This pass adds the real domains — regex harvests over the backing
fact files where the key space is enumerable, and AUTHORED_TUPLE_DOMAINS
where the witness computes over a key space no fact file lists. review_decide
is not among them: the worker dropped that op when the review queue retired
(eade506b), so its audit refusals close as retired, not repaired.

Usage (from the repo root):
  python3 scripts/bigred/total_audit/sweep_driver.py --out OUTDIR \
      [--max-per-op 3000] [--item-timeout 180] [--segment-items 4000]
      [--dry-run-worklist]
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import selectors
import signal
import subprocess
import sys
import time
from collections import Counter, defaultdict, deque
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
COV_WORKER = "scripts/bigred/total_audit/cov_worker.pl"
DISPATCH_SPEC = REPO / "hermes" / "dispatch_spec.pl"

HARVEST_OPS = [
    "list_strategies", "list_misconceptions", "list_standards",
    "capability_atlas", "render_coverage", "lesson_enactment_list",
    # Run-2: canonical_contract's vocabulary entries feed the "canonical"
    # pool the 14 *_claim_witness(canonical, source) ops key on (item 6).
    "canonical_contract",
]
# File-side domain supplements: op replies alone under-harvest the lesson
# codes (the compiled corpus is larger than any one list op's reach).
SUPPLEMENT_FILES = [
    "curriculum/im/generated/field_context_cache.json",
    "hermes/app/web/generated/notation_lesson_charts/manifest.json",
    "hermes/app/web/generated/lesson_deformation_charts/manifest.json",
]
# Param names whose values are enumerable pools; harvested from replies.
POOL_KEYS = {
    "code", "cluster", "kind", "operation", "family", "standard",
    "misconception", "strategy", "state", "context", "pack", "topic",
    "lesson", "domain",
    # Run-2 additions (item 6, 7, 11): regex-harvested from the fact stores
    # rather than the worker's own replies (see harvest_static_pools below).
    "claim_id", "concept", "bootstrap_id", "inference_id",
    "canonical", "phrase",
}
IM_CODE = re.compile(r"^IM-G[K0-9]")
# Ops whose per-item cost makes full enumeration a multi-day job; run-2's
# first attempt burned 17 hours rotating segments on the incompatibility
# witness (every keyed call exceeds the item timeout). Sampled, and logged
# as a truncation like every other cap.
OP_SAMPLE_CAPS = {
    # 2026-08-22: lesson_misconception_incompatibility_witness's cap (25) and
    # timeout override (360) retired — the baked store landed
    # (curriculum/im/generated/lesson_misconception_witness_store.pl is
    # tracked), so the keyed domain is now fact lookups.
    "monitoring_chart_export": 50,
    "ranked_figures": 50,
    "lesson_enactment_run": 50,
    "field_context": 100,
    "lesson_deformation_chart": 100,
    "lesson_arithmetic_demonstration": 100,
}

TIMEOUT_OVERRIDES = {"lesson_enactment_run": 360, "monitoring_chart_export": 360,
                     "lesson_enactment_list": 360, "field_connectivity_audit": 600,
                     "notation_monitoring_chart": 360,
                     # Run-2 item 3: figure export walks every ranked figure
                     # for a lesson; the other lesson_code chains showed this
                     # needs headroom too.
                     "ranked_figures": 360}


def first_terminal_rows(rows):
    """Yield the first recorded terminal result for each work-item id."""
    seen: set[str] = set()
    for row in rows:
        item_id = row.get("id")
        if not isinstance(item_id, str) or item_id in seen:
            continue
        seen.add(item_id)
        yield row


def replay_outcomes(path: Path, op: str) -> Counter:
    rows = []
    for line in path.open(encoding="utf-8"):
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(row, dict):
            rows.append(row)
    return Counter(
        row.get("outcome", "missing")
        for row in first_terminal_rows(rows)
        if row.get("op") == op
    )
TYPE_FIXTURES = {"atom": "probe", "string": "probe", "code": "IM-G1-U3-L17",
                 "term": "probe", "number": 1, "int": 1, "dict": {},
                 "json": {}, "json_list": [{"id": "u1", "speaker": "student",
                                            "text": "i added the tens first"}],
                 "list": [],
                 "nonempty_text": "ten plus three is thirteen",
                 # Run-3 (2026-08-22): "3 + 4 = 7" is not in the registered
                 # safe_math_claim_shape/1 grammar (hermes_worker.pl); sum/3 is.
                 "math_claim": "sum(3,4,7)", "fraction": "1/2",
                 "optional_code": "IM-G1-U3-L17", "op_atom": "probe",
                 "filter": {},
                 # Run-2 item 1: image_schema/primitive_for_practice had no
                 # fixture for their sole required param and got shape-probe
                 # only.
                 "practice": "counting",
                 # Run-2 item 8: diagnose_error/abduce_error's geometric
                 # branch needs Input=[Shape,Target] and a verdict atom; the
                 # pair below is a real entailment row (misconceptions_geometry.pl
                 # db_row(38447), parallelogram_is_rectangle) so the geometric
                 # domain value in the pooled domain-atom sweep gets a genuine
                 # match, not just a clean refusal.
                 "shape_target_pair": ["parallelogram", "rectangle"],
                 "verdict_atom": "holds",
                 # Run-3 (2026-08-22): media_alignment's valid_segment_dict/1
                 # (formal/pml/media_alignment.pl) takes STRICT dicts with
                 # exactly {speaker, text, start_ms, end_ms}; the generic
                 # json_list fixture's {id, speaker, text} elements refuse.
                 "media_segments": [
                     {"speaker": "T", "text": "What did you notice?",
                      "start_ms": 0, "end_ms": 2000},
                     {"speaker": "S", "text": "I counted by fives.",
                      "start_ms": 2000, "end_ms": 4000}],
                 "alignment_source": "reallms_audio_alignment:probe",
                 # Run-3: gesture_alignment's observation_dict_term/5
                 # (formal/pml/gesture_alignment.pl) takes STRICT dicts with
                 # exactly {kind, start_ms, end_ms, target, source, confidence}.
                 "gesture_observations": [
                     {"kind": "pointing", "start_ms": 100, "end_ms": 700,
                      "target": "unresolved", "source": "video:probe",
                      "confidence": "high"}]}
# Param types with structured shapes the driver cannot fabricate honestly
# (recollection, fallback, ...) stay unresolved: those ops get a
# shape probe, and their refusal message records the contract.

# Run-2 item 3. A param is often a pool value under a different name than the
# POOL_KEYS entry that holds it (lesson_code IS a code; content/text/query
# ARE classroom phrases). Resolve pools[ALIAS.get(name, name)] rather than
# pools[name] so these reach the domain they actually belong to. concept,
# claim_id, canonical, bootstrap_id are listed for readability even though
# they resolve to themselves; arc_id is a deliberate deviation from the
# widening spec's literal "identity entry" — geometry/concepts/developmental_arcs.pl's
# developmental_arc_witness/2 keys ArcId directly against geom_concept/4
# (verified by reading the predicate body), so arc_id has no pool of its own
# and belongs on "concept", not on an empty "arc_id" pool.
PARAM_POOL_ALIAS = {
    "lesson_code": "code",
    "content": "phrase",
    "text": "phrase",
    "query": "phrase",
    "id_value": "claim_id",
    "concept": "concept",
    "claim_id": "claim_id",
    "canonical": "canonical",
    "bootstrap_id": "bootstrap_id",
    "arc_id": "concept",
}

# Run-2 item 8. Bespoke (dispatch_irregular) ops carry no dispatch_spec typed
# params, so they got shape-probe only in run 1. Entries here are consumed
# exactly like dispatch_spec params: (name, type, optional) triples resolved
# through TYPE_FIXTURES / the pool machinery below.
IRREGULAR_SPECS = {
    "lesson_deformation_chart": [("code", "code", False)],
    "notation_monitoring_chart": [("code", "code", False)],
    "diagnose_error": [("domain", "atom", False),
                       ("input", "shape_target_pair", False),
                       ("got", "verdict_atom", False)],
    "abduce_error": [("domain", "atom", False),
                     ("input", "shape_target_pair", False),
                     ("got", "verdict_atom", False)],
    "discourse_features": [("utterances", "json_list", False)],
    "discourse_pragmatics": [("utterances", "json_list", False)],
    # Run-3 (2026-08-22): both alignment ops refused their run-2 json_list
    # fixtures on strict dict-key checks; the typed fixtures above carry the
    # exact required keys.
    "gesture_alignment": [("utterances", "json_list", False),
                          ("observations", "gesture_observations", False)],
    "media_alignment": [("segments", "media_segments", False),
                        ("source", "alignment_source", False)],
}


def parse_dispatch_specs() -> dict[str, list[tuple[str, str, bool]]]:
    """Return op -> [(param, type, optional)], read from dispatch_spec.pl."""
    text = DISPATCH_SPEC.read_text(encoding="utf-8")
    specs: dict[str, list[tuple[str, str, bool]]] = {}
    for m in re.finditer(r"^dispatch_spec\((\w+),\s*\n?\s*\[(.*?)\]", text,
                         re.MULTILINE | re.DOTALL):
        op, params_raw = m.group(1), m.group(2)
        params: list[tuple[str, str, bool]] = []
        depth = 0
        item = ""
        items = []
        for ch in params_raw:
            if ch == "," and depth == 0:
                items.append(item)
                item = ""
                continue
            if ch in "([{":
                depth += 1
            elif ch in ")]}":
                depth -= 1
            item += ch
        if item.strip():
            items.append(item)
        for it in items:
            it = it.strip().replace("\n", " ")
            pm = re.match(r"(\w+)\s*-\s*(.+)$", it)
            if not pm:
                continue
            name, typ = pm.group(1), pm.group(2).strip()
            optional = typ.startswith("default(")
            base = typ.split("(")[0] if "(" in typ else typ
            if optional:
                inner = typ[len("default("):]
                base = inner.split(",")[0].split("(")[0].strip()
            params.append((name, base, optional))
        specs[op] = params
    return specs


def walk_json(node, pools: dict[str, set]):
    if isinstance(node, dict):
        for k, v in node.items():
            if k in POOL_KEYS and isinstance(v, str) and v:
                pools[k].add(v)
            walk_json(v, pools)
    elif isinstance(node, list):
        for v in node:
            walk_json(v, pools)
    elif isinstance(node, str) and IM_CODE.match(node):
        pools["code"].add(node)


# ---------------------------------------------------------------------------
# Run-2 static pool harvest (items 2, 6, 7, 9, 11). Cheap regex reads of the
# fact files themselves rather than a live prolog_query call — the brief's
# instruction: "prefer cheap regex harvests over the Prolog fact files; use
# the prolog_query op only where the spec says" (the spec says nowhere).
# Every read is best-effort: a missing/unreadable file logs and the pool
# stays whatever it already was, never a hard failure.

def _read(rel: str, log) -> str | None:
    p = REPO / rel
    try:
        return p.read_text(encoding="utf-8")
    except OSError as e:
        log(f"static-pool source unreadable: {rel} ({type(e).__name__})")
        return None


def _bracket_phrase(raw: str) -> str | None:
    tokens = [t.strip().strip("'\"") for t in raw.split(",")]
    tokens = [t for t in tokens if t]
    return " ".join(tokens) if tokens else None


ATTESTED_PHRASE_RE = re.compile(
    r"^attested_phrase\(\s*\w+,\s*\w+,\s*\w+,\s*\[([^\]]*)\]", re.MULTILINE)
CANONICAL_PHRASE_RE = re.compile(
    r"^canonical_phrase\(\s*\w+,\s*\[([^\]]*)\]", re.MULTILINE)
STUDENT_RULE_KEY_RE = re.compile(
    r"^student_rule_map\(\s*([A-Za-z0-9_]+)\s*,", re.MULTILINE)
GEOM_CONCEPT_RE = re.compile(r"^geom_concept\(\s*([A-Za-z0-9_]+)\s*,", re.MULTILINE)
MATERIAL_CLAIM_RE = re.compile(
    r"^[a-z_]+_material_claim\(\s*([A-Za-z0-9_]+)\s*,", re.MULTILINE)
BOOTSTRAP_ID_RE = re.compile(r"^bootstrap\(\s*([A-Za-z0-9_]+)\s*,", re.MULTILINE)
KNOWN_TOPIC_RE = re.compile(r"^known_topic\((.+?)\)\.", re.MULTILINE)
STATE_LABEL_RE = re.compile(r"^state_label\(\s*([A-Za-z0-9_]+)\s*,", re.MULTILINE)
DEFAULT_AXIOM_PACK_RE = re.compile(
    r"^default_axiom_pack\(\s*([A-Za-z0-9_]+)\s*\)\.", re.MULTILINE)
MATERIAL_INFERENCE_ID_RE = re.compile(
    r"^material_inference\(\s*([A-Za-z0-9_]+)\s*,", re.MULTILINE)


def harvest_static_pools(pools: dict[str, set], log) -> None:
    # item 2: phrase pool for strategy_recognize / commitment_match (item 9).
    text = _read("knowledge/strategies/attested_phrases.pl", log)
    if text:
        for m in ATTESTED_PHRASE_RE.finditer(text):
            phrase = _bracket_phrase(m.group(1))
            if phrase:
                pools["phrase"].add(phrase)
    text = _read("knowledge/strategies/canonical_phrases.pl", log)
    if text:
        for m in CANONICAL_PHRASE_RE.finditer(text):
            phrase = _bracket_phrase(m.group(1))
            if phrase:
                pools["phrase"].add(phrase)
    # item 9: raw student-rule spellings student_rule_map/2 keys on.
    text = _read("knowledge/misconceptions/literature_student_rule_map.pl", log)
    if text:
        for m in STUDENT_RULE_KEY_RE.finditer(text):
            pools["phrase"].add(m.group(1).replace("_", " "))

    # item 7: concept / claim_id from the geometry concept files. Both
    # predicates live in the same 15-file directory; one pass reads both.
    concepts_dir = REPO / "knowledge/geometry/concepts"
    for f in sorted(concepts_dir.glob("*.pl")) if concepts_dir.is_dir() else []:
        try:
            ftext = f.read_text(encoding="utf-8")
        except OSError as e:
            log(f"static-pool source unreadable: {f} ({type(e).__name__})")
            continue
        for m in GEOM_CONCEPT_RE.finditer(ftext):
            pools["concept"].add(m.group(1))
        for m in MATERIAL_CLAIM_RE.finditer(ftext):
            pools["claim_id"].add(m.group(1))

    # item 7: bootstrap_id from both activity bootstrap files.
    for rel in ["knowledge/geometry/bootstrap/van_de_walle_activities.pl",
                "knowledge/geometry/bootstrap/n103_activities.pl"]:
        text = _read(rel, log)
        if text:
            for m in BOOTSTRAP_ID_RE.finditer(text):
                pools["bootstrap_id"].add(m.group(1))

    # item 6: topic, state, and pack.
    text = _read("knowledge/index/relevance_negation.pl", log)
    if text:
        for m in KNOWN_TOPIC_RE.finditer(text):
            raw = m.group(1).strip()
            if raw.startswith("'") and raw.endswith("'") and len(raw) >= 2:
                raw = raw[1:-1]
            pools["topic"].add(raw)
    text = _read("knowledge/strategies/math/state_vocabulary.pl", log)
    if text:
        for m in STATE_LABEL_RE.finditer(text):
            pools["state"].add(m.group(1))
    text = _read("formal/sequent/sequent_engine.pl", log)
    if text:
        # Deviation from the widening spec's literal file pointer
        # (formal/tools/axiom_pack_audit.pl + axioms_geometry.pl): those
        # files audit packs, they do not enumerate the admitted set.
        # default_axiom_pack/1 in sequent_engine.pl IS the admitted-pack
        # enumeration axiom_pack_witness's "pack" argument is checked
        # against (enabled_axiom_pack/1 reads from it via
        # normalize_axiom_packs(all, Packs)).
        for m in DEFAULT_AXIOM_PACK_RE.finditer(text):
            pools["pack"].add(m.group(1))

    # item 11: inference_id for defeasible_classify.
    text = _read("formal/incompatibility/error_rule_inferences.pl", log)
    if text:
        for m in MATERIAL_INFERENCE_ID_RE.finditer(text):
            pools["inference_id"].add(m.group(1))

    log("static pools: " +
        ", ".join(f"{k}={len(v)}" for k, v in sorted(pools.items())
                  if k in {"phrase", "concept", "claim_id", "bootstrap_id",
                          "topic", "state", "pack",
                          "inference_id"}))


# ---------------------------------------------------------------------------
# Run-2 TUPLE_DOMAINS (item 5 + item 4 + item 11). Ops whose params are
# correlated (Operation goes with Kind, not with every other op's Kind) get
# real tuples here instead of a first-param sweep with the rest pinned to one
# sample. Each entry is (param_names, tuples, class); build_worklist emits
# one item per tuple with args = dict(zip(param_names, tuple)), bypassing the
# normal per-op pool resolution entirely for that op.

METAPHOR_SOURCE_RE = re.compile(
    r"^metaphor_source\(\s*([A-Za-z0-9_]+)\s*,\s*([A-Za-z0-9_]+)\s*,", re.MULTILINE)
STANDARD_ANCHOR_RE = re.compile(
    r'^standard_anchor\(\s*([A-Za-z0-9_]+)\s*,\s*([a-z_]+)\s*,\s*"((?:[^"\\]|\\.)*)"',
    re.MULTILINE)
CONTRACT_RE = re.compile(
    r"automaton_input_contract\(([a-z0-9_]+),\s*([a-z0-9_]+),\s*'((?:[^'\\]|\\.)*)',"
    r"\s*'((?:[^'\\]|\\.)*)',\s*verified\(strategy_trace_ok\)\)\.")
DIALECTICAL_TRANSITION_RE = re.compile(
    r"^dialectical_transition\(\s*(\w+)\s*,\s*(.+?)\)\.", re.MULTILINE)
SEQUENT_PROOF_SOURCE_RE = re.compile(
    r"rule\(cw_sequent_proof,\s*sequent_proof_source\(([a-z_]+),")

# ---------------------------------------------------------------------------
# Run-3 (2026-08-22) regex harvests: the 08-19 audit's full-refusal ops, per
# the two verified domain reports. Correlated params (misconception_hook's
# family==operation, grounding_metaphor's domains(Src,Tgt) anchor) always come
# from the SAME fact row, never a cross product of independent pools.

# Ten crosswalk claim families whose canonical enum lives in cw_edges.pl as
# rule(<family>, <tag>(Canonical, Commitment, Edges)). Each pairs with the
# always-live source 'literature_commitment' lane the reports verified.
CW_EDGE_CLAIM_FAMILIES = [
    ("algebra_claim_witness", re.compile(r"rule\(cw_algebra_claim, ac\((\w+),")),
    ("arithmetic_property_witness",
     re.compile(r"rule\(cw_arithmetic_property_claim, ap\((\w+),")),
    ("calculus_claim_witness", re.compile(r"rule\(cw_calculus_claim, cc\((\w+),")),
    ("decimal_claim_witness", re.compile(r"rule\(cw_decimal_claim, dc\((\w+),")),
    ("fraction_extra_claim_witness",
     re.compile(r"rule\(cw_fraction_extra_claim, fe\((\w+),")),
    ("integer_signed_claim_witness",
     re.compile(r"rule\(cw_integer_signed_claim, isc\((\w+),")),
    ("magnitude_equivalence_claim_witness",
     re.compile(r"rule\(cw_magnitude_equivalence_claim, me\((\w+),")),
    ("multiplication_division_claim_witness",
     re.compile(r"rule\(cw_multiplication_division_claim, md\((\w+),")),
    ("ratio_proportion_claim_witness",
     re.compile(r"rule\(cw_ratio_proportion_claim, rp\((\w+),")),
    ("whole_number_addsub_claim_witness",
     re.compile(r"rule\(cw_whole_number_addsub_claim, wn\((\w+),")),
]
# Four families that dispatch to their own module; the claim table heads
# (cc/2+, fc/4, pv/2+, wn/2+) start at column 0 in the family's own file.
CW_MODULE_CLAIM_FAMILIES = [
    ("counting_claim_witness",
     "knowledge/crosswalk/families/cw_counting_claim.pl",
     re.compile(r"^cc\((\w+),", re.MULTILINE)),
    ("fraction_claim_witness",
     "knowledge/crosswalk/families/cw_fraction_claim.pl",
     re.compile(r"^fc\((\w+),", re.MULTILINE)),
    ("place_value_number_claim_witness",
     "knowledge/crosswalk/families/cw_place_value_number_claim.pl",
     re.compile(r"^pv\((\w+),", re.MULTILINE)),
    ("whole_number_claim_witness",
     "knowledge/crosswalk/families/cw_whole_number_claim.pl",
     re.compile(r"^wn\((\w+),", re.MULTILINE)),
]
# cw_edges.pl registry rows whose key params are correlated within one row.
CW_ACCOMMODATION_REGISTRY_RE = re.compile(
    r"rule\(cw_accommodation, registry\(([a-z_]+:[a-z_]+/\d+),(\w+),")
CW_EXEC_PRACTICE_RE = re.compile(
    r"rule\(cw_executable_practice, \(source_executable_practice_witness\("
    r"(\w+),[a-z_]+:[a-z_]+/\d+,\w+,(\w+),")
CW_FSM_ENGINE_VARIANT_RE = re.compile(
    r"rule\(cw_fsm_engine, fsm_engine_variant\((\w+),([a-z_]+:[a-z_]+/\d+),")
CW_ORR_ENTRY_REGISTRY_RE = re.compile(
    r"rule\(cw_orr_entry, registry\((\w+),[a-z_]+:[a-z_]+/\d+,\w+,(\w+),")
# formal/incompatibility/defeasible_inference.pl material_inference/3 rows
# (multiline; id, premises list, conclusion sent verbatim as term strings).
DEFEASIBLE_MATERIAL_INFERENCE_RE = re.compile(
    r"^material_inference\((\w+),\s*(\[.*?\]),\s*(.*?)\)\.\s*$",
    re.MULTILINE | re.DOTALL)
# knowledge/strategies/math action-pair fact tables (addition + fraction).
ACTION_CLUSTER_ROW_RE = re.compile(r"^action_cluster\((\w+),\s*(\w+)\)",
                                   re.MULTILINE)
FRACTION_ACTION_CLUSTER_ROW_RE = re.compile(
    r"^fraction_action_cluster\((\w+),\s*(\w+)\)", re.MULTILINE)
PRODUCTIVE_DEFORMATION_ROW_RE = re.compile(
    r"^productive_deformation\(\s*(\w+),\s*(\w+),\s*(\w+)\)", re.MULTILINE)
PRODUCTIVE_FRACTION_DEFORMATION_ROW_RE = re.compile(
    r"^productive_fraction_deformation\(\s*(\w+),\s*(\w+),\s*(\w+)\)",
    re.MULTILINE)
ACTION_VOCABULARY_KEY_RE = re.compile(r"^action_vocabulary\(\s*(\w+),",
                                      re.MULTILINE)
FRACTION_ACTION_VOCABULARY_KEY_RE = re.compile(
    r"^fraction_action_vocabulary\(\s*(\w+),", re.MULTILINE)
# knowledge/misconceptions/misconception_registry.pl attested_misconception/5
# (Name, Operation, ...); the line-start anchor skips the clause-body use.
ATTESTED_MISCONCEPTION_ROW_RE = re.compile(
    r"^attested_misconception\(\s*(\w+),\s*(\w+),", re.MULTILINE)
# formal/formalization/grounding_metaphors.pl fact tables.
GROUNDING_METAPHOR_DEF_RE = re.compile(
    r"^base_grounding_metaphor_definition\(\s*(\w+),\s*(\w+),\s*(\w+),",
    re.MULTILINE)
GROUNDS_INFERENCE_RE = re.compile(r"^grounds_inference\(\s*(\w+),\s*(\w+)",
                                  re.MULTILINE)
# formal/pml/mua_relations.pl metaphor_breaks_at/2 (short metaphor names).
METAPHOR_BREAKS_AT_RE = re.compile(r"^metaphor_breaks_at\(\s*(\w+),\s+(\w+)\)\.",
                                   re.MULTILINE)
# formal/learner/meta_interpreter.pl is_modal_operator/2: the four PML
# polarity operators; the witness takes '<operator>(<any term>)'.
IS_MODAL_OPERATOR_RE = re.compile(r"^is_modal_operator\((\w+)\(_\), (\w+)\)\.",
                                  re.MULTILINE)
# knowledge/geometry fact tables the run-2 claim_id/concept pools missed.
CONCEPT_RELATION_ROW_RE = re.compile(
    r"^concept_relation\(\s*(\w+),\s*(\w+),\s*(\w+),\s*(\w+)\)", re.MULTILINE)
GEOM_MISCONCEPTION_ID_RE = re.compile(r"^geom_misconception\(\s*(\w+)",
                                      re.MULTILINE)
VAN_HIELE_CLAIM_RE = re.compile(r"^van_hiele_material_claim\(\s*(\w+)",
                                re.MULTILINE)
# knowledge/standards/indiana/standard_k_ns_4.pl known_pattern/2 first args.
KNOWN_PATTERN_RE = re.compile(r"^known_pattern\(\s*([a-z_]+\(\d+\)),",
                              re.MULTILINE)
# formal/pml/rhythm_axioms.pl rhythm_transition/2 rows (single-line facts).
RHYTHM_TRANSITION_RE = re.compile(r"^rhythm_transition\((s\(\w+\)),\s*(.+?)\)\.",
                                  re.MULTILINE)

# The minimal event dict hermes/event_scoring.pl score_event/2 accepts (every
# required nested key present), from the verified domain report.
EVENT_SCORE_EVENT = {
    "event_id": "e1",
    "actor": {"role": "student", "pseudonym": "Quill"},
    "substrate": {"utterance_type": "claim"},
    "pml": {"status": "stable", "validity_focus": "subjective",
            "pragmatic_horizon_level": 1},
    "carspecken": {"recognition_risk": "low", "proprioceptive_delta": "stable"},
    "symbolic": {"commitments": ["counts_by_ones"], "incompatibilities": []},
}

# ---------------------------------------------------------------------------
# Run-3 authored tuple lists. Authored lists are honest here because these
# key spaces are computed by the witness (arithmetic re-derived, budgets
# compared, proofs re-walked, dynamic state read) or the enum lives in code —
# no fact file enumerates them, so a regex harvest would have nothing to
# read. Tuples copied from the 2026-08-22 verified domain reports; each entry
# names the backing rule. Number-typed params carry JSON numbers, a
# deliberate deviation from the all-strings tuple convention.
AUTHORED_TUPLE_DOMAINS = {
    # cw_edges.pl cw_godel_primes: query is an is_prime/1, nth_prime/1, or
    # product_of_list/1 term; automata / sequent_engine re-derive the trace.
    "godel_primes_witness": (("query", "source"), [
        ("is_prime(7)", "automata"),
        ("nth_prime(3)", "automata"),
        ("product_of_list([2,3,5])", "sequent_engine"),
    ], "tuple"),
    # cw_edges.pl cw_grounded_arith: executes the grounded op under a cost
    # snapshot; output must unify with the computed result (tally
    # recollections, never integers).
    "grounded_arith_witness": (("operation", "inputs", "output", "source"), [
        ("add", "[recollection([tally]),recollection([tally])]",
         "recollection([tally,tally])", "grounded_arithmetic"),
        ("subtract", "[recollection([tally,tally]),recollection([tally])]",
         "recollection([tally])", "grounded_arithmetic"),
        ("successor", "[recollection([tally])]",
         "recollection([tally,tally])", "grounded_arithmetic"),
    ], "tuple"),
    # cw_edges.pl cw_domain_context: reads the CURRENT sequent_engine domain
    # (default n) — dynamic state, not a fact table; the default-state pairs.
    "domain_context_witness": (("domain", "context", "source"), [
        ("n", "not_projected_by_source", "domain_atom"),
        ("not_projected_by_source", "natural_numbers", "domain_context"),
    ], "tuple"),
    # cw_edges.pl cw_mua_coherence: scores free corpus text against
    # mua_relations:kind_vocabulary_terms/2 — a det computed scorer.
    "mua_coherence_witness": (("subject", "input", "source"), [
        ("unit_fraction_iteration",
         "iterate the unit fraction against the referent whole",
         "pml_vocabulary"),
        ("count_on_from_larger", "count on from the larger addend",
         "pml_vocabulary"),
    ], "tuple"),
    # cw_edges.pl cw_normative_crisis: a non-mutating guard over
    # axioms_domains.pl prohibition/2 under the current domain (default n).
    "normative_crisis_witness": (("context", "goal", "source"), [
        ("natural_numbers", "subtract(1,2,-1)", "prohibition"),
        ("natural_numbers", "subtract(3,5,_)", "prohibition"),
    ], "tuple"),
    # cw_edges.pl cw_unit_coordination strategy_compose lane: the family rule
    # hard-codes the compose(2,3) ground demo — exactly one tuple exists.
    "unit_coordination_witness": (("key", "detail", "source"), [
        ("compose(2,3)", "composite(6)", "strategy_compose"),
    ], "tuple"),
    # dispatch_spec viability_witness: embodied_prover / meta_interpreter
    # check_viability/2 over any numbers with resources >= cost.
    "viability_witness": (("resources", "cost", "source"), [
        (5, 1, "embodied_prover"),
        (10, 10, "meta_interpreter"),
    ], "tuple"),
    # formal/tools/axiom_pack_audit.pl hierarchy_proof_witness/2 clause
    # heads: five term shapes re-proved on call, not fact rows.
    "axiom_hierarchy_witness": (("kind",), [
        ("domain_expansion(n_to_z)",),
        ("geometry_cover(square, rectangle)",),
        ("number_theory_self_defeat([2,3,5])",),
    ], "tuple"),
    # mua_relations:kind_mua_coherence_witness/4: det scorer over any
    # (kind, text); row_text is a json param and must stay a plain string.
    "mua_kind_coherence_witness": (("kind", "row_text"), [
        ("count_on_from_larger", "count on"),
        ("fraction", "unit fraction"),
    ], "tuple"),
    # hermes/event_scoring.pl score_event/2: a structured event dict, not an
    # enumerable key space.
    "event_score": (("event",), [(EVENT_SCORE_EVENT,)], "tuple"),
    "batch_event_score": (("events",), [([EVENT_SCORE_EVENT],)], "tuple"),
    # formal/dialectic/critique.pl bad_infinite_witness/2: needs a cyclic
    # comp_nec proof term; the canonical t_b/t_n bad-infinite cycle.
    "critique_bad_infinite": (("proof",), [
        ("proof(pml_rhythm(s(t_b) => s(comp_nec(t_n))), "
         "([s(t_b)] => [s(comp_nec(t_n))]), "
         "[proof(pml_rhythm(s(t_n) => s(comp_nec(t_b))), "
         "([s(t_n)] => [s(comp_nec(t_b))]), "
         "[proof(pml_rhythm(s(t_b) => s(comp_nec(t_n))), "
         "([s(t_b)] => [s(comp_nec(t_n))]), [])])])",),
    ], "tuple"),
    # formal/sequent/embodied_prover.pl proves_witness/5: the identity
    # sequent always proves under a finite budget (resources is a number).
    "embodied_proof_witness": (("sequent", "resources"), [
        ("([a] => [a])", 10),
    ], "tuple"),
    # sequent_engine:incoherent_witness/2: a plain negation pair is the
    # minimal incoherent context.
    "incoherent_witness": (("context",), [("[p, neg(p)]",)], "tuple"),
    # incompatibility_sets:incompatibility_entailment_witness: the identity
    # replacement always preserves joint incompatibility; non-identity
    # positive pairs must be mined from the profiles themselves.
    "incompatibility_entailment_witness": (("replacement", "replaced"), [
        ("misconception(count_all_when_count_on_available)",
         "misconception(count_all_when_count_on_available)"),
    ], "tuple"),
    # formal/pml/intersubjective_praxis.pl mutual-recognition clause:
    # participant atoms are free but must differ.
    "intersubjective_material_witness": (("from", "to"), [
        ("[n(confession(alice)), n(confession(bob))]",
         "n(exp_nec(forgiveness(alice, bob)))"),
    ], "tuple"),
    # formal/formalization/axioms_robinson.pl robinson_axiom_witness/3:
    # claim must unify with the axiom clause's shape with integer bindings.
    "robinson_axiom_witness": (("axiom", "claim"), [
        ("q3_zero_or_successor", "o(eq(4, succ(3)))"),
    ], "tuple"),
    # formal/formalization/axioms_geometry.pl rejection profiles: entailment
    # holds iff the entailer rejects every restriction the entailed rejects;
    # identity and X->quadrilateral hold for every shape.
    "geometry_entailment_witness": (("entailer", "entailed"), [
        ("square", "rectangle"),
        ("rhombus", "rhombus"),
        ("kite", "quadrilateral"),
    ], "tuple"),
    # knowledge/geometry/concepts/quadrilateral_incompatibility.pl
    # quad_rejects/2 profiles, same entailment rule as above.
    "geometry_quadrilateral_entailment_witness": (("entailer", "entailed"), [
        ("square", "rectangle"),
        ("trapezoid", "trapezoid"),
        ("rhombus", "quadrilateral"),
    ], "tuple"),
    # standard_k_ns_3: counts the supplied list and its reverse — any finite
    # atom list serves.
    "standard_k_ns_3_order_independence_witness": (("objects",), [
        ("[apple, pear, plum]",),
    ], "tuple"),
    # standard_k_ns_5_6: grounded counting over two supplied finite lists.
    "standard_k_ns_5_6_compare_groups_witness": (("group_a", "group_b"), [
        ("[a, b, c]", "[x, y]"),
    ], "tuple"),
    # incompatibility_discovery:classify_candidate_set_witness/4 over the
    # finite scratch programs; set is list-typed (the 08-22 defect fix) and a
    # Prolog-list string parses via json_to_term.
    "incompatibility_discovery_witness": (("context", "set"), [
        ("finite_three_rule_program",
         "[rule(a_requires_b), rule(b_requires_c), rule(a_forbids_c)]"),
        ("finite_loop_program", "[rule(loop_self)]"),
    ], "tuple"),
    # teacher_layer/2 is det over any practice atom; counting_on is the
    # report-verified practice.
    "teacher_layer": (("practice",), [("counting_on",)], "tuple"),
    # trace_adjudication: the ledger is a STRICT dict with exactly
    # {proposals, adjudications}; the empty ledger is the cheap key.
    "trace_adjudication": (("utterances", "ledger"), [
        ([{"id": "u1", "speaker": "T", "text": "um, what did you notice?"}],
         {"proposals": [], "adjudications": []}),
    ], "tuple"),
    # misconception_jumps_witness: the one deformation family whose trace
    # parses to number-line jumps today (trace_step_jump/2); a, b integers.
    "misconception_jumps_witness": (("operation", "deformation", "a", "b"), [
        ("addition", "round_without_adjusting", 38, 27),
    ], "tuple"),
    # hermes/pair_scoring.pl pair_reason_witness/4: the pair needs a shared
    # pairing reason; shared source.metadata domain+topic supplies two.
    "pair_candidate_witness": (("event_a", "event_b"), [
        ({"event_id": "e1",
          "actor": {"role": "student", "pseudonym": "Quill"},
          "source": {"metadata": {"domain": "fractions",
                                  "topic": "unit_fractions"}}},
         {"event_id": "e2",
          "actor": {"role": "student", "pseudonym": "Sable"},
          "source": {"metadata": {"domain": "fractions",
                                  "topic": "unit_fractions"}}}),
    ], "tuple"),
    # notation_render: kind enum lives in code; everything else defaulted.
    "notation_render": (("kind",), [("write_equation",), ("mirror_written",)],
                        "tuple"),
    # compute: the four grounded operations with integer operands.
    "compute": (("operation", "a", "b", "limit", "mode"), [
        ("add", 3, 4, 50, "direct"),
        ("subtract", 7, 3, 50, "direct"),
        ("multiply", 3, 4, 50, "direct"),
        ("divide", 12, 3, 50, "direct"),
    ], "tuple"),
    # canonical_check classifies any functor-name list; never refuses.
    "canonical_check": (("terms",), [(["add_grounded"],)], "tuple"),
    # brandomian_check computes b_incoherent over any commitment list.
    "brandomian_check": (("commitments",), [(["p", "neg(p)"],)], "tuple"),
    # carving_strategy_proof: a true fact of the operation with a productive
    # proof in the carving store.
    "carving_strategy_proof": (("operation", "x", "y", "z"), [
        ("add", 2, 3, 5),
    ], "tuple"),
    # balance_solve_witness: one-unknown balance a*x + b = c with a
    # non-negative integer solution.
    "balance_solve_witness": (("a", "b", "c"), [(3, 4, 7)], "tuple"),
    # deontic_scorekeeper requires_entitlement_fact/1: today the arity-6
    # result_of(cross_multiply, ...) shape.
    "deontic_requires_entitlement": (("proposition",), [
        ("result_of(cross_multiply, 2, 3, 4, 6, ok)",),
    ], "tuple"),
    # fraction_cgi_addition: a CGI addition automaton over same-denominator
    # fraction operands.
    "fraction_cgi_addition": (("kind", "na", "nb", "d"), [
        ("count_on_from_larger", 7, 8, 10),
    ], "tuple"),
    # fraction_comparison_compare: 12-family enum in hermes_worker.pl
    # fraction_comparison_family/1 with per-family strict arg counts; only
    # the report-verified four-int family is authored.
    "fraction_comparison_compare": (("family", "n1", "d1", "n2", "d2"), [
        ("number_line_fraction_comparison", 1, 3, 2, 3),
    ], "tuple"),
    # fraction_render: arith is the fully-defaulted kind.
    "fraction_render": (("kind",), [("arith",)], "tuple"),
    # dispatch_geometry/4 (hermes_worker.pl): predicate + positional args.
    "geometry": (("predicate", "args"), [
        ("matching_concepts", [["ruler", "units"], "any"]),
    ], "tuple"),
}


def _standard_pairs(rel: str, framework: str, log) -> list[tuple[str, str]]:
    text = _read(rel, log)
    if not text:
        return []
    seen = set()
    out = []
    for m in STANDARD_ANCHOR_RE.finditer(text):
        concept, fw, code = m.group(1), m.group(2), m.group(3)
        if fw != framework:
            continue
        key = (concept, code)
        if key not in seen:
            seen.add(key)
            out.append(key)
    return out


def harvest_tuple_domains(log) -> dict[str, tuple[tuple[str, ...], list, str]]:
    domains: dict[str, tuple[tuple[str, ...], list, str]] = {}

    # item 5: input_contract, item 4: strategy_trace — both read the same
    # 284-row execution-verified contract table; all rows carry
    # verified(strategy_trace_ok) so no separate filtering is needed.
    text = _read("knowledge/strategies/automaton_input_contracts.pl", log)
    input_contract_pairs: list[tuple[str, str]] = []
    strategy_trace_pairs: list[tuple[str, dict]] = []
    if text:
        for m in CONTRACT_RE.finditer(text):
            operation, kind, _shape_raw, example_raw = m.groups()
            input_contract_pairs.append((operation, kind))
            try:
                example = json.loads(example_raw.replace('\\"', '"'))
            except json.JSONDecodeError:
                log(f"strategy_trace example unparsable for {operation}/{kind}")
                continue
            strategy_trace_pairs.append((kind, example))
    if input_contract_pairs:
        domains["input_contract"] = (("operation", "kind"), input_contract_pairs, "tuple")
    if strategy_trace_pairs:
        domains["strategy_trace"] = (("strategy", "input"), strategy_trace_pairs, "paired")

    # item 5: the two metaphor witnesses. metaphor_source/4 is multifile
    # across measuring_stick.pl (14 rows, measuring-stick family) and
    # lakoff_nunez_inventory.pl (21 rows, L&N family) — both files declare
    # `:- multifile metaphor_source/4` and both witnesses probe the SAME
    # shared fact base, filtered internally by their own family-membership
    # check. Reading only measuring_stick.pl (the widening spec's literal
    # file pointer) would hand geometry_lakoff_nunez_metaphor_witness 14
    # pairs that can never match its family filter — a deliberate deviation:
    # union both files' pairs and let each op's own family check select its
    # real subset, which is what makes both ops reachable at all.
    ms_text = _read("knowledge/geometry/metaphors/measuring_stick.pl", log)
    ln_text = _read("knowledge/geometry/metaphors/lakoff_nunez_inventory.pl", log)
    metaphor_pairs: list[tuple[str, str]] = []
    seen_mp = set()
    for src in (ms_text, ln_text):
        if not src:
            continue
        for m in METAPHOR_SOURCE_RE.finditer(src):
            pair = (m.group(1), m.group(2))
            if pair not in seen_mp:
                seen_mp.add(pair)
                metaphor_pairs.append(pair)
    if metaphor_pairs:
        domains["geometry_measuring_stick_metaphor_witness"] = (
            ("concept", "metaphor"), metaphor_pairs, "tuple")
        domains["geometry_lakoff_nunez_metaphor_witness"] = (
            ("concept", "metaphor"), metaphor_pairs, "tuple")

    # item 5: the six standard witnesses, each keyed on its own framework
    # value inside its own file (grade5 takes Framework as an explicit third
    # param, so it keeps every framework rather than filtering to one).
    standard_ops = [
        ("geometry_ccss_standard_witness", "knowledge/standards/ccss/geometry.pl", "ccss"),
        ("geometry_indiana_standard_witness", "knowledge/standards/indiana/geometry.pl", "in_indiana"),
        ("geometry_im_grade6_lesson_standard_witness", "knowledge/standards/im/grade_6.pl", "im_lesson"),
        ("geometry_im_grade7_lesson_standard_witness", "knowledge/standards/im/grade_7.pl", "im_lesson"),
        ("geometry_im_grade8_lesson_standard_witness", "knowledge/standards/im/grade_8.pl", "im_lesson"),
    ]
    for op, rel, framework in standard_ops:
        pairs = _standard_pairs(rel, framework, log)
        if pairs:
            domains[op] = (("concept", "code"), pairs, "tuple")
    g5_text = _read("knowledge/standards/im/grade_5.pl", log)
    if g5_text:
        triples = []
        seen_g5 = set()
        for m in STANDARD_ANCHOR_RE.finditer(g5_text):
            key = (m.group(1), m.group(2), m.group(3))
            if key not in seen_g5:
                seen_g5.add(key)
                triples.append(key)
        if triples:
            domains["geometry_im_grade5_standard_anchor_witness"] = (
                ("concept", "framework", "code"), triples, "tuple")

    # item 11: semantic_material_witness. semantic_material_witness([s(Stage)],
    # s(ModalTerm), _) :- dialectical_transition(Stage, ModalTerm), ... —
    # verified by reading the clause body, not assumed from the raw pair
    # shape; From/To need the [s(_)]/s(_) wrapping to unify at all.
    sa_text = _read("formal/pml/semantic_axioms.pl", log)
    if sa_text:
        pairs = []
        for m in DIALECTICAL_TRANSITION_RE.finditer(sa_text):
            stage, modal_term = m.group(1), m.group(2).strip()
            pairs.append((f"[s({stage})]", f"s({modal_term})"))
        if pairs:
            domains["semantic_material_witness"] = (("from", "to"), pairs, "tuple")

    # item 11: sequent_proof_witness (dispatch_irregular, not in
    # dispatch_spec.pl — TUPLE_DOMAINS reaches it because build_worklist
    # checks TUPLE_DOMAINS before consulting specs/IRREGULAR_SPECS). Source
    # is one of five real cw_sequent_proof source atoms; the sequent is a
    # trivial identity proof ([X]=>[X]) written in canonical functor form
    # (not the infix `=>` operator) so it parses via term_string regardless
    # of which module's operator table is in scope when the worker reads it.
    edges_text = _read("knowledge/crosswalk/families/cw_edges.pl", log)
    if edges_text:
        sources = sorted(set(SEQUENT_PROOF_SOURCE_RE.findall(edges_text)))
        if sources:
            sequent = "=>([comp_nec(a)],[comp_nec(a)])"
            domains["sequent_proof_witness"] = (
                ("sequent", "source"), [(sequent, s) for s in sources], "tuple")

    # ---- Run-3 (2026-08-22): domains for the 08-19 audit's full-refusal
    # ops, per the two verified domain reports. Correlated params come from
    # the SAME fact row throughout; the two deliberate crosses (claim
    # canonicals x 'literature_commitment', axiom packs x the two store
    # readers) pair a harvested key with a fixed always-live lane the reports
    # verified, not with another harvested pool.
    if edges_text:
        # The ten cw_edges claim families: canonical enum from the family's
        # own claim rows, source fixed to the literature_commitment lane.
        for op, rx in CW_EDGE_CLAIM_FAMILIES:
            canonicals = sorted(set(rx.findall(edges_text)))
            if canonicals:
                domains[op] = (
                    ("canonical", "source"),
                    [(c, "literature_commitment") for c in canonicals],
                    "tuple")
        # cw_accommodation registry/6 rows: (target, source) from one row;
        # target is a Module:Name/Arity term string.
        pairs = CW_ACCOMMODATION_REGISTRY_RE.findall(edges_text)
        if pairs:
            domains["accommodation_witness"] = (("target", "source"), pairs,
                                                "tuple")
        # cw_executable_practice source_executable_practice_witness heads:
        # (variant, source) from one head; the predicate and practice_kind
        # slots are dropped by dispatch.
        pairs = CW_EXEC_PRACTICE_RE.findall(edges_text)
        if pairs:
            domains["executable_practice_witness"] = (("variant", "source"),
                                                      pairs, "tuple")
        # cw_fsm_engine fsm_engine_variant rows: (source, descriptor);
        # descriptor is a Module:Name/Arity term string.
        pairs = [(d, s) for s, d in CW_FSM_ENGINE_VARIANT_RE.findall(edges_text)]
        if pairs:
            domains["fsm_engine_witness"] = (("descriptor", "source"), pairs,
                                             "tuple")
        # cw_orr_entry registry/7 rows: (variant, source) from one row.
        pairs = CW_ORR_ENTRY_REGISTRY_RE.findall(edges_text)
        if pairs:
            domains["orr_entry_witness"] = (("variant", "source"), pairs,
                                            "tuple")
    # The four claim families with their own module: canonical enum from the
    # family's own claim table, same literature_commitment lane.
    for op, rel, rx in CW_MODULE_CLAIM_FAMILIES:
        text = _read(rel, log)
        if text:
            canonicals = sorted(set(rx.findall(text)))
            if canonicals:
                domains[op] = (
                    ("canonical", "source"),
                    [(c, "literature_commitment") for c in canonicals],
                    "tuple")

    # material_inference_witness, source='defeasible' (the plain fact-table
    # lane): defeasible_inference.pl material_inference/3 rows sent verbatim
    # as term strings.
    text = _read("formal/incompatibility/defeasible_inference.pl", log)
    if text:
        tuples = [(mid, prem, concl, "defeasible")
                  for mid, prem, concl in
                  DEFEASIBLE_MATERIAL_INFERENCE_RE.findall(text)]
        if tuples:
            domains["material_inference_witness"] = (
                ("inference_id", "premises", "conclusion", "source"), tuples,
                "tuple")

    # The action-pair fact tables back four ops at once; read both files one
    # time each. Backing predicates: action_cluster/2 +
    # productive_deformation/3 + action_vocabulary/2 (sar_add_action_pairs.pl,
    # operation addition) and their fraction_* twins
    # (fraction_action_pairs.pl, operation fraction).
    add_text = _read("knowledge/strategies/math/sar_add_action_pairs.pl", log)
    frac_text = _read("knowledge/strategies/math/fraction_action_pairs.pl", log)
    cluster_tuples = []
    deformation_tuples = []
    incompat_tuples = []
    vocab_tuples = []
    if add_text:
        cluster_tuples += [("addition", kind, cluster, "addition_pairs")
                           for kind, cluster in
                           ACTION_CLUSTER_ROW_RE.findall(add_text)]
        for prod, deform, family in \
                PRODUCTIVE_DEFORMATION_ROW_RE.findall(add_text):
            deformation_tuples.append(("addition", prod, deform, family,
                                       "registry"))
            # misconception_incompatibility_witness keys the registered
            # action_automaton_pair rows: move=Deformation,
            # conflict=strategy(Operation, Productive) — same fact row.
            incompat_tuples.append((deform, f"strategy(addition,{prod})"))
        vocab_tuples += [(key, "additive_action")
                         for key in ACTION_VOCABULARY_KEY_RE.findall(add_text)]
    if frac_text:
        cluster_tuples += [("fraction", kind, cluster, "fraction_pairs")
                           for kind, cluster in
                           FRACTION_ACTION_CLUSTER_ROW_RE.findall(frac_text)]
        fraction_kinds = []
        for prod, deform, family in \
                PRODUCTIVE_FRACTION_DEFORMATION_ROW_RE.findall(frac_text):
            deformation_tuples.append(("fraction", prod, deform, family,
                                       "registry"))
            incompat_tuples.append((deform, f"strategy(fraction,{prod})"))
            fraction_kinds.append(prod)
        vocab_tuples += [(key, "fraction_action") for key in
                         FRACTION_ACTION_VOCABULARY_KEY_RE.findall(frac_text)]
        # fraction_compare keys the productive kinds of the same pair table;
        # a and b are free integers (the op's own defaults).
        if fraction_kinds:
            domains["fraction_compare"] = (
                ("kind", "a", "b"), [(k, 5, 3) for k in fraction_kinds],
                "tuple")
    if cluster_tuples:
        domains["action_cluster_witness"] = (
            ("operation", "kind", "cluster", "source"), cluster_tuples, "tuple")
    if deformation_tuples:
        domains["productive_deformation_witness"] = (
            ("operation", "productive", "deformation", "family", "source"),
            deformation_tuples, "tuple")
    if incompat_tuples:
        domains["misconception_incompatibility_witness"] = (
            ("move", "conflict"), incompat_tuples, "tuple")
    if vocab_tuples:
        domains["practice_vocabulary_witness"] = (("key", "source"),
                                                  vocab_tuples, "tuple")

    # misconception_hook_witness, source='literature_registry' (the
    # enumerable lane): attested_misconception/5 rows; outcome wraps the
    # row's own name and family MUST equal the row's operation.
    text = _read("knowledge/misconceptions/misconception_registry.pl", log)
    if text:
        tuples = [(op_, f"misconception({name})", op_, "literature_registry")
                  for name, op_ in ATTESTED_MISCONCEPTION_ROW_RE.findall(text)]
        if tuples:
            domains["misconception_hook_witness"] = (
                ("operation", "outcome", "family", "source"), tuples, "tuple")

    # grounding_metaphor_witness (definition lane): the anchor is authored
    # from the SAME base_grounding_metaphor_definition/4 row as
    # domains(Source,Target). grounding_inference_witness:
    # grounds_inference/3 (metaphor, inference) pairs from the same file.
    text = _read("formal/formalization/grounding_metaphors.pl", log)
    if text:
        tuples = [(met, f"domains({src},{tgt})", "definition")
                  for met, src, tgt in GROUNDING_METAPHOR_DEF_RE.findall(text)]
        if tuples:
            domains["grounding_metaphor_witness"] = (
                ("metaphor", "anchor", "source"), tuples, "tuple")
        pairs = sorted(set(GROUNDS_INFERENCE_RE.findall(text)))
        if pairs:
            domains["grounding_inference_witness"] = (
                ("metaphor", "inference"), pairs, "tuple")

    # metaphor_break_witness, source='mua' (the enumerable lane):
    # mua_relations.pl metaphor_breaks_at/2; detail fixed 'none'.
    text = _read("formal/pml/mua_relations.pl", log)
    if text:
        tuples = [(met, inf, "none", "mua")
                  for met, inf in METAPHOR_BREAKS_AT_RE.findall(text)]
        if tuples:
            domains["metaphor_break_witness"] = (
                ("metaphor", "inference", "detail", "source"), tuples, "tuple")

    # modal_context_witness: meta_interpreter.pl is_modal_operator/2 — the
    # four PML polarity operators wrapping any inner term.
    text = _read("formal/learner/meta_interpreter.pl", log)
    if text:
        tuples = [(f"{operator}(p)", context, "meta_interpreter")
                  for operator, context in IS_MODAL_OPERATOR_RE.findall(text)]
        if tuples:
            domains["modal_context_witness"] = (
                ("term", "context", "source"), tuples, "tuple")

    # axiom_pack_witness: default_axiom_pack/1 in sequent_engine.pl is the
    # load-time enabled set; enabled_predicate and enabled_store read the
    # same dynamic store, so crossing them is deliberate, not a correlated-
    # row violation. ('core', the cw_edges edge sample, is NOT default-
    # enabled — the run-2 pool trap this replaces.)
    text = _read("formal/sequent/sequent_engine.pl", log)
    if text:
        packs = sorted(set(DEFAULT_AXIOM_PACK_RE.findall(text)))
        if packs:
            domains["axiom_pack_witness"] = (
                ("pack", "source"),
                [(p, s) for p in packs
                 for s in ("enabled_predicate", "enabled_store")], "tuple")

    # geometry_cross_link_witness: concept_relation/4 rows (multiline); the
    # authored status arg is left to its dispatch default, which matches
    # every row.
    text = _read("knowledge/geometry/concepts/cross_links.pl", log)
    if text:
        tuples = [(src, rel_, tgt) for src, rel_, tgt, _status in
                  CONCEPT_RELATION_ROW_RE.findall(text)]
        if tuples:
            domains["geometry_cross_link_witness"] = (
                ("source", "relation", "target"), tuples, "tuple")

    # geometry_measurement_misconception_witness: geom_misconception/6 heads
    # whose clause lives in measurement.pl (the witness filters by clause
    # file) — the run-2 claim_id pool never held this id.
    text = _read("knowledge/geometry/concepts/measurement.pl", log)
    if text:
        ids = sorted(set(GEOM_MISCONCEPTION_ID_RE.findall(text)))
        if ids:
            domains["geometry_measurement_misconception_witness"] = (
                ("id_value",), [(i,) for i in ids], "tuple")

    # geometry_van_hiele_material_witness: van_hiele_material_claim/5 first
    # args live outside the concepts dir the run-2 claim_id pool reads.
    text = _read("knowledge/geometry/van_hiele/transitions.pl", log)
    if text:
        ids = sorted(set(VAN_HIELE_CLAIM_RE.findall(text)))
        if ids:
            domains["geometry_van_hiele_material_witness"] = (
                ("claim_id",), [(i,) for i in ids], "tuple")

    # standard_k_ns_4_verify_subitizing_witness: known_pattern/2 first args
    # (dice/fingers/ten_frame terms).
    text = _read("knowledge/standards/indiana/standard_k_ns_4.pl", log)
    if text:
        patterns = sorted(set(KNOWN_PATTERN_RE.findall(text)))
        if patterns:
            domains["standard_k_ns_4_verify_subitizing_witness"] = (
                ("pattern",), [(p,) for p in patterns], "tuple")

    # rhythm_transition_witness: rhythm_axioms.pl rhythm_transition/2 direct
    # modal pairs, sent verbatim (requires axiom_pack_enabled(rhythm), which
    # holds on a stock worker).
    text = _read("formal/pml/rhythm_axioms.pl", log)
    if text:
        pairs = RHYTHM_TRANSITION_RE.findall(text)
        if pairs:
            domains["rhythm_transition_witness"] = (("from", "to"), pairs,
                                                    "tuple")

    # Authored tuple lists last; a harvested domain for the same op would be
    # a programming error, so keep the harvest and say so.
    for op, entry in AUTHORED_TUPLE_DOMAINS.items():
        if op in domains:
            log(f"authored domain for {op} collides with a harvested one; "
                f"keeping the harvested domain")
            continue
        domains[op] = entry

    for op, (names, tuples, cls) in sorted(domains.items()):
        log(f"tuple domain {op}: {len(tuples)} {'+'.join(names)} tuples ({cls})")
    return domains


class CovWorker:
    """One coverage-instrumented worker instance (one segment)."""

    def __init__(self, outdir: Path, segno: int, swipl: str):
        self.segfile = outdir / f"cov_seg_{segno:03d}.dat"
        self.errfile = outdir / f"cov_seg_{segno:03d}.stderr"
        env = dict(os.environ, HERMES_COV_SEGMENT=str(self.segfile))
        self.err_fh = open(self.errfile, "w")
        self.proc = subprocess.Popen(
            [swipl, "-q", "-l", "hermes_worker.pl", "-l", COV_WORKER,
             "-g", "cov_main"],
            cwd=REPO, env=env, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=self.err_fh, text=True, bufsize=1)
        self.items: list[str] = []  # ids completed in this segment

    def request(self, payload: dict, timeout: float):
        line = json.dumps(payload, ensure_ascii=False)
        self.proc.stdin.write(line + "\n")
        self.proc.stdin.flush()
        sel = selectors.DefaultSelector()
        sel.register(self.proc.stdout, selectors.EVENT_READ)
        deadline = time.monotonic() + timeout
        buf = ""
        while time.monotonic() < deadline:
            if sel.select(timeout=min(1.0, deadline - time.monotonic())):
                chunk = self.proc.stdout.readline()
                if chunk == "":
                    raise BrokenPipeError("worker stdout closed")
                buf = chunk
                break
        sel.close()
        if not buf:
            raise TimeoutError()
        return json.loads(buf)

    def stop(self, grace: float = 60.0) -> bool:
        """Close stdin and let the worker save through the clean EOF path
        (the save can take a while on a full runtime). Escalate to TERM,
        then KILL, only if it does not exit on its own. Returns True if the
        segment file exists afterward (coverage preserved)."""
        if self.proc.poll() is None:
            try:
                self.proc.stdin.close()
            except OSError:
                pass
            try:
                self.proc.wait(timeout=grace)
            except subprocess.TimeoutExpired:
                self.proc.send_signal(signal.SIGTERM)
                try:
                    self.proc.wait(timeout=15)
                except subprocess.TimeoutExpired:
                    self.proc.kill()
                    self.proc.wait()
        self.err_fh.close()
        return self.segfile.exists() and self.segfile.stat().st_size > 0


def build_worklist(specs, pools, ops, max_per_op, log,
                   tuple_domains=None, irregular_specs=None):
    tuple_domains = tuple_domains or {}
    irregular_specs = irregular_specs or {}

    def pool_domain(pool_name: str, param_name: str) -> set:
        values = pools.get(pool_name, set())
        if param_name == "lesson_code":
            # item 3: lesson_code is a code, but not every harvested code is
            # a lesson (the pool also carries CCSS/Indiana standard codes).
            values = {v for v in values if IM_CODE.match(v)}
        return values

    items = []
    truncations = []
    for op in sorted(ops):
        items.append({"op": op, "args": {}, "class": "shape_probe"})

        op_cap = min(max_per_op, OP_SAMPLE_CAPS.get(op, max_per_op))

        if op in tuple_domains:
            param_names, tuples, cls = tuple_domains[op]
            domain = tuples
            if len(domain) > op_cap:
                truncations.append({"op": op, "param": "+".join(param_names),
                                    "domain": len(domain), "kept": op_cap})
                domain = domain[:op_cap]
            for tup in domain:
                items.append({"op": op, "args": dict(zip(param_names, tup)),
                             "class": cls})
            continue

        params = specs.get(op) or irregular_specs.get(op)
        if not params:
            continue
        pooled: list[tuple[str, str]] = []  # (param_name, pool_name)
        args_base = {}
        resolvable = True
        for name, typ, opt in params:
            if opt:
                continue
            pool_name = PARAM_POOL_ALIAS.get(name, name)
            if pool_name in pools and pool_domain(pool_name, name):
                pooled.append((name, pool_name))
                continue
            if typ in TYPE_FIXTURES:
                args_base[name] = TYPE_FIXTURES[typ]
            else:
                resolvable = False
        if not resolvable:
            continue
        if not pooled:
            # item 1: a resolvable op with no pooled param used to get
            # nothing beyond the shape probe above. If every required param
            # fixture-resolved, that is one real (if generic) call.
            if args_base:
                items.append({"op": op, "args": dict(args_base), "class": "fixture"})
            continue
        # Enumerate the FIRST pooled param fully; fix the rest to one sample.
        key_name, key_pool = pooled[0]
        for name, pool_name in pooled[1:]:
            args_base[name] = sorted(pool_domain(pool_name, name))[0]
        domain = sorted(pool_domain(key_pool, key_name))
        if len(domain) > op_cap:
            truncations.append({"op": op, "param": key_name,
                                "domain": len(domain), "kept": op_cap})
            domain = domain[:op_cap]
        for value in domain:
            args = dict(args_base)
            args[key_name] = value
            items.append({"op": op, "args": args, "class": "keyed"})

    # item 10: pedagogical_questions' explicit kind="all" probe. The generic
    # path already sweeps query over the phrase pool with kind left at its
    # server-side default ("topic"); this adds the one item that specifically
    # exercises kind="all", which nothing else in the worklist reaches.
    if "pedagogical_questions" in ops:
        items.append({"op": "pedagogical_questions",
                      "args": {"query": "all", "kind": "all"}, "class": "fixture"})

    for t in truncations:
        log(f"TRUNCATED {t['op']}.{t['param']}: {t['domain']} -> {t['kept']}")
    for it in items:
        digest = hashlib.sha1(
            json.dumps([it["op"], it["args"]], sort_keys=True).encode()
        ).hexdigest()[:12]
        it["id"] = f"{it['op']}:{digest}"
    return items, truncations


def print_worklist_table(items, ops, log):
    by_op_class: dict[str, Counter] = defaultdict(Counter)
    for it in items:
        by_op_class[it["op"]][it["class"]] += 1
    classes = ["shape_probe", "fixture", "keyed", "tuple", "paired"]
    real_ops = sorted(op for op, c in by_op_class.items()
                      if set(c) - {"shape_probe"})
    probe_only_ops = sorted(set(ops) - set(real_ops))
    log(f"dry-run: {len(ops)} ops total, {len(real_ops)} with real (non-probe) "
        f"items, {len(probe_only_ops)} still shape_probe-only")
    header = "op".ljust(48) + "".join(c.ljust(12) for c in classes) + "total"
    log(header)
    log("-" * len(header))
    for op in real_ops:
        counts = by_op_class[op]
        total = sum(counts.values())
        row = op.ljust(48) + "".join(str(counts.get(c, 0)).ljust(12) for c in classes)
        log(f"{row}{total}")
    log(f"probe-only ops ({len(probe_only_ops)}): " + ", ".join(probe_only_ops))


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out")
    ap.add_argument("--max-per-op", type=int, default=3000)
    ap.add_argument("--item-timeout", type=float, default=180.0)
    ap.add_argument("--segment-items", type=int, default=4000)
    ap.add_argument("--ops-filter", default=None,
                    help="regex; only ops matching it enter the work list "
                         "(smoke runs, targeted reruns)")
    ap.add_argument("--dry-run-worklist", action="store_true",
                    help="build pools and the worklist, print a per-op "
                         "count-by-class table, and exit before executing "
                         "any item (still boots one worker for health + "
                         "the harvest ops)")
    ap.add_argument("--replay-results", type=Path,
                    help="read a prior sweep_results.jsonl through the first-terminal merge and exit")
    ap.add_argument("--replay-op", default="notation_monitoring_chart",
                    help="op summarized by --replay-results")
    args = ap.parse_args()

    if args.replay_results is not None:
        counts = replay_outcomes(args.replay_results, args.replay_op)
        print(json.dumps({"op": args.replay_op, "outcomes": dict(counts)}, sort_keys=True))
        return 0
    if not args.out:
        ap.error("--out is required unless --replay-results is used")

    outdir = Path(args.out)
    outdir.mkdir(parents=True, exist_ok=True)
    swipl = os.environ.get("HERMES_SWIPL", "swipl")

    def log(msg):
        print(f"[sweep] {msg}", flush=True)

    results_path = outdir / "sweep_results.jsonl"
    done: set[str] = set()
    if results_path.exists():
        for line in results_path.open():
            try:
                item_id = json.loads(line)["id"]
            except (json.JSONDecodeError, KeyError):
                continue
            if isinstance(item_id, str):
                done.add(item_id)
        log(f"resume: {len(done)} items already recorded")
    results = results_path.open("a")

    segno = 0
    worker = CovWorker(outdir, segno, swipl)
    log("worker segment 0 spawned; waiting for health")
    health = worker.request({"id": "boot", "op": "health"}, timeout=600)
    ops = health.get("result", {}).get("ops", [])
    log(f"worker reports {len(ops)} ops")

    pools: dict[str, set] = defaultdict(set)
    for hop in HARVEST_OPS:
        if hop not in ops:
            continue
        try:
            reply = worker.request({"id": f"harvest:{hop}", "op": hop},
                                   timeout=max(360, args.item_timeout))
            walk_json(reply, pools)
            log(f"harvest {hop}: pools now " +
                ", ".join(f"{k}={len(v)}" for k, v in sorted(pools.items())))
        except (TimeoutError, BrokenPipeError, json.JSONDecodeError) as e:
            log(f"harvest {hop} failed: {type(e).__name__}")
    for rel in SUPPLEMENT_FILES:
        p = REPO / rel
        if not p.exists():
            log(f"supplement absent: {rel}")
            continue
        try:
            doc = json.loads(p.read_text())
        except (json.JSONDecodeError, OSError) as e:
            log(f"supplement unreadable: {rel} ({type(e).__name__})")
            continue
        if isinstance(doc, dict):
            for key in doc.keys():
                if isinstance(key, str) and IM_CODE.match(key):
                    pools["code"].add(key)
        walk_json(doc, pools)
        log(f"supplement {rel}: code pool now {len(pools['code'])}")
    harvest_static_pools(pools, log)
    (outdir / "domains.json").write_text(json.dumps(
        {k: sorted(v) for k, v in pools.items()}, indent=1))

    specs = parse_dispatch_specs()
    log(f"dispatch_spec declares {len(specs)} typed ops")
    tuple_domains = harvest_tuple_domains(log)
    worklist_path = outdir / "worklist.jsonl"
    if worklist_path.exists():
        items = [json.loads(l) for l in worklist_path.open()]
        log(f"worklist reused: {len(items)} items")
    else:
        items, truncations = build_worklist(specs, pools, ops, args.max_per_op,
                                            log, tuple_domains, IRREGULAR_SPECS)
        with worklist_path.open("w") as f:
            for it in items:
                f.write(json.dumps(it, ensure_ascii=False) + "\n")
        (outdir / "truncations.json").write_text(json.dumps(truncations, indent=1))
        log(f"worklist built: {len(items)} items")

    if args.dry_run_worklist:
        print_worklist_table(items, ops, log)
        worker.stop()
        results.close()
        return 0

    outcomes = Counter()
    terminal_outcomes = set(done)
    requeue: list[dict] = []
    seg_count = 0

    def record(item, outcome, ms, note=""):
        if item["id"] in terminal_outcomes:
            return False
        terminal_outcomes.add(item["id"])
        outcomes[outcome] += 1
        results.write(json.dumps({
            "id": item["id"], "op": item["op"], "class": item["class"],
            "outcome": outcome, "ms": round(ms, 1), "note": note[:400],
        }, ensure_ascii=False) + "\n")
        results.flush()
        return True

    def rotate(reason):
        nonlocal worker, segno, seg_count
        saved = worker.stop()
        if not saved and worker.items:
            requeue.extend(i for i in pending_lookup(worker.items))
            log(f"segment {segno} lost ({reason}); requeued "
                f"{len(worker.items)} completed items")
        segno += 1
        seg_count = 0
        worker = CovWorker(outdir, segno, swipl)
        worker.request({"id": f"boot{segno}", "op": "health"}, timeout=600)
        log(f"worker segment {segno} spawned ({reason})")

    if args.ops_filter:
        rx = re.compile(args.ops_filter)
        before = len(items)
        items = [it for it in items if rx.search(it["op"])]
        log(f"ops-filter {args.ops_filter!r}: {before} -> {len(items)} items")

    by_id = {it["id"]: it for it in items}

    def pending_lookup(ids):
        return [by_id[i] for i in ids if i in by_id]

    queue = deque(it for it in items if it["id"] not in done)
    total = len(queue)
    log(f"executing {total} items")
    n = 0
    requeued_once: set[str] = set()
    # Circuit breaker: five timeouts on one op trips it, and the op's
    # remaining items record op_circuit_open without executing. Run-2's
    # first attempt spent 17 hours rotating segments on one op whose every
    # keyed call exceeded the item timeout; the breaker makes that cost
    # five items, loudly, instead of the whole job.
    op_timeout_counts: Counter = Counter()
    tripped_ops: set[str] = set()
    while queue:
        item = queue.popleft()
        n += 1
        if item["op"] in tripped_ops:
            record(item, "op_circuit_open", 0.0,
                   note="skipped after 5 timeouts on this op")
            continue
        timeout = TIMEOUT_OVERRIDES.get(item["op"], args.item_timeout)
        t0 = time.monotonic()
        try:
            reply = worker.request(
                {"id": item["id"], "op": item["op"], **item["args"]}, timeout)
            ms = (time.monotonic() - t0) * 1000
            ok = reply.get("ok")
            if ok is True:
                record(item, "ok", ms)
            else:
                record(item, "refused", ms,
                       note=str(reply.get("error", reply.get("message", ""))))
            worker.items.append(item["id"])
            seg_count += 1
        except TimeoutError:
            ms = (time.monotonic() - t0) * 1000
            record(item, "timeout", ms)
            op_timeout_counts[item["op"]] += 1
            if op_timeout_counts[item["op"]] >= 5 and item["op"] not in tripped_ops:
                tripped_ops.add(item["op"])
                log(f"CIRCUIT OPEN for {item['op']} after 5 timeouts; "
                    f"its remaining items record op_circuit_open")
            rotate(f"timeout on {item['op']}")
        except (BrokenPipeError, json.JSONDecodeError, OSError) as e:
            ms = (time.monotonic() - t0) * 1000
            record(item, "worker_died", ms, note=type(e).__name__)
            rotate(f"death on {item['op']}")
        if seg_count >= args.segment_items:
            rotate("segment rotation")
        if n % 500 == 0:
            log(f"{n}/{total} done; outcomes: {dict(outcomes)}")
        if not queue and requeue:
            fresh = [i for i in requeue if i["id"] not in requeued_once]
            for i in fresh:
                requeued_once.add(i["id"])
            queue = deque(fresh)
            requeue = []
            if queue:
                log(f"requeue pass: {len(queue)} items")

    worker.stop()
    results.close()
    (outdir / "sweep_summary.json").write_text(json.dumps({
        "items": total, "outcomes": dict(outcomes), "segments": segno + 1,
        "ops": len(ops), "pools": {k: len(v) for k, v in pools.items()},
    }, indent=1))
    log(f"done; outcomes: {dict(outcomes)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
