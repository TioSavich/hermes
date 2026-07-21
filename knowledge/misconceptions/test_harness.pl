% Misconception Test Harness
% Run: swipl -l paths.pl -l knowledge/misconceptions/test_harness.pl -g run_all -t halt
%
% Loads all misconception modules, runs every registered check,
% prints a summary, and writes results.csv.
%
% Multifile plumbing pattern (read before adding new facts in Task 3+):
%   * The harness module `test_harness` owns two dynamic/multifile
%     registration predicates:
%       - arith_misconception/6  (for fraction, decimal, whole_number, measurement)
%       - entail_misconception/5 (for geometry)
%   * Each misconceptions_*.pl file declares the relevant predicate as
%     multifile against the `test_harness` module, e.g.
%         :- multifile test_harness:arith_misconception/6.
%     and then writes facts with the `test_harness:` module qualifier.
%   * The harness collects every such fact via `findall(test_harness:...)`.
%
% axioms_geometry.pl is NOT a module — it is :- include(...)-ed by
% formal/sequent/sequent_engine.pl. `entails_via_incompatibility/2`
% therefore lives inside the sequent_engine module and we call
% it via module qualification below, following the pattern in
% formal/formalization/tests/test_geometry_entailment.pl.

:- module(test_harness,
          [ run_all/0
          , classify_arith/5
          , classify_arith_by_trace/5
          , classify_entail/4
          , arith_misconception/6
          , arith_trace_profile/4
          , entail_misconception/5
          , diagnose_error/4
          , query_misconception/4
          ]).

% Load the formal reasoning stack into user module. `formal/load.pl` is a
% plain script (no :- module header) that uses ensure_loaded('../paths')
% and several use_module directives. If we let it run inside the
% test_harness module it tries to re-load paths.pl (non-module file
% already in user) and double-imports utilities. Loading via user:
% keeps every inner directive in user context, matching the pattern
% in formal/formalization/tests/test_geometry_entailment.pl.
:- user:ensure_loaded('formal/load.pl').

:- use_module(library(lists)).
:- use_module(library(error)).  % yall lambdas call must_be/2 from here

% Registration predicates — populated from misconceptions_*.pl files.
:- multifile arith_misconception/6.
:- discontiguous arith_misconception/6.
:- dynamic arith_misconception/6.

:- multifile arith_trace_profile/4.
:- discontiguous arith_trace_profile/4.
:- dynamic arith_trace_profile/4.

:- multifile entail_misconception/5.
:- discontiguous entail_misconception/5.
:- dynamic entail_misconception/5.

% Local convenience alias for the module-qualified call.
entails(Shape, Target) :-
    sequent_engine:entails_via_incompatibility(Shape, Target).

% Load all misconception modules. Each declares its registration
% predicate as multifile against `test_harness`, so its facts show up
% when we query arith_misconception/6 or entail_misconception/5 here.
:- use_module(misconceptions(misconceptions_fraction)).
:- use_module(misconceptions(misconceptions_whole_number)).
:- use_module(misconceptions(misconceptions_decimal)).
:- use_module(misconceptions(misconceptions_measurement)).
:- use_module(misconceptions(misconceptions_geometry)).
:- use_module(misconceptions(misconceptions_extended_arithmetic)).

%! classify_arith(+RuleName, +Input, +Expected, -Class, -Got) is det.
%
%  Runs `call(RuleName, Input, Got)` under a finite inference limit.
%  RuleName may be either a bare atom (legacy) or a module-qualified term
%  `Module:LocalName`. The module-qualified form is preferred because it
%  lets rule predicates stay unexported — the harness reaches into the
%  home module directly instead of every file maintaining an export list.
%
%  Classifies the outcome as:
%    well_formed    — the rule returned the correct answer (Got =@= Expected).
%                     For a misconception fact, this is a flag: either the
%                     misconception has been silently repaired or the row
%                     is a duplicate of the correct rule (dedup).
%    wrong_answer   — the rule terminated with a value different from Expected.
%                     This is the typical "misconception confirmed" outcome.
%    loop_detected  — the rule exceeded the inference limit.
%    undefined      — the rule predicate does not exist.

% Special case: RuleName = skip (bare atom) is the convention for
% "too_vague" registrations. Short-circuit — don't call anything.
% SWI-Prolog has a builtin skip/2 (stream I/O) that would otherwise be
% dispatched and raise instantiation_error on the uninstantiated Got.
classify_arith(skip, _Input, _Expected, undefined, no_output) :- !.
classify_arith(_:skip, _Input, _Expected, undefined, no_output) :- !.

