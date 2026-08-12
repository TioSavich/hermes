#!/usr/bin/env python3
"""Focused unit checks for the central Markdown store builder."""

from __future__ import annotations

import sys
from pathlib import Path
import unittest


sys.path.insert(0, str(Path(__file__).resolve().parent))

from build_central_markdown_store import (  # noqa: E402
    format_operation,
    lesson_code_from_dir_name,
    lesson_dir_name_from_code,
)


class LessonMappingTests(unittest.TestCase):
    def test_grade_one_mapping_in_both_directions(self) -> None:
        directory = "Grade1-1-13-Lesson-teacher-guide-"
        code = "IM-G1-U1-L13"
        self.assertEqual(lesson_code_from_dir_name(directory), code)
        self.assertEqual(lesson_dir_name_from_code(code), directory)

    def test_kindergarten_mapping_in_both_directions(self) -> None:
        directory = "Kindergarten-2-7-Lesson-teacher-guide-"
        code = "IM-GK-U2-L7"
        self.assertEqual(lesson_code_from_dir_name(directory), code)
        self.assertEqual(lesson_dir_name_from_code(code), directory)

    def test_mapping_rejects_invalid_names(self) -> None:
        with self.assertRaises(ValueError):
            lesson_code_from_dir_name("Grade1-U1-L13")
        with self.assertRaises(ValueError):
            lesson_dir_name_from_code("IM-G1-1-13")


class OperationPhraseTests(unittest.TestCase):
    def test_addition_phrase(self) -> None:
        self.assertEqual(format_operation("add", [7, 1]), "Addition: 7 + 1")

    def test_unknown_operation_falls_back_to_term_shape(self) -> None:
        self.assertEqual(
            format_operation("compose_unknown", [3, "quarter"]),
            "compose_unknown(3, quarter)",
        )


if __name__ == "__main__":
    unittest.main()
