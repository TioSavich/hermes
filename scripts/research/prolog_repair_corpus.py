#!/usr/bin/env python3
"""Authored replies for measuring what the Prolog arm's harness throws away.

Every word problem and every program here was written for this file. None of
them is a benchmark item, a dataset row, or a model's actual output on either,
and the corpus is never scored against a benchmark target. What it holds is one
reply per way a generated program can be a correct quantity model that the arm
does not run, plus the cases that must keep failing.

The four verdicts are the whole point of the fixture:

``runs``
    The program runs as written. Repair must not fire, and the answer must not
    move. This is the guard against a repair that rewrites working programs.
``harness``
    The program says the right thing about the quantities and the arm discards
    it. Repair must recover it, at the value the program already meant.
``model``
    The program does not determine an answer. Repair must not manufacture one.
    This is the guard against a ladder that answers by guessing.
``unsafe``
    The screen refuses the program. Every rung of the ladder must also be
    refused, so repair can never widen what runs.

The failure shapes are the ones this repository has already recorded from real
runs: goals in the order the sentences arrived, lowercase words used as
variables, prose and query lines around the program, and comparisons against
variables nothing has bound (`docs/research/2026-08-01-diagnosis-prolog-arm.md`).
"""
from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class Case:
    """One authored reply, with what the arm must do with it."""

    name: str
    verdict: str  # "runs", "harness", "model", or "unsafe"
    question: str
    reply: str
    value: str | None = None
    note: str = ""


def _fence(program: str) -> str:
    return f"```prolog\n{program}\n```"


