/** <module> Authored machine-class attestations
 *
 * These rows report classes named in module prose. They are authored claims
 * with source locations, not classifications witnessed by the generated
 * transition tables. The computed graph typology remains separate in
 * machine_typology.pl.
 */

:- multifile machine_class_attestation/4.

machine_class_attestation(counting, recursive_place_value_inscription,
                          pushdown_counter,
                          source('knowledge/strategies/math/counting2.pl:1')).
machine_class_attestation(addition, make_base_transfer,
                          finite_state_machine,
                          source('knowledge/strategies/math/sar_add_rmb.pl:4')).
machine_class_attestation(addition, base_ones_chunking,
                          finite_state_machine,
                          source('knowledge/strategies/math/sar_add_chunking.pl:4')).
machine_class_attestation(fraction, unit_fraction_partition,
                          finite_state_automaton,
                          source('knowledge/strategies/math/fraction_partitioning.pl:3')).
