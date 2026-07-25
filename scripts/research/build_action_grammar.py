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
    ("carry_forward_and_name", ("retain_unchanged", "name_result"),
     "Carry a quantity through untouched and name what it now stands for."),
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


def pl_string(text: str) -> str:
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def build(output: Path) -> dict:
    projection, axes = read_alphabet()
    machines = read_machines(projection)
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

    # -- interruption licenses, derived ------------------------------------
    by_name = {m.name: m for m in machines}
    family_of = {m.name: m.family for m in machines}
    genre_of = {m.name: m.genre for m in machines}
    loses = {name: axes[w[-1]][2] == "deforming" for name, w in words.items() if w}

    licenses: list[tuple[str, str, str, str, str]] = []

    # every action whose own stance is deforming
    holders = collections.defaultdict(list)
    for name, w in words.items():
        for action in set(w):
            holders[action].append(name)
    for action in sorted(holders):
        if axes[action][2] != "deforming":
            continue
        carriers = holders[action]
        families = {family_of[c] for c in carriers}
        if all(loses[c] for c in carriers):
            licenses.append((axes[action][0], action, "any_context", "stop",
                             stop_basis(action, len(carriers), len(families))))
        else:
                    # "keeping" here means only: does not end on a deforming step.
            keeping = sorted(c for c in carriers if not loses[c])
            licenses.append((
                axes[action][0], action, "any_context", "watch",
                f"the action's own stance is deforming, and yet "
                f"{len(keeping)} of {len(carriers)} machines carrying it do not "
                f"end on a deforming step ({', '.join(keeping)}); in those the "
                f"break happens and the machine runs on past it to a step that "
                f"neither keeps nor breaks"))

    # neutral actions that never recover after a particular predecessor
    bigrams = collections.defaultdict(list)
    for name, w in words.items():
        for i in range(len(w) - 1):
            bigrams[(w[i], w[i + 1])].append(name)
    for (context, action), carriers in sorted(bigrams.items()):
        if axes[action][2] != "neutral":
            continue
        if len(carriers) < MIN_MACHINES:
            continue
        if len({family_of[c] for c in carriers}) < MIN_FAMILIES:
            continue
        if all(loses[c] for c in carriers):
            licenses.append((axes[action][0], action, context, "stop",
                             context_stop_basis(context, action, carriers)))

    # neutral actions whose loss share is worth naming either way
    for action in sorted(holders):
        if axes[action][2] != "neutral":
            continue
        carriers = holders[action]
        if len(carriers) < 4:
            continue
        losing = [c for c in carriers if loses[c]]
        share = len(losing) / len(carriers)
        if share >= WATCH_LOSS_SHARE:
            verdict, tail = "watch", "so the token is worth attending to and settles nothing by itself"
        elif share <= CONTINUE_LOSS_SHARE:
            verdict, tail = "continue", "so the token is not a signal on its own"
        else:
            continue
        licenses.append((
            axes[action][0], action, "any_context", verdict,
            f"the action's own stance is neutral; {len(losing)} of "
            f"{len(carriers)} machines carrying it end on a deforming step, "
            f"{tail}"))

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
    W("            interruption_license/5")
    W("          ]).")
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
    W("% interruption_license(Genre, Action, after(Context), verdict(V),")
    W("%                      basis(Text)).")
    W("%")
    W("% The question this family answers: does a token, arriving in a given")
    W("% context, already tell you the rest is lost? after(any_context) means the")
    W("% verdict does not depend on what came before.")
    W("%")
    W("% stop     -- every machine carrying this token in this context ends on a")
    W("%             deforming step.")
    W("% watch    -- the token appears on both sides; only its context decides.")
    W("% continue -- the token is not a signal on its own.")
    W("%")
    W("% The verdicts are derived from the corpus by rules stated in the builder,")
    W("% not asserted here, and each row's basis names the derivation and its n.")
    W("% What the corpus actually licenses is narrow: almost every stop is a token")
    W("% whose own stance is already deforming, which means the token names the")
    W("% break rather than predicting it. Exactly one context-sensitive stop")
    W("% survives the two-machine two-family gate, and two machines is thin. The")
    W("% useful finding is elsewhere and is not a verdict: of the 73 machines with")
    W("% a deforming step, 4 have any conserving step after it. Stopping is worth")
    W("% doing because running on almost never recovers, not because the corpus")
    W("% can see the break coming.")
    for genre, action, context, verdict, basis in sorted(licenses):
        W(f"interruption_license({genre}, {action}, after({context}), verdict({verdict}),")
        W(f"                     basis({pl_string(basis)})).")

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
        "licenses": len(licenses),
        "verdicts": dict(sorted(collections.Counter(v for *_, v, _ in licenses).items())),
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
