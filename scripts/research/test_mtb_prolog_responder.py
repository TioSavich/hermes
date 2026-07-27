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
