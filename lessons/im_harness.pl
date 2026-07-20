/** <module> Illustrative Math execution harness (codebook refactor, Phase 2)
 *
 * The lesson->strategy and lesson->misconception mappings ALREADY EXIST for K-5
 * (lessons/im/grade_*.pl: explicit_lesson_strategy/4, explicit_lesson_misconception/4,
 * each keyed by an IM lesson id and linked to its teacher-guide markdown). This
 * harness does not build that mapping — it EXECUTES it: for each distinct
 * (operation, kind) a grade prescribes, it drives the existing action automata
 * (action_automata_registry:run_action_automaton/6) on representative operands,
 * reads the self-reported result/expected/validity/classification, and
 * independently red-pens the answer with SWI arithmetic.
 *
 * It reports coverage, honestly: how many prescribed strategies run and are
 * arithmetically correct (the calculator doing IM), and how many named
 * misconceptions reproduce as runnable deformations (the calculator doing IM
 * incorrectly, as children do). Kinds that do not run are first-class gaps.
 *
 * Scope: representative operands cover whole-number add/sub/mult/div (K-5 core).
 * Fraction/decimal kinds are reported as unsupported operation-family gaps, not
 * as failed strategy executions.
 *
 * Run: swipl -q -l paths.pl -s lessons/tests/test_im_harness.pl -g run_tests -t halt
 */
:- module(im_harness,
          [ representative_operands/3,   % +Operation, -N1, -N2
            run_im_strategy/6,           % +Operation, +Kind, +N1, +N2, -Outcome, -Trace
            im_strategy_result/5,        % +Operation, +Kind, -Result, -Expected, -Validity
            im_grade_report/2,           % +Grade, -Dict
            demonstrated_pp_necessary/4, % ?BasePractice, ?ElabPractice, -Status, -Evidence
            im_pp_necessity_report/1     % -Dict
          ]).

:- use_module(math(action_automata_registry)).
:- use_module(pml(mua_relations), []).   % pp_necessary/2, practice_kind/3 (qualified)
:- use_module(library(lists), [ member/2 ]).
:- use_module(library(apply), [ include/3 ]).

%!  representative_operands(?Operation, ?N1, ?N2) is nondet.
%   Grade-appropriate small operands so a strategy automaton has something to run.
representative_operands(addition,       8, 5).
representative_operands(subtraction,   13, 5).
representative_operands(multiplication, 4, 3).
representative_operands(division,      12, 3).

%!  ground_truth(+Operation, +N1, +N2, -Value) is semidet.
%   The red pen: SWI built-in arithmetic, used only to check the automaton's answer.
ground_truth(addition,       A, B, V) :- V is A + B.
ground_truth(subtraction,    A, B, V) :- V is A - B.
ground_truth(multiplication, A, B, V) :- V is A * B.
ground_truth(division,       A, B, V) :- B =\= 0, 0 =:= A mod B, V is A // B.

run_im_strategy(Op, Kind, N1, N2, Outcome, Trace) :-
    catch(action_automata_registry:run_action_automaton(Op, Kind, N1, N2, Outcome, Trace),
          _, fail).

%!  im_strategy_result(+Operation, +Kind, -Result, -Expected, -Validity) is semidet.
im_strategy_result(Op, Kind, Result, Expected, Validity) :-
    representative_operands(Op, N1, N2),
    run_im_strategy(Op, Kind, N1, N2, action_outcome(_, Fields), _),
    field(Fields, result,   Result,   none),
    field(Fields, expected, Expected, none),
    field(Fields, validity, Validity, unknown).

field(Fields, Name, Value, _Default) :- F =.. [Name, V], member(F, Fields), !, Value = V.
field(_Fields, _Name, Default, Default).

% strategy is arithmetically correct: it runs, self-reports correct, result matches
% its own expected, AND matches the independent red pen.
strategy_correct(Op, Kind) :-
    im_strategy_result(Op, Kind, R, E, V),
    V == correct,
    (   number(R), number(E)
    ->  R =:= E,
        % independent red pen when a ground truth exists for this op
        ( representative_operands(Op, N1, N2), ground_truth(Op, N1, N2, TV)
        -> R =:= TV
        ;  true )
    ;   % structured result (e.g. quotient_remainder(Q,R), fraction terms):
        % trust the automaton's self-reported validity + result==expected.
        R == E
    ).

