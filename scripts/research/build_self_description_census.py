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
        "curriculum/im/generated/compiled_receipt_routes.pl",
        "consumed_by_builder",
        "The evidence ledger reads its route and defect facts to decide "
        "whether a receipt licenses structured_negative, and the PUSU runner "
        "loads it for the receipt contrast lane.",
        evidence(
            "scripts/curriculum/build_lesson_evidence.py",
            "COMPILED_RECEIPT_ROUTES",
            "ledger licensing reader",
        ),
        evidence(
            "scripts/curriculum/pusu_pass.py",
            "compiled_receipt_routes",
            "runner contrast lane",
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
            "generated_module('formal/learner/atlas/basis_transitions.pl').",
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
    "standards_progression_candidates": {
        "does": "Returns the candidate building_on-to-addressing progression "
        "rows touching a standards code, from the lesson-mediated overlay, "
        "each carrying its spine provenance and the learner_reachability "
        "false boundary.",
        "judgement": "Being unrouted from a web page is correct.",
        "reason": "The overlay holds candidates, not licensed prerequisites. "
        "Its consumers are the stage-2 normalizer and analysis clients "
        "through the worker; a web form would invite readers to treat "
        "candidate edges as a learning order before any reviewed promotion.",
        "evidence": [
            evidence(
                "hermes/dispatch_spec.pl",
                "dispatch_spec(standards_progression_candidates,",
                "worker dispatch",
            ),
            evidence(
                "knowledge/index/standards_progression_overlay.pl",
                "learner_reachability",
                "the candidate boundary",
            ),
        ],
    },
    "abduce_error": {
        "does": "Runs the closed misconception-rule registry on a caller's ground input "
        "and returns the rules that reproduce the supplied result, with recorded db_row citations.",
        "judgement": "Being unrouted from a web page is correct.",
        "reason": "The questionnaire runner and other analysis clients reach it through "
        "the MCP core. Its results are cited candidates rather than learner diagnoses, "
        "so adding a standalone web form would not add a licensed interpretation.",
        "evidence": [
            evidence(
                "hermes/mcp/server.py",
                '("abduce_error", "Run the closed registry of arithmetic misconception rules',
                "MCP exposure",
            ),
            evidence(
                "hermes_worker.pl",
                "dispatch_request(abduce_error, Id, Request, Response)",
                "worker dispatch",
            ),
        ],
    },
    "prolog_query": {
        "does": "Runs one caller-supplied Prolog goal against the loaded "
        "knowledge base and returns its bindings, after SWI's sandbox accepts "
        "the goal's whole call graph.",
        "judgement": "Being unrouted from a web page is correct, and a page "
        "would be the wrong shape for it.",
        "reason": "Every other operation is a question shaped in advance with "
        "fixed argument slots; 202 of them stand against 81,663 clauses. This "
        "one lets a caller ask something nobody wrote an operation for. Its "
        "consumer is a program composing a goal, not a person filling a form, "
        "and a page would have to invent an input widget for arbitrary Prolog.",
        "evidence": [
            evidence(
                "hermes/prolog_query.pl",
                "Bounded read-only queries over loaded knowledge predicates",
                "the module that runs and bounds the goal",
            ),
            evidence(
                "hermes/mcp/server.py",
                '("prolog_query"',
                "MCP exposure",
            ),
        ],
    },
    "lesson_enactment_list": {
        "does": "Lists every lesson an enactment lane can perform, the distinct forms "
        "declared for each, and every named refusal with the machine it would need.",
        "judgement": "Being unrouted from a web page is correct.",
        "reason": "It is a discovery listing for a caller choosing what to run next, and "
        "its consumers are the MCP surface and the census builder. The console reaches an "
        "enactment through the strategy-trace display it already serves, so a page that "
        "listed the inventory would show what no page asks for.",
        "evidence": [
            evidence(
                "hermes/mcp/server.py",
                '("lesson_enactment_list", "List every lesson with an executable enactment',
                "MCP exposure",
            )
        ],
    },
    "lesson_enactment_run": {
        "does": "Runs one lesson's enactment and serializes every distinct form it "
        "produces, keeping the verdict, the input provenance, and the sentence naming "
        "what the row does not claim.",
        "judgement": "Being unrouted from a web page is correct.",
        "reason": "The serializer fills the dict shape strategy_trace_dict/3 returns, so "
        "an enactment already reaches every consumer a strategy trace reaches. A second "
        "route would duplicate a display path rather than add one.",
        "evidence": [
            evidence(
                "curriculum/im/lesson_enactment.pl",
                "The one serializer. It fills the dict shape `strategy_trace_dict/3` returns,",
                "the shared response shape that makes a page route unnecessary",
            ),
            evidence(
                "hermes/mcp/server.py",
                '("lesson_enactment_run"',
                "MCP exposure",
            ),
        ],
    },
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
    "incompatibility_contexts": {
        "does": "Returns the reviewed a-fortiori context-nesting inventory, optionally "
        "filtered to nestings that touch one named context.",
        "judgement": "Being unrouted from a web page is correct.",
        "reason": "The MCP server exposes it for research callers, and the entailment "
        "page presents the same inventory from its generated register rather than a "
        "live route.",
        "evidence": [
            evidence(
                "hermes/mcp/server.py",
                '"incompatibility_contexts": "incompatibility_contexts"',
                "MCP exposure",
            )
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

    # 269 until 2026-07-27, when knowledge/index/coverage_absence_registry.pl
    # added the 270th. It is counted because it declares a module and exports
    # query predicates; knowledge/index/relevance_negation.pl, a generated
    # index beside it, is a bare fact file and so is not a capability. The row
    # is orphan_module and unclassified, which is accurate: the relation is
    # queryable from Prolog and no worker op routes to it yet.
    #
    # knowledge/index/im_lesson_identity.pl is the 271st and
    # knowledge/index/task_span_absence_registry.pl the 272nd, on the same
    # grounds. The lesson-identity index landed in 7ce0a20 without a registry
    # regeneration, so this baseline and hermes/capability_registry.pl both
    # described a tree that no longer existed and the gate was red from that
    # commit until 2026-07-27. Regenerating the registry is what a new module
    # under knowledge/ costs.
    # knowledge/index/research_measurement_registry.pl is the 273rd, on the same
    # grounds. It indexes what the reports claim and which of those claims join
    # to a method that still runs here.
    # knowledge/index/data_consumption_manifest.pl is the 275th: it indexes every
    # data artifact in the checkout and the readers that open it.
    # formal/incompatibility/error_rule_inferences.pl is the 277th: the generated
    # error-rule material inferences that defeasible_inference.pl includes. The
    # registry reads it as a source file with no op routing to it, which is what
    # an included clause file looks like from the outside.
    # formal/incompatibility/error_rule_incompatibility_adapter.pl is the 279th:
    # the second feeder into the canonical Brandomian relation, reachable only
    # lazily through axiom_toggle, which is how the registry records it.
    # knowledge/strategies/math/smr_div_remainder_cycle.pl is the 280th: the
    # division automaton that decides termination by remainder recurrence. It is
    # unregistered on purpose — registering it needs a canonical action naming a
    # halt on state recurrence, which extends a closed alphabet — so the registry
    # reads it as an orphan module, which is what it is.
    # 280 until 2026-07-29 night: incompatibility_contexts is the 281st (the
    # reviewed nesting inventory, MCP-exposed, judged unrouted above), and
    # knowledge/misconceptions/research_corpus_automaton_bindings.pl the 282nd,
    # an orphan module in the registry's own reading.
    # compiled_receipt_routes.pl is the 283rd (2026-07-29, the receipt-route
    # wiring): the register the ledger's licensing rule and the PUSU contrast
    # lane both consume.
    # monitoring_registry_bridge.pl is the 284th (2026-08-01): the two-witness
    # table joining the geometry monitoring names to the misconception registry.
    # It arrived with 5ea7876 and the registry was not regenerated then, so the
    # capability gate had been failing on main until this wave caught it up.
    # 285 through 292 (2026-08-01) are the lesson-enactment rung: the contract
    # curriculum/im/lesson_enactment.pl, the five lane modules under
    # curriculum/im/enactment/ that register into it, and the two files under
    # enactment/support/ that carry a lesson table and a figure algebra without
    # declaring a form of their own. The support pair reads as orphan modules
    # because nothing routes to them directly, which is what an included table
    # and a helper library look like from outside.
    # 294 from 2026-08-01, the two being lesson_enactment_list and
    # lesson_enactment_run. They are the first worker operations to reach the
    # enactment contract, which until now no operation reached at all.
    # 295 from 2026-08-01: prolog_query, the first operation that runs a
    # goal rather than answering a question shaped in advance.
    # 296 from late 2026-08-01: misconception_query_probes, the keyword
    # probe the diagnosis benchmark's query-forming model can call through
    # prolog_query. It reads as an orphan module because only caller-formed
    # goals reach it, never a routed operation.
    # 301 from 2026-08-03: the abstraction wing — four quarantined pilot
    # modules under knowledge/strategies/abstraction/ and the generated
    # deformation-coincidence data. All five then read as orphan modules
    # because nothing imported candidate structure.
    # 308 from 2026-08-03: seven formerly prebaked-only scene formats now
    # expose bounded live render operations through the worker.
    # 310 from the evening of 2026-08-03: machine_typology.pl (computed
    # structural classes for every transition table) and
    # machine_class_attestations.pl (module-documented class claims held
    # apart from computation). Both read as orphan modules: the compendium
    # builder consumes them by parsing, and nothing imports them.
    # 311 from 2026-08-05: deformation_validity.pl, the authored validity
    # ledger for the 232 deforming transitions (rust/blue/mixed with basis
    # and review status). Orphan module for the same reason: the graph and
    # compendium builders consume it by parsing, and nothing imports it.
    # 312 from 2026-08-06: metaphor_seam_registry.pl, the authored registry
    # of where each curricular metaphor operates and where its reach ends
    # (26 rows, 16 seams). Orphan module for the abstraction wing's reason:
    # its gate check parses it, and nothing imports it.
    # 311 from 2026-08-07: fraction_action_pairs.pl statically imports
    # kernel_gate_pilot.pl for unit_fraction_partition. The extractor records
    # dispatch operations and unreachable module rows, so a loaded helper with
    # no dispatch operation leaves the registry instead of becoming unrouted.
    # 312 from 2026-08-07: abduce_error adds the rule_builds/4 worker operation;
    # it is MCP-exposed and intentionally has no web route.
    # 313 from 2026-08-08: lesson_arithmetic_demonstration — the vertical
    # slice's lesson-bounded operation (worker + MCP + POST route).
    # 314 later the same day: standards_progression_candidates — the
    # candidate progression overlay's bounded worker query (unrouted by
    # judgement; candidates never read as a learning order).
    # 315 from 2026-08-12: compiled_defragged_task_instances — the defrag
    # artifact's generated module (orphan by design; consumers arrive in
    # later slices).
    # 324 later on 2026-08-12: the defrag consumers arrived (the worker's
    # display fallback reads the artifact, so it left the orphan set), and
    # the nine per-grade extracted guide-question modules entered
    # (grade_k..grade_8; pending review; compiled context consumes them).
    # 345 from 2026-08-13: the twenty-one quarantined pilots authored in the
    # previous commit entered the registry — fourteen g8_* modules (the
    # solvers and their shared quantity decoder), five k7_* scene emitters
    # and their common file, and the two question-mining stores. The commit
    # that authored those files shipped a registry that did not yet name
    # them, so this pin move is a repair rather than a bump: the registry
    # now describes the tree it ships with.
    # 352 from 2026-08-14: the language lane entered the registry — the
    # Webster morphology interface, the authored supplement, the demand-fit
    # math lexicon, the word-problem and APE readers, the loop-admitted
    # store, the pedagogy force funnel, and the standards router/doing
    # stores. All quarantined; the parser points at doings it never loads.
    # 361 from 2026-08-14 evening: the printed-expression reader entered the
    # registry beside the session's Big Red lanes — the lesson structure read,
    # its byte-anchoring pass, the rewrite consultation and its Prolog gate,
    # and the two anchored curriculum stores they produce. All quarantined;
    # the reader emits relations and never evaluates one.
    if len(registry_rows) != 361:
        raise ValueError(f"registry has {len(registry_rows)} rows, task baseline has 361")
    # 59 until 2026-07-27; the coverage-absence registry is the 60th orphan
    # module, the lesson-identity index the 61st, the task-span absence registry
    # the 62nd, and the research-measurement registry the 63rd, for the same
    # reason each is a capability.
    # 63 until machine_block_decomposition.pl, the 64th: a generated index
    # declaring a module, queryable from Prolog, with no worker op routing to
    # it. Same reason as the coverage-absence and lesson-identity indexes.
    # error_rule_inferences.pl is the 67th, on narrower grounds: it is an
    # included clause file rather than a module, so nothing routes to it and
    # nothing ever will. The registry has no separate reading for an include.
    # smr_div_remainder_cycle.pl is the 69th, and its orphanhood is a decision
    # rather than an oversight: it decides what its sibling smr_div_long cannot,
    # and wiring it in waits on a canonical action for halting on a state
    # recurrence. Stalled pipeline input with a named reason, never vestige.
    # research_corpus_automaton_bindings.pl is the 70th (2026-07-29): a
    # generated registry from research_shared.db with no Prolog loader yet —
    # stalled pipeline input awaiting its first reader, undetermined by default.
    # compiled_receipt_routes.pl is the 71st (2026-07-29): orphan only in the
    # worker-closure sense — its consumers are the ledger's licensing rule and
    # the PUSU runner, recorded in its finding above.
    # monitoring_registry_bridge.pl is the 72nd (2026-08-01): its own header
    # states that no lesson predicate loads it yet. Stalled pipeline input with
    # a named reason and both witnesses recorded, never vestige.
    # 73 through 80 are the whole lesson-enactment rung (2026-08-01): the
    # contract, its five lanes, and its two support files. Every one of them is
    # an orphan in the worker-closure sense, and the count is the honest record
    # of a gap rather than a bookkeeping bump.
    #
    # That entry first predicted that wiring a worker op would move these eight
    # out of this count. Later the same day lesson_enactment_list and
    # lesson_enactment_run were wired, and the eight did not move. The
    # prediction was wrong, and the reason is worth keeping. orphan_modules()
    # subtracts the worker's STATIC load closure from the shipped set, while the
    # two operations load the contract and its lanes lazily inside a predicate
    # body, because loading them eagerly costs about eleven seconds at every
    # worker boot for a rung most calls never touch. Both facts are correct at
    # once: the rung is now reachable by a request, and it is still outside the
    # closure this count measures.
    #
    # So this number does not mean "nothing can reach these files". It means
    # "these files are not statically imported by the worker". Wiring changed
    # the first and not the second. Whether the extractor should report a lazily
    # loaded module as lazy_reachable rather than orphan_module is a live
    # question, deliberately not answered here, because answering it moves
    # counts across this census and wants its own slice.
    # 81 from late 2026-08-01: misconception_query_probes joins the orphan
    # count for the same reason it joins the registry — only caller-formed
    # prolog_query goals reach it, so no static import ever will.
    # 86 from 2026-08-03: the five abstraction-wing files (four pilots and
    # the deformation-coincidence data) were orphan modules by design —
    # candidate structure that nothing imported until adopted.
    # 85 after input_contract made automaton_input_contracts.pl reachable
    # through the dispatch surface.
    # 87 from the evening of 2026-08-03: machine_typology.pl and
    # machine_class_attestations.pl join for the registry's reason —
    # the compendium builder parses them; nothing imports them.
    # 88 from 2026-08-05: deformation_validity.pl joins for the same
    # reason — the graph and compendium builders parse it; nothing
    # imports it.
    # 89 from 2026-08-06: metaphor_seam_registry.pl joins for the
    # abstraction wing's reason — its gate check parses it; nothing
    # imports it.
    # 88 from 2026-08-07: kernel_gate_pilot.pl leaves the orphan count when
    # fraction_action_pairs.pl adopts run_kernel/4 for unit_fraction_partition.
    # 89 from 2026-08-12: compiled_defragged_task_instances.pl joins as a
    # generated orphan; its consumers (training pairs, chart referents,
    # page typesetting) land in later slices.
    # 98 later on 2026-08-12: the defrag artifact LEFT the orphan set (the
    # worker's display fallback consumes it), while ten extraction modules
    # entered — grade_8_extracted_task_instances plus the nine per-grade
    # extracted guide-question files. Their consumers are the compiled
    # context (built, not loaded) and the coming question-mining slices;
    # unconsumed here means stalled pipeline input, never vestige.
    # 119 from 2026-08-13: all twenty-one new registry rows are orphan
    # modules, which is what quarantine means here. Nothing imports a pilot;
    # the mints and the scene emitters reach them by running them, never by
    # loading them into the worker. Admission by ceremony would move them.
    # 126 from 2026-08-14: the language-lane rows are orphans in the same
    # quarantine sense; the harness and router run them, nothing loads them.
    # 135 from 2026-08-14 evening: the printed-expression reader and the Big
    # Red structure and consultation lanes are orphans in the same quarantine
    # sense. The harness, the router and the slurm jobs run them; nothing
    # loads them into the worker.
    if len(orphan_records) != 135:
        raise ValueError(f"registry has {len(orphan_records)} orphan rows, task baseline has 135")
    # 10 from 2026-08-01: the two enactment operations and prolog_query
    # carry no web route. 11 from 2026-08-07: abduce_error is the additive
    # questionnaire analysis seam and is exposed through MCP, not a web form.
    # 12 from 2026-08-08: standards_progression_candidates joins the
    # unrouted set with its authored judgement (candidates never read
    # as a learning order).
    if len(unrouted) != 12:
        raise ValueError(f"registry has {len(unrouted)} unrouted rows, task baseline has 12")

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
