#!/usr/bin/env python3
"""Build the grammar layer over the canonical action alphabet.

The alphabet in ``knowledge/strategies/action_vocabulary_map.pl`` compresses 644
bespoke action labels onto 119 canonical actions across two genres.  That is one
level of abstraction.  This builder adds the level above it and writes
``knowledge/strategies/action_grammar.pl``.

Three things live in that file.

**Phrases** are contiguous runs of canonical actions that recur across families.
They are the within-genre idioms: ``unitize_referent > partition_into_equal_parts``
is what the fraction and geometry machines both do before they measure anything.
Phrase names are authored here; which machines carry them is derived.

**Normative arcs** are the cross-genre basis.  Replace every action in a
machine's word with its stance, then collapse runs of the same stance.  What is
left is a short arc: the machine works, keeps what it had to keep, breaks it,
records the break.  189 machines across both genres spell 187 distinct action
words and 18 distinct arcs.  Five of those arcs are spelled by machines from
both genres, which is the only level at which arithmetic computation and
discursive commitment turn out to share anything.

**Interruption licenses** answer a narrower question: does a token, arriving in
a given context, already tell you the rest is lost?  The verdicts are derived
from the corpus rather than asserted, and the derivation is stated in each row's
basis.  The honest result is thin and is recorded as thin.

The builder is deterministic and its output is byte-compared by
``scripts/checks/action_grammar.py``.  Authored data lives in this file, next to
the derivation that consumes it, exactly as
``scripts/research/build_transition_tables.py`` holds its own.
"""

from __future__ import annotations

import argparse
import collections
import itertools
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MAP_PATH = ROOT / "knowledge/strategies/action_vocabulary_map.pl"
STRATEGY_TABLES = ROOT / "knowledge/strategies/transition_tables"
DISCOURSE_TABLE = ROOT / "knowledge/discourse/commitment_automata.pl"
DEFAULT_OUTPUT = ROOT / "knowledge/strategies/action_grammar.pl"
ACTION_PAIRS = ROOT / "knowledge/strategies/math"


# ---------------------------------------------------------------------------
# Authored: phrase names
#
# A phrase earns a name when it recurs across at least two families and names a
# doing a reader would recognize.  The sequences are the mined ones; the names
# and glosses are decided here.  Sequences not named below stay unnamed, and the
# machines that carry them fall back to their bare actions -- an unnamed
# remainder is a finding about the corpus, not a gap to paper over.
# ---------------------------------------------------------------------------

PHRASES: list[tuple[str, tuple[str, ...], str]] = [
    # opening
    ("bind_the_roles", ("assign_roles", "assign_roles"),
     "Bind two givens to their roles in the relation before any of them is operated on. The corpus's most widely shared opening."),
    ("read_the_givens_through", ("read_operand_attribute", "read_operand_attribute"),
     "Read two properties of the givens in succession, settling what the strategy is working with before it works."),
    ("take_up_and_read", ("register_givens", "read_operand_attribute"),
     "Hold the givens, then read the property the next step turns on."),
    ("take_up_and_fix_the_unit", ("register_givens", "select_unit_scale"),
     "Hold the givens, then decide which unit or base the work will run in."),
    ("constitute_and_partition", ("unitize_referent", "partition_into_equal_parts"),
     "Constitute the whole, then cut it into parts the strategy treats as equal. The opening the fraction and geometry measurement machines share."),
    ("constitute_and_certify", ("unitize_referent", "verify_invariant"),
     "Constitute the whole, then certify the property the later comparison depends on."),
    # working
    ("partition_then_iterate", ("unitize_referent", "partition_into_equal_parts", "iterate_unit"),
     "Constitute the whole, cut it into equal parts, then repeat one part. The fraction-scheme core in the Steffe/Olive/Hackenberg line."),
    ("bring_both_to_a_common_unit", ("align_to_common_unit", "align_to_common_unit"),
     "Bring each of the two quantities into the shared unit in turn, so that neither is measured in the other's terms."),
    ("measure_together_then_order", ("align_to_common_unit", "compare_magnitudes"),
     "Bring both to a common unit, then decide the order relation."),
    ("bind_then_compose", ("assign_roles", "assign_roles", "compose_expression"),
     "Bind the roles, then assemble the expression the roles determine."),
    # closing, keeping
    ("order_and_release", ("compare_magnitudes", "emit_result"),
     "Decide the order and release it. The closing the comparison automata share."),
    ("count_and_name", ("count_units", "name_result"),
     "Count the units the iteration produced and name that count as the answer."),
    ("operate_and_record_the_keeping", ("combine_quantities", "record_conservation"),
     "Carry out the joining and record that the total was conserved."),
    ("accumulate_and_record_the_keeping", ("accumulate_total", "record_conservation"),
     "Accumulate the pieces and record that the whole was conserved."),
    ("keep_what_survives_and_name", ("retain_what_must_survive", "name_result"),
     "Carry through, untouched, the quantity the strategy was obliged not to lose, then name the result that includes it. Before the retention split this phrase read as an untouched carry-through of no particular obligation, and every machine that carried it was in fact conserving."),
    ("write_then_apply_the_rule", ("apply_stored_rule", "inscribe_result"),
     "Carry out the prescribed step and write what it produced."),
    # closing, losing
    ("skip_then_misname", ("omit_required_step", "misname_result"),
     "Skip a step the strategy needs, then name a value that answers a different question. The corpus's most widely shared deformation."),
    ("misname_and_record_the_loss", ("misname_result", "record_loss"),
     "Name the wrong quantity, then record which relation went with it."),
    ("write_and_record_the_loss", ("inscribe_result", "record_loss"),
     "Write a result and record that what it was supposed to preserve is not in it."),
    ("halt_and_record_the_loss", ("halt_before_completion", "record_loss"),
     "Stop a required traversal and record what stopping cost."),
    ("bind_then_collapse_the_roles", ("assign_roles", "conflate_roles"),
     "Bind the roles, then collapse two of them into one."),
    ("take_up_then_set_aside_what_bears", ("register_givens", "treat_relevant_as_irrelevant"),
     "Hold the givens, then treat a relation the answer depends on as though it did not bear."),
    ("read_then_set_aside_what_bears", ("read_operand_attribute", "treat_relevant_as_irrelevant"),
     "Read the property, then treat it as not bearing on what follows."),
    ("accept_unchecked_then_skip", ("accept_without_check", "omit_required_step"),
     "Take a structure as usable without its check, then skip the step that check would have licensed."),
    ("skip_twice_then_misname", ("omit_required_step", "omit_required_step", "misname_result"),
     "Skip two required steps in succession, then name what is left as the answer."),
    ("count_then_name_the_wrong_terminus", ("count_up_to_target", "misname_result", "record_loss"),
     "Count forward to the target, then name the place reached instead of the distance travelled, or the reverse."),
    # discursive
    ("undertake_and_authorize", ("undertake_commitment", "authorize_deferral"),
     "Undertake the commitment and license others to defer to it."),
    ("acknowledge_twice_then_test", ("acknowledge_commitment", "acknowledge_commitment", "test_compatibility"),
     "Put two commitments on one's own score, then test whether they can be held together."),
    ("attend_then_name_the_token", ("attend_to_utterance", "name_the_incompatible_token"),
     "Take the utterance up while it is still running, and name the word whose use here is what will not go through."),
    ("elaborate_then_deploy", ("elaborate_practice_algorithmically", "deploy_vocabulary_from_practice"),
     "Elaborate the practice from another by algorithm, then deploy the vocabulary that practice suffices for."),
]

