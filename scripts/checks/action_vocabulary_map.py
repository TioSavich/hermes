#!/usr/bin/env python3
"""Regression check for the authored action alphabet.

``knowledge/strategies/action_vocabulary_map.pl`` maps every action label in
the extracted transition tables onto a small alphabet of canonical actions, or
names the label as an explicit remainder.  The map is review-pending data: no
recognizer, reader, or automaton consults it, and the only consumer is the
opt-in ``--mapping`` flag of
``scripts/bigred/strategy_algebra/analyze_strategy_algebra.py``.

The file now carries four fact families: the canonical alphabet across two
genres, the genre/register/stance axes over it, the cross-genre kinship pairs,
and the per-signature mapping rows.  The grammar layer above it -- phrases,
normative arcs, and interruption verdicts -- is checked by
``scripts/checks/action_grammar.py``.

This check holds the map to what it claims:

  Coverage.  Every action label the census finds
  (``scripts/research/strategy_label_census.py``) is either mapped or
  explicitly unmapped, and so is every ``(family, signature, label)`` triple
  the transition tables actually contain -- including the six labels that
  appear only on execution-observed edges and so never enter a signature's
  declared ``actions`` list.

  No double bookkeeping.  One row per triple, and no triple both mapped and
  unmapped.

  Well-formed fields.  ``confidence`` is high, medium, or low; ``status`` is
  review_pending on every row; every canonical action a row names is declared;
  every declared canonical action is used at least once, so the alphabet
  carries no dead names.

  Evidence names the doing.  Each row's evidence text names the signature it
  belongs to and at least one state transition, because a row justified by the
  local label resembling the canonical name would justify nothing.

  Risk gating.  Where a canonical action's citation names a HIGH-risk entry of
  ``knowledge/crosswalk/vocabulary_licenses.pl``, the citation records the
  disambiguation obligation that comes with it rather than reading the entry as
  a synonym licence.  The division case is checked structurally: sharing
  (vl005) and measuring (vl006) are separate canonical actions, and no label
  maps to both.

  Two genres, one set of axes.  Every canonical action carries exactly one
  genre, register, and stance, drawn from the closed sets above.  A canonical
  action earns its place either by carrying mapping rows (the computational
  genre, whose table labels are bespoke) or by being fired in
  ``knowledge/discourse/commitment_automata.pl`` (the discursive genre, whose
  actions are canonical already and need no map).  Every kinship pair crosses
  the two genres and says what the shared doing is, because kinship is the only
  thing relating genres that share a single action name.

  The default path is untouched.  A run of the analyzer without ``--mapping``
  emits exactly the ``scope`` keys it emitted before the flag existed, so
  projection data cannot leak into the unprojected analysis.  Both the
  unprojected and the projected runs are checked for two-run determinism.

The check is read-only with respect to ``knowledge/`` and writes its analyzer
output to a temporary directory.
"""
from __future__ import annotations

import json
import py_compile
import re
import shutil
import subprocess
import sys
import tempfile
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PATHS_PL = ROOT / "paths.pl"
MAP_PATH = ROOT / "knowledge/strategies/action_vocabulary_map.pl"
LICENSES_PATH = ROOT / "knowledge/crosswalk/vocabulary_licenses.pl"
TABLES = ROOT / "knowledge/strategies/transition_tables"
DISCOURSE = ROOT / "knowledge/discourse/commitment_automata.pl"
CENSUS = ROOT / "scripts/research/strategy_label_census.py"
ANALYZER = ROOT / "scripts/bigred/strategy_algebra/analyze_strategy_algebra.py"

CONFIDENCES = ("high", "medium", "low")
GENRES = ("computational", "discursive")
REGISTERS = ("constitution", "partition", "iteration", "transformation",
             "operation", "comparison", "search", "delegation", "inscription",
             "normative")
STANCES = ("conserving", "deforming", "neutral")

