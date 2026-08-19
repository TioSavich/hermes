% check_pipe_tables.pl — 2026-08-18 vision wave.
%
% Reads a JSON array of {"record_id": "...", "text": "..."} objects from
% stdin (one flattened pipe-table text per statement whose recovered vision
% content included a table) and reports, per record, whether
% serialized_table_reader_pilot.pl's serialized_table_reading/3 parses it --
% the real reader, not a guess about its grammar. Never loads
% hermes_worker.pl; the reader module is self-contained.
%
% Usage: swipl scripts/coverage/check_pipe_tables.pl < tables.json
% stdout: one JSON object per input row: {"record_id": "...", "readable": true|false,
%          "tables": N, "reason": "..."}

:- use_module(library(http/json)).
:- use_module(knowledge/strategies/abstraction/serialized_table_reader_pilot).

:- initialization(main, main).

main(_Argv) :-
    read_stdin_json(Rows),
    forall(member(Row, Rows), check_row(Row)).

read_stdin_json(Rows) :-
    set_stream(user_input, encoding(utf8)),
    json_read_dict(user_input, Rows, [value_string_as(string)]).

check_row(Row) :-
    RecordId = Row.get(record_id),
    Text0 = Row.get(text),
    ( string(Text0) -> Text = Text0 ; atom_string(Text0, Text) ),
    ( catch(serialized_table_reading(Text, Tables, _Remnants), _, fail)
    -> length(Tables, N),
       ( N > 0
       -> Readable = true, Reason = "ok"
       ;  Readable = false, Reason = "zero_tables"
       )
    ;  N = 0, Readable = false, Reason = "reading_failed"
    ),
    Out = _{record_id: RecordId, readable: Readable, tables: N, reason: Reason},
    json_write_dict(user_output, Out, [width(0)]),
    nl(user_output).
