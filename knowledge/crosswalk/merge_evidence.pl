/** <module> merge_evidence — required companion to every canonical_concept/2 assertion.
 *
 * GATE CONTRACT
 * Before adding a line of the form
 *     canonical_concept('some_module:predicate/N', canonical_name).
 * to ANY crosswalk file, you MUST first add a corresponding
 *     merge_evidence('some_module:predicate/N', canonical_name, BibKey, Evidence).
 * entry here.
 *
 * The pre-commit hook (scripts/merge_gate/check_merge.py) scans staged diffs
 * for new canonical_concept/2 lines and BLOCKS the commit unless:
 *   (a) a merge_evidence/4 entry with matching first two arguments exists here,
 *   (b) the BibKey atom is non-empty (not ''),
 *   (c) the Evidence string is non-empty (not ''),
 *   (d) the discrimination test passes: no Prolog context found where the
 *       proposed legacy functor's inferential role (entailments, incompatibilities)
 *       differs from the existing members of the target canonical family.
 *
 * Discrimination test logic (run by check_merge.py via swipl):
 *   For proposed pair (LegacyFunctor, Canonical):
 *     1. Collect the MODULE and PRED from LegacyFunctor (format: 'mod:pred/N').
 *     2. Query material_inference_unified/4 filtered to PRED vs to other preds
 *        already in Canonical's family -> compare conclusion sets.
 *     3. Query incompatible/3 from canonical_vocabulary -> compare partner sets.
 *     4. If any set differs -> BLOCK: the terms are discriminable.
 *
 * A discriminable pair is NOT the same concept. Shared string root is not
 * evidence of shared inferential role (carrots != grapes).
 *
 * FORMAT
 *   merge_evidence(
 *       LegacyFunctor,   % atom: 'module:predicate/arity'
 *       CanonicalName,   % atom: the target canonical name
 *       BibKey,          % atom: citation key in the literature DB (non-empty)
 *       Evidence         % atom: one sentence stating the SHARED inferential role
 *   ).
 *
 * STATUS TRACKING
 *   After check_merge.py verifies a proposal, it prints "GATE PASSED" for that
 *   entry. You may then add the canonical_concept/2 line in the family file.
 *   The merge_evidence entry stays here permanently as the audit record.
 *
 * EXAMPLES (commented — do not uncomment without running the gate first)
 *
 * % EXAMPLE: correct — two different arities of the same Brandomian operation
 * % merge_evidence(
 * %     'deontic_scorekeeper:material_inference/3',
 * %     material_inference,
 * %     brandom_2000_ar,
 * %     'Both carry the relation: holding premise P materially entitles commitment C'
 * % ).
 *
 * % EXAMPLE: WRONG — would be blocked because 'reorganize' has crisis-trigger
 * % entailments that 'reflect' lacks:
 * % merge_evidence('learner:reflect/2', reorganize, '', '').
 */
:- module(merge_evidence, [merge_evidence/4]).

%! merge_evidence(+LegacyFunctor, +CanonicalName, +BibKey, +Evidence) is det.
%
%  Audit record for every approved canonical_concept/2 mapping.
%  Gate check runs on entries present here; entries ABSENT here cause BLOCK.

% No approved proposals yet — add entries below as they pass the gate.
