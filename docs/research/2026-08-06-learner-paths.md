# Learner-paths scout: tensions and releases through calculus

Date: 2026-08-06

## Scope and decision rule

This is a static scout of the live tree. The action registry exposes counting,
fraction, decimal, integer, ratio, algebraic, statistics, geometry, and calculus
as sibling dispatch families (`knowledge/strategies/math/action_automata_registry.pl:18-33,56-91`).
That registry does not order them. The graph is also explicit that a shared
action name asserts no equivalence, prerequisite order, or learner relation,
and that its vertical order is authored rather than derived
(`docs/research/automata-graph.html:55-64`). I therefore use **walkable** only
when the current tree executes or represents both the limiting doing and the
repairing doing. Mere family adjacency, a proposal, or a target-side machine is
not enough.

The error column preserves the ledger's distinction between an objectively
false claim and a doing that may remain correct but be insufficient or
inefficient in context (`knowledge/strategies/deformation_validity.pl:2-20`).
These are the graph's rust and blue categories, respectively
(`docs/research/automata-graph.html:55-60`). Neither category by itself is a
learner transition.

## 1. Rung table

| Rung | Tension in the current practice | Release represented in the tree | Gate, shell/kernel, and error slots | Status |
|---|---|---|---|---|
| Counting one by one -> recursive place value | Counting coordinates one word with one object and retains the last word as cardinality (`knowledge/strategies/math/counting_action_pairs.pl:27-51`). **Missing end:** there is no authored refusal or resource-bound machine saying when this doing must yield to regrouped units. | `recursive_place_value_inscription` recollects completed base cycles as positional places (`knowledge/strategies/math/counting_action_pairs.pl:72-95`). | Gate: a cardinality and base. Shell/kernel: establish cardinality/base, recollect cycles, then use the numeral witness. Error: `omit_highest_place_regrouping` drops the composite-unit action (`knowledge/strategies/math/counting_action_pairs.pl:96-125`). | **Not walkable:** release exists; generating tension is missing. |
| Whole-number subtraction -> signed integers | `iterate_to_target` at `whole_number(10)` returns `refused(crosses_lower_limit)` for 3 - 5 (`knowledge/strategies/abstraction/kernel_gate_pilot.pl:185-214`; `knowledge/strategies/abstraction/refusal_genesis_sketch.pl:138-146`). | The same kernel at `integer_line` computes -2, and `signed_subtraction_as_additive_inverse` enacts the signed practice with an integer-line gate (`knowledge/strategies/abstraction/refusal_genesis_sketch.pl:140-146`; `knowledge/strategies/math/integer_action_pairs.pl:90-129`). | Old gate: `whole_number(B)`, lower limit 0, partial subtraction; new gate: `integer_line`, no lower limit, total subtraction (`knowledge/strategies/abstraction/kernel_gate_pilot.pl:121-140`). Shell/kernel: unknown-addend arrow plus additive-inverse generalization over `iterate_to_target`. Error: swapping operands evades the refusal and loses subtraction order (`knowledge/strategies/math/integer_action_pairs.pl:132-169`). | **Walkable.** Both refusal and institutionalized repair execute. |
| Whole-number sharing -> unit fractions | `genesis/3` names `refused(non_integer_share)`, but the source says this middle rung is stated, not run (`knowledge/strategies/abstraction/refusal_genesis_sketch.pl:127-132`). **Missing end:** an executable whole-number sharing machine that returns that refusal. | `unit_fraction_partition` partitions a referent whole into equal units and selects one as the iterable unit fraction (`knowledge/strategies/math/fraction_action_pairs.pl:126-155`). | New gate: `unit_fraction(D)`, a count of D-parts with a partitioned-whole boundary and partial subtraction (`knowledge/strategies/abstraction/kernel_gate_pilot.pl:134-140`). Shell/kernel: establish referent, partition, select one part. Error: `whole_number_grab` keeps the visible count but drops the denominator and referent unit (`knowledge/strategies/math/fraction_action_pairs.pl:185-213`). | **Not walkable:** the release runs; the source refusal does not. |
| Fraction units -> decimal place units | Fraction actions retain a count and named unit/referent; decimal arithmetic requires alignment to a common decimal unit. **Missing end:** no machine turns an exhausted or unsuitable fraction inscription into a decimal-place demand. | Decimal addition and subtraction align operands to a common unit and delegate to integer kernels; decimal regrouping exchanges tenths for finer base-ten units (`knowledge/strategies/math/decimal_action_pairs.pl:20-33`). | Candidate gate: a power-of-ten unit and positional inscription. Shell/kernel: align scales, inherited integer operation, reinscription. Error: operating on written numerals before alignment or renaming a unit without regrouping, both already named in the decimal family (`knowledge/strategies/math/decimal_action_pairs.pl:20-33`). | **Not walkable:** both families exist, but no tension/release bridge exists. |
| Fraction/decimal quantities -> ordered ratios | Fraction machines construct and iterate one named unit (`knowledge/strategies/math/fraction_action_pairs.pl:126-183`). **Missing end:** no refusal says that a single-referent unit practice cannot coordinate two quantity roles. | Ratio machines normalize an ordered pair to a requested per-one referent and preserve rate direction (`knowledge/strategies/math/ratio_action_pairs.pl:91-120`); they can also test several pairs for one constant, accepting or returning a witness-bearing refusal (`knowledge/strategies/math/ratio_action_pairs.pl:159-218`). | Ratio gate: ordered positive quantities plus the requested referent. Shell/kernel: bind roles, divide compared by reference, inscribe the rate (`knowledge/strategies/math/ratio_action_pairs.pl:16-34`). Error: replace quantity roles with magnitude order (`knowledge/strategies/math/ratio_action_pairs.pl:122-157`). | **Not walkable:** target practices run; the transition from a one-referent fraction/decimal practice is missing. |
| Additive ratio extension -> multiplicative ratio invariance | `additive_extension_of_ratio` carries an absolute increment into the slot where scaling is required; admitted runs are guarded away from the correct scaled denominator (`knowledge/strategies/math/ratio_action_pairs.pl:16-22,41-45,65-90`). | `scale_ratio_unit` scales both terms by one factor, and `test_relation_for_proportionality` checks all pairs against one candidate constant (`knowledge/strategies/math/ratio_action_pairs.pl:16-31,159-218`). | Gate: positive ordered ratio pair and factor, or a list of pairs. Shell/kernel: bind factor or candidate constant, scale/compare, then inscribe. Error: the additive transfer is an objectively invalid gate mutation on admitted inputs, not a productive blue deformation (`knowledge/strategies/deformation_validity.pl:481-483`). | **Walkable as a within-family repair.** It is not yet a cross-family learner path. |
| Proportional equation -> covariational function | `inscribe_proportional_equation` can write and use `y = kx`, but its result explicitly carries `boundary(does_not_enact_covariational_practice)` (`knowledge/strategies/math/ratio_action_pairs.pl:219-253`). The seam says the variable/substitution metaphor stops before covariational practice (`knowledge/strategies/abstraction/metaphor_seam_registry.pl:179-186`). **Missing end:** a machine coordinating two changing quantities. | Algebra can construct a contextual linear equation and evaluate an expression under an assignment (`knowledge/strategies/math/algebraic_action_pairs.pl:130-195`), but the grade-8 survey states that functions as input-output coordination are absent (`docs/research/2026-08-05-grade8-saying-and-doing.md:371-386`). | Candidate gate: input/output dependency with stable quantity roles. Candidate shell/kernel: infer or receive a rule, apply it across inputs, coordinate outputs. Candidate errors: swapped dependency roles and a rule inferred from one pair; these are proposals, not current machines (`docs/research/2026-08-05-grade8-saying-and-doing.md:407-412`). | **Not walkable:** the ratio seam is executable; the covariational release is missing. |
| Procedural equals -> equality as a conserved relation | The authored antecedent transports sequencing from procedure discourse and forgets that equality is symmetric and flanks one quantity (`knowledge/strategies/abstraction/refusal_genesis_sketch.pl:104-113`). `operational_equals_left_value` and `one_sided_equation_operation` enact that failure (`knowledge/strategies/math/algebraic_action_pairs.pl:330-361,393-424`). | `equation_truth_by_substitution` evaluates both sides under one assignment, and `balance_preserving_linear_solution` applies the same transformation to both sides (`knowledge/strategies/math/algebraic_action_pairs.pl:296-329,363-392`). | Gate: an equation relation and one assignment/solution domain. Shell/kernel: substitute and compare, or select inverse operations and preserve balance. Errors: stop at the equals sign or change one side only. | **Walkable as a within-algebra repair.** The tree does not encode this as the genesis of variables or functions. |
| Rational co-measurement -> real-number measurement | `run_co_measure/3` returns `refused(incommensurable(sqrt2))`, and `genesis/3` names `real_line` as the new gate (`knowledge/strategies/abstraction/refusal_genesis_sketch.pl:157-170`). The geometry seam also stops before establishing exact or irrational pi (`knowledge/strategies/abstraction/metaphor_seam_registry.pl:193-204`). | **Missing end:** no machine enacts real-line completion or nested interval refinement. The existing circle machine requires a positive rational pi co-measure and scales by that rational (`knowledge/strategies/math/geometry_action_pairs.pl:1283-1316`). The grade-8 report labels `nested_interval_root` a candidate rather than existing code (`docs/research/2026-08-05-grade8-saying-and-doing.md:413-421`). | Candidate gate: `real_line`. Candidate shell/kernel: refine a bracketing interval with `iterate_to_target` and `partition_regroup`, stop on a precision/refusal condition, inscribe the root. Candidate errors: truncate an approximation as exact; treat root-taking as halving. | **Not walkable:** the refusal and gate name exist; the repairing machine does not. |
| Finite relative frequency -> sequence convergence | `finite_frequency_as_exact_probability` promotes one finite record to an exact claim; the machine records the violation and retains the finite-record viability context (`knowledge/strategies/math/statistics_action_pairs.pl:374-409`). The seam stops before turning a finite record into a limit (`knowledge/strategies/abstraction/metaphor_seam_registry.pl:245-271`). | `bounded_numerator_over_diverging_denominator` enacts a symbolic epsilon/tail-bound argument for a sequence and concludes zero (`knowledge/strategies/math/calculus_limits_action_pairs.pl:220-252`). **Missing end:** a bridge that turns cumulative frequency records into an indexed sequence with an explicit tail claim. | Statistics gate: a finite frequency record; shell/kernel: form relative frequency and retain estimate status (`knowledge/strategies/math/statistics_action_pairs.pl:344-372`). Calculus gate: a bounded numerator, diverging denominator, and `as_n_to_infinity`; shell/kernel: choose a tail bound. Error: erase finite-sampling qualification. | **Not walkable:** source tension and target limit machine exist, but they operate on different contracts. |
| Algebraic evaluation -> function limit | Algebra evaluates a term at an assignment (`knowledge/strategies/math/algebraic_action_pairs.pl:130-160`). **Missing end:** no machine coordinates values in a punctured neighborhood, establishes continuity, or transforms the algebraic expression contract into the calculus contract. | `direct_substitution` accepts `polynomial(Coeffs)` at an integer target, labels the polynomial continuous, evaluates at that point, and names the value as the limit (`knowledge/strategies/math/calculus_limits_action_pairs.pl:90-127`). | Candidate gate: function plus approach target and continuity warrant. Candidate shell/kernel: coordinate nearby inputs/outputs, establish the applicable continuity rule, then delegate evaluation. Error: conflate one function value with an approached value without a warrant. | **Not walkable:** the calculus endpoint runs, but the approach practice and contract bridge are missing. |
| Substitution at a removable singularity -> factor, cancel, substitute | Inside the calculus machine, substitution produces 0/0 and the trace detects it (`knowledge/strategies/math/calculus_limits_action_pairs.pl:128-170`). | The same trace factors `(x-A)` from numerator and denominator, substitutes into the reduced quotient, and evaluates it (`knowledge/strategies/math/calculus_limits_action_pairs.pl:140-177`). | Gate: rational expression at `limit_at(A)` with both values zero and a nonzero reduced denominator. Shell/kernel: detect 0/0, synthetic-divide both polynomials, cancel, evaluate. Error: apply cancellation when the common-factor precondition is absent (`knowledge/strategies/math/calculus_limits_action_pairs.pl:179-218`). | **Walkable locally inside calculus.** It remains disconnected from a learner path into calculus. |

