:- encoding(utf8).
/** <module> Corpus-grounded lexicon supplement pilot
 *
 * This quarantined, authored store dispositions every word absent from the
 * slice-1 Webster demand lexicon. Rows record corpus counts and vetoable
 * lexical judgments; refused fragments remain explicit findings.
 *
 * Check from the repository root:
 * swipl -q -l paths.pl -l knowledge/strategies/abstraction/lexicon_supplement_pilot.pl -g lexicon_supplement_pilot:check_lexicon_supplement -t halt
 */

:- module(lexicon_supplement_pilot,
          [ ls_word/5, ls_phrase/3, lexicon_supplement_summary/1,
            check_lexicon_supplement/0 ]).

:- dynamic supplement_directory/1.
:- prolog_load_context(directory, Here), assertz(supplement_directory(Here)).

% abbreviation: an invariant corpus abbreviation or size label.
% adjective: a corpus-attested adjectival surface absent from Webster.
% adverb: a corpus-attested adverbial surface absent from Webster.
% algebra_symbol: a variable, Greek symbol, or labeled figure symbol.
% common_noun: a corpus noun with an authored singular and plural relation.
% contraction_fragment: a token detached from an apostrophe contraction and refused as a word.
% corpus_verb: a corpus verb with an authored five-form paradigm.
% curriculum_code: an invariant standards, lesson, routine, or source identifier used by the guides.
% family_name: a corpus token used as a person family name.
% function_word: an invariant grammatical function word.
% given_name: a corpus token used as an individual person name.
% honorific: an abbreviated personal title.
% interjection: an invariant conversational response or sound word.
% math_notation: a spreadsheet, typesetting, or mathematical notation token.
% math_term: a noun used in mathematics or classroom analysis.
% name_particle: an invariant component used within a person's name.
% named_entity: a capitalized entity, product, team, or disease label.
% pedagogy_term: a noun for an instructional routine, resource, or analysis practice.
% place_name: a capitalized place name or place-name component.
% pronunciation_token: an invariant pronunciation or transliteration component printed by a guide.
% temporal_word: a day name or relative-time noun or adverb.
% tokenizer_artifact: a fused, detached, or malformed source token refused as a word.
% unit_abbreviation: a unit abbreviation, expanded when its full form is admitted.
% unit_prefix: an invariant written name for a metric unit prefix.
% web_token: an invariant web, file-conversion, or publishing token in source metadata.

