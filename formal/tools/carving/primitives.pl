% formal/tools/carving/primitives.pl
%
% Proof rules for CORRECT arithmetic facts. Each rule corresponds to one
% strategy. Base-parameterized throughout (works at base 10, base 5, etc.).
%
% Each rule is a clause of carving_synthesizer:prove/3 with shape:
%   prove(+Fact, +Config, -Proof)
% A Proof is a term proof(StrategyName, [Step1, Step2, ...]).
%
% Note on the "build connections" reading: each step in a proof body is a
% connection-edge. A fact with many proofs is highly connected (entitled
% via multiple inferential routes). The tolerance parameter doesn't model
% fatigue; it bounds how many homogeneous steps a single proof may carry
% before some structurally-different step is required.

:- module(carving_primitives, []).
:- use_module(synthesizer).

:- multifile(carving_synthesizer:prove/3).
:- discontiguous(carving_synthesizer:prove/3).

% ----- Zero identity -----
% X + 0 = X and 0 + Y = Y are trivially carved without invoking memory or counting.
% (Important: count_on requires the smaller addend >= 1, and lookup requires
% the fact to be in known_fact/4. Without an identity rule, 0-cases remain residue.)
carving_synthesizer:prove(fact(add, X, 0, X), _Config,
                          proof(zero_identity, [identity_right(X)])) :-
    X >= 0.
carving_synthesizer:prove(fact(add, 0, Y, Y), _Config,
                          proof(zero_identity, [identity_left(Y)])) :-
    Y >= 1.   % avoid double-firing on (0,0,0); right-identity already covers it

% ----- Lookup -----
% Cheapest entitlement: the fact is already in the recollection store
% (either initial single-digit table or memoized from prior carving rounds).
carving_synthesizer:prove(fact(Op, X, Y, Z), _Config,
                          proof(lookup, [recollection(Op, X, Y, Z)])) :-
    carving_synthesizer:known_fact(Op, X, Y, Z).

% ----- Counting-on from larger (COL) -----
% Always available; bounded by tolerance on the smaller addend.
carving_synthesizer:prove(fact(add, X, Y, Z), Config,
                          proof(count_on, [start(L), successor_n(M, Z)])) :-
    Z =:= X + Y,
    M is min(X, Y),
    L is max(X, Y),
    M >= 1,
    Tol = Config.tolerance,
    M =< Tol.

% ----- Counting-on via memorized successor chain -----
% Available at level 1 IF the recollection store carries succ_chain facts
% (Peano-style chains: succ_chain(N, [s, s, ..., s(0)])). This represents
% a learner who has memorized the successor structure of small numerals
% but does not yet see "ten" as a unit. The proof body is the chain itself.
carving_synthesizer:prove(fact(add, X, Y, Z), _Config,
                          proof(succ_chain_count_on,
                                [start(X), apply_chain(Y, Chain), result(Z)])) :-
    carving_synthesizer:known_fact(succ_chain, Y, _, Chain),
    Z =:= X + Y,
    Y >= 1.

% ----- Counting-on from larger, using a sub-proof of the count (RECURSIVE COL) -----
% At level >= 2 we allow the "smaller" addend to itself be a known fact
% bigger than tolerance, as long as that fact has been previously carved.
% This is what gives the system access to 8 + 12 even when 12 > tolerance:
% if we already know 12 = 10 + 2, we can split.
carving_synthesizer:prove(fact(add, X, Y, Z), Config,
                          proof(count_on_via_split,
                                [start(L), split(M, [A, B]),
                                 count_on(L, A, MID),
                                 count_on(MID, B, Z)])) :-
    Z =:= X + Y,
    Config.unit_levels >= 2,
    M is min(X, Y),
    L is max(X, Y),
    M > Config.tolerance,
    % find a split M = A + B with both pieces within tolerance
    between(1, Config.tolerance, A),
    B is M - A,
    B >= 1, B =< Config.tolerance,
    MID is L + A.

% ----- Rearranging to make base (RMB) -----
% Requires seeing "Base" as a unit; i.e., unit_levels >= 2.
% Bridge from the larger addend up to the next multiple of Base.
carving_synthesizer:prove(fact(add, X, Y, Z), Config,
                          proof(rmb(Base),
                                [decompose(M, [Rem, Bridge]),
                                 bridge_to_base(L, Rem, NextBase),
                                 count_on(NextBase, Bridge, Z)])) :-
    Z =:= X + Y,
    Config.unit_levels >= 2,
    Base = Config.base,
    Tol = Config.tolerance,
    L is max(X, Y),
    M is min(X, Y),
    M >= 1,
    Rem is (Base - (L mod Base)) mod Base,
    Rem > 0, Rem =< Tol,
    Bridge is M - Rem,
    Bridge >= 0, Bridge =< Tol,
    NextBase is L + Rem.

