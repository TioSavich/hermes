#!/usr/bin/env python3
"""Build the repository self-description census from the generated registry."""
from __future__ import annotations

import json
import re
from collections import Counter
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
REGISTRY = ROOT / "hermes/capability_registry.pl"
JSON_OUTPUT = ROOT / "data/research/self_description_census.json"
REPORT_OUTPUT = ROOT / "docs/research/2026-07-25-what-the-repo-knows-about-itself.md"
GENERATED_BY = "scripts/research/build_self_description_census.py"

CAPABILITY_RE = re.compile(
    r"^capability\('([^']+)', '([^']+)', '([^']+)', "
    r"\[(.*?)\], ([a-z_]+)\)\.$"
)
VERDICTS = (
    "consumed_by_check",
    "consumed_by_builder",
    "include_active",
    "deliberately_unloaded",
    "stalled_input",
    "superseded",
    "undetermined",
)

# This is the task-128 starting set. The builder checks every name against the
# current registry, then records the class assigned by the current extractor.
BASELINE_UNCLASSIFIED = tuple(
    """
accommodation_witness
action_cluster_witness
algebra_claim_witness
arithmetic_property_witness
batch_event_score
benny_demo
calculus_claim_witness
check_math_claim
commitment_match
corpus_grammar_summary
counting_claim_witness
critique_bad_infinite
decimal_claim_witness
defeasible_classify
discourse_features
discourse_pragmatics
domain_context_witness
elaborations
embodied_proof_witness
event_score
executable_practice_witness
fsm_engine_witness
gesture_alignment
godel_primes_witness
ground
grounded_arith_witness
grounding_for
grounding_inference_witness
grounding_metaphor_witness
grounding_metaphors
image_schema
incoherent_witness
index_topic_subtraction
inferential_strength
integer_signed_claim_witness
intersubjective_material_witness
lesson_deformation_chart
lesson_misconception_incompatibility_witness
list_standards
list_strategies
lit_search
magnitude_equivalence_claim_witness
material_inference_witness
media_alignment
metaphor_break_witness
modal_context_witness
mua_coherence_witness
mua_kind_coherence_witness
multiplication_division_claim_witness
normative_crisis_witness
number_theory_self_defeat_witness
orr_entry_witness
pair_candidate_witness
pair_graph
pair_score
practice_vocabulary_witness
primitive_for_practice
productive_deformation_witness
ratio_proportion_claim_witness
rhythm_transition_witness
robinson_axiom_witness
semantic_material_witness
state_labels
strategy_recognize
strategy_trace
target_inferential_strength_witness
trace_adjudication
unit_coordination_svg
unit_coordination_witness
unit_echo_render
viability_witness
whole_number_addsub_claim_witness
whole_number_claim_witness
curriculum/im/generated/vision_lesson_digest.pl
curriculum/im/im_glossary.pl
curriculum/im_harness.pl
knowledge/discourse/commitment_automata.pl
""".strip().splitlines()
)


@dataclass(frozen=True)
class Capability:
    name: str
    module: str
    capability_class: str
    status: str


def evidence(path: str, locator: str, relation: str) -> dict[str, str]:
    return {"path": path, "locator": locator, "relation": relation}


def source_evidence(path: str) -> dict[str, str]:
    text = (ROOT / path).read_text(encoding="utf-8", errors="replace")
    locator = next((line.strip() for line in text.splitlines() if line.strip()), "")
    if not locator:
        raise ValueError(f"orphan source is empty: {path}")
    return evidence(path, locator, "source inspected")


def parse_registry() -> list[Capability]:
    rows: list[Capability] = []
    for line in REGISTRY.read_text(encoding="utf-8").splitlines():
        match = CAPABILITY_RE.match(line)
        if match:
            rows.append(
                Capability(
                    name=match.group(1),
                    module=match.group(2),
                    capability_class=match.group(3),
                    status=match.group(5),
                )
            )
    if not rows:
        raise ValueError("no capability rows parsed from the registry")
    names = [row.name for row in rows]
    duplicates = sorted(name for name, count in Counter(names).items() if count > 1)
    if duplicates:
        raise ValueError(f"duplicate capability names: {duplicates}")
    return rows