The current walkable set is therefore narrow: one executed gate-genesis rung
(whole numbers to integers) and three within-family repair pairs (ratio
invariance, relational equality, and removable-singularity handling). The tree
does not currently encode one continuous learner path from counting to limits.

## 2. The Zeeman join

**Classification: homologous shape at a coarse event level, but different
objects and no executable join.**

The Zeeman core computes a physical potential from two pull-only springs and
derives torque from its angular derivative
(`hermes/web/prolog/zeeman_machine.pl:39-70`). It samples equilibria, classifies
them by the second derivative, and exposes stable equilibria
(`hermes/web/prolog/zeeman_machine.pl:76-127`). A control-point sweep counts how
many stable equilibria exist at each position, which is the implemented
bifurcation surface (`hermes/web/prolog/zeeman_bifurcation.pl:16-30`).
Quasi-static release is gradient descent toward a stable angle
(`hermes/web/prolog/zeeman_machine.pl:129-143`).

The refusal-genesis machine has a different state and transition type. A kernel
run meets a gate guard and returns the first-class term `refused(Guard)`
(`knowledge/strategies/abstraction/kernel_gate_pilot.pl:150-154,203-214`). A
`genesis(FromGate, Refusal, ToGate)` row then names a new license under which the
same kernel computes; the subtraction check performs that exact old-gate/new-
gate comparison (`knowledge/strategies/abstraction/refusal_genesis_sketch.pl:120-146`).

