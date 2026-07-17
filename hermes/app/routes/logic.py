"""Endpoint behavior shared by the declarative route modules.

This class is deliberately stateless: every request receives the server-owned
RequestContext, including worker, gate, cache, paths, and LLM dependencies.
"""
from __future__ import annotations

import base64
import binascii
import json
import os
import re
import urllib.parse
from typing import Any

from hermes.app import gate, llm, worker

TRANSCRIPT_SPEAKER_RE = re.compile(
    r"^\s*(student\s*\d+|s\d+|[A-Za-z][A-Za-z .'-]{0,40})\s*:\s+\S",
    re.IGNORECASE,
)
NON_SPEAKER_LABELS = frozenset({"answer", "answers", "note", "prompt", "question", "response", "state", "trace"})
FRACTION_RE = re.compile(r"\b(?P<a>\d{1,3})\s*/\s*(?P<b>\d{1,3})\b")

WITNESS_OPS: dict[str, frozenset[str]] = {
    "crosswalk_claim": frozenset({
        "accommodation_witness",
        "action_cluster_witness",
        "algebra_claim_witness",
        "arithmetic_property_witness",
        "axiom_pack_witness",
        "calculus_claim_witness",
        "counting_claim_witness",
        "decimal_claim_witness",
        "domain_context_witness",
        "executable_practice_witness",
        "fraction_claim_witness",
        "fraction_extra_claim_witness",
        "fsm_engine_witness",
        "godel_primes_witness",
        "grounded_arith_witness",
        "grounding_metaphor_witness",
        "integer_signed_claim_witness",
        "magnitude_equivalence_claim_witness",
        "material_inference_witness",
        "metaphor_break_witness",
        "misconception_hook_witness",
        "modal_context_witness",
        "mua_coherence_witness",
        "multiplication_division_claim_witness",
        "normative_crisis_witness",
        "orr_entry_witness",
        "place_value_number_claim_witness",
        "practice_vocabulary_witness",
        "productive_deformation_witness",
        "ratio_proportion_claim_witness",
        "unit_coordination_witness",
        "viability_witness",
        "whole_number_addsub_claim_witness",
        "whole_number_claim_witness",
    }),
    "geometry": frozenset({
        "geometry_angle_material_witness",
        "geometry_area_perimeter_material_witness",
        "geometry_attribute_material_witness",
        "geometry_ccss_standard_witness",
        "geometry_classification_material_witness",
        "geometry_coordinate_material_witness",
        "geometry_cross_link_witness",
        "geometry_developmental_arc_witness",
        "geometry_entailment_witness",
        "geometry_im_grade5_standard_anchor_witness",
        "geometry_im_grade6_lesson_standard_witness",
        "geometry_im_grade7_lesson_standard_witness",
        "geometry_im_grade8_lesson_standard_witness",
        "geometry_indiana_standard_witness",
        "geometry_lakoff_nunez_metaphor_witness",
        "geometry_material_profile_witness",
        "geometry_measurement_misconception_witness",
        "geometry_measuring_stick_metaphor_witness",
        "geometry_n103_bootstrap_witness",
        "geometry_pck_classification_witness",
        "geometry_pythagorean_material_witness",
        "geometry_quadrilateral_entailment_witness",
        "geometry_shape_recognition_material_witness",
        "geometry_similarity_material_witness",
        "geometry_strength_lift_coverage_witness",
        "geometry_synthesizer_anchor_material_witness",
        "geometry_synthesizer_triangulation_witness",
        "geometry_transformation_material_witness",
        "geometry_van_de_walle_bootstrap_witness",
        "geometry_van_hiele_level_material_witness",
        "geometry_van_hiele_marker_witness",
        "geometry_van_hiele_material_witness",
        "geometry_volume_surface_area_material_witness",
    }),
}

SWIPL_HINT = (
    "SWI-Prolog (swipl) isn't installed, or it isn't on your PATH. Install it from "
    "https://www.swi-prolog.org/download/stable, then quit Hermes (Ctrl-C in the "
    "terminal) and run ./hermes/app/launch.sh again. See QUICKSTART_N103.md, step 1."
)
KEY_HINT = (
    "No REALLMS API key is set. Click “Set key” (top-right) and paste your "
    "key, or add it to hermes/app/runtime/.env. See QUICKSTART_N103.md, step 2."
)
WORKER_HINT = (
    "The local Prolog worker didn't respond as expected. If you just installed "
    "SWI-Prolog, restart Hermes. The terminal that launched Hermes has the full detail."
)


