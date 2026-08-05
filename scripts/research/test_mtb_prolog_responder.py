#!/usr/bin/env python3
"""Unit tests for the isolated MathTutorBench Prolog responder."""
from __future__ import annotations

import os
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

HERE = Path(__file__).resolve().parent
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))

import mtb_prolog_repair as repair
import mtb_prolog_responder as responder
import prolog_arm_report as report


BENIGN = """\
:- use_module(library(clpq)).
apples(16).
eaten(3).
solve(Answer) :- apples(Laid), eaten(Eaten), {Answer = Laid - Eaten}.
"""


class ScreenTests(unittest.TestCase):
    def test_benign_clpq_program_passes(self) -> None:
        self.assertEqual(responder.screen_program(BENIGN), responder.ScreenResult(True))

    def test_each_denylist_rule_is_named(self) -> None:
        cases = {
            "shell": "shell(ls)",
            "process_create": "process_create(path(ls), [], _)",
            "exec": "exec(ls, [], _)",
            "open": "open('/tmp/x', read, _)",
            "close": "close(_)" ,
            "see": "see('/tmp/x')",
            "tell": "tell('/tmp/x')",
            "read_term": "read_term(_, [])",
            "consult": "consult('/tmp/x')",
            "ensure_loaded": "ensure_loaded('/tmp/x')",
            "load_files": "load_files('/tmp/x', [])",
            "assert": "assert(x)",
            "asserta": "asserta(x)",
            "assertz": "assertz(x)",
            "retract": "retract(x)",
            "halt": "halt",
            "setenv": "setenv(x, y)",
            "getenv": "getenv(x, _)",
            "absolute_file_name": "absolute_file_name(x, _)",
            "tmp_file": "tmp_file(x, _)",
            "delete_file": "delete_file('/tmp/x')",
            "directory_files": "directory_files('/tmp', _)",
            "http_": "http_request(x)",
            "socket": "socket(_, _, _)",
            "qsave": "qsave_program('/tmp/x')",
            "dollar": "$hidden",
        }
        for name, body in cases.items():
            with self.subTest(name=name):
                result = responder.screen_program(f"solve(_) :- {body}.")
                self.assertFalse(result.allowed)
                self.assertIsNotNone(result.reason)
                self.assertIn(
                    name if name in {"http_", "dollar"} else body.split("(")[0],
                    result.reason or "",
                )

    def test_disallowed_use_module_is_rejected(self) -> None:
        result = responder.screen_program(
            ":- use_module(library(filesex)).\nsolve(1)."
        )
        self.assertEqual(result.reason, "disallowed_use_module")

    def test_other_directive_is_rejected(self) -> None:
        result = responder.screen_program(":- initialization(main).\nsolve(1).")
        self.assertEqual(result.reason, "disallowed_directive")


class RunnerTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.scratch = Path(self.temporary.name)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_handwritten_programs_cover_runner_outcomes(self) -> None:
        solved = responder.run_program(BENIGN, self.scratch)
        self.assertEqual((solved.outcome, solved.value), ("ran", "13"))

        syntax = responder.run_program("solve(Answer :- .", self.scratch)
        self.assertEqual(syntax.outcome, "syntax_error")

        no_solution = responder.run_program("solve(_) :- fail.", self.scratch)
        self.assertEqual(no_solution.outcome, "no_solution")

    def test_loop_hits_wall_limit_and_process_is_gone(self) -> None:
        result = responder.run_program(
            "solve(_) :- repeat, fail.", self.scratch, wall_timeout_seconds=0.1
        )
        self.assertEqual(result.outcome, "timeout")
        self.assertEqual(result.detail, "wall_clock")
        self.assertIsNotNone(result.pid)
        with self.assertRaises(ProcessLookupError):
            os.kill(result.pid or -1, 0)

    def test_clpq_variable_is_grounded_to_integer_maximum(self) -> None:
        program = """\
:- use_module(library(clpq)).
solve(Answer) :- {Answer >= 0, Answer =< 13}.
"""
        result = responder.run_program(program, self.scratch)
        self.assertEqual(
            (result.outcome, result.value), ("ran_grounded", "13"))

    def test_clpq_variable_without_finite_maximum_stays_nonnumeric(self) -> None:
        program = """\
:- use_module(library(clpq)).
solve(Answer) :- {Answer >= 0}.
"""
        result = responder.run_program(program, self.scratch)
        self.assertEqual(result.outcome, "nonnumeric")

    def test_undefined_solve_has_specific_runtime_class(self) -> None:
        result = responder.run_program("quantity(1).", self.scratch)
        self.assertEqual(result.outcome, "runtime_error")
        self.assertEqual(result.error_class, "undefined_solve")

    def test_instantiation_error_has_specific_runtime_class(self) -> None:
        result = responder.run_program(
            "solve(Answer) :- Unknown > 1, Answer = Unknown.", self.scratch)
        self.assertEqual(result.outcome, "runtime_error")
        self.assertEqual(result.error_class, "instantiation_error")

    def test_type_error_has_specific_runtime_class(self) -> None:
        result = responder.run_program(
            "solve(Answer) :- Answer is not_a_number + 1.", self.scratch)
        self.assertEqual(result.outcome, "runtime_error")
        self.assertEqual(result.error_class, "type_error")

    def test_transcript_keeps_program_and_process_record(self) -> None:
        transcript_dir = self.scratch / "transcripts"
        arm = responder.PrologResponder(
            "test-model", guarded=False, scratch_dir=str(self.scratch),
            transcript_dir=str(transcript_dir),
        )
        reply = f"```prolog\n{BENIGN}```"
        with mock.patch.object(
                responder.mtb_responders, "complete", return_value=reply):
            answer = arm.respond(
                prompt="benchmark prompt", stop=None,
                example={"question": "How many apples remain?"},
                task_name="problem_solving",
            )
        arm.close()

        self.assertEqual(answer, "Final answer: 13")
        self.assertIsNotNone(arm.transcript_path)
        records = [
            json.loads(line)
            for line in (arm.transcript_path or Path()).read_text(
                encoding="utf-8").splitlines()
        ]
        self.assertEqual(len(records), 1)
        record = records[0]
        self.assertEqual(record["program"], BENIGN.strip())
        self.assertEqual(record["raw_reply"], reply)
        self.assertEqual(record["screen"], {"allowed": True, "reason": None})
        self.assertEqual(record["outcome"], "ran")
        self.assertIn("__MTB_ANSWER__13", record["swipl_stdout"])
        self.assertEqual(record["swipl_stderr"], "")
        self.assertIsInstance(record["seconds"], float)


class RepairReaderTests(unittest.TestCase):
    def test_clause_end_is_not_read_as_a_decimal_point(self) -> None:
        clauses = repair.parse_clauses("a(1).\nb(2).\n")
        self.assertEqual(
            [clause.functor for clause in clauses], [("a", 1), ("b", 1)])

    def test_decimal_number_keeps_its_fraction(self) -> None:
        clauses = repair.parse_clauses("rate(1.5).\n")
        self.assertEqual(clauses[0].head_text, "rate(1.5)")

    def test_query_and_directive_are_distinguished(self) -> None:
        clauses = repair.parse_clauses(":- dynamic x/1.\n?- solve(A).\n")
        self.assertEqual([clause.kind for clause in clauses],
                         ["directive", "query"])

    def test_quoted_atom_holding_a_period_is_one_token(self) -> None:
        clauses = repair.parse_clauses("name('a. b').\n")
        self.assertEqual(len(clauses), 1)


