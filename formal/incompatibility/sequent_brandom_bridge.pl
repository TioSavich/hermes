/** <module> Bridge between the classical sequent engine and Brandomian incompatibility
 *
 * This is the glue the split plan (`docs/INCOMPATIBILITY_SPLIT_PLAN.md`, module
 * 3) staged but never built, and the wiring the project always assumed was
 * there: the classical sequent engine acting as a BACKSTOP on the Brandomian
 * incompatibility relation.
 *
 * Two jobs.
 *
 * 1. UNION INCOHERENCE (`b_incoherent/1`, `b_proves/1`). Material incoherence is
 *    judged Brandom-first: a set is incoherent if it contains a declared
 *    incompatible set (a hyperedge the classical engine cannot represent), OR if
 *    it is a classical negation-pair clash. So the bridge catches strictly more
 *    than either engine alone. `b_proves/1` is the incoherence-aware sequent
 *    front end: it adds earned explosion over `b_incoherent/1` to the classical
 *    prover.
 *
 * 2. THE BACKSTOP (`brandom_backstop/1`, `brandom_backstop_ok/0`). The reason
 *    the classical engine stays in the loop. A data-driven incompatibility
 *    relation can quietly go trivial — a stray singleton or empty hyperedge, a
 *    content that ends up incompatible with everything, an entailment relation
 *    that collapses to "everything entails everything". Any of those is the
 *    incompatibility-semantics form of explosion: incoherence stops being
 *    earned. The classical engine is the trusted reference for what coherence
 *    looks like, and the backstop audits the Brandomian relation against it.
 *    `brandom_backstop/1` returns a per-check report; `brandom_backstop_ok/0`
 *    succeeds iff every check passes. Callers that mutate `incompatible_set/1`
 *    at runtime should run it after mutating.
 *
 * This module is OPT-IN. Loading `sequent_engine` does not load this; callers
 * that want the Brandomian-augmented behavior `use_module` this explicitly. The
 * classical engine's own predicates are untouched.
 */
:- module(sequent_brandom_bridge,
          [ b_incoherent/1,         % +Set
            b_proves/1,             % +Sequent (Premises => Conclusions)
            brandom_backstop/1,     % -Report
            brandom_backstop_ok/0
          ]).

:- use_module(library(lists)).
:- use_module(sequent(sequent_engine), [ incoherent_base/1, safe_proves/2 ]).
:- use_module(incompat(brandomian_incompatibility),
              [ incompatible_set/1,
                brandomian_incoherent/1,
                coherent_set/1,
                minimal_incompatible_set/1,
                incompatibility_entails/2
              ]).

:- op(1050, xfy, =>).

% =================================================================
% Union incoherence + incoherence-aware sequent
% =================================================================

%!  b_incoherent(+Set) is semidet.
%
%   Brandom-first union incoherence. Brandomian hyperedge incoherence, falling
%   back to the classical law-of-non-contradiction over neg/1 pairs. The
%   fallback is what guarantees the bridge is never WEAKER than the classical
%   floor (see the classical_floor backstop check).
b_incoherent(Set) :-
    is_list(Set),
    ( brandomian_incoherent(Set)
    -> true
    ;  incoherent_base(Set)
    ).

%!  b_proves(+Sequent) is semidet.
%
%   Sequent is `Premises => Conclusions`. Succeeds when:
%     - identity: some premise also appears among the conclusions; or
%     - earned explosion: the premises are b_incoherent (contain a declared
%       hyperedge or a neg-pair) — ex falso, but only from incoherence that had
%       to be earned through declared incompatibility data; or
%     - the classical engine proves it (time-limited via safe_proves/2, so the
%       classical engine's known non-termination on some false goals cannot hang
%       the bridge).
%
%   The non-explosion property the project wanted lives here: from a COHERENT
%   premise set, b_proves cannot reach the explosion clause, so it does not
%   prove arbitrary conclusions. It proves only what identity or the classical
%   structural rules license.
b_proves((Premises => Conclusions)) :-
    is_list(Premises),
    is_list(Conclusions),
    ( member(P, Premises), memberchk_eq(P, Conclusions) -> true
    ; b_incoherent(Premises) -> true
    ; safe_proves((Premises => Conclusions), [time_limit(2)])
    ).