# The scope keys the analyzer emitted before --mapping existed. A run without
# the flag must still emit exactly these, so that the projection cannot change
# the shape of the unprojected analysis.
PRE_FLAG_SCOPE_KEYS = frozenset(
    {
        "bounds",
        "execution_observed_signature_count",
        "expected_pairwise_formula",
        "mode",
        "pairwise_comparison_count",
        "signature_count",
        "signatures",
        "source_table_directory",
    }
)

# Stance-consistency drift.
#
# A local label whose own words say preserve, retain, or confirm, sitting under a
# canonical action whose stance is not conserving -- or a label saying lose, omit,
# ignore, or drop under an action that is not deforming -- is usually a mistake in
# the map, and it was one twice: retain_unchanged carried eleven rows and three
# normative jobs until the retention split, and two machines that had looked like
# they record nothing turned out to conserve something their deformation partners
# lose. So the audit that found that runs on every check now.
#
# Some inversions are deliberate. Each one below has to say why, because "the
# label says preserve and the stance is deforming" is exactly what a mistake
# looks like, and the only thing separating the two is an argument.
KEEP_WORDS = re.compile(r"^(preserve|retain|conserve|confirm|certify|verify)|_certified$")
LOSE_WORDS = re.compile(
    r"^(lose|lost|omit|omitted|ignore|drop|discard|skip|stop_before|fail|"
    r"confuse|misread|double|overcount)|_not_checked$|_ignored$")

STANCE_INVERSIONS = {
    "compute_product":
        # 2026-08-06: double_misread_radius_to_diameter names the misread
        # history, but the doing at this step is a sound doubling of the
        # value it was handed; the misreading itself is the earlier
        # deforming transition. The lose-word carries legibility, not
        # stance.
        "the label names an upstream misreading for legibility; the doing "
        "at this step is arithmetically sound on its input, and the "
        "deforming transition is the earlier read step",
    "set_aside_irrelevant_attribute":
        "the labels all begin ignore_, and setting aside a property the "
        "conclusion does not depend on is correct; treat_relevant_as_irrelevant "
        "is the deforming counterpart, and keeping the two apart is the point",
    "retain_where_change_was_due":
        "the labels all say retain or preserve or unchanged, and the retention "
        "is the deformation because the step obliged a change",
    "record_loss":
        "two labels say preserve_result_but_lose_X; the map takes the loss "
        "clause because the machine is a deformation, and the kept-result "
        "clause is a distinction the alphabet drops",
    "exhaust_resource":
        "the label says fail_to_retrieve, and a resource met at its limit is "
        "the ORR crisis rather than a break in what the strategy had to keep",
    "filter_by_constraint":
        "the labels say retain_pairs_with_perimeter and the like; retaining is "
        "set membership in a search -- which candidates passed the constraint -- "
        "and not a quantity the strategy owed",
    "name_result":
        "the labels say certify_equivalent and retain_all_maximal_frequencies; "
        "both are terminal edges whose keep-word describes the answer's content, "
        "the equivalence verdict and the set of modes, rather than a conservation",
    "register_givens":
        "nine statistics machines open on preserve_data_set. The position rule "
        "decides these: a label naming what is kept, on a machine's first edge, "
        "is holding the givens rather than closing a conservation",
    "retain_unchanged":
        "the residue of the retention split. retain_known_side and "
        "retain_one_known_dimension carry a quantity to the next step where the "
        "strategy owes it nothing; the obligated retentions went to "
        "retain_what_must_survive and the obliged-to-change ones to "
        "retain_where_change_was_due",
    "select_unit_scale":
        "retain_lcm_as_composite_iteration_unit holds the least common multiple "
        "as the unit the next edge iterates; choosing what to work in is not "
        "keeping something owed",
}

# The two canonical actions vocabulary_licenses vl005 and vl006 oblige to stay
# apart: the entries are HIGH risk precisely because students confuse sharing
# with measuring, so a label may map to one or the other, never to both.
DIVISION_SENSES = ("share_into_known_groups", "measure_out_group_size")


