"""N103 Hermes: deterministic geometry discussion pairing.

This is the short-path Hermes runtime for May 2026: consume forum posts or
Zoom transcript text, surface geometry misconception/paradox signals, and
recommend instructor-reviewable student pairs.

The module is intentionally model-free. RealLMS/Open WebUI can still sit
around it as the prose layer, but the auditable decision about why two
students were paired should not depend on an opaque chat completion.
"""
from __future__ import annotations

import csv
import itertools
import json
import re
from collections import Counter
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Iterable, Sequence


TEXT_KEYS = ("text", "body", "message", "content", "transcript")
STUDENT_KEYS = ("student", "name", "user", "author", "speaker", "display_name")


@dataclass(frozen=True)
class HermesEvent:
    student: str
    text: str
    source: str = ""
    timestamp: str = ""
    event_id: str = ""

    def as_dict(self) -> dict:
        return asdict(self)


@dataclass(frozen=True)
class SignalRule:
    code: str
    family: str  # misconception | paradox
    label: str
    topic: str
    weight: float
    phrases: tuple[str, ...] = ()
    patterns: tuple[str, ...] = ()
    question_focus: str = ""


@dataclass(frozen=True)
class Signal:
    code: str
    family: str
    label: str
    topic: str
    evidence: str
    weight: float
    question_focus: str = ""

    def as_dict(self) -> dict:
        return asdict(self)


@dataclass(frozen=True)
class Stance:
    mode: str
    polarity: str
    evidence: tuple[str, ...] = ()

    def as_dict(self) -> dict:
        return asdict(self)


@dataclass(frozen=True)
class ContributionAnalysis:
    event: HermesEvent
    signals: tuple[Signal, ...]
    stance: Stance

    def as_dict(self) -> dict:
        return {
            "event": self.event.as_dict(),
            "signals": [s.as_dict() for s in self.signals],
            "stance": self.stance.as_dict(),
        }


@dataclass
class StudentProfile:
    student: str
    contributions: list[ContributionAnalysis] = field(default_factory=list)
    signal_counts: Counter = field(default_factory=Counter)
    topic_counts: Counter = field(default_factory=Counter)
    family_counts: Counter = field(default_factory=Counter)
    mode_counts: Counter = field(default_factory=Counter)
    polarity_counts: Counter = field(default_factory=Counter)

    def add(self, analysis: ContributionAnalysis) -> None:
        self.contributions.append(analysis)
        self.mode_counts[analysis.stance.mode] += 1
        self.polarity_counts[analysis.stance.polarity] += 1
        for signal in analysis.signals:
            self.signal_counts[signal.code] += 1
            self.topic_counts[signal.topic] += 1
            self.family_counts[signal.family] += 1

    @property
    def top_topics(self) -> tuple[str, ...]:
        return tuple(topic for topic, _ in self.topic_counts.most_common())

    @property
    def misconception_topics(self) -> set[str]:
        return {
            s.topic
            for c in self.contributions
            for s in c.signals
            if s.family == "misconception"
        }

    @property
    def paradox_topics(self) -> set[str]:
        return {
            s.topic
            for c in self.contributions
            for s in c.signals
            if s.family == "paradox"
        }

    @property
    def dominant_mode(self) -> str:
        return self.mode_counts.most_common(1)[0][0] if self.mode_counts else "unknown"

    @property
    def dominant_polarity(self) -> str:
        if not self.polarity_counts:
            return "unknown"
        return self.polarity_counts.most_common(1)[0][0]

    def best_evidence_for(self, topics: Iterable[str]) -> str:
        wanted = set(topics)
        for contribution in self.contributions:
            if any(signal.topic in wanted for signal in contribution.signals):
                return snippet(contribution.event.text)
        if self.contributions:
            return snippet(self.contributions[0].event.text)
        return ""

    def as_dict(self) -> dict:
        return {
            "student": self.student,
            "contribution_count": len(self.contributions),
            "signal_counts": dict(self.signal_counts),
            "topic_counts": dict(self.topic_counts),
            "family_counts": dict(self.family_counts),
            "mode_counts": dict(self.mode_counts),
            "polarity_counts": dict(self.polarity_counts),
            "dominant_mode": self.dominant_mode,
            "dominant_polarity": self.dominant_polarity,
            "contributions": [c.as_dict() for c in self.contributions],
        }