def finding(
    path: str,
    verdict: str,
    note: str,
    *support: dict[str, str],
) -> dict[str, object]:
    if verdict not in VERDICTS:
        raise ValueError(f"unknown verdict for {path}: {verdict}")
    return {
        "path": path,
        "verdict": verdict,
        "note": note,
        "evidence": [source_evidence(path), *support],
    }


def orphan_findings(orphan_rows: list[Capability]) -> list[dict[str, object]]:
    rows = {
        row.name: finding(
            row.name,
            "undetermined",
            "No scripts/checks loader, scripts/research reader, include directive, "
            "explicit supersession record, or applicable unload constraint was found. "
            "The source was inspected without assigning a stronger verdict.",
        )
        for row in orphan_rows
    }

    def set_finding(
        path: str,
        verdict: str,
        note: str,
        *support: dict[str, str],
    ) -> None:
        if path not in rows:
            raise ValueError(f"finding names a non-orphan row: {path}")
        rows[path] = finding(path, verdict, note, *support)

    set_finding(
        "curriculum/im/generated/vision_lesson_digest.pl",
        "consumed_by_builder",
        "The IM coverage builder loads the digest and reads its lesson facts.",
        evidence(
            "scripts/research/build_im_coverage.py",
            "use_module(lessons('im/generated/vision_lesson_digest'))",
            "builder loader",
        ),
    )
    set_finding(
        "knowledge/strategies/automaton_input_contracts.pl",
        "consumed_by_builder",
        "The transition-table builder reads the checked input contracts.",
        evidence(
            "scripts/research/build_transition_tables.py",
            'CONTRACTS = ROOT / "knowledge/strategies/automaton_input_contracts.pl"',
            "builder input",
        ),
    )

    set_finding(
        "hermes/quantity_claim.pl",
        "consumed_by_check",
        "The quantity_claim check adjudicates single claims and expression trees "
        "against this module; the quantity binding probe reads it as well.",
        evidence(
            "scripts/checks/quantity_claim_check.py",
            "quantity_claim:check_quantity_claim({claim}, D)",
            "check input",
        ),
    )
    set_finding(
        "knowledge/crosswalk/vocabulary_licenses.pl",
        "consumed_by_check",
        "The vocabulary_licenses check reads the source table directly.",
        evidence(
            "scripts/checks/vocabulary_licenses.py",
            'MODULE_PATH = ROOT / "knowledge/crosswalk/vocabulary_licenses.pl"',
            "check input",
        ),
    )
    set_finding(
        "knowledge/discourse/commitment_automata.pl",
        "consumed_by_check",
        "The action_grammar check reads the discourse automata.",
        evidence(
            "scripts/checks/action_grammar.py",
            'DISCOURSE = ROOT / "knowledge/discourse/commitment_automata.pl"',
            "check input",
        ),
    )
    set_finding(
        "knowledge/strategies/action_grammar.pl",
        "consumed_by_check",
        "The action_grammar check reads the generated grammar and compares a rebuild.",
        evidence(
            "scripts/checks/action_grammar.py",
            'GRAMMAR = ROOT / "knowledge/strategies/action_grammar.pl"',
            "check input",
        ),
    )
    set_finding(
        "hermes/web/prolog/zeeman_bifurcation.pl",
        "consumed_by_check",
        "The zeeman_bifurcation check invokes the cross-verifier, which loads this module.",
        evidence(
            "scripts/checks/zeeman_bifurcation.sh",
            '"$repo/hermes/web/bifurcation_verify.py" --cross-check',
            "named check",
        ),
        evidence(
            "hermes/web/bifurcation_verify.py",
            '"use_module(zeeman(zeeman_bifurcation)),"',
            "check loader",
        ),
    )
    set_finding(
        "hermes/web/prolog/zeeman_machine.pl",
        "consumed_by_check",
        "The zeeman_bifurcation check loads this physics core through the bifurcation module.",
        evidence(
            "scripts/checks/zeeman_bifurcation.sh",
            '"$repo/hermes/web/bifurcation_verify.py" --cross-check',
            "named check",
        ),
        evidence(
            "hermes/web/prolog/zeeman_bifurcation.pl",
            ":- use_module(zeeman(zeeman_machine)).",
            "check dependency",
        ),
    )

    include_rows = {
        "formal/formalization/axioms_geometry.pl": (
            "formal/sequent/sequent_engine.pl",
            ":- include(formalization(axioms_geometry)).",
        ),
        "formal/formalization/axioms_number_theory.pl": (
            "formal/sequent/sequent_engine.pl",
            ":- include(formalization(axioms_number_theory)).",
        ),
        "formal/formalization/axioms_robinson.pl": (
            "formal/sequent/sequent_engine.pl",
            ":- include(formalization(axioms_robinson)).",
        ),
        "formal/learner/axioms_domains.pl": (
            "formal/sequent/sequent_engine.pl",
            ":- include(learner(axioms_domains)).",
        ),
        "formal/pml/rhythm_axioms.pl": (
            "formal/sequent/sequent_engine.pl",
            ":- include(pml(rhythm_axioms)).",
        ),
        "knowledge/misconceptions/literature_canonical_mappings.pl": (
            "knowledge/misconceptions/literature_vocabulary.pl",
            ":- include('literature_canonical_mappings.pl').",
        ),
    }
    for family in (
        "addition",
        "algebraic",
        "calculus",
        "counting",
        "decimal",
        "division",
        "fraction",
        "geometry",
        "integer",
        "measurement",
        "multiplication",
        "probability",
        "ratio",
        "statistics",
        "subtraction",
    ):
        include_rows[f"knowledge/strategies/transition_tables/{family}.pl"] = (
            "hermes/strategy_recognizer.pl",
            f":- include('../knowledge/strategies/transition_tables/{family}.pl').",
        )
    for path, (includer, locator) in include_rows.items():
        set_finding(
            path,
            "include_active",
            f"{includer} includes this source rather than importing it as a module.",
            evidence(includer, locator, "include directive"),
        )

    set_finding(
        "knowledge/geometry/geometry_bridge.pl",
        "deliberately_unloaded",
        "The geometry gate excludes this bridge from the normal source set and loads it "
        "separately as a comparison point.",
        evidence(
            "scripts/checks/geometry_load.sh",
            "/knowledge/geometry/geometry_bridge.pl",
            "comparison constraint",
        ),
    )
    set_finding(
        "formal/learner/server.pl",
        "deliberately_unloaded",
        "This is a separate HTTP server entry point with a port-binding start predicate. "
        "It stays outside the worker load closure.",
        evidence(
            "formal/learner/server.pl",
            "http_server(http_dispatch, [port(Port)])",
            "port-binding entry point",
        ),
    )
    set_finding(
        "formal/learner/server_visualization.pl",
        "deliberately_unloaded",
        "This server companion registers HTTP handlers at load time. Loading it into the "
        "worker would mutate the global HTTP route table.",
        evidence(
            "formal/learner/server_visualization.pl",
            ":- http_handler(root(api/cgi_dispatch), handle_cgi_dispatch, []).",
            "load-time HTTP registration",
        ),
    )
    set_finding(
        "formal/learner/reorg_demo_server.pl",
        "deliberately_unloaded",
        "This fourth server-side case owns HTTP handlers and a port-binding demo entry "
        "point. It stays outside the worker load closure.",
        evidence(
            "formal/learner/reorg_demo_server.pl",
            "http_server(http_dispatch, [port(Port)])",
            "port-binding demo entry point",
        ),
    )

    set_finding(
        "curriculum/im/im_glossary.pl",
        "stalled_input",
        "No code reader was found. The file holds attributed K-8 glossary terms and "
        "lesson joins as generated facts.",
        evidence(
            "curriculum/im/im_glossary.pl",
            "Illustrative Mathematics K-8 glossary terms as facts.",
            "authored data description",
        ),
    )
    set_finding(
        "formal/juncture/differance_juncture.pl",
        "stalled_input",
        "No code reader was found. The file holds authored derivation and juncture facts.",
        evidence(
            "formal/juncture/differance_juncture.pl",
            "derivation(half, outcome(equal_parts(2)),",
            "authored fact",
        ),
    )
    set_finding(
        "formal/learner/atlas/basis_transitions.pl",
        "stalled_input",
        "The curriculum atlas builder writes this generated fact table, but no code reader "
        "was found for the checked-in table.",
        evidence(
            "scripts/curriculum/mini_atlas.pl",
            "generated_module('learner/atlas/basis_transitions.pl').",
            "table producer",
        ),
        evidence(
            "formal/learner/atlas/basis_transitions.pl",
            "basis_transition(",
            "generated data",
        ),
    )

    specific_undetermined = {
        "curriculum/im_harness.pl": (
            "The source names curriculum/tests/test_im_harness.pl, but that path does not "
            "exist. No consumer in an allowed verdict category was found."
        ),
        "formal/formalization/synthesis/run_add.pl": (
            "This is a manual command entry point. No check or research builder invokes it."
        ),
        "formal/formalization/synthesis/run_lazy.pl": (
            "This is a manual command entry point. No check or research builder invokes it."
        ),
        "formal/formalization/synthesis/run_synth.pl": (
            "This is a manual command entry point. No check or research builder invokes it."
        ),
        "formal/formalization/synthesis/synth.pl": (
            "Only the unconsumed run_synth.pl entry point imports this module. No stronger "
            "verdict is supported."
        ),
        "formal/formalization/synthesis/synth_lazy.pl": (
            "Only the unconsumed run_add.pl and run_lazy.pl entry points import this module. "
            "No stronger verdict is supported."
        ),
        "formal/learner/activity_contract.pl": (
            "task_transition.pl and scripts/curriculum/mini_atlas.pl load this module, but "
            "neither is a scripts/checks or scripts/research consumer."
        ),
        "formal/learner/crisis_processor.pl": (
            "Only the deliberately unloaded learner server stack imports this module."
        ),
        "formal/learner/curriculum_processor.pl": (
            "Only the deliberately unloaded learner server stack and its crisis processor "
            "import this module."
        ),
        "formal/learner/interactive_ui.pl": (
            "This is a manual command-line interface. No check, research builder, include "
            "directive, or supersession record was found."
        ),
        "formal/learner/knowledge_manager.pl": (
            "Only the deliberately unloaded learner server stack imports this module."
        ),
        "formal/learner/learned_knowledge_v2.pl": (
            "Only the deliberately unloaded learner server stack loads these generated "
            "proof-strategy facts."
        ),
        "formal/learner/main.pl": (
            "This is a manual command entry point. It loads primordial_start.pl, but no "
            "check or research builder invokes it."
        ),
        "formal/learner/primordial_start.pl": (
            "Only the unconsumed learner main entry point loads this bootstrap script."
        ),
        "formal/learner/task_transition.pl": (
            "scripts/curriculum/mini_atlas.pl loads this module, but that producer is not "
            "one of the consumer categories in the verdict table."
        ),
        "formal/pml/audit_connectors.pl": (
            "This source describes a strict audit entry point, but run_all.sh and the "
            "scripts/checks directory do not invoke it."
        ),
        "formal/pml/mua_conjectures.pl": (
            "The register is intentionally empty. It holds no authored relation row to "
            "classify as stalled input, and no consumer was found."
        ),
        "formal/pml/mua_health.pl": (
            "Only the unconsumed audit_connectors.pl module imports this health query."
        ),
        "formal/pml/talkmoves_adapter.pl": (
            "No check, research builder, include directive, or explicit supersession "
            "record was found for this packet-review adapter."
        ),
        "hermes/web/prolog/zeeman_tape.pl": (
            "This module imports the checked Zeeman machine, but no check or builder "
            "consumes the tape itself."
        ),
        "hermes/web/prolog/zeeman_pml_bridge.pl": (
            "The source explicitly calls itself opt-in and records that canonical loaders "
            "do not load it. Opt-in status is not one of the specified positive verdicts."
        ),
        "knowledge/crosswalk/merge_evidence.pl": (
            "The file describes a merge gate that is absent from scripts/. It contains no "
            "active merge_evidence row, so stalled_input and superseded are unsupported."
        ),
        "knowledge/strategies/math_benchmark.pl": (
            "This is a manual command-line benchmark. No check or research builder invokes it."
        ),
    }
    for path, note in specific_undetermined.items():
        set_finding(path, "undetermined", note)

    return [rows[path] for path in sorted(rows)]


