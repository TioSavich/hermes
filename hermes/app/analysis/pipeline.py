"""In-memory N103 transcript-to-Prolog pairing bridge.

This module replaces the pure-Python pairing path for fresh runs: raw
discussion text may enter memory as ``HermesEvent`` objects, but only
canonical pseudonym/event metadata is sent to the Prolog worker or returned to
the GUI.
"""
from __future__ import annotations

from collections.abc import Callable, Iterable
from typing import Any

from .hermes_n103 import ContributionAnalysis, HermesEvent, analyze_event
from hermes.app.worker import PersistentPrologWorker


TOPIC_MATERIAL_HANDLES = {
    "inclusive_shape_hierarchy": "class_inclusion_by_defining_attributes",
    "prototype_vs_definition": "classification_by_definition_over_prototype",
    "measure_vs_object": "measure_tracks_attribute_not_object",
    "angle_as_turn_vs_length": "angle_measure_as_turn_not_arm_length",
    "diagram_vs_deduction": "diagram_suggests_deduction_licenses",
    "motion_vs_invariance": "transformation_preserves_invariants",
    "dimension_boundary": "representation_not_object",
    "same_difference": "equal_measure_not_same_shape",
    "finite_vs_infinite": "finite_mark_represents_continuum",
}


def canonical_events_from_hermes_events(events: Iterable[HermesEvent]) -> list[dict[str, Any]]:
    """Analyze raw in-memory events and return Prolog-safe canonical events.

    The returned records intentionally omit names, raw text, source paths, and
    evidence snippets. Pseudonyms are assigned by first-seen participant order.
    """
    pseudonyms: dict[str, str] = {}
    canonical: list[dict[str, Any]] = []
    for index, event in enumerate(events, start=1):
        pseudonym = pseudonyms.setdefault(event.student, f"S{len(pseudonyms) + 1:02d}")
        event_id = f"ev_{index:04d}"
        canonical.append(_canonical_event(analyze_event(event), event_id, pseudonym))
    return canonical


def run_prolog_pair_pipeline(
    events: Iterable[HermesEvent],
    *,
    worker_factory: Callable[[], Any] = PersistentPrologWorker,
) -> dict[str, Any]:
    canonical_events = canonical_events_from_hermes_events(events)
    worker = worker_factory()
    try:
        scores = worker.request("batch_event_score", events=canonical_events)
        pairs = worker.request("pair_score", events=canonical_events)
        graph = worker.request("pair_graph", events=canonical_events)
    finally:
        worker.close()
    return {
        "privacy": "pseudonymized_metadata_only_no_student_work",
        "event_count": len(canonical_events),
        "events": canonical_events,
        "scores": scores,
        "pairs": pairs,
        "graph": graph,
    }


def _canonical_event(
    analysis: ContributionAnalysis,
    event_id: str,
    pseudonym: str,
) -> dict[str, Any]:
    signals = list(analysis.signals)
    topic = signals[0].topic if signals else "unknown"
    mode = _pml_mode(analysis.stance.mode)
    polarity = _pml_polarity(analysis.stance.polarity)
    commitments = [signal.code for signal in signals] or ["low_information_geometry_claim"]
    misconceptions = [signal.code for signal in signals if signal.family == "misconception"]
    paradoxes = [signal.code for signal in signals if signal.family == "paradox"]
    material_handles = _material_handles(topic, polarity)
    return {
        "event_id": event_id,
        "source": {
            "source_type": "n103_discussion",
            "metadata": {
                "domain": "geometry",
                "topic": topic,
            },
        },
        "actor": {
            "role": "student",
            "pseudonym": pseudonym,
        },
        "substrate": {
            "utterance_type": _utterance_type(mode),
            "observed_markers": sorted({signal.family for signal in signals} | {topic}),
            "candidate_terms": sorted({signal.code for signal in signals}),
            "confidence": _confidence(signals),
        },
        "symbolic": {
            "commitments": commitments,
            "entitlements": paradoxes,
            "missing_requirements": _missing_requirements(topic, misconceptions),
            "incompatibilities": misconceptions,
            "material_inferences": material_handles,
            "literature_handles": sorted({signal.code for signal in signals}),
            "residuals": [] if signals else ["no_geometry_signal_detected"],
        },
        "pml": {
            "mode": mode,
            "polarity": polarity,
            "force": "binding",
            # One of the 12 legal PML operators (formal/pml/pml_operators.pl): compressive
            # necessity vs expansive possibility. The prior value "possibility" is
            # not a PML operator.
            "operator": "comp_nec" if polarity == "compressive" else "exp_poss",
            "validity_focus": [_validity_register(mode)],
            "pragmatic_horizon_level": "foreground" if signals else "background",
            "status": "candidate",
            "confidence": _confidence(signals),
        },
        "carspecken": {
            "action_impetus": _action_impetus(topic, misconceptions),
            "identity_claim": None,
            "identity_cost": 0.65 if misconceptions else 0.25,
            "recognition_risk": "medium" if misconceptions else "low",
            "proprioceptive_delta": "contraction" if polarity == "compressive" else "expansion",
            "internalized_audience": "n103_geometry_discussion_norm",
            "infinite_seed": False,
            "apophatic_guardrail": "Do not diagnose the learner or quote student work.",
        },
        "question_candidates": [
            _question_candidate(event_id, index, signal, mode)
            for index, signal in enumerate(signals, start=1)
        ] or [_fallback_question_candidate(event_id, mode)],
        "status": "pml_annotated",
    }


