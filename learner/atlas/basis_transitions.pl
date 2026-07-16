/** <module> Generated basis transitions of the curriculum dynamics.
 *
 * Do not edit by hand. Regenerate with scripts/curriculum/mini_atlas.pl.
 * basis_transition(Lesson, Stage0, Role, Task, State1, Observation): one run
 * of f_{t,c} over a basis event. atlas_sufficiency_finding(Op, RoleKind,
 * Stage, ObservationKinds): an event class the (stage, operation, role)
 * abstraction fails to determine (operand detail is a hidden variable).
 */
:- module(basis_transitions, [basis_transition/6, atlas_sufficiency_finding/4]).

basis_transition('IM-G1-U2-L1', 1, productive, add(5,2), learner_state(1,[]), solved(7)).
basis_transition('IM-G1-U2-L1', 1, productive, subtract(5,2), learner_state(1,[]), solved(3)).
basis_transition('IM-G1-U2-L1', 1, deformation(count_all_when_count_on_available), add(5,2), learner_state(1,[]), no_reorganization_domain(add)).
basis_transition('IM-G1-U2-L1', 2, productive, add(5,2), learner_state(2,[]), solved(7)).
basis_transition('IM-G1-U2-L1', 2, productive, subtract(5,2), learner_state(2,[]), solved(3)).
basis_transition('IM-G1-U2-L1', 2, deformation(count_all_when_count_on_available), add(5,2), learner_state(2,[]), no_reorganization_domain(add)).
basis_transition('IM-G1-U2-L2', 1, productive, add(6,3), learner_state(1,[]), solved(9)).
basis_transition('IM-G1-U2-L2', 1, deformation(count_all_when_count_on_available), add(6,3), learner_state(1,[]), no_reorganization_domain(add)).
basis_transition('IM-G1-U2-L2', 2, productive, add(6,3), learner_state(2,[]), solved(9)).
basis_transition('IM-G1-U2-L2', 2, deformation(count_all_when_count_on_available), add(6,3), learner_state(2,[]), no_reorganization_domain(add)).
basis_transition('IM-G1-U2-L3', 1, productive, subtract(8,6), learner_state(1,[]), solved(2)).
basis_transition('IM-G1-U2-L3', 1, deformation(operation_direction_reversal), subtract(8,6), learner_state(1,[]), needs_oracle).
basis_transition('IM-G1-U2-L3', 2, productive, subtract(8,6), learner_state(2,[]), solved(2)).
basis_transition('IM-G1-U2-L3', 2, deformation(operation_direction_reversal), subtract(8,6), learner_state(2,[]), needs_oracle).
basis_transition('IM-G1-U2-L6', 1, productive, add(4,5), learner_state(1,[]), solved(9)).
basis_transition('IM-G1-U2-L6', 1, deformation(count_all_when_count_on_available), add(4,5), learner_state(1,[]), no_reorganization_domain(add)).
basis_transition('IM-G1-U2-L6', 2, productive, add(4,5), learner_state(2,[]), solved(9)).
basis_transition('IM-G1-U2-L6', 2, deformation(count_all_when_count_on_available), add(4,5), learner_state(2,[]), no_reorganization_domain(add)).
basis_transition('IM-G1-U3-L11', 1, productive, add(14,3), learner_state(1,[]), solved(17)).
basis_transition('IM-G1-U3-L11', 1, deformation(count_all_when_count_on_available), add(14,3), learner_state(1,[]), no_reorganization_domain(add)).
basis_transition('IM-G1-U3-L11', 2, productive, add(14,3), learner_state(2,[]), solved(17)).
basis_transition('IM-G1-U3-L11', 2, deformation(count_all_when_count_on_available), add(14,3), learner_state(2,[]), no_reorganization_domain(add)).
basis_transition('IM-G1-U3-L17', 1, productive, add(3,9), learner_state(1,[]), solved(12)).
basis_transition('IM-G1-U3-L17', 1, productive, add(6,8), learner_state(1,[]), solved(14)).
basis_transition('IM-G1-U3-L17', 1, productive, add(7,5), learner_state(1,[]), solved(12)).
basis_transition('IM-G1-U3-L17', 1, productive, add(8,6), learner_state(1,[]), solved(14)).
basis_transition('IM-G1-U3-L17', 1, deformation(count_all_when_count_on_available), add(3,9), learner_state(1,[]), no_reorganization_domain(add)).
basis_transition('IM-G1-U3-L17', 1, deformation(count_all_when_count_on_available), add(6,8), learner_state(1,[]), no_reorganization_domain(add)).
basis_transition('IM-G1-U3-L17', 1, deformation(count_all_when_count_on_available), add(7,5), learner_state(1,[]), no_reorganization_domain(add)).
basis_transition('IM-G1-U3-L17', 1, deformation(count_all_when_count_on_available), add(8,6), learner_state(1,[]), no_reorganization_domain(add)).
basis_transition('IM-G1-U3-L17', 2, productive, add(3,9), learner_state(2,[]), solved(12)).
basis_transition('IM-G1-U3-L17', 2, productive, add(6,8), learner_state(2,[]), solved(14)).
basis_transition('IM-G1-U3-L17', 2, productive, add(7,5), learner_state(2,[]), solved(12)).
basis_transition('IM-G1-U3-L17', 2, productive, add(8,6), learner_state(2,[]), solved(14)).
basis_transition('IM-G1-U3-L17', 2, deformation(count_all_when_count_on_available), add(3,9), learner_state(2,[]), no_reorganization_domain(add)).
basis_transition('IM-G1-U3-L17', 2, deformation(count_all_when_count_on_available), add(6,8), learner_state(2,[]), no_reorganization_domain(add)).
basis_transition('IM-G1-U3-L17', 2, deformation(count_all_when_count_on_available), add(7,5), learner_state(2,[]), no_reorganization_domain(add)).
basis_transition('IM-G1-U3-L17', 2, deformation(count_all_when_count_on_available), add(8,6), learner_state(2,[]), no_reorganization_domain(add)).
basis_transition('IM-G1-U3-L2', 1, productive, add(2,8), learner_state(1,[]), solved(10)).
basis_transition('IM-G1-U3-L2', 1, productive, add(3,6), learner_state(1,[]), solved(9)).
basis_transition('IM-G1-U3-L2', 1, productive, add(5,3), learner_state(1,[]), solved(8)).
basis_transition('IM-G1-U3-L2', 1, productive, add(7,2), learner_state(1,[]), solved(9)).
basis_transition('IM-G1-U3-L2', 1, deformation(count_all_when_count_on_available), add(3,6), learner_state(1,[]), no_reorganization_domain(add)).
basis_transition('IM-G1-U3-L2', 1, deformation(count_all_when_count_on_available), add(5,3), learner_state(1,[]), no_reorganization_domain(add)).
basis_transition('IM-G1-U3-L2', 2, productive, add(2,8), learner_state(2,[]), solved(10)).
basis_transition('IM-G1-U3-L2', 2, productive, add(3,6), learner_state(2,[]), solved(9)).
basis_transition('IM-G1-U3-L2', 2, productive, add(5,3), learner_state(2,[]), solved(8)).
basis_transition('IM-G1-U3-L2', 2, productive, add(7,2), learner_state(2,[]), solved(9)).
basis_transition('IM-G1-U3-L2', 2, deformation(count_all_when_count_on_available), add(3,6), learner_state(2,[]), no_reorganization_domain(add)).
basis_transition('IM-G1-U3-L2', 2, deformation(count_all_when_count_on_available), add(5,3), learner_state(2,[]), no_reorganization_domain(add)).
basis_transition('IM-G1-U3-L6', 1, productive, subtract(7,4), learner_state(1,[]), solved(3)).
basis_transition('IM-G1-U3-L6', 1, productive, subtract(10,3), learner_state(1,[]), solved(7)).
basis_transition('IM-G1-U3-L6', 1, deformation(operation_direction_reversal), subtract(10,3), learner_state(1,[]), needs_oracle).
basis_transition('IM-G1-U3-L6', 2, productive, subtract(7,4), learner_state(2,[]), solved(3)).
basis_transition('IM-G1-U3-L6', 2, productive, subtract(10,3), learner_state(2,[]), solved(7)).
basis_transition('IM-G1-U3-L6', 2, deformation(operation_direction_reversal), subtract(10,3), learner_state(2,[]), needs_oracle).
basis_transition('IM-G2-U2-L1', 1, productive, subtract(36,23), learner_state(1,[]), solved(13)).
basis_transition('IM-G2-U2-L1', 1, deformation(operation_direction_reversal), subtract(36,23), learner_state(2,[strategy(subtract,2)]), reorganized(accommodation,strategy(subtract,2))).
basis_transition('IM-G2-U2-L1', 2, productive, subtract(36,23), learner_state(2,[]), solved(13)).
basis_transition('IM-G2-U2-L1', 2, deformation(operation_direction_reversal), subtract(36,23), learner_state(2,[strategy(subtract,2)]), reorganized(efficiency,strategy(subtract,2))).
basis_transition('IM-G2-U2-L11', 1, productive, subtract(31,15), learner_state(1,[]), solved(16)).
basis_transition('IM-G2-U2-L11', 1, productive, subtract(42,16), learner_state(1,[]), solved(26)).
basis_transition('IM-G2-U2-L11', 1, productive, subtract(42,28), learner_state(1,[]), solved(14)).
basis_transition('IM-G2-U2-L11', 1, deformation(operation_direction_reversal), subtract(42,16), learner_state(2,[strategy(subtract,2)]), reorganized(accommodation,strategy(subtract,2))).
basis_transition('IM-G2-U2-L11', 1, deformation(smaller_from_larger_column), subtract(42,28), learner_state(2,[strategy(subtract,2)]), reorganized(accommodation,strategy(subtract,2))).
basis_transition('IM-G2-U2-L11', 2, productive, subtract(31,15), learner_state(2,[]), solved(16)).
basis_transition('IM-G2-U2-L11', 2, productive, subtract(42,16), learner_state(2,[]), solved(26)).
basis_transition('IM-G2-U2-L11', 2, productive, subtract(42,28), learner_state(2,[]), solved(14)).
basis_transition('IM-G2-U2-L11', 2, deformation(operation_direction_reversal), subtract(42,16), learner_state(2,[strategy(subtract,2)]), reorganized(efficiency,strategy(subtract,2))).
basis_transition('IM-G2-U2-L11', 2, deformation(smaller_from_larger_column), subtract(42,28), learner_state(2,[strategy(subtract,2)]), reorganized(efficiency,strategy(subtract,2))).
basis_transition('IM-G2-U3-L10', 1, productive, subtract(27,13), learner_state(1,[]), solved(14)).
basis_transition('IM-G2-U3-L10', 1, deformation(endpoint_as_difference), subtract(27,13), learner_state(2,[strategy(subtract,2)]), reorganized(accommodation,strategy(subtract,2))).
basis_transition('IM-G2-U3-L10', 2, productive, subtract(27,13), learner_state(2,[]), solved(14)).
basis_transition('IM-G2-U3-L10', 2, deformation(endpoint_as_difference), subtract(27,13), learner_state(2,[strategy(subtract,2)]), reorganized(efficiency,strategy(subtract,2))).
basis_transition('IM-G2-U3-L11', 1, productive, subtract(44,18), learner_state(1,[]), solved(26)).
basis_transition('IM-G2-U3-L11', 1, deformation(operation_direction_reversal), subtract(44,18), learner_state(2,[strategy(subtract,2)]), reorganized(accommodation,strategy(subtract,2))).
basis_transition('IM-G2-U3-L11', 2, productive, subtract(44,18), learner_state(2,[]), solved(26)).
basis_transition('IM-G2-U3-L11', 2, deformation(operation_direction_reversal), subtract(44,18), learner_state(2,[strategy(subtract,2)]), reorganized(efficiency,strategy(subtract,2))).
basis_transition('IM-G3-U1-L12', 1, productive, multiply(3,5), learner_state(1,[]), solved(15)).
basis_transition('IM-G3-U1-L12', 1, productive, multiply(3,10), learner_state(1,[]), solved(30)).
basis_transition('IM-G3-U1-L12', 1, productive, multiply(4,2), learner_state(1,[]), solved(8)).
basis_transition('IM-G3-U1-L12', 1, productive, multiply(4,5), learner_state(1,[]), solved(20)).
basis_transition('IM-G3-U1-L12', 1, productive, multiply(5,10), learner_state(1,[]), solved(50)).
basis_transition('IM-G3-U1-L12', 1, productive, multiply(7,2), learner_state(1,[]), solved(14)).
basis_transition('IM-G3-U1-L12', 1, deformation(addition_instead_of_multiplication), multiply(3,5), learner_state(2,[strategy(multiply,2)]), reorganized(accommodation,strategy(multiply,2))).
basis_transition('IM-G3-U1-L12', 1, deformation(addition_instead_of_multiplication), multiply(3,10), learner_state(2,[strategy(multiply,2)]), reorganized(accommodation,strategy(multiply,2))).
basis_transition('IM-G3-U1-L12', 1, deformation(addition_instead_of_multiplication), multiply(4,2), learner_state(2,[strategy(multiply,2)]), reorganized(accommodation,strategy(multiply,2))).
basis_transition('IM-G3-U1-L12', 1, deformation(addition_instead_of_multiplication), multiply(4,5), learner_state(2,[strategy(multiply,2)]), reorganized(accommodation,strategy(multiply,2))).
basis_transition('IM-G3-U1-L12', 1, deformation(addition_instead_of_multiplication), multiply(5,10), learner_state(2,[strategy(multiply,2)]), reorganized(accommodation,strategy(multiply,2))).
basis_transition('IM-G3-U1-L12', 1, deformation(addition_instead_of_multiplication), multiply(7,2), learner_state(2,[strategy(multiply,2)]), reorganized(accommodation,strategy(multiply,2))).
basis_transition('IM-G3-U1-L12', 2, productive, multiply(3,5), learner_state(2,[]), solved(15)).
basis_transition('IM-G3-U1-L12', 2, productive, multiply(3,10), learner_state(2,[]), solved(30)).
basis_transition('IM-G3-U1-L12', 2, productive, multiply(4,2), learner_state(2,[]), solved(8)).
basis_transition('IM-G3-U1-L12', 2, productive, multiply(4,5), learner_state(2,[]), solved(20)).
basis_transition('IM-G3-U1-L12', 2, productive, multiply(5,10), learner_state(2,[]), solved(50)).
basis_transition('IM-G3-U1-L12', 2, productive, multiply(7,2), learner_state(2,[]), solved(14)).
basis_transition('IM-G3-U1-L12', 2, deformation(addition_instead_of_multiplication), multiply(3,5), learner_state(2,[strategy(multiply,2)]), reorganized(efficiency,strategy(multiply,2))).
basis_transition('IM-G3-U1-L12', 2, deformation(addition_instead_of_multiplication), multiply(3,10), learner_state(2,[strategy(multiply,2)]), reorganized(efficiency,strategy(multiply,2))).
basis_transition('IM-G3-U1-L12', 2, deformation(addition_instead_of_multiplication), multiply(4,2), learner_state(2,[strategy(multiply,2)]), reorganized(efficiency,strategy(multiply,2))).
basis_transition('IM-G3-U1-L12', 2, deformation(addition_instead_of_multiplication), multiply(4,5), learner_state(2,[strategy(multiply,2)]), reorganized(efficiency,strategy(multiply,2))).
basis_transition('IM-G3-U1-L12', 2, deformation(addition_instead_of_multiplication), multiply(5,10), learner_state(2,[strategy(multiply,2)]), reorganized(efficiency,strategy(multiply,2))).
basis_transition('IM-G3-U1-L12', 2, deformation(addition_instead_of_multiplication), multiply(7,2), learner_state(2,[strategy(multiply,2)]), reorganized(efficiency,strategy(multiply,2))).
basis_transition('IM-G3-U1-L13', 1, productive, multiply(4,5), learner_state(1,[]), solved(20)).
basis_transition('IM-G3-U1-L13', 1, productive, multiply(6,5), learner_state(1,[]), solved(30)).
basis_transition('IM-G3-U1-L13', 1, productive, multiply(7,10), learner_state(1,[]), solved(70)).
basis_transition('IM-G3-U1-L13', 1, productive, multiply(8,10), learner_state(1,[]), solved(80)).
basis_transition('IM-G3-U1-L13', 1, deformation(addition_instead_of_multiplication), multiply(8,10), learner_state(2,[strategy(multiply,2)]), reorganized(accommodation,strategy(multiply,2))).
basis_transition('IM-G3-U1-L13', 2, productive, multiply(4,5), learner_state(2,[]), solved(20)).
basis_transition('IM-G3-U1-L13', 2, productive, multiply(6,5), learner_state(2,[]), solved(30)).
basis_transition('IM-G3-U1-L13', 2, productive, multiply(7,10), learner_state(2,[]), solved(70)).
basis_transition('IM-G3-U1-L13', 2, productive, multiply(8,10), learner_state(2,[]), solved(80)).
basis_transition('IM-G3-U1-L13', 2, deformation(addition_instead_of_multiplication), multiply(8,10), learner_state(2,[strategy(multiply,2)]), reorganized(efficiency,strategy(multiply,2))).
basis_transition('IM-G3-U3-L2', 1, productive, subtract(674,327), learner_state(1,[]), solved(347)).
basis_transition('IM-G3-U3-L2', 1, deformation(operation_direction_reversal), subtract(674,327), learner_state(1,[]), needs_oracle).
basis_transition('IM-G3-U3-L2', 2, productive, subtract(674,327), learner_state(2,[]), solved(347)).
basis_transition('IM-G3-U3-L2', 2, deformation(operation_direction_reversal), subtract(674,327), learner_state(2,[]), needs_oracle).
basis_transition('IM-G4-U5-L3', 1, productive, divide(21,3), learner_state(1,[]), solved(7)).
basis_transition('IM-G4-U5-L3', 1, deformation(total_as_missing_factor), divide(21,3), learner_state(2,[strategy(divide,2)]), reorganized(accommodation,strategy(divide,2))).
basis_transition('IM-G4-U5-L3', 2, productive, divide(21,3), learner_state(2,[]), solved(7)).
basis_transition('IM-G4-U5-L3', 2, deformation(total_as_missing_factor), divide(21,3), learner_state(2,[strategy(divide,2)]), reorganized(efficiency,strategy(divide,2))).

atlas_sufficiency_finding(subtract, deformation, 1, [needs_oracle,reorganized]).
atlas_sufficiency_finding(subtract, deformation, 2, [needs_oracle,reorganized]).