strategy_executes(Op, Kind) :- im_strategy_result(Op, Kind, _, _, _).

% ---- grade lesson enumeration (heads only, via clause/2 — no body deps) -------

grade_file('GK', 'im/grade_k').    grade_file('G1', 'im/grade_1').
grade_file('G2', 'im/grade_2').    grade_file('G3', 'im/grade_3').
grade_file('G4', 'im/grade_4').    grade_file('G5', 'im/grade_5').
grade_file('G6', 'im/grade_6').    grade_file('G7', 'im/grade_7').
grade_file('G8', 'im/grade_8').

% Lesson files are non-module multifile facts; depending on the loading context
% they land in `user` or in the loading module. We load them, then read their
% heads module-agnostically (grade_pairs/3) so it does not matter where they sit.
ensure_grade_loaded(Grade) :-
    ( grade_file(Grade, Rel) -> catch(ensure_loaded(lessons(Rel)), _, true) ; true ).

grade_prefix(Grade, Prefix) :-
    atom_concat('IM-', Grade, P0), atom_concat(P0, '-', Prefix).

% Distinct (Operation, Kind) the grade PRESCRIBES as strategies. Operation is a
% literal in these heads, so the pairs are clean. Searches every module that
% carries the predicate (clause/2 needs a bound module).
grade_strategy_pairs(Grade, Pairs) :-
    grade_prefix(Grade, Prefix),
    findall(Op-Kind,
            ( current_module(M),
              catch(clause(M:explicit_lesson_strategy(Id, Op, Kind, _), _), _, fail),
              atom(Id), sub_atom(Id, 0, _, _, Prefix),
              nonvar(Op), atom(Op), nonvar(Kind), atom(Kind) ),
            Raw),
    sort(Raw, Pairs).

% Distinct misconception KINDS the grade NAMES. In these heads Operation is a
% variable (bound in the body from misconception_registry), so we dedup by kind
% and probe the operation when reproducing.
grade_misconception_kinds(Grade, Kinds) :-
    grade_prefix(Grade, Prefix),
    findall(Kind,
            ( current_module(M),
              catch(clause(M:explicit_lesson_misconception(Id, _, Kind, _), _), _, fail),
              atom(Id), sub_atom(Id, 0, _, _, Prefix), nonvar(Kind), atom(Kind) ),
            Raw),
    sort(Raw, Kinds).

% A misconception reproduces if its deformation runs under some whole-number op.
misconception_reproduces(Kind) :-
    member(Op, [addition, subtraction, multiplication, division]),
    representative_operands(Op, N1, N2),
    run_im_strategy(Op, Kind, N1, N2, _, _), !.

%!  im_grade_report(+Grade, -Dict) is det.
%   Grade is 'G1'..'G8' or 'GK'.
im_grade_report(Grade, Dict) :-
    ensure_grade_loaded(Grade),
    grade_strategy_pairs(Grade, Strats),
    grade_misconception_kinds(Grade, MisconKinds),
    include(supported_strategy_pair, Strats, SupportedStrats),
    subtract_list(Strats, SupportedStrats, UnsupportedOperationGaps),
    include([Op-K]>>strategy_executes(Op,K), SupportedStrats, StratExec),
    include([Op-K]>>strategy_correct(Op,K),  SupportedStrats, StratOK),
    include(misconception_reproduces, MisconKinds, MisconRepro),
    subtract_list(SupportedStrats, StratExec, StratGaps),
    subtract_list(MisconKinds, MisconRepro, MisconGaps),
    length(Strats, NS), length(StratExec, NSE), length(StratOK, NSC),
    length(MisconKinds, NM), length(MisconRepro, NMR),
    length(UnsupportedOperationGaps, UnsupportedOperationGapCount),
    % Grades with no mapped strategies (currently G6-G8) are out of the K-5 Phase 2
    % slice, not a wiring failure. Name that so a zero count reads as scope, not gap.
    (   NS =:= 0
    ->  Reason = out_of_scope_phase2_no_mapped_strategies
    ;   UnsupportedOperationGaps \== []
    ->  Reason = unsupported_strategy_operations
    ;   Reason = none
    ),
    Dict = _{ grade: Grade,
              strategies_total: NS,
              strategies_executable: NSE,
              strategies_correct: NSC,
              strategy_gaps: StratGaps,
              unsupported_operation_gaps: UnsupportedOperationGaps,
              unsupported_operation_gap_count: UnsupportedOperationGapCount,
              gap_reason: Reason,
              misconceptions_total: NM,
              misconceptions_reproduced: NMR,
              misconception_gaps: MisconGaps }.