The homology is limited to this sequence:

1. a currently occupied organization persists under increasing constraint;
2. a boundary is reached;
3. a different organization settles and subsequent behavior proceeds under it.

The objects are not the same. Zeeman's constraint is spring energy under a
continuous control position; its alternatives are stable angular equilibria.
The fractal's constraint is an admissibility rule; its alternative is a newly
licensed mathematical practice. Zeeman does not return `refused/1` or create a
gate. Refusal genesis does not compute potential, stability, a fold, or a basin.
The module graph reflects the separation: the Zeeman modules and the two
abstraction modules are independently marked orphan modules
(`hermes/capability_registry.pl:277-300`), while the only opt-in Zeeman bridge
explicitly declines to claim that a machine trajectory and a classroom episode
are isomorphic (`hermes/web/prolog/zeeman_pml_bridge.pl:1-15`). Treating the two
as the same machine would therefore exceed the code.

## 3. Gap list: shortest ordered build path to connected calculus rungs

This is an implementation order for a runnable path, not a claim about a
necessary curriculum order.

1. **`whole_number_non_integer_share_refusal`.** Enact sharing `P` wholes among
   `Q` recipients inside a whole-number gate; return
   `refused(non_integer_share)` exactly when `P mod Q =\= 0`, and preserve the
   same task for `unit_fraction(Q)` to repair. This supplies the missing source
   end of the already-authored fraction genesis row
   (`knowledge/strategies/abstraction/refusal_genesis_sketch.pl:127-132`).