% ----- Decimal (place-value) decomposition -----
% Requires unit_levels >= 2. Splits both addends into Base-units and
% ones, sums each column, and recomposes (with carry if needed).
% Recursive: the column sums must themselves be derivable (typically via
% the single-digit lookup that the system has memoized in early rounds).
carving_synthesizer:prove(fact(add, X, Y, Z), Config,
                          proof(decimal_decomp(Base),
                                [split_place(X, [TensX, OnesX]),
                                 split_place(Y, [TensY, OnesY]),
                                 add_ones(OnesX, OnesY, OnesSum),
                                 carry(Carry, FinalOnes),
                                 add_tens_with_carry(TensX, TensY, Carry,
                                                     FinalTens),
                                 recompose([FinalTens, FinalOnes], Base, Z)])) :-
    Z =:= X + Y,
    Config.unit_levels >= 2,
    Base = Config.base,
    (X >= Base ; Y >= Base),
    OnesX is X mod Base, TensX is X div Base,
    OnesY is Y mod Base, TensY is Y div Base,
    OnesSum is OnesX + OnesY,
    ( OnesSum >= Base
    -> Carry = 1, FinalOnes is OnesSum - Base
    ;  Carry = 0, FinalOnes = OnesSum ),
    FinalTens is TensX + TensY + Carry,
    Z =:= FinalTens * Base + FinalOnes,
    % Sub-proofs must be reachable: ones sums and tens sums must be carve-able
    % by simpler means at this level (typically via lookup once memoized).
    OnesSum =< Base + Base - 2,
    FinalTens =< 2 * (200 div Base).

% ----- Doubles + a small adjustment -----
% Near-doubles strategy: X + Y = 2*M + delta, where delta is small.
carving_synthesizer:prove(fact(add, X, Y, Z), Config,
                          proof(near_doubles,
                                [identify_near_double(X, Y, M, Delta),
                                 double(M, TwoM),
                                 count_on(TwoM, Delta, Z)])) :-
    Z =:= X + Y,
    Config.unit_levels >= 1,
    Tol = Config.tolerance,
    M is min(X, Y),
    L is max(X, Y),
    Delta is L - M,
    Delta >= 0, Delta =< Tol,
    M >= 1,
    M =< 10,                       % "doubles" we expect to be memorized
    TwoM is 2 * M.

% ----- RMB via count-back (cognitively-faithful variant) -----
% Same numerical effect as rmb/3 above, but the proof body explicitly
% shows count_back as the route by which the bridge distance was found.
% This is the "in-activity" version per Hackenberg's distinction: the
% complement-to-base is DERIVED via counting back from candidate-base
% to the current number, rather than recalled from interiorized
% complement-of-Base knowledge. A learner without "complements of 10"
% memorized can still RMB via this route.
carving_synthesizer:prove(fact(add, X, Y, Z), Config,
                          proof(rmb_via_count_back(Base),
                                [identify_candidate_base(L, NextBase),
                                 count_back_to(NextBase, L, Rem),
                                 decompose(M, [Rem, Bridge]),
                                 bridge_to_base(L, Rem, NextBase),
                                 count_on(NextBase, Bridge, Z)])) :-
    Z =:= X + Y,
    Config.unit_levels >= 2,
    Base = Config.base,
    Tol = Config.tolerance,
    L is max(X, Y),
    M is min(X, Y),
    M >= 1,
    Rem is (Base - (L mod Base)) mod Base,
    Rem > 0, Rem =< Tol,
    Bridge is M - Rem,
    Bridge >= 0, Bridge =< Tol,
    NextBase is L + Rem.

% ----- Rounding (round-and-adjust via substitute + count-back correction) -----
% Round L up to NextBase, add M, then count back K to correct for the
% over-shoot. 8+5 = (8+2)+5 - 2 = 10 + 5 - 2 = 13.
% Distinct from RMB: RMB rearranges within the sum (K moves from M to L);
% rounding modifies L outside the sum and corrects afterward.
carving_synthesizer:prove(fact(add, X, Y, Z), Config,
                          proof(rounding(Base),
                                [identify_candidate_base(L, NextBase),
                                 count_back_to(NextBase, L, K),
                                 substitute(L, NextBase),
                                 add_substituted(NextBase, M, OverShoot),
                                 count_back(OverShoot, K, Z)])) :-
    Z =:= X + Y,
    Config.unit_levels >= 2,
    Base = Config.base,
    Tol = Config.tolerance,
    L is max(X, Y),
    M is min(X, Y),
    M >= 1,
    K is (Base - (L mod Base)) mod Base,
    K > 0, K =< Tol,
    NextBase is L + K,
    OverShoot is NextBase + M.

