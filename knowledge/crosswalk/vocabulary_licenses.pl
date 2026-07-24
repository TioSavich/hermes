/** <module> vocabulary_licenses -- E343 cross-framework term substitution licenses
 *
 * Transcribes the owner-authored 79-entry vocabulary crosswalk
 * (/Users/tio/Documents/GitHub/Math-Methods/vocabulary_crosswalk_expanded.json,
 * a READ-ONLY sibling repository) into flat, queryable Prolog facts. Six
 * frameworks per entry: Van de Walle, Indiana Academic Standards, CCSS,
 * Illustrative Mathematics, Five Practices (Smith & Stein), and CDM/Talk
 * Moves (Chapin). The source's own confusion_risk field is the design
 * center: it records where frameworks name the same concept transparently
 * (LOW/MEDIUM) versus where the same word covers different things, or
 * different words cover the same thing, in ways that mislead students
 * (HIGH).
 *
 * vocabulary_license(ConceptId, Framework, Term, Risk, LicenseKind,
 * provenance(EntryIndex, SourceFile, SourceVersion)) records, per entry per
 * framework, the framework's own term (or its "no term here" placeholder,
 * preserved verbatim either way) and a LicenseKind classification:
 *
 *   - substitutable_in_context : the entry's risk is LOW or MEDIUM and this
 *     framework names a term. The source data licenses bounded
 *     intersubstitution with the other addressed frameworks in the same
 *     entry; this module records that license, it does not perform any
 *     substitution.
 *   - disambiguation_required : the entry's risk is HIGH -- same word for
 *     different things, or different words for the same thing, in ways the
 *     source found likely to confuse students. These are disambiguation
 *     obligations, never synonym licenses, in any consumer.
 *   - not_addressed : this framework's cell names no term of its own for
 *     the concept. A fixed set of source-literal disclaimer markers ("not
 *     addressed", "not named", "not specified", and similar; see
 *     scripts/checks/vocabulary_licenses.py for the exact list) decides
 *     this mechanically. That check re-derives the classification from the
 *     source JSON on every run rather than trusting this file once written.
 *
 * vocabulary_license_concept/3 and vocabulary_license_note/2 keep the
 * entry's own concept description and note VERBATIM. The note carries the
 * pedagogical reasoning the crosswalk's author wrote; it is not paraphrased
 * here. vocabulary_license_source/3 names the transcribed file, its
 * version, and its date once.
 *
 * Boundary (quarantine): every fact here is data about a curriculum
 * vocabulary crosswalk that the reader and recognizers do not consult.
 * Nothing in this module is imported by hermes_worker.pl, the reader, or
 * any automaton. Wiring a substitutable_in_context license into an actual
 * term substitution anywhere -- the reader's grammar, a recognizer's label
 * matching, a misconception mapping -- is a formal-core change out of
 * scope here and needs its own reviewed slice. A disambiguation_required
 * entry must never become a synonym expansion in any consumer, present or
 * future.
 */
:- module(vocabulary_licenses,
          [ vocabulary_license/6,
            vocabulary_license_note/2,
            vocabulary_license_concept/3,
            vocabulary_license_source/3
          ]).


% vocabulary_license_source(SourceFile, Version, Date).
vocabulary_license_source('vocabulary_crosswalk_expanded.json', "2.0", "2026-03-31").

% vocabulary_license_concept(ConceptId, EntryIndex, ConceptText).
vocabulary_license_concept(vl001, 1, "Addition problem where something is added to an initial quantity").
vocabulary_license_concept(vl002, 2, "Subtraction problem where something is removed").
vocabulary_license_concept(vl003, 3, "Two parts combine into a whole (or whole decomposed into parts)").
vocabulary_license_concept(vl004, 4, "Two quantities compared to find the difference").
vocabulary_license_concept(vl005, 5, "Division where the number of groups is known, find group size").
vocabulary_license_concept(vl006, 6, "Division where group size is known, find number of groups").
vocabulary_license_concept(vl007, 7, "Knowing single-digit facts automatically").
vocabulary_license_concept(vl008, 8, "Using strategies rather than rote recall for facts").
vocabulary_license_concept(vl009, 9, "Multiplication with arrays and equal groups").
vocabulary_license_concept(vl010, 10, "Teacher orchestrates whole-class discussion of student work").
vocabulary_license_concept(vl011, 11, "Teacher circulates during student work time to understand thinking").
vocabulary_license_concept(vl012, 12, "Choosing tasks that require genuine mathematical thinking").
vocabulary_license_concept(vl013, 13, "Three-phase lesson structure for problem-based instruction").
vocabulary_license_concept(vl014, 14, "The quantity that a fraction refers to").
vocabulary_license_concept(vl015, 15, "Building fractions by repeating a unit fraction").
vocabulary_license_concept(vl016, 16, "Teacher questions that surface current student thinking").
vocabulary_license_concept(vl017, 17, "Teacher questions that push student thinking forward").
vocabulary_license_concept(vl018, 18, "What students should understand vs. what students should be able to do").
vocabulary_license_concept(vl019, 19, "Strategic teacher talk that structures productive mathematical discussion").
vocabulary_license_concept(vl020, 20, "Assessment that reveals how students think, not just whether they are correct").
vocabulary_license_concept(vl021, 21, "One-on-one interview to understand a student's mathematical reasoning").
vocabulary_license_concept(vl022, 22, "Progression from physical objects to drawings to symbols in student strategies").
vocabulary_license_concept(vl023, 23, "Student engagement where struggle is productive rather than frustrating").
vocabulary_license_concept(vl024, 24, "Repeating or restating a student's idea to make it public and check understanding").
vocabulary_license_concept(vl025, 25, "Asking students to justify, prove, or explain their reasoning").
vocabulary_license_concept(vl026, 26, "Fractions as equal parts of a whole").
vocabulary_license_concept(vl027, 27, "Two fractions that name the same amount").
vocabulary_license_concept(vl028, 28, "Four progressive steps of productive classroom talk").
vocabulary_license_concept(vl029, 29, "Teacher restates student idea to check understanding and make it public").
vocabulary_license_concept(vl030, 30, "Classroom norms for respectful and equitable mathematical discussion").
vocabulary_license_concept(vl031, 31, "Five meanings or constructs of fractions").
vocabulary_license_concept(vl032, 32, "Fraction as a measure on the number line (iterating unit fractions)").
vocabulary_license_concept(vl033, 33, "Fraction as the result of dividing one whole number by another").
vocabulary_license_concept(vl034, 34, "Fraction operating on (multiplying) another quantity").
vocabulary_license_concept(vl035, 35, "Three visual models for representing fractions").
vocabulary_license_concept(vl036, 36, "Equation that matches the story vs. equation that can be calculated").
vocabulary_license_concept(vl037, 37, "The four components that make up fact fluency").
vocabulary_license_concept(vl038, 38, "Three developmental phases children go through in learning basic facts").
vocabulary_license_concept(vl039, 39, "Three approaches to teaching basic facts").
vocabulary_license_concept(vl040, 40, "Quick mental recall of basic facts without conscious strategy use").
vocabulary_license_concept(vl041, 41, "A short, daily routine where students mentally solve a computation and share strategies").
vocabulary_license_concept(vl042, 42, "Five multiplicative problem structures").
vocabulary_license_concept(vl043, 43, "Commutative property of multiplication").
vocabulary_license_concept(vl044, 44, "Distributive property of multiplication over addition").
vocabulary_license_concept(vl045, 45, "Strategies for multi-digit multiplication").
vocabulary_license_concept(vl046, 46, "Strategies for multi-digit division").
vocabulary_license_concept(vl047, 47, "Partial products as a multiplication strategy").
vocabulary_license_concept(vl048, 48, "Place value understanding for multi-digit computation").
vocabulary_license_concept(vl049, 49, "Trading 10 ones for 1 ten (or vice versa) during computation").
vocabulary_license_concept(vl050, 50, "The standard step-by-step procedure for an arithmetic operation").
vocabulary_license_concept(vl051, 51, "Using known facts and relationships to figure out unknown facts").
vocabulary_license_concept(vl052, 52, "Specific addition fact strategies").
vocabulary_license_concept(vl053, 53, "Specific multiplication fact strategies").
vocabulary_license_concept(vl054, 54, "Indiana Process Standards vs. CCSS Mathematical Practices").
vocabulary_license_concept(vl055, 55, "Make sense of problems and persevere in solving them").
vocabulary_license_concept(vl056, 56, "Model with mathematics").
vocabulary_license_concept(vl057, 57, "Teacher tracking which students used which strategies during work time").
vocabulary_license_concept(vl058, 58, "Selecting which student work to share in whole-class discussion").
vocabulary_license_concept(vl059, 59, "Ordering shared student work to create a coherent mathematical storyline").
vocabulary_license_concept(vl060, 60, "Making explicit links between different student solutions and to learning goals").
vocabulary_license_concept(vl061, 61, "Asking a student to elaborate on an unclear or brief statement").
vocabulary_license_concept(vl062, 62, "Asking students to listen to and restate another student's idea").
vocabulary_license_concept(vl063, 63, "Asking students whether they agree or disagree with a claim and why").
vocabulary_license_concept(vl064, 64, "Asking students to build on what another student said").
vocabulary_license_concept(vl065, 65, "Wait time: silence after asking a question to allow thinking").
vocabulary_license_concept(vl066, 66, "Students discussing in pairs before sharing with the whole class").
vocabulary_license_concept(vl067, 67, "Teaching approach where teacher presents information to students").
vocabulary_license_concept(vl068, 68, "Teaching approach where students explore problems before formal instruction").
vocabulary_license_concept(vl069, 69, "Purposeful selection of students to present, considering equity").
vocabulary_license_concept(vl070, 70, "Cognitive demand of mathematical tasks").
vocabulary_license_concept(vl071, 71, "Launching a lesson: setting up the task without giving away the solution").
vocabulary_license_concept(vl072, 72, "Content strands in Indiana standards vs. CCSS domains").
vocabulary_license_concept(vl073, 73, "What Indiana calls a standard identification code").
vocabulary_license_concept(vl074, 74, "Vertical articulation: how content progresses across grade levels").
vocabulary_license_concept(vl075, 75, "Assessment built into daily instruction (not a separate test)").
vocabulary_license_concept(vl076, 76, "End-of-lesson check for student understanding").
vocabulary_license_concept(vl077, 77, "Tasks, problems, activities, and exercises as units of student work").
vocabulary_license_concept(vl078, 78, "Area model as visual representation for multiplication vs. for fractions").
vocabulary_license_concept(vl079, 79, "Open array / Open number line as a semi-concrete representation").

