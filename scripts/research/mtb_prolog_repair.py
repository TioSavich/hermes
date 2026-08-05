#!/usr/bin/env python3
"""Repair the Prolog a checkpoint writes without changing the quantities it meant.

A generated program can fail for two unrelated reasons. It can say the wrong
thing about the word problem, which is the model's error and belongs in the
score. Or it can say the right thing in a form the interpreter will not run:
goals written in the order the sentences arrived rather than the order
dataflow needs, a query line appended after the program, an output clause the
safety screen refuses, an answer predicate the runner never looks for. The
second class is the harness discarding a correct quantity model, and every
transformation here removes one of them.

Nothing in this module reads a benchmark item, a target, or an answer. Each
transformation is a syntactic rewrite of program text, so a repair that turns a
wrong program into a running one still returns the wrong number.

The entry point is ``repair_ladder``, which returns the successive programs to
try after the text as written. Each rung carries the names of the steps that
produced it, so a run can report how many of its answers needed which repair.
"""
from __future__ import annotations

from dataclasses import dataclass, replace
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))

from mtb_prolog_responder import ALLOWED_MODULES

# The screen's tokenizer reads `12.` at the end of a clause as a decimal number,
# which costs it nothing because it only inspects atoms. Moving clauses around
# needs the clause boundary itself, so end-of-clause is a token here: a period
# is a terminator only when layout or a comment follows it, as ISO says, and a
# number only carries a fractional part when a digit follows the point. This
# tokenizer is a reader; `screen_program` remains the one authority on what may
# run, and it is applied to every repaired program before that program is run.
_TOKEN_RE = re.compile(
    r"""
    (?P<space>\s+)
  | (?P<line_comment>%[^\n]*)
  | (?P<block_comment>/\*.*?\*/)
  | (?P<quoted_atom>'(?:''|\\.|[^'\\])*')
  | (?P<string>"(?:""|\\.|[^"\\])*")
  | (?P<back_quoted>`(?:``|\\.|[^`\\])*`)
  | (?P<number>\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)
  | (?P<atom>[a-z][A-Za-z0-9_]*)
  | (?P<variable>[_A-Z][A-Za-z0-9_]*)
  | (?P<end>\.(?=\s|%|$))
  | (?P<operator>:-|-->|\?-|\\\+|\*->|->|>=|=<|=:=|=\\=|==|\\==|@=<|@>=|@<|@>
                |//|\*\*|>>|<<|/\\|\\/)
  | (?P<punct>.)
    """,
    re.DOTALL | re.VERBOSE,
)

ANSWER_PREDICATE = "solve"

# Goals that only put text on a stream. A quantity model's answer does not
# depend on them, and the safety screen refuses the whole program for naming
# one, so dropping them recovers the model rather than weakening the screen.
OUTPUT_GOALS = {
    ("format", 1), ("format", 2), ("format", 3),
    ("write", 1), ("writeln", 1), ("write_canonical", 1), ("print", 1),
    ("nl", 0), ("tab", 1), ("print_message", 2), ("flush_output", 0),
}

# Comparisons need both sides bound, so they consume variables and bind none.
COMPARISON_OPERATORS = {">", "<", ">=", "=<", "=:=", "=\\=", "@<", "@>", "@=<", "@>="}

# clpq arithmetic is exact rational and has no integer division, truncation, or
# transcendental functions. An expression naming one cannot become a constraint.
CLPQ_SAFE_FUNCTIONS = {"+", "-", "*", "/", "(", ")"}
CLPQ_UNSAFE_ATOMS = {
    "//", "mod", "rem", "div", "rdiv", "**", "^", "abs", "sign", "min", "max",
    "sqrt", "truncate", "round", "ceiling", "floor", "integer", "float",
    "float_integer_part", "float_fractional_part", "gcd", "msb", "random",
    "log", "exp", "sin", "cos", "tan", "atan", "atan2", "pi", "e", "inf",
    "nan", "cot", "asin", "acos", "copysign", "succ", "plus",
}

_CONTROL_TOKENS = {";", "->", "*->"}
_OPEN = {"(", "[", "{"}
_CLOSE = {")", "]", "}"}


@dataclass(frozen=True)
class Lexeme:
    """A token that remembers where it came from, so edits stay surgical."""

    kind: str
    value: str
    start: int
    end: int


