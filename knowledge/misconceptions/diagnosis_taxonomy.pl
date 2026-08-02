/** <module> The stepverify error taxonomy as queryable facts
 *
 * The diagnosis benchmark asks for one of seven category names. Until now
 * the taxonomy lived only in the benchmark's option strings, so every
 * caller reconstructed the category boundaries from seven bare labels, and
 * the boundaries are where the misses happen. This module carries the
 * names, a definition that states each boundary, worked examples chosen to
 * mark the boundaries that bite, and a small mapping from checkable
 * observations to the categories they license.
 *
 * The category strings are the benchmark annotators' own labels, kept
 * verbatim because an answer must repeat one exactly. The observation
 * vocabulary is this repository's: each observation names something a
 * caller can check against a worked solution, and category_when/2 says
 * only which category an observation licenses — deciding whether the
 * observation holds stays with the caller, and the mapping is evidence,
 * never a verdict.
 */
:- module(diagnosis_taxonomy,
          [ diagnosis_category/1,
            diagnosis_category_definition/2,
            diagnosis_category_example/3,
            diagnosis_observation/1,
            category_when/2
          ]).

%!  diagnosis_category(?Category) is nondet.
%
%   The seven category labels, verbatim.
diagnosis_category('Misunderstanding of a question').
diagnosis_category('Extra quantity or Missing quantity').
diagnosis_category('Missing / Wrong factual knowledge').
diagnosis_category('Calculation error easily solved by a calculator').
diagnosis_category('None of the above').
diagnosis_category('Reached correct solution but proceeded further').
diagnosis_category('Unit conversion error').

%!  diagnosis_category_definition(?Category, ?Definition) is nondet.
%
%   One definition per category, written to state the boundary rather than
%   restate the label.
diagnosis_category_definition('Misunderstanding of a question',
    'The student answers a different question than the one asked: a different unknown, a different comparison, or a different event. The arithmetic may all be correct. If the student answers the right question with a wrong quantity set, prefer the quantity categories.').
diagnosis_category_definition('Extra quantity or Missing quantity',
    'The student\'s equation uses a quantity the situation does not license, or fails to use one it requires: a given value ignored, a value counted twice, an unstated multiplier missed (twice as, each, per person). The fault sits in which quantities enter the computation, not in the computing.').
diagnosis_category_definition('Missing / Wrong factual knowledge',
    'A fact from outside the problem text is needed and the student lacks it or holds it wrong: days in a week, minutes in an hour used as a known, a definition, a formula. If the problem text itself supplies the value and the student ignores it, that is a quantity error, not this.').
diagnosis_category_definition('Calculation error easily solved by a calculator',
    'A single arithmetic step is computed wrong: the operation and operands are the ones the student intended, and a calculator doing that step would have returned a different number than the student wrote.').
diagnosis_category_definition('None of the above',
    'The solution\'s fault fits none of the other six, or the flagged solution is defensible as read. Reached when every arithmetic step checks, the question asked is the question answered, and the quantity set is licensed.').
diagnosis_category_definition('Reached correct solution but proceeded further',
    'A step states the correct final answer and the student then keeps operating on it, ending elsewhere. The fault is not stopping; everything up to the correct value stands.').
diagnosis_category_definition('Unit conversion error',
    'An exchange between quantity types goes wrong: units of measure, currency, time, or a rate applied across the wrong span. This covers any quantity-type exchange, not only named measurement units; converting correctly but to the wrong target also lands here.').

%!  diagnosis_category_example(?Category, ?Example, ?Boundary) is nondet.
%
%   Worked examples, two per category, each chosen to mark a boundary that
%   a bare label leaves open.
diagnosis_category_example('Misunderstanding of a question',
    'Asked how many more marbles A has than B, the student adds the two collections and reports the total, correctly computed.',
    'Correct arithmetic on the wrong question stays here; it never becomes a calculation error.').
diagnosis_category_example('Misunderstanding of a question',
    'Asked for the price after a discount, the student computes and reports the discount amount itself.',
    'Reporting an intermediate the question did not ask for is this, not proceeding further, when the correct final value never appears.').
diagnosis_category_example('Extra quantity or Missing quantity',
    'A recipe problem states one batch needs 3 eggs and asks about four batches; the student computes with 3 eggs total, missing the multiplier.',
    'An unstated lexical multiplier (each, per, twice as) that never enters the equation is a missing quantity, not missing knowledge.').
