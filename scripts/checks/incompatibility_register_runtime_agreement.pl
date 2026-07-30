% PURPOSE: Keep the generated finite entailment register and the context-scoped
% runtime reader in agreement, including every cross-context permission.
/** <module> Incompatibility register/runtime agreement gate
 *
 * The generated register and `incompatibility_sets` read overlapping
 * hyperedges through different paths. This check requires every earned
 * register row to resolve through the runtime witness relation. It also
 * rejects a co-derivation permission whose declared profile or exact witness
 * edge no longer exists, or whose exact replacement pair is not earned by the
 * register.
 *
 * Run: swipl -q -l paths.pl -s scripts/checks/incompatibility_register_runtime_agreement.pl -g main -t halt
 */
:- use_module(incompat(incompatibility_entailment_order),
              [incompatibility_earned_entails/3,
               incompatibility_order_count/2]).
:- use_module(library(lists), [subtract/3]).
:- use_module(incompat(incompatibility_sets),
              [incompatibility_set/2]).
:- use_module(incompat(brandomian_incompatibility),
              [incompatible_set/1,
               incompatible_set_co_derivation/3]).


main :-
    findall(
        row(Replacement, Replaced, RegisterWitnessCount),
        incompatibility_earned_entails(
            Replacement,
            Replaced,
            RegisterWitnessCount),
        RegisterRows),
    length(RegisterRows, EarnedCount),
    incompatibility_order_count(
        earned_entailments,
        DeclaredEarnedCount),
    findall(
        row(Replacement2, Replaced2, RegisterWitnessCount2),
        ( member(
              row(Replacement2, Replaced2, RegisterWitnessCount2),
              RegisterRows),
          \+ once(
                 incompatibility_sets:incompatibility_entails(
                     Replacement2,
                     Replaced2))
        ),
        RuntimeFailures),
    findall(
        permission(Profile, SourceContext, Witness),
        incompatible_set_co_derivation(Profile, SourceContext, Witness),
        Permissions),
    findall(
        dangling(
            Profile2,
            SourceContext2,
            Witness2,
            MissingProfile,
            MissingWitness),
        ( member(
              permission(Profile2, SourceContext2, Witness2),
              Permissions),
          existence_status(
              incompatible_set(Profile2),
              MissingProfile),
          existence_status(
              incompatibility_set(
                  SourceContext2,
                  set(_Provenance, Witness2)),
              MissingWitness),
          \+ (MissingProfile == no, MissingWitness == no)
        ),
        DanglingPermissions),
    findall(
        malformed(Profile3, SourceContext3, Witness3),
        ( member(
              permission(Profile3, SourceContext3, Witness3),
              Permissions),
          \+ co_derivation_pair(
                 Profile3,
                 Witness3,
                 _Replacement3,
                 _Replaced3)
        ),
        MalformedPermissions),
    findall(
        unregistered(
            Replacement4,
            Replaced4,
            Profile4,
            SourceContext4,
            Witness4),
        ( member(
              permission(Profile4, SourceContext4, Witness4),
              Permissions),
          co_derivation_pair(
              Profile4,
              Witness4,
              Replacement4,
              Replaced4),
          \+ incompatibility_earned_entails(
                 Replacement4,
                 Replaced4,
                 _)
        ),
        UnregisteredPermissions),
    report_result(
        EarnedCount,
        DeclaredEarnedCount,
        RegisterRows,
        RuntimeFailures,
        Permissions,
        DanglingPermissions,
        MalformedPermissions,
        UnregisteredPermissions).


existence_status(Goal, no) :-
    once(Goal),
    !.
existence_status(_Goal, yes).


co_derivation_pair(Profile, Witness, Replacement, Replaced) :-
    subtract(Profile, Witness, [Replaced]),
    subtract(Witness, Profile, [Replacement]),
    Replacement \== Replaced.


report_result(
    EarnedCount,
    EarnedCount,
    _RegisterRows,
    [],
    Permissions,
    [],
    [],
    []) :-
    length(Permissions, PermissionCount),
    format(
        "PASS incompatibility register/runtime agreement: earned=~w; declared_earned=~w; confirmed=~w; co_derivations=~w; registered_co_derivations=~w; dangling=0~n",
        [ EarnedCount,
          EarnedCount,
          EarnedCount,
          PermissionCount,
          PermissionCount
        ]).
report_result(
    EarnedCount,
    DeclaredEarnedCount,
    _RegisterRows,
    RuntimeFailures,
    _Permissions,
    DanglingPermissions,
    MalformedPermissions,
    UnregisteredPermissions) :-
    length(RuntimeFailures, RuntimeFailureCount),
    length(DanglingPermissions, DanglingCount),
    length(MalformedPermissions, MalformedCount),
    length(UnregisteredPermissions, UnregisteredCount),
    ConfirmedCount is EarnedCount - RuntimeFailureCount,
    ( EarnedCount =:= DeclaredEarnedCount ->
        true
    ; format(
          "FAIL register earned-count mismatch: facts=~w declared=~w~n",
          [EarnedCount, DeclaredEarnedCount])
    ),
    forall(
        member(
            row(Replacement, Replaced, RegisterWitnessCount),
            RuntimeFailures),
        format(
            "FAIL register/runtime disagreement: ~q |= ~q (register_witnesses=~w; runtime=refused)~n",
            [Replacement, Replaced, RegisterWitnessCount])),
    forall(
        member(
            dangling(
                Profile,
                SourceContext,
                Witness,
                MissingProfile,
                MissingWitness),
            DanglingPermissions),
        format(
            "FAIL dangling co-derivation permission: profile=~q source=~q witness=~q missing_profile=~w missing_witness=~w~n",
            [ Profile,
              SourceContext,
              Witness,
              MissingProfile,
              MissingWitness
            ])),
    forall(
        member(
            malformed(Profile2, SourceContext2, Witness2),
            MalformedPermissions),
        format(
            "FAIL malformed co-derivation permission: profile=~q source=~q witness=~q replacement_pair=not_single~n",
            [Profile2, SourceContext2, Witness2])),
    forall(
        member(
            unregistered(
                Replacement3,
                Replaced3,
                Profile3,
                SourceContext3,
                Witness3),
            UnregisteredPermissions),
        format(
            "FAIL unregistered co-derivation entailment: ~q |= ~q profile=~q source=~q witness=~q~n",
            [ Replacement3,
              Replaced3,
              Profile3,
              SourceContext3,
              Witness3
            ])),
    format(
        "FAIL incompatibility register/runtime agreement: earned=~w; declared_earned=~w; confirmed=~w; runtime_failures=~w; dangling=~w; malformed_co_derivations=~w; unregistered_co_derivations=~w~n",
        [ EarnedCount,
          DeclaredEarnedCount,
          ConfirmedCount,
          RuntimeFailureCount,
          DanglingCount,
          MalformedCount,
          UnregisteredCount
        ]),
    halt(1).