# ---------------------------------------------------------------------------
# Prolog fact reading
# ---------------------------------------------------------------------------


def split_top_level(text: str, delimiter: str = ",") -> list[str]:
    result: list[str] = []
    start = 0
    stack: list[str] = []
    quote: str | None = None
    escaped = False
    pairs = {"(": ")", "[": "]", "{": "}"}
    for index, char in enumerate(text):
        if quote:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
        elif char in {"'", '"'}:
            quote = char
        elif char in pairs:
            stack.append(pairs[char])
        elif stack and char == stack[-1]:
            stack.pop()
        elif not stack and char == delimiter:
            result.append(text[start:index].strip())
            start = index + 1
    tail = text[start:].strip()
    if tail:
        result.append(tail)
    return result


def iter_facts(text: str, functor: str):
    pattern = re.compile(rf"(?m)^{re.escape(functor)}\s*\(")
    for match in pattern.finditer(text):
        depth = 1
        quote: str | None = None
        escaped = False
        index = match.end()
        while index < len(text) and depth:
            char = text[index]
            if quote:
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == quote:
                    quote = None
            elif char in {"'", '"'}:
                quote = char
            elif char == "(":
                depth += 1
            elif char == ")":
                depth -= 1
            index += 1
        if depth:
            raise ValueError(f"unterminated {functor} fact")
        yield text[match.end() : index - 1].strip()


def atom(raw: str) -> str:
    value = raw.strip()
    if len(value) >= 2 and value[0] == value[-1] == "'":
        return value[1:-1]
    if not re.fullmatch(r"[a-z][a-zA-Z0-9_]*", value):
        raise ValueError(f"expected an atom, got {raw!r}")
    return value


def wrapped(raw: str, functor: str) -> str:
    value = raw.strip()
    prefix = f"{functor}("
    if not value.startswith(prefix) or not value.endswith(")"):
        raise ValueError(f"expected {functor}/1, got {raw!r}")
    return value[len(prefix) : -1].strip()


def wrapper_name(raw: str) -> str:
    match = re.match(r"^([a-z][a-zA-Z0-9_]*)\(", raw.strip())
    if not match:
        raise ValueError(f"expected a compound term, got {raw!r}")
    return match.group(1)


def pl_text(raw: str) -> str:
    value = raw.strip()
    if not (len(value) >= 2 and value[0] == value[-1] == '"'):
        raise ValueError(f"expected a double-quoted string, got {raw[:60]!r}")
    return value[1:-1].replace('\\"', '"').replace("\\\\", "\\")


# ---------------------------------------------------------------------------
# Sources
# ---------------------------------------------------------------------------