@dataclass(frozen=True)
class PairRecommendation:
    student_a: str
    student_b: str
    score: float
    topics: tuple[str, ...]
    reasons: tuple[str, ...]
    question: str
    evidence_a: str
    evidence_b: str

    def as_dict(self) -> dict:
        return asdict(self)


GEOMETRY_RULES: tuple[SignalRule, ...] = (
    SignalRule(
        code="square_not_rectangle",
        family="misconception",
        label="Square rejected as a rectangle",
        topic="inclusive_shape_hierarchy",
        weight=4.0,
        patterns=(
            r"\bsquare(s)?\b.{0,40}\b(not|isn't|is not|aren't|are not|cant|can't)\b.{0,30}\brectangle(s)?\b",
            r"\brectangle(s)?\b.{0,30}\bnot\b.{0,30}\bsquare(s)?\b",
        ),
        question_focus="whether class inclusion can hold without visual sameness",
    ),
    SignalRule(
        code="square_not_rhombus",
        family="misconception",
        label="Square rejected as a rhombus",
        topic="inclusive_shape_hierarchy",
        weight=3.5,
        patterns=(
            r"\bsquare(s)?\b.{0,40}\b(not|isn't|is not|aren't|are not|cant|can't)\b.{0,30}\brhombus(es)?\b",
            r"\brhombus(es)?\b.{0,30}\bnot\b.{0,30}\bsquare(s)?\b",
        ),
        question_focus="what properties a square inherits from a rhombus",
    ),
    SignalRule(
        code="rectangle_not_parallelogram",
        family="misconception",
        label="Rectangle rejected as a parallelogram",
        topic="inclusive_shape_hierarchy",
        weight=3.5,
        patterns=(
            r"\brectangle(s)?\b.{0,40}\b(not|isn't|is not|aren't|are not|cant|can't)\b.{0,30}\bparallelogram(s)?\b",
            r"\bparallelogram(s)?\b.{0,30}\bnot\b.{0,30}\brectangle(s)?\b",
        ),
        question_focus="whether right angles disqualify or specialize a parallelogram",
    ),
    SignalRule(
        code="quadrilateral_is_parallelogram",
        family="misconception",
        label="Every quadrilateral treated as a parallelogram",
        topic="inclusive_shape_hierarchy",
        weight=4.0,
        phrases=("every quadrilateral is a parallelogram", "all quadrilaterals are parallelograms"),
        patterns=(r"\bquadrilateral(s)?\b.{0,25}\b(all|always|every)\b.{0,35}\bparallelogram(s)?\b",),
        question_focus="which properties are necessary for a four-sided figure to be a parallelogram",
    ),
    SignalRule(
        code="parallelogram_is_rectangle",
        family="misconception",
        label="Parallelogram overclassified as a rectangle",
        topic="inclusive_shape_hierarchy",
        weight=3.5,
        phrases=("parallelograms are rectangles", "a parallelogram is a rectangle"),
        patterns=(r"\bparallelogram(s)?\b.{0,35}\b(is|are|counts as|count as)\b.{0,20}\brectangle(s)?\b",),
        question_focus="which extra conditions turn a parallelogram into a rectangle",
    ),
    SignalRule(
        code="prototype_orientation",
        family="misconception",
        label="Prototype or orientation controls the shape name",
        topic="prototype_vs_definition",
        weight=3.0,
        phrases=(
            "it is a diamond",
            "it's a diamond",
            "tilted square",
            "turned square",
            "not a square because it is tilted",
            "not a square because it is turned",
            "squares sit flat",
            "rectangle has to be long",
        ),
        patterns=(r"\b(square|rectangle)\b.{0,50}\b(tilted|turned|slanted|sideways|diamond|flat)\b",),
        question_focus="whether visual prototype or defining properties decide the name",
    ),
    SignalRule(
        code="measurement_taxonomy_confusion",
        family="misconception",
        label="Area, perimeter, angle, or length treated as the same kind of measure",
        topic="measure_vs_object",
        weight=3.0,
        phrases=(
            "area is the outside",
            "perimeter is the inside",
            "count the squares around",
            "bigger perimeter means bigger area",
            "same perimeter means same area",
            "same area means same perimeter",
            "longer sides means bigger area",
            "double the side doubles the area",
        ),
        patterns=(
            r"\b(area|perimeter)\b.{0,35}\b(same|bigger|larger|longer|outside|inside)\b.{0,35}\b(area|perimeter)\b",
        ),
        question_focus="what object is being measured, and by which unit",
    ),
    SignalRule(
        code="angle_length_confusion",
        family="misconception",
        label="Angle size coordinated with arm length or visual width",
        topic="angle_as_turn_vs_length",
        weight=3.0,
        phrases=(
            "longer sides make a bigger angle",
            "longer arms make a bigger angle",
            "angle is wider because the lines are longer",
            "the angle is the length",
            "angle is how long",
        ),
        patterns=(r"\bangle\b.{0,45}\b(longer|length|wide|wider|arm|arms|side|sides)\b",),
        question_focus="angle as turn/opening rather than side length",
    ),
    SignalRule(
        code="proof_from_appearance",
        family="misconception",
        label="Diagram appearance or measurement treated as proof",
        topic="diagram_vs_deduction",
        weight=3.0,
        phrases=(
            "it looks like",
            "looks equal",
            "looks parallel",
            "measure it with a ruler",
            "use a protractor to prove",
            "the picture proves",
            "because the diagram",
        ),
        patterns=(r"\b(looks|picture|diagram|measure|ruler|protractor)\b.{0,45}\b(proves|proof|must|always|equal|parallel)\b",),
        question_focus="what a diagram can suggest versus what a definition or theorem licenses",
    ),
    SignalRule(
        code="transformation_motion_confusion",
        family="misconception",
        label="Transformation understood only as physical motion",
        topic="motion_vs_invariance",
        weight=2.5,
        phrases=(
            "reflection means flip over",
            "rotation means move it",
            "translation means slide it to a new place",
            "it changes because it moved",
            "turning it makes a different shape",
        ),
        patterns=(r"\b(reflection|rotation|translation|turning|flipping|sliding)\b.{0,45}\b(move|moved|different|changes|new shape)\b",),
        question_focus="what changes and what stays invariant under a transformation",
    ),
    SignalRule(
        code="dimension_confusion",
        family="misconception",
        label="Two-dimensional and three-dimensional objects conflated",
        topic="dimension_boundary",
        weight=2.5,
        phrases=(
            "cube is a square",
            "a square is a cube",
            "triangle is a pyramid",
            "circle is a sphere",
            "face is the whole solid",
            "flat cube",
        ),
        patterns=(r"\b(cube|sphere|pyramid|solid)\b.{0,35}\b(square|circle|triangle|flat|face)\b",),
        question_focus="how faces, drawings, and solids relate without collapsing dimensions",
    ),
    SignalRule(
        code="partition_congruence_confusion",
        family="misconception",
        label="Equal area or equal parts require congruent-looking pieces",
        topic="same_difference",
        weight=2.5,
        phrases=(
            "equal parts have to look the same",
            "same area means same shape",
            "not equal because they look different",
            "fair shares have to be the same shape",
        ),
        patterns=(r"\b(equal|same|fair)\b.{0,35}\b(shape|look|congruent|piece|part)\b",),
        question_focus="when sameness is about measure, shape, or both",
    ),
    SignalRule(
        code="continuity_as_beads",
        family="misconception",
        label="Line or continuum treated as a finite necklace of points",
        topic="finite_vs_infinite",
        weight=2.5,
        phrases=(
            "line is made of dots",
            "segment is made of points like beads",
            "there are only so many points",
            "points next to each other",
            "last point before",
        ),
        patterns=(r"\b(line|segment)\b.{0,45}\b(dots|beads|points next|only so many|last point)\b",),
        question_focus="how a finite drawing can stand for continuous geometry",
    ),
    SignalRule(
        code="paradox_definition_image",
        family="paradox",
        label="Tension between image and definition",
        topic="prototype_vs_definition",
        weight=2.5,
        phrases=(
            "looks different but has the same properties",
            "what makes it still a square",
            "is it the picture or the definition",
            "the drawing changes but the properties do not",
            "property not appearance",
        ),
        patterns=(r"\b(looks|drawing|picture|image)\b.{0,45}\b(definition|properties|property|same)\b",),
        question_focus="the image/definition paradox",
    ),
    SignalRule(
        code="paradox_hierarchy",
        family="paradox",
        label="Tension between everyday categories and inclusive hierarchy",
        topic="inclusive_shape_hierarchy",
        weight=2.5,
        phrases=(
            "a square can be more than one shape",
            "both a square and a rectangle",
            "both rectangle and parallelogram",
            "exclusive in everyday language but inclusive in math",
            "when is a shape also another shape",
        ),
        patterns=(r"\b(square|rectangle|rhombus|parallelogram)\b.{0,35}\b(both|also|more than one|inclusive)\b",),
        question_focus="how one object can answer to multiple definitions",
    ),
    SignalRule(
        code="paradox_measure_object",
        family="paradox",
        label="Tension between object, boundary, and measure",
        topic="measure_vs_object",
        weight=2.5,
        phrases=(
            "area is not the shape itself",
            "perimeter is not the shape itself",
            "boundary versus region",
            "inside versus around",
            "what exactly are we measuring",
        ),
        patterns=(r"\b(area|perimeter|boundary|region|inside|around)\b.{0,45}\b(measuring|measure|object|shape itself)\b",),
        question_focus="the boundary/region/object paradox",
    ),
    SignalRule(
        code="paradox_diagram_proof",
        family="paradox",
        label="Tension between seeing and proving",
        topic="diagram_vs_deduction",
        weight=2.5,
        phrases=(
            "the diagram helps but does not prove",
            "seeing is not proving",
            "what can we trust in a diagram",
            "a picture can mislead",
            "need a reason beyond the picture",
        ),
        patterns=(r"\b(diagram|picture|seeing|looks)\b.{0,45}\b(prove|proving|reason|mislead|trust)\b",),
        question_focus="the seeing/proving paradox",
    ),
    SignalRule(
        code="paradox_motion_invariance",
        family="paradox",
        label="Tension between motion and invariance",
        topic="motion_vs_invariance",
        weight=2.5,
        phrases=(
            "moves but stays the same",
            "changes position but not shape",
            "what changes under a transformation",
            "invariant under rotation",
            "same after a reflection",
        ),
        patterns=(r"\b(move|moves|changes|transformation|rotation|reflection)\b.{0,50}\b(same|invariant|stays|preserved)\b",),
        question_focus="the motion/invariance paradox",
    ),
    SignalRule(
        code="paradox_dimension",
        family="paradox",
        label="Tension between representation and object",
        topic="dimension_boundary",
        weight=2.0,
        phrases=(
            "drawing of a cube is not a cube",
            "face of a solid",
            "flat picture of a solid",
            "representation versus object",
        ),
        patterns=(r"\b(drawing|picture|face|net|representation)\b.{0,45}\b(cube|solid|object|3d|three dimensional)\b",),
        question_focus="the representation/object paradox",
    ),
    SignalRule(
        code="paradox_finite_infinite",
        family="paradox",
        label="Tension between finite drawings and continuous objects",
        topic="finite_vs_infinite",
        weight=2.0,
        phrases=(
            "finite drawing of an infinite line",
            "segment has infinitely many points",
            "points have no length",
            "continuum",
        ),
        patterns=(r"\b(finite|infinite|infinitely|continuum|points have no length)\b",),
        question_focus="the finite/infinite paradox",
    ),
)


