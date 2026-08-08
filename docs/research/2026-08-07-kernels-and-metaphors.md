# Kernels, metaphors, and the shape of the learner module

Date: 2026-08-07. Written for a colleague who knows none of the repo's vocabulary.
Every load-bearing claim carries a file and line; conjectures are marked as such.

## Glossary

A **kernel**, in this repo, is a small piece of executable Prolog that carries one
reusable mathematical doing — a control loop that actually computes, such as
"measure the gap from a part to a boundary" (`knowledge/strategies/abstraction/kernel_gate_pilot.pl:12-14`).
A **gate** is the licensing wrapper around a kernel: it supplies what kind of thing
is being counted, where the boundary sits, and which operations are allowed —
the kernel computes, the gate says what the computation is about
(`kernel_gate_pilot.pl:131-143`). A **machine** (or automaton) is a finite-state
encoding of one attested way a student carries out a piece of arithmetic,
productive or mistaken; the corpus holds 245 of them. A **bridge** is a recorded,
citable identification between two gates — for example, "a count of ones in
base 7 corresponds to a count of sevenths" — never applied silently
(`kernel_gate_pilot.pl:719-729`). A **seam** is an authored registry row naming
where a grounding metaphor's reach ends inside some content; its two strongest
kinds are **vanishing_point** (the metaphor has no referent at all for the named
content) and **repair_point** (the inference stays valid but a different metaphor
must take over the grounding) (`knowledge/strategies/abstraction/metaphor_seam_registry.pl:11-23`).
These are named technical vocabulary in the registry, borrowed from painting;
they do not carry Carspecken's sense of "horizon," and "horizon" itself appears
nowhere in the tree as a term of art. A **scene**, in the repo's render layer, is
a compiled sequence of picture frames — an automaton runs, and its trace is
turned into fraction bars, a number line, a balance scale, and so on
(`knowledge/strategies/render/fraction_bars_scene.pl:1-10`); Carspecken's scene
(a typified setting whose meaning is mostly backgrounded) is a reading one can
lay over this, not a claim the code makes. A **hyperedge** is a recorded set of
claims that cannot all be held together at once, where a plain edge joins only
two things; the interesting ones need three or more members
(`formal/incompatibility/brandomian_incompatibility.pl:21-26`).

## 1. How many kernels, and what they answer to

The count is **eight, not seven**: seven live in `kernel_gate_pilot.pl` —
complete_to_unit (:235), iterate_to_target (:261), partition_regroup (:300),
refine_bracket_by_order (:329), compare_place_sequences_by_significance (:418),
recollect_base_cycles (:501), and enumerate_positive_integer_pairs (:570, admitted
2026-08-07 from a failed geometry derivation, :563-569) — and the eighth,
co_measure ("find the common refinement of two units"), lives in
`refusal_genesis_sketch.pl:157-163`. New kernels are admitted only when composing
the existing ones fails; each admission is itself a finding
(`refusal_genesis_sketch.pl:48-52`).

**Lakoff and Núñez's question lands at the gate, not the kernel.** Their four
grounding metaphors — Object Collection (numbers as collections), Object
Construction (numbers as built objects), Measuring Stick (numbers as lengths),
Motion Along a Path (numbers as locations) — describe what a number *is* in a
practice. The kernels are deliberately indifferent to that: complete_to_unit
computes "2 is 5 short of 7" identically whether 7 is a base-seven cycle or a
whole cut into sevenths; only the gate slot differs
(`kernel_gate_pilot.pl:231-234, 1076-1086`). So the collection-vs-stick
distinction Tio asked about is real in the formalism, but it is carried by the
gates and their boundary kinds, and the sketch says so in its own words: the
license rows use metaphor-named gates like `collection(addition)` and
`path(addition)` (`refusal_genesis_sketch.pl:95-97`), pointing at the corpus's
existing metaphor annotations (`formal/pml/mua_relations.pl:412-417`).

Laid against the four metaphors, kernel by kernel:

- **partition_regroup is the clean fit.** Building a composite unit outward and
  cutting a whole inward is Object Construction's content, and the gate that
  reads its boundary as a `partitioned_whole` is the fraction gate
  (`kernel_gate_pilot.pl:158-164, 293-309`).
