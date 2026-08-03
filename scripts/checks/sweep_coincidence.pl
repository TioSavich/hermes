:- encoding(utf8).
/** <module> Coincidence sweep: how often is each broken clock right?
 *
 * For every contracted kind with an independent truth adapter, run the
 * automaton over an input grid and measure the coincidence set — the
 * inputs on which its computed result equals the truth. For kinds
 * classified deformation/incorrect, that set is where diagnosis is
 * UNSAFE: a student may land there while reasoning correctly, and a
 * recognizer that charges the misconception on such an input
 * manufactures a misconception. For kinds classified productive, the
 * complement (inputs where the result misses the truth) is a defect
 * list. Emits coincidence data rows to stdout; the generated data
 * lives in knowledge/strategies/deformation_coincidence.pl.
 *
 * Run crash-isolated, one process per kind (some kinds abort or hang
 * on pathological inputs; see no_return_within/3 in the data file):
 *
 *   swipl -q -l paths.pl -l scripts/checks/audit_purported_validity.pl \
 *         -l scripts/checks/sweep_coincidence.pl \
 *         -g sweep_coincidence:list_kinds -t halt > /tmp/kinds.txt
 *   while read -r op kind; do
 *     timeout 120 swipl -q -l paths.pl \
 *       -l scripts/checks/audit_purported_validity.pl \
 *       -l scripts/checks/sweep_coincidence.pl \
 *       -g "sweep_coincidence:sweep_one($op, $kind)" -t halt
 *   done < /tmp/kinds.txt
 */

:- module(sweep_coincidence, [sweep/0, sweep_one/2, list_kinds/0]).

:- use_module(library(time)).

:- use_module(audit_purported_validity, []).
:- use_module(strategies(math/action_automata_registry), [run_action_automaton/6]).
:- use_module(strategies(automaton_input_contracts), [automaton_input_contract/5]).
:- use_module(strategies(deformation_coincidence), [no_return_within/3]).

grid(addition, A, B) :- between(1, 30, A), between(1, 30, B).
grid(subtraction, A, B) :- between(1, 30, A), between(1, 30, B).
grid(multiplication, A, B) :- between(1, 20, A), between(1, 20, B).
grid(division, A, B) :- between(1, 60, A), between(1, 12, B).
grid(counting, counts(A, B), base(10)) :- between(1, 9, A), between(1, 9, B).
grid(counting, counts(A, B), extents(EA, EB)) :-
    between(1, 6, A), between(1, 6, B), between(1, 9, EA), between(1, 9, EB).
grid(counting, A, base(10)) :- between(1, 30, A).
grid(fraction, fraction_pair(N1, D1, N2, D2), unit(whole)) :-
    between(1, 6, N1), between(2, 8, D1), between(1, 6, N2), between(2, 8, D2).
grid(fraction, fraction_addend_pair(frac(N1, D1), frac(N2, D2)), unit(whole)) :-
    between(1, 6, N1), between(2, 8, D1), between(1, 6, N2), between(2, 8, D2).
grid(fraction, fraction_minuend_subtrahend(frac(N1, D1), frac(N2, D2)), unit(whole)) :-
    between(1, 6, N1), between(2, 8, D1), between(1, 6, N2), between(2, 8, D2).
grid(decimal, decimal_pair(N1, S1, N2, S2), ignored) :-
    member(S1, [10, 100]), member(S2, [10, 100]),
    between(1, 40, N1), between(1, 40, N2).

% The contract example fixes which argument SHAPE a kind takes; sweep
% only grid rows of that shape. Integers are a shape, not a value.
shape_of(A0, B0, A, B) :- compat(A0, A), compat(B0, B).
compat(X0, X) :- integer(X0), !, integer(X).
compat(X0, X) :- functor(X0, F, N), functor(X, F, N).

kind_classification(Op, Kind, A0, B0, Class, Validity) :-
    run_action_automaton(Op, Kind, A0, B0, action_outcome(_, Fields), _),
    memberchk(classification(Class), Fields),
    memberchk(validity(Validity), Fields).

sweep_kind(Op, Kind, A0, B0, row(Op, Kind, Class, Ran, Coincide,
                                 Violations, SampleCo, SampleSep, SampleViol)) :-
    kind_classification(Op, Kind, A0, B0, Class, _),
    findall(A-B-Verdict-PV,
            ( grid(Op, A, B),
              shape_of(A0, B0, A, B),
              catch(run_action_automaton(Op, Kind, A, B,
                                         action_outcome(_, Fs), _),
                    _, fail),
              memberchk(result(Res), Fs),
              audit_purported_validity:normalize_result(Res, Norm),
              Norm \== unknown,
              audit_purported_validity:truth(Op, Kind, A, B, Truth),
              ( audit_purported_validity:results_equal(Norm, Truth)
              -> Verdict = coincide ; Verdict = separate ),
              ( memberchk(validity(V), Fs) -> true ; V = none ),
              purport_violation(V, Verdict, PV)
            ),
            Rows),
    length(Rows, Ran),
    Ran > 0,
    include([_-_-coincide-_]>>true, Rows, Cos),
    length(Cos, Coincide),
    ( Cos = [SA-SB-_-_|_] -> SampleCo = some(SA, SB) ; SampleCo = none ),
    include([_-_-separate-_]>>true, Rows, Seps),
    ( Seps = [PA-PB-_-_|_] -> SampleSep = some(PA, PB) ; SampleSep = none ),
    include([_-_-_-viol(_)]>>true, Rows, Viols),
    length(Viols, Violations),
    ( Viols = [VA-VB-_-viol(VV)|_] -> SampleViol = some(VA, VB, VV) ; SampleViol = none ).

