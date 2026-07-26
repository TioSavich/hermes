# Gemma 4 E2B interface cycle log

This log records the single `scaffolding_generation` arm and its required
empty-evidence leak probe. Scores are official MathTutorBench reward-model win
rates over the ground-truth teacher response. Reference solutions and
ground-truth teacher responses remain scorer-only data.

## Cycle 1: model-selected machine

### Interface change

The model receives the machine window and must return one
`OPEN family/signature` line. The loop validates that name, opens only the
selected machine's transition table, and gives that table to the model for its
tutor turn.

The leak probe follows the same two-call shape with both the machine window and
opened table replaced by explicit empty markers. A machine name produced during
the probe cannot open a table.

### Prediction written before the run

I expect at least 90% of the main-arm selection replies to name an openable
machine. I expect the official score to land between 0.75 and 0.79, with the
first cycle more likely to match or slightly trail the 0.783 incumbent than to
improve it because one chosen table removes the incumbent's broader assembled
evidence.

I expect the empty-evidence leak probe to score between 0.45 and 0.52, near the
0.458 unassisted floor and at least 0.20 below the main arm. If that separation
does not appear, the machine table is not carrying the result.

The full window is about 12,900 prompt tokens, so I expect mean total model
tokens to rise to roughly 14,000 to 16,000 per item. Even an equal score would
therefore call for topic pruning in the next cycle.

### Run

- Official score: 0.511 over 360 official items
- Official mean margin: 0.353
- Empty-evidence leak-probe score: 0.483
- Empty-evidence mean margin: 0.273
- Main minus empty-evidence score: 0.028
- Mean total model tokens per main item: 15,672
- Mean total model tokens per empty-evidence item: 610
- Main selection open rate: 0.453

### Breaks and fixes

The 232-machine window includes 18 discourse machines, but those machines live
in `knowledge/discourse/commitment_automata.pl` rather than the per-family
transition-table directory. The opener now routes that family explicitly, and
the contract check opens a discourse machine before the run.

The three-item local stub proof completed 12 calls. All three main selections
opened `fraction/unit_fraction_partition`; all three leak-probe selections
opened no machine and supplied zero evidence characters. A sentinel check
confirmed that reference-solution and teacher-response text was absent from
every generation prompt. This was a protocol proof on synthetic items, not a
benchmark run, so it produced no score and no model-token estimate.

The run invalidated the central prediction. Only 45.3% of main-arm selection
replies named an openable machine, against the predicted minimum of 90%, and the
main arm finished only 0.028 above its own empty-evidence probe while using 25.7
times as many tokens. The score was 0.272 below the 0.783 incumbent and only
0.053 above the 0.458 unassisted floor.

The aggregate selection count supports selection failure as the likeliest cause
of the near-probe result: most items opened no table and therefore reached the
tutor turn with an empty evidence channel. The local collection contains only
the aggregate summary. The per-chunk generations remain on Big Red, and this
sandbox could not access the existing SSH control socket, so the reply-level
mix of invalid syntax and unoffered names has not been verified.

### Call

Revert the full-window interface and push further with topic subtraction. Cycle
1 did not show that a selected machine can carry the result because it usually
failed to select one; it did show that placing all 232 machines in front of E2B
is costly and unreliable.

## Cycle 2: negation-first topic slice

### Interface change

The model first names one topic from the index vocabulary, then
`index_query:machines_for_topic/3` removes machines whose recorded topic or
genre evidence rules them out and reports the subtraction reasons. The model
receives only the surviving 8-to-54-machine slice, chooses one machine to open,
and receives that transition table for its tutor turn.

The empty-evidence probe retains the same three-call protocol, but its topic
menu, pruned machine slice, subtraction reasons, and opened table are replaced
by explicit empty markers. Neither the main protocol nor the probe receives the
reference solution or ground-truth teacher response before generation ends.

### Prediction written before the run

I expect at least 90% of main-arm topic replies to name an accepted topic and at
least 85% of all main items to open a machine. The second threshold is the
direct test of the cycle-1 bottleneck: the largest offered slice has 54 machines
rather than 232, and an invalid topic or machine reply does not fall back to the
full window.

I expect the official score to land between 0.58 and 0.68. I expect the
empty-evidence probe to remain between 0.45 and 0.52, with the main arm at least
0.08 higher. This does not predict recovery to the 0.783 incumbent; one table
still carries less evidence than the incumbent's assembled channel.

I expect mean total model tokens for the main arm to fall between 3,000 and
6,000 per item, below 40% of cycle 1, even with the added topic turn. If at least
85% of items open a table but the score remains below 0.58 or separation remains
below 0.08, selection was not the sufficient bottleneck and cycle 3 should move
truth decisions into Prolog rather than tune machine selection again.

### Run

- Official score: pending controller run
- Empty-evidence leak-probe score: pending controller run
- Mean total model tokens per item: pending controller run

### Breaks and fixes

Listing every excluded machine would have replaced the 232-machine window with
196 to 224 repetitive exclusion rows. The renderer groups identical Prolog
reasons and retains their counts, so every exclusion is accounted for in 14 or
15 reason groups while the offered rows remain machine-specific.

The local contract check loaded all 17 topics through
`index_query:machines_for_topic/3`, verified that every subtraction partitions
the same 232-machine corpus, and confirmed slice bounds of 8 to 54. The
three-item fixed-stub proof completed 18 calls: all three main topic replies
were accepted, all three main machine replies opened
`fraction/unit_fraction_partition`, and the three leak-probe items selected no
topic, opened no machine, and received zero evidence characters. Sentinel scans
kept the reference solution and target teacher response outside all generation
prompts. This proof produced no benchmark score or model-token estimate.

### Call

Pending controller run.