% ============================================================================
% SUBTRACTION primitives
% ============================================================================
% Mirror to sar_sub_*.pl. The "chunking unlock" hypothesis: at level 2,
% chunking strategies (A: take-away by place value; B: missing-addend by
% chunks; C: count-back to subtrahend by chunks) should carve the 2-digit
% region that counting-back alone leaves as residue.

% ----- Zero identity for subtraction -----
carving_synthesizer:prove(fact(sub, X, 0, X), _Config,
                          proof(zero_identity_sub, [identity(X)])) :-
    X >= 0.
% Identity by self-cancellation: X - X = 0.
carving_synthesizer:prove(fact(sub, X, X, 0), _Config,
                          proof(self_cancel_sub, [cancel(X, 0)])) :-
    X >= 1.

% ----- Counting back: the foundational subtraction strategy -----
% Start at M, iterate predecessor S times. Bounded by tolerance on S.
carving_synthesizer:prove(fact(sub, M, S, Z), Config,
                          proof(counting_back, [start(M), predecessor_n(S, Z)])) :-
    Z =:= M - S,
    S >= 1,
    S =< Config.tolerance.

% ----- COBO Missing-Addend: count up from S to reach M -----
% Frame the subtraction as "what do I add to S to get M?" Adds bases first
% then ones. Distance is the answer.
carving_synthesizer:prove(fact(sub, M, S, Z), Config,
                          proof(cobo_missing_addend,
                                [target(M), start(S),
                                 count_up_by_bases(S, Bases, S1),
                                 count_up_by_ones(S1, Ones, M),
                                 distance(Z)])) :-
    Z =:= M - S,
    Config.unit_levels >= 2,
    Base = Config.base,
    Z >= 1,
    Bases is Z div Base,
    Ones is Z mod Base,
    S1 is S + Bases * Base.

% ----- CBBO Take-Away: count back from M by bases then ones -----
% Decompose S into bases and ones; subtract bases first, then ones.
carving_synthesizer:prove(fact(sub, M, S, Z), Config,
                          proof(cbbo_take_away,
                                [start(M),
                                 split_place(S, [BaseChunks, OneChunks]),
                                 count_back_bases(M, BaseChunks, Mid),
                                 count_back_ones(Mid, OneChunks, Z)])) :-
    Z =:= M - S,
    Config.unit_levels >= 2,
    Base = Config.base,
    S >= Base,
    BaseChunks is S div Base,
    OneChunks is S mod Base,
    Mid is M - BaseChunks * Base.

% ----- Chunking A: take-away by place-value chunks of the subtrahend -----
% The flagship "chunking unlock" pattern. Subtract the largest place-value
% chunk of S from M, then the next, etc. Distinct from CBBO because the
% chunk sizes are place-valued numerals (200, 30, 4) rather than counts.
% At small scale (< 100) this looks like CBBO; the structural difference
% shows up on three-digit problems.
carving_synthesizer:prove(fact(sub, M, S, Z), Config,
                          proof(chunking_a,
                                [start(M),
                                 leading_chunk(S, BigChunk),
                                 subtract_chunk(M, BigChunk, Mid),
                                 remaining(S, BigChunk, Rest),
                                 subtract_rest(Mid, Rest, Z)])) :-
    Z =:= M - S,
    Config.unit_levels >= 2,
    Base = Config.base,
    S >= Base,
    leading_place_chunk(S, Base, BigChunk),
    BigChunk > 0,
    Rest is S - BigChunk,
    Mid is M - BigChunk,
    Mid >= Rest.

% Helper: extract the leading place-value chunk of N in given Base.
% E.g. leading_place_chunk(234, 10, 200).
leading_place_chunk(N, Base, Chunk) :-
    N > 0,
    leading_place_chunk_(N, Base, 1, Chunk).
leading_place_chunk_(N, Base, Place, Chunk) :-
    Next is Place * Base,
    ( N < Next
    -> Lead is N div Place,
       Chunk is Lead * Place
    ;  leading_place_chunk_(N, Base, Next, Chunk) ).

% ----- Chunking B: missing-addend by strategic chunks (forward to base) -----
% Stand at S. First jump to next multiple of Base, then jump by bases,
% then by ones, accumulating the chunks as Distance.
carving_synthesizer:prove(fact(sub, M, S, Z), Config,
                          proof(chunking_b,
                                [start(S), target(M),
                                 jump_to_next_base(S, K, NextBase),
                                 jump_by_bases(NextBase, BaseJumps, Mid),
                                 jump_by_ones(Mid, OneJumps, M),
                                 sum_chunks([K, BaseJumps, OneJumps], Z)])) :-
    Z =:= M - S,
    Config.unit_levels >= 2,
    Base = Config.base,
    Z >= 1,
    K is (Base - (S mod Base)) mod Base,
    K =< Z,
    NextBase is S + K,
    NextBase =< M,
    Remaining is M - NextBase,
    BaseJumps is Remaining div Base,
    OneJumps is Remaining mod Base,
    Mid is NextBase + BaseJumps * Base.