TOPIC_QUESTIONS = {
    "inclusive_shape_hierarchy": (
        "When can one shape genuinely count as another shape, and which "
        "properties license that inclusion?"
    ),
    "prototype_vs_definition": (
        "When a drawing fights a definition, which should control the name "
        "of the shape, and why?"
    ),
    "measure_vs_object": (
        "What exactly is being measured here: the object, its boundary, its "
        "region, or a property of it?"
    ),
    "angle_as_turn_vs_length": (
        "How can you tell whether angle size is about turn/opening rather "
        "than the length of the sides drawn?"
    ),
    "diagram_vs_deduction": (
        "What can a diagram let you notice, and what would still need a "
        "definition, theorem, or argument?"
    ),
    "motion_vs_invariance": (
        "In a transformation, what changes, what stays invariant, and how "
        "do you know?"
    ),
    "dimension_boundary": (
        "How can a drawing, face, net, or model represent a solid without "
        "becoming the same mathematical object?"
    ),
    "same_difference": (
        "When do two pieces need to be the same shape, and when is equal "
        "measure enough?"
    ),
    "finite_vs_infinite": (
        "How can a finite drawing or mark stand for a continuous geometric "
        "object?"
    ),
}


CONTRAST_SETS = (
    (
        {"square_not_rectangle", "square_not_rhombus", "rectangle_not_parallelogram"},
        {"quadrilateral_is_parallelogram", "parallelogram_is_rectangle"},
        "one contribution narrows a hierarchy too much while the other broadens it too much",
    ),
)