# ---------------------------------------------------------------------------
# Authored: normative arc names
#
# One name per run-length-encoded stance word.  The names describe the arc and
# nothing else, so that two machines sharing an arc can be read as sharing that
# and no more.
# ---------------------------------------------------------------------------

ARCS: dict[tuple[str, ...], tuple[str, str]] = {
    ("neutral",): ("unrecorded_run",
     "Every step carries a working load and none carries a conservation load. The machine does its work and stops without recording what it kept or lost."),
    ("neutral", "conserving"): ("work_then_keep",
     "Working steps, then the step or steps where what had to be kept is kept."),
    ("neutral", "deforming"): ("work_then_break",
     "Working steps, then the step or steps where what had to be kept breaks."),
    ("neutral", "conserving", "neutral"): ("keep_then_work_on",
     "The conservation is secured early and the machine keeps working after it."),
    ("neutral", "deforming", "neutral"): ("break_then_work_on",
     "The break happens early and the machine keeps working after it, on material that no longer carries the relation."),
    ("neutral", "deforming", "neutral", "deforming"): ("break_recover_break",
     "A break, then working steps that look ordinary, then a further break. The most common deformation arc in the corpus."),
    ("neutral", "conserving", "neutral", "conserving"): ("keep_work_keep",
     "The conservation is secured, more work follows, and a second conservation closes the machine."),
    ("deforming", "neutral", "deforming"): ("break_first_work_break",
     "The first step already breaks the relation; the working steps and the closing break follow from it."),
    ("neutral", "conserving", "deforming"): ("keep_then_break",
     "What had to be kept is kept, and then dropped. The arc that joins making a base and abandoning the leftover to asserting and declining the vindication task."),
    ("conserving", "neutral", "conserving"): ("keep_first_work_keep",
     "A conservation is certified before any work is done, and another closes the machine."),
    ("conserving", "neutral"): ("keep_first_then_work_on",
     "A conservation is certified first and the machine works on from it without recording again."),
    ("neutral", "deforming", "conserving", "deforming"): ("break_keep_break",
     "A break, then a step that keeps something locally, then a further break. The local keeping does not repair the earlier break."),
    ("neutral", "conserving", "neutral", "conserving", "neutral"): ("keep_work_keep_work_on",
     "Two conservations with work between and after them."),
    ("conserving", "deforming", "neutral"): ("keep_first_break_work_on",
     "A conservation certified first, then broken, and the machine works on."),
    ("conserving", "neutral", "conserving", "neutral", "conserving"): ("keep_work_keep_work_keep",
     "Three conservations with working steps between them."),
    ("neutral", "deforming", "neutral", "deforming", "neutral"): ("break_recover_break_work_on",
     "Two breaks with working steps between and after them."),
    ("neutral", "deforming", "neutral", "conserving", "neutral"): ("break_then_keep_work_on",
     "A break, then a step that keeps something, then further work. One of the four machines in which anything conserving follows a break."),
    ("conserving", "neutral", "deforming"): ("keep_first_then_break",
     "A conservation is secured before any work is done, and the machine breaks after it. The arc of a deformation whose setup was sound."),
    ("deforming", "neutral", "deforming", "neutral", "deforming"): ("break_three_times",
     "Three breaks with working steps between them. The most broken arc in the corpus."),
    ("conserving", "deforming", "neutral", "deforming"): ("keep_first_break_recover_break",
     "A conservation certified first, then a break, working steps, and a further break."),
    ("neutral", "deforming", "neutral", "conserving", "deforming"): ("break_then_keep_then_break",
     "A break, work, something kept, and a final break. The kept step does not repair the first break."),
    ("conserving", "neutral", "deforming", "neutral", "deforming"): ("keep_first_break_recover_break_again",
     "A conservation certified before any work, then two breaks with work between them."),
    ("conserving", "neutral", "deforming", "neutral", "conserving", "deforming"):
    ("keep_first_break_keep_break",
     "A conservation, a break, something kept again, and a closing break. The longest mixed arc the corpus spells."),
    ("neutral", "deforming", "neutral", "deforming", "neutral", "conserving", "neutral"):
    ("break_twice_then_keep_work_on",
     "Two breaks, then a conserving step, then more work. The longest arc in the corpus and the only one that records a viability judgment after its breaks."),
}