% ----- Chunking C: count-back-to-subtrahend by chunks -----
% Stand at M. First step down to the previous multiple of Base, then by
% bases, then by ones. Distance accumulated.
carving_synthesizer:prove(fact(sub, M, S, Z), Config,
                          proof(chunking_c,
                                [start(M), target(S),
                                 step_down_to_prev_base(M, K, PrevBase),
                                 jump_back_by_bases(PrevBase, BaseJumps, Mid),
                                 jump_back_by_ones(Mid, OneJumps, S),
                                 sum_chunks([K, BaseJumps, OneJumps], Z)])) :-
    Z =:= M - S,
    Config.unit_levels >= 2,
    Base = Config.base,
    Z >= 1,
    K is M mod Base,
    K =< Z,
    K > 0,
    PrevBase is M - K,
    PrevBase >= S,
    Remaining is PrevBase - S,
    BaseJumps is Remaining div Base,
    OneJumps is Remaining mod Base,
    Mid is PrevBase - BaseJumps * Base.

% ----- Decomposition (standard borrowing algorithm) -----
% Subtract column by column; borrow when ones-of-M < ones-of-S.
carving_synthesizer:prove(fact(sub, M, S, Z), Config,
                          proof(decomposition(Base),
                                [split_place(M, [TensM, OnesM]),
                                 split_place(S, [TensS, OnesS]),
                                 borrow_if_needed(OnesM, OnesS, BorrowedTens,
                                                  EffectiveOnesM),
                                 sub_ones(EffectiveOnesM, OnesS, FinalOnes),
                                 sub_tens(TensM, TensS, BorrowedTens, FinalTens),
                                 recompose([FinalTens, FinalOnes], Base, Z)])) :-
    Z =:= M - S,
    Config.unit_levels >= 2,
    Base = Config.base,
    M >= Base,
    OnesM is M mod Base, TensM is M div Base,
    OnesS is S mod Base, TensS is S div Base,
    ( OnesM >= OnesS
    -> BorrowedTens = 0, EffectiveOnesM = OnesM
    ;  BorrowedTens = 1, EffectiveOnesM is OnesM + Base ),
    FinalOnes is EffectiveOnesM - OnesS,
    FinalTens is TensM - TensS - BorrowedTens,
    FinalTens >= 0,
    Z =:= FinalTens * Base + FinalOnes.

% ----- Sliding (constant difference) -----
% (M + K) - (S + K) = M - S. Choose K so S+K lands on a base.
carving_synthesizer:prove(fact(sub, M, S, Z), Config,
                          proof(sliding(Base),
                                [find_slide(S, K, AdjS),
                                 slide(M, K, AdjM),
                                 subtract_aligned(AdjM, AdjS, Z)])) :-
    Z =:= M - S,
    Config.unit_levels >= 2,
    Base = Config.base,
    S >= 1,
    K is (Base - (S mod Base)) mod Base,
    K > 0,
    K =< Config.tolerance,
    AdjS is S + K,
    AdjM is M + K.

% ----- Sub-rounding: round S up, subtract, then add back K -----
% M - S = M - (S + K) + K. Choose K so S+K lands on a base.
carving_synthesizer:prove(fact(sub, M, S, Z), Config,
                          proof(sub_rounding(Base),
                                [identify_candidate_base(S, NextBase),
                                 count_up_to(S, NextBase, K),
                                 substitute(S, NextBase),
                                 sub_substituted(M, NextBase, UnderShoot),
                                 count_on(UnderShoot, K, Z)])) :-
    Z =:= M - S,
    Config.unit_levels >= 2,
    Base = Config.base,
    Tol = Config.tolerance,
    S >= 1,
    K is (Base - (S mod Base)) mod Base,
    K > 0, K =< Tol,
    NextBase is S + K,
    NextBase =< M,
    UnderShoot is M - NextBase.

% ----- Near-doubles for subtraction -----
% If M ≈ 2*S then M-S ≈ S (M-S = S + delta where delta = M - 2*S).
carving_synthesizer:prove(fact(sub, M, S, Z), Config,
                          proof(near_doubles_sub,
                                [identify_near_double(M, S, Delta),
                                 double_known(S, TwoS),
                                 adjust(TwoS, M, Delta),
                                 result(Z)])) :-
    Z =:= M - S,
    Config.unit_levels >= 1,
    S >= 1, S =< 10,
    TwoS is 2 * S,
    Delta is M - TwoS,
    abs(Delta) =< Config.tolerance,
    Z is S + Delta.