SUBJECTIVE_CUES = (
    "i think",
    "i feel",
    "i see",
    "i noticed",
    "i wonder",
    "my",
    "we thought",
    "we saw",
)
OBJECTIVE_CUES = (
    "because",
    "definition",
    "property",
    "properties",
    "the shape",
    "the diagram",
    "the angle",
    "the sides",
)
NORMATIVE_CUES = (
    "should",
    "must",
    "has to",
    "have to",
    "always",
    "never",
    "can't",
    "cannot",
    "counts as",
    "doesn't count",
    "not allowed",
)
COMPRESSIVE_CUES = (
    "always",
    "never",
    "only",
    "exactly",
    "must",
    "has to",
    "have to",
    "can't",
    "cannot",
    "definitely",
    "same as",
)
EXPANSIVE_CUES = (
    "could",
    "might",
    "maybe",
    "depends",
    "what if",
    "another way",
    "also",
    "both",
    "can be",
    "i wonder",
)


def load_events(path: str | Path) -> list[HermesEvent]:
    """Load events from JSON, CSV, or simple Zoom-style transcript text."""
    p = Path(path)
    suffix = p.suffix.lower()
    if suffix == ".json":
        return _load_json_events(p)
    if suffix == ".csv":
        return _load_csv_events(p)
    return _load_text_events(p)