2. **`ordered_quantity_covariation`.** Accept named input/output quantities and
   multiple pairs, maintain dependency roles while one quantity varies, and
   produce an evaluable rule rather than one solved `y=kx` instance. This enacts
   the exact doing excluded by the current ratio boundary
   (`knowledge/strategies/math/ratio_action_pairs.pl:219-253`) and supplies the
   function coordination the grade-8 survey says is missing
   (`docs/research/2026-08-05-grade8-saying-and-doing.md:371-386`).

3. **`nested_interval_real_line`.** Given a rational bracket and a root target,
   iteratively refine the bracket, retain lower/upper witnesses, stop at a named
   precision or incommensurability condition, and distinguish an approximation
   from exact root inscription. This turns the existing symbolic
   `refused(incommensurable(...)) -> real_line` row into a doing
   (`knowledge/strategies/abstraction/refusal_genesis_sketch.pl:157-170`).

4. **`frequency_sequence_tail_bridge`.** Turn successive finite frequency
   records into an indexed relative-frequency sequence, keep every finite term
   qualified as an estimate, and state the additional tail condition needed for
   a limit claim. This connects the statistical seam to the existing calculus
   tail-bound machine without equating a finite record with its limit
   (`knowledge/strategies/math/statistics_action_pairs.pl:344-409`;
   `knowledge/strategies/math/calculus_limits_action_pairs.pl:220-252`).

5. **`function_approach_contract_bridge`.** Convert the function/rule machine's
   output into the calculus input types, coordinate a punctured neighborhood or
   sequence of approaches, attach a continuity or removable-discontinuity
   warrant, and only then delegate to `direct_substitution` or
   `factor_cancel_substitute`. The present calculus boundary accepts coefficient
   lists and symbolic sequence descriptors directly, with derivatives and
   integrals outside scope
   (`knowledge/strategies/math/calculus_limits_action_pairs.pl:54-74`).

After these five additions, the already-existing calculus machines are usable
as the endpoint. More calculus content is not needed to establish the first
connected path; derivatives and integrals remain a later scope.

## 4. Falsifiable next

**Can `nested_interval_real_line` be built using only the existing
`iterate_to_target`, `partition_regroup`, and `run_co_measure` kernels, with no
new kernel?**

An afternoon lane can decide this with one quarantined prototype and three
cases: a rational target that terminates exactly, `sqrt(2)` that produces nested
rational brackets plus an incommensurability/precision stop, and a malformed
target that is refused before iteration. The answer is **yes** only if the
composition produces a monotone shrinking interval, preserves the target in
every bracket, and keeps approximation distinct from exact inscription. If any
of those properties requires control not expressible by the three kernels, the
answer is **no**, and the missing kernel can be named from the failed derivation.

IMPLEMENTATION_COMPLETE
