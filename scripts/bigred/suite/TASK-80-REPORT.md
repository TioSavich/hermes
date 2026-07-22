# Task 80 report: Big Red scenario suite

## Inventory

| Candidate | Live entry point | Decision |
| --- | --- | --- |
| Hyperedges | `formal/incompatibility/find_emergent_hyperedges.pl`: `run_search/0`, `emergent_in_discovery_layer/1`, and `verified_emergent/1` | Batchable offline. |
| Representation HTML | `hermes/app/scripts/export_lesson_deformation_charts.py` and `hermes/app/scripts/export_notation_charts.py` | Batchable offline. Both accept `--limit`. |
| Search traces | `formal/tools/carving/strategy_machine.pl`: `all_paths/6`, with seeded `known_fact/3` and bounded transitions | Batchable offline. The worker has no named `explore` operation with catches, budgets, and tickers; the suite therefore records the live bounded carving search rather than claiming a worker surface that is absent. |
| Predicate carving | `knowledge/strategies/inferential_strength.pl`, `formal/incompatibility/incompatibility_sets.pl`, and `curriculum/im/lesson_monitoring.pl` | Batchable offline. The suite records every encoded lesson's finite report, operation rows, and ordered containment verdicts. |
| Modeling | `knowledge/strategies/math/action_automata_registry.pl` has 172 live `action_automaton_signature/4` rows across 13 operations | Not batchable today. The registry supplies invocation schemas but no verified generic concrete-input generator, so an all-automata grid would invent inputs. A checked per-signature instantiation contract, or a verified narrow fraction/decimal comparator runner, is required. |

The existing `scripts/bigred/package.sh` already creates the transfer tarball and includes this suite. It was left unchanged.

## Implemented suite

- Four resumable runners write only below `.bigred-output/<scenario>/` and accept `--limit N`.
- `suite_batch.pl` writes JSON and readable Markdown for the Prolog scenarios. Trace steps include before and after state, move, cost, and the transition/unit/recall facts that license the move.
- `suite.slurm` follows the deformation-gallery module and conda setup, with the required account and email placeholders.
- `collect.sh` gathers the remote `.bigred-output/` tree into one local results tarball.
- `README.md` explains runtime class, output handling, and the modeling boundary.

## Local smoke evidence

All runners completed with `--limit 2` under `.bigred-output/task80-smoke/`.

- Hyperedges: `hyperedges/hyperedges.json`, `hyperedges/search.md`.
- Search traces: `search-traces/add_count_on.{json,md}` and `search-traces/add_make_ten.{json,md}`.
- Predicate carving: `predicate-carving/predicate-carving.json` and `README-results.md`; it reports 2 lesson rows, 2 operation rows, and 2 ordered containment verdicts.
- Representation HTML: two deformation lesson directories and two notation lesson directories; the exporters reported 16 deformation files and 8 notation SVGs.

## Verification

- `bash -n` passed for every shell and Slurm script in `scripts/bigred/suite/`.
- Forbidden-reference scan over suite shell, Slurm, and Prolog files returned no references to `server*.pl`, `geometry_bridge`, `REALLMS`, or the formalization sibling path.
- No git operation was run.

## Files changed

- `scripts/bigred/suite/run_representation_html.sh`
- `scripts/bigred/suite/run_hyperedges.sh`
- `scripts/bigred/suite/run_search_traces.sh`
- `scripts/bigred/suite/run_predicate_carving.sh`
- `scripts/bigred/suite/suite_batch.pl`
- `scripts/bigred/suite/suite.slurm`
- `scripts/bigred/suite/collect.sh`
- `scripts/bigred/suite/README.md`
- `scripts/bigred/suite/TASK-80-REPORT.md`

IMPLEMENTATION_COMPLETE