def _load_json_events(path: Path) -> list[HermesEvent]:
    raw = json.loads(path.read_text())
    if isinstance(raw, dict):
        for key in ("events", "posts", "messages", "transcript"):
            if key in raw and isinstance(raw[key], list):
                raw = raw[key]
                break
    if not isinstance(raw, list):
        raise ValueError(f"{path} must contain a list or an object with events/posts/messages")
    return [_event_from_mapping(item, default_source=path.stem) for item in raw]


def _load_csv_events(path: Path) -> list[HermesEvent]:
    with path.open(newline="") as handle:
        reader = csv.DictReader(handle)
        return [_event_from_mapping(row, default_source=path.stem) for row in reader]


def _load_text_events(path: Path) -> list[HermesEvent]:
    events: list[HermesEvent] = []
    current: HermesEvent | None = None
    for idx, raw_line in enumerate(path.read_text().splitlines(), start=1):
        line = raw_line.strip()
        if not line:
            continue
        parsed = _parse_transcript_line(line, path.stem, str(idx))
        if parsed:
            events.append(parsed)
            current = parsed
        elif current:
            merged = HermesEvent(
                student=current.student,
                text=f"{current.text} {line}",
                source=current.source,
                timestamp=current.timestamp,
                event_id=current.event_id,
            )
            events[-1] = merged
            current = merged
    return events