def read_map() -> tuple[dict, list, list]:
    text = MAP_PATH.read_text(encoding="utf-8")
    alphabet: dict[str, tuple[str, str, str]] = {}
    for body in iter_facts(text, "canonical_action"):
        fields = split_top_level(body)
        if len(fields) != 3:
            raise ValueError(f"expected canonical_action/3, got /{len(fields)}")
        name = atom(fields[0])
        gloss = pl_text(wrapped(fields[1], "gloss"))
        kind = wrapper_name(fields[2])
        if kind not in ("citation", "coined"):
            raise ValueError(f"{name}: third argument must be citation or coined")
        source = pl_text(wrapped(fields[2], kind))
        if name in alphabet:
            raise ValueError(f"{name}: declared twice")
        alphabet[name] = (gloss, kind, source)
    rows = []
    for body in iter_facts(text, "action_maps"):
        fields = split_top_level(body)
        if len(fields) != 7:
            raise ValueError(f"expected action_maps/7, got /{len(fields)}")
        rows.append(
            {
                "family": atom(fields[0]),
                "signature": atom(fields[1]),
                "label": atom(fields[2]),
                "canonical": atom(fields[3]),
                "confidence": atom(wrapped(fields[4], "confidence")),
                "evidence": pl_text(wrapped(fields[5], "evidence")),
                "status": atom(wrapped(fields[6], "status")),
            }
        )
    axes = {}
    for body in iter_facts(text, "action_register"):
        fields = split_top_level(body)
        if len(fields) != 4:
            raise ValueError(f"expected action_register/4, got /{len(fields)}")
        name = atom(fields[0])
        if name in axes:
            raise ValueError(f"{name}: two action_register/4 rows")
        axes[name] = (
            atom(wrapped(fields[1], "genre")),
            atom(wrapped(fields[2], "register")),
            atom(wrapped(fields[3], "stance")),
        )
    kinship = []
    for body in iter_facts(text, "action_kinship"):
        fields = split_top_level(body)
        if len(fields) != 3:
            raise ValueError(f"expected action_kinship/3, got /{len(fields)}")
        kinship.append((atom(fields[0]), atom(fields[1]),
                        pl_text(wrapped(fields[2], "basis"))))
    unmapped = []
    for body in iter_facts(text, "action_unmapped"):
        fields = split_top_level(body)
        if len(fields) != 4:
            raise ValueError(f"expected action_unmapped/4, got /{len(fields)}")
        unmapped.append(
            {
                "family": atom(fields[0]),
                "signature": atom(fields[1]),
                "label": atom(fields[2]),
                "reason": pl_text(wrapped(fields[3], "reason")),
            }
        )
    return alphabet, rows, unmapped, axes, kinship


def read_table_triples() -> set[tuple[str, str, str]]:
    pattern = re.compile(
        r"automaton_transition\((\w+),\s*(\w+),\s*(\w+),\s*(\w+),\s*(\w+),"
    )
    triples: set[tuple[str, str, str]] = set()
    for path in sorted(TABLES.glob("*.pl")):
        for match in pattern.finditer(path.read_text(encoding="utf-8")):
            family, signature, _, action, _ = match.groups()
            triples.add((family, signature, action))
    return triples


def read_discursive_actions() -> set[str]:
    """Actions the discursive genre's automata actually fire."""
    pattern = re.compile(
        r"(?m)^automaton_transition\((\w+),\s*(\w+),\s*(\w+),\s*(\w+),")
    return {action for _, _, _, action in pattern.findall(
        DISCOURSE.read_text(encoding="utf-8"))}


def read_census_labels() -> set[str]:
    result = subprocess.run(
        [sys.executable, str(CENSUS)],
        cwd=ROOT,
        capture_output=True,
        text=True,
        timeout=300,
    )
    if result.returncode != 0:
        raise RuntimeError(f"census failed:\n{result.stderr}")
    return set(json.loads(result.stdout)["action_labels"]["arities"])


def read_high_risk_concepts() -> set[str]:
    pattern = re.compile(r"vocabulary_license\((vl\d+),\s*\w+,\s*\".*?\",\s*(\w+),")
    return {
        concept
        for concept, risk in pattern.findall(
            LICENSES_PATH.read_text(encoding="utf-8")
        )
        if risk == "high"
    }


# ---------------------------------------------------------------------------
# Structural checks
# ---------------------------------------------------------------------------


