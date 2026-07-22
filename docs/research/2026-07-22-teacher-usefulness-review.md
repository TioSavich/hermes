# Teacher usefulness review

## Review basis

This review follows the shipped first-session surfaces for a second-grade
teacher with eleven free minutes: console, transcript handoff, lesson context,
monitoring chart, and classroom carry-out. It is a source-and-route review.
The local browser connection was unavailable in this environment, so claims
about visible states are tied to the rendered HTML and client behavior rather
than an interactive recording.

## First-session path: ranked user-loss risks

1. **The lesson-monitoring destination is not a first-session path.** The
   console initially exposes only `Workspace`; `Encyclopedia` and `Ask Hermes`
   are hidden as advanced tabs, and no monitoring destination is present in
   that navigation ([console.html:471-477](../../hermes/app/web/console.html#L471-L477)). A
   teacher must first know to load the lesson catalog, open a lesson, then use
   a link that opens a separate page and says to enter the code again
   ([console.html:1373-1384](../../hermes/app/web/console.html#L1373-L1384),
   [console.html:1412-1415](../../hermes/app/web/console.html#L1412-L1415)).
   The chart page defaults to a different lesson and requires a manual code
   entry and a second click ([monitoring_chart.html:113-115](../../hermes/web/monitoring_chart.html#L113-L115)).
   This is the most likely point of abandonment for someone preparing tomorrow.

2. **The chart can silently become the wrong lesson's chart after a loading
   failure.** When the live request fails, the chart keeps showing the prior
   chart (initially the static `IM-G2-U2-L2` page) while reporting that the
   requested lesson could not load ([monitoring_chart.html:674-699](../../hermes/web/monitoring_chart.html#L674-L699)).
   That preserves a usable demo but is unsafe as a time-pressured preparation
   surface: the visible content is not clearly quarantined from the requested
   lesson. The monitoring endpoint itself returns whatever the worker provides
   without a teacher-facing coverage guard ([monitoring.py:32-37](../../hermes/app/routes/monitoring.py#L32-L37)).

3. **Coverage gaps arrive after navigation, not before commitment.** A selected
   lesson can be only a scope-sequence marker with no authored strategies or
   misconceptions ([console.html:2684-2703](../../hermes/app/web/console.html#L2684-L2703)).
   The catalog labels lessons as `ready`, `usable`, or `thin` and reports
   system counts such as “need work,” which makes the teacher interpret
   repository coverage before getting classroom help
   ([console.html:1240-1249](../../hermes/app/web/console.html#L1240-L1249),
   [console.html:1270-1283](../../hermes/app/web/console.html#L1270-L1283)).

4. **The transcript path splits the teacher's work across two different tools.**
   Workspace promises local pairing, but moves a claim-check report to
   `Discussions` ([console.html:515-526](../../hermes/app/web/console.html#L515-L526)).
   The handoff succeeds only by browser session storage and then asks the
   teacher to press a second action ([console.html:1001-1013](../../hermes/app/web/console.html#L1001-L1013),
   [discussions.html:392-400](../../hermes/app/web/discussions.html#L392-L400)).
   The second page says a live report needs the campus connection
   ([discussions.html:139-144](../../hermes/app/web/discussions.html#L139-L144)).
   The result is a wall precisely after a teacher has invested time preparing
   the text.

5. **Research vocabulary appears before a classroom purpose is established.**
   The default workspace calls its calculator “The Hermeneutic Calculator” and
   asks the user to choose a “strategy machine”
   ([console.html:540-559](../../hermes/app/web/console.html#L540-L559)).
   Lesson detail then exposes “inferential-strength measures,” incompatibility
   breadth, a graph, grounding breaks, and raw context
   ([console.html:1422-1430](../../hermes/app/web/console.html#L1422-L1430)).
   These are defensible research surfaces, but they do not answer “what do I
   listen for tomorrow?” and force a novice to sort the product's audiences.

6. **The first useful transcript action is named for a scheduling algorithm,
   not a teaching decision.** “Analyze & pair” returns dyad scores, a speaker
   graph, and a lengthy caution about discourse markers
   ([console.html:955-974](../../hermes/app/web/console.html#L955-L974)).
   It offers pair suggestions but no next question, discussion sequence, or
   small-group action. For a teacher arriving with a transcript, the output is
   evidence about relationships rather than an immediate move.

7. **Some waiting states are good; the ones that matter most still lack a
   bounded promise.** Workspace says “reading locally…” and the catalog says
   “loading lesson context…” ([console.html:976-997](../../hermes/app/web/console.html#L976-L997),
   [console.html:1373-1382](../../hermes/app/web/console.html#L1373-L1382)).
   The report page is clearer—“extracting claims, checking each one, reading
   the moves…”—but does not state whether the campus/key prerequisite has
   already been met before the teacher starts
   ([discussions.html:505-531](../../hermes/app/web/discussions.html#L505-L531)).
   This is a moderate risk, not the primary defect.

8. **The classroom output has no explicit carry-out action.** The report is a
   long on-screen analysis with claim tables, conflicts, repairs, caveats, and
   machine-detail disclosure; it supplies neither print nor download control
   ([discussions.html:429-458](../../hermes/app/web/discussions.html#L429-L458)).
   The monitoring page has print CSS, but no named Print button; the teacher
   must discover the browser print command ([monitoring_chart.html:87-95](../../hermes/web/monitoring_chart.html#L87-L95)).

9. **The console contains dead monitoring-print wiring.** Its script registers
   a monitoring load and print action ([console.html:2706-2727](../../hermes/app/web/console.html#L2706-L2727)),
   but the console has no `mc-out`, `mc-print`, `mc-load`, or `lesson-code`
   element. This does not itself block the external chart, but it shows that
   the intended single-page classroom path was removed without removing or
   replacing its interaction.

10. **The advanced/research boundary is conceptually present but operationally
    porous.** The source says PML scoring and the class workflow should be out
    of the default teacher view ([console.html:86-94](../../hermes/app/web/console.html#L86-L94)),
    yet the default Workspace still contains the named calculator and the
    public lesson detail opens research measures. The boundary needs to be
    based on the teacher's job, not merely a toggle.

## Five highest slickness-per-effort changes

1. **Add a “Plan tomorrow’s lesson” primary action on the console.** Put a
   lesson-code search beside the landing action, preserve the selected code,
   and open the matching chart in the same tab. Do not make the teacher pass
   through catalog status cards or retype the code. If coverage is thin, say
   that before opening: “Hermes has the lesson goal but not enough monitored
   approaches yet. Try these nearby prepared lessons: …”.

2. **Turn the monitoring output into a one-page “Tomorrow card” and give it a
   visible `Print / save PDF` action.** The card should contain only: lesson
   goal; task in one sentence; 2–3 approaches to listen for; the corresponding
   visual or representation; one likely trouble spot; one assess question; and
   one advance question. Place provenance and research detail behind
   “Sources and details.” On live failure, replace the card with an error
   panel; never leave a prior lesson's card in place.

3. **Make the transcript result a teacher-move sheet.** Keep pairs as a
   secondary section, but lead with “Try next,” e.g. a proposed grouping,
   one question to ask, and the claim or utterance that prompted it. Make
   “Build a discussion report” a clearly marked optional next step with a
   preflight message: “Needs campus connection; your transcript will be
   pseudonymized before analysis.”

4. **Replace research labels in practice paths.** Rename “The Hermeneutic
   Calculator” to “Work through a math strategy”; rename “strategy machine”
   to “method to show”; remove score numbers from the initial pairing display;
   change `ready / usable / thin` to “prepared for classroom use / partial
   notes / not prepared yet.” The existing formal labels can remain in
   research view.

5. **Remove the broken in-console monitoring code or restore its UI.** The
   smaller, safer change is deletion of the orphaned `mc-*` handlers. The
   higher value follow-up is to restore those controls as the first change
   above, so the console owns one consistent plan-and-print route.

## Remove from the teacher-facing surface

Move these items behind a clearly labeled Research view; do not make teachers
decide whether they matter before they can plan instruction.

- “Hermeneutic,” PML/modal-posture language, and the Gemma A–E class workflow.
- Inferential-strength counts, incompatibility breadth tallies and graph,
  grounding/metaphor-break material, raw context, and machine detail.
- Catalog health accounting (“encoded,” “fully connected,” “usable,” “need
  work”) except for a brief, actionable coverage notice on the selected lesson.
- The visible calculator as a landing-card feature. It is a useful demonstrator,
  but it competes with the actual teacher job of planning a lesson or responding
  to student thinking.

## What a teacher would carry tomorrow

The plausible artifact is a single lesson-specific monitoring card: the task
and goal, three anticipated approaches with “listen for” cues, one likely
wrong turn, two questions, and one usable visual. The underlying monitoring
page already contains task/goal, strategy cues/questions, and generated
strategy/error filmstrips ([monitoring_chart.html:130-162](../../hermes/web/monitoring_chart.html#L130-L162)).

What prevents it from being that artifact now is not a missing Prolog export.
It is product assembly: the chart is hard to reach, requires code re-entry,
may retain a different lesson on failure, mixes classroom material with a
large visualizer and research sections, and has no explicit print/save action.
The report path has the opposite problem: it produces a rich post-hoc analysis
but no one-page action sheet. Build the monitoring card first; then let a
transcript produce the same card format with its suggested question grounded
in the submitted discussion.

## Completion ranking

1. Direct lesson-to-card route with preserved lesson code.
2. Correct-lesson-only chart loading and explicit thin-coverage fallback.
3. One-page monitoring card with visible Print / save PDF.
4. Transcript output led by a next teaching move.
5. Remove research vocabulary and orphaned monitoring wiring from practice paths.

REVIEW_COMPLETE