def _event_from_mapping(item: dict, default_source: str) -> HermesEvent:
    if not isinstance(item, dict):
        raise ValueError(f"event rows must be objects, got {type(item).__name__}")
    student = _first_present(item, STUDENT_KEYS) or "Unknown"
    text = _first_present(item, TEXT_KEYS)
    if not text:
        raise ValueError(f"event for {student!r} has no text/body/message/content field")
    return HermesEvent(
        student=str(student).strip() or "Unknown",
        text=str(text).strip(),
        source=str(item.get("source") or item.get("channel") or default_source),
        timestamp=str(item.get("timestamp") or item.get("time") or ""),
        event_id=str(item.get("id") or item.get("event_id") or ""),
    )


def _first_present(item: dict, keys: Sequence[str]) -> object | None:
    for key in keys:
        if key in item and item[key] not in (None, ""):
            return item[key]
    return None


def _parse_transcript_line(line: str, source: str, event_id: str) -> HermesEvent | None:
    match = re.match(
        r"^(?:\[(?P<bracket_time>[^\]]+)\]\s*)?(?:(?P<plain_time>\d{1,2}:\d{2}(?::\d{2})?)\s+)?(?P<speaker>[^:]{1,80}):\s*(?P<text>.+)$",
        line,
    )
    if not match:
        return None
    timestamp = match.group("bracket_time") or match.group("plain_time") or ""
    return HermesEvent(
        student=match.group("speaker").strip(),
        text=match.group("text").strip(),
        source=source,
        timestamp=timestamp,
        event_id=event_id,
    )


def analyze_event(event: HermesEvent) -> ContributionAnalysis:
    text = normalize_text(event.text)
    signals = tuple(_signals_for_text(text, event.text))
    stance = classify_stance(text)
    return ContributionAnalysis(event=event, signals=signals, stance=stance)


def analyze_events(events: Iterable[HermesEvent]) -> dict[str, StudentProfile]:
    profiles: dict[str, StudentProfile] = {}
    for event in events:
        analysis = analyze_event(event)
        profile = profiles.setdefault(event.student, StudentProfile(student=event.student))
        profile.add(analysis)
    return profiles


def _signals_for_text(normalized: str, original: str) -> list[Signal]:
    hits: list[Signal] = []
    for rule in GEOMETRY_RULES:
        evidence = _match_rule(rule, normalized, original)
        if evidence:
            hits.append(
                Signal(
                    code=rule.code,
                    family=rule.family,
                    label=rule.label,
                    topic=rule.topic,
                    evidence=evidence,
                    weight=rule.weight,
                    question_focus=rule.question_focus,
                )
            )
    return hits


def _match_rule(rule: SignalRule, normalized: str, original: str) -> str:
    for phrase in rule.phrases:
        idx = normalized.find(phrase)
        if idx >= 0:
            return snippet(original, approx_index=idx)
    for pattern in rule.patterns:
        match = re.search(pattern, normalized)
        if match:
            return snippet(original, approx_index=match.start())
    return ""