# ---------------------------------------------------------------------------
# Authored: how each interruption verdict is decided
#
# The verdicts are derived, not asserted.  These are the rules the derivation
# applies, stated here so a reader can reject a rule rather than argue with 100
# rows.  MIN_MACHINES and MIN_FAMILIES gate every corpus-derived stop.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Authored: when an interruption is warranted
#
# The first pass invented a policy. It derived stop / watch / continue verdicts
# per token from the corpus and, asked how often it fires, the answer was 59 of
# 189 machines. The owner's practice, in his words, is to interrupt
# INFREQUENTLY: when a student is in a contradiction loop he can point out so
# they can recognize it, or when a student is frustrated and has no idea and
# starts saying things that are very irrelevant. Sometimes on setup, sometimes on
# error, and rarely.
#
# So the verdicts went. Two conditions replace them, and a third fact family
# carries the thing that matters most and that a verdict cannot express: both
# readings stay open. "Sometimes people unexpectedly land in the right place and
# I learn something" is a constraint on the parser, not an aside. A stop verdict
# forecloses a reading; nothing here does.
TRIGGERS = [
    ("contradiction_loop",
     "The trace returns to a commitment it has already made without the "
     "incompatibility between them having been discharged. In an automaton: a "
     "cycle reachable from the start whose traversal leaves the same "
     "incompatible pair on the score.",
     "To make the loop explicit so the student can recognize it. The point is "
     "the student's own recognition, not the correction: an interruption that "
     "supplies the answer has answered the wrong question.",
     ("citation",
      "the owner's practice, stated 2026-07-25. Its formal counterpart is "
      "incompatibility in Brandom, Making It Explicit, ch. 3, and "
      "formal/learner/deontic_scorekeeper.pl:deontic_incoherent/2, which "
      "detects the state and not the loop")),
    ("unmoored_utterance",
     "The utterance stops answering to anything the exchange has established: "
     "tokens that belong to no strategy in play, in no register with an "
     "antecedent. Frustration with no purchase, rather than a wrong move.",
     "To end an exchange that has stopped being about the task. The owner "
     "describes the condition and not the aim, so the aim here is inferred and "
     "should be treated as such.",
     ("citation",
      "the owner's practice, stated 2026-07-25: frustrated, no idea, and "
      "starting to say things that are very irrelevant")),
]

MIN_MACHINES = 2
MIN_FAMILIES = 2
WATCH_LOSS_SHARE = 0.30   # a token this often in losing machines is worth watching
CONTINUE_LOSS_SHARE = 0.12  # below this it is not a signal on its own


def stop_basis(action: str, n_machines: int, n_families: int) -> str:
    return (f"the action's own stance is deforming, so the token names the break "
            f"rather than predicting it; {n_machines} machines in "
            f"{n_families} families carry it and every one of them ends on a "
            f"deforming step")


def context_stop_basis(context: str, action: str, machines: list[str]) -> str:
    return (f"the action's own stance is neutral, and yet every machine in which "
            f"it follows {context} ends on a deforming step "
            f"({', '.join(sorted(machines))}). This is the whole of what the "
            f"corpus licenses as an early stop, and {len(machines)} machines is "
            f"thin evidence for a rule")


# ---------------------------------------------------------------------------
# Reading the two genres
# ---------------------------------------------------------------------------