UNROUTED = {
    "check_math_claim": {
        "does": "Checks a safely parsed typed mathematical claim and returns a verdict record.",
        "judgement": "Being unrouted from a web page is correct.",
        "reason": "The MCP server exposes it as a tool, and research scripts call the checker. "
        "A page route is not required for those consumers.",
        "evidence": [
            evidence(
                "hermes/mcp/server.py",
                '("check_math_claim", "Parse and check an explicit mathematical claim',
                "MCP exposure",
            )
        ],
    },
    "check_solution_steps": {
        "does": "Adjudicates the explicit arithmetic of a numbered solution, step by step, "
        "and names the first refuted step or reports that none was refuted.",
        "judgement": "Being unrouted from a web page is correct, for now.",
        "reason": "Its consumer is the MathTutorBench measurement path, which calls the "
        "worker directly. A tutor-facing page would want the narrated trace rather than "
        "the step table, and no such page has been designed.",
        "evidence": [
            evidence(
                "hermes/dispatch_spec.pl",
                "dispatch_spec(check_solution_steps,",
                "worker dispatch",
            ),
            evidence(
                "hermes/math_claim_language.pl",
                "Conservative natural-language reader for mathematical claims",
                "the DCG that reads its steps",
            ),
        ],
    },
    "pedagogical_questions": {
        "does": "Finds the authored monitoring clusters for a topic, automaton state, or "
        "standard, and returns their assessing and advancing questions with the "
        "productive core and deformation that license them.",
        "judgement": "A page should route to it.",
        "reason": "126 assessing and 85 advancing questions were reachable only through a "
        "lesson code before this operation, so a teacher who knew the mathematics but not "
        "the IM code could not reach them. A page could now ask from the mathematics.",
        "evidence": [
            evidence(
                "curriculum/im/lesson_monitoring.pl",
                "pedagogical_question_clusters",
                "cluster lookup",
            ),
            evidence(
                "hermes/dispatch_spec.pl",
                "dispatch_spec(pedagogical_questions,",
                "worker dispatch",
            ),
        ],
    },
    "index_topic_subtraction": {
        "does": "Returns counts and evidence samples after topic exclusions remove index rows.",
        "judgement": "A page should route to it.",
        "reason": "The module states that the index is reachable from the running application, "
        "but the dispatch operation has no web route or MCP exposure.",
        "evidence": [
            evidence(
                "knowledge/index/index_query.pl",
                "index is reachable from the running application",
                "runtime intent",
            ),
            evidence(
                "hermes/dispatch_spec.pl",
                "dispatch_spec(index_topic_subtraction,",
                "worker dispatch",
            ),
        ],
    },
    "state_labels": {
        "does": "Returns the default cited state label and its recorded alternatives.",
        "judgement": "A page should route to it.",
        "reason": "The operation has no web or MCP consumer. A strategy or Atlas page can use "
        "the same cited vocabulary that the worker already returns.",
        "evidence": [
            evidence(
                "hermes/dispatch_spec.pl",
                "dispatch_spec(state_labels,",
                "worker dispatch",
            ),
            evidence(
                "knowledge/strategies/math/state_vocabulary.pl",
                "state_display_label",
                "label source",
            ),
        ],
    },
    "strategy_recognize": {
        "does": "Returns evidence-bearing candidate strategy traces for classroom language.",
        "judgement": "Being unrouted from a web page is correct.",
        "reason": "The MCP server exposes it as a tool. The lack of a page route does not make "
        "the operation unreachable to its current consumer.",
        "evidence": [
            evidence(
                "hermes/mcp/server.py",
                '"strategy_recognize": "strategy_recognize"',
                "MCP exposure",
            )
        ],
    },
}