def classify_stance(normalized: str) -> Stance:
    mode_scores = {
        "subjective": _cue_hits(normalized, SUBJECTIVE_CUES),
        "objective": _cue_hits(normalized, OBJECTIVE_CUES),
        "normative": _cue_hits(normalized, NORMATIVE_CUES),
    }
    polarity_scores = {
        "compressive": _cue_hits(normalized, COMPRESSIVE_CUES),
        "expansive": _cue_hits(normalized, EXPANSIVE_CUES),
    }
    mode = max(mode_scores, key=lambda key: (len(mode_scores[key]), key))
    polarity = max(polarity_scores, key=lambda key: (len(polarity_scores[key]), key))
    if not mode_scores[mode]:
        mode = "unknown"
    if not polarity_scores[polarity]:
        polarity = "unknown"
    mode_evidence = mode_scores.get(mode, [])
    polarity_evidence = polarity_scores.get(polarity, [])
    evidence = tuple(mode_evidence + polarity_evidence)
    return Stance(mode=mode, polarity=polarity, evidence=evidence)


def _cue_hits(text: str, cues: Sequence[str]) -> list[str]:
    return [cue for cue in cues if cue in text]


def recommend_pairs(
    profiles: dict[str, StudentProfile],
    *,
    max_pairs: int | None = None,
    min_score: float = 3.0,
    exclusive: bool = True,
) -> list[PairRecommendation]:
    candidates: list[PairRecommendation] = []
    for a, b in itertools.combinations(sorted(profiles), 2):
        recommendation = score_pair(profiles[a], profiles[b])
        if recommendation.score >= min_score:
            candidates.append(recommendation)
    candidates.sort(key=lambda rec: (-rec.score, rec.student_a, rec.student_b))

    if not exclusive:
        return candidates[:max_pairs] if max_pairs else candidates

    chosen: list[PairRecommendation] = []
    used: set[str] = set()
    for candidate in candidates:
        if candidate.student_a in used or candidate.student_b in used:
            continue
        chosen.append(candidate)
        used.update((candidate.student_a, candidate.student_b))
        if max_pairs and len(chosen) >= max_pairs:
            break
    return chosen


def score_pair(a: StudentProfile, b: StudentProfile) -> PairRecommendation:
    topics_a = set(a.topic_counts)
    topics_b = set(b.topic_counts)
    shared_topics = topics_a & topics_b
    reasons: list[str] = []
    score = 0.0

    for topic in sorted(shared_topics):
        topic_score = 3.0
        a_has_mis = topic in a.misconception_topics
        b_has_mis = topic in b.misconception_topics
        a_has_paradox = topic in a.paradox_topics
        b_has_paradox = topic in b.paradox_topics
        if (a_has_mis and b_has_paradox) or (b_has_mis and a_has_paradox):
            topic_score += 2.5
            reasons.append(f"{topic}: misconception/paradox bridge")
        elif a_has_mis and b_has_mis:
            topic_score += 1.0
            reasons.append(f"{topic}: shared geometry misconception signal")
        elif a_has_paradox and b_has_paradox:
            topic_score += 1.5
            reasons.append(f"{topic}: shared paradox signal")
        else:
            reasons.append(f"{topic}: shared geometry topic")
        score += topic_score

    contrast_reason = _hierarchy_contrast_reason(a, b)
    if contrast_reason:
        score += 3.0
        reasons.append(contrast_reason)

    if a.dominant_mode != "unknown" and b.dominant_mode != "unknown" and a.dominant_mode != b.dominant_mode:
        score += 1.0
        reasons.append(f"PML mode contrast: {a.dominant_mode} vs {b.dominant_mode}")

    if (
        a.dominant_polarity != "unknown"
        and b.dominant_polarity != "unknown"
        and a.dominant_polarity != b.dominant_polarity
    ):
        score += 1.25
        reasons.append(
            f"PML polarity contrast: {a.dominant_polarity} vs {b.dominant_polarity}"
        )

    if not shared_topics and topics_a and topics_b:
        score += 1.0
        reasons.append("both have geometry signals, but on different topics")

    topics = tuple(sorted(shared_topics or (topics_a | topics_b)))
    question = build_pair_question(a, b, topics, reasons)
    return PairRecommendation(
        student_a=a.student,
        student_b=b.student,
        score=round(score, 2),
        topics=topics,
        reasons=tuple(reasons),
        question=question,
        evidence_a=a.best_evidence_for(topics),
        evidence_b=b.best_evidence_for(topics),
    )