% ============================================================================
% MULTIPLICATION primitives
% ============================================================================
% Mirror to smr_mult_*.pl: C2C, commutative-reasoning (repeated addition),
% CBO (group redistribution to base), DR (distributive reasoning), doubling,
% commutative-swap. Plus zero/one identities and lookup.

% ----- Zero and one identities -----
carving_synthesizer:prove(fact(mult, X, 0, 0), _Config,
                          proof(zero_annihilator, [annihilator_right(X)])) :-
    X >= 0.
carving_synthesizer:prove(fact(mult, 0, Y, 0), _Config,
                          proof(zero_annihilator, [annihilator_left(Y)])) :-
    Y >= 1.
carving_synthesizer:prove(fact(mult, X, 1, X), _Config,
                          proof(one_identity_mult, [identity_right(X)])) :-
    X >= 1.
carving_synthesizer:prove(fact(mult, 1, Y, Y), _Config,
                          proof(one_identity_mult, [identity_left(Y)])) :-
    Y >= 2.    % avoid double-firing for (1,1,1); right-identity covers it

% ----- C2C: Coordinating Two Counts (direct modeling) -----
% Count S items, N times. Total = N*S, but the proof shape is "tick all
% N*S items individually under a double-tracking discipline." Bounded by
% N*S =< tolerance^2 to mirror the cognitive load of literal counting.
carving_synthesizer:prove(fact(mult, N, S, Z), Config,
                          proof(c2c,
                                [groups(N), items_per_group(S),
                                 double_track(N, S),
                                 total(Z)])) :-
    Z =:= N * S,
    N >= 2, S >= 2,
    Tol = Config.tolerance,
    N =< Tol, S =< Tol.

% ----- Commutative repeated addition -----
% N*S = S + S + ... + S (N times). The "less brittle than C2C" version —
% the count of S is treated as a unit, not item-by-item.
carving_synthesizer:prove(fact(mult, N, S, Z), Config,
                          proof(commutative_repeated_addition,
                                [groups(N), addend(S),
                                 sum_n_copies(N, S, Z)])) :-
    Z =:= N * S,
    N >= 1, S >= 1,
    Tol = Config.tolerance,
    Smaller is min(N, S),
    Smaller =< Tol.

% ----- Commutative swap (reframe to the easier direction) -----
% N*S = S*N when S*N has a sub-proof we already trust. This pulls weight
% when one of N, S is in the memorized table but the other is not.
carving_synthesizer:prove(fact(mult, N, S, Z), _Config,
                          proof(commutative_swap,
                                [commute(N, S),
                                 recollection(mult, S, N, Z)])) :-
    Z =:= N * S,
    N \= S,
    carving_synthesizer:known_fact(mult, S, N, Z).

% ----- Distributive reasoning -----
% N*(A+B) = N*A + N*B. Split S into A+B with both pieces in the
% memorized table, then combine.
carving_synthesizer:prove(fact(mult, N, S, Z), Config,
                          proof(distributive_reasoning,
                                [split(S, [A, B]),
                                 partial(mult(N, A), PA),
                                 partial(mult(N, B), PB),
                                 sum_partials(PA, PB, Z)])) :-
    Z =:= N * S,
    Config.unit_levels >= 2,
    N >= 1, S >= 2,
    between(1, 9, A),
    B is S - A,
    B >= 1, B =< 9, A =< B,    % A =< B canonicalizes the split
    PA is N * A,
    PB is N * B,
    Z =:= PA + PB.

% ----- Doubling (N*2 = N+N) -----
% Treat doubling as a recognized cardinal-pairing move rather than
% repeated addition. Cognitively cheap when N is in the doubles table.
carving_synthesizer:prove(fact(mult, N, 2, Z), _Config,
                          proof(doubling, [double(N, Z)])) :-
    Z =:= N * 2,
    N >= 1, N =< 20.
carving_synthesizer:prove(fact(mult, 2, N, Z), _Config,
                          proof(doubling, [double(N, Z)])) :-
    Z =:= 2 * N,
    N >= 1, N =< 20,
    N =\= 2.   % avoid double-firing for (2,2,4)

% ----- CBO Multiplication: redistribute groups to base -----
% Make N groups of S; redistribute items so as many groups as possible
% are filled to Base. Reading the rearranged total gives N*S by
% conservation. This is the Steffe "iterable composite unit" move:
% requires unit_levels >= 2 and N*S not trivially in lookup.
carving_synthesizer:prove(fact(mult, N, S, Z), Config,
                          proof(cbo_mult(Base),
                                [make_groups(N, S),
                                 redistribute_to_base(Base),
                                 full_groups(F, Base),
                                 partial_group(R),
                                 recompose([F, R], Base, Z)])) :-
    Z =:= N * S,
    Config.unit_levels >= 2,
    Base = Config.base,
    N >= 2, S >= 2,
    Z >= Base,
    F is Z div Base,
    R is Z mod Base.