def evidence_text(items: list[dict[str, str]]) -> str:
    return "<br>".join(
        f"`{item['path']}` ({item['relation']})" for item in items
    )


def render_report(data: dict[str, object]) -> str:
    status_counts = data["counts"]["by_status"]
    class_counts = data["counts"]["by_class"]
    verdict_counts = data["counts"]["orphan_verdicts"]
    resolved_counts = data["counts"]["baseline_class_resolution"]

    lines = [
        "# What the repository records about itself",
        "",
        f"Generated by `{GENERATED_BY}`. Do not hand-edit.",
        "",
        "## Scope and limits",
        "",
        "This census reads the generated capability registry and names evidence in the "
        "current tree. An orphan verdict describes consumption evidence, not code quality. "
        "A row remains `undetermined` when the specified verdicts do not fit the available "
        "evidence.",
        "",
        f"The registry contains {data['counts']['total']} rows. The reachability counts "
        "below are generated from the current tree. Class assignment changes because the "
        "extractor now uses an operation's defining module directory when no operation-name "
        "rule applies.",
        "",
        "## Registry counts",
        "",
        "### By reachability status",
        "",
        "| status | count |",
        "|---|---:|",
    ]
    lines.extend(f"| `{name}` | {count} |" for name, count in status_counts.items())
    lines.extend(
        [
            "",
            "### By capability class",
            "",
            "| class | count |",
            "|---|---:|",
        ]
    )
    lines.extend(f"| `{name}` | {count} |" for name, count in class_counts.items())
    lines.extend(
        [
            "",
            "## Orphan-module census",
            "",
            "| verdict | count |",
            "|---|---:|",
        ]
    )
    lines.extend(f"| `{name}` | {verdict_counts[name]} |" for name in VERDICTS)
    lines.extend(
        [
            "",
            "| path | verdict | named evidence | note |",
            "|---|---|---|---|",
        ]
    )
    for row in data["orphan_modules"]:
        lines.append(
            f"| `{row['path']}` | `{row['verdict']}` | "
            f"{evidence_text(row['evidence'])} | {row['note']} |"
        )

    lines.extend(
        [
            "",
            "No row is classified as `superseded`. The tree does not contain a direct "
            "movement record for any orphan source.",
            "",
            "The fourth server-side unload case is "
            "`formal/learner/reorg_demo_server.pl`. It owns HTTP handlers and a "
            "port-binding demo entry point, so it stays outside the worker closure.",
            "",
            "## Class resolution",
            "",
            "The task baseline contains 77 unclassified registry rows. The current "
            "extractor assigns 76 of them to existing classes. One row remains "
            "unclassified pending a class decision.",
            "",
            "| current class | rows from the 77-row baseline |",
            "|---|---:|",
        ]
    )
    lines.extend(
        f"| `{name}` | {count} |" for name, count in resolved_counts.items()
    )
    lines.extend(
        [
            "",
            "| baseline row | current class | resolution |",
            "|---|---|---|",
        ]
    )
    for row in data["class_resolution"]:
        lines.append(
            f"| `{row['name']}` | `{row['current_class']}` | {row['resolution']} |"
        )
    lines.extend(
        [
            "",
            "### Proposed class",
            "",
            "`indexing` is proposed for one registry row: `index_topic_subtraction`. "
            "`knowledge/index/index_query.pl` queries the generated "
            "`corpus_window.pl` and `relevance_negation.pl` tables. None of the existing "
            "classes names index construction, exclusion data, or subtraction queries.",
            "",
            "The brief refers to those three index files as three of the 77. The registry "
            "creates rows for dispatched operations and for shipped modules outside the "
            "worker closure. In the current tree, only `index_topic_subtraction` is a "
            "registry row. The two generated files load under `index_query.pl`, so this "
            "census counts one row and records all three files as class evidence.",
            "",
            "## Unrouted operations",
            "",
            "| operation | what it does | judgement | reason |",
            "|---|---|---|---|",
        ]
    )
    for row in data["unrouted"]:
        lines.append(
            f"| `{row['name']}` | {row['does']} | {row['judgement']} | {row['reason']} |"
        )
    lines.extend(
        [
            "",
            "## Findings that remain open",
            "",
            "Several manual entry points and the older learner server dependency chain do "
            "not fit the required positive verdicts. They remain `undetermined`; the "
            "census does not infer supersession from age or naming.",
            "",
            "`curriculum/im_harness.pl` names "
            "`curriculum/tests/test_im_harness.pl`, but that test path is absent. "
            "`knowledge/crosswalk/merge_evidence.pl` names a merge-gate script that is "
            "also absent. These dead references support neither consumption nor "
            "supersession.",
            "",
        ]
    )
    return "\n".join(lines)