def _hierarchy_contrast_reason(a: StudentProfile, b: StudentProfile) -> str:
    codes_a = set(a.signal_counts)
    codes_b = set(b.signal_counts)
    for left, right, reason in CONTRAST_SETS:
        if (codes_a & left and codes_b & right) or (codes_b & left and codes_a & right):
            return f"inclusive hierarchy contrast: {reason}"
    return ""


def build_pair_question(
    a: StudentProfile,
    b: StudentProfile,
    topics: Sequence[str],
    reasons: Sequence[str],
) -> str:
    topic = topics[0] if topics else ""
    base = TOPIC_QUESTIONS.get(
        topic,
        "What relationship between your two comments is worth testing together?",
    )
    bridge = "Start by each naming the property, image, or definition your comment relies on."
    if any("misconception/paradox bridge" in reason for reason in reasons):
        bridge = (
            "One of you seems to be near a common misconception while the other "
            "is naming the underlying tension; test both readings."
        )
    elif any("hierarchy contrast" in reason for reason in reasons):
        bridge = (
            "One of you may be narrowing a shape category while the other may be "
            "broadening one; locate the property that decides the issue."
        )
    return f"{a.student} and {b.student}: {base} {bridge}"


def render_markdown(
    recommendations: Sequence[PairRecommendation],
    profiles: dict[str, StudentProfile],
    *,
    title: str = "N103 Hermes Pairing Packet",
) -> str:
    lines = [f"# {title}", ""]
    if not recommendations:
        lines.append("No pair recommendations met the score threshold.")
        return "\n".join(lines).rstrip() + "\n"

    for idx, rec in enumerate(recommendations, start=1):
        topic_text = ", ".join(rec.topics) if rec.topics else "no shared topic"
        lines.extend(
            [
                f"## {idx}. {rec.student_a} + {rec.student_b}",
                "",
                f"- Score: {rec.score}",
                f"- Topics: {topic_text}",
                f"- Why: {'; '.join(rec.reasons) if rec.reasons else 'low-information pairing'}",
                f"- Question: {rec.question}",
                f"- {rec.student_a}: {rec.evidence_a}",
                f"- {rec.student_b}: {rec.evidence_b}",
                "",
            ]
        )
    lines.extend(["## Profile Summary", ""])
    for name in sorted(profiles):
        profile = profiles[name]
        topics = ", ".join(profile.top_topics) or "none"
        signals = ", ".join(f"{k}={v}" for k, v in profile.signal_counts.most_common()) or "none"
        lines.append(
            f"- {name}: topics [{topics}], signals [{signals}], "
            f"PML {profile.dominant_mode}/{profile.dominant_polarity}"
        )
    return "\n".join(lines).rstrip() + "\n"


def analysis_payload(
    profiles: dict[str, StudentProfile],
    recommendations: Sequence[PairRecommendation],
) -> dict:
    return {
        "profiles": {name: profile.as_dict() for name, profile in sorted(profiles.items())},
        "recommendations": [rec.as_dict() for rec in recommendations],
    }


def normalize_text(text: str) -> str:
    lower = text.lower()
    lower = lower.replace("doesnt", "doesn't").replace("isnt", "isn't")
    lower = lower.replace("cant", "can't").replace("wont", "won't")
    lower = re.sub(r"\s+", " ", lower)
    return lower.strip()


def snippet(text: str, *, approx_index: int = 0, width: int = 180) -> str:
    compact = re.sub(r"\s+", " ", text).strip()
    if len(compact) <= width:
        return compact
    start = max(0, approx_index - width // 3)
    end = min(len(compact), start + width)
    if end - start < width:
        start = max(0, end - width)
    prefix = "..." if start > 0 else ""
    suffix = "..." if end < len(compact) else ""
    return f"{prefix}{compact[start:end].strip()}{suffix}"