def check_structure(
    alphabet: dict,
    rows: list,
    unmapped: list,
    axes: dict,
    kinship: list,
    triples: set[tuple[str, str, str]],
    census_labels: set[str],
    high_risk: set[str],
    discursive_actions: set[str],
) -> list[str]:
    errors: list[str] = []

    mapped_keys = Counter((r["family"], r["signature"], r["label"]) for r in rows)
    unmapped_keys = Counter(
        (r["family"], r["signature"], r["label"]) for r in unmapped
    )
    for key, count in mapped_keys.items():
        if count > 1:
            errors.append(f"duplicate action_maps rows for {key[0]}/{key[1]}/{key[2]}")
    for key, count in unmapped_keys.items():
        if count > 1:
            errors.append(
                f"duplicate action_unmapped rows for {key[0]}/{key[1]}/{key[2]}"
            )
    for key in sorted(set(mapped_keys) & set(unmapped_keys)):
        errors.append(
            f"{key[0]}/{key[1]}/{key[2]} is both mapped and unmapped; a label is "
            "either covered by the alphabet or named as a remainder, not both"
        )

    covered = set(mapped_keys) | set(unmapped_keys)
    for key in sorted(triples - covered):
        errors.append(
            f"transition table triple {key[0]}/{key[1]}/{key[2]} has no row"
        )
    for key in sorted(covered - triples):
        errors.append(
            f"row {key[0]}/{key[1]}/{key[2]} names a triple no transition table has"
        )

    covered_labels = {key[2] for key in covered}
    for label in sorted(census_labels - covered_labels):
        errors.append(f"census label {label} is neither mapped nor unmapped")

    for row in rows:
        where = f"{row['family']}/{row['signature']}/{row['label']}"
        if row["confidence"] not in CONFIDENCES:
            errors.append(f"{where}: confidence {row['confidence']} is not one of {CONFIDENCES}")
        if row["status"] != "review_pending":
            errors.append(f"{where}: status is {row['status']}, not review_pending")
        if row["canonical"] not in alphabet:
            errors.append(f"{where}: canonical action {row['canonical']} is not declared")
        evidence = row["evidence"]
        if f"{row['family']}/{row['signature']}" not in evidence:
            errors.append(f"{where}: evidence does not name its own signature")
        if " -> " not in evidence:
            errors.append(
                f"{where}: evidence names no state transition, so it cannot show "
                "the doing the row claims"
            )
        if len(evidence) < 40:
            errors.append(f"{where}: evidence is too short to name a doing")

    for row in unmapped:
        where = f"{row['family']}/{row['signature']}/{row['label']}"
        if len(row["reason"]) < 80:
            errors.append(
                f"{where}: unmapped reason is too short; a remainder has to say "
                "what doing the alphabet is missing"
            )

    # A canonical action earns its place either by carrying a mapping row (the
    # computational genre, whose labels are bespoke) or by being fired in the
    # discursive genre (whose actions are canonical already and need no map).
    used = {row["canonical"] for row in rows} | discursive_actions
    for name in sorted(set(alphabet) - used):
        errors.append(f"canonical action {name} is declared but never used")
    for name in sorted(discursive_actions - set(alphabet)):
        errors.append(f"{name} is fired in the discursive genre but not declared")

    for name in sorted(set(alphabet) - set(axes)):
        errors.append(f"{name} has no action_register/4 row")
    for name in sorted(set(axes) - set(alphabet)):
        errors.append(f"{name} has an action_register/4 row but no canonical_action/3")
    for name, (genre, register, stance) in sorted(axes.items()):
        if genre not in GENRES:
            errors.append(f"{name}: genre {genre} is not one of {GENRES}")
        if register not in REGISTERS:
            errors.append(f"{name}: register {register} is not one of {REGISTERS}")
        if stance not in STANCES:
            errors.append(f"{name}: stance {stance} is not one of {STANCES}")
    mapped_canonicals = {row["canonical"] for row in rows}
    for name in sorted(mapped_canonicals):
        if name in axes and axes[name][0] != "computational":
            errors.append(
                f"{name} carries mapping rows from the strategy tables but its "
                f"genre is {axes[name][0]}")
    for name in sorted(discursive_actions):
        if name in axes and axes[name][0] not in GENRES:
            errors.append(f"{name}: genre {axes[name][0]} is not one of {GENRES}")

    if not kinship:
        errors.append("no action_kinship/3 rows; the two genres share one action "
                      "name, and without kinship nothing relates them")
    for left, right, basis in kinship:
        for side in (left, right):
            if side not in alphabet:
                errors.append(f"kinship names {side}, which is not declared")
        if left in axes and right in axes:
            if {axes[left][0], axes[right][0]} != set(GENRES):
                errors.append(
                    f"kinship {left} ~ {right} does not cross the two genres; "
                    "kinship records the same doing on different material")
        if len(basis) < 40:
            errors.append(f"kinship {left} ~ {right}: basis is too short to say "
                          "what the shared doing is")

    for name, (gloss, kind, source) in sorted(alphabet.items()):
        if not gloss.endswith("."):
            errors.append(f"{name}: gloss is not a sentence")
        if not source:
            errors.append(f"{name}: {kind} text is empty")
        named_high = sorted(
            concept for concept in high_risk if concept in source
        )
        if named_high and "risk HIGH" not in source:
            errors.append(
                f"{name}: cites HIGH-risk entries {named_high} without saying so"
            )
        if "risk HIGH" in source and not any(
            phrase in source
            for phrase in ("disambiguation obligation", "never", "kept distinct", "two canonical actions")
        ):
            errors.append(
                f"{name}: cites a HIGH-risk license entry without recording the "
                "disambiguation obligation it carries"
            )

    # stance-consistency audit
    words_by_action = defaultdict(lambda: {"keep": [], "lose": []})
    for row in rows:
        label, canonical = row["label"], row["canonical"]
        where = f"{row['family']}/{row['signature']}:{label}"
        if KEEP_WORDS.search(label):
            words_by_action[canonical]["keep"].append(where)
        elif LOSE_WORDS.search(label):
            words_by_action[canonical]["lose"].append(where)
    for canonical, found in sorted(words_by_action.items()):
        if canonical not in axes:
            continue
        stance = axes[canonical][2]
        if canonical in STANCE_INVERSIONS:
            continue
        if found["keep"] and found["lose"]:
            errors.append(
                f"{canonical} [{stance}] carries both keep-words "
                f"({found['keep'][0]}) and lose-words ({found['lose'][0]}); one "
                "action cannot hold two normative bearings, so either split it "
                "or record the inversion in STANCE_INVERSIONS with its reason")
        elif found["keep"] and stance != "conserving":
            errors.append(
                f"{canonical} [{stance}] carries keep-words "
                f"({', '.join(found['keep'][:3])}); either its stance is wrong, "
                "or those rows belong under a conserving action, or the "
                "inversion is deliberate and belongs in STANCE_INVERSIONS")
        elif found["lose"] and stance != "deforming":
            errors.append(
                f"{canonical} [{stance}] carries lose-words "
                f"({', '.join(found['lose'][:3])}); either its stance is wrong, "
                "or those rows belong under a deforming action, or the "
                "inversion is deliberate and belongs in STANCE_INVERSIONS")
    for canonical in sorted(STANCE_INVERSIONS):
        if canonical not in alphabet:
            errors.append(
                f"STANCE_INVERSIONS names {canonical}, which is not a declared "
                "canonical action; a stale exemption hides real drift")
        elif canonical not in words_by_action:
            errors.append(
                f"STANCE_INVERSIONS exempts {canonical}, which no longer carries "
                "any keep-word or lose-word row; drop the exemption")

    for sense in DIVISION_SENSES:
        if sense not in alphabet:
            errors.append(
                f"{sense} is missing; vocabulary_licenses vl005 and vl006 are both "
                "HIGH risk and oblige the two division senses to stay apart"
            )
    by_label: dict[str, set[str]] = defaultdict(set)
    for row in rows:
        by_label[row["label"]].add(row["canonical"])
    for label, canonicals in sorted(by_label.items()):
        if set(DIVISION_SENSES) <= canonicals:
            errors.append(
                f"{label} maps to both {DIVISION_SENSES[0]} and "
                f"{DIVISION_SENSES[1]}; the sharing and measuring senses must "
                "not be joined through a shared label"
            )

    return errors