% vocabulary_license_note(ConceptId, Note).
vocabulary_license_note(vl001, "VdW uses 'Join' which sounds like combining (Part-Part-Whole) but specifically means an action of adding to an existing quantity. Indiana/CCSS/IM use 'Add to' which is more transparent. Students confuse Join with Part-Part-Whole.").
vocabulary_license_note(vl002, "VdW 'Separate' implies physical action but is less intuitive than 'Take from.' Students sometimes confuse 'Separate' with 'Compare' since both involve subtraction.").
vocabulary_license_note(vl003, "VdW emphasizes that Part-Part-Whole has NO ACTION, which is the key distinction from Join. Students confuse this with Join because both involve addition. The Indiana/CCSS phrasing 'Putting together' unfortunately implies action.").
vocabulary_license_note(vl004, "Fairly consistent across frameworks. Confusion arises because Compare problems can ask 'how many more' OR 'how many fewer' and students find the 'fewer' version much harder.").
vocabulary_license_note(vl005, "VdW and Indiana use 'partition' which is also used for fractions (partitioning a whole). CCSS describes the action rather than naming it. IM uses a question format. The word 'partition' doing double duty (division AND fractions) is a major source of confusion.").
vocabulary_license_note(vl006, "VdW calls this 'measurement division' which is confusing because 'measurement' also refers to rulers/units. Indiana does not name this type explicitly. IM uses a question format. Students struggle to see why this is called 'measurement.'").
vocabulary_license_note(vl007, "VdW distinguishes 'automaticity' (quick recall) from 'fluency' (efficient + accurate + flexible + appropriate strategy use). Indiana conflates fluency and mastery. CCSS says 'know from memory.' IM uses 'fluency' broadly. The course PPTs explicitly state: 'Automaticity is different from fluency.'").
vocabulary_license_note(vl008, "VdW places this in a three-phase developmental trajectory (counting, reasoning strategies, mastery). Indiana and CCSS list specific strategies. The risk is students thinking 'strategies' means tricks or shortcuts rather than understanding-based reasoning.").
vocabulary_license_note(vl009, "All frameworks recognize these models but emphasize them differently. VdW treats them as distinct problem structures. Indiana lists them as equivalent representations. The key confusion is array vs. area model -- arrays show discrete objects while area models show continuous area.").
vocabulary_license_note(vl010, "VdW calls this 'After phase,' IM calls it 'Synthesis' or 'Synthesize,' Five Practices breaks it into three sub-practices, CDM frames it as talk move steps. Students must map these onto each other when writing lesson plans.").
vocabulary_license_note(vl011, "Five Practices subdivides monitoring into tracking (who did what), assessing (questions that surface thinking), and advancing (questions that push thinking forward). VdW and IM treat this as a single phase. CDM provides the specific talk moves to use. Students must integrate all three frameworks when planning this part of a lesson.").
vocabulary_license_note(vl012, "VdW frames this as a pedagogical stance ('teaching through problem solving'). Five Practices makes it a numbered practice (Practice 0). IM embeds high-demand tasks in the curriculum itself. The terminology overlap is manageable but students sometimes conflate 'selecting tasks' (Practice 0) with 'selecting student work' (Practice 3).").
vocabulary_license_note(vl013, "Four different sets of names for essentially the same three phases. The course PPTs use 'Launch-Explore-Summarize' as the primary frame but require students to map Five Practices onto it. IM adds a four-part structure (Warm Up, Activities, Synthesis, Cool Down) nested within the three phases. The final exam explicitly asks students to know 'launch-explore-summarize' and when each of the 5 Practices occurs within it.").
vocabulary_license_note(vl014, "VdW uses 'referent unit' which is a technical term students rarely encounter elsewhere. Indiana/CCSS say 'the same whole' only in comparison contexts. IM alternates between 'the whole' and 'the unit.' The course PPTs emphasize: 'Fractions are relative -- the size of the whole makes a difference.'").
vocabulary_license_note(vl015, "VdW and IM both use 'iterating' but VdW ties it to the 'measurement construct' of fractions. CCSS uses formal notation. Indiana uses 'iterations' in standard 3.NS.2. The course PPTs frame this as 'remove one share and repeat it.'").
vocabulary_license_note(vl016, "Five Practices names these 'assessing questions' which students confuse with assessment (tests/quizzes). CDM calls them 'probing questions' which overlaps with Steps 1-2 talk moves. The course calls these 'stay and listen questions' informally. Students must learn that 'assessing' here means understanding thinking, not grading.").
vocabulary_license_note(vl017, "Five Practices' 'advancing questions' are contrasted with 'assessing questions' -- a distinction students find hard to maintain. The course informally calls these 'walk away questions' because they give students something to work on. CDM's Steps 3-4 overlap but are not identical.").
vocabulary_license_note(vl018, "The course PPTs devote an entire session to learning goals vs. performance goals. Key insight: 'If you can start it with Students will be able to... it is a performance goal (SWBAT).' Students can meet a performance goal WITHOUT meeting the related learning goal by following a procedure without understanding. The course notes: 'Your future school curriculum might call these ideas something different.'").
vocabulary_license_note(vl019, "CDM provides the most specific and actionable vocabulary. Five Practices embeds discourse within its practices without naming specific moves. VdW treats it as a general pedagogical principle. Students must learn CDM's specific moves AND know where they fit in the Five Practices framework.").
vocabulary_license_note(vl020, "Each framework treats formative assessment differently. VdW and Five Practices emphasize in-the-moment assessment during lessons. IM has a specific 'cool-down' component that serves this purpose. CDM frames talk moves themselves as assessment tools.").
vocabulary_license_note(vl021, "The course calls this a Think-Aloud Interview (TAI). This is a course-specific term that maps to VdW's 'diagnostic interview' and the research tradition of 'clinical interviews.' Students conduct TAIs as a major assignment.").
vocabulary_license_note(vl022, "VdW's CRA framework is well-known but the course PPTs use 'concrete, semi-concrete, and abstract' instead. IM embeds this progression in its activity design. Five Practices uses it as a sequencing rationale ('most concrete first'). The final exam asks about 'concrete, semi-concrete and abstract representations.'").
vocabulary_license_note(vl023, "The concept is universal but named differently. VdW names it explicitly. Five Practices frames it as an outcome of good task selection. Indiana/CCSS embed it in 'persevere.' IM operationalizes it by maintaining cognitive demand and not giving away solutions in the Launch.").
vocabulary_license_note(vl024, "CDM provides the specific term 'revoicing.' Other frameworks recognize the practice but don't name it. Students learn this as a CDM talk move and must recognize it when they see it in Five Practices or IM contexts.").
vocabulary_license_note(vl025, "CDM's 'Press for Reasoning' is a specific talk move. Five Practices frames this as advancing questions. Indiana/CCSS frame it as a mathematical practice standard. Students need to know that Press for Reasoning is a specific CDM term for what other frameworks describe more generally.").
vocabulary_license_note(vl026, "VdW identifies part-whole as ONE of five fraction constructs (part-whole, measurement, division, operator, ratio). Indiana/CCSS describe the action without naming the construct. Students must learn that partitioning is the first and simplest fraction meaning, used in grades 1-2.").
vocabulary_license_note(vl027, "Terminology is consistent across frameworks. The confusion is conceptual, not terminological -- students (and their future students) struggle with WHY 2/4 = 1/2, not what to call it.").
vocabulary_license_note(vl028, "CDM's four steps are the most detailed framework for classroom talk. They map onto but do not align one-to-one with Five Practices. Steps 1-2 correspond roughly to Monitoring; Steps 3-4 to Connecting. Students must hold both taxonomies in mind.").
vocabulary_license_note(vl029, "Duplicate of entry 23 -- revoicing. CDM is the only framework that names this specific move.").
vocabulary_license_note(vl030, "Each framework assumes norms exist but frames them differently. CDM devotes an entire chapter to norms. Five Practices treats them as prerequisites. VdW discusses 'mathematical community.' Indiana/CCSS embed norms in Practice Standard 3.").
vocabulary_license_note(vl031, "VdW's five constructs framework is a major organizing idea in the course. No other framework names them. Students must learn these as a VdW-specific taxonomy and then recognize them implicitly in standards and IM lessons. The course PPTs and final exam explicitly test knowledge of these five constructs.").
vocabulary_license_note(vl032, "VdW calls this the 'measurement construct' -- but 'measurement' also means rulers, length, area, volume. Indiana/CCSS describe the action (marking number lines). IM uses 'iterating.' The course PPTs define it as: 'make equal shares of a whole, remove one share, repeat the unit fraction.' This is the primary fraction meaning for 3rd grade.").
vocabulary_license_note(vl033, "VdW names this the 'division construct' as one of five fraction meanings. This is not introduced until 4th-5th grade. The course PPTs demonstrate this with 'sharing multiple equal bars among multiple people.' Students confuse this with partition division of whole numbers.").
vocabulary_license_note(vl034, "VdW names this the 'operator construct' -- taking 1/3 of 15 or 1/3 of 1/2. The course PPTs introduce this with set models (discrete objects). Indiana/CCSS describe it as multiplication. IM frames it as 'fraction of a quantity.' Students may not recognize that '1/3 of 15' IS multiplication.").
vocabulary_license_note(vl035, "VdW names three distinct visual models. Indiana/CCSS reference 'visual fraction models' without specifying which. IM uses 'area diagrams' (not 'area models'), 'number lines' (not 'length models'), and doesn't consistently name the set model. The course PPTs explicitly teach all three: 'Three kinds of visual models: Area, Length, Set.'").
vocabulary_license_note(vl036, "The course PPTs introduce this explicitly: '__ + 25 = 40 is the semantic equation (follows the story); 40 - 25 = __ is the calculation equation (can be calculated this way).' VdW makes this distinction but no other framework does. Students struggle to see that the same problem can have both representations and that the semantic equation is important for algebraic reasoning.").
vocabulary_license_note(vl037, "VdW defines fluency as four specific components. Indiana, CCSS, and IM use 'fluency' without defining it, which students (and many teachers) interpret as 'fast recall.' The course PPTs explicitly teach: 'Efficiency, Accuracy, Flexibility, Appropriate strategy selection.' This is tested on the final exam.").
vocabulary_license_note(vl038, "VdW's three-phase trajectory is a core course concept. The final exam tests it. No other framework names these phases. The critical point is that Phase 2 (strategies) is the road to Phase 3 (mastery) -- memorization that bypasses Phase 2 is counterproductive.").
vocabulary_license_note(vl039, "VdW names three distinct approaches. The course PPTs emphasize that memorization 'often bypasses Phase 2' and that strategies are 'ways to think about problems, not tricks to be memorized.' Guided invention is the most aligned with Five Practices. Students must understand the difference between teaching a strategy and having students invent strategies.").
vocabulary_license_note(vl040, "VdW explicitly distinguishes automaticity from fluency: 'Automaticity means quick recall of basic facts. Fact fluency is the road that leads to automaticity.' Indiana conflates them. CCSS says 'know from memory.' This distinction is a major course theme and is tested on the final exam.").
vocabulary_license_note(vl041, "Number Talks are a widely used routine taught in the course. IM includes them as one of several Warm-Up routines. Neither VdW nor Five Practices nor CDM 'own' the concept, but the course uses Number Talks as a vehicle to practice talk moves and demonstrate fact fluency teaching.").
vocabulary_license_note(vl042, "VdW identifies FIVE distinct structures; Indiana/CCSS/IM list only three or four. Combination (Cartesian product) problems are rarely in standards. The course PPTs teach all five and require students to identify problem structure and unknown parts. Array vs. Area is confusing because arrays are rows/columns of discrete objects while area models use continuous regions.").
vocabulary_license_note(vl043, "The property itself is consistent across frameworks, but the grade placement differs: CCSS introduces it in 3rd grade, Indiana in 4th grade. The course PPTs use area models and arrays to demonstrate it: '10 groups of 4 equals 4 groups of 10.'").
vocabulary_license_note(vl044, "VdW and Indiana use the formal name 'distributive property.' IM and the course PPTs also call it 'break apart.' The course uses it as a key multiplication fact strategy: 6 x 7 = 6 x 5 + 6 x 2. Students confuse this with the 'add a group' strategy which is a special case. Grade placement differs: CCSS 3rd grade, Indiana 4th grade.").
vocabulary_license_note(vl045, "VdW provides the most detailed progression: cluster problems -> concrete area model with base-ten blocks -> open array (semi-concrete) -> partial products -> standard algorithm. The course PPTs call the open array 'a semi-concrete representation of the area model.' IM uses 'area diagrams' not 'area models.' Students must understand that the standard algorithm IS partial products compressed into fewer lines.").
vocabulary_license_note(vl046, "VdW distinguishes between models for sharing division (base-ten blocks work well) and measurement division (open arrays work well). The course PPTs teach both explicitly. IM and standards don't make this distinction for multi-digit division. Students must learn that the division model affects which representation is most helpful.").
vocabulary_license_note(vl047, "The term 'partial products' is consistent but the visual representation varies. VdW connects partial products to area model sub-rectangles. The course PPTs show this connection explicitly: 'Each section is a partial product. Figure out the size of each sub-rectangle and combine to find the whole.'").
vocabulary_license_note(vl048, "VdW uses 'equivalent representations' (e.g., 100 = 8 tens and 20 ones) which is a key concept for regrouping. Indiana uses 'number sense' strand. CCSS uses 'Numbers and Operations in Base Ten (NBT)' domain. IM uses 'composing and decomposing.' The course PPTs note: '2nd students work on understanding base ten and EQUIVALENT representations for three-digit numbers.' The concept of 'regrouping' vs. 'carrying/borrowing' is also a terminology issue.").
vocabulary_license_note(vl049, "Older textbooks say 'carrying' and 'borrowing.' VdW uses 'regrouping' and 'trading.' Indiana avoids naming the action. CCSS uses 'compose/decompose.' The course goal examples reference 'when solving a two-digit addition problem with regrouping that ten ones creates one ten.' Students' future K-12 students will likely hear 'carry' and 'borrow' from parents.").
vocabulary_license_note(vl050, "All frameworks use 'standard algorithm' but differ on when to introduce it and how. VdW treats it as the endpoint of a progression from concrete models through partial products. The course PPTs show the connection: standard algorithm IS partial products in compressed notation. The confusion is that students (and parents) think the algorithm IS the math, rather than one representation of it.").
vocabulary_license_note(vl051, "VdW names specific strategies: doubling, near doubles, making 10, pretend-a-10, using 5 as anchor. The course PPTs teach these explicitly. Indiana/CCSS list strategy types without naming them. IM embeds them in curriculum. The N101 prerequisite course uses different names for some of these strategies (e.g., 'chunking' instead of 'down under 10').").
vocabulary_license_note(vl052, "VdW names eight specific strategies. The course PPTs teach all of them and note they differ from N101 prerequisite course names: 'Think addition = difference in N101; Down from 10 = chunking in N101; Take from 10 = decomposition in N101.' Students must coordinate VdW names, N101 names, and whatever names their field placement teachers use.").
vocabulary_license_note(vl053, "VdW names specific strategies. The course PPTs demonstrate them with visual models. 'Add a group' is a special case of the distributive property. 'Making bases' comes from N101 and is not in VdW. Students must map between VdW strategy names and what they learned in N101.").
vocabulary_license_note(vl054, "Indiana PS.1-8 are nearly identical to CCSS MP.1-8 in wording, but they are technically different documents. IM uses CCSS MPs. The CRITICAL confusion: Five Practices (Anticipate, Monitor, Select, Sequence, Connect) are TEACHER practices, not STUDENT practices, and are NOT the same as Process Standards / Mathematical Practices which describe what STUDENTS do. The course PPTs list all 8 Process Standards and have students create visuals for each.").
vocabulary_license_note(vl055, "PS.1/MP.1 is the broadest practice standard. VdW's 'teaching through problem solving' creates the conditions for it. Five Practices supports it through task selection and monitoring. Students must understand this is a STUDENT practice, not a teaching technique.").
vocabulary_license_note(vl056, "'Model' is dangerously ambiguous. PS.4/MP.4 means students use math to represent real-world situations. VdW uses 'model' to mean physical manipulatives (base-ten blocks, fraction bars). The course PPTs use both meanings. A 'model' can be a physical object, a drawing, or a mathematical equation depending on context.").
vocabulary_license_note(vl057, "Five Practices provides the most concrete tool: a monitoring chart where teachers record which students did which anticipated (or unanticipated) solutions. The course PPTs teach students to use monitoring charts and to plan for circulation patterns. VdW mentions observation but doesn't provide a specific tool.").
vocabulary_license_note(vl058, "Five Practices' 'selecting' (Practice 3) is easily confused with 'selecting tasks' (Practice 0). The course PPTs address this: 'Selecting is deciding WHICH mathematical ideas (what) and students (who) the teacher will focus on during discussion.' It is purposeful, not random, and guided by learning goals.").
vocabulary_license_note(vl059, "Five Practices provides specific sequencing rationales: most common strategy first, most concrete first, begin with misconception, put contrasting strategies back-to-back. The course PPTs warn: 'DON'T always use the same sequencing strategy -- kids will catch on.'").
vocabulary_license_note(vl060, "Five Practices identifies two types of connecting: connecting student work TO learning goals, and connecting student solutions TO EACH OTHER. The course PPTs teach both. IM's Synthesis phase serves this purpose. CDM's Steps 3-4 provide the talk moves to accomplish it.").
vocabulary_license_note(vl061, "CDM names this 'Say More' -- one of the Step 1 talk moves. The course teaches it alongside Revoicing. Students practice it during TAI rehearsals.").
vocabulary_license_note(vl062, "CDM names this 'Who Can Repeat?' -- a Step 2 talk move that helps students orient to the thinking of others. Easily confused with Revoicing (which is the TEACHER restating), not a student.").
vocabulary_license_note(vl063, "CDM names this as a Step 4 talk move. It directly supports PS.3/MP.3. The course PPTs teach it in Week 6.").
vocabulary_license_note(vl064, "CDM names this 'Who Can Add On?' -- a Step 4 talk move that helps students engage with the reasoning of others.").
vocabulary_license_note(vl065, "CDM names 'Wait Time' as a foundational talk move. IM calls it 'Quiet Think Time.' The concept is the same but the names differ. Students may not realize these are the same practice.").
vocabulary_license_note(vl066, "CDM calls this 'Turn and Talk.' IM and general education vocabulary use 'Think-Pair-Share.' They are essentially the same routine. Students encounter both terms and may not realize they refer to the same structure.").
vocabulary_license_note(vl067, "The course PPTs contrast inquiry-based and lecture-based instruction: 'Inquiry: Students explore. Lecture: Teacher stands at front of class, talks to deliver information.' CDM distinguishes 'dialogic instruction' from 'direct instruction.' Neither is inherently wrong -- the course argues for inquiry as primary with some direct instruction for vocabulary and conventions.").
vocabulary_license_note(vl068, "Multiple overlapping terms for the same general approach. VdW says 'teaching through problem solving.' Five Practices says 'ambitious teaching.' CDM says 'dialogic instruction.' IM says 'problem-based curriculum.' The course PPTs note that 'every IM lesson CAN be taught as launch-explore-summarize and using 5 Practices, but they are not all written that way.' Students must understand these terms all point to the same pedagogical stance.").
vocabulary_license_note(vl069, "The course PPTs explicitly address equity in selecting: 'It is important for ALL students at different times to get a chance to share, NOT just the students with the clearest work or who are the most verbally articulate.' Five Practices and CDM both address this. Standards do not.").
vocabulary_license_note(vl070, "Five Practices draws on the Stein & Smith task analysis guide which categorizes tasks by cognitive demand (memorization, procedures without connections, procedures with connections, doing mathematics). VdW uses 'worthwhile tasks.' The course PPTs emphasize: 'Students have to have something meaty to talk about.'").
vocabulary_license_note(vl071, "VdW calls this 'Before,' CDM and the course use 'Launch,' IM has a specific 'Launch' section. The key tension: 'Maintain cognitive demand; Don't give away too much' vs. 'Make sure they have all the info and tools they need.' The course PPTs give detailed guidance: introduce vocabulary, provide tools and logistics, but don't model the solution.").
vocabulary_license_note(vl072, "Indiana and CCSS organize content into different strands/domains with different names. Indiana combines 'Computation and Algebraic Thinking' into one strand; CCSS separates 'Operations & Algebraic Thinking' from 'Number & Operations in Base Ten.' Indiana has 'Number Sense'; CCSS splits this across multiple domains. Students reading standards must know which system they are looking at.").
vocabulary_license_note(vl073, "Indiana codes (3.CA.5) and CCSS codes (3.OA.C.7) look similar but use different abbreviations for different organizational structures. IM uses CCSS codes. The course requires students to identify appropriate Indiana standards for their lessons, but many resources reference CCSS codes. Students must be able to cross-reference both systems.").
vocabulary_license_note(vl074, "Indiana publishes 'vertical articulation' documents. CCSS has 'progressions' documents. IM has scope and sequence. VdW organizes chapters developmentally. The course requires students to analyze vertical articulation documents to understand what comes before and after their lesson.").
vocabulary_license_note(vl075, "The term 'formative assessment' is used broadly. VdW means observing and questioning during lessons. Five Practices means the assessing questions asked during monitoring. IM's Cool-down is a specific formative assessment artifact. CDM frames talk moves themselves as assessment. The course PPTs note that 'Timed tests do NOT help students LEARN basic facts' -- distinguishing formative from summative purposes.").
vocabulary_license_note(vl076, "IM is the only framework that names this component. IM's 'Cool-down' serves as both a formative assessment and a consolidation of learning. Other frameworks assume some form of closure but don't name it. Students writing lesson plans may not include this unless they are using IM.").
vocabulary_license_note(vl077, "VdW distinguishes 'tasks' (requiring genuine thinking) from 'exercises' (practice of known procedures). Five Practices uses 'tasks' exclusively. IM uses 'activities' for lesson sections and 'problems' within them. Standards use 'problems.' The course PPTs frame the distinction: tasks require thinking; exercises are drill.").
vocabulary_license_note(vl078, "'Area model' is used in TWO completely different mathematical contexts in this course: (1) for multi-digit multiplication (connected rectangles showing partial products) and (2) for fractions (shaded portions of shapes showing fractional amounts). Students must understand these are the same NAME for different visual tools used for different purposes.").
vocabulary_license_note(vl079, "The course PPTs call the open array 'a semi-concrete representation of the area model.' It is drawn as a blank rectangle (not to scale) subdivided by place value, with partial products recorded inside. Students must understand the progression: base-ten blocks -> connected array -> open array -> standard algorithm.").