ls_word('ad', common_noun, forms(noun(ad, ads)), evidence(occurrences(12)), "The corpus uses ad as a noun, and Webster supplies no matching surface.").
ls_word('addend', math_term, forms(noun(addend, addends)), evidence(occurrences(3)), "The corpus uses addend as a mathematics or classroom-analysis noun.").
ls_word('addends', math_term, forms(noun(addend, addends)), evidence(occurrences(1)), "The corpus uses addends as a mathematics or classroom-analysis noun.").
ls_word('ads', common_noun, forms(noun(ad, ads)), evidence(occurrences(6)), "The corpus uses ads as a noun, and Webster supplies no matching surface.").
ls_word('agnes', given_name, none, evidence(occurrences(15)), "The corpus uses agnes as a capitalized name for a person.").
ls_word('aimee', given_name, none, evidence(occurrences(4)), "The corpus uses aimee as a capitalized name for a person.").
ls_word('airline', common_noun, forms(noun(airline, airlines)), evidence(occurrences(8)), "The corpus uses airline as a noun, and Webster supplies no matching surface.").
ls_word('airplane', common_noun, forms(noun(airplane, airplanes)), evidence(occurrences(32)), "The corpus uses airplane as a noun, and Webster supplies no matching surface.").
ls_word('airplanes', common_noun, forms(noun(airplane, airplanes)), evidence(occurrences(4)), "The corpus uses airplanes as a noun, and Webster supplies no matching surface.").
ls_word('airport', common_noun, forms(noun(airport, airports)), evidence(occurrences(3)), "The corpus uses airport as a noun, and Webster supplies no matching surface.").
ls_word('airtight', adjective, forms(invariant), evidence(occurrences(4)), "The corpus uses airtight adjectivally, and Webster supplies no matching surface.").
ls_word('alaskan', adjective, forms(invariant), evidence(occurrences(2)), "The corpus uses alaskan adjectivally, and Webster supplies no matching surface.").
ls_word('alex', given_name, none, evidence(occurrences(21)), "The corpus uses alex as a capitalized name for a person.").
ls_word('alice', given_name, none, evidence(occurrences(8)), "The corpus uses alice as a capitalized name for a person.").
ls_word('alisha', given_name, none, evidence(occurrences(7)), "The corpus uses alisha as a capitalized name for a person.").
ls_word('allergic', adjective, forms(invariant), evidence(occurrences(4)), "The corpus uses allergic adjectivally, and Webster supplies no matching surface.").
ls_word('amalie', given_name, none, evidence(occurrences(18)), "The corpus uses amalie as a capitalized name for a person.").
ls_word('amanda', given_name, none, evidence(occurrences(11)), "The corpus uses amanda as a capitalized name for a person.").
ls_word('amaya', given_name, none, evidence(occurrences(24)), "The corpus uses amaya as a capitalized name for a person.").
ls_word('america', place_name, none, evidence(occurrences(34)), "The corpus uses america as a capitalized place name or place-name component.").
ls_word('amoura', given_name, none, evidence(occurrences(10)), "The corpus uses amoura as a capitalized name for a person.").
ls_word('andre', given_name, none, evidence(occurrences(8)), "The corpus uses andre as a capitalized name for a person.").
ls_word('andrew', given_name, none, evidence(occurrences(17)), "The corpus uses andrew as a capitalized name for a person.").
ls_word('andy', given_name, none, evidence(occurrences(24)), "The corpus uses andy as a capitalized name for a person.").
ls_word('annie', given_name, none, evidence(occurrences(10)), "The corpus uses annie as a capitalized name for a person.").
ls_word('antonio', given_name, none, evidence(occurrences(18)), "The corpus uses antonio as a capitalized name for a person.").
ls_word('anya', given_name, none, evidence(occurrences(12)), "The corpus uses anya as a capitalized name for a person.").
ls_word('arabella', given_name, none, evidence(occurrences(15)), "The corpus uses arabella as a capitalized name for a person.").
ls_word('archie', given_name, none, evidence(occurrences(3)), "The corpus uses archie as a capitalized name for a person.").
ls_word('aren', given_name, none, evidence(occurrences(3)), "The corpus uses aren as a capitalized name for a person.").
ls_word('artemis', given_name, none, evidence(occurrences(9)), "The corpus uses artemis as a capitalized name for a person.").
ls_word('artworks', common_noun, forms(noun(artwork, artworks)), evidence(occurrences(12)), "The corpus uses artworks as a noun, and Webster supplies no matching surface.").
ls_word('arvin', given_name, none, evidence(occurrences(5)), "The corpus uses arvin as a capitalized name for a person.").
ls_word('ashley', given_name, none, evidence(occurrences(14)), "The corpus uses ashley as a capitalized name for a person.").
ls_word('aubree', given_name, none, evidence(occurrences(3)), "The corpus uses aubree as a capitalized name for a person.").
ls_word('avianna', given_name, none, evidence(occurrences(14)), "The corpus uses avianna as a capitalized name for a person.").
ls_word('aziz', given_name, none, evidence(occurrences(22)), "The corpus uses aziz as a capitalized name for a person.").
ls_word('b', algebra_symbol, forms(invariant), evidence(occurrences(59)), "The corpus uses b as a mathematical variable, Greek symbol, or labeled figure symbol.").
ls_word('babysit', corpus_verb, forms(verb(babysit, babysits, babysat, babysitting, babysat)), evidence(occurrences(4)), "The corpus uses babysit as a verb form, and the row records its full inflection.").
ls_word('babysitters', common_noun, forms(noun(babysitter, babysitters)), evidence(occurrences(2)), "The corpus uses babysitters as a noun, and Webster supplies no matching surface.").
ls_word('babysitting', corpus_verb, forms(verb(babysit, babysits, babysat, babysitting, babysat)), evidence(occurrences(3)), "The corpus uses babysitting as a verb form, and the row records its full inflection.").
ls_word('backyard', common_noun, forms(noun(backyard, backyards)), evidence(occurrences(11)), "The corpus uses backyard as a noun, and Webster supplies no matching surface.").
ls_word('backyards', common_noun, forms(noun(backyard, backyards)), evidence(occurrences(4)), "The corpus uses backyards as a noun, and Webster supplies no matching surface.").
ls_word('bali', place_name, none, evidence(occurrences(8)), "The corpus uses bali as a capitalized place name or place-name component.").
ls_word('barney', given_name, none, evidence(occurrences(8)), "The corpus uses barney as a capitalized name for a person.").
ls_word('basketball', common_noun, forms(noun(basketball, basketballs)), evidence(occurrences(15)), "The corpus uses basketball as a noun, and Webster supplies no matching surface.").
ls_word('basketballs', common_noun, forms(noun(basketball, basketballs)), evidence(occurrences(12)), "The corpus uses basketballs as a noun, and Webster supplies no matching surface.").
ls_word('bathroom', common_noun, forms(noun(bathroom, bathrooms)), evidence(occurrences(6)), "The corpus uses bathroom as a noun, and Webster supplies no matching surface.").
ls_word('bathrooms', common_noun, forms(noun(bathroom, bathrooms)), evidence(occurrences(2)), "The corpus uses bathrooms as a noun, and Webster supplies no matching surface.").
ls_word('bathtub', common_noun, forms(noun(bathtub, bathtubs)), evidence(occurrences(12)), "The corpus uses bathtub as a noun, and Webster supplies no matching surface.").
ls_word('bathwater', common_noun, forms(noun(bathwater, bathwater)), evidence(occurrences(4)), "The corpus uses bathwater as a noun, and Webster supplies no matching surface.").
ls_word('beckett', given_name, none, evidence(occurrences(6)), "The corpus uses beckett as a capitalized name for a person.").
ls_word('becky', given_name, none, evidence(occurrences(4)), "The corpus uses becky as a capitalized name for a person.").
ls_word('bella', given_name, none, evidence(occurrences(4)), "The corpus uses bella as a capitalized name for a person.").
ls_word('bert', given_name, none, evidence(occurrences(18)), "The corpus uses bert as a capitalized name for a person.").
ls_word('beth', given_name, none, evidence(occurrences(12)), "The corpus uses beth as a capitalized name for a person.").
ls_word('billie', given_name, none, evidence(occurrences(10)), "The corpus uses billie as a capitalized name for a person.").
ls_word('birdhouse', common_noun, forms(noun(birdhouse, birdhouses)), evidence(occurrences(27)), "The corpus uses birdhouse as a noun, and Webster supplies no matching surface.").
ls_word('birdhouses', common_noun, forms(noun(birdhouse, birdhouses)), evidence(occurrences(10)), "The corpus uses birdhouses as a noun, and Webster supplies no matching surface.").
ls_word('blake', given_name, none, evidence(occurrences(12)), "The corpus uses blake as a capitalized name for a person.").
ls_word('boisjoli', given_name, none, evidence(occurrences(3)), "The corpus uses boisjoli as a capitalized name for a person.").
ls_word('boyfriend', common_noun, forms(noun(boyfriend, boyfriends)), evidence(occurrences(8)), "The corpus uses boyfriend as a noun, and Webster supplies no matching surface.").
ls_word('brandon', given_name, none, evidence(occurrences(5)), "The corpus uses brandon as a capitalized name for a person.").
ls_word('brian', given_name, none, evidence(occurrences(36)), "The corpus uses brian as a capitalized name for a person.").
ls_word('brianna', given_name, none, evidence(occurrences(8)), "The corpus uses brianna as a capitalized name for a person.").
ls_word('brie', common_noun, forms(noun(brie, bries)), evidence(occurrences(6)), "The corpus uses brie as a noun, and Webster supplies no matching surface.").
ls_word('brinley', given_name, none, evidence(occurrences(27)), "The corpus uses brinley as a capitalized name for a person.").
ls_word('bronner', family_name, none, evidence(occurrences(7)), "The corpus uses bronner as a family name for a person.").
ls_word('bryan', given_name, none, evidence(occurrences(8)), "The corpus uses bryan as a capitalized name for a person.").
ls_word('bubba', given_name, none, evidence(occurrences(2)), "The corpus uses bubba as a capitalized name for a person.").
ls_word('budgeted', corpus_verb, forms(verb(budget, budgets, budgeted, budgeting, budgeted)), evidence(occurrences(10)), "The corpus uses budgeted as a verb form, and the row records its full inflection.").
ls_word('budgeting', corpus_verb, forms(verb(budget, budgets, budgeted, budgeting, budgeted)), evidence(occurrences(8)), "The corpus uses budgeting as a verb form, and the row records its full inflection.").
ls_word('c', algebra_symbol, forms(invariant), evidence(occurrences(49)), "The corpus uses c as a mathematical variable, Greek symbol, or labeled figure symbol.").
ls_word('c2', math_notation, forms(invariant), evidence(occurrences(1)), "The corpus uses c2 as a spreadsheet, typesetting, or mathematical notation token.").
ls_word('cafe', common_noun, forms(noun(cafe, cafes)), evidence(occurrences(2)), "The corpus uses cafe as a noun, and Webster supplies no matching surface.").
ls_word('cameron', given_name, none, evidence(occurrences(10)), "The corpus uses cameron as a capitalized name for a person.").
ls_word('camille', given_name, none, evidence(occurrences(4)), "The corpus uses camille as a capitalized name for a person.").
ls_word('candice', given_name, none, evidence(occurrences(21)), "The corpus uses candice as a capitalized name for a person.").
ls_word('cannot', function_word, forms(invariant), evidence(occurrences(21)), "The corpus uses cannot as an invariant grammatical function word.").
ls_word('cappuccino', common_noun, forms(noun(cappuccino, cappuccinos)), evidence(occurrences(3)), "The corpus uses cappuccino as a noun, and Webster supplies no matching surface.").
ls_word('carla', given_name, none, evidence(occurrences(53)), "The corpus uses carla as a capitalized name for a person.").
ls_word('carlos', given_name, none, evidence(occurrences(6)), "The corpus uses carlos as a capitalized name for a person.").
ls_word('carly', given_name, none, evidence(occurrences(8)), "The corpus uses carly as a capitalized name for a person.").
ls_word('carmela', given_name, none, evidence(occurrences(4)), "The corpus uses carmela as a capitalized name for a person.").
ls_word('carolyn', given_name, none, evidence(occurrences(4)), "The corpus uses carolyn as a capitalized name for a person.").
ls_word('carsharing', common_noun, forms(noun(carsharing, carsharings)), evidence(occurrences(4)), "The corpus uses carsharing as a noun, and Webster supplies no matching surface.").
ls_word('cary', given_name, none, evidence(occurrences(24)), "The corpus uses cary as a capitalized name for a person.").
ls_word('catherine', given_name, none, evidence(occurrences(4)), "The corpus uses catherine as a capitalized name for a person.").
ls_word('cathy', given_name, none, evidence(occurrences(24)), "The corpus uses cathy as a capitalized name for a person.").
ls_word('cauldron', common_noun, forms(noun(cauldron, cauldrons)), evidence(occurrences(3)), "The corpus uses cauldron as a noun, and Webster supplies no matching surface.").
ls_word('cds', abbreviation, forms(invariant), evidence(occurrences(24)), "The corpus uses cds as an invariant abbreviation or size label.").
ls_word('cecil', given_name, none, evidence(occurrences(10)), "The corpus uses cecil as a capitalized name for a person.").
ls_word('celine', given_name, none, evidence(occurrences(8)), "The corpus uses celine as a capitalized name for a person.").
ls_word('charles', given_name, none, evidence(occurrences(3)), "The corpus uses charles as a capitalized name for a person.").
ls_word('cheaper', adjective, forms(invariant), evidence(occurrences(21)), "The corpus uses cheaper adjectivally, and Webster supplies no matching surface.").
ls_word('cheesecakes', common_noun, forms(noun(cheesecake, cheesecakes)), evidence(occurrences(20)), "The corpus uses cheesecakes as a noun, and Webster supplies no matching surface.").
ls_word('chester', given_name, none, evidence(occurrences(6)), "The corpus uses chester as a capitalized name for a person.").
ls_word('chloe', given_name, none, evidence(occurrences(20)), "The corpus uses chloe as a capitalized name for a person.").
ls_word('choi', family_name, none, evidence(occurrences(8)), "The corpus uses choi as a family name for a person.").
ls_word('chris', given_name, none, evidence(occurrences(26)), "The corpus uses chris as a capitalized name for a person.").
ls_word('christina', given_name, none, evidence(occurrences(7)), "The corpus uses christina as a capitalized name for a person.").
ls_word('cindy', given_name, none, evidence(occurrences(5)), "The corpus uses cindy as a capitalized name for a person.").
ls_word('cities', common_noun, forms(noun(city, cities)), evidence(occurrences(2)), "The corpus uses cities as a noun, and Webster supplies no matching surface.").
ls_word('classroom', common_noun, forms(noun(classroom, classrooms)), evidence(occurrences(31)), "The corpus uses classroom as a noun, and Webster supplies no matching surface.").
ls_word('classrooms', common_noun, forms(noun(classroom, classrooms)), evidence(occurrences(10)), "The corpus uses classrooms as a noun, and Webster supplies no matching surface.").
ls_word('clerk', common_noun, forms(noun(clerk, clerks)), evidence(occurrences(6)), "The corpus uses clerk as a noun, and Webster supplies no matching surface.").
ls_word('cloudy', adjective, forms(invariant), evidence(occurrences(1)), "The corpus uses cloudy adjectivally, and Webster supplies no matching surface.").
ls_word('cm', unit_abbreviation, expands_to(centimeter), evidence(occurrences(48)), "The corpus uses cm as a unit abbreviation for centimeter.").
ls_word('coconut', common_noun, forms(noun(coconut, coconuts)), evidence(occurrences(32)), "The corpus uses coconut as a noun, and Webster supplies no matching surface.").
ls_word('combo', common_noun, forms(noun(combo, combos)), evidence(occurrences(6)), "The corpus uses combo as a noun, and Webster supplies no matching surface.").
ls_word('combos', common_noun, forms(noun(combo, combos)), evidence(occurrences(2)), "The corpus uses combos as a noun, and Webster supplies no matching surface.").
ls_word('comcast', named_entity, none, evidence(occurrences(3)), "The corpus uses comcast as a capitalized entity, product, team, or disease label.").
ls_word('committed', corpus_verb, forms(verb(commit, commits, committed, committing, committed)), evidence(occurrences(2)), "The corpus uses committed as a verb form, and the row records its full inflection.").
ls_word('communal', adjective, forms(invariant), evidence(occurrences(2)), "The corpus uses communal adjectivally, and Webster supplies no matching surface.").
ls_word('concentrated', adjective, forms(invariant), evidence(occurrences(4)), "The corpus uses concentrated adjectivally, and Webster supplies no matching surface.").
ls_word('condominium', common_noun, forms(noun(condominium, condominiums)), evidence(occurrences(4)), "The corpus uses condominium as a noun, and Webster supplies no matching surface.").
ls_word('connie', given_name, none, evidence(occurrences(22)), "The corpus uses connie as a capitalized name for a person.").
ls_word('cookfire', common_noun, forms(noun(cookfire, cookfires)), evidence(occurrences(6)), "The corpus uses cookfire as a noun, and Webster supplies no matching surface.").
ls_word('cookout', common_noun, forms(noun(cookout, cookouts)), evidence(occurrences(16)), "The corpus uses cookout as a noun, and Webster supplies no matching surface.").
ls_word('coordinate', math_term, forms(noun(coordinate, coordinates)), evidence(occurrences(5)), "The corpus uses coordinate as a mathematics or classroom-analysis noun.").
ls_word('coordinates', math_term, forms(noun(coordinate, coordinates)), evidence(occurrences(4)), "The corpus uses coordinates as a mathematics or classroom-analysis noun.").
ls_word('corey', given_name, none, evidence(occurrences(2)), "The corpus uses corey as a capitalized name for a person.").
ls_word('coronavirus', common_noun, forms(noun(coronavirus, coronaviruses)), evidence(occurrences(6)), "The corpus uses coronavirus as a noun, and Webster supplies no matching surface.").
ls_word('correctly', adverb, forms(invariant), evidence(occurrences(2)), "The corpus uses correctly adverbially, and Webster supplies no matching surface.").
ls_word('corresponds', corpus_verb, forms(verb(correspond, corresponds, corresponded, corresponding, corresponded)), evidence(occurrences(1)), "The corpus uses corresponds as a verb form, and the row records its full inflection.").
ls_word('cottage', common_noun, forms(noun(cottage, cottages)), evidence(occurrences(8)), "The corpus uses cottage as a noun, and Webster supplies no matching surface.").
ls_word('counterexamples', math_term, forms(noun(counterexample, counterexamples)), evidence(occurrences(1)), "The corpus uses counterexamples as a mathematics or classroom-analysis noun.").
ls_word('county', common_noun, forms(noun(county, counties)), evidence(occurrences(4)), "The corpus uses county as a noun, and Webster supplies no matching surface.").
ls_word('coupon', common_noun, forms(noun(coupon, coupons)), evidence(occurrences(30)), "The corpus uses coupon as a noun, and Webster supplies no matching surface.").
ls_word('coupons', common_noun, forms(noun(coupon, coupons)), evidence(occurrences(1)), "The corpus uses coupons as a noun, and Webster supplies no matching surface.").
ls_word('crackers', common_noun, forms(noun(cracker, crackers)), evidence(occurrences(10)), "The corpus uses crackers as a noun, and Webster supplies no matching surface.").
ls_word('crawled', corpus_verb, forms(verb(crawl, crawls, crawled, crawling, crawled)), evidence(occurrences(2)), "The corpus uses crawled as a verb form, and the row records its full inflection.").
ls_word('crayon', common_noun, forms(noun(crayon, crayons)), evidence(occurrences(1), pass(relation_emission_1)), "The corpus uses crayon as a noun; Webster holds the surface only as a verb.").
ls_word('crayons', common_noun, forms(noun(crayon, crayons)), evidence(occurrences(26), pass(relation_emission_1)), "The corpus uses crayons as a noun; Webster holds the base surface only as a verb.").
ls_word('credit', common_noun, forms(noun(credit, credits)), evidence(occurrences(5)), "The corpus uses credit as a noun, and Webster supplies no matching surface.").
ls_word('crew', common_noun, forms(noun(crew, crews)), evidence(occurrences(9)), "The corpus uses crew as a noun, and Webster supplies no matching surface.").
ls_word('croissant', common_noun, forms(noun(croissant, croissants)), evidence(occurrences(5)), "The corpus uses croissant as a noun, and Webster supplies no matching surface.").
ls_word('croissants', common_noun, forms(noun(croissant, croissants)), evidence(occurrences(25)), "The corpus uses croissants as a noun, and Webster supplies no matching surface.").
ls_word('crossword', common_noun, forms(noun(crossword, crosswords)), evidence(occurrences(7)), "The corpus uses crossword as a noun, and Webster supplies no matching surface.").
ls_word('cucumber', common_noun, forms(noun(cucumber, cucumbers)), evidence(occurrences(6)), "The corpus uses cucumber as a noun, and Webster supplies no matching surface.").
ls_word('cumulative', adjective, forms(invariant), evidence(occurrences(1)), "The corpus uses cumulative adjectivally, and Webster supplies no matching surface.").
ls_word('cube', common_noun, forms(noun(cube, cubes)), evidence(occurrences(35), pass(relation_emission_1)), "The corpus uses cube as a noun; Webster holds the surface only as a verb.").
ls_word('cubes', common_noun, forms(noun(cube, cubes)), evidence(occurrences(209), pass(relation_emission_1)), "The corpus uses cubes as a noun; Webster holds the base surface only as a verb.").
ls_word('cup', common_noun, forms(noun(cup, cups)), evidence(occurrences(78), pass(relation_emission_1)), "The corpus uses cup as a noun; Webster holds the surface only as a verb.").
ls_word('cupcake', common_noun, forms(noun(cupcake, cupcakes)), evidence(occurrences(4)), "The corpus uses cupcake as a noun, and Webster supplies no matching surface.").
ls_word('cupcakes', common_noun, forms(noun(cupcake, cupcakes)), evidence(occurrences(67)), "The corpus uses cupcakes as a noun, and Webster supplies no matching surface.").
ls_word('cups', common_noun, forms(noun(cup, cups)), evidence(occurrences(72), pass(relation_emission_1)), "The corpus uses cups as a noun; Webster holds the base surface only as a verb.").
ls_word('customer', common_noun, forms(noun(customer, customers)), evidence(occurrences(30)), "The corpus uses customer as a noun, and Webster supplies no matching surface.").
ls_word('customers', common_noun, forms(noun(customer, customers)), evidence(occurrences(143)), "The corpus uses customers as a noun, and Webster supplies no matching surface.").
ls_word('cycles', common_noun, forms(noun(cycle, cycles)), evidence(occurrences(12)), "The corpus uses cycles as a noun, and Webster supplies no matching surface.").
ls_word('cylinder', math_term, forms(noun(cylinder, cylinders)), evidence(occurrences(10)), "The corpus uses cylinder as a mathematics or classroom-analysis noun.").
ls_word('cylinders', math_term, forms(noun(cylinder, cylinders)), evidence(occurrences(3)), "The corpus uses cylinders as a mathematics or classroom-analysis noun.").
ls_word('cylindrical', adjective, forms(invariant), evidence(occurrences(11)), "The corpus uses cylindrical adjectivally, and Webster supplies no matching surface.").
ls_word('cyrus', given_name, none, evidence(occurrences(8)), "The corpus uses cyrus as a capitalized name for a person.").
ls_word('d', algebra_symbol, forms(invariant), evidence(occurrences(22)), "The corpus uses d as a mathematical variable, Greek symbol, or labeled figure symbol.").
ls_word('d2', math_notation, forms(invariant), evidence(occurrences(1)), "The corpus uses d2 as a spreadsheet, typesetting, or mathematical notation token.").
ls_word('dakota', given_name, none, evidence(occurrences(19)), "The corpus uses dakota as a capitalized name for a person.").
ls_word('danai', given_name, none, evidence(occurrences(11)), "The corpus uses danai as a capitalized name for a person.").
ls_word('dani', given_name, none, evidence(occurrences(8)), "The corpus uses dani as a capitalized name for a person.").
ls_word('danielle', given_name, none, evidence(occurrences(7)), "The corpus uses danielle as a capitalized name for a person.").
ls_word('danny', given_name, none, evidence(occurrences(8)), "The corpus uses danny as a capitalized name for a person.").
ls_word('dara', given_name, none, evidence(occurrences(10)), "The corpus uses dara as a capitalized name for a person.").
ls_word('david', given_name, none, evidence(occurrences(24)), "The corpus uses david as a capitalized name for a person.").
ls_word('davis', given_name, none, evidence(occurrences(12)), "The corpus uses davis as a capitalized name for a person.").
ls_word('daycare', common_noun, forms(noun(daycare, daycares)), evidence(occurrences(4)), "The corpus uses daycare as a noun, and Webster supplies no matching surface.").
ls_word('deadline', common_noun, forms(noun(deadline, deadlines)), evidence(occurrences(6)), "The corpus uses deadline as a noun, and Webster supplies no matching surface.").
ls_word('debra', given_name, none, evidence(occurrences(7)), "The corpus uses debra as a capitalized name for a person.").
ls_word('deforestation', common_noun, forms(noun(deforestation, deforestation)), evidence(occurrences(1)), "The corpus uses deforestation as a noun, and Webster supplies no matching surface.").
ls_word('delaney', given_name, none, evidence(occurrences(8)), "The corpus uses delaney as a capitalized name for a person.").
ls_word('denny', given_name, none, evidence(occurrences(3)), "The corpus uses denny as a capitalized name for a person.").
ls_word('denver', place_name, none, evidence(occurrences(16)), "The corpus uses denver as a capitalized place name or place-name component.").
ls_word('descriptor', math_term, forms(noun(descriptor, descriptors)), evidence(occurrences(1)), "The corpus uses descriptor as a mathematics or classroom-analysis noun.").
ls_word('deshaun', given_name, none, evidence(occurrences(4)), "The corpus uses deshaun as a capitalized name for a person.").
ls_word('desktop', common_noun, forms(noun(desktop, desktops)), evidence(occurrences(1)), "The corpus uses desktop as a noun, and Webster supplies no matching surface.").
ls_word('devin', given_name, none, evidence(occurrences(12)), "The corpus uses devin as a capitalized name for a person.").
ls_word('diane', given_name, none, evidence(occurrences(1)), "The corpus uses diane as a capitalized name for a person.").
ls_word('dianne', given_name, none, evidence(occurrences(5)), "The corpus uses dianne as a capitalized name for a person.").
ls_word('didn', contraction_fragment, none, evidence(occurrences(14)), "The tokenizer detached didn from an apostrophe contraction, so the fragment is not admitted as a word.").
ls_word('diego', given_name, none, evidence(occurrences(13)), "The corpus uses diego as a capitalized name for a person.").
ls_word('dodgeballs', common_noun, forms(noun(dodgeball, dodgeballs)), evidence(occurrences(4)), "The corpus uses dodgeballs as a noun, and Webster supplies no matching surface.").
ls_word('doesn', contraction_fragment, none, evidence(occurrences(22)), "The tokenizer detached doesn from an apostrophe contraction, so the fragment is not admitted as a word.").
ls_word('donut', common_noun, forms(noun(donut, donuts)), evidence(occurrences(8)), "The corpus uses donut as a noun, and Webster supplies no matching surface.").
ls_word('donuts', common_noun, forms(noun(donut, donuts)), evidence(occurrences(61)), "The corpus uses donuts as a noun, and Webster supplies no matching surface.").
ls_word('dorothy', given_name, none, evidence(occurrences(4)), "The corpus uses dorothy as a capitalized name for a person.").
ls_word('download', common_noun, forms(noun(download, downloads)), evidence(occurrences(80)), "The corpus uses download as a noun, and Webster supplies no matching surface.").
ls_word('downloaded', corpus_verb, forms(verb(download, downloads, downloaded, downloading, downloaded)), evidence(occurrences(5)), "The corpus uses downloaded as a verb form, and the row records its full inflection.").
ls_word('downloading', corpus_verb, forms(verb(download, downloads, downloaded, downloading, downloaded)), evidence(occurrences(10)), "The corpus uses downloading as a verb form, and the row records its full inflection.").
ls_word('downpayment', common_noun, forms(noun(downpayment, downpayments)), evidence(occurrences(6)), "The corpus uses downpayment as a noun, and Webster supplies no matching surface.").
ls_word('dr', honorific, forms(invariant), evidence(occurrences(13)), "The corpus uses dr as an abbreviated personal title.").
ls_word('dumbbell', common_noun, forms(noun(dumbbell, dumbbells)), evidence(occurrences(3)), "The corpus uses dumbbell as a noun, and Webster supplies no matching surface.").
ls_word('dumbbells', common_noun, forms(noun(dumbbell, dumbbells)), evidence(occurrences(6)), "The corpus uses dumbbells as a noun, and Webster supplies no matching surface.").
ls_word('dumpster', common_noun, forms(noun(dumpster, dumpsters)), evidence(occurrences(6)), "The corpus uses dumpster as a noun, and Webster supplies no matching surface.").
ls_word('e', algebra_symbol, forms(invariant), evidence(occurrences(1)), "The corpus uses e as a mathematical variable, Greek symbol, or labeled figure symbol.").
ls_word('earbuds', common_noun, forms(noun(earbud, earbuds)), evidence(occurrences(5)), "The corpus uses earbuds as a noun, and Webster supplies no matching surface.").
ls_word('electronics', common_noun, forms(noun(electronics, electronics)), evidence(occurrences(6)), "The corpus uses electronics as a noun, and Webster supplies no matching surface.").
ls_word('elena', given_name, none, evidence(occurrences(7)), "The corpus uses elena as a capitalized name for a person.").
ls_word('eliana', given_name, none, evidence(occurrences(8)), "The corpus uses eliana as a capitalized name for a person.").
ls_word('elise', given_name, none, evidence(occurrences(30)), "The corpus uses elise as a capitalized name for a person.").
ls_word('ella', given_name, none, evidence(occurrences(22)), "The corpus uses ella as a capitalized name for a person.").
ls_word('elliott', given_name, none, evidence(occurrences(42)), "The corpus uses elliott as a capitalized name for a person.").
ls_word('elsa', given_name, none, evidence(occurrences(6)), "The corpus uses elsa as a capitalized name for a person.").
ls_word('email', common_noun, forms(noun(email, emails)), evidence(occurrences(2)), "The corpus uses email as a noun, and Webster supplies no matching surface.").
ls_word('emails', common_noun, forms(noun(email, emails)), evidence(occurrences(25)), "The corpus uses emails as a noun, and Webster supplies no matching surface.").
ls_word('emily', given_name, none, evidence(occurrences(10)), "The corpus uses emily as a capitalized name for a person.").
ls_word('emma', given_name, none, evidence(occurrences(10)), "The corpus uses emma as a capitalized name for a person.").
ls_word('encourage', corpus_verb, forms(verb(encourage, encourages, encouraged, encouraging, encouraged)), evidence(occurrences(5)), "The corpus uses encourage as a verb form, and the row records its full inflection.").
ls_word('espresso', common_noun, forms(noun(espresso, espressos)), evidence(occurrences(2)), "The corpus uses espresso as a noun, and Webster supplies no matching surface.").
ls_word('etc', abbreviation, forms(invariant), evidence(occurrences(1)), "The corpus uses etc as an invariant abbreviation or size label.").
ls_word('ethereum', named_entity, none, evidence(occurrences(3)), "The corpus uses ethereum as a capitalized entity, product, team, or disease label.").
ls_word('euro', common_noun, forms(noun(euro, euros)), evidence(occurrences(4)), "The corpus uses euro as a noun, and Webster supplies no matching surface.").
ls_word('euros', common_noun, forms(noun(euro, euros)), evidence(occurrences(6)), "The corpus uses euros as a noun, and Webster supplies no matching surface.").
ls_word('eva', given_name, none, evidence(occurrences(4)), "The corpus uses eva as a capitalized name for a person.").
ls_word('ever', adverb, forms(invariant), evidence(occurrences(3)), "The corpus uses ever adverbially, and Webster supplies no matching surface.").
ls_word('exam', common_noun, forms(noun(exam, exams)), evidence(occurrences(12)), "The corpus uses exam as a noun, and Webster supplies no matching surface.").
ls_word('exams', common_noun, forms(noun(exam, exams)), evidence(occurrences(2)), "The corpus uses exams as a noun, and Webster supplies no matching surface.").
ls_word('extracurricular', adjective, forms(invariant), evidence(occurrences(5)), "The corpus uses extracurricular adjectivally, and Webster supplies no matching surface.").
ls_word('extracurriculars', common_noun, forms(noun(extracurricular, extracurriculars)), evidence(occurrences(3)), "The corpus uses extracurriculars as a noun, and Webster supplies no matching surface.").
ls_word('fatima', given_name, none, evidence(occurrences(5)), "The corpus uses fatima as a capitalized name for a person.").
ls_word('feedback', common_noun, forms(noun(feedback, feedback)), evidence(occurrences(1)), "The corpus uses feedback as a noun, and Webster supplies no matching surface.").
ls_word('fernando', given_name, none, evidence(occurrences(6)), "The corpus uses fernando as a capitalized name for a person.").
ls_word('flamethrower', common_noun, forms(noun(flamethrower, flamethrowers)), evidence(occurrences(1)), "The corpus uses flamethrower as a noun, and Webster supplies no matching surface.").
ls_word('frac', math_notation, forms(invariant), evidence(occurrences(1)), "The corpus uses frac as a spreadsheet, typesetting, or mathematical notation token.").
ls_word('francisco', place_name, none, evidence(occurrences(1)), "The corpus uses francisco as a capitalized place name or place-name component.").
ls_word('frankie', given_name, none, evidence(occurrences(4)), "The corpus uses frankie as a capitalized name for a person.").
ls_word('ft', unit_abbreviation, expands_to(foot), evidence(occurrences(54)), "The corpus uses ft as a unit abbreviation for foot.").
ls_word('fundraiser', common_noun, forms(noun(fundraiser, fundraisers)), evidence(occurrences(4)), "The corpus uses fundraiser as a noun, and Webster supplies no matching surface.").
ls_word('gavin', given_name, none, evidence(occurrences(6)), "The corpus uses gavin as a capitalized name for a person.").
ls_word('gb', unit_abbreviation, expands_to(gigabyte), evidence(occurrences(70)), "The corpus uses gb as a unit abbreviation for gigabyte.").
ls_word('gemstones', common_noun, forms(noun(gemstone, gemstones)), evidence(occurrences(26)), "The corpus uses gemstones as a noun, and Webster supplies no matching surface.").
ls_word('geoblocks', math_term, forms(noun(geoblock, geoblocks)), evidence(occurrences(1)), "The corpus uses geoblocks as a mathematics or classroom-analysis noun.").
ls_word('geoff', given_name, none, evidence(occurrences(8)), "The corpus uses geoff as a capitalized name for a person.").
ls_word('geometry', math_term, forms(noun(geometry, geometries)), evidence(occurrences(2)), "The corpus uses geometry as a mathematics or classroom-analysis noun.").
ls_word('germany', place_name, none, evidence(occurrences(7)), "The corpus uses germany as a capitalized place name or place-name component.").
ls_word('gigabytes', common_noun, forms(noun(gigabyte, gigabytes)), evidence(occurrences(5)), "The corpus uses gigabytes as a noun, and Webster supplies no matching surface.").
ls_word('gina', given_name, none, evidence(occurrences(8)), "The corpus uses gina as a capitalized name for a person.").
ls_word('girlfriend', common_noun, forms(noun(girlfriend, girlfriends)), evidence(occurrences(8)), "The corpus uses girlfriend as a noun, and Webster supplies no matching surface.").
ls_word('giselle', given_name, none, evidence(occurrences(12)), "The corpus uses giselle as a capitalized name for a person.").
ls_word('giuliana', given_name, none, evidence(occurrences(3)), "The corpus uses giuliana as a capitalized name for a person.").
ls_word('glenn', given_name, none, evidence(occurrences(6)), "The corpus uses glenn as a capitalized name for a person.").
ls_word('goodie', common_noun, forms(noun(goodie, goodies)), evidence(occurrences(2)), "The corpus uses goodie as a noun, and Webster supplies no matching surface.").
ls_word('gotten', corpus_verb, forms(verb(get, gets, got, getting, gotten)), evidence(occurrences(10)), "The corpus uses gotten as a verb form, and the row records its full inflection.").
ls_word('graham', adjective, forms(invariant), evidence(occurrences(10)), "The corpus uses graham adjectivally, and Webster supplies no matching surface.").
ls_word('grandchildren', common_noun, forms(noun(grandchild, grandchildren)), evidence(occurrences(8)), "The corpus uses grandchildren as a noun, and Webster supplies no matching surface.").
ls_word('granville', place_name, none, evidence(occurrences(7)), "The corpus uses granville as a capitalized place name or place-name component.").
ls_word('graph', math_term, forms(noun(graph, graphs)), evidence(occurrences(20)), "The corpus uses graph as a mathematics or classroom-analysis noun.").
ls_word('graphed', corpus_verb, forms(verb(graph, graphs, graphed, graphing, graphed)), evidence(occurrences(1)), "The corpus uses graphed as a verb form, and the row records its full inflection.").
ls_word('graphs', common_noun, forms(noun(graph, graphs)), evidence(occurrences(8)), "The corpus uses graphs as a noun, and Webster supplies no matching surface.").
ls_word('grayson', family_name, none, evidence(occurrences(7)), "The corpus uses grayson as a family name for a person.").
ls_word('gremlins', named_entity, none, evidence(occurrences(4)), "The corpus uses gremlins as a capitalized entity, product, team, or disease label.").
ls_word('guidelines', common_noun, forms(noun(guideline, guidelines)), evidence(occurrences(2)), "The corpus uses guidelines as a noun, and Webster supplies no matching surface.").
ls_word('gumballs', common_noun, forms(noun(gumball, gumballs)), evidence(occurrences(41)), "The corpus uses gumballs as a noun, and Webster supplies no matching surface.").
ls_word('gym', common_noun, forms(noun(gym, gyms)), evidence(occurrences(6)), "The corpus uses gym as a noun, and Webster supplies no matching surface.").
ls_word('h', algebra_symbol, forms(invariant), evidence(occurrences(5)), "The corpus uses h as a mathematical variable, Greek symbol, or labeled figure symbol.").
ls_word('hadn', contraction_fragment, none, evidence(occurrences(1)), "The tokenizer detached hadn from an apostrophe contraction, so the fragment is not admitted as a word.").
ls_word('haircut', common_noun, forms(noun(haircut, haircuts)), evidence(occurrences(9)), "The corpus uses haircut as a noun, and Webster supplies no matching surface.").
ls_word('haircuts', common_noun, forms(noun(haircut, haircuts)), evidence(occurrences(49)), "The corpus uses haircuts as a noun, and Webster supplies no matching surface.").
ls_word('hamburger', common_noun, forms(noun(hamburger, hamburgers)), evidence(occurrences(8)), "The corpus uses hamburger as a noun, and Webster supplies no matching surface.").
ls_word('hamburgers', common_noun, forms(noun(hamburger, hamburgers)), evidence(occurrences(34)), "The corpus uses hamburgers as a noun, and Webster supplies no matching surface.").
ls_word('hamza', given_name, none, evidence(occurrences(3)), "The corpus uses hamza as a capitalized name for a person.").
ls_word('han', given_name, none, evidence(occurrences(9)), "The corpus uses han as a capitalized name for a person.").
ls_word('hanna', given_name, none, evidence(occurrences(12)), "The corpus uses hanna as a capitalized name for a person.").
ls_word('hardcover', common_noun, forms(noun(hardcover, hardcovers)), evidence(occurrences(4)), "The corpus uses hardcover as a noun, and Webster supplies no matching surface.").
ls_word('harold', given_name, none, evidence(occurrences(3)), "The corpus uses harold as a capitalized name for a person.").
ls_word('hawaii', place_name, none, evidence(occurrences(3)), "The corpus uses hawaii as a capitalized place name or place-name component.").
ls_word('hawkins', family_name, none, evidence(occurrences(10)), "The corpus uses hawkins as a family name for a person.").
ls_word('hawksbill', common_noun, forms(noun(hawksbill, hawksbills)), evidence(occurrences(6)), "The corpus uses hawksbill as a noun, and Webster supplies no matching surface.").
ls_word('hayden', given_name, none, evidence(occurrences(7)), "The corpus uses hayden as a capitalized name for a person.").
ls_word('hayes', given_name, none, evidence(occurrences(2)), "The corpus uses hayes as a capitalized name for a person.").
ls_word('headphones', common_noun, forms(noun(headphone, headphones)), evidence(occurrences(8)), "The corpus uses headphones as a noun, and Webster supplies no matching surface.").
ls_word('highlight', corpus_verb, forms(verb(highlight, highlights, highlighted, highlighting, highlighted)), evidence(occurrences(2)), "The corpus uses highlight as a verb form, and the row records its full inflection.").
ls_word('hiker', common_noun, forms(noun(hiker, hikers)), evidence(occurrences(1)), "The corpus uses hiker as a noun, and Webster supplies no matching surface.").
ls_word('hilary', given_name, none, evidence(occurrences(4)), "The corpus uses hilary as a capitalized name for a person.").
ls_word('hillary', given_name, none, evidence(occurrences(8)), "The corpus uses hillary as a capitalized name for a person.").
ls_word('histogram', math_term, forms(noun(histogram, histograms)), evidence(occurrences(1)), "The corpus uses histogram as a mathematics or classroom-analysis noun.").
ls_word('histograms', math_term, forms(noun(histogram, histograms)), evidence(occurrences(1)), "The corpus uses histograms as a mathematics or classroom-analysis noun.").
ls_word('homework', common_noun, forms(noun(homework, homework)), evidence(occurrences(38)), "The corpus uses homework as a noun, and Webster supplies no matching surface.").
ls_word('hortense', given_name, none, evidence(occurrences(12)), "The corpus uses hortense as a capitalized name for a person.").
ls_word('hotdog', common_noun, forms(noun(hotdog, hotdogs)), evidence(occurrences(32)), "The corpus uses hotdog as a noun, and Webster supplies no matching surface.").
ls_word('hotdogs', common_noun, forms(noun(hotdog, hotdogs)), evidence(occurrences(53)), "The corpus uses hotdogs as a noun, and Webster supplies no matching surface.").
ls_word('hs', algebra_symbol, forms(invariant), evidence(occurrences(1)), "The corpus uses hs as a mathematical variable, Greek symbol, or labeled figure symbol.").
ls_word('hung', corpus_verb, forms(verb(hang, hangs, hung, hanging, hung)), evidence(occurrences(1)), "The corpus uses hung as a verb form, and the row records its full inflection.").
ls_word('ignatius', given_name, none, evidence(occurrences(24)), "The corpus uses ignatius as a capitalized name for a person.").
ls_word('inbox', common_noun, forms(noun(inbox, inboxes)), evidence(occurrences(7)), "The corpus uses inbox as a noun, and Webster supplies no matching surface.").
ls_word('ingrid', given_name, none, evidence(occurrences(10)), "The corpus uses ingrid as a capitalized name for a person.").
ls_word('input', math_term, forms(noun(input, inputs)), evidence(occurrences(1)), "The corpus uses input as a mathematics or classroom-analysis noun.").
ls_word('inputs', math_term, forms(noun(input, inputs)), evidence(occurrences(1)), "The corpus uses inputs as a mathematics or classroom-analysis noun.").
ls_word('instagram', named_entity, none, evidence(occurrences(2)), "The corpus uses instagram as a capitalized entity, product, team, or disease label.").
ls_word('iphone', named_entity, none, evidence(occurrences(4)), "The corpus uses iphone as a capitalized entity, product, team, or disease label.").
ls_word('iqr', math_notation, forms(invariant), evidence(occurrences(1)), "The corpus uses iqr as a spreadsheet, typesetting, or mathematical notation token.").
ls_word('italy', place_name, none, evidence(occurrences(2)), "The corpus uses italy as a capitalized place name or place-name component.").
ls_word('ittymangnark', given_name, none, evidence(occurrences(4)), "The corpus uses ittymangnark as a capitalized name for a person.").
ls_word('ivan', given_name, none, evidence(occurrences(17)), "The corpus uses ivan as a capitalized name for a person.").
ls_word('j', algebra_symbol, forms(invariant), evidence(occurrences(1)), "The corpus uses j as a mathematical variable, Greek symbol, or labeled figure symbol.").
ls_word('jace', given_name, none, evidence(occurrences(10)), "The corpus uses jace as a capitalized name for a person.").
ls_word('jackson', given_name, none, evidence(occurrences(23)), "The corpus uses jackson as a capitalized name for a person.").
ls_word('jaco', given_name, none, evidence(occurrences(20)), "The corpus uses jaco as a capitalized name for a person.").
ls_word('jada', given_name, none, evidence(occurrences(3)), "The corpus uses jada as a capitalized name for a person.").
ls_word('jake', given_name, none, evidence(occurrences(59)), "The corpus uses jake as a capitalized name for a person.").
ls_word('jalapeno', common_noun, forms(noun(jalapeno, jalapenos)), evidence(occurrences(13)), "The corpus uses jalapeno as a noun, and Webster supplies no matching surface.").
ls_word('jame', given_name, none, evidence(occurrences(6)), "uncertain: the corpus capitalizes Jame as a person's name, but the spelling may be an error.").
ls_word('james', given_name, none, evidence(occurrences(125)), "The corpus uses james as a capitalized name for a person.").
ls_word('janet', given_name, none, evidence(occurrences(6)), "The corpus uses janet as a capitalized name for a person.").
ls_word('janice', given_name, none, evidence(occurrences(14)), "The corpus uses janice as a capitalized name for a person.").
ls_word('jason', given_name, none, evidence(occurrences(21)), "The corpus uses jason as a capitalized name for a person.").
ls_word('javier', given_name, none, evidence(occurrences(6)), "The corpus uses javier as a capitalized name for a person.").
ls_word('jeanette', given_name, none, evidence(occurrences(8)), "The corpus uses jeanette as a capitalized name for a person.").
ls_word('jeff', given_name, none, evidence(occurrences(21)), "The corpus uses jeff as a capitalized name for a person.").
ls_word('jeffrey', given_name, none, evidence(occurrences(7)), "The corpus uses jeffrey as a capitalized name for a person.").
ls_word('jen', given_name, none, evidence(occurrences(12)), "The corpus uses jen as a capitalized name for a person.").
ls_word('jenga', named_entity, none, evidence(occurrences(2)), "The corpus uses jenga as a capitalized entity, product, team, or disease label.").
ls_word('jennifer', given_name, none, evidence(occurrences(8)), "The corpus uses jennifer as a capitalized name for a person.").
ls_word('jerry', given_name, none, evidence(occurrences(31)), "The corpus uses jerry as a capitalized name for a person.").
ls_word('jessica', given_name, none, evidence(occurrences(18)), "The corpus uses jessica as a capitalized name for a person.").
ls_word('jethro', given_name, none, evidence(occurrences(20)), "The corpus uses jethro as a capitalized name for a person.").
ls_word('jim', given_name, none, evidence(occurrences(44)), "The corpus uses jim as a capitalized name for a person.").
ls_word('jina', given_name, none, evidence(occurrences(11)), "The corpus uses jina as a capitalized name for a person.").
ls_word('joanie', given_name, none, evidence(occurrences(12)), "The corpus uses joanie as a capitalized name for a person.").
ls_word('joey', given_name, none, evidence(occurrences(55)), "The corpus uses joey as a capitalized name for a person.").
ls_word('johnson', family_name, none, evidence(occurrences(16)), "The corpus uses johnson as a family name for a person.").
ls_word('jones', family_name, none, evidence(occurrences(8)), "The corpus uses jones as a family name for a person.").
ls_word('jorge', given_name, none, evidence(occurrences(3)), "The corpus uses jorge as a capitalized name for a person.").
ls_word('jose', given_name, none, evidence(occurrences(7)), "The corpus uses jose as a capitalized name for a person.").
ls_word('josh', given_name, none, evidence(occurrences(63)), "The corpus uses josh as a capitalized name for a person.").
ls_word('jr', honorific, forms(invariant), evidence(occurrences(1)), "The corpus uses jr as an abbreviated personal title.").
ls_word('juan', given_name, none, evidence(occurrences(20)), "The corpus uses juan as a capitalized name for a person.").
ls_word('judah', given_name, none, evidence(occurrences(5)), "The corpus uses judah as a capitalized name for a person.").
ls_word('julia', given_name, none, evidence(occurrences(114)), "The corpus uses julia as a capitalized name for a person.").
ls_word('julie', given_name, none, evidence(occurrences(18)), "The corpus uses julie as a capitalized name for a person.").
ls_word('jumbo', adjective, forms(invariant), evidence(occurrences(7)), "The corpus uses jumbo adjectivally, and Webster supplies no matching surface.").
ls_word('kamil', given_name, none, evidence(occurrences(5)), "The corpus uses kamil as a capitalized name for a person.").
ls_word('karan', given_name, none, evidence(occurrences(30)), "The corpus uses karan as a capitalized name for a person.").
ls_word('karina', given_name, none, evidence(occurrences(24)), "The corpus uses karina as a capitalized name for a person.").
ls_word('karts', common_noun, forms(noun(kart, karts)), evidence(occurrences(35)), "The corpus uses karts as a noun, and Webster supplies no matching surface.").
ls_word('katrina', given_name, none, evidence(occurrences(9)), "The corpus uses katrina as a capitalized name for a person.").
ls_word('kaylee', given_name, none, evidence(occurrences(4)), "The corpus uses kaylee as a capitalized name for a person.").
ls_word('keenan', given_name, none, evidence(occurrences(5)), "The corpus uses keenan as a capitalized name for a person.").
ls_word('kendra', given_name, none, evidence(occurrences(32)), "The corpus uses kendra as a capitalized name for a person.").
ls_word('kenny', given_name, none, evidence(occurrences(20)), "The corpus uses kenny as a capitalized name for a person.").
ls_word('kerry', given_name, none, evidence(occurrences(15)), "The corpus uses kerry as a capitalized name for a person.").
ls_word('keziah', given_name, none, evidence(occurrences(5)), "The corpus uses keziah as a capitalized name for a person.").
ls_word('kg', unit_abbreviation, expands_to(kilogram), evidence(occurrences(143)), "The corpus uses kg as a unit abbreviation for kilogram.").
ls_word('kgs', unit_abbreviation, expands_to(kilogram), evidence(occurrences(12)), "The corpus uses kgs as a unit abbreviation for kilogram.").
ls_word('kiddie', adjective, forms(invariant), evidence(occurrences(18)), "The corpus uses kiddie adjectivally, and Webster supplies no matching surface.").
ls_word('kiki', given_name, none, evidence(occurrences(8)), "The corpus uses kiki as a capitalized name for a person.").
ls_word('kilobyte', common_noun, forms(noun(kilobyte, kilobytes)), evidence(occurrences(5)), "The corpus uses kilobyte as a noun, and Webster supplies no matching surface.").
ls_word('kilobytes', common_noun, forms(noun(kilobyte, kilobytes)), evidence(occurrences(12)), "The corpus uses kilobytes as a noun, and Webster supplies no matching surface.").
ls_word('kingnook', given_name, none, evidence(occurrences(2)), "The corpus uses kingnook as a capitalized name for a person.").
ls_word('kiran', given_name, none, evidence(occurrences(4)), "The corpus uses kiran as a capitalized name for a person.").
ls_word('kiwi', common_noun, forms(noun(kiwi, kiwis)), evidence(occurrences(3)), "The corpus uses kiwi as a noun, and Webster supplies no matching surface.").
ls_word('km', unit_abbreviation, expands_to(kilometer), evidence(occurrences(40)), "The corpus uses km as a unit abbreviation for kilometer.").
ls_word('kristin', given_name, none, evidence(occurrences(12)), "The corpus uses kristin as a capitalized name for a person.").
ls_word('kwh', unit_abbreviation, forms(invariant), evidence(occurrences(1)), "The corpus uses kwh as a unit abbreviation.").
ls_word('kyle', given_name, none, evidence(occurrences(12)), "The corpus uses kyle as a capitalized name for a person.").
ls_word('l', unit_abbreviation, forms(invariant), evidence(occurrences(26)), "The corpus uses l as a unit abbreviation.").
ls_word('landscaping', common_noun, forms(noun(landscaping, landscaping)), evidence(occurrences(4)), "The corpus uses landscaping as a noun, and Webster supplies no matching surface.").
ls_word('lara', given_name, none, evidence(occurrences(8)), "The corpus uses lara as a capitalized name for a person.").
ls_word('latte', common_noun, forms(noun(latte, lattes)), evidence(occurrences(2)), "The corpus uses latte as a noun, and Webster supplies no matching surface.").
ls_word('lattes', common_noun, forms(noun(latte, lattes)), evidence(occurrences(5)), "The corpus uses lattes as a noun, and Webster supplies no matching surface.").
ls_word('launderette', common_noun, forms(noun(launderette, launderettes)), evidence(occurrences(8)), "The corpus uses launderette as a noun, and Webster supplies no matching surface.").
ls_word('lawnmower', common_noun, forms(noun(lawnmower, lawnmowers)), evidence(occurrences(10)), "The corpus uses lawnmower as a noun, and Webster supplies no matching surface.").
ls_word('lawnmowers', common_noun, forms(noun(lawnmower, lawnmowers)), evidence(occurrences(4)), "The corpus uses lawnmowers as a noun, and Webster supplies no matching surface.").
ls_word('lb', unit_abbreviation, expands_to(pound), evidence(occurrences(7)), "The corpus uses lb as a unit abbreviation for pound.").
ls_word('lbs', unit_abbreviation, expands_to(pound), evidence(occurrences(10)), "The corpus uses lbs as a unit abbreviation for pound.").
ls_word('leah', given_name, none, evidence(occurrences(8)), "The corpus uses leah as a capitalized name for a person.").
ls_word('leftover', common_noun, forms(noun(leftover, leftovers)), evidence(occurrences(18)), "The corpus uses leftover as a noun, and Webster supplies no matching surface.").
ls_word('leftovers', common_noun, forms(noun(leftover, leftovers)), evidence(occurrences(6)), "The corpus uses leftovers as a noun, and Webster supplies no matching surface.").
ls_word('lego', named_entity, none, evidence(occurrences(45)), "The corpus uses lego as a capitalized entity, product, team, or disease label.").
ls_word('leila', given_name, none, evidence(occurrences(10)), "The corpus uses leila as a capitalized name for a person.").
ls_word('levi', given_name, none, evidence(occurrences(45)), "The corpus uses levi as a capitalized name for a person.").
ls_word('liam', given_name, none, evidence(occurrences(3)), "The corpus uses liam as a capitalized name for a person.").
ls_word('lilibeth', given_name, none, evidence(occurrences(24)), "The corpus uses lilibeth as a capitalized name for a person.").
ls_word('lilith', given_name, none, evidence(occurrences(11)), "The corpus uses lilith as a capitalized name for a person.").
ls_word('lillian', given_name, none, evidence(occurrences(8)), "The corpus uses lillian as a capitalized name for a person.").
ls_word('lisa', given_name, none, evidence(occurrences(56)), "The corpus uses lisa as a capitalized name for a person.").
ls_word('ll', contraction_fragment, none, evidence(occurrences(13)), "The tokenizer detached ll from an apostrophe contraction, so the fragment is not admitted as a word.").
ls_word('lopez', family_name, none, evidence(occurrences(8)), "The corpus uses lopez as a family name for a person.").
ls_word('lou', given_name, none, evidence(occurrences(6)), "The corpus uses lou as a capitalized name for a person.").
ls_word('louie', given_name, none, evidence(occurrences(10)), "The corpus uses louie as a capitalized name for a person.").
ls_word('lucian', given_name, none, evidence(occurrences(4)), "The corpus uses lucian as a capitalized name for a person.").
ls_word('lyle', given_name, none, evidence(occurrences(9)), "The corpus uses lyle as a capitalized name for a person.").
ls_word('m', algebra_symbol, forms(invariant), evidence(occurrences(91)), "The corpus uses m as a mathematical variable, Greek symbol, or labeled figure symbol.").
ls_word('mabel', given_name, none, evidence(occurrences(9)), "The corpus uses mabel as a capitalized name for a person.").
ls_word('mac', given_name, none, evidence(occurrences(9)), "The corpus uses mac as a capitalized name for a person.").
ls_word('mack', given_name, none, evidence(occurrences(2)), "The corpus uses mack as a capitalized name for a person.").
ls_word('madeline', given_name, none, evidence(occurrences(35)), "The corpus uses madeline as a capitalized name for a person.").
ls_word('mai', given_name, none, evidence(occurrences(3)), "The corpus uses mai as a capitalized name for a person.").
ls_word('mailbox', common_noun, forms(noun(mailbox, mailboxes)), evidence(occurrences(5)), "The corpus uses mailbox as a noun, and Webster supplies no matching surface.").
ls_word('mandy', given_name, none, evidence(occurrences(8)), "The corpus uses mandy as a capitalized name for a person.").
ls_word('manny', given_name, none, evidence(occurrences(9)), "The corpus uses manny as a capitalized name for a person.").
ls_word('marathon', common_noun, forms(noun(marathon, marathons)), evidence(occurrences(5)), "The corpus uses marathon as a noun, and Webster supplies no matching surface.").
ls_word('marco', given_name, none, evidence(occurrences(4)), "The corpus uses marco as a capitalized name for a person.").
ls_word('marcus', given_name, none, evidence(occurrences(14)), "The corpus uses marcus as a capitalized name for a person.").
ls_word('marcy', given_name, none, evidence(occurrences(39)), "The corpus uses marcy as a capitalized name for a person.").
ls_word('margaret', given_name, none, evidence(occurrences(3)), "The corpus uses margaret as a capitalized name for a person.").
ls_word('marinara', common_noun, forms(noun(marinara, marinaras)), evidence(occurrences(4)), "The corpus uses marinara as a noun, and Webster supplies no matching surface.").
ls_word('marissa', given_name, none, evidence(occurrences(8)), "The corpus uses marissa as a capitalized name for a person.").
ls_word('marla', given_name, none, evidence(occurrences(8)), "The corpus uses marla as a capitalized name for a person.").
ls_word('marshmallow', common_noun, forms(noun(marshmallow, marshmallows)), evidence(occurrences(5)), "The corpus uses marshmallow as a noun, and Webster supplies no matching surface.").
ls_word('marshmallows', common_noun, forms(noun(marshmallow, marshmallows)), evidence(occurrences(14)), "The corpus uses marshmallows as a noun, and Webster supplies no matching surface.").
ls_word('martha', given_name, none, evidence(occurrences(19)), "The corpus uses martha as a capitalized name for a person.").
ls_word('marvin', given_name, none, evidence(occurrences(10)), "The corpus uses marvin as a capitalized name for a person.").
ls_word('matilda', given_name, none, evidence(occurrences(14)), "The corpus uses matilda as a capitalized name for a person.").
ls_word('matthew', given_name, none, evidence(occurrences(8)), "The corpus uses matthew as a capitalized name for a person.").
ls_word('max', given_name, none, evidence(occurrences(49)), "The corpus uses max as a capitalized name for a person.").
ls_word('mealworms', common_noun, forms(noun(mealworm, mealworms)), evidence(occurrences(16)), "The corpus uses mealworms as a noun, and Webster supplies no matching surface.").
ls_word('meg', given_name, none, evidence(occurrences(42)), "The corpus uses meg as a capitalized name for a person.").
ls_word('megan', given_name, none, evidence(occurrences(2)), "The corpus uses megan as a capitalized name for a person.").
ls_word('meghan', given_name, none, evidence(occurrences(2)), "The corpus uses meghan as a capitalized name for a person.").
ls_word('melanie', given_name, none, evidence(occurrences(56)), "The corpus uses melanie as a capitalized name for a person.").
ls_word('michael', given_name, none, evidence(occurrences(8)), "The corpus uses michael as a capitalized name for a person.").
ls_word('michel', given_name, none, evidence(occurrences(10)), "The corpus uses michel as a capitalized name for a person.").
ls_word('midterms', common_noun, forms(noun(midterm, midterms)), evidence(occurrences(6)), "The corpus uses midterms as a noun, and Webster supplies no matching surface.").
ls_word('mikaela', given_name, none, evidence(occurrences(5)), "The corpus uses mikaela as a capitalized name for a person.").
ls_word('mike', given_name, none, evidence(occurrences(3)), "The corpus uses mike as a capitalized name for a person.").
ls_word('mila', given_name, none, evidence(occurrences(9)), "The corpus uses mila as a capitalized name for a person.").
ls_word('mileage', common_noun, forms(noun(mileage, mileage)), evidence(occurrences(7)), "The corpus uses mileage as a noun, and Webster supplies no matching surface.").
ls_word('milkshake', common_noun, forms(noun(milkshake, milkshakes)), evidence(occurrences(4)), "The corpus uses milkshake as a noun, and Webster supplies no matching surface.").
ls_word('milly', given_name, none, evidence(occurrences(7)), "The corpus uses milly as a capitalized name for a person.").
ls_word('min', unit_abbreviation, expands_to(minute), evidence(occurrences(4)), "The corpus uses min as a unit abbreviation for minute.").
ls_word('mini', adjective, forms(invariant), evidence(occurrences(81)), "The corpus uses mini adjectivally, and Webster supplies no matching surface.").
ls_word('minis', tokenizer_artifact, none, evidence(occurrences(2)), "uncertain: the corpus says minis croissants, which appears to add a plural marker to attributive mini.").
ls_word('mitchell', given_name, none, evidence(occurrences(28)), "The corpus uses mitchell as a capitalized name for a person.").
ls_word('ml', unit_abbreviation, forms(invariant), evidence(occurrences(57)), "The corpus uses ml as a unit abbreviation.").
ls_word('mom', common_noun, forms(noun(mom, moms)), evidence(occurrences(37)), "The corpus uses mom as a noun, and Webster supplies no matching surface.").
ls_word('motorcycle', common_noun, forms(noun(motorcycle, motorcycles)), evidence(occurrences(5)), "The corpus uses motorcycle as a noun, and Webster supplies no matching surface.").
ls_word('motorcycles', common_noun, forms(noun(motorcycle, motorcycles)), evidence(occurrences(9)), "The corpus uses motorcycles as a noun, and Webster supplies no matching surface.").
ls_word('mph', unit_abbreviation, forms(invariant), evidence(occurrences(29)), "The corpus uses mph as a unit abbreviation.").
ls_word('mr', honorific, forms(invariant), evidence(occurrences(55)), "The corpus uses mr as an abbreviated personal title.").
ls_word('mrs', honorific, forms(invariant), evidence(occurrences(37)), "The corpus uses mrs as an abbreviated personal title.").
ls_word('ms', honorific, forms(invariant), evidence(occurrences(36)), "The corpus uses ms as an abbreviated personal title.").
ls_word('muffaletta', common_noun, forms(noun(muffaletta, muffalettas)), evidence(occurrences(8)), "The corpus uses muffaletta as a noun, and Webster supplies no matching surface.").
ls_word('multi', adjective, forms(invariant), evidence(occurrences(4)), "The corpus uses multi adjectivally, and Webster supplies no matching surface.").
ls_word('mustafa', given_name, none, evidence(occurrences(6)), "The corpus uses mustafa as a capitalized name for a person.").
ls_word('nadia', given_name, none, evidence(occurrences(6)), "The corpus uses nadia as a capitalized name for a person.").
ls_word('nancy', given_name, none, evidence(occurrences(11)), "The corpus uses nancy as a capitalized name for a person.").
ls_word('nate', given_name, none, evidence(occurrences(3)), "The corpus uses nate as a capitalized name for a person.").
ls_word('nd', tokenizer_artifact, none, evidence(occurrences(22)), "The tokenizer detached nd from ordinal numerals, so this fragment is not admitted as a word.").
ls_word('nearby', adjective, forms(invariant), evidence(occurrences(4)), "The corpus uses nearby adjectivally, and Webster supplies no matching surface.").
ls_word('necklaces', common_noun, forms(noun(necklace, necklaces)), evidence(occurrences(1)), "The corpus uses necklaces as a noun, and Webster supplies no matching surface.").
ls_word('neil', given_name, none, evidence(occurrences(12)), "The corpus uses neil as a capitalized name for a person.").
ls_word('newfound', adjective, forms(invariant), evidence(occurrences(2)), "The corpus uses newfound adjectivally, and Webster supplies no matching surface.").
ls_word('ney', family_name, none, evidence(occurrences(4)), "The corpus uses ney as a family name for a person.").
ls_word('nicki', given_name, none, evidence(occurrences(8)), "The corpus uses nicki as a capitalized name for a person.").
ls_word('nicole', given_name, none, evidence(occurrences(10)), "The corpus uses nicole as a capitalized name for a person.").
ls_word('nida', given_name, none, evidence(occurrences(3)), "The corpus uses nida as a capitalized name for a person.").
ls_word('nigel', given_name, none, evidence(occurrences(27)), "The corpus uses nigel as a capitalized name for a person.").
ls_word('nilo', given_name, none, evidence(occurrences(8)), "The corpus uses nilo as a capitalized name for a person.").
ls_word('odds', math_term, forms(noun(odds, odds)), evidence(occurrences(10)), "The corpus uses odds as a mathematics or classroom-analysis noun.").
ls_word('olaf', given_name, none, evidence(occurrences(12)), "The corpus uses olaf as a capitalized name for a person.").
ls_word('olga', given_name, none, evidence(occurrences(27)), "The corpus uses olga as a capitalized name for a person.").
ls_word('olivia', given_name, none, evidence(occurrences(4)), "The corpus uses olivia as a capitalized name for a person.").
ls_word('omar', given_name, none, evidence(occurrences(5)), "The corpus uses omar as a capitalized name for a person.").
ls_word('online', adjective, forms(invariant), evidence(occurrences(4)), "The corpus uses online adjectivally, and Webster supplies no matching surface.").
ls_word('oomyapeck', given_name, none, evidence(occurrences(8)), "The corpus uses oomyapeck as a capitalized name for a person.").
ls_word('openai', named_entity, none, evidence(occurrences(2)), "The corpus uses openai as a capitalized entity, product, team, or disease label.").
ls_word('oscar', given_name, none, evidence(occurrences(6)), "The corpus uses oscar as a capitalized name for a person.").
ls_word('oz', unit_abbreviation, expands_to(ounce), evidence(occurrences(14)), "The corpus uses oz as a unit abbreviation for ounce.").
ls_word('p', algebra_symbol, forms(invariant), evidence(occurrences(13)), "The corpus uses p as a mathematical variable, Greek symbol, or labeled figure symbol.").
ls_word('pablo', given_name, none, evidence(occurrences(8)), "The corpus uses pablo as a capitalized name for a person.").
ls_word('pace', common_noun, forms(noun(pace, paces)), evidence(occurrences(2)), "The corpus uses pace as a noun, and Webster supplies no matching surface.").
ls_word('paige', given_name, none, evidence(occurrences(7)), "The corpus uses paige as a capitalized name for a person.").
ls_word('paperback', common_noun, forms(noun(paperback, paperbacks)), evidence(occurrences(4)), "The corpus uses paperback as a noun, and Webster supplies no matching surface.").
ls_word('patricia', given_name, none, evidence(occurrences(8)), "The corpus uses patricia as a capitalized name for a person.").
ls_word('pepperoni', common_noun, forms(noun(pepperoni, pepperonis)), evidence(occurrences(16)), "The corpus uses pepperoni as a noun, and Webster supplies no matching surface.").
ls_word('percent', math_term, forms(noun(percent, percents)), evidence(occurrences(35)), "The corpus uses percent as a mathematics or classroom-analysis noun.").
ls_word('percius', given_name, none, evidence(occurrences(3)), "The corpus uses percius as a capitalized name for a person.").
ls_word('percy', given_name, none, evidence(occurrences(3)), "The corpus uses percy as a capitalized name for a person.").
ls_word('piggy', adjective, forms(invariant), evidence(occurrences(24)), "The corpus uses piggy adjectivally, and Webster supplies no matching surface.").
ls_word('pima', given_name, none, evidence(occurrences(3)), "The corpus uses pima as a capitalized name for a person.").
ls_word('pizza', common_noun, forms(noun(pizza, pizzas)), evidence(occurrences(24)), "The corpus uses pizza as a noun, and Webster supplies no matching surface.").
ls_word('pizzas', common_noun, forms(noun(pizza, pizzas)), evidence(occurrences(22)), "The corpus uses pizzas as a noun, and Webster supplies no matching surface.").
ls_word('playoff', common_noun, forms(noun(playoff, playoffs)), evidence(occurrences(2)), "The corpus uses playoff as a noun, and Webster supplies no matching surface.").
ls_word('playoffs', common_noun, forms(noun(playoff, playoffs)), evidence(occurrences(5)), "The corpus uses playoffs as a noun, and Webster supplies no matching surface.").
ls_word('pm', abbreviation, forms(invariant), evidence(occurrences(8)), "The corpus uses pm as an invariant abbreviation or size label.").
ls_word('pokemon', named_entity, none, evidence(occurrences(10)), "The corpus uses pokemon as a capitalized entity, product, team, or disease label.").
ls_word('popcorn', common_noun, forms(noun(popcorn, popcorn)), evidence(occurrences(57)), "The corpus uses popcorn as a noun, and Webster supplies no matching surface.").
ls_word('prepping', corpus_verb, forms(verb(prep, preps, prepped, prepping, prepped)), evidence(occurrences(20)), "The corpus uses prepping as a verb form, and the row records its full inflection.").
ls_word('priya', given_name, none, evidence(occurrences(2)), "The corpus uses priya as a capitalized name for a person.").
ls_word('promotional', adjective, forms(invariant), evidence(occurrences(7)), "The corpus uses promotional adjectivally, and Webster supplies no matching surface.").
ls_word('q', algebra_symbol, forms(invariant), evidence(occurrences(2)), "The corpus uses q as a mathematical variable, Greek symbol, or labeled figure symbol.").
ls_word('queenie', given_name, none, evidence(occurrences(24)), "The corpus uses queenie as a capitalized name for a person.").
ls_word('r', algebra_symbol, forms(invariant), evidence(occurrences(13)), "The corpus uses r as a mathematical variable, Greek symbol, or labeled figure symbol.").
ls_word('rabbit', common_noun, forms(noun(rabbit, rabbits)), evidence(occurrences(14)), "The corpus uses rabbit as a noun, and Webster supplies no matching surface.").
ls_word('rabbits', common_noun, forms(noun(rabbit, rabbits)), evidence(occurrences(29)), "The corpus uses rabbits as a noun, and Webster supplies no matching surface.").
ls_word('rachel', given_name, none, evidence(occurrences(27)), "The corpus uses rachel as a capitalized name for a person.").
ls_word('radio', common_noun, forms(noun(radio, radios)), evidence(occurrences(6)), "The corpus uses radio as a noun, and Webster supplies no matching surface.").
ls_word('rainforest', common_noun, forms(noun(rainforest, rainforests)), evidence(occurrences(2)), "The corpus uses rainforest as a noun, and Webster supplies no matching surface.").
ls_word('rancher', common_noun, forms(noun(rancher, ranchers)), evidence(occurrences(30)), "The corpus uses rancher as a noun, and Webster supplies no matching surface.").
ls_word('randi', given_name, none, evidence(occurrences(14)), "The corpus uses randi as a capitalized name for a person.").
ls_word('randy', given_name, none, evidence(occurrences(30)), "The corpus uses randy as a capitalized name for a person.").
ls_word('raspberries', common_noun, forms(noun(raspberry, raspberries)), evidence(occurrences(8)), "The corpus uses raspberries as a noun, and Webster supplies no matching surface.").
ls_word('rd', tokenizer_artifact, none, evidence(occurrences(20)), "The tokenizer detached rd from ordinal numerals, so this fragment is not admitted as a word.").
ls_word('rds', tokenizer_artifact, none, evidence(occurrences(2)), "The tokenizer detached rds from the source form 2/3rds, so this fragment is not admitted as a word.").
ls_word('re', contraction_fragment, none, evidence(occurrences(28)), "The tokenizer detached re from an apostrophe contraction, so the fragment is not admitted as a word.").
ls_word('realised', corpus_verb, forms(verb(realise, realises, realised, realising, realised)), evidence(occurrences(2)), "The corpus uses realised as a verb form, and the row records its full inflection.").
ls_word('rebecca', given_name, none, evidence(occurrences(14)), "The corpus uses rebecca as a capitalized name for a person.").
ls_word('recommend', corpus_verb, forms(verb(recommend, recommends, recommended, recommending, recommended)), evidence(occurrences(2)), "The corpus uses recommend as a verb form, and the row records its full inflection.").
ls_word('recommendation', common_noun, forms(noun(recommendation, recommendations)), evidence(occurrences(1)), "The corpus uses recommendation as a noun, and Webster supplies no matching surface.").
ls_word('recommended', corpus_verb, forms(verb(recommend, recommends, recommended, recommending, recommended)), evidence(occurrences(1)), "The corpus uses recommended as a verb form, and the row records its full inflection.").
ls_word('recovered', corpus_verb, forms(verb(recover, recovers, recovered, recovering, recovered)), evidence(occurrences(5)), "The corpus uses recovered as a verb form, and the row records its full inflection.").
ls_word('rectangles', math_term, forms(noun(rectangle, rectangles)), evidence(occurrences(20)), "The corpus uses rectangles as a mathematics or classroom-analysis noun.").
ls_word('rectangular', adjective, forms(invariant), evidence(occurrences(12)), "The corpus uses rectangular adjectivally, and Webster supplies no matching surface.").
ls_word('recycle', corpus_verb, forms(verb(recycle, recycles, recycled, recycling, recycled)), evidence(occurrences(6)), "The corpus uses recycle as a verb form, and the row records its full inflection.").
ls_word('recycled', corpus_verb, forms(verb(recycle, recycles, recycled, recycling, recycled)), evidence(occurrences(10)), "The corpus uses recycled as a verb form, and the row records its full inflection.").
ls_word('recycling', corpus_verb, forms(verb(recycle, recycles, recycled, recycling, recycled)), evidence(occurrences(7)), "The corpus uses recycling as a verb form, and the row records its full inflection.").
ls_word('redeem', corpus_verb, forms(verb(redeem, redeems, redeemed, redeeming, redeemed)), evidence(occurrences(4)), "The corpus uses redeem as a verb form, and the row records its full inflection.").
ls_word('redeemed', corpus_verb, forms(verb(redeem, redeems, redeemed, redeeming, redeemed)), evidence(occurrences(4)), "The corpus uses redeemed as a verb form, and the row records its full inflection.").
ls_word('redo', corpus_verb, forms(verb(redo, redoes, redid, redoing, redone)), evidence(occurrences(4)), "The corpus uses redo as a verb form, and the row records its full inflection.").
ls_word('reduce', corpus_verb, forms(verb(reduce, reduces, reduced, reducing, reduced)), evidence(occurrences(14)), "The corpus uses reduce as a verb form, and the row records its full inflection.").
ls_word('reduced', corpus_verb, forms(verb(reduce, reduces, reduced, reducing, reduced)), evidence(occurrences(9)), "The corpus uses reduced as a verb form, and the row records its full inflection.").
ls_word('reduces', corpus_verb, forms(verb(reduce, reduces, reduced, reducing, reduced)), evidence(occurrences(5)), "The corpus uses reduces as a verb form, and the row records its full inflection.").
ls_word('reduction', common_noun, forms(noun(reduction, reductions)), evidence(occurrences(2)), "The corpus uses reduction as a noun, and Webster supplies no matching surface.").
ls_word('refill', corpus_verb, forms(verb(refill, refills, refilled, refilling, refilled)), evidence(occurrences(15)), "The corpus uses refill as a verb form, and the row records its full inflection.").
ls_word('refilling', corpus_verb, forms(verb(refill, refills, refilled, refilling, refilled)), evidence(occurrences(2)), "The corpus uses refilling as a verb form, and the row records its full inflection.").
ls_word('refills', corpus_verb, forms(verb(refill, refills, refilled, refilling, refilled)), evidence(occurrences(1)), "The corpus uses refills as a verb form, and the row records its full inflection.").
ls_word('reflection', math_term, forms(noun(reflection, reflections)), evidence(occurrences(1)), "The corpus uses reflection as a mathematics or classroom-analysis noun.").
ls_word('refuel', corpus_verb, forms(verb(refuel, refuels, refueled, refueling, refueled)), evidence(occurrences(4)), "The corpus uses refuel as a verb form, and the row records its full inflection.").
ls_word('refunded', corpus_verb, forms(verb(refund, refunds, refunded, refunding, refunded)), evidence(occurrences(1)), "The corpus uses refunded as a verb form, and the row records its full inflection.").
ls_word('reggie', given_name, none, evidence(occurrences(18)), "The corpus uses reggie as a capitalized name for a person.").
ls_word('region', math_term, forms(noun(region, regions)), evidence(occurrences(8)), "The corpus uses region as a mathematics or classroom-analysis noun.").
ls_word('regions', math_term, forms(noun(region, regions)), evidence(occurrences(1)), "The corpus uses regions as a mathematics or classroom-analysis noun.").
ls_word('regroup', corpus_verb, forms(verb(regroup, regroups, regrouped, regrouping, regrouped)), evidence(occurrences(1)), "The corpus uses regroup as a verb form, and the row records its full inflection.").
ls_word('regular', adjective, forms(invariant), evidence(occurrences(50)), "The corpus uses regular adjectivally, and Webster supplies no matching surface.").
ls_word('rehana', given_name, none, evidence(occurrences(12)), "The corpus uses rehana as a capitalized name for a person.").
ls_word('rely', corpus_verb, forms(verb(rely, relies, relied, relying, relied)), evidence(occurrences(1)), "The corpus uses rely as a verb form, and the row records its full inflection.").
ls_word('relying', corpus_verb, forms(verb(rely, relies, relied, relying, relied)), evidence(occurrences(1)), "The corpus uses relying as a verb form, and the row records its full inflection.").
ls_word('remember', corpus_verb, forms(verb(remember, remembers, remembered, remembering, remembered)), evidence(occurrences(1)), "The corpus uses remember as a verb form, and the row records its full inflection.").
ls_word('remembers', corpus_verb, forms(verb(remember, remembers, remembered, remembering, remembered)), evidence(occurrences(2)), "The corpus uses remembers as a verb form, and the row records its full inflection.").
ls_word('remind', corpus_verb, forms(verb(remind, reminds, reminded, reminding, reminded)), evidence(occurrences(3)), "The corpus uses remind as a verb form, and the row records its full inflection.").
ls_word('removed', corpus_verb, forms(verb(remove, removes, removed, removing, removed)), evidence(occurrences(13)), "The corpus uses removed as a verb form, and the row records its full inflection.").
ls_word('removing', corpus_verb, forms(verb(remove, removes, removed, removing, removed)), evidence(occurrences(6)), "The corpus uses removing as a verb form, and the row records its full inflection.").
ls_word('rena', given_name, none, evidence(occurrences(9)), "The corpus uses rena as a capitalized name for a person.").
ls_word('renovate', corpus_verb, forms(verb(renovate, renovates, renovated, renovating, renovated)), evidence(occurrences(2)), "The corpus uses renovate as a verb form, and the row records its full inflection.").
ls_word('repainting', corpus_verb, forms(verb(repaint, repaints, repainted, repainting, repainted)), evidence(occurrences(2)), "The corpus uses repainting as a verb form, and the row records its full inflection.").
ls_word('repay', corpus_verb, forms(verb(repay, repays, repaid, repaying, repaid)), evidence(occurrences(4)), "The corpus uses repay as a verb form, and the row records its full inflection.").
ls_word('repeats', corpus_verb, forms(verb(repeat, repeats, repeated, repeating, repeated)), evidence(occurrences(6)), "The corpus uses repeats as a verb form, and the row records its full inflection.").
ls_word('replace', corpus_verb, forms(verb(replace, replaces, replaced, replacing, replaced)), evidence(occurrences(3)), "The corpus uses replace as a verb form, and the row records its full inflection.").
ls_word('report', common_noun, forms(noun(report, reports)), evidence(occurrences(2)), "The corpus uses report as a noun, and Webster supplies no matching surface.").
ls_word('reported', corpus_verb, forms(verb(report, reports, reported, reporting, reported)), evidence(occurrences(4)), "The corpus uses reported as a verb form, and the row records its full inflection.").
ls_word('represent', corpus_verb, forms(verb(represent, represents, represented, representing, represented)), evidence(occurrences(72)), "The corpus uses represent as a verb form, and the row records its full inflection.").
ls_word('representation', math_term, forms(noun(representation, representations)), evidence(occurrences(7)), "The corpus uses representation as a mathematics or classroom-analysis noun.").
ls_word('representations', math_term, forms(noun(representation, representations)), evidence(occurrences(11)), "The corpus uses representations as a mathematics or classroom-analysis noun.").
ls_word('represented', corpus_verb, forms(verb(represent, represents, represented, representing, represented)), evidence(occurrences(16)), "The corpus uses represented as a verb form, and the row records its full inflection.").
ls_word('representing', corpus_verb, forms(verb(represent, represents, represented, representing, represented)), evidence(occurrences(6)), "The corpus uses representing as a verb form, and the row records its full inflection.").
ls_word('represents', corpus_verb, forms(verb(represent, represents, represented, representing, represented)), evidence(occurrences(22)), "The corpus uses represents as a verb form, and the row records its full inflection.").
ls_word('reps', common_noun, forms(noun(rep, reps)), evidence(occurrences(6)), "The corpus uses reps as a noun, and Webster supplies no matching surface.").
ls_word('requested', corpus_verb, forms(verb(request, requests, requested, requesting, requested)), evidence(occurrences(2)), "The corpus uses requested as a verb form, and the row records its full inflection.").
ls_word('require', corpus_verb, forms(verb(require, requires, required, requiring, required)), evidence(occurrences(13)), "The corpus uses require as a verb form, and the row records its full inflection.").
ls_word('required', corpus_verb, forms(verb(require, requires, required, requiring, required)), evidence(occurrences(29)), "The corpus uses required as a verb form, and the row records its full inflection.").
ls_word('requirement', common_noun, forms(noun(requirement, requirements)), evidence(occurrences(5)), "The corpus uses requirement as a noun, and Webster supplies no matching surface.").
ls_word('requirements', common_noun, forms(noun(requirement, requirements)), evidence(occurrences(3)), "The corpus uses requirements as a noun, and Webster supplies no matching surface.").
ls_word('requires', corpus_verb, forms(verb(require, requires, required, requiring, required)), evidence(occurrences(19)), "The corpus uses requires as a verb form, and the row records its full inflection.").
ls_word('reread', corpus_verb, forms(verb(reread, rereads, reread, rereading, reread)), evidence(occurrences(8)), "The corpus uses reread as a verb form, and the row records its full inflection.").
ls_word('researchers', common_noun, forms(noun(researcher, researchers)), evidence(occurrences(2)), "The corpus uses researchers as a noun, and Webster supplies no matching surface.").
ls_word('reseeding', corpus_verb, forms(verb(reseed, reseeds, reseeded, reseeding, reseeded)), evidence(occurrences(4)), "The corpus uses reseeding as a verb form, and the row records its full inflection.").
ls_word('reseeds', corpus_verb, forms(verb(reseed, reseeds, reseeded, reseeding, reseeded)), evidence(occurrences(4)), "The corpus uses reseeds as a verb form, and the row records its full inflection.").
ls_word('respectfully', adverb, forms(invariant), evidence(occurrences(1)), "The corpus uses respectfully adverbially, and Webster supplies no matching surface.").
ls_word('response', math_term, forms(noun(response, responses)), evidence(occurrences(5)), "The corpus uses response as a mathematics or classroom-analysis noun.").
ls_word('responses', math_term, forms(noun(response, responses)), evidence(occurrences(1)), "The corpus uses responses as a mathematics or classroom-analysis noun.").
ls_word('restart', common_noun, forms(noun(restart, restarts)), evidence(occurrences(40)), "The corpus uses restart as a noun, and Webster supplies no matching surface.").
ls_word('restarts', corpus_verb, forms(verb(restart, restarts, restarted, restarting, restarted)), evidence(occurrences(5)), "The corpus uses restarts as a verb form, and the row records its full inflection.").
ls_word('restate', corpus_verb, forms(verb(restate, restates, restated, restating, restated)), evidence(occurrences(99)), "The corpus uses restate as a verb form, and the row records its full inflection.").
ls_word('restaurant', common_noun, forms(noun(restaurant, restaurants)), evidence(occurrences(21)), "The corpus uses restaurant as a noun, and Webster supplies no matching surface.").
ls_word('restroom', common_noun, forms(noun(restroom, restrooms)), evidence(occurrences(10)), "The corpus uses restroom as a noun, and Webster supplies no matching surface.").
ls_word('reusable', adjective, forms(invariant), evidence(occurrences(1)), "The corpus uses reusable adjectivally, and Webster supplies no matching surface.").
ls_word('rewind', corpus_verb, forms(verb(rewind, rewinds, rewound, rewinding, rewound)), evidence(occurrences(40)), "The corpus uses rewind as a verb form, and the row records its full inflection.").
ls_word('rewinding', corpus_verb, forms(verb(rewind, rewinds, rewound, rewinding, rewound)), evidence(occurrences(8)), "The corpus uses rewinding as a verb form, and the row records its full inflection.").
ls_word('rewound', corpus_verb, forms(verb(rewind, rewinds, rewound, rewinding, rewound)), evidence(occurrences(4)), "The corpus uses rewound as a verb form, and the row records its full inflection.").
ls_word('reynald', given_name, none, evidence(occurrences(6)), "The corpus uses reynald as a capitalized name for a person.").
ls_word('rho', algebra_symbol, forms(invariant), evidence(occurrences(1)), "The corpus uses rho as a mathematical variable, Greek symbol, or labeled figure symbol.").
ls_word('richard', given_name, none, evidence(occurrences(4)), "The corpus uses richard as a capitalized name for a person.").
ls_word('riverbed', common_noun, forms(noun(riverbed, riverbeds)), evidence(occurrences(14)), "The corpus uses riverbed as a noun, and Webster supplies no matching surface.").
ls_word('robi', given_name, none, evidence(occurrences(4)), "The corpus uses robi as a capitalized name for a person.").
ls_word('robot', common_noun, forms(noun(robot, robots)), evidence(occurrences(17)), "The corpus uses robot as a noun, and Webster supplies no matching surface.").
ls_word('robotics', common_noun, forms(noun(robotics, robotics)), evidence(occurrences(2)), "The corpus uses robotics as a noun, and Webster supplies no matching surface.").
ls_word('ron', given_name, none, evidence(occurrences(11)), "The corpus uses ron as a capitalized name for a person.").
ls_word('rosie', given_name, none, evidence(occurrences(14)), "The corpus uses rosie as a capitalized name for a person.").
ls_word('runoff', common_noun, forms(noun(runoff, runoffs)), evidence(occurrences(3)), "The corpus uses runoff as a noun, and Webster supplies no matching surface.").
ls_word('ryan', given_name, none, evidence(occurrences(20)), "The corpus uses ryan as a capitalized name for a person.").
ls_word('salisbury', place_name, none, evidence(occurrences(7)), "The corpus uses salisbury as a capitalized place name or place-name component.").
ls_word('salsa', common_noun, forms(noun(salsa, salsas)), evidence(occurrences(6)), "The corpus uses salsa as a noun, and Webster supplies no matching surface.").
ls_word('samantha', given_name, none, evidence(occurrences(4)), "The corpus uses samantha as a capitalized name for a person.").
ls_word('sammy', given_name, none, evidence(occurrences(22)), "The corpus uses sammy as a capitalized name for a person.").
ls_word('samuel', given_name, none, evidence(occurrences(9)), "The corpus uses samuel as a capitalized name for a person.").
ls_word('san', place_name, none, evidence(occurrences(1)), "The corpus uses san as a capitalized place name or place-name component.").
ls_word('sandbag', common_noun, forms(noun(sandbag, sandbags)), evidence(occurrences(4)), "The corpus uses sandbag as a noun, and Webster supplies no matching surface.").
ls_word('sandoval', family_name, none, evidence(occurrences(18)), "The corpus uses sandoval as a family name for a person.").
ls_word('sandra', given_name, none, evidence(occurrences(16)), "The corpus uses sandra as a capitalized name for a person.").
ls_word('sang', corpus_verb, forms(verb(sing, sings, sang, singing, sung)), evidence(occurrences(22)), "The corpus uses sang as a verb form, and the row records its full inflection.").
ls_word('sangita', given_name, none, evidence(occurrences(7)), "The corpus uses sangita as a capitalized name for a person.").
ls_word('sarah', given_name, none, evidence(occurrences(34)), "The corpus uses sarah as a capitalized name for a person.").
ls_word('sarith', given_name, none, evidence(occurrences(20)), "The corpus uses sarith as a capitalized name for a person.").
ls_word('saturday', temporal_word, forms(noun(saturday, saturdays)), evidence(occurrences(35)), "The corpus uses saturday as a day or relative-time expression.").
ls_word('sausage', common_noun, forms(noun(sausage, sausages)), evidence(occurrences(8)), "The corpus uses sausage as a noun, and Webster supplies no matching surface.").
ls_word('seabed', common_noun, forms(noun(seabed, seabeds)), evidence(occurrences(4)), "The corpus uses seabed as a noun, and Webster supplies no matching surface.").
ls_word('seahawks', named_entity, none, evidence(occurrences(24)), "The corpus uses seahawks as a capitalized entity, product, team, or disease label.").
ls_word('seattle', place_name, none, evidence(occurrences(24)), "The corpus uses seattle as a capitalized place name or place-name component.").
ls_word('sec', unit_abbreviation, expands_to(second), evidence(occurrences(5)), "The corpus uses sec as a unit abbreviation for second.").
ls_word('semi', adjective, forms(invariant), evidence(occurrences(6)), "The corpus uses semi adjectivally, and Webster supplies no matching surface.").
ls_word('servings', common_noun, forms(noun(serving, servings)), evidence(occurrences(6)), "The corpus uses servings as a noun, and Webster supplies no matching surface.").
ls_word('shannen', given_name, none, evidence(occurrences(16)), "The corpus uses shannen as a capitalized name for a person.").
ls_word('sharpener', common_noun, forms(noun(sharpener, sharpeners)), evidence(occurrences(15)), "The corpus uses sharpener as a noun, and Webster supplies no matching surface.").
ls_word('shawn', given_name, none, evidence(occurrences(4)), "The corpus uses shawn as a capitalized name for a person.").
ls_word('shawna', given_name, none, evidence(occurrences(33)), "The corpus uses shawna as a capitalized name for a person.").
ls_word('sheena', given_name, none, evidence(occurrences(6)), "The corpus uses sheena as a capitalized name for a person.").
ls_word('sheila', given_name, none, evidence(occurrences(10)), "The corpus uses sheila as a capitalized name for a person.").
ls_word('shelby', given_name, none, evidence(occurrences(9)), "The corpus uses shelby as a capitalized name for a person.").
ls_word('shoebox', common_noun, forms(noun(shoebox, shoeboxes)), evidence(occurrences(6)), "The corpus uses shoebox as a noun, and Webster supplies no matching surface.").
ls_word('shredded', corpus_verb, forms(verb(shred, shreds, shredded, shredding, shredded)), evidence(occurrences(4)), "The corpus uses shredded as a verb form, and the row records its full inflection.").
ls_word('shrunk', corpus_verb, forms(verb(shrink, shrinks, shrank, shrinking, shrunk)), evidence(occurrences(4)), "The corpus uses shrunk as a verb form, and the row records its full inflection.").
ls_word('sibling', common_noun, forms(noun(sibling, siblings)), evidence(occurrences(1)), "The corpus uses sibling as a noun, and Webster supplies no matching surface.").
ls_word('siblings', common_noun, forms(noun(sibling, siblings)), evidence(occurrences(12)), "The corpus uses siblings as a noun, and Webster supplies no matching surface.").
ls_word('silas', given_name, none, evidence(occurrences(5)), "The corpus uses silas as a capitalized name for a person.").
ls_word('situp', common_noun, forms(noun(situp, situps)), evidence(occurrences(3)), "The corpus uses situp as a noun, and Webster supplies no matching surface.").
ls_word('situps', common_noun, forms(noun(situp, situps)), evidence(occurrences(45)), "The corpus uses situps as a noun, and Webster supplies no matching surface.").
ls_word('skier', common_noun, forms(noun(skier, skiers)), evidence(occurrences(3)), "The corpus uses skier as a noun, and Webster supplies no matching surface.").
ls_word('skiers', common_noun, forms(noun(skier, skiers)), evidence(occurrences(2)), "The corpus uses skiers as a noun, and Webster supplies no matching surface.").
ls_word('skiing', corpus_verb, forms(verb(ski, skis, skied, skiing, skied)), evidence(occurrences(1)), "The corpus uses skiing as a verb form, and the row records its full inflection.").
ls_word('sloan', given_name, none, evidence(occurrences(8)), "The corpus uses sloan as a capitalized name for a person.").
ls_word('smoothie', common_noun, forms(noun(smoothie, smoothies)), evidence(occurrences(1)), "The corpus uses smoothie as a noun, and Webster supplies no matching surface.").
ls_word('soccer', common_noun, forms(noun(soccer, soccer)), evidence(occurrences(69)), "The corpus uses soccer as a noun, and Webster supplies no matching surface.").
ls_word('sofia', given_name, none, evidence(occurrences(5)), "The corpus uses sofia as a capitalized name for a person.").
ls_word('softball', common_noun, forms(noun(softball, softballs)), evidence(occurrences(2)), "The corpus uses softball as a noun, and Webster supplies no matching surface.").
ls_word('softballs', common_noun, forms(noun(softball, softballs)), evidence(occurrences(12)), "The corpus uses softballs as a noun, and Webster supplies no matching surface.").
ls_word('someone', function_word, forms(invariant), evidence(occurrences(20)), "The corpus uses someone as an invariant grammatical function word.").
ls_word('sonja', given_name, none, evidence(occurrences(10)), "The corpus uses sonja as a capitalized name for a person.").
ls_word('sophia', given_name, none, evidence(occurrences(28)), "The corpus uses sophia as a capitalized name for a person.").
ls_word('sourdough', common_noun, forms(noun(sourdough, sourdough)), evidence(occurrences(5)), "The corpus uses sourdough as a noun, and Webster supplies no matching surface.").
ls_word('spacecraft', common_noun, forms(noun(spacecraft, spacecraft)), evidence(occurrences(2)), "The corpus uses spacecraft as a noun, and Webster supplies no matching surface.").
ls_word('spain', place_name, none, evidence(occurrences(12)), "The corpus uses spain as a capitalized place name or place-name component.").
ls_word('spiderwebs', common_noun, forms(noun(spiderweb, spiderwebs)), evidence(occurrences(7)), "The corpus uses spiderwebs as a noun, and Webster supplies no matching surface.").
ls_word('splitting', corpus_verb, forms(verb(split, splits, split, splitting, split)), evidence(occurrences(2)), "The corpus uses splitting as a verb form, and the row records its full inflection.").
ls_word('spotify', named_entity, none, evidence(occurrences(4)), "The corpus uses spotify as a capitalized entity, product, team, or disease label.").
ls_word('spreadsheet', common_noun, forms(noun(spreadsheet, spreadsheets)), evidence(occurrences(1)), "The corpus uses spreadsheet as a noun, and Webster supplies no matching surface.").
ls_word('sq', unit_abbreviation, expands_to(square), evidence(occurrences(8)), "The corpus uses sq as a unit abbreviation for square.").
ls_word('sqrt', math_notation, forms(invariant), evidence(occurrences(2)), "The corpus uses sqrt as a spreadsheet, typesetting, or mathematical notation token.").
ls_word('squirrel', common_noun, forms(noun(squirrel, squirrels)), evidence(occurrences(24)), "The corpus uses squirrel as a noun, and Webster supplies no matching surface.").
ls_word('squirrels', common_noun, forms(noun(squirrel, squirrels)), evidence(occurrences(28)), "The corpus uses squirrels as a noun, and Webster supplies no matching surface.").
ls_word('sr', honorific, forms(invariant), evidence(occurrences(1)), "The corpus uses sr as an abbreviated personal title.").
ls_word('st', tokenizer_artifact, none, evidence(occurrences(16)), "The tokenizer detached st from ordinal numerals, so this fragment is not admitted as a word.").
ls_word('starshaped', tokenizer_artifact, none, evidence(occurrences(1)), "The source fuses star and shaped without a separator, so this token remains a tokenizer artifact.").
ls_word('stashed', corpus_verb, forms(verb(stash, stashes, stashed, stashing, stashed)), evidence(occurrences(2)), "The corpus uses stashed as a verb form, and the row records its full inflection.").
ls_word('stephen', given_name, none, evidence(occurrences(2)), "The corpus uses stephen as a capitalized name for a person.").
ls_word('stockpiling', corpus_verb, forms(verb(stockpile, stockpiles, stockpiled, stockpiling, stockpiled)), evidence(occurrences(8)), "The corpus uses stockpiling as a verb form, and the row records its full inflection.").
ls_word('stopover', common_noun, forms(noun(stopover, stopovers)), evidence(occurrences(2)), "The corpus uses stopover as a noun, and Webster supplies no matching surface.").
ls_word('striploin', common_noun, forms(noun(striploin, striploins)), evidence(occurrences(2)), "The corpus uses striploin as a noun, and Webster supplies no matching surface.").
ls_word('stuart', given_name, none, evidence(occurrences(20)), "The corpus uses stuart as a capitalized name for a person.").
ls_word('suddenly', adverb, forms(invariant), evidence(occurrences(2)), "The corpus uses suddenly adverbially, and Webster supplies no matching surface.").
ls_word('sunscreen', common_noun, forms(noun(sunscreen, sunscreen)), evidence(occurrences(4)), "The corpus uses sunscreen as a noun, and Webster supplies no matching surface.").
ls_word('supermajorities', common_noun, forms(noun(supermajority, supermajorities)), evidence(occurrences(1)), "The corpus uses supermajorities as a noun, and Webster supplies no matching surface.").
ls_word('susan', given_name, none, evidence(occurrences(6)), "The corpus uses susan as a capitalized name for a person.").
ls_word('sustainably', adverb, forms(invariant), evidence(occurrences(3)), "The corpus uses sustainably adverbially, and Webster supplies no matching surface.").
ls_word('suv', abbreviation, forms(invariant), evidence(occurrences(15)), "The corpus uses suv as an invariant abbreviation or size label.").
ls_word('tabitha', given_name, none, evidence(occurrences(8)), "The corpus uses tabitha as a capitalized name for a person.").
ls_word('taco', common_noun, forms(noun(taco, tacos)), evidence(occurrences(7)), "The corpus uses taco as a noun, and Webster supplies no matching surface.").
ls_word('tacos', common_noun, forms(noun(taco, tacos)), evidence(occurrences(17)), "The corpus uses tacos as a noun, and Webster supplies no matching surface.").
ls_word('taken', corpus_verb, forms(verb(take, takes, took, taking, taken)), evidence(occurrences(44)), "The corpus uses taken as a verb form, and the row records its full inflection.").
ls_word('talia', given_name, none, evidence(occurrences(50)), "The corpus uses talia as a capitalized name for a person.").
ls_word('tania', given_name, none, evidence(occurrences(2)), "The corpus uses tania as a capitalized name for a person.").
ls_word('tanya', given_name, none, evidence(occurrences(22)), "The corpus uses tanya as a capitalized name for a person.").
ls_word('tara', given_name, none, evidence(occurrences(2)), "The corpus uses tara as a capitalized name for a person.").
ls_word('tasha', given_name, none, evidence(occurrences(8)), "The corpus uses tasha as a capitalized name for a person.").
ls_word('tavernmaster', common_noun, forms(noun(tavernmaster, tavernmasters)), evidence(occurrences(2)), "The corpus uses tavernmaster as a noun, and Webster supplies no matching surface.").
ls_word('tayzia', given_name, none, evidence(occurrences(15)), "The corpus uses tayzia as a capitalized name for a person.").
ls_word('teammates', common_noun, forms(noun(teammate, teammates)), evidence(occurrences(2)), "The corpus uses teammates as a noun, and Webster supplies no matching surface.").
ls_word('teddies', common_noun, forms(noun(teddy, teddies)), evidence(occurrences(11)), "The corpus uses teddies as a noun, and Webster supplies no matching surface.").
ls_word('teddy', common_noun, forms(noun(teddy, teddies)), evidence(occurrences(2)), "The corpus uses teddy as a noun, and Webster supplies no matching surface.").
ls_word('tedra', given_name, none, evidence(occurrences(8)), "The corpus uses tedra as a capitalized name for a person.").
ls_word('television', common_noun, forms(noun(television, televisions)), evidence(occurrences(10)), "The corpus uses television as a noun, and Webster supplies no matching surface.").
ls_word('televisions', common_noun, forms(noun(television, televisions)), evidence(occurrences(36)), "The corpus uses televisions as a noun, and Webster supplies no matching surface.").
ls_word('textbook', common_noun, forms(noun(textbook, textbooks)), evidence(occurrences(26)), "The corpus uses textbook as a noun, and Webster supplies no matching surface.").
ls_word('th', tokenizer_artifact, none, evidence(occurrences(47)), "The tokenizer detached th from ordinal numerals, so this fragment is not admitted as a word.").
ls_word('theirs', function_word, forms(invariant), evidence(occurrences(1)), "The corpus uses theirs as an invariant grammatical function word.").
ls_word('themed', adjective, forms(invariant), evidence(occurrences(13)), "The corpus uses themed adjectivally, and Webster supplies no matching surface.").
ls_word('thiswarmup', tokenizer_artifact, none, evidence(occurrences(1)), "The source fuses this and Warmup, so this token remains a tokenizer artifact.").
ls_word('threedimensional', tokenizer_artifact, none, evidence(occurrences(1)), "The source fuses three and dimensional, so this token remains a tokenizer artifact.").
ls_word('thumbtack', common_noun, forms(noun(thumbtack, thumbtacks)), evidence(occurrences(2)), "The corpus uses thumbtack as a noun, and Webster supplies no matching surface.").
ls_word('thumbtacks', common_noun, forms(noun(thumbtack, thumbtacks)), evidence(occurrences(1)), "The corpus uses thumbtacks as a noun, and Webster supplies no matching surface.").
ls_word('tim', given_name, none, evidence(occurrences(24)), "The corpus uses tim as a capitalized name for a person.").
ls_word('timmy', given_name, none, evidence(occurrences(9)), "The corpus uses timmy as a capitalized name for a person.").
ls_word('tina', given_name, none, evidence(occurrences(12)), "The corpus uses tina as a capitalized name for a person.").
ls_word('today', temporal_word, forms(invariant), evidence(occurrences(104)), "The corpus uses today as a day or relative-time expression.").
ls_word('todd', given_name, none, evidence(occurrences(36)), "The corpus uses todd as a capitalized name for a person.").
ls_word('toenails', common_noun, forms(noun(toenail, toenails)), evidence(occurrences(40)), "The corpus uses toenails as a noun, and Webster supplies no matching surface.").
ls_word('tonya', given_name, none, evidence(occurrences(9)), "The corpus uses tonya as a capitalized name for a person.").
ls_word('totaling', corpus_verb, forms(verb(total, totals, totaled, totaling, totaled)), evidence(occurrences(3)), "The corpus uses totaling as a verb form, and the row records its full inflection.").
ls_word('toula', given_name, none, evidence(occurrences(24)), "The corpus uses toula as a capitalized name for a person.").
ls_word('tracy', given_name, none, evidence(occurrences(30)), "The corpus uses tracy as a capitalized name for a person.").
ls_word('trevor', given_name, none, evidence(occurrences(32)), "The corpus uses trevor as a capitalized name for a person.").
ls_word('tripped', corpus_verb, forms(verb(trip, trips, tripped, tripping, tripped)), evidence(occurrences(2)), "The corpus uses tripped as a verb form, and the row records its full inflection.").
ls_word('trivia', common_noun, forms(noun(trivia, trivia)), evidence(occurrences(1)), "The corpus uses trivia as a noun, and Webster supplies no matching surface.").
ls_word('ts', algebra_symbol, forms(invariant), evidence(occurrences(1)), "The corpus uses ts as a mathematical variable, Greek symbol, or labeled figure symbol.").
ls_word('tsunami', common_noun, forms(noun(tsunami, tsunamis)), evidence(occurrences(8)), "The corpus uses tsunami as a noun, and Webster supplies no matching surface.").
ls_word('tv', abbreviation, forms(invariant), evidence(occurrences(19)), "The corpus uses tv as an invariant abbreviation or size label.").
ls_word('twodigit', tokenizer_artifact, none, evidence(occurrences(1)), "The source fuses two and digit, so this token remains a tokenizer artifact.").
ls_word('typically', adverb, forms(invariant), evidence(occurrences(6)), "The corpus uses typically adverbially, and Webster supplies no matching surface.").
ls_word('tyson', given_name, none, evidence(occurrences(12)), "The corpus uses tyson as a capitalized name for a person.").
ls_word('unclear', adjective, forms(invariant), evidence(occurrences(6)), "The corpus uses unclear adjectivally, and Webster supplies no matching surface.").
ls_word('undetected', adjective, forms(invariant), evidence(occurrences(3)), "The corpus uses undetected adjectivally, and Webster supplies no matching surface.").
ls_word('undried', adjective, forms(invariant), evidence(occurrences(2)), "The corpus uses undried adjectivally, and Webster supplies no matching surface.").
ls_word('unfollowed', corpus_verb, forms(verb(unfollow, unfollows, unfollowed, unfollowing, unfollowed)), evidence(occurrences(4)), "The corpus uses unfollowed as a verb form, and the row records its full inflection.").
ls_word('unfortunately', adverb, forms(invariant), evidence(occurrences(4)), "The corpus uses unfortunately adverbially, and Webster supplies no matching surface.").
ls_word('ungridded', adjective, forms(invariant), evidence(occurrences(1)), "The corpus uses ungridded adjectivally, and Webster supplies no matching surface.").
ls_word('unicycle', common_noun, forms(noun(unicycle, unicycles)), evidence(occurrences(16)), "The corpus uses unicycle as a noun, and Webster supplies no matching surface.").
ls_word('uninterrupted', adjective, forms(invariant), evidence(occurrences(8)), "The corpus uses uninterrupted adjectivally, and Webster supplies no matching surface.").
ls_word('unnoticed', adjective, forms(invariant), evidence(occurrences(2)), "The corpus uses unnoticed adjectivally, and Webster supplies no matching surface.").
ls_word('unoccupied', adjective, forms(invariant), evidence(occurrences(4)), "The corpus uses unoccupied adjectivally, and Webster supplies no matching surface.").
ls_word('unproductive', adjective, forms(invariant), evidence(occurrences(1)), "The corpus uses unproductive adjectivally, and Webster supplies no matching surface.").
ls_word('unsold', adjective, forms(invariant), evidence(occurrences(18)), "The corpus uses unsold adjectivally, and Webster supplies no matching surface.").
ls_word('unsure', adjective, forms(invariant), evidence(occurrences(1)), "The corpus uses unsure adjectivally, and Webster supplies no matching surface.").
ls_word('upcoming', adjective, forms(invariant), evidence(occurrences(7)), "The corpus uses upcoming adjectivally, and Webster supplies no matching surface.").
ls_word('update', common_noun, forms(noun(update, updates)), evidence(occurrences(5)), "The corpus uses update as a noun, and Webster supplies no matching surface.").
ls_word('updates', common_noun, forms(noun(update, updates)), evidence(occurrences(10)), "The corpus uses updates as a noun, and Webster supplies no matching surface.").
ls_word('usually', adverb, forms(invariant), evidence(occurrences(6)), "The corpus uses usually adverbially, and Webster supplies no matching surface.").
ls_word('ve', contraction_fragment, none, evidence(occurrences(11)), "The tokenizer detached ve from an apostrophe contraction, so the fragment is not admitted as a word.").
ls_word('vegetables', common_noun, forms(noun(vegetable, vegetables)), evidence(occurrences(34)), "The corpus uses vegetables as a noun, and Webster supplies no matching surface.").
ls_word('vet', common_noun, forms(noun(vet, vets)), evidence(occurrences(3)), "The corpus uses vet as a noun, and Webster supplies no matching surface.").
ls_word('video', common_noun, forms(noun(video, videos)), evidence(occurrences(96)), "The corpus uses video as a noun, and Webster supplies no matching surface.").
ls_word('videos', common_noun, forms(noun(video, videos)), evidence(occurrences(14)), "The corpus uses videos as a noun, and Webster supplies no matching surface.").
ls_word('village', common_noun, forms(noun(village, villages)), evidence(occurrences(10)), "The corpus uses village as a noun, and Webster supplies no matching surface.").
ls_word('visitors', common_noun, forms(noun(visitor, visitors)), evidence(occurrences(54)), "The corpus uses visitors as a noun, and Webster supplies no matching surface.").
ls_word('vloggers', common_noun, forms(noun(vlogger, vloggers)), evidence(occurrences(2)), "The corpus uses vloggers as a noun, and Webster supplies no matching surface.").
ls_word('volleyballs', common_noun, forms(noun(volleyball, volleyballs)), evidence(occurrences(12)), "The corpus uses volleyballs as a noun, and Webster supplies no matching surface.").
ls_word('voltaire', given_name, none, evidence(occurrences(6)), "The corpus uses voltaire as a capitalized name for a person.").
ls_word('w', algebra_symbol, forms(invariant), evidence(occurrences(7)), "The corpus uses w as a mathematical variable, Greek symbol, or labeled figure symbol.").
ls_word('walled', adjective, forms(invariant), evidence(occurrences(12)), "The corpus uses walled adjectivally, and Webster supplies no matching surface.").
ls_word('wallpaper', common_noun, forms(noun(wallpaper, wallpaper)), evidence(occurrences(24)), "The corpus uses wallpaper as a noun, and Webster supplies no matching surface.").
ls_word('walmart', named_entity, none, evidence(occurrences(12)), "The corpus uses walmart as a capitalized entity, product, team, or disease label.").
ls_word('wanda', given_name, none, evidence(occurrences(12)), "The corpus uses wanda as a capitalized name for a person.").
ls_word('was30', tokenizer_artifact, none, evidence(occurrences(2)), "The source fuses was and 30, so this token remains a tokenizer artifact.").
ls_word('wasn', contraction_fragment, none, evidence(occurrences(9)), "The tokenizer detached wasn from an apostrophe contraction, so the fragment is not admitted as a word.").
ls_word('wayne', place_name, none, evidence(occurrences(1)), "The corpus uses wayne as a capitalized place name or place-name component.").
ls_word('website', common_noun, forms(noun(website, websites)), evidence(occurrences(2)), "The corpus uses website as a noun, and Webster supplies no matching surface.").
ls_word('wednesday', temporal_word, forms(noun(wednesday, wednesdays)), evidence(occurrences(66)), "The corpus uses wednesday as a day or relative-time expression.").
ls_word('wednesdays', temporal_word, forms(noun(wednesday, wednesdays)), evidence(occurrences(4)), "The corpus uses wednesdays as a day or relative-time expression.").
ls_word('weekday', temporal_word, forms(noun(weekday, weekdays)), evidence(occurrences(24)), "The corpus uses weekday as a day or relative-time expression.").
ls_word('weekdays', temporal_word, forms(noun(weekday, weekdays)), evidence(occurrences(29)), "The corpus uses weekdays as a day or relative-time expression.").
ls_word('weekend', temporal_word, forms(noun(weekend, weekends)), evidence(occurrences(47)), "The corpus uses weekend as a day or relative-time expression.").
ls_word('weekends', temporal_word, forms(noun(weekend, weekends)), evidence(occurrences(30)), "The corpus uses weekends as a day or relative-time expression.").
ls_word('weeknights', temporal_word, forms(noun(weeknight, weeknights)), evidence(occurrences(4)), "The corpus uses weeknights as a day or relative-time expression.").
ls_word('wendi', given_name, none, evidence(occurrences(40)), "The corpus uses wendi as a capitalized name for a person.").
ls_word('wendy', given_name, none, evidence(occurrences(20)), "The corpus uses wendy as a capitalized name for a person.").
ls_word('weren', contraction_fragment, none, evidence(occurrences(1)), "The tokenizer detached weren from an apostrophe contraction, so the fragment is not admitted as a word.").
ls_word('wes', given_name, none, evidence(occurrences(3)), "The corpus uses wes as a capitalized name for a person.").
ls_word('widget', common_noun, forms(noun(widget, widgets)), evidence(occurrences(4)), "The corpus uses widget as a noun, and Webster supplies no matching surface.").
ls_word('widgets', common_noun, forms(noun(widget, widgets)), evidence(occurrences(6)), "The corpus uses widgets as a noun, and Webster supplies no matching surface.").
ls_word('william', given_name, none, evidence(occurrences(24)), "The corpus uses william as a capitalized name for a person.").
ls_word('willowton', place_name, none, evidence(occurrences(4)), "The corpus uses willowton as a capitalized place name or place-name component.").
ls_word('wilson', given_name, none, evidence(occurrences(4)), "The corpus uses wilson as a capitalized name for a person.").
ls_word('winston', given_name, none, evidence(occurrences(9)), "The corpus uses winston as a capitalized name for a person.").
ls_word('woke', corpus_verb, forms(verb(wake, wakes, woke, waking, woken)), evidence(occurrences(4)), "The corpus uses woke as a verb form, and the row records its full inflection.").
ls_word('workout', common_noun, forms(noun(workout, workouts)), evidence(occurrences(6)), "The corpus uses workout as a noun, and Webster supplies no matching surface.").
ls_word('x', algebra_symbol, forms(invariant), evidence(occurrences(2699)), "The corpus uses x as a mathematical variable, Greek symbol, or labeled figure symbol.").
ls_word('xavier', given_name, none, evidence(occurrences(20)), "The corpus uses xavier as a capitalized name for a person.").
ls_word('xena', given_name, none, evidence(occurrences(14)), "The corpus uses xena as a capitalized name for a person.").
ls_word('xl', abbreviation, forms(invariant), evidence(occurrences(9)), "The corpus uses xl as an invariant abbreviation or size label.").
ls_word('yd', unit_abbreviation, expands_to(yard), evidence(occurrences(5)), "The corpus uses yd as a unit abbreviation for yard.").
ls_word('york', place_name, none, evidence(occurrences(2)), "The corpus uses york as a capitalized place name or place-name component.").
ls_word('yulia', given_name, none, evidence(occurrences(10)), "The corpus uses yulia as a capitalized name for a person.").
ls_word('zap', corpus_verb, forms(verb(zap, zaps, zapped, zapping, zapped)), evidence(occurrences(4)), "The corpus uses zap as a verb form, and the row records its full inflection.").
ls_word('zapped', corpus_verb, forms(verb(zap, zaps, zapped, zapping, zapped)), evidence(occurrences(6)), "The corpus uses zapped as a verb form, and the row records its full inflection.").
ls_word('zero', math_term, forms(noun(zero, zeros)), evidence(occurrences(3)), "The corpus uses zero as a mathematics or classroom-analysis noun.").
ls_word('zeros', math_term, forms(noun(zero, zeros)), evidence(occurrences(1)), "The corpus uses zeros as a mathematics or classroom-analysis noun.").
ls_word('zika', named_entity, none, evidence(occurrences(6)), "The corpus uses zika as a capitalized entity, product, team, or disease label.").
ls_word('zombies', common_noun, forms(noun(zomby, zombies)), evidence(occurrences(22)), "The corpus uses zombies as a noun, and Webster supplies no matching surface.").
ls_word('zoo', common_noun, forms(noun(zoo, zoos)), evidence(occurrences(2)), "The corpus uses zoo as a noun, and Webster supplies no matching surface.").
ls_word('zubir', given_name, none, evidence(occurrences(4)), "The corpus uses zubir as a capitalized name for a person.").
ls_word('zucchini', common_noun, forms(noun(zucchini, zucchinis)), evidence(occurrences(8)), "The corpus uses zucchini as a noun, and Webster supplies no matching surface.").
ls_word('π', algebra_symbol, forms(invariant), evidence(occurrences(2)), "The corpus uses π as a mathematical variable, Greek symbol, or labeled figure symbol.").
ls_word('πr', algebra_symbol, forms(invariant), evidence(occurrences(5)), "The corpus uses πr as a mathematical variable, Greek symbol, or labeled figure symbol.").