class RepairStepTests(unittest.TestCase):
    def test_query_line_is_dropped(self) -> None:
        rung = repair.normalize("solve(1).\n?- solve(X), write(X).")
        self.assertIn("dropped_query", rung.steps)
        self.assertNotIn("write", rung.program)

    def test_allowed_import_survives_and_others_do_not(self) -> None:
        rung = repair.normalize(
            ":- use_module(library(clpq)).\n"
            ":- initialization(main).\n"
            "solve(A) :- {A = 1}."
        )
        self.assertIn("use_module(library(clpq))", rung.program)
        self.assertIn("dropped_directive", rung.steps)

    def test_root_predicate_of_another_name_is_aliased(self) -> None:
        rung = repair.normalize("answer(A) :- A is 2 * 3.")
        self.assertIn("aliased_answer_predicate", rung.steps)
        self.assertIn("solve(A)", rung.program)

    def test_two_roots_are_too_ambiguous_to_alias(self) -> None:
        rung = repair.normalize("answer(A) :- A is 1.\nresult(B) :- B is 2.")
        self.assertNotIn("aliased_answer_predicate", rung.steps)

    def test_wider_solve_is_aliased_to_its_last_argument(self) -> None:
        rung = repair.normalize("solve(A, B, C) :- C is A + B.")
        self.assertIn("aliased_answer_arity", rung.steps)
        self.assertIn("solve(_, _, A)", rung.program)

    def test_clauses_solve_cannot_reach_are_dropped(self) -> None:
        rung = repair.normalize(
            "solve(A) :- A is 1.\nmain :- solve(X), write(X).")
        self.assertIn("dropped_unreachable_clauses", rung.steps)
        self.assertNotIn("main", rung.program)

    def test_a_predicate_called_inside_findall_survives_pruning(self) -> None:
        rung = repair.normalize(
            "?- go.\n"
            "sale(14).\nsale(22).\n"
            "solve(A) :- findall(X, sale(X), L), sum_list(L, A)."
        )
        self.assertIn("sale(14)", rung.program)

    def test_atom_used_as_the_target_of_is_becomes_a_variable(self) -> None:
        rung = repair.normalize("solve(total) :- total is 6 * 7.")
        self.assertIn("capitalized_pseudo_variables", rung.steps)
        self.assertIn("V_total", rung.program)

    def test_a_defined_predicate_name_is_not_taken_for_a_variable(self) -> None:
        rung = repair.normalize("total(42).\nsolve(A) :- total(A).")
        self.assertNotIn("capitalized_pseudo_variables", rung.steps)

    def test_clpq_import_is_added_only_for_brace_constraints(self) -> None:
        with_braces = repair.normalize("solve(A) :- {A = 1}.")
        self.assertIn("added_clpq_import", with_braces.steps)
        without = repair.normalize("solve(A) :- A is 1.")
        self.assertNotIn("added_clpq_import", without.steps)


class ReorderTests(unittest.TestCase):
    def test_evaluation_moves_after_what_binds_its_inputs(self) -> None:
        rung = repair.reorder("solve(T) :- T is A * B, A = 7, B = 12.")
        self.assertEqual(rung.steps, ("reordered_by_dataflow",))
        body = rung.program.split(":-")[1]
        self.assertLess(body.index("A = 7"), body.index("T is A * B"))

    def test_a_body_that_already_runs_is_left_alone(self) -> None:
        rung = repair.reorder("solve(T) :- A = 7, B = 12, T is A * B.")
        self.assertEqual(rung.steps, ())

    def test_generate_and_test_keeps_its_generator_first(self) -> None:
        rung = repair.reorder(
            "solve(X) :- between(1, 9, X), X > 4, Y is X + 1, Y > 0.")
        self.assertEqual(rung.steps, ())

    def test_a_body_with_a_disjunction_is_not_reordered(self) -> None:
        rung = repair.reorder(
            "solve(T) :- (T is A ; T is B), A = 1, B = 2.")
        self.assertEqual(rung.steps, ())

    def test_a_body_nothing_can_bind_keeps_the_author_order(self) -> None:
        rung = repair.reorder("solve(T) :- T is A + B, C > 1.")
        self.assertEqual(rung.steps, ())


class ConstrainTests(unittest.TestCase):
    def test_rational_arithmetic_becomes_a_constraint(self) -> None:
        rung = repair.constrain("solve(T) :- T is 3 * (A + 2), A = 1.")
        self.assertIn("constrained_arithmetic", rung.steps)
        self.assertIn("{T = 3 * (A + 2)}", rung.program)

    def test_integer_division_has_no_constraint_reading(self) -> None:
        rung = repair.constrain("solve(T) :- T is 30 // 4.")
        self.assertEqual(rung.steps, ())

    def test_a_named_function_has_no_constraint_reading(self) -> None:
        for expression in ("max(A, B)", "truncate(A)", "A mod 3", "sqrt(A)"):
            with self.subTest(expression=expression):
                rung = repair.constrain(f"solve(T) :- T is {expression}.")
                self.assertEqual(rung.steps, ())


