/** <module> Queries over the machine index and its exclusions
 *
 * `corpus_window.pl` and `relevance_negation.pl` are generated fact files with
 * no module of their own, in the manner of the other generated knowledge in this
 * tree.  This module loads them and names the questions callers ask, so that the
 * index is reachable from the running application rather than only from its
 * checks.
 *
 * The negation direction is the one worth naming.  `machines_for_topic/3` does
 * not rank machines by relevance; it removes the machines an exclusion rule
 * accounts for and hands back both what survived and why the rest did not.  A
 * caller can therefore report the subtraction it performed, which is the whole
 * reason the exclusions were generated as data carrying their evidence.
 */
:- module(index_query,
          [ window_of/2,               % ?Machine, -Row
            window_legend/2,           % ?Action, -Legend
            machine_arc/2,             % ?Machine, ?Arc
            machines_for_topic/3,      % +Topic, -Machines, -Excluded
            topic_subtraction/2,       % +Topic, -Counts
            topic_subtraction_dict/2,  % +Topic, -Dict
            index_topic/1              % ?Topic
          ]).

:- use_module(library(apply), [include/3, maplist/3]).
:- use_module(library(lists), [member/2, append/3]).

:- ensure_loaded(index('corpus_window')).
:- ensure_loaded(index('relevance_negation')).

%!  window_of(?Machine, -Row) is nondet.
%
%   Machine is `Family/Signature`.  Row is `window(Arc, Shell, Core, Closure,
%   Other)` — the index row, with the fourth list retained.  Callers that want
%   only the three named groups can ignore Other, but it is never dropped here
%   because the machines that have one are the machines that call another machine.
window_of(Family/Signature, window(Arc, Shell, Core, Closure, Other)) :-
    window_row(Family, Signature, Arc, Shell, Core, Closure, Other).

%!  window_legend(?Action, -Legend) is nondet.
%
%   Legend is `legend(Genre, Register, Stance)` for one canonical action.
window_legend(Action, legend(Genre, Register, Stance)) :-
    window_legend_action(Action, Genre, Register, Stance).

%!  machine_arc(?Machine, ?Arc) is nondet.
machine_arc(Family/Signature, Arc) :-
    window_row(Family, Signature, Arc, _, _, _, _).

%!  index_topic(?Topic) is nondet.
%
%   The topics the exclusion rules can key on.  A query outside this set
%   subtracts nothing, which `machines_for_topic/3` reports rather than hides.
index_topic(Topic) :-
    known_topic(Topic).

%!  machines_for_topic(+Topic, -Machines, -Excluded) is det.
%
%   Machines survived topic subtraction.  Excluded is a list of
%   `excluded(Machine, Reason)` where Reason is the ground evidence term the
%   generated file recorded, so the caller can say why a machine is absent.
%
%   Both lists are returned because a subtraction that cannot show its work is
%   indistinguishable from a guess.
machines_for_topic(Topic, Machines, Excluded) :-
    surviving_slices(Topic, Survivors, Dropped),
    findall(Family/Signature,
            member(slice(family, machine(Family, Signature)), Survivors),
            Machines0),
    sort(Machines0, Machines),
    findall(excluded(Family/Signature, Reason),
            member(excluded(family, machine(Family, Signature), Reason), Dropped),
            Excluded0),
    sort(Excluded0, Excluded).

%!  topic_subtraction(+Topic, -Counts) is det.
%
%   Counts is `subtraction(Surviving, Excluded, Total)` over machines.  Reported
%   as counts because the value of the index is how much it removes, and that is
%   a number rather than a claim.
topic_subtraction(Topic, subtraction(Surviving, Gone, Total)) :-
    machines_for_topic(Topic, Machines, Excluded),
    length(Machines, Surviving),
    length(Excluded, Gone),
    Total is Surviving + Gone.

%!  topic_subtraction_dict(+Topic, -Dict) is semidet.
%
%   The dispatch surface.  Fails for a topic no exclusion rule keys on, so a
%   caller learns that its query subtracted nothing instead of receiving an
%   untouched corpus that reads as a result.
%
%   `excluded_sample` carries a few reasons rather than all of them: the full
%   list runs to the hundreds and the point of returning any is that a caller can
%   show the kind of evidence behind the subtraction.
topic_subtraction_dict(Topic, Dict) :-
    atom(Topic),
    index_topic(Topic),
    machines_for_topic(Topic, Machines, Excluded),
    length(Machines, Surviving),
    length(Excluded, Gone),
    Total is Surviving + Gone,
    maplist(machine_atom, Machines, Names),
    length(Sample, 5),
    (   append(Sample, _, Excluded)
    ->  true
    ;   Sample = Excluded
    ),
    maplist(exclusion_pair, Sample, Reasons),
    Dict = index_subtraction{
        topic: Topic,
        surviving: Surviving,
        excluded: Gone,
        total: Total,
        machines: Names,
        excluded_sample: Reasons
    }.

machine_atom(Family/Signature, Name) :-
    format(atom(Name), '~w/~w', [Family, Signature]).

exclusion_pair(excluded(Machine, Reason), pair{machine: Name, reason: Text}) :-
    machine_atom(Machine, Name),
    format(atom(Text), '~w', [Reason]).