class RouteLogic:
    def __init__(self, ctx: Any) -> None:
        self.ctx = ctx

    def __getattr__(self, name: str) -> Any:
        return getattr(self.ctx, name)

    def _ground_message(self, message: str) -> dict | None:
        """Retrieve symbolic facts relevant to a chat question. Best-effort: returns
        None if the worker/swipl is unavailable, so chat still works ungrounded."""
        try:
            return self.ctx.worker_request("ground", query=message)
        except Exception:
            return None

    def _fraction_compare_scene_request(self, message: str) -> dict | None:
        text = message.lower()
        if "fraction" not in text or not any(word in text for word in ("bar", "bars", "compare", "scene")):
            return None
        match = FRACTION_RE.search(message)
        if not match:
            return None
        a = int(match.group("a"))
        b = int(match.group("b"))
        if "improper" in text:
            kind = "improper_fraction_iteration"
        elif "partition" in text or "part of part" in text or "part-of-part" in text:
            kind = "recursive_partition"
        else:
            kind = "unit_fraction_iteration"
        query = urllib.parse.urlencode({"kind": kind, "a": a, "b": b})
        return {
            "kind": kind,
            "a": a,
            "b": b,
            "url": f"/more-zeeman/fraction-bars/compare.html?{query}",
        }

    def _chat_render_scene_request(self, message: str) -> dict | None:
        text = message.lower()
        nums = [int(n) for n in re.findall(r"\d{1,4}", message)]
    
        def scene(op: str, payload: dict, path: str) -> dict:
            query = urllib.parse.urlencode(payload)
            return {"op": op, "payload": payload, "url": f"{path}?{query}"}
    
        if ("area" in text or "array" in text) and len(nums) >= 2:
            payload = {"kind": "array_multiplication", "a": nums[0], "b": nums[1]}
            return scene("area_render", payload, "/more-zeeman/area-model/index.html")
        if ("base-ten" in text or "base ten" in text or "blocks" in text) and len(nums) >= 2:
            payload = {"kind": "add_with_carry", "a": nums[0], "b": nums[1], "base": 10}
            return scene("base_ten_render", payload, "/more-zeeman/base-ten/index.html")
        if ("set grouping" in text or "make ten" in text or "ten frame" in text) and len(nums) >= 2:
            payload = {"kind": "make_ten", "a": nums[0], "b": nums[1]}
            return scene("set_grouping_render", payload, "/more-zeeman/set-grouping/index.html")
        if "balance" in text and len(nums) >= 3:
            payload = {"a": nums[0], "b": nums[1], "c": nums[2]}
            return scene("balance_render", payload, "/more-zeeman/balance-scale/index.html")
        return None

    def _grounding_facts_block(self, g: dict | None) -> str:
        """A compact, plain-text rendering of retrieved facts for the model prompt."""
        if not g or not g.get("total"):
            return ("SYMBOLIC FACTS: Hermes has no encoded strategy, misconception, "
                    "standard, or grounding metaphor matching this question.")
        lines = ["SYMBOLIC FACTS Hermes retrieved from its knowledge base "
                 "(ground your answer in these; do not invent others):"]
        if g.get("strategies"):
            lines.append("- Strategies (children's arithmetic automata): " + "; ".join(
                f"{s['kind']} ({s['operation']}{', runnable' if s.get('runnable') else ''})"
                for s in g["strategies"]))
        if g.get("misconceptions"):
            parts = []
            for m in g["misconceptions"]:
                ex = m.get("example") or {}
                if ex.get("wrong"):
                    parts.append(f"{m['name']} — a student computes {ex['input']} and gets "
                                 f"{ex['wrong']} (correct: {ex['correct']})")
                else:
                    parts.append(f"{m['name']} ({m['domain']})")
            lines.append("- Misconceptions with the exact wrong answer each produces: " + "; ".join(parts))
        if g.get("standards"):
            lines.append("- Standards: " + "; ".join(
                f"{str(s['framework']).upper()} {s['code']} — {str(s['statement'])[:110]}"
                for s in g["standards"]))
        if g.get("metaphors"):
            lines.append("- Lakoff & Núñez grounding metaphors: " + "; ".join(
                f"{m['short_name']} ({m['breaks']} break-point(s))" for m in g["metaphors"]))
        if g.get("geometry"):
            lines.append("- Geometry concepts: " + "; ".join(
                f"{item.get('concept')} — {item.get('name')} ({item.get('topic')})"
                for item in g["geometry"]))
        if g.get("literature"):
            parts = []
            for c in g["literature"]:
                valid = c.get("valid_domain")
                where = f"valid in {valid}" if valid and valid != "none" else "a genuine slip"
                parts.append(
                    f"{c['student_rule']} ({where}; collides with {c['incompatible_with']}) "
                    f"[{c.get('citation') or 'uncited'}]"
                )
            lines.append("- Literature-derived incompatibility analyses "
                         "(rule / where it IS valid / what it collides with): " + "; ".join(parts))
        return "\n".join(lines)

    def _grounding_summary(self, g: dict | None) -> dict:
        """Compact source list for the UI to show what the answer was grounded in."""
        if not g:
            return {"total": 0, "strategies": [], "misconceptions": [], "standards": [],
                    "metaphors": [], "geometry": [], "literature": []}
        return {
            "total": g.get("total", 0),
            "strategies": [s["kind"] for s in (g.get("strategies") or [])],
            "misconceptions": [m["name"] for m in (g.get("misconceptions") or [])],
            "standards": [f"{s['framework']} {s['code']}" for s in (g.get("standards") or [])],
            "metaphors": [m["short_name"] for m in (g.get("metaphors") or [])],
            "geometry": [f"{c.get('concept')} ({c.get('topic')})" for c in (g.get("geometry") or [])],
            "literature": [f"{c['student_rule']} [{c.get('citation') or 'uncited'}]"
                           for c in (g.get("literature") or [])],
            "math_claims": [f"{c.get('claim', '')}: {c.get('verdict') or c.get('status', '')}"
                            for c in (g.get("math_claims") or [])],
        }

    def _offline_chat_answer(self, grounded: dict) -> str:
        """Deterministic chat answer assembled from the symbolic grounding when no
        language-model key is configured. It states its own boundary rather than
        imitating prose the model would have written."""
        sections = [
            ("math_claims", "Checked claims"),
            ("strategies", "Strategies"),
            ("misconceptions", "Misconceptions"),
            ("standards", "Standards"),
            ("metaphors", "Grounding metaphors"),
            ("geometry", "Geometry concepts"),
            ("literature", "Literature"),
        ]
        lines = []
        for field, label in sections:
            values = grounded.get(field) or []
            if values:
                lines.append(f"{label}: " + ", ".join(str(v) for v in values))
        if not lines:
            return ("No language-model key is configured, and the symbolic knowledge "
                    "base returned nothing for this message. " + KEY_HINT)
        return ("No language-model key is configured, so this answer is the symbolic "
                "grounding itself rather than prose about it.\n" + "\n".join(lines))

    def _extract_pml_clauses(self, text: str) -> list[str]:
        """Pull balanced reader_axiom(...) / passage_mode(...) clauses out of the model
        output, ignoring any prose or markdown fences around them. The worker only
        term-PARSES these (never consults them), so this is the safe collection step."""
        clauses: list[str] = []
        for kw in ("reader_axiom", "passage_mode"):
            needle, start = kw + "(", 0
            while True:
                j = text.find(needle, start)
                if j < 0:
                    break
                depth, k = 0, j + len(kw)
                while k < len(text):
                    ch = text[k]
                    if ch == "(":
                        depth += 1
                    elif ch == ")":
                        depth -= 1
                        if depth == 0:
                            break
                    k += 1
                if k < len(text):
                    clauses.append(text[j:k + 1])
                    start = k + 1
                else:
                    break
        return clauses

    def _friendly_backend_error(self, text: str) -> tuple[str | None, str | None]:
        """Map a raw backend error string to (plain_message, error_type).
    
        Returns (None, None) when no rule matches, so the caller keeps the raw text.
        Rules are ordered most-specific first.
        """
        low = (text or "").lower()
        if "swipl" in low or ("no such file or directory" in low and "prolog" in low):
            return SWIPL_HINT, "swipl_missing"
        if "reallms_api_key" in low or "set reallms" in low or "no api key" in low \
                or "no reallms api key" in low:
            return KEY_HINT, "no_key"
        if ("worker returned malformed json" in low or "worker exited with" in low
                or "worker request timed out" in low or "worker pipe closed" in low):
            return WORKER_HINT, "worker_failed"
        return None, None

    def _looks_like_discussion_transcript(self, text: str) -> bool:
        labels: list[str] = []
        for raw_line in text.splitlines():
            match = TRANSCRIPT_SPEAKER_RE.match(raw_line)
            if not match:
                continue
            label = re.sub(r"\s+", " ", match.group(1).strip().lower())
            if label in NON_SPEAKER_LABELS:
                continue
            labels.append(label)
        return len(set(labels)) >= 2

    def _run_preflight(self) -> tuple[bool, str]:
        """Secure preflight using the configured key. Never raises."""
        key = llm.load_key(self.ctx.runtime)
        if key is None:
            return False, "no REALLMS_API_KEY configured (set it in the app or runtime/.env)"
        return llm.secure_preflight(api_key=key, api_url=llm.resolve_api_url())

    def _ssl_ctx_for_mode(self):
        """campus -> secure (verified); home -> insecure (tinker only)."""
        os.environ["REALLMS_INSECURE"] = "0" if self.ctx.services.gate.state.mode == gate.CAMPUS else "1"
        if self.ctx.services.gate.state.mode == gate.CAMPUS:
            return llm.build_secure_ssl_context()
        return llm.build_ssl_context()

    def _two_pass_module(self):
        return self.ctx.services.two_pass_module()

    def _handle_learner_compute(self, payload: object) -> None:
        if not isinstance(payload, dict):
            self._send_json({"error": "request body must be a JSON object"}, status=400)
            return
        operation = payload.get("operation")
        if operation not in {"add", "subtract", "multiply", "divide"}:
            self._send_json(
                {"error": "operation must be add, subtract, multiply, or divide"},
                status=400,
            )
            return
        if type(payload.get("a")) is not int or type(payload.get("b")) is not int:
            self._send_json({"error": "a and b must be integers"}, status=400)
            return
        limit = payload.get("limit", 20)
        if type(limit) is not int or limit <= 0:
            self._send_json({"error": "limit must be a positive integer"}, status=400)
            return
        mode = payload.get("mode", "direct")
        if mode not in {"direct", "developmental"}:
            self._send_json(
                {"error": "mode must be direct or developmental"}, status=400
            )
            return
        request = {
            "operation": operation,
            "a": payload["a"],
            "b": payload["b"],
            "limit": limit,
            "mode": mode,
        }
        try:
            result = self.ctx.worker_request("compute", **request)
        except worker.PersistentPrologError as exc:
            self._send_json({"error": str(exc)}, status=500)
            return
        self._send_json(result)

    def _handle_learner_knowledge(self) -> None:
        try:
            result = self.ctx.worker_request("knowledge")
        except worker.PersistentPrologError as exc:
            self._send_json({"error": str(exc)}, status=500)
            return
        self._send_json(result)

    def _handle_visualize_coordination(self, query: str) -> None:
        params = urllib.parse.parse_qs(query, keep_blank_values=True)
        try:
            base = self._query_integer(params, "base", 10)
            val_up = self._query_integer(params, "val_up", 0)
        except ValueError as exc:
            self._send_json({"error": str(exc)}, status=400)
            return
        if not 2 <= base <= 15:
            self._send_json({"error": "base must be between 2 and 15"}, status=400)
            return
        if val_up < 0:
            self._send_json({"error": "val_up must be non-negative"}, status=400)
            return
        val_down = params.get("val_down", ["1"])[-1]
        if "/" in val_down:
            pieces = val_down.split("/")
            try:
                if len(pieces) != 2:
                    raise ValueError
                int(pieces[0])
                denominator = int(pieces[1])
            except ValueError:
                self._send_json(
                    {"error": "val_down fractions must have integer numerator and denominator"},
                    status=400,
                )
                return
            if denominator == 0:
                self._send_json(
                    {"error": "val_down denominator must be non-zero"}, status=400
                )
                return
        try:
            result = self.ctx.worker_request(
                "visualize_coordination",
                base=base,
                val_up=val_up,
                val_down=val_down,
            )
        except worker.PersistentPrologError as exc:
            self._send_json({"error": str(exc)}, status=500)
            return
        self._send_utf8(result["svg"], "image/svg+xml; charset=utf-8")

    def _handle_learner_reorganize(self, query: str) -> None:
        params = urllib.parse.parse_qs(query, keep_blank_values=True)
        domain = params.get("domain", ["fraction_splitting"])[-1]
        if domain not in {
            "fraction_splitting", "fraction_improper",
            "fraction_of_fraction", "fraction_algebra",
        }:
            self._send_json({"error": "unknown reorganization domain"}, status=400)
            return
        try:
            request = {
                "domain": domain,
                "a": self._query_integer(params, "a", 3),
                "b": self._query_integer(params, "b", 8),
                "c": self._query_integer(params, "c", 4),
                "d": self._query_integer(params, "d", 5),
            }
        except ValueError as exc:
            self._send_json({"error": str(exc)}, status=400)
            return
        try:
            result = self.ctx.worker_request("reorganize", **request)
        except worker.PersistentPrologError as exc:
            self._send_json(
                {"error": True, "message": str(exc), "domain": domain}, status=500
            )
            return
        self._send_json(result)

    def _handle_learner_reset(self, payload: object) -> None:
        if not isinstance(payload, dict):
            self._send_json({"error": "request body must be a JSON object"}, status=400)
            return
        try:
            result = self.ctx.worker_request("learner_reset")
        except worker.PersistentPrologError as exc:
            self._send_json({"error": str(exc)}, status=500)
            return
        self._send_json(result)

    @staticmethod
    def _query_integer(params: dict[str, list[str]], key: str, default: int) -> int:
        values = params.get(key)
        if not values:
            return default
        try:
            return int(values[-1])
        except (TypeError, ValueError) as exc:
            raise ValueError(f"{key} must be an integer") from exc

    def _handle_analyze(self, payload: dict) -> None:
        """Ingest -> domain-general discourse layer -> signal-gated router ->
        student-level, capped, provenance-labelled pairing. Local and model-free."""
        from hermes.app.analysis import discourse, event_importer, ingest, router
        raw = payload.get("transcript")
        if raw is None:
            raw = payload.get("text") or payload.get("events")
        if raw is None:
            self._send_json({"error": "transcript, text, or events required"}, status=400)
            return
        if isinstance(raw, (list, dict)):
            try:
                events = event_importer.events_from_payload(raw)
            except ValueError as exc:
                self._send_json({"error": str(exc)}, status=400)
                return
            meta = {"format": "events", "event_count": len(events)}
        else:
            events, meta = ingest.ingest(str(raw))
        if not events:
            self._send_json(
                {"error": "no contributions parsed — use 'Speaker: text' lines (two or more speakers), "
                          "or paste a table with Speaker and text columns"},
                status=400,
            )
            return
        flag = ingest.implausible_speakers(events)
        top_n = int(payload.get("top_n") or 8)
        result = discourse.analyze_discourse(events, top_n=top_n, include_all=bool(payload.get("include_all")))
        # Signal-gated router: enrich + relabel as grounded when the domain is modelled.
        routing = router.route(events, force_mode=payload.get("force_mode"))
        if routing["mode"] == "grounded":
            result["pairs"] = router.enrich_pairs(result["pairs"], routing["by_student"])[:top_n]
            result["provenance"] = "grounded"
        result["routing"] = {k: routing[k] for k in ("mode", "grounding_score", "topics", "forced")}
        result["ingest"] = meta
        if flag["implausible"]:
            result["warning"] = flag["reason"]
        self._send_json(result)

    def _handle_set_key(self, payload: dict) -> None:
        key = str(payload.get("api_key") or "").strip()
        if not key.startswith("sk-"):
            self._send_json({"error": "expected a key starting with sk-"}, status=400)
            return
        self.ctx.runtime.mkdir(parents=True, exist_ok=True)
        env_path = self.ctx.runtime / ".env"
        env_path.write_text(f"REALLMS_API_KEY={key}\n", encoding="utf-8")
        os.environ["REALLMS_API_KEY"] = key
        self._send_json({"ok": True, "key_configured": True})

    def _handle_chat(self, payload: dict) -> None:
        message = str(payload.get("message") or "").strip()
        if not message:
            self._send_json({"error": "message is required"}, status=400)
            return
        if self._looks_like_discussion_transcript(message):
            self._send_json({
                "error": ("This looks like speaker-labeled discussion text. "
                          "Use the Discussion reports page (/discussions.html) — "
                          "it blinds the speakers locally before any model call "
                          "and returns a claim-by-claim report."),
                "error_type": "chat_transcript_safety",
            }, status=400)
            return
        scene = self._fraction_compare_scene_request(message)
        if scene is not None:
            result = self.ctx.worker_request("fraction_compare",
                                    kind=scene["kind"],
                                    a=scene["a"],
                                    b=scene["b"])
            self._send_json({
                "answer": f"Fraction-bars compare scene: {scene['url']}",
                "scene": scene,
                "result": result,
                "model": "offline-symbolic",
                "offline": True,
                "mode": self.ctx.services.gate.state.mode,
                "insecure": not (self.ctx.services.gate.state.mode == gate.CAMPUS and self.ctx.services.gate.state.verified),
            })
            return
        scene = self._chat_render_scene_request(message)
        if scene is not None:
            result = self.ctx.worker_request(scene["op"], **scene["payload"])
            self._send_json({
                "answer": f"Render scene: {scene['url']}",
                "scene": scene,
                "result": result,
                "model": "offline-symbolic",
                "offline": True,
                "mode": self.ctx.services.gate.state.mode,
                "insecure": not (self.ctx.services.gate.state.mode == gate.CAMPUS and self.ctx.services.gate.state.verified),
            })
            return
        # Retrieve symbolic facts FIRST, so the answer is grounded in the KB
        # (and so the UI can show what it was grounded in) — neuro-symbolic, not
        # a free-associating chatbot. Best-effort; chat still works ungrounded.
        grounding = self._ground_message(message)
        grounded = self._grounding_summary(grounding)
        key = llm.load_key(self.ctx.runtime)
        if key is None:
            # Offline fallback: the symbolic grounding IS the answer. No prose
            # model is imitated; the reply names its own boundary and carries
            # the key hint so the console can say how to enable prose.
            self._send_json({
                "answer": self._offline_chat_answer(grounded),
                "grounded": grounded,
                "model": "offline-symbolic",
                "offline": True,
                "key_hint": KEY_HINT,
                "mode": self.ctx.services.gate.state.mode,
                "insecure": not (self.ctx.services.gate.state.mode == gate.CAMPUS and self.ctx.services.gate.state.verified),
            })
            return
        ssl_ctx = self._ssl_ctx_for_mode()
        messages = [
            {"role": "system", "content": self.ctx.prompt("chat.md")},
            {"role": "user", "content": f"{message}\n\n{self._grounding_facts_block(grounding)}"},
        ]
        try:
            answer = llm.call_api_messages(
                messages, api_key=key, api_url=llm.resolve_api_url(),
                model=llm.resolve_model(), ssl_ctx=ssl_ctx, fail_on_error=False,
            )
        except Exception as exc:  # network / API failure -> clean 502, not 500
            self._send_json({"error": str(exc), "error_type": "reallms", "grounded": grounded}, status=502)
            return
        self._send_json({"answer": answer, "grounded": grounded, "model": llm.resolve_model(),
                         "mode": self.ctx.services.gate.state.mode, "insecure": not (self.ctx.services.gate.state.mode == gate.CAMPUS and self.ctx.services.gate.state.verified)})

    def _handle_transcript_report(self, payload: dict) -> None:
        """Discussion transcript -> teacher-legible two-pass report.

        Pipeline (scripts/talkmoves_two_pass.py, all logic tested there):
        blind speakers locally -> pass 1 math extraction (Gemma) -> Prolog
        adjudication of every typed claim -> deterministic mask -> pass 2
        posture read over the residue (Gemma) -> teacher_report. Two model
        calls total; the verdicts are computed, never generated.

        Offline path, symmetric with pml_score's `clauses` shortcut: a request
        that already carries `claims` (pass-1 claim objects) skips both model
        calls. The deterministic chain (blind -> adjudicate -> mask ->
        teacher_report) runs unchanged on the supplied claims; the posture
        section stays empty because pass 2 is a model read."""
        text = str(payload.get("text") or "").strip()
        if not text:
            self._send_json({"error": "text is required"}, status=400)
            return
        # Symmetric with pml_score's `clauses` shortcut: a non-empty `claims`
        # list selects the offline path; an absent or empty one falls through
        # to the two-pass model pipeline.
        claims_payload = payload.get("claims")
        offline_claims: list[dict] | None = None
        if claims_payload:
            if not (isinstance(claims_payload, list)
                    and all(isinstance(c, dict) for c in claims_payload)):
                self._send_json(
                    {"error": "claims must be a list of pass-1 claim objects"},
                    status=400,
                )
                return
            offline_claims = claims_payload
        key = llm.load_key(self.ctx.runtime)
        if key is None and offline_claims is None:
            self._send_json(
                {"error": ("The report's extraction and posture passes need "
                           "the model, and no REALLMS API key is set. A "
                           "request that supplies pre-extracted `claims` "
                           "runs the deterministic adjudication without a "
                           "key. " + KEY_HINT),
                 "error_type": "no_key"},
                status=503)
            return
        tp = self._two_pass_module()
        blinded, _aliases = tp.blind_transcript(text)
        if not blinded.strip():
            self._send_json({"error": ("No speaker lines found. Paste "
                                       "'Speaker: utterance' lines, or a "
                                       "CSV/TSV where one column names the "
                                       "speaker and one holds what they "
                                       "said (most header names are "
                                       "recognized; a headerless "
                                       "speaker,text table works too).")},
                            status=400)
            return
        scorer = tp._load_scorer()
        numbered, _ = scorer.number_transcript(blinded)
        transcript_id = str(payload.get("transcript_id") or "pasted")
        if offline_claims is not None:
            # Symbolic-only report: Prolog adjudicates the supplied claims and
            # the deterministic mask and report run as usual. No model call.
            extractions = tp.adjudicate_claims(offline_claims)
            mask_result = tp.mask_transcript(numbered, extractions)
            report = tp.teacher_report(transcript_id, extractions, [],
                                       numbered, mask_result=mask_result)
            self._send_json({"ok": True, "report": report,
                             "offline": True, "model": "offline-symbolic"})
            return
        ssl_ctx = self._ssl_ctx_for_mode()

        def call(system: str, user: str) -> str:
            return llm.call_api_messages(
                [{"role": "system", "content": system},
                 {"role": "user", "content": user}],
                api_key=key, api_url=llm.resolve_api_url(),
                model=llm.resolve_model(), ssl_ctx=ssl_ctx,
                fail_on_error=False,
            )

        def json_after(reply: str, heading: str) -> dict:
            start = reply.find("{", max(reply.find(heading), 0))
            if start < 0:
                raise ValueError(f"the model reply contained no {heading} block")
            try:
                return json.loads(reply[start:reply.rfind("}") + 1])
            except json.JSONDecodeError as exc:
                raise ValueError(
                    f"the model's {heading} block was not valid JSON ({exc})"
                ) from exc

        try:
            reply1 = call(tp.PASS1_PROMPT_PATH.read_text(encoding="utf-8"),
                          tp.build_pass1_user_content(transcript_id, numbered))
            math_json = json_after(reply1, "## MATH_JSON")
            extractions = tp.adjudicate_claims(math_json.get("claims", []))
            mask_result = tp.mask_transcript(numbered, extractions)
            reply2 = call(tp.PASS2_PROMPT_PATH.read_text(encoding="utf-8"),
                          tp.build_pass2_user_content(
                              transcript_id, mask_result,
                              variant="hard_mask"))
            pml_json = json_after(reply2, "## PML_JSON")
            readings = pml_json.get("readings", [])
        except Exception as exc:  # noqa: BLE001 — surface, don't crash
            self._send_json({"error": f"report failed: {exc}",
                             "error_type": "transcript_report_failed"},
                            status=502)
            return
        report = tp.teacher_report(transcript_id, extractions, readings,
                                   numbered, mask_result=mask_result)
        self._send_json({"ok": True, "report": report})

    def _handle_media_transcribe(self, payload: dict) -> None:
        """One uploaded artifact -> a proposed transcript and optional timing.

        Gemma proposes the transcript. For audio, Prolog validates the timed
        segment structure without interpreting the discussion. The teacher
        reviews (and can edit) the proposal in the composer, and the
        report pipeline then blinds and adjudicates it exactly as pasted
        text. Pasted text never reaches the model unblinded; an image or a
        recording necessarily does, because transcription is the first read.
        Audio segment bounds pass through Prolog shape validation and remain an
        unreviewed model proposal; the response names that boundary."""
        from hermes.app.analysis import media

        name = str(payload.get("name") or "upload")
        raw_b64 = str(payload.get("data_b64") or "")
        if "," in raw_b64 and raw_b64.lstrip().startswith("data:"):
            raw_b64 = raw_b64.split(",", 1)[1]
        if not raw_b64.strip():
            self._send_json({"error": "data_b64 is required (base64 file content)"},
                            status=400)
            return
        try:
            data = base64.b64decode(raw_b64, validate=True)
        except (ValueError, binascii.Error):
            self._send_json({"error": "data_b64 is not valid base64"}, status=400)
            return
        key = llm.load_key(self.ctx.runtime)
        if key is None:
            # Honest 503: reading an image or a recording is the model's first
            # pass, and there is no symbolic substitute for it. Name what
            # still works without a key alongside the remedy.
            self._send_json(
                {"error": ("Transcribing an upload needs the model, and no "
                           "REALLMS API key is set. Pasted-text analysis and "
                           "reports still work without one. " + KEY_HINT),
                 "error_type": "no_key"},
                status=503)
            return
        notes: list[str] = []
        parts, render = media.parts_for_upload(
            name, str(payload.get("mime") or ""), data, notes)
        if not parts:
            self._send_json({"error": f"could not read {name} ({render})",
                             "error_type": "unreadable_upload",
                             "notes": notes}, status=422)
            return
        timed_audio = media.has_audio(parts)
        prompt_name = "transcribe_timed.md" if timed_audio else "transcribe.md"
        system = self.ctx.prompt(prompt_name)
        content = [{"type": "text", "text": f"FILE: {name}"}] + parts
        ssl_ctx = self._ssl_ctx_for_mode()

        def call(user_content: list) -> str:
            return llm.call_api_messages(
                [{"role": "system", "content": system},
                 {"role": "user", "content": user_content}],
                api_key=key, api_url=llm.resolve_api_url(),
                model=llm.resolve_model(), ssl_ctx=ssl_ctx, fail_on_error=False,
            )

        try:
            reply = call(content)
        except Exception as exc:  # noqa: BLE001 — surface, don't crash
            # Some OpenAI-compatible servers take audio only in the
            # audio_url data-URI shape; retry once in that form before
            # reporting the failure.
            if media.has_audio(parts) and "HTTP 4" in str(exc):
                try:
                    reply = call([content[0]] + media.audio_parts_as_urls(parts))
                    notes.append("audio accepted in audio_url form after input_audio was refused")
                except Exception as retry_exc:  # noqa: BLE001
                    self._send_json({"error": str(retry_exc), "error_type": "reallms",
                                     "notes": notes}, status=502)
                    return
            else:
                self._send_json({"error": str(exc), "error_type": "reallms",
                                 "notes": notes}, status=502)
                return
        alignment = None
        if timed_audio:
            try:
                segments = media.timed_segments_from_reply(reply)
                alignment = self.ctx.worker_request(
                    "media_alignment",
                    segments=segments,
                    source=f"reallms_audio_alignment:{llm.resolve_model()}",
                )
            except (ValueError, worker.PersistentPrologError) as exc:
                self._send_json({
                    "error": f"timed transcription failed validation: {exc}",
                    "error_type": "media_alignment_failed",
                    "notes": notes,
                }, status=502)
                return
            transcript = alignment["transcript"]
            notes.append(
                "audio timestamps are a model proposal validated for shape by Prolog; review them against the recording before discourse analysis")
        else:
            transcript = re.sub(r"^```[a-z]*\n|\n```$", "", reply.strip())
        self._send_json({
            "ok": True,
            "transcript": transcript,
            "render": render,
            "notes": notes,
            "model": llm.resolve_model(),
            "alignment": alignment,
            "privacy": ("The uploaded file itself was sent to REALLMS for "
                        "transcription; review the transcript before building "
                        "a report. Report passes blind the speakers locally."),
        })

    def _handle_pml_score(self, payload: dict) -> None:
        """Neuro-symbolic loop: Gemma encodes the text as PML reader_axiom/4 facts;
        the Prolog worker SAFELY parses, validates against the 12 operators, and
        scores them. The model emits the symbolic axioms; swipl is the judge.

        Offline path: a request that already carries `clauses` (reader_axiom/4
        or passage_mode/3 strings) skips the model entirely — the worker scores
        them whether or not a key is configured. The neural side proposes;
        here the caller has already proposed, so only the symbolic judge runs."""
        clauses_payload = payload.get("clauses")
        if clauses_payload:
            if not (isinstance(clauses_payload, list)
                    and all(isinstance(c, str) and c.strip() for c in clauses_payload)):
                self._send_json(
                    {"error": "clauses must be a list of non-empty Prolog clause strings"},
                    status=400,
                )
                return
            clauses = [c.strip().rstrip(".") for c in clauses_payload]
            result = self.ctx.worker_request("pml_score", clauses=clauses)
            self._send_json({"ok": True, "clauses": clauses, "result": result,
                             "offline": True, "model": "offline-symbolic"})
            return
        text = str(payload.get("text") or "").strip()
        if not text:
            self._send_json({"error": "text is required"}, status=400)
            return
        key = llm.load_key(self.ctx.runtime)
        if key is None:
            self._send_json({"error": KEY_HINT, "error_type": "no_key"}, status=503)
            return
        ssl_ctx = self._ssl_ctx_for_mode()
        messages = [
            {"role": "system", "content": self.ctx.prompt("pml_reader.md")},
            {"role": "user", "content": text},
        ]
        try:
            raw = llm.call_api_messages(
                messages, api_key=key, api_url=llm.resolve_api_url(),
                model=llm.resolve_model(), ssl_ctx=ssl_ctx, fail_on_error=False,
            )
        except Exception as exc:
            self._send_json({"error": str(exc), "error_type": "reallms"}, status=502)
            return
        clauses = self._extract_pml_clauses(raw)
        if not clauses:
            self._send_json(
                {
                    "error": "model output did not contain reader_axiom/4 or passage_mode/3 clauses",
                    "error_type": "no_pml_clauses",
                    "raw": raw,
                },
                status=422,
            )
            return
        result = self.ctx.worker_request("pml_score", clauses=clauses)
        self._send_json({"ok": True, "text": text, "result": result, "raw": raw,
                         "model": llm.resolve_model()})

    def _handle_expressive_power(self, payload: dict) -> None:
        lesson = payload.get("lesson")
        if not lesson:
            self._send_json({"error": "lesson is required"}, status=400)
            return
        self._send_json({"ok": True, "result": self.ctx.worker_request("expressive_power", lesson=lesson)})

    def _handle_deontic_scorecard(self, payload: dict) -> None:
        # The deontic board for one ephemeral agent: seed `commitments` and
        # `entitlements` (lists of Prolog term strings), read back commitments,
        # entitlements, and incoherences. The signature incoherence is
        # commitment_without_entitlement — a move that is procedurally correct but
        # inferentially hollow; depositing the missing vocabulary clears it.
        commitments = payload.get("commitments") or []
        entitlements = payload.get("entitlements") or []
        if not isinstance(commitments, list) or not isinstance(entitlements, list):
            self._send_json({"error": "commitments and entitlements must be lists of term strings"}, status=400)
            return
        self._send_json({"ok": True, "result": self.ctx.worker_request(
            "deontic_scorecard",
            agent=str(payload.get("agent") or "scoreboard"),
            commitments=commitments,
            entitlements=entitlements,
        )})

    def _handle_crisis(self, payload: dict) -> None:
        commitments = payload.get("commitments") or []
        entitlements = payload.get("entitlements") or []
        if not isinstance(commitments, list) or not isinstance(entitlements, list):
            self._send_json({"error": "commitments and entitlements must be lists of term strings"}, status=400)
            return
        self._send_json({"ok": True, "result": self.ctx.worker_request(
            "deontic_crisis",
            agent=str(payload.get("agent") or "scoreboard"),
            commitments=commitments,
            entitlements=entitlements,
        )})

    def _handle_deontic_consequences(self, payload: dict) -> None:
        # What a set of `commitments` (a list of Prolog term strings) materially
        # commits the agent to: the one-step consequence of every commitment in
        # the closure, each carrying the witness that records which rule or MUA
        # mechanism licensed it. An agent committed to the area-model practice is
        # thereby committed to the cross-multiplication result — entitlement
        # carried, not procedural recall.
        commitments = payload.get("commitments") or []
        if not isinstance(commitments, list):
            self._send_json({"error": "commitments must be a list of term strings"}, status=400)
            return
        self._send_json({"ok": True, "result": self.ctx.worker_request(
            "deontic_consequences",
            agent=str(payload.get("agent") or "scoreboard"),
            commitments=commitments,
        )})

    def _handle_deontic_up_level(self, payload: dict) -> None:
        # The objectivation move. For each commitment_without_entitlement that
        # survives the within-level closure, the witness lifts the gap into a new
        # object of discourse one level up ("talking about talking"). The
        # witness's `erasure` field marks what the formalism does not supply; a
        # coherent or within-level-dischargeable board returns an empty list. The
        # board names the break and the move past it; it does not close it.
        commitments = payload.get("commitments") or []
        if not isinstance(commitments, list):
            self._send_json({"error": "commitments must be a list of term strings"}, status=400)
            return
        self._send_json({"ok": True, "result": self.ctx.worker_request(
            "deontic_up_level",
            agent=str(payload.get("agent") or "scoreboard"),
            commitments=commitments,
        )})

    def _handle_deontic_requires_entitlement(self, payload: dict) -> None:
        # Single-proposition lookup: does this proposition require an entitlement
        # the agent has to earn (an LX-elaboration in the MUA graph), and what
        # source licenses that requirement? Distinct from the full board above.
        proposition = payload.get("proposition")
        if not proposition:
            self._send_json({"error": "proposition is required"}, status=400)
            return
        self._send_json({"ok": True, "result": self.ctx.worker_request(
            "deontic_requires_entitlement", proposition=proposition,
        )})

    def _handle_sequent_proof(self, payload: dict) -> None:
        # A sequent witness from the embodied prover. Where the proof goes
        # through, the witness records it; where the source is trace-tainted the
        # engine returns erasure(...) — the boundary, made operable, where formal
        # proof goes hollow and human judgment has to take over.
        sequent = payload.get("sequent")
        source = payload.get("source")
        if not sequent or not source:
            self._send_json({"error": "sequent and source are required"}, status=400)
            return
        self._send_json({"ok": True, "result": self.ctx.worker_request(
            "sequent_proof_witness", sequent=sequent, source=source,
        )})

    def _handle_pair_graph(self, payload: dict) -> None:
        from hermes.app.analysis import event_importer

        events = payload.get("events")
        if not isinstance(events, list):
            self._send_json({"error": "events list is required"}, status=400)
            return
        try:
            event_importer.assert_pair_graph_safe(events)
        except ValueError as exc:
            self._send_json(
                {"error": str(exc), "error_type": "unsafe_event_payload"},
                status=400,
            )
            return
        self._send_json({
            "pairs": self.ctx.worker_request("pair_score", events=events),
            "graph": self.ctx.worker_request("pair_graph", events=events),
        })

    def _handle_strategies(self, _payload: dict) -> None:
        self._send_json({"ok": True, "result": self.ctx.worker_request("list_strategies")})

    def _handle_fraction_frames(self, raw_path: str) -> None:
        """Lay out a fraction automaton as bars (v2 frames). Returns the frame
        document at the top level so the viewer's live mode can fetch it directly
        (it reads doc.frames / doc.productive.frames). Public KB; no student data."""
        url = urllib.parse.urlparse(raw_path)
        q = urllib.parse.parse_qs(url.query)
        kind = (q.get("kind") or [""])[0].strip()
        if not kind:
            self._send_json({"error": "kind is required"}, status=400)
            return

        def _int(name: str, default: int) -> int:
            try:
                return int((q.get(name) or [str(default)])[0])
            except (TypeError, ValueError):
                return default

        if url.path.endswith("/compare"):
            result = self.ctx.worker_request("fraction_compare", kind=kind,
                                    a=_int("a", _int("n", 5)), b=_int("b", _int("d", 3)))
        else:
            result = self.ctx.worker_request("fraction_render", kind=kind,
                                    n=_int("n", 5), d=_int("d", 3))
        self._send_json(result)

    def _handle_render(self, payload: dict) -> None:
        """Generic render bridge. The unified drawer (more-zeeman/render/drawer.js)
        POSTs {op, ...inputs} here; forward to the worker op and return its render
        document. Whitelisted ops only — this is a public KB surface, no student
        data. Lets every visualizer page draw against this same origin."""
        allowed = {
            "fraction_render", "fraction_compare", "area_render", "area_compare",
            "base_ten_render", "ace_of_bases_render", "base_ten_compare", "set_grouping_render",
            "unit_echo_render",
            "set_grouping_compare", "number_line_render", "number_line_compare",
            "place_value_chart_render", "hybridization_render",
            "balance_render", "balance_compare", "teacher_layer",
            "strategy_trace",
        }
        op = str(payload.get("op") or "").strip()
        if op not in allowed:
            self._send_json(
                {"ok": False, "error": f"unknown render op: {op or '(none)'}"},
                status=400,
            )
            return
        kwargs = {k: v for k, v in payload.items() if k != "op"}
        try:
            result = self.ctx.worker_request(op, **kwargs)
        except Exception as exc:  # noqa: BLE001
            # A worker-side op error (ok:false) or a transport failure. Return a
            # shape the drawer can reason about rather than a bare 500 body.
            self._send_json({"ok": False, "error": str(exc)}, status=400)
            return
        from hermes.app.routes.worker import validate_render_response

        validation_error = validate_render_response(result)
        if validation_error is not None:
            self._send_json(
                {
                    "ok": False,
                    "error": (
                        f"the {op} op returned a non-drawable render document: "
                        f"{validation_error}"
                    ),
                },
                status=400,
            )
            return
        self._send_json(result)

    def _handle_witness(self, family: str, payload: dict) -> None:
        """Forward one allowlisted witness request to the symbolic worker."""
        allowed = WITNESS_OPS.get(family, frozenset())
        op = str(payload.get("op") or "").strip()
        if op not in allowed:
            self._send_json(
                {"ok": False, "error": f"unknown {family} witness op: {op or '(none)'}"},
                status=400,
            )
            return
        kwargs = {key: value for key, value in payload.items() if key != "op"}
        try:
            result = self.ctx.worker_request(op, **kwargs)
        except Exception as exc:  # noqa: BLE001
            self._send_json({"ok": False, "error": str(exc)}, status=400)
            return
        self._send_json({"ok": True, "op": op, "result": result})

    def _handle_strategy_trace(self, payload: dict) -> None:
        strategy = str(payload.get("strategy") or "").strip()
        if not strategy:
            self._send_json({"error": "strategy is required"}, status=400)
            return
        inp = payload.get("input")
        kwargs = {"strategy": strategy}
        if isinstance(inp, dict):
            kwargs["input"] = inp
        self._send_json({"ok": True, "result": self.ctx.worker_request("strategy_trace", **kwargs)})

    def _handle_literature(self, payload: dict) -> None:
        # Public: literature-derived incompatibility analyses (student_rule /
        # valid_domain / incompatible_with triples with citations). No student data.
        query = str(payload.get("query") or "").strip()
        if not query:
            self._send_json({"ok": False, "error": "literature requires query"}, status=400)
            return
        self._send_json({"ok": True, "result": self.ctx.worker_request("lit_search", query=query)})

    def _handle_misconceptions(self, payload: dict) -> None:
        kwargs = {}
        domain = str(payload.get("domain") or "").strip()
        if domain:
            kwargs["domain"] = domain
        self._send_json({"ok": True, "result": self.ctx.worker_request("list_misconceptions", **kwargs)})

    def _handle_standards(self, payload: dict) -> None:
        kwargs = {}
        framework = str(payload.get("framework") or "").strip()
        if framework:
            kwargs["framework"] = framework
        self._send_json({"ok": True, "result": self.ctx.worker_request("list_standards", **kwargs)})

    def _handle_grounding(self, payload: dict) -> None:
        operation = str(payload.get("operation") or "").strip()
        if operation:
            result = self.ctx.worker_request("grounding_for", operation=operation)
        else:
            result = self.ctx.worker_request("grounding_metaphors")
        self._send_json({"ok": True, "result": result})

    def _handle_geometry(self, payload: dict) -> None:
        predicate = str(payload.get("predicate") or "").strip()
        args = payload.get("args")
        if not predicate or not isinstance(args, list):
            self._send_json(
                {"error": "geometry requires predicate and args list"},
                status=400,
            )
            return
        self._send_json({
            "ok": True,
            "result": self.ctx.worker_request("geometry", predicate=predicate, args=args),
        })

    def _handle_canonical_contract(self, _payload: dict) -> None:
        # Public: the legal-vocabulary contract (canonical query predicates and
        # the scattered legacy functors each subsumes). No student data.
        self._send_json({"ok": True, "result": self.ctx.worker_request("canonical_contract")})

    def _handle_canonical_check(self, payload: dict) -> None:
        # Judge a list of functor-name strings against the legal vocabulary:
        # each is classified canonical | legacy | unknown.
        terms = payload.get("terms") or []
        self._send_json({"ok": True, "result": self.ctx.worker_request("canonical_check", terms=terms)})

    def _handle_diagnose_error(self, payload: dict) -> None:
        domain = str(payload.get("domain") or "").strip()
        if not domain:
            self._send_json({"error": "domain is required"}, status=400)
            return
        # input/got pass through json_to_term in the worker, so the UI may send
        # plain values (e.g. "1/2 + 1/3", "2/5") and the worker term-parses them.
        self._send_json({"ok": True, "result": self.ctx.worker_request(
            "diagnose_error", domain=domain,
            input=str(payload.get("input") or ""),
            got=str(payload.get("got") or ""))})

    def _handle_query_misconception(self, payload: dict) -> None:
        kwargs = {}
        for key in ("domain", "description", "source"):
            val = str(payload.get(key) or "").strip()
            if val:
                kwargs[key] = val
        self._send_json({"ok": True, "result": self.ctx.worker_request("query_misconception", **kwargs)})

    def _handle_event_score(self, payload: dict) -> None:
        from hermes.app.analysis import event_importer

        raw = (
            payload.get("events")
            if "events" in payload
            else payload.get("event", payload.get("transcript", payload))
        )
        try:
            events = event_importer.worker_events_from_payload(raw)
        except ValueError as exc:
            self._send_json(
                {"error": str(exc), "error_type": "unsafe_event_payload"},
                status=400,
            )
            return
        if not events:
            self._send_json(
                {
                    "ok": False,
                    "error": "no scoreable events after pseudonymization",
                    "error_type": "quarantined_no_scoreable_events",
                },
                status=422,
            )
            return
        if len(events) == 1 and "event" in payload and "events" not in payload:
            self._send_json({"ok": True, "result": self.ctx.worker_request("event_score", event=events[0])})
            return
        self._send_json({"ok": True, "result": self.ctx.worker_request("batch_event_score", events=events)})

    def _handle_notation_render(self, payload: dict) -> None:
        # Symbol-level representation language: `kind` selects the lane
        # (write_equation productive, mirror_written deformation); a/b/r are the
        # operands and result, `operator` the symbol (+, -, =). The worker
        # supplies defaults, so only kind is required here.
        kind = str(payload.get("kind") or "").strip()
        if not kind:
            self._send_json({"error": "kind is required"}, status=400)
            return
        kwargs: dict[str, Any] = {"kind": kind}
        for key in ("a", "b", "r", "operator"):
            if payload.get(key) is not None:
                kwargs[key] = payload[key]
        self._send_json({"ok": True, "result": self.ctx.worker_request("notation_render", **kwargs)})

    def _handle_fraction_cgi_addition(self, payload: dict) -> None:
        # A CGI addition automaton over a shared denominator: `kind` names the
        # automaton, na/nb are the numerators, d the common denominator. The
        # worker carries defaults, so only kind is required.
        kind = str(payload.get("kind") or "").strip()
        if not kind:
            self._send_json({"error": "kind is required"}, status=400)
            return
        kwargs: dict[str, Any] = {"kind": kind}
        for key in ("na", "nb", "d"):
            if payload.get(key) is not None:
                kwargs[key] = payload[key]
        self._send_json({"ok": True, "result": self.ctx.worker_request("fraction_cgi_addition", **kwargs)})

    def _handle_lesson_deformation_chart(self, payload: dict) -> None:
        # The deformation monitoring chart for one lesson code. Covers the three
        # grade-3 IM fraction lessons; out-of-coverage codes return a clear
        # coverage error from the worker.
        code = str(payload.get("code") or payload.get("lesson_code") or "").strip()
        if not code:
            self._send_json({"error": "code is required"}, status=400)
            return
        self._send_json({"ok": True, "result": self.ctx.worker_request("lesson_deformation_chart", code=code)})

    def _handle_notation_monitoring_chart(self, payload: dict) -> None:
        # The notation monitoring chart for one lesson code (183 K/G1 lessons).
        # Out-of-coverage codes return a clear coverage error from the worker.
        code = str(payload.get("code") or payload.get("lesson_code") or "").strip()
        if not code:
            self._send_json({"error": "code is required"}, status=400)
            return
        self._send_json({"ok": True, "result": self.ctx.worker_request("notation_monitoring_chart", code=code)})

    def _handle_brandom_backstop(self, _payload: dict) -> None:
        # The Brandomian backstop audit: the per-check report and the all-pass
        # flag for the data-driven incompatibility relation. Public KB surface;
        # no student data.
        self._send_json({"ok": True, "result": self.ctx.worker_request("brandom_backstop")})

    def _handle_brandomian_check(self, payload: dict) -> None:
        # One commitment set (a list of Prolog term strings) checked against the
        # declared incompatibility hyperedges: the union incoherence verdict
        # (hyperedge first, classical neg-pair floor second, with the firing
        # witness), the incompatibility-entailment pairs that hold inside the
        # set, an optional single `entails: {from, to}` query, and the classical
        # backstop verdict alongside.
        commitments = payload.get("commitments")
        if not isinstance(commitments, list) or not commitments:
            self._send_json(
                {"error": "commitments must be a non-empty list of term strings"},
                status=400,
            )
            return
        request: dict[str, Any] = {"commitments": commitments}
        entails = payload.get("entails")
        if isinstance(entails, dict) and entails.get("from") and entails.get("to"):
            request["entails"] = {"from": str(entails["from"]), "to": str(entails["to"])}
        self._send_json({"ok": True, "result": self.ctx.worker_request("brandomian_check", **request)})

    def _handle_hyperedges(self, payload: dict) -> None:
        # The discovered incompatibility hyperedges (Big Red discovery cache +
        # the canonical relation's declared size>=3 sets), each with its
        # computed emergence verdict. Optional `kind` filter (emergent /
        # defeated / incoherent / nonterminating / declared).
        request: dict[str, Any] = {}
        kind = str(payload.get("kind") or "").strip()
        if kind:
            request["kind"] = kind
        self._send_json({"ok": True, "result": self.ctx.worker_request("hyperedges", **request)})

    def _handle_axiom_toggle(self, payload: dict) -> None:
        # Runtime axiom toggling: action=list enumerates every toggle with its
        # state; enable/disable require `axiom` (a toggle term string such as
        # "pack(eml)"). Only these three actions exist on this surface, so any
        # disable stays inspectable and reversible from the same console.
        action = str(payload.get("action") or "list").strip()
        request: dict[str, Any] = {"action": action}
        axiom = str(payload.get("axiom") or "").strip()
        if axiom:
            request["axiom"] = axiom
        self._send_json({"ok": True, "result": self.ctx.worker_request("axiom_toggle", **request)})

    def _handle_carving_strategy_proof(self, payload: dict) -> None:
        # An on-demand proof entitlement for one arithmetic fact: `operation`
        # plus operands x, y and result z. Facts without a carving proof return a
        # no_carving_proof error from the worker.
        operation = str(payload.get("operation") or "").strip()
        if not operation:
            self._send_json({"error": "operation is required"}, status=400)
            return
        if any(payload.get(k) is None for k in ("x", "y", "z")):
            self._send_json({"error": "x, y, and z are required"}, status=400)
            return
        self._send_json({"ok": True, "result": self.ctx.worker_request(
            "carving_strategy_proof",
            operation=operation,
            x=payload["x"], y=payload["y"], z=payload["z"],
        )})

    def _handle_carving_operation_summary(self, payload: dict) -> None:
        # Carved-fact count and residue for one `operation` — how much of the
        # table the carving covers and what it leaves uncarved.
        operation = str(payload.get("operation") or "").strip()
        if not operation:
            self._send_json({"error": "operation is required"}, status=400)
            return
        self._send_json({"ok": True, "result": self.ctx.worker_request(
            "carving_operation_summary", operation=operation,
        )})

    def _handle_benny_demo(self, _payload: dict) -> None:
        # Public: Benny's rule deformations run side by side with their correct
        # coordinated counterparts on the same inputs. No student data, no FERPA
        # gate (like the rest of the encyclopedia surfaces).
        self._send_json({"ok": True, "result": self.ctx.worker_request("benny_demo")})

    def _handle_capabilities(self) -> None:
        self._send_json(self.ctx.worker_request("capability_atlas"))