% ----- Decimal decomposition for multiplication -----
% (Tens_X * Base + Ones_X) * Y = Tens_X * Base * Y + Ones_X * Y.
% A more explicit place-value version of distributive_reasoning.
carving_synthesizer:prove(fact(mult, X, Y, Z), Config,
                          proof(decimal_decomp_mult(Base),
                                [split_place(X, [TensX, OnesX]),
                                 partial(mult(TensX, Y), Hundreds),
                                 mult_by_base(Hundreds, Base, HundredsScaled),
                                 partial(mult(OnesX, Y), Ones),
                                 sum_partials(HundredsScaled, Ones, Z)])) :-
    Z =:= X * Y,
    Config.unit_levels >= 2,
    Base = Config.base,
    X >= Base,
    OnesX is X mod Base,
    TensX is X div Base,
    Hundreds is TensX * Y,
    HundredsScaled is Hundreds * Base,
    Ones is OnesX * Y.

% ============================================================================
% DIVISION primitives (exact division only — remainder = 0)
% ============================================================================
% Mirror to smr_div_*.pl: dealing-by-ones, UCR (repeated addition to T),
% IDP (inverse of distributive — subtract known multiples), CBO (decompose
% T into bases). Plus zero/one identities, lookup, and inverse-of-known-mult.

% ----- Zero dividend (0 / S = 0 for S >= 1) -----
carving_synthesizer:prove(fact(div, 0, S, 0), _Config,
                          proof(zero_dividend, [zero_in(S)])) :-
    S >= 1.

% ----- Divide-by-one identity -----
carving_synthesizer:prove(fact(div, T, 1, T), _Config,
                          proof(one_divisor_identity, [identity(T)])) :-
    T >= 1.

% ----- Divide-by-self identity (T / T = 1) -----
carving_synthesizer:prove(fact(div, T, T, 1), _Config,
                          proof(self_divisor_identity, [self_cancel(T)])) :-
    T >= 1.

% ----- Inverse of a known multiplication fact -----
% If mult(Q, S, T) is in the memoized store, then T / S = Q.
carving_synthesizer:prove(fact(div, T, S, Q), _Config,
                          proof(inverse_of_known_mult,
                                [recollection(mult, Q, S, T),
                                 invert_to_div(T, S, Q)])) :-
    S >= 1,
    carving_synthesizer:known_fact(mult, Q, S, T),
    Q >= 1.

% ----- Dealing by ones (partitive direct modeling) -----
% Distribute T items into S groups one at a time. Q is the per-group
% count. Cognitively expensive: cost proportional to T.
carving_synthesizer:prove(fact(div, T, S, Q), Config,
                          proof(dealing_by_ones,
                                [items(T), groups(S),
                                 deal_one_at_a_time(T, S, Q)])) :-
    S >= 1, T >= 1,
    Q is T // S, 0 =:= T mod S,
    Tol = Config.tolerance,
    T =< Tol * Tol.

% ----- UCR: Using Commutative Reasoning (repeated addition) -----
% Find Q such that Q*S = T by adding S to itself, counting iterations.
% Quotative direct modeling, measurement variant.
carving_synthesizer:prove(fact(div, T, S, Q), Config,
                          proof(ucr_repeated_addition,
                                [divisor(S), target(T),
                                 add_until_hit(S, Q, T)])) :-
    S >= 1, T >= S,
    Q is T // S, 0 =:= T mod S,
    Tol = Config.tolerance,
    Q =< Tol.

% ----- IDP: Inverse of Distributive Property (chunk by known multiples) -----
% Subtract a known large multiple of S from T, then a known small
% multiple; sum the factors. Requires the mult sub-facts to be known.
carving_synthesizer:prove(fact(div, T, S, Q), Config,
                          proof(idp_known_multiples,
                                [divisor(S),
                                 subtract_multiple(T, S, Q1, R),
                                 subtract_multiple(R, S, Q2, 0),
                                 sum_quotients(Q1, Q2, Q)])) :-
    Config.unit_levels >= 2,
    S >= 2, T >= S,
    Q is T // S, 0 =:= T mod S,
    Q >= 2,
    between(1, Q, Q1),
    Q2 is Q - Q1,
    Q2 >= 1, Q1 =< Q2,        % canonicalize (Q1 =< Q2)
    R is T - Q1 * S,
    R >= S.