class LadderTests(unittest.TestCase):
    def test_every_rung_is_a_program_no_earlier_rung_already_was(self) -> None:
        rungs = repair.repair_ladder(
            "solve(T) :- T is A * B, A = 7, B = 12.")
        programs = [rung.program.strip() for rung in rungs]
        self.assertEqual(len(programs), len(set(programs)))

    def test_steps_accumulate_down_the_ladder(self) -> None:
        rungs = repair.repair_ladder(
            ":- initialization(main).\n"
            "solve(T) :- T is A * B, A = 7, B = 12.\n"
            "main :- solve(X), write(X)."
        )
        self.assertIn("dropped_directive", rungs[0].steps)
        self.assertIn("dropped_directive", rungs[-1].steps)
        self.assertIn("reordered_by_dataflow", rungs[-1].steps)

    def test_text_that_will_not_parse_yields_no_rungs_or_no_answer(self) -> None:
        # The reader is total over token streams, so a broken program may still
        # produce rungs; what it must never do is raise into the arm.
        for text in ("solve(", ")))", "", "solve(A :- , B is 1."):
            with self.subTest(text=text):
                repair.repair_ladder(text)


class VoteTests(unittest.TestCase):
    def _attempt(self, outcome: str, value: str | None) -> responder.Attempt:
        return responder.Attempt(outcome, value, 0, (), None, None, "")

    def test_the_value_most_programs_reached_wins(self) -> None:
        value, tally = responder._vote([
            self._attempt("ran", "12"),
            self._attempt("ran", "7"),
            self._attempt("ran", "7"),
        ])
        self.assertEqual(value, "7")
        self.assertEqual(tally, {"12": 1, "7": 2})

    def test_a_program_that_did_not_run_casts_no_vote(self) -> None:
        value, tally = responder._vote([
            self._attempt("runtime_error", None),
            self._attempt("ran", "5"),
        ])
        self.assertEqual((value, tally), ("5", {"5": 1}))

    def test_a_tie_goes_to_the_earliest_sample(self) -> None:
        value, _ = responder._vote([
            self._attempt("ran", "9"), self._attempt("ran", "4")])
        self.assertEqual(value, "9")

    def test_no_answer_at_all_is_no_answer(self) -> None:
        self.assertEqual(responder._vote([]), (None, {}))
        self.assertEqual(
            responder._vote([self._attempt("timeout", None)]), (None, {}))


class ArmRepairTests(unittest.TestCase):
    """The arm's own behaviour around repair, sampling, and the fallback."""

    DECLARATIVE = "```prolog\nsolve(T) :- T is A * B, A = 7, B = 12.\n```"

    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.scratch = Path(self.temporary.name)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def _arm(self, **options: str) -> responder.PrologResponder:
        return responder.PrologResponder(
            "test-model", guarded=False, scratch_dir=str(self.scratch),
            **options,
        )

    def _ask(self, arm: responder.PrologResponder, replies: list[str]) -> str:
        with mock.patch.object(
                responder.mtb_responders, "complete", side_effect=replies):
            return arm.respond(
                prompt="benchmark prompt", stop=None,
                example={"question": "How many in all?"},
                task_name="problem_solving",
            )

    def test_repair_recovers_a_program_the_arm_used_to_discard(self) -> None:
        arm = self._arm()
        self.assertEqual(self._ask(arm, [self.DECLARATIVE]), "Final answer: 84")
        self.assertEqual(arm.stats["repaired"], 1)

    def test_repair_off_reproduces_the_arm_before_the_ladder(self) -> None:
        arm = self._arm(repair="off")
        self.assertEqual(self._ask(arm, [self.DECLARATIVE]), "")
        self.assertEqual(arm.stats["repaired"], 0)
        self.assertEqual(arm.stats["runtime_error"], 1)

    def test_a_program_that_runs_is_never_repaired(self) -> None:
        arm = self._arm()
        self.assertEqual(
            self._ask(arm, [f"```prolog\n{BENIGN}```"]), "Final answer: 13")
        self.assertEqual(arm.stats["repaired"], 0)

    def test_samples_vote_on_what_the_interpreter_returned(self) -> None:
        arm = self._arm(samples="3")
        replies = [
            "```prolog\nsolve(T) :- T is 5 * 5.\n```",
            "```prolog\nsolve(T) :- T is 4 * 6.\n```",
            "```prolog\nsolve(T) :- T is 12 * 2.\n```",
        ]
        self.assertEqual(self._ask(arm, replies), "Final answer: 24")
        self.assertEqual(arm.stats["prolog_model_calls"], 3)

    def test_samples_that_do_not_run_leave_the_one_that_did(self) -> None:
        arm = self._arm(samples="2")
        replies = ["not a program at all", "```prolog\nsolve(T) :- T is 6.\n```"]
        self.assertEqual(self._ask(arm, replies), "Final answer: 6")

    def test_more_than_one_sample_needs_spread_to_be_worth_taking(self) -> None:
        self.assertEqual(self._arm().temperature, 0.0)
        self.assertGreater(self._arm(samples="4").temperature, 0.0)
        self.assertEqual(self._arm(samples="4", temperature="0.3").temperature, 0.3)

    def test_the_record_names_the_rung_and_the_steps_it_took(self) -> None:
        transcripts = self.scratch / "transcripts"
        arm = self._arm(transcript_dir=str(transcripts))
        self._ask(arm, [self.DECLARATIVE])
        arm.close()
        record = json.loads(
            (arm.transcript_path or Path()).read_text(encoding="utf-8"))
        self.assertGreater(record["rung"], 0)
        self.assertIn("reordered_by_dataflow", record["repair_steps"])
        self.assertEqual(len(record["attempts"]), 1)

    def test_an_unsafe_program_is_refused_at_every_rung(self) -> None:
        arm = self._arm()
        reply = (
            "```prolog\n:- initialization(main).\n"
            "solve(A) :- A is 1, shell('ls').\n"
            "main :- solve(X), write(X).\n```"
        )
        self.assertEqual(self._ask(arm, [reply]), "")
        self.assertEqual(arm.stats["rejected_unsafe"], 1)

    def test_bad_options_are_refused_at_construction(self) -> None:
        for options in ({"repair": "maybe"}, {"samples": "0"}):
            with self.subTest(options=options):
                with self.assertRaises(ValueError):
                    self._arm(**options)


