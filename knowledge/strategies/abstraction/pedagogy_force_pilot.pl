:- encoding(utf8).
/** <module> Pedagogy-force funnel pilot
 *
 * This quarantined pilot dispositions the 114 counted instructional frames
 * into the fixed PML force vocabulary. It adds no force term. An unlicensed
 * surface remains unmarked, and every classroom demand retains uptake(open).
 * The experimental PUSU harness imports this store only to classify existing
 * refusals; the store does not change parsing or completion.
 *
 * Check: swipl -q -l paths.pl -l knowledge/strategies/abstraction/pedagogy_force_pilot.pl -g pedagogy_force_pilot:check_pedagogy_force_pilot -t halt
 */
:- module(pedagogy_force_pilot,
          [ frame_force/8,
            sentence_force/3,
            pedagogy_force_pilot_summary/3,
            check_pedagogy_force_pilot/0
          ]).

:- use_module(library(pcre), [re_match/3]).
:- use_module(library(lists), [member/2]).

licensed_force(assert).
licensed_force(avow).
licensed_force(acknowledge).
licensed_force(attribute).
licensed_force(demand).
licensed_force(permit).
licensed_force(question).
licensed_force(unmarked).

licensed_uptake(undertake_commitment).
licensed_uptake(challenge_entitlement).
licensed_uptake(attribute_commitment).
licensed_uptake(acknowledge_commitment).
licensed_uptake(grant_entitlement).
licensed_uptake(open).
licensed_uptake(none).