TUPLE_RE = re.compile(
    r"(?m)^automaton_tuple\((\w+),\s*(\w+),\s*states\(\[([^\]]*)\]\),\s*"
    r"actions\(\[[^\]]*\]\),\s*start\((\w+)\),\s*accepting\(\[([^\]]*)\]\)\)")
TRANS_RE = re.compile(
    r"(?m)^automaton_transition\((\w+),\s*(\w+),\s*(\w+),\s*(\w+),\s*(\w+),\s*"
    r"provenance\((.*?)\)\)\.")
MAPS_RE = re.compile(r"(?m)^action_maps\((\w+), (\w+), (\w+), (\w+),")
AXES_RE = re.compile(
    r"(?m)^action_register\((\w+), genre\((\w+)\), register\((\w+)\), stance\((\w+)\)\)")


class Machine:
    __slots__ = ("genre", "family", "signature", "start", "accepting", "edges")

    def __init__(self, genre, family, signature, start, accepting):
        self.genre = genre
        self.family = family
        self.signature = signature
        self.start = start
        self.accepting = accepting
        self.edges: set[tuple[str, str, str]] = set()

    @property
    def name(self) -> str:
        return f"{self.family}/{self.signature}"


def read_alphabet() -> tuple[dict, dict]:
    text = MAP_PATH.read_text(encoding="utf-8")
    projection = {(f, s, l): c for f, s, l, c in MAPS_RE.findall(text)}
    axes = {name: (genre, register, stance)
            for name, genre, register, stance in AXES_RE.findall(text)}
    if not projection or not axes:
        raise SystemExit(f"{MAP_PATH}: expected action_maps/7 and action_register/4 rows")
    return projection, axes


def read_machines(projection: dict) -> list[Machine]:
    sources = [(path, "computational") for path in sorted(STRATEGY_TABLES.glob("*.pl"))]
    sources.append((DISCOURSE_TABLE, "discursive"))
    machines: dict[tuple[str, str], Machine] = {}
    for path, genre in sources:
        text = path.read_text(encoding="utf-8")
        for family, signature, _, start, accepting in (m.groups() for m in TUPLE_RE.finditer(text)):
            machines[(family, signature)] = Machine(
                genre, family, signature, start,
                {a.strip() for a in accepting.split(",") if a.strip()})
        for family, signature, source, action, target, _ in (
                m.groups() for m in TRANS_RE.finditer(text)):
            machine = machines.get((family, signature))
            if machine is None:
                raise SystemExit(f"{path}: transition without a tuple for {family}/{signature}")
            canonical = projection.get((family, signature, action), action)
            machine.edges.add((source, canonical, target))
    return [machines[key] for key in sorted(machines)]


def word(machine: Machine) -> tuple[str, ...]:
    """The action word the machine spells while each state has one successor."""
    routes: dict[str, list[tuple[str, str]]] = collections.defaultdict(list)
    for source, action, target in sorted(machine.edges):
        if action not in [a for a, _ in routes[source]]:
            routes[source].append((action, target))
    sequence: list[str] = []
    state, seen = machine.start, {machine.start}
    while True:
        outgoing = routes.get(state, [])
        if len(outgoing) != 1:
            break
        action, target = outgoing[0]
        sequence.append(action)
        if target in seen:
            break
        seen.add(target)
        state = target
    return tuple(sequence)


def factor(sequence: tuple[str, ...], phrases: list[tuple[str, tuple[str, ...]]]) -> list[str]:
    """Cover the word left to right with the longest phrase that fits."""
    ordered = sorted(phrases, key=lambda item: -len(item[1]))
    result: list[str] = []
    index = 0
    while index < len(sequence):
        for name, body in ordered:
            if sequence[index:index + len(body)] == body:
                result.append(name)
                index += len(body)
                break
        else:
            result.append(sequence[index])
            index += 1
    return result


def arc_of(stances: tuple[str, ...]) -> tuple[str, ...]:
    return tuple(key for key, _ in itertools.groupby(stances))


# ---------------------------------------------------------------------------
# Emitting
# ---------------------------------------------------------------------------


OUTCOME_RE = re.compile(r"action_outcome\(\s*([a-z][a-z0-9_]*)\s*,\s*\[")
INVARIANT_RE = re.compile(r"invariant\(([a-z][a-z0-9_]*)\)")
PAIRING_RE = re.compile(
    r"productive_[a-z_]*deformation\(\s*([a-z][a-z0-9_]*)\s*,\s*"
    r"([a-z][a-z0-9_]*)\s*,\s*([a-z][a-z0-9_]*)\s*\)")


