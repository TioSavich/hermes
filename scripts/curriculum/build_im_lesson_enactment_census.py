#!/usr/bin/env python3
"""Build the enacted-non-arithmetic rung of the IM lesson-capability census.

The arithmetic rung (`executable_task` in
`data/learningcommons/derived/im_lesson_capability_census.json`) counts a lesson
when an automaton ran a computation on operands the lesson printed.  Most of the
IM curriculum asks for a doing that is not a computation, and 226 such lessons
were carved into subclasses in `im_action_seam_recut.json`.  This census counts
the second rung: `enacted_non_arithmetic`, a lesson whose structural form a
machine ran on the lesson's own inputs, producing steps, an artifact, and a
verdict.

The count comes from running the enactors.  `run_lesson_enactments.pl` loads
every lane under `curriculum/im/enactment/`, calls `enact_lesson/2` on every
lesson any lane declared, and reports what ran.  Nothing here reads a table of
what a lane meant to do.

The rung is deliberately kept out of `executable_task`.  A lesson can sit on
both rungs, on one, or on neither, and merging them would destroy the only
number that makes the second rung worth building.

Usage:
    python3 scripts/curriculum/build_im_lesson_enactment_census.py
    python3 scripts/curriculum/build_im_lesson_enactment_census.py --check
"""

from __future__ import annotations

import argparse
from collections import Counter
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from hermes.app.rendering import (  # noqa: E402
    RenderDocumentError,
    validate_render_document,
)

OUTPUT = (
    ROOT / "data" / "learningcommons" / "derived" / "im_lesson_enactment_census.json"
)
RECUT = (
    ROOT / "data" / "learningcommons" / "derived" / "im_action_seam_recut.json"
)
EMISSION_DIR = (
    ROOT / "data" / "learningcommons" / "derived" / "lesson_enactments"
)
DRIVER = ROOT / "scripts" / "curriculum" / "run_lesson_enactments.pl"
PATHS = ROOT / "paths.pl"
SCHEMA = "im_lesson_enactment_census_v1"

# Pinning the emission stamp keeps a rerun that changed nothing byte-identical,
# so a diff in the JSONL rows carries information about the machines rather than
# about the clock.
EMISSION_STAMP = "2026-08-01"

# The rung starts here.  Before this wave no machine ran a non-arithmetic IM
# doing on a lesson's own inputs, so the baseline is zero by construction and
# every later increase is a machine that ran, never a reclassification.
BASELINE = {
    "value": 0,
    "measured_at": "2026-08-01, commit b9a851c",
    "statement": (
        "No enactor existed before this wave, so the rung opens at zero. Any "
        "later count is the number of lessons whose form a machine ran, "
        "measured by running it."
    ),
}

DEFINITION = (
    "A machine named the structural form the lesson asks a class to move "
    "through, ran that form's moves on the lesson's own inputs, and produced a "
    "scene or a printed record together with a verdict. It is not a claim that "
    "a discussion occurred; each emitted row carries its own sentence about "
    "what it does not claim."
)