def build() -> dict[str, object]:
    registry_rows = parse_registry()
    by_name = {row.name: row for row in registry_rows}
    missing_baseline = sorted(set(BASELINE_UNCLASSIFIED) - set(by_name))
    if missing_baseline:
        raise ValueError(f"baseline unclassified rows absent from registry: {missing_baseline}")
    if len(BASELINE_UNCLASSIFIED) != 77:
        raise ValueError(
            f"baseline unclassified set has {len(BASELINE_UNCLASSIFIED)} rows, expected 77"
        )

    orphan_rows = [row for row in registry_rows if row.status == "orphan_module"]
    findings = orphan_findings(orphan_rows)
    findings_by_path = {row["path"]: row for row in findings}
    if set(findings_by_path) != {row.name for row in orphan_rows}:
        raise ValueError("orphan findings do not match the registry orphan set")

    orphan_records = []
    for row in orphan_rows:
        record = dict(findings_by_path[row.name])
        record.update({"module": row.module, "capability_class": row.capability_class})
        orphan_records.append(record)

    class_resolution = []
    for name in BASELINE_UNCLASSIFIED:
        row = by_name[name]
        if row.capability_class == "unclassified":
            resolution = "proposed `indexing` class; no code class added"
        else:
            resolution = "assigned to an existing class by extractor rules"
        class_resolution.append(
            {
                "name": name,
                "current_class": row.capability_class,
                "resolution": resolution,
            }
        )

    unrouted_rows = [row for row in registry_rows if row.status == "unrouted"]
    if set(UNROUTED) != {row.name for row in unrouted_rows}:
        raise ValueError("unrouted judgements do not match the registry")
    unrouted = []
    for row in unrouted_rows:
        item = {"name": row.name, **UNROUTED[row.name]}
        unrouted.append(item)

    status_counts = Counter(row.status for row in registry_rows)
    class_counts = Counter(row.capability_class for row in registry_rows)
    verdict_counts = Counter(row["verdict"] for row in orphan_records)
    resolution_counts = Counter(row["current_class"] for row in class_resolution)

    if len(registry_rows) != 269:
        raise ValueError(f"registry has {len(registry_rows)} rows, task baseline has 269")
    if len(orphan_records) != 59:
        raise ValueError(f"registry has {len(orphan_records)} orphan rows, task baseline has 59")
    if len(unrouted) != 6:
        raise ValueError(f"registry has {len(unrouted)} unrouted rows, task baseline has 6")

    return {
        "schema": "self_description_census_v1",
        "generated_by": GENERATED_BY,
        "registry": "hermes/capability_registry.pl",
        "counts": {
            "total": len(registry_rows),
            "by_status": dict(sorted(status_counts.items())),
            "by_class": dict(sorted(class_counts.items())),
            "orphan_verdicts": {
                verdict: verdict_counts.get(verdict, 0) for verdict in VERDICTS
            },
            "baseline_unclassified": len(BASELINE_UNCLASSIFIED),
            "baseline_class_resolution": dict(sorted(resolution_counts.items())),
            "unrouted": len(unrouted),
        },
        "orphan_modules": orphan_records,
        "class_resolution": class_resolution,
        "proposed_classes": [
            {
                "name": "indexing",
                "count": 1,
                "rows": ["index_topic_subtraction"],
                "evidence": [
                    evidence(
                        "knowledge/index/index_query.pl",
                        ":- ensure_loaded(index('corpus_window')).",
                        "query module",
                    ),
                    evidence(
                        "knowledge/index/corpus_window.pl",
                        "window_row(",
                        "generated index data",
                    ),
                    evidence(
                        "knowledge/index/relevance_negation.pl",
                        "known_topic(",
                        "generated exclusion data",
                    ),
                ],
            }
        ],
        "unrouted": unrouted,
    }


def main() -> int:
    data = build()
    JSON_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    REPORT_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    JSON_OUTPUT.write_text(
        json.dumps(data, indent=2, sort_keys=True, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    REPORT_OUTPUT.write_text(render_report(data), encoding="utf-8")
    print(
        f"wrote {JSON_OUTPUT.relative_to(ROOT)} and {REPORT_OUTPUT.relative_to(ROOT)}: "
        f"{len(data['orphan_modules'])} orphan rows"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