% vocabulary_license(ConceptId, Framework, Term, Risk, LicenseKind, Provenance).
% -- entry 1: Addition problem where something is added to an initial quantity
vocabulary_license(vl001, van_de_walle, "Join", high, disambiguation_required, provenance(1, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl001, indiana, "Adding to", high, disambiguation_required, provenance(1, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl001, ccss, "Add to", high, disambiguation_required, provenance(1, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl001, illustrative_math, "Add To", high, disambiguation_required, provenance(1, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl001, five_practices, "Not addressed (content-neutral framework)", high, not_addressed, provenance(1, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl001, cdm, "Not addressed (discourse-focused framework)", high, not_addressed, provenance(1, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 2: Subtraction problem where something is removed
vocabulary_license(vl002, van_de_walle, "Separate", high, disambiguation_required, provenance(2, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl002, indiana, "Taking from", high, disambiguation_required, provenance(2, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl002, ccss, "Take from", high, disambiguation_required, provenance(2, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl002, illustrative_math, "Take From", high, disambiguation_required, provenance(2, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl002, five_practices, "Not addressed", high, not_addressed, provenance(2, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl002, cdm, "Not addressed", high, not_addressed, provenance(2, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 3: Two parts combine into a whole (or whole decomposed into parts)
vocabulary_license(vl003, van_de_walle, "Part-Part-Whole", high, disambiguation_required, provenance(3, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl003, indiana, "Putting together / Taking apart", high, disambiguation_required, provenance(3, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl003, ccss, "Put together / Take apart", high, disambiguation_required, provenance(3, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl003, illustrative_math, "Put Together / Take Apart", high, disambiguation_required, provenance(3, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl003, five_practices, "Not addressed", high, not_addressed, provenance(3, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl003, cdm, "Not addressed", high, not_addressed, provenance(3, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 4: Two quantities compared to find the difference
vocabulary_license(vl004, van_de_walle, "Compare", medium, substitutable_in_context, provenance(4, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl004, indiana, "Comparing", medium, substitutable_in_context, provenance(4, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl004, ccss, "Compare", medium, substitutable_in_context, provenance(4, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl004, illustrative_math, "Compare", medium, substitutable_in_context, provenance(4, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl004, five_practices, "Not addressed", medium, not_addressed, provenance(4, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl004, cdm, "Not addressed", medium, not_addressed, provenance(4, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 5: Division where the number of groups is known, find group size
vocabulary_license(vl005, van_de_walle, "Partition division (sharing division)", high, disambiguation_required, provenance(5, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl005, indiana, "Partitioning / Sharing", high, disambiguation_required, provenance(5, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl005, ccss, "Number of objects in each share", high, disambiguation_required, provenance(5, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl005, illustrative_math, "How many in each group?", high, disambiguation_required, provenance(5, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl005, five_practices, "Not addressed", high, not_addressed, provenance(5, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl005, cdm, "Not addressed", high, not_addressed, provenance(5, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 6: Division where group size is known, find number of groups
vocabulary_license(vl006, van_de_walle, "Measurement division (repeated subtraction)", high, disambiguation_required, provenance(6, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl006, indiana, "(Implied via inverse of multiplication)", high, not_addressed, provenance(6, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl006, ccss, "Number of shares / equal shares of", high, disambiguation_required, provenance(6, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl006, illustrative_math, "How many groups?", high, disambiguation_required, provenance(6, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl006, five_practices, "Not addressed", high, not_addressed, provenance(6, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl006, cdm, "Not addressed", high, not_addressed, provenance(6, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 7: Knowing single-digit facts automatically
vocabulary_license(vl007, van_de_walle, "Mastery (Phase 3 of fact development)", high, disambiguation_required, provenance(7, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl007, indiana, "Demonstrate fluency with mastery", high, disambiguation_required, provenance(7, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl007, ccss, "Know from memory", high, disambiguation_required, provenance(7, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl007, illustrative_math, "Fluency", high, disambiguation_required, provenance(7, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl007, five_practices, "Not addressed", high, not_addressed, provenance(7, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl007, cdm, "Not addressed", high, not_addressed, provenance(7, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 8: Using strategies rather than rote recall for facts
vocabulary_license(vl008, van_de_walle, "Reasoning strategies (Phase 2 of fact development)", medium, substitutable_in_context, provenance(8, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl008, indiana, "Using strategies such as...", medium, substitutable_in_context, provenance(8, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl008, ccss, "Using strategies such as...", medium, substitutable_in_context, provenance(8, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl008, illustrative_math, "Strategy-based fluency", medium, substitutable_in_context, provenance(8, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl008, five_practices, "Not addressed", medium, not_addressed, provenance(8, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl008, cdm, "Not addressed", medium, not_addressed, provenance(8, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 9: Multiplication with arrays and equal groups
vocabulary_license(vl009, van_de_walle, "Equal groups / Array / Area", medium, substitutable_in_context, provenance(9, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl009, indiana, "Equal-sized groups, arrays, area models, equal intervals on a number line", medium, substitutable_in_context, provenance(9, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl009, ccss, "Groups of objects", medium, substitutable_in_context, provenance(9, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl009, illustrative_math, "Equal groups, arrays, area diagrams", medium, substitutable_in_context, provenance(9, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl009, five_practices, "Not addressed", medium, not_addressed, provenance(9, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl009, cdm, "Not addressed", medium, not_addressed, provenance(9, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 10: Teacher orchestrates whole-class discussion of student work
vocabulary_license(vl010, van_de_walle, "After phase / Classroom discourse", high, disambiguation_required, provenance(10, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl010, indiana, "PS.3: Construct viable arguments and critique the reasoning of others", high, disambiguation_required, provenance(10, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl010, ccss, "MP.3: Construct viable arguments and critique the reasoning of others", high, disambiguation_required, provenance(10, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl010, illustrative_math, "Synthesis / Cool-down discussion", high, disambiguation_required, provenance(10, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl010, five_practices, "Selecting, Sequencing, and Connecting", high, disambiguation_required, provenance(10, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl010, cdm, "Steps 3-4 talk moves in whole-class context", high, disambiguation_required, provenance(10, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 11: Teacher circulates during student work time to understand thinking
vocabulary_license(vl011, van_de_walle, "During phase / Observe and assess", high, disambiguation_required, provenance(11, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl011, indiana, "PS.1: Make sense of problems (teacher modeling this disposition)", high, disambiguation_required, provenance(11, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl011, ccss, "Not addressed as teacher action", high, not_addressed, provenance(11, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl011, illustrative_math, "Work phase of Launch-Work-Synthesize", high, disambiguation_required, provenance(11, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl011, five_practices, "Monitoring (tracking, assessing, advancing)", high, disambiguation_required, provenance(11, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl011, cdm, "Using talk moves in small-group conversations", high, disambiguation_required, provenance(11, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 12: Choosing tasks that require genuine mathematical thinking
vocabulary_license(vl012, van_de_walle, "Teaching through problem solving / Worthwhile tasks", medium, substitutable_in_context, provenance(12, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl012, indiana, "PS.1: Make sense of problems and persevere in solving them", medium, substitutable_in_context, provenance(12, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl012, ccss, "MP.1: Make sense of problems and persevere in solving them", medium, substitutable_in_context, provenance(12, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl012, illustrative_math, "High-demand tasks / Invitations to reason", medium, substitutable_in_context, provenance(12, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl012, five_practices, "Practice 0: Setting Goals and Selecting Tasks", medium, substitutable_in_context, provenance(12, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl012, cdm, "Not addressed directly", medium, not_addressed, provenance(12, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 13: Three-phase lesson structure for problem-based instruction
vocabulary_license(vl013, van_de_walle, "Before / During / After", high, disambiguation_required, provenance(13, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl013, indiana, "Not specified in standards", high, not_addressed, provenance(13, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl013, ccss, "Not specified in standards", high, not_addressed, provenance(13, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl013, illustrative_math, "Launch -> Work -> Synthesize (within: Warm Up -> Activities -> Synthesis -> Cool Down)", high, disambiguation_required, provenance(13, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl013, five_practices, "Anticipate -> Monitor -> Select/Sequence/Connect", high, disambiguation_required, provenance(13, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl013, cdm, "Launch -> Explore -> Summarize", high, disambiguation_required, provenance(13, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 14: The quantity that a fraction refers to
vocabulary_license(vl014, van_de_walle, "The whole / Referent unit", high, disambiguation_required, provenance(14, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl014, indiana, "The same whole (in 3.NS.5, 4.NS.4)", high, disambiguation_required, provenance(14, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl014, ccss, "The same whole (in 3.NF.A.3, 4.NF.A.2)", high, disambiguation_required, provenance(14, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl014, illustrative_math, "The whole / The unit", high, disambiguation_required, provenance(14, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl014, five_practices, "Not addressed", high, not_addressed, provenance(14, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl014, cdm, "Not addressed", high, not_addressed, provenance(14, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 15: Building fractions by repeating a unit fraction
vocabulary_license(vl015, van_de_walle, "Iteration / Measurement construct", medium, substitutable_in_context, provenance(15, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl015, indiana, "Iterations of unit fractions (3.NS.2)", medium, substitutable_in_context, provenance(15, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl015, ccss, "a parts of size 1/b (3.NF.A.1)", medium, substitutable_in_context, provenance(15, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl015, illustrative_math, "Iterating / Copies of a unit fraction", medium, substitutable_in_context, provenance(15, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl015, five_practices, "Not addressed", medium, not_addressed, provenance(15, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl015, cdm, "Not addressed", medium, not_addressed, provenance(15, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 16: Teacher questions that surface current student thinking
vocabulary_license(vl016, van_de_walle, "During phase questioning", high, disambiguation_required, provenance(16, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl016, indiana, "Not addressed in standards", high, not_addressed, provenance(16, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl016, ccss, "Not addressed in standards", high, not_addressed, provenance(16, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl016, illustrative_math, "(Not named; embedded in teacher guidance)", high, not_addressed, provenance(16, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl016, five_practices, "Assessing questions", high, disambiguation_required, provenance(16, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl016, cdm, "Probing questions / Talk moves Steps 1-2", high, disambiguation_required, provenance(16, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 17: Teacher questions that push student thinking forward
vocabulary_license(vl017, van_de_walle, "During phase questioning", high, disambiguation_required, provenance(17, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl017, indiana, "Not addressed in standards", high, not_addressed, provenance(17, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl017, ccss, "Not addressed in standards", high, not_addressed, provenance(17, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl017, illustrative_math, "(Not named; embedded in teacher guidance)", high, not_addressed, provenance(17, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl017, five_practices, "Advancing questions", high, disambiguation_required, provenance(17, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl017, cdm, "Talk moves Steps 3-4 (press for reasoning, extend)", high, disambiguation_required, provenance(17, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 18: What students should understand vs. what students should be able to do
vocabulary_license(vl018, van_de_walle, "Understanding / Conceptual knowledge vs. Procedural fluency", high, disambiguation_required, provenance(18, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl018, indiana, "Process Standards (understanding) + Content Standards (performance)", high, disambiguation_required, provenance(18, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl018, ccss, "Standards for Mathematical Practice (understanding) + Content Standards (performance)", high, disambiguation_required, provenance(18, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl018, illustrative_math, "Lesson goals (understanding) + Cool-down performance indicators", high, disambiguation_required, provenance(18, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl018, five_practices, "Learning goals vs. Performance goals", high, disambiguation_required, provenance(18, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl018, cdm, "Not addressed directly", high, not_addressed, provenance(18, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 19: Strategic teacher talk that structures productive mathematical discuss
vocabulary_license(vl019, van_de_walle, "Classroom discourse / Teacher questioning", medium, substitutable_in_context, provenance(19, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl019, indiana, "PS.3: Construct viable arguments and critique the reasoning of others", medium, substitutable_in_context, provenance(19, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl019, ccss, "MP.3: Construct viable arguments and critique the reasoning of others", medium, substitutable_in_context, provenance(19, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl019, illustrative_math, "Discussion supports in teacher guidance", medium, substitutable_in_context, provenance(19, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl019, five_practices, "Embedded in Monitoring and Connecting practices", medium, substitutable_in_context, provenance(19, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl019, cdm, "Talk Moves (Wait Time, Turn & Talk, Revoicing, Say More, Who Can Repeat, Press for Reasoning, Agree/Disagree, Who Can Add On)", medium, substitutable_in_context, provenance(19, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 20: Assessment that reveals how students think, not just whether they are 
vocabulary_license(vl020, van_de_walle, "Diagnostic interview / Assessment through observation", medium, substitutable_in_context, provenance(20, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl020, indiana, "(Not named in standards; implied by PS.1)", medium, not_addressed, provenance(20, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl020, ccss, "Not addressed directly", medium, not_addressed, provenance(20, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl020, illustrative_math, "Cool-down / Formative assessment", medium, substitutable_in_context, provenance(20, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl020, five_practices, "Monitoring (tracking + assessing student thinking)", medium, substitutable_in_context, provenance(20, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl020, cdm, "Talk Moves Steps 1-2 as assessment tools", medium, substitutable_in_context, provenance(20, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 21: One-on-one interview to understand a student's mathematical reasoning
vocabulary_license(vl021, van_de_walle, "Diagnostic interview", low, substitutable_in_context, provenance(21, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl021, indiana, "(Not referenced in standards)", low, not_addressed, provenance(21, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl021, ccss, "Not addressed", low, not_addressed, provenance(21, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl021, illustrative_math, "(Not a curriculum component; used in research)", low, not_addressed, provenance(21, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl021, five_practices, "Clinical interview / Related to anticipating and monitoring", low, substitutable_in_context, provenance(21, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl021, cdm, "(Not addressed directly)", low, not_addressed, provenance(21, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 22: Progression from physical objects to drawings to symbols in student st
vocabulary_license(vl022, van_de_walle, "Concrete -> Representational -> Abstract (CRA)", medium, substitutable_in_context, provenance(22, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl022, indiana, "PS.4: Model with mathematics (multiple representations)", medium, substitutable_in_context, provenance(22, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl022, ccss, "MP.4: Model with mathematics", medium, substitutable_in_context, provenance(22, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl022, illustrative_math, "Representations progression within activity sequences", medium, substitutable_in_context, provenance(22, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl022, five_practices, "Sequencing from less to more sophisticated strategies", medium, substitutable_in_context, provenance(22, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl022, cdm, "Not addressed directly", medium, not_addressed, provenance(22, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 23: Student engagement where struggle is productive rather than frustratin
vocabulary_license(vl023, van_de_walle, "Teaching through problem solving / Productive struggle", medium, substitutable_in_context, provenance(23, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl023, indiana, "PS.1: Make sense of problems and persevere in solving them", medium, substitutable_in_context, provenance(23, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl023, ccss, "MP.1: Make sense of problems and persevere in solving them", medium, substitutable_in_context, provenance(23, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl023, illustrative_math, "Maintaining cognitive demand during Work phase", medium, substitutable_in_context, provenance(23, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl023, five_practices, "Created by setting appropriate goals + high-demand tasks", medium, substitutable_in_context, provenance(23, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl023, cdm, "Not addressed directly", medium, not_addressed, provenance(23, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 24: Repeating or restating a student's idea to make it public and check un
vocabulary_license(vl024, van_de_walle, "(Not named specifically; part of discourse)", medium, not_addressed, provenance(24, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl024, indiana, "Not addressed", medium, not_addressed, provenance(24, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl024, ccss, "Not addressed", medium, not_addressed, provenance(24, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl024, illustrative_math, "(Embedded in teacher guidance)", medium, substitutable_in_context, provenance(24, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl024, five_practices, "Part of Monitoring and Connecting", medium, substitutable_in_context, provenance(24, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl024, cdm, "Revoicing (Step 1 talk move)", medium, substitutable_in_context, provenance(24, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 25: Asking students to justify, prove, or explain their reasoning
vocabulary_license(vl025, van_de_walle, "Justification / Proof in the classroom", medium, substitutable_in_context, provenance(25, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl025, indiana, "PS.3: Construct viable arguments and critique the reasoning of others", medium, substitutable_in_context, provenance(25, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl025, ccss, "MP.3: Construct viable arguments and critique the reasoning of others", medium, substitutable_in_context, provenance(25, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl025, illustrative_math, "Not named; embedded in teacher guidance", medium, not_addressed, provenance(25, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl025, five_practices, "Advancing questions during Monitoring", medium, substitutable_in_context, provenance(25, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl025, cdm, "Press for Reasoning (Step 3 talk move)", medium, substitutable_in_context, provenance(25, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 26: Fractions as equal parts of a whole
vocabulary_license(vl026, van_de_walle, "Part-whole construct / Partitioning", medium, substitutable_in_context, provenance(26, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl026, indiana, "3.NS.2: Understand a unit fraction as the quantity formed by one part when a whole is partitioned", medium, substitutable_in_context, provenance(26, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl026, ccss, "3.NF.A.1: A fraction 1/b as the quantity formed by 1 part when a whole is partitioned into b equal parts", medium, substitutable_in_context, provenance(26, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl026, illustrative_math, "Unit fractions / Partitioning shapes and wholes", medium, substitutable_in_context, provenance(26, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl026, five_practices, "Not addressed", medium, not_addressed, provenance(26, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl026, cdm, "Not addressed", medium, not_addressed, provenance(26, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 27: Two fractions that name the same amount
vocabulary_license(vl027, van_de_walle, "Equivalent fractions / Conceptual methods for generating equivalence", low, substitutable_in_context, provenance(27, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl027, indiana, "4.NS.3: Explain equivalence of fractions and compare fractions", low, substitutable_in_context, provenance(27, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl027, ccss, "3.NF.A.3: Equivalent fractions / 4.NF.A.1: Explain fraction equivalence using visual models", low, substitutable_in_context, provenance(27, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl027, illustrative_math, "Equivalent fractions / Size of fractions", low, substitutable_in_context, provenance(27, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl027, five_practices, "Not addressed", low, not_addressed, provenance(27, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl027, cdm, "Not addressed", low, not_addressed, provenance(27, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 28: Four progressive steps of productive classroom talk
vocabulary_license(vl028, van_de_walle, "During/After phase discourse", medium, substitutable_in_context, provenance(28, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl028, indiana, "Not addressed", medium, not_addressed, provenance(28, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl028, ccss, "Not addressed", medium, not_addressed, provenance(28, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl028, illustrative_math, "Discussion supports in teacher guidance", medium, substitutable_in_context, provenance(28, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl028, five_practices, "Embedded across Monitoring and Connecting", medium, substitutable_in_context, provenance(28, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl028, cdm, "Steps 1-4: Clarify/Share -> Orient to Others -> Deepen Reasoning -> Engage with Others' Reasoning", medium, substitutable_in_context, provenance(28, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 29: Teacher restates student idea to check understanding and make it publi
vocabulary_license(vl029, van_de_walle, "Part of During phase discourse", low, substitutable_in_context, provenance(29, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl029, indiana, "Not addressed", low, not_addressed, provenance(29, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl029, ccss, "Not addressed", low, not_addressed, provenance(29, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl029, illustrative_math, "Embedded in Synthesize guidance", low, substitutable_in_context, provenance(29, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl029, five_practices, "Monitoring tool", low, substitutable_in_context, provenance(29, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl029, cdm, "Revoicing (Step 1 talk move)", low, substitutable_in_context, provenance(29, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 30: Classroom norms for respectful and equitable mathematical discussion
vocabulary_license(vl030, van_de_walle, "Creating a mathematical community", medium, substitutable_in_context, provenance(30, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl030, indiana, "PS.3: Construct viable arguments and critique the reasoning of others", medium, substitutable_in_context, provenance(30, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl030, ccss, "MP.3: Construct viable arguments and critique the reasoning of others", medium, substitutable_in_context, provenance(30, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl030, illustrative_math, "Community-building activities in early units", medium, substitutable_in_context, provenance(30, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl030, five_practices, "Prerequisites for all practices", medium, substitutable_in_context, provenance(30, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl030, cdm, "Chapter 2: Classroom Talk Norms (respectful discourse + equitable participation)", medium, substitutable_in_context, provenance(30, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 31: Five meanings or constructs of fractions
vocabulary_license(vl031, van_de_walle, "Part-whole, Measurement, Division, Operator, Ratio", high, disambiguation_required, provenance(31, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl031, indiana, "Not named as constructs; individual meanings appear across grade-level standards", high, not_addressed, provenance(31, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl031, ccss, "Not named as constructs; individual meanings appear across domains", high, not_addressed, provenance(31, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl031, illustrative_math, "Not named as constructs; different meanings emerge across grade-level units", high, not_addressed, provenance(31, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl031, five_practices, "Not addressed", high, not_addressed, provenance(31, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl031, cdm, "Not addressed", high, not_addressed, provenance(31, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 32: Fraction as a measure on the number line (iterating unit fractions)
vocabulary_license(vl032, van_de_walle, "Measurement construct", high, disambiguation_required, provenance(32, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl032, indiana, "3.NS.3: Model a non-unit fraction on a number line by marking equal lengths", high, disambiguation_required, provenance(32, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl032, ccss, "3.NF.A.2: Understand a fraction as a number on the number line", high, disambiguation_required, provenance(32, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl032, illustrative_math, "Fractions on a number line / Iterating unit fractions", high, disambiguation_required, provenance(32, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl032, five_practices, "Not addressed", high, not_addressed, provenance(32, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl032, cdm, "Not addressed", high, not_addressed, provenance(32, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 33: Fraction as the result of dividing one whole number by another
vocabulary_license(vl033, van_de_walle, "Division construct of fractions", high, disambiguation_required, provenance(33, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl033, indiana, "5.NS.2: Explain different interpretations of fractions, including as parts of a whole, division of whole numbers, and parts of a set", high, disambiguation_required, provenance(33, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl033, ccss, "5.NF.B.3: Interpret a fraction as division of the numerator by the denominator", high, disambiguation_required, provenance(33, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl033, illustrative_math, "Division situations that result in fractions", high, disambiguation_required, provenance(33, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl033, five_practices, "Not addressed", high, not_addressed, provenance(33, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl033, cdm, "Not addressed", high, not_addressed, provenance(33, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 34: Fraction operating on (multiplying) another quantity
vocabulary_license(vl034, van_de_walle, "Operator construct of fractions", medium, substitutable_in_context, provenance(34, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl034, indiana, "5.CA.5: Use visual fraction models to multiply a fraction by a fraction", medium, substitutable_in_context, provenance(34, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl034, ccss, "5.NF.B.4: Apply and extend previous understandings of multiplication to multiply a fraction by a whole number", medium, substitutable_in_context, provenance(34, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl034, illustrative_math, "Fraction of a quantity / Fraction multiplication", medium, substitutable_in_context, provenance(34, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl034, five_practices, "Not addressed", medium, not_addressed, provenance(34, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl034, cdm, "Not addressed", medium, not_addressed, provenance(34, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 35: Three visual models for representing fractions
vocabulary_license(vl035, van_de_walle, "Area model, Length model, Set model", medium, substitutable_in_context, provenance(35, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl035, indiana, "Visual fraction models (referenced across 3.NS through 5.CA standards)", medium, substitutable_in_context, provenance(35, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl035, ccss, "Visual fraction models (referenced across 3.NF through 5.NF)", medium, substitutable_in_context, provenance(35, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl035, illustrative_math, "Area diagrams, number lines, discrete diagrams", medium, substitutable_in_context, provenance(35, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl035, five_practices, "Not addressed", medium, not_addressed, provenance(35, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl035, cdm, "Not addressed", medium, not_addressed, provenance(35, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 36: Equation that matches the story vs. equation that can be calculated
vocabulary_license(vl036, van_de_walle, "Semantic equation vs. Calculation equation", high, disambiguation_required, provenance(36, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl036, indiana, "Not distinguished in standards", high, not_addressed, provenance(36, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl036, ccss, "Not distinguished in standards", high, not_addressed, provenance(36, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl036, illustrative_math, "Not explicitly distinguished", high, not_addressed, provenance(36, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl036, five_practices, "Not addressed", high, not_addressed, provenance(36, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl036, cdm, "Not addressed", high, not_addressed, provenance(36, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 37: The four components that make up fact fluency
vocabulary_license(vl037, van_de_walle, "Efficiency, Accuracy, Flexibility, Appropriate strategy selection", high, disambiguation_required, provenance(37, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl037, indiana, "Fluency (without specifying components)", high, disambiguation_required, provenance(37, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl037, ccss, "Fluency (without specifying components)", high, disambiguation_required, provenance(37, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl037, illustrative_math, "Fluency (without specifying components)", high, disambiguation_required, provenance(37, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl037, five_practices, "Not addressed", high, not_addressed, provenance(37, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl037, cdm, "Not addressed", high, not_addressed, provenance(37, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 38: Three developmental phases children go through in learning basic facts
vocabulary_license(vl038, van_de_walle, "Phase 1: Counting (counting all, counting on) -> Phase 2: Reasoning strategies (doubles, making 10) -> Phase 3: Mastery (automaticity)", high, disambiguation_required, provenance(38, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl038, indiana, "Not described as phases; standards list strategies", high, not_addressed, provenance(38, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl038, ccss, "Not described as phases; standards list strategies", high, not_addressed, provenance(38, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl038, illustrative_math, "Implicit in unit sequencing but not named as phases", high, not_addressed, provenance(38, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl038, five_practices, "Not addressed", high, not_addressed, provenance(38, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl038, cdm, "Not addressed", high, not_addressed, provenance(38, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 39: Three approaches to teaching basic facts
vocabulary_license(vl039, van_de_walle, "Memorization / Explicit Strategy Instruction / Guided Invention", medium, substitutable_in_context, provenance(39, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl039, indiana, "Not specified (standards say 'using strategies such as...')", medium, not_addressed, provenance(39, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl039, ccss, "Not specified", medium, not_addressed, provenance(39, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl039, illustrative_math, "Embedded in curriculum design (tends toward guided invention)", medium, substitutable_in_context, provenance(39, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl039, five_practices, "Not addressed", medium, not_addressed, provenance(39, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl039, cdm, "Not addressed", medium, not_addressed, provenance(39, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 40: Quick mental recall of basic facts without conscious strategy use
vocabulary_license(vl040, van_de_walle, "Automaticity (distinct from fluency)", high, disambiguation_required, provenance(40, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl040, indiana, "Mastery (in 'demonstrate fluency with mastery')", high, disambiguation_required, provenance(40, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl040, ccss, "Know from memory", high, disambiguation_required, provenance(40, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl040, illustrative_math, "Not named separately from fluency", high, not_addressed, provenance(40, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl040, five_practices, "Not addressed", high, not_addressed, provenance(40, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl040, cdm, "Not addressed", high, not_addressed, provenance(40, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 41: A short, daily routine where students mentally solve a computation and
vocabulary_license(vl041, van_de_walle, "Number Talk (referenced but not named as a VdW concept)", medium, not_addressed, provenance(41, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl041, indiana, "Not referenced in standards", medium, not_addressed, provenance(41, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl041, ccss, "Not referenced in standards", medium, not_addressed, provenance(41, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl041, illustrative_math, "Warm-Up routines (Number Talks, Which One Doesn't Belong, True or False, etc.)", medium, substitutable_in_context, provenance(41, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl041, five_practices, "Not named; example of a task that can be orchestrated using all five practices", medium, not_addressed, provenance(41, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl041, cdm, "Not named; exemplifies all four talk move steps", medium, not_addressed, provenance(41, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 42: Five multiplicative problem structures
vocabulary_license(vl042, van_de_walle, "Equal Groups, Comparison, Array, Area, Combination (Cartesian product)", high, disambiguation_required, provenance(42, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl042, indiana, "Equal-sized groups, arrays, area models (3.CA.3)", high, disambiguation_required, provenance(42, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl042, ccss, "Equal groups, arrays, area (3.OA.A.1)", high, disambiguation_required, provenance(42, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl042, illustrative_math, "Equal groups, arrays, area diagrams, comparison", high, disambiguation_required, provenance(42, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl042, five_practices, "Not addressed", high, not_addressed, provenance(42, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl042, cdm, "Not addressed", high, not_addressed, provenance(42, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 43: Commutative property of multiplication
vocabulary_license(vl043, van_de_walle, "Commutative property (demonstrated with arrays: 3 rows of 5 = 5 rows of 3)", medium, substitutable_in_context, provenance(43, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl043, indiana, "4.CA.3: Show how the order in which two numbers are multiplied (commutative property) does not change the product", medium, substitutable_in_context, provenance(43, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl043, ccss, "3.OA.B.5: Apply properties of operations (commutative property of multiplication)", medium, substitutable_in_context, provenance(43, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl043, illustrative_math, "Commutative property / Rotating arrays", medium, substitutable_in_context, provenance(43, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl043, five_practices, "Not addressed", medium, not_addressed, provenance(43, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl043, cdm, "Not addressed", medium, not_addressed, provenance(43, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 44: Distributive property of multiplication over addition
vocabulary_license(vl044, van_de_walle, "Distributive property / Break apart strategy", high, disambiguation_required, provenance(44, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl044, indiana, "4.CA.3: Show how a multiplication problem can use the distributive property", high, disambiguation_required, provenance(44, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl044, ccss, "3.OA.B.5: Apply properties of operations (distributive property)", high, disambiguation_required, provenance(44, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl044, illustrative_math, "Break-apart problems / Decomposing factors", high, disambiguation_required, provenance(44, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl044, five_practices, "Not addressed", high, not_addressed, provenance(44, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl044, cdm, "Not addressed", high, not_addressed, provenance(44, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 45: Strategies for multi-digit multiplication
vocabulary_license(vl045, van_de_walle, "Cluster problems / Number strings -> Area model (connected) -> Open array -> Partial products -> Standard algorithm", high, disambiguation_required, provenance(45, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl045, indiana, "4.CA.1: Multiply using strategies based on place value and the properties of operations", high, disambiguation_required, provenance(45, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl045, ccss, "4.NBT.B.5: Multiply using strategies based on place value and properties of operations", high, disambiguation_required, provenance(45, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl045, illustrative_math, "Area diagrams -> Partial products -> Standard algorithm", high, disambiguation_required, provenance(45, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl045, five_practices, "Example of sequencing from concrete to abstract", high, disambiguation_required, provenance(45, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl045, cdm, "Not addressed", high, not_addressed, provenance(45, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 46: Strategies for multi-digit division
vocabulary_license(vl046, van_de_walle, "Sharing division (base-ten blocks) / Measurement division (open arrays) -> Partial quotients -> Standard algorithm", high, disambiguation_required, provenance(46, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl046, indiana, "4.CA.2: Find whole-number quotients and remainders with up to four-digit dividends and one-digit divisors", high, disambiguation_required, provenance(46, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl046, ccss, "4.NBT.B.6: Find whole-number quotients and remainders using strategies based on place value", high, disambiguation_required, provenance(46, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl046, illustrative_math, "Partial quotients -> Standard algorithm", high, disambiguation_required, provenance(46, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl046, five_practices, "Not addressed", high, not_addressed, provenance(46, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl046, cdm, "Not addressed", high, not_addressed, provenance(46, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 47: Partial products as a multiplication strategy
vocabulary_license(vl047, van_de_walle, "Partial products (each sub-rectangle in an area model)", medium, substitutable_in_context, provenance(47, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl047, indiana, "Strategies based on place value (4.CA.1)", medium, substitutable_in_context, provenance(47, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl047, ccss, "Strategies based on place value (4.NBT.B.5)", medium, substitutable_in_context, provenance(47, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl047, illustrative_math, "Partial products / Sub-rectangles in area diagrams", medium, substitutable_in_context, provenance(47, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl047, five_practices, "Not addressed", medium, not_addressed, provenance(47, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl047, cdm, "Not addressed", medium, not_addressed, provenance(47, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 48: Place value understanding for multi-digit computation
vocabulary_license(vl048, van_de_walle, "Composing and decomposing / Base-ten representations / Equivalent representations", high, disambiguation_required, provenance(48, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl048, indiana, "1.NS through 3.NS: Place value across grades (tens, hundreds, thousands)", high, disambiguation_required, provenance(48, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl048, ccss, "1.NBT through 4.NBT: Understand place value / Use place value understanding", high, disambiguation_required, provenance(48, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl048, illustrative_math, "Place value / Composing and decomposing by place value", high, disambiguation_required, provenance(48, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl048, five_practices, "Not addressed", high, not_addressed, provenance(48, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl048, cdm, "Not addressed", high, not_addressed, provenance(48, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 49: Trading 10 ones for 1 ten (or vice versa) during computation
vocabulary_license(vl049, van_de_walle, "Regrouping / Trading / Composing and decomposing", high, disambiguation_required, provenance(49, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl049, indiana, "Using number sense and place value strategies", high, disambiguation_required, provenance(49, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl049, ccss, "Compose and decompose (1.NBT.C.4)", high, disambiguation_required, provenance(49, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl049, illustrative_math, "Composing and decomposing / Regrouping", high, disambiguation_required, provenance(49, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl049, five_practices, "Not addressed", high, not_addressed, provenance(49, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl049, cdm, "Not addressed", high, not_addressed, provenance(49, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 50: The standard step-by-step procedure for an arithmetic operation
vocabulary_license(vl050, van_de_walle, "Standard algorithm (endpoint of a developmental progression)", medium, substitutable_in_context, provenance(50, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl050, indiana, "Standard algorithm (named in 4.CA.1, 5.CA.1)", medium, substitutable_in_context, provenance(50, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl050, ccss, "Standard algorithm (4.NBT.B.5, 4.NBT.B.6)", medium, substitutable_in_context, provenance(50, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl050, illustrative_math, "Standard algorithm (introduced after conceptual foundation)", medium, substitutable_in_context, provenance(50, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl050, five_practices, "Not addressed", medium, not_addressed, provenance(50, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl050, cdm, "Not addressed", medium, not_addressed, provenance(50, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 51: Using known facts and relationships to figure out unknown facts
vocabulary_license(vl051, van_de_walle, "Derived fact strategies / Reasoning strategies", medium, substitutable_in_context, provenance(51, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl051, indiana, "Strategies such as the relationship between multiplication and division (3.CA.5)", medium, substitutable_in_context, provenance(51, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl051, ccss, "Using strategies such as the relationship between multiplication and division (3.OA.C.7)", medium, substitutable_in_context, provenance(51, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl051, illustrative_math, "Using known products to find unknown products", medium, substitutable_in_context, provenance(51, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl051, five_practices, "Not addressed", medium, not_addressed, provenance(51, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl051, cdm, "Not addressed", medium, not_addressed, provenance(51, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 52: Specific addition fact strategies
vocabulary_license(vl052, van_de_walle, "One more/two more, Adding zero, Doubles, Near doubles, Combinations of 10, Making 10, Pretend-a-10 (Use 10), Using 5 as anchor", high, disambiguation_required, provenance(52, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl052, indiana, "Not named individually in standards", high, not_addressed, provenance(52, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl052, ccss, "Not named individually in standards", high, not_addressed, provenance(52, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl052, illustrative_math, "Embedded in curriculum unit progression", high, disambiguation_required, provenance(52, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl052, five_practices, "Not addressed", high, not_addressed, provenance(52, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl052, cdm, "Not addressed", high, not_addressed, provenance(52, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 53: Specific multiplication fact strategies
vocabulary_license(vl053, van_de_walle, "Doubling, Add a group (distributive property), Break apart, Making bases from N101, Skip counting", medium, substitutable_in_context, provenance(53, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl053, indiana, "Strategies such as the relationship between multiplication and division (3.CA.5)", medium, substitutable_in_context, provenance(53, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl053, ccss, "3.OA.C.7: Fluently multiply using strategies", medium, substitutable_in_context, provenance(53, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl053, illustrative_math, "Doubling, using known facts, breaking apart factors", medium, substitutable_in_context, provenance(53, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl053, five_practices, "Not addressed", medium, not_addressed, provenance(53, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl053, cdm, "Not addressed", medium, not_addressed, provenance(53, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 54: Indiana Process Standards vs. CCSS Mathematical Practices
vocabulary_license(vl054, van_de_walle, "Referenced but not systematically aligned", high, not_addressed, provenance(54, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl054, indiana, "PS.1 through PS.8 (8 Process Standards)", high, disambiguation_required, provenance(54, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl054, ccss, "MP.1 through MP.8 (8 Standards for Mathematical Practice)", high, disambiguation_required, provenance(54, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl054, illustrative_math, "MP.1 through MP.8 (uses CCSS Mathematical Practices directly)", high, disambiguation_required, provenance(54, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl054, five_practices, "Five Practices overlap with PS.1, PS.3, PS.4 but are NOT the same thing", high, disambiguation_required, provenance(54, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl054, cdm, "Talk Moves support PS.3/MP.3 specifically", high, disambiguation_required, provenance(54, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 55: Make sense of problems and persevere in solving them
vocabulary_license(vl055, van_de_walle, "Teaching through problem solving / Productive struggle", medium, substitutable_in_context, provenance(55, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl055, indiana, "PS.1", medium, substitutable_in_context, provenance(55, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl055, ccss, "MP.1", medium, substitutable_in_context, provenance(55, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl055, illustrative_math, "MP.1 (embedded in lesson design)", medium, substitutable_in_context, provenance(55, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl055, five_practices, "Practice 0 (Setting Goals) + Practice 2 (Monitoring for perseverance)", medium, substitutable_in_context, provenance(55, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl055, cdm, "Not directly addressed", medium, not_addressed, provenance(55, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 56: Model with mathematics
vocabulary_license(vl056, van_de_walle, "Multiple representations / CRA progression", high, disambiguation_required, provenance(56, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl056, indiana, "PS.4", high, disambiguation_required, provenance(56, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl056, ccss, "MP.4", high, disambiguation_required, provenance(56, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl056, illustrative_math, "MP.4 (students create representations of mathematical situations)", high, disambiguation_required, provenance(56, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl056, five_practices, "Multiple representations appear in sequencing rationale", high, disambiguation_required, provenance(56, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl056, cdm, "Not directly addressed", high, not_addressed, provenance(56, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 57: Teacher tracking which students used which strategies during work time
vocabulary_license(vl057, van_de_walle, "Observation / During phase", medium, substitutable_in_context, provenance(57, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl057, indiana, "Not addressed in standards", medium, not_addressed, provenance(57, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl057, ccss, "Not addressed in standards", medium, not_addressed, provenance(57, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl057, illustrative_math, "Monitoring suggestions in teacher guidance", medium, substitutable_in_context, provenance(57, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl057, five_practices, "Monitoring chart / Tracking student thinking", medium, substitutable_in_context, provenance(57, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl057, cdm, "Not addressed directly", medium, not_addressed, provenance(57, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 58: Selecting which student work to share in whole-class discussion
vocabulary_license(vl058, van_de_walle, "After phase preparation", high, disambiguation_required, provenance(58, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl058, indiana, "Not addressed in standards", high, not_addressed, provenance(58, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl058, ccss, "Not addressed in standards", high, not_addressed, provenance(58, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl058, illustrative_math, "Suggestions for selecting student work in teacher guides", high, disambiguation_required, provenance(58, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl058, five_practices, "Practice 3: Selecting", high, disambiguation_required, provenance(58, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl058, cdm, "Not addressed directly", high, not_addressed, provenance(58, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 59: Ordering shared student work to create a coherent mathematical storyli
vocabulary_license(vl059, van_de_walle, "Not named specifically", medium, not_addressed, provenance(59, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl059, indiana, "Not addressed in standards", medium, not_addressed, provenance(59, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl059, ccss, "Not addressed in standards", medium, not_addressed, provenance(59, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl059, illustrative_math, "Implicit in activity sequence design", medium, substitutable_in_context, provenance(59, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl059, five_practices, "Practice 4: Sequencing", medium, substitutable_in_context, provenance(59, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl059, cdm, "Not addressed directly", medium, not_addressed, provenance(59, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 60: Making explicit links between different student solutions and to learn
vocabulary_license(vl060, van_de_walle, "After phase / Summarize discussion", medium, substitutable_in_context, provenance(60, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl060, indiana, "Not addressed in standards", medium, not_addressed, provenance(60, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl060, ccss, "Not addressed in standards", medium, not_addressed, provenance(60, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl060, illustrative_math, "Synthesis phase / Making connections across representations", medium, substitutable_in_context, provenance(60, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl060, five_practices, "Practice 5: Connecting", medium, substitutable_in_context, provenance(60, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl060, cdm, "Steps 3-4 talk moves support connecting", medium, substitutable_in_context, provenance(60, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 61: Asking a student to elaborate on an unclear or brief statement
vocabulary_license(vl061, van_de_walle, "Not named specifically", low, not_addressed, provenance(61, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl061, indiana, "Not addressed", low, not_addressed, provenance(61, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl061, ccss, "Not addressed", low, not_addressed, provenance(61, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl061, illustrative_math, "Not named; embedded in teacher guidance", low, not_addressed, provenance(61, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl061, five_practices, "Part of assessing during Monitoring", low, substitutable_in_context, provenance(61, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl061, cdm, "Say More (Step 1 talk move)", low, substitutable_in_context, provenance(61, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 62: Asking students to listen to and restate another student's idea
vocabulary_license(vl062, van_de_walle, "Not named specifically", low, not_addressed, provenance(62, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl062, indiana, "Not addressed", low, not_addressed, provenance(62, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl062, ccss, "Not addressed", low, not_addressed, provenance(62, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl062, illustrative_math, "Not named; embedded in teacher guidance", low, not_addressed, provenance(62, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl062, five_practices, "Part of Connecting practice", low, substitutable_in_context, provenance(62, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl062, cdm, "Who Can Repeat? (Step 2 talk move)", low, substitutable_in_context, provenance(62, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 63: Asking students whether they agree or disagree with a claim and why
vocabulary_license(vl063, van_de_walle, "Not named specifically", low, not_addressed, provenance(63, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl063, indiana, "PS.3: Construct viable arguments and critique the reasoning of others", low, substitutable_in_context, provenance(63, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl063, ccss, "MP.3: Construct viable arguments and critique the reasoning of others", low, substitutable_in_context, provenance(63, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl063, illustrative_math, "Not named; embedded in synthesis discussions", low, not_addressed, provenance(63, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl063, five_practices, "Part of Connecting practice", low, substitutable_in_context, provenance(63, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl063, cdm, "Do You Agree or Disagree... Why? (Step 4 talk move)", low, substitutable_in_context, provenance(63, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 64: Asking students to build on what another student said
vocabulary_license(vl064, van_de_walle, "Not named specifically", low, not_addressed, provenance(64, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl064, indiana, "PS.3: Construct viable arguments and critique the reasoning of others", low, substitutable_in_context, provenance(64, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl064, ccss, "MP.3: Construct viable arguments and critique the reasoning of others", low, substitutable_in_context, provenance(64, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl064, illustrative_math, "Not named; embedded in teacher guidance", low, not_addressed, provenance(64, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl064, five_practices, "Part of Connecting practice", low, substitutable_in_context, provenance(64, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl064, cdm, "Who Can Add On? (Step 4 talk move)", low, substitutable_in_context, provenance(64, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 65: Wait time: silence after asking a question to allow thinking
vocabulary_license(vl065, van_de_walle, "Not named specifically", medium, not_addressed, provenance(65, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl065, indiana, "Not addressed", medium, not_addressed, provenance(65, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl065, ccss, "Not addressed", medium, not_addressed, provenance(65, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl065, illustrative_math, "Quiet Think Time (named in warm-up routines)", medium, substitutable_in_context, provenance(65, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl065, five_practices, "Not named; implied in monitoring", medium, not_addressed, provenance(65, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl065, cdm, "Wait Time (foundational talk move)", medium, substitutable_in_context, provenance(65, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 66: Students discussing in pairs before sharing with the whole class
vocabulary_license(vl066, van_de_walle, "Not named specifically", medium, not_addressed, provenance(66, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl066, indiana, "Not addressed", medium, not_addressed, provenance(66, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl066, ccss, "Not addressed", medium, not_addressed, provenance(66, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl066, illustrative_math, "Think-Pair-Share / Partner discussion", medium, substitutable_in_context, provenance(66, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl066, five_practices, "Not named; can be used during any practice", medium, not_addressed, provenance(66, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl066, cdm, "Turn and Talk (foundational talk move / partner discussion)", medium, substitutable_in_context, provenance(66, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 67: Teaching approach where teacher presents information to students
vocabulary_license(vl067, van_de_walle, "Lecture-based instruction / Direct instruction", medium, substitutable_in_context, provenance(67, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl067, indiana, "Not addressed in standards", medium, not_addressed, provenance(67, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl067, ccss, "Not addressed in standards", medium, not_addressed, provenance(67, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl067, illustrative_math, "Not used; IM is designed for inquiry-based instruction", medium, not_addressed, provenance(67, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl067, five_practices, "Contrasted with ambitious teaching / productive discourse", medium, substitutable_in_context, provenance(67, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl067, cdm, "Not addressed directly (CDM assumes inquiry-based context)", medium, not_addressed, provenance(67, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 68: Teaching approach where students explore problems before formal instru
vocabulary_license(vl068, van_de_walle, "Teaching through problem solving / Inquiry-based instruction", high, disambiguation_required, provenance(68, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl068, indiana, "Not specified in standards", high, not_addressed, provenance(68, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl068, ccss, "Not specified in standards", high, not_addressed, provenance(68, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl068, illustrative_math, "Problem-based curriculum / Inquiry-based lessons", high, disambiguation_required, provenance(68, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl068, five_practices, "Ambitious teaching / Orchestrating productive mathematical discussion", high, disambiguation_required, provenance(68, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl068, cdm, "Dialogic instruction (contrasted with direct instruction)", high, disambiguation_required, provenance(68, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 69: Purposeful selection of students to present, considering equity
vocabulary_license(vl069, van_de_walle, "Not addressed specifically", medium, not_addressed, provenance(69, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl069, indiana, "Not addressed in standards", medium, not_addressed, provenance(69, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl069, ccss, "Not addressed in standards", medium, not_addressed, provenance(69, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl069, illustrative_math, "Not addressed explicitly in curriculum; embedded in teacher guidance", medium, not_addressed, provenance(69, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl069, five_practices, "Part of Selecting practice: 'Bias can affect ALL of us so it is critical to pay attention to race, gender, other background factors'", medium, substitutable_in_context, provenance(69, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl069, cdm, "Chapter 2: Equitable participation in classroom talk", medium, substitutable_in_context, provenance(69, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 70: Cognitive demand of mathematical tasks
vocabulary_license(vl070, van_de_walle, "Worthwhile tasks / High-level tasks", medium, substitutable_in_context, provenance(70, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl070, indiana, "Not addressed in standards", medium, not_addressed, provenance(70, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl070, ccss, "Not addressed in standards", medium, not_addressed, provenance(70, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl070, illustrative_math, "Invitations to reason / High-demand tasks", medium, substitutable_in_context, provenance(70, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl070, five_practices, "High-demand tasks (from Stein & Smith task analysis guide)", medium, substitutable_in_context, provenance(70, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl070, cdm, "Not addressed directly", medium, not_addressed, provenance(70, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 71: Launching a lesson: setting up the task without giving away the soluti
vocabulary_license(vl071, van_de_walle, "Before phase", high, disambiguation_required, provenance(71, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl071, indiana, "Not addressed in standards", high, not_addressed, provenance(71, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl071, ccss, "Not addressed in standards", high, not_addressed, provenance(71, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl071, illustrative_math, "Launch (specific section of each activity/lesson)", high, disambiguation_required, provenance(71, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl071, five_practices, "Relates to Anticipating (Practice 1) -- prepared before launch", high, disambiguation_required, provenance(71, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl071, cdm, "Launch phase (general lesson structure)", high, disambiguation_required, provenance(71, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 72: Content strands in Indiana standards vs. CCSS domains
vocabulary_license(vl072, van_de_walle, "Chapters organized by topic (not by strand/domain)", high, disambiguation_required, provenance(72, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl072, indiana, "Number Sense (NS), Computation and Algebraic Thinking (CA), Geometry (G), Measurement (M), Data Analysis (DA)", high, disambiguation_required, provenance(72, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl072, ccss, "Counting & Cardinality (CC), Operations & Algebraic Thinking (OA), Number & Operations in Base Ten (NBT), Number & Operations -- Fractions (NF), Measurement & Data (MD), Geometry (G)", high, disambiguation_required, provenance(72, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl072, illustrative_math, "Units organized by mathematical topic, not by standard strand", high, disambiguation_required, provenance(72, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl072, five_practices, "Not addressed", high, not_addressed, provenance(72, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl072, cdm, "Not addressed", high, not_addressed, provenance(72, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 73: What Indiana calls a standard identification code
vocabulary_license(vl073, van_de_walle, "Referenced by topic/section description rather than code", high, disambiguation_required, provenance(73, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl073, indiana, "Grade.Strand.Number (e.g., 3.CA.5, 4.NS.3)", high, disambiguation_required, provenance(73, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl073, ccss, "Grade.Domain.Cluster.Standard (e.g., 3.OA.C.7, 4.NF.A.1)", high, disambiguation_required, provenance(73, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl073, illustrative_math, "References CCSS codes, not Indiana codes", high, not_addressed, provenance(73, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl073, five_practices, "Not addressed", high, not_addressed, provenance(73, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl073, cdm, "Not addressed", high, not_addressed, provenance(73, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 74: Vertical articulation: how content progresses across grade levels
vocabulary_license(vl074, van_de_walle, "Developmental perspective / Learning trajectories", medium, substitutable_in_context, provenance(74, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl074, indiana, "Vertical articulation documents (K-2, 2-3, etc.)", medium, substitutable_in_context, provenance(74, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl074, ccss, "Progressions documents (Learning Progressions for each domain)", medium, substitutable_in_context, provenance(74, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl074, illustrative_math, "Scope and sequence / Unit narrative (explains progression)", medium, substitutable_in_context, provenance(74, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl074, five_practices, "Not addressed", medium, not_addressed, provenance(74, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl074, cdm, "Not addressed", medium, not_addressed, provenance(74, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 75: Assessment built into daily instruction (not a separate test)
vocabulary_license(vl075, van_de_walle, "Formative assessment / Assessment through observation and questioning", high, disambiguation_required, provenance(75, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl075, indiana, "Not named in standards (implied)", high, not_addressed, provenance(75, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl075, ccss, "Not named in standards (implied)", high, not_addressed, provenance(75, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl075, illustrative_math, "Cool-down (end-of-lesson check) / Ongoing formative assessment", high, disambiguation_required, provenance(75, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl075, five_practices, "Assessing questions during Monitoring", high, disambiguation_required, provenance(75, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl075, cdm, "Talk moves as formative assessment tools", high, disambiguation_required, provenance(75, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 76: End-of-lesson check for student understanding
vocabulary_license(vl076, van_de_walle, "Not named specifically (part of After phase)", medium, not_addressed, provenance(76, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl076, indiana, "Not addressed in standards", medium, not_addressed, provenance(76, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl076, ccss, "Not addressed in standards", medium, not_addressed, provenance(76, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl076, illustrative_math, "Cool-down (specific section at end of each lesson)", medium, substitutable_in_context, provenance(76, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl076, five_practices, "Not named specifically (outcome of Connecting)", medium, not_addressed, provenance(76, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl076, cdm, "Not addressed", medium, not_addressed, provenance(76, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 77: Tasks, problems, activities, and exercises as units of student work
vocabulary_license(vl077, van_de_walle, "Worthwhile tasks / Story problems / Contextualized problems / Exercises (for practice)", medium, substitutable_in_context, provenance(77, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl077, indiana, "Problems (in standard language: 'Solve real-world problems...')", medium, substitutable_in_context, provenance(77, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl077, ccss, "Problems (in standard language: 'Solve real-world and mathematical problems...')", medium, substitutable_in_context, provenance(77, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl077, illustrative_math, "Activities (main sections of a lesson) / Problems (within activities) / Practice problems (homework)", medium, substitutable_in_context, provenance(77, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl077, five_practices, "Tasks (the work students do, selected in Practice 0)", medium, substitutable_in_context, provenance(77, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl077, cdm, "Not distinguished (discusses how to talk about any mathematical work)", medium, not_addressed, provenance(77, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 78: Area model as visual representation for multiplication vs. for fractio
vocabulary_license(vl078, van_de_walle, "Area model (multiplication: array of base-ten blocks; fractions: shaded region of a shape)", high, disambiguation_required, provenance(78, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl078, indiana, "Area models (3.CA.3 for multiplication; visual fraction models for fractions)", high, disambiguation_required, provenance(78, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl078, ccss, "Area models (multiplication); visual fraction models (fractions)", high, disambiguation_required, provenance(78, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl078, illustrative_math, "Area diagrams (both multiplication and fractions)", high, disambiguation_required, provenance(78, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl078, five_practices, "Not addressed", high, not_addressed, provenance(78, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl078, cdm, "Not addressed", high, not_addressed, provenance(78, 'vocabulary_crosswalk_expanded.json', "2.0")).
% -- entry 79: Open array / Open number line as a semi-concrete representation
vocabulary_license(vl079, van_de_walle, "Open array (for multiplication/division) / Open number line (for addition/subtraction)", medium, substitutable_in_context, provenance(79, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl079, indiana, "Not named in standards (strategies based on place value)", medium, not_addressed, provenance(79, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl079, ccss, "Not named in standards", medium, not_addressed, provenance(79, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl079, illustrative_math, "Open array (for multiplication/division) / Number line diagrams", medium, substitutable_in_context, provenance(79, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl079, five_practices, "Example of a representation between concrete and abstract", medium, substitutable_in_context, provenance(79, 'vocabulary_crosswalk_expanded.json', "2.0")).
vocabulary_license(vl079, cdm, "Not addressed", medium, not_addressed, provenance(79, 'vocabulary_crosswalk_expanded.json', "2.0")).