diagnosis_category_example('Extra quantity or Missing quantity',
    'The problem gives a delivery fee and a unit price; the student adds the fee once per item instead of once per order.',
    'A given value entering the computation more times than the situation licenses is an extra quantity.').
diagnosis_category_example('Missing / Wrong factual knowledge',
    'The student computes a week\'s earnings as 5 days of work because they take a week to hold 5 days, and the problem never states the number of working days.',
    'The wrong value comes from outside the problem text; had the text stated the days, ignoring it would be a quantity error instead.').
diagnosis_category_example('Missing / Wrong factual knowledge',
    'Area of a triangle computed as base times height with no halving, all multiplications correct.',
    'A wrong formula is wrong knowledge, not a calculation error, because the calculator would faithfully compute the wrong plan.').
diagnosis_category_example('Calculation error easily solved by a calculator',
    'The student sets up 47 times 6 for the right reason and writes 262.',
    'The plan is sound and one step\'s number is false; this is the only category a failed arithmetic check alone can license.').
diagnosis_category_example('Calculation error easily solved by a calculator',
    'A column subtraction inside an otherwise sound solution drops a borrow and carries the wrong difference forward.',
    'One bad step contaminating later steps is still one calculation error, not several categories at once.').
diagnosis_category_example('None of the above',
    'Every step checks, the asked question is answered, and the solution was flagged for style: an unusual but valid decomposition.',
    'When all checks pass, the licensed answer is this one, not the majority category.').
diagnosis_category_example('None of the above',
    'The solution is wrong only because the problem statement itself is contradictory.',
    'A fault in the problem, not the student, has no student-error category and lands here.').
diagnosis_category_example('Reached correct solution but proceeded further',
    'Step 4 states the asked-for total, 28, and step 5 divides it by 2 for no stated reason, reporting 14.',
    'The correct value must actually appear in the work; a solution that never reaches it cannot be this category.').
diagnosis_category_example('Reached correct solution but proceeded further',
    'The student finds the right change due, then subtracts it from the bill again and reports that.',
    'Re-consuming an already-final answer is proceeding further even when the extra step reuses a given.').
diagnosis_category_example('Unit conversion error',
    'Hours are converted to minutes by multiplying by 100.',
    'The classic case: a named unit exchange with the wrong factor.').
diagnosis_category_example('Unit conversion error',
    'A weekly rate is applied to a number of days without scaling, dollars and cents mixed mid-sum.',
    'Rates across spans and currency mixes are quantity-type exchanges; this category is not limited to measurement units.').

%!  diagnosis_observation(?Observation) is nondet.
%
%   The closed observation vocabulary category_when/2 accepts.
diagnosis_observation(arithmetic_step_false).
diagnosis_observation(given_quantity_unused).
diagnosis_observation(quantity_counted_twice).
diagnosis_observation(unstated_multiplier_missed).
diagnosis_observation(outside_fact_wrong_or_absent).
diagnosis_observation(wrong_formula_applied).
diagnosis_observation(different_question_answered).
diagnosis_observation(correct_value_then_more_operations).
diagnosis_observation(quantity_type_exchange_wrong).
diagnosis_observation(all_checks_pass).

%!  category_when(?Observation, ?Category) is nondet.
%
%   Which category an established observation licenses. The caller
%   establishes the observation; this table only carries the license. An
%   observation licensing two categories returns both, and that ambiguity
%   is the table being honest, not a defect.
category_when(arithmetic_step_false,
              'Calculation error easily solved by a calculator').
category_when(given_quantity_unused,
              'Extra quantity or Missing quantity').
category_when(quantity_counted_twice,
              'Extra quantity or Missing quantity').
category_when(unstated_multiplier_missed,
              'Extra quantity or Missing quantity').
category_when(outside_fact_wrong_or_absent,
              'Missing / Wrong factual knowledge').
category_when(wrong_formula_applied,
              'Missing / Wrong factual knowledge').
category_when(different_question_answered,
              'Misunderstanding of a question').
category_when(correct_value_then_more_operations,
              'Reached correct solution but proceeded further').
category_when(quantity_type_exchange_wrong,
              'Unit conversion error').
category_when(all_checks_pass,
              'None of the above').
