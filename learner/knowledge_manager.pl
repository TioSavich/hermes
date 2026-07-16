/** <module> Knowledge Management Utilities
 *
 * Utilities for managing learned knowledge:
 * - Reset (clear all learned strategies)
 * - Backup (save current state)
 * - Restore (load previous state)
 * - Inspect (view current strategies)
 *
 * The system DOES retain learned knowledge across sessions by default,
 * stored in learned_knowledge.pl. These utilities give you control.
 */

:- module(knowledge_manager, [
    reset_learned_knowledge/0,
    backup_learned_knowledge/1,
    restore_learned_knowledge/1,
    inspect_learned_knowledge/0,
    count_learned_strategies/1
]).

:- use_module(more_machine_learner).
:- use_module(strategy_synthesis, []).
:- use_module(reflective_monitor, []).
:- use_module(library(filesex)).

%!      reset_learned_knowledge is det.
%
%       CLEARS all learned strategies and deletes learned_knowledge.pl.
%       This resets the system to primordial state.
%
%       Use this when you want to test the full learning trajectory from scratch.
reset_learned_knowledge :-
    writeln('╔════════════════════════════════════════════════════════════╗'),
    writeln('║  Resetting Learned Knowledge                               ║'),
    writeln('╚════════════════════════════════════════════════════════════╝'),
    writeln(''),
    
    % Count current strategies
    all_learned_strategy_names(Strategies),
    length(Strategies, Count),
    format('Current learned strategies: ~w~n', [Count]),
    (   Count > 0
    ->  format('  ~w~n', [Strategies])
    ;   true
    ),
    
    writeln(''),
    writeln('Clearing dynamic predicates...'),
    
    % Retract all learned strategy clauses without destroying the predicate properties
    retractall(more_machine_learner:run_learned_strategy(_,_,_,_,_)),
    strategy_synthesis:reset_synthesized_strategies,
    reflective_monitor:reset_success_reflection,
    
    % Restore object_level:add to its purely primordial state
    % We use make/consult here to avoid namespace qualifier injection bugs
    % resulting from using assertz across module boundaries.
    retractall(object_level:add(_,_,_)),
    % Resolve through the `learner` search-path alias so the reset works from
    % any working directory, not only when CWD is learner/.
    consult(learner('object_level')),
    
    writeln('Deleting learned_knowledge.pl...'),
    
    % Delete the knowledge file
    (   exists_file('learned_knowledge.pl')
    ->  delete_file('learned_knowledge.pl'),
        writeln('✓ learned_knowledge.pl deleted')
    ;   writeln('• learned_knowledge.pl not found (already clean)')
    ),
    
    writeln(''),
    writeln('✓ System reset to primordial state'),
    writeln('  Only Counting All strategy remains'),
    writeln('').

%!      backup_learned_knowledge(+BackupName) is det.
%
%       Saves current learned knowledge to a backup file.
%       Useful before experiments or testing.
%
%       @param BackupName Atom or string for backup filename (without extension)
backup_learned_knowledge(BackupName) :-
    atomic_list_concat(['learned_knowledge_', BackupName, '.pl'], BackupFile),
    
    writeln('╔════════════════════════════════════════════════════════════╗'),
    writeln('║  Backing Up Learned Knowledge                              ║'),
    writeln('╚════════════════════════════════════════════════════════════╝'),
    writeln(''),
    
    (   exists_file('learned_knowledge.pl')
    ->  copy_file('learned_knowledge.pl', BackupFile),
        format('✓ Backed up to: ~w~n', [BackupFile]),
        
        % Count strategies in backup
        findall(Name, clause(more_machine_learner:run_learned_strategy(_,_,_,Name,_), _), Strategies),
        length(Strategies, Count),
        format('  Strategies backed up: ~w~n', [Count])
    ;   writeln('⚠️  No learned_knowledge.pl to backup'),
        writeln('  System is in primordial state')
    ),
    writeln('').

%!      restore_learned_knowledge(+BackupName) is det.
%
%       Restores learned knowledge from a backup file.
%
%       @param BackupName Atom or string for backup filename (without extension)
restore_learned_knowledge(BackupName) :-
    atomic_list_concat(['learned_knowledge_', BackupName, '.pl'], BackupFile),
    
    writeln('╔════════════════════════════════════════════════════════════╗'),
    writeln('║  Restoring Learned Knowledge                               ║'),
    writeln('╚════════════════════════════════════════════════════════════╝'),
    writeln(''),
    
    (   exists_file(BackupFile)
    ->  % Clear current knowledge
        retractall(more_machine_learner:run_learned_strategy(_,_,_,_,_)),
        
        % Copy backup to active file
        copy_file(BackupFile, 'learned_knowledge.pl'),
        
        % Reload
        consult('learned_knowledge.pl'),
        
        format('✓ Restored from: ~w~n', [BackupFile]),
        
        % Count restored strategies
        findall(Name, clause(more_machine_learner:run_learned_strategy(_,_,_,Name,_), _), Strategies),
        length(Strategies, Count),
        format('  Strategies restored: ~w~n', [Count]),
        (   Count > 0
        ->  format('  ~w~n', [Strategies])
        ;   true
        )
    ;   format('✗ Backup file not found: ~w~n', [BackupFile])
    ),
    writeln('').

%!      inspect_learned_knowledge is det.
%
%       Displays all currently learned strategies.
inspect_learned_knowledge :-
    writeln('╔════════════════════════════════════════════════════════════╗'),
    writeln('║  Current Learned Knowledge                                 ║'),
    writeln('╚════════════════════════════════════════════════════════════╝'),
    writeln(''),
    
    all_learned_strategy_names(Strategies),
    length(Strategies, Count),
    
    format('Total Strategies: ~w~n', [Count]),
    writeln(''),
    
    (   Count > 0
    ->  writeln('Strategy Names:'),
        forall(member(S, Strategies),
               format('  • ~w~n', [S]))
    ;   writeln('No strategies learned yet.'),
        writeln('System is in primordial state (Counting All only).')
    ),
    
    writeln(''),
    
    (   exists_file('learned_knowledge.pl')
    ->  size_file('learned_knowledge.pl', Size),
        format('Knowledge file size: ~w bytes~n', [Size])
    ;   writeln('Knowledge file: not found')
    ),
    writeln('').

%!      count_learned_strategies(-Count) is det.
%
%       Returns the number of currently learned strategies.
count_learned_strategies(Count) :-
    all_learned_strategy_names(All),
    length(All, Count).

all_learned_strategy_names(All) :-
    findall(Name, clause(more_machine_learner:run_learned_strategy(_,_,_,Name,_), _), Strategies),
    findall(Name,
            strategy_synthesis:synthesized_strategy(_, _, _, _, Name, _, _),
            Syntheses),
    append(Strategies, Syntheses, All0),
    sort(All0, All).