- **iterate_to_target straddles Collection and Motion, and its gate ladder is the
  stick's vanishing point made executable.** At the whole-number gate, running
  3 − 5 is refused (`crosses_lower_limit`); at the integer-line gate the same
  kernel computes −2 (`kernel_gate_pilot.pl:1107-1117`). The seam registry
  records the same break in metaphor vocabulary: the measuring stick has no
  referent for signed quantity, and motion along a path takes over —
  `seam_kind(vanishing_point)`, `break(negative_numbers)`
  (`metaphor_seam_registry.pl:111-120`). One caution: both rows cite the same
  Lakoff-Núñez chapter, so their agreement is consistency of authorship, not an
  independent empirical convergence.
- **co_measure is Measuring Stick territory, at the stick's other break.** Its
  refusal at an incommensurable length (`refused(incommensurable(sqrt2))`) is
  the diagonal-of-the-unit-square case, and the repo carries that break twice
  over: as the one machine-checked emergent hyperedge
  (`brandomian_incompatibility.pl:116-137`) and as the Lakoff-Núñez blend row
  that "gave birth to the irrational numbers"
  (`knowledge/geometry/metaphors/measuring_stick.pl:131-141`). But co-measurement
  itself — coordinating two units through a common refinement — is not one of
  the four grounding metaphors. It comes from the constructivist fraction
  literature (the state label "co-measurement unit" cites Shin & Lee 2018,
  `knowledge/strategies/math/state_vocabulary.pl:147`). Partial fit; the
  mismatch is the finding.
- **complete_to_unit is metaphor-neutral by design.** The same gap-measuring run
  serves make-ten (collection/base structure) and fraction complement
  (construction); the bridge between them must be cited, never assumed
  (`kernel_gate_pilot.pl:58-69, 729`).
- **compare_place_sequences and recollect_base_cycles answer to positional
  notation, which Lakoff and Núñez do not name.** Their gates' boundary kind is
  a `radix_cycle` (`kernel_gate_pilot.pl:172-185`), and the pilot insists the
  radix cycle and the partitioned whole are "different things that happen to be
  isomorphic as bounded complement structures" (:723-727). Two of eight kernels
  live in a region the four-metaphor scheme leaves unnamed.
- **refine_bracket_by_order stops exactly where the Basic Metaphor of Infinity
  would begin.** It does one interval refinement and keeps "next bracket"
  distinct from "exact" (`kernel_gate_pilot.pl:351-363`); completing the limit
  is what Lakoff-Núñez's BMI does, and the registry's statistics seams record
  the same stopping — a finite frequency record "stops_before turning a finite
  record into the limit" (`metaphor_seam_registry.pl:264-269`).
- **enumerate_positive_integer_pairs is constraint search**, closest to Object
  Construction (rectangles as built objects) but not a grounding-metaphor doing.
  Unforced mismatch, reported as such.

The registry itself currently holds 26 metaphor-operating rows and 17 seam rows;
the grade-7 middle of the curriculum is dominated by Measuring Stick (five ratio
rows and two circle rows, `metaphor_seam_registry.pl:146-229`), with BMI
appearing at probability (:257-283).

## 2. The five missing machines and the road to calculus

The learner-paths scout found that only one gate-genesis rung executes end to
end (whole numbers to integers) and named five machines that would connect the
ladder through to the existing calculus endpoint
(`.superpowers/sdd/task-2026-08-06-learner-paths-scout-report.md:42-45, 92-129`).
Placed on the metaphor map:

1. **Sharing refusal** (`whole_number_non_integer_share_refusal`) — the
   Collection gate refusing a non-integer share, repaired by the Construction
   gate. This is the collection-to-construction seam; the genesis row already
   exists but is "stated, not run" (`refusal_genesis_sketch.pl:127-131`).
2. **Covariation** (`ordered_quantity_covariation`) — sits past the seam where
   the algebra metonymy "stops_before covariational_practice"
   (`metaphor_seam_registry.pl:194-198`). Coordinated variation is not among the
   four grounding metaphors at all; this rung leaves them behind.
3. **Nested-interval root** (`nested_interval_real_line`) — the Measuring Stick's
   incommensurable break, repaired by the real line. The scout asked whether it
   could be composed from existing kernels; the probe answered no, and
   refine_bracket_by_order was admitted from that failure
   (`kernel_gate_pilot.pl:322-327`). The kernel now exists; the iterating shell
   does not.