supported_strategy_pair(Op-_) :-
    representative_operands(Op, _, _).

subtract_list(All, Sub, Diff) :- findall(X, (member(X, All), \+ member(X, Sub)), Diff).


%% ----------------------------------------------------------------------
%% pp-necessity, demonstrated against the curriculum's lesson ordering.
%%
%% The convergence insight: a curriculum's prerequisite progression IS a
%% PP-necessity ordering. So an asserted pp_necessary(A,B) is DEMONSTRATED when
%% Illustrative Math introduces A's kind in a lesson no later than B's kind;
%% CONTRADICTED if A's kind is introduced strictly later (a real finding); and
%% NOT_IN_CURRICULUM when a kind is never prescribed (cannot be demonstrated this
%% way). This reads the asserted edges in formal/pml/mua_relations.pl against the IM
%% lesson order — it does not invent the relations.

% Total order over IM lesson ids 'IM-G{K|n}-U{n}-L{n}'.
im_lesson_order(LessonId, Order) :-
    atom(LessonId),
    atomic_list_concat(['IM', G, U, L], '-', LessonId),
    grade_num(G, GN), tail_num(U, UN), tail_num(L, LN),
    Order is GN*1000000 + UN*1000 + LN.

grade_num('GK', 0) :- !.
grade_num(G, N) :- atom_chars(G, ['G'|Cs]), catch(number_chars(N, Cs), _, fail).
tail_num(Tok, N) :- atom_chars(Tok, [_|Cs]), catch(number_chars(N, Cs), _, fail).

% A lesson (any grade, any module the facts loaded into) prescribes a kind.
lesson_prescribes_kind(LessonId, Kind) :-
    current_module(M),
    catch(clause(M:explicit_lesson_strategy(LessonId, _, Kind, _), _), _, fail),
    atom(LessonId), atom(Kind).

% Earliest (lowest-order) lesson that prescribes a kind.
earliest_lesson_for_kind(Kind, Order, LessonId) :-
    findall(O-Id, ( lesson_prescribes_kind(Id, Kind), im_lesson_order(Id, O) ), Pairs),
    Pairs \== [],
    sort(Pairs, [Order-LessonId|_]).

%!  demonstrated_pp_necessary(?A, ?B, -Status, -Evidence) is nondet.
%   Status in {demonstrated, contradicted, not_in_curriculum}.
demonstrated_pp_necessary(A, B, Status, Evidence) :-
    mua_relations:pp_necessary(A, B),
    ( mua_relations:practice_kind(A, _, KA), mua_relations:practice_kind(B, _, KB) -> true
    ; KA = none, KB = none ),
    (   KA \== none, KB \== none,
        earliest_lesson_for_kind(KA, OA, LA),
        earliest_lesson_for_kind(KB, OB, LB)
    ->  ( OA =< OB -> Status = demonstrated ; Status = contradicted ),
        Evidence = _{ base_kind: KA, base_lesson: LA,
                      elaborated_kind: KB, elaborated_lesson: LB }
    ;   Status = not_in_curriculum,
        Evidence = _{ base_kind: KA, elaborated_kind: KB }
    ).

ensure_all_im_grades_loaded :-
    forall( member(G, ['GK','G1','G2','G3','G4','G5']), ensure_grade_loaded(G) ).

%!  im_pp_necessity_report(-Dict) is det.
im_pp_necessity_report(_{ total: NT,
                         demonstrated: ND,
                         contradicted: NC,
                         not_in_curriculum: NN,
                         edges: EdgeDicts }) :-
    ensure_all_im_grades_loaded,
    findall(S-_{base: A, elaborated: B, status: S, evidence: E},
            demonstrated_pp_necessary(A, B, S, E),
            Pairs),
    findall(S, member(S-_, Pairs), Statuses),
    findall(D, member(_-D, Pairs), EdgeDicts),
    length(Pairs, NT),
    occurrences(demonstrated, Statuses, ND),
    occurrences(contradicted, Statuses, NC),
    occurrences(not_in_curriculum, Statuses, NN).

occurrences(X, L, N) :- include(==(X), L, Xs), length(Xs, N).