@dataclass(frozen=True)
class Goal:
    """One top-level goal of a clause body, with its source slice."""

    text: str
    tokens: tuple[Lexeme, ...]

    @property
    def functor(self) -> tuple[str, int] | None:
        """The goal's predicate indicator, or None for an operator or brace goal."""
        return _functor(self.tokens)

    @property
    def variables(self) -> frozenset[str]:
        return frozenset(
            token.value for token in self.tokens
            if token.kind == "variable" and token.value != "_"
        )


@dataclass(frozen=True)
class Clause:
    """A top-level clause split into the pieces the repairs move around."""

    kind: str  # "fact", "rule", "directive", or "query"
    head_text: str
    head_tokens: tuple[Lexeme, ...]
    goals: tuple[Goal, ...]
    has_control: bool

    @property
    def functor(self) -> tuple[str, int] | None:
        return _functor(self.head_tokens)

    def called(self) -> set[tuple[str, int]]:
        """Every predicate this clause's body could call, at any depth.

        A goal handed to ``findall/3`` or ``forall/2`` is a call the clause
        makes, so reachability has to see inside those arguments. The set is
        deliberately an over-approximation: keeping a clause that turns out to
        be dead costs nothing, and dropping a live one breaks the program.
        """
        return {
            indicator
            for goal in self.goals
            for indicator in _nested_calls(goal.tokens)
        }

    def render(self) -> str:
        if self.kind in {"directive", "query"}:
            marker = ":-" if self.kind == "directive" else "?-"
            return f"{marker} {self.goals[0].text}." if self.goals else f"{marker} true."
        if not self.goals:
            return f"{self.head_text}."
        body = ",\n    ".join(goal.text for goal in self.goals)
        return f"{self.head_text} :-\n    {body}."


@dataclass(frozen=True)
class Rung:
    """A repaired program and the named steps that produced it."""

    program: str
    steps: tuple[str, ...]


def lex(program: str) -> list[Lexeme]:
    """Tokenize with positions, dropping only layout and comments."""
    lexemes: list[Lexeme] = []
    position = 0
    while position < len(program):
        match = _TOKEN_RE.match(program, position)
        if match is None:  # The final punctuation branch makes this unreachable.
            raise ValueError("cannot tokenize Prolog program")
        start, position = match.start(), match.end()
        kind = match.lastgroup
        assert kind is not None
        if kind in {"space", "line_comment", "block_comment"}:
            continue
        lexemes.append(Lexeme(kind, match.group(kind), start, position))
    return lexemes


def strip_comments(program: str) -> str:
    """Remove comments so a reordered goal cannot swallow the goals after it."""
    pieces: list[str] = []
    position = 0
    cursor = 0
    while position < len(program):
        match = _TOKEN_RE.match(program, position)
        if match is None:
            raise ValueError("cannot tokenize Prolog program")
        kind = match.lastgroup
        if kind in {"line_comment", "block_comment"}:
            pieces.append(program[cursor:match.start()])
            cursor = match.end()
        position = match.end()
    pieces.append(program[cursor:])
    return "".join(pieces)


def _functor(tokens: tuple[Lexeme, ...] | list[Lexeme]) -> tuple[str, int] | None:
    """Read a predicate indicator from a head or goal, if it has one."""
    if not tokens or tokens[0].kind != "atom":
        return None
    name = tokens[0].value
    if len(tokens) == 1:
        return (name, 0)
    if tokens[1].value != "(":
        return None
    depth = 0
    arity = 1
    for token in tokens[1:]:
        if token.value in _OPEN:
            depth += 1
        elif token.value in _CLOSE:
            depth -= 1
            if depth == 0:
                break
        elif token.value == "," and depth == 1:
            arity += 1
    return (name, arity)


def _nested_calls(tokens: tuple[Lexeme, ...]) -> set[tuple[str, int]]:
    """Every ``name(...)`` application in a token run, however deeply nested."""
    calls: set[tuple[str, int]] = set()
    for index, token in enumerate(tokens):
        if token.kind != "atom":
            continue
        if index + 1 < len(tokens) and tokens[index + 1].value == "(":
            indicator = _functor(tokens[index:])
            if indicator is not None:
                calls.add(indicator)
        elif index == 0:
            calls.add((token.value, 0))
    return calls


