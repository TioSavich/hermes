% cov_worker.pl — run the Hermes worker loop under clause coverage.
%
% Load order matters: hermes_worker.pl first (defines load_runtime/0 and
% worker_loop/0), then this file, then -g cov_main. The sweep driver spawns:
%
%   swipl -q -l hermes_worker.pl -l scripts/bigred/total_audit/cov_worker.pl \
%         -g cov_main
%
% with HERMES_COV_SEGMENT naming the coverage data file for this worker
% instance. Coverage wraps worker_loop/0 only — load_runtime/0 runs outside
% the instrument so consult-time execution does not pollute the counts.
%
% The at_halt hook saves on SIGTERM as well as on clean EOF, so a watchdog
% kill (TERM, then KILL after a grace period) usually preserves the segment.
% A segment file that is missing after a kill means the grace period was too
% short for that item; the driver requeues that segment's completed items.

:- use_module(library(prolog_coverage)).

:- dynamic cov_saved/0.

cov_segment(File) :-
    ( getenv('HERMES_COV_SEGMENT', F0), F0 \== '' -> File = F0
    ; File = 'cov_segment.dat'
    ).

cov_flush :-
    ( cov_saved -> true
    ; cov_segment(File),
      catch(( cov_save_data(File, []), asserta(cov_saved) ), E,
            print_message(error, E))
    ).

cov_main :-
    catch(with_output_to(user_error, load_runtime), E,
          ( print_message(error, E), halt(4) )),
    at_halt(cov_flush),
    catch(coverage(worker_loop), E2,
          ( print_message(error, E2) )),
    cov_flush,
    halt(0).
