:- use_module(hermes(math_claim_language)).
:- use_module(hermes(encyclopedia)).

:- initialization(main, main).

main :-
    expect_claim("4 plus 2 is 6", sum(4,2,6)),
    expect_claim("I added 4 and 2 and got 6", sum(4,2,6)),
    expect_claim("I subtracted 8 from 24 and got 16", subtraction(24,8,16)),
    expect_claim("16 divided by 2 is 8", arithmetic_equation(16/2,8)),
    expect_claim("three fourths of twelve is nine",
                 fraction_of(12,fraction(3,4),9)),
    expect_claim("2/4 is equal to 1/2",
                 equivalence(fraction(2,4),fraction(1,2))),
    expect_claim("24 - 4 - 2 - 8 = 10",
                 arithmetic_equation(24-4-2-8,10)),
    expect_only_claim("2 + 3 * 4 = 14",
                      arithmetic_equation(2+3*4,14)),
    expect_only_claim("2 times 3 plus 4 is 10",
                      arithmetic_equation(2*3+4,10)),
    expect_only_claim("-2 plus 3 is 1",
                      arithmetic_equation(-2+3,1)),
    expect_only_claim("1.5 plus 2.5 is 4",
                      arithmetic_equation(1.5+2.5,4)),
    expect_only_claim("10 percent of 50 is 5",
                      arithmetic_equation(10/100*50,5)),
    expect_only_claim("2 plus 3 plus 4 is 9",
                      arithmetic_equation(2+3+4,9)),
    expect_only_claim("(2 + 3) * 4 = 20",
                      arithmetic_equation((2+3)*4,20)),
    expect_only_claim("2 * (3 + 4) = 14",
                      arithmetic_equation(2*(3+4),14)),
    expect_claims("3 + 4 = 7 = 7 + 0",
                  [arithmetic_equation(3+4,7),
                   arithmetic_equation(7,7+0)]),
    expect_claims("7 = 7 = 7",
                  [arithmetic_equation(7,7),
                   arithmetic_equation(7,7)]),
    expect_only_claim("The ratio is 2 to 3",
                      ratio_statement(ratio(2,3))),
    expect_only_claim("2 is to 3 as 4 is to 6",
                      proportion_statement(ratio(2,3),ratio(4,6))),
    expect_only_claim("I added 2, 3, and 4 and got 9",
                      arithmetic_equation(2+3+4,9)),
    expect_only_claim("nine times three, I said that it was 36",
                      arithmetic_equation(9*3,36)),
    expect_reading("nine times three, I said that it was 36",
                   reported, attributed, positive),
    expect_only_claim("I said that nine times three was 36",
                      arithmetic_equation(9*3,36)),
    expect_reading("I said that nine times three was 36",
                   reported, attributed, positive),
    expect_only_claim("36 divided by one, which would be 36",
                      arithmetic_equation(36/1,36)),
    expect_only_claim("45 divided by one, which would be 45",
                      arithmetic_equation(45/1,45)),
    expect_only_claim("27 divided by three or just, which is nine",
                      arithmetic_equation(27/3,9)),
    expect_only_claim("nine divided by one would be nine",
                      arithmetic_equation(9/1,9)),
    expect_same_claim("nine times three is 27",
                      "I figured that nine times three was 27"),
    expect_reading("I figured that nine times three was 27",
                   reported, attributed, positive),
    expect_only_claim("2 hours and 3 hours and 4 hours, so that's 9 hours total",
                      arithmetic_equation(2+3+4,9)),
    expect_only_claim("1 hour and 2 hours, so that is 3 hours total",
                      sum(1,2,3)),
    expect_verdict("2 + 3 * 4 = 14", "holds"),
    expect_verdict("-2 plus 3 is 1", "holds"),
    expect_verdict("1.5 plus 2.5 is 4", "holds"),
    expect_verdict("10 percent of 50 is 5", "holds"),
    expect_claim("two thirds is greater than one half",
                 comparison(fraction(2,3),greater,fraction(1,2))),
    expect_claim("4 hours cleaning and 2 hours cooking, so that's 6 hours total",
                 sum(4,2,6)),
    expect_no_claim("I have 24 hours"),
    expect_no_claim("4 hours and 2 apples, so that's 6 hours total"),
    expect_reading("Maybe 4 plus 2 is 7", tentative, proposed, positive),
    expect_reading("She said that 4 plus 2 is 6", reported, attributed, positive),
    expect_reading("She said '4 plus 2 is 6'", quoted, attributed, positive),
    expect_reading("She said that 5 plus 3 would be 8", reported, attributed, positive),
    expect_reading("She said '5 plus 3 would be 8'", quoted, attributed, positive),
    expect_reading("It must be that 5 plus 3 would be 8", asserted, undertaken, positive),
    expect_reading("36 divided by one, which would be 36", tentative, proposed, positive),
    expect_same_claim("4 plus 2 is 6", "She said '4 plus 2 is 6'"),
    expect_reading("Is 4 plus 2 equal to 6?", queried, queried, positive),
    expect_reading("4 plus 2 is not 6", asserted, undertaken, negative),
    expect_argument_roles("(2 + 3) * 4 = 20",
                          [left_operand_1,left_operand_2,left_operand_3,right_side]),
    expect_units("2 hours and 3 hours and 4 hours, so that's 9 hours total",
                 [hour]),
    expect_inferred_percentage("10 percent of 50 is 5"),
    expect_unresolved_referent("45 divided by one, which would be 45", which),
    expect_no_claim("I got 18 for that"),
    expect_no_claim("We have 1/3 block left over, which is half a pizza"),
    hermes_encyclopedia:ground_query_dict("4 plus 2 is not 6", Grounded),
    Grounded.math_claims = [Negative],
    expect_equal(Negative.base_verdict, "holds", negative_base_verdict),
    expect_equal(Negative.verdict, "refuted", negative_surface_verdict),
    hermes_encyclopedia:ground_query_dict("She said that 4 plus 2 is 6", Reported),
    Reported.math_claims = [Attributed],
    expect_equal(Attributed.commitment, "attributed", reported_commitment),
    format("PASS quotation-aware math claim language~n").