class ReportTests(unittest.TestCase):
    def test_report_crosses_outcomes_with_correctness(self) -> None:
        built = report.build_report(
            {
                0: {"position": 0, "prediction": "26", "target": "26"},
                1: {"position": 1, "prediction": None, "target": "72"},
            },
            {
                0: {"position": 0, "outcome": "ran"},
                1: {"position": 1, "outcome": "no_program"},
            },
        )
        self.assertEqual(built["ran_rate"], 0.5)
        self.assertEqual(built["outcomes"]["ran"]["correct"], 1)
        self.assertEqual(built["outcomes"]["no_program"]["incorrect"], 1)

    def test_report_separates_answers_that_needed_a_repair(self) -> None:
        built = report.build_report(
            {
                0: {"position": 0, "prediction": "54", "target": "54"},
                1: {"position": 1, "prediction": "9", "target": "12"},
                2: {"position": 2, "prediction": "7", "target": "7"},
            },
            {
                0: {"position": 0, "outcome": "ran", "rung": 2,
                    "repair_steps": ["reordered_by_dataflow"]},
                1: {"position": 1, "outcome": "ran", "rung": 1,
                    "repair_steps": ["dropped_query"]},
                2: {"position": 2, "outcome": "ran", "rung": 0},
            },
        )
        self.assertEqual(built["repaired"]["items"], 2)
        self.assertEqual(built["repaired"]["correct"], 1)
        self.assertEqual(built["repaired"]["incorrect"], 1)
        self.assertEqual(
            built["repaired"]["steps"]["reordered_by_dataflow"]["correct"], 1)

    def test_report_counts_grounded_runs_in_overall_ran_rate(self) -> None:
        built = report.build_report(
            {
                0: {"position": 0, "prediction": "13", "target": "13"},
                1: {"position": 1, "prediction": None, "target": "2"},
            },
            {
                0: {"position": 0, "outcome": "ran_grounded"},
                1: {"position": 1, "outcome": "nonnumeric"},
            },
        )
        self.assertEqual(built["ran_rate"], 0.5)
        self.assertEqual(built["outcomes"]["ran_grounded"]["correct"], 1)

    def test_report_rejects_partial_join(self) -> None:
        with self.assertRaisesRegex(ValueError, "position mismatch"):
            report.build_report(
                {0: {"position": 0, "prediction": "1", "target": "1"}},
                {1: {"position": 1, "outcome": "ran"}},
            )


if __name__ == "__main__":
    unittest.main()
