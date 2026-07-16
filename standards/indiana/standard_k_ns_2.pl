/** <module> Standard K.NS.2 — Write whole numbers 0-20, number words 0-10
 *
 * Indiana: K.NS.2 — "Write whole numbers from 0 to 20 and identify number
 *          words from 0 to 10. Represent a number of objects with a written
 *          numeral 0-20 (with 0 representing a count of no objects)." (E)
 * CCSS:    K.CC.A.3 — "Write numbers from 0 to 20. Represent a number of
 *                      objects with a written numeral 0-20 (with 0
 *                      representing a count of no objects)."
 *
 * VPV MAPPING:
 *   V  (target vocabulary): written numerals 0-20; number words
 *      zero through ten (Indiana adds word identification)
 *   P  (practices): writing numerals (production); identifying number
 *      words (recognition); representing object counts with written
 *      numerals (correspondence between counted quantity and symbol)
 *   V' (metavocabulary): "write the number", "this is called",
 *      "how many? write that number", "zero means none"
 *
 * LEARNING COMPONENTS (from LearningCommons KG v1.7.0):
 *   - Write numbers from 0 to 9          (ad9ed28a-1130-545c-...)
 *   - Write numbers from 0 to 20         (ef66c64b-bb86-50a5-...)
 *   - Use the number 0 for no objects    (eaa30141-1b84-5d15-...)
 *   - Represent objects up to 20 with numeral (47cdf11f-85a1-5d6e-...)
 *
 * BRANDOM CONNECTION: Naming is normative assignment — the teacher
 *   confers authority on the symbol. The learner cannot derive that
 *   s(s(0)) is called "two"; it must be taught. This is Brandom's
 *   point about vocabulary introduction: new vocabulary enters through
 *   social practice (the teacher's act of naming), not through
 *   individual discovery. The practice (P) of naming transforms the
 *   learner's vocabulary from tally-sequences-only to tally-sequences-
 *   plus-number-words. PP-sufficiency: mastering the naming practice
 *   is sufficient to deploy the numeral vocabulary.
 *
 * RELATIONSHIP TO DESIGN/04:
 *   This module implements the numeral_name/2 naming table and the
 *   learn_name/2, resolve/2 operations specified in design/04
 *   (Number-Word Layer). Names are taught incrementally through
 *   the curriculum — the table starts empty.
 *
 * BOUNDARIES:
 *   - "Writing" is modeled as producing a Prolog atom. The embodied
 *     act of writing a numeral (motor skill, spatial layout) is outside
 *     this symbolic naming table.
 *   - Number words beyond ten are not compositional in this module.
 *     "Thirteen" is a primitive name, not "three-and-ten". The
 *     compositional structure of English number words (twenty-three
 *     = two tens and three) is a place-value discovery that belongs
 *     to later standards.
 *   - The "0 represents no objects" component is represented as the
 *     empty recollection in this naming table. Further distinctions
 *     between absence, cardinality, and symbol use belong to a richer
 *     zero concept surface.
 */

:- module(standard_k_ns_2, [
    learn_numeral/2,       % +TallySequence, +Name — teacher teaches a name
    learn_numeral_witness/3, % +TallySequence, +Name, -Witness
    write_numeral/2,       % +Recollection, -Name — produce numeral for quantity
    write_numeral_witness/3, % +Recollection, -Name, -Witness
    read_numeral/2,        % +Name, -Recollection — resolve name to quantity
    read_numeral_witness/3, % +Name, -Recollection, -Witness
    represent_count/3,     % +Objects, -Count, -Name — count then name
    represent_count_witness/4, % +Objects, -Count, -Name, -Witness
    numeral_known/2,       % ?Recollection, ?Name — query the naming table
    numeral_known_witness/3, % ?Recollection, ?Name, -Witness
    reset_numerals/0,      % clear all learned names
    teach_numerals_to/1,   % +MaxInt — teach all names from 0 to Max
    teach_numerals_to_witness/2 % +MaxInt, -Witness
]).

:- use_module(formalization(grounded_arithmetic), [
    integer_to_recollection/2,
    recollection_to_integer/2,
    incur_cost/1
]).

:- dynamic numeral_known/2.
%% numeral_known(+Recollection, +Name)
%% The teacher's naming table. Populated incrementally via learn_numeral/2.
%% Starts empty — names must be taught.