# ---------------------------------------------------------------------------
# Strict load and analyzer behaviour
# ---------------------------------------------------------------------------


def run_strict_load() -> None:
    goal = "user:use_module(strategies(action_vocabulary_map), []), halt."
    result = subprocess.run(
        [
            "swipl",
            "-q",
            "--on-warning=status",
            "--on-error=status",
            "-l",
            str(PATHS_PL),
            "-g",
            goal,
        ],
        cwd=ROOT,
        capture_output=True,
        text=True,
        timeout=180,
    )
    if result.returncode != 0:
        raise RuntimeError(
            "strict SWI load of strategies(action_vocabulary_map) failed "
            f"(exit {result.returncode}):\n{result.stdout}\n{result.stderr}"
        )


def run_analyzer(output: Path, mapping: bool) -> dict:
    command = [sys.executable, str(ANALYZER), "--output", str(output)]
    if mapping:
        command += ["--mapping", str(MAP_PATH)]
    result = subprocess.run(
        command, cwd=ROOT, capture_output=True, text=True, timeout=900
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"analyzer failed (mapping={mapping}, exit {result.returncode}):\n"
            f"{result.stdout}\n{result.stderr}"
        )
    return json.loads((output / "strategy_algebra.json").read_text(encoding="utf-8"))


def stable(payload: dict) -> str:
    """Drop the one block that cannot repeat: elapsed time and Python version."""
    copy = dict(payload)
    copy.pop("runtime", None)
    return json.dumps(copy, indent=2, sort_keys=True)


