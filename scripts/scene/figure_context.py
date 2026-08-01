#!/usr/bin/env python3
"""Locate the article and the page for one student-work figure crop.

The first description pass saw a cropped PNG and nothing else. That is why it
called a candy-grouping figure "base ten" and misread N4's task. The article
was on disk the whole time and was never joined.

This module is that join, and only that join. It calls no model. Codex is the
single arm (Tio, 2026-08-01), so the driver that called REALLMS was removed and
this is what survived it.

Coverage, measured 2026-08-01 over the 1,359 student-work crops:

    article text     341 of 342 keys      MERJ_Ramful_2014_Proportional is the
                                          miss; 3 figures, no text on this machine
    page location    334 of 341 articles  the other 7 carry a page offset

Usage:

    from figure_context import figure_context
    ctx = figure_context(Path("data/.../ESM_Abele_1978_Usage/p3_1.png"))
    ctx.article_text     # the docling markdown, or None
    ctx.page_no          # which page the figure sits on, or None
    ctx.caption          # docling's caption, or None
    ctx.join             # "page_index" | "page_offset" | "absent"
"""

from __future__ import annotations

import json
import os
import re
from dataclasses import dataclass
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]


def shared_root() -> Path:
    """Return the checkout holding the gitignored data.

    A git worktree carries only tracked files, so the article corpus under
    .bigred-collected is absent from one. The git common directory belongs to
    the main checkout. Set HERMES_DATA_ROOT to override.
    """
    override = os.environ.get("HERMES_DATA_ROOT")
    if override:
        return Path(override)
    marker = REPO / ".git"
    if marker.is_file():  # a worktree records a gitdir pointer, not a directory
        text = marker.read_text(encoding="utf-8").strip()
        if text.startswith("gitdir:"):
            return Path(text.split(":", 1)[1].strip()).resolve().parents[2]
    return REPO


ARTICLES = shared_root() / ".bigred-collected/2026-07-25-literature"
CROPS = REPO / "data/research_assets/research/student_work_figures/2026-06-18-docling-figures"

# The vocabularies the Prolog side already accepts. A value outside these does
# not bind, so any schema sent to a model must constrain to them rather than
# describe them. Asked for a free string, a model answers "English".
REPRESENTATION_LANGUAGES = (
    "none", "area_model", "balance_scale", "base_ten_blocks", "fraction_bars",
    "number_line", "place_value_chart", "set_grouping",
)
SPATIAL_ELEMENTS = (
    "partition", "equal_part", "axis", "counter", "jump", "ten_rod",
    "unit_cube", "digit_column", "ten_frame", "hundred_flat", "weight", "pan",
)


@dataclass
class FigureContext:
    crop: Path
    bibtex_key: str
    page_no: int | None
    figure_index: int
    article_path: Path | None
    article_text: str | None
    sidecar_path: Path | None
    figure_id: str | None
    caption: str | None
    join: str


def _sidecar(key: str, page: int, index: int) -> tuple[Path | None, dict, str]:
    """Find the sidecar record for one figure.

    The crop name p3_1.png means page 3, figure 1 on that page.
    """
    for path in ARTICLES.glob(f"*/{key}.json"):
        data = json.loads(path.read_text(encoding="utf-8", errors="replace"))
        on_page = [
            fig for fig in data.get("figures", [])
            if (fig.get("provenance") or [{}])[0].get("page_no") == page
        ]
        if len(on_page) >= index:
            return path, on_page[index - 1], "page_index"
        return path, {}, "page_offset"
    return None, {}, "absent"


def figure_context(crop: Path) -> FigureContext:
    """Return everything known about one crop, without calling any model."""
    key = crop.parent.name
    match = re.match(r"p(\d+)_(\d+)", crop.name)
    page, index = (int(match.group(1)), int(match.group(2))) if match else (0, 1)

    article_path = next(ARTICLES.glob(f"*/{key}.md"), None)
    article_text = (
        article_path.read_text(encoding="utf-8", errors="replace")
        if article_path else None
    )
    sidecar_path, record, join = _sidecar(key, page, index)

    return FigureContext(
        crop=crop,
        bibtex_key=key,
        page_no=page or None,
        figure_index=index,
        article_path=article_path,
        article_text=article_text,
        sidecar_path=sidecar_path,
        figure_id=record.get("id"),
        caption=record.get("caption"),
        join="absent" if article_path is None else join,
    )


def all_crops(student_work_only: bool = True) -> list[Path]:
    """Every crop, or only those the first pass judged to be student work."""
    crops = sorted(CROPS.glob("*/*.png"))
    if not student_work_only:
        return crops
    prior_path = REPO / "data/research_assets/research/docling_classifications.json"
    if not prior_path.exists():
        return crops
    prior = json.loads(prior_path.read_text())
    keep = {
        k.replace("docs/research_assets", "data/research_assets", 1)
        for k, v in prior.items() if v.get("has_handwriting_or_student_work")
    }
    return [c for c in crops if str(c.relative_to(REPO)) in keep]


if __name__ == "__main__":
    crops = all_crops()
    counts: dict[str, int] = {}
    for crop in crops:
        counts[figure_context(crop).join] = counts.get(figure_context(crop).join, 0) + 1
    print(f"crops: {len(crops)}")
    for join, n in sorted(counts.items(), key=lambda kv: -kv[1]):
        print(f"  {join:<12} {n:>5}  ({100 * n / len(crops):.1f}%)")