def _material_handles(topic: str, polarity: str) -> list[dict[str, str]]:
    handle = TOPIC_MATERIAL_HANDLES.get(topic, f"{topic}_material_inference")
    return [
        {
            "handle": handle,
            "frame": _inference_frame_for_topic(topic),
            "polarity": polarity,
        }
    ]


def _question_candidate(event_id: str, index: int, signal, mode: str) -> dict[str, Any]:
    return {
        "question_id": f"q_{event_id}_{index:02d}",
        "move_type": _move_type(signal.family, mode),
        "target_commitment": signal.code,
        "validity_register": _validity_register(mode),
        "constraints_satisfied": _constraints(signal.family),
        "llm_revoiced": False,
    }


def _fallback_question_candidate(event_id: str, mode: str) -> dict[str, Any]:
    return {
        "question_id": f"q_{event_id}_00",
        "move_type": "FMST",
        "target_commitment": "low_information_geometry_claim",
        "validity_register": _validity_register(mode),
        "constraints_satisfied": ["recognition_safe", "opens_validity_claim"],
        "llm_revoiced": False,
    }


def _constraints(family: str) -> list[str]:
    if family == "misconception":
        return ["recognition_safe", "repair_affordance", "targets_missing_requirement"]
    if family == "paradox":
        return ["recognition_safe", "opens_validity_claim", "decompresses_background_norm"]
    return ["recognition_safe", "opens_validity_claim"]


def _move_type(family: str, mode: str) -> str:
    if family == "misconception":
        return "FMST"
    if family == "paradox":
        return "decompression"
    if mode == "subjective":
        return "recognition"
    return "AQST"


def _missing_requirements(topic: str, misconceptions: list[str]) -> list[str]:
    if not misconceptions:
        return []
    return [f"{topic}_defining_attribute_warrant"]


def _action_impetus(topic: str, misconceptions: list[str]) -> str:
    if misconceptions:
        return f"repair_{topic}_classification"
    return f"surface_{topic}_validity_claim"


def _pml_mode(mode: str) -> str:
    return mode if mode in {"subjective", "objective", "normative"} else "objective"


def _pml_polarity(polarity: str) -> str:
    return polarity if polarity in {"compressive", "expansive"} else "expansive"


def _validity_register(mode: str) -> str:
    return {
        "subjective": "subjective_truthfulness",
        "normative": "normative_rightness",
    }.get(mode, "objective_truth")


def _utterance_type(mode: str) -> str:
    if mode == "subjective":
        return "avowal"
    if mode == "normative":
        return "assertion_of_norm"
    return "assertion"


def _inference_frame_for_topic(topic: str) -> str:
    # A coarse discourse "inference frame" tag for the geometry topic — a routing
    # heuristic, NOT a Lakoff & Núñez grounding metaphor. The real L&N grounding
    # metaphors (object collection, measuring stick, motion along a path, …) and
    # their break-points live in formal/formalization/grounding_metaphors.pl and are
    # surfaced via the /api/grounding endpoint; do not conflate the two.
    if topic in {"inclusive_shape_hierarchy", "prototype_vs_definition"}:
        return "category_membership_frame"
    if topic in {"measure_vs_object", "angle_as_turn_vs_length"}:
        return "measurement_frame"
    return "inference_transition_frame"


def _confidence(signals: list) -> float:
    if not signals:
        return 0.35
    return round(min(0.95, 0.62 + 0.07 * len(signals)), 2)