def _split_top_level(
    tokens: list[Lexeme], separator: str,
) -> list[list[Lexeme]]:
    """Split a token run on a separator that sits outside every bracket."""
    parts: list[list[Lexeme]] = []
    current: list[Lexeme] = []
    depth = 0
    for token in tokens:
        if token.value in _OPEN:
            depth += 1
        elif token.value in _CLOSE:
            depth -= 1
        if token.value == separator and depth == 0:
            parts.append(current)
            current = []
        else:
            current.append(token)
    parts.append(current)
    return parts


def _slice(program: str, tokens: list[Lexeme]) -> str:
    return program[tokens[0].start:tokens[-1].end] if tokens else ""


def _goal(program: str, tokens: list[Lexeme]) -> Goal:
    return Goal(text=_slice(program, tokens), tokens=tuple(tokens))


def _split_clauses(lexemes: list[Lexeme]) -> list[list[Lexeme]]:
    """Cut a token stream at every end-of-clause token."""
    runs: list[list[Lexeme]] = []
    current: list[Lexeme] = []
    for token in lexemes:
        if token.kind == "end":
            runs.append(current)
            current = []
        else:
            current.append(token)
    runs.append(current)
    return runs


def parse_clauses(program: str) -> list[Clause]:
    """Split comment-free program text into clauses the repairs can rewrite."""
    clauses: list[Clause] = []
    for run in _split_clauses(lex(program)):
        if not run:
            continue
        if run[0].value in {":-", "?-"}:
            kind = "directive" if run[0].value == ":-" else "query"
            clauses.append(Clause(
                kind=kind, head_text="", head_tokens=(),
                goals=(_goal(program, run[1:]),) if len(run) > 1 else (),
                has_control=False,
            ))
            continue
        neck = _neck_index(run)
        if neck is None:
            clauses.append(Clause(
                kind="fact", head_text=_slice(program, run),
                head_tokens=tuple(run), goals=(), has_control=False,
            ))
            continue
        head, body = run[:neck], run[neck + 1:]
        control = any(
            token.value in _CONTROL_TOKENS
            for token in _outer_tokens(body)
        )
        goals = tuple(
            _goal(program, part) for part in _split_top_level(body, ",") if part
        )
        clauses.append(Clause(
            kind="rule", head_text=_slice(program, head),
            head_tokens=tuple(head), goals=goals, has_control=control,
        ))
    return clauses


def _neck_index(run: list[Lexeme]) -> int | None:
    """Where a clause's top-level ``:-`` sits, or None if it is a fact."""
    depth = 0
    for index, token in enumerate(run):
        if token.value in _OPEN:
            depth += 1
        elif token.value in _CLOSE:
            depth -= 1
        elif token.value == ":-" and depth == 0:
            return index
    return None


def _outer_tokens(tokens: list[Lexeme]) -> list[Lexeme]:
    """Tokens that sit outside every bracket, where control operators matter."""
    outer: list[Lexeme] = []
    depth = 0
    for token in tokens:
        if token.value in _OPEN:
            depth += 1
            continue
        if token.value in _CLOSE:
            depth -= 1
            continue
        if depth == 0:
            outer.append(token)
    return outer


def render(clauses: list[Clause]) -> str:
    return "\n".join(clause.render() for clause in clauses) + "\n"


# --- normalization -------------------------------------------------------


def _allowed_import(clause: Clause) -> bool:
    """Accept exactly the ``use_module(library(Name))`` the screen allows."""
    if clause.kind != "directive" or not clause.goals:
        return False
    values = [token.value for token in clause.goals[0].tokens]
    return (
        len(values) == 7
        and values[0] == "use_module"
        and values[1] == "("
        and values[2] == "library"
        and values[3] == "("
        and values[4] in ALLOWED_MODULES
        and values[5] == ")"
        and values[6] == ")"
    )


def drop_stray_clauses(clauses: list[Clause]) -> tuple[list[Clause], list[str]]:
    """Keep the program and the imports; drop queries and other directives.

    A checkpoint often appends ``?- solve(X), write(X).`` after the program, or
    opens with ``:- initialization(main).``. Neither is part of the quantity
    model, and both make the screen refuse the file.
    """
    kept: list[Clause] = []
    steps: list[str] = []
    for clause in clauses:
        if clause.kind == "query":
            steps.append("dropped_query")
            continue
        if clause.kind == "directive" and not _allowed_import(clause):
            steps.append("dropped_directive")
            continue
        kept.append(clause)
    return kept, sorted(set(steps))


