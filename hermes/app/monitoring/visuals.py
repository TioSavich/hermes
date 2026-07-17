"""Build monitoring visual documents from a lesson chart."""
from __future__ import annotations

import re
from pathlib import Path
from typing import Any, Callable

LESSON_CODE_RE = re.compile(r"^IM-G(?P<grade>K|\d+)-U(?P<unit>\d+)-L(?P<lesson>\d+)$")
INT_RE = r"\d[\d,]*"


class _VisualBuilder:
    def __init__(self, repo_root: Path, worker_request: Callable[..., Any]) -> None:
        self.repo_root = repo_root
        self.worker_request = worker_request

    def _lesson_teacher_guide_path(self, code: str) -> Path | None:
        match = LESSON_CODE_RE.match(code)
        if not match:
            return None
        grade = match.group("grade")
        grade_dir = "kindergarten" if grade == "K" else f"grade{grade}"
        return (
            self.repo_root
            / "geometry"
            / "corpus"
            / "im_teacher_guides"
            / grade_dir
            / f"unit{match.group('unit')}"
            / f"lesson{match.group('lesson')}.md"
        )

    def _lesson_teacher_guide_text(self, code: str) -> str:
        path = self._lesson_teacher_guide_path(code)
        if not path or not path.is_file():
            return ""
        return path.read_text(encoding="utf-8", errors="replace")

    def _parse_int(self, text: str) -> int:
        return int(text.replace(",", ""))

    def _format_int(self, value: int) -> str:
        return f"{value:,}" if abs(value) >= 1000 else str(value)

    def _lesson_addition_candidates(self, text: str) -> list[tuple[int, int]]:
        candidates: list[tuple[int, int]] = []
        for match in re.finditer(rf"(?<!\d)({INT_RE})\s*\+\s*({INT_RE})(?:\s*=\s*({INT_RE}))?", text):
            a, b = self._parse_int(match.group(1)), self._parse_int(match.group(2))
            if match.group(3) and a + b != self._parse_int(match.group(3)):
                continue
            candidates.append((a, b))
        for match in re.finditer(rf"sum of\s+({INT_RE})\s+and\s+({INT_RE})", text, re.IGNORECASE):
            candidates.append((self._parse_int(match.group(1)), self._parse_int(match.group(2))))
        return candidates

    def _lesson_subtraction_candidates(self, text: str) -> list[tuple[int, int]]:
        candidates: list[tuple[int, int]] = []
        for match in re.finditer(rf"(?<!\d)({INT_RE})\s*-\s*({INT_RE})(?:\s*=\s*({INT_RE}))?", text):
            a, b = self._parse_int(match.group(1)), self._parse_int(match.group(2))
            if match.group(3) and a - b != self._parse_int(match.group(3)):
                continue
            candidates.append((a, b))
        start = re.search(rf"Starting number:\s*({INT_RE})", text, re.IGNORECASE)
        end = re.search(rf"Ending number:\s*({INT_RE})", text, re.IGNORECASE)
        if start and end:
            a, result = self._parse_int(start.group(1)), self._parse_int(end.group(1))
            if a >= result:
                candidates.insert(0, (a, a - result))
        return candidates

    def _chart_names(self, chart: dict, key: str) -> set[str]:
        rows = chart.get(key) or []
        names = {
            str(row.get("kind") or row.get("name") or "")
            for row in rows
            if isinstance(row, dict)
        }
        return {name for name in names if name}

    def _render_doc(self, request: dict[str, Any]) -> dict:
        op = str(request.get("op") or "")
        kwargs = {k: v for k, v in request.items() if k != "op"}
        doc = self.worker_request(op, **kwargs)
        return doc if isinstance(doc, dict) else {"error": f"{op} returned a non-document value"}

    def _representation_spec_proof_request(self, request: dict[str, Any]) -> dict[str, Any] | None:
        """Translate a render request into the grammar proof request it should satisfy."""
        op = str(request.get("op") or "")
        payload = {k: v for k, v in request.items() if k != "op"}
        representation_by_op = {
            "set_grouping_render": "set_grouping",
            "base_ten_render": "base_ten_blocks",
            "ace_of_bases_render": "base_ten_blocks",
            "unit_echo_render": "fraction_bars",
            "base_ten_compare": "base_ten_blocks",
            "number_line_render": "number_line",
            "place_value_chart_render": "place_value_chart",
            "area_render": "area_model",
            "area_compare": "area_model",
            "balance_render": "balance_scale",
            "balance_compare": "balance_scale",
            "fraction_render": "fraction_bars",
            "hybridization_render": "hybridization",
        }
        representation = representation_by_op.get(op)
        if not representation:
            return None
    
        proof = {"representation": representation, **payload}
        kind = str(payload.get("kind") or "")
        if op == "base_ten_compare":
            proof["kind"] = "add_with_dropped_carry"
            proof["task"] = "whole_number_addition"
        elif op == "area_compare":
            proof["kind"] = "area_compare"
            proof["task"] = "fraction_product"
        elif op == "balance_compare":
            proof["kind"] = "balance_compare"
            proof["task"] = "equation_linear"
        elif op == "set_grouping_render" and kind == "make_ten_drop_leftover":
            proof["task"] = "whole_number_addition"
        elif op == "base_ten_render" and kind == "subtract_without_reducing_borrow":
            proof["task"] = "whole_number_subtraction"
        elif op == "hybridization_render":
            proof.setdefault("kind", "circle_partition_on_rectangle")
        elif op == "fraction_render" and kind == "add_numerators_and_denominators":
            proof["task"] = "fraction_addition"
        return proof

    def _representation_spec_proof(self, request: dict[str, Any]) -> dict:
        proof_request = self._representation_spec_proof_request(request)
        if proof_request is None:
            return {
                "status": "proof_unavailable",
                "reason": f"no representation_spec_check mapping for {request.get('op')}",
            }
        grammar = self.worker_request("representation_spec_check", **proof_request)
        if not isinstance(grammar, dict):
            return {
                "status": "proof_error",
                "request": {"op": "representation_spec_check", **proof_request},
                "reason": f"representation_spec_check returned {type(grammar).__name__}",
            }
        if grammar.get("preserves") is True:
            status = "productive_preserves_denoted_task"
        elif grammar.get("deformation"):
            status = "misconception_deformation"
        else:
            status = "proof_inconclusive"
        return {
            "status": status,
            "request": {"op": "representation_spec_check", **proof_request},
            "grammar": grammar,
        }

    def _frame_proof(self, doc: dict) -> dict:
        frames = doc.get("frames") if isinstance(doc, dict) else []
        frames = frames if isinstance(frames, list) else []
        frame_count = len(frames)
        sequence = [
            {
                "step": frame.get("step"),
                "verb": str(frame.get("verb") or ""),
                "caption": str(frame.get("caption") or ""),
            }
            for frame in frames
            if isinstance(frame, dict)
        ]
        return {
            "frame_count": frame_count,
            "temporal": frame_count > 1,
            "frame_sequence": sequence,
        }

    def _interpretive_residue(self) -> dict:
        return {
            "status": "human_endorsement_required",
            "claim": (
                "Hermes checks representation grammar, denotation, deformation evidence, "
                "refusal, and render frames; it does not certify that this generated "
                "visual is a faithful reading of any particular student's work."
            ),
            "machine_certifies": [
                "render spec denotation or named deformation evidence",
                "representation refusal when a vocabulary cannot productively denote the task",
                "temporal frame count and scene-contract shape",
            ],
            "human_must_endorse": [
                "the fit between extracted teacher-guide numbers and the lesson activity",
                "the projective reading from an actual student work sample to this labeled misconception",
            ],
        }

    def _proof_for_render_pair(self, correct_request: dict[str, Any], correct_doc: dict,
                               incorrect_request: dict[str, Any], incorrect_doc: dict) -> dict:
        correct_proof = self._representation_spec_proof(correct_request)
        correct_proof.update(self._frame_proof(correct_doc))
        incorrect_proof = self._representation_spec_proof(incorrect_request)
        incorrect_proof.update(self._frame_proof(incorrect_doc))
        return {
            "source": "representation_grammar_and_render_contract",
            "correct": correct_proof,
            "incorrect": incorrect_proof,
            "interpretive_residue": self._interpretive_residue(),
        }

    def _proof_for_refusal(self, correct_request: dict[str, Any], correct_doc: dict,
                           decision: dict) -> dict:
        correct_proof = self._representation_spec_proof(correct_request)
        correct_proof.update(self._frame_proof(correct_doc))
        return {
            "source": "representation_grammar_and_render_contract",
            "correct": correct_proof,
            "incorrect": {
                "status": "refused_by_representation_grammar",
                "refusal": str(decision.get("refusal") or ""),
                "grammar": decision,
                "frame_count": 0,
                "temporal": False,
                "frame_sequence": [],
            },
            "interpretive_residue": self._interpretive_residue(),
        }

    def _representation_check(self, representation: str, task: str, **payload: Any) -> dict:
        decision = self.worker_request(
            "representation_check",
            mode="productive",
            representation=representation,
            task=task,
            **payload,
        )
        return decision if isinstance(decision, dict) else {
            "allowed": False,
            "refusal": f"representation_check returned {type(decision).__name__}",
        }

    def _representation_candidates(self, lesson_code: str, task: str, **payload: Any) -> dict:
        result = self.worker_request(
            "representation_candidates",
            lesson_code=lesson_code,
            task=task,
            **payload,
        )
        return result if isinstance(result, dict) else {
            "candidates": [],
            "refusals": [],
            "error": f"representation_candidates returned {type(result).__name__}",
        }

    def _refusal_reason_for_candidate_result(self, candidate_result: dict, representation: str) -> str | None:
        refusals = [
            refusal for refusal in (candidate_result.get("refusals") or [])
            if refusal.get("representation") == representation
        ]
        if not refusals:
            return None
        physical = [
            str(refusal.get("reason") or "")
            for refusal in refusals
            if "no_physical_block_for_required_place_value" in str(refusal.get("reason") or "")
        ]
        if physical:
            def refusal_number(reason: str) -> int:
                match = re.search(r"\((\d+)\)", reason)
                return int(match.group(1)) if match else 10**18
            return sorted(physical, key=refusal_number)[0]
        return str(refusals[0].get("reason") or "")

    def _has_drawable_candidate(self, candidate_result: dict, representation: str) -> bool:
        return any(
            candidate.get("representation") == representation
            and str(candidate.get("render_status") or "").startswith("renderable(")
            for candidate in (candidate_result.get("candidates") or [])
        )

    def _candidate_for_representation(self, candidate_result: dict, representation: str) -> dict | None:
        for candidate in candidate_result.get("candidates") or []:
            if isinstance(candidate, dict) and candidate.get("representation") == representation:
                return candidate
        return None

    def _refusal_for_representation(self, candidate_result: dict, representation: str) -> dict | None:
        for refusal in candidate_result.get("refusals") or []:
            if isinstance(refusal, dict) and refusal.get("representation") == representation:
                return refusal
        return None

    def _alternative_representation_search(self, 
        candidate_result: dict,
        failed_representation: str,
        failed_reason: str,
        order: list[str],
    ) -> dict:
        attempts: list[dict] = []
        selected: dict | None = None
        for representation in order:
            candidate = self._candidate_for_representation(candidate_result, representation)
            refusal = self._refusal_for_representation(candidate_result, representation)
            if candidate and str(candidate.get("render_status") or "").startswith("renderable("):
                attempt = {
                    "representation": representation,
                    "status": "selected" if selected is None else "available",
                    "render_status": str(candidate.get("render_status") or ""),
                    "evidence": candidate.get("evidence") or [],
                }
                if selected is None:
                    selected = attempt
            elif refusal:
                attempt = {
                    "representation": representation,
                    "status": "refused",
                    "reason": str(refusal.get("reason") or ""),
                }
            else:
                attempt = {
                    "representation": representation,
                    "status": "unavailable",
                    "reason": "no lesson-licensed drawable candidate returned",
                }
            attempts.append(attempt)
        return {
            "failed": {
                "representation": failed_representation,
                "reason": failed_reason,
            },
            "attempts": attempts,
            "selected": selected or {},
        }

    def _visual_card(self, expression: str, correct: dict, incorrect: dict,
                     correct_label: str, incorrect_label: str,
                     family: str) -> dict:
        correct_doc = self._render_doc(correct)
        incorrect_doc = self._render_doc(incorrect)
        return {
            "expression": expression,
            "family": family,
            "source": "generated_from_teacher_guide_and_monitoring_chart",
            "correct": {
                "label": "Correct strategy",
                "description": correct_label,
                "request": correct,
                "doc": correct_doc,
            },
            "incorrect": {
                "label": "Incorrect strategy",
                "description": incorrect_label,
                "request": incorrect,
                "doc": incorrect_doc,
            },
            "proof": self._proof_for_render_pair(correct, correct_doc, incorrect, incorrect_doc),
        }

    def _visual_refusal_card(self, expression: str, correct: dict, refused: dict,
                             correct_label: str, refusal_label: str,
                             family: str, decision: dict) -> dict:
        reason = str(decision.get("refusal") or "representation grammar refused this visual")
        correct_doc = self._render_doc(correct)
        return {
            "expression": expression,
            "family": family,
            "source": "generated_from_teacher_guide_and_monitoring_chart",
            "status": "refused_by_representation_grammar",
            "grammar": decision,
            "correct": {
                "label": "Correct strategy",
                "description": correct_label,
                "request": correct,
                "doc": correct_doc,
            },
            "incorrect": {
                "label": "Misconception visual refused",
                "description": refusal_label,
                "request": refused,
                "doc": {
                    "error": f"Representation grammar refused this base-ten picture: {reason}",
                    "frames": [],
                },
            },
            "proof": self._proof_for_refusal(correct, correct_doc, decision),
        }

    def _monitoring_visuals_for_chart(self, code: str, chart: dict) -> dict:
        text = self._lesson_teacher_guide_text(code)
        strategies = self._chart_names(chart, "anticipated_strategies")
        misconceptions = self._chart_names(chart, "teacher_misconceptions")
        visuals: list[dict] = []
    
        if {"make_ten_split_leftover", "make_ten_drop_leftover"} & (strategies | misconceptions):
            small_additions = [
                (a, b) for a, b in self._lesson_addition_candidates(text)
                if a + b <= 20 and max(a, b) < 10 and min(a, b) > 0
            ]
            if small_additions:
                shown_a, shown_b = small_additions[0]
                render_a, render_b = (shown_a, shown_b)
                if shown_b > shown_a:
                    render_a, render_b = shown_b, shown_a
                visuals.append(self._visual_card(
                    f"{shown_a} + {shown_b}",
                    {"op": "set_grouping_render", "kind": "make_ten", "a": render_a, "b": render_b},
                    {"op": "set_grouping_render", "kind": "make_ten_drop_leftover", "a": render_a, "b": render_b},
                    "Make a ten, then preserve the leftover.",
                    "Make a ten, then drop the leftover.",
                    "make_ten",
                ))
    
        subtraction_needs_borrow = "borrow_without_reducing_bases" in misconceptions or "decompose_base_for_ones" in strategies
        if subtraction_needs_borrow:
            subtraction = next(
                ((a, b) for a, b in self._lesson_subtraction_candidates(text) if a >= b and (a % 10) < (b % 10)),
                None,
            )
            if subtraction:
                a, b = subtraction
                visuals.append(self._visual_card(
                    f"{self._format_int(a)} - {self._format_int(b)}",
                    {"op": "base_ten_render", "kind": "subtract_with_borrow", "a": a, "b": b, "base": 10},
                    {"op": "base_ten_render", "kind": "subtract_without_reducing_borrow", "a": a, "b": b, "base": 10},
                    "Decompose one ten and reduce the tens place.",
                    "Add ten ones but leave the tens place unchanged.",
                    "base_ten_subtraction_borrow",
                ))
    
        addition_with_carry = "column_addition_with_carrying" in strategies or "add_with_dropped_carry" in misconceptions
        if addition_with_carry:
            addition = next(
                ((a, b) for a, b in self._lesson_addition_candidates(text) if max(a, b) >= 100 and (a % 1000) + (b % 1000) >= 1000),
                None,
            )
            if addition:
                a, b = addition
                candidate_result = self._representation_candidates(
                    code,
                    "whole_number_addition",
                    a=a,
                    b=b,
                    strategy="column_addition_with_carrying",
                    misconception="add_with_dropped_carry",
                )
                expression = f"{self._format_int(a)} + {self._format_int(b)}"
                base_ten_refusal = self._refusal_reason_for_candidate_result(candidate_result, "base_ten_blocks")
                if base_ten_refusal:
                    alternative_search = self._alternative_representation_search(
                        candidate_result,
                        "base_ten_blocks",
                        base_ten_refusal,
                        ["number_line", "fraction_bars", "place_value_chart"],
                    )
                    selected_representation = str(
                        (alternative_search.get("selected") or {}).get("representation") or ""
                    )
                    if selected_representation == "number_line":
                        correct_request = {
                            "op": "number_line_render",
                            "mode": "magnitude",
                            "operation": "addition",
                            "a": a,
                            "b": b,
                        }
                        correct_label = "Use a scalable number-line measure model for the large magnitude."
                    elif selected_representation == "place_value_chart":
                        correct_request = {
                            "op": "place_value_chart_render",
                            "kind": "add_with_carry",
                            "a": a,
                            "b": b,
                            "base": 10,
                        }
                        correct_label = "Use a place-value chart for the large-number column algorithm."
                    else:
                        correct_request = {"op": "representation_candidates", "lesson_code": code}
                        correct_label = "No drawable productive representation is registered for this task."
                    base_ten_decision = {
                        **candidate_result,
                        "allowed": False,
                        "refusal": base_ten_refusal,
                        "alternative_search": alternative_search,
                        "preferred": {
                            "representation": selected_representation,
                            "reason": "alternative_representation_search",
                        },
                    }
                    visuals.append(self._visual_refusal_card(
                        expression,
                        correct_request,
                        {"op": "representation_check", "mode": "productive",
                         "representation": "base_ten_blocks", "task": "whole_number_addition",
                         "a": a, "b": b},
                        correct_label,
                        "Base-ten blocks stop being a productive physical vocabulary here; a collapsed-cube picture would be a labeled misconception, not a calculator answer.",
                        "base_ten_addition_carry_refused_large_number",
                        base_ten_decision,
                    ))
                else:
                    visuals.append(self._visual_card(
                        expression,
                        {"op": "base_ten_render", "kind": "add_with_carry", "a": a, "b": b, "base": 10},
                        {"op": "base_ten_compare", "a": a, "b": b, "base": 10},
                        "Regroup by place value and carry the base-group.",
                        "Write the place remainder and drop the carry.",
                        "base_ten_addition_carry",
                    ))
    
        fraction_addition_names = {
            "fraction_addition_co_measurement",
            "add_fractions_by_co_measurement",
            "co_measurement_fraction_addition",
        }
        fraction_componentwise_names = {
            "add_numerators_and_denominators",
            "add_denominators_unit_fractions",
            "componentwise_fraction_addition",
        }
        if fraction_addition_names & strategies or fraction_componentwise_names & misconceptions:
            visuals.append(self._visual_card(
                "1/3 + 1/4",
                {
                    "op": "fraction_render",
                    "kind": "arith",
                    "operation": "add",
                    "na": 1,
                    "da": 3,
                    "nb": 1,
                    "db": 4,
                },
                {
                    "op": "fraction_render",
                    "kind": "add_numerators_and_denominators",
                    "na": 1,
                    "da": 3,
                    "nb": 1,
                    "db": 4,
                },
                "Measure both fractions in a shared unit before combining.",
                "Add the visible numerator and denominator components as if they were independent counts.",
                "fraction_bars_addition",
            ))
    
        balance_strategy_names = {
            "balance_solve_equation",
            "solve_linear_equation",
            "preserve_balance",
        }
        balance_misconception_names = {
            "operational_equals_subtract_from_one_side",
            "operational_equals_compute_one_side",
            "balance_not_preserved",
        }
        if balance_strategy_names & strategies or balance_misconception_names & misconceptions:
            visuals.append(self._visual_card(
                "2x + 3 = 11",
                {"op": "balance_render", "a": 2, "b": 3, "c": 11},
                {"op": "balance_compare", "a": 2, "b": 3, "c": 11},
                "Preserve equality by making the same move on both pans.",
                "Treat the equals sign as a command and change only one side.",
                "balance_scale_equation",
            ))
    
        hybridization_names = {
            "hybridized_model",
            "circle_partition_on_rectangle",
            "circle_radial_partition_on_rectangle",
            "object_language_binding_violation",
        }
        if hybridization_names & misconceptions:
            visuals.append(self._visual_card(
                "circle partition transplanted onto a rectangle",
                {
                    "op": "area_render",
                    "kind": "area_model_fraction",
                    "na": 1,
                    "da": 2,
                    "nb": 1,
                    "db": 3,
                },
                {
                    "op": "hybridization_render",
                    "kind": "circle_partition_on_rectangle",
                },
                "Partition the rectangular area model by its own part-of-part vocabulary.",
                "Move the circle's radial partition rule onto the rectangle host.",
                "hybridization_transplant",
            ))
    
        return {"lesson_code": code, "visuals": visuals}



def monitoring_visuals_for_chart(
    code: str,
    chart: dict,
    worker_request: Callable[..., Any],
    *,
    repo_root: Path | None = None,
) -> dict:
    root = repo_root or Path(__file__).resolve().parents[3]
    return _VisualBuilder(root, worker_request)._monitoring_visuals_for_chart(code, chart)