% ----- CBO Division: decompose T into bases, divide each part -----
% T = TensT * Base + OnesT. Compute (TensT * Base) / S and OnesT / S
% separately (assuming both are exact). This is the place-value
% version of IDP and aligns with smr_div_cbo.
carving_synthesizer:prove(fact(div, T, S, Q), Config,
                          proof(cbo_div(Base),
                                [split_place(T, [TensT, OnesT]),
                                 base_pieces(TensT, Base, S, QH),
                                 ones_pieces(OnesT, S, QL),
                                 sum_quotients(QH, QL, Q)])) :-
    Config.unit_levels >= 2,
    Base = Config.base,
    S >= 1, T >= Base,
    Q is T // S, 0 =:= T mod S,
    OnesT is T mod Base,
    TensT is T div Base,
    HighPart is TensT * Base,
    0 =:= HighPart mod S,
    QH is HighPart // S,
    0 =:= OnesT mod S,
    QL is OnesT // S,
    Q =:= QH + QL.

% ----- Halving (T / 2 by recognized doubles fact) -----
carving_synthesizer:prove(fact(div, T, 2, Q), _Config,
                          proof(halving, [halve(T, Q)])) :-
    T >= 2, 0 =:= T mod 2,
    Q is T // 2.

% ============================================================================
% FRACTION construction primitives
% ============================================================================
% Three core productive moves and one classic deformation. Aligned with
% knowledge/strategies/math/fraction_action_pairs.pl: partitive (1/D from the
% whole), iterative (N/D from N copies of 1/D), equivalence (N/D = M/E
% when D*M = E*N), and whole_number_grab (the deformation that ignores
% the denominator).

% ----- 1/1: the whole as a fraction of itself -----
carving_synthesizer:prove(fact(frac, 1, 1, fraction(1, 1)), _Config,
                          proof(whole_as_fraction,
                                [name_the_whole,
                                 trivial_partition(1)])) :- true.

% ----- N/N: the whole reconstituted from N copies of 1/N (N >= 2) -----
carving_synthesizer:prove(fact(frac, N, N, fraction(N, N)), _Config,
                          proof(reconstituted_whole,
                                [partition(N),
                                 iterate_unit_fraction(N, fraction(1, N)),
                                 reach_whole_at(N)])) :-
    N >= 2.

% ----- Unit fraction 1/D: partitive operation on the whole -----
carving_synthesizer:prove(fact(frac, 1, D, fraction(1, D)), _Config,
                          proof(unit_fraction_partition,
                                [establish_referent_whole(unit),
                                 partition_into_equal_parts(D),
                                 name_one_part(fraction(1, D))])) :-
    D >= 2.

% ----- Non-unit fraction N/D: iterate N copies of the unit fraction -----
carving_synthesizer:prove(fact(frac, N, D, fraction(N, D)), _Config,
                          proof(unit_fraction_iteration,
                                [unit_fraction(D, fraction(1, D)),
                                 iterate_count(N),
                                 gather(fraction(N, D))])) :-
    N >= 2, D >= 2, N =< D.

% ----- Equivalence: N/D = M/E when D*M = E*N -----
% e.g. 2/4 = 1/2 via the (D*M = E*N) cross-multiplication check.
% Carves N/D by exhibiting a simpler equivalent M/E already in the
% recollection store.
carving_synthesizer:prove(fact(frac, N, D, fraction(N, D)), _Config,
                          proof(equivalence_class,
                                [find_simpler(M, E),
                                 cross_check(D*M, E*N),
                                 recollection(frac, M, E, fraction(M, E))])) :-
    N >= 2, D >= 3,
    carving_synthesizer:known_fact(frac, M, E, fraction(M, E)),
    (M \= N ; E \= D),
    D * M =:= E * N.

% ============================================================================
% FRACTION primitives requiring three-level unit coordination (L3)
% ============================================================================
% Three-level unit coordination (Hackenberg/Steffe): the learner can
% treat a unit fraction 1/D as itself a unit that persists across
% boundaries — either across the whole (improper iteration) or under
% a further partitioning (fraction-of-fraction). The L3 gate is
% Config.unit_coords >= 3. unit_coords is optional in Config; absent
% defaults to whatever Config.unit_levels says about the whole-number
% base layer (i.e. legacy experiments keep working).
%
% NOTE: do not conflate Config.unit_levels (base/place-value cognition)
% with Config.unit_coords (fraction unit-coordination depth). They are
% related conceptually but distinct as parameters.

% Helper to read unit_coords with backward-compatible default.
% Use a hand-written predicate so SWI's dict-default semantics don't
% bite us with missing keys.
:- discontiguous(carving_synthesizer:prove/3).