% IM teacher-guide saturation pass 1 dispositions.
ls_word('aa', curriculum_code, forms(invariant), evidence(occurrences(12), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('ab25', curriculum_code, forms(invariant), evidence(occurrences(6), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('abstractly', adverb, forms(invariant), evidence(occurrences(135), pass(guide_saturation_1)), "The guides use this word adverbially.").
ls_word('access', corpus_verb, forms(verb(access, accesss, accessed, accessing, accessed)), evidence(occurrences(4194), pass(guide_saturation_1)), "The guides use this instructional verb; the row records its five-form paradigm.").
ls_word('accuracy', math_term, forms(noun(accuracy, accuracies)), evidence(occurrences(13), pass(guide_saturation_1)), "The guides use this word as a mathematics or classroom-analysis noun.").
ls_word('additively', adverb, forms(invariant), evidence(occurrences(7), pass(guide_saturation_1)), "The guides use this word adverbially.").
ls_word('adriana', given_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('africa', place_name, none, evidence(occurrences(17), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('agassiz', family_name, none, evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('al16', curriculum_code, forms(invariant), evidence(occurrences(7), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('alabama', place_name, none, evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('alaska', place_name, none, evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('alicia', given_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('allyson', given_name, none, evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('analog', adjective, forms(invariant), evidence(occurrences(70), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('andres', given_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('angeles', place_name, none, evidence(occurrences(7), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('anteater', common_noun, forms(noun(anteater, anteaters)), evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('antennae', common_noun, forms(noun(antenna, antennae)), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('anthony', given_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('apache', place_name, none, evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('applesauce', common_noun, forms(noun(applesauce, applesauces)), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('applet', common_noun, forms(noun(applet, applets)), evidence(occurrences(11), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('apr', abbreviation, forms(invariant), evidence(occurrences(9), pass(guide_saturation_1)), "The guides use this invariant abbreviation or file label.").
ls_word('arizona', place_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('attendees', common_noun, forms(noun(attendee, attendees)), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('aug', abbreviation, forms(invariant), evidence(occurrences(8), pass(guide_saturation_1)), "The guides use this invariant abbreviation or file label.").
ls_word('australia', place_name, none, evidence(occurrences(9), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('awareness', pedagogy_term, forms(noun(awareness, awarenesses)), evidence(occurrences(47), pass(guide_saturation_1)), "The guides use this noun for an instructional routine, resource, or analysis practice.").
ls_word('azulejos', common_noun, forms(noun(azulejo, azulejos)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('backpack', common_noun, forms(noun(backpack, backpacks)), evidence(occurrences(17), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('backpacks', common_noun, forms(noun(backpack, backpacks)), evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('bahamas', place_name, none, evidence(occurrences(7), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('bao', given_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('baseline', common_noun, forms(noun(baseline, baselines)), evidence(occurrences(8), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('bb', curriculum_code, forms(invariant), evidence(occurrences(8), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('beamon', family_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('beliveau', family_name, none, evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('benchmark', math_term, forms(noun(benchmark, benchmarks)), evidence(occurrences(82), pass(guide_saturation_1)), "The guides use this word as a mathematics or classroom-analysis noun.").
ls_word('benchmarks', math_term, forms(noun(benchmark, benchmarks)), evidence(occurrences(33), pass(guide_saturation_1)), "The guides use this word as a mathematics or classroom-analysis noun.").
ls_word('bermuda', place_name, none, evidence(occurrences(10), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('bindergarten', tokenizer_artifact, none, evidence(occurrences(2), pass(guide_saturation_1)), "uncertain: the guide text contains a truncated, fused, or malformed token, so it remains refused as a word.").
ls_word('bingo', named_entity, none, evidence(occurrences(138), pass(guide_saturation_1)), "The guides use this token as a named game, organization, event, or team.").
ls_word('blackline', pedagogy_term, forms(noun(blackline, blacklines)), evidence(occurrences(343), pass(guide_saturation_1)), "The guides use this noun for an instructional routine, resource, or analysis practice.").
ls_word('boxy', adjective, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('bq64', curriculum_code, forms(invariant), evidence(occurrences(6), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('brainstorm', corpus_verb, forms(verb(brainstorm, brainstorms, brainstormed, brainstorming, brainstormed)), evidence(occurrences(26), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('brantley', family_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('breadsticks', common_noun, forms(noun(breadstick, breadsticks)), evidence(occurrences(6), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('brisco', family_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('brooklyn', place_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('burgers', common_noun, forms(noun(burger, burgers)), evidence(occurrences(11), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('california', place_name, none, evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('cardinality', math_term, forms(noun(cardinality, cardinalities)), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this word as a mathematics or classroom-analysis noun.").
ls_word('cardstock', common_noun, forms(noun(cardstock, cardstock)), evidence(occurrences(23), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('carey', given_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('carolina', place_name, none, evidence(occurrences(6), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('carousel', common_noun, forms(noun(carousel, carousels)), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('carrie', given_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('cc', curriculum_code, forms(invariant), evidence(occurrences(7119), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('cd', abbreviation, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this invariant abbreviation or file label.").
ls_word('centavo', common_noun, forms(noun(centavo, centavos)), evidence(occurrences(7), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('centavos', common_noun, forms(noun(centavo, centavos)), evidence(occurrences(8), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('centered', adjective, forms(invariant), evidence(occurrences(7), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('chandra', given_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('chango', family_name, none, evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('checklist', common_noun, forms(noun(checklist, checklists)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('checkpoint', common_noun, forms(noun(checkpoint, checkpoints)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('cheesborough', family_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('cherokee', place_name, none, evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('chicago', place_name, none, evidence(occurrences(7), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('chihuahua', place_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('choctaw', place_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('cl48', curriculum_code, forms(invariant), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('clipboard', common_noun, forms(noun(clipboard, clipboards)), evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('clipboards', common_noun, forms(noun(clipboard, clipboards)), evidence(occurrences(10), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('co', tokenizer_artifact, none, evidence(occurrences(75), pass(guide_saturation_1)), "uncertain: the guide text contains a truncated, fused, or malformed token, so it remains refused as a word.").
ls_word('coded', corpus_verb, forms(verb(code, codes, coded, coding, coded)), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('coding', common_noun, forms(noun(coding, coding)), evidence(occurrences(6), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('collaborate', corpus_verb, forms(verb(collaborate, collaborates, collaborated, collaborating, collaborated)), evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('collage', common_noun, forms(noun(collage, collages)), evidence(occurrences(7), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('collages', common_noun, forms(noun(collage, collages)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('colombia', place_name, none, evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('colorful', adjective, forms(invariant), evidence(occurrences(6), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('commutativity', math_term, forms(noun(commutativity, commutativities)), evidence(occurrences(9), pass(guide_saturation_1)), "The guides use this word as a mathematics or classroom-analysis noun.").
ls_word('concentrate', corpus_verb, forms(verb(concentrate, concentrates, concentrated, concentrating, concentrated)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('conceptualize', corpus_verb, forms(verb(conceptualize, conceptualizes, conceptualized, conceptualizing, conceptualized)), evidence(occurrences(8), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('conceptually', adverb, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word adverbially.").
ls_word('contextual', adjective, forms(invariant), evidence(occurrences(16), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('contextualize', corpus_verb, forms(verb(contextualize, contextualizes, contextualized, contextualizing, contextualized)), evidence(occurrences(6), pass(guide_saturation_1)), "The guides use this instructional verb; the row records its five-form paradigm.").
ls_word('contextualized', corpus_verb, forms(verb(contextualize, contextualizes, contextualized, contextualizing, contextualized)), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('contextually', adverb, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word adverbially.").
ls_word('conversely', adverb, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word adverbially.").
ls_word('cooke', family_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('cornbread', common_noun, forms(noun(cornbread, cornbread)), evidence(occurrences(7), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('corrections', common_noun, forms(noun(correction, corrections)), evidence(occurrences(43), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('correspondence', math_term, forms(noun(correspondence, correspondences)), evidence(occurrences(12), pass(guide_saturation_1)), "The guides use this word as a mathematics or classroom-analysis noun.").
ls_word('correspondences', math_term, forms(noun(correspondences, correspondenceses)), evidence(occurrences(18), pass(guide_saturation_1)), "The guides use this word as a mathematics or classroom-analysis noun.").
ls_word('could', function_word, forms(invariant), evidence(occurrences(2390), pass(guide_saturation_1)), "The absorbed questioning-paper STOP list supplies this closed function-word judgment.").
ls_word('couldn', contraction_fragment, none, evidence(occurrences(27), pass(guide_saturation_1)), "The tokenizer detached this contraction fragment; it remains refused as a word.").
ls_word('coun', tokenizer_artifact, none, evidence(occurrences(2), pass(guide_saturation_1)), "uncertain: the guide text contains a truncated, fused, or malformed token, so it remains refused as a word.").
ls_word('council', common_noun, forms(noun(council, councils)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('countdown', common_noun, forms(noun(countdown, countdown)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('counterparts', common_noun, forms(noun(counterparts, counterpartses)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('countless', adjective, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('countries', common_noun, forms(noun(country, countries)), evidence(occurrences(25), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('craig', given_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('cranberry', common_noun, forms(noun(cranberry, cranberries)), evidence(occurrences(6), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('cranes', common_noun, forms(noun(crane, cranes)), evidence(occurrences(10), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('crawly', adjective, forms(invariant), evidence(occurrences(8), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('creation', common_noun, forms(noun(creation, creations)), evidence(occurrences(7), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('creations', common_noun, forms(noun(creation, creations)), evidence(occurrences(13), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('creative', adjective, forms(invariant), evidence(occurrences(12), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('creativecommons', web_token, forms(invariant), evidence(occurrences(5), pass(guide_saturation_1)), "The guide source metadata uses this web, file-conversion, or publishing token.").
ls_word('creatures', common_noun, forms(noun(creature, creatures)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('creepy', adjective, forms(invariant), evidence(occurrences(8), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('criteria', common_noun, forms(noun(criterion, criteria)), evidence(occurrences(15), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('critical', adjective, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('cubbies', common_noun, forms(noun(cubby, cubbies)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('cultivate', corpus_verb, forms(verb(cultivate, cultivates, cultivated, cultivating, cultivated)), evidence(occurrences(17), pass(guide_saturation_1)), "The guides use this instructional verb; the row records its five-form paradigm.").
ls_word('cumbersome', adjective, forms(invariant), evidence(occurrences(8), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('curiosity', common_noun, forms(noun(curiosity, curiosities)), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('curious', adjective, forms(invariant), evidence(occurrences(12), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('currency', common_noun, forms(noun(currency, currencies)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('curriculum', common_noun, forms(noun(curriculum, curriculum)), evidence(occurrences(92), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('cutout', common_noun, forms(noun(cutout, cutouts)), evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('cutouts', common_noun, forms(noun(cutout, cutouts)), evidence(occurrences(10), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('darker', adjective, forms(invariant), evidence(occurrences(9), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('dc', abbreviation, forms(invariant), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this invariant abbreviation or file label.").
ls_word('dd', curriculum_code, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('de', name_particle, forms(invariant), evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this invariant particle inside a person's name.").
ls_word('debris', common_noun, forms(noun(debris, debris)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('dec', abbreviation, forms(invariant), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this invariant abbreviation or file label.").
ls_word('decontextualize', corpus_verb, forms(verb(decontextualize, decontextualizes, decontextualized, decontextualizing, decontextualized)), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this instructional verb; the row records its five-form paradigm.").
ls_word('decontextualized', corpus_verb, forms(verb(decontextualize, decontextualizes, decontextualized, decontextualizing, decontextualized)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('dominoes', common_noun, forms(noun(domino, dominoes)), evidence(occurrences(21), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('dosage', common_noun, forms(noun(dosage, dosage)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('downplayed', corpus_verb, forms(verb(downplay, downplays, downplayed, downplaying, downplayed)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('dragonflies', common_noun, forms(noun(dragonfly, dragonflies)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('dragonfly', common_noun, forms(noun(dragonfly, dragonflies)), evidence(occurrences(6), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('dreidels', common_noun, forms(noun(dreidel, dreidels)), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('e343', curriculum_code, forms(invariant), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('ee', curriculum_code, forms(invariant), evidence(occurrences(11), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('egypt', place_name, none, evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('eiffel', family_name, none, evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('endpoint', math_term, forms(noun(endpoint, endpoints)), evidence(occurrences(17), pass(guide_saturation_1)), "The guides use this word as a mathematics or classroom-analysis noun.").
ls_word('endpoints', math_term, forms(noun(endpoint, endpoints)), evidence(occurrences(31), pass(guide_saturation_1)), "The guides use this word as a mathematics or classroom-analysis noun.").
ls_word('english106', tokenizer_artifact, none, evidence(occurrences(2), pass(guide_saturation_1)), "uncertain: the guide text contains a truncated, fused, or malformed token, so it remains refused as a word.").
ls_word('enrique', given_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('environmental', adjective, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('eral', tokenizer_artifact, none, evidence(occurrences(6), pass(guide_saturation_1)), "uncertain: the guide text contains a truncated, fused, or malformed token, so it remains refused as a word.").
ls_word('es', pronunciation_token, forms(invariant), evidence(occurrences(7), pass(guide_saturation_1)), "The guides use this invariant pronunciation or transliteration component.").
ls_word('expectation', math_term, forms(noun(expectation, expectations)), evidence(occurrences(26), pass(guide_saturation_1)), "The guides use this word as a mathematics or classroom-analysis noun.").
ls_word('expectations', math_term, forms(noun(expectation, expectations)), evidence(occurrences(55), pass(guide_saturation_1)), "The guides use this word as a mathematics or classroom-analysis noun.").
ls_word('exposure', common_noun, forms(noun(exposure, exposure)), evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('facedown', adjective, forms(invariant), evidence(occurrences(7), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('fahrenheit', adjective, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('farthest', adverb, forms(invariant), evidence(occurrences(21), pass(guide_saturation_1)), "The guides use this word adverbially.").
ls_word('fe', place_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('feasible', adjective, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('feb', abbreviation, forms(invariant), evidence(occurrences(13), pass(guide_saturation_1)), "The guides use this invariant abbreviation or file label.").
ls_word('felix', given_name, none, evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('fenton', family_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('fenway', place_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('ferris', family_name, none, evidence(occurrences(11), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('ff', curriculum_code, forms(invariant), evidence(occurrences(8), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('firsthand', adjective, forms(invariant), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('fizzy', adjective, forms(invariant), evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('flagpole', common_noun, forms(noun(flagpole, flagpoles)), evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('flexibly', adverb, forms(invariant), evidence(occurrences(39), pass(guide_saturation_1)), "The guides use this word adverbially.").
ls_word('flickr', web_token, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guide source metadata uses this web, file-conversion, or publishing token.").
ls_word('florida', place_name, none, evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('foldable', adjective, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('format', common_noun, forms(noun(format, formats)), evidence(occurrences(12), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('formatively', adverb, forms(invariant), evidence(occurrences(8), pass(guide_saturation_1)), "The guides use this word adverbially.").
ls_word('formats', common_noun, forms(noun(format, formats)), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('formatted', adjective, forms(invariant), evidence(occurrences(9), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('foundational', adjective, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('freehand', adjective, forms(invariant), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('friendliest', adjective, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('fuertes', pronunciation_token, forms(invariant), evidence(occurrences(7), pass(guide_saturation_1)), "The guides use this invariant pronunciation or transliteration component.").
ls_word('fuhl', pronunciation_token, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this invariant pronunciation or transliteration component.").
ls_word('fundraising', common_noun, forms(noun(fundraising, fundraising)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('g1', curriculum_code, forms(invariant), evidence(occurrences(148), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('g2', curriculum_code, forms(invariant), evidence(occurrences(150), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('g3', curriculum_code, forms(invariant), evidence(occurrences(143), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('g4', curriculum_code, forms(invariant), evidence(occurrences(151), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('g5', curriculum_code, forms(invariant), evidence(occurrences(148), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('gameboard', common_noun, forms(noun(gameboard, gameboards)), evidence(occurrences(226), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('gameboards', common_noun, forms(noun(gameboard, gameboards)), evidence(occurrences(72), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('gg', curriculum_code, forms(invariant), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('ghana', place_name, none, evidence(occurrences(13), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('gila', place_name, none, evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('giza', place_name, none, evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('gk', curriculum_code, forms(invariant), evidence(occurrences(139), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('glub', interjection, forms(invariant), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this invariant conversational interjection.").
ls_word('goh', pronunciation_token, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this invariant pronunciation or transliteration component.").
ls_word('grade1', curriculum_code, forms(invariant), evidence(occurrences(148), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('grade2', curriculum_code, forms(invariant), evidence(occurrences(150), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('grade3', curriculum_code, forms(invariant), evidence(occurrences(143), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('grade4', curriculum_code, forms(invariant), evidence(occurrences(151), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('grade5', curriculum_code, forms(invariant), evidence(occurrences(148), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('grandparents', common_noun, forms(noun(grandparent, grandparents)), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('granola', common_noun, forms(noun(granola, granolas)), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('grapefruits', common_noun, forms(noun(grapefruit, grapefruits)), evidence(occurrences(12), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('gridded', adjective, forms(invariant), evidence(occurrences(56), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('gulab', common_noun, forms(noun(gulab, gulabs)), evidence(occurrences(6), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('gustafson', family_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('gymnasium', common_noun, forms(noun(gymnasium, gymnasiums)), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('halftime', common_noun, forms(noun(halftime, halftime)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('hallway', common_noun, forms(noun(hallway, hallways)), evidence(occurrences(23), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('handout', common_noun, forms(noun(handout, handouts)), evidence(occurrences(115), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('handouts', common_noun, forms(noun(handout, handouts)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('harrisburg', place_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('hasn', contraction_fragment, none, evidence(occurrences(7), pass(guide_saturation_1)), "The tokenizer detached this contraction fragment; it remains refused as a word.").
ls_word('hh', curriculum_code, forms(invariant), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('highlighters', common_noun, forms(noun(highlighter, highlighters)), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('hirst', family_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('hohs', pronunciation_token, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this invariant pronunciation or transliteration component.").
ls_word('homeroom', common_noun, forms(noun(homeroom, homerooms)), evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('hr', unit_abbreviation, expands_to(hour), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this unit abbreviation with the stated expansion.").
ls_word('https', web_token, forms(invariant), evidence(occurrences(11), pass(guide_saturation_1)), "The guide source metadata uses this web, file-conversion, or publishing token.").
ls_word('huskies', common_noun, forms(noun(husky, huskies)), evidence(occurrences(6), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('ii', curriculum_code, forms(invariant), evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('illustrativemathematics', web_token, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guide source metadata uses this web, file-conversion, or publishing token.").
ls_word('im', curriculum_code, forms(invariant), evidence(occurrences(1041), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('imprecise', adjective, forms(invariant), evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('incrementally', adverb, forms(invariant), evidence(occurrences(8), pass(guide_saturation_1)), "The guides use this word adverbially.").
ls_word('indiana', place_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('indianapolis', place_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('indo', adjective, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('info', abbreviation, forms(invariant), evidence(occurrences(83), pass(guide_saturation_1)), "The guides use this invariant abbreviation or file label.").
ls_word('interactive', adjective, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('interchangeably', adverb, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word adverbially.").
ls_word('internalize', corpus_verb, forms(verb(internalize, internalizes, internalized, internalizing, internalized)), evidence(occurrences(314), pass(guide_saturation_1)), "The guides use this instructional verb; the row records its five-form paradigm.").
ls_word('internet', common_noun, forms(noun(internet, internets)), evidence(occurrences(9), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('interpet', tokenizer_artifact, none, evidence(occurrences(2), pass(guide_saturation_1)), "uncertain: the guide text contains a truncated, fused, or malformed token, so it remains refused as a word.").
ls_word('interquartile', adjective, forms(invariant), evidence(occurrences(85), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('intuit', corpus_verb, forms(verb(intuit, intuits, intuited, intuiting, intuited)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('iqrs', math_term, forms(noun(iqr, iqrs)), evidence(occurrences(29), pass(guide_saturation_1)), "The guides use this word as a mathematics or classroom-analysis noun.").
ls_word('ireland', place_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('isn', contraction_fragment, none, evidence(occurrences(66), pass(guide_saturation_1)), "The tokenizer detached this contraction fragment; it remains refused as a word.").
ls_word('its', function_word, forms(invariant), evidence(occurrences(428), pass(guide_saturation_1)), "The absorbed questioning-paper STOP list supplies this closed function-word judgment.").
ls_word('jackie', given_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('jacksonville', place_name, none, evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('jamuns', common_noun, forms(noun(jamun, jamuns)), evidence(occurrences(6), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('jarrion', given_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('jeison', given_name, none, evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('jj', curriculum_code, forms(invariant), evidence(occurrences(10), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('joyner', family_name, none, evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('json', abbreviation, forms(invariant), evidence(occurrences(18), pass(guide_saturation_1)), "The guides use this invariant abbreviation or file label.").
ls_word('judy', given_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('k', curriculum_code, forms(invariant), evidence(occurrences(1649), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('kah', pronunciation_token, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this invariant pronunciation or transliteration component.").
ls_word('kels', pronunciation_token, forms(invariant), evidence(occurrences(7), pass(guide_saturation_1)), "The guides use this invariant pronunciation or transliteration component.").
ls_word('keres', place_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('kersee', family_name, none, evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('keyboarding', common_noun, forms(noun(keyboarding, keyboardings)), evidence(occurrences(6), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('kinesthetic', adjective, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('kinesthetically', adverb, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word adverbially.").
ls_word('koi', common_noun, forms(noun(koi, kois)), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('komodo', place_name, none, evidence(occurrences(13), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('kruh', pronunciation_token, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this invariant pronunciation or transliteration component.").
ls_word('l1', curriculum_code, forms(invariant), evidence(occurrences(50), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('l10', curriculum_code, forms(invariant), evidence(occurrences(49), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('l11', curriculum_code, forms(invariant), evidence(occurrences(48), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('l12', curriculum_code, forms(invariant), evidence(occurrences(47), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('l13', curriculum_code, forms(invariant), evidence(occurrences(45), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('l14', curriculum_code, forms(invariant), evidence(occurrences(43), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('l15', curriculum_code, forms(invariant), evidence(occurrences(39), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('l16', curriculum_code, forms(invariant), evidence(occurrences(32), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('l17', curriculum_code, forms(invariant), evidence(occurrences(29), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('l18', curriculum_code, forms(invariant), evidence(occurrences(24), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('l19', curriculum_code, forms(invariant), evidence(occurrences(17), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('l2', curriculum_code, forms(invariant), evidence(occurrences(50), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('l20', curriculum_code, forms(invariant), evidence(occurrences(16), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('l21', curriculum_code, forms(invariant), evidence(occurrences(13), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('l22', curriculum_code, forms(invariant), evidence(occurrences(9), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('l23', curriculum_code, forms(invariant), evidence(occurrences(7), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('l24', curriculum_code, forms(invariant), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('l25', curriculum_code, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('l26', curriculum_code, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('l3', curriculum_code, forms(invariant), evidence(occurrences(50), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('l4', curriculum_code, forms(invariant), evidence(occurrences(50), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('l5', curriculum_code, forms(invariant), evidence(occurrences(50), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('l6', curriculum_code, forms(invariant), evidence(occurrences(50), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('l7', curriculum_code, forms(invariant), evidence(occurrences(50), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('l8', curriculum_code, forms(invariant), evidence(occurrences(50), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('l9', curriculum_code, forms(invariant), evidence(occurrences(49), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('lah', pronunciation_token, forms(invariant), evidence(occurrences(6), pass(guide_saturation_1)), "The guides use this invariant pronunciation or transliteration component.").
ls_word('lapa', common_noun, forms(noun(lapa, lapas)), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('laptop', common_noun, forms(noun(laptop, laptops)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('largemouth', adjective, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('lassi', common_noun, forms(noun(lassi, lassis)), evidence(occurrences(14), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('lawson', family_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('layered', adjective, forms(invariant), evidence(occurrences(11), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('layout', common_noun, forms(noun(layout, layouts)), evidence(occurrences(20), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('leftmost', adjective, forms(invariant), evidence(occurrences(9), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('lemony', adjective, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('leveraging', corpus_verb, forms(verb(leverage, leverages, leveraged, leveraging, leveraged)), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('lifetime', common_noun, forms(noun(lifetime, lifetime)), evidence(occurrences(8), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('lincoln', place_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('linda', given_name, none, evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('logistically', adverb, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word adverbially.").
ls_word('logo', common_noun, forms(noun(logo, logos)), evidence(occurrences(8), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('loh', pronunciation_token, forms(invariant), evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this invariant pronunciation or transliteration component.").
ls_word('lorraine', given_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('lotería', named_entity, none, evidence(occurrences(10), pass(guide_saturation_1)), "The guides use this token as a named game, organization, event, or team.").
ls_word('louis', given_name, none, evidence(occurrences(6), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('luge', common_noun, forms(noun(luge, luges)), evidence(occurrences(11), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('lunchtime', common_noun, forms(noun(lunchtime, lunchtimes)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('macramé', common_noun, forms(noun(macramé, macramés)), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('madison', place_name, none, evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('mahn', pronunciation_token, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this invariant pronunciation or transliteration component.").
ls_word('maker', common_noun, forms(noun(maker, makers)), evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('makers', common_noun, forms(noun(maker, makers)), evidence(occurrences(17), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('malaysia', place_name, none, evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('mancala', named_entity, none, evidence(occurrences(15), pass(guide_saturation_1)), "The guides use this token as a named game, organization, event, or team.").
ls_word('manipulatives', pedagogy_term, forms(noun(manipulative, manipulatives)), evidence(occurrences(16), pass(guide_saturation_1)), "The guides use this noun for an instructional routine, resource, or analysis practice.").
ls_word('margarita', given_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('mathematically', adverb, forms(invariant), evidence(occurrences(17), pass(guide_saturation_1)), "The guides use this word adverbially.").
ls_word('mathematize', corpus_verb, forms(verb(mathematize, mathematizes, mathematized, mathematizing, mathematized)), evidence(occurrences(7), pass(guide_saturation_1)), "The guides use this instructional verb; the row records its five-form paradigm.").
ls_word('mayng', pronunciation_token, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this invariant pronunciation or transliteration component.").
ls_word('md', curriculum_code, forms(invariant), evidence(occurrences(1287), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('meaningful', adjective, forms(invariant), evidence(occurrences(9), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('meaningfully', adverb, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word adverbially.").
ls_word('meegan', given_name, none, evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('messy', adjective, forms(invariant), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('meta', adjective, forms(invariant), evidence(occurrences(38), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('mexico', place_name, none, evidence(occurrences(22), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('mg', unit_abbreviation, expands_to(milligram), evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this unit abbreviation with the stated expansion.").
ls_word('miami', place_name, none, evidence(occurrences(6), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('michigan', place_name, none, evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('microwave', common_noun, forms(noun(microwave, microwaves)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('midpoint', math_term, forms(noun(midpoint, midpoints)), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this word as a mathematics or classroom-analysis noun.").
ls_word('miguel', given_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('milwaukee', place_name, none, evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('minnesota', place_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('miscalculation', common_noun, forms(noun(miscalculation, miscalculations)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('mlr', curriculum_code, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('mlr1', curriculum_code, forms(invariant), evidence(occurrences(176), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('mlr2', curriculum_code, forms(invariant), evidence(occurrences(319), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('mlr3', curriculum_code, forms(invariant), evidence(occurrences(47), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('mlr4', curriculum_code, forms(invariant), evidence(occurrences(54), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('mlr5', curriculum_code, forms(invariant), evidence(occurrences(82), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('mlr6', curriculum_code, forms(invariant), evidence(occurrences(118), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('mlr7', curriculum_code, forms(invariant), evidence(occurrences(365), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('mlr8', curriculum_code, forms(invariant), evidence(occurrences(1112), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('mm', unit_abbreviation, expands_to(millimeter), evidence(occurrences(22), pass(guide_saturation_1)), "The guides use this unit abbreviation with the stated expansion.").
ls_word('mondrian', named_entity, none, evidence(occurrences(20), pass(guide_saturation_1)), "The guides use this token as a named game, organization, event, or team.").
ls_word('monique', given_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('monitoring', pedagogy_term, forms(noun(monitoring, monitorings)), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this noun for an instructional routine, resource, or analysis practice.").
ls_word('motivation', common_noun, forms(noun(motivation, motivation)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('mp1', curriculum_code, forms(invariant), evidence(occurrences(86), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('mp2', curriculum_code, forms(invariant), evidence(occurrences(400), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('mp3', curriculum_code, forms(invariant), evidence(occurrences(226), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('mp4', curriculum_code, forms(invariant), evidence(occurrences(181), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('mp5', curriculum_code, forms(invariant), evidence(occurrences(65), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('mp6', curriculum_code, forms(invariant), evidence(occurrences(357), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('mp7', curriculum_code, forms(invariant), evidence(occurrences(614), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('mp8', curriculum_code, forms(invariant), evidence(occurrences(138), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('multimodal', adjective, forms(invariant), evidence(occurrences(14), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('mustardy', adjective, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('nashville', place_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('navajo', place_name, none, evidence(occurrences(10), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('nba', abbreviation, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this invariant abbreviation or file label.").
ls_word('nbt', curriculum_code, forms(invariant), evidence(occurrences(1915), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('nc', curriculum_code, forms(invariant), evidence(occurrences(6191), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('newton', family_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('nf', curriculum_code, forms(invariant), evidence(occurrences(971), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('nic', pronunciation_token, forms(invariant), evidence(occurrences(7), pass(guide_saturation_1)), "The guides use this invariant pronunciation or transliteration component.").
ls_word('nie', pronunciation_token, forms(invariant), evidence(occurrences(7), pass(guide_saturation_1)), "The guides use this invariant pronunciation or transliteration component.").
ls_word('nm44', curriculum_code, forms(invariant), evidence(occurrences(8), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('noisemakers', common_noun, forms(noun(noisemaker, noisemakers)), evidence(occurrences(7), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('nondefining', adjective, forms(invariant), evidence(occurrences(13), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('nonexample', math_term, forms(noun(nonexample, nonexamples)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a mathematics or classroom-analysis noun.").
ls_word('nonexamples', math_term, forms(noun(nonexample, nonexamples)), evidence(occurrences(21), pass(guide_saturation_1)), "The guides use this word as a mathematics or classroom-analysis noun.").
ls_word('nonfiction', adjective, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('notion', common_noun, forms(noun(notion, notions)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('nov', abbreviation, forms(invariant), evidence(occurrences(8), pass(guide_saturation_1)), "The guides use this invariant abbreviation or file label.").
ls_word('ns', curriculum_code, forms(invariant), evidence(occurrences(13), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('oa', curriculum_code, forms(invariant), evidence(occurrences(2093), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('obtuse', adjective, forms(invariant), evidence(occurrences(65), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('oct', abbreviation, forms(invariant), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this invariant abbreviation or file label.").
ls_word('oge', given_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('ojibwa', place_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('ok', abbreviation, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this invariant abbreviation or file label.").
ls_word('okay', interjection, forms(invariant), evidence(occurrences(23), pass(guide_saturation_1)), "The guides use this invariant conversational interjection.").
ls_word('oklahoma', place_name, none, evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('olympics', named_entity, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this token as a named game, organization, event, or team.").
ls_word('openupresources', web_token, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guide source metadata uses this web, file-conversion, or publishing token.").
ls_word('opt', corpus_verb, forms(verb(opt, opts, opted, opting, opted)), evidence(occurrences(6), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('optimize', corpus_verb, forms(verb(optimize, optimizes, optimized, optimizing, optimized)), evidence(occurrences(42), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('oregano', common_noun, forms(noun(oregano, oregano)), evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('org', web_token, forms(invariant), evidence(occurrences(13), pass(guide_saturation_1)), "The guide source metadata uses this web, file-conversion, or publishing token.").
ls_word('organizational', adjective, forms(invariant), evidence(occurrences(11), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('origami', common_noun, forms(noun(origami, origamis)), evidence(occurrences(9), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('others', function_word, forms(invariant), evidence(occurrences(536), pass(guide_saturation_1)), "The absorbed questioning-paper STOP list supplies this closed function-word judgment.").
ls_word('our', function_word, forms(invariant), evidence(occurrences(666), pass(guide_saturation_1)), "The absorbed questioning-paper STOP list supplies this closed function-word judgment.").
ls_word('overlapping', adjective, forms(invariant), evidence(occurrences(30), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('packaged', corpus_verb, forms(verb(package, packages, packaged, packaging, packaged)), evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('packaging', common_noun, forms(noun(packaging, packaging)), evidence(occurrences(7), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('paletas', common_noun, forms(noun(paleta, paletas)), evidence(occurrences(38), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('palooza', named_entity, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this token as a named game, organization, event, or team.").
ls_word('partially', adverb, forms(invariant), evidence(occurrences(45), pass(guide_saturation_1)), "The guides use this word adverbially.").
ls_word('partygoers', common_noun, forms(noun(partygoer, partygoers)), evidence(occurrences(14), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('pdf', abbreviation, forms(invariant), evidence(occurrences(36), pass(guide_saturation_1)), "The guides use this invariant abbreviation or file label.").
ls_word('pdfs', abbreviation, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this invariant abbreviation or file label.").
ls_word('pdftotext', web_token, forms(invariant), evidence(occurrences(18), pass(guide_saturation_1)), "The guide source metadata uses this web, file-conversion, or publishing token.").
ls_word('pennsylvania', place_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('penta', named_entity, none, evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this token as a named game, organization, event, or team.").
ls_word('percentile', math_term, forms(noun(percentile, percentiles)), evidence(occurrences(22), pass(guide_saturation_1)), "The guides use this word as a mathematics or classroom-analysis noun.").
ls_word('percentiles', math_term, forms(noun(percentile, percentiles)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a mathematics or classroom-analysis noun.").
ls_word('peña', family_name, none, evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('philadelphia', place_name, none, evidence(occurrences(11), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('phillips', family_name, none, evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('pierre', given_name, none, evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('pih', pronunciation_token, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this invariant pronunciation or transliteration component.").
ls_word('pilolo', named_entity, none, evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this token as a named game, organization, event, or team.").
ls_word('pixabay', web_token, forms(invariant), evidence(occurrences(4), pass(guide_saturation_1)), "The guide source metadata uses this web, file-conversion, or publishing token.").
ls_word('plastics', common_noun, forms(noun(plastic, plastics)), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('playlist', common_noun, forms(noun(playlist, playlists)), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('plc', curriculum_code, forms(invariant), evidence(occurrences(159), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('pointy', adjective, forms(invariant), evidence(occurrences(17), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('poppler', web_token, forms(invariant), evidence(occurrences(17), pass(guide_saturation_1)), "The guide source metadata uses this web, file-conversion, or publishing token.").
ls_word('portugal', place_name, none, evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('postcard', common_noun, forms(noun(postcard, postcards)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('powell', family_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('pre', tokenizer_artifact, none, evidence(occurrences(40), pass(guide_saturation_1)), "uncertain: the guide text contains a truncated, fused, or malformed token, so it remains refused as a word.").
ls_word('precisely', adverb, forms(invariant), evidence(occurrences(187), pass(guide_saturation_1)), "The guides use this word adverbially.").
ls_word('premade', adjective, forms(invariant), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('preschool', common_noun, forms(noun(preschool, preschools)), evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('preview', corpus_verb, forms(verb(preview, previews, previewed, previewing, previewed)), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('previewing', corpus_verb, forms(verb(preview, previews, previewed, previewing, previewed)), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('previews', corpus_verb, forms(verb(preview, previews, previewed, previewing, previewed)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('procedural', adjective, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('proceed', corpus_verb, forms(verb(proceed, proceeds, proceeded, proceeding, proceeded)), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('processing', pedagogy_term, forms(noun(processing, processings)), evidence(occurrences(612), pass(guide_saturation_1)), "The guides use this noun for an instructional routine, resource, or analysis practice.").
ls_word('progressed', corpus_verb, forms(verb(progress, progresss, progressed, progressing, progressed)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('q1', curriculum_code, forms(invariant), evidence(occurrences(101), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('q2', curriculum_code, forms(invariant), evidence(occurrences(62), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('q3', curriculum_code, forms(invariant), evidence(occurrences(95), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('quadrilat', tokenizer_artifact, none, evidence(occurrences(6), pass(guide_saturation_1)), "uncertain: the guide text contains a truncated, fused, or malformed token, so it remains refused as a word.").
ls_word('quantify', corpus_verb, forms(verb(quantify, quantifies, quantifyed, quantifying, quantifyed)), evidence(occurrences(13), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('quantifying', corpus_verb, forms(verb(quantify, quantifies, quantifyed, quantifying, quantifyed)), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('quantitatively', adverb, forms(invariant), evidence(occurrences(126), pass(guide_saturation_1)), "The guides use this word adverbially.").
ls_word('quinceañera', common_noun, forms(noun(quinceañera, quinceañeras)), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('quizzes', common_noun, forms(noun(quiz, quizzes)), evidence(occurrences(20), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('raccoon', common_noun, forms(noun(raccoon, raccoons)), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('rainwater', common_noun, forms(noun(rainwater, rainwater)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('ratings', common_noun, forms(noun(rating, ratings)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('reacquainted', corpus_verb, forms(verb(reacquaint, reacquaints, reacquainted, reacquainting, reacquainted)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('reallocate', corpus_verb, forms(verb(reallocate, reallocates, reallocated, reallocating, reallocated)), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('reallocated', corpus_verb, forms(verb(reallocate, reallocates, reallocated, reallocating, reallocated)), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('recap', pedagogy_term, forms(noun(recap, recaps)), evidence(occurrences(17), pass(guide_saturation_1)), "The guides use this noun for an instructional routine, resource, or analysis practice.").
ls_word('reconstruct', corpus_verb, forms(verb(reconstruct, reconstructs, reconstructed, reconstructing, reconstructed)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('recontextualize', corpus_verb, forms(verb(recontextualize, recontextualizes, recontextualized, recontextualizing, recontextualized)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this instructional verb; the row records its five-form paradigm.").
ls_word('reconvene', corpus_verb, forms(verb(reconvene, reconvenes, reconvened, reconvening, reconvened)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('recounting', corpus_verb, forms(verb(recount, recounts, recounted, recounting, recounted)), evidence(occurrences(10), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('rectilinear', adjective, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('recyclable', adjective, forms(invariant), evidence(occurrences(26), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('recyclables', common_noun, forms(noun(recyclable, recyclables)), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('redesign', corpus_verb, forms(verb(redesign, redesigns, redesigned, redesigning, redesigned)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('redesigned', corpus_verb, forms(verb(redesign, redesigns, redesigned, redesigning, redesigned)), evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('redistribute', corpus_verb, forms(verb(redistribute, redistributes, redistributed, redistributing, redistributed)), evidence(occurrences(6), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('redistributed', corpus_verb, forms(verb(redistribute, redistributes, redistributed, redistributing, redistributed)), evidence(occurrences(31), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('redistributing', corpus_verb, forms(verb(redistribute, redistributes, redistributed, redistributing, redistributed)), evidence(occurrences(7), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('redistribution', common_noun, forms(noun(redistribution, redistributions)), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('reference', pedagogy_term, forms(noun(reference, references)), evidence(occurrences(142), pass(guide_saturation_1)), "The guides use this noun for an instructional routine, resource, or analysis practice.").
ls_word('references', common_noun, forms(noun(reference, references)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('referencing', corpus_verb, forms(verb(reference, references, referenced, referencing, referenced)), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('referred', corpus_verb, forms(verb(refer, refers, referred, referring, referred)), evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('referring', corpus_verb, forms(verb(refer, refers, referred, referring, referred)), evidence(occurrences(12), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('reflect', corpus_verb, forms(verb(reflect, reflects, reflected, reflecting, reflected)), evidence(occurrences(258), pass(guide_saturation_1)), "The guides use this instructional verb; the row records its five-form paradigm.").
ls_word('reflects', corpus_verb, forms(verb(reflect, reflects, reflected, reflecting, reflected)), evidence(occurrences(9), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('refreshed', corpus_verb, forms(verb(refresh, refreshs, refreshed, refreshing, refreshed)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('regroupings', math_term, forms(noun(regrouping, regroupings)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a mathematics or classroom-analysis noun.").
ls_word('regularity', math_term, forms(noun(regularity, regularities)), evidence(occurrences(56), pass(guide_saturation_1)), "The guides use this word as a mathematics or classroom-analysis noun.").
ls_word('regulation', common_noun, forms(noun(regulation, regulation)), evidence(occurrences(23), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('rehearsal', common_noun, forms(noun(rehearsal, rehearsals)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('reinforcing', corpus_verb, forms(verb(reinforce, reinforces, reinforced, reinforcing, reinforced)), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('reintroduced', corpus_verb, forms(verb(reintroduce, reintroduces, reintroduced, reintroducing, reintroduced)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('reiterate', corpus_verb, forms(verb(reiterate, reiterates, reiterated, reiterating, reiterated)), evidence(occurrences(18), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('relation', math_term, forms(noun(relation, relations)), evidence(occurrences(25), pass(guide_saturation_1)), "The guides use this word as a mathematics or classroom-analysis noun.").
ls_word('relay', common_noun, forms(noun(relay, relays)), evidence(occurrences(10), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('released', corpus_verb, forms(verb(release, releases, released, releasing, released)), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('relevant', adjective, forms(invariant), evidence(occurrences(39), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('reliable', adjective, forms(invariant), evidence(occurrences(10), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('remainders', math_term, forms(noun(remainder, remainders)), evidence(occurrences(39), pass(guide_saturation_1)), "The guides use this word as a mathematics or classroom-analysis noun.").
ls_word('reminder', common_noun, forms(noun(reminder, reminders)), evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('reminders', common_noun, forms(noun(reminder, reminders)), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('removal', common_noun, forms(noun(removal, removals)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('repetition', common_noun, forms(noun(repetition, repetition)), evidence(occurrences(10), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('repetitive', adjective, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('rephrase', corpus_verb, forms(verb(rephrase, rephrases, rephrased, rephrasing, rephrased)), evidence(occurrences(39), pass(guide_saturation_1)), "The guides use this instructional verb; the row records its five-form paradigm.").
ls_word('replica', common_noun, forms(noun(replica, replicas)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('replicate', corpus_verb, forms(verb(replicate, replicates, replicated, replicating, replicated)), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('resemble', corpus_verb, forms(verb(resemble, resembles, resembled, resembling, resembled)), evidence(occurrences(6), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('resembles', corpus_verb, forms(verb(resemble, resembles, resembled, resembling, resembled)), evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('reservoir', common_noun, forms(noun(reservoir, reservoirs)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('resolution', common_noun, forms(noun(resolution, resolution)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('resources', common_noun, forms(noun(resource, resources)), evidence(occurrences(98), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('resp', tokenizer_artifact, none, evidence(occurrences(2), pass(guide_saturation_1)), "uncertain: the guide text contains a truncated, fused, or malformed token, so it remains refused as a word.").
ls_word('respective', adjective, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('responsible', adjective, forms(invariant), evidence(occurrences(9), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('restock', corpus_verb, forms(verb(restock, restocks, restocked, restocking, restocked)), evidence(occurrences(9), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('reused', corpus_verb, forms(verb(reuse, reuses, reused, reusing, reused)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('rhode', place_name, none, evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('richards', family_name, none, evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('ridley', family_name, none, evidence(occurrences(7), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('rightmost', adjective, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('rodriguez', family_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('role', common_noun, forms(noun(role, roles)), evidence(occurrences(21), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('roles', common_noun, forms(noun(role, roles)), evidence(occurrences(81), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('roti', common_noun, forms(noun(roti, rotis)), evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('rp', curriculum_code, forms(invariant), evidence(occurrences(25), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('rufus', given_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('rukhsana', given_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('s', contraction_fragment, none, evidence(occurrences(7745), pass(guide_saturation_1)), "The tokenizer detached this contraction fragment; it remains refused as a word.").
ls_word('sandbox', common_noun, forms(noun(sandbox, sandboxes)), evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('santa', place_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('sanya', given_name, none, evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('satsumas', common_noun, forms(noun(satsuma, satsumas)), evidence(occurrences(12), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('sayre', family_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('schneider', family_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('scooter', common_noun, forms(noun(scooter, scooters)), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('sep', abbreviation, forms(invariant), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this invariant abbreviation or file label.").
ls_word('separately', adverb, forms(invariant), evidence(occurrences(33), pass(guide_saturation_1)), "The guides use this word adverbially.").
ls_word('sequenced', corpus_verb, forms(verb(sequence, sequences, sequenced, sequencing, sequenced)), evidence(occurrences(40), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('sequencing', pedagogy_term, forms(noun(sequencing, sequencings)), evidence(occurrences(9), pass(guide_saturation_1)), "The guides use this noun for an instructional routine, resource, or analysis practice.").
ls_word('severely', adverb, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word adverbially.").
ls_word('sh', algebra_symbol, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this invariant token as a variable or labeled quantity.").
ls_word('shaunae', given_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('sheep', common_noun, forms(noun(sheep, sheep)), evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('should', function_word, forms(invariant), evidence(occurrences(1037), pass(guide_saturation_1)), "The absorbed questioning-paper STOP list supplies this closed function-word judgment.").
ls_word('shouldn', contraction_fragment, none, evidence(occurrences(4), pass(guide_saturation_1)), "The tokenizer detached this contraction fragment; it remains refused as a word.").
ls_word('showcase', corpus_verb, forms(verb(showcase, showcases, showcased, showcasing, showcased)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('silverman', family_name, none, evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('simultaneously', adverb, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word adverbially.").
ls_word('sk51', curriculum_code, forms(invariant), evidence(occurrences(6), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('skateboard', common_noun, forms(noun(skateboard, skateboards)), evidence(occurrences(7), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('skinnier', adjective, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('smiley', adjective, forms(invariant), evidence(occurrences(14), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('soh', pronunciation_token, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this invariant pronunciation or transliteration component.").
ls_word('sohz', pronunciation_token, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this invariant pronunciation or transliteration component.").
ls_word('soo', pronunciation_token, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this invariant pronunciation or transliteration component.").
ls_word('sp', curriculum_code, forms(invariant), evidence(occurrences(343), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('specificity', common_noun, forms(noun(specificity, specificities)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('staten', place_name, none, evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('steepest', adjective, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('stingrays', common_noun, forms(noun(stingray, stingrays)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('stopwatch', common_noun, forms(noun(stopwatch, stopwatches)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('storyboard', common_noun, forms(noun(storyboard, storyboards)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('strategically', adverb, forms(invariant), evidence(occurrences(73), pass(guide_saturation_1)), "The guides use this word adverbially.").
ls_word('subcategories', common_noun, forms(noun(subcategory, subcategories)), evidence(occurrences(10), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('subitize', corpus_verb, forms(verb(subitize, subitizes, subitized, subitizing, subitized)), evidence(occurrences(37), pass(guide_saturation_1)), "The guides use this instructional verb; the row records its five-form paradigm.").
ls_word('subitizing', pedagogy_term, forms(noun(subitizing, subitizings)), evidence(occurrences(19), pass(guide_saturation_1)), "The guides use this noun for an instructional routine, resource, or analysis practice.").
ls_word('subset', math_term, forms(noun(subset, subsets)), evidence(occurrences(22), pass(guide_saturation_1)), "The guides use this word as a mathematics or classroom-analysis noun.").
ls_word('subtotal', common_noun, forms(noun(subtotal, subtotals)), evidence(occurrences(6), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('successfully', adverb, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word adverbially.").
ls_word('succinctly', adverb, forms(invariant), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this word adverbially.").
ls_word('sunnyside', named_entity, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this token as a named game, organization, event, or team.").
ls_word('t', contraction_fragment, none, evidence(occurrences(1460), pass(guide_saturation_1)), "The tokenizer detached this contraction fragment; it remains refused as a word.").
ls_word('tabletop', common_noun, forms(noun(tabletop, tabletops)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('tah', pronunciation_token, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this invariant pronunciation or transliteration component.").
ls_word('tanco', family_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('taow', pronunciation_token, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this invariant pronunciation or transliteration component.").
ls_word('teenagers', common_noun, forms(noun(teenager, teenagers)), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('terrariums', common_noun, forms(noun(terrarium, terrariums)), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('ters', tokenizer_artifact, none, evidence(occurrences(2), pass(guide_saturation_1)), "uncertain: the guide text contains a truncated, fused, or malformed token, so it remains refused as a word.").
ls_word('thailand', place_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('the', function_word, forms(invariant), evidence(occurrences(96414), pass(guide_saturation_1)), "The absorbed questioning-paper STOP list supplies this closed function-word judgment.").
ls_word('they', function_word, forms(invariant), evidence(occurrences(11505), pass(guide_saturation_1)), "The absorbed questioning-paper STOP list supplies this closed function-word judgment.").
ls_word('threadsnake', common_noun, forms(noun(threadsnake, threadsnakes)), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('ths', tokenizer_artifact, none, evidence(occurrences(5), pass(guide_saturation_1)), "uncertain: the guide text contains a truncated, fused, or malformed token, so it remains refused as a word.").
ls_word('timeline', pedagogy_term, forms(noun(timeline, timelines)), evidence(occurrences(883), pass(guide_saturation_1)), "The guides use this noun for an instructional routine, resource, or analysis practice.").
ls_word('tio', given_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('to', function_word, forms(invariant), evidence(occurrences(54499), pass(guide_saturation_1)), "The absorbed questioning-paper STOP list supplies this closed function-word judgment.").
ls_word('tofu', common_noun, forms(noun(tofu, tofus)), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('tonique', given_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('toolkit', common_noun, forms(noun(toolkit, toolkits)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('trompos', common_noun, forms(noun(trompo, trompos)), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('trujillo', family_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('tuhs', pronunciation_token, forms(invariant), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this invariant pronunciation or transliteration component.").
ls_word('u', curriculum_code, forms(invariant), evidence(occurrences(89), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('u1', curriculum_code, forms(invariant), evidence(occurrences(91), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('u2', curriculum_code, forms(invariant), evidence(occurrences(113), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('u3', curriculum_code, forms(invariant), evidence(occurrences(122), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('u4', curriculum_code, forms(invariant), evidence(occurrences(121), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('u5', curriculum_code, forms(invariant), evidence(occurrences(105), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('u6', curriculum_code, forms(invariant), evidence(occurrences(115), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('u7', curriculum_code, forms(invariant), evidence(occurrences(98), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('u8', curriculum_code, forms(invariant), evidence(occurrences(89), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('u9', curriculum_code, forms(invariant), evidence(occurrences(25), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('uibo', family_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('unchanged', adjective, forms(invariant), evidence(occurrences(8), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('unconnected', adjective, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('unfamiliar', adjective, forms(invariant), evidence(occurrences(17), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('unknowns', math_term, forms(noun(unknowns, unknownses)), evidence(occurrences(42), pass(guide_saturation_1)), "The guides use this word as a mathematics or classroom-analysis noun.").
ls_word('unlabeled', adjective, forms(invariant), evidence(occurrences(31), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('unmarked', adjective, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('unmatched', adjective, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('unshaded', adjective, forms(invariant), evidence(occurrences(8), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('unsharpened', adjective, forms(invariant), evidence(occurrences(17), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('unstuck', adjective, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('unsubstantiated', adjective, forms(invariant), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('unusually', adverb, forms(invariant), evidence(occurrences(27), pass(guide_saturation_1)), "The guides use this word adverbially.").
ls_word('uppercase', adjective, forms(invariant), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this word adjectivally.").
ls_word('usa', named_entity, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this token as a named game, organization, event, or team.").
ls_word('v', algebra_symbol, forms(invariant), evidence(occurrences(24), pass(guide_saturation_1)), "The guides use this invariant token as a variable or labeled quantity.").
ls_word('valerie', given_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('veggies', common_noun, forms(noun(veggie, veggies)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('vendor', common_noun, forms(noun(vendor, vendors)), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('venn', common_noun, forms(noun(venn, venns)), evidence(occurrences(8), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('versa', adverb, forms(invariant), evidence(occurrences(10), pass(guide_saturation_1)), "The guides use this word adverbially.").
ls_word('verónica', given_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as an individual person's given name.").
ls_word('vimeo', web_token, forms(invariant), evidence(occurrences(4), pass(guide_saturation_1)), "The guide source metadata uses this web, file-conversion, or publishing token.").
ls_word('visibly', adverb, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word adverbially.").
ls_word('visualization', pedagogy_term, forms(noun(visualization, visualizations)), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this noun for an instructional routine, resource, or analysis practice.").
ls_word('visually', adverb, forms(invariant), evidence(occurrences(56), pass(guide_saturation_1)), "The guides use this word adverbially.").
ls_word('visuals', common_noun, forms(noun(visual, visuals)), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('vohz', pronunciation_token, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this invariant pronunciation or transliteration component.").
ls_word('vs', abbreviation, forms(invariant), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this invariant abbreviation or file label.").
ls_word('vt35', curriculum_code, forms(invariant), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('washington', place_name, none, evidence(occurrences(12), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('whiteboard', common_noun, forms(noun(whiteboard, whiteboards)), evidence(occurrences(19), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('whiteboards', common_noun, forms(noun(whiteboard, whiteboards)), evidence(occurrences(22), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('wikimedia', web_token, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guide source metadata uses this web, file-conversion, or publishing token.").
ls_word('wildlife', common_noun, forms(noun(wildlife, wildlife)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('willems', family_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('williams', family_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a person's family name.").
ls_word('wingspan', common_noun, forms(noun(wingspan, wingspans)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('wisconsin', place_name, none, evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('wn11', curriculum_code, forms(invariant), evidence(occurrences(7), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('wn90', curriculum_code, forms(invariant), evidence(occurrences(10), pass(guide_saturation_1)), "The guides use this invariant token in a curriculum, standard, lesson, or source identifier.").
ls_word('wore', corpus_verb, forms(verb(wear, wears, wore, wearing, worn)), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('workbook', common_noun, forms(noun(workbook, workbooks)), evidence(occurrences(11), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('workload', common_noun, forms(noun(workload, workload)), evidence(occurrences(18), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('worksheet', common_noun, forms(noun(worksheet, worksheets)), evidence(occurrences(3), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('workspace', common_noun, forms(noun(workspace, workspaces)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('worn', corpus_verb, forms(verb(wear, wears, wore, wearing, worn)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this verb form; the row records its five-form paradigm.").
ls_word('wouldn', contraction_fragment, none, evidence(occurrences(25), pass(guide_saturation_1)), "The tokenizer detached this contraction fragment; it remains refused as a word.").
ls_word('www', web_token, forms(invariant), evidence(occurrences(5), pass(guide_saturation_1)), "The guide source metadata uses this web, file-conversion, or publishing token.").
ls_word('wyoming', place_name, none, evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('xs', algebra_symbol, forms(invariant), evidence(occurrences(43), pass(guide_saturation_1)), "The guides use this invariant token as a variable or labeled quantity.").
ls_word('yourselves', function_word, forms(invariant), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this invariant grammatical function word.").
ls_word('yum', interjection, forms(invariant), evidence(occurrences(4), pass(guide_saturation_1)), "The guides use this invariant conversational interjection.").
ls_word('yupik', place_name, none, evidence(occurrences(6), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('z', algebra_symbol, forms(invariant), evidence(occurrences(26), pass(guide_saturation_1)), "The guides use this invariant token as a variable or labeled quantity.").
ls_word('zealand', place_name, none, evidence(occurrences(24), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").
ls_word('zeroes', math_term, forms(noun(zero, zeroes)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a mathematics or classroom-analysis noun.").
ls_word('zookeeper', common_noun, forms(noun(zookeeper, zookeepers)), evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('zookeepers', common_noun, forms(noun(zookeeper, zookeepers)), evidence(occurrences(5), pass(guide_saturation_1)), "The guides use this word as a noun absent from the combined stores.").
ls_word('zuni', place_name, none, evidence(occurrences(2), pass(guide_saturation_1)), "The guides use this capitalized token as a place or people-name component.").

ls_word('aceves', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('acosta', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('addington', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('additivity', math_term, forms(noun(additivity, additivities)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as a mathematics noun.").
ls_word('adolfo', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('aesthetic', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('aishlinn', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('alaskans', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('alberto', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('alejandro', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('alphonese', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('alves', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('andrea', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('andrés', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('angela', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('anke', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('anothers', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('anymore', adverb, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adverbially.").
ls_word('app', common_noun, forms(noun(app, apps)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('approximations', math_term, forms(noun(approximation, approximations)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as a mathematics noun.").
ls_word('argentina', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('arjun', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('arrowed', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('ascars', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('ashli', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('asia', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('atehortúa', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('aubrey', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('audiobooks', common_noun, forms(noun(audiobook, audiobooks)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('audrey', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('audubon', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('augusta', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('automated', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('awarenes', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('backline', pedagogy_term, forms(noun(backline, backlines)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this noun for an instructional resource or practice.").
ls_word('bal', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('baltimore', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('baow', pronunciation_token, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide prints this invariant pronunciation component beside a named term.").
ls_word('barnum', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('becca', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('beekeepers', common_noun, forms(noun(beekeeper, beekeepers)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('begun', corpus_verb, forms(verb(begin, begins, began, beginning, begun)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this verb surface; the row records its five-form paradigm.").
ls_word('behmer', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('bejarano', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('bement', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('berger', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('bernadette', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('beverly', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('biked', corpus_verb, forms(verb(bike, bikes, biked, biking, biked)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this verb surface; the row records its five-form paradigm.").
ls_word('bim', named_entity, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this token as a named product, organization, title, or game.").
ls_word('blaker', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('bodegas', common_noun, forms(noun(bodega, bodegas)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('bondurant', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('bonilla', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('bookcase', common_noun, forms(noun(bookcase, bookcases)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('bop', named_entity, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this token as a named product, organization, title, or game.").
ls_word('bossio', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('botero', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('bottlenose', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('bow', common_noun, forms(noun(bow, bows)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('bowen', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('brazil', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('brendan', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('bridget', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('brigitte', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('brokaw', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('buckner', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('bulleted', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('by1', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('by5', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('ca', abbreviation, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this invariant abbreviation.").
ls_word('camilo', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('casias', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('casseroles', common_noun, forms(noun(casserole, casseroles)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('castelblanco', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('catanese', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('ccss', curriculum_code, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide source uses this invariant curriculum or lesson identifier.").
ls_word('celeana', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('centersl', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('centi', unit_prefix, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide explicitly uses this invariant SI unit-prefix name.").
ls_word('ceo', abbreviation, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this invariant abbreviation.").
ls_word('cerrahoglu', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('chang', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('chavez', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('checkmark', common_noun, forms(noun(checkmark, checkmarks)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('chiasson', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('chunking', pedagogy_term, forms(noun(chunking, chunking)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this noun for an instructional resource or practice.").
ls_word('clara', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('cleanup', common_noun, forms(noun(cleanup, cleanups)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('clker', web_token, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide source metadata uses this invariant web, file, or publishing token.").
ls_word('clothespins', common_noun, forms(noun(clothespin, clothespins)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('cm2', math_notation, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this invariant measurement or tally notation.").
ls_word('cm3', math_notation, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this invariant measurement or tally notation.").
ls_word('coer', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('collaboratively', adverb, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adverbially.").
ls_word('colorado', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('commercials', common_noun, forms(noun(commercial, commercials)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('competent', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('connally', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('corpus', common_noun, forms(noun(corpus, corpus)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('costumes', common_noun, forms(noun(costume, costumes)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('counselor', common_noun, forms(noun(counselor, counselors)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('countable', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('countertop', common_noun, forms(noun(countertop, countertops)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('creatively', adverb, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adverbially.").
ls_word('creativity', common_noun, forms(noun(creativity, creativity)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('crilley', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('criticize', corpus_verb, forms(verb(criticize, criticizes, criticized, criticizing, criticized)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this verb surface; the row records its five-form paradigm.").
ls_word('cuervo', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('cukier', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('culminating', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('cultural', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('cummins', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('cunningham', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('cute', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('cycling', common_noun, forms(noun(cycling, cycling)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('daro', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('deb', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('delhi', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('delis', common_noun, forms(noun(deli, delis)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('developmentally', adverb, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adverbially.").
ls_word('dieckmann', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('digitally', adverb, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adverbially.").
ls_word('dina', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('disalvo', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('dislay', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('distractors', pedagogy_term, forms(noun(distractor, distractors)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this noun for an instructional resource or practice.").
ls_word('doran', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('dougie', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('drawdy', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('drawhen', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('duhls', pronunciation_token, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide prints this invariant pronunciation component beside a named term.").
ls_word('dunbar', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('dyanne', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('ehlert', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('ehn', pronunciation_token, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide prints this invariant pronunciation component beside a named term.").
ls_word('eleanor', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('elijah', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('ellen', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('englard', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('erase2', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('espinosa', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('estrella', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('exclusively', adverb, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adverbially.").
ls_word('experimenting', corpus_verb, forms(verb(experiment, experiments, experimented, experimenting, experimented)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this verb surface; the row records its five-form paradigm.").
ls_word('exploiting', corpus_verb, forms(verb(exploit, exploits, exploited, exploiting, exploited)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this verb surface; the row records its five-form paradigm.").
ls_word('fawlz', pronunciation_token, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide prints this invariant pronunciation component beside a named term.").
ls_word('fettuccine', common_noun, forms(noun(fettuccine, fettuccines)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('fishbowl', common_noun, forms(noun(fishbowl, fishbowls)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('fishbowls', common_noun, forms(noun(fishbowl, fishbowls)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('fl', abbreviation, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this invariant abbreviation.").
ls_word('flanagan', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('flatbread', common_noun, forms(noun(flatbread, flatbreads)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('floorspace', common_noun, forms(noun(floorspace, floorspaces)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('forero', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('forg', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('france', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('francy', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('freeways', common_noun, forms(noun(freeway, freeways)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('freshwater', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('friendlier', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('frisbee', common_noun, forms(noun(frisbee, frisbees)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('gael', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('gah', pronunciation_token, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide prints this invariant pronunciation component beside a named term.").
ls_word('garrett', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('gary', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('gcf', abbreviation, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this invariant abbreviation.").
ls_word('geh', pronunciation_token, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide prints this invariant pronunciation component beside a named term.").
ls_word('gehé', named_entity, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this token as a named product, organization, title, or game.").
ls_word('giang', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('gonna', function_word, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this invariant grammatical function word.").
ls_word('gonzález', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('grassy', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('gretchen', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('groupmates', common_noun, forms(noun(groupmate, groupmates)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('guarín', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('gutiérrez', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('gwah', pronunciation_token, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide prints this invariant pronunciation component beside a named term.").
ls_word('gómez', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('haase', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('hamilton', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('hannah', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('harris', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('hathaway', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('helicopter', common_noun, forms(noun(helicopter, helicopters)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('hemmings', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('heptathlon', common_noun, forms(noun(heptathlon, heptathlons)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('hernandez', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('hippos', common_noun, forms(noun(hippo, hippos)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('hollister', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('hovan', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('http', web_token, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide source metadata uses this invariant web, file, or publishing token.").
ls_word('hummingbirds', common_noun, forms(noun(hummingbird, hummingbirds)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('hypothesize', corpus_verb, forms(verb(hypothesize, hypothesizes, hypothesized, hypothesizing, hypothesized)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this verb surface; the row records its five-form paradigm.").
ls_word('iguazu', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('iii', math_notation, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this invariant measurement or tally notation.").
ls_word('iiiii', math_notation, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this invariant measurement or tally notation.").
ls_word('iiiiiii', math_notation, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this invariant measurement or tally notation.").
ls_word('iiiiiiii', math_notation, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this invariant measurement or tally notation.").
ls_word('illinois', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('inadvertently', adverb, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adverbially.").
ls_word('inche', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('infographic', pedagogy_term, forms(noun(infographic, infographics)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this noun for an instructional resource or practice.").
ls_word('infographics', pedagogy_term, forms(noun(infographic, infographics)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this noun for an instructional resource or practice.").
ls_word('insightful', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('invitational', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('ipad', named_entity, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this token as a named product, organization, title, or game.").
ls_word('iraq', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('iteratively', adverb, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adverbially.").
ls_word('jackyra', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('jaragua', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('jaramillo', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('jareb', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('jed', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('jenise', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('jkpics', web_token, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide source metadata uses this invariant web, file, or publishing token.").
ls_word('jon', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('jpg', web_token, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide source metadata uses this invariant web, file, or publishing token.").
ls_word('judgement', common_noun, forms(noun(judgement, judgements)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('judith', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('karim', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('kathy', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('kerins', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('kessel', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('kia', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('kim', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('kobyra', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('koppens', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('krah', pronunciation_token, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide prints this invariant pronunciation component beside a named term.").
ls_word('kranendonk', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('krismen', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('kristine', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('kuo', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('l27', curriculum_code, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide source uses this invariant curriculum or lesson identifier.").
ls_word('l28', curriculum_code, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide source uses this invariant curriculum or lesson identifier.").
ls_word('lahme', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('lahn', pronunciation_token, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide prints this invariant pronunciation component beside a named term.").
ls_word('landfills', common_noun, forms(noun(landfill, landfills)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('larrieu', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('lasagna', common_noun, forms(noun(lasagna, lasagnas)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('lcm', abbreviation, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this invariant abbreviation.").
ls_word('least1', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('lebanon', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('lefto', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('lemense', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('lesondak', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('lessondoc', curriculum_code, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide source uses this invariant curriculum or lesson identifier.").
ls_word('libby', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('lindsay', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('lipitz', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('liz', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('lizzy', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('liévano', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('lois', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('lowercase', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('lyons', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('lópez', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('maddie', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('madeleine', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('mah', pronunciation_token, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide prints this invariant pronunciation component beside a named term.").
ls_word('mak', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('malamut', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('manhattan', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('mappings', common_noun, forms(noun(mapping, mappings)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('mariño', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('marsaili', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('martínez', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('maría', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('mashup', common_noun, forms(noun(mashup, mashups)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('massachusetts', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('mathematicals', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('mathforum', web_token, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide source metadata uses this invariant web, file, or publishing token.").
ls_word('mauricio', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('mccallum', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('mckissack', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('mcleman', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('medina', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('mee', pronunciation_token, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide prints this invariant pronunciation component beside a named term.").
ls_word('mesa', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('metacognition', pedagogy_term, forms(noun(metacognition, metacognition)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this noun for an instructional resource or practice.").
ls_word('mexicos', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('mia', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('micah', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('michelle', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('midrange', math_term, forms(noun(midrange, midranges)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as a mathematics noun.").
ls_word('mimi', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('mindset', pedagogy_term, forms(noun(mindset, mindsets)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this noun for an instructional resource or practice.").
ls_word('minuter', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('miqramah', named_entity, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this token as a named product, organization, title, or game.").
ls_word('misalign', corpus_verb, forms(verb(misalign, misaligns, misaligned, misaligning, misaligned)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this verb surface; the row records its five-form paradigm.").
ls_word('misalignment', math_term, forms(noun(misalignment, misalignments)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as a mathematics noun.").
ls_word('moises', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('moma', named_entity, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this token as a named product, organization, title, or game.").
ls_word('montana', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('mourtgos', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('ms3', curriculum_code, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide source uses this invariant curriculum or lesson identifier.").
ls_word('murals', common_noun, forms(noun(mural, murals)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('muñoz', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('nah', pronunciation_token, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide prints this invariant pronunciation component beside a named term.").
ls_word('nakamaye', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('nathaly', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('nctm', named_entity, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this token as a named product, organization, title, or game.").
ls_word('neihaus', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('nevada', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('newborns', common_noun, forms(noun(newborn, newborns)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('nia', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('nicely', adverb, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adverbially.").
ls_word('nightstand', common_noun, forms(noun(nightstand, nightstands)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('nik', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('nonzero', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('norstrom', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('notated', corpus_verb, forms(verb(notate, notates, notated, notating, notated)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this verb surface; the row records its five-form paradigm.").
ls_word('notecard', common_noun, forms(noun(notecard, notecards)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('nowak', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('number10', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('oakland', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('obviously', adverb, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adverbially.").
ls_word('of54', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('ohio', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('orlando', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('otero', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('ott', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('ours', function_word, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this invariant grammatical function word.").
ls_word('overlapped', corpus_verb, forms(verb(overlap, overlaps, overlapped, overlapping, overlapped)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this verb surface; the row records its five-form paradigm.").
ls_word('overspend', corpus_verb, forms(verb(overspend, overspends, overspent, overspending, overspent)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this verb surface; the row records its five-form paradigm.").
ls_word('oware', named_entity, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this token as a named product, organization, title, or game.").
ls_word('pakistan', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('pallanguzhi', named_entity, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this token as a named product, organization, title, or game.").
ls_word('papadum', common_noun, forms(noun(papadum, papadums)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('paperclips', common_noun, forms(noun(paperclip, paperclips)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('parascand', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('paredes', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('parker', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('partitionings', math_term, forms(noun(partitioning, partitionings)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as a mathematics noun.").
ls_word('paternina', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('patti', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('peru', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('petersen', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('philomen', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('phyllis', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('pikcilingis', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('pina', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('pohs', pronunciation_token, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide prints this invariant pronunciation component beside a named term.").
ls_word('portee', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('preetha', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('prefilled', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('pressure', common_noun, forms(noun(pressure, pressure)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('prioritize', corpus_verb, forms(verb(prioritize, prioritizes, prioritized, prioritizing, prioritized)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this verb surface; the row records its five-form paradigm.").
ls_word('productively', adverb, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adverbially.").
ls_word('progressively', adverb, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adverbially.").
ls_word('pros', common_noun, forms(noun(pro, pros)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('protractorhas', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('puchalik', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('pullin', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('py', web_token, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide source metadata uses this invariant web, file, or publishing token.").
ls_word('pérez', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('quach', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('quantified', corpus_verb, forms(verb(quantify, quantifies, quantified, quantifying, quantified)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this verb surface; the row records its five-form paradigm.").
ls_word('quantifiers', math_term, forms(noun(quantifier, quantifiers)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as a mathematics noun.").
ls_word('quesadilla', common_noun, forms(noun(quesadilla, quesadillas)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('quiltmakers', common_noun, forms(noun(quiltmaker, quiltmakers)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('quintillion', math_term, forms(noun(quintillion, quintillions)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as a mathematics noun.").
ls_word('ramen', common_noun, forms(noun(ramen, ramens)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('ramirez', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('rdquo', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('reasonin', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('receptively', adverb, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adverbially.").
ls_word('recomposing', math_term, forms(noun(recomposing, recomposing)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as a mathematics noun.").
ls_word('reconsidering', corpus_verb, forms(verb(reconsider, reconsiders, reconsidered, reconsidering, reconsidered)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this verb surface; the row records its five-form paradigm.").
ls_word('recorder', common_noun, forms(noun(recorder, recorders)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('reframe', corpus_verb, forms(verb(reframe, reframes, reframed, reframing, reframed)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this verb surface; the row records its five-form paradigm.").
ls_word('reh', pronunciation_token, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide prints this invariant pronunciation component beside a named term.").
ls_word('relational', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('reliability', common_noun, forms(noun(reliability, reliability)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('remake', corpus_verb, forms(verb(remake, remakes, remade, remaking, remade)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this verb surface; the row records its five-form paradigm.").
ls_word('remaking', corpus_verb, forms(verb(remake, remakes, remade, remaking, remade)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this verb surface; the row records its five-form paradigm.").
ls_word('renae', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('renames', corpus_verb, forms(verb(rename, renames, renamed, renaming, renamed)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this verb surface; the row records its five-form paradigm.").
ls_word('renaming', math_term, forms(noun(renaming, renaming)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as a mathematics noun.").
ls_word('renee', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('reorganize', corpus_verb, forms(verb(reorganize, reorganizes, reorganized, reorganizing, reorganized)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this verb surface; the row records its five-form paradigm.").
ls_word('reorganized', corpus_verb, forms(verb(reorganize, reorganizes, reorganized, reorganizing, reorganized)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this verb surface; the row records its five-form paradigm.").
ls_word('replacement', common_noun, forms(noun(replacement, replacements)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('reserved', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('reyes', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('rivera', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('rodney', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('rolando', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('rotational', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('route', common_noun, forms(noun(route, routes)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('roxy', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('russell', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('rutherford', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('s15strategy', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('sacramento', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('sadako', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('sadie', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('salazar', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('salgarino', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('sara', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('selectively', adverb, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adverbially.").
ls_word('setup', common_noun, forms(noun(setup, setups)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('setups', common_noun, forms(noun(setup, setups)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('shadyside', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('shean', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('shortcuts', common_noun, forms(noun(shortcut, shortcuts)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('siavash', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('skarin', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('skousen', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('skydive', named_entity, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this token as a named product, organization, title, or game.").
ls_word('socio', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('somari', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('soulsgrowndeep', web_token, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide source metadata uses this invariant web, file, or publishing token.").
ls_word('southeast', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('souvenir', common_noun, forms(noun(souvenir, souvenirs)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('squishing', corpus_verb, forms(verb(squish, squishes, squished, squishing, squished)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this verb surface; the row records its five-form paradigm.").
ls_word('stefanie', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('stitchin', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('stoll', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('stoplight', common_noun, forms(noun(stoplight, stoplights)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('structurally', adverb, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adverbially.").
ls_word('sturges', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('sudan', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('supermarkets', common_noun, forms(noun(supermarket, supermarkets)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('suárez', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('symbolically', adverb, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adverbially.").
ls_word('syria', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('sánchez', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('taiwan', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('takeout', common_noun, forms(noun(takeout, takeout)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('tamari', common_noun, forms(noun(tamari, tamaris)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('tanzania', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('taranto', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('taren', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('tate', named_entity, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this token as a named product, organization, title, or game.").
ls_word('teh', pronunciation_token, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide prints this invariant pronunciation component beside a named term.").
ls_word('tehrani', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('tennessee', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('thai', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('themself', function_word, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this invariant grammatical function word.").
ls_word('thetwo', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('thier', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('thingies', common_noun, forms(noun(thingy, thingies)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('thoughtfully', adverb, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adverbially.").
ls_word('tiana', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('tioanda', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('tock', interjection, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide text uses this invariant sound word.").
ls_word('tompert', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('toni', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('topeka', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('trademarks', common_noun, forms(noun(trademark, trademarks)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('transitioned', corpus_verb, forms(verb(transition, transitions, transitioned, transitioning, transitioned)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this verb surface; the row records its five-form paradigm.").
ls_word('trenton', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('trickiest', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('trish', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('trohm', pronunciation_token, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide prints this invariant pronunciation component beside a named term.").
ls_word('tsp', unit_abbreviation, expands_to(teaspoon), evidence(occurrences(1), pass(guide_saturation_2)), "The guide recipe uses this unit abbreviation with the stated expansion.").
ls_word('umland', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('unambiguous', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('unattended', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('unavailable', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('uncooked', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('uneaten', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('unfilled', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('unhealthy', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('unpartitioned', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('unreasonably', adverb, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adverbially.").
ls_word('unresolved', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('unrounded', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('unsafe', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('untorn', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('updating', corpus_verb, forms(verb(update, updates, updated, updating, updated)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this verb surface; the row records its five-form paradigm.").
ls_word('utah', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('va', abbreviation, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this invariant abbreviation.").
ls_word('ver', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('vigorously', adverb, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adverbially.").
ls_word('vinci', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('voh', pronunciation_token, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide prints this invariant pronunciation component beside a named term.").
ls_word('wah', pronunciation_token, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide prints this invariant pronunciation component beside a named term.").
ls_word('walsh', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('wartime', common_noun, forms(noun(wartime, wartime)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('weiss', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('whiteman', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('wiki', web_token, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide source metadata uses this invariant web, file, or publishing token.").
ls_word('winkler', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('wisdom', common_noun, forms(noun(wisdom, wisdom)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('wolfsburg', place_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this capitalized token as a place or people-name component.").
ls_word('workstations', common_noun, forms(noun(workstation, workstations)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('worthwhile', adjective, forms(invariant), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface adjectivally.").
ls_word('write1', tokenizer_artifact, none, evidence(occurrences(1), pass(guide_saturation_2)), "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.").
ls_word('xander', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('yenche', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('yogurt', common_noun, forms(noun(yogurt, yogurts)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('yoko', given_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide text or credits use this capitalized token as a person's given name.").
ls_word('youth', common_noun, forms(noun(youth, youth)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('zapata', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").
ls_word('zillion', math_term, forms(noun(zillion, zillions)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as a mathematics noun.").
ls_word('zipper', common_noun, forms(noun(zipper, zippers)), evidence(occurrences(1), pass(guide_saturation_2)), "The guide context uses this surface as an ordinary noun.").
ls_word('zwiers', family_name, none, evidence(occurrences(1), pass(guide_saturation_2)), "The guide credits use this capitalized token as a person's family name.").

% Multiword alternatives in the absorbed questioning-paper lexicon.
ls_phrase([place, value], math_phrase, "The questioning-paper lexicon attests place value as one mathematics phrase.").
ls_phrase([number, line], math_phrase, "The questioning-paper lexicon attests number line as one mathematics phrase.").
ls_phrase([tape, diagram], math_phrase, "The questioning-paper lexicon attests tape diagram as one mathematics phrase.").
ls_phrase([base, ten], math_phrase, "The questioning-paper lexicon attests base ten, including its hyphenated source alternative.").
ls_phrase([ten, frame], math_phrase, "The questioning-paper lexicon attests ten frame, including its hyphenated source alternative.").
ls_phrase([square, root], math_phrase, "The questioning-paper lexicon attests square root as one mathematics phrase.").
ls_phrase([absolute, value], math_phrase, "The questioning-paper lexicon attests absolute value as one mathematics phrase.").
ls_phrase([scale, factor], math_phrase, "The questioning-paper lexicon attests scale factor as one mathematics phrase.").

lexicon_supplement_summary(
    summary(role(orphan_authored_lexicon_supplement),
            sources([slice_1_ml_unknown, im_guide_saturation_1, im_guide_saturation_2]),
            word_rows(1923), occurrence_evidence(233776), phrase_rows(8), class_counts([
                abbreviation(28),
                adjective(141),
                adverb(54),
                algebra_symbol(21),
                common_noun(433),
                contraction_fragment(15),
                corpus_verb(158),
                curriculum_code(103),
                family_name(164),
                function_word(15),
                given_name(405),
                honorific(6),
                interjection(4),
                math_notation(11),
                math_term(61),
                name_particle(1),
                named_entity(34),
                pedagogy_term(18),
                place_name(108),
                pronunciation_token(40),
                temporal_word(9),
                tokenizer_artifact(52),
                unit_abbreviation(21),
                unit_prefix(1),
                web_token(20)
            ]))).

check_lexicon_supplement :-
    aggregate_all(count, ls_word(_, _, _, _, _), 1923),
    findall(W, ls_word(W, _, _, _, _), W0), sort(W0, Words), length(Words, 1923),
    findall(N, ls_word(_, _, _, evidence(occurrences(N)), _), Slice2Ns),
    length(Slice2Ns, 764), sum_list(Slice2Ns, 12529),
    findall(N, ls_word(_, _, _, evidence(occurrences(N), pass(guide_saturation_1)), _), GuideNs),
    length(GuideNs, 654), sum_list(GuideNs, 220327),
    findall(N, ls_word(_, _, _, evidence(occurrences(N), pass(guide_saturation_2)), _), Guide2Ns),
    length(Guide2Ns, 499), sum_list(Guide2Ns, 499),
    forall(ls_word(_, tokenizer_artifact, none,
                   evidence(_, pass(guide_saturation_2)), R),
           sub_string(R, 0, 10, _, "uncertain:")),
    forall(member(FunctionWord, [could, its, others, our, should, the, they, to]),
           once(ls_word(FunctionWord, function_word, forms(invariant),
                        evidence(_, pass(guide_saturation_1)), _))),
    forall(member(Fragment, [s, t]),
           once(ls_word(Fragment, contraction_fragment, none,
                        evidence(_, pass(guide_saturation_1)), _))),
    forall(ls_word(W, C, M, E, R), valid_word_row(W, C, M, E, R)),
    aggregate_all(count, ls_phrase(_, _, _), 8),
    forall(ls_phrase(T, C, R), valid_phrase_row(T, C, R)),
    ensure_math_lexicon,
    aggregate_all(count, math_lexicon_pilot:ml_baseline_unknown(_, _), 764),
    forall(math_lexicon_pilot:ml_baseline_unknown(W, N), once(ls_word(W, _, _, evidence(occurrences(N)), _))),
    forall(ls_word(W, _, _, evidence(occurrences(N)), _), math_lexicon_pilot:ml_baseline_unknown(W, N)),
    forall((math_lexicon_pilot:ml_source_term(questioning_paper_lexicon, _, tokens(T)), T = [_,_|_]), once(ls_phrase(T, math_phrase, _))),
    forall(ls_phrase(T, math_phrase, _), math_lexicon_pilot:ml_source_term(questioning_paper_lexicon, _, tokens(T))),
    writeln('lexicon_supplement_pilot: all receipts passed').

valid_word_row(W, C, M, evidence(occurrences(N)), R) :-
    atom(W), atom(C), integer(N), N > 0, string(R), R \== "", valid_morphology(C, M).
valid_word_row(W, C, M, evidence(occurrences(N), pass(P)), R) :-
    atom(W), atom(C), integer(N), N > 0, atom(P), string(R), R \== "",
    valid_morphology(C, M).

valid_morphology(C, none) :- memberchk(C, [given_name, family_name, place_name, named_entity, tokenizer_artifact, contraction_fragment]).
valid_morphology(_, forms(noun(S, P))) :- atom(S), atom(P).
valid_morphology(_, forms(verb(B, S, P, I, T))) :- maplist(atom, [B, S, P, I, T]).
valid_morphology(_, forms(invariant)).
valid_morphology(unit_abbreviation, expands_to(F)) :- atom(F).

valid_phrase_row(T, math_phrase, R) :- T = [_,_|_], maplist(atom, T), string(R), R \== "".

ensure_math_lexicon :-
    ( current_predicate(math_lexicon_pilot:ml_baseline_unknown/2) -> true
    ; supplement_directory(H), directory_file_path(H, 'math_lexicon_pilot.pl', P), ensure_loaded(P)
    ).