CASES: tuple[Case, ...] = (
    # --- programs that already run: repair must leave every one alone -----
    Case(
        name="clpq_facts_and_rule",
        verdict="runs",
        question="A greenhouse has 7 shelves with 12 seedlings on each shelf. "
                 "How many seedlings are in the greenhouse?",
        value="84",
        reply=_fence(""":- use_module(library(clpq)).
shelves(7).
per_shelf(12).
solve(Seedlings) :-
    shelves(S),
    per_shelf(P),
    {Seedlings = S * P}."""),
    ),
    Case(
        name="evaluable_in_dataflow_order",
        verdict="runs",
        question="A baker makes 60 rolls, sells 45, and then bakes 12 more. "
                 "How many rolls does the baker have?",
        value="27",
        reply=_fence("""solve(Rolls) :-
    Made is 60,
    Sold is 45,
    Extra is 12,
    Rolls is Made - Sold + Extra."""),
    ),
    Case(
        name="clpq_division_keeps_the_fraction",
        verdict="runs",
        question="A tank holds 50 litres and is poured evenly into 4 jugs. "
                 "How many litres are in each jug?",
        value="12.500000000000000",
        reply=_fence(""":- use_module(library(clpq)).
solve(Litres) :- {Litres = 50 / 4}."""),
    ),
    Case(
        name="integer_division_stays_evaluable",
        verdict="runs",
        question="A class of 30 students is split into teams of 4. "
                 "How many full teams are there?",
        value="7",
        reply=_fence("""solve(Teams) :- Teams is 30 // 4."""),
        note="clpq has no integer division, so the constraint rung must "
             "decline this goal rather than rewrite it.",
    ),
    Case(
        name="list_aggregate",
        verdict="runs",
        question="A stall sold 14 jars on Friday, 22 on Saturday, and 9 on "
                 "Sunday. How many jars did it sell?",
        value="45",
        reply=_fence("""sales([14, 22, 9]).
solve(Jars) :- sales(Days), sum_list(Days, Jars)."""),
    ),
    Case(
        name="prose_wrapped_program",
        verdict="runs",
        question="A cyclist rides 18 kilometres on each of 5 mornings and 24 "
                 "kilometres on Saturday. How far does the cyclist ride?",
        value="114",
        reply="""Here is the program for this problem.

```prolog
solve(Km) :-
    Weekday is 18 * 5,
    Km is Weekday + 24.
```

The interpreter binds Km.""",
    ),
    Case(
        name="unfenced_program",
        verdict="runs",
        question="A shop stocks 3 crates of 24 bottles and 17 bottles break. "
                 "How many bottles remain?",
        value="55",
        reply="""solve(Bottles) :-
    Stocked is 3 * 24,
    Bottles is Stocked - 17.""",
    ),

    # --- the harness discards a correct quantity model ---------------------
    Case(
        name="declarative_goal_order",
        verdict="harness",
        question="A courier delivers 9 parcels an hour for 6 hours. "
                 "How many parcels is that?",
        value="54",
        reply=_fence("""solve(Parcels) :-
    Parcels is Rate * Hours,
    Rate is 9,
    Hours is 6."""),
        note="The model states the relation before the quantities it reads, "
             "which is the order the sentence gave and the order Prolog's "
             "declarative reading permits. is/2 raises an instantiation error.",
    ),
    Case(
        name="declarative_order_in_a_helper",
        verdict="harness",
        question="A stand takes 240 dollars and spends 95 dollars on supplies. "
                 "What is its profit?",
        value="145",
        reply=_fence("""solve(Profit) :- profit(Profit).

profit(P) :-
    P is Takings - Supplies,
    Takings is 240,
    Supplies is 95."""),
    ),
    Case(
        name="trailing_query_line",
        verdict="harness",
        question="A library lends 36 books a day for 7 days. "
                 "How many loans is that?",
        value="252",
        reply=_fence(""":- use_module(library(clpq)).
solve(Loans) :- {Loans = 36 * 7}.
?- solve(X), write(X), nl."""),
        note="The query is a caller's line, not part of the program, and it "
             "names write/1, so the screen refuses the whole file.",
    ),
    Case(
        name="initialization_and_main",
        verdict="harness",
        question="A printer runs 45 pages a minute for 8 minutes. "
                 "How many pages is that?",
        value="360",
        reply=_fence(""":- initialization(main).

solve(Pages) :- Pages is 45 * 8.

main :- solve(P), format("~w pages~n", [P])."""),
    ),
    Case(
        name="output_goal_inside_solve",
        verdict="harness",
        question="A farm collects 130 eggs and packs them into trays of 10. "
                 "How many trays is that?",
        value="13",
        reply=_fence("""solve(Trays) :-
    Trays is 130 / 10,
    format("The answer is ~w", [Trays])."""),
    ),
    Case(
        name="lowercase_words_as_variables",
        verdict="harness",
        question="A hall sets out 16 rows of 11 chairs. How many chairs is that?",
        value="176",
        reply=_fence("""solve(chairs) :-
    rows is 16,
    per_row is 11,
    chairs is rows * per_row."""),
        note="is/2 evaluates the right side and then tries to unify a number "
             "with an atom, so the clause fails without raising anything.",
    ),
    Case(
        name="answer_predicate_renamed",
        verdict="harness",
        question="A team scores 4 goals in each of 12 matches. "
                 "How many goals is that?",
        value="48",
        reply=_fence("""answer(Goals) :-
    Matches is 12,
    PerMatch is 4,
    Goals is Matches * PerMatch."""),
        note="The runner asks for solve/1 and this program is a root under "
             "another name, so nothing about it is ambiguous.",
    ),
    Case(
        name="braces_without_the_import",
        verdict="harness",
        question="A depot ships 25 pallets holding 32 boxes each. "
                 "How many boxes is that?",
        value="800",
        reply=_fence("""solve(Boxes) :- {Boxes = 25 * 32}."""),
    ),
    Case(
        name="dynamic_declaration",
        verdict="harness",
        question="A route covers 12 stops twice a day for 5 days. "
                 "How many stops is that?",
        value="120",
        reply=_fence(""":- dynamic stops/1.

solve(Stops) :- Stops is 12 * 2 * 5."""),
    ),
    Case(
        name="comparison_before_its_binding",
        verdict="harness",
        question="A bin holds 90 apples. After 34 are taken, how many remain, "
                 "and is that more than 50?",
        value="56",
        reply=_fence("""solve(Left) :-
    Left > 50,
    Left is 90 - 34."""),
        note="The test is stated before the quantity it tests, which is the "
             "order the question asked it in.",
    ),
    Case(
        name="facts_gathered_inside_findall",
        verdict="harness",
        question="A stall sold 14 jars on Friday, 22 on Saturday, and 9 on "
                 "Sunday. How many jars did it sell?",
        value="45",
        reply=_fence("""sold(friday, 14).
sold(saturday, 22).
sold(sunday, 9).

solve(Jars) :-
    findall(N, sold(_, N), Counts),
    sum_list(Counts, Jars).

?- solve(J), writeln(J)."""),
        note="The facts are reached only from inside findall/3, so pruning "
             "has to see calls nested in a meta-goal's arguments.",
    ),
    Case(
        name="query_and_prose_and_bad_order",
        verdict="harness",
        question="A cafe sells 23 coffees an hour across a 9 hour day. "
                 "How many coffees is that?",
        value="207",
        reply="""I will model the quantities and let Prolog do the arithmetic.

```prolog
% coffees per hour times hours open
solve(Coffees) :-
    Coffees is Rate * Hours,
    Rate is 23,
    Hours is 9.
```

?- solve(X).""",
        note="Three defects at once, which is what a real reply looks like.",
    ),

    # --- the model is wrong: no rung may answer ----------------------------
    Case(
        name="quantities_never_stated",
        verdict="model",
        question="A workshop builds chairs and tables. How many legs is that?",
        reply=_fence("""solve(Count, PerItem, Legs) :- Legs is Count * PerItem."""),
        note="Nothing binds Count or PerItem. Aliasing solve/3 to solve/1 is "
             "still right, and the program still cannot answer.",
    ),
    Case(
        name="unbounded_constraint",
        verdict="model",
        question="A jar holds more than 20 marbles. How many marbles is that?",
        reply=_fence(""":- use_module(library(clpq)).
solve(Marbles) :- {Marbles > 20}."""),
    ),
    Case(
        name="clause_that_cannot_hold",
        verdict="model",
        question="A pot holds 12 litres and 15 litres are poured out. "
                 "How many litres are left?",
        reply=_fence("""solve(Left) :- Left is 12 - 15, Left > 0."""),
        note="The program runs and the conjunction fails. no_solution is the "
             "honest outcome and repair must not turn it into a number.",
    ),
    Case(
        name="no_program_at_all",
        verdict="model",
        question="A bus carries 40 passengers on each of 3 routes. "
                 "How many passengers is that?",
        reply="I would multiply forty by three to get one hundred and twenty.",
    ),
    Case(
        name="unparseable_program",
        verdict="model",
        question="A crate holds 18 tins across 6 layers. "
                 "How many tins per layer?",
        reply=_fence("""solve(Tins :- , Layers is 6."""),
    ),

    # --- the screen refuses, and every rung must go on refusing ------------
    Case(
        name="shell_call",
        verdict="unsafe",
        question="A drive holds 500 files. How many files is that?",
        reply=_fence("""solve(Files) :- shell('ls /'), Files is 500."""),
    ),
    Case(
        name="file_read",
        verdict="unsafe",
        question="A ledger records 12 entries. How many entries is that?",
        reply=_fence("""solve(Entries) :-
    open('/etc/passwd', read, Stream),
    Entries is 12."""),
    ),
    Case(
        name="assert_into_the_database",
        verdict="unsafe",
        question="A shelf holds 8 boxes of 5. How many items is that?",
        reply=_fence("""solve(Items) :-
    Items is 8 * 5,
    assertz(cached(Items))."""),
    ),
    Case(
        name="unsafe_goal_reached_only_from_main",
        verdict="unsafe",
        question="A bag holds 22 coins. How many coins is that?",
        reply=_fence(""":- initialization(main).

solve(Coins) :- Coins is 22, shell('rm -rf /tmp/x').

main :- solve(C), write(C)."""),
        note="Pruning removes main/0, and the unsafe goal is inside solve/1, "
             "so the pruned program must still be refused.",
    ),
    Case(
        name="disallowed_library",
        verdict="unsafe",
        question="A folder holds 4 files of 3 pages. How many pages is that?",
        reply=_fence(""":- use_module(library(filesex)).
solve(Pages) :- Pages is 4 * 3, directory_files('/tmp', _)."""),
    ),
)


def by_verdict(verdict: str) -> tuple[Case, ...]:
    return tuple(case for case in CASES if case.verdict == verdict)