def read_action_pair_sources() -> tuple[dict, list]:
    """Read the invariants and the productive/deformation pairings.

    Both were authored in ``knowledge/strategies/math/*_action_pairs.pl`` and
    neither was carried into the transition tables. ``invariant(Name)`` says
    what a strategy is answerable for; ``productive_*_deformation/3`` says which
    deformation stands opposite which productive strategy and what it deforms.
    Reading them rather than re-authoring them is the whole point of this pass:
    the answer to "what does this machine conserve" was in the tree already.
    """
    invariants: dict[str, tuple[set[str], str]] = {}
    pairings: list[tuple[str, str, str, str]] = []
    for path in sorted(ACTION_PAIRS.glob("*action_pairs*.pl")):
        text = path.read_text(encoding="utf-8")
        name = path.name
        for match in OUTCOME_RE.finditer(text):
            signature = match.group(1)
            index, depth = match.end(), 1
            while index < len(text) and depth:
                if text[index] == "[":
                    depth += 1
                elif text[index] == "]":
                    depth -= 1
                index += 1
            found = set(INVARIANT_RE.findall(text[match.end():index - 1]))
            if not found:
                continue
            held, _ = invariants.get(signature, (set(), name))
            invariants[signature] = (held | found, name)
        for productive, deformation, deforms in (
                m.groups() for m in PAIRING_RE.finditer(text)):
            pairings.append((productive, deformation, deforms, name))
    if not invariants or not pairings:
        raise SystemExit(f"{ACTION_PAIRS}: expected invariant/1 and "
                         "productive_*_deformation/3 facts")
    return invariants, pairings


def classify_divergence(productive_action: str, deformation_action: str,
                        axes: dict) -> tuple[str, str]:
    """Name what kind of parting of the ways the divergent step is.

    The classification decides how much an early divergence is worth, and the
    last class is deliberately not called an artifact: whether two neutral
    actions in one register are a real divergence or this alphabet's grain
    cannot be settled from the tables, and saying so is more use than guessing.
    """
    register = axes[productive_action][1], axes[deformation_action][1]
    stance = axes[productive_action][2], axes[deformation_action][2]
    if "deforming" in stance:
        return ("substantive_break",
                "the divergent step itself is where something breaks, so the "
                "two readings part company and the loss lands together")
    if "conserving" in stance:
        return ("substantive_keep",
                "one side keeps something at the divergent step and the other "
                "does not, before either records a loss")
    if register[0] != register[1]:
        return ("register_divergence",
                "both divergent actions are working steps and they are "
                "different kinds of doing, so the readings part company before "
                "anything breaks")
    return ("same_register_neutral",
            "both divergent actions are working steps in the same register. "
            "Whether the strategies genuinely part here or this alphabet is "
            "drawing a line they do not draw cannot be settled from the "
            "tables; the pair belongs in a review queue, not in a finding")