def check_analyzer(workdir: Path) -> tuple[list[str], dict, dict]:
    errors: list[str] = []
    plain_one = run_analyzer(workdir / "plain-1", mapping=False)
    plain_two = run_analyzer(workdir / "plain-2", mapping=False)
    if stable(plain_one) != stable(plain_two):
        errors.append("two runs without --mapping do not agree")
    scope_keys = set(plain_one["scope"])
    if scope_keys != PRE_FLAG_SCOPE_KEYS:
        errors.append(
            "a run without --mapping emits scope keys "
            f"{sorted(scope_keys)}, not the pre-flag set "
            f"{sorted(PRE_FLAG_SCOPE_KEYS)}; the projection must not change the "
            "shape of the unprojected analysis"
        )
    mapped_one = run_analyzer(workdir / "mapped-1", mapping=True)
    mapped_two = run_analyzer(workdir / "mapped-2", mapping=True)
    if stable(mapped_one) != stable(mapped_two):
        errors.append("two runs with --mapping do not agree")
    projection = mapped_one["scope"].get("action_projection")
    if not isinstance(projection, dict):
        errors.append("a run with --mapping records no action_projection")
    else:
        if projection["action_count_after"] > projection["action_count_before"]:
            errors.append("projection increased the action count")
        held = projection["signatures_held_at_exact_label_grain"]
        for record in projection["per_signature"]:
            if bool(record["nondeterminism_introduced"]) != (
                record["signature"] in held
            ):
                errors.append(
                    f"{record['signature']}: nondeterminism record and held-back "
                    "list disagree"
                )
            if record["signature"] not in held and (
                record["action_count_after"] > record["action_count_before"]
            ):
                errors.append(
                    f"{record['signature']}: projection increased its action count"
                )
    return errors, plain_one, mapped_one


# ---------------------------------------------------------------------------