classify_arith(RuleName, Input, Expected, Class, Got) :-
    rule_goal(RuleName, Input, Got, FullGoal, ErrorPI),
    (   catch(call_with_inference_limit(FullGoal, 10_000, Status),
              Error,
              handle_classify_error(Error, ErrorPI, Status))
    ->  (   Status == inference_limit_exceeded
        ->  Class = loop_detected
        ;   Status == undefined_proc
        ->  Class = undefined, Got = no_output
        ;   (Got =@= Expected -> Class = well_formed ; Class = wrong_answer)
        )
    ;   Class = undefined, Got = no_output
    ).

%! classify_arith_by_trace(+RuleName, +Input, +Expected, -Class, -Evidence) is det.
%
%  Trace-aware variant of classify_arith/5. It first runs the normal output
%  check. Non-matching outputs keep their existing class and Got value. When a
%  row produces the expected output, an optional arith_trace_profile/4 fact can
%  distinguish a trace-correct row from an output-correct row whose computation
%  followed a different documented path.
%
%  arith_trace_profile(RuleName, Input, StudentTrace, CorrectTrace).
%
%  If no trace profile exists, the row is not called well_formed; it is marked
%  trace_unavailable so the CSV is explicit about the remaining diagnostic gap.
classify_arith_by_trace(RuleName, Input, Expected, Class, Evidence) :-
    classify_arith(RuleName, Input, Expected, OutputClass, Got),
    (   OutputClass \== well_formed
    ->  Class = OutputClass,
        Evidence = Got
    ;   arith_trace_profile(RuleName, Input, StudentTrace, CorrectTrace)
    ->  Evidence = trace{
            got: Got,
            student_trace: StudentTrace,
            correct_trace: CorrectTrace
        },
        (   StudentTrace =@= CorrectTrace
        ->  Class = well_formed
        ;   Class = trace_divergence
        )
    ;   Class = trace_unavailable,
        Evidence = trace{got: Got, reason: no_trace_profile}
    ).

rule_goal(RuleName, Input, Got, FullGoal, ErrorPI) :-
    (   RuleName = Module:LocalName
    ->  Goal =.. [LocalName, Input, Got],
        FullGoal = Module:Goal,
        ErrorPI = Module:LocalName/2
    ;   Goal =.. [RuleName, Input, Got],
        FullGoal = Goal,
        ErrorPI = RuleName/2
    ).

% Narrow existence_error handling: only convert to `undefined_proc` when the
% missing predicate is exactly the registered rule (bare atom or
% module-qualified). Anything else re-throws so unrelated bugs crash loudly.
%
% ErrorPI is the expected PI derived from RuleName (Name/2 for bare atoms,
% Module:Name/2 for qualified ones). We match against both the qualified
% and bare forms SWI may raise, since call/1 into a named module can
% surface the existence_error in either shape depending on how the goal
% was constructed.
handle_classify_error(error(existence_error(procedure, PI), _), ErrorPI, undefined_proc) :-
    (   % Qualified registration: ErrorPI = Module:Name/2
        ErrorPI = Module:Name/2,
        ( PI = Module:Name/2
        ; PI = Name/2
        )
    ;   % Bare registration: ErrorPI = Name/2
        ErrorPI = Name/2,
        atom(Name),
        ( PI = Name/2
        ; PI = _:Name/2
        )
    ),
    !.
handle_classify_error(Error, _ErrorPI, _Status) :-
    throw(Error).

%! classify_entail(+Shape, +Target, +Claim, -Class) is det.
%
%  Claim is `holds` or `fails` — what the student asserts about
%  entailment from Shape to Target. We compare against the axiom.
%
% Special case: too_vague registrations use Shape=none or Target=none.
% Short-circuit to undefined (matches the arith `skip` convention).
% Must come before the holds/fails clauses because the identity clause
% in entails_via_incompatibility (P == Q -> true) would otherwise classify
% (none, none, holds) as well_formed.
classify_entail(none, _, _, undefined) :- !.
classify_entail(_, none, _, undefined) :- !.

classify_entail(Shape, Target, holds, Class) :-
    ( entails(Shape, Target)
    -> Class = well_formed       % student says it holds, axiom agrees — dedup flag
    ;  Class = wrong_answer      % student says holds, axiom disagrees
    ).
classify_entail(Shape, Target, fails, Class) :-
    ( \+ entails(Shape, Target)
    -> Class = well_formed       % student says it fails, axiom agrees — dedup flag
    ;  Class = wrong_answer      % student says fails, axiom says it holds
    ).