def pl_string(text: str) -> str:
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def build(output: Path) -> dict:
    projection, axes = read_alphabet()
    machines = read_machines(projection)
    invariants, pairings = read_action_pair_sources()
    words = {machine.name: word(machine) for machine in machines}
    unknown = sorted({a for w in words.values() for a in w if a not in axes})
    if unknown:
        raise SystemExit(
            "actions with no action_register/4 row: " + ", ".join(unknown))

    phrase_bodies = [(name, body) for name, body, _ in PHRASES]
    seen_bodies = collections.Counter(body for _, body in phrase_bodies)
    duplicated = [body for body, count in seen_bodies.items() if count > 1]
    if duplicated:
        raise SystemExit(f"the same phrase body is named twice: {duplicated}")

    stance_words = {m.name: tuple(axes[a][2] for a in words[m.name]) for m in machines}
    arcs = {m.name: arc_of(stance_words[m.name]) for m in machines}
    missing_arcs = sorted({arc for arc in arcs.values() if arc not in ARCS})
    if missing_arcs:
        raise SystemExit("normative arcs with no authored name: "
                         + "; ".join(" > ".join(a) for a in missing_arcs))

    phrasings = {m.name: factor(words[m.name], phrase_bodies) for m in machines}
    phrase_use = collections.Counter(
        p for parts in phrasings.values() for p in parts
        if p in {name for name, _ in phrase_bodies})
    unused = sorted({name for name, _ in phrase_bodies} - set(phrase_use))
    if unused:
        raise SystemExit(f"phrases named but carried by no machine: {unused}")

    # -- triggers, instances, and the census that used to be a policy -------
    by_name = {m.name: m for m in machines}
    family_of = {m.name: m.family for m in machines}
    genre_of = {m.name: m.genre for m in machines}
    loses = {name: axes[w[-1]][2] == "deforming"
             for name, w in words.items() if w}

    # trigger A: a cycle reachable from the start
    loop_instances = []
    for machine in machines:
        adjacency = collections.defaultdict(set)
        for source, _, target in machine.edges:
            adjacency[source].add(target)
        stack = [(machine.start, (machine.start,))]
        while stack:
            state, path = stack.pop()
            hit = None
            for target in sorted(adjacency.get(state, ())):
                if target in path:
                    hit = target
                    break
                stack.append((target, path + (target,)))
            if hit is not None:
                loop_instances.append((machine, hit, len(path)))
                break

    # trigger B: a token belonging to no canonical action
    unmoored_instances = []
    for machine in machines:
        for _, action, _ in sorted(machine.edges):
            canonical = projection.get(
                (machine.family, machine.signature, action), action)
            if canonical not in axes:
                unmoored_instances.append((machine, action))

    # the token census, demoted from policy to evidence
    holders = collections.defaultdict(list)
    for name, word_of in words.items():
        for action in set(word_of):
            holders[action].append(name)
    census = []
    for action in sorted(holders):
        carriers = holders[action]
        if len(carriers) < 4:
            continue
        losing = [c for c in carriers if loses.get(c)]
        census.append((axes[action][0], action, len(carriers), len(losing)))

    lines: list[str] = []
    W = lines.append
    W("% Generated by scripts/research/build_action_grammar.py.")
    W("% Authored phrase, arc, and verdict-rule tables live in that builder; the")
    W("% factorizations and the verdicts below are derived from the two genres'")
    W("% transition tables and re-derived byte-for-byte by")
    W("% scripts/checks/action_grammar.py.")
    W("%")
    W("% WHAT THIS LAYER IS FOR. knowledge/strategies/action_vocabulary_map.pl")
    W("% compresses 644 bespoke action labels onto 119 canonical actions. This file")
    W("% is the level above: what shapes those actions make, and what a shape")
    W("% tells you about where a machine is going.")
    W("%")
    W("% THE COMPRESSION THAT MATTERS IS THE ARC. Projected to canonical actions,")
    W("% the 189 machines across both genres spell 187 distinct words -- almost no")
    W("% sharing. Projected to stance and run-length-collapsed, they spell 18")
    W("% arcs, and five of those are spelled by machines from both genres. An")
    W("% arithmetic strategy and a discursive practice never share an action; they")
    W("% share a normative arc. That is the level at which the two genres are")
    W("% commensurable, and it is a result of the projection rather than an")
    W("% assumption behind it.")
    W("%")
    W("% WHAT THE ARC LAYER CANNOT REACH. A machine whose every step is a working")
    W("% step carries arc(unrecorded_run) and tells the layer nothing. Those")
    W("% machines are listed as machine_conservation_gap/4 rather than left to be")
    W("% counted out of the arc census, because the gap is in the tables and is")
    W("% fixable there.")
    W("%")
    W("% AN ARC IS NOT A CLAIM OF SAMENESS. Two machines with one arc agree on the")
    W("% order in which conservation and loss arrive and on nothing else. Reading")
    W("% more into a shared arc than that is the error this layer makes easy, so:")
    W("% strategies stay distinct, practices stay distinct, and a shared arc is a")
    W("% finding to report with both machines named.")
    W("")
    W(":- module(action_grammar,")
    W("          [ action_phrase/3,")
    W("            normative_arc/3,")
    W("            machine_grammar/6,")
    W("            machine_answerability/5,")
    W("            incompatible_pair/6,")
    W("            unpaired_reference/4,")
    W("            machine_conservation_gap/4,")
    W("            interruption_trigger/4,")
    W("            trigger_instance/5,")
    W("            reading_held_open/5,")
    W("            token_loss_rate/4")
    W("          ]).")
    W("")
    W("% unpaired_reference/4 is empty whenever every pairing the action-pair")
    W("% sources declare has both of its machines extracted, which is the outcome")
    W("% to want. The declaration keeps the export legal when the family is empty,")
    W("% so shrinking it to nothing cannot break the load.")
    W(":- discontiguous unpaired_reference/4.")
    W("")
    W("% action_phrase(Name, sequence([Action, ...]), gloss(Text)).")
    for name, body, gloss in sorted(PHRASES):
        W(f"action_phrase({name}, sequence([{', '.join(body)}]),")
        W(f"              gloss({pl_string(gloss)})).")
    W("")
    W("% normative_arc(Name, stances([Stance, ...]), gloss(Text)) -- the stance")
    W("% word of a machine with runs of the same stance collapsed.")
    for body in sorted(ARCS, key=lambda b: (len(b), b)):
        name, gloss = ARCS[body]
        W(f"normative_arc({name}, stances([{', '.join(body)}]),")
        W(f"              gloss({pl_string(gloss)})).")
    W("")
    W("% machine_grammar(Genre, Family, Signature, arc(ArcName),")
    W("%                 phrases([PhraseOrAction, ...]), stances([Stance, ...])).")
    W("%")
    W("% An element of the phrases list is a phrase name where one covers that")
    W("% stretch of the word and a bare canonical action where none does. The")
    W("% bare actions are the residue the phrase table does not reach, and they")
    W("% are kept on the record for that reason.")
    for machine in machines:
        name = machine.name
        arc_name = ARCS[arcs[name]][0]
        W(f"machine_grammar({machine.genre}, {machine.family}, {machine.signature}, arc({arc_name}),")
        W(f"                phrases([{', '.join(phrasings[name])}]),")
        W(f"                stances([{', '.join(stance_words[name])}])).")
    W("")
    by_signature = {machine.signature: machine for machine in machines}
    W("% machine_answerability(Genre, Family, Signature, invariant(Name),")
    W("%                       source(File)) -- what the strategy is answerable")
    W("% for, read from the action-pair sources rather than authored here.")
    W("%")
    W("% knowledge/strategies/math/*_action_pairs.pl already carried an")
    W("% invariant/1 in the outcome of most actions: each_object_counted_once,")
    W("% cardinality_independent_of_spatial_extent,")
    W("% ray_length_does_not_change_angle_measure. The transition-table extraction")
    W("% carried states, actions, and provenance and left the invariants behind.")
    W("% So the question the last pass posed as a labelling job -- what does this")
    W("% machine conserve -- was answered in the tree, for most machines, before")
    W("% it was asked.")
    answerability = []
    for signature, (held, source) in sorted(invariants.items()):
        machine = by_signature.get(signature)
        if machine is None:
            continue
        for name in sorted(held):
            answerability.append((machine, name, source))
            W(f"machine_answerability({machine.genre}, {machine.family}, {signature},")
            W(f"                      invariant({name}), source('{source}')).")
    W("")
    W("% incompatible_pair(Family, Productive, Deformation, deforms(What),")
    W("%                   divergence(Step, ProductiveAction, DeformationAction),")
    W("%                   class(Class)) -- the two readings and where they part.")
    W("%")
    W("% Brandom's incompatibility rather than a similarity: what a strategy")
    W("% conserves is fixed by what the strategy it excludes fails to conserve, so")
    W("% the pair carries content the productive machine does not carry alone. The")
    W("% pairing and the deforms/1 name are read from the action-pair sources; the")
    W("% divergence step is computed by walking the two projected words together")
    W("% until they differ.")
    W("%")
    W("% Step is 1-based. class(_) says what kind of parting it is, and the")
    W("% same_register_neutral class is a review queue rather than a finding --")
    W("% see classify_divergence in the builder for why.")
    paired = []
    for productive, deformation, deforms, source in sorted(pairings):
        left, right = by_signature.get(productive), by_signature.get(deformation)
        if left is None or right is None:
            continue
        wl, wr = words[left.name], words[right.name]
        if not wl or not wr:
            continue
        step = next((i for i in range(min(len(wl), len(wr))) if wl[i] != wr[i]), None)
        if step is None:
            continue
        klass, _ = classify_divergence(wl[step], wr[step], axes)
        paired.append((left.family, productive, deformation, deforms, step, klass))
        W(f"incompatible_pair({left.family}, {productive}, {deformation}, deforms({deforms}),")
        W(f"                  divergence({step + 1}, {wl[step]}, {wr[step]}),")
        W(f"                  class({klass})).")
    W("")
    W("% unpaired_reference(Family, Signature, side(Which), source(File)) -- a")
    W("% signature the action-pair sources pair up and the transition tables do")
    W("% not carry. Stalled input, named rather than dropped: the pairing exists")
    W("% and the machine it names has no extracted automaton, so nothing can")
    W("% compare the two readings.")
    unpaired = []
    for productive, deformation, deforms, source in sorted(pairings):
        for signature, side in ((productive, "productive"), (deformation, "deformation")):
            if signature in by_signature:
                continue
            row = (signature, side, source)
            if row in unpaired:
                continue
            unpaired.append(row)
            family = source.replace("_action_pairs.pl", "")
            W(f"unpaired_reference({family}, {signature}, side({side}), source('{source}')).")
    W("")
    W("% machine_conservation_gap(Genre, Family, Signature, reason(Text)) -- a")
    W("% machine with no step whose stance is conserving or deforming. It runs its")
    W("% work and stops without any edge naming what the strategy kept or lost.")
    W("%")
    W("% This is a gap in the transition tables, not a property of the strategies.")
    W("% Every one of these machines does conserve or lose something; none of them")
    W("% has a label that says so, so none can take part in any comparison that")
    W("% turns on conservation, and each is invisible to the arc layer beyond")
    W("% carrying arc(unrecorded_run). The family is derived on every build, so it")
    W("% shrinks by itself as the tables gain the labels -- it is a work list, not")
    W("% a verdict, and it is queryable rather than sitting in a report.")
    W("%")
    W("% Two machines left this list when retain_unchanged split: the conservation")
    W("% was in their tables all along, under a label the alphabet had read as a")
    W("% working retention. That is worth knowing before reading the rest as a")
    W("% table gap; some of what remains may be the same kind of mistake.")
    for machine in machines:
        name = machine.name
        if any(axes[a][2] != "neutral" for a in words[name]):
            continue
        held = invariants.get(machine.signature)
        if held is not None:
            reason = (
                f"{len(words[name])} edges, every one of them a working step: "
                f"{' > '.join(words[name])}. An EXTRACTION gap, not an authoring "
                f"one: {machine.signature} already declares "
                f"invariant({', '.join(sorted(held[0]))}) in {held[1]}, and the "
                f"transition-table builder did not carry it onto an edge. "
                f"Fixable by extraction")
        else:
            reason = (
                f"{len(words[name])} edges, every one of them a working step: "
                f"{' > '.join(words[name])}. An AUTHORING gap: no invariant/1 for "
                f"this signature anywhere in the action-pair sources, so nothing "
                f"in the tree says what the strategy is answerable for")
        W(f"machine_conservation_gap({machine.genre}, {machine.family}, {machine.signature},")
        W(f"                        reason({pl_string(reason)})).")
    W("")
    W("% interruption_trigger(Name, condition(Text), purpose(Text),")
    W("%                      citation(Source)) -- when an interruption is")
    W("% warranted, from the owner's practice rather than from this corpus.")
    W("%")
    W("% The first pass derived stop / watch / continue verdicts per token and")
    W("% would have fired on 59 of 189 machines. The practice it was meant to")
    W("% model is infrequent. Two conditions replace the verdicts, and the token")
    W("% census below is what the derivation actually supports: evidence about")
    W("% where losses cluster, not a policy about when to speak.")
    for name, condition, purpose, (kind, source) in TRIGGERS:
        W(f"interruption_trigger({name}, condition({pl_string(condition)}),")
        W(f"                     purpose({pl_string(purpose)}),")
        W(f"                     {kind}({pl_string(source)})).")
    W("")
    W("% trigger_instance(Genre, Family, Signature, trigger(Name),")
    W("%                  evidence(Text)) -- where this corpus exhibits a trigger.")
    W("%")
    W("% Sparse on purpose. One machine loops. None is unmoored, because the")
    W("% corpus is closed by construction: every token in it belongs to a")
    W("% strategy, so the condition cannot arise here. That trigger is defined")
    W("% against discourse this repository does not yet hold, and saying so is")
    W("% the point of declaring it with no instances.")
    for machine, state, depth in loop_instances:
        evidence = (f"the trace returns to {state} after {depth} states, so the "
                    f"machine can traverse the same commitment twice without "
                    f"anything between the two passes discharging it")
        W(f"trigger_instance({machine.genre}, {machine.family}, {machine.signature},")
        W(f"                 trigger(contradiction_loop),")
        W(f"                 evidence({pl_string(evidence)})).")
    for machine, action in unmoored_instances:
        evidence = f"{action} belongs to no canonical action"
        W(f"trigger_instance({machine.genre}, {machine.family}, {machine.signature},")
        W(f"                 trigger(unmoored_utterance),")
        W(f"                 evidence({pl_string(evidence)})).")
    W("")
    W("% reading_held_open(Family, Productive, Deformation, divergence(Step),")
    W("%                   reason(Text)) -- both readings of a diverged trace stay")
    W("% live. This is the default and it has no exceptions.")
    W("%")
    W("% The owner: sometimes people unexpectedly land in the right place and I")
    W("% learn something. A parser that commits to the deformation reading at the")
    W("% divergence cannot be surprised, and being surprised is how the")
    W("% instructor learns. So a divergence is reported as two live readings and a")
    W("% step, and never as a verdict about which one is running.")
    for family, productive, deformation, deforms, step, klass in paired:
        reason = (f"the two readings part at step {step + 1} and both remain "
                  f"reachable: a trace on the {deformation} reading may still "
                  f"terminate where {productive} does, and the corpus cannot say "
                  f"it will not")
        W(f"reading_held_open({family}, {productive}, {deformation}, divergence({step + 1}),")
        W(f"                  reason({pl_string(reason)})).")
    W("")
    W("% token_loss_rate(Genre, Action, machines(N), ending_deforming(K)) -- of")
    W("% the machines carrying this action, how many end on a deforming step.")
    W("%")
    W("% Evidence, not a verdict. It says where losses cluster in this corpus and")
    W("% nothing about whether to interrupt. Actions carried by fewer than four")
    W("% machines are omitted rather than reported at a scale that cannot bear it.")
    for genre, action, total, losing in census:
        W(f"token_loss_rate({genre}, {action}, machines({total}), ending_deforming({losing})).")

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(lines) + "\n", encoding="utf-8")

    cross = collections.defaultdict(set)
    for name in arcs:
        cross[ARCS[arcs[name]][0]].add(genre_of[name])
    return {
        "machines": len(machines),
        "distinct_action_words": len(set(words.values())),
        "distinct_stance_words": len(set(stance_words.values())),
        "arcs": len(ARCS),
        "arcs_in_use": len({arcs[n] for n in arcs}),
        "cross_genre_arcs": sum(1 for genres in cross.values() if len(genres) > 1),
        "phrases": len(PHRASES),
        "phrase_uses": sum(phrase_use.values()),
        "residue_actions": sum(
            1 for parts in phrasings.values() for p in parts
            if p not in {name for name, _ in phrase_bodies}),
        "answerability_rows": len(answerability),
        "incompatible_pairs": len(paired),
        "divergence_classes": dict(sorted(
            collections.Counter(k for *_, k in paired).items())),
        "unpaired_references": len(unpaired),
        "extraction_gaps": sum(
            1 for m in machines
            if all(axes[a][2] == "neutral" for a in words[m.name])
            and m.signature in invariants),
        "conservation_gaps": sum(
            1 for m in machines
            if all(axes[a][2] == "neutral" for a in words[m.name])),
        "triggers": len(TRIGGERS),
        "trigger_instances": len(loop_instances) + len(unmoored_instances),
        "readings_held_open": len(paired),
        "token_census_rows": len(census),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    summary = build(args.output)
    print(f"wrote {args.output}")
    for key, value in summary.items():
        print(f"  {key:24s} {value}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