%% Number word table: maps integers to their English names.
%% This is the teacher's knowledge, not the learner's.
number_word(0, zero).
number_word(1, one).
number_word(2, two).
number_word(3, three).
number_word(4, four).
number_word(5, five).
number_word(6, six).
number_word(7, seven).
number_word(8, eight).
number_word(9, nine).
number_word(10, ten).
number_word(11, eleven).
number_word(12, twelve).
number_word(13, thirteen).
number_word(14, fourteen).
number_word(15, fifteen).
number_word(16, sixteen).
number_word(17, seventeen).
number_word(18, eighteen).
number_word(19, nineteen).
number_word(20, twenty).

% ============================================================
% Core operations (design/04 implementation)
% ============================================================

%!  learn_numeral(+Recollection, +Name) is det.
%
%   The teacher teaches that a tally sequence has a name.
%   This is a normative act — the learner accepts the name
%   on the teacher's authority. The name enters as endorsed
%   (the teacher said so).
%
%   Fails silently if already known (idempotent).

learn_numeral(Recollection, Name) :-
    learn_numeral_witness(Recollection, Name, _).

%!  learn_numeral_witness(+Recollection, +Name, -Witness) is det.
%
%   Witness-bearing version of learn_numeral/2. This is the finite dynamic
%   naming-table case: the teacher endorsement either already exists or is
%   asserted into numeral_known/2.
learn_numeral_witness(Recollection, Name, Witness) :-
    (   numeral_known(Recollection, Name)
    ->  learning_witness(Recollection, Name, already_known, Witness)
    ;   incur_cost(inference),
        assertz(numeral_known(Recollection, Name)),
        learning_witness(Recollection, Name, asserted_teacher_endorsement, Witness)
    ).

%!  write_numeral(+Recollection, -Name) is semidet.
%
%   Given a recollection (tally sequence), produce the name
%   the teacher taught for it. Fails if the name hasn't been
%   taught yet — the learner cannot write what they haven't
%   been taught to write.

write_numeral(Recollection, Name) :-
    write_numeral_witness(Recollection, Name, _),
    incur_cost(inference).

%!  write_numeral_witness(+Recollection, -Name, -Witness) is semidet.
%
%   Resolve a recollection through the finite dynamic naming table.
write_numeral_witness(Recollection, Name, Witness) :-
    numeral_known_witness(Recollection, Name, KnownWitness),
    naming_projection_witness(write_numeral,
                              write_numeral/2,
                              Recollection,
                              Name,
                              KnownWitness,
                              Witness).

%!  read_numeral(+Name, -Recollection) is semidet.
%
%   Given a name, resolve it to the tally sequence the teacher
%   associated with it. Fails if the name is unknown.

read_numeral(Name, Recollection) :-
    read_numeral_witness(Name, Recollection, _),
    incur_cost(inference).

%!  read_numeral_witness(+Name, -Recollection, -Witness) is semidet.
%
%   Resolve a name through the finite dynamic naming table.
read_numeral_witness(Name, Recollection, Witness) :-
    numeral_known_witness(Recollection, Name, KnownWitness),
    naming_projection_witness(read_numeral,
                              read_numeral/2,
                              Recollection,
                              Name,
                              KnownWitness,
                              Witness).

%!  represent_count(+Objects, -Count, -Name) is semidet.
%
%   Count a collection of objects (represented as a list),
%   then produce the numeral for the count. This is the
%   "represent a number of objects with a written numeral"
%   component.
%
%   Objects is a list (any elements). Count is the recollection
%   representing the number of objects. Name is the numeral.
%
%   Fails if the count exceeds what the learner has names for.

represent_count(Objects, Count, Name) :-
    incur_cost(inference),
    represent_count_witness(Objects, Count, Name, _).

%!  represent_count_witness(+Objects, -Count, -Name, -Witness) is semidet.
%
%   Count a finite object list, convert that length to a recollection, and
%   resolve it through the taught numeral table.
represent_count_witness(Objects, Count, Name, Witness) :-
    length(Objects, N),
    integer_to_recollection(N, Count),
    write_numeral_witness(Count, Name, WriteWitness),
    Witness = _{ kind: standard_k_ns_2_represent_count,
                 scope: closed_world_finite_dynamic_numeral_table,
                 standard: in_k_ns_2,
                 source_predicate: represent_count/3,
                 object_count: N,
                 count: Count,
                 name: Name,
                 derivation: finite_list_length_then_taught_name_lookup,
                 boundary: supplied_object_list_and_current_taught_names,
                 write_witness: WriteWitness }.