%! run_all is det.
run_all :-
    writeln('=== Misconception Test Harness ==='),
    run_arith_checks(ArithResults),
    run_entail_checks(EntailResults),
    append(ArithResults, EntailResults, All),
    length(All, Total),
    include([r(_,_,_,wrong_answer,_)]>>true,  All, WA),
    include([r(_,_,_,loop_detected,_)]>>true, All, LD),
    include([r(_,_,_,undefined,_)]>>true,     All, Undef),
    include([r(_,_,_,well_formed,_)]>>true,   All, WF),
    include([r(_,_,_,trace_divergence,_)]>>true, All, TD),
    include([r(_,_,_,trace_unavailable,_)]>>true, All, TU),
    length(WA, NWA), length(LD, NLD), length(Undef, NUndef), length(WF, NWF),
    length(TD, NTD), length(TU, NTU),
    format('~nResults: ~w total~n', [Total]),
    format('  wrong_answer:  ~w~n', [NWA]),
    format('  loop_detected: ~w~n', [NLD]),
    format('  undefined:     ~w~n', [NUndef]),
    format('  well_formed:   ~w~n', [NWF]),
    format('  trace_divergence:  ~w~n', [NTD]),
    format('  trace_unavailable: ~w~n', [NTU]),
    write_csv(All),
    writeln('Results written to knowledge/misconceptions/results.csv').

run_arith_checks(Results) :-
    findall(
        r(Source, Domain, Desc, Class, Got),
        (   arith_misconception(Source, Domain, Desc, Rule, Input, Expected),
            classify_arith_by_trace(Rule, Input, Expected, Class, Got)
        ),
        Results
    ).

run_entail_checks(Results) :-
    findall(
        r(Source, geometric, Desc, Class, entailment),
        (   entail_misconception(Source, Desc, Shape, Target, Claim),
            classify_entail(Shape, Target, Claim, Class)
        ),
        Results
    ).

% Write results as RFC 4180-ish CSV: every field double-quoted, embedded
% double-quotes doubled. Required because `got` and `source` may carry
% compound terms (e.g. frac(2,3), lists) whose ~w form contains commas
% that would otherwise split across columns.
write_csv(Rows) :-
    open('knowledge/misconceptions/results.csv', write, S),
    format(S, 'source,domain,description,classification,got~n', []),
    forall(member(r(Src, Dom, Desc, Class, Got), Rows),
           ( csv_field(S, Src),   write(S, ','),
             csv_field(S, Dom),   write(S, ','),
             csv_field(S, Desc),  write(S, ','),
             csv_field(S, Class), write(S, ','),
             csv_field(S, Got),   nl(S)
           )),
    close(S).

% Write one CSV field: always double-quoted; any embedded " is escaped as "".
csv_field(Stream, Value) :-
    format(atom(Raw), '~w', [Value]),
    atom_codes(Raw, RawCodes),
    escape_quotes(RawCodes, EscapedCodes),
    format(Stream, '"~s"', [EscapedCodes]).

escape_quotes([], []).
escape_quotes([0'"|T], [0'",0'"|T2]) :- !, escape_quotes(T, T2).
escape_quotes([C|T], [C|T2]) :- escape_quotes(T, T2).

%! diagnose_error(+Domain, +Input, +Got, -Match) is nondet.
%
%  Diagnoses a student's erroneous answer (Got) for a given Input.
%  Matches against both arithmetic and geometric (entailment) misconceptions.
%
%  For geometric: Domain is `geometric`. Input is Shape-Target or [Shape, Target].
%  Got is holds/fails.
%  For arithmetic: Domain is fraction, decimal, whole_number, etc. Input is the
%  argument passed to the rule. Got is the student's output.
diagnose_error(Domain, Input, Got, Match) :-
    (   Domain == geometric
    ->  ( Input = Shape-Target ; Input = [Shape, Target] ),
        entail_misconception(Source, Desc, Shape, Target, Got),
        Match = _{
            type: entailment,
            source: Source,
            domain: geometric,
            description: Desc,
            shape: Shape,
            target: Target,
            claim: Got
        }
    ;   arith_misconception(Source, Domain, Desc, Rule, Input, Expected),
        classify_arith(Rule, Input, Expected, Class, GotResult),
        GotResult =@= Got,
        Match = _{
            type: arithmetic,
            source: Source,
            domain: Domain,
            description: Desc,
            rule: Rule,
            input: Input,
            expected: Expected,
            got: Got,
            classification: Class
        }
    ).

%! query_misconception(?Domain, ?Description, ?Source, -Match) is nondet.
%
%  Queries the registered misconceptions by Domain, Description, or Source.
%  Unifies fields and returns a unified Match dict.
query_misconception(Domain, Description, Source, Match) :-
    (   arith_misconception(Source, Domain, Description, Rule, Input, Expected),
        Match = _{
            type: arithmetic,
            source: Source,
            domain: Domain,
            description: Description,
            rule: Rule,
            input: Input,
            expected: Expected
        }
    ;   Domain = geometric,
        entail_misconception(Source, Description, Shape, Target, Claim),
        Match = _{
            type: entailment,
            source: Source,
            domain: geometric,
            description: Description,
            shape: Shape,
            target: Target,
            claim: Claim
        }
    ).
