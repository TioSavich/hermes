#!/usr/bin/env python3
"""Assert the approved method/path/module registry and duplicate guard."""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from hermes.app.routes.registry import DuplicateRouteError, Route, Router, build_router  # noqa: E402

EXPECTED_TEXT = """
GET / static
GET /lesson static
GET /api/quickstart static
GET /api/sample static
GET /api/inputs static
GET /api/fraction/render static
GET /api/fraction/compare static
GET /api/models runtime
POST /api/input runtime
POST /api/results/list runtime
POST /api/results/get runtime
GET /api/knowledge analysis
GET /api/visualize/coordination analysis
GET /api/unit_coordination.svg analysis
GET /api/reorganize analysis
POST /api/compute analysis
POST /api/learner/reset analysis
POST /api/analyze analysis
POST /api/event_score analysis
POST /api/pair_graph analysis
POST /api/pair_candidate analysis
GET /api/preflight llm
POST /api/preflight llm
POST /api/set_key llm
POST /api/chat llm
POST /api/help llm
POST /api/transcript_report llm
POST /api/media_transcribe llm
POST /api/pml_score llm
POST /api/misconception_search misconception_search
GET /api/lesson_visual monitoring
POST /api/field_context monitoring
POST /api/monitoring_chart_export monitoring
POST /api/lesson_dossier monitoring
POST /api/ranked_figures monitoring
POST /api/monitoring_visuals monitoring
POST /api/lesson_arithmetic_demonstration monitoring
POST /api/field_connectivity_audit monitoring
POST /api/render_coverage monitoring
GET /api/capabilities worker
GET /api/base worker
GET /api/diagnostics worker
POST /api/base worker
POST /api/render worker
POST /api/inferential_strength worker
POST /api/strategies worker
POST /api/strategy_trace worker
POST /api/input_contract worker
POST /api/deontic_scorecard worker
POST /api/crisis worker
POST /api/deontic_consequences worker
POST /api/deontic_up_level worker
POST /api/deontic_requires_entitlement worker
POST /api/sequent_proof worker
POST /api/misconceptions worker
POST /api/standards worker
POST /api/grounding worker
POST /api/geometry worker
POST /api/canonical_contract worker
POST /api/canonical_check worker
POST /api/diagnose_error worker
POST /api/query_misconception worker
POST /api/literature worker
POST /api/notation_render worker
POST /api/fraction_cgi_addition worker
POST /api/lesson_deformation_chart worker
POST /api/notation_monitoring_chart worker
POST /api/brandom_backstop worker
POST /api/brandomian_check worker
POST /api/hyperedges worker
POST /api/axiom_toggle worker
POST /api/carving_strategy_proof worker
POST /api/carving_operation_summary worker
POST /api/balance_solve worker
POST /api/benny_demo worker
POST /api/pedagogical_questions worker
POST /api/guide_question_labels worker
POST /api/index_topic_subtraction worker
POST /api/state_labels worker
POST /api/discourse_features worker
POST /api/discourse_pragmatics worker
POST /api/gesture_alignment worker
POST /api/trace_adjudication worker
POST /api/witness/crosswalk_claim worker
POST /api/witness/geometry worker
POST /api/witness/standards worker
POST /api/witness/formal worker
POST /api/witness/pml worker
POST /api/witness/grounding worker
POST /api/witness/misconception worker
POST /api/parse workflow
POST /api/content workflow
POST /api/profile workflow
POST /api/draft workflow
POST /api/grade workflow
POST /api/score workflow
POST /api/metrics workflow
POST /api/work_read workflow
POST /api/work_refine workflow
GET /api/sidekick/status sidekick
POST /api/sidekick_chat sidekick
"""
EXPECTED = tuple(tuple(line.split()) for line in EXPECTED_TEXT.splitlines() if line.strip())


def noop(_context: object) -> None:
    return


def main() -> int:
    router = build_router()
    actual = tuple((route.method, route.path, route.module) for route in router.routes)
    if actual != EXPECTED:
        print("route registry mismatch", file=sys.stderr)
        print("expected:", *EXPECTED, sep="\n", file=sys.stderr)
        print("actual:", *actual, sep="\n", file=sys.stderr)
        return 1
    duplicate = Route("GET", "/api/preflight", noop)
    try:
        Router((*router.routes, duplicate), noop)
    except DuplicateRouteError:
        print(f"route registry: {len(actual)} exact routes; duplicate rejection: PASS")
        return 0
    print("duplicate route was accepted", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
