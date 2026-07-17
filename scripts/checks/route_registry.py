#!/usr/bin/env python3
"""Assert the approved method/path/access/module registry and duplicate guard."""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from hermes.app.routes.registry import DuplicateRouteError, Route, Router, build_router  # noqa: E402

EXPECTED_TEXT = """
GET / public static
GET /api/quickstart public static
GET /api/sample public static
GET /api/inputs public static
GET /api/fraction/render public static
GET /api/fraction/compare public static
GET /api/mode public gate
GET /api/preflight public gate
POST /api/mode public gate
POST /api/override public gate
POST /api/preflight public gate
POST /api/reset public gate
POST /api/set_key public gate
GET /api/models public runtime
POST /api/input unlocked runtime
POST /api/results/list unlocked runtime
POST /api/results/get unlocked runtime
GET /api/knowledge public analysis
GET /api/visualize/coordination public analysis
GET /api/unit_coordination.svg public analysis
GET /api/reorganize public analysis
POST /api/compute public analysis
POST /api/learner/reset public analysis
POST /api/analyze unlocked analysis
POST /api/event_score public analysis
POST /api/pair_graph verified analysis
POST /api/pair_candidate verified analysis
POST /api/chat public llm
POST /api/transcript_report public llm
POST /api/media_transcribe public llm
POST /api/pml_score public llm
POST /api/field_context public monitoring
POST /api/monitoring_chart_export public monitoring
POST /api/ranked_figures public monitoring
POST /api/monitoring_visuals public monitoring
POST /api/field_connectivity_audit public monitoring
POST /api/render_coverage public monitoring
GET /api/capabilities public worker
POST /api/render public worker
POST /api/expressive_power public worker
POST /api/strategies public worker
POST /api/strategy_trace public worker
POST /api/deontic_scorecard public worker
POST /api/crisis public worker
POST /api/deontic_consequences public worker
POST /api/deontic_up_level public worker
POST /api/deontic_requires_entitlement public worker
POST /api/sequent_proof public worker
POST /api/misconceptions public worker
POST /api/standards public worker
POST /api/grounding public worker
POST /api/geometry public worker
POST /api/canonical_contract public worker
POST /api/canonical_check public worker
POST /api/diagnose_error public worker
POST /api/query_misconception public worker
POST /api/literature public worker
POST /api/notation_render public worker
POST /api/fraction_cgi_addition public worker
POST /api/lesson_deformation_chart public worker
POST /api/notation_monitoring_chart public worker
POST /api/brandom_backstop public worker
POST /api/brandomian_check public worker
POST /api/hyperedges public worker
POST /api/axiom_toggle public worker
POST /api/carving_strategy_proof public worker
POST /api/carving_operation_summary public worker
POST /api/balance_solve public worker
POST /api/benny_demo public worker
POST /api/discourse_features public worker
POST /api/discourse_pragmatics public worker
POST /api/gesture_alignment public worker
POST /api/trace_adjudication public worker
POST /api/witness/crosswalk_claim public worker
POST /api/witness/geometry public worker
POST /api/witness/standards public worker
POST /api/witness/formal public worker
POST /api/witness/pml public worker
POST /api/witness/grounding public worker
POST /api/witness/misconception public worker
POST /api/parse verified workflow
POST /api/content verified workflow
POST /api/profile verified workflow
POST /api/draft verified workflow
POST /api/grade verified workflow
POST /api/score verified workflow
POST /api/metrics verified workflow
"""
EXPECTED = tuple(tuple(line.split()) for line in EXPECTED_TEXT.splitlines() if line.strip())


def noop(_context: object) -> None:
    return


def main() -> int:
    router = build_router()
    actual = tuple((route.method, route.path, route.access, route.module) for route in router.routes)
    if actual != EXPECTED:
        print("route registry mismatch", file=sys.stderr)
        print("expected:", *EXPECTED, sep="\n", file=sys.stderr)
        print("actual:", *actual, sep="\n", file=sys.stderr)
        return 1
    duplicate = Route("GET", "/api/mode", noop)
    try:
        Router((*router.routes, duplicate), noop)
    except DuplicateRouteError:
        print(f"route registry: {len(actual)} exact routes; duplicate rejection: PASS")
        return 0
    print("duplicate route was accepted", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
