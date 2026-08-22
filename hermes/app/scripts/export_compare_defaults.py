#!/usr/bin/env python3
"""Export the tracked default document for every comparison-page family."""
from __future__ import annotations

import json
import sys
from html.parser import HTMLParser
from pathlib import Path
from typing import Any


REPO = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO))
from hermes.app.scripts import export_engine


OUT = export_engine.gallery_output(
    REPO / "hermes" / "app" / "web" / "generated" / "compare_defaults"
)
PAGES = {
    "fraction": REPO / "hermes/web/fraction-comparison/compare.html",
    "deformation": REPO / "hermes/web/deformation-comparison/compare.html",
}
OPS = {
    "fraction": "fraction_comparison_compare",
    "deformation": "deformation_compare",
}

FRACTION_DEFAULTS: dict[str, dict[str, Any]] = {
    "number_line_fraction_comparison": {"family": "number_line_fraction_comparison", "n1": 1, "d1": 3, "n2": 2, "d2": 5},
    "area_model_fraction_comparison": {"family": "area_model_fraction_comparison", "n1": 1, "d1": 3, "n2": 2, "d2": 5},
    "set_model_fraction_comparison": {"family": "set_model_fraction_comparison", "n1": 1, "d1": 3, "n2": 2, "d2": 5},
    "benchmark_fraction_comparison": {"family": "benchmark_fraction_comparison", "n1": 1, "d1": 3, "n2": 2, "d2": 5},
    "common_unit_fraction_comparison": {"family": "common_unit_fraction_comparison", "n1": 1, "d1": 3, "n2": 2, "d2": 5},
    "decimal_fraction_place_value_comparison": {"family": "decimal_fraction_place_value_comparison", "n1": 9, "d1": 10, "n2": 10, "d2": 100},
    "positional_decimal_reading": {"family": "positional_decimal_reading", "n1": 37, "d1": 100, "n2": 0},
    "decimal_comparison_by_aligned_units": {"family": "decimal_comparison_by_aligned_units", "n1": 9, "d1": 10, "n2": 10, "d2": 100},
    "decimal_addition_by_aligned_units": {"family": "decimal_addition_by_aligned_units", "n1": 12, "d1": 10, "n2": 3, "d2": 100},
    "decimal_subtraction_by_aligned_units": {"family": "decimal_subtraction_by_aligned_units", "n1": 12, "d1": 10, "n2": 3, "d2": 100},
    "decimal_place_unit_regrouping": {"family": "decimal_place_unit_regrouping", "n1": 3, "d1": 10, "n2": 100},
    "decimal_multiplication_rule": {"family": "decimal_multiplication_rule", "n1": 12, "d1": 10, "n2": 3, "d2": 10},
}

DEFORMATION_DEFAULTS: dict[str, dict[str, Any]] = {
    "quadrant_sign_error": {"family": "quadrant_sign_error", "x": -3, "y": 2},
    "reflection_by_rotation": {"family": "reflection_by_rotation", "vertices": "[[0,0],[4,0],[4,1],[2,1],[2,3],[0,3]]"},
    "flip_needed": {"family": "flip_needed", "piece": "l"},
    "unfillable_by_parity": {"family": "unfillable_by_parity", "cols": 5, "rows": 5},
    "angle_confused_with_ray_length": {"family": "angle_confused_with_ray_length", "degrees": 60, "short_length": 120, "long_length": 240},
    "bar_histogram_conflation": {"family": "bar_histogram_conflation", "pairs": '[{"category":"red","count":4},{"category":"blue","count":6}]'},
    "net_fold_failure": {"family": "net_fold_failure", "solid": "cube"},
    "boundary_peg_as_interior": {"family": "boundary_peg_as_interior", "vertices": "[[0,0],[4,0],[4,3],[0,3]]"},
}

DEFAULTS = {"fraction": FRACTION_DEFAULTS, "deformation": DEFORMATION_DEFAULTS}
PINNED = {"fraction": "number_line_fraction_comparison", "deformation": "quadrant_sign_error"}


class FamilyOptions(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.in_family = False
        self.values: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = dict(attrs)
        if tag == "select" and values.get("id") == "family":
            self.in_family = True
        elif tag == "option" and self.in_family and values.get("value") is not None:
            self.values.append(str(values["value"]))

    def handle_endtag(self, tag: str) -> None:
        if tag == "select" and self.in_family:
            self.in_family = False


def page_families(path: Path) -> set[str]:
    parser = FamilyOptions()
    parser.feed(path.read_text(encoding="utf-8"))
    return set(parser.values)


def assert_family_coverage() -> None:
    for page, path in PAGES.items():
        options = page_families(path)
        defaults = set(DEFAULTS[page])
        if options != defaults:
            missing = sorted(options - defaults)
            extra = sorted(defaults - options)
            raise RuntimeError(
                f"{page} comparison defaults do not match page options; "
                f"missing={missing}, extra={extra}"
            )


def with_inputs(document: dict[str, Any], inputs: dict[str, Any]) -> dict[str, Any]:
    baked = dict(document)
    baked["inputs"] = dict(inputs)
    return baked


def export() -> int:
    args = export_engine.parse_args(__doc__, default_out=OUT)
    out = args.out.resolve()
    assert_family_coverage()
    written = 0
    with export_engine.worker_requester() as request:
        for page in ("fraction", "deformation"):
            page_out = out / page
            page_out.mkdir(parents=True, exist_ok=True)
            for family, inputs in DEFAULTS[page].items():
                document = request(OPS[page], **inputs)
                export_engine.write_json(
                    page_out / f"{family}.json", with_inputs(document, inputs)
                )
                written += 1
    print(f"exported {written} comparison defaults to {out}")
    return 0


def canonical(value: object) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def pinned_repost_check() -> int:
    failed: list[str] = []
    with export_engine.worker_requester() as request:
        for page, family in PINNED.items():
            path = OUT / page / f"{family}.json"
            baked = json.loads(path.read_text(encoding="utf-8"))
            inputs = baked.get("inputs")
            if not isinstance(inputs, dict):
                failed.append(f"{page}/{family}: baked inputs absent")
                continue
            live = with_inputs(request(OPS[page], **inputs), inputs)
            if canonical(live) != canonical(baked):
                failed.append(f"{page}/{family}: live re-POST differs")
    if failed:
        for issue in failed:
            print(issue)
        return 1
    print("compare default re-POST current: 2 pinned families")
    return 0


def check() -> int:
    drift = export_engine.check_exporter(Path(__file__), OUT)
    if drift:
        return drift
    return pinned_repost_check()


if __name__ == "__main__":
    raise SystemExit(check() if "--check" in sys.argv else export())