expect_claim(Text, Expected) :-
    math_claim_language:math_claims_in_text(Text, Claims),
    ( memberchk(Expected, Claims)
    -> true
    ;  throw(error(assertion_failed(expected_claim(Text, Expected, Claims)), _))
    ).

expect_only_claim(Text, Expected) :-
    math_claim_language:math_claims_in_text(Text, Claims),
    expect_equal(Claims, [Expected], expected_only_claim(Text)).

expect_claims(Text, Expected) :-
    math_claim_language:math_claims_in_text(Text, Claims),
    expect_equal(Claims, Expected, expected_claims(Text)).

expect_no_claim(Text) :-
    math_claim_language:math_claims_in_text(Text, Claims),
    expect_equal(Claims, [], expected_abstention(Text)).

expect_reading(Text, Mode, Commitment, Polarity) :-
    math_claim_language:math_readings_in_text(Text, Readings),
    ( Readings = [Reading|_]
    -> expect_equal(Reading.mode, Mode, reading_mode(Text)),
       expect_equal(Reading.commitment, Commitment, reading_commitment(Text)),
       expect_equal(Reading.polarity, Polarity, reading_polarity(Text))
    ;  throw(error(assertion_failed(expected_reading(Text)), _))
    ).

expect_same_claim(BareText, FramedText) :-
    math_claim_language:math_claims_in_text(BareText, BareClaims),
    math_claim_language:math_claims_in_text(FramedText, FramedClaims),
    expect_equal(FramedClaims, BareClaims, frame_preserves_claim(FramedText)).

expect_argument_roles(Text, ExpectedRoles) :-
    math_claim_language:math_readings_in_text(Text, [Reading]),
    maplist(binding_role, Reading.argument_bindings, Roles),
    expect_equal(Roles, ExpectedRoles, argument_roles(Text)),
    maplist(expect_explicit_binding(Text), Reading.argument_bindings).

binding_role(Binding, Binding.role).

expect_explicit_binding(Text, Binding) :-
    expect_equal(Binding.support, explicit, explicit_argument(Text, Binding.role)),
    ( integer(Binding.token_start),
      integer(Binding.token_end),
      Binding.token_start < Binding.token_end
    -> true
    ;  throw(error(assertion_failed(argument_span(Text, Binding)), _))
    ).

expect_units(Text, ExpectedUnits) :-
    math_claim_language:math_readings_in_text(Text, [Reading]),
    expect_equal(Reading.units, ExpectedUnits, retained_units(Text)).

expect_inferred_percentage(Text) :-
    math_claim_language:math_readings_in_text(Text, [Reading]),
    expect_equal(Reading.inferred_arguments,
                 [argument{role:percent_denominator,
                           value:"100",
                           support:inferred,
                           source_span:none,
                           reason:"percent normalization"}],
                 inferred_percentage_denominator(Text)).

expect_unresolved_referent(Text, Token) :-
    math_claim_language:math_readings_in_text(Text, [Reading]),
    ( member(Referent, Reading.unresolved_referents),
      Referent.token == Token,
      Reading.antecedent_candidates \== []
    -> true
    ;  throw(error(assertion_failed(unresolved_referent(Text, Token, Reading)), _))
    ).

expect_verdict(Text, Expected) :-
    hermes_encyclopedia:ground_query_dict(Text, Grounded),
    ( Grounded.math_claims = [Claim]
    -> expect_equal(Claim.verdict, Expected, claim_verdict(Text))
    ;  throw(error(assertion_failed(expected_one_checked_claim(Text, Grounded.math_claims)), _))
    ).

expect_equal(Actual, Expected, Label) :-
    ( Actual == Expected
    -> true
    ;  throw(error(assertion_failed(Label-expected(Expected)-actual(Actual)), _))
    ).