def drop_output_goals(clauses: list[Clause]) -> tuple[list[Clause], list[str]]:
    """Remove goals that only write to a stream, keeping every binding goal."""
    changed = False
    kept: list[Clause] = []
    for clause in clauses:
        if clause.kind != "rule":
            kept.append(clause)
            continue
        goals = tuple(
            goal for goal in clause.goals if goal.functor not in OUTPUT_GOALS
        )
        if len(goals) != len(clause.goals):
            changed = True
            if not goals:
                # A clause with nothing left but output was never a quantity
                # model; dropping the clause is the same repair one rung up.
                continue
            clause = replace(clause, goals=goals)
        kept.append(clause)
    return kept, ["dropped_output_goals"] if changed else []


def _defined(clauses: list[Clause]) -> set[tuple[str, int]]:
    return {
        clause.functor for clause in clauses
        if clause.kind in {"fact", "rule"} and clause.functor is not None
    }


def _called(clauses: list[Clause]) -> set[tuple[str, int]]:
    called: set[tuple[str, int]] = set()
    for clause in clauses:
        called |= clause.called()
    return called


def alias_answer_predicate(
    clauses: list[Clause],
) -> tuple[list[Clause], list[str]]:
    """Give the runner the ``solve/1`` it calls when the program named it else.

    The runner asks for ``solve(Answer)``. A checkpoint that computed the right
    number under ``answer/1``, ``result/1``, or ``solve/3`` currently scores the
    same as one that computed nothing. The alias is added only when the program
    has a single unambiguous root, so nothing is guessed.
    """
    defined = _defined(clauses)
    if (ANSWER_PREDICATE, 1) in defined:
        return clauses, []
    called = _called(clauses)

    roots = sorted(
        indicator for indicator in defined
        if indicator[1] == 1 and indicator not in called
    )
    if len(roots) == 1:
        name = roots[0][0]
        alias = parse_clauses(f"{ANSWER_PREDICATE}(A) :- {name}(A).")[0]
        return clauses + [alias], ["aliased_answer_predicate"]

    wider = sorted(
        indicator for indicator in defined
        if indicator[0] == ANSWER_PREDICATE and indicator[1] > 1
    )
    if len(wider) == 1:
        # The answer of a wider solve/N is conventionally its last argument.
        arity = wider[0][1]
        arguments = ", ".join(["_"] * (arity - 1) + ["A"])
        alias = parse_clauses(
            f"{ANSWER_PREDICATE}(A) :- {ANSWER_PREDICATE}({arguments})."
        )[0]
        return clauses + [alias], ["aliased_answer_arity"]
    return clauses, []


def prune_unreachable(clauses: list[Clause]) -> tuple[list[Clause], list[str]]:
    """Keep only what ``solve/1`` can reach, plus the imports it needs."""
    if (ANSWER_PREDICATE, 1) not in _defined(clauses):
        return clauses, []
    reachable = {(ANSWER_PREDICATE, 1)}
    frontier = [(ANSWER_PREDICATE, 1)]
    while frontier:
        indicator = frontier.pop()
        for clause in clauses:
            if clause.functor != indicator:
                continue
            for call in clause.called():
                if call not in reachable:
                    reachable.add(call)
                    frontier.append(call)
    kept = [
        clause for clause in clauses
        if clause.kind == "directive" or clause.functor in reachable
    ]
    if len(kept) == len(clauses):
        return clauses, []
    return kept, ["dropped_unreachable_clauses"]


def _is_split(goal: Goal) -> tuple[list[Lexeme], list[Lexeme]] | None:
    """Split ``Lhs is Rhs`` at its top-level ``is``, if the goal is one."""
    depth = 0
    for index, token in enumerate(goal.tokens):
        if token.value in _OPEN:
            depth += 1
        elif token.value in _CLOSE:
            depth -= 1
        elif depth == 0 and token.kind == "atom" and token.value == "is":
            return list(goal.tokens[:index]), list(goal.tokens[index + 1:])
    return None