% ----- Improper fraction by direct iteration (N > D, N =< 2*D) -----
% Iterate 1/D N times. Recognize the whole-crossing at the D-th
% iteration but do not stop there — the unit fraction persists.
carving_synthesizer:prove(fact(frac, N, D, fraction(N, D)), Config,
                          proof(improper_iteration,
                                [unit_fraction(D, fraction(1, D)),
                                 iterate_count(N),
                                 crossing_at(D, whole),
                                 persist_unit_past_whole,
                                 gather(fraction(N, D))])) :-
    N > D, D >= 2,
    get_dict(unit_coords, Config, UC),
    UC >= 3.

% ----- Mixed-number decomposition -----
% N/D = (N div D) wholes + (N mod D)/D. Equivalent value, different
% inferential structure. The proof body cites a whole-number-iteration
% step and a proper-fraction-iteration step.
carving_synthesizer:prove(fact(frac, N, D, fraction(N, D)), Config,
                          proof(mixed_number_decomposition,
                                [wholes(Q),
                                 remainder_part(R, D),
                                 unit_fraction(D, fraction(1, D)),
                                 iterate_count_within_whole(R),
                                 add_wholes_and_remainder(Q, fraction(R, D),
                                                          fraction(N, D))])) :-
    N > D, D >= 2,
    Q is N // D, R is N mod D,
    Q >= 1,
    get_dict(unit_coords, Config, UC),
    UC >= 3.

% ----- Unit fraction product: 1/B * 1/D = 1/(B*D) -----
% The simplest fraction-of-fraction case. The proof body is the
% area-model construction.
carving_synthesizer:prove(fact(frac_of, fraction(1, B), fraction(1, D),
                               fraction(1, P)),
                          Config,
                          proof(unit_fraction_product,
                                [partition_whole_by(B),
                                 take_part(fraction(1, B)),
                                 re_partition_part_by(D),
                                 identify_subpart(fraction(1, P))])) :-
    B >= 2, D >= 2,
    P =:= B * D,
    get_dict(unit_coords, Config, UC),
    UC >= 3.

% ----- Area-model composition of two fractions (productive) -----
% (a/b) * (c/d) by partitioning a unit square along each denominator,
% identifying the (b*d)-grid sub-rectangle of size a-by-c. The
% inferential anchor of the (a*c)/(b*d) computation.
carving_synthesizer:prove(fact(frac_of, fraction(A, B), fraction(C, D),
                               fraction(P, Q)),
                          Config,
                          proof(area_model_compose,
                                [partition_horizontally_by(B),
                                 partition_vertically_by(D),
                                 cell_unit(fraction(1, Q)),
                                 select_rectangle(A, C),
                                 count_selected_cells(P)])) :-
    B >= 2, D >= 2,
    A >= 1, A =< B,            % proper-fraction operands
    C >= 1, C =< D,
    P =:= A * C, Q =:= B * D,
    \+ (A =:= 1, C =:= 1),     % the all-1 case is covered by unit_fraction_product
    get_dict(unit_coords, Config, UC),
    UC >= 3.

% ----- Cross-multiplication rule WITH ground (productive) -----
% (a/b) * (c/d) = (a*c)/(b*d) carried out as a multiply-across rule,
% but with a body citation of the area-model justification. The
% productive twin of the cross_multiply_without_ground deformation.
carving_synthesizer:prove(fact(frac_of, fraction(A, B), fraction(C, D),
                               fraction(P, Q)),
                          Config,
                          proof(cross_multiply_with_ground,
                                [recall_rule(numerator_times_numerator,
                                             denominator_times_denominator),
                                 cite_ground(area_model_compose),
                                 multiply(A, C, P),
                                 multiply(B, D, Q)])) :-
    B >= 2, D >= 2,
    A >= 1, C >= 1,
    P =:= A * C, Q =:= B * D,
    get_dict(unit_coords, Config, UC),
    UC >= 3.

% ----- Partition-of-partition equivalence (re-partition raises
% denominator) -----
% 1/D = k/(D*k) by re-partitioning each 1/D-part into k sub-parts.
% Carves equivalences from a simpler fraction in the recollection
% store using the L3 re-partition move (not the L2 cross-multiply
% check).
carving_synthesizer:prove(fact(frac, N, D, fraction(N, D)), Config,
                          proof(partition_of_partition_equivalence,
                                [recollection(frac, M, E, fraction(M, E)),
                                 re_partition_each_part_by(K),
                                 new_denominator(D),
                                 new_numerator(N)])) :-
    N >= 2, D >= 3,
    get_dict(unit_coords, Config, UC),
    UC >= 3,
    carving_synthesizer:known_fact(frac, M, E, fraction(M, E)),
    (M \= N ; E \= D),
    D mod E =:= 0,
    K is D // E,
    K >= 2,
    N =:= M * K.