% Per-input purport: what the outcome's own validity field claims about
% THIS input, held against the truth on this input.
purport_violation(correct, separate, viol(claimed_correct_but_wrong)) :- !.
purport_violation(correct_but_inefficient, separate, viol(claimed_correct_but_wrong)) :- !.
purport_violation(accidentally_correct, separate, viol(claimed_accidentally_correct_but_wrong)) :- !.
purport_violation(contextually_correct, separate, viol(claimed_contextually_correct_but_wrong)) :- !.
purport_violation(incorrect, coincide, viol(claimed_incorrect_but_right)) :- !.
purport_violation(_, _, ok).

sweep :-
    % Pathological inputs can blow the stack (grounded recollection
    % arithmetic on unlucky pairs). A bounded stack turns that into a
    % catchable resource error; the input is skipped and counted out.
    set_prolog_flag(stack_limit, 300000000),
    findall(k(Op, Kind, A0, B0),
            ( automaton_input_contract(Op, Kind, _, ExampleAtom, _),
              atom_string(ExampleAtom, S),
              atom_json_dict(S, Dict, []),
              once(audit_purported_validity:example_args(Dict, A0, B0))
            ),
            Kinds0),
    sort(Kinds0, Kinds),
    forall(member(k(Op, Kind, A0, B0), Kinds),
           ( format(user_error, 'sweeping ~w/~w~n', [Op, Kind]),
             garbage_collect,
             (   no_return_within(Op, Kind, Input)
             ->  format('sweep_skip(~q, ~q, grid_input_no_return(~q)).~n',
                        [Op, Kind, Input])
             ;   once(sweep_kind(Op, Kind, A0, B0, Row))
             ->  Row = row(Op2, K2, Cl, Ran, Co, Viol, SCo, SSep, SViol),
                 Rate is Co * 100 // Ran,
                 format('sweep_row(~q, ~q, ~q, ran(~w), coincide(~w), rate_pct(~w), purport_violations(~w), sample_coincide(~q), sample_separate(~q), sample_violation(~q)).~n',
                        [Op2, K2, Cl, Ran, Co, Rate, Viol, SCo, SSep, SViol])
             ;   format('sweep_skip(~q, ~q, no_normalizable_grid_runs).~n', [Op, Kind])
             )
           )).

:- use_module(library(http/json)).


% Crash isolation: some automata abort the process on specific inputs
% (C-stack overflow is uncatchable). sweep_one/2 sweeps a single kind in
% its own process; the driver script records a crash row when the
% process dies, and the last input printed to stderr names the killer.
list_kinds :-
    forall(( automaton_input_contract(Op, Kind, _, ExampleAtom, _),
             atom_string(ExampleAtom, S),
             atom_json_dict(S, Dict, []),
             once(audit_purported_validity:example_args(Dict, _, _))
           ),
           format('~w ~w~n', [Op, Kind])).

sweep_one(Op, Kind) :-
    set_prolog_flag(stack_limit, 300000000),
    automaton_input_contract(Op, Kind, _, ExampleAtom, _),
    atom_string(ExampleAtom, S),
    atom_json_dict(S, Dict, []),
    once(audit_purported_validity:example_args(Dict, A0, B0)),
    (   no_return_within(Op, Kind, Input)
    ->  format('sweep_skip(~q, ~q, grid_input_no_return(~q)).~n',
               [Op, Kind, Input])
    ;   once(sweep_kind_logged(Op, Kind, A0, B0, Row))
    ->  Row = row(Op2, K2, Cl, Ran, Co, Viol, SCo, SSep, SViol),
        Rate is Co * 100 // Ran,
        format('sweep_row(~q, ~q, ~q, ran(~w), coincide(~w), rate_pct(~w), purport_violations(~w), sample_coincide(~q), sample_separate(~q), sample_violation(~q)).~n',
               [Op2, K2, Cl, Ran, Co, Rate, Viol, SCo, SSep, SViol])
    ;   format('sweep_skip(~q, ~q, no_normalizable_grid_runs).~n', [Op, Kind])
    ).

sweep_kind_logged(Op, Kind, A0, B0, Row) :-
    kind_classification(Op, Kind, A0, B0, Class, _),
    findall(A-B-Verdict-PV,
            ( grid(Op, A, B),
              shape_of(A0, B0, A, B),
              format(user_error, 'input ~q ~q~n', [A, B]),
              catch(run_action_automaton(Op, Kind, A, B,
                                         action_outcome(_, Fs), _),
                    _, fail),
              memberchk(result(Res), Fs),
              audit_purported_validity:normalize_result(Res, Norm),
              Norm \== unknown,
              audit_purported_validity:truth(Op, Kind, A, B, Truth),
              ( audit_purported_validity:results_equal(Norm, Truth)
              -> Verdict = coincide ; Verdict = separate ),
              ( memberchk(validity(V), Fs) -> true ; V = none ),
              purport_violation(V, Verdict, PV)
            ),
            Rows),
    length(Rows, Ran),
    Ran > 0,
    include([_-_-coincide-_]>>true, Rows, Cos),
    length(Cos, Coincide),
    ( Cos = [SA-SB-_-_|_] -> SampleCo = some(SA, SB) ; SampleCo = none ),
    include([_-_-separate-_]>>true, Rows, Seps),
    ( Seps = [PA-PB-_-_|_] -> SampleSep = some(PA, PB) ; SampleSep = none ),
    include([_-_-_-viol(_)]>>true, Rows, Viols),
    length(Viols, Violations),
    ( Viols = [VA-VB-_-viol(VV)|_] -> SampleViol = some(VA, VB, VV) ; SampleViol = none ),
    Row = row(Op, Kind, Class, Ran, Coincide, Violations, SampleCo, SampleSep, SampleViol).
