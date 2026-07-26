:- use_module(library(http/json)).
:- use_module(hermes(strategy_recognizer), [recognize_strategies/2]).
:- use_module(strategies(action_vocabulary_map), [action_maps/7]).
:- use_module(strategies(attested_phrases),
              [attested_phrase/6, attested_utterance/4]).
:- use_module(strategies(canonical_phrases), [canonical_phrase/2]).


main :-
    json_read_dict(user_input, Request),
    dispatch(Request, Response),
    json_write_dict(user_output, Response, [width(0)]),
    nl.


dispatch(Request, Response) :-
    Mode = Request.mode,
    ( Mode == "sources"
    -> source_rows(Response)
    ; Mode == "score"
    -> score_rows(Request.items, Response)
    ; throw(error(domain_error(recognition_benchmark_mode, Mode), _))
    ).


source_rows(_{literature:Literature, student:Student, authored:Authored}) :-
    findall(
        _{ text:Text,
           family:Family,
           signature:Signature,
           citation:Citation
         },
        ( attested_phrase(
              Family, Signature, _Action, Words, source(Citation), _Attachment),
          atomic_list_concat(Words, ' ', Text)
        ),
        Literature),
    findall(
        _{ text:Text,
           family:Family,
           signature:Signature,
           citation:Citation
         },
        attested_utterance(
            Family, Signature, Text, source(Citation)),
        Student),
    findall(
        _{text:Text, action:Action},
        ( canonical_phrase(Action, Words),
          atomic_list_concat(Words, ' ', Text)
        ),
        Authored).


score_rows(Items, _{results:Results}) :-
    maplist(score_item, Items, Results).


score_item(Item, _{id:Item.id, candidate_count:Count, candidates:Top}) :-
    recognize_strategies(Item.text, Candidates),
    length(Candidates, Count),
    take_first(5, Candidates, TopCandidates),
    maplist(candidate_summary, TopCandidates, Top).


candidate_summary(
    Candidate,
    _{ family:Candidate.operation,
       signature:Candidate.kind,
       recovered_action_order:Recovered,
       matched_span_actions:SpanActions,
       recovered_canonical_actions:Canonical
     }) :-
    Recovered = Candidate.recovered_action_order,
    maplist(span_action, Candidate.matched_spans, SpanActions),
    append(Recovered, SpanActions, ExposedActions),
    findall(
        CanonicalAction,
       ( member(LocalAction, ExposedActions),
          canonical_projection(
              Candidate.operation, Candidate.kind,
              LocalAction, CanonicalAction)
        ),
        Canonical0),
    sort(Canonical0, Canonical).


span_action(Span, Span.action).


canonical_projection(_, _, Action, Action).
canonical_projection(Family, Signature, LocalAction, CanonicalAction) :-
    action_maps(
        Family, Signature, LocalAction, CanonicalAction,
        _Confidence, _Evidence, _Status).


take_first(0, _, []) :-
    !.
take_first(_, [], []) :-
    !.
take_first(N, [Item|Items], [Item|Taken]) :-
    Next is N - 1,
    take_first(Next, Items, Taken).