4. **Frequency-sequence bridge** — connects the BMI seam in statistics to the
   existing tail-bound limit machine without equating a finite record with its
   limit (scout report :114-120).
5. **Function-approach bridge** — feeds the limit machines a punctured-
   neighborhood practice instead of a bare coefficient list (scout report
   :122-129).

So the path does climb, roughly, from collection through construction toward
stick, motion, and then BMI — and the registry's vanishing points sit at the
same joints where the missing machines are queued. Two honest limits: the
eight-rung family order is authored presentation, not a derived learner order
(the scout says this at :7-13), and rungs 4 (decimals, positional notation) and
6 (covariation) pass through territory the four metaphors do not name. The
climb is toward measurement-and-limit metaphors, but it is not a walk *inside*
the Lakoff-Núñez scheme; it exits the scheme twice.

## 3. Hyperedges

Two different relations in the tree get called hyperedges, and the gitignored
research note on this keeps them apart: shared-action groups (several machines
carrying one canonical action name — 85 groups) and joint-incompatibility sets
(contents that cannot all be held — currently 58 pairs and 641 triples in the
strict register). The structural relation to the kernels is specific: the
misconception corpus's incompatibility facts are all pairs
(`brandomian_incompatibility.pl:131-133`), while the one machine-checked
*emergent* triple — stick grounds length, length is a count of stick-units, the
diagonal is measured; every pair fine, the three jointly incoherent — is
exactly co_measure's refusal case, and the sketch cites it as the top rung of
the gate ladder (`refusal_genesis_sketch.pl:36-46, 132-136`). Conjecture, worth
testing: ordinary student errors are pairwise-statable, and it is the deep
metaphor seams that need three terms — a vanishing point, stated fully, is a
hyperedge.

## 4. Scenes

The 167 executed scenes are the render layer: a productive machine runs, and
its trace compiles to frames in a concrete setting — bars, lines, grids,
scales — so the doing is displayed rather than summarized
(`fraction_bars_scene.pl:1-10`; count per the 2026-08-04 handoff). Relation to
the kernels: a kernel/gate pair is setting-free; a scene supplies the enacted
setting in which the gate's sort becomes a drawable object (a partitioned bar
is `partitioned_whole(D)` made concrete). The Carspecken reading — that what a
scene backgrounds is precisely its gate, and a seam names where the backgrounded
setting fails (a bar cannot display −2) — is my gloss, consistent with the code
but not encoded in it.

## 5. The big picture

The learner module is shaping up as a three-layer account. At bottom, eight
metaphor-indifferent kernels that compute. Around them, gates that carry the
licensing — and the gates are where the known distinctions live: collection vs
construction vs stick vs motion are gate-level facts, annotated in an authored,
vetoable registry rather than baked into control flow. Across the top, one
generative move: a gate refuses a run; the student's repair of that refusal is
an attested error (swap the operands and 3 − 5 becomes 2,
`kernel_gate_pilot.pl:1104-1117`), and the institution's repair of the same
refusal is a new gate — the integers, the rationals, the reals
(`refusal_genesis_sketch.pl:26-46`). A misconception and a number system are
modeled as the same move under different scorekeeping. The borrowed-transition
census fills in the middle: 25 of the blue/mixed error rows are licensed
borrowings — a doing correct in its home practice, transported without its
license (`.superpowers/sdd/task-2026-08-06-borrowed-transition-report.md:19-49`) —
which is the mediant precedent generalized.

What this does not yet establish: only one genesis rung runs end to end; the
ladder order is authored; 28 percent of the corpus does not parse into the
shell-core shape the fractal claim needs
(`docs/research/2026-07-25-the-fractal-measured.md:189-205`); the metaphor rows
confirm consistency with Lakoff-Núñez, not facts about learners; and no
learner-path evidence exists anywhere in the tree. The honest summary: the
formal kernels do reflect the object-collection/measuring-stick distinction,
but at the gate layer, and the two places the kernel set breaks out of the
four-metaphor scheme — positional notation and co-measurement — are the
module's most original claims, precisely because no one handed them a metaphor.