def capitalize_pseudo_variables(
    clauses: list[Clause],
) -> tuple[list[Clause], list[str]]:
    """Turn an atom used as the target of ``is`` into the variable it meant.

    ``total is crates * per`` fails silently: ``is/2`` evaluates the right side
    and then tries to unify a number with the atom ``total``. The clause reads
    as a quantity model to a person and returns no solution to the runner.
    """
    defined_names = {indicator[0] for indicator in _defined(clauses)}
    repaired: list[Clause] = []
    changed = False
    for clause in clauses:
        if clause.kind != "rule":
            repaired.append(clause)
            continue
        targets: set[str] = set()
        for goal in clause.goals:
            split = _is_split(goal)
            if split is None:
                continue
            left = split[0]
            if len(left) == 1 and left[0].kind == "atom":
                name = left[0].value
                if name not in defined_names:
                    targets.add(name)
        if not targets:
            repaired.append(clause)
            continue
        changed = True
        rename = {name: _variable_name(name) for name in targets}
        repaired.append(replace(
            clause,
            head_text=_rename_atoms(clause.head_text, clause.head_tokens, rename),
            goals=tuple(
                replace(goal, text=_rename_atoms(goal.text, goal.tokens, rename))
                for goal in clause.goals
            ),
        ))
    return repaired, ["capitalized_pseudo_variables"] if changed else []


def _variable_name(atom: str) -> str:
    """Name a variable after the atom it replaces, so a trace stays readable."""
    return "V_" + atom


def _rename_atoms(
    text: str, tokens: tuple[Lexeme, ...], rename: dict[str, str],
) -> str:
    """Replace named atom occurrences inside one source slice."""
    if not tokens:
        return text
    origin = tokens[0].start
    pieces: list[str] = []
    cursor = 0
    for token in tokens:
        if token.kind != "atom" or token.value not in rename:
            continue
        start, end = token.start - origin, token.end - origin
        pieces.append(text[cursor:start])
        pieces.append(rename[token.value])
        cursor = end
    pieces.append(text[cursor:])
    return "".join(pieces)


def _uses_braces(clauses: list[Clause]) -> bool:
    return any(
        token.value == "{"
        for clause in clauses
        for goal in clause.goals
        for token in goal.tokens
    )


def _has_constraint_import(clauses: list[Clause]) -> bool:
    for clause in clauses:
        if not _allowed_import(clause):
            continue
        values = [token.value for token in clause.goals[0].tokens]
        if values[4] in {"clpq", "clpfd"}:
            return True
    return False


def add_constraint_import(clauses: list[Clause]) -> tuple[list[Clause], list[str]]:
    """Supply the clpq import a program with brace constraints forgot."""
    if not _uses_braces(clauses) or _has_constraint_import(clauses):
        return clauses, []
    directive = parse_clauses(":- use_module(library(clpq)).")[0]
    return [directive] + clauses, ["added_clpq_import"]


def normalize(program: str) -> Rung:
    """Apply every repair that does not move or rewrite a goal."""
    steps: list[str] = []
    stripped = strip_comments(program)
    if stripped != program:
        steps.append("stripped_comments")
    clauses = parse_clauses(stripped)
    for step in (
        drop_stray_clauses, drop_output_goals, capitalize_pseudo_variables,
        alias_answer_predicate, prune_unreachable, add_constraint_import,
    ):
        clauses, applied = step(clauses)
        steps.extend(applied)
    return Rung(render(clauses), tuple(steps))


# --- reordering ----------------------------------------------------------


def _dataflow(goal: Goal) -> tuple[frozenset[str], frozenset[str]]:
    """The variables a goal needs bound already, and the ones it can bind."""
    variables = goal.variables
    split = _is_split(goal)
    if split is not None:
        left, right = split
        left_variables = frozenset(
            token.value for token in left
            if token.kind == "variable" and token.value != "_"
        )
        return frozenset(variables - left_variables), left_variables
    outer = _outer_tokens(list(goal.tokens))
    if any(token.value in COMPARISON_OPERATORS for token in outer):
        return variables, frozenset()
    # A brace constraint, a fact lookup, and a library relation all bind what
    # they mention, so none of them constrains where the goal may sit.
    return frozenset(), variables


