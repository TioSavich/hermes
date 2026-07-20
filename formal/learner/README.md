# learner

The ORR cycle: a learner-agent acquires arithmetic strategies through crisis. It
observes its own trace, reacts to disequilibrium, and reorganizes its move space
when a task exceeds its finite resources.

## Running it

`main.pl` runs a fixed Peano goal once, non-interactively. `server.pl` starts the
Arithmetic Machine Explorer HTTP server (port 8080). `reorg_demo_server.pl`
serves the live reorganization demo (`reorg_demo.html`, port 8090), which feeds
each typed fraction problem straight into `reorganize/4` with no cache and no
canned answer.

## The cycle, distributed across files

- `meta_interpreter.pl` — the Observe stage (embodied tracing).
- `reflective_monitor.pl` — the Reflect stage (disequilibrium detection).
- `reorganization_engine.pl`, `reorganize.pl` — the Reorganize step
  (reorganization as search over the primitive move space).
- `crisis_processor.pl`, `curriculum_processor.pl` — read the `crisis_curriculum*.txt`
  and `mathematical_curriculum.txt` files line by line and drive tasks to crisis.
- `more_machine_learner.pl`, `strategy_synthesis.pl`, `deontic_scorekeeper.pl`
  (commitment vs entitlement), `tension_dynamics.pl` (catastrophe-geometry state).
- `up_leveling.pl` — labels itself a representation, not an implementation, of
  Gödelian diagonalization.
- `reorg_domains/` — the reorganization domains (arithmetic, the whole-number
  operations, and the five fraction cliffs); `atlas/` holds generated
  curriculum-dynamics facts and their task quotient.

## Consumers and boundary

`hermes_worker.pl` loads the scorekeeper, machine, and monitor;
`arche-trace/sequent_engine.pl`, the `crosswalk` families (`cw_viability` loads
`meta_interpreter`), and `misconceptions/` reach in. `reorg_demo.html` states
plainly what reorganization does and does not mean: the machine is not conscious,
the ladder of levels is part of the given model, and the honest line is exactly
where it still gets stuck and would have to ask a teacher.
`fsm_synthesis_engine.pl` is an archived shim whose synthesis predicates fail.
