/** <module> Interactive Command-Line UI for the More Machine Learner
 *
 * This module provides a text-based, interactive user interface for the
 * "More Machine Learner" system. It allows a user to:
 *
 * - Trigger the learning of new addition strategies from examples.
 * - Trigger a critique of existing rules using challenging subtraction problems.
 * - View the strategies that have been learned during the session.
 * - Load and save learned knowledge from a file (`learned_knowledge.pl`).
 *
 * The main entry point is `start/0`, which initializes the system and
 * displays the main menu.
 *
 * 
 * 
 */
:- module(interactive_ui, [start/0]).

:- use_module(more_machine_learner).
:- use_module(execution_handler, [run_computation/2]).

% --- Main Entry Point ---

%!      start is det.
%
%       The main entry point for the interactive user interface.
%
%       This predicate displays a welcome message, asks the user if they want
%       to load previously saved knowledge, and then enters the main menu loop
%       where the user can select different actions.
start :-
    welcome_message,
    ask_to_load_knowledge,
    main_menu.

% --- Interactive UI Predicates ---

welcome_message :-
    nl,
    writeln('===================================================='),
    writeln('          Welcome to the More Machine Learner       '),
    writeln('===================================================='),
    writeln('All I can do is count, but I can learn from what you show me.'),
    nl.

ask_to_load_knowledge :-
    write('Do you want to load previously learned strategies? (y/n) > '),
    read_line_to_string(user_input, Response),
    (   (Response = "y" ; Response = "Y")
    ->  (   exists_file('learned_knowledge.pl')
        ->  writeln('Loading previously learned knowledge...'),
            consult('learned_knowledge.pl')
        ;   writeln('No saved knowledge file found.')
        )
    ;   writeln('Starting with a clean slate.')
    ).

main_menu :-
    nl,
    writeln('--- Main Menu ---'),
    writeln('1. Learn a new addition strategy (e.g., from 8+5=13)'),
    writeln('2. Critique a normative rule (e.g., from 3-5=-2)'),
    writeln('3. Show currently learned strategies'),
    writeln('4. Save learned strategies'),
    writeln('5. Exit'),
    write('> '),
    read_line_to_string(user_input, Choice),
    handle_menu_choice(Choice).

handle_menu_choice("1") :- !, run_learning_interaction, main_menu.
handle_menu_choice("2") :- !, run_critique_interaction, main_menu.
handle_menu_choice("3") :- !, show_learned_strategies, main_menu.
handle_menu_choice("4") :- !, save_knowledge, main_menu.
handle_menu_choice("5") :- !, writeln('Goodbye!'), nl.
handle_menu_choice(_) :- writeln('Invalid choice, please try again.'), main_menu.

run_learning_interaction :-
    nl,
    writeln('--- Learning a New Strategy ---'),
    writeln('Please provide a basic addition problem and its result.'),
    write('Example: 8+5=13'), nl,
    write('Problem > '),
    read_line_to_string(user_input, ProblemString),
    (   parse_problem(ProblemString, +(A,B), Result)
    ->  bootstrap_from_observation(+(A,B), Result)
    ;   writeln('Invalid problem format. Please use the format "A+B=C".')
    ).

run_critique_interaction :-
    nl,
    writeln('--- Critiquing a Norm ---'),
    writeln('Please provide a challenging subtraction problem.'),
    write('Example: 3-5=-2'), nl,
    write('Problem > '),
    read_line_to_string(user_input, ProblemString),
    (   parse_problem(ProblemString, -(A,B), Result)
    ->  % Route through the execution handler so norm-violating problems
        % (A < B in natural numbers) trigger perturbation(normative_crisis(...))
        % and route to domain expansion (N -> Z).
        run_computation(object_level:minus(A, B, Result), 20)
    ;   writeln('Invalid problem format. Please use the format "A-B=C".')
    ).

show_learned_strategies :-
    nl,
    writeln('--- Learned Strategies ---'),
    (   current_predicate(learned_strategy/1)
    ->  listing(learned_strategy/1)
    ;   writeln('No strategies have been learned in this session.')
    ),
    nl.

% --- Parsing Helper ---
parse_problem(String, Term, Result) :-
    normalize_space(string(CleanString), String),
    atomic_list_concat(Parts, '=', CleanString),
    (   Parts = [Problem, ResultStr]
    ->  normalize_space(string(TrimmedResult), ResultStr),
        number_string(Result, TrimmedResult),
        (   atomic_list_concat([A_str, B_str], '+', Problem)
        ->  normalize_space(string(TrimmedA), A_str),
            normalize_space(string(TrimmedB), B_str),
            number_string(A, TrimmedA),
            number_string(B, TrimmedB),
            Term = +(A,B)
        ;   atomic_list_concat([A_str, B_str], '-', Problem)
        ->  normalize_space(string(TrimmedA), A_str),
            normalize_space(string(TrimmedB), B_str),
            number_string(A, TrimmedA),
            number_string(B, TrimmedB),
            Term = -(A,B)
        ;   fail
        )
    ;   fail
    ).
