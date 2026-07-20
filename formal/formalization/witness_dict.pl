/** <module> Shared constructor for closed-world witness dictionaries
 *
 * Witness predicates keep their domain-specific fields in Fields.  This
 * constructor supplies the two fields shared across the crosswalk, geometry,
 * and standards witness families without changing the resulting dict shape.
 */
:- module(witness_dict,
          [ witness_dict/4
          ]).

%!  witness_dict(+Kind, +Scope, +Fields, -Witness) is det.
%
%   Add the shared Kind and Scope fields to a domain-specific witness dict.
witness_dict(Kind, Scope, Fields, Witness) :-
    put_dict(_{kind: Kind, scope: Scope}, Fields, Witness).
