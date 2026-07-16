/** <module> Opt-in Zeeman and interactional-trace PML candidates

    This module exposes two independent routes into the same inner PML
    vocabulary:

      * tape_pml_candidate/2 reads an already-classified Zeeman tape term;
      * trace_pml_candidate/2 reads an already-coded interactional trace event.

    Both routes return candidate inner operators. Neither route assigns a
    subjective, objective, or normative mode. contextualize_candidate/4 adds a
    mode only when a caller supplies it explicitly.

    The bridge does not parse transcripts, infer trace codes, or claim that a
    machine trajectory and a classroom episode are isomorphic. It is opt-in and
    is not loaded by zeeman_tape.pl, Hermes, or the canonical system loader.

    Interactional events have this shape:

      trace_event(Id, span(From, To), Codes,
                  trace_meta(Actor, Certifier, Condition))

    Certifier is none, authority(Actor), or convergence(Actors). Condition is
    none or required_if(Condition). A settlement requires a certifier, and a
    conditional_reopening requires a named condition.
*/
:- module(zeeman_pml_bridge, [
    tape_pml_candidate/2,       % tape_pml_candidate(+TapeTerm, -Candidate)
    trace_pml_candidate/2,      % trace_pml_candidate(+TraceEvent, -Candidate)
    contextualize_candidate/4  % contextualize_candidate(+Mode, +Content, +Candidate, -Reading)
]).

:- use_module(pml(pml_operators)).
:- use_module(pml(interactional_trace), []).

%! tape_pml_candidate(+TapeTerm, -Candidate) is semidet.
%
%  Candidate is pml_candidate(Source, Operator, Polarity, Warrant). The
%  mapping follows the proposal table in More_Machine_Description.md. A settle
%  event has no candidate because the table does not assign it one.
tape_pml_candidate(
    event(Step, snap(Letter, TensionBefore, ThetaFrom, ThetaTo)),
    pml_candidate(tape_event(Step, Letter), comp_nec, compressive,
                  catastrophic_basin_loss(TensionBefore,
                                          ThetaFrom, ThetaTo))) :-
    nonnegative_number(TensionBefore).
tape_pml_candidate(
    interval(From, To, no_snap(held_rigid, Rise, Fall)),
    pml_candidate(tape_interval(From, To), comp_poss, compressive,
                  held_tension(Rise, Fall, toward(comp_nec)))) :-
    !,
    valid_interval_numbers(Rise, Fall).
tape_pml_candidate(
    interval(From, To, no_snap(released_pre_threshold, Rise, Fall)),
    pml_candidate(tape_interval(From, To), exp_nec, expansive,
                  disciplined_release(Rise, Fall))) :-
    !,
    valid_interval_numbers(Rise, Fall).
tape_pml_candidate(
    interval(From, To, no_snap(wandering_slack, Rise, Fall)),
    pml_candidate(tape_interval(From, To), exp_poss, expansive,
                  slack_without_demand(Rise, Fall))) :-
    valid_interval_numbers(Rise, Fall).

%! trace_pml_candidate(+TraceEvent, -Candidate) is nondet.
%
%  Return one candidate for each operator-bearing code on a valid event.
%  uptake and non_uptake remain evidence about interaction and do not receive
%  an operator automatically. Multiple codes can therefore yield multiple
%  candidates without collapsing their distinct roles.
trace_pml_candidate(Event, Candidate) :-
    interactional_trace:valid_trace_event(Event),
    Event = trace_event(Id, Span, Codes, Meta),
    member(Code, Codes),
    trace_code_candidate(Code, Id, Span, Meta, Candidate).

trace_code_candidate(
    opening, Id, Span, trace_meta(Actor, _Certifier, _Condition),
    pml_candidate(interactional_trace(Id, Span, Actor), exp_poss, expansive,
                  candidate_opening)).
trace_code_candidate(
    closure_bid, Id, Span, trace_meta(Actor, _Certifier, _Condition),
    pml_candidate(interactional_trace(Id, Span, Actor), comp_poss, compressive,
                  proposed_narrowing)).
trace_code_candidate(
    reopening, Id, Span, trace_meta(Actor, _Certifier, _Condition),
    pml_candidate(interactional_trace(Id, Span, Actor), exp_poss, expansive,
                  restored_alternative)).
trace_code_candidate(
    settlement, Id, Span, trace_meta(Actor, Certifier, _Condition),
    pml_candidate(interactional_trace(Id, Span, Actor), comp_nec, compressive,
                  certified_settlement(Certifier))).
trace_code_candidate(
    conditional_reopening, Id, Span,
    trace_meta(Actor, _Certifier, required_if(Condition)),
    pml_candidate(interactional_trace(Id, Span, Actor), exp_nec, expansive,
                  required_return(Condition))).

%! contextualize_candidate(+Mode, +Content, +Candidate, -Reading) is semidet.
%
%  Wrap a candidate only after a caller supplies a validity mode. Reading keeps
%  the candidate source and warrant visible for audit.
contextualize_candidate(Mode, Content,
                        pml_candidate(Source, Operator, Polarity, Warrant),
                        pml_reading(Source, Wrapped, Polarity, Warrant)) :-
    nonvar(Mode),
    ground(Content),
    acyclic_term(Content),
    ground(Source),
    ground(Warrant),
    operator_polarity(Operator, Polarity),
    operator_term(Operator, Content, Inner),
    mode_term(Mode, Inner, Wrapped),
    valid_mode_term(Mode, Inner).

operator_term(comp_nec, Content, comp_nec(Content)).
operator_term(comp_poss, Content, comp_poss(Content)).
operator_term(exp_nec, Content, exp_nec(Content)).
operator_term(exp_poss, Content, exp_poss(Content)).

operator_polarity(comp_nec, compressive).
operator_polarity(comp_poss, compressive).
operator_polarity(exp_nec, expansive).
operator_polarity(exp_poss, expansive).

mode_term(subjective, Inner, s(Inner)).
mode_term(objective, Inner, o(Inner)).
mode_term(normative, Inner, n(Inner)).

valid_mode_term(subjective, Inner) :- pml_operators:s(Inner).
valid_mode_term(objective, Inner) :- pml_operators:o(Inner).
valid_mode_term(normative, Inner) :- pml_operators:n(Inner).

valid_interval_numbers(Rise, Fall) :-
    nonnegative_number(Rise),
    nonnegative_number(Fall).

nonnegative_number(Number) :-
    number(Number),
    Number >= 0.