def reorder_body(goals: tuple[Goal, ...]) -> tuple[Goal, ...]:
    """Sort goals so each one runs after whatever binds the variables it reads.

    Prolog's declarative reading does not depend on this order and its
    procedural reading does. A checkpoint writing in the order the word problem
    stated its quantities produces a clause that means the right thing and
    raises an instantiation error. Sorting is stable, so a body that already
    runs is returned untouched.
    """
    remaining = list(goals)
    available: set[str] = set()
    ordered: list[Goal] = []
    while remaining:
        choice = next(
            (index for index, goal in enumerate(remaining)
             if _dataflow(goal)[0] <= available),
            0,  # Nothing is ready: keep the author's order and let it raise.
        )
        goal = remaining.pop(choice)
        available |= _dataflow(goal)[1]
        ordered.append(goal)
    return tuple(ordered)


def reorder(program: str) -> Rung:
    """Reorder every body whose goals are a plain conjunction."""
    clauses = parse_clauses(program)
    changed = False
    repaired: list[Clause] = []
    for clause in clauses:
        if clause.kind != "rule" or clause.has_control or len(clause.goals) < 2:
            repaired.append(clause)
            continue
        goals = reorder_body(clause.goals)
        if goals != clause.goals:
            changed = True
        repaired.append(replace(clause, goals=goals))
    if not changed:
        return Rung(program, ())
    return Rung(render(repaired), ("reordered_by_dataflow",))


# --- constraint rewriting ------------------------------------------------


def _clpq_safe(tokens: list[Lexeme]) -> bool:
    """Whether an arithmetic expression has a clpq reading."""
    for token in tokens:
        if token.kind == "number":
            if re.fullmatch(r"\d+(?:\.\d+)?", token.value) is None:
                return False
            continue
        if token.kind == "variable":
            continue
        if token.value in CLPQ_UNSAFE_ATOMS:
            return False
        if token.kind == "atom":
            return False
        if token.value not in CLPQ_SAFE_FUNCTIONS:
            return False
    return True


def constrain(program: str) -> Rung:
    """Rewrite evaluable arithmetic as constraints, which have no goal order.

    ``is/2`` demands its right side be bound; ``{X = Expr}`` does not. Where an
    expression stays inside clpq's rationals, the rewrite makes the clause run
    in whatever order it was written, which is the property the permutation
    literature relies on. Integer division, truncation, and the transcendental
    functions have no clpq reading and are left as they are.
    """
    clauses = parse_clauses(program)
    changed = False
    repaired: list[Clause] = []
    for clause in clauses:
        if clause.kind != "rule":
            repaired.append(clause)
            continue
        goals: list[Goal] = []
        for goal in clause.goals:
            split = _is_split(goal)
            if split is None or not _clpq_safe(split[1]):
                goals.append(goal)
                continue
            origin = goal.tokens[0].start
            left_text = goal.text[:split[0][-1].end - origin] if split[0] else ""
            right_text = goal.text[split[1][0].start - origin:] if split[1] else ""
            rewritten = "{" + f"{left_text.strip()} = {right_text.strip()}" + "}"
            goals.append(Goal(text=rewritten, tokens=tuple(lex(rewritten))))
            changed = True
        repaired.append(replace(clause, goals=tuple(goals)))
    if not changed:
        return Rung(program, ())
    clauses, imported = add_constraint_import(repaired)
    return Rung(render(clauses), ("constrained_arithmetic", *imported))


# --- the ladder ----------------------------------------------------------


def repair_ladder(program: str) -> list[Rung]:
    """The programs to try after the text as written, cheapest repair first.

    Each rung builds on the one before it, and a rung that changes nothing is
    left out, so a caller never runs the same text twice.
    """
    rungs: list[Rung] = []
    seen = {program.strip()}

    def offer(rung: Rung, steps: tuple[str, ...]) -> str:
        if rung.program.strip() in seen:
            return rung.program
        seen.add(rung.program.strip())
        rungs.append(Rung(rung.program, steps))
        return rung.program

    try:
        normalized = normalize(program)
    except ValueError:
        return []
    current = offer(normalized, normalized.steps)

    try:
        reordered = reorder(current)
    except ValueError:
        return rungs
    if reordered.steps:
        current = offer(reordered, normalized.steps + reordered.steps)

    try:
        constrained = constrain(current)
    except ValueError:
        return rungs
    if constrained.steps:
        offer(
            constrained,
            (normalized.steps + reordered.steps + constrained.steps),
        )
    return rungs