def main() -> int:
    for path in (MAP_PATH, ANALYZER, LICENSES_PATH, CENSUS, DISCOURSE):
        if not path.exists():
            print(f"FAIL: {path} does not exist", file=sys.stderr)
            return 1
    try:
        alphabet, rows, unmapped, axes, kinship = read_map()
        triples = read_table_triples()
        census_labels = read_census_labels()
        high_risk = read_high_risk_concepts()
        discursive_actions = read_discursive_actions()
    except (ValueError, RuntimeError) as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1

    errors = check_structure(
        alphabet, rows, unmapped, axes, kinship, triples, census_labels,
        high_risk, discursive_actions
    )

    for path in (ANALYZER, Path(__file__)):
        try:
            py_compile.compile(str(path), doraise=True)
        except py_compile.PyCompileError as exc:
            errors.append(f"{path.name} does not compile: {exc}")

    workdir = Path(tempfile.mkdtemp(prefix="action-vocabulary-map-"))
    try:
        run_strict_load()
        analyzer_errors, plain, mapped = check_analyzer(workdir)
        errors.extend(analyzer_errors)
    except (RuntimeError, OSError) as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        shutil.rmtree(workdir, ignore_errors=True)
        return 1
    finally:
        shutil.rmtree(workdir, ignore_errors=True)

    if errors:
        print(f"FAIL: {len(errors)} problem(s):", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    confidence_counts = Counter(row["confidence"] for row in rows)
    canonical_use = Counter(row["canonical"] for row in rows)
    coined = sum(1 for _, kind, _ in alphabet.values() if kind == "coined")
    projection = mapped["scope"]["action_projection"]

    print(f"PASS strict SWI load of strategies(action_vocabulary_map)")
    print(
        f"PASS coverage: {len(triples)} transition-table triples and "
        f"{len(census_labels)} census labels, all mapped or named as remainders"
    )
    print(
        f"PASS field shape: {len(rows)} action_maps rows, all review_pending, "
        f"confidence {dict(sorted(confidence_counts.items()))}"
    )
    by_genre = Counter(genre for genre, _, _ in axes.values())
    print(
        f"PASS alphabet: {len(alphabet)} canonical actions "
        f"({len(alphabet) - coined} cited, {coined} coined), none unused; "
        f"{by_genre['computational']} computational, "
        f"{by_genre['discursive']} discursive"
    )
    print(
        f"PASS axes: every action carries one genre, register, and stance; "
        f"registers {len({r for _, r, _ in axes.values()})}, stances "
        f"{dict(sorted(Counter(s for _, _, s in axes.values()).items()))}"
    )
    print(
        f"PASS kinship: {len(kinship)} pairs, every one crossing the genres"
    )
    print(
        f"PASS stance consistency: no action holds two normative bearings; "
        f"{len(STANCE_INVERSIONS)} deliberate inversions, each with its reason"
    )
    print("PASS evidence: every row names its signature and a state transition")
    print(
        "PASS risk gating: HIGH-risk citations record their disambiguation "
        "obligation; sharing and measuring stay apart"
    )
    print("PASS analyzer: two runs each way agree, and the default path keeps its scope keys")
    print()
    print("Compression:")
    print(
        f"  action labels -> canonical actions : "
        f"{len({key[2] for key in triples})} -> {len(alphabet)}"
    )
    print(
        f"  distinct actions across the 69     : "
        f"{projection['distinct_action_count_before']} -> "
        f"{projection['distinct_action_count_after']}"
    )
    print(
        f"  action slots summed over the 69    : "
        f"{projection['action_count_before']} -> {projection['action_count_after']}"
    )
    print(f"  remainders left unmapped           : {len(unmapped)}")
    print(
        f"  held at exact-label grain          : "
        f"{len(projection['signatures_held_at_exact_label_grain'])} "
        f"{projection['signatures_held_at_exact_label_grain']}"
    )
    print()
    print("Most-used canonical actions:")
    for name, count in canonical_use.most_common(8):
        print(f"  {count:4d}  {name}")
    print()
    print(
        f"Released structure (projected against exact label): "
        f"coincidence classes {plain['findings']['coincidence_class_count']} -> "
        f"{mapped['findings']['coincidence_class_count']}, "
        f"homomorphisms {plain['findings']['candidate_homomorphism_count']} -> "
        f"{mapped['findings']['candidate_homomorphism_count']}, "
        f"products {plain['findings']['product_count']} -> "
        f"{mapped['findings']['product_count']}"
    )
    print()
    print("PASS action_vocabulary_map check")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