memberchk_eq(X, [Y|_]) :- X == Y, !.
memberchk_eq(X, [_|Ys]) :- memberchk_eq(X, Ys).

% =================================================================
% The backstop
% =================================================================

% Fresh probe contents: terms that appear in no incompatibility data, used to
% witness coherence and to detect universal-incompatible pathologies. The odd
% names keep them from colliding with real vocabulary.
probe_atom(brandom_probe_alpha_9z).
probe_atom(brandom_probe_beta_9z).
probe_atom(brandom_probe_gamma_9z).

%!  brandom_backstop(-Report) is det.
%
%   Run every backstop check and collect check(Name, Status, Detail) entries,
%   Status in {pass, fail}. The four checks correspond to the four ways a
%   data-driven incompatibility relation can explode.
brandom_backstop(Report) :-
    findall(Entry,
            ( backstop_check(Name, Goal, Detail),
              ( catch(call(Goal), _, fail) -> Status = pass ; Status = fail ),
              Entry = check(Name, Status, Detail)
            ),
            Report).

%!  brandom_backstop_ok is semidet.
%
%   Every backstop check passes.
brandom_backstop_ok :-
    brandom_backstop(Report),
    \+ member(check(_, fail, _), Report).

% --- the checks ----------------------------------------------------------
% Each backstop_check(Name, Goal, Detail): Goal succeeds iff the relation is
% well-behaved on that dimension.

% (1) Non-explosion: coherent sets exist. A pair of unrelated fresh contents is
% coherent, and so is a singleton fresh content. If these are incoherent the
% relation has gone trivial.
backstop_check(non_explosion,
               ( probe_atom(A), probe_atom(B), A \== B,
                 coherent_set([A]),
                 coherent_set([A, B])
               ),
               'a fresh content, and a pair of unrelated fresh contents, are coherent').

% (2) Classical floor: the bridge is never weaker than the law of
% non-contradiction. A neg-pair clash is incoherent through b_incoherent even
% though the Brandomian layer alone may carry no fact about it.
backstop_check(classical_floor,
               ( probe_atom(A),
                 b_incoherent([A, neg(A)]),
                 \+ b_incoherent([A])
               ),
               'b_incoherent covers classical neg-pairs without making a bare content incoherent').

% (3) Earned incoherence: no degenerate hyperedge. Every declared incompatible
% set has at least two members (no empty set, no singleton). An empty or
% singleton incompatible set would, by persistence, poison every set — the
% catastrophic explosion case. Also: no content is incompatible with a fresh,
% unrelated probe (no universal-incompatible content).
backstop_check(earned_incoherence,
               ( \+ degenerate_incompatible_set,
                 \+ universal_incompatible_content
               ),
               'every incompatible set has arity >= 2 and no content is incompatible with a fresh unrelated content').

% (4) Entailment non-triviality: incompatibility-entailment does not collapse.
% Unrelated fresh contents do not entail each other, and a content with no
% incompatibility profile is entailed by nothing (the vacuous-quantifier guard).
backstop_check(entailment_non_triviality,
               ( probe_atom(A), probe_atom(B), A \== B,
                 \+ incompatibility_entails(A, B),
                 \+ incompatibility_entails(B, A)
               ),
               'unrelated fresh contents do not incompatibility-entail each other').

% --- explosion detectors used by check (3) -------------------------------

degenerate_incompatible_set :-
    incompatible_set(Set),
    ( Set == []
    ; Set = [_]
    ),
    !.

universal_incompatible_content :-
    % a content C declared somewhere that turns out incoherent merely by being
    % paired with a fresh, unrelated probe — i.e. C is incompatible with
    % something it has no declared relation to.
    incompatible_set(Some),
    member(C, Some),
    probe_atom(P),
    \+ memberchk_eq_list(P, Some),
    brandomian_incoherent([C, P]),
    !.

memberchk_eq_list(X, [Y|_]) :- X == Y, !.
memberchk_eq_list(X, [_|Ys]) :- memberchk_eq_list(X, Ys).