% ============================================================
% Curriculum support
% ============================================================

%!  reset_numerals is det.
%
%   Clear all learned names. For testing.

reset_numerals :-
    retractall(numeral_known(_, _)).

%!  teach_numerals_to(+MaxInt) is det.
%
%   Teach all number words from 0 to MaxInt using the teacher's
%   number_word table. This simulates the curriculum sequence
%   where children learn names incrementally.
%
%   Each name is taught by converting the integer to a recollection
%   and asserting the name mapping.

teach_numerals_to(MaxInt) :-
    teach_numerals_to_witness(MaxInt, _).

%!  teach_numerals_to_witness(+MaxInt, -Witness) is det.
%
%   Teach all teacher-known number words from 0 through MaxInt.
teach_numerals_to_witness(MaxInt,
                          _{ kind: standard_k_ns_2_teach_sequence,
                             scope: closed_world_finite_teacher_number_word_table,
                             standard: in_k_ns_2,
                             source_predicate: teach_numerals_to/1,
                             max: MaxInt,
                             taught: Taught,
                             taught_count: TaughtCount,
                             missing_words: Missing,
                             derivation: iterate_teacher_number_word_table,
                             boundary: number_word_rows_loaded_in_standard_k_ns_2 }) :-
    teach_numerals_(0, MaxInt, [], RevTaught, [], RevMissing),
    reverse(RevTaught, Taught),
    reverse(RevMissing, Missing),
    length(Taught, TaughtCount).

teach_numerals_(Current, Max, Taught, Taught, Missing, Missing) :-
    Current > Max, !.
teach_numerals_(Current, Max, AccTaught, Taught, AccMissing, Missing) :-
    integer_to_recollection(Current, Rec),
    (   number_word(Current, Name)
    ->  learn_numeral_witness(Rec, Name, LearnWitness),
        NextTaught = [LearnWitness|AccTaught],
        NextMissing = AccMissing
    ;   NextTaught = AccTaught,
        NextMissing = [Current|AccMissing]
    ),
    Next is Current + 1,
    teach_numerals_(Next, Max, NextTaught, Taught, NextMissing, Missing).

%!  numeral_known_witness(?Recollection, ?Name, -Witness) is nondet.
%
%   Inspect a row in the current dynamic naming table.
numeral_known_witness(Recollection, Name,
                      _{ kind: standard_k_ns_2_numeral_known,
                         scope: closed_world_finite_dynamic_numeral_table,
                         standard: in_k_ns_2,
                         source_predicate: numeral_known/2,
                         recollection: Recollection,
                         count: Count,
                         name: Name,
                         derivation: current_teacher_endorsed_name_row,
                         boundary: current_dynamic_taught_names }) :-
    numeral_known(Recollection, Name),
    recollection_to_integer(Recollection, Count).

learning_witness(Recollection,
                 Name,
                 Status,
                 _{ kind: standard_k_ns_2_learn_numeral,
                    scope: closed_world_finite_dynamic_numeral_table,
                    standard: in_k_ns_2,
                    source_predicate: learn_numeral/2,
                    recollection: Recollection,
                    count: Count,
                    name: Name,
                    status: Status,
                    derivation: teacher_endorsed_symbol_assignment,
                    boundary: current_dynamic_taught_names }) :-
    recollection_to_integer(Recollection, Count).

naming_projection_witness(Operation,
                          Predicate,
                          Recollection,
                          Name,
                          KnownWitness,
                          _{ kind: standard_k_ns_2_naming_projection,
                             scope: closed_world_finite_dynamic_numeral_table,
                             standard: in_k_ns_2,
                             operation: Operation,
                             source_predicate: Predicate,
                             recollection: Recollection,
                             count: Count,
                             name: Name,
                             derivation: current_taught_name_lookup,
                             boundary: current_dynamic_taught_names,
                             known_witness: KnownWitness }) :-
    recollection_to_integer(Recollection, Count).