def run_driver(out_dir: Path) -> dict:
    """Run every declared enactment and return the driver's JSON summary."""
    out_dir.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ)
    env["HERMES_ENACTMENT_STAMP"] = EMISSION_STAMP
    completed = subprocess.run(
        [
            "swipl",
            "-q",
            "-l",
            str(PATHS),
            "-s",
            str(DRIVER),
            "-g",
            f"main('{out_dir}')",
            "-t",
            "halt",
        ],
        cwd=str(ROOT),
        env=env,
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        sys.stderr.write(completed.stderr)
        raise SystemExit(
            f"run_lesson_enactments.pl exited {completed.returncode}"
        )
    stdout = completed.stdout.strip()
    if not stdout:
        sys.stderr.write(completed.stderr)
        raise SystemExit("run_lesson_enactments.pl printed no summary")
    return json.loads(stdout.splitlines()[-1])


def scene_documents(artifact: dict) -> list:
    """Every render document inside one artifact.

    An artifact is a scene, a printed record, or a list of both: the geometry
    lane usually draws a figure and prints the adjudication beside it.  A
    validator that looked only at the top-level `kind` would skip every scene
    that arrived inside a list, which is most of the scenes on this rung.
    """
    kind = artifact.get("kind")
    if kind == "scene":
        return [artifact["scene"]]
    if kind == "scene_and_record":
        found: list = []
        for part in artifact.get("parts", []):
            found.extend(scene_documents(part))
        return found
    return []


def validate_emitted_scenes(out_dir: Path) -> int:
    """Check every emitted scene against the repo's own render contract.

    An enactment whose artifact says `scene` but carries a document the drawer
    would refuse has emitted a picture nobody can draw.  Checking here keeps the
    contract's promise ("prefer an existing renderer") honest rather than
    nominal.
    """
    checked = 0
    for path in sorted(out_dir.glob("*.jsonl")):
        for number, line in enumerate(
            path.read_text(encoding="utf-8").splitlines(), 1
        ):
            row = json.loads(line)
            for document in scene_documents(row["artifact"]):
                try:
                    validate_render_document(document)
                except RenderDocumentError as error:
                    raise SystemExit(
                        f"{path.name}:{number} lesson {row['lesson']} emitted a "
                        f"scene the render contract refuses: {error}"
                    )
                checked += 1
    return checked


def stale_emissions(scratch_dir: Path) -> list[str]:
    """Compare the committed rows against the rows this run just produced.

    The census JSON is checked against a fresh run, and the rows have to be too.
    Without this the JSONL files could drift from the machines with no gate
    noticing, and they are what the page builder and three lane gates read.  The
    emission stamp is pinned, so a run that changed nothing is byte-identical
    and a difference here is a difference in what the machines did.
    """
    stale: list[str] = []
    fresh = {path.name: path.read_text(encoding="utf-8") for path in scratch_dir.glob("*.jsonl")}
    committed = {
        path.name: path.read_text(encoding="utf-8")
        for path in EMISSION_DIR.glob("*.jsonl")
    }
    for name in sorted(set(fresh) | set(committed)):
        if name not in committed:
            stale.append(f"stale enactment rows: {name} is not in the tree")
        elif name not in fresh:
            stale.append(
                f"stale enactment rows: {name} is in the tree but no lane "
                "produced it in this run"
            )
        elif fresh[name] != committed[name]:
            stale.append(
                f"stale enactment rows: {name} differs from a fresh run of the "
                "enactors"
            )
    return stale


def load_population() -> dict:
    document = json.loads(RECUT.read_text(encoding="utf-8"))
    return {
        row["lesson"]: {
            "subclass": row["task_209_subclass"],
            "action_class": row["action_class"],
            "grade": row["grade"],
        }
        for row in document["lessons"]
    }


def build(summary: dict, population: dict) -> dict:
    rows = summary["lessons"]
    # A lesson can exhibit more than one form, so `rows` can carry more than one
    # entry per lesson.  The rung counts distinct lessons; everything else
    # counts enactments, and the two numbers are reported separately so neither
    # can stand in for the other.
    enacted = sorted(
        (row for row in rows if row["enacted"]),
        key=lambda row: (row["lesson"], row["form"]),
    )
    enacted_ids = {row["lesson"] for row in enacted}

    outside = sorted(enacted_ids - set(population))
    denominator = len(population)

    failure_reasons: Counter = Counter()
    for lesson in population:
        if lesson in enacted_ids:
            continue
        declared = any(
            row["lesson"] == lesson and not row["enacted"] for row in rows
        )
        if declared:
            failure_reasons["declared_but_no_run_on_the_lesson_inputs"] += 1
        else:
            failure_reasons["no_lane_has_declared_a_form"] += 1

    by_subclass: dict[str, dict] = {}
    for subclass in sorted({meta["subclass"] for meta in population.values()}):
        pool = [
            lesson
            for lesson, meta in population.items()
            if meta["subclass"] == subclass
        ]
        by_subclass[subclass] = {
            "denominator": len(pool),
            "enacted": sum(1 for lesson in pool if lesson in enacted_ids),
        }

    # The class the rung exists to move.  A lesson already inside
    # enacted_with_lesson_inputs was reached by an arithmetic adapter; one
    # inside not_enacted_by_measured_inventory was not reached at all.  Keeping
    # the split stops a rerun of old reach from reading as new reach.
    by_prior_action_class: dict[str, int] = {}
    for lesson in sorted(enacted_ids & set(population)):
        prior = population[lesson]["action_class"]
        by_prior_action_class[prior] = by_prior_action_class.get(prior, 0) + 1

    ladder = [
        {
            "id": "enacted_non_arithmetic",
            "count": len(enacted_ids & set(population)),
            "denominator": denominator,
            "denominator_source": (
                "data/learningcommons/derived/im_action_seam_recut.json"
            ),
            "definition": DEFINITION,
            "baseline": BASELINE,
            "counted_separately_from": "executable_task",
            "binding_constraint": (
                {
                    "reason": failure_reasons.most_common(1)[0][0],
                    "lessons": failure_reasons.most_common(1)[0][1],
                }
                if failure_reasons
                else {"reason": "none", "lessons": 0}
            ),
            "failure_reason_counts": dict(sorted(failure_reasons.items())),
        }
    ]

    forms = sorted(summary["forms"], key=lambda form: form["form"])
    refusals = sorted(summary["refusals"], key=lambda row: row["lesson"])

    emissions = sorted(
        (
            {
                "subclass": row["subclass"],
                "rows": row["rows"],
                "path": (
                    "data/learningcommons/derived/lesson_enactments/"
                    f"{row['subclass']}.jsonl"
                ),
            }
            for row in summary["emissions"]
        ),
        key=lambda row: row["subclass"],
    )

    return {
        "move_check": summary["move_check"],
        "solution_check": summary["solution_check"],
        "enactments": summary["enactments"],
        "schema": SCHEMA,
        "generated_by": (
            "scripts/curriculum/build_im_lesson_enactment_census.py"
        ),
        "runner": "scripts/curriculum/run_lesson_enactments.pl",
        "contract": "curriculum/im/lesson_enactment.pl",
        "register": (
            "Measured enactment count. A lesson joins this rung only when "
            "enact_lesson/2 ran its form and produced steps and an artifact "
            "in this build."
        ),
        "ladder": ladder,
        "lane_modules": summary["lane_modules"],
        "forms": forms,
        "by_subclass": by_subclass,
        "by_prior_action_class": by_prior_action_class,
        "by_verdict": dict(
            sorted(Counter(row["verdict_class"] for row in enacted).items())
        ),
        "by_input_provenance": dict(
            sorted(Counter(row["input_provenance"] for row in enacted).items())
        ),
        "by_artifact_kind": dict(
            sorted(Counter(row["artifact_kind"] for row in enacted).items())
        ),
        "lessons": [
            {
                "lesson": row["lesson"],
                "grade": population.get(row["lesson"], {}).get("grade", ""),
                "subclass": row["subclass"],
                "prior_action_class": population.get(row["lesson"], {}).get(
                    "action_class", "outside_population"
                ),
                "form": row["form"],
                "steps": row["steps"],
                "verdict": row["verdict"],
                "artifact_kind": row["artifact_kind"],
                "input_provenance": row["input_provenance"],
            }
            for row in enacted
        ],
        "refusals": refusals,
        "emissions": emissions,
        "declared_outside_population": outside,
    }


def render(payload: dict) -> str:
    return (
        json.dumps(payload, indent=1, ensure_ascii=False, sort_keys=True) + "\n"
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--output", type=Path, default=OUTPUT)
    args = parser.parse_args()

    population = load_population()

    if args.check:
        # A check writes nothing.  The enactors still run; only their emission
        # goes to a scratch directory that is discarded, and the committed rows
        # are then compared against it.
        with tempfile.TemporaryDirectory() as scratch:
            scratch_dir = Path(scratch)
            summary = run_driver(scratch_dir)
            scenes = validate_emitted_scenes(scratch_dir)
            stale = stale_emissions(scratch_dir)
            if stale:
                for message in stale:
                    print(message, file=sys.stderr)
                print(
                    "run scripts/curriculum/build_im_lesson_enactment_census.py "
                    "to rewrite the emitted rows",
                    file=sys.stderr,
                )
                return 1
    else:
        summary = run_driver(EMISSION_DIR)
        scenes = validate_emitted_scenes(EMISSION_DIR)

    payload = build(summary, population)
    rendered = render(payload)

    if args.check:
        current = (
            args.output.read_text(encoding="utf-8")
            if args.output.exists()
            else ""
        )
        if current != rendered:
            print(
                "stale IM lesson enactment census: run "
                "scripts/curriculum/build_im_lesson_enactment_census.py",
                file=sys.stderr,
            )
            return 1
    else:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered, encoding="utf-8")

    rung = payload["ladder"][0]
    print(
        "im_lesson_enactment_census "
        f"{rung['id']}={rung['count']}/{rung['denominator']} "
        f"baseline={rung['baseline']['value']} "
        f"lanes={payload['lane_modules']} "
        f"forms={len(payload['forms'])} "
        f"enactments={payload['enactments']} "
        f"refusals={len(payload['refusals'])} "
        f"undeclared_step_verbs={payload['move_check']['undeclared']} "
        f"multiplied_solutions={payload['solution_check']['multiplied']} "
        f"scenes_validated={scenes}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