%! frame_force(?FrameId, ?Pattern, ?Force, ?Position, ?Uptake,
%!             ?Evidence, ?Source, ?Basis) is nondet.
%
%  A counted surface frame and its conservative force disposition. Counts are
%  guide_all numerators from the controller's instructional-structure census.
frame_force(q_notice,
    pattern("What do you notice?"), force(question), position(pos_2s),
    uptake(challenge_entitlement), evidence(counted(718)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_wonder,
    pattern("What do you wonder?"), force(question), position(pos_2s),
    uptake(challenge_entitlement), evidence(counted(534)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_notice_about,
    pattern("What do you notice about {referent}?"), force(question), position(pos_2s),
    uptake(challenge_entitlement), evidence(counted(139)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_patterns,
    pattern("What patterns do you notice/see?"), force(question), position(pos_2s),
    uptake(challenge_entitlement), evidence(counted(102)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_know_about,
    pattern("What do you know about {topic}?"), force(question), position(pos_2s),
    uptake(challenge_entitlement), evidence(counted(284)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_how_many_x,
    pattern("How many {noun} …?"), force(question), position(unmarked),
    uptake(challenge_entitlement), evidence(counted(3438)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_how_many_see,
    pattern("How many do you see?"), force(question), position(pos_2s),
    uptake(challenge_entitlement), evidence(counted(530)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_how_do_you_see,
    pattern("How do you see them?"), force(question), position(pos_2s),
    uptake(challenge_entitlement), evidence(counted(160)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_how_many_in_all,
    pattern("How many … in all / altogether / total?"), force(question), position(unmarked),
    uptake(challenge_entitlement), evidence(counted(95)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_how_many_left,
    pattern("How many … left / remain?"), force(question), position(unmarked),
    uptake(challenge_entitlement), evidence(counted(66)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_how_many_more,
    pattern("How many more / fewer …?"), force(question), position(unmarked),
    uptake(challenge_entitlement), evidence(counted(292)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_how_many_now,
    pattern("How many {noun} … now?"), force(question), position(unmarked),
    uptake(challenge_entitlement), evidence(counted(66)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_how_much_total,
    pattern("How much does {agent} have?"), force(question), position(unmarked),
    uptake(challenge_entitlement), evidence(counted(33)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_what_fraction,
    pattern("What fraction of {whole} …?"), force(question), position(unmarked),
    uptake(challenge_entitlement), evidence(counted(29)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_what_percentage,
    pattern("What percent(age) of {whole} …?"), force(question), position(unmarked),
    uptake(challenge_entitlement), evidence(counted(31)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_value_of,
    pattern("What is the value of {expression}?"), force(question), position(unmarked),
    uptake(challenge_entitlement), evidence(counted(67)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_area_of,
    pattern("What is the area of {figure}?"), force(question), position(unmarked),
    uptake(challenge_entitlement), evidence(counted(38)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_length_of,
    pattern("What is the length/volume/perimeter of {figure}?"), force(question), position(unmarked),
    uptake(challenge_entitlement), evidence(counted(57)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_estimate,
    pattern("What is an estimate that's too high / too low / about right?"), force(question), position(unmarked),
    uptake(challenge_entitlement), evidence(counted(82)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_estimate_less,
    pattern("Is anyone's estimate less than / greater than {n}?"), force(question), position(unmarked),
    uptake(challenge_entitlement), evidence(counted(22)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_which_greater,
    pattern("Which is greater / larger / more?"), force(question), position(unmarked),
    uptake(challenge_entitlement), evidence(counted(139)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_true_or_false,
    pattern("Is this true or false?"), force(question), position(unmarked),
    uptake(challenge_entitlement), evidence(counted(447)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_equation_show,
    pattern("What equation can we write to show {relation}?"), force(question), position(unmarked),
    uptake(challenge_entitlement), evidence(counted(38)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_how_do_you_know,
    pattern("How do you know?"), force(question), position(pos_2s),
    uptake(challenge_entitlement), evidence(counted(388)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_how_did_you,
    pattern("How did you {verb}?"), force(question), position(pos_2s),
    uptake(challenge_entitlement), evidence(counted(857)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_how_can_explain,
    pattern("How can you explain your {thinking}?"), force(question), position(pos_2s),
    uptake(challenge_entitlement), evidence(counted(17)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_why_did_you,
    pattern("Why did you {verb}?"), force(question), position(pos_2s),
    uptake(challenge_entitlement), evidence(counted(55)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_same_about,
    pattern("What is the same about {a} and {b}?"), force(question), position(unmarked),
    uptake(challenge_entitlement), evidence(counted(106)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_how_same_different,
    pattern("How are they the same? How are they different?"), force(question), position(unmarked),
    uptake(challenge_entitlement), evidence(counted(354)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_which_three,
    pattern("Which three go together?"), force(question), position(unmarked),
    uptake(challenge_entitlement), evidence(counted(504)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_common,
    pattern("What do these {items} have in common?"), force(question), position(unmarked),
    uptake(challenge_entitlement), evidence(counted(68)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_who_restate,
    pattern("Who can restate {name}'s reasoning?"), force(question), position(unmarked),
    uptake(challenge_entitlement), evidence(counted(114)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_agree_disagree,
    pattern("Do you agree or disagree?"), force(question), position(pos_2s),
    uptake(challenge_entitlement), evidence(counted(148)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_who_agree_with,
    pattern("Who do you agree with?"), force(question), position(unmarked),
    uptake(challenge_entitlement), evidence(counted(21)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_say_more,
    pattern("Can you say that in another way?"), force(question), position(pos_2s),
    uptake(challenge_entitlement), evidence(counted(11)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_anything_on_this,
    pattern("Is there anything on this {list} you are wondering about?"), force(question), position(unmarked),
    uptake(challenge_entitlement), evidence(counted(0)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_ready_for_more,
    pattern("Are you ready for more?"), force(question), position(pos_2s),
    uptake(challenge_entitlement), evidence(counted(47)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_story_about,
    pattern("What is the story / situation about?"), force(question), position(unmarked),
    uptake(challenge_entitlement), evidence(counted(35)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_behind_my_back,
    pattern("What's behind my back?"), force(question), position(unmarked),
    uptake(challenge_entitlement), evidence(counted(95)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_can_you_draw,
    pattern("Can you draw it?"), force(question), position(pos_2s),
    uptake(challenge_entitlement), evidence(counted(73)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_talk_me_through,
    pattern("Talk / walk me through your solution"), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(0)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(q_tell_me_how_got,
    pattern("Can you tell me how you got your answer?"), force(question), position(pos_2s),
    uptake(challenge_entitlement), evidence(counted(0)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_explain_your,
    pattern("Can you explain your {reasoning/answer}?"), force(question), position(pos_2s),
    uptake(challenge_entitlement), evidence(counted(23)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(q_i_can_see_you,
    pattern("I can see you have {observation}"), force(acknowledge), position(pos_1s),
    uptake(acknowledge_commitment), evidence(counted(0)),
    source(instructional_structure_census),
    basis("The teacher recognizes the addressee's stated observation, licensing acknowledge under PML 2026-06-15:33-34. The commitment action alphabet licenses acknowledge_commitment.")).
frame_force(d_invite_students,
    pattern("Invite students to {verb} …"), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(1516)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_invite_identified,
    pattern("Invite previously identified / selected students to share …"), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(380)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_monitor_for,
    pattern("Monitor for students who {behaviour}"), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(782)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_share_record,
    pattern("Share and record responses / answers."), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(560)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_consider_asking,
    pattern("Consider asking: …"), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(1064)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_ask_students,
    pattern("Ask students to {verb} …"), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(343)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_listen_for,
    pattern("Listen for and clarify any {vocabulary}"), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(76)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_give_signal,
    pattern("Give me a signal when you {have an answer}."), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(291)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_discuss_partner,
    pattern("Discuss your thinking with your partner."), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(471)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_work_with_partner,
    pattern("Work with your partner to {verb} …"), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(260)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_explain_how_got,
    pattern("Explain how you got it / your answer."), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(222)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_explain_or_show,
    pattern("Explain or show your reasoning."), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(413)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_show_thinking,
    pattern("Show your thinking using drawings, numbers, or words."), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(281)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_be_prepared,
    pattern("Be prepared / ready to explain your reasoning."), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(190)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_find_value,
    pattern("Find the value of each {expression}."), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(1110)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_find_value_mentally,
    pattern("Find the value of each expression mentally."), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(218)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_solve_mentally,
    pattern("Solve each equation mentally."), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(0)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_find_number_makes,
    pattern("Find the number that makes the equation true."), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(93)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_long_division,
    pattern("Use long division to find {quotient}."), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(0)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_write_equation,
    pattern("Write an equation to represent {situation}."), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(151)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_write_answer_as,
    pattern("Write your answer as a {fraction/decimal}."), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(1)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_draw_diagram,
    pattern("Draw a diagram / tape diagram / number line to show …"), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(186)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_compare_using,
    pattern("Compare using >, =, or <."), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(11)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_use_representation,
    pattern("Use the {representation} to {verb}."), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(858)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_repeat_with,
    pattern("Repeat with each {item}."), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(370)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_display,
    pattern("Display the {artifact}."), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(1723)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_display_image,
    pattern("Display the image / picture."), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(516)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_keep_displayed,
    pattern("Keep {artifact} displayed."), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(246)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_give_access,
    pattern("Give students access to {material}."), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(411)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_give_each,
    pattern("Give each {group/student} a {material}."), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(644)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_arrange_groups,
    pattern("Arrange students in groups of {n}."), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(72)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_create_set,
    pattern("Create a set of cards."), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(132)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_gather_materials,
    pattern("Gather materials from {previous centers}."), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(192)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_copies_per,
    pattern("1 copy for every {n} students"), force(unmarked), position(unmarked),
    uptake(none), evidence(counted(678)),
    source(instructional_structure_census),
    basis("utterance_layers.pl:53-57 requires an unread force layer to remain unmarked. This staging quantity is a noun phrase, not a force-bearing clause.")).
frame_force(d_read_task,
    pattern("Read the task statement."), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(117)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_center_choice,
    pattern("Invite students to work at the center of their choice."), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(184)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_notice_wonder_routine,
    pattern("Notice and Wonder: {title}"), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(881)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_lets,
    pattern("Let's {verb} …  (hortative, outside the closed imperative lexicon)"), force(demand), position(pos_1p_incl),
    uptake(open), evidence(counted(1918)),
    source(instructional_structure_census),
    basis("Force census section 2 licenses demand and pos_1p_incl for this hortative. PML definition 2026-06-15:33-34 licenses demand; pass-2:110-111 blocks an objective default. The census leaves classroom-demand uptake open.")).
frame_force(d_be_sure,
    pattern("Be sure to {verb} …"), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(148)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(d_choral_count,
    pattern("Choral count by {n}"), force(unmarked), position(unmarked),
    uptake(none), evidence(counted(265)),
    source(instructional_structure_census),
    basis("utterance_layers.pl:53-57 requires an unread force layer to remain unmarked. This routine label does not distinguish a title from a directive.")).
frame_force(s_purpose_lesson,
    pattern("The purpose of this lesson is for students to {verb} …"), force(unmarked), position(unmarked),
    uptake(none), evidence(counted(1798)),
    source(instructional_structure_census),
    basis("utterance_layers.pl:53-57 requires an unread force layer to remain unmarked. This furniture, heading, or narrative frame licenses no force reading.")).
frame_force(s_purpose_activity,
    pattern("The purpose of this activity is {to/for} …"), force(unmarked), position(unmarked),
    uptake(none), evidence(counted(1950)),
    source(instructional_structure_census),
    basis("utterance_layers.pl:53-57 requires an unread force layer to remain unmarked. This furniture, heading, or narrative frame licenses no force reading.")).
frame_force(s_in_this_lesson,
    pattern("In this lesson, students {verb} …"), force(unmarked), position(unmarked),
    uptake(none), evidence(counted(894)),
    source(instructional_structure_census),
    basis("utterance_layers.pl:53-57 requires an unread force layer to remain unmarked. This furniture, heading, or narrative frame licenses no force reading.")).
frame_force(s_time_budget,
    pattern("{n} minutes: {quiet think / partner work} time"), force(unmarked), position(unmarked),
    uptake(none), evidence(counted(5819)),
    source(instructional_structure_census),
    basis("utterance_layers.pl:53-57 requires an unread force layer to remain unmarked. This furniture, heading, or narrative frame licenses no force reading.")).
frame_force(s_access_disabilities,
    pattern("Access for Students with Disabilities"), force(unmarked), position(unmarked),
    uptake(none), evidence(counted(1680)),
    source(instructional_structure_census),
    basis("utterance_layers.pl:53-57 requires an unread force layer to remain unmarked. This furniture, heading, or narrative frame licenses no force reading.")).
frame_force(s_access_language,
    pattern("Access for English Language Learners"), force(unmarked), position(unmarked),
    uptake(none), evidence(counted(1419)),
    source(instructional_structure_census),
    basis("utterance_layers.pl:53-57 requires an unread force layer to remain unmarked. This furniture, heading, or narrative frame licenses no force reading.")).
frame_force(s_supports_accessibility,
    pattern("Supports accessibility for {conceptual processing}"), force(unmarked), position(unmarked),
    uptake(none), evidence(counted(880)),
    source(instructional_structure_census),
    basis("utterance_layers.pl:53-57 requires an unread force layer to remain unmarked. This furniture, heading, or narrative frame licenses no force reading.")).
frame_force(s_responding_thinking,
    pattern("Responding to Student Thinking"), force(unmarked), position(unmarked),
    uptake(none), evidence(counted(612)),
    source(instructional_structure_census),
    basis("utterance_layers.pl:53-57 requires an unread force layer to remain unmarked. This furniture, heading, or narrative frame licenses no force reading.")).
frame_force(s_learning_goals,
    pattern("Student Facing / Teacher Facing Learning Goals"), force(unmarked), position(unmarked),
    uptake(none), evidence(counted(1758)),
    source(instructional_structure_census),
    basis("utterance_layers.pl:53-57 requires an unread force layer to remain unmarked. This furniture, heading, or narrative frame licenses no force reading.")).
frame_force(s_raw_extract,
    pattern("## Full Teacher Guide (raw extract)"), force(unmarked), position(unmarked),
    uptake(none), evidence(counted(879)),
    source(instructional_structure_census),
    basis("utterance_layers.pl:53-57 requires an unread force layer to remain unmarked. This furniture, heading, or narrative frame licenses no force reading.")).
frame_force(s_md_heading,
    pattern("Markdown heading (`## …`)"), force(unmarked), position(unmarked),
    uptake(none), evidence(counted(4389)),
    source(instructional_structure_census),
    basis("utterance_layers.pl:53-57 requires an unread force layer to remain unmarked. This furniture, heading, or narrative frame licenses no force reading.")).
frame_force(s_licence,
    pattern("CC BY NC {year}"), force(unmarked), position(unmarked),
    uptake(none), evidence(counted(6191)),
    source(instructional_structure_census),
    basis("utterance_layers.pl:53-57 requires an unread force layer to remain unmarked. This furniture, heading, or narrative frame licenses no force reading.")).
frame_force(s_sample_response,
    pattern("Sample response(s): {exemplar student answer}"), force(unmarked), position(unmarked),
    uptake(none), evidence(counted(3624)),
    source(instructional_structure_census),
    basis("utterance_layers.pl:53-57 requires an unread force layer to remain unmarked. This furniture, heading, or narrative frame licenses no force reading.")).
frame_force(s_student_response,
    pattern("Student Response(s): {exemplar student answer}"), force(unmarked), position(unmarked),
    uptake(none), evidence(counted(3370)),
    source(instructional_structure_census),
    basis("utterance_layers.pl:53-57 requires an unread force layer to remain unmarked. This furniture, heading, or narrative frame licenses no force reading.")).
frame_force(s_materials_to,
    pattern("Materials to Gather / Materials to Copy"), force(unmarked), position(unmarked),
    uptake(none), evidence(counted(2491)),
    source(instructional_structure_census),
    basis("utterance_layers.pl:53-57 requires an unread force layer to remain unmarked. This furniture, heading, or narrative frame licenses no force reading.")).
frame_force(d_orally_tag,
    pattern("{Verb} (orally) {object}  — modality tag"), force(unmarked), position(unmarked),
    uptake(none), evidence(counted(1324)),
    source(instructional_structure_census),
    basis("utterance_layers.pl:53-57 requires an unread force layer to remain unmarked. The parenthetical marks modality and does not license a force reading.")).
frame_force(q_how_does,
    pattern("How does {a} {relate to} {b}?"), force(question), position(unmarked),
    uptake(challenge_entitlement), evidence(counted(439)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(d_provide_students,
    pattern("Provide students with {material}."), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(138)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(s_if_students,
    pattern("If students {behaviour}, consider {move}."), force(demand), position(pos_2_indef),
    uptake(open), evidence(counted(766)),
    source(instructional_structure_census),
    basis("The imperative licenses demand under the PML definition at 2026-06-15:33-34. Pass-2:110-111 blocks an objective default. The force census leaves classroom-demand uptake open.")).
frame_force(s_mlr_advances,
    pattern("Advances: {language function}"), force(unmarked), position(unmarked),
    uptake(none), evidence(counted(835)),
    source(instructional_structure_census),
    basis("utterance_layers.pl:53-57 requires an unread force layer to remain unmarked. This furniture, heading, or narrative frame licenses no force reading.")).
frame_force(s_mlr_representation,
    pattern("Representation: {support}"), force(unmarked), position(unmarked),
    uptake(none), evidence(counted(324)),
    source(instructional_structure_census),
    basis("utterance_layers.pl:53-57 requires an unread force layer to remain unmarked. This furniture, heading, or narrative frame licenses no force reading.")).
frame_force(s_students_may,
    pattern("Students may / might / will {behaviour}."), force(unmarked), position(unmarked),
    uptake(none), evidence(counted(1386)),
    source(instructional_structure_census),
    basis("utterance_layers.pl:53-57 requires an unread force layer to remain unmarked. This combined frame mixes permission, possibility, and prediction, so it licenses no single force.")).
frame_force(p_each_has,
    pattern("Each {kind} has {n} {kind}."), force(assert), position(pos_3_generic),
    uptake(undertake_commitment), evidence(counted(216)),
    source(instructional_structure_census),
    basis("The declarative existence or possession form licenses assert under PML 2026-06-15:33-34. utterance_layers.pl maps assertion uptake to undertake_commitment.")).
frame_force(p_there_are,
    pattern("There are {n} {kind}."), force(assert), position(pos_3_generic),
    uptake(undertake_commitment), evidence(counted(1207)),
    source(instructional_structure_census),
    basis("The declarative existence or possession form licenses assert under PML 2026-06-15:33-34. utterance_layers.pl maps assertion uptake to undertake_commitment.")).
frame_force(p_at_this_rate,
    pattern("At this rate, {question}"), force(unmarked), position(unmarked),
    uptake(none), evidence(counted(2)),
    source(instructional_structure_census),
    basis("utterance_layers.pl:53-57 requires an unread force layer to remain unmarked. This prepositional container does not carry the embedded question's force.")).
frame_force(p_per_unit,
    pattern("{n} {unit} per {unit}"), force(unmarked), position(unmarked),
    uptake(none), evidence(counted(65)),
    source(instructional_structure_census),
    basis("utterance_layers.pl:53-57 requires an unread force layer to remain unmarked. This ratio fragment carries content but no force-bearing clause.")).
frame_force(p_if_then_many,
    pattern("If {condition}, how many {kind}?"), force(question), position(unmarked),
    uptake(challenge_entitlement), evidence(counted(45)),
    source(instructional_structure_census),
    basis("The interrogative form licenses question under PML 2026-06-15:33-34 and its genuine-question rule at 63-64. utterance_layers.pl maps question uptake to challenge_entitlement.")).
frame_force(p_times_as_many,
    pattern("{n} times as many / as much as"), force(unmarked), position(unmarked),
    uptake(none), evidence(counted(258)),
    source(instructional_structure_census),
    basis("utterance_layers.pl:53-57 requires an unread force layer to remain unmarked. This comparison fragment carries content but no force-bearing clause.")).
frame_force(p_altogether,
    pattern("… altogether / in all"), force(unmarked), position(unmarked),
    uptake(none), evidence(counted(294)),
    source(instructional_structure_census),
    basis("utterance_layers.pl:53-57 requires an unread force layer to remain unmarked. This lexical fragment occurs across questions and statements and licenses no single force.")).
frame_force(p_share_equally,
    pattern("share equally / split evenly among {n}"), force(unmarked), position(unmarked),
    uptake(none), evidence(counted(36)),
    source(instructional_structure_census),
    basis("utterance_layers.pl:53-57 requires an unread force layer to remain unmarked. This broad surface occurs in directives and narrative clauses and licenses no single force.")).

% PCRE patterns are the counted patterns used by the controller's census.
frame_regex(q_notice, "(?i)\\bwhat do you notice\\b").
frame_regex(q_wonder, "(?i)\\bwhat do you wonder\\b").
frame_regex(q_notice_about, "(?i)\\bwhat do you notice about\\b").
frame_regex(q_patterns, "(?i)\\bwhat patterns? do you (?:notice|see)\\b").
frame_regex(q_know_about, "(?i)\\bwhat do you know about\\b").
frame_regex(q_how_many_x, "(?i)\\bhow many [a-z]").
frame_regex(q_how_many_see, "(?i)\\bhow many do you see\\b").
frame_regex(q_how_do_you_see, "(?i)\\bhow do you see (?:them|it)\\b").
frame_regex(q_how_many_in_all, "(?i)\\bhow (?:many|much)\\b[^?]{0,60}\\b(?:in all|altogether|in total)\\b").
frame_regex(q_how_many_left, "(?i)\\bhow (?:many|much)\\b[^?]{0,50}\\b(?:left|remain|still)\\b").
frame_regex(q_how_many_more, "(?i)\\bhow (?:many|much) (?:more|fewer|less|longer|farther)\\b").
frame_regex(q_how_many_now, "(?i)\\bhow many\\b[^?]{0,60}\\bnow\\b[^?]{0,20}\\?").
frame_regex(q_how_much_total, "(?i)\\bhow much (?:does|do|did|will|would)\\b").
frame_regex(q_what_fraction, "(?i)\\bwhat fraction of\\b").
frame_regex(q_what_percentage, "(?i)\\bwhat percent(?:age)? (?:of|is)\\b").
frame_regex(q_value_of, "(?i)\\bwhat(?:'s|’s| is) the value of\\b").
frame_regex(q_area_of, "(?i)\\bwhat(?:'s|’s| is) the area of\\b").
frame_regex(q_length_of, "(?i)\\bwhat(?:'s|’s| is) the (?:length|volume|perimeter|width|height|weight) of\\b").
frame_regex(q_estimate, "(?i)\\bwhat(?:'s|’s| is) an estimate\\b").
frame_regex(q_estimate_less, "(?i)\\bis anyone(?:'s|’s) estimate (?:less|greater|more|too)\\b").
frame_regex(q_which_greater, "(?i)\\bwhich (?:is|one is|number is|expression is)\\b[^?]{0,30}(?:greater|larger|more|bigger|smaller|less)").
frame_regex(q_true_or_false, "(?i)\\btrue or false\\b").
frame_regex(q_equation_show, "(?i)\\bwhat equation\\b").
frame_regex(q_how_do_you_know, "(?i)\\bhow do you know\\b").
frame_regex(q_how_did_you, "(?i)\\bhow did you\\b").
frame_regex(q_how_can_explain, "(?i)\\bhow can you explain your\\b").
frame_regex(q_why_did_you, "(?i)\\bwhy did you\\b").
frame_regex(q_same_about, "(?i)\\bwhat(?:'s|’s| is| are)? the same about\\b").
frame_regex(q_how_same_different, "(?i)\\bhow are (?:they|these|the)\\b[^?]{0,60}(?:same|different)").
frame_regex(q_which_three, "(?i)\\bwhich (?:three|3) go together\\b").
frame_regex(q_common, "(?i)\\bhave in common\\b").
frame_regex(q_who_restate, "(?i)\\bwho can restate\\b").
frame_regex(q_agree_disagree, "(?i)\\bdo you agree\\b").
frame_regex(q_who_agree_with, "(?i)\\bwho do you agree with\\b").
frame_regex(q_say_more, "(?i)\\bcan you say (?:that|more|it)\\b").
frame_regex(q_anything_on_this, "(?i)\\bis there anything on this\\b").
frame_regex(q_ready_for_more, "(?i)\\bare you ready for more\\b").
frame_regex(q_story_about, "(?i)\\bwhat is (?:the story|this situation|this problem) about\\b").
frame_regex(q_behind_my_back, "(?i)\\bbehind my back\\b").
frame_regex(q_can_you_draw, "(?i)\\bcan you draw it\\b").
frame_regex(q_talk_me_through, "(?i)\\b(?:talk|walk) me through\\b").
frame_regex(q_tell_me_how_got, "(?i)\\btell me how you got\\b").
frame_regex(q_explain_your, "(?i)\\b(?:can|could) you (?:please )?explain your\\b").
frame_regex(q_i_can_see_you, "(?i)\\bi can see you\\b").
frame_regex(d_invite_students, "(?i)\\binvite students to\\b").
frame_regex(d_invite_identified, "(?i)\\binvite previously (?:identified|selected) students\\b").
frame_regex(d_monitor_for, "(?i)\\bmonitor for students who\\b").
frame_regex(d_share_record, "(?i)\\bshare and record\\b").
frame_regex(d_consider_asking, "(?i)\\bconsider asking\\b").
frame_regex(d_ask_students, "(?i)\\bask students to\\b").
frame_regex(d_listen_for, "(?i)\\blisten for and clarify\\b").
frame_regex(d_give_signal, "(?i)\\bgive me a signal when\\b").
frame_regex(d_discuss_partner, "(?i)\\bdiscuss your thinking with\\b").
frame_regex(d_work_with_partner, "(?i)\\bwork with your partner to\\b").
frame_regex(d_explain_how_got, "(?i)\\bexplain how you got\\b").
frame_regex(d_explain_or_show, "(?i)\\bexplain or show your\\b").
frame_regex(d_show_thinking, "(?i)\\bshow your thinking using\\b").
frame_regex(d_be_prepared, "(?i)\\bbe (?:prepared|ready) to explain\\b").
frame_regex(d_find_value, "(?i)\\bfind the value of\\b").
frame_regex(d_find_value_mentally, "(?i)\\bvalue of each (?:expression|sum|difference|product|quotient)\\b[^.]{0,12}mentally").
frame_regex(d_solve_mentally, "(?i)\\bsolve each equation mentally\\b").
frame_regex(d_find_number_makes, "(?i)\\bfind the number that makes\\b").
frame_regex(d_long_division, "(?i)\\buse long division to\\b").
frame_regex(d_write_equation, "(?i)\\bwrite an equation\\b").
frame_regex(d_write_answer_as, "(?i)\\bwrite your answer as a\\b").
frame_regex(d_draw_diagram, "(?i)\\bdraw a (?:diagram|picture|number line|tape diagram)\\b").
frame_regex(d_compare_using, "(?i)\\bcompare\\b[^.?]{0,40}(?:>|<|greater than|less than)").
frame_regex(d_use_representation, "(?i)\\buse the\\b[^.?]{0,40}\\bto\\b").
frame_regex(d_repeat_with, "(?i)\\brepeat with\\b").
frame_regex(d_display, "(?i)\\bdisplay the\\b").
frame_regex(d_display_image, "(?i)\\bdisplay the (?:image|picture)\\b").
frame_regex(d_keep_displayed, "(?i)\\bkeep\\b[^.]{0,40}\\bdisplayed\\b").
frame_regex(d_give_access, "(?i)\\bgive students access to\\b").
frame_regex(d_give_each, "(?i)\\bgive each (?:group|student|pair|partner)\\b").
frame_regex(d_arrange_groups, "(?i)\\barrange students in groups of\\b").
frame_regex(d_create_set, "(?i)\\bcreate a set of\\b").
frame_regex(d_gather_materials, "(?i)\\bgather materials\\b").
frame_regex(d_copies_per, "(?i)\\b\\d+ cop(?:y|ies) for every\\b").
frame_regex(d_read_task, "(?i)\\bread the task statement\\b").
frame_regex(d_center_choice, "(?i)\\bcenter of their choice\\b").
frame_regex(d_notice_wonder_routine, "(?i)\\bnotice and wonder\\b").
frame_regex(d_lets, "(?i)^\\s*let(?:'|’)s ").
frame_regex(d_be_sure, "(?i)^(?:be|make) sure\\b").
frame_regex(d_choral_count, "(?i)\\bchoral count\\b").
frame_regex(s_purpose_lesson, "(?i)\\bpurpose of this lesson is\\b").
frame_regex(s_purpose_activity, "(?i)\\bpurpose of this (?:activity|warm)\\b").
frame_regex(s_in_this_lesson, "(?i)\\bin this (?:lesson|activity),? students\\b").
frame_regex(s_time_budget, "(?i)\\b\\d+(?:\\s*[‒–-]\\s*\\d+)?\\s*(?:minutes?|seconds?)\\s*:?\\s*(?:quiet think|independent work|partner (?:work|discussion)|(?:small.)?group work)").
frame_regex(s_access_disabilities, "(?i)\\baccess for students with disabilities\\b").
frame_regex(s_access_language, "(?i)\\baccess for english (?:language )?learners\\b").
frame_regex(s_supports_accessibility, "(?i)\\bsupports accessibility for\\b").
frame_regex(s_responding_thinking, "(?i)\\bresponding to student thinking\\b").
frame_regex(s_learning_goals, "(?i)\\b(?:student|teacher).facing learning goals\\b").
frame_regex(s_raw_extract, "(?i)full teacher guide \\(raw extract\\)").
frame_regex(s_md_heading, "^#{1,6} ").
frame_regex(s_licence, "(?i)\\bcc by.nc\\b").
frame_regex(s_sample_response, "(?i)^sample responses?\\b").
frame_regex(s_student_response, "(?i)^student responses?\\b").
frame_regex(s_materials_to, "(?i)^materials to (?:gather|copy)\\b").
frame_regex(d_orally_tag, "(?i)\\(orally\\)").
frame_regex(q_how_does, "(?i)\\bhow does\\b").
frame_regex(d_provide_students, "(?i)\\bprovide students with\\b").
frame_regex(s_if_students, "(?i)^if students\\b").
frame_regex(s_mlr_advances, "(?i)^advances?:").
frame_regex(s_mlr_representation, "(?i)^representation:").
frame_regex(s_students_may, "(?i)^students (?:may|might|will|should)\\b").
frame_regex(p_each_has, "(?i)\\beach [a-z]+ (?:has|holds|contains|weighs|costs)\\b").
frame_regex(p_there_are, "(?i)\\bthere (?:are|were) \\d+\\b").
frame_regex(p_at_this_rate, "(?i)\\bat this rate\\b").
frame_regex(p_per_unit, "(?i)\\b\\d+ [a-z]+ per [a-z]+\\b").
frame_regex(p_if_then_many, "(?i)^if\\b[^?]{0,80}\\bhow (?:many|much)\\b").
frame_regex(p_times_as_many, "(?i)\\btimes as (?:many|much|long|fast)\\b").
frame_regex(p_altogether, "(?i)\\b(?:altogether|in all)\\b").
frame_regex(p_share_equally, "(?i)\\b(?:share|shares|shared|split|divide[sd]?) (?:them |it |the [a-z]+ )?(?:equally|evenly)\\b").

%! sentence_force(+Text, -Force, -FrameId) is semidet.
%
%  Match a counted frame and return its stored force. Fact order is the census
%  order, so overlapping specific and broad frames remain deterministic.
sentence_force(Text, Force, FrameId) :-
    once((frame_regex(FrameId, Regex),
          re_match(Regex, Text, []),
          frame_force(FrameId, _, force(Force), _, _, _, _, _))).

pedagogy_force_pilot_summary(frames(114),
    dispositions([assert(2), avow(0),
                  acknowledge(1), attribute(0),
                  demand(41), permit(0),
                  question(44), unmarked(26)]),
    status(orphan_from_production)).

%! check_pedagogy_force_pilot is det.
%
%  Check one disposition and one counted matcher per census frame, the closed
%  force set, licensed uptake values, count pins, summary totals, and the two
%  owner-specified conservative readings.
check_pedagogy_force_pilot :-
    findall(Id, frame_force(Id, _, _, _, _, _, _, _), Ids),
    length(Ids, 114),
    sort(Ids, UniqueIds), length(UniqueIds, 114),
    findall(Id, frame_regex(Id, _), RegexIds),
    msort(Ids, SortedIds), msort(RegexIds, SortedIds),
    forall(frame_force(Id, pattern(Pattern), force(Force), position(_),
                       uptake(Uptake), evidence(counted(Count)),
                       source(instructional_structure_census), basis(Basis)),
           ( licensed_force(Force), licensed_uptake(Uptake),
             string(Pattern), string(Basis), Basis \== "",
             expected_count(Id, Count) )),
    pedagogy_force_pilot_summary(frames(114), dispositions(Disposition),
                                 status(orphan_from_production)),
    findall(Name-Count,
            ( member(Name, [assert,avow,acknowledge,attribute,demand,permit,question,unmarked]),
              findall(Id, frame_force(Id, _, force(Name), _, _, _, _, _), ForceIds),
              length(ForceIds, Count) ),
            ActualDisposition),
    summary_pairs(Disposition, SummaryDisposition),
    ActualDisposition == SummaryDisposition,
    frame_force(d_lets, _, force(demand), position(pos_1p_incl),
                uptake(open), evidence(counted(1918)), _, _),
    forall(frame_force(_, _, force(demand), _, Uptake, _, _, _),
           Uptake == uptake(open)),
    sentence_force("Let’s compare the two methods.", demand, d_lets),
    sentence_force("How many dots are there?", question, _),
    format("check_pedagogy_force_pilot: 114 frames, closed force set, counts pinned~n").

summary_pairs([], []).
summary_pairs([Term|Terms], [Name-Count|Pairs]) :-
    Term =.. [Name, Count],
    summary_pairs(Terms, Pairs).

expected_count(q_notice, 718).
expected_count(q_wonder, 534).
expected_count(q_notice_about, 139).
expected_count(q_patterns, 102).
expected_count(q_know_about, 284).
expected_count(q_how_many_x, 3438).
expected_count(q_how_many_see, 530).
expected_count(q_how_do_you_see, 160).
expected_count(q_how_many_in_all, 95).
expected_count(q_how_many_left, 66).
expected_count(q_how_many_more, 292).
expected_count(q_how_many_now, 66).
expected_count(q_how_much_total, 33).
expected_count(q_what_fraction, 29).
expected_count(q_what_percentage, 31).
expected_count(q_value_of, 67).
expected_count(q_area_of, 38).
expected_count(q_length_of, 57).
expected_count(q_estimate, 82).
expected_count(q_estimate_less, 22).
expected_count(q_which_greater, 139).
expected_count(q_true_or_false, 447).
expected_count(q_equation_show, 38).
expected_count(q_how_do_you_know, 388).
expected_count(q_how_did_you, 857).
expected_count(q_how_can_explain, 17).
expected_count(q_why_did_you, 55).
expected_count(q_same_about, 106).
expected_count(q_how_same_different, 354).
expected_count(q_which_three, 504).
expected_count(q_common, 68).
expected_count(q_who_restate, 114).
expected_count(q_agree_disagree, 148).
expected_count(q_who_agree_with, 21).
expected_count(q_say_more, 11).
expected_count(q_anything_on_this, 0).
expected_count(q_ready_for_more, 47).
expected_count(q_story_about, 35).
expected_count(q_behind_my_back, 95).
expected_count(q_can_you_draw, 73).
expected_count(q_talk_me_through, 0).
expected_count(q_tell_me_how_got, 0).
expected_count(q_explain_your, 23).
expected_count(q_i_can_see_you, 0).
expected_count(d_invite_students, 1516).
expected_count(d_invite_identified, 380).
expected_count(d_monitor_for, 782).
expected_count(d_share_record, 560).
expected_count(d_consider_asking, 1064).
expected_count(d_ask_students, 343).
expected_count(d_listen_for, 76).
expected_count(d_give_signal, 291).
expected_count(d_discuss_partner, 471).
expected_count(d_work_with_partner, 260).
expected_count(d_explain_how_got, 222).
expected_count(d_explain_or_show, 413).
expected_count(d_show_thinking, 281).
expected_count(d_be_prepared, 190).
expected_count(d_find_value, 1110).
expected_count(d_find_value_mentally, 218).
expected_count(d_solve_mentally, 0).
expected_count(d_find_number_makes, 93).
expected_count(d_long_division, 0).
expected_count(d_write_equation, 151).
expected_count(d_write_answer_as, 1).
expected_count(d_draw_diagram, 186).
expected_count(d_compare_using, 11).
expected_count(d_use_representation, 858).
expected_count(d_repeat_with, 370).
expected_count(d_display, 1723).
expected_count(d_display_image, 516).
expected_count(d_keep_displayed, 246).
expected_count(d_give_access, 411).
expected_count(d_give_each, 644).
expected_count(d_arrange_groups, 72).
expected_count(d_create_set, 132).
expected_count(d_gather_materials, 192).
expected_count(d_copies_per, 678).
expected_count(d_read_task, 117).
expected_count(d_center_choice, 184).
expected_count(d_notice_wonder_routine, 881).
expected_count(d_lets, 1918).
expected_count(d_be_sure, 148).
expected_count(d_choral_count, 265).
expected_count(s_purpose_lesson, 1798).
expected_count(s_purpose_activity, 1950).
expected_count(s_in_this_lesson, 894).
expected_count(s_time_budget, 5819).
expected_count(s_access_disabilities, 1680).
expected_count(s_access_language, 1419).
expected_count(s_supports_accessibility, 880).
expected_count(s_responding_thinking, 612).
expected_count(s_learning_goals, 1758).
expected_count(s_raw_extract, 879).
expected_count(s_md_heading, 4389).
expected_count(s_licence, 6191).
expected_count(s_sample_response, 3624).
expected_count(s_student_response, 3370).
expected_count(s_materials_to, 2491).
expected_count(d_orally_tag, 1324).
expected_count(q_how_does, 439).
expected_count(d_provide_students, 138).
expected_count(s_if_students, 766).
expected_count(s_mlr_advances, 835).
expected_count(s_mlr_representation, 324).
expected_count(s_students_may, 1386).
expected_count(p_each_has, 216).
expected_count(p_there_are, 1207).
expected_count(p_at_this_rate, 2).
expected_count(p_per_unit, 65).
expected_count(p_if_then_many, 45).
expected_count(p_times_as_many, 258).
expected_count(p_altogether, 294).
expected_count(p_share_equally, 36).
