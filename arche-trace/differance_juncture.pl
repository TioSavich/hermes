/** <module> The juncture — where two reconstructions of one outcome meet
 *
 * SEED. This is the first kindling of the "breath to kindling" direction
 * (docs/research/2026-06-25-the-juncture-and-differance.md), not a finished
 * account. Register: the code ENCODES and MAKES QUERYABLE a structural fact;
 * it does not "implement" différance. The philosophy is Tio's; the Prolog
 * only holds the place where it can be asked.
 *
 * The fact it holds:
 *
 *   A circle halved by a radial cut and a circle halved by a vertical cut are
 *   the SAME outcome — two equal pieces, 1/2 — reached by two derivations with
 *   different histories. One derivation (radial) is normatively licensed; the
 *   other (vertical) is the deformation rule. At N = 2 they coincide; the
 *   vertical rule only diverges into unequal pieces at N >= 3. So at exactly
 *   1/2 the unlicensed move and the licensed move produce an identical result:
 *   a fixed point that is both normative failure (in derivation) and objective
 *   success (in outcome). This is a soft contradiction at the norm/outcome
 *   boundary, not a Liar-style self-negation. The outcome effaces which
 *   derivation produced it — the effaced trace. The numeral "1/2" is that
 *   anaphora: it carries the identity and loses the history.
 *
 *   The same shape recurs in arithmetic. X and X + 0 and X * 1 are one outcome
 *   reached by derivations whose enaction the result effaces. Add zero, multiply
 *   by one: identities of différance, enacted. Mathematics is full of this.
 *
 * Three frames meet here (Tio's neurosymbolic architecture): the SUBJECTIVE
 * (which derivation the learner took), the NORMATIVE (which derivation is
 * licensed — incompatibility, standards), and the OBJECTIVE (the outcome, and
 * the corpus fact that children do this). Because Prolog is homoiconic, the two
 * actions ARE terms, and their meeting is an assertion between terms. The LLM /
 * action-impetus is meant to sit at this juncture and query on the fractal loop.
 * That neuro layer is NOT in this file; the file is the symbolic place it sits.
 */

:- module(differance_juncture,
          [ enacted_identity/1,
            derivation/4,
            effaced_trace/2,
            differance_fixed_point/1,
            diverges_at/2,
            juncture/4
          ]).

% ---------------------------------------------------------------------------
% Derivations: one outcome, two histories. derivation(Name, Outcome, Path, Licensed).
% Path is a homoiconic term — the action, written as data.
% ---------------------------------------------------------------------------

% The spatial identity: 1/2 by radial cut vs 1/2 by vertical cut.
derivation(half, outcome(equal_parts(2)),
           partition(circle, radial, 2),   licensed).
derivation(half, outcome(equal_parts(2)),
           partition(circle, vertical, 2), unlicensed).

% Arithmetic identities of différance: the result effaces the operation.
derivation(self(X), outcome(X), recollect(X),        licensed) :- number(X).
derivation(self(X), outcome(X), add(X, 0),           licensed) :- number(X).
derivation(self(X), outcome(X), multiply(X, 1),      licensed) :- number(X).

% ---------------------------------------------------------------------------
% same_outcome_histories(Name, Outcome, Histories): one outcome reached by two
% or more distinct histories. This is the invariant enacted_identity/1 relies
% on; sharing only a Name is not enough.
% ---------------------------------------------------------------------------

same_outcome_histories(Name, Outcome, Histories) :-
    setof(Path-L, derivation(Name, Outcome, Path, L), Histories),
    Histories = [_, _ | _].

% enacted_identity(Name): an outcome reached by two or more distinct derivations.
enacted_identity(Name) :-
    same_outcome_histories(Name, _Outcome, _Histories).

% ---------------------------------------------------------------------------
% effaced_trace(Outcome, Paths): the outcome carries the identity and loses the
% histories. The numeral is the anaphora under erasure — it points back to a
% derivation that the result no longer shows.
% ---------------------------------------------------------------------------

effaced_trace(Outcome, Paths) :-
    setof(Path, Name^L^derivation(Name, Outcome, Path, L), Paths),
    Paths = [_, _ | _].

% ---------------------------------------------------------------------------
% The contradiction-bearing fixed point: one outcome reached by BOTH a licensed
% and an unlicensed derivation. Normative failure and objective success meet on
% the same result. This is not total self-negation; it is the identity where the
% outcome drops the licensing history.
% ---------------------------------------------------------------------------

differance_fixed_point(Name) :-
    derivation(Name, Outcome, _, licensed),
    derivation(Name, Outcome, _, unlicensed).

% Where the two derivations stop coinciding: the divergence the identity
% compresses. For the partition pair, vertical and radial agree at N = 2 and
% part company at N >= 3 (vertical width is not radial area once there are more
% than two pieces). Boundary fact for the seed; the parametric render layer
% supplies the visual deformation family, but this predicate does not compute
% areas.
diverges_at(half, n_geq(3)).

% ---------------------------------------------------------------------------
% juncture(Name, subjective(Path), normative(Licensed), objective(Outcome)):
% the single place where the three frames meet on one identity. The subjective
% derivation may or may not be normatively licensed; the objective outcome is
% the same either way. This is the Prolog file the architecture converges on.
% ---------------------------------------------------------------------------

juncture(Name, subjective(Path), normative(Licensed), objective(Outcome)) :-
    derivation(Name, Outcome, Path, Licensed).

% ---------------------------------------------------------------------------
% A reading, for inspection:  ?- show_juncture(half).
% ---------------------------------------------------------------------------

show_juncture(Name) :-
    format("juncture: ~w~n", [Name]),
    forall(juncture(Name, subjective(P), normative(L), objective(O)),
           format("  ~w  via ~q  [~w]~n", [O, P, L])),
    ( differance_fixed_point(Name)
    -> format("  -> différance fixed point: one outcome, licensed AND unlicensed; trace effaced~n")
    ;  true ),
    ( diverges_at(Name, D) -> format("  -> the compressed divergence reappears at ~w~n", [D]) ; true ).
